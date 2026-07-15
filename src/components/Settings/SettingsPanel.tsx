import { useState } from 'react';
import { useAppStore } from '../../store/appStore';
import { ConfirmDialog, PixelButton, PixelPanel, PixelInput } from '../PixelUI';

export function SettingsPanel() {
  const {
    openaiApiKey,
    setOpenaiApiKey,
    targetLanguage,
    setTargetLanguage,
    ankiMediaDirHandle,
    setAnkiMediaDirHandle,
    media,
    setMedia,
  } = useAppStore();

  const [showKey, setShowKey] = useState(false);
  const [saved, setSaved] = useState(false);
  const [confirmClear, setConfirmClear] = useState(false);
  const [dirPickError, setDirPickError] = useState('');

  const handleSave = () => {
    localStorage.setItem('pixel-listen-api-key', openaiApiKey);
    localStorage.setItem('pixel-listen-target-lang', targetLanguage);
    setSaved(true);
    setTimeout(() => setSaved(false), 2000);
  };

  const clearMedia = () => {
    if (media) URL.revokeObjectURL(media.url);
    setMedia(null);
    setConfirmClear(false);
  };

  const pickAnkiMediaDir = async () => {
    setDirPickError('');
    try {
      if (!('showDirectoryPicker' in window)) {
        setDirPickError('Directory picker not supported in this browser.');
        return;
      }
      const handle = await (window as Window & typeof globalThis & {
        showDirectoryPicker: (opts?: { mode?: string }) => Promise<FileSystemDirectoryHandle>;
      }).showDirectoryPicker({ mode: 'readwrite' });
      setAnkiMediaDirHandle(handle);
    } catch (err) {
      if (err instanceof Error && err.name !== 'AbortError') {
        setDirPickError('Could not access directory. Make sure you grant write permission.');
      }
    }
  };

  return (
    <PixelPanel title="SETTINGS">
      <ConfirmDialog
        open={confirmClear}
        title="Clear media?"
        message="This removes the loaded media and all subtitles from the session. Favorites are kept."
        confirmLabel="CLEAR"
        danger
        onConfirm={clearMedia}
        onCancel={() => setConfirmClear(false)}
      />

      <div className="settings-form">
        <label className="settings-label">
          OpenAI API Key
          <span className="settings-hint">For AI transcription, translation, grammar &amp; Anki</span>
        </label>
        <div className="api-key-row">
          <PixelInput
            type={showKey ? 'text' : 'password'}
            value={openaiApiKey}
            onChange={(e) => setOpenaiApiKey(e.target.value)}
            placeholder="sk-..."
          />
          <PixelButton variant="ghost" size="sm" onClick={() => setShowKey(!showKey)}>
            {showKey ? 'HIDE' : 'SHOW'}
          </PixelButton>
        </div>

        <label className="settings-label">Translation Target Language</label>
        <PixelInput
          value={targetLanguage}
          onChange={(e) => setTargetLanguage(e.target.value)}
          placeholder="Chinese, Japanese, Spanish..."
        />

        <label className="settings-label">
          Anki Media Folder
          <span className="settings-hint">
            When set, audio/video clips are written directly here on export — no manual unzip needed.
          </span>
        </label>
        <div className="anki-dir-row">
          <span className="anki-dir-path">
            {ankiMediaDirHandle ? `📂 ${ankiMediaDirHandle.name}` : 'Not set — exports will be ZIP files'}
          </span>
          <PixelButton variant="secondary" size="sm" onClick={() => void pickAnkiMediaDir()}>
            BROWSE
          </PixelButton>
          {ankiMediaDirHandle && (
            <PixelButton variant="ghost" size="sm" onClick={() => setAnkiMediaDirHandle(null)}>
              ✕
            </PixelButton>
          )}
        </div>
        {dirPickError && <p className="settings-error">{dirPickError}</p>}

        <PixelButton variant="accent" onClick={handleSave}>
          {saved ? '✓ SAVED' : 'SAVE SETTINGS'}
        </PixelButton>

        {media && (
          <div className="settings-media">
            <p className="settings-media-name" title={media.name}>
              Current: {media.name}
            </p>
            <PixelButton variant="danger" size="sm" onClick={() => setConfirmClear(true)}>
              CLEAR MEDIA
            </PixelButton>
          </div>
        )}
      </div>
    </PixelPanel>
  );
}
