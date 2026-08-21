from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel
from sqlalchemy import select, delete
from sqlalchemy.ext.asyncio import AsyncSession

from database import Favorite, get_db, generate_uuid
from middleware.auth import get_current_user

router = APIRouter(prefix="/api/favorites", tags=["favorites"])


class FavoriteCreate(BaseModel):
    type: str
    text: str
    context: Optional[str] = None
    cefr_level: Optional[str] = None
    media_time: Optional[float] = None
    cue_id: Optional[str] = None


class FavoriteBatchCreate(BaseModel):
    items: list[FavoriteCreate]


class FavoriteResponse(BaseModel):
    id: str
    type: str
    text: str
    context: Optional[str] = None
    cefr_level: Optional[str] = None
    media_time: Optional[float] = None
    cue_id: Optional[str] = None
    created_at: datetime
    updated_at: datetime


@router.get("", response_model=list[FavoriteResponse])
async def list_favorites(
    type_filter: Optional[str] = Query(None, alias="type"),
    level_filter: Optional[str] = Query(None, alias="level"),
    user_id: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    query = select(Favorite).where(Favorite.user_id == user_id)
    if type_filter:
        query = query.where(Favorite.type == type_filter)
    if level_filter:
        query = query.where(Favorite.cefr_level == level_filter)

    query = query.order_by(Favorite.created_at.desc())
    result = await db.execute(query)
    rows = result.scalars().all()
    return [FavoriteResponse.model_validate(r) for r in rows]


@router.post("", response_model=FavoriteResponse, status_code=status.HTTP_201_CREATED)
async def create_favorite(
    item: FavoriteCreate,
    user_id: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    existing = await db.execute(
        select(Favorite).where(
            Favorite.user_id == user_id,
            Favorite.cue_id == item.cue_id,
            Favorite.cue_id.isnot(None),
        )
    )
    if existing.scalar_one_or_none() is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Favorite already exists for this cue",
        )

    fav = Favorite(
        id=generate_uuid(),
        user_id=user_id,
        type=item.type,
        text=item.text,
        context=item.context,
        cefr_level=item.cefr_level,
        media_time=item.media_time,
        cue_id=item.cue_id,
    )
    db.add(fav)
    await db.commit()
    await db.refresh(fav)
    return FavoriteResponse.model_validate(fav)


@router.delete("/{favorite_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_favorite(
    favorite_id: str,
    user_id: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        delete(Favorite).where(
            Favorite.id == favorite_id,
            Favorite.user_id == user_id,
        )
    )
    await db.commit()
    if result.rowcount == 0:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Favorite not found",
        )