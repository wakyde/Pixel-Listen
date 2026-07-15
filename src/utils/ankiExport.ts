import JSZip from 'jszip';
import type { AnkiCard } from '../types';

/** yyyymmdd_HHmmss_<6-char uid> — safe for all file systems */
function generateMediaFilename(ext: string): string {
  const now = new Date();
  const pad = (n: number, w = 2) => String(n).padStart(w, '0');
  const datePart =
    `${now.getFullYear()}${pad(now.getMonth() + 1)}${pad(now.getDate())}` +
    `_${pad(now.getHours())}${pad(now.getMinutes())}${pad(now.getSeconds())}`;
  const uid = crypto.randomUUID().replace(/-/g, '').slice(0, 6);
  return `pl_${datePart}_${uid}.${ext}`;
}

async function extractAudioClip(
  mediaUrl: string,
  start: number,
  end: number,
  _isVideo: boolean
): Promise<Blob | null> {
  try {
    const response = await fetch(mediaUrl);
    const arrayBuffer = await response.arrayBuffer();

    const audioCtx = new AudioContext();
    const audioBuffer = await audioCtx.decodeAudioData(arrayBuffer.slice(0));
    await audioCtx.close();

    const sampleRate = audioBuffer.sampleRate;
    const startSample = Math.floor(start * sampleRate);
    const endSample = Math.min(Math.floor(end * sampleRate), audioBuffer.length);
    const length = endSample - startSample;
    if (length <= 0) return null;

    const offlineCtx = new OfflineAudioContext(
      audioBuffer.numberOfChannels,
      length,
      sampleRate
    );
    const source = offlineCtx.createBufferSource();
    source.buffer = audioBuffer;
    source.connect(offlineCtx.destination);
    source.start(0, start, end - start);
    const rendered = await offlineCtx.startRendering();

    const wav = audioBufferToWav(rendered);
    return new Blob([wav], { type: 'audio/wav' });
  } catch {
    return null;
  }
}

/** Capture a short video segment via MediaRecorder (best-effort). */
async function extractVideoClip(
  mediaUrl: string,
  start: number,
  end: number
): Promise<Blob | null> {
  try {
    const video = document.createElement('video');
    video.src = mediaUrl;
    video.muted = true;
    video.playsInline = true;
    await new Promise<void>((resolve, reject) => {
      video.onloadedmetadata = () => resolve();
      video.onerror = () => reject(new Error('video load failed'));
    });
    video.currentTime = Math.max(0, start);
    await new Promise<void>((resolve) => {
      video.onseeked = () => resolve();
    });

    const stream = (video as HTMLVideoElement & { captureStream?: () => MediaStream }).captureStream?.();
    if (!stream) return null;

    const chunks: Blob[] = [];
    const recorder = new MediaRecorder(stream, { mimeType: 'video/webm' });
    recorder.ondataavailable = (e) => {
      if (e.data.size > 0) chunks.push(e.data);
    };

    const durationMs = Math.max(200, (end - start) * 1000);
    const done = new Promise<Blob>((resolve) => {
      recorder.onstop = () => resolve(new Blob(chunks, { type: 'video/webm' }));
    });

    recorder.start();
    await video.play();
    await new Promise((r) => setTimeout(r, durationMs));
    video.pause();
    recorder.stop();
    stream.getTracks().forEach((t) => t.stop());
    const blob = await done;
    return blob.size > 0 ? blob : null;
  } catch {
    return null;
  }
}

function audioBufferToWav(buffer: AudioBuffer): ArrayBuffer {
  const numChannels = buffer.numberOfChannels;
  const sampleRate = buffer.sampleRate;
  const format = 1;
  const bitDepth = 16;
  const bytesPerSample = bitDepth / 8;
  const blockAlign = numChannels * bytesPerSample;
  const dataLength = buffer.length * blockAlign;
  const headerLength = 44;
  const arrayBuffer = new ArrayBuffer(headerLength + dataLength);
  const view = new DataView(arrayBuffer);

  const writeString = (offset: number, str: string) => {
    for (let i = 0; i < str.length; i++) view.setUint8(offset + i, str.charCodeAt(i));
  };

  writeString(0, 'RIFF');
  view.setUint32(4, 36 + dataLength, true);
  writeString(8, 'WAVE');
  writeString(12, 'fmt ');
  view.setUint32(16, 16, true);
  view.setUint16(20, format, true);
  view.setUint16(22, numChannels, true);
  view.setUint32(24, sampleRate, true);
  view.setUint32(28, sampleRate * blockAlign, true);
  view.setUint16(32, blockAlign, true);
  view.setUint16(34, bitDepth, true);
  writeString(36, 'data');
  view.setUint32(40, dataLength, true);

  let offset = 44;
  for (let i = 0; i < buffer.length; i++) {
    for (let ch = 0; ch < numChannels; ch++) {
      const sample = Math.max(-1, Math.min(1, buffer.getChannelData(ch)[i]));
      view.setInt16(offset, sample < 0 ? sample * 0x8000 : sample * 0x7fff, true);
      offset += 2;
    }
  }
  return arrayBuffer;
}

/**
 * Export Anki-importable zip:
 * - TSV with html + tags (importable via Anki File → Import)
 * - Audio clips; optional video clips when source is video
 *
 * Card layout (cart mode): Front = translation, Back = original + audio/video
 */
export async function exportAnkiDeck(
  deckName: string,
  cards: AnkiCard[],
  mediaUrl: string | null,
  isVideo: boolean,
  ankiMediaDirHandle?: FileSystemDirectoryHandle | null
): Promise<void> {
  const zip = new JSZip();
  const mediaFiles: { name: string; blob: Blob }[] = [];

  const noteLines: string[] = [];
  for (let i = 0; i < cards.length; i++) {
    const card = cards[i];
    let mediaTags = '';
    if (mediaUrl && card.audioStart != null && card.audioEnd != null) {
      const clip = await extractAudioClip(mediaUrl, card.audioStart, card.audioEnd, isVideo);
      if (clip) {
        const filename = generateMediaFilename('wav');
        mediaFiles.push({ name: filename, blob: clip });
        zip.file(filename, clip);
        mediaTags += `[sound:${filename}] `;
      }
      if (isVideo) {
        const vclip = await extractVideoClip(mediaUrl, card.audioStart, card.audioEnd);
        if (vclip) {
          const vname = generateMediaFilename('webm');
          mediaFiles.push({ name: vname, blob: vclip });
          zip.file(vname, vclip);
          mediaTags += `[sound:${vname}] `;
        }
      }
    }
    const front = escapeField(card.front);
    const back = escapeField(card.back) + (mediaTags ? `<br>${mediaTags.trim()}` : '');
    const tags = card.tags.join(' ');
    noteLines.push(`${front}\t${back}\t${tags}`);
  }

  // Anki text import directives
  const header =
    '#separator:tab\n#html:true\n#tags column:3\n#deck column:4\n#notetype column:5\n';
  const tsv =
    header +
    noteLines.map((l) => `${l}\t${deckName}\tBasic`).join('\n');
  const tsvFilename = `${deckName}.txt`;

  // If the user has picked an Anki media directory, write files directly into it
  if (ankiMediaDirHandle && mediaFiles.length > 0) {
    for (const { name, blob } of mediaFiles) {
      try {
        const fileHandle = await ankiMediaDirHandle.getFileHandle(name, { create: true });
        const writable = await fileHandle.createWritable();
        await writable.write(blob);
        await writable.close();
      } catch {
        // Silently ignore individual write failures; continue with the rest
      }
    }
    // Only download the TSV cards file — media is already in Anki's folder
    const tsvBlob = new Blob([tsv], { type: 'text/plain' });
    downloadBlob(tsvBlob, tsvFilename);
    return;
  }

  // Fallback: bundle everything into a ZIP
  zip.file(tsvFilename, tsv);

  if (mediaFiles.length > 0) {
    for (const { name, blob } of mediaFiles) {
      zip.file(name, blob);
    }
    zip.file(
      'media.json',
      JSON.stringify(
        Object.fromEntries(mediaFiles.map(({ name }, i) => [String(i), name]))
      )
    );
    zip.file('README_IMPORT.txt', [
      'How to import into Anki:',
      '1. Unzip this archive into a folder.',
      '2. In Anki: File → Import → select the .txt file.',
      '3. Map fields: Front, Back, Tags. Note type: Basic.',
      '4. Copy the .wav/.webm files into your Anki media collection folder',
      '   (Anki → Tools → Check Media → Open media folder).',
      '5. Tip: set your Anki media path in Pixel Listen Settings to skip this step.',
      '',
    ].join('\n'));
  }

  const blob = await zip.generateAsync({ type: 'blob' });
  downloadBlob(blob, `${deckName}_anki_export.zip`);
}

function escapeField(text: string): string {
  return text.replace(/\t/g, ' ').replace(/\n/g, '<br>');
}

function downloadBlob(blob: Blob, filename: string) {
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}

/** Front = translation (or EN if missing), Back = original English */
export function buildCartCards(
  items: { text: string; translation?: string; start?: number; end?: number }[]
): AnkiCard[] {
  return items.map((item) => ({
    front: item.translation?.trim() || item.text,
    back: item.text,
    audioStart: item.start,
    audioEnd: item.end,
    tags: ['pixel-listen', 'cart'],
    mode: 'cart' as const,
  }));
}

export function buildCustomCards(
  items: { text: string; translation?: string; start?: number; end?: number }[]
): AnkiCard[] {
  return buildCartCards(items);
}

export function buildAiCards(
  recommendations: { front: string; back: string; start: number; end: number }[]
): AnkiCard[] {
  return recommendations.map((r) => ({
    front: r.front,
    back: r.back,
    audioStart: r.start,
    audioEnd: r.end,
    tags: ['pixel-listen', 'ai-recommended'],
    mode: 'ai' as const,
  }));
}
