import { useState } from 'react';
import { useAppStore } from '../../store/appStore';
import { useI18n } from '../../context/I18nContext';
import { exportAnkiDeck, buildMultiFormatCards } from '../../utils/ankiExport';
import { ConfirmDialog, PixelButton, PixelPanel } from '../PixelUI';
import { formatTimeDisplay } from '../PixelUI';
import { ClozeEditor } from '../ClozeEditor';
import type { AnkiCardFormat, ClozeConfig } from '../../types';
import './AnkiExportPanel.css';

export function AnkiExportPanel() {
  const { t } = useI18n();
  const {
    media,
    ankiCart,
    ankiMediaDirHandle,
    removeFromAnkiCart,
    mergeAnkiCartItems,
    clearAnkiCart,
    addFormatToAnkiCartItem,
    removeFormatFromAnkiCartItem,
  } = useAppStore();
  const [isExporting, setIsExporting] = useState(false);
  const [selectedItemIds, setSelectedItemIds] = useState<Set<string>>(new Set());
  const [confirmClear, setConfirmClear] = useState(false);
  const [pendingRemoveId, setPendingRemoveId] = useState<string | null>(null);
  const [expandedItemId, setExpandedItemId] = useState<string | null>(null);
  const [editingItemId, setEditingItemId] = useState<string | null>(null);

  const toggleSelectedItem = (id: string) => {
    setSelectedItemIds((current) => {
      const next = new Set(current);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  const concatenateSelected = () => {
    mergeAnkiCartItems([...selectedItemIds]);
    setSelectedItemIds(new Set());
  };

  const handleAddFormat = (itemId: string, format: AnkiCardFormat) => {
    if (format === 'cloze_deletion') {
      setEditingItemId(itemId);
    } else {
      addFormatToAnkiCartItem(itemId, format);
    }
  };

  const handleRemoveFormat = (itemId: string, format: AnkiCardFormat) => {
    removeFormatFromAnkiCartItem(itemId, format);
  };

  const handleClozeConfigSave = (config: ClozeConfig) => {
    if (editingItemId) {
      addFormatToAnkiCartItem(editingItemId, 'cloze_deletion', config);
      setEditingItemId(null);
    }
  };

  const handleExport = async () => {
    if (ankiCart.length === 0) return;
    setIsExporting(true);
    try {
      const allCards = ankiCart.flatMap((item) =>
        buildMultiFormatCards({
          text: item.text,
          translation: item.translation,
          nativeTranslation: item.nativeTranslation,
          start: item.start,
          end: item.end,
          formats: item.formats,
        })
      );

      await exportAnkiDeck(
        'PixelListen_Cart',
        allCards,
        media?.url ?? null,
        media?.type === 'video',
        ankiMediaDirHandle
      );
    } finally {
      setIsExporting(false);
    }
  };

  const availableFormats: AnkiCardFormat[] = ['colloquial', 'listening_review', 'cloze_deletion'];
  const formatLabels: Record<AnkiCardFormat, string> = {
    colloquial: t('anki.colloquial'),
    listening_review: t('anki.listening'),
    cloze_deletion: t('anki.cloze'),
  };
  const formatDescriptions: Record<AnkiCardFormat, string> = {
    colloquial: t('anki.colloquial_desc'),
    listening_review: t('anki.listening_desc'),
    cloze_deletion: t('anki.cloze_desc'),
  };

  return (
    <PixelPanel
      title={t('panel.anki_cart')}
      actions={
        ankiCart.length > 0 ? (
          <span className="anki-cart-badge">{ankiCart.length}</span>
        ) : undefined
      }
    >
      {editingItemId && (
        <ClozeEditor
          text={ankiCart.find((item) => item.id === editingItemId)?.text || ''}
          initialConfig={
            ankiCart
              .find((item) => item.id === editingItemId)
              ?.formats.find((f) => f.format === 'cloze_deletion')?.clozeConfig
          }
          onSave={handleClozeConfigSave}
          onCancel={() => setEditingItemId(null)}
        />
      )}

      <ConfirmDialog
        open={confirmClear}
        title={t('common.clear')}
        message={t('anki.clear_msg')}
        confirmLabel={t('common.clear')}
        danger
        onConfirm={() => {
          clearAnkiCart();
          setConfirmClear(false);
        }}
        onCancel={() => setConfirmClear(false)}
      />
      <ConfirmDialog
        open={pendingRemoveId != null}
        title={t('common.remove')}
        message={t('anki.remove_msg')}
        confirmLabel={t('common.remove')}
        danger
        onConfirm={() => {
          if (pendingRemoveId) removeFromAnkiCart(pendingRemoveId);
          setPendingRemoveId(null);
        }}
        onCancel={() => setPendingRemoveId(null)}
      />

      <div className="anki-export">
        <p className="anki-hint">
          {t('anki.hint')}
        </p>

        {ankiCart.length === 0 ? (
          <p className="empty-hint">{t('anki.empty')}</p>
        ) : (
          <>
            <div className="anki-cart-actions">
              <PixelButton
                variant="secondary"
                size="sm"
                onClick={concatenateSelected}
                disabled={selectedItemIds.size < 2}
              >
                {t('common.concatenate')} ({selectedItemIds.size})
              </PixelButton>
              <PixelButton variant="ghost" size="sm" onClick={() => setConfirmClear(true)}>
                {t('common.clear')}
              </PixelButton>
              <PixelButton variant="accent" size="sm" onClick={handleExport} disabled={isExporting}>
                {isExporting ? '⏳...' : t('common.export')}
              </PixelButton>
            </div>
            <div className="anki-cart-list">
              {ankiCart.map((item) => (
                <div
                  key={item.id}
                  className={`anki-cart-item${selectedItemIds.has(item.id) ? ' selected' : ''}`}
                >
                  <label className="anki-cart-check" title={t('anki.concat_title')}>
                    <input
                      type="checkbox"
                      checked={selectedItemIds.has(item.id)}
                      onChange={() => toggleSelectedItem(item.id)}
                    />
                  </label>
                  <div className="anki-cart-body">
                    {(item.translation || item.nativeTranslation) && (
                      <p className="anki-cart-front">
                        {item.translation ?? item.nativeTranslation}
                      </p>
                    )}
                    <p className="anki-cart-back">{item.text}</p>
                    <span className="anki-cart-time">
                      {formatTimeDisplay(item.start)} → {formatTimeDisplay(item.end)}
                      {item.cueIds.length > 1 ? ` · ${item.cueIds.length} lines` : ''}
                    </span>

                    {/* Format selection */}
                    <div className="anki-formats">
                      <div className="formats-header">
                        <span>{t('anki.formats')}</span>
                        <PixelButton
                          variant="ghost"
                          size="sm"
                          onClick={() =>
                            setExpandedItemId(
                              expandedItemId === item.id ? null : item.id
                            )
                          }
                        >
                          {expandedItemId === item.id ? '▼' : '▶'}
                        </PixelButton>
                      </div>
                      <div className="formats-selected">
                        {item.formats.map((fmt) => (
                          <span key={fmt.format} className="format-badge">
                            {formatLabels[fmt.format]}
                            <button
                              className="format-remove"
                              onClick={() => handleRemoveFormat(item.id, fmt.format)}
                            >
                              ✕
                            </button>
                          </span>
                        ))}
                      </div>
                      {expandedItemId === item.id && (
                        <div className="formats-available">
                          {availableFormats
                            .filter((f) => !item.formats.some((fmt) => fmt.format === f))
                            .map((format) => (
                              <div key={format} className="format-option">
                                <button
                                  className="format-add-btn"
                                  onClick={() => handleAddFormat(item.id, format)}
                                >
                                  + {formatLabels[format]}
                                </button>
                                <span className="format-desc">
                                  {formatDescriptions[format]}
                                </span>
                              </div>
                            ))}
                        </div>
                      )}
                    </div>
                  </div>
                  <PixelButton
                    variant="danger"
                    size="sm"
                    onClick={() => setPendingRemoveId(item.id)}
                  >
                    {t('common.remove')}
                  </PixelButton>
                </div>
              ))}
            </div>
          </>
        )}
      </div>
    </PixelPanel>
  );
}