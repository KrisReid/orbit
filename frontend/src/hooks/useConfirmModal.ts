import { useState, useCallback } from 'react';
import type { ConfirmModalVariant } from '@/components/ConfirmModal';

export function useConfirmModal() {
  const [modalState, setModalState] = useState<{
    isOpen: boolean;
    title: string;
    message: string;
    variant: ConfirmModalVariant;
    confirmText: string;
    cancelText: string;
    onConfirm: () => void;
  }>({
    isOpen: false,
    title: '',
    message: '',
    variant: 'danger',
    confirmText: 'Confirm',
    cancelText: 'Cancel',
    onConfirm: () => {},
  });

  const confirm = useCallback(
    (options: {
      title: string;
      message: string;
      variant?: ConfirmModalVariant;
      confirmText?: string;
      cancelText?: string;
    }): Promise<boolean> => {
      return new Promise((resolve) => {
        setModalState({
          isOpen: true,
          title: options.title,
          message: options.message,
          variant: options.variant || 'danger',
          confirmText: options.confirmText || 'Confirm',
          cancelText: options.cancelText || 'Cancel',
          onConfirm: () => {
            setModalState((prev) => ({ ...prev, isOpen: false }));
            resolve(true);
          },
        });
      });
    },
    []
  );

  const close = useCallback(() => {
    setModalState((prev) => ({ ...prev, isOpen: false }));
  }, []);

  return {
    modalState,
    confirm,
    close,
  };
}
