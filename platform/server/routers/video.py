import asyncio
import hashlib
import json
import os
import re
import uuid
from pathlib import Path
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import StreamingResponse, FileResponse
from pydantic import BaseModel

from database import Base, Column, String, Float, Integer, Text, DateTime, func, get_db, generate_uuid
from middleware.auth import get_optional_user

router = APIRouter(prefix="/api/video", tags=["video"])

_YT_DLP_PYTHON = os.environ.get("YT_DLP_PYTHON", "python3.11")

_MEDIA_DIR = Path("media")
_MEDIA_DIR.mkdir(exist_ok=True)

_TASKS: dict[str, dict] = {}

_URL_PATTERNS = {
    "bilibili": re.compile(r"bilibili\.com/video/(BV[a-zA-Z0-9]+)"),
    "youtube": re.compile(r"(?:youtube\.com/watch\?v=|youtu\.be/)([a-zA-Z0-9_-]+)"),
    "douyin": re.compile(r"(?:douyin\.com/video/(\d+)|v\.douyin\.com/(\w+))"),
    "tiktok": re.compile(r"tiktok\.com/@[\w.-]+/video/(\d+)"),
    "xiaohongshu": re.compile(r"(?:xhslink\.com/(\w+)|xiaohongshu\.com/explore/(\w+))"),
}


class VideoTask(Base):
    __tablename__ = "video_tasks"

    id = Column(String, primary_key=True, default=generate_uuid)
    user_id = Column(String, nullable=False)
    url = Column(Text, nullable=False)
    platform = Column(String, nullable=True)
    title = Column(Text, nullable=True)
    status = Column(String, default="pending")
    progress = Column(Float, default=0.0)
    file_id = Column(String, nullable=True)
    error = Column(Text, nullable=True)
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())


class ParseRequest(BaseModel):
    url: str


class DownloadRequest(BaseModel):
    url: str


class ParseResponse(BaseModel):
    platform: str
    title: str
    thumbnail_url: Optional[str] = None
    duration: Optional[float] = None
    has_subtitles: bool = False


def _detect_platform(url: str) -> Optional[str]:
    for platform, pattern in _URL_PATTERNS.items():
        if pattern.search(url):
            return platform
    return None


def _hash_url(url: str) -> str:
    return hashlib.md5(url.encode()).hexdigest()[:12]


async def _run_yt_dlp(args: list[str], timeout: int = 300) -> tuple[int, str, str]:
    try:
        process = await asyncio.create_subprocess_exec(
            _YT_DLP_PYTHON, "-m", "yt_dlp", *args,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )
    except FileNotFoundError:
        return -1, "", "yt-dlp is not installed. Run: pip install yt-dlp"
    except Exception as e:
        return -1, "", f"Failed to start yt-dlp: {e}"

    try:
        stdout, stderr = await asyncio.wait_for(
            process.communicate(), timeout=timeout
        )
        rc = process.returncode
        if rc is None:
            rc = -1
        return rc, stdout.decode(errors="replace"), stderr.decode(errors="replace")
    except asyncio.TimeoutError:
        process.kill()
        return -1, "", "Request timed out"


@router.post("/parse", response_model=ParseResponse)
async def parse_video(req: ParseRequest, user: Optional[str] = Depends(get_optional_user)):
    platform = _detect_platform(req.url)
    if not platform:
        raise HTTPException(
            status_code=400,
            detail="Unsupported URL format. Please paste a link from Bilibili, YouTube, Douyin, TikTok, or Xiaohongshu.",
        )

    _code, stdout, stderr = await _run_yt_dlp(
        ["--dump-json", "--no-playlist", "--no-warnings", req.url], timeout=30
    )

    try:
        info = json.loads(stdout)
    except json.JSONDecodeError:
        raise HTTPException(
            status_code=400,
            detail=f"Failed to parse video: {stderr[:200]}" if stderr else "No video metadata found",
        )

    has_subtitles = bool(info.get("subtitles") or info.get("automatic_captions"))

    return ParseResponse(
        platform=platform,
        title=info.get("title", "Unknown"),
        thumbnail_url=info.get("thumbnail"),
        duration=info.get("duration"),
        has_subtitles=has_subtitles,
    )


@router.post("/download")
async def download_video(req: DownloadRequest, user: Optional[str] = Depends(get_optional_user)):
    platform = _detect_platform(req.url)
    if not platform:
        raise HTTPException(status_code=400, detail="Unsupported URL format")

    task_id = str(uuid.uuid4())
    file_id = _hash_url(req.url)
    output_dir = _MEDIA_DIR / file_id
    output_dir.mkdir(exist_ok=True)

    _TASKS[task_id] = {
        "status": "downloading",
        "progress": 0.0,
        "file_id": file_id,
        "platform": platform,
    }

    asyncio.create_task(_do_download(task_id, req.url, output_dir, file_id))

    return {"task_id": task_id, "status": "downloading"}


async def _do_download(task_id: str, url: str, output_dir: Path, file_id: str):
    try:
        output_template = str(output_dir / "%(title)s.%(ext)s")
        code, stdout, stderr = await _run_yt_dlp([
            "-f", "bestvideo[height<=720]+bestaudio/best[height<=720]/best",
            "-o", output_template,
            "--continue",
            "--write-subs",
            "--write-auto-subs",
            "--sub-lang", "en,zh-Hans,zh",
            "--convert-subs", "srt",
            "--no-playlist",
            "--js-runtimes", "node",
            "--extractor-args", "youtube:player_client=android",
            url,
        ], timeout=600)

        if code != 0:
            _TASKS[task_id] = {"status": "failed", "error": stderr[:500]}
            return

        video_files = list(output_dir.glob("*.mp4")) + list(output_dir.glob("*.mkv")) + list(output_dir.glob("*.webm"))
        subtitle_files = list(output_dir.glob("*.srt")) + list(output_dir.glob("*.vtt")) + list(output_dir.glob("*.ass"))

        _TASKS[task_id] = {
            "status": "done",
            "progress": 1.0,
            "file_id": file_id,
            "video_path": str(video_files[0]) if video_files else None,
            "subtitle_paths": [str(f) for f in subtitle_files],
            "video_count": len(video_files),
            "subtitle_count": len(subtitle_files),
        }
    except Exception as e:
        _TASKS[task_id] = {"status": "failed", "error": str(e)[:500]}


@router.get("/progress/{task_id}")
async def get_progress(task_id: str):
    if task_id not in _TASKS:
        raise HTTPException(status_code=404, detail="Task not found")
    return _TASKS[task_id]


@router.get("/progress/{task_id}/stream")
async def stream_progress(task_id: str):
    async def event_stream():
        while True:
            if task_id in _TASKS:
                task = _TASKS[task_id]
                yield f"data: {json.dumps(task)}\n\n"
                if task["status"] in ("done", "failed"):
                    break
            await asyncio.sleep(1)
    return StreamingResponse(event_stream(), media_type="text/event-stream")


@router.get("/files/{file_id}/subtitle/{index}")
async def get_subtitle(file_id: str, index: int):
    output_dir = _MEDIA_DIR / file_id
    if not output_dir.exists():
        raise HTTPException(status_code=404, detail="Files not found")

    subtitle_files = (
        list(output_dir.glob("*.srt"))
        + list(output_dir.glob("*.vtt"))
        + list(output_dir.glob("*.ass"))
    )

    if index < 0 or index >= len(subtitle_files):
        raise HTTPException(status_code=404, detail="Subtitle file not found")

    file_path = subtitle_files[index]
    content = file_path.read_text(encoding="utf-8")
    return {
        "name": file_path.name,
        "content": content,
        "extension": file_path.suffix,
    }


@router.get("/files/{file_id}/stream")
async def stream_media(file_id: str):
    output_dir = _MEDIA_DIR / file_id
    if not output_dir.exists():
        raise HTTPException(status_code=404, detail="Files not found")

    video_files = (
        list(output_dir.glob("*.mp4"))
        + list(output_dir.glob("*.mkv"))
        + list(output_dir.glob("*.webm"))
    )

    if not video_files:
        raise HTTPException(status_code=404, detail="No video file found")

    file_path = video_files[0]
    return FileResponse(
        file_path,
        media_type="video/mp4",
        filename=file_path.name,
    )