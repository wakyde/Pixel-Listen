import { createContext, useContext, useRef, type RefObject, type ReactNode } from 'react';

interface MediaContextValue {
  mediaRef: RefObject<HTMLVideoElement | HTMLAudioElement | null>;
}

const MediaContext = createContext<MediaContextValue | null>(null);

export function MediaProvider({ children }: { children: ReactNode }) {
  const mediaRef = useRef<HTMLVideoElement | HTMLAudioElement>(null);
  return <MediaContext.Provider value={{ mediaRef }}>{children}</MediaContext.Provider>;
}

export function useMediaRef() {
  const ctx = useContext(MediaContext);
  if (!ctx) throw new Error('useMediaRef must be used within MediaProvider');
  return ctx.mediaRef;
}
