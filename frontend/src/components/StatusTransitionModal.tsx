import { FormModal, SelectInput } from '@/components/ui';

interface StatusTransitionModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: () => void;
  isLoading: boolean;
  statusToRemove: string;
  itemCount: number;
  availableStatuses: string[];
  targetStatus: string;
  onTargetStatusChange: (status: string) => void;
  /** The type of entity being transitioned (e.g., "theme", "project", "task") */
  entityType: 'theme' | 'project' | 'task';
}

/**
 * Reusable modal for transitioning items from one status to another
 * when removing a status from a workflow.
 */
export function StatusTransitionModal({
  isOpen,
  onClose,
  onSubmit,
  isLoading,
  statusToRemove,
  itemCount,
  availableStatuses,
  targetStatus,
  onTargetStatusChange,
  entityType,
}: StatusTransitionModalProps) {
  const entityPlural = itemCount === 1 ? entityType : `${entityType}s`;
  
  return (
    <FormModal
      isOpen={isOpen}
      onClose={onClose}
      onSubmit={onSubmit}
      title="Remove Status from Workflow"
      submitLabel="Transition & Remove"
      loadingLabel="Transitioning..."
      isLoading={isLoading}
    >
      <div className="space-y-4">
        <div className="p-3 bg-amber-50 dark:bg-amber-900/20 rounded-lg">
          <p className="text-sm text-amber-800 dark:text-amber-200">
            The status <strong className="capitalize">"{statusToRemove}"</strong> is currently used by{' '}
            <strong>{itemCount} {entityPlural}</strong>.
          </p>
        </div>
        
        <p className="text-sm text-gray-600 dark:text-gray-400">
          To remove this status from the workflow, all {entityPlural} with this status will be transitioned to another status.
        </p>
        
        <SelectInput
          label={`Transition ${entityPlural} to`}
          value={targetStatus}
          onChange={(e) => onTargetStatusChange(e.target.value)}
          options={availableStatuses.map((s) => ({
            value: s,
            label: s.charAt(0).toUpperCase() + s.slice(1),
          }))}
        />
        
        <div className="p-3 bg-gray-50 dark:bg-gray-700/50 rounded-lg">
          <p className="text-xs text-gray-500 dark:text-gray-400">
            This action will update {itemCount} {entityPlural} to the new status
            and remove "{statusToRemove}" from the workflow.
          </p>
        </div>
      </div>
    </FormModal>
  );
}