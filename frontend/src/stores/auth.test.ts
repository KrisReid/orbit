/**
 * Tests for auth store.
 */
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { useAuthStore } from './auth';
import { api } from '@/api/client';

// Mock the API client
vi.mock('@/api/client', () => ({
  api: {
    login: vi.fn(),
    logout: vi.fn(),
    getCurrentUser: vi.fn(),
    isAuthenticated: vi.fn(),
  },
}));

describe('useAuthStore', () => {
  beforeEach(() => {
    // Reset store state before each test
    useAuthStore.setState({
      user: null,
      isLoading: true,
      isAuthenticated: false,
    });
    vi.clearAllMocks();
  });

  afterEach(() => {
    vi.resetAllMocks();
  });

  describe('initial state', () => {
    it('should have correct initial state', () => {
      const state = useAuthStore.getState();
      
      expect(state.user).toBeNull();
      expect(state.isLoading).toBe(true);
      expect(state.isAuthenticated).toBe(false);
    });
  });

  describe('login', () => {
    it('should login successfully and set user', async () => {
      const mockUser = {
        id: 1,
        email: 'test@example.com',
        full_name: 'Test User',
        role: 'user' as const,
        is_active: true,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      };

      vi.mocked(api.login).mockResolvedValue({ access_token: 'token', token_type: 'bearer' });
      vi.mocked(api.getCurrentUser).mockResolvedValue(mockUser);

      await useAuthStore.getState().login('test@example.com', 'password');

      const state = useAuthStore.getState();
      expect(state.user).toEqual(mockUser);
      expect(state.isAuthenticated).toBe(true);
      expect(api.login).toHaveBeenCalledWith({
        email: 'test@example.com',
        password: 'password',
      });
    });

    it('should throw on login failure', async () => {
      vi.mocked(api.login).mockRejectedValue(new Error('Invalid credentials'));

      await expect(
        useAuthStore.getState().login('test@example.com', 'wrong')
      ).rejects.toThrow('Invalid credentials');

      const state = useAuthStore.getState();
      expect(state.user).toBeNull();
      expect(state.isAuthenticated).toBe(false);
    });
  });

  describe('logout', () => {
    it('should clear user and authentication state', () => {
      // Set up authenticated state
      useAuthStore.setState({
        user: { id: 1, email: 'test@example.com' } as any,
        isAuthenticated: true,
      });

      useAuthStore.getState().logout();

      const state = useAuthStore.getState();
      expect(state.user).toBeNull();
      expect(state.isAuthenticated).toBe(false);
      expect(api.logout).toHaveBeenCalled();
    });
  });

  describe('fetchUser', () => {
    it('should fetch user when authenticated', async () => {
      const mockUser = {
        id: 1,
        email: 'test@example.com',
        full_name: 'Test User',
        role: 'user' as const,
        is_active: true,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      };

      vi.mocked(api.isAuthenticated).mockReturnValue(true);
      vi.mocked(api.getCurrentUser).mockResolvedValue(mockUser);

      await useAuthStore.getState().fetchUser();

      const state = useAuthStore.getState();
      expect(state.user).toEqual(mockUser);
      expect(state.isAuthenticated).toBe(true);
      expect(state.isLoading).toBe(false);
    });

    it('should set loading false when not authenticated', async () => {
      vi.mocked(api.isAuthenticated).mockReturnValue(false);

      await useAuthStore.getState().fetchUser();

      const state = useAuthStore.getState();
      expect(state.user).toBeNull();
      expect(state.isAuthenticated).toBe(false);
      expect(state.isLoading).toBe(false);
    });

    it('should logout on fetch error', async () => {
      vi.mocked(api.isAuthenticated).mockReturnValue(true);
      vi.mocked(api.getCurrentUser).mockRejectedValue(new Error('Token expired'));

      await useAuthStore.getState().fetchUser();

      const state = useAuthStore.getState();
      expect(state.user).toBeNull();
      expect(state.isAuthenticated).toBe(false);
      expect(state.isLoading).toBe(false);
      expect(api.logout).toHaveBeenCalled();
    });
  });

  describe('checkAuth', () => {
    it('should return authentication status', () => {
      useAuthStore.setState({ isAuthenticated: false });
      expect(useAuthStore.getState().checkAuth()).toBe(false);

      useAuthStore.setState({ isAuthenticated: true });
      expect(useAuthStore.getState().checkAuth()).toBe(true);
    });
  });
});
