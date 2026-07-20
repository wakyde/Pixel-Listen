import type { SubtitleCue } from '../types';
import { splitBilingualText } from './bilingualText';

function parseTime(timeStr: string): number {
  const parts = timeStr.trim().replace(',', '.').split(':');
  if (parts.length === 3) {
    const [h, m, s] = parts;
    return parseInt(h, 10) * 3600 + parseInt(m, 10) * 60 + parseFloat(s);
  }
  if (parts.length === 2) {
    const [m, s] = parts;
    return parseInt(m, 10) * 60 + parseFloat(s);
  }
  return parseFloat(parts[0]);
}

function formatSrtTime(seconds: number): string {
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = seconds % 60;
  const ms = Math.round((s % 1) * 1000);
  const ss = Math.floor(s);
  return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}:${String(ss).padStart(2, '0')},${String(ms).padStart(3, '0')}`;
}

/** Clean subtitle text: strip tags, normalize newlines, decode common entities. */
export function cleanSubtitleText(raw: string): string {
  return raw
    .replace(/\r\n/g, '\n')
    .replace(/<br\s*\/?>/gi, '\n')
    .replace(/<\/?[^>]+>/g, '')
    .replace(/\{[^}]*\}/g, '')
    .replace(/&nbsp;/gi, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/[ \t]+\n/g, '\n')
    .replace(/\n{3,}/g, '\n\n')
    .replace(/[ \t]{2,}/g, ' ')
    .trim();
}

export function parseSRT(content: string): SubtitleCue[] {
  const cues: SubtitleCue[] = [];
  const normalized = content.replace(/^\uFEFF/, '').replace(/\r\n/g, '\n').replace(/\r/g, '\n');
  const blocks = normalized.trim().split(/\n\s*\n/);

  for (const block of blocks) {
    const lines = block.trim().split('\n');
    if (lines.length < 2) continue;

    let timeLineIdx = 0;
    if (/^\d+$/.test(lines[0].trim())) timeLineIdx = 1;

    const timeMatch = lines[timeLineIdx]?.match(
      /(\d{1,2}:\d{2}:\d{2}[.,]\d{1,3})\s*-->\s*(\d{1,2}:\d{2}:\d{2}[.,]\d{1,3})/
    );
    if (!timeMatch) continue;

    const text = cleanSubtitleText(lines.slice(timeLineIdx + 1).join('\n'));
    if (!text) continue;

    const start = parseTime(timeMatch[1]);
    const end = parseTime(timeMatch[2]);
    if (!Number.isFinite(start) || !Number.isFinite(end) || end <= start) continue;

    const { english, nativeTranslation } = splitBilingualText(text);
    cues.push({
      id: crypto.randomUUID(),
      start,
      end,
      text: english || text,
      nativeTranslation,
    });
  }
  return cues.sort((a, b) => a.start - b.start || a.end - b.end);
}

export function parseVTT(content: string): SubtitleCue[] {
  const cleaned = content
    .replace(/^\uFEFF/, '')
    .replace(/^WEBVTT[^\n]*\n/i, '')
    .replace(/NOTE[^\n]*\n(?:[^\n]+\n)*\n/g, '')
    .trim();
  return parseSRT(cleaned);
}

export function cuesToSRT(cues: SubtitleCue[]): string {
  return cues
    .map((cue, i) => {
      const parts = [`${i + 1}`, `${formatSrtTime(cue.start)} --> ${formatSrtTime(cue.end)}`, cue.text];
      const trans = cue.translation ?? cue.nativeTranslation;
      if (trans) parts.push(trans);
      return parts.join('\n');
    })
    .join('\n\n');
}

/** Binary-search the cue active at `time`. Prefers the latest-starting match on overlaps. */
export function getActiveCue(cues: SubtitleCue[], time: number): SubtitleCue | null {
  if (cues.length === 0 || !Number.isFinite(time)) return null;

  let lo = 0;
  let hi = cues.length - 1;
  let candidate: SubtitleCue | null = null;

  while (lo <= hi) {
    const mid = (lo + hi) >> 1;
    const cue = cues[mid];
    if (time < cue.start) {
      hi = mid - 1;
    } else if (time >= cue.end) {
      lo = mid + 1;
    } else {
      candidate = cue;
      lo = mid + 1;
    }
  }

  if (candidate) return candidate;

  for (let i = cues.length - 1; i >= 0; i--) {
    const c = cues[i];
    if (time >= c.start && time < c.end) return c;
  }
  return null;
}

export function getActiveCueIndex(cues: SubtitleCue[], time: number): number {
  const cue = getActiveCue(cues, time);
  if (!cue) return -1;
  return cues.findIndex((c) => c.id === cue.id);
}

export function splitIntoSentences(text: string): string[] {
  return text
    .split(/(?<=[.!?])\s+/)
    .map((s) => s.trim())
    .filter(Boolean);
}