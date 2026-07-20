import { useCallback, useEffect, useRef, useState } from 'react';
import { useAppStore } from '../../store/appStore';
import { useMediaRef } from '../../context/MediaContext';
import { useI18n } from '../../context/I18nContext';
import { getActiveCue } from '../../utils/subtitleParser';
import { safePlay, safePause } from '../../utils/mediaControl';
import { seekTo } from '../../utils/mediaControl';
import { PixelButton } from '../PixelUI';

const ACCEPTED_MEDIA = '.mp4,.mkv,.mp3,.webm,.m4a,.wav,.ogg';

export function MediaPlayer() {
  const mediaRef = useMediaRef();
  const wrapRef = useRef<HTMLDivElement>(null);
  const {
    media,
    setMedia,
    subtitles,
    videoSubtitleMode,
    currentTime,
    setCurrentTime,
    setDuration,
    isPlaying,
    setIsPlaying,
    playbackRate,
    pointA,
    pointB,
    abLoopActive,
    practiceMode,
    leadTime,
    setSubtitles,
    setSubtitleFile,
    setSelectedCueId,
    recentMedia,
    addRecentMedia,
  } = useAppStore();

  const fileInputRef = useRef<HTMLInputElement>(null);
  const [isFullscreen, setIsFullscreen] = useState(false);
  const { t } = useI18n();
  const activeCue = getActiveCue(subtitles, currentTime);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key !== 'ArrowLeft' && e.key !== 'ArrowRight') return;
      if (practiceMode !== 'listen') return;
      const tag = (e.target as HTMLElement)?.tagName?.toLowerCase();
      if (tag === 'input' || tag === 'textarea' || (e.target as HTMLElement)?.isContentEditable) return;
      if (!subtitles || subtitles.length === 0) return;

      const navSubtitles = abLoopActive && pointA != null && pointB != null
        ? subtitles.filter((c) => c.start < pointB && c.end > pointA)
        : subtitles;
      if (navSubtitles.length === 0) return;

      let idx = activeCue ? navSubtitles.findIndex((c) => c.id === activeCue.id) : -1;
      if (idx === -1) {
        idx = navSubtitles.findIndex((c) => c.start > currentTime) - 1;
      }

      const goToIndex = async (newIdx: number) => {
        if (newIdx < 0 || newIdx >= navSubtitles.length) return;
        const cue = navSubtitles[newIdx];
        setSelectedCueId(cue.id);
        const seekTarget = Math.max(0, cue.start - leadTime / 1000);
        const t = seekTo(mediaRef.current, seekTarget);
        setCurrentTime(t);
        const ok = await safePlay(mediaRef.current);
        setIsPlaying(ok);
      };

      if (e.key === 'ArrowLeft') {
        e.preventDefault();
        const newIdx = idx <= 0 ? 0 : idx - 1;
        void goToIndex(newIdx);
      } else if (e.key === 'ArrowRight') {
        e.preventDefault();
        const newIdx = idx < 0 ? 0 : Math.min(navSubtitles.length - 1, idx + 1);
        void goToIndex(newIdx);
      }
    };

    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [subtitles, currentTime, activeCue, abLoopActive, pointA, pointB, practiceMode, setCurrentTime, setIsPlaying, setSelectedCueId]);

  useEffect(() => {
    const onFs = () => setIsFullscreen(Boolean(document.fullscreenElement));
    document.addEventListener('fullscreenchange', onFs);
    return () => document.removeEventListener('fullscreenchange', onFs);
  }, []);

  const handleFile = useCallback(
    (file: File) => {
      const ext = file.name.split('.').pop()?.toLowerCase() ?? '';
      const isVideo = ['mp4', 'mkv', 'webm'].includes(ext);
      const isAudio = ['mp3', 'm4a', 'wav', 'ogg'].includes(ext);
      if (!isVideo && !isAudio) return;

      const prev = useAppStore.getState().media;
      if (prev) URL.revokeObjectURL(prev.url);

      setSubtitles([]);
      setSubtitleFile(null);

      // Determine correct mime type
      let mimeType = file.type;
      if (!mimeType) {
        const mimeMap: Record<string, string> = {
          mp4: 'video/mp4',
          mkv: 'video/x-matroska',
          webm: 'video/webm',
          mp3: 'audio/mpeg',
          m4a: 'audio/mp4',
          wav: 'audio/wav',
          ogg: 'audio/ogg',
        };
        mimeType = mimeMap[ext] || (isVideo ? 'video/mp4' : 'audio/mpeg');
      }

      const newMedia = {
        name: file.name,
        url: URL.createObjectURL(file),
        type: (isVideo ? 'video' : 'audio') as 'video' | 'audio',
        mimeType,
        file,
      };
      setMedia(newMedia);
      addRecentMedia({
        name: file.name,
        type: isVideo ? 'video' : 'audio',
        mimeType,
        fileHandle: undefined,
      });
    },
    [setMedia, setSubtitles, setSubtitleFile, addRecentMedia]
  );

  const loadRecentMedia = async (item: { name: string; type: 'video' | 'audio'; mimeType: string; fileHandle?: FileSystemFileHandle | null; }) => {
    if (!item.fileHandle) {
      alert(t('media.no_file_handle'));
      return;
    }

    try {
      const file = await item.fileHandle.getFile();
      if (!file) throw new Error(t('media.unable_access'));
      const ext = file.name.split('.').pop()?.toLowerCase() ?? '';
      const isVideo = ['mp4', 'mkv', 'webm'].includes(ext);
      const isAudio = ['mp3', 'm4a', 'wav', 'ogg'].includes(ext);
      if (!isVideo && !isAudio) throw new Error(t('media.unsupported_type'));

      const prev = useAppStore.getState().media;
      if (prev) URL.revokeObjectURL(prev.url);

      setSubtitles([]);
      setSubtitleFile(null);
      setMedia({
        name: file.name,
        url: URL.createObjectURL(file),
        type: isVideo ? 'video' : 'audio',
        mimeType: file.type || (isVideo ? 'video/mp4' : 'audio/mpeg'),
        file,
        fileHandle: item.fileHandle,
      });
      addRecentMedia({
        name: file.name,
        type: isVideo ? 'video' : 'audio',
        mimeType: file.type || (isVideo ? 'video/mp4' : 'audio/mpeg'),
        fileHandle: item.fileHandle,
      });
    } catch (err) {
      alert(err instanceof Error ? err.message : t('media.restore_failed'));
    }
  };

  useEffect(() => {
    const el = mediaRef.current;
    if (el && media) el.playbackRate = playbackRate;
  }, [media, playbackRate, mediaRef]);

  const togglePlay = async () => {
    const el = mediaRef.current;
    if (!el) return;
    if (el.paused) {
      const ok = await safePlay(el);
      setIsPlaying(ok);
    } else {
      safePause(el);
      setIsPlaying(false);
    }
  };

  const toggleFullscreen = async () => {
    const wrap = wrapRef.current;
    if (!wrap) return;
    try {
      if (!document.fullscreenElement) {
        await wrap.requestFullscreen();
      } else {
        await document.exitFullscreen();
      }
    } catch {
      // fullscreen may be blocked
    }
  };

  if (!media) {
    return (
      <div
        className="media-dropzone"
        onDragOver={(e) => {
          e.preventDefault();
          e.dataTransfer.dropEffect = 'copy';
        }}
        onDrop={(e) => {
          e.preventDefault();
          const file = e.dataTransfer.files[0];
          if (file) handleFile(file);
        }}
        onClick={() => fileInputRef.current?.click()}
        role="button"
        tabIndex={0}
        onKeyDown={(e) => {
          if (e.key === 'Enter' || e.key === ' ') {
            e.preventDefault();
            fileInputRef.current?.click();
          }
        }}
      >
        <div className="dropzone-content">
          <div className="pixel-icon-headphones" />
          <p className="dropzone-title">{t('media.drop_zone')}</p>
          <p className="dropzone-hint">{t('media.formats')}</p>
          <label className="pixel-file-label" onClick={(e) => e.stopPropagation()}>
            <span className="pixel-btn pixel-btn-accent">{t('media.browse_files')}</span>
            <input
              ref={fileInputRef}
              type="file"
              accept={ACCEPTED_MEDIA}
              hidden
              onChange={(e) => {
                const file = e.target.files?.[0];
                if (file) handleFile(file);
                e.target.value = '';
              }}
            />
          </label>
          {recentMedia.length > 0 && (
            <div className="recent-media-section">
              <span className="recent-media-label">{t('media.recent')}</span>
              <div className="recent-media-list">
                {recentMedia.map((item) => (
                  <button
                    key={item.name}
                    type="button"
                    className="recent-media-item"
                    onClick={(e) => {
                      e.stopPropagation();
                      void loadRecentMedia(item);
                    }}
                    disabled={!item.fileHandle}
                  >
                    {item.name}
                  </button>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>
    );
  }

  const mediaProps = {
    onTimeUpdate: (e: React.SyntheticEvent<HTMLMediaElement>) => {
      setCurrentTime(e.currentTarget.currentTime);
    },
    onLoadedMetadata: (e: React.SyntheticEvent<HTMLMediaElement>) => {
      const el = e.currentTarget;
      el.playbackRate = playbackRate;
      setDuration(el.duration);
      setCurrentTime(0);
    },
    onPlay: () => setIsPlaying(true),
    onPause: () => setIsPlaying(false),
    onEnded: () => setIsPlaying(false),
    onSeeked: (e: React.SyntheticEvent<HTMLMediaElement>) => {
      setCurrentTime(e.currentTarget.currentTime);
    },
  };

  const abLoopCueVisible =
    !abLoopActive || pointA == null || pointB == null ||
    (activeCue != null && activeCue.start < pointB && activeCue.end > pointA);
  const showOverlay = practiceMode === 'listen' && videoSubtitleMode !== 'off' && activeCue && abLoopCueVisible;
  const translation = activeCue?.translationHidden
    ? undefined
    : activeCue?.translation ?? activeCue?.nativeTranslation;

  return (
    <div className={`media-player-wrap${isFullscreen ? ' is-fullscreen' : ''}`} ref={wrapRef}>
      {media.type === 'video' ? (
        <video
          ref={mediaRef as React.RefObject<HTMLVideoElement>}
          className="media-element"
          onClick={togglePlay}
          playsInline
          crossOrigin="anonymous"
          {...mediaProps}
        >
          <source src={media.url} type={media.mimeType} />
          <p>{t('media.unsupported_video')}</p>
        </video>
      ) : (
        <div className="audio-visualizer">
          <audio ref={mediaRef as React.RefObject<HTMLAudioElement>} {...mediaProps}>
            <source src={media.url} type={media.mimeType} />
            {t('media.unsupported_audio')}
          </audio>
          <div className="audio-wave" onClick={togglePlay}>
            {Array.from({ length: 16 }).map((_, i) => (
              <div
                key={i}
                className={`wave-bar ${isPlaying ? 'wave-active' : ''}`}
                style={{ animationDelay: `${i * 0.08}s` }}
              />
            ))}
          </div>
          <p className="audio-filename">{media.name}</p>
          <PixelButton variant="primary" size="sm" onClick={togglePlay}>
            {isPlaying ? '⏸' : '▶'}
          </PixelButton>
        </div>
      )}

      <div className="tv-stand" aria-hidden="true" />

      {showOverlay && activeCue && (
        <div className="subtitle-overlay" aria-live="polite">
          {(videoSubtitleMode === 'en' || videoSubtitleMode === 'both') && (
            <p className="subtitle-text">{activeCue.text}</p>
          )}
          {(videoSubtitleMode === 'zh' || videoSubtitleMode === 'both') && translation && (
            <p className="subtitle-translation">{translation}</p>
          )}
          {(videoSubtitleMode === 'zh' || videoSubtitleMode === 'both') && !translation && (
            <p className="subtitle-translation subtitle-unavailable">{t('media.translation_unavailable')}</p>
          )}
        </div>
      )}

      {media.type === 'video' && (
        <button
          type="button"
          className="fullscreen-button"
          onClick={() => void toggleFullscreen()}
          aria-label={isFullscreen ? t('media.exit_fullscreen') : t('media.enter_fullscreen')}
          title={isFullscreen ? t('media.exit_fullscreen') : t('media.fullscreen')}
        >
          {isFullscreen ? '×' : '⛶'}
        </button>
      )}

      {abLoopActive && pointA != null && pointB != null && (
        <div className="ab-loop-indicator">⟳ AB LOOP</div>
      )}
    </div>
  );
}