import { useEffect, useState } from 'react';
import { useAppStore } from './store/appStore';
import { MediaProvider, useMediaRef } from './context/MediaContext';
import { MediaPlayer } from './components/MediaPlayer/MediaPlayer';
import { PlaybackControls } from './components/PlaybackControls/PlaybackControls';
import { SubtitlePanel } from './components/SubtitlePanel/SubtitlePanel';
import { FavoritesPanel } from './components/FavoritesPanel/FavoritesPanel';
import { TypingMode } from './components/PracticeModes/TypingMode';
import { RecordingMode } from './components/PracticeModes/RecordingMode';
import { AnkiExportPanel } from './components/AnkiExport/AnkiExportPanel';
import { SettingsPanel } from './components/Settings/SettingsPanel';
import { loadFromStore, saveToStore, loadSessionValue, saveSessionValue, deleteSessionValue } from './utils/storage';
import type {
  ABLoopSegment,
  FavoriteItem,
  MediaFile,
  RecentMediaItem,
  RecentSubtitleItem,
  SubtitleCue,
  SubtitleFile,
} from './types';
import './styles/globals.css';

type Tab = 'subtitles' | 'favorites' | 'anki' | 'settings';

/** High-frequency clock so subtitles and progress stay synced with playback. */
function PlaybackClock() {
  const mediaRef = useMediaRef();
  const media = useAppStore((s) => s.media);
  const isPlaying = useAppStore((s) => s.isPlaying);
  const setCurrentTime = useAppStore((s) => s.setCurrentTime);

  useEffect(() => {
    if (!media) return;
    let raf = 0;
    let lastWritten = -1;

    const tick = () => {
      const el = mediaRef.current;
      if (el) {
        const t = el.currentTime;
        // Throttle store writes slightly to avoid excessive re-renders (~30fps)
        if (Math.abs(t - lastWritten) >= 1 / 30) {
          lastWritten = t;
          setCurrentTime(t);
        }
      }
      raf = requestAnimationFrame(tick);
    };

    if (isPlaying) {
      raf = requestAnimationFrame(tick);
    } else {
      const el = mediaRef.current;
      if (el) setCurrentTime(el.currentTime);
    }

    return () => {
      if (raf) cancelAnimationFrame(raf);
    };
  }, [media, isPlaying, mediaRef, setCurrentTime]);

  return null;
}

function PlaybackRateSync() {
  const mediaRef = useMediaRef();
  const { playbackRate, media } = useAppStore();

  useEffect(() => {
    const el = mediaRef.current;
    if (el && media) el.playbackRate = playbackRate;
  }, [playbackRate, media, mediaRef]);

  return null;
}

function ABLoopHandler() {
  const mediaRef = useMediaRef();
  const { abLoopActive, pointA, pointB, media, isPlaying } = useAppStore();

  useEffect(() => {
    const el = mediaRef.current;
    if (!el || !media || !abLoopActive || pointA == null || pointB == null) return;

    let raf = 0;
    const check = () => {
      if (el.currentTime >= pointB - 0.02) {
        el.currentTime = pointA;
      }
      if (!el.paused) {
        raf = requestAnimationFrame(check);
      }
    };

    if (isPlaying) {
      raf = requestAnimationFrame(check);
    }

    return () => {
      if (raf) cancelAnimationFrame(raf);
    };
  }, [abLoopActive, pointA, pointB, media, mediaRef, isPlaying]);

  return null;
}

function AppContent() {
  const {
    practiceMode,
    setPracticeMode,
    setFavorites,
    setABHistory,
    setOpenaiApiKey,
    setTargetLanguage,
    setMedia,
    setSubtitleFile,
    setSubtitles,
    setPanelSubtitlesVisible,
    setCurrentTime,
    panelSubtitlesVisible,
    media,
    subtitleFile,
    subtitles,
    currentTime,
    abHistory,
    favorites,
    ankiCart,
    recentMedia,
    recentSubtitleFiles,
    setRecentMedia,
    setRecentSubtitleFiles,
  } = useAppStore();

  const [sideTab, setSideTab] = useState<Tab>('subtitles');

  useEffect(() => {
    loadFromStore<FavoriteItem>('favorites').then(setFavorites);
    loadFromStore<ABLoopSegment>('abHistory').then(setABHistory);
    const key = localStorage.getItem('pixel-listen-api-key');
    const lang = localStorage.getItem('pixel-listen-target-lang');
    if (key) setOpenaiApiKey(key);
    if (lang) setTargetLanguage(lang);

    (async () => {
      const sessionMedia = await loadSessionValue<MediaFile>('session-media');
      const sessionSubtitleFile = await loadSessionValue<SubtitleFile>('session-subtitle-file');
      const sessionSubtitles = await loadSessionValue<SubtitleCue[]>('session-subtitles');
      const sessionCurrentTime = await loadSessionValue<number>('session-current-time');
      const sessionPanelVisible = await loadSessionValue<boolean>('session-panel-visible');
      const sessionRecentMedia = await loadSessionValue<RecentMediaItem[]>('recent-media');
      const sessionRecentSubs = await loadSessionValue<RecentSubtitleItem[]>('recent-subtitles');

      if (sessionMedia) {
        let file: File | undefined = sessionMedia.file;
        if (!file && sessionMedia.fileHandle) {
          try {
            file = await sessionMedia.fileHandle.getFile();
          } catch {
            // File handle not accessible anymore
          }
        }
        if (file) {
          setMedia({
            ...sessionMedia,
            file,
            url: URL.createObjectURL(file),
          });
        }
      }
      if (sessionSubtitleFile) {
        setSubtitleFile(sessionSubtitleFile);
      }
      if (sessionSubtitles) {
        setSubtitles(sessionSubtitles);
      }
      if (typeof sessionCurrentTime === 'number' && sessionCurrentTime >= 0) {
        setCurrentTime(sessionCurrentTime);
      }
      if (typeof sessionPanelVisible === 'boolean') {
        setPanelSubtitlesVisible(sessionPanelVisible);
      }
      if (sessionRecentMedia) {
        setRecentMedia(sessionRecentMedia);
      }
      if (sessionRecentSubs) {
        setRecentSubtitleFiles(sessionRecentSubs);
      }
    })();
  }, [setFavorites, setABHistory, setOpenaiApiKey, setTargetLanguage, setMedia, setSubtitleFile, setSubtitles, setCurrentTime, setPanelSubtitlesVisible, setRecentMedia, setRecentSubtitleFiles]);

  useEffect(() => {
    favorites.forEach((f) => saveToStore('favorites', f));
  }, [favorites]);

  useEffect(() => {
    abHistory.forEach((s) => saveToStore('abHistory', s));
  }, [abHistory]);

  useEffect(() => {
    if (media) {
      saveSessionValue('session-media', media);
    } else {
      deleteSessionValue('session-media');
    }
  }, [media]);

  useEffect(() => {
    if (subtitleFile) saveSessionValue('session-subtitle-file', subtitleFile);
    else deleteSessionValue('session-subtitle-file');
  }, [subtitleFile]);

  useEffect(() => {
    if (subtitles.length > 0) saveSessionValue('session-subtitles', subtitles);
    else deleteSessionValue('session-subtitles');
  }, [subtitles]);

  useEffect(() => {
    saveSessionValue('recent-media', recentMedia);
  }, [recentMedia]);

  useEffect(() => {
    saveSessionValue('recent-subtitles', recentSubtitleFiles);
  }, [recentSubtitleFiles]);

  useEffect(() => {
    saveSessionValue('session-current-time', currentTime);
  }, [currentTime]);

  useEffect(() => {
    saveSessionValue('session-panel-visible', panelSubtitlesVisible);
  }, [panelSubtitlesVisible]);

  return (
    <div className="app">
      <PlaybackClock />
      <ABLoopHandler />
      <PlaybackRateSync />
      <header className="app-header">
        <div className="logo">
          <span className="logo-icon">🎧</span>
          <h1>PIXEL LISTEN</h1>
        </div>
        <p className="tagline">Listen · Type · Shadow · Review</p>

        <nav className="mode-nav">
          {(['listen', 'typing', 'recording'] as const).map((mode) => (
            <button
              key={mode}
              type="button"
              className={`mode-btn ${practiceMode === mode ? 'active' : ''}`}
              onClick={() => setPracticeMode(mode)}
            >
              {mode === 'listen' ? '🎵 LISTEN' : mode === 'typing' ? '⌨ TYPE' : '🎤 SHADOW'}
            </button>
          ))}
        </nav>
      </header>

      <main className="app-main">
        <section className="main-stage">
          <MediaPlayer />
          <PlaybackControls />
          {practiceMode === 'typing' && <TypingMode />}
          {practiceMode === 'recording' && <RecordingMode />}
        </section>

        <aside className="side-panel">
          <nav className="side-tabs">
            {(
              [
                ['subtitles', 'SUBS'],
                ['favorites', '★ FAV'],
                ['anki', ankiCart.length > 0 ? `🛒 ${ankiCart.length}` : 'ANKI'],
                ['settings', '⚙'],
              ] as [Tab, string][]
            ).map(([tab, label]) => (
              <button
                key={tab}
                type="button"
                className={`side-tab ${sideTab === tab ? 'active' : ''}`}
                onClick={() => setSideTab(tab)}
              >
                {label}
              </button>
            ))}
          </nav>

          <div className="side-content">
            {sideTab === 'subtitles' && <SubtitlePanel />}
            {sideTab === 'favorites' && <FavoritesPanel />}
            {sideTab === 'anki' && <AnkiExportPanel />}
            {sideTab === 'settings' && <SettingsPanel />}
          </div>
        </aside>
      </main>

      <footer className="app-footer">
        <span>PIXEL LISTEN v1.0</span>
        <span className="footer-blink">▮</span>
      </footer>
    </div>
  );
}

export default function App() {
  return (
    <MediaProvider>
      <AppContent />
    </MediaProvider>
  );
}
