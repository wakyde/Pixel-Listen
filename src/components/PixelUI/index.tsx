import { useEffect, useCallback, type ButtonHTMLAttributes, type ReactNode } from 'react';

interface PixelButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'accent' | 'danger' | 'ghost';
  size?: 'sm' | 'md' | 'lg';
  children: ReactNode;
}

const variantClass = {
  primary: 'pixel-btn-primary',
  secondary: 'pixel-btn-secondary',
  accent: 'pixel-btn-accent',
  danger: 'pixel-btn-danger',
  ghost: 'pixel-btn-ghost',
};

const sizeClass = {
  sm: 'pixel-btn-sm',
  md: '',
  lg: 'pixel-btn-lg',
};

export function PixelButton({
  variant = 'primary',
  size = 'md',
  className = '',
  children,
  ...props
}: PixelButtonProps) {
  return (
    <button
      type="button"
      className={`pixel-btn ${variantClass[variant]} ${sizeClass[size]} ${className}`}
      {...props}
    >
      {children}
    </button>
  );
}

interface PixelPanelProps {
  title?: string;
  children: ReactNode;
  className?: string;
  actions?: ReactNode;
}

export function PixelPanel({ title, children, className = '', actions }: PixelPanelProps) {
  return (
    <div className={`pixel-panel ${className}`}>
      {title && (
        <div className="pixel-panel-header">
          <h3 className="pixel-panel-title">{title}</h3>
          {actions && <div className="pixel-panel-actions">{actions}</div>}
        </div>
      )}
      <div className="pixel-panel-body">{children}</div>
    </div>
  );
}

export function PixelBadge({ children, color = 'green' }: { children: ReactNode; color?: string }) {
  return <span className={`pixel-badge pixel-badge-${color}`}>{children}</span>;
}

export function PixelInput(props: React.InputHTMLAttributes<HTMLInputElement>) {
  return <input className="pixel-input" {...props} />;
}

export function PixelTextarea(props: React.TextareaHTMLAttributes<HTMLTextAreaElement>) {
  return <textarea className="pixel-textarea" {...props} />;
}

export function PixelSelect(props: React.SelectHTMLAttributes<HTMLSelectElement>) {
  return <select className="pixel-select" {...props} />;
}

export function formatTimeDisplay(seconds: number): string {
  if (!Number.isFinite(seconds) || seconds < 0) return '0:00';
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = Math.floor(seconds % 60);
  if (h > 0) return `${h}:${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
  return `${m}:${String(s).padStart(2, '0')}`;
}

interface ConfirmDialogProps {
  open: boolean;
  title: string;
  message: string;
  confirmLabel?: string;
  cancelLabel?: string;
  danger?: boolean;
  onConfirm: () => void;
  onCancel: () => void;
}

export function ConfirmDialog({
  open,
  title,
  message,
  confirmLabel = 'CONFIRM',
  cancelLabel = 'CANCEL',
  danger = false,
  onConfirm,
  onCancel,
}: ConfirmDialogProps) {
  const onKeyDown = useCallback(
    (e: KeyboardEvent) => {
      if (!open) return;
      if (e.key === 'Escape') onCancel();
    },
    [open, onCancel]
  );

  useEffect(() => {
    document.addEventListener('keydown', onKeyDown);
    return () => document.removeEventListener('keydown', onKeyDown);
  }, [onKeyDown]);

  if (!open) return null;

  return (
    <div className="confirm-overlay" role="presentation" onClick={onCancel}>
      <div
        className="confirm-dialog"
        role="alertdialog"
        aria-modal="true"
        aria-labelledby="confirm-title"
        aria-describedby="confirm-message"
        onClick={(e) => e.stopPropagation()}
      >
        <h3 id="confirm-title" className="confirm-title">
          {title}
        </h3>
        <p id="confirm-message" className="confirm-message">
          {message}
        </p>
        <div className="confirm-actions">
          <PixelButton variant="ghost" size="sm" onClick={onCancel}>
            {cancelLabel}
          </PixelButton>
          <PixelButton
            variant={danger ? 'danger' : 'accent'}
            size="sm"
            onClick={onConfirm}
            autoFocus
          >
            {confirmLabel}
          </PixelButton>
        </div>
      </div>
    </div>
  );
}

export { Drawer } from './Drawer';
