# Pixel Listen

A pixel-art styled language listening practice tool for immersive English learning.

## Features

- **Media Import** — Drag & drop or browse MP4, MKV, MP3 files
- **Subtitles** — Import SRT/VTT, AI transcription (Whisper), toggle visibility, translate, grammar analysis
- **AB Loop** — Custom segment looping with persistent history
- **Playback Speed** — 0.5x to 2x speed control
- **Favorites** — Save words, collocations, phrases, and sentences
- **Typing Mode** — Type along with audio to test comprehension
- **Shadowing Mode** — Record your voice for pronunciation practice
- **Anki Export** — Custom and AI-recommended flashcard decks with embedded audio clips

## Getting Started

```bash
npm install
npm run dev
```

Open http://localhost:5173 in your browser.

## AI Features

Add your OpenAI API key in Settings to enable:
- Whisper transcription
- Subtitle translation
- Grammar analysis
- AI Anki card generation

## Tech Stack

- React 18 + TypeScript + Vite
- Zustand state management
- IndexedDB persistence
- Web Audio API for clip extraction
