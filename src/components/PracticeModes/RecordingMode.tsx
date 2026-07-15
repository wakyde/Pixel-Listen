import { useState, useRef, useEffect } from 'react';
import { useAppStore } from '../../store/appStore';
import { useMediaRef } from '../../context/MediaContext';
import { getEnglishText } from '../../utils/bilingualText';
import { safePlay, safePause, seekTo } from '../../utils/mediaControl';
import { scoreShadowRecording } from '../../utils/audioScore';
import { playSuccessSound } from '../../utils/soundEffects';
import { ConfirmDialog, PixelButton, PixelPanel } from '../PixelUI';

interface Recording {
  id: string;
  cueText: string;
  translation?: string;
  url: string;
  blob: Blob;
  score: number | null;
  createdAt: number;
}

export function RecordingMode() {
  const mediaRef = useMediaRef();
  const { media, subtitles, currentTime, setCurrentTime, setIsPlaying } = useAppStore();
  const [cueIndex, setCueIndex] = useState(0);
  const [phase, setPhase] = useState<'idle' | 'playing' | 'recording' | 'scoring'>('idle');
  const [recordings, setRecordings] = useState<Recording[]>([]);
  const [pendingClear, setPendingClear] = useState(false);
  const [showBurst, setShowBurst] = useState(false);
  const [lastScore, setLastScore] = useState<number | null>(null);
  const mediaRecorderRef = useRef<MediaRecorder | null>(null);
  const chunksRef = useRef<Blob[]>([]);
  const stopAtRef = useRef<number | null>(null);
  const awaitingRecordRef = useRef(false);
  const streamRef = useRef<MediaStream | null>(null);

  const cue = subtitles[cueIndex];
  const english = cue ? getEnglishText(cue.text) : '';

  // Stop original playback at cue end; then start mic recording if waiting
  useEffect(() => {
    const end = stopAtRef.current;
    if (end == null) return;
    if (currentTime >= end - 0.05) {
      safePause(mediaRef.current);
      setIsPlaying(false);
      stopAtRef.current = null;
      if (awaitingRecordRef.current) {
        awaitingRecordRef.current = false;
        void beginMicCapture();
      } else if (phase === 'playing') {
        setPhase('idle');
      }
    }
  }, [currentTime, mediaRef, setIsPlaying, phase]);

  useEffect(() => {
    return () => {
      streamRef.current?.getTracks().forEach((t) => t.stop());
    };
  }, []);

  const playOriginal = async () => {
    if (!cue) return;
    stopAtRef.current = cue.end;
    awaitingRecordRef.current = false;
    setPhase('playing');
    const t = seekTo(mediaRef.current, cue.start);
    setCurrentTime(t);
    const ok = await safePlay(mediaRef.current);
    setIsPlaying(ok);
  };

  const beginMicCapture = async () => {
    const stream = streamRef.current;
    if (!stream) {
      setPhase('idle');
      return;
    }
    const recorder = new MediaRecorder(stream);
    chunksRef.current = [];
    recorder.ondataavailable = (e) => {
      if (e.data.size > 0) chunksRef.current.push(e.data);
    };
    recorder.onstop = () => {
      void finalizeRecording();
    };
    recorder.start();
    mediaRecorderRef.current = recorder;
    setPhase('recording');
  };

  const finalizeRecording = async () => {
    const blob = new Blob(chunksRef.current, { type: 'audio/webm' });
    const url = URL.createObjectURL(blob);
    streamRef.current?.getTracks().forEach((t) => t.stop());
    streamRef.current = null;

    setPhase('scoring');
    let score = 0;
    if (media && cue) {
      score = await scoreShadowRecording(media.url, cue.start, cue.end, blob);
    }
    setLastScore(score);
    setRecordings((prev) => [
      {
        id: crypto.randomUUID(),
        cueText: english,
        translation: cue?.translation,
        url,
        blob,
        score,
        createdAt: Date.now(),
      },
      ...prev,
    ]);
    setPhase('idle');
    if (score >= 90) {
      playSuccessSound();
      setShowBurst(true);
      window.setTimeout(() => setShowBurst(false), 1600);
    }
  };

  const startShadowing = async () => {
    if (!cue) return;
    setLastScore(null);
    setShowBurst(false);
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      streamRef.current = stream;
      // Play original first; recording starts after cue ends
      awaitingRecordRef.current = true;
      stopAtRef.current = cue.end;
      setPhase('playing');
      const t = seekTo(mediaRef.current, cue.start);
      setCurrentTime(t);
      const ok = await safePlay(mediaRef.current);
      setIsPlaying(ok);
      if (!ok) {
        // If play fails, start recording immediately
        awaitingRecordRef.current = false;
        await beginMicCapture();
      }
    } catch {
      alert('Microphone access denied. Please allow microphone permissions.');
      setPhase('idle');
    }
  };

  const stopRecording = () => {
    awaitingRecordRef.current = false;
    stopAtRef.current = null;
    if (mediaRecorderRef.current && mediaRecorderRef.current.state !== 'inactive') {
      mediaRecorderRef.current.stop();
    } else {
      streamRef.current?.getTracks().forEach((t) => t.stop());
      streamRef.current = null;
      setPhase('idle');
    }
    safePause(mediaRef.current);
    setIsPlaying(false);
  };

  const clearRecordings = () => {
    recordings.forEach((r) => URL.revokeObjectURL(r.url));
    setRecordings([]);
    setPendingClear(false);
  };

  if (subtitles.length === 0) {
    return (
      <PixelPanel title="VOICE RECORDING">
        <p className="empty-hint">Load subtitles first to practice shadowing</p>
      </PixelPanel>
    );
  }

  const phaseLabel =
    phase === 'playing'
      ? '▶ Playing original…'
      : phase === 'recording'
        ? '● REC — speak now'
        : phase === 'scoring'
          ? '⏳ Scoring…'
          : null;

  return (
    <PixelPanel title="VOICE RECORDING">
      <ConfirmDialog
        open={pendingClear}
        title="Clear recordings?"
        message="Delete all shadowing recordings from this session? This cannot be undone."
        confirmLabel="CLEAR"
        danger
        onConfirm={clearRecordings}
        onCancel={() => setPendingClear(false)}
      />

      <div className={`recording-mode${showBurst ? ' success-burst' : ''}`}>
        {showBurst && lastScore != null && (
          <div className="success-fx" aria-hidden>
            🎯 {lastScore}! GREAT!
          </div>
        )}

        <div className="recording-header">
          <span className="cue-counter">
            {cueIndex + 1} / {subtitles.length}
          </span>
          <div className="recording-nav">
            <PixelButton
              variant="ghost"
              size="sm"
              disabled={cueIndex === 0 || phase !== 'idle'}
              onClick={() => {
                setCueIndex((i) => i - 1);
                setLastScore(null);
              }}
            >
              ◀
            </PixelButton>
            <PixelButton
              variant="secondary"
              size="sm"
              onClick={() => void playOriginal()}
              disabled={phase !== 'idle'}
            >
              🔊 ORIGINAL
            </PixelButton>
            <PixelButton
              variant="ghost"
              size="sm"
              disabled={cueIndex >= subtitles.length - 1 || phase !== 'idle'}
              onClick={() => {
                setCueIndex((i) => i + 1);
                setLastScore(null);
              }}
            >
              ▶
            </PixelButton>
          </div>
        </div>

        {cue && (
          <div className="shadow-text-block">
            <p className="shadow-text cue-text">{english}</p>
            {cue.translation && <p className="cue-translation">{cue.translation}</p>}
          </div>
        )}

        <div className="recording-controls">
          {phase === 'idle' || phase === 'scoring' ? (
            <PixelButton
              variant="accent"
              onClick={() => void startShadowing()}
              disabled={phase === 'scoring'}
            >
              🎤 START SHADOWING
            </PixelButton>
          ) : (
            <PixelButton variant="danger" onClick={stopRecording}>
              ⏹ STOP
            </PixelButton>
          )}
          {phaseLabel && <span className="recording-indicator">{phaseLabel}</span>}
        </div>

        {lastScore != null && phase === 'idle' && (
          <p className={`shadow-score ${lastScore >= 90 ? 'high' : lastScore >= 70 ? 'mid' : 'low'}`}>
            SCORE: {lastScore}/100
          </p>
        )}

        {recordings.length > 0 && (
          <div className="recordings-list">
            <div className="recordings-header-row">
              <h4>YOUR RECORDINGS</h4>
              <PixelButton variant="ghost" size="sm" onClick={() => setPendingClear(true)}>
                CLEAR
              </PixelButton>
            </div>
            {recordings.slice(0, 10).map((rec) => (
              <div key={rec.id} className="recording-item">
                <p className="rec-cue cue-text">
                  {rec.cueText.length > 60 ? `${rec.cueText.slice(0, 60)}…` : rec.cueText}
                </p>
                {rec.translation && (
                  <p className="cue-translation">
                    {rec.translation.length > 60
                      ? `${rec.translation.slice(0, 60)}…`
                      : rec.translation}
                  </p>
                )}
                {rec.score != null && (
                  <span className={`rec-score ${rec.score >= 90 ? 'high' : ''}`}>
                    {rec.score}/100
                  </span>
                )}
                <PixelAudioPlayer src={rec.url} />
              </div>
            ))}
          </div>
        )}
      </div>
    </PixelPanel>
  );
}

function PixelAudioPlayer({ src }: { src: string }) {
  const audioRef = useRef<HTMLAudioElement>(null);
  const [playing, setPlaying] = useState(false);
  const [progress, setProgress] = useState(0);

  useEffect(() => {
    const el = audioRef.current;
    if (!el) return;
    const onTime = () => {
      if (el.duration) setProgress((el.currentTime / el.duration) * 100);
    };
    const onEnded = () => {
      setPlaying(false);
      setProgress(0);
    };
    el.addEventListener('timeupdate', onTime);
    el.addEventListener('ended', onEnded);
    return () => {
      el.removeEventListener('timeupdate', onTime);
      el.removeEventListener('ended', onEnded);
    };
  }, [src]);

  const toggle = async () => {
    const el = audioRef.current;
    if (!el) return;
    if (el.paused) {
      await el.play();
      setPlaying(true);
    } else {
      el.pause();
      setPlaying(false);
    }
  };

  return (
    <div className="pixel-audio-player">
      <audio ref={audioRef} src={src} preload="metadata" />
      <button type="button" className="pixel-audio-play" onClick={() => void toggle()}>
        {playing ? '⏸' : '▶'}
      </button>
      <div className="pixel-audio-track">
        <div className="pixel-audio-fill" style={{ width: `${progress}%` }} />
        <div
          className={`pixel-audio-runner${playing ? ' running' : ''}`}
          style={{ left: `calc(${progress}% - 6px)` }}
        >
          👾
        </div>
      </div>
    </div>
  );
}
