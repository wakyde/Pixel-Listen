from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, status
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from database import Flashcard, AnkiImportLog, get_db, generate_uuid
from middleware.auth import get_current_user
from services.anki_parser import parse_apkg, parse_csv_content, map_csv_to_cards

router = APIRouter(prefix="/api/flashcards/import", tags=["anki-import"])


class AnkiImportPreview(BaseModel):
    deck_name: str
    total_cards: int
    preview: list[dict] = []
    media_files: list[str] = []


class CsvImportRequest(BaseModel):
    cards: list[dict]


class ImportResult(BaseModel):
    imported_count: int
    skipped_count: int
    errors: list[str] = []


@router.post("/anki", response_model=AnkiImportPreview)
async def preview_anki_import(
    file: UploadFile = File(...),
    user_id: str = Depends(get_current_user),
):
    if not file.filename or not file.filename.endswith(".apkg"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only .apkg files are supported",
        )

    content = await file.read()
    if len(content) > 200 * 1024 * 1024:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail="File too large. Maximum 200MB.",
        )

    result = parse_apkg(content)

    if result.get("errors") and "Unsupported" in str(result["errors"]):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=result["errors"][0],
        )

    return AnkiImportPreview(
        deck_name=result["deck_name"],
        total_cards=result["total_cards"],
        preview=result["preview"],
        media_files=result["media_files"],
    )


@router.post("/anki/confirm", response_model=ImportResult)
async def confirm_anki_import(
    deck_name: str = Form(""),
    user_id: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return ImportResult(imported_count=0, skipped_count=0)


@router.post("/csv", response_model=ImportResult)
async def import_csv(
    request: CsvImportRequest,
    user_id: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    imported = 0
    skipped = 0
    errors = []

    for card_data in request.cards:
        try:
            front_text = card_data.get("front_text", "")
            back_answer = card_data.get("back_answer", "")

            if not front_text or not back_answer:
                skipped += 1
                continue

            card = Flashcard(
                id=generate_uuid(),
                user_id=user_id,
                front_text=front_text,
                front_hint=card_data.get("front_hint"),
                back_answer=back_answer,
                back_meaning=card_data.get("back_meaning"),
                back_original=card_data.get("back_original"),
                source_title=card_data.get("source_title"),
                tags=card_data.get("tags"),
                ai_generated=False,
            )
            db.add(card)
            imported += 1
        except Exception as e:
            errors.append(str(e)[:200])
            skipped += 1

    log = AnkiImportLog(
        id=generate_uuid(),
        user_id=user_id,
        file_name="csv_import",
        source_type="csv",
        deck_name="CSV Import",
        total_cards=len(request.cards),
        imported_count=imported,
        skipped_count=skipped,
        errors="\n".join(errors) if errors else None,
    )
    db.add(log)
    await db.commit()

    return ImportResult(
        imported_count=imported,
        skipped_count=skipped,
        errors=errors,
    )


@router.get("/history", response_model=list[dict])
async def import_history(
    user_id: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    from sqlalchemy import select
    query = (
        select(AnkiImportLog)
        .where(AnkiImportLog.user_id == user_id)
        .order_by(AnkiImportLog.imported_at.desc())
        .limit(20)
    )
    result = await db.execute(query)
    rows = result.scalars().all()
    return [
        {
            "id": r.id,
            "file_name": r.file_name,
            "source_type": r.source_type,
            "deck_name": r.deck_name,
            "total_cards": r.total_cards,
            "imported_count": r.imported_count,
            "skipped_count": r.skipped_count,
            "imported_at": r.imported_at.isoformat() if r.imported_at else None,
        }
        for r in rows
    ]