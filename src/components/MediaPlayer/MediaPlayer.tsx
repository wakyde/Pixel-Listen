import { useCallback, useEffect, useRef, useState } from 'react';
import { useAppStore } from '../../store/appStore';
import { useMediaRef } from '../../context/MediaContext';
import { getActiveCue } from '../../utils/subtitleParser';
import { safePlay, safePause } from '../../utils/mediaControl';
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
    setSubtitles,
    setSubtitleFile,
  } = useAppStore();

  const fileInputRef = useRef<HTMLInputElement>(null);
  const [isFullscreen, setIsFullscreen] = useState(false);
  const activeCue = getActiveCue(subtitles, currentTime);

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

      setMedia({
        name: file.name,
        url: URL.createObjectURL(file),
        type: isVideo ? 'video' : 'audio',
        mimeType: file.type || (isVideo ? 'video/mp4' : 'audio/mpeg'),
        file,
      });
    },
    [setMedia, setSubtitles, setSubtitleFile]
  );

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
          <p className="dropzone-title">DROP MEDIA HERE</p>
          <p className="dropzone-hint">MP4 · MKV · MP3 · WAV · WEBM</p>
          <label className="pixel-file-label" onClick={(e) => e.stopPropagation()}>
            <span className="pixel-btn pixel-btn-accent">BROWSE FILES</span>
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
        </div>
      </div>
    );
  }

  const mediaProps = {
    src: media.url,
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

  const showOverlay = practiceMode === 'listen' && videoSubtitleMode !== 'off' && activeCue;
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
          {...mediaProps}
        />
      ) : (
        <div className="audio-visualizer">
          <audio ref={mediaRef as React.RefObject<HTMLAudioElement>} {...mediaProps} />
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

      {showOverlay && activeCue && (
        <div className="subtitle-overlay" aria-live="polite">
          {(videoSubtitleMode === 'en' || videoSubtitleMode === 'both') && (
            <p className="subtitle-text">{activeCue.text}</p>
          )}
          {(videoSubtitleMode === 'zh' || videoSubtitleMode === 'both') && translation && (
            <p className="subtitle-translation">{translation}</p>
          )}
          {(videoSubtitleMode === 'zh' || videoSubtitleMode === 'both') && !translation && (
            <p className="subtitle-translation subtitle-unavailable">Translation unavailable</p>
          )}
        </div>
      )}

      {media.type === 'video' && (
        <button
          type="button"
          className="fullscreen-button"
          onClick={() => void toggleFullscreen()}
          aria-label={isFullscreen ? 'Exit fullscreen' : 'Enter fullscreen'}
          title={isFullscreen ? 'Exit fullscreen' : 'Fullscreen'}
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
