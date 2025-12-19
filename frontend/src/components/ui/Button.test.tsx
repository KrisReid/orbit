/**
 * Tests for Button component.
 */
import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { Button, IconButton } from './Button';
import { Plus } from 'lucide-react';

describe('Button', () => {
  it('renders children correctly', () => {
    render(<Button>Click me</Button>);
    
    expect(screen.getByRole('button')).toHaveTextContent('Click me');
  });

  it('applies primary variant by default', () => {
    render(<Button>Primary</Button>);
    
    const button = screen.getByRole('button');
    expect(button).toHaveClass('bg-primary-600');
  });

  it('applies secondary variant', () => {
    render(<Button variant="secondary">Secondary</Button>);
    
    const button = screen.getByRole('button');
    expect(button).toHaveClass('bg-gray-100');
  });

  it('applies danger variant', () => {
    render(<Button variant="danger">Delete</Button>);
    
    const button = screen.getByRole('button');
    expect(button).toHaveClass('bg-red-600');
  });

  it('applies ghost variant', () => {
    render(<Button variant="ghost">Ghost</Button>);
    
    const button = screen.getByRole('button');
    expect(button).toHaveClass('hover:bg-gray-100');
  });

  it('applies correct size classes', () => {
    const { rerender } = render(<Button size="sm">Small</Button>);
    expect(screen.getByRole('button')).toHaveClass('px-3');
    
    rerender(<Button size="md">Medium</Button>);
    expect(screen.getByRole('button')).toHaveClass('px-4');
    
    rerender(<Button size="lg">Large</Button>);
    expect(screen.getByRole('button')).toHaveClass('px-6');
  });

  it('shows loading spinner when isLoading', () => {
    render(<Button isLoading>Loading</Button>);
    
    const button = screen.getByRole('button');
    expect(button).toBeDisabled();
    expect(button.querySelector('.animate-spin')).toBeInTheDocument();
  });

  it('renders left icon', () => {
    render(
      <Button leftIcon={<Plus data-testid="left-icon" />}>
        Add Item
      </Button>
    );
    
    expect(screen.getByTestId('left-icon')).toBeInTheDocument();
  });

  it('renders right icon', () => {
    render(
      <Button rightIcon={<Plus data-testid="right-icon" />}>
        Add Item
      </Button>
    );
    
    expect(screen.getByTestId('right-icon')).toBeInTheDocument();
  });

  it('hides icons when loading', () => {
    render(
      <Button isLoading leftIcon={<Plus data-testid="left-icon" />}>
        Loading
      </Button>
    );
    
    expect(screen.queryByTestId('left-icon')).not.toBeInTheDocument();
  });

  it('is disabled when disabled prop is true', () => {
    render(<Button disabled>Disabled</Button>);
    
    expect(screen.getByRole('button')).toBeDisabled();
  });

  it('calls onClick handler when clicked', () => {
    const handleClick = vi.fn();
    render(<Button onClick={handleClick}>Click me</Button>);
    
    fireEvent.click(screen.getByRole('button'));
    
    expect(handleClick).toHaveBeenCalledTimes(1);
  });

  it('does not call onClick when disabled', () => {
    const handleClick = vi.fn();
    render(<Button disabled onClick={handleClick}>Click me</Button>);
    
    fireEvent.click(screen.getByRole('button'));
    
    expect(handleClick).not.toHaveBeenCalled();
  });

  it('forwards ref to button element', () => {
    const ref = vi.fn();
    render(<Button ref={ref}>With ref</Button>);
    
    expect(ref).toHaveBeenCalled();
    expect(ref.mock.calls[0][0]).toBeInstanceOf(HTMLButtonElement);
  });

  it('applies custom className', () => {
    render(<Button className="custom-class">Custom</Button>);
    
    expect(screen.getByRole('button')).toHaveClass('custom-class');
  });
});

describe('IconButton', () => {
  it('renders icon correctly', () => {
    render(
      <IconButton
        icon={<Plus data-testid="icon" />}
        label="Add item"
      />
    );
    
    expect(screen.getByTestId('icon')).toBeInTheDocument();
  });

  it('has aria-label for accessibility', () => {
    render(
      <IconButton
        icon={<Plus />}
        label="Add item"
      />
    );
    
    expect(screen.getByRole('button')).toHaveAttribute('aria-label', 'Add item');
  });

  it('applies variant classes', () => {
    const { rerender } = render(
      <IconButton icon={<Plus />} label="Default" variant="default" />
    );
    expect(screen.getByRole('button')).toHaveClass('text-gray-400');
    
    rerender(
      <IconButton icon={<Plus />} label="Danger" variant="danger" />
    );
    expect(screen.getByRole('button')).toHaveClass('text-red-400');
    
    rerender(
      <IconButton icon={<Plus />} label="Success" variant="success" />
    );
    expect(screen.getByRole('button')).toHaveClass('text-green-400');
  });

  it('applies size classes', () => {
    const { rerender } = render(
      <IconButton icon={<Plus />} label="Small" size="sm" />
    );
    expect(screen.getByRole('button')).toHaveClass('p-1');
    
    rerender(
      <IconButton icon={<Plus />} label="Medium" size="md" />
    );
    expect(screen.getByRole('button')).toHaveClass('p-2');
  });

  it('calls onClick handler', () => {
    const handleClick = vi.fn();
    render(
      <IconButton icon={<Plus />} label="Add" onClick={handleClick} />
    );
    
    fireEvent.click(screen.getByRole('button'));
    
    expect(handleClick).toHaveBeenCalledTimes(1);
  });
});
