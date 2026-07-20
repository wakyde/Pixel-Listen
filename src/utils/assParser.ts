import type { AssCueMeta, SubtitleCue } from '../types';
import { splitBilingualText } from './bilingualText';

function parseAssTime(timeStr: string): number {
  const parts = timeStr.trim().split(':');
  if (parts.length === 3) {
    const [h, m, s] = parts;
    return parseInt(h, 10) * 3600 + parseInt(m, 10) * 60 + parseFloat(s.replace(',', '.'));
  }
  if (parts.length === 2) {
    const [m, s] = parts;
    return parseInt(m, 10) * 60 + parseFloat(s.replace(',', '.'));
  }
  return parseFloat(timeStr.replace(',', '.'));
}

export function formatAssTime(seconds: number): string {
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const cs = Math.round((seconds % 1) * 100);
  const s = Math.floor(seconds % 60);
  return `${h}:${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}.${String(cs).padStart(2, '0')}`;
}

export function stripAssTags(text: string): string {
  return text
    .replace(/\{[^}]*\}/g, '')
    .replace(/\\h/g, ' ')
    .replace(/\\N/g, '\n')
    .replace(/\\n/g, '\n')
    .replace(/\\[a-zA-Z]+\d*/g, '')
    .replace(/[ \t]+\n/g, '\n')
    .replace(/\n{3,}/g, '\n\n')
    .replace(/[ \t]{2,}/g, ' ')
    .trim();
}

function splitDialogueFields(csv: string): string[] | null {
  const fields: string[] = [];
  let remaining = csv;
  for (let i = 0; i < 9; i++) {
    const idx = remaining.indexOf(',');
    if (idx === -1) return null;
    fields.push(remaining.slice(0, idx).trim());
    remaining = remaining.slice(idx + 1);
  }
  fields.push(remaining);
  return fields;
}

function parseDialogueLine(line: string): {
  meta: AssCueMeta;
  start: number;
  end: number;
  rawText: string;
} | null {
  const match = line.match(/^Dialogue:\s*(.*)$/i);
  if (!match) return null;

  const fields = splitDialogueFields(match[1]);
  if (!fields || fields.length < 10) return null;

  const [layer, start, end, style, name, marginL, marginR, marginV, effect, ...textParts] = fields;
  const rawText = textParts.join(',');

  return {
    meta: { layer, style, name, marginL, marginR, marginV, effect },
    start: parseAssTime(start),
    end: parseAssTime(end),
    rawText,
  };
}

export interface AssParseResult {
  preamble: string;
  cues: SubtitleCue[];
}

export function parseASS(content: string): AssParseResult {
  const lines = content.split(/\r?\n/);
  const cues: SubtitleCue[] = [];
  let firstDialogueIdx = -1;

  for (let i = 0; i < lines.length; i++) {
    if (/^Dialogue:/i.test(lines[i])) {
      if (firstDialogueIdx === -1) firstDialogueIdx = i;
      const parsed = parseDialogueLine(lines[i]);
      if (parsed) {
        const cleaned = stripAssTags(parsed.rawText);
        const { english, nativeTranslation } = splitBilingualText(cleaned);
        cues.push({
          id: crypto.randomUUID(),
          start: parsed.start,
          end: parsed.end,
          text: english || cleaned,
          nativeTranslation,
          rawAssText: parsed.rawText,
          assMeta: parsed.meta,
        });
      }
    }
  }

  const preamble =
    firstDialogueIdx === -1
      ? content.trimEnd()
      : lines.slice(0, firstDialogueIdx).join('\n').trimEnd();

  return { preamble, cues };
}

export function serializeASS(preamble: string, cues: SubtitleCue[]): string {
  const lines = [preamble];
  for (const cue of cues) {
    if (!cue.assMeta) continue;
    const m = cue.assMeta;
    let text = cue.rawAssText ?? cue.text.replace(/\n/g, '\\N');
    const trans = cue.translation ?? cue.nativeTranslation;
    if (!cue.rawAssText && trans) {
      text = `${text}\\N${trans.replace(/\n/g, '\\N')}`;
    }
    lines.push(
      `Dialogue: ${m.layer},${formatAssTime(cue.start)},${formatAssTime(cue.end)},${m.style},${m.name},${m.marginL},${m.marginR},${m.marginV},${m.effect},${text}`
    );
  }
  return lines.join('\n') + '\n';
}

export function getSubtitleFormat(filename: string): 'srt' | 'vtt' | 'ass' | null {
  const ext = filename.split('.').pop()?.toLowerCase();
  if (ext === 'srt') return 'srt';
  if (ext === 'vtt') return 'vtt';
  if (ext === 'ass' || ext === 'ssa') return 'ass';
  return null;
}