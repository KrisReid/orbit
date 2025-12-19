/**
 * Tests for Modal component.
 */
import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { Modal, ModalBody, ModalFooter } from './Modal';

describe('Modal', () => {
  it('renders nothing when closed', () => {
    render(
      <Modal isOpen={false} onClose={() => {}}>
        <div>Modal content</div>
      </Modal>
    );
    
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });

  it('renders when open', () => {
    render(
      <Modal isOpen={true} onClose={() => {}}>
        <div>Modal content</div>
      </Modal>
    );
    
    expect(screen.getByRole('dialog')).toBeInTheDocument();
    expect(screen.getByText('Modal content')).toBeInTheDocument();
  });

  it('renders title when provided', () => {
    render(
      <Modal isOpen={true} onClose={() => {}} title="Test Title">
        <div>Content</div>
      </Modal>
    );
    
    expect(screen.getByText('Test Title')).toBeInTheDocument();
  });

  it('shows close button by default', () => {
    render(
      <Modal isOpen={true} onClose={() => {}}>
        <div>Content</div>
      </Modal>
    );
    
    expect(screen.getByLabelText('Close modal')).toBeInTheDocument();
  });

  it('hides close button when showCloseButton is false', () => {
    render(
      <Modal isOpen={true} onClose={() => {}} showCloseButton={false}>
        <div>Content</div>
      </Modal>
    );
    
    expect(screen.queryByLabelText('Close modal')).not.toBeInTheDocument();
  });

  it('calls onClose when close button clicked', () => {
    const handleClose = vi.fn();
    render(
      <Modal isOpen={true} onClose={handleClose}>
        <div>Content</div>
      </Modal>
    );
    
    fireEvent.click(screen.getByLabelText('Close modal'));
    
    expect(handleClose).toHaveBeenCalledTimes(1);
  });

  it('calls onClose when backdrop clicked', () => {
    const handleClose = vi.fn();
    render(
      <Modal isOpen={true} onClose={handleClose}>
        <div>Content</div>
      </Modal>
    );
    
    // Click the backdrop (aria-hidden div)
    const backdrop = document.querySelector('[aria-hidden="true"]');
    fireEvent.click(backdrop!);
    
    expect(handleClose).toHaveBeenCalledTimes(1);
  });

  it('does not close on backdrop click when closeOnBackdrop is false', () => {
    const handleClose = vi.fn();
    render(
      <Modal isOpen={true} onClose={handleClose} closeOnBackdrop={false}>
        <div>Content</div>
      </Modal>
    );
    
    const backdrop = document.querySelector('[aria-hidden="true"]');
    fireEvent.click(backdrop!);
    
    expect(handleClose).not.toHaveBeenCalled();
  });

  it('calls onClose on Escape key', () => {
    const handleClose = vi.fn();
    render(
      <Modal isOpen={true} onClose={handleClose}>
        <div>Content</div>
      </Modal>
    );
    
    fireEvent.keyDown(document, { key: 'Escape' });
    
    expect(handleClose).toHaveBeenCalledTimes(1);
  });

  it('does not close on Escape when closeOnEscape is false', () => {
    const handleClose = vi.fn();
    render(
      <Modal isOpen={true} onClose={handleClose} closeOnEscape={false}>
        <div>Content</div>
      </Modal>
    );
    
    fireEvent.keyDown(document, { key: 'Escape' });
    
    expect(handleClose).not.toHaveBeenCalled();
  });

  it('applies correct size class', () => {
    const { rerender } = render(
      <Modal isOpen={true} onClose={() => {}} size="sm">
        <div>Content</div>
      </Modal>
    );
    expect(screen.getByRole('dialog')).toHaveClass('max-w-sm');
    
    rerender(
      <Modal isOpen={true} onClose={() => {}} size="lg">
        <div>Content</div>
      </Modal>
    );
    expect(screen.getByRole('dialog')).toHaveClass('max-w-lg');
    
    rerender(
      <Modal isOpen={true} onClose={() => {}} size="full">
        <div>Content</div>
      </Modal>
    );
    expect(screen.getByRole('dialog')).toHaveClass('max-w-4xl');
  });

  it('applies custom className', () => {
    render(
      <Modal isOpen={true} onClose={() => {}} className="custom-modal">
        <div>Content</div>
      </Modal>
    );
    
    expect(screen.getByRole('dialog')).toHaveClass('custom-modal');
  });

  it('has correct aria attributes', () => {
    render(
      <Modal isOpen={true} onClose={() => {}} title="Accessible Modal">
        <div>Content</div>
      </Modal>
    );
    
    const dialog = screen.getByRole('dialog');
    expect(dialog).toHaveAttribute('aria-modal', 'true');
    expect(dialog).toHaveAttribute('aria-labelledby', 'modal-title');
  });

  it('prevents body scroll when open', () => {
    const { unmount } = render(
      <Modal isOpen={true} onClose={() => {}}>
        <div>Content</div>
      </Modal>
    );
    
    expect(document.body.style.overflow).toBe('hidden');
    
    unmount();
    
    expect(document.body.style.overflow).toBe('');
  });
});

describe('ModalBody', () => {
  it('renders children with padding', () => {
    render(
      <ModalBody>
        <div data-testid="content">Body content</div>
      </ModalBody>
    );
    
    const body = screen.getByTestId('content').parentElement;
    expect(body).toHaveClass('p-6');
  });

  it('applies custom className', () => {
    render(
      <ModalBody className="custom-body">
        <div data-testid="content">Content</div>
      </ModalBody>
    );
    
    const body = screen.getByTestId('content').parentElement;
    expect(body).toHaveClass('custom-body');
  });
});

describe('ModalFooter', () => {
  it('renders children with proper styling', () => {
    render(
      <ModalFooter>
        <button data-testid="btn">Action</button>
      </ModalFooter>
    );
    
    const footer = screen.getByTestId('btn').parentElement;
    expect(footer).toHaveClass('flex');
    expect(footer).toHaveClass('justify-end');
    expect(footer).toHaveClass('gap-3');
  });

  it('applies custom className', () => {
    render(
      <ModalFooter className="custom-footer">
        <button data-testid="btn">Action</button>
      </ModalFooter>
    );
    
    const footer = screen.getByTestId('btn').parentElement;
    expect(footer).toHaveClass('custom-footer');
  });
});
