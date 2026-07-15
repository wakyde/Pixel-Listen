const CJK_RE = /[\u3040-\u30ff\u3400-\u9fff\uf900-\ufaff]/;

function isMostlyCjk(line: string): boolean {
  const chars = line.replace(/\s/g, '');
  if (!chars) return false;
  let cjk = 0;
  for (const ch of chars) {
    if (CJK_RE.test(ch)) cjk++;
  }
  return cjk / chars.length >= 0.3;
}

/**
 * Split bilingual subtitle text into English + Chinese/native translation.
 * Common ASS styles put ZH and EN on separate lines (\\N).
 */
export function splitBilingualText(raw: string): {
  english: string;
  nativeTranslation?: string;
} {
  const text = raw.replace(/\r\n/g, '\n').trim();
  if (!text) return { english: '' };

  const lines = text
    .split('\n')
    .map((l) => l.trim())
    .filter(Boolean);

  if (lines.length === 0) return { english: '' };

  if (lines.length === 1) {
    if (isMostlyCjk(lines[0])) {
      return { english: lines[0], nativeTranslation: undefined };
    }
    return { english: lines[0] };
  }

  const cjkLines = lines.filter(isMostlyCjk);
  const enLines = lines.filter((l) => !isMostlyCjk(l));

  if (enLines.length > 0 && cjkLines.length > 0) {
    return {
      english: enLines.join('\n'),
      nativeTranslation: cjkLines.join('\n'),
    };
  }

  // Prefer English-looking lines; fall back to full text
  if (enLines.length > 0) return { english: enLines.join('\n') };
  return { english: text };
}

/** English-only text for typing / shadow comparison. */
export function getEnglishText(text: string): string {
  return splitBilingualText(text).english || text;
}

/**
 * Merge consecutive cues that form one sentence (no terminal punctuation,
 * or next starts with lowercase / continuation).
 */
export function shouldMergeCues(
  a: { text: string; end: number },
  b: { text: string; start: number }
): boolean {
  const gap = b.start - a.end;
  if (gap > 1.2) return false;
  const aText = getEnglishText(a.text).trim();
  const bText = getEnglishText(b.text).trim();
  if (!aText || !bText) return false;
  if (/[.!?…"”']$/.test(aText)) return false;
  if (/^[a-z]/.test(bText)) return true;
  if (gap <= 0.35) return true;
  if (/[,;:—–-]$/.test(aText)) return true;
  return false;
}

export function mergeCueGroups<T extends { id: string; text: string; start: number; end: number; translation?: string }>(
  cues: T[],
  selectedIds: Set<string>
): {
  text: string;
  translation?: string;
  start: number;
  end: number;
  ids: string[];
}[] {
  const selected = cues.filter((c) => selectedIds.has(c.id));
  if (selected.length === 0) return [];

  const groups: {
    text: string;
    translation?: string;
    start: number;
    end: number;
    ids: string[];
  }[] = [];

  let current = {
    text: getEnglishText(selected[0].text),
    translation: selected[0].translation,
    start: selected[0].start,
    end: selected[0].end,
    ids: [selected[0].id],
  };

  for (let i = 1; i < selected.length; i++) {
    const cue = selected[i];
    const prev = selected[i - 1];
    const consecutive =
      cues.findIndex((c) => c.id === cue.id) ===
      cues.findIndex((c) => c.id === prev.id) + 1;

    if (consecutive && shouldMergeCues(current, cue)) {
      current.text = `${current.text} ${getEnglishText(cue.text)}`.replace(/\s+/g, ' ').trim();
      current.end = cue.end;
      current.ids.push(cue.id);
      if (cue.translation) {
        current.translation = current.translation
          ? `${current.translation} ${cue.translation}`
          : cue.translation;
      }
    } else {
      groups.push(current);
      current = {
        text: getEnglishText(cue.text),
        translation: cue.translation,
        start: cue.start,
        end: cue.end,
        ids: [cue.id],
      };
    }
  }
  groups.push(current);
  return groups;
}
