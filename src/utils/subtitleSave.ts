import { serializeASS } from './assParser';
import { cuesToSRT } from './subtitleParser';
import type { SubtitleCue, SubtitleFile } from '../types';

export async function saveSubtitleFile(
  subtitleFile: SubtitleFile,
  cues: SubtitleCue[]
): Promise<{ success: boolean; message: string }> {
  const content = buildSubtitleContent(subtitleFile, cues);

  if (subtitleFile.fileHandle) {
    try {
      const handle = subtitleFile.fileHandle;
      if ((await handle.queryPermission({ mode: 'readwrite' })) !== 'granted') {
        const perm = await handle.requestPermission({ mode: 'readwrite' });
        if (perm !== 'granted') {
          return { success: false, message: 'Write permission denied' };
        }
      }
      const writable = await handle.createWritable();
      await writable.write(content);
      await writable.close();
      return { success: true, message: `Saved to ${subtitleFile.name}` };
    } catch (err) {
      return {
        success: false,
        message: err instanceof Error ? err.message : 'Failed to write file',
      };
    }
  }

  if ('showSaveFilePicker' in window) {
    try {
      const ext = subtitleFile.format === 'ass' ? '.ass' : subtitleFile.format === 'vtt' ? '.vtt' : '.srt';
      const handle = await window.showSaveFilePicker({
        suggestedName: subtitleFile.name,
        types: [
          {
            description: 'Subtitle file',
            accept: { 'text/plain': [ext] },
          },
        ],
      });
      const writable = await handle.createWritable();
      await writable.write(content);
      await writable.close();
      return { success: true, message: `Saved to ${handle.name}` };
    } catch (err) {
      if (err instanceof DOMException && err.name === 'AbortError') {
        return { success: false, message: 'Save cancelled' };
      }
    }
  }

  downloadText(content, subtitleFile.name);
  return { success: true, message: `Downloaded ${subtitleFile.name}` };
}

function buildSubtitleContent(subtitleFile: SubtitleFile, cues: SubtitleCue[]): string {
  if (subtitleFile.format === 'ass' && subtitleFile.assPreamble) {
    return serializeASS(subtitleFile.assPreamble, cues);
  }
  return cuesToSRT(cues);
}

function downloadText(content: string, filename: string) {
  const blob = new Blob([content], { type: 'text/plain;charset=utf-8' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}

export async function pickSubtitleFile(): Promise<{
  file: File;
  handle: FileSystemFileHandle | null;
} | null> {
  if ('showOpenFilePicker' in window) {
    try {
      const [handle] = await window.showOpenFilePicker({
        multiple: false,
        types: [
          {
            description: 'Subtitle files',
            accept: {
              'text/plain': ['.srt', '.vtt', '.ass', '.ssa'],
              'application/x-subrip': ['.srt'],
            },
          },
        ],
      });
      await handle.requestPermission({ mode: 'readwrite' }).catch(() => {});
      const file = await handle.getFile();
      return { file, handle };
    } catch (err) {
      // AbortError = user cancelled; any other error (picker already active, security policy etc.)
      // → return null so the caller falls back to the native <input> picker.
      void err;
      return null;
    }
  }
  return null;
}
