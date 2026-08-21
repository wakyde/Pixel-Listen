from datetime import datetime, timezone
from typing import Any, Optional

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from database import (
    Favorite, Flashcard, FlashcardReview, Collocation,
    TypingResult, AbHistory, SyncStatus, get_db,
)
from middleware.auth import get_current_user

router = APIRouter(prefix="/api/sync", tags=["sync"])


class SyncPushItem(BaseModel):
    table: str
    id: str
    data: dict[str, Any]
    updated_at: str


class SyncPushRequest(BaseModel):
    last_synced_at: Optional[str] = None
    items: list[SyncPushItem] = []


class SyncPullResponse(BaseModel):
    server_generation: int
    favorites: list[dict[str, Any]] = []
    flashcards: list[dict[str, Any]] = []
    flashcard_reviews: list[dict[str, Any]] = []
    collocations: list[dict[str, Any]] = []
    typing_results: list[dict[str, Any]] = []
    ab_history: list[dict[str, Any]] = []


_TABLE_MAP = {
    "favorites": Favorite,
    "flashcards": Flashcard,
    "flashcard_reviews": FlashcardReview,
    "collocations": Collocation,
    "typing_results": TypingResult,
    "ab_history": AbHistory,
}


def _model_to_dict(obj) -> dict[str, Any]:
    result = {}
    for col in obj.__table__.columns:
        val = getattr(obj, col.name)
        if isinstance(val, datetime):
            val = val.isoformat()
        result[col.name] = val
    return result


@router.get("/pull", response_model=SyncPullResponse)
async def pull_changes(
    since: Optional[str] = None,
    user_id: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    status_result = await db.execute(
        select(SyncStatus).where(SyncStatus.user_id == user_id)
    )
    sync_status = status_result.scalar_one_or_none()
    server_gen = sync_status.server_generation if sync_status else 0

    since_dt = None
    if since:
        try:
            since_dt = datetime.fromisoformat(since)
        except ValueError:
            pass

    response = SyncPullResponse(server_generation=server_gen)

    for table_name, model in _TABLE_MAP.items():
        if not hasattr(model, "user_id"):
            continue
        query = select(model).where(model.user_id == user_id)
        if since_dt and hasattr(model, "updated_at"):
            query = query.where(model.updated_at > since_dt)
        elif since_dt and hasattr(model, "created_at"):
            query = query.where(model.created_at > since_dt)

        result = await db.execute(query)
        rows = result.scalars().all()
        data = [_model_to_dict(r) for r in rows]
        setattr(response, table_name, data)

    return response


@router.post("/push")
async def push_changes(
    request: SyncPushRequest,
    user_id: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    imported = 0
    for item in request.items:
        model = _TABLE_MAP.get(item.table)
        if model is None:
            continue

        existing = await db.execute(
            select(model).where(model.id == item.id)
        )
        existing_obj = existing.scalar_one_or_none()

        data = {**item.data, "user_id": user_id}
        data.pop("id", None)

        if existing_obj:
            for key, value in data.items():
                if hasattr(existing_obj, key):
                    setattr(existing_obj, key, value)
            if hasattr(existing_obj, "updated_at"):
                existing_obj.updated_at = datetime.now(timezone.utc)
        else:
            obj = model(id=item.id, **data)
            db.add(obj)

        imported += 1

    status_result = await db.execute(
        select(SyncStatus).where(SyncStatus.user_id == user_id)
    )
    sync_status = status_result.scalar_one_or_none()
    if sync_status:
        sync_status.server_generation = (sync_status.server_generation or 0) + 1
        sync_status.last_synced_at = datetime.now(timezone.utc)
    else:
        sync_status = SyncStatus(
            user_id=user_id,
            server_generation=1,
            last_synced_at=datetime.now(timezone.utc),
        )
        db.add(sync_status)

    await db.commit()
    return {"imported": imported, "status": "ok"}