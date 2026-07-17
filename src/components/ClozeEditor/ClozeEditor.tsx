import { useState } from 'react';
import { useI18n } from '../../context/I18nContext';
import type { ClozeConfig } from '../../types';
import { PixelButton, PixelPanel } from '../PixelUI';
import './ClozeEditor.css';

interface ClozeEditorProps {
  text: string;
  initialConfig?: ClozeConfig;
  onSave: (config: ClozeConfig) => void;
  onCancel: () => void;
}

export function ClozeEditor({ text, initialConfig, onSave, onCancel }: ClozeEditorProps) {
  const { t } = useI18n();
  const [blanks, setBlanks] = useState<{ start: number; end: number }[]>(
    initialConfig?.blanks || []
  );
  const [selectedRange, setSelectedRange] = useState<{ start: number; end: number } | null>(null);

  // Handle text selection via mouse
  const handleMouseUp = () => {
    const selection = window.getSelection();
    if (!selection?.toString()) return;

    const range = selection.getRangeAt(0);
    const preRange = range.cloneRange();
    preRange.selectNodeContents(document.getElementById('cloze-text') || new Text());
    preRange.setEnd(range.endContainer, range.endOffset);
    const start = preRange.toString().length - range.toString().length;
    const end = start + range.toString().length;

    // Validate that selection doesn't cross blank boundaries
    const overlaps = blanks.some(
      (b) => (start < b.end && end > b.start) || (start >= b.start && start < b.end)
    );

    if (!overlaps) {
      setSelectedRange({ start, end });
    }
    selection.removeAllRanges();
  };

  const addBlank = () => {
    if (selectedRange) {
      const newBlanks = [...blanks, selectedRange].sort((a, b) => a.start - b.start);
      setBlanks(newBlanks);
      setSelectedRange(null);
    }
  };

  const removeBlank = (index: number) => {
    setBlanks(blanks.filter((_, i) => i !== index));
  };

  const handleSave = () => {
    onSave({
      originalText: text,
      blanks,
    });
  };

  // Generate sentence with blanks removed for the card preview
  const generateClozeText = (): string => {
    let result = text;
    // Sort blanks in reverse order to maintain correct indices
    const sortedBlanks = [...blanks].sort((a, b) => b.start - a.start);
    sortedBlanks.forEach((blank) => {
      result = result.substring(0, blank.start) + '______' + result.substring(blank.end);
    });
    return result;
  };

  // Generate answer key
  const generateAnswerKey = (): string[] => {
    return blanks.map((blank) => text.substring(blank.start, blank.end));
  };

  return (
    <PixelPanel title={t('cloze.title')}>
      <div className="cloze-editor">
        {/* Instructions */}
        <div className="cloze-instructions">
          <p>{t('cloze.instructions_full')}</p>
        </div>

        {/* Text selection area */}
        <div className="cloze-text-container">
          <div
            id="cloze-text"
            className="cloze-text"
            onMouseUp={handleMouseUp}
            title={t('cloze.select_hint')}
          >
            {text}
          </div>

          {selectedRange && (
            <div className="cloze-selection-info">
              <p>
                {t('cloze.selected')} "<strong>{text.substring(selectedRange.start, selectedRange.end)}</strong>"
              </p>
              <PixelButton
                variant="primary"
                size="sm"
                onClick={addBlank}
              >
                {t('cloze.add_blank')}
              </PixelButton>
            </div>
          )}
        </div>

        {/* Blanks list */}
        {blanks.length > 0 && (
          <div className="cloze-blanks-list">
            <h3>{t('cloze.blanks_count').replace('{count}', String(blanks.length))}</h3>
            {blanks.map((blank, idx) => (
              <div key={idx} className="cloze-blank-item">
                <span className="blank-index">#{idx + 1}</span>
                <span className="blank-text">
                  {text.substring(blank.start, blank.end)}
                </span>
                <PixelButton
                  variant="danger"
                  size="sm"
                  onClick={() => removeBlank(idx)}
                >
                  ✕
                </PixelButton>
              </div>
            ))}
          </div>
        )}

        {/* Preview */}
        <div className="cloze-preview">
          <h3>{t('cloze.preview_title')}</h3>
          <div className="cloze-preview-card">
            <div className="preview-front">
              <strong>{t('cloze.front_label')}</strong>
              <p className="preview-text">{generateClozeText()}</p>
            </div>
            <div className="preview-back">
              <strong>{t('cloze.back_label')}</strong>
              <ol className="preview-answers">
                {generateAnswerKey().map((answer, idx) => (
                  <li key={idx}>{answer}</li>
                ))}
              </ol>
            </div>
          </div>
        </div>

        {/* Actions */}
        <div className="cloze-actions">
          <PixelButton
            variant="primary"
            onClick={handleSave}
            disabled={blanks.length === 0}
          >
            {t('cloze.save_config')}
          </PixelButton>
          <PixelButton
            variant="secondary"
            onClick={onCancel}
          >
            {t('common.cancel')}
          </PixelButton>
        </div>
      </div>
    </PixelPanel>
  );
}