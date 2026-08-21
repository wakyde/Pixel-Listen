import re
import json
import asyncio
import hashlib
import random
from pathlib import Path
from typing import Optional

from fastapi import APIRouter, HTTPException, Query
from fastapi.responses import StreamingResponse, FileResponse
from pydantic import BaseModel
import httpx

router = APIRouter(prefix="/api/songs", tags=["songs"])

_SONGS_CACHE = Path("media/songs_cache")
_SONGS_CACHE.mkdir(parents=True, exist_ok=True)


def _cache_key(artist: str, title: str) -> str:
    raw = f"{artist.strip().lower()}:{title.strip().lower()}"
    return hashlib.md5(raw.encode()).hexdigest()


class SongResult(BaseModel):
    track_id: str
    title: str
    artist: str
    album_name: Optional[str] = None
    artwork_url: Optional[str] = None
    preview_url: Optional[str] = None
    audio_url: Optional[str] = None
    duration: Optional[int] = None


class SearchResponse(BaseModel):
    results: list[SongResult]
    query: str


ITUNES_SEARCH = "https://itunes.apple.com/search"
LYRICS_OVH = "https://api.lyrics.ovh/v1"
NETEASE_BASE = "https://music.163.com/api"
NETEASE_HEADERS = {"Referer": "https://music.163.com"}

QQ_SEARCH = "https://c.y.qq.com/soso/fcgi-bin/client_search_cp"
QQ_SONG_URL = "https://u.y.qq.com/cgi-bin/musicu.fcg"
QQ_HEADERS = {
    "Referer": "https://y.qq.com",
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
}


@router.get("/search", response_model=SearchResponse)
async def search_songs(q: str = Query(..., min_length=1), limit: int = Query(20, ge=1, le=50)):
    results = await _search_itunes(q, limit)
    if len(results) < limit:
        qq_results = await _search_qqmusic(q, limit - len(results))
        seen = {_normalize_key(r.title, r.artist) for r in results}
        for r in qq_results:
            key = _normalize_key(r.title, r.artist)
            if key not in seen:
                seen.add(key)
                results.append(r)

    return SearchResponse(results=results, query=q)


@router.get("/lyrics")
async def get_lyrics(artist: str = Query(...), title: str = Query(...)):
    result = await _fetch_lyrics_ovh(artist, title)
    if result:
        return result

    result = await _fetch_lyrics_netease(artist, title)
    if result:
        return result

    raise HTTPException(status_code=404, detail="Lyrics not found")


@router.get("/audio")
async def get_audio(artist: str = Query(...), title: str = Query(...)):
    audio_url = await _get_qqmusic_audio(title, artist)
    if audio_url:
        return {"artist": artist, "title": title, "audio_url": audio_url, "source": "qqmusic"}

    audio_url = await _get_youtube_audio(title, artist)
    if audio_url:
        return {"artist": artist, "title": title, "audio_url": audio_url, "source": "youtube"}

    raise HTTPException(status_code=404, detail="Audio not found")


@router.get("/stream")
async def stream_audio(artist: str = Query(...), title: str = Query(...)):
    cache_name = _cache_key(artist, title)
    cache_path = _SONGS_CACHE / f"{cache_name}.mp3"

    if cache_path.exists() and cache_path.stat().st_size > 0:
        return FileResponse(
            cache_path,
            media_type="audio/mpeg",
            headers={"Accept-Ranges": "bytes", "Cache-Control": "public, max-age=86400"},
        )

    temp_path = _SONGS_CACHE / f"{cache_name}.tmp"

    success = await _download_youtube_audio(artist, title, temp_path)
    if success:
        temp_path.rename(cache_path)
        return FileResponse(
            cache_path,
            media_type="audio/mpeg",
            headers={"Accept-Ranges": "bytes", "Cache-Control": "public, max-age=86400"},
        )

    if temp_path.exists():
        temp_path.unlink()

    audio_url = await _get_itunes_preview(title, artist)
    if audio_url:
        async def audio_stream():
            try:
                async with httpx.AsyncClient(timeout=120) as client:
                    async with client.stream("GET", audio_url, headers={
                        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
                        "Referer": "https://music.apple.com/",
                    }) as resp:
                        async for chunk in resp.aiter_bytes(chunk_size=65536):
                            yield chunk
            except Exception:
                pass

        return StreamingResponse(
            audio_stream(),
            media_type="audio/mp4",
            headers={"Accept-Ranges": "bytes", "Cache-Control": "no-cache"},
        )

    raise HTTPException(status_code=404, detail="Audio not found")


async def _search_itunes(q: str, limit: int) -> list[SongResult]:
    try:
        async with httpx.AsyncClient(timeout=15) as client:
            resp = await client.get(
                ITUNES_SEARCH,
                params={"term": q, "entity": "song", "limit": limit},
            )
            resp.raise_for_status()
            data = resp.json()

        results = []
        seen = set()
        for item in data.get("results", []):
            kind = item.get("kind", "")
            wrapper = item.get("wrapperType", "")
            if kind != "song" and wrapper != "track":
                continue

            title = item.get("trackName") or item.get("collectionName") or "Unknown"
            artist = item.get("artistName") or "Unknown"
            key = _normalize_key(title, artist)
            if key in seen:
                continue
            seen.add(key)

            results.append(SongResult(
                track_id=str(item.get("trackId", "")),
                title=title,
                artist=artist,
                album_name=item.get("collectionName"),
                artwork_url=item.get("artworkUrl100"),
                preview_url=item.get("previewUrl"),
                audio_url=None,
                duration=item.get("trackTimeMillis"),
            ))
        return results
    except Exception:
        return []


async def _search_qqmusic(q: str, limit: int) -> list[SongResult]:
    try:
        async with httpx.AsyncClient(timeout=15) as client:
            resp = await client.get(
                QQ_SEARCH,
                params={"w": q, "n": limit, "format": "json", "t": 0},
                headers=QQ_HEADERS,
            )
            resp.raise_for_status()
            data = resp.json()

        results = []
        songs = data.get("data", {}).get("song", {}).get("list", [])
        for song in songs:
            results.append(SongResult(
                track_id=f"qq_{song.get('songmid', '')}",
                title=song.get("songname", "Unknown"),
                artist=song.get("singer", [{}])[0].get("name", "Unknown"),
                album_name=song.get("albumname"),
                artwork_url=None,
                preview_url=None,
                audio_url=None,
                duration=song.get("interval", 0) * 1000,
            ))
        return results
    except Exception:
        return []


async def _get_qqmusic_audio(title: str, artist: str) -> Optional[str]:
    try:
        async with httpx.AsyncClient(timeout=15) as client:
            search_resp = await client.get(
                QQ_SEARCH,
                params={"w": f"{artist} {title}", "n": 3, "format": "json", "t": 0},
                headers=QQ_HEADERS,
            )
            search_resp.raise_for_status()
            search_data = search_resp.json()

            songs = search_data.get("data", {}).get("song", {}).get("list", [])
            if not songs:
                return None

            best = _pick_best_qq(songs, artist, title)
            if not best:
                return None

            songmid = best["songmid"]
            song_url = await _fetch_qq_song_url(client, songmid)
            return song_url
    except Exception:
        return None


async def _fetch_qq_song_url(client: httpx.AsyncClient, songmid: str) -> Optional[str]:
    guid = str(random.randint(10000000, 99999999))
    req_data = {
        "req": {
            "module": "CDN.SrfCdnDispatchServer",
            "method": "GetCdnDispatch",
            "param": {
                "guid": guid,
                "songmid": [songmid],
            },
        }
    }
    resp = await client.get(
        QQ_SONG_URL,
        params={"format": "json", "data": json.dumps(req_data)},
        headers=QQ_HEADERS,
    )
    resp.raise_for_status()
    data = resp.json()

    req_result = data.get("req", {})
    if req_result.get("code") != 0:
        return None

    inner = req_result.get("data", {})
    sip_list = inner.get("sip") or inner.get("freeflowsip") or []
    filename = inner.get("keepalivefile", "")

    if not sip_list or not filename:
        return None

    for sip in sip_list:
        try:
            test_url = f"{sip}{filename}"
            return test_url
        except Exception:
            continue

    return None


def _pick_best_qq(songs: list, artist: str, title: str) -> Optional[dict]:
    best = songs[0]
    best_score = 0

    for song in songs:
        s_name = (song.get("songname") or "").lower()
        s_artist = (song.get("singer", [{}])[0].get("name") or "").lower()
        q_title = title.lower().strip()
        q_artist = artist.lower().strip()

        score = 0
        if q_title in s_name or s_name in q_title:
            score += 3
        if q_artist in s_artist or s_artist in q_artist:
            score += 2
        if q_title == s_name:
            score += 5

        if score > best_score:
            best_score = score
            best = song

    return best if best_score >= 2 else None


async def _get_itunes_preview(title: str, artist: str) -> Optional[str]:
    try:
        async with httpx.AsyncClient(timeout=15) as client:
            resp = await client.get(
                ITUNES_SEARCH,
                params={"term": f"{artist} {title}", "entity": "song", "limit": 3},
            )
            resp.raise_for_status()
            data = resp.json()

        for item in data.get("results", []):
            preview_url = item.get("previewUrl")
            if preview_url:
                return preview_url
    except Exception:
        pass
    return None


async def _fetch_lyrics_ovh(artist: str, title: str) -> Optional[dict]:
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.get(f"{LYRICS_OVH}/{artist}/{title}")
            if resp.status_code == 404:
                return None
            resp.raise_for_status()
            data = resp.json()
            lyrics = data.get("lyrics", "").strip()
            if lyrics:
                return {
                    "artist": artist,
                    "title": title,
                    "lyrics": lyrics,
                    "format": "txt",
                    "source": "lyrics.ovh",
                }
    except Exception:
        pass
    return None


async def _fetch_lyrics_netease(artist: str, title: str) -> Optional[dict]:
    try:
        async with httpx.AsyncClient(timeout=15) as client:
            search_resp = await client.get(
                f"{NETEASE_BASE}/search/get",
                params={"type": 1, "limit": 5, "s": f"{artist} {title}"},
                headers=NETEASE_HEADERS,
            )
            search_resp.raise_for_status()
            search_data = search_resp.json()

            songs = search_data.get("result", {}).get("songs", [])
            if not songs:
                return None

            best = _pick_best_match(songs, artist, title)
            if not best:
                return None

            song_id = best["id"]
            lyric_resp = await client.get(
                f"{NETEASE_BASE}/song/lyric",
                params={"id": song_id, "lv": 1},
                headers=NETEASE_HEADERS,
            )
            lyric_resp.raise_for_status()
            lyric_data = lyric_resp.json()

            lrc = lyric_data.get("lrc", {}).get("lyric", "")
            if not lrc:
                return None

            return {
                "artist": artist,
                "title": title,
                "lyrics": lrc,
                "format": "lrc",
                "source": "netease",
            }
    except Exception:
        pass
    return None


def _pick_best_match(songs: list, artist: str, title: str) -> Optional[dict]:
    best = songs[0]
    best_score = 0

    for song in songs:
        s_name = (song.get("name") or "").lower()
        s_artist = (song.get("artists", [{}])[0].get("name") or "").lower()
        q_title = title.lower().strip()
        q_artist = artist.lower().strip()

        score = 0
        if q_title in s_name or s_name in q_title:
            score += 3
        if q_artist in s_artist or s_artist in q_artist:
            score += 2
        if q_title == s_name:
            score += 5

        if score > best_score:
            best_score = score
            best = song

    return best if best_score >= 2 else None


def _normalize_key(title: str, artist: str) -> str:
    return f"{title.strip().lower()}|{artist.strip().lower()}"


async def _get_youtube_audio(title: str, artist: str) -> Optional[str]:
    try:
        query = f"ytsearch1:{artist} - {title} audio"
        code, stdout, stderr = await _run_yt_dlp_cmd([
            "--dump-json",
            "--no-warnings",
            "--no-playlist",
            "--format", "best[ext=m4a]/bestaudio/best",
            "--extractor-args", "youtube:player_client=android",
            "--js-runtimes", "node",
            "--socket-timeout", "60",
            query,
        ], timeout=60)

        if code != 0:
            return None

        info = json.loads(stdout)
        if "entries" in info and info["entries"]:
            url = info["entries"][0].get("url")
            if url:
                return url
        url = info.get("url")
        if url:
            return url
    except Exception:
        pass
    return None


async def _download_youtube_audio(artist: str, title: str, output_path: Path) -> bool:
    audio_url = await _get_youtube_audio(title, artist)
    if not audio_url:
        return False

    temp_raw = output_path.with_suffix(".raw")
    try:
        async with httpx.AsyncClient(timeout=120) as client:
            async with client.stream("GET", audio_url, headers={
                "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
            }) as resp:
                if resp.status_code != 200:
                    return False
                with open(temp_raw, "wb") as f:
                    async for chunk in resp.aiter_bytes(chunk_size=65536):
                        f.write(chunk)

        process = await asyncio.create_subprocess_exec(
            'ffmpeg', '-y', '-i', str(temp_raw),
            '-vn', '-acodec', 'libmp3lame', '-b:a', '128k',
            '-f', 'mp3', str(output_path),
            stderr=asyncio.subprocess.DEVNULL,
        )
        await asyncio.wait_for(process.wait(), timeout=60)

        return process.returncode == 0 and output_path.exists() and output_path.stat().st_size > 0
    except Exception:
        return False
    finally:
        if temp_raw.exists():
            temp_raw.unlink()


async def _run_yt_dlp_cmd(args: list, timeout: int) -> tuple:
    python_path = "/Users/wakyde/.local/bin/python3.11"
    cmd = [python_path, "-m", "yt_dlp"] + args
    try:
        process = await asyncio.create_subprocess_exec(
            *cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )
        stdout, stderr = await asyncio.wait_for(process.communicate(), timeout=timeout)
        rc = process.returncode
        if rc is None:
            rc = -1
        return rc, stdout.decode(errors="replace"), stderr.decode(errors="replace")
    except asyncio.TimeoutError:
        process.kill()
        return -1, "", "Request timed out"