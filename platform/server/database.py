import uuid
from datetime import datetime

from sqlalchemy import Column, String, DateTime, Boolean, Integer, Float, Text, func
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase

from config import settings

engine = create_async_engine(settings.database_url, echo=False)
async_session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)


class Base(DeclarativeBase):
    pass


def generate_uuid():
    return str(uuid.uuid4())


class User(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True, default=generate_uuid)
    username = Column(String, unique=True, nullable=False)
    email = Column(String, unique=True, nullable=False)
    password_hash = Column(String, nullable=False)
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())


class Favorite(Base):
    __tablename__ = "favorites"

    id = Column(String, primary_key=True, default=generate_uuid)
    user_id = Column(String, nullable=False)
    type = Column(String, nullable=False)
    text = Column(Text, nullable=False)
    context = Column(Text, nullable=True)
    cefr_level = Column(String, nullable=True)
    media_time = Column(Float, nullable=True)
    cue_id = Column(String, nullable=True)
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())


class Collocation(Base):
    __tablename__ = "collocations"

    id = Column(String, primary_key=True, default=generate_uuid)
    user_id = Column(String, nullable=False)
    type = Column(String, nullable=False)
    text = Column(Text, nullable=False)
    meaning = Column(Text, nullable=True)
    source_cue_id = Column(String, nullable=True)
    source_text = Column(Text, nullable=True)
    ai_detected = Column(Boolean, default=False)
    created_at = Column(DateTime, default=func.now())


class Flashcard(Base):
    __tablename__ = "flashcards"

    id = Column(String, primary_key=True, default=generate_uuid)
    user_id = Column(String, nullable=False)
    front_text = Column(Text, nullable=False)
    front_hint = Column(Text, nullable=True)
    back_answer = Column(Text, nullable=False)
    back_meaning = Column(Text, nullable=True)
    back_original = Column(Text, nullable=True)
    media_file_path = Column(Text, nullable=True)
    media_file_id = Column(String, nullable=True)
    media_time = Column(Float, nullable=True)
    cue_id = Column(String, nullable=True)
    source_title = Column(Text, nullable=True)
    tags = Column(Text, nullable=True)
    review_count = Column(Integer, default=0)
    next_review_at = Column(DateTime, default=func.now())
    ease_factor = Column(Float, default=2.5)
    interval = Column(Float, default=0.0)
    ai_generated = Column(Boolean, default=False)
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())


class FlashcardReview(Base):
    __tablename__ = "flashcard_reviews"

    id = Column(String, primary_key=True, default=generate_uuid)
    flashcard_id = Column(String, nullable=False)
    rating = Column(Integer, nullable=False)
    reviewed_at = Column(DateTime, default=func.now())


class AiCache(Base):
    __tablename__ = "ai_cache"

    cache_key = Column(String, primary_key=True)
    task_type = Column(String, nullable=False)
    input_hash = Column(String, nullable=False)
    response = Column(Text, nullable=False)
    created_at = Column(DateTime, default=func.now())
    expires_at = Column(DateTime, nullable=False)


class TypingResult(Base):
    __tablename__ = "typing_results"

    id = Column(String, primary_key=True, default=generate_uuid)
    user_id = Column(String, nullable=False)
    cue_id = Column(String, nullable=True)
    expected = Column(Text, nullable=False)
    typed = Column(Text, nullable=False)
    accuracy = Column(Float, nullable=False)
    created_at = Column(DateTime, default=func.now())


class AbHistory(Base):
    __tablename__ = "ab_history"

    id = Column(String, primary_key=True, default=generate_uuid)
    user_id = Column(String, nullable=False)
    label = Column(String, nullable=False)
    point_a = Column(Float, nullable=False)
    point_b = Column(Float, nullable=False)
    created_at = Column(DateTime, default=func.now())


class SyncStatus(Base):
    __tablename__ = "sync_status"

    user_id = Column(String, primary_key=True)
    last_synced_at = Column(DateTime, nullable=True)
    server_generation = Column(Integer, default=0)


class VideoSource(Base):
    __tablename__ = "video_sources"

    id = Column(String, primary_key=True, default=generate_uuid)
    user_id = Column(String, nullable=False)
    platform = Column(String, nullable=True)
    url = Column(Text, nullable=True)
    title = Column(Text, nullable=True)
    thumbnail_url = Column(Text, nullable=True)
    file_id = Column(String, nullable=True)
    local_video_path = Column(Text, nullable=True)
    local_subtitle_path = Column(Text, nullable=True)
    original_device_id = Column(String, nullable=True)
    downloaded_at = Column(DateTime, default=func.now())


class AnkiImportLog(Base):
    __tablename__ = "anki_import_logs"

    id = Column(String, primary_key=True, default=generate_uuid)
    user_id = Column(String, nullable=False)
    file_name = Column(String, nullable=False)
    source_type = Column(String, nullable=False)
    deck_name = Column(String, nullable=True)
    total_cards = Column(Integer, default=0)
    imported_count = Column(Integer, default=0)
    skipped_count = Column(Integer, default=0)
    errors = Column(Text, nullable=True)
    imported_at = Column(DateTime, default=func.now())


async def init_db():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)


async def get_db():
    async with async_session() as session:
        yield session