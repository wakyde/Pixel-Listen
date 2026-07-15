import { useState } from 'react';
import { useAppStore } from '../../store/appStore';
import { exportAnkiDeck, buildCartCards } from '../../utils/ankiExport';
import { ConfirmDialog, PixelButton, PixelPanel } from '../PixelUI';
import { formatTimeDisplay } from '../PixelUI';

export function AnkiExportPanel() {
  const {
    media,
    ankiCart,
    removeFromAnkiCart,
    mergeAnkiCartItems,
    clearAnkiCart,
  } = useAppStore();
  const [isExporting, setIsExporting] = useState(false);
  const [selectedItemIds, setSelectedItemIds] = useState<Set<string>>(new Set());
  const [confirmClear, setConfirmClear] = useState(false);
  const [pendingRemoveId, setPendingRemoveId] = useState<string | null>(null);

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

  const handleExport = async () => {
    if (ankiCart.length === 0) return;
    setIsExporting(true);
    try {
      const cards = buildCartCards(
        ankiCart.map((c) => ({
          text: c.text,
          translation: c.translation,
          start: c.start,
          end: c.end,
        }))
      );
      await exportAnkiDeck(
        'PixelListen_Cart',
        cards,
        media?.url ?? null,
        media?.type === 'video'
      );
    } finally {
      setIsExporting(false);
    }
  };

  return (
    <PixelPanel
      title="ANKI CART"
      actions={
        ankiCart.length > 0 ? (
          <span className="anki-cart-badge">{ankiCart.length}</span>
        ) : undefined
      }
    >
      <ConfirmDialog
        open={confirmClear}
        title="Clear cart?"
        message="Remove all items from the Anki cart?"
        confirmLabel="CLEAR"
        danger
        onConfirm={() => {
          clearAnkiCart();
          setConfirmClear(false);
        }}
        onCancel={() => setConfirmClear(false)}
      />
      <ConfirmDialog
        open={pendingRemoveId != null}
        title="Remove from cart?"
        message="Remove this card from the Anki cart?"
        confirmLabel="REMOVE"
        danger
        onConfirm={() => {
          if (pendingRemoveId) removeFromAnkiCart(pendingRemoveId);
          setPendingRemoveId(null);
        }}
        onCancel={() => setPendingRemoveId(null)}
      />

      <div className="anki-export">
        <p className="anki-hint">
          Add subtitle lines with 🛒, select any two or more segments here, then use
          CONCATENATE to combine them into one card in timeline order. Front = translation ·
          Back = English + audio/video.
        </p>

        {ankiCart.length === 0 ? (
          <p className="empty-hint">Cart is empty — add lines from SUBS</p>
        ) : (
          <>
            <div className="anki-cart-actions">
              <PixelButton
                variant="secondary"
                size="sm"
                onClick={concatenateSelected}
                disabled={selectedItemIds.size < 2}
              >
                CONCATENATE ({selectedItemIds.size})
              </PixelButton>
              <PixelButton variant="ghost" size="sm" onClick={() => setConfirmClear(true)}>
                CLEAR
              </PixelButton>
              <PixelButton variant="accent" size="sm" onClick={handleExport} disabled={isExporting}>
                {isExporting ? '⏳...' : '📦 EXPORT'}
              </PixelButton>
            </div>
            <div className="anki-cart-list">
              {ankiCart.map((item) => (
                <div
                  key={item.id}
                  className={`anki-cart-item${selectedItemIds.has(item.id) ? ' selected' : ''}`}
                >
                  <label className="anki-cart-check" title="Select segment to concatenate">
                    <input
                      type="checkbox"
                      checked={selectedItemIds.has(item.id)}
                      onChange={() => toggleSelectedItem(item.id)}
                    />
                  </label>
                  <div className="anki-cart-body">
                    {item.translation && (
                      <p className="anki-cart-front">{item.translation}</p>
                    )}
                    <p className="anki-cart-back">{item.text}</p>
                    <span className="anki-cart-time">
                      {formatTimeDisplay(item.start)} → {formatTimeDisplay(item.end)}
                      {item.cueIds.length > 1 ? ` · ${item.cueIds.length} lines` : ''}
                    </span>
                  </div>
                  <PixelButton
                    variant="danger"
                    size="sm"
                    onClick={() => setPendingRemoveId(item.id)}
                  >
                    ✕
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
