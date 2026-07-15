import { useCallback } from 'react';
import { useAppStore } from '../../store/appStore';
import { useMediaRef } from '../../context/MediaContext';
import { safePlay, safePause, seekTo } from '../../utils/mediaControl';
import { PixelButton, formatTimeDisplay } from '../PixelUI';
import type { ABLoopSegment, VideoSubtitleMode } from '../../types';

const RATES = [0.5, 0.75, 1, 1.25, 1.5, 2];
const SUBTITLE_MODES: { value: VideoSubtitleMode; label: string }[] = [
  { value: 'en', label: 'EN only' },
  { value: 'zh', label: 'Translation only' },
  { value: 'both', label: 'EN + Translation' },
  { value: 'off', label: 'Hidden' },
];

export function PlaybackControls() {
  const mediaRef = useMediaRef();
  const {
    media,
    currentTime,
    duration,
    isPlaying,
    setIsPlaying,
    setCurrentTime,
    playbackRate,
    setPlaybackRate,
    videoSubtitleMode,
    setVideoSubtitleMode,
    pointA,
    pointB,
    setPointA,
    setPointB,
    abLoopActive,
    toggleABLoop,
    saveABSegment,
    abHistory,
    loadABSegment,
  } = useAppStore();

  const seek = (time: number) => {
    const t = seekTo(mediaRef.current, time);
    setCurrentTime(t);
  };

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

  const setRate = useCallback(
    (rate: number) => {
      setPlaybackRate(rate);
      const el = mediaRef.current;
      if (el) el.playbackRate = rate;
    },
    [setPlaybackRate, mediaRef]
  );

  const markA = () => setPointA(currentTime);
  const markB = () => setPointB(currentTime);

  const handleLoadSegment = async (seg: ABLoopSegment) => {
    loadABSegment(seg);
    seek(seg.pointA);
    const ok = await safePlay(mediaRef.current);
    setIsPlaying(ok);
  };

  if (!media) return null;

  const progress = duration > 0 ? Math.min(100, (currentTime / duration) * 100) : 0;

  return (
    <div className="playback-controls">
      <div className="progress-bar-wrap">
        <input
          type="range"
          className="pixel-range"
          min={0}
          max={duration > 0 ? duration : 100}
          step={0.05}
          value={Number.isFinite(currentTime) ? currentTime : 0}
          aria-label="Seek"
          onChange={(e) => seek(parseFloat(e.target.value))}
        />
        <div className="progress-fill" style={{ width: `${progress}%` }} />
        <div
          className={`progress-runner${isPlaying ? ' running' : ''}`}
          style={{ left: `calc(${progress}% - 14px)` }}
          aria-hidden
        >
          <span className="runner-character">
            <span className="runner-head" />
            <span className="runner-torso" />
            <span className="runner-arm runner-arm-left" />
            <span className="runner-arm runner-arm-right" />
            <span className="runner-leg runner-leg-left" />
            <span className="runner-leg runner-leg-right" />
          </span>
        </div>
        {pointA != null && duration > 0 && (
          <div
            className="ab-marker ab-a"
            style={{ left: `${Math.min(100, (pointA / duration) * 100)}%` }}
            title="Point A"
          />
        )}
        {pointB != null && duration > 0 && (
          <div
            className="ab-marker ab-b"
            style={{ left: `${Math.min(100, (pointB / duration) * 100)}%` }}
            title="Point B"
          />
        )}
      </div>

      <div className="controls-row">
        <span className="time-display">
          {formatTimeDisplay(currentTime)} / {formatTimeDisplay(duration)}
        </span>

        <div className="controls-center">
          <PixelButton
            variant="ghost"
            size="sm"
            onClick={() => seek(Math.max(0, currentTime - 5))}
          >
            ⏪ 5s
          </PixelButton>
          <PixelButton variant="primary" onClick={togglePlay}>
            {isPlaying ? '⏸ PAUSE' : '▶ PLAY'}
          </PixelButton>
          <PixelButton
            variant="ghost"
            size="sm"
            onClick={() => seek(Math.min(duration || currentTime + 5, currentTime + 5))}
          >
            5s ⏩
          </PixelButton>
        </div>

        <div className="playback-options">
          <div className="speed-controls">
            <span className="control-label">SPEED</span>
            {RATES.map((r) => (
              <button
                key={r}
                type="button"
                className={`speed-btn ${playbackRate === r ? 'active' : ''}`}
                onClick={() => setRate(r)}
              >
                {r}x
              </button>
            ))}
          </div>
          <label className="subtitle-mode-control">
            <span className="control-label">SUBS</span>
            <select
              className="pixel-select video-sub-select"
              value={videoSubtitleMode}
              onChange={(event) =>
                setVideoSubtitleMode(event.target.value as VideoSubtitleMode)
              }
              aria-label="Video subtitle display"
            >
              {SUBTITLE_MODES.map((mode) => (
                <option key={mode.value} value={mode.value}>
                  {mode.label}
                </option>
              ))}
            </select>
          </label>
        </div>
      </div>

      <div className="ab-loop-section">
        <div className="ab-controls">
          <PixelButton variant="secondary" size="sm" onClick={markA}>
            SET A {pointA != null ? `(${formatTimeDisplay(pointA)})` : ''}
          </PixelButton>
          <PixelButton variant="secondary" size="sm" onClick={markB}>
            SET B {pointB != null ? `(${formatTimeDisplay(pointB)})` : ''}
          </PixelButton>
          <PixelButton
            variant={abLoopActive ? 'accent' : 'ghost'}
            size="sm"
            onClick={toggleABLoop}
            disabled={pointA == null || pointB == null}
          >
            {abLoopActive ? '⟳ LOOP ON' : '⟳ LOOP'}
          </PixelButton>
          <PixelButton
            variant="ghost"
            size="sm"
            onClick={() => saveABSegment()}
            disabled={pointA == null || pointB == null}
          >
            💾 SAVE
          </PixelButton>
        </div>

        {abHistory.length > 0 && (
          <div className="ab-history">
            <span className="control-label">AB HISTORY</span>
            <div className="ab-history-list">
              {abHistory.slice(0, 8).map((seg) => (
                <button
                  key={seg.id}
                  type="button"
                  className="ab-history-item"
                  onClick={() => handleLoadSegment(seg)}
                >
                  {seg.label}
                </button>
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
