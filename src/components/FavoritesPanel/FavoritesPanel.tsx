import { useState } from 'react';
import { useAppStore } from '../../store/appStore';
import { deleteFromStore } from '../../utils/storage';
import { ConfirmDialog, PixelButton, PixelPanel, PixelBadge } from '../PixelUI';
import type { FavoriteType } from '../../types';

const TYPE_LABELS: Record<FavoriteType, string> = {
  word: 'WORD',
  collocation: 'COLLOC',
  phrase: 'PHRASE',
  sentence: 'SENTENCE',
};

const TYPE_COLORS: Record<FavoriteType, string> = {
  word: 'green',
  collocation: 'blue',
  phrase: 'yellow',
  sentence: 'red',
};

export function FavoritesPanel() {
  const { favorites, addFavorite, removeFavorite, removeFavorites } = useAppStore();
  const [newText, setNewText] = useState('');
  const [newType, setNewType] = useState<FavoriteType>('word');
  const [filter, setFilter] = useState<FavoriteType | 'all'>('all');
  const [pendingDeleteId, setPendingDeleteId] = useState<string | null>(null);
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const [confirmBatch, setConfirmBatch] = useState(false);

  const filtered =
    filter === 'all' ? favorites : favorites.filter((f) => f.type === filter);

  const pendingItem = pendingDeleteId
    ? favorites.find((f) => f.id === pendingDeleteId)
    : null;

  const handleAdd = () => {
    if (!newText.trim()) return;
    addFavorite({ type: newType, text: newText.trim() });
    setNewText('');
  };

  const confirmDelete = () => {
    if (!pendingDeleteId) return;
    removeFavorite(pendingDeleteId);
    void deleteFromStore('favorites', pendingDeleteId);
    setSelectedIds((prev) => {
      const next = new Set(prev);
      next.delete(pendingDeleteId);
      return next;
    });
    setPendingDeleteId(null);
  };

  const toggleSelect = (id: string) => {
    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  const selectAllFiltered = () => {
    if (filtered.every((f) => selectedIds.has(f.id)) && filtered.length > 0) {
      setSelectedIds((prev) => {
        const next = new Set(prev);
        filtered.forEach((f) => next.delete(f.id));
        return next;
      });
    } else {
      setSelectedIds((prev) => {
        const next = new Set(prev);
        filtered.forEach((f) => next.add(f.id));
        return next;
      });
    }
  };

  const confirmBatchDelete = () => {
    const ids = [...selectedIds];
    removeFavorites(ids);
    ids.forEach((id) => void deleteFromStore('favorites', id));
    setSelectedIds(new Set());
    setConfirmBatch(false);
  };

  const selectedCount = [...selectedIds].filter((id) =>
    filtered.some((f) => f.id === id)
  ).length;

  return (
    <PixelPanel title="FAVORITES">
      <ConfirmDialog
        open={pendingDeleteId != null}
        title="Delete favorite?"
        message={
          pendingItem
            ? `Remove “${pendingItem.text.slice(0, 80)}${pendingItem.text.length > 80 ? '…' : ''}” from favorites?`
            : 'Remove this favorite?'
        }
        confirmLabel="DELETE"
        danger
        onConfirm={confirmDelete}
        onCancel={() => setPendingDeleteId(null)}
      />
      <ConfirmDialog
        open={confirmBatch}
        title="Delete selected?"
        message={`Remove ${selectedIds.size} favorite(s)? This cannot be undone.`}
        confirmLabel="DELETE ALL"
        danger
        onConfirm={confirmBatchDelete}
        onCancel={() => setConfirmBatch(false)}
      />

      <div className="favorites-add">
        <select
          className="pixel-select"
          value={newType}
          onChange={(e) => setNewType(e.target.value as FavoriteType)}
        >
          {Object.entries(TYPE_LABELS).map(([k, v]) => (
            <option key={k} value={k}>
              {v}
            </option>
          ))}
        </select>
        <input
          className="pixel-input"
          placeholder="Add word, phrase, or sentence..."
          value={newText}
          onChange={(e) => setNewText(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && handleAdd()}
        />
        <PixelButton variant="accent" size="sm" onClick={handleAdd}>
          +
        </PixelButton>
      </div>

      <div className="favorites-filter">
        {(['all', 'word', 'collocation', 'phrase', 'sentence'] as const).map((t) => (
          <button
            key={t}
            type="button"
            className={`filter-chip ${filter === t ? 'active' : ''}`}
            onClick={() => setFilter(t)}
          >
            {t === 'all' ? 'ALL' : TYPE_LABELS[t]}
          </button>
        ))}
      </div>

      {filtered.length > 0 && (
        <div className="favorites-batch-bar">
          <PixelButton variant="ghost" size="sm" onClick={selectAllFiltered}>
            {filtered.every((f) => selectedIds.has(f.id)) ? 'DESELECT' : 'SELECT ALL'}
          </PixelButton>
          <PixelButton
            variant="danger"
            size="sm"
            disabled={selectedCount === 0}
            onClick={() => setConfirmBatch(true)}
          >
            DELETE ({selectedCount})
          </PixelButton>
        </div>
      )}

      <div className="favorites-list">
        {filtered.length === 0 ? (
          <p className="empty-hint">Save words & sentences from subtitles</p>
        ) : (
          filtered.map((item) => (
            <div key={item.id} className="favorite-item">
              <label className="favorite-check">
                <input
                  type="checkbox"
                  checked={selectedIds.has(item.id)}
                  onChange={() => toggleSelect(item.id)}
                />
              </label>
              <PixelBadge color={TYPE_COLORS[item.type]}>{TYPE_LABELS[item.type]}</PixelBadge>
              <div className="favorite-content">
                <p className="favorite-text cue-text">{item.text}</p>
                {item.translation && (
                  <p className="favorite-translation cue-translation">{item.translation}</p>
                )}
                {item.context && item.context !== item.text && (
                  <p className="favorite-context">↳ {item.context}</p>
                )}
              </div>
              <PixelButton
                variant="danger"
                size="sm"
                onClick={() => setPendingDeleteId(item.id)}
              >
                ✕
              </PixelButton>
            </div>
          ))
        )}
      </div>
    </PixelPanel>
  );
}
