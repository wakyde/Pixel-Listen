import { useState } from 'react';
import { useAppStore } from '../../store/appStore';
import { ConfirmDialog, PixelButton, PixelPanel, PixelInput, PixelSelect } from '../PixelUI';
import type { AIProvider, LocalWhisperModel, TranscriptionProvider } from '../../types';

export function SettingsPanel() {
  const {
    openaiApiKey,
    setOpenaiApiKey,
    targetLanguage,
    setTargetLanguage,
    aiProvider,
    setAiProvider,
    aiBaseUrl,
    setAiBaseUrl,
    aiChatModel,
    setAiChatModel,
    aiTranscriptionModel,
    setAiTranscriptionModel,
    transcriptionProvider,
    setTranscriptionProvider,
    localWhisperModel,
    setLocalWhisperModel,
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
    localStorage.setItem('pixel-listen-ai-provider', aiProvider);
    localStorage.setItem('pixel-listen-ai-base-url', aiBaseUrl);
    localStorage.setItem('pixel-listen-ai-chat-model', aiChatModel);
    localStorage.setItem('pixel-listen-ai-transcription-model', aiTranscriptionModel);
    localStorage.setItem('pixel-listen-transcription-provider', transcriptionProvider);
    localStorage.setItem('pixel-listen-local-whisper-model', localWhisperModel);
    setSaved(true);
    setTimeout(() => setSaved(false), 2000);
  };

  const handleProviderChange = (value: AIProvider) => {
    setAiProvider(value);
    if (value === 'openai') {
      if (!aiBaseUrl) setAiBaseUrl('https://api.openai.com/v1');
      if (!aiChatModel) setAiChatModel('gpt-4o-mini');
      if (!aiTranscriptionModel) setAiTranscriptionModel('whisper-1');
    }
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
          AI Provider
          <span className="settings-hint">Choose OpenAI or a custom OpenAI-compatible API</span>
        </label>
        <PixelSelect
          value={aiProvider}
          onChange={(e) => handleProviderChange(e.target.value as AIProvider)}
        >
          <option value="openai">OpenAI</option>
          <option value="custom">Custom / Third-party</option>
        </PixelSelect>

        <label className="settings-label">
          API Base URL
          <span className="settings-hint">For custom providers like DeepSeek, Gemini proxy, Ollama, vLLM...</span>
        </label>
        <PixelInput
          value={aiBaseUrl}
          onChange={(e) => setAiBaseUrl(e.target.value)}
          placeholder="https://api.openai.com/v1"
        />

        <label className="settings-label">
          API Key
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

        <label className="settings-label">Translation / Grammar Model</label>
        <PixelInput
          value={aiChatModel}
          onChange={(e) => setAiChatModel(e.target.value)}
          placeholder="gpt-4o-mini"
        />

        <label className="settings-label">Transcription Model</label>
        <PixelInput
          value={aiTranscriptionModel}
          onChange={(e) => setAiTranscriptionModel(e.target.value)}
          placeholder="whisper-1"
        />

        <label className="settings-label">
          Transcription Provider
          <span className="settings-hint">API uses the provider above; Local Whisper runs in your browser</span>
        </label>
        <PixelSelect
          value={transcriptionProvider}
          onChange={(e) => setTranscriptionProvider(e.target.value as TranscriptionProvider)}
        >
          <option value="api">API (OpenAI / Third-party)</option>
          <option value="local">Local Whisper (free, browser-based)</option>
        </PixelSelect>

        {transcriptionProvider === 'local' && (
          <>
            <label className="settings-label">
              Local Whisper Model
              <span className="settings-hint">Larger = more accurate but slower download / inference</span>
            </label>
            <PixelSelect
              value={localWhisperModel}
              onChange={(e) => setLocalWhisperModel(e.target.value as LocalWhisperModel)}
            >
              <option value="tiny">tiny (~39 MB, fast)</option>
              <option value="base">base (~74 MB, balanced)</option>
              <option value="small">small (~244 MB, accurate)</option>
            </PixelSelect>
          </>
        )}

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
