export type StatusVariant = 'success' | 'warning' | 'error' | 'info' | 'default' | 'primary';

// Helper function to determine status color based on common status names
export function getStatusColor(status: string): StatusVariant {
  const normalizedStatus = status.toLowerCase();
  
  // Success states
  if (['done', 'completed', 'released', 'active', 'success'].includes(normalizedStatus)) {
    return 'success';
  }
  
  // In progress states
  if (['in progress', 'in_progress', 'in-progress', 'pending', 'review'].includes(normalizedStatus)) {
    return 'info';
  }
  
  // Warning states
  if (['warning', 'planned', 'draft'].includes(normalizedStatus)) {
    return 'warning';
  }
  
  // Error states
  if (['error', 'cancelled', 'failed', 'blocked'].includes(normalizedStatus)) {
    return 'error';
  }
  
  return 'default';
}
