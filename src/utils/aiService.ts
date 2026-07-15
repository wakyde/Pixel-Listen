import type { AIConfig, GrammarAnalysis } from '../types';

export type AIServiceConfig = AIConfig;

const DEFAULT_BASE_URL = 'https://api.openai.com/v1';

function resolveBaseUrl(config: AIServiceConfig): string {
  const url = config.baseUrl.trim();
  if (!url) return DEFAULT_BASE_URL;
  return url.replace(/\/$/, '');
}

function authHeaders(config: AIServiceConfig): HeadersInit {
  return {
    'Content-Type': 'application/json',
    Authorization: `Bearer ${config.apiKey}`,
  };
}

const GRAMMAR_PROMPT = (sentence: string) =>
  `Analyze this English sentence for a language learner. Return ONLY valid JSON with keys: structure (string), keyPoints (string array), vocabulary (array of {word, meaning}), suggestions (string array). Sentence: "${sentence}"`;

export async function translateText(
  text: string,
  targetLang: string,
  config?: AIServiceConfig
): Promise<string> {
  if (!config?.apiKey) {
    // Without API key: only return when caller already provided nativeTranslation
    return text;
  }
  try {
    const baseUrl = resolveBaseUrl(config);
    const res = await fetch(`${baseUrl}/chat/completions`, {
      method: 'POST',
      headers: authHeaders(config),
      body: JSON.stringify({
        model: config.chatModel || 'gpt-4o-mini',
        messages: [
          {
            role: 'system',
            content: `Translate to ${targetLang}. Return only the translation, no explanation.`,
          },
          { role: 'user', content: text },
        ],
        temperature: 0.3,
      }),
    });
    if (!res.ok) throw new Error('Translation failed');
    const data = await res.json();
    return data.choices?.[0]?.message?.content?.trim() ?? text;
  } catch {
    return text;
  }
}

export async function analyzeGrammar(
  sentence: string,
  config?: AIServiceConfig
): Promise<GrammarAnalysis> {
  const fallback: GrammarAnalysis = {
    sentence,
    structure: 'Subject + Verb + Object (basic SVO)',
    keyPoints: ['Check verb tense consistency', 'Note subject-verb agreement'],
    vocabulary: sentence
      .split(/\s+/)
      .filter((w) => w.length > 4)
      .slice(0, 5)
      .map((w) => ({ word: w.replace(/[^a-zA-Z]/g, ''), meaning: '(look up in dictionary)' })),
    suggestions: ['Practice reading aloud', 'Shadow the original audio'],
  };

  if (!config?.apiKey) return fallback;

  try {
    const baseUrl = resolveBaseUrl(config);
    const res = await fetch(`${baseUrl}/chat/completions`, {
      method: 'POST',
      headers: authHeaders(config),
      body: JSON.stringify({
        model: config.chatModel || 'gpt-4o-mini',
        messages: [
          { role: 'system', content: 'You are an English grammar tutor. Respond only with valid JSON.' },
          { role: 'user', content: GRAMMAR_PROMPT(sentence) },
        ],
        temperature: 0.4,
      }),
    });
    if (!res.ok) return fallback;
    const data = await res.json();
    const content = data.choices?.[0]?.message?.content ?? '';
    const jsonMatch = content.match(/\{[\s\S]*\}/);
    if (!jsonMatch) return fallback;
    const parsed = JSON.parse(jsonMatch[0]);
    return { sentence, ...parsed };
  } catch {
    return fallback;
  }
}

export async function generateAnkiRecommendations(
  cues: { text: string; start: number; end: number }[],
  config?: AIServiceConfig
): Promise<{ front: string; back: string; start: number; end: number }[]> {
  if (!config?.apiKey || cues.length === 0) {
    return cues.slice(0, 10).map((c) => ({
      front: `Listen and repeat:\n${c.text.slice(0, 80)}`,
      back: c.text,
      start: c.start,
      end: c.end,
    }));
  }

  const sample = cues.slice(0, 20).map((c) => c.text).join('\n');
  try {
    const baseUrl = resolveBaseUrl(config);
    const res = await fetch(`${baseUrl}/chat/completions`, {
      method: 'POST',
      headers: authHeaders(config),
      body: JSON.stringify({
        model: config.chatModel || 'gpt-4o-mini',
        messages: [
          {
            role: 'system',
            content:
              'Create Anki flashcard pairs for English listening practice. Return JSON array of {front, back, sourceText} where front is a cloze or prompt and back is the full sentence. Max 15 cards.',
          },
          { role: 'user', content: sample },
        ],
        temperature: 0.5,
      }),
    });
    if (!res.ok) throw new Error('AI failed');
    const data = await res.json();
    const content = data.choices?.[0]?.message?.content ?? '';
    const jsonMatch = content.match(/\[[\s\S]*\]/);
    if (!jsonMatch) throw new Error('No JSON');
    const cards = JSON.parse(jsonMatch[0]) as { front: string; back: string; sourceText?: string }[];
    return cards.map((card) => {
      const match = cues.find((c) => c.text.includes(card.sourceText ?? card.back));
      return {
        front: card.front,
        back: card.back,
        start: match?.start ?? 0,
        end: match?.end ?? 0,
      };
    });
  } catch {
    return cues.slice(0, 10).map((c) => ({
      front: `Fill in: ${c.text.replace(/\b\w{4,}\b/g, '____').slice(0, 100)}`,
      back: c.text,
      start: c.start,
      end: c.end,
    }));
  }
}

export async function transcribeWithWhisper(
  audioBlob: Blob,
  config?: AIServiceConfig
): Promise<string> {
  if (!config?.apiKey) {
    throw new Error('API key required for AI transcription');
  }
  const baseUrl = resolveBaseUrl(config);
  const formData = new FormData();
  formData.append('file', audioBlob, 'audio.webm');
  formData.append('model', config.transcriptionModel || 'whisper-1');
  formData.append('response_format', 'verbose_json');

  const res = await fetch(`${baseUrl}/audio/transcriptions`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${config.apiKey}` },
    body: formData,
  });
  if (!res.ok) throw new Error('Transcription failed');
  const data = await res.json();

  if (data.segments) {
    return data.segments
      .map(
        (s: { start: number; end: number; text: string }, i: number) =>
          `${i + 1}\n${formatSrt(s.start)} --> ${formatSrt(s.end)}\n${s.text.trim()}`
      )
      .join('\n\n');
  }
  return `1\n00:00:00,000 --> 00:00:10,000\n${data.text}`;
}

function formatSrt(sec: number): string {
  const h = Math.floor(sec / 3600);
  const m = Math.floor((sec % 3600) / 60);
  const s = sec % 60;
  const ms = Math.round((s % 1) * 1000);
  const ss = Math.floor(s);
  return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}:${String(ss).padStart(2, '0')},${String(ms).padStart(3, '0')}`;
}

export { transcribeWithLocalWhisper, clearWhisperCache } from './localWhisper';
