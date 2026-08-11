import { useEffect, useRef, useState } from 'react';
import { useAppStore } from './store/appStore';
import { useI18n } from './context/I18nContext';
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
  const { abLoopActive, pointA, pointB, media, isPlaying, skipSilent, subtitles } = useAppStore();

  useEffect(() => {
    const el = mediaRef.current;
    if (!el || !media) return;

    let raf = 0;
    let pendingSeek: number | null = null;
    let lastCheckTime = 0;
    const CHECK_INTERVAL = 100; // ms — throttle to avoid excessive checks

    const findNextCueStart = (t: number, maxTime: number | null): number | null => {
      for (const c of subtitles) {
        if (c.start > t && (maxTime === null || c.start < maxTime)) {
          return c.start;
        }
      }
      return null;
    };

    const isInCue = (t: number): boolean => {
      for (const c of subtitles) {
        if (t >= c.start && t < c.end) return true;
      }
      return false;
    };

    const performSeek = (target: number) => {
      pendingSeek = target;
      el.currentTime = target;
    };

    const tick = (now: number) => {
      raf = requestAnimationFrame(tick);

      // Throttle checks
      if (now - lastCheckTime < CHECK_INTERVAL) return;
      lastCheckTime = now;

      // If we have a pending seek that hasn't completed yet, wait
      if (pendingSeek !== null) {
        if (Math.abs(el.currentTime - pendingSeek) < 0.05) {
          pendingSeek = null;
        } else {
          return; // Still seeking, don't interfere
        }
      }

      if (el.paused) return;

      const t = el.currentTime;

      // AB loop boundary check
      if (abLoopActive && pointA != null && pointB != null && t >= pointB - 0.02) {
        performSeek(pointA);
        return;
      }

      // Skip silent check
      if (skipSilent && subtitles.length > 0 && !isInCue(t)) {
        const inLoopRange = abLoopActive && pointA != null && pointB != null && t >= pointA && t < pointB;
        const maxTime = inLoopRange ? pointB : null;
        const next = findNextCueStart(t, maxTime);

        if (next !== null) {
          performSeek(next);
        } else if (inLoopRange) {
          performSeek(pointA);
        }
      }
    };

    const onSeeked = () => {
      pendingSeek = null;
    };

    el.addEventListener('seeked', onSeeked);

    if (isPlaying) {
      raf = requestAnimationFrame(tick);
    }

    return () => {
      if (raf) cancelAnimationFrame(raf);
      el.removeEventListener('seeked', onSeeked);
    };
  }, [abLoopActive, pointA, pointB, media, mediaRef, isPlaying, skipSilent, subtitles]);

  return null;
}

function AppContent() {
  const { t } = useI18n();
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
  const [sidePanelWidth, setSidePanelWidth] = useState(480);
  const [isResizing, setIsResizing] = useState(false);

  const handleResizeMouseDown = (e: React.MouseEvent) => {
    e.preventDefault();
    setIsResizing(true);
    const startX = e.clientX;
    const startWidth = sidePanelWidth;

    const handleMouseMove = (ev: MouseEvent) => {
      const diff = startX - ev.clientX;
      const newWidth = Math.max(320, Math.min(800, startWidth + diff));
      setSidePanelWidth(newWidth);
    };

    const handleMouseUp = () => {
      setIsResizing(false);
      document.removeEventListener('mousemove', handleMouseMove);
      document.removeEventListener('mouseup', handleMouseUp);
      document.body.style.cursor = '';
      document.body.style.userSelect = '';
    };

    document.addEventListener('mousemove', handleMouseMove);
    document.addEventListener('mouseup', handleMouseUp);
    document.body.style.cursor = 'col-resize';
    document.body.style.userSelect = 'none';
  };

  const sessionRestoredRef = useRef(false);

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

      sessionRestoredRef.current = true;
    })();
  }, [setFavorites, setABHistory, setOpenaiApiKey, setTargetLanguage, setMedia, setSubtitleFile, setSubtitles, setCurrentTime, setPanelSubtitlesVisible, setRecentMedia, setRecentSubtitleFiles]);

  useEffect(() => {
    favorites.forEach((f) => saveToStore('favorites', f));
  }, [favorites]);

  useEffect(() => {
    abHistory.forEach((s) => saveToStore('abHistory', s));
  }, [abHistory]);

  useEffect(() => {
    if (!sessionRestoredRef.current) return;
    if (media) {
      saveSessionValue('session-media', media).catch(() => {});
    } else {
      deleteSessionValue('session-media').catch(() => {});
    }
  }, [media]);

  useEffect(() => {
    if (!sessionRestoredRef.current) return;
    if (subtitleFile) saveSessionValue('session-subtitle-file', subtitleFile).catch(() => {});
    else deleteSessionValue('session-subtitle-file').catch(() => {});
  }, [subtitleFile]);

  useEffect(() => {
    if (!sessionRestoredRef.current) return;
    if (subtitles.length > 0) saveSessionValue('session-subtitles', subtitles).catch(() => {});
    else deleteSessionValue('session-subtitles').catch(() => {});
  }, [subtitles]);

  useEffect(() => {
    if (!sessionRestoredRef.current) return;
    saveSessionValue('recent-media', recentMedia).catch(() => {});
  }, [recentMedia]);

  useEffect(() => {
    if (!sessionRestoredRef.current) return;
    saveSessionValue('recent-subtitles', recentSubtitleFiles).catch(() => {});
  }, [recentSubtitleFiles]);

  useEffect(() => {
    if (!sessionRestoredRef.current) return;
    saveSessionValue('session-current-time', currentTime).catch(() => {});
  }, [currentTime]);

  useEffect(() => {
    if (!sessionRestoredRef.current) return;
    saveSessionValue('session-panel-visible', panelSubtitlesVisible).catch(() => {});
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
        <p className="tagline">{t('header.tagline')}</p>

        <nav className="mode-nav">
          {(['listen', 'typing', 'recording'] as const).map((mode) => (
            <button
              key={mode}
              type="button"
              className={`mode-btn ${practiceMode === mode ? 'active' : ''}`}
              onClick={() => setPracticeMode(mode)}
            >
              {mode === 'listen' ? t('mode.listen') : mode === 'typing' ? t('mode.typing') : t('mode.recording')}
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

        <aside className="side-panel side-panel-vertical" style={{ width: sidePanelWidth }}>
          <div
            className="side-resize-handle"
            onMouseDown={handleResizeMouseDown}
            title="Drag to resize"
          />
          <nav className="side-tabs-vertical">
            {(
              [
                ['subtitles', '📝', t('common.subs')],
                ['favorites', '★', t('common.favorites').replace('★ ', '')],
                ['anki', '🛒', ankiCart.length > 0 ? `${ankiCart.length}` : t('common.anki')],
                ['settings', '⚙', ''],
              ] as [Tab, string, string][]
            ).map(([tab, icon, label]) => (
              <button
                key={tab}
                type="button"
                className={`side-tab-vertical ${sideTab === tab ? 'active' : ''}`}
                onClick={() => setSideTab(tab)}
                title={label || tab}
              >
                <span className="side-tab-icon">{icon}</span>
                {label && <span className="side-tab-label">{label}</span>}
              </button>
            ))}
          </nav>

          <div className="side-content-vertical">
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