import { useState } from 'react';
import { useAppStore } from '../../store/appStore';
import { useI18n } from '../../context/I18nContext';
import { ConfirmDialog, PixelButton, PixelPanel, PixelInput } from '../PixelUI';

export function SettingsPanel() {
  const { t, language, setLanguage } = useI18n();
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
        setDirPickError(t('settings.dir_not_supported'));
        return;
      }
      const handle = await (window as Window & typeof globalThis & {
        showDirectoryPicker: (opts?: { mode?: string }) => Promise<FileSystemDirectoryHandle>;
      }).showDirectoryPicker({ mode: 'readwrite' });
      setAnkiMediaDirHandle(handle);
    } catch (err) {
      if (err instanceof Error && err.name !== 'AbortError') {
        setDirPickError(t('settings.dir_access_error'));
      }
    }
  };

  return (
    <PixelPanel title={t('panel.settings')}>
      <ConfirmDialog
        open={confirmClear}
        title={t('settings.clear_media_title')}
        message={t('settings.clear_media_msg')}
        confirmLabel={t('settings.clear_media')}
        danger
        onConfirm={clearMedia}
        onCancel={() => setConfirmClear(false)}
      />

      <div className="settings-form">
        <label className="settings-label">
          {t('settings.language')}
          <span className="settings-hint">{t('settings.language_hint')}</span>
        </label>
        <div className="language-selector">
          <PixelButton
            variant={language === 'zh' ? 'accent' : 'ghost'}
            size="sm"
            onClick={() => setLanguage('zh')}
          >
            {t('settings.language_zh')}
          </PixelButton>
          <PixelButton
            variant={language === 'en' ? 'accent' : 'ghost'}
            size="sm"
            onClick={() => setLanguage('en')}
          >
            {t('settings.language_en')}
          </PixelButton>
        </div>

        <label className="settings-label">
          {t('settings.api_key')}
          <span className="settings-hint">{t('settings.api_key_hint')}</span>
        </label>
        <div className="api-key-row">
          <PixelInput
            type={showKey ? 'text' : 'password'}
            value={openaiApiKey}
            onChange={(e) => setOpenaiApiKey(e.target.value)}
            placeholder="sk-..."
          />
          <PixelButton variant="ghost" size="sm" onClick={() => setShowKey(!showKey)}>
            {showKey ? t('settings.hide') : t('settings.show')}
          </PixelButton>
        </div>

        <label className="settings-label">{t('settings.target_lang')}</label>
        <PixelInput
          value={targetLanguage}
          onChange={(e) => setTargetLanguage(e.target.value)}
          placeholder={t('settings.target_lang_placeholder')}
        />

        <label className="settings-label">
          {t('settings.anki_folder')}
          <span className="settings-hint">{t('settings.anki_folder_hint')}</span>
        </label>
        <div className="anki-dir-row">
          <span className="anki-dir-path">
            {ankiMediaDirHandle ? `📂 ${ankiMediaDirHandle.name}` : t('settings.anki_not_set')}
          </span>
          <PixelButton variant="secondary" size="sm" onClick={() => void pickAnkiMediaDir()}>
            {t('settings.browse')}
          </PixelButton>
          {ankiMediaDirHandle && (
            <PixelButton variant="ghost" size="sm" onClick={() => setAnkiMediaDirHandle(null)}>
              ✕
            </PixelButton>
          )}
        </div>
        {dirPickError && <p className="settings-error">{dirPickError}</p>}

        <PixelButton variant="accent" onClick={handleSave}>
          {saved ? t('settings.saved') : t('settings.save')}
        </PixelButton>

        {media && (
          <div className="settings-media">
            <p className="settings-media-name" title={media.name}>
              {t('settings.current_media')} {media.name}
            </p>
            <PixelButton variant="danger" size="sm" onClick={() => setConfirmClear(true)}>
              {t('settings.clear_media')}
            </PixelButton>
          </div>
        )}
      </div>
    </PixelPanel>
  );
}