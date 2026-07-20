import { create } from 'zustand';
import type {
  ABLoopSegment,
  AnkiCartItem,
  AnkiCardFormat,
  CartItemFormat,
  ClozeConfig,
  FavoriteItem,
  GrammarAnalysis,
  MediaFile,
  PracticeMode,
  RecentMediaItem,
  RecentSubtitleItem,
  SubtitleCue,
  SubtitleFile,
  VideoSubtitleMode,
} from '../types';
import { mergeCueGroups } from '../utils/bilingualText';

interface AppState {
  media: MediaFile | null;
  subtitles: SubtitleCue[];
  subtitleFile: SubtitleFile | null;
  /** Right panel subtitle list visibility */
  panelSubtitlesVisible: boolean;
  /** Video overlay subtitle mode */
  videoSubtitleMode: VideoSubtitleMode;
  currentTime: number;
  duration: number;
  isPlaying: boolean;
  playbackRate: number;

  pointA: number | null;
  pointB: number | null;
  abLoopActive: boolean;
  abHistory: ABLoopSegment[];
  skipSilent: boolean;
  leadTime: number;

  selectedCueId: string | null;
  grammarAnalysis: GrammarAnalysis | null;
  grammarDrawerOpen: boolean;

  favorites: FavoriteItem[];
  practiceMode: PracticeMode;

  ankiCart: AnkiCartItem[];

  recentMedia: RecentMediaItem[];
  recentSubtitleFiles: RecentSubtitleItem[];

  openaiApiKey: string;
  targetLanguage: string;
  /** File System Access API directory handle for Anki's media collection folder */
  ankiMediaDirHandle: FileSystemDirectoryHandle | null;

  isTranscribing: boolean;
  isTranslating: boolean;
  isAnalyzing: boolean;

  setMedia: (media: MediaFile | null) => void;
  setSubtitles: (cues: SubtitleCue[]) => void;
  setSubtitleFile: (file: SubtitleFile | null) => void;
  addRecentMedia: (item: Omit<RecentMediaItem, 'timestamp'>) => void;
  addRecentSubtitleFile: (item: Omit<RecentSubtitleItem, 'timestamp'>) => void;
  setRecentMedia: (items: RecentMediaItem[]) => void;
  setRecentSubtitleFiles: (items: RecentSubtitleItem[]) => void;
  updateCueText: (id: string, text: string) => void;
  updateCueTiming: (id: string, start: number, end: number) => void;
  setPanelSubtitlesVisible: (visible: boolean) => void;
  togglePanelSubtitles: () => void;
  setVideoSubtitleMode: (mode: VideoSubtitleMode) => void;
  setCurrentTime: (t: number) => void;
  setDuration: (d: number) => void;
  setIsPlaying: (p: boolean) => void;
  setPlaybackRate: (r: number) => void;

  setPointA: (t: number | null) => void;
  setPointB: (t: number | null) => void;
  toggleABLoop: () => void;
  saveABSegment: (label?: string) => void;
  loadABSegment: (seg: ABLoopSegment) => void;
  setABHistory: (history: ABLoopSegment[]) => void;
  toggleSkipSilent: () => void;
  setLeadTime: (ms: number) => void;

  setSelectedCueId: (id: string | null) => void;
  updateCueTranslation: (id: string, translation: string) => void;
  setCueTranslationHidden: (id: string, hidden: boolean) => void;
  setAllTranslationsHidden: (hidden: boolean) => void;
  setGrammarAnalysis: (a: GrammarAnalysis | null) => void;
  setGrammarDrawerOpen: (open: boolean) => void;

  addFavorite: (item: Omit<FavoriteItem, 'id' | 'createdAt'>) => void;
  removeFavorite: (id: string) => void;
  removeFavorites: (ids: string[]) => void;
  setFavorites: (items: FavoriteItem[]) => void;

  addToAnkiCart: (cueIds: string[]) => void;
  removeFromAnkiCart: (id: string) => void;
  mergeAnkiCartItems: (ids: string[]) => void;
  clearAnkiCart: () => void;
  updateAnkiCartItemFormats: (itemId: string, formats: CartItemFormat[]) => void;
  addFormatToAnkiCartItem: (itemId: string, format: AnkiCardFormat, clozeConfig?: ClozeConfig) => void;
  removeFormatFromAnkiCartItem: (itemId: string, format: AnkiCardFormat) => void;

  setPracticeMode: (mode: PracticeMode) => void;
  setOpenaiApiKey: (key: string) => void;
  setTargetLanguage: (lang: string) => void;
  setAnkiMediaDirHandle: (handle: FileSystemDirectoryHandle | null) => void;

  setIsTranscribing: (v: boolean) => void;
  setIsTranslating: (v: boolean) => void;
  setIsAnalyzing: (v: boolean) => void;
}

export const useAppStore = create<AppState>((set, get) => ({
  media: null,
  subtitles: [],
  subtitleFile: null,
  panelSubtitlesVisible: true,
  videoSubtitleMode: 'en',
  currentTime: 0,
  duration: 0,
  isPlaying: false,
  playbackRate: 1,

  pointA: null,
  pointB: null,
  abLoopActive: false,
  abHistory: [],
  skipSilent: false,
  leadTime: 0,

  selectedCueId: null,
  grammarAnalysis: null,
  grammarDrawerOpen: false,

  favorites: [],
  practiceMode: 'listen',

  ankiCart: [],

  recentMedia: [],
  recentSubtitleFiles: [],

  openaiApiKey: '',
  targetLanguage: 'Chinese',
  ankiMediaDirHandle: null,

  isTranscribing: false,
  isTranslating: false,
  isAnalyzing: false,

  setMedia: (media) =>
    set({
      media,
      currentTime: 0,
      duration: 0,
      isPlaying: false,
      pointA: null,
      pointB: null,
      abLoopActive: false,
      selectedCueId: null,
      grammarAnalysis: null,
      grammarDrawerOpen: false,
      ...(media === null ? { subtitles: [], subtitleFile: null, ankiCart: [] } : {}),
    }),
  setSubtitles: (cues) => {
    const sorted = [...cues].sort((a, b) => a.start - b.start || a.end - b.end);
    if (sorted.length > 0) {
      for (let i = 0; i < sorted.length; i++) {
        const prevEnd = i > 0 ? sorted[i - 1].end : 0;
        const gap = sorted[i].start - prevEnd;
        if (gap > 0.05 && gap < 2) {
          const lead = Math.min(gap * 0.5, 0.3);
          sorted[i] = { ...sorted[i], start: Math.max(prevEnd, sorted[i].start - lead) };
        }
      }
    }
    set({
      subtitles: sorted,
      selectedCueId: null,
      grammarAnalysis: null,
      grammarDrawerOpen: false,
    });
  },
  setSubtitleFile: (file) => set({ subtitleFile: file }),
  addRecentMedia: (item) =>
    set((s) => {
      const filtered = s.recentMedia.filter((media) => media.name !== item.name);
      return {
        recentMedia: [{ ...item, timestamp: Date.now() }, ...filtered].slice(0, 10),
      };
    }),
  addRecentSubtitleFile: (item) =>
    set((s) => {
      const filtered = s.recentSubtitleFiles.filter((file) => file.name !== item.name);
      return {
        recentSubtitleFiles: [{ ...item, timestamp: Date.now() }, ...filtered].slice(0, 10),
      };
    }),
  setRecentMedia: (items) => set({ recentMedia: items }),
  setRecentSubtitleFiles: (items) => set({ recentSubtitleFiles: items }),
  updateCueText: (id, text) =>
    set((s) => ({
      subtitles: s.subtitles.map((c) =>
        c.id === id ? { ...c, text, rawAssText: undefined } : c
      ),
    })),
  updateCueTiming: (id, start, end) =>
    set((s) => ({
      subtitles: [...s.subtitles]
        .map((c) => (c.id === id ? { ...c, start, end } : c))
        .sort((a, b) => a.start - b.start || a.end - b.end),
    })),
  setPanelSubtitlesVisible: (visible) => set({ panelSubtitlesVisible: visible }),
  togglePanelSubtitles: () =>
    set((s) => ({ panelSubtitlesVisible: !s.panelSubtitlesVisible })),
  setVideoSubtitleMode: (mode) => set({ videoSubtitleMode: mode }),
  setCurrentTime: (t) => set({ currentTime: t }),
  setDuration: (d) => set({ duration: Number.isFinite(d) ? d : 0 }),
  setIsPlaying: (p) => set({ isPlaying: p }),
  setPlaybackRate: (r) => set({ playbackRate: r }),

  setPointA: (t) => set({ pointA: t, abLoopActive: false }),
  setPointB: (t) => set({ pointB: t, abLoopActive: false }),
  toggleABLoop: () => {
    const { pointA, pointB, abLoopActive } = get();
    if (pointA == null || pointB == null) return;
    if (abLoopActive) {
      set({ abLoopActive: false });
      return;
    }
    const a = Math.min(pointA, pointB);
    const b = Math.max(pointA, pointB);
    if (b - a < 0.15) return;
    set({ pointA: a, pointB: b, abLoopActive: true });
  },
  saveABSegment: (label) => {
    const { pointA, pointB, abHistory } = get();
    if (pointA == null || pointB == null) return;
    const a = Math.min(pointA, pointB);
    const b = Math.max(pointA, pointB);
    if (b - a < 0.15) return;
    const seg: ABLoopSegment = {
      id: crypto.randomUUID(),
      label: label ?? `AB ${formatTime(a)} → ${formatTime(b)}`,
      pointA: a,
      pointB: b,
      createdAt: Date.now(),
    };
    set({ abHistory: [seg, ...abHistory], pointA: a, pointB: b });
  },
  loadABSegment: (seg) =>
    set({
      pointA: seg.pointA,
      pointB: seg.pointB,
      abLoopActive: true,
      currentTime: seg.pointA,
    }),
  setABHistory: (history) => set({ abHistory: history }),
  toggleSkipSilent: () => set((s) => ({ skipSilent: !s.skipSilent })),
  setLeadTime: (ms) => set({ leadTime: ms }),

  setSelectedCueId: (id) => set({ selectedCueId: id }),
  updateCueTranslation: (id, translation) =>
    set((s) => ({
      subtitles: s.subtitles.map((c) =>
        c.id === id ? { ...c, translation, translationHidden: false } : c
      ),
    })),
  setCueTranslationHidden: (id, hidden) =>
    set((s) => ({
      subtitles: s.subtitles.map((c) =>
        c.id === id ? { ...c, translationHidden: hidden } : c
      ),
    })),
  setAllTranslationsHidden: (hidden) =>
    set((s) => ({
      subtitles: s.subtitles.map((c) => ({ ...c, translationHidden: hidden })),
    })),
  setGrammarAnalysis: (a) => set({ grammarAnalysis: a }),
  setGrammarDrawerOpen: (open) => set({ grammarDrawerOpen: open }),

  addFavorite: (item) =>
    set((s) => ({
      favorites: [
        { ...item, id: crypto.randomUUID(), createdAt: Date.now() },
        ...s.favorites,
      ],
    })),
  removeFavorite: (id) =>
    set((s) => ({ favorites: s.favorites.filter((f) => f.id !== id) })),
  removeFavorites: (ids) => {
    const idSet = new Set(ids);
    set((s) => ({ favorites: s.favorites.filter((f) => !idSet.has(f.id)) }));
  },
  setFavorites: (items) => set({ favorites: items }),

  addToAnkiCart: (cueIds) => {
    const { subtitles, ankiCart } = get();
    if (cueIds.length === 0) return;
    const idSet = new Set(cueIds);
    // Avoid exact duplicate of same cue set
    const key = [...cueIds].sort().join(',');
    if (ankiCart.some((item) => [...item.cueIds].sort().join(',') === key)) return;

    const groups = mergeCueGroups(subtitles, idSet);
    if (groups.length === 0) return;

    // If multiple selected, prefer merging connected groups into cart items
    const items: AnkiCartItem[] = groups.map((g) => ({
      id: crypto.randomUUID(),
      cueIds: g.ids,
      text: g.text,
      translation: g.translation,
      nativeTranslation: g.nativeTranslation,
      start: g.start,
      end: g.end,
      addedAt: Date.now(),
      formats: [{ format: 'colloquial' }], // Default format
    }));

    set({ ankiCart: [...items, ...ankiCart] });
  },
  removeFromAnkiCart: (id) =>
    set((s) => ({ ankiCart: s.ankiCart.filter((i) => i.id !== id) })),


  mergeAnkiCartItems: (ids) => {
    const idSet = new Set(ids);
    const { ankiCart } = get();
    const selected = ankiCart
      .filter((item) => idSet.has(item.id))
      .sort((a, b) => a.start - b.start);
    if (selected.length < 2) return;

    const cueIds = [...new Set(selected.flatMap((item) => item.cueIds))];
    const merged: AnkiCartItem = {
      id: crypto.randomUUID(),
      cueIds,
      text: selected.map((item) => item.text.trim()).filter(Boolean).join(' '),
      translation: (() => {
        const parts = selected
          .map((item) => item.translation?.trim())
          .filter((text): text is string => typeof text === 'string' && text.length > 0);
        return parts.length > 0 ? parts.join(' ') : undefined;
      })(),
      nativeTranslation: (() => {
        const parts = selected
          .map((item) => item.nativeTranslation?.trim())
          .filter((text): text is string => typeof text === 'string' && text.length > 0);
        return parts.length > 0 ? parts.join(' ') : undefined;
      })(),
      start: Math.min(...selected.map((item) => item.start)),
      end: Math.max(...selected.map((item) => item.end)),
      addedAt: Date.now(),
      formats: [{ format: 'colloquial' }], // Default format for merged items
    };

    const remaining = ankiCart.filter((item) => !idSet.has(item.id));
    set({ ankiCart: [merged, ...remaining] });
  },
  clearAnkiCart: () => set({ ankiCart: [] }),
  updateAnkiCartItemFormats: (itemId, formats) =>
    set((s) => ({
      ankiCart: s.ankiCart.map((item) =>
        item.id === itemId ? { ...item, formats } : item
      ),
    })),
  addFormatToAnkiCartItem: (itemId, format, clozeConfig) =>
    set((s) => ({
      ankiCart: s.ankiCart.map((item) => {
        if (item.id !== itemId) return item;
        // Check if format already exists
        if (item.formats.some((f) => f.format === format)) return item;
        const newFormats = [...item.formats, { format, clozeConfig }];
        return { ...item, formats: newFormats };
      }),
    })),
  removeFormatFromAnkiCartItem: (itemId, format) =>
    set((s) => ({
      ankiCart: s.ankiCart.map((item) =>
        item.id === itemId
          ? { ...item, formats: item.formats.filter((f) => f.format !== format) }
          : item
      ),
    })),

  setPracticeMode: (mode) => set({ practiceMode: mode }),
  setOpenaiApiKey: (key) => set({ openaiApiKey: key }),
  setTargetLanguage: (lang) => set({ targetLanguage: lang }),
  setAnkiMediaDirHandle: (handle) => set({ ankiMediaDirHandle: handle }),

  setIsTranscribing: (v) => set({ isTranscribing: v }),
  setIsTranslating: (v) => set({ isTranslating: v }),
  setIsAnalyzing: (v) => set({ isAnalyzing: v }),
}));

function formatTime(sec: number): string {
  const m = Math.floor(sec / 60);
  const s = Math.floor(sec % 60);
  return `${m}:${String(s).padStart(2, '0')}`;
}

// Re-export for convenience
export { getEnglishText } from '../utils/bilingualText';