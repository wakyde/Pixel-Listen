from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel
from sqlalchemy import select, delete, func
from sqlalchemy.ext.asyncio import AsyncSession

from database import Flashcard, FlashcardReview, get_db, generate_uuid
from middleware.auth import get_current_user

router = APIRouter(prefix="/api/flashcards", tags=["flashcards"])


class FlashcardCreate(BaseModel):
    front_text: str
    front_hint: Optional[str] = None
    back_answer: str
    back_meaning: Optional[str] = None
    back_original: Optional[str] = None
    media_file_path: Optional[str] = None
    media_file_id: Optional[str] = None
    media_time: Optional[float] = None
    cue_id: Optional[str] = None
    source_title: Optional[str] = None
    tags: Optional[str] = None
    ai_generated: bool = False


class FlashcardUpdate(BaseModel):
    front_text: Optional[str] = None
    front_hint: Optional[str] = None
    back_answer: Optional[str] = None
    back_meaning: Optional[str] = None
    back_original: Optional[str] = None
    tags: Optional[str] = None


class ReviewRequest(BaseModel):
    rating: int


class FlashcardResponse(BaseModel):
    id: str
    front_text: str
    front_hint: Optional[str] = None
    back_answer: str
    back_meaning: Optional[str] = None
    back_original: Optional[str] = None
    media_file_path: Optional[str] = None
    media_file_id: Optional[str] = None
    media_time: Optional[float] = None
    cue_id: Optional[str] = None
    source_title: Optional[str] = None
    tags: Optional[str] = None
    review_count: int
    next_review_at: datetime
    ease_factor: float
    interval: float
    ai_generated: bool
    created_at: datetime
    updated_at: datetime


class FlashcardReviewResponse(BaseModel):
    id: str
    flashcard_id: str
    rating: int
    reviewed_at: datetime


class DueCountResponse(BaseModel):
    due_count: int
    total_count: int


@router.get("", response_model=list[FlashcardResponse])
async def list_flashcards(
    sort_by: Optional[str] = Query(None, description="next_review, created_at, source"),
    tags: Optional[str] = Query(None),
    user_id: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    query = select(Flashcard).where(Flashcard.user_id == user_id)

    if tags:
        query = query.where(Flashcard.tags.contains(tags))

    if sort_by == "next_review":
        query = query.order_by(Flashcard.next_review_at.asc())
    elif sort_by == "source":
        query = query.order_by(Flashcard.source_title.asc())
    else:
        query = query.order_by(Flashcard.created_at.desc())

    result = await db.execute(query)
    rows = result.scalars().all()
    return [FlashcardResponse.model_validate(r) for r in rows]


@router.get("/due", response_model=list[FlashcardResponse])
async def list_due_cards(
    user_id: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    query = (
        select(Flashcard)
        .where(
            Flashcard.user_id == user_id,
            Flashcard.next_review_at <= func.now(),
        )
        .order_by(Flashcard.next_review_at.asc())
    )
    result = await db.execute(query)
    rows = result.scalars().all()
    return [FlashcardResponse.model_validate(r) for r in rows]


@router.get("/counts", response_model=DueCountResponse)
async def get_counts(
    user_id: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    total = await db.execute(
        select(func.count(Flashcard.id)).where(Flashcard.user_id == user_id)
    )
    due = await db.execute(
        select(func.count(Flashcard.id)).where(
            Flashcard.user_id == user_id,
            Flashcard.next_review_at <= func.now(),
        )
    )
    return DueCountResponse(
        due_count=due.scalar() or 0,
        total_count=total.scalar() or 0,
    )


@router.post("", response_model=FlashcardResponse, status_code=status.HTTP_201_CREATED)
async def create_flashcard(
    item: FlashcardCreate,
    user_id: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    card = Flashcard(
        id=generate_uuid(),
        user_id=user_id,
        front_text=item.front_text,
        front_hint=item.front_hint,
        back_answer=item.back_answer,
        back_meaning=item.back_meaning,
        back_original=item.back_original,
        media_file_path=item.media_file_path,
        media_file_id=item.media_file_id,
        media_time=item.media_time,
        cue_id=item.cue_id,
        source_title=item.source_title,
        tags=item.tags,
        ai_generated=item.ai_generated,
    )
    db.add(card)
    await db.commit()
    await db.refresh(card)
    return FlashcardResponse.model_validate(card)


@router.put("/{card_id}", response_model=FlashcardResponse)
async def update_flashcard(
    card_id: str,
    item: FlashcardUpdate,
    user_id: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Flashcard).where(
            Flashcard.id == card_id,
            Flashcard.user_id == user_id,
        )
    )
    card = result.scalar_one_or_none()
    if card is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Flashcard not found")

    update_data = item.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(card, key, value)
    card.updated_at = datetime.now(timezone.utc)

    await db.commit()
    await db.refresh(card)
    return FlashcardResponse.model_validate(card)


@router.delete("/{card_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_flashcard(
    card_id: str,
    user_id: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        delete(Flashcard).where(
            Flashcard.id == card_id,
            Flashcard.user_id == user_id,
        )
    )
    await db.commit()
    if result.rowcount == 0:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Flashcard not found")


@router.post("/{card_id}/review", response_model=FlashcardReviewResponse)
async def review_card(
    card_id: str,
    review: ReviewRequest,
    user_id: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if review.rating not in (0, 1, 2, 3):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Rating must be 0, 1, 2, or 3",
        )

    result = await db.execute(
        select(Flashcard).where(
            Flashcard.id == card_id,
            Flashcard.user_id == user_id,
        )
    )
    card = result.scalar_one_or_none()
    if card is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Flashcard not found")

    interval = float(card.interval)
    ease_factor = float(card.ease_factor)

    if review.rating == 0:
        interval = 0
        ease_factor = max(1.3, ease_factor - 0.2)
    elif review.rating == 1:
        interval = max(1, interval * 0.5)
        ease_factor = max(1.3, ease_factor - 0.15)
    elif review.rating == 2:
        if interval == 0:
            interval = 1
        elif interval == 1:
            interval = 3
        else:
            interval = interval * ease_factor
    elif review.rating == 3:
        if interval == 0:
            interval = 1
        else:
            interval = (interval + 1) * ease_factor * 1.3
        ease_factor += 0.15

    card.interval = interval
    card.ease_factor = ease_factor
    card.review_count = (card.review_count or 0) + 1
    card.next_review_at = datetime.now(timezone.utc).replace(
        hour=0, minute=0, second=0, microsecond=0
    ) + __days_to_timedelta(interval)

    review_record = FlashcardReview(
        id=generate_uuid(),
        flashcard_id=card_id,
        rating=review.rating,
    )
    db.add(review_record)
    await db.commit()
    await db.refresh(review_record)
    return FlashcardReviewResponse.model_validate(review_record)


def __days_to_timedelta(days: float):
    from datetime import timedelta
    return timedelta(days=days)