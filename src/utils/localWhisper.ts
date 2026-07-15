import { env } from '@xenova/transformers';
import type { LocalWhisperModel } from '../types';

const MODEL_MAP: Record<LocalWhisperModel, string> = {
  tiny: 'Xenova/whisper-tiny',
  base: 'Xenova/whisper-base',
  small: 'Xenova/whisper-small',
};

env.allowLocalModels = false;
env.useBrowserCache = true;
env.remoteHost = 'https://hf.217337.xyz';
env.remotePathTemplate = '{model}/resolve/{revision}/';

type WhisperPipeline = (audio: string, options?: {
  return_timestamps?: boolean | 'word';
  chunk_length_s?: number;
}) => Promise<unknown>;

interface ChunkItem {
  text: string;
  timestamp: [number, number | null];
}

interface TranscriptionResult {
  text: string;
  chunks: ChunkItem[];
}

let cachedTranscriber: WhisperPipeline | null = null;
let cachedModel: string | null = null;

function formatSrtTime(sec: number): string {
  const h = Math.floor(sec / 3600);
  const m = Math.floor((sec % 3600) / 60);
  const s = sec % 60;
  const ms = Math.round((s % 1) * 1000);
  const ss = Math.floor(s);
  return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}:${String(ss).padStart(2, '0')},${String(ms).padStart(3, '0')}`;
}

export function getWhisperModelName(model: LocalWhisperModel): string {
  return MODEL_MAP[model];
}

export async function transcribeWithLocalWhisper(
  audioBlob: Blob,
  model: LocalWhisperModel,
  onProgress?: (progress: number) => void
): Promise<string> {
  const modelName = MODEL_MAP[model];

  if (!cachedTranscriber || cachedModel !== modelName) {
    onProgress?.(0);
    try {
      const { pipeline } = await import('@xenova/transformers');
      cachedTranscriber = (await pipeline('automatic-speech-recognition', modelName, {
        progress_callback: (progress: unknown) => {
          if (typeof progress === 'object' && progress !== null && 'status' in progress) {
            const p = progress as { status: string; progress?: number };
            if (p.status === 'progress' && typeof p.progress === 'number') {
              onProgress?.(Math.round(p.progress));
            }
          }
        },
      })) as WhisperPipeline;
      cachedModel = modelName;
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      throw new Error(
        `Failed to load local Whisper model "${modelName}". ` +
        `This usually means Hugging Face is unreachable from your network. ` +
        `Try using a VPN, or switch Transcription Provider back to API in Settings. ` +
        `Details: ${msg}`
      );
    }
  }

  onProgress?.(100);

  const audioUrl = URL.createObjectURL(audioBlob);
  try {
    const result = (await cachedTranscriber(audioUrl, {
      return_timestamps: true,
      chunk_length_s: 30,
    })) as TranscriptionResult;

    const chunks = result.chunks ?? [];
    if (chunks.length === 0) {
      return `1\n00:00:00,000 --> 00:00:10,000\n${result.text ?? ''}`.trim();
    }

    return chunks
      .map((chunk, i) => {
        const start = chunk.timestamp[0] ?? 0;
        const end = chunk.timestamp[1] ?? start + 5;
        return `${i + 1}\n${formatSrtTime(start)} --> ${formatSrtTime(end)}\n${chunk.text.trim()}`;
      })
      .join('\n\n');
  } finally {
    URL.revokeObjectURL(audioUrl);
  }
}

export function clearWhisperCache(): void {
  cachedTranscriber = null;
  cachedModel = null;
}
