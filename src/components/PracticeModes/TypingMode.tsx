import { useState, useRef, useEffect, useCallback, useMemo } from 'react';
import { useAppStore } from '../../store/appStore';
import { useI18n } from '../../context/I18nContext';
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
  const { t } = useI18n();
  const mediaRef = useMediaRef();
  const { subtitles, currentTime, setCurrentTime, setIsPlaying, abLoopActive, pointA, pointB, leadTime } = useAppStore();
  const [cueIndex, setCueIndex] = useState(0);
  const [input, setInput] = useState('');
  const [result, setResult] = useState<{ accuracy: number; shown: boolean; perfect: boolean } | null>(
    null
  );
  const [showBurst, setShowBurst] = useState(false);
  const [autoPlayPending, setAutoPlayPending] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);
  const stopAtRef = useRef<number | null>(null);

  const abFilteredSubtitles = useMemo(() =>
    abLoopActive && pointA != null && pointB != null
      ? subtitles.filter((cue) => cue.start < pointB && cue.end > pointA)
      : subtitles
  , [abLoopActive, pointA, pointB, subtitles]);
  const safeCueIndex = Math.min(cueIndex, Math.max(0, abFilteredSubtitles.length - 1));
  const cue = abFilteredSubtitles[safeCueIndex];
  const english = cue ? getEnglishText(cue.text) : '';
  const activeCue = getActiveCue(subtitles, currentTime);

  useEffect(() => {
    if (safeCueIndex !== cueIndex && abFilteredSubtitles.length > 0) {
      setCueIndex(safeCueIndex);
    }
  }, [safeCueIndex, cueIndex, abFilteredSubtitles.length]);

  useEffect(() => {
    if (activeCue && abFilteredSubtitles.length > 0 && !autoPlayPending) {
      const idx = abFilteredSubtitles.findIndex((c) => c.id === activeCue.id);
      if (idx >= 0 && idx !== cueIndex) setCueIndex(idx);
    }
  }, [activeCue, abFilteredSubtitles, cueIndex, autoPlayPending]);

  useEffect(() => {
    const end = stopAtRef.current;
    if (end == null) return;
    if (currentTime >= end - 0.05) {
      safePause(mediaRef.current);
      setIsPlaying(false);
      stopAtRef.current = null;
    }
  }, [currentTime, mediaRef, setIsPlaying]);

  const abFilteredRef = useRef(abFilteredSubtitles);
  abFilteredRef.current = abFilteredSubtitles;

  const playCueAt = useCallback(async (index: number) => {
    const target = abFilteredRef.current[index];
    if (!target) return;
    stopAtRef.current = target.end;
    const seekTarget = Math.max(0, target.start - leadTime / 1000);
    const t = seekTo(mediaRef.current, seekTarget);
    setCurrentTime(t);
    const ok = await safePlay(mediaRef.current);
    setIsPlaying(ok);
    setInput('');
    setResult(null);
    setShowBurst(false);
    inputRef.current?.focus();
  }, [leadTime, mediaRef, setCurrentTime, setIsPlaying]);

  useEffect(() => {
    if (!autoPlayPending) return;
    setAutoPlayPending(false);
    void playCueAt(cueIndex);
  }, [cueIndex, autoPlayPending, playCueAt]);

  const playCue = () => {
    void playCueAt(cueIndex);
  };

  const togglePlayPause = useCallback(async () => {
    const el = mediaRef.current;
    if (!el || !cue) return;
    if (el.paused) {
      stopAtRef.current = cue.end;
      const seekTarget = Math.max(0, cue.start - leadTime / 1000);
      const t = seekTo(el, seekTarget);
      setCurrentTime(t);
      const ok = await safePlay(el);
      setIsPlaying(ok);
    } else {
      safePause(el);
      setIsPlaying(false);
      stopAtRef.current = null;
    }
  }, [mediaRef, cue, leadTime, setCurrentTime, setIsPlaying]);

  const goTo = useCallback((delta: number) => {
    const len = abFilteredRef.current.length;
    const next = cueIndex + delta;
    if (next < 0 || next >= len) return;
    setCueIndex(next);
    setInput('');
    setResult(null);
    setShowBurst(false);
    setAutoPlayPending(true);
  }, [cueIndex]);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.ctrlKey && e.key === ' ') {
        e.preventDefault();
        void togglePlayPause();
        return;
      }
      if (e.ctrlKey && (e.key === 'ArrowLeft' || e.key === 'ArrowRight')) {
        e.preventDefault();
        goTo(e.key === 'ArrowLeft' ? -1 : 1);
        return;
      }
      if (e.key === 'ArrowLeft' || e.key === 'ArrowRight') {
        const tag = (e.target as HTMLElement)?.tagName?.toLowerCase();
        if (tag === 'input' || tag === 'textarea' || (e.target as HTMLElement)?.isContentEditable) return;
        e.preventDefault();
        goTo(e.key === 'ArrowLeft' ? -1 : 1);
      }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [togglePlayPause, goTo]);

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

  if (abFilteredSubtitles.length === 0) {
    return (
      <PixelPanel title={t('panel.typing_mode')}>
        <p className="empty-hint">{t('typing.empty_hint')}</p>
      </PixelPanel>
    );
  }

  return (
    <PixelPanel title={t('panel.typing_mode')}>
      <div className={`typing-mode${showBurst ? ' success-burst' : ''}`}>
        {showBurst && <div className="success-fx" aria-hidden>✨ {t('typing.perfect')} ✨</div>}
        <div className="typing-header">
          <span className="cue-counter">
            {cueIndex + 1} / {abFilteredSubtitles.length}
          </span>
          <PixelButton variant="secondary" size="sm" onClick={playCue}>
             {t('typing.replay')}
          </PixelButton>
        </div>

        <p className="typing-hint">{t('typing.hint')}</p>

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
          placeholder={t('typing.placeholder')}
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
            ← {t('typing.prev')}
          </PixelButton>
          <PixelButton variant="accent" onClick={checkAnswer} disabled={!input.trim()}>
            {t('typing.check')}
          </PixelButton>
          <PixelButton
            variant="ghost"
            size="sm"
            onClick={() => goTo(1)}
            disabled={cueIndex >= abFilteredSubtitles.length - 1}
          >
            {t('typing.next')} →
          </PixelButton>
        </div>

        {result?.shown && cue && (
          <div
            className={`typing-result ${result.perfect ? 'perfect' : result.accuracy >= 80 ? 'good' : result.accuracy >= 50 ? 'ok' : 'bad'}`}
          >
            <p className="accuracy-score">{result.accuracy}% {t('typing.match')}</p>
            <p className="expected-text">{t('typing.expected')}: {english}</p>
            <p className="typed-text">{t('typing.you_typed')}: {input}</p>
          </div>
        )}
      </div>
    </PixelPanel>
  );
}