# Frontend Test Suite

This directory contains the test infrastructure for the Orbit frontend application.

## Structure

```
src/
├── test/
│   ├── setup.ts         # Test setup and global configuration
│   ├── utils.tsx        # Test utilities and custom render functions
│   └── README.md        # This file
├── stores/
│   └── auth.test.ts     # Auth store tests
├── hooks/
│   └── useClickOutside.test.ts  # Hook tests
├── components/ui/
│   ├── Button.test.tsx  # Button component tests
│   └── Modal.test.tsx   # Modal component tests
└── pages/
    └── LoginPage.test.tsx  # Page integration tests
```

## Running Tests

### Prerequisites

Install dependencies:
```bash
cd frontend
npm install
```

### Running All Tests

```bash
npm test
```

### Running Tests Once (no watch)

```bash
npm run test:run
```

### Running with Coverage

```bash
npm run test:coverage
```

### Running Specific Tests

```bash
# Run tests matching a pattern
npm test -- Button

# Run specific file
npm test -- src/components/ui/Button.test.tsx

# Run in watch mode for specific file
npm test -- --watch Button
```

## Test Utilities

### Custom Render

Use the custom `render` function from `@/test/utils` for components that need providers:

```tsx
import { render, screen } from '@/test/utils';

test('renders component', () => {
  render(<MyComponent />);
  expect(screen.getByText('Hello')).toBeInTheDocument();
});
```

### Render with Route

For components that depend on routing:

```tsx
import { renderWithRoute, screen } from '@/test/utils';

test('renders at specific route', () => {
  renderWithRoute(<MyPage />, { route: '/projects/1' });
  expect(screen.getByText('Project')).toBeInTheDocument();
});
```

### Query Client

For components using React Query:

```tsx
import { createTestQueryClient } from '@/test/utils';

const queryClient = createTestQueryClient();
```

## Writing Tests

### Component Tests

```tsx
import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MyComponent } from './MyComponent';

describe('MyComponent', () => {
  it('renders correctly', () => {
    render(<MyComponent />);
    expect(screen.getByRole('button')).toBeInTheDocument();
  });

  it('handles click', async () => {
    const user = userEvent.setup();
    const handleClick = vi.fn();
    
    render(<MyComponent onClick={handleClick} />);
    await user.click(screen.getByRole('button'));
    
    expect(handleClick).toHaveBeenCalled();
  });
});
```

### Hook Tests

```tsx
import { describe, it, expect } from 'vitest';
import { renderHook, act } from '@testing-library/react';
import { useMyHook } from './useMyHook';

describe('useMyHook', () => {
  it('returns initial value', () => {
    const { result } = renderHook(() => useMyHook());
    expect(result.current.value).toBe(0);
  });

  it('updates value', () => {
    const { result } = renderHook(() => useMyHook());
    
    act(() => {
      result.current.increment();
    });
    
    expect(result.current.value).toBe(1);
  });
});
```

### Store Tests

```tsx
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { useMyStore } from './myStore';

describe('useMyStore', () => {
  beforeEach(() => {
    // Reset store state
    useMyStore.setState({ value: null });
    vi.clearAllMocks();
  });

  it('has correct initial state', () => {
    const state = useMyStore.getState();
    expect(state.value).toBeNull();
  });

  it('updates state', async () => {
    await useMyStore.getState().setValue('test');
    expect(useMyStore.getState().value).toBe('test');
  });
});
```

## Mocking

### Mocking API Calls

```tsx
vi.mock('@/api/client', () => ({
  api: {
    myMethod: vi.fn(),
  },
}));

// In test
vi.mocked(api.myMethod).mockResolvedValue({ data: 'test' });
```

### Mocking Router

```tsx
const mockNavigate = vi.fn();
vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual('react-router-dom');
  return {
    ...actual,
    useNavigate: () => mockNavigate,
  };
});
```

### Mocking Zustand Stores

```tsx
// Direct state manipulation
useMyStore.setState({ value: 'mocked' });

// Mock specific methods
const originalMethod = useMyStore.getState().myMethod;
useMyStore.setState({ myMethod: vi.fn() });
// ... test ...
useMyStore.setState({ myMethod: originalMethod });
```

## Best Practices

1. **Use Testing Library queries**: Prefer `getByRole`, `getByLabelText` over `getByTestId`
2. **Test behavior, not implementation**: Focus on what users see and do
3. **Use `userEvent` over `fireEvent`**: More realistic user interactions
4. **Mock at the boundary**: Mock API calls, not internal functions
5. **Reset state between tests**: Use `beforeEach` to clean up

## CI/CD Integration

Tests are configured to work with CI/CD pipelines:

```bash
# Run tests with coverage for CI
npm run test:coverage

# Coverage reports are generated in:
# - Terminal output
# - coverage/ directory (HTML, JSON)
```

## Troubleshooting

### Tests Failing with Import Errors

Ensure all dependencies are installed:
```bash
npm install
```

### Tests Timing Out

Increase timeout in vitest.config.ts:
```ts
test: {
  testTimeout: 10000,
}
```

### Mock Not Working

Ensure mocks are set up before imports:
```tsx
vi.mock('./module');  // Must be at top level
import { thing } from './module';
```
