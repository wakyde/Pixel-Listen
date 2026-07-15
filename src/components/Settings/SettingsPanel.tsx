import { useState } from 'react';
import { useAppStore } from '../../store/appStore';
import { ConfirmDialog, PixelButton, PixelPanel, PixelInput } from '../PixelUI';

export function SettingsPanel() {
  const {
    openaiApiKey,
    setOpenaiApiKey,
    targetLanguage,
    setTargetLanguage,
    media,
    setMedia,
  } = useAppStore();

  const [showKey, setShowKey] = useState(false);
  const [saved, setSaved] = useState(false);
  const [confirmClear, setConfirmClear] = useState(false);

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
          <span className="settings-hint">For AI transcription, translation, grammar & Anki</span>
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
