/**
 * Test utilities for rendering components with providers.
 * 
 * Provides wrapper components and utility functions for testing.
 */
import { ReactElement, ReactNode } from 'react';
import { render, RenderOptions, RenderResult } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { BrowserRouter, MemoryRouter } from 'react-router-dom';

/**
 * Create a fresh QueryClient for tests with disabled retries.
 */
function createTestQueryClient(): QueryClient {
  return new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
        gcTime: 0,
      },
      mutations: {
        retry: false,
      },
    },
  });
}

interface WrapperProps {
  children: ReactNode;
}

/**
 * Default wrapper with all providers for component tests.
 */
function AllProviders({ children }: WrapperProps): ReactElement {
  const queryClient = createTestQueryClient();
  
  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        {children}
      </BrowserRouter>
    </QueryClientProvider>
  );
}

function createMemoryRouterWrapper(initialEntries: string[] = ['/']) {
  return function MemoryRouterWrapper({ children }: WrapperProps): ReactElement {
    const queryClient = createTestQueryClient();
    
    return (
      <QueryClientProvider client={queryClient}>
        <MemoryRouter initialEntries={initialEntries}>
          {children}
        </MemoryRouter>
      </QueryClientProvider>
    );
  };
}

/**
 * Custom render function that wraps component with all providers.
 */
function customRender(
  ui: ReactElement,
  options?: Omit<RenderOptions, 'wrapper'>
): RenderResult {
  return render(ui, { wrapper: AllProviders, ...options });
}

/**
 * Render with custom route path.
 */
function renderWithRoute(
  ui: ReactElement,
  options?: Omit<RenderOptions, 'wrapper'> & { route?: string }
): RenderResult {
  const { route = '/', ...renderOptions } = options || {};
  const Wrapper = createMemoryRouterWrapper([route]);
  return render(ui, { wrapper: Wrapper, ...renderOptions });
}

/**
 * Wait for async operations to complete.
 */
async function waitForLoadingToFinish(): Promise<void> {
  // Small delay to allow React Query to process
  await new Promise(resolve => setTimeout(resolve, 0));
}

// Re-export everything from testing-library
export * from '@testing-library/react';
export { userEvent } from '@testing-library/user-event';

// Export custom utilities
export {
  customRender as render,
  renderWithRoute,
  createTestQueryClient,
  AllProviders,
  createMemoryRouterWrapper,
  waitForLoadingToFinish,
};
