import hashlib
import json
import os
import subprocess
import tempfile
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Optional

import httpx
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from config import settings
from database import AiCache, get_db
from middleware.auth import get_current_user

router = APIRouter(prefix="/api/ai", tags=["ai"])

_transcription_in_progress = False

_CACHE_DIR = Path(__file__).resolve().parent.parent / "ai_subtitles"
_CACHE_DIR.mkdir(exist_ok=True)


class TranslateRequest(BaseModel):
    text: str
    source_lang: str = "en"
    target_lang: str = "zh"


class TranslateResponse(BaseModel):
    translation: str
    cached: bool = False


class CollocationRequest(BaseModel):
    text: str


class CollocationItem(BaseModel):
    text: str
    type: str
    meaning: Optional[str] = None
    start_index: int = 0
    end_index: int = 0


class CollocationResponse(BaseModel):
    collocations: list[CollocationItem]


class ClozeRequest(BaseModel):
    collocation: str
    original_sentence: str


class ClozeResponse(BaseModel):
    cloze_sentence: str
    hint: Optional[str] = None


class ExampleSentence(BaseModel):
    sentence_en: str
    sentence_zh: str


class ExamplesRequest(BaseModel):
    word: str
    meaning: Optional[str] = None
    count: int = 3


class ExamplesResponse(BaseModel):
    examples: list[ExampleSentence]
    cached: bool = False


class WordLookupRequest(BaseModel):
    word: str


class WordSense(BaseModel):
    definition_en: str
    definition_zh: str


class WordExample(BaseModel):
    sentence_en: str
    sentence_zh: str


class WordCollocation(BaseModel):
    phrase: str
    meaning: str


class ConfusableWord(BaseModel):
    word: str
    meaning: str
    difference: str


class WordLookupResponse(BaseModel):
    word: str
    phonetic_us: str
    senses: list[WordSense]
    examples: list[WordExample]
    collocations: list[WordCollocation]
    confusable_words: list[ConfusableWord]
    cached: bool = False


class TranscribeRequest(BaseModel):
    media_path: str


class TranscribeResponse(BaseModel):
    srt_content: str
    cached: bool = False


class SubtitleCacheResponse(BaseModel):
    cached: bool
    srt_content: Optional[str] = None


def _media_cache_key(media_path: str) -> str:
    try:
        stat = os.stat(media_path)
        raw = f"{media_path}:{stat.st_size}:{stat.st_mtime}"
    except OSError:
        raw = media_path
    return hashlib.md5(raw.encode()).hexdigest()


def _get_cache_path(cache_key: str) -> Path:
    return _CACHE_DIR / f"{cache_key}.srt"


def _extract_audio(media_path: str) -> str:
    output_path = tempfile.mktemp(suffix=".mp3")
    cmd = [
        "ffmpeg", "-y", "-i", media_path,
        "-vn", "-acodec", "libmp3lame",
        "-ar", "16000", "-ac", "1", "-b:a", "32k",
        output_path,
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(f"Audio extraction failed: {result.stderr[:500]}")
    return output_path


def _parse_whisper_to_srt(data: dict) -> str:
    segments = data.get("segments", [])
    if not segments:
        text = data.get("text", "")
        return f"1\n00:00:00,000 --> 00:00:05,000\n{text.strip()}\n"

    lines = []
    for i, seg in enumerate(segments, 1):
        start_s = seg.get("start", 0.0)
        end_s = seg.get("end", 0.0)
        text = seg.get("text", "").strip()
        if not text:
            continue

        def _fmt(seconds: float) -> str:
            h = int(seconds // 3600)
            m = int((seconds % 3600) // 60)
            s = int(seconds % 60)
            ms = int((seconds % 1) * 1000)
            return f"{h:02d}:{m:02d}:{s:02d},{ms:03d}"

        lines.append(f"{i}\n{_fmt(start_s)} --> {_fmt(end_s)}\n{text}\n")

    return "\n".join(lines)


async def _call_groq_whisper(audio_path: str) -> dict:
    if not settings.groq_api_key:
        raise RuntimeError("GROQ_API_KEY not configured")

    async with httpx.AsyncClient(timeout=300.0) as client:
        with open(audio_path, "rb") as f:
            resp = await client.post(
                "https://api.groq.com/openai/v1/audio/transcriptions",
                headers={"Authorization": f"Bearer {settings.groq_api_key}"},
                files={"file": (os.path.basename(audio_path), f, "audio/mpeg")},
                data={"model": "whisper-large-v3", "response_format": "verbose_json"},
            )
        if resp.status_code != 200:
            raise RuntimeError(f"Groq Whisper failed: {resp.status_code} {resp.text[:500]}")
        return resp.json()


def _cache_key(task_type: str, text: str) -> str:
    return hashlib.md5(f"{task_type}:{text}".encode()).hexdigest()


async def _check_cache(db: AsyncSession, task_type: str, text: str) -> Optional[str]:
    key = _cache_key(task_type, text)
    result = await db.execute(
        select(AiCache).where(AiCache.cache_key == key).where(AiCache.expires_at > func.now())
    )
    cached = result.scalar_one_or_none()
    if cached:
        return cached.response
    return None


async def _write_cache(db: AsyncSession, task_type: str, text: str, response: str):
    key = _cache_key(task_type, text)
    cache = AiCache(
        cache_key=key,
        task_type=task_type,
        input_hash=hashlib.md5(text.encode()).hexdigest(),
        response=response,
        expires_at=datetime.now(timezone.utc) + timedelta(hours=24),
    )
    db.add(cache)
    await db.commit()


async def _call_ollama(prompt: str, system_prompt: str = "") -> Optional[str]:
    if not settings.ollama_base_url:
        return None
    try:
        async with httpx.AsyncClient(timeout=60.0) as client:
            resp = await client.post(
                f"{settings.ollama_base_url}/v1/chat/completions",
                json={
                    "model": settings.ollama_model,
                    "messages": [
                        {"role": "system", "content": system_prompt},
                        {"role": "user", "content": prompt},
                    ],
                    "temperature": 0.3,
                },
            )
            if resp.status_code == 200:
                data = resp.json()
                msg = data["choices"][0]["message"]
                content = (msg.get("content") or "").strip()
                if not content:
                    content = (msg.get("reasoning") or "").strip()
                if content:
                    return content
            print(f"[Ollama] status={resp.status_code}, body={resp.text[:200]}")
    except Exception as e:
        print(f"[Ollama] error: {e}")
    return None


async def _call_gemini(prompt: str, system_prompt: str = "") -> Optional[str]:
    if not settings.gemini_api_key:
        return None
    try:
        async with httpx.AsyncClient(timeout=60.0) as client:
            resp = await client.post(
                f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key={settings.gemini_api_key}",
                json={
                    "system_instruction": {"parts": [{"text": system_prompt}]},
                    "contents": [{"parts": [{"text": prompt}]}],
                },
            )
            if resp.status_code == 200:
                data = resp.json()
                return data["candidates"][0]["content"]["parts"][0]["text"].strip()
    except Exception:
        pass
    return None


async def _call_deepseek(prompt: str, system_prompt: str = "") -> Optional[str]:
    if not settings.deepseek_api_key:
        return None
    try:
        async with httpx.AsyncClient(timeout=60.0) as client:
            resp = await client.post(
                "https://api.deepseek.com/v1/chat/completions",
                headers={"Authorization": f"Bearer {settings.deepseek_api_key}"},
                json={
                    "model": "deepseek-chat",
                    "messages": [
                        {"role": "system", "content": system_prompt},
                        {"role": "user", "content": prompt},
                    ],
                    "temperature": 0.3,
                },
            )
            if resp.status_code == 200:
                data = resp.json()
                return data["choices"][0]["message"]["content"].strip()
    except Exception:
        pass
    return None


async def _call_groq(prompt: str, system_prompt: str = "") -> Optional[str]:
    global _transcription_in_progress
    if _transcription_in_progress or not settings.groq_api_key:
        return None
    try:
        async with httpx.AsyncClient(timeout=60.0) as client:
            resp = await client.post(
                "https://api.groq.com/openai/v1/chat/completions",
                headers={"Authorization": f"Bearer {settings.groq_api_key}"},
                json={
                    "model": "llama-3.3-70b-versatile",
                    "messages": [
                        {"role": "system", "content": system_prompt},
                        {"role": "user", "content": prompt},
                    ],
                    "temperature": 0.3,
                },
            )
            if resp.status_code == 200:
                data = resp.json()
                return data["choices"][0]["message"]["content"].strip()
    except Exception:
        pass
    return None


async def _call_mlx(prompt: str, system_prompt: str = "") -> Optional[str]:
    if not settings.mlx_base_url:
        return None
    try:
        async with httpx.AsyncClient(timeout=60.0, trust_env=False) as client:
            resp = await client.post(
                f"{settings.mlx_base_url}/v1/chat/completions",
                json={
                    "model": settings.mlx_model,
                    "messages": [
                        {"role": "system", "content": system_prompt},
                        {"role": "user", "content": prompt},
                    ],
                    "temperature": 0.3,
                    "max_tokens": 1024,
                },
            )
            if resp.status_code == 200:
                data = resp.json()
                return data["choices"][0]["message"]["content"].strip()
            print(f"[MLX] status={resp.status_code}, body={resp.text[:200]}")
    except Exception as e:
        print(f"[MLX] error: {e}")
    return None


async def _call_ai_fallback(prompt: str, system_prompt: str = "") -> Optional[str]:
    result = await _call_ollama(prompt, system_prompt)
    if result:
        return result

    result = await _call_mlx(prompt, system_prompt)
    if result:
        return result

    result = await _call_gemini(prompt, system_prompt)
    if result:
        return result

    result = await _call_deepseek(prompt, system_prompt)
    if result:
        return result

    result = await _call_groq(prompt, system_prompt)
    if result:
        return result

    return None


@router.post("/translate", response_model=TranslateResponse)
async def translate(
    req: TranslateRequest,
    user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if len(req.text) > 5000:
        raise HTTPException(status_code=400, detail="Input text too long. Maximum 5000 characters.")

    cached = await _check_cache(db, "translate", req.text)
    if cached:
        return TranslateResponse(translation=cached, cached=True)

    system_prompt = "You are a translator. Translate the given text accurately while preserving the original tone and style."
    prompt = f"Translate the following English text to Chinese. Only return the translation, nothing else.\n\n{req.text}"

    result = await _call_ai_fallback(prompt, system_prompt)
    if not result:
        raise HTTPException(status_code=503, detail="AI_SERVICE_UNAVAILABLE")

    await _write_cache(db, "translate", req.text, result)
    return TranslateResponse(translation=result, cached=False)


@router.post("/detect-collocations", response_model=CollocationResponse)
async def detect_collocations(
    req: CollocationRequest,
    user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if len(req.text) > 5000:
        raise HTTPException(status_code=400, detail="Input text too long.")

    cached = await _check_cache(db, "collocations", req.text)
    if cached:
        return CollocationResponse(collocations=json.loads(cached))

    system_prompt = "You are an English teacher. Identify common collocations and fixed expressions in the given text."
    prompt = (
        f'Identify collocations (phrasal verbs, idioms, fixed expressions) in this text.\n'
        f'Return ONLY a JSON array: [{{"text":"...","type":"phrasalVerb|idiom|collocation","meaning":"...",'
        f'"startIndex":N,"endIndex":N}}]\n\n'
        f'Text: {req.text}'
    )

    result = await _call_ai_fallback(prompt, system_prompt)
    if not result:
        raise HTTPException(status_code=503, detail="AI_SERVICE_UNAVAILABLE")

    try:
        json_match = result
        if "```" in json_match:
            json_match = json_match.split("```")[1]
            if json_match.startswith("json"):
                json_match = json_match[4:]
        collocations = json.loads(json_match.strip())
        await _write_cache(db, "collocations", req.text, json.dumps(collocations))
        return CollocationResponse(collocations=collocations)
    except (json.JSONDecodeError, KeyError):
        raise HTTPException(status_code=500, detail="AI_RESPONSE_PARSE_ERROR")


@router.post("/generate-cloze", response_model=ClozeResponse)
async def generate_cloze(
    req: ClozeRequest,
    user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    cache_text = f"{req.collocation}|{req.original_sentence}"
    cached = await _check_cache(db, "cloze", cache_text)
    if cached:
        data = json.loads(cached)
        return ClozeResponse(**data)

    system_prompt = "You are an English teacher. Create cloze (fill-in-the-blank) exercises."
    prompt = (
        f'Create a cloze exercise for the collocation "{req.collocation}" in this sentence.\n'
        f'Replace the collocation with "______" and provide a hint.\n'
        f'Return ONLY JSON: {{"clozeSentence":"...","hint":"..."}}\n\n'
        f'Sentence: {req.original_sentence}'
    )

    result = await _call_ai_fallback(prompt, system_prompt)
    if not result:
        raise HTTPException(status_code=503, detail="AI_SERVICE_UNAVAILABLE")

    try:
        json_match = result
        if "```" in json_match:
            json_match = json_match.split("```")[1]
            if json_match.startswith("json"):
                json_match = json_match[4:]
        data = json.loads(json_match.strip())
        await _write_cache(db, "cloze", cache_text, json.dumps(data))
        return ClozeResponse(**data)
    except (json.JSONDecodeError, KeyError):
        raise HTTPException(status_code=500, detail="AI_RESPONSE_PARSE_ERROR")


@router.post("/generate-examples", response_model=ExamplesResponse)
async def generate_examples(
    req: ExamplesRequest,
    user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    word = req.word.strip().lower()
    if not word or len(word) > 100:
        raise HTTPException(status_code=400, detail="Invalid word.")

    cache_key = f"{word}|{req.meaning or ''}|{req.count}"
    cached = await _check_cache(db, "examples", cache_key)
    if cached:
        data = json.loads(cached)
        return ExamplesResponse(examples=[ExampleSentence(**e) for e in data], cached=True)

    meaning_hint = f' (meaning: {req.meaning})' if req.meaning else ''
    system_prompt = "You are an English teacher. Generate natural example sentences."
    prompt = (
        f'Generate {req.count} example sentences for the word "{word}"{meaning_hint}.\n'
        f'Each example should show the word in a different, natural context.\n'
        f'Return ONLY JSON: {{"examples":[{{"sentence_en":"...","sentence_zh":"..."}}]}}\n'
        f'IMPORTANT: sentence_en in English, sentence_zh in Chinese. '
        f'Do NOT mark the word or wrap it in quotes or brackets.'
    )

    result = await _call_ai_fallback(prompt, system_prompt)
    if not result:
        raise HTTPException(status_code=503, detail="AI_SERVICE_UNAVAILABLE")

    try:
        json_match = result
        if "```" in json_match:
            json_match = json_match.split("```")[1]
            if json_match.startswith("json"):
                json_match = json_match[4:]
        data = json.loads(json_match.strip())
        examples = [ExampleSentence(**e) for e in data["examples"]]
        await _write_cache(db, "examples", cache_key, json.dumps([e.model_dump() for e in examples]))
        return ExamplesResponse(examples=examples, cached=False)
    except (json.JSONDecodeError, KeyError) as e:
        raise HTTPException(status_code=500, detail=f"AI_RESPONSE_PARSE_ERROR: {str(e)}")


@router.post("/lookup-word", response_model=WordLookupResponse)
async def lookup_word(
    req: WordLookupRequest,
    user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    word = req.word.strip().lower()
    if not word or len(word) > 100:
        raise HTTPException(status_code=400, detail="Invalid word.")

    cached = await _check_cache(db, "lookup_word", word)
    if cached:
        data = json.loads(cached)
        data["cached"] = True
        return WordLookupResponse(**data)

    system_prompt = (
        "You are an expert English lexicographer. "
        "You MUST return ONLY a valid JSON object. No markdown, no explanation, no code blocks."
    )

    prompt = (
        f'Word to analyze: "{req.word}"\n\n'
        f'Return a JSON object with these fields. '
        f'Fields ending in _en must be in English. '
        f'Fields ending in _zh must be in Chinese. '
        f'Fields named "meaning" and "difference" must be in Chinese.\n\n'
        f'JSON structure:\n'
        f'{{\n'
        f'  "word": "{req.word}",\n'
        f'  "phonetic_us": "IPA notation",\n'
        f'  "senses": [\n'
        f'    {{"definition_en": "English definition using simple words", '
        f'"definition_zh": "Chinese definition"}}\n'
        f'  ],\n'
        f'  "examples": [\n'
        f'    {{"sentence_en": "English example sentence", '
        f'"sentence_zh": "Chinese example sentence"}}\n'
        f'  ],\n'
        f'  "collocations": [\n'
        f'    {{"phrase": "English collocation", "meaning": "Chinese meaning"}}\n'
        f'  ],\n'
        f'  "confusable_words": [\n'
        f'    {{"word": "English similar word", "meaning": "Chinese meaning", '
        f'"difference": "Chinese explanation"}}\n'
        f'  ]\n'
        f'}}\n\n'
        f'IMPORTANT RULES:\n'
        f'1. definition_en, sentence_en, phrase, word: Write in ENGLISH only\n'
        f'2. definition_zh, sentence_zh, meaning, difference: Write in Chinese only\n'
        f'3. Use A1-level simple English words for definition_en\n'
        f'4. Use standard US IPA for phonetic_us\n'
        f'5. Provide 1-3 senses, 2 examples, 2-3 collocations, 1-2 confusable words\n'
        f'6. Return ONLY the JSON object, nothing else'
    )

    result = await _call_ai_fallback(prompt, system_prompt)
    if not result:
        raise HTTPException(status_code=503, detail="AI_SERVICE_UNAVAILABLE")

    try:
        json_match = result
        if "<|im_end|>" in json_match:
            json_match = json_match.split("<|im_end|>")[0]
        if "```" in json_match:
            json_match = json_match.split("```")[1]
            if json_match.startswith("json"):
                json_match = json_match[4:]
        json_match = json_match.strip()
        start = json_match.find("{")
        end = json_match.rfind("}")
        if start != -1 and end != -1:
            json_match = json_match[start:end + 1]
        data = json.loads(json_match)
        await _write_cache(db, "lookup_word", word, json.dumps(data))
        return WordLookupResponse(**data)
    except (json.JSONDecodeError, KeyError) as e:
        raise HTTPException(status_code=500, detail=f"AI_RESPONSE_PARSE_ERROR: {str(e)}")


@router.get("/subtitle-cache", response_model=SubtitleCacheResponse)
async def check_subtitle_cache(
    media_path: str,
    user: dict = Depends(get_current_user),
):
    cache_key = _media_cache_key(media_path)
    cache_path = _get_cache_path(cache_key)
    if cache_path.exists():
        srt_content = cache_path.read_text(encoding="utf-8")
        return SubtitleCacheResponse(cached=True, srt_content=srt_content)
    return SubtitleCacheResponse(cached=False)


@router.post("/transcribe", response_model=TranscribeResponse)
async def transcribe_audio(
    req: TranscribeRequest,
    user: dict = Depends(get_current_user),
):
    global _transcription_in_progress

    if not os.path.isfile(req.media_path):
        raise HTTPException(status_code=400, detail="Media file not found")

    cache_key = _media_cache_key(req.media_path)
    cache_path = _get_cache_path(cache_key)

    if cache_path.exists():
        srt_content = cache_path.read_text(encoding="utf-8")
        return TranscribeResponse(srt_content=srt_content, cached=True)

    if not settings.groq_api_key:
        raise HTTPException(
            status_code=503,
            detail="GROQ_API_KEY not configured. Set it in .env to enable AI transcription.",
        )

    audio_path = None
    try:
        _transcription_in_progress = True
        audio_path = _extract_audio(req.media_path)
        data = await _call_groq_whisper(audio_path)
        srt_content = _parse_whisper_to_srt(data)
        cache_path.write_text(srt_content, encoding="utf-8")
        return TranscribeResponse(srt_content=srt_content, cached=False)
    except RuntimeError as e:
        raise HTTPException(status_code=503, detail=str(e))
    finally:
        _transcription_in_progress = False
        if audio_path and os.path.isfile(audio_path):
            try:
                os.unlink(audio_path)
            except OSError:
                pass


class TutorChatRequest(BaseModel):
    question: str
    context_subtitles: list[str] = []
    current_subtitle: str = ""


class TutorChatResponse(BaseModel):
    answer: str
    cached: bool = False


class MistakeItem(BaseModel):
    expected: str
    typed: str
    accuracy: float


class AnalyzeMistakesRequest(BaseModel):
    mistakes: list[MistakeItem]


class MistakePattern(BaseModel):
    type: str
    description: str
    examples: list[str]


class AnalyzeMistakesResponse(BaseModel):
    patterns: list[MistakePattern]
    suggestions: list[str]
    cached: bool = False


class GenerateDictationRequest(BaseModel):
    source_sentences: list[str] = []
    weak_patterns: list[str] = []
    count: int = 5


class DictationSentence(BaseModel):
    text: str
    focus_pattern: str


class GenerateDictationResponse(BaseModel):
    sentences: list[DictationSentence]
    cached: bool = False


@router.post("/tutor-chat", response_model=TutorChatResponse)
async def tutor_chat(
    req: TutorChatRequest,
    user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if len(req.question) > 2000:
        raise HTTPException(status_code=400, detail="Question too long. Maximum 2000 characters.")

    cache_text = f"{req.question}|{req.current_subtitle}"
    cached = await _check_cache(db, "tutor_chat", cache_text)
    if cached:
        return TutorChatResponse(answer=cached, cached=True)

    system_prompt = (
        "You are a friendly, patient English tutor sitting next to a student who is watching "
        "a video in English. The student can ask you anything about the subtitles they see: "
        "grammar, vocabulary, pronunciation, cultural context, idioms, or anything else.\n\n"
        "Rules:\n"
        "1. Answer in Chinese (the student's native language), but use English for examples\n"
        "2. Be concise but thorough — aim for 2-5 sentences\n"
        "3. When explaining grammar, give clear examples from the provided context\n"
        "4. When explaining vocabulary, give the word's meaning, usage, and 1-2 examples\n"
        "5. Be encouraging and supportive\n"
        "6. If the question is unclear, ask for clarification\n"
        "7. If asked about pronunciation, explain using IPA and Chinese approximations"
    )

    context_lines = req.context_subtitles + [req.current_subtitle]
    context_text = "\n".join(f"[{i}]: {line}" for i, line in enumerate(context_lines) if line)

    prompt = (
        f"The student is watching a video. Here are the surrounding subtitles:\n\n"
        f"{context_text}\n\n"
        f"The student asks: {req.question}\n\n"
        f"Please answer helpfully."
    )

    result = await _call_ai_fallback(prompt, system_prompt)
    if not result:
        raise HTTPException(status_code=503, detail="AI_SERVICE_UNAVAILABLE")

    await _write_cache(db, "tutor_chat", cache_text, result)
    return TutorChatResponse(answer=result, cached=False)


@router.post("/analyze-mistakes", response_model=AnalyzeMistakesResponse)
async def analyze_mistakes(
    req: AnalyzeMistakesRequest,
    user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if not req.mistakes:
        raise HTTPException(status_code=400, detail="No mistakes provided.")

    mistakes_json = json.dumps([m.model_dump() for m in req.mistakes])
    cache_text = mistakes_json
    cached = await _check_cache(db, "analyze_mistakes", cache_text)
    if cached:
        data = json.loads(cached)
        return AnalyzeMistakesResponse(**data)

    system_prompt = (
        "You are an expert English teacher analyzing a student's dictation mistakes. "
        "Identify patterns in their errors and provide actionable suggestions.\n\n"
        "Return ONLY valid JSON, no markdown, no explanation:\n"
        '{"patterns": [{"type": "pattern type", "description": "detailed description", '
        '"examples": ["example1", "example2"]}], '
        '"suggestions": ["suggestion1", "suggestion2"]}\n\n'
        "Pattern types to look for:\n"
        "- missing_prepositions: student omits prepositions (in, on, at, to, for)\n"
        "- missing_articles: student omits a/an/the\n"
        "- verb_tense: wrong verb tense (past/present/future)\n"
        "- plural_singular: wrong plural/singular form\n"
        "- spelling: consistent spelling errors\n"
        "- word_order: wrong word order\n"
        "- missing_words: student skips content words\n"
        "- extra_words: student adds unnecessary words\n"
        "- homophone: confuses similar-sounding words (their/there, your/you're)\n"
        "- contraction: misses or adds contractions (don't/do not, it's/its)\n\n"
        "If no clear pattern is found, return empty arrays. "
        "Suggestions should be in Chinese, actionable and specific."
    )

    prompt = (
        f"Analyze these dictation mistakes:\n\n"
        f"{mistakes_json}\n\n"
        f"Identify the top 2-3 error patterns and provide 3-5 actionable suggestions."
    )

    result = await _call_ai_fallback(prompt, system_prompt)
    if not result:
        raise HTTPException(status_code=503, detail="AI_SERVICE_UNAVAILABLE")

    try:
        json_match = result
        if "```" in json_match:
            json_match = json_match.split("```")[1]
            if json_match.startswith("json"):
                json_match = json_match[4:]
        data = json.loads(json_match.strip())
        await _write_cache(db, "analyze_mistakes", cache_text, json.dumps(data))
        return AnalyzeMistakesResponse(**data)
    except (json.JSONDecodeError, KeyError):
        raise HTTPException(status_code=500, detail="AI_RESPONSE_PARSE_ERROR")


@router.post("/generate-dictation", response_model=GenerateDictationResponse)
async def generate_dictation(
    req: GenerateDictationRequest,
    user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if req.count < 1 or req.count > 20:
        raise HTTPException(status_code=400, detail="Count must be between 1 and 20.")

    cache_key_parts = json.dumps({
        "sentences": req.source_sentences[:5],
        "patterns": req.weak_patterns,
        "count": req.count,
    })
    cached = await _check_cache(db, "generate_dictation", cache_key_parts)
    if cached:
        data = json.loads(cached)
        return GenerateDictationResponse(**data)

    system_prompt = (
        "You are an English teacher creating personalized dictation exercises. "
        "Generate sentences that target the student's weak areas. "
        "Use vocabulary similar to the source sentences they've been practicing with.\n\n"
        "Return ONLY valid JSON, no markdown:\n"
        '{"sentences": [{"text": "sentence text", "focus_pattern": "pattern name"}]}\n\n'
        "Rules:\n"
        "1. Each sentence should be 8-20 words long\n"
        "2. Make sentences natural and conversational\n"
        "3. Target the weak patterns specified\n"
        "4. Vary the sentence structures\n"
        "5. Use vocabulary appropriate for the student's level (based on source sentences)"
    )

    source_text = "\n".join(req.source_sentences[:10]) if req.source_sentences else "General English"
    patterns_text = ", ".join(req.weak_patterns) if req.weak_patterns else "general practice"

    prompt = (
        f"Source sentences the student has been practicing:\n{source_text}\n\n"
        f"Weak patterns to focus on: {patterns_text}\n\n"
        f"Generate {req.count} dictation sentences targeting these weaknesses."
    )

    result = await _call_ai_fallback(prompt, system_prompt)
    if not result:
        raise HTTPException(status_code=503, detail="AI_SERVICE_UNAVAILABLE")

    try:
        json_match = result
        if "```" in json_match:
            json_match = json_match.split("```")[1]
            if json_match.startswith("json"):
                json_match = json_match[4:]
        data = json.loads(json_match.strip())
        await _write_cache(db, "generate_dictation", cache_key_parts, json.dumps(data))
        return GenerateDictationResponse(**data)
    except (json.JSONDecodeError, KeyError):
        raise HTTPException(status_code=500, detail="AI_RESPONSE_PARSE_ERROR")


class EvaluateChunkLine(BaseModel):
    index: int
    text: str


class EvaluateChunkRequest(BaseModel):
    lines: list[EvaluateChunkLine]


class EvaluateChunkResult(BaseModel):
    index: int
    score: float
    reason: Optional[str] = None
    highlights: list[str] = []
    scenario: Optional[str] = None


class EvaluateChunkResponse(BaseModel):
    results: list[EvaluateChunkResult]
    cached: bool = False


class GenerateMemoRequest(BaseModel):
    text: str
    highlights: list[str] = []


class KeyPhraseResult(BaseModel):
    phrase: str
    meaning: str


class GenerateMemoResponse(BaseModel):
    cloze_text: str
    hint: str
    key_phrases: list[KeyPhraseResult] = []
    usage_note: str = ""
    cached: bool = False


@router.post("/evaluate-chunk", response_model=EvaluateChunkResponse)
async def evaluate_chunk(
    req: EvaluateChunkRequest,
    user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if not req.lines:
        raise HTTPException(status_code=400, detail="No lines provided.")
    if len(req.lines) > 30:
        raise HTTPException(status_code=400, detail="Maximum 30 lines per chunk.")

    combined = json.dumps([l.model_dump() for l in req.lines])
    cached = await _check_cache(db, "evaluate_chunk", combined)
    if cached:
        results = [EvaluateChunkResult(**r) for r in json.loads(cached)]
        return EvaluateChunkResponse(results=results, cached=True)

    system_prompt = (
        "You are an English teacher. Evaluate each subtitle line for memorization value. "
        "Score 1-10 based on: practical daily use, common collocations/idioms, "
        "reusable sentence patterns, and natural authentic expression.\n\n"
        "Return ONLY a JSON array, no markdown, no explanation:\n"
        '[{"index": 0, "score": 8, "reason": "Chinese reason", '
        '"highlights": ["phrase1", "phrase2"], "scenario": "Chinese usage scenario"}]\n\n'
        "Rules:\n"
        "1. index must match the input index exactly\n"
        "2. score: 1-3 for trivial lines (Hello, OK, yes), 4-6 for common but simple, "
        "7-8 for useful everyday expressions, 9-10 for must-learn lines\n"
        "3. reason: brief Chinese explanation (max 30 chars)\n"
        "4. highlights: 1-3 key phrases worth remembering\n"
        "5. scenario: when to use this in real life, in Chinese (max 50 chars)\n"
        "6. If a line is not worth memorizing, return score 1-3 with empty highlights"
    )

    lines_text = "\n".join(f"[{l.index}] {l.text}" for l in req.lines)
    prompt = (
        f"Evaluate these English subtitle lines for memorization value:\n\n"
        f"{lines_text}\n\n"
        f"Return a JSON array with one evaluation per line."
    )

    result = await _call_ai_fallback(prompt, system_prompt)
    if not result:
        raise HTTPException(status_code=503, detail="AI_SERVICE_UNAVAILABLE")

    try:
        json_match = result
        if "<|im_end|>" in json_match:
            json_match = json_match.split("<|im_end|>")[0]
        if "```" in json_match:
            json_match = json_match.split("```")[1]
            if json_match.startswith("json"):
                json_match = json_match[4:]
        json_match = json_match.strip()
        start = json_match.find("[")
        end = json_match.rfind("]")
        if start != -1 and end != -1:
            json_match = json_match[start:end + 1]
        data = json.loads(json_match)
        results = [EvaluateChunkResult(**r) for r in data]
        await _write_cache(db, "evaluate_chunk", combined, json.dumps([r.model_dump() for r in results]))
        return EvaluateChunkResponse(results=results, cached=False)
    except (json.JSONDecodeError, KeyError) as e:
        raise HTTPException(status_code=500, detail=f"AI_RESPONSE_PARSE_ERROR: {str(e)}")


@router.post("/generate-memo-template", response_model=GenerateMemoResponse)
async def generate_memo_template(
    req: GenerateMemoRequest,
    user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if not req.text or len(req.text) > 500:
        raise HTTPException(status_code=400, detail="Invalid text. Max 500 characters.")

    cache_key = f"{req.text}|{','.join(req.highlights)}"
    cached = await _check_cache(db, "memo_template", cache_key)
    if cached:
        data = json.loads(cached)
        return GenerateMemoResponse(**data, cached=True)

    system_prompt = (
        "You are an English teacher creating flashcard templates for Chinese learners of English. "
        "Your goal is to help learners memorize USEFUL PHRASES, not individual words.\n\n"
        "CRITICAL - What is a key phrase worth memorizing:\n"
        "- Phrasal verbs: give up, run into, figure out, turn down, bring up\n"
        "- Collocations: make a decision, heavy rain, bitterly cold, pay attention\n"
        "- Idioms: piece of cake, break the ice, hit the road, once in a blue moon\n"
        "- Fixed expressions: by the way, as a matter of fact, in other words, on the other hand\n"
        "- Compound prepositions: in spite of, due to, according to, regardless of\n"
        "- Useful sentence patterns: not only...but also, the more...the more\n\n"
        "What NOT to blank out:\n"
        "- Single common words (the, hello, yes, car, walk, good) — these are too basic\n"
        "- Articles (a, an, the) or prepositions alone (in, on, at)\n"
        "- Pronouns (I, you, he, she, it, they)\n"
        "- If the sentence has NO useful phrases, set cloze_text same as original and say so in usage_note\n\n"
        "Return ONLY valid JSON, no markdown, no explanation:\n"
        '{"cloze_text": "sentence with ______ replacing the key phrase", '
        '"hint": "Chinese meaning of the blanked phrase (max 20 chars)", '
        '"key_phrases": [{"phrase": "english phrase", "meaning": "Chinese meaning"}], '
        '"usage_note": "Chinese explanation of when to use this sentence (max 80 chars)"}\n\n'
        "Examples of good templates:\n"
        'Input: "I ran into my old friend at the grocery store."\n'
        'Output: {"cloze_text": "I ______ my old friend at the grocery store.", '
        '"hint": "偶遇/撞见", "key_phrases": [{"phrase": "ran into", "meaning": "偶遇，撞见"}], '
        '"usage_note": "ran into 表示偶然遇见某人，是日常口语中非常高频的表达"}\n\n'
        'Input: "Can you figure out what went wrong?"\n'
        'Output: {"cloze_text": "Can you ______ what went wrong?", '
        '"hint": "弄清楚/搞明白", "key_phrases": [{"phrase": "figure out", "meaning": "弄清楚，搞明白"}], '
        '"usage_note": "figure out 表示经过思考后弄明白某事，口语和书面语都很常用"}\n\n'
        'Input: "By the way, have you seen my keys?"\n'
        'Output: {"cloze_text": "______, have you seen my keys?", '
        '"hint": "顺便说一下", "key_phrases": [{"phrase": "by the way", "meaning": "顺便说一下"}], '
        '"usage_note": "by the way 用于转换话题或补充信息，是最常用的口语过渡表达之一"}\n\n'
        "Rules:\n"
        "1. cloze_text: Replace the SINGLE most important phrase/collocation with ______ (exactly 6 underscores)\n"
        "2. hint: Chinese meaning of the blanked phrase (max 20 chars)\n"
        "3. key_phrases: 1-3 useful phrases from the sentence with Chinese meanings\n"
        "4. usage_note: When and how to use this sentence pattern in real life, in Chinese (max 80 chars)\n"
        "5. ALWAYS prioritize phrases/collocations over single words\n"
        "6. If no good phrase exists, return the original text as cloze_text and explain why in usage_note"
    )

    highlights_text = ", ".join(req.highlights) if req.highlights else "auto-detect"
    prompt = (
        f"Create a flashcard template for this English subtitle:\n"
        f'"{req.text}"\n\n'
        f"Known key phrases: {highlights_text}\n\n"
        f"Return the JSON template."
    )

    result = await _call_ai_fallback(prompt, system_prompt)
    if not result:
        raise HTTPException(status_code=503, detail="AI_SERVICE_UNAVAILABLE")

    try:
        json_match = result
        if "<|im_end|>" in json_match:
            json_match = json_match.split("<|im_end|>")[0]
        if "```" in json_match:
            json_match = json_match.split("```")[1]
            if json_match.startswith("json"):
                json_match = json_match[4:]
        json_match = json_match.strip()
        start = json_match.find("{")
        end = json_match.rfind("}")
        if start != -1 and end != -1:
            json_match = json_match[start:end + 1]
        data = json.loads(json_match)
        await _write_cache(db, "memo_template", cache_key, json.dumps(data))
        return GenerateMemoResponse(**data, cached=False)
    except (json.JSONDecodeError, KeyError) as e:
        raise HTTPException(status_code=500, detail=f"AI_RESPONSE_PARSE_ERROR: {str(e)}")


class AnalyzeGrammarRequest(BaseModel):
    text: str


class GrammarPointResult(BaseModel):
    name: str
    explanation: str
    example: str
    related_text: str


class AnalyzeGrammarResponse(BaseModel):
    grammar_points: list[GrammarPointResult] = []
    sentence_structure: str = ""
    sentence_type: str = ""
    tense: str = ""
    difficulty: str = ""
    notes: str = ""
    cached: bool = False


@router.post("/analyze-grammar", response_model=AnalyzeGrammarResponse)
async def analyze_grammar(
    req: AnalyzeGrammarRequest,
    user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if not req.text or len(req.text) > 500:
        raise HTTPException(status_code=400, detail="Invalid text. Max 500 characters.")

    cache_key = req.text
    cached = await _check_cache(db, "analyze_grammar", cache_key)
    if cached:
        data = json.loads(cached)
        return AnalyzeGrammarResponse(**data, cached=True)

    system_prompt = (
        "You are an English grammar teacher analyzing sentences for Chinese learners. "
        "Analyze the given sentence and return the grammar information in JSON format.\n\n"
        "Return ONLY valid JSON, no markdown, no explanation:\n"
        '{"grammar_points": [{"name": "grammar point name (Chinese)", '
        '"explanation": "Chinese explanation (max 100 chars)", '
        '"example": "an example sentence showing this grammar", '
        '"related_text": "the specific part of the input sentence that uses this grammar"}], '
        '"sentence_structure": "Simple/Compound/Complex/Compound-Complex", '
        '"sentence_type": "Declarative/Interrogative/Imperative/Exclamatory", '
        '"tense": "Simple Present/Present Continuous/Present Perfect/Past Simple/etc.", '
        '"difficulty": "A1/A2/B1/B2/C1/C2", '
        '"notes": "Chinese learning tips for this sentence (max 100 chars)"}\n\n'
        "Rules:\n"
        "1. grammar_points: List ALL grammar points found in this sentence (at least 1, max 5)\n"
        "2. name: Use Chinese names like 一般现在时, 被动语态, 定语从句, 虚拟语气, etc.\n"
        "3. explanation: Explain the grammar rule in Chinese, be specific to this sentence\n"
        "4. example: Provide a NEW example sentence (not the input) that demonstrates the same grammar\n"
        "5. related_text: Quote the exact phrase from the input sentence\n"
        "6. sentence_structure: Classify the sentence structure\n"
        "7. sentence_type: Classify the sentence type\n"
        "8. tense: Identify the primary tense used\n"
        "9. difficulty: Estimate the CEFR difficulty level\n"
        "10. notes: Practical tips for Chinese learners about this sentence pattern"
    )

    prompt = (
        f"Analyze the grammar of this English sentence:\n"
        f'"{req.text}"\n\n'
        f"Return the JSON analysis."
    )

    result = await _call_ai_fallback(prompt, system_prompt)
    if not result:
        raise HTTPException(status_code=503, detail="AI_SERVICE_UNAVAILABLE")

    try:
        json_match = result
        if "<|im_end|>" in json_match:
            json_match = json_match.split("<|im_end|>")[0]
        if "```" in json_match:
            json_match = json_match.split("```")[1]
            if json_match.startswith("json"):
                json_match = json_match[4:]
        json_match = json_match.strip()
        start = json_match.find("{")
        end = json_match.rfind("}")
        if start != -1 and end != -1:
            json_match = json_match[start:end + 1]
        data = json.loads(json_match)
        await _write_cache(db, "analyze_grammar", cache_key, json.dumps(data))
        return AnalyzeGrammarResponse(**data, cached=False)
    except (json.JSONDecodeError, KeyError) as e:
        raise HTTPException(status_code=500, detail=f"AI_RESPONSE_PARSE_ERROR: {str(e)}")