import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { UseCRUDOptions, UseCRUDReturn } from './types';

export function useCRUD<T, CreateData = Partial<T>, UpdateData = Partial<T>>({
  queryKey,
  listFn,
  createFn,
  updateFn,
  deleteFn,
  onCreateSuccess,
  onUpdateSuccess,
  onDeleteSuccess,
}: UseCRUDOptions<T, CreateData, UpdateData>): UseCRUDReturn<T, CreateData, UpdateData> {
  const queryClient = useQueryClient();

  const { data, isLoading, error, refetch } = useQuery({
    queryKey,
    queryFn: listFn,
  });

  // Always call hooks unconditionally
  const createMutation = useMutation({
    mutationFn: createFn ?? (() => Promise.reject(new Error('Create not supported'))),
    onSuccess: (data) => {
      queryClient.invalidateQueries({ queryKey });
      onCreateSuccess?.(data);
    },
  });

  const updateMutation = useMutation({
    mutationFn: updateFn
      ? ({ id, data }: { id: number; data: UpdateData }) => updateFn(id, data)
      : () => Promise.reject(new Error('Update not supported')),
    onSuccess: (data) => {
      queryClient.invalidateQueries({ queryKey });
      onUpdateSuccess?.(data);
    },
  });

  const deleteMutation = useMutation({
    mutationFn: deleteFn ?? (() => Promise.reject(new Error('Delete not supported'))),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey });
      onDeleteSuccess?.();
    },
  });

  return {
    items: data?.items ?? [],
    isLoading,
    error: error as Error | null,
    createMutation: createFn ? createMutation : null,
    updateMutation: updateFn ? updateMutation : null,
    deleteMutation: deleteFn ? deleteMutation : null,
    refetch,
  };
}
