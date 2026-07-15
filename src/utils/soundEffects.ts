let audioCtx: AudioContext | null = null;

function ctx(): AudioContext {
  if (!audioCtx) audioCtx = new AudioContext();
  return audioCtx;
}

/** Cheerful ascending chime for perfect typing / high shadow score. */
export function playSuccessSound(): void {
  try {
    const ac = ctx();
    const now = ac.currentTime;
    const notes = [523.25, 659.25, 783.99, 1046.5]; // C5 E5 G5 C6

    notes.forEach((freq, i) => {
      const osc = ac.createOscillator();
      const gain = ac.createGain();
      osc.type = 'square';
      osc.frequency.value = freq;
      gain.gain.setValueAtTime(0.0001, now);
      gain.gain.exponentialRampToValueAtTime(0.12, now + 0.02 + i * 0.08);
      gain.gain.exponentialRampToValueAtTime(0.0001, now + 0.2 + i * 0.08);
      osc.connect(gain);
      gain.connect(ac.destination);
      osc.start(now + i * 0.08);
      osc.stop(now + 0.35 + i * 0.08);
    });
  } catch {
    // ignore — AudioContext may be blocked
  }
}
