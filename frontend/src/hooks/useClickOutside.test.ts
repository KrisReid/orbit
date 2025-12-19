/**
 * Tests for useClickOutside hook.
 */
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { renderHook } from '@testing-library/react';
import { useRef } from 'react';
import { useClickOutside } from './useClickOutside';

describe('useClickOutside', () => {
  let container: HTMLDivElement;
  let outsideElement: HTMLDivElement;
  
  beforeEach(() => {
    container = document.createElement('div');
    outsideElement = document.createElement('div');
    document.body.appendChild(container);
    document.body.appendChild(outsideElement);
  });
  
  afterEach(() => {
    document.body.removeChild(container);
    document.body.removeChild(outsideElement);
  });
  
  it('should call handler when clicking outside', () => {
    const handler = vi.fn();
    
    const { result } = renderHook(() => {
      const ref = useRef<HTMLDivElement>(null);
      // @ts-expect-error - Assigning for test purposes
      ref.current = container;
      useClickOutside(ref, handler);
      return ref;
    });
    
    // Simulate click outside
    const event = new MouseEvent('mousedown', { bubbles: true });
    outsideElement.dispatchEvent(event);
    
    expect(handler).toHaveBeenCalledTimes(1);
  });
  
  it('should not call handler when clicking inside', () => {
    const handler = vi.fn();
    
    renderHook(() => {
      const ref = useRef<HTMLDivElement>(null);
      // @ts-expect-error - Assigning for test purposes
      ref.current = container;
      useClickOutside(ref, handler);
      return ref;
    });
    
    // Simulate click inside
    const event = new MouseEvent('mousedown', { bubbles: true });
    container.dispatchEvent(event);
    
    expect(handler).not.toHaveBeenCalled();
  });
  
  it('should not call handler when disabled', () => {
    const handler = vi.fn();
    
    renderHook(() => {
      const ref = useRef<HTMLDivElement>(null);
      // @ts-expect-error - Assigning for test purposes
      ref.current = container;
      useClickOutside(ref, handler, false);
      return ref;
    });
    
    // Simulate click outside
    const event = new MouseEvent('mousedown', { bubbles: true });
    outsideElement.dispatchEvent(event);
    
    expect(handler).not.toHaveBeenCalled();
  });
  
  it('should handle array of refs', () => {
    const handler = vi.fn();
    const secondContainer = document.createElement('div');
    document.body.appendChild(secondContainer);
    
    renderHook(() => {
      const ref1 = useRef<HTMLDivElement>(null);
      const ref2 = useRef<HTMLDivElement>(null);
      // @ts-expect-error - Assigning for test purposes
      ref1.current = container;
      // @ts-expect-error - Assigning for test purposes
      ref2.current = secondContainer;
      useClickOutside([ref1, ref2], handler);
      return [ref1, ref2];
    });
    
    // Click inside first ref - should not trigger
    let event = new MouseEvent('mousedown', { bubbles: true });
    container.dispatchEvent(event);
    expect(handler).not.toHaveBeenCalled();
    
    // Click inside second ref - should not trigger
    event = new MouseEvent('mousedown', { bubbles: true });
    secondContainer.dispatchEvent(event);
    expect(handler).not.toHaveBeenCalled();
    
    // Click outside both - should trigger
    event = new MouseEvent('mousedown', { bubbles: true });
    outsideElement.dispatchEvent(event);
    expect(handler).toHaveBeenCalledTimes(1);
    
    document.body.removeChild(secondContainer);
  });
  
  it('should clean up event listener on unmount', () => {
    const handler = vi.fn();
    const removeEventListenerSpy = vi.spyOn(document, 'removeEventListener');
    
    const { unmount } = renderHook(() => {
      const ref = useRef<HTMLDivElement>(null);
      // @ts-expect-error - Assigning for test purposes
      ref.current = container;
      useClickOutside(ref, handler);
      return ref;
    });
    
    unmount();
    
    expect(removeEventListenerSpy).toHaveBeenCalledWith(
      'mousedown',
      expect.any(Function)
    );
    
    removeEventListenerSpy.mockRestore();
  });
});
