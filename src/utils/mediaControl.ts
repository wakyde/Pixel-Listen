/** Safely play media; returns false if playback was blocked/failed. */
export async function safePlay(
  el: HTMLMediaElement | null | undefined
): Promise<boolean> {
  if (!el) return false;
  try {
    await el.play();
    return true;
  } catch {
    return false;
  }
}

export function safePause(el: HTMLMediaElement | null | undefined): void {
  if (!el) return;
  el.pause();
}

export function seekTo(
  el: HTMLMediaElement | null | undefined,
  time: number
): number {
  if (!el) return time;
  const duration = Number.isFinite(el.duration) ? el.duration : time;
  const clamped = Math.max(0, Math.min(time, duration || time));
  el.currentTime = clamped;
  return clamped;
}
