import { useState, useRef, useEffect } from 'react';
import { useAppStore } from '../../store/appStore';
import { useMediaRef } from '../../context/MediaContext';
import { getActiveCue } from '../../utils/subtitleParser';
import { getEnglishText } from '../../utils/bilingualText';
import { safePlay, safePause, seekTo } from '../../utils/mediaControl';
import { playSuccessSound } from '../../utils/soundEffects';
import { PixelButton, PixelPanel } from '../PixelUI';

function normalizeForCompare(s: string): string {
  return s
    .toLowerCase()
    .replace(/[^\p{L}\p{N}\s']/gu, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function calcAccuracy(expected: string, typed: string): number {
  const exp = normalizeForCompare(getEnglishText(expected));
  const typ = normalizeForCompare(typed);
  if (!exp) return 0;
  if (exp === typ) return 100;
  let matches = 0;
  const minLen = Math.min(exp.length, typ.length);
  for (let i = 0; i < minLen; i++) {
    if (exp[i] === typ[i]) matches++;
  }
  return Math.round((matches / Math.max(exp.length, typ.length)) * 100);
}

export function TypingMode() {
  const mediaRef = useMediaRef();
  const { subtitles, currentTime, setCurrentTime, setIsPlaying } = useAppStore();
  const [cueIndex, setCueIndex] = useState(0);
  const [input, setInput] = useState('');
  const [result, setResult] = useState<{ accuracy: number; shown: boolean; perfect: boolean } | null>(
    null
  );
  const [showBurst, setShowBurst] = useState(false);
  const [autoPlayPending, setAutoPlayPending] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);
  const stopAtRef = useRef<number | null>(null);

  const cue = subtitles[cueIndex];
  const english = cue ? getEnglishText(cue.text) : '';
  const activeCue = getActiveCue(subtitles, currentTime);

  useEffect(() => {
    if (activeCue && subtitles.length > 0 && !autoPlayPending) {
      const idx = subtitles.findIndex((c) => c.id === activeCue.id);
      if (idx >= 0 && idx !== cueIndex) setCueIndex(idx);
    }
  }, [activeCue, subtitles, cueIndex, autoPlayPending]);

  useEffect(() => {
    const end = stopAtRef.current;
    if (end == null) return;
    if (currentTime >= end - 0.05) {
      safePause(mediaRef.current);
      setIsPlaying(false);
      stopAtRef.current = null;
    }
  }, [currentTime, mediaRef, setIsPlaying]);

  const playCueAt = async (index: number) => {
    const target = subtitles[index];
    if (!target) return;
    stopAtRef.current = target.end;
    const t = seekTo(mediaRef.current, target.start);
    setCurrentTime(t);
    const ok = await safePlay(mediaRef.current);
    setIsPlaying(ok);
    setInput('');
    setResult(null);
    setShowBurst(false);
    inputRef.current?.focus();
  };

  useEffect(() => {
    if (!autoPlayPending) return;
    setAutoPlayPending(false);
    void playCueAt(cueIndex);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [cueIndex, autoPlayPending]);

  const playCue = () => {
    void playCueAt(cueIndex);
  };

  const checkAnswer = () => {
    if (!cue) return;
    const accuracy = calcAccuracy(cue.text, input);
    const perfect = accuracy === 100;
    setResult({ accuracy, shown: true, perfect });
    safePause(mediaRef.current);
    setIsPlaying(false);
    stopAtRef.current = null;
    if (perfect) {
      playSuccessSound();
      setShowBurst(true);
      window.setTimeout(() => setShowBurst(false), 1400);
    }
  };

  const goTo = (delta: number) => {
    const next = cueIndex + delta;
    if (next < 0 || next >= subtitles.length) return;
    setInput('');
    setResult(null);
    setShowBurst(false);
    setAutoPlayPending(true);
    setCueIndex(next);
  };

  if (subtitles.length === 0) {
    return (
      <PixelPanel title="TYPING MODE">
        <p className="empty-hint">Load subtitles first to practice typing</p>
      </PixelPanel>
    );
  }

  return (
    <PixelPanel title="TYPING MODE">
      <div className={`typing-mode${showBurst ? ' success-burst' : ''}`}>
        {showBurst && <div className="success-fx" aria-hidden>✨ PERFECT! ✨</div>}
        <div className="typing-header">
          <span className="cue-counter">
            {cueIndex + 1} / {subtitles.length}
          </span>
          <PixelButton variant="secondary" size="sm" onClick={playCue}>
            🔊 REPLAY
          </PixelButton>
        </div>

        <p className="typing-hint">Listen and type the English line (case ignored):</p>

        {result?.shown && cue && (
          <div className="typing-reveal">
            <p className="cue-text">{english}</p>
            {cue.translation && <p className="cue-translation">{cue.translation}</p>}
          </div>
        )}

        <input
          ref={inputRef}
          className="pixel-input typing-input"
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === 'Enter') checkAnswer();
          }}
          placeholder="Type English here..."
          autoComplete="off"
          spellCheck={false}
        />

        <div className="typing-actions">
          <PixelButton
            variant="ghost"
            size="sm"
            onClick={() => goTo(-1)}
            disabled={cueIndex === 0}
          >
            ← PREV
          </PixelButton>
          <PixelButton variant="accent" onClick={checkAnswer} disabled={!input.trim()}>
            CHECK
          </PixelButton>
          <PixelButton
            variant="ghost"
            size="sm"
            onClick={() => goTo(1)}
            disabled={cueIndex >= subtitles.length - 1}
          >
            NEXT →
          </PixelButton>
        </div>

        {result?.shown && cue && (
          <div
            className={`typing-result ${result.perfect ? 'perfect' : result.accuracy >= 80 ? 'good' : result.accuracy >= 50 ? 'ok' : 'bad'}`}
          >
            <p className="accuracy-score">{result.accuracy}% match</p>
            <p className="expected-text">Expected: {english}</p>
            <p className="typed-text">You typed: {input}</p>
          </div>
        )}
      </div>
    </PixelPanel>
  );
}
