export interface AssCueMeta {
  layer: string;
  style: string;
  name: string;
  marginL: string;
  marginR: string;
  marginV: string;
  effect: string;
}

export interface SubtitleCue {
  id: string;
  start: number;
  end: number;
  /** English (or primary) subtitle text */
  text: string;
  /** Revealed / API translation shown under English */
  translation?: string;
  /** Whether an available translation is hidden in the UI */
  translationHidden?: boolean;
  /** Chinese (or other) text embedded in bilingual files; shown after Translate */
  nativeTranslation?: string;
  assMeta?: AssCueMeta;
  /** Original ASS text with override tags; used when saving if not edited */
  rawAssText?: string;
}

/** Video overlay subtitle display mode */
export type VideoSubtitleMode = 'en' | 'zh' | 'both' | 'off';

export interface AnkiCartItem {
  id: string;
  cueIds: string[];
  text: string;
  translation?: string;
  nativeTranslation?: string;
  start: number;
  end: number;
  addedAt: number;
}

export type SubtitleFormat = 'srt' | 'vtt' | 'ass' | 'none';

export interface SubtitleFile {
  name: string;
  format: SubtitleFormat;
  /** File System Access API handle for in-place save */
  fileHandle?: FileSystemFileHandle | null;
  /** ASS: all content before the first Dialogue: line */
  assPreamble?: string;
}

export type FavoriteType = 'word' | 'collocation' | 'phrase' | 'sentence';

export interface FavoriteItem {
  id: string;
  type: FavoriteType;
  text: string;
  context?: string;
  translation?: string;
  mediaTime?: number;
  cueId?: string;
  createdAt: number;
}

export interface ABLoopSegment {
  id: string;
  label: string;
  pointA: number;
  pointB: number;
  createdAt: number;
}

export interface MediaFile {
  name: string;
  url: string;
  type: 'video' | 'audio';
  mimeType: string;
  file: File;
  fileHandle?: FileSystemFileHandle | null;
}

export interface RecentMediaItem {
  name: string;
  type: 'video' | 'audio';
  mimeType: string;
  fileHandle?: FileSystemFileHandle | null;
  timestamp: number;
}

export interface RecentSubtitleItem {
  name: string;
  format: SubtitleFormat;
  fileHandle?: FileSystemFileHandle | null;
  timestamp: number;
}

export interface GrammarAnalysis {
  sentence: string;
  structure: string;
  keyPoints: string[];
  vocabulary: { word: string; meaning: string }[];
  suggestions: string[];
}

export interface AnkiCard {
  /** Front of card — typically the translation */
  front: string;
  /** Back of card — original + media markers */
  back: string;
  audioStart?: number;
  audioEnd?: number;
  tags: string[];
  mode: 'custom' | 'ai' | 'cart';
}

export type PracticeMode = 'listen' | 'typing' | 'recording';

export interface TypingResult {
  cueId: string;
  expected: string;
  typed: string;
  accuracy: number;
  completedAt: number;
}

export interface RecordingItem {
  id: string;
  cueId: string;
  blob: Blob;
  url: string;
  createdAt: number;
}

export interface AppSettings {
  playbackRate: number;
  panelSubtitlesVisible: boolean;
  videoSubtitleMode: VideoSubtitleMode;
  targetLanguage: string;
  openaiApiKey: string;
}
