import { ReactNode } from 'react';
import { getStatusColor, StatusVariant } from '@/utils/statusUtils';

interface StatusBadgeProps {
  children: ReactNode;
  variant?: StatusVariant;
  size?: 'sm' | 'md';
  className?: string;
  color?: string | null; // Custom color override
}

const variantClasses: Record<StatusVariant, string> = {
  success: 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400',
  warning: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400',
  error: 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400',
  info: 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-400',
  primary: 'bg-primary-100 text-primary-800 dark:bg-primary-900/30 dark:text-primary-400',
  default: 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300',
};

const sizeClasses = {
  sm: 'px-2 py-0.5 text-xs',
  md: 'px-2.5 py-0.5 text-sm',
};

export function StatusBadge({
  children,
  variant = 'default',
  size = 'sm',
  className = '',
  color,
}: StatusBadgeProps) {
  // If custom color is provided, use it
  const style = color ? {
    backgroundColor: `${color}20`,
    color: color,
  } : undefined;

  return (
    <span
      className={`inline-flex items-center rounded-full font-medium ${
        color ? '' : variantClasses[variant]
      } ${sizeClasses[size]} ${className}`}
      style={style}
    >
      {children}
    </span>
  );
}

// Convenience component that automatically determines color
export function AutoStatusBadge({ status, className = '' }: { status: string; className?: string }) {
  return (
    <StatusBadge variant={getStatusColor(status)} className={className}>
      {status}
    </StatusBadge>
  );
}
