from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from database import init_db
from routers import auth, songs, video, ai, favorites, flashcards, sync, anki_import


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    yield


app = FastAPI(
    title="Personal Integration Platform",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(songs.router)
app.include_router(video.router)
app.include_router(ai.router)
app.include_router(favorites.router)
app.include_router(flashcards.router)
app.include_router(sync.router)
app.include_router(anki_import.router)


@app.get("/api/health")
async def health():
    return {"status": "ok"}