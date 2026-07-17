import { useState } from 'react';
import { useAppStore } from '../../store/appStore';
import { useI18n } from '../../context/I18nContext';
import { deleteFromStore } from '../../utils/storage';
import { ConfirmDialog, PixelButton, PixelPanel, PixelBadge } from '../PixelUI';
import type { FavoriteType } from '../../types';

const TYPE_LABELS: Record<FavoriteType, string> = {
  word: 'WORD',
  collocation: 'COLLOC',
  phrase: 'PHRASE',
  sentence: 'SENTENCE',
};

// These are only used as fallback keys; actual labels come from i18n via typeLabels in component

const TYPE_COLORS: Record<FavoriteType, string> = {
  word: 'green',
  collocation: 'blue',
  phrase: 'yellow',
  sentence: 'red',
};

export function FavoritesPanel() {
  const { t } = useI18n();
  const { favorites, addFavorite, removeFavorite, removeFavorites } = useAppStore();
  const [newText, setNewText] = useState('');
  const [newType, setNewType] = useState<FavoriteType>('word');
  const [filter, setFilter] = useState<FavoriteType | 'all'>('all');
  const [pendingDeleteId, setPendingDeleteId] = useState<string | null>(null);
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const [confirmBatch, setConfirmBatch] = useState(false);

  const typeLabels: Record<FavoriteType, string> = {
    word: t('fav.type_word'),
    collocation: t('fav.type_colloc'),
    phrase: t('fav.type_phrase'),
    sentence: t('fav.type_sentence'),
  };

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
    <PixelPanel title={t('panel.favorites')}>
      <ConfirmDialog
        open={pendingDeleteId != null}
        title={t('fav.delete_title')}
        message={
          pendingItem
            ? `Remove "${pendingItem.text.slice(0, 80)}${pendingItem.text.length > 80 ? '…' : ''}" from favorites?`
            : t('fav.delete_msg')
        }
        confirmLabel={t('fav.delete_label')}
        danger
        onConfirm={confirmDelete}
        onCancel={() => setPendingDeleteId(null)}
      />
      <ConfirmDialog
        open={confirmBatch}
        title={t('fav.delete_batch_title')}
        message={t('fav.delete_batch_msg').replace('{count}', String(selectedIds.size))}
        confirmLabel={t('fav.delete_batch_label')}
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
          {Object.entries(typeLabels).map(([k, v]) => (
            <option key={k} value={k}>
              {v}
            </option>
          ))}
        </select>
        <input
          className="pixel-input"
          placeholder={t('fav.placeholder')}
          value={newText}
          onChange={(e) => setNewText(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && handleAdd()}
        />
        <PixelButton variant="accent" size="sm" onClick={handleAdd}>
          +
        </PixelButton>
      </div>

      <div className="favorites-filter">
        {(['all', 'word', 'collocation', 'phrase', 'sentence'] as const).map((ft) => (
          <button
            key={ft}
            type="button"
            className={`filter-chip ${filter === ft ? 'active' : ''}`}
            onClick={() => setFilter(ft)}
          >
            {ft === 'all' ? t('fav.filter_all') : typeLabels[ft]}
          </button>
        ))}
      </div>

      {filtered.length > 0 && (
        <div className="favorites-batch-bar">
          <PixelButton variant="ghost" size="sm" onClick={selectAllFiltered}>
            {filtered.every((f) => selectedIds.has(f.id)) ? t('fav.deselect') : t('fav.select_all')}
          </PixelButton>
          <PixelButton
            variant="danger"
            size="sm"
            disabled={selectedCount === 0}
            onClick={() => setConfirmBatch(true)}
          >
            {t('fav.delete_count').replace('{count}', String(selectedCount))}
          </PixelButton>
        </div>
      )}

      <div className="favorites-list">
        {filtered.length === 0 ? (
          <p className="empty-hint">{t('fav.empty_hint')}</p>
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
              <PixelBadge color={TYPE_COLORS[item.type]}>{typeLabels[item.type]}</PixelBadge>
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