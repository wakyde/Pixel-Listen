import { useEffect, useRef, useState, useMemo } from 'react';
import { useAppStore } from '../../store/appStore';
import { useMediaRef } from '../../context/MediaContext';
import { useI18n } from '../../context/I18nContext';
import { parseASS, getSubtitleFormat } from '../../utils/assParser';
import { parseSRT, parseVTT, getActiveCue } from '../../utils/subtitleParser';
import { pickSubtitleFile, saveSubtitleFile } from '../../utils/subtitleSave';
import { translateText, analyzeGrammar, transcribeWithWhisper } from '../../utils/aiService';
import { seekTo, safePlay, safePause } from '../../utils/mediaControl';
import { getEnglishText } from '../../utils/bilingualText';
import {
  ConfirmDialog,
  PixelButton,
  PixelPanel,
  PixelBadge,
  PixelInput,
  PixelTextarea,
} from '../PixelUI';
import type { FavoriteType, SubtitleCue } from '../../types';

export function SubtitlePanel() {
  const { t } = useI18n();
  const fileRef = useRef<HTMLInputElement>(null);
  const listRef = useRef<HTMLDivElement>(null);
  const activeItemRef = useRef<HTMLDivElement>(null);
  const mediaRef = useMediaRef();
  const [editingCueId, setEditingCueId] = useState<string | null>(null);
  const [editText, setEditText] = useState('');
  const [editingCueStart, setEditingCueStart] = useState<number | null>(null);
  const [editingCueEnd, setEditingCueEnd] = useState<number | null>(null);
  const [isSaving, setIsSaving] = useState(false);
  const [saveMessage, setSaveMessage] = useState('');
  const [searchQuery, setSearchQuery] = useState('');
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
    updateCueTiming,
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
    isTranscribing,
    isTranslating,
    isAnalyzing,
    setIsTranscribing,
    setIsTranslating,
    setIsAnalyzing,
    currentTime,
    setCurrentTime,
    setIsPlaying,
    recentSubtitleFiles,
    addRecentSubtitleFile,
    abLoopActive,
    pointA,
    pointB,
    leadTime,
  } = useAppStore();

  const activeCue = getActiveCue(subtitles, currentTime);
  const activeCueId = activeCue?.id ?? null;

  const abFilteredSubtitles = useMemo(() =>
    abLoopActive && pointA != null && pointB != null
      ? subtitles.filter((cue) => cue.start < pointB && cue.end > pointA)
      : subtitles
  , [abLoopActive, pointA, pointB, subtitles]);

  const filteredSubtitles = searchQuery.trim()
    ? abFilteredSubtitles.filter((cue) => {
        const q = searchQuery.toLowerCase();
        return (
          cue.text.toLowerCase().includes(q) ||
          (cue.translation && cue.translation.toLowerCase().includes(q)) ||
          (cue.nativeTranslation && cue.nativeTranslation.toLowerCase().includes(q))
        );
      })
    : abFilteredSubtitles;

  useEffect(() => {
    if (!activeCueId || editingCueId) return;
    const el = activeItemRef.current;
    const list = listRef.current;
    if (!el || !list) return;
    const elRect = el.getBoundingClientRect();
    const listRect = list.getBoundingClientRect();
    if (elRect.top < listRect.top + 8 || elRect.bottom > listRect.bottom - 8) {
      el.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
    }
  }, [activeCueId, editingCueId]);

  const applySubtitleFile = async (
    file: File,
    handle: FileSystemFileHandle | null = null
  ) => {
    const format = getSubtitleFormat(file.name);
    if (!format) {
      alert(t('subs.unsupported_format'));
      return;
    }

    const text = await file.text();

    if (format === 'ass') {
      const { preamble, cues } = parseASS(text);
      if (cues.length === 0) {
        alert(t('subs.no_dialogue'));
        return;
      }
      setSubtitles(cues);
      setSubtitleFile({
        name: file.name,
        format: 'ass',
        fileHandle: handle,
        assPreamble: preamble,
      });
      addRecentSubtitleFile({ name: file.name, format: 'ass', fileHandle: handle });
      return;
    }

    const cues = format === 'vtt' ? parseVTT(text) : parseSRT(text);
    if (cues.length === 0) {
      alert(t('subs.no_subtitles'));
      return;
    }
    setSubtitles(cues);
    setSubtitleFile({
      name: file.name,
      format,
      fileHandle: handle,
    });
    addRecentSubtitleFile({ name: file.name, format, fileHandle: handle });
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

  const loadRecentSubtitleFile = async (item: {
    name: string;
    format: 'srt' | 'vtt' | 'ass' | 'none';
    fileHandle?: FileSystemFileHandle | null;
  }) => {
    if (!item.fileHandle) {
      alert(t('subs.no_file_handle'));
      return;
    }
    try {
      const file = await item.fileHandle.getFile();
      if (!file) throw new Error(t('subs.unable_access'));
      await applySubtitleFile(file, item.fileHandle);
    } catch (err) {
      alert(err instanceof Error ? err.message : t('subs.restore_failed'));
    }
  };

  const handleSave = async () => {
    if (!subtitleFile || subtitles.length === 0) return;
    setIsSaving(true);
    setSaveMessage('');
    const result = await saveSubtitleFile(subtitleFile, subtitles);
    setIsSaving(false);
    setSaveMessage(result.message);
    if (!result.success && result.message !== t('subs.save_cancelled')) {
      alert(result.message);
    }
  };

  const runAITranscribe = async () => {
    if (!media) return;
    setIsTranscribing(true);
    try {
      const response = await fetch(media.url);
      const blob = await response.blob();
      const srt = await transcribeWithWhisper(blob, openaiApiKey || undefined);
      setSubtitles(parseSRT(srt));
      setSubtitleFile({ name: 'transcription.srt', format: 'srt', fileHandle: null });
    } catch (err) {
      alert(
        err instanceof Error
          ? err.message
          : t('subs.transcription_failed')
      );
    } finally {
      setIsTranscribing(false);
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
      const translation = await translateText(
        english,
        targetLanguage,
        openaiApiKey || undefined
      );
      // Avoid dumping English again when no API key
      if (translation && translation !== english) {
        updateCueTranslation(cue.id, translation);
      } else if (!openaiApiKey) {
        alert(t('subs.api_key_needed'));
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
        const translation = await translateText(
          english,
          targetLanguage,
          openaiApiKey || undefined
        );
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
    // If any cue already has a visible translation, hide them all (toggle off)
    const hasVisible = subtitles.some(
      (cue) => (cue.translation || cue.nativeTranslation) && !cue.translationHidden
    );
    if (hasVisible) {
      setAllTranslationsHidden(true);
      return;
    }
    // If all cues have a translation (just hidden), reveal them all
    const allHaveTranslation = subtitles.every(
      (cue) => cue.translation || cue.nativeTranslation
    );
    if (allHaveTranslation) {
      setAllTranslationsHidden(false);
      return;
    }
    // Otherwise fetch translations
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
      const analysis = await analyzeGrammar(
        getEnglishText(cue.text),
        openaiApiKey || undefined
      );
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
    const seekTarget = Math.max(0, cue.start - leadTime / 1000);
    const t = seekTo(mediaRef.current, seekTarget);
    setCurrentTime(t);
    const ok = await safePlay(mediaRef.current);
    setIsPlaying(ok);
  };

  const startEdit = (cue: SubtitleCue) => {
    setEditingCueId(cue.id);
    setEditText(cue.text);
    setEditingCueStart(cue.start);
    setEditingCueEnd(cue.end);
    setSelectedCueId(cue.id);
    setActionsCueId(cue.id);
  };

  const commitEdit = () => {
    if (!editingCueId) return;
    const trimmed = editText.trim();
    if (trimmed !== '') {
      updateCueText(editingCueId, trimmed);
    }
    if (
      editingCueStart != null &&
      editingCueEnd != null &&
      editingCueEnd >= editingCueStart
    ) {
      updateCueTiming(editingCueId, editingCueStart, editingCueEnd);
    }
    if (editingCueEnd != null && editingCueStart != null && editingCueEnd < editingCueStart) {
      alert(t('subs.end_after_start'));
      return;
    }
    setEditingCueId(null);
    setEditText('');
    setEditingCueStart(null);
    setEditingCueEnd(null);
  };

  const cancelEdit = () => {
    setEditingCueId(null);
    setEditText('');
    setEditingCueStart(null);
    setEditingCueEnd(null);
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

  const highlightMatch = (text: string) => {
    const q = searchQuery.trim();
    if (!q) return text;
    const idx = text.toLowerCase().indexOf(q.toLowerCase());
    if (idx === -1) return text;
    return (
      <>
        {text.slice(0, idx)}
        <mark className="search-highlight">{text.slice(idx, idx + q.length)}</mark>
        {text.slice(idx + q.length)}
      </>
    );
  };

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
      <PixelPanel title={t('panel.subtitles')}>
        <p className="empty-hint">{t('subs.empty_hint')}</p>
      </PixelPanel>
    );
  }

  return (
    <PixelPanel
      title={t('panel.subtitles')}
      className="subtitle-panel-root"
      actions={
        <div className="subtitle-actions">
          <PixelButton variant="ghost" size="sm" onClick={togglePanelSubtitles}>
            {panelSubtitlesVisible ? t('subs.panel_on') : t('subs.panel_off')}
          </PixelButton>
        </div>
      }
    >
      <ConfirmDialog
        open={confirmAction === 'transcribe'}
        title={t('subs.confirm_transcribe_title')}
        message={t('subs.confirm_transcribe_msg')}
        confirmLabel={t('subs.confirm_transcribe_label')}
        danger
        onConfirm={handleConfirm}
        onCancel={() => setConfirmAction(null)}
      />
      <ConfirmDialog
        open={confirmAction === 'translateAll'}
        title={t('subs.confirm_translate_title')}
        message={t('subs.confirm_translate_msg').replace('{lang}', targetLanguage)}
        confirmLabel={t('subs.confirm_translate_label')}
        onConfirm={handleConfirm}
        onCancel={() => setConfirmAction(null)}
      />
      <ConfirmDialog
        open={confirmAction === 'overwriteImport'}
        title={t('subs.confirm_import_title')}
        message={t('subs.confirm_import_msg')}
        confirmLabel={t('subs.confirm_import_label')}
        danger
        onConfirm={handleConfirm}
        onCancel={() => {
          pendingImportRef.current = null;
          setConfirmAction(null);
        }}
      />

      <div className="subtitle-toolbar">
        <PixelButton variant="secondary" size="sm" onClick={handleImportClick}>
          {t('subs.confirm_import_label')}
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
            {isSaving ? t('subs.saving') : t('subs.save')}
          </PixelButton>
        )}
        <PixelButton
          variant="accent"
          size="sm"
          onClick={handleAITranscribe}
          disabled={isTranscribing || !media}
        >
          {isTranscribing ? t('subs.ai_transcribing') : t('subs.ai_transcribe')}
        </PixelButton>
        {subtitles.length > 0 && (
          <PixelButton
            variant="ghost"
            size="sm"
            onClick={handleTranslateAll}
            disabled={isTranslating}
          >
            {isTranslating ? t('subs.translating') : t('subs.translate_all')}
          </PixelButton>
        )}
      </div>
      {recentSubtitleFiles.length > 0 && (
        <div className="recent-subtitle-list">
          <span className="recent-subtitle-label">{t('subs.recent_subtitles')}</span>
          <div className="recent-subtitle-items">
            {recentSubtitleFiles.map((item) => (
              <button
                key={item.name}
                type="button"
                className="recent-subtitle-item"
                onClick={() => void loadRecentSubtitleFile(item)}
                disabled={!item.fileHandle}
              >
                {item.name}
              </button>
            ))}
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

      {subtitles.length > 0 && panelSubtitlesVisible && (
        <div className="subtitle-search">
          <PixelInput
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder={t('subs.search_placeholder')}
            className="subtitle-search-input"
          />
          {searchQuery.trim() && (
            <span className="subtitle-search-count">
              {filteredSubtitles.length}/{subtitles.length}
            </span>
          )}
          {searchQuery.trim() && (
            <PixelButton
              variant="ghost"
              size="sm"
              onClick={() => setSearchQuery('')}
              className="subtitle-search-clear"
            >
              ✕
            </PixelButton>
          )}
        </div>
      )}

      <div className="subtitle-list-wrap">
        {!panelSubtitlesVisible ? (
          <p className="empty-hint">{t('subs.panel_hidden_hint')}</p>
        ) : (
          <div className="subtitle-list" ref={listRef}>
            {subtitles.length === 0 ? (
              <p className="empty-hint">{t('subs.import_hint')}</p>
            ) : (
              filteredSubtitles.map((cue) => {
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
                        <div className="cue-time-edit-row">
                          <label>
                            Start
                            <PixelInput
                              type="number"
                              step="0.01"
                              min="0"
                              value={editingCueStart ?? ''}
                              onChange={(e) => setEditingCueStart(Number(e.target.value) || 0)}
                            />
                          </label>
                          <label>
                            End
                            <PixelInput
                              type="number"
                              step="0.01"
                              min="0"
                              value={editingCueEnd ?? ''}
                              onChange={(e) => setEditingCueEnd(Number(e.target.value) || 0)}
                            />
                          </label>
                        </div>
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
                        <p className="cue-text">
                          {highlightMatch(cue.text)}
                        </p>
                        {(cue.translation || cue.nativeTranslation) && !cue.translationHidden && (
                          <p className="cue-translation">
                            {highlightMatch(cue.translation ?? cue.nativeTranslation ?? '')}
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
                          title={t('subs.edit_title')}
                        >
                          ✏️
                        </PixelButton>
                        <PixelButton
                          variant="ghost"
                          size="sm"
                          onClick={() => void handleTranslate(cue)}
                          disabled={isTranslating}
                          title={cue.translation || cue.nativeTranslation
                            ? cue.translationHidden ? t('subs.show_trans') : t('subs.hide_trans')
                            : t('subs.translate')}
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
                          title={t('subs.grammar_title')}
                        >
                          📖
                        </PixelButton>
                        <PixelButton
                          variant="ghost"
                          size="sm"
                          onClick={() => saveFavorite('sentence', cue.text, cue.id)}
                          title={t('subs.favorite_title')}
                        >
                          ★
                        </PixelButton>
                        <PixelButton
                          variant={inCart(cue.id) ? 'accent' : 'ghost'}
                          size="sm"
                          onClick={() => toggleAnkiCue(cue.id)}
                          title={inCart(cue.id) ? t('subs.remove_cart') : t('subs.add_cart')}
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
          <div className="grammar-drawer" role="dialog" aria-label={t('subs.grammar_analysis')}>
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