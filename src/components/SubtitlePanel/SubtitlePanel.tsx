import { useEffect, useRef, useState } from 'react';
import { useAppStore } from '../../store/appStore';
import { useMediaRef } from '../../context/MediaContext';
import { parseASS, getSubtitleFormat } from '../../utils/assParser';
import { parseSRT, parseVTT, getActiveCue } from '../../utils/subtitleParser';
import { pickSubtitleFile, saveSubtitleFile } from '../../utils/subtitleSave';
import {
  translateText,
  analyzeGrammar,
  transcribeWithWhisper,
  transcribeWithLocalWhisper,
} from '../../utils/aiService';
import type { AIConfig } from '../../types';
import { seekTo, safePlay, safePause } from '../../utils/mediaControl';
import { getEnglishText } from '../../utils/bilingualText';
import { ConfirmDialog, PixelButton, PixelPanel, PixelBadge, PixelTextarea } from '../PixelUI';
import type { FavoriteType, SubtitleCue } from '../../types';

export function SubtitlePanel() {
  const fileRef = useRef<HTMLInputElement>(null);
  const listRef = useRef<HTMLDivElement>(null);
  const activeItemRef = useRef<HTMLDivElement>(null);
  const mediaRef = useMediaRef();
  const [editingCueId, setEditingCueId] = useState<string | null>(null);
  const [editText, setEditText] = useState('');
  const [isSaving, setIsSaving] = useState(false);
  const [saveMessage, setSaveMessage] = useState('');
  const [actionsCueId, setActionsCueId] = useState<string | null>(null);
  const [confirmAction, setConfirmAction] = useState<
    null | 'transcribe' | 'translateAll' | 'overwriteImport'
  >(null);
  const pendingImportRef = useRef<{ file: File; handle: FileSystemFileHandle | null } | null>(
    null
  );

  const {
    media,
    subtitles,
    subtitleFile,
    setSubtitles,
    setSubtitleFile,
    updateCueText,
    panelSubtitlesVisible,
    togglePanelSubtitles,
    selectedCueId,
    setSelectedCueId,
    updateCueTranslation,
    setCueTranslationHidden,
    setAllTranslationsHidden,
    grammarAnalysis,
    setGrammarAnalysis,
    grammarDrawerOpen,
    setGrammarDrawerOpen,
    addFavorite,
    addToAnkiCart,
    removeFromAnkiCart,
    ankiCart,
    openaiApiKey,
    targetLanguage,
    aiProvider,
    aiBaseUrl,
    aiChatModel,
    aiTranscriptionModel,
    transcriptionProvider,
    localWhisperModel,
    localWhisperProgress,
    setLocalWhisperProgress,
    isTranscribing,
    isTranslating,
    isAnalyzing,
    setIsTranscribing,
    setIsTranslating,
    setIsAnalyzing,
    currentTime,
    setCurrentTime,
    setIsPlaying,
  } = useAppStore();

  const aiConfig: AIConfig = {
    provider: aiProvider,
    apiKey: openaiApiKey,
    baseUrl: aiBaseUrl,
    chatModel: aiChatModel,
    transcriptionModel: aiTranscriptionModel,
  };

  const activeCue = getActiveCue(subtitles, currentTime);
  const activeCueId = activeCue?.id ?? null;

  useEffect(() => {
    if (!activeCueId || editingCueId) return;
    const el = activeItemRef.current;
    if (!el || !listRef.current) return;
    const list = listRef.current;
    const elTop = el.offsetTop;
    const elBottom = elTop + el.offsetHeight;
    const viewTop = list.scrollTop;
    const viewBottom = viewTop + list.clientHeight;
    if (elTop < viewTop + 8 || elBottom > viewBottom - 8) {
      el.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
    }
  }, [activeCueId, editingCueId]);

  const applySubtitleFile = async (
    file: File,
    handle: FileSystemFileHandle | null = null
  ) => {
    const format = getSubtitleFormat(file.name);
    if (!format) {
      alert('Unsupported format. Use SRT, VTT, or ASS.');
      return;
    }

    const text = await file.text();

    if (format === 'ass') {
      const { preamble, cues } = parseASS(text);
      if (cues.length === 0) {
        alert('No dialogue lines found in ASS file.');
        return;
      }
      setSubtitles(cues);
      setSubtitleFile({
        name: file.name,
        format: 'ass',
        fileHandle: handle,
        assPreamble: preamble,
      });
      return;
    }

    const cues = format === 'vtt' ? parseVTT(text) : parseSRT(text);
    if (cues.length === 0) {
      alert('No subtitles found. Please check the file format.');
      return;
    }
    setSubtitles(cues);
    setSubtitleFile({
      name: file.name,
      format,
      fileHandle: handle,
    });
  };

  const loadSubtitle = async (file: File, handle: FileSystemFileHandle | null = null) => {
    if (subtitles.length > 0) {
      pendingImportRef.current = { file, handle };
      setConfirmAction('overwriteImport');
      return;
    }
    await applySubtitleFile(file, handle);
  };

  const handleImportClick = async () => {
    setSaveMessage('');
    const picked = await pickSubtitleFile();
    if (picked) {
      await loadSubtitle(picked.file, picked.handle);
      return;
    }
    fileRef.current?.click();
  };

  const handleSave = async () => {
    if (!subtitleFile || subtitles.length === 0) return;
    setIsSaving(true);
    setSaveMessage('');
    const result = await saveSubtitleFile(subtitleFile, subtitles);
    setIsSaving(false);
    setSaveMessage(result.message);
    if (!result.success && result.message !== 'Save cancelled') {
      alert(result.message);
    }
  };

  const startEdit = (cue: SubtitleCue) => {
    setEditingCueId(cue.id);
    setEditText(cue.text);
    setSelectedCueId(cue.id);
    setActionsCueId(cue.id);
  };

  const commitEdit = () => {
    if (editingCueId) {
      updateCueText(editingCueId, editText.trim());
      setEditingCueId(null);
      setEditText('');
    }
  };

  const cancelEdit = () => {
    setEditingCueId(null);
    setEditText('');
  };

  const runAITranscribe = async () => {
    if (!media) return;
    setIsTranscribing(true);
    setLocalWhisperProgress(0);
    try {
      const response = await fetch(media.url);
      const blob = await response.blob();
      const srt =
        transcriptionProvider === 'local'
          ? await transcribeWithLocalWhisper(blob, localWhisperModel, (progress) => {
              setLocalWhisperProgress(progress);
            })
          : await transcribeWithWhisper(blob, aiConfig);
      setSubtitles(parseSRT(srt));
      setSubtitleFile({ name: 'transcription.srt', format: 'srt', fileHandle: null });
    } catch (err) {
      alert(
        err instanceof Error
          ? err.message
          : 'Transcription failed. Check settings or try a different provider.'
      );
    } finally {
      setIsTranscribing(false);
      setLocalWhisperProgress(0);
    }
  };

  const handleAITranscribe = () => {
    if (!media) return;
    if (subtitles.length > 0) {
      setConfirmAction('transcribe');
      return;
    }
    void runAITranscribe();
  };

  const handleTranslate = async (cue: SubtitleCue) => {
    setActionsCueId(cue.id);
    const availableTranslation = cue.translation ?? cue.nativeTranslation;
    if (availableTranslation && !cue.translationHidden) {
      setCueTranslationHidden(cue.id, true);
      return;
    }
    if (availableTranslation && cue.translationHidden) {
      setCueTranslationHidden(cue.id, false);
      return;
    }
    if (cue.nativeTranslation) {
      updateCueTranslation(cue.id, cue.nativeTranslation);
      return;
    }
    setIsTranslating(true);
    try {
      const english = getEnglishText(cue.text);
      const translation = await translateText(english, targetLanguage, aiConfig);
      // Avoid dumping English again when no API key
      if (translation && translation !== english) {
        updateCueTranslation(cue.id, translation);
      } else if (!openaiApiKey) {
        alert('Add an API key in Settings to translate, or use bilingual ASS files.');
      }
    } finally {
      setIsTranslating(false);
    }
  };

  const runTranslateAll = async () => {
    setIsTranslating(true);
    try {
      for (const cue of useAppStore.getState().subtitles) {
        if (cue.translation || cue.nativeTranslation) {
          setCueTranslationHidden(cue.id, false);
        }
        if (cue.translation) continue;
        if (cue.nativeTranslation) {
          updateCueTranslation(cue.id, cue.nativeTranslation);
          continue;
        }
        const english = getEnglishText(cue.text);
        const translation = await translateText(english, targetLanguage, aiConfig);
        if (translation && translation !== english) {
          updateCueTranslation(cue.id, translation);
        }
      }
    } finally {
      setIsTranslating(false);
    }
  };

  const handleTranslateAll = () => {
    if (subtitles.length === 0) return;
    const available = subtitles.filter((cue) => cue.translation || cue.nativeTranslation);
    if (available.length === subtitles.length) {
      const hasVisibleTranslations = available.some((cue) => !cue.translationHidden);
      setAllTranslationsHidden(hasVisibleTranslations);
      return;
    }
    setConfirmAction('translateAll');
  };

  const handleGrammar = async (cue: SubtitleCue) => {
    setSelectedCueId(cue.id);
    setActionsCueId(cue.id);
    setGrammarDrawerOpen(true);
    safePause(mediaRef.current);
    setIsPlaying(false);
    setIsAnalyzing(true);
    try {
      const analysis = await analyzeGrammar(getEnglishText(cue.text), aiConfig);
      setGrammarAnalysis(analysis);
    } finally {
      setIsAnalyzing(false);
    }
  };

  const closeGrammarDrawer = () => {
    setGrammarDrawerOpen(false);
    setGrammarAnalysis(null);
  };

  const saveFavorite = (type: FavoriteType, text: string, cueId?: string) => {
    const cue = subtitles.find((c) => c.id === cueId);
    addFavorite({
      type,
      text,
      context: cue?.text,
      translation: cue?.translation,
      mediaTime: cue?.start ?? currentTime,
      cueId,
    });
  };

  const jumpToCue = async (cue: SubtitleCue) => {
    if (editingCueId) return;
    setSelectedCueId(cue.id);
    setActionsCueId(cue.id);
    const t = seekTo(mediaRef.current, cue.start);
    setCurrentTime(t);
    const ok = await safePlay(mediaRef.current);
    setIsPlaying(ok);
  };

  const handleConfirm = async () => {
    const action = confirmAction;
    setConfirmAction(null);
    if (action === 'transcribe') {
      await runAITranscribe();
    } else if (action === 'translateAll') {
      await runTranslateAll();
    } else if (action === 'overwriteImport') {
      const pending = pendingImportRef.current;
      pendingImportRef.current = null;
      if (pending) await applySubtitleFile(pending.file, pending.handle);
    }
  };

  const inCart = (cueId: string) =>
    ankiCart.some((item) => item.cueIds.includes(cueId));

  const toggleAnkiCue = (cueId: string) => {
    const item = ankiCart.find((cartItem) => cartItem.cueIds.includes(cueId));
    if (item) {
      removeFromAnkiCart(item.id);
    } else {
      addToAnkiCart([cueId]);
    }
  };

  if (!media) {
    return (
      <PixelPanel title="SUBTITLES">
        <p className="empty-hint">Load a media file first, then import subtitles</p>
      </PixelPanel>
    );
  }

  return (
    <PixelPanel
      title="SUBTITLES"
      className="subtitle-panel-root"
      actions={
        <div className="subtitle-actions">
          <PixelButton variant="ghost" size="sm" onClick={togglePanelSubtitles}>
            {panelSubtitlesVisible ? '👁 ON' : '👁 OFF'}
          </PixelButton>
        </div>
      }
    >
      <ConfirmDialog
        open={confirmAction === 'transcribe'}
        title="Overwrite subtitles?"
        message="AI transcription will replace all current subtitle lines. This cannot be undone."
        confirmLabel="TRANSCRIBE"
        danger
        onConfirm={handleConfirm}
        onCancel={() => setConfirmAction(null)}
      />
      <ConfirmDialog
        open={confirmAction === 'translateAll'}
        title="Translate all lines?"
        message={`Reveal / translate every line to ${targetLanguage}? This may use API credits.`}
        confirmLabel="TRANSLATE"
        onConfirm={handleConfirm}
        onCancel={() => setConfirmAction(null)}
      />
      <ConfirmDialog
        open={confirmAction === 'overwriteImport'}
        title="Replace subtitles?"
        message="Importing will replace the current subtitle list. Unsaved edits will be lost."
        confirmLabel="IMPORT"
        danger
        onConfirm={handleConfirm}
        onCancel={() => {
          pendingImportRef.current = null;
          setConfirmAction(null);
        }}
      />

      <div className="subtitle-toolbar">
        <PixelButton variant="secondary" size="sm" onClick={handleImportClick}>
          IMPORT
        </PixelButton>
        <input
          ref={fileRef}
          type="file"
          accept=".srt,.vtt,.ass,.ssa,text/plain,application/x-subrip"
          hidden
          onChange={(e) => {
            const f = e.target.files?.[0];
            if (f) {
              void loadSubtitle(f, null);
              e.target.value = '';
            }
          }}
        />
        {subtitleFile && subtitles.length > 0 && (
          <PixelButton variant="primary" size="sm" onClick={handleSave} disabled={isSaving}>
            {isSaving ? '⏳...' : '💾 SAVE'}
          </PixelButton>
        )}
        <PixelButton
          variant="accent"
          size="sm"
          onClick={handleAITranscribe}
          disabled={isTranscribing || !media}
        >
          {isTranscribing ? '⏳ AI...' : '🤖 AI'}
        </PixelButton>
        {subtitles.length > 0 && (
          <PixelButton
            variant="ghost"
            size="sm"
            onClick={handleTranslateAll}
            disabled={isTranslating}
          >
            {isTranslating ? '⏳...' : '🌐 ALL'}
          </PixelButton>
        )}
      </div>

      {isTranscribing && transcriptionProvider === 'local' && (
        <div className="local-whisper-progress">
          <span className="local-whisper-progress-label">
            {localWhisperProgress < 100
              ? `Loading Whisper model: ${localWhisperProgress}%`
              : 'Transcribing with local Whisper...'}
          </span>
          <div className="local-whisper-progress-bar">
            <div
              className="local-whisper-progress-fill"
              style={{ width: `${localWhisperProgress}%` }}
            />
          </div>
        </div>
      )}

      {subtitleFile && (
        <p className="subtitle-file-info">
          📄 {subtitleFile.name}
          {subtitleFile.format === 'ass' && ' (ASS)'}
          {subtitleFile.fileHandle ? ' · writable' : ''}
        </p>
      )}
      {saveMessage && <p className="save-message">{saveMessage}</p>}

      <div className="subtitle-list-wrap">
        {!panelSubtitlesVisible ? (
          <p className="empty-hint">Subtitle list hidden (👁 OFF)</p>
        ) : (
          <div className="subtitle-list" ref={listRef}>
            {subtitles.length === 0 ? (
              <p className="empty-hint">Import SRT / VTT / ASS subtitles</p>
            ) : (
              subtitles.map((cue) => {
                const isActive = activeCueId === cue.id;
                const isSelected = selectedCueId === cue.id;
                const showActions = actionsCueId === cue.id || isSelected;
                return (
                  <div
                    key={cue.id}
                    ref={isActive ? activeItemRef : undefined}
                    className={`subtitle-item${isActive ? ' active' : ''}${isSelected ? ' selected' : ''}`}
                    onClick={() => void jumpToCue(cue)}
                  >
                    <span className="cue-time">
                      {formatCueTime(cue.start)} → {formatCueTime(cue.end)}
                      {isActive ? ' ●' : ''}
                      {inCart(cue.id) ? ' 🛒' : ''}
                    </span>

                    {editingCueId === cue.id ? (
                      <div className="cue-edit" onClick={(e) => e.stopPropagation()}>
                        <PixelTextarea
                          value={editText}
                          onChange={(e) => setEditText(e.target.value)}
                          rows={3}
                          autoFocus
                          onKeyDown={(e) => {
                            if (e.key === 'Escape') {
                              e.stopPropagation();
                              cancelEdit();
                            }
                            if (e.key === 'Enter' && (e.metaKey || e.ctrlKey)) {
                              e.preventDefault();
                              commitEdit();
                            }
                          }}
                        />
                        <div className="cue-edit-actions">
                          <PixelButton variant="accent" size="sm" onClick={commitEdit}>
                            ✓ OK
                          </PixelButton>
                          <PixelButton variant="ghost" size="sm" onClick={cancelEdit}>
                            ✕
                          </PixelButton>
                        </div>
                      </div>
                    ) : (
                      <>
                        {/* EN on top */}
                        <p className="cue-text">{cue.text}</p>
                        {/* Translation below only after Translate */}
                        {(cue.translation || cue.nativeTranslation) && !cue.translationHidden && (
                          <p className="cue-translation">
                            {cue.translation ?? cue.nativeTranslation}
                          </p>
                        )}
                      </>
                    )}

                    {showActions && editingCueId !== cue.id && (
                      <div className="cue-actions" onClick={(e) => e.stopPropagation()}>
                        <PixelButton
                          variant="ghost"
                          size="sm"
                          onClick={() => startEdit(cue)}
                          title="Edit"
                        >
                          ✏️
                        </PixelButton>
                        <PixelButton
                          variant="ghost"
                          size="sm"
                          onClick={() => void handleTranslate(cue)}
                          disabled={isTranslating}
                          title={cue.translation || cue.nativeTranslation
                            ? cue.translationHidden ? 'Show translation' : 'Hide translation'
                            : 'Translate'}
                        >
                          {cue.translation || cue.nativeTranslation
                            ? cue.translationHidden ? '🌐' : '🙈'
                            : '🌐'}
                        </PixelButton>
                        <PixelButton
                          variant="ghost"
                          size="sm"
                          onClick={() => void handleGrammar(cue)}
                          disabled={isAnalyzing}
                          title="Grammar"
                        >
                          📖
                        </PixelButton>
                        <PixelButton
                          variant="ghost"
                          size="sm"
                          onClick={() => saveFavorite('sentence', cue.text, cue.id)}
                          title="Favorite"
                        >
                          ★
                        </PixelButton>
                        <PixelButton
                          variant={inCart(cue.id) ? 'accent' : 'ghost'}
                          size="sm"
                          onClick={() => toggleAnkiCue(cue.id)}
                          title={inCart(cue.id) ? 'Remove from Anki cart' : 'Add to Anki cart'}
                        >
                          {inCart(cue.id) ? '✓🛒' : '🛒'}
                        </PixelButton>
                      </div>
                    )}
                  </div>
                );
              })
            )}
          </div>
        )}

        {grammarDrawerOpen && (
          <div className="grammar-drawer" role="dialog" aria-label="Grammar analysis">
            <div className="grammar-drawer-header">
              <h4>GRAMMAR</h4>
              <PixelButton variant="ghost" size="sm" onClick={closeGrammarDrawer}>
                ✕
              </PixelButton>
            </div>
            <div className="grammar-drawer-body">
              {isAnalyzing || !grammarAnalysis ? (
                <p>Analyzing...</p>
              ) : (
                <>
                  <p className="cue-text">{grammarAnalysis.sentence}</p>
                  <PixelBadge color="blue">{grammarAnalysis.structure}</PixelBadge>
                  <ul className="grammar-list">
                    {grammarAnalysis.keyPoints.map((p, i) => (
                      <li key={i}>{p}</li>
                    ))}
                  </ul>
                  <div className="vocab-grid">
                    {grammarAnalysis.vocabulary.map((v) => (
                      <button
                        key={v.word}
                        type="button"
                        className="vocab-chip"
                        onClick={() => saveFavorite('word', v.word, selectedCueId ?? undefined)}
                      >
                        {v.word}: {v.meaning}
                      </button>
                    ))}
                  </div>
                  <div className="grammar-suggestions">
                    {grammarAnalysis.suggestions.map((s, i) => (
                      <p key={i}>💡 {s}</p>
                    ))}
                  </div>
                </>
              )}
            </div>
          </div>
        )}
      </div>
    </PixelPanel>
  );
}

function formatCueTime(sec: number): string {
  const m = Math.floor(sec / 60);
  const s = Math.floor(sec % 60);
  const cs = Math.floor((sec % 1) * 10);
  return `${m}:${String(s).padStart(2, '0')}.${cs}`;
}
