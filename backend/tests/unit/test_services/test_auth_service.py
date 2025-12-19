"""
Unit tests for AuthService and UserService.

Tests authentication and user management logic with mocked repositories.
"""
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.core.security import get_password_hash
from app.domain.entities import User, UserRole
from app.domain.exceptions import AuthenticationError, EntityNotFoundError, EntityAlreadyExistsError
from app.domain.services.auth import AuthService, UserService


class TestAuthService:
    """Tests for AuthService."""
    
    @pytest.fixture
    def mock_user_repo(self):
        """Create mock user repository."""
        repo = AsyncMock()
        return repo
    
    @pytest.fixture
    def auth_service(self, mock_session, mock_user_repo):
        """Create AuthService with mocked dependencies."""
        service = AuthService(mock_session)
        service.user_repo = mock_user_repo
        return service
    
    @pytest.fixture
    def sample_user(self):
        """Create sample user for tests."""
        user = MagicMock(spec=User)
        user.id = 1
        user.email = "test@example.com"
        user.hashed_password = get_password_hash("testpassword")
        user.full_name = "Test User"
        user.role = UserRole.USER
        user.is_active = True
        return user
    
    @pytest.mark.asyncio
    async def test_authenticate_success(self, auth_service, mock_user_repo, sample_user):
        """Successful authentication returns user and token."""
        mock_user_repo.get_by_email.return_value = sample_user
        
        user, token = await auth_service.authenticate("test@example.com", "testpassword")
        
        assert user == sample_user
        assert token is not None
        assert len(token) > 0
        mock_user_repo.get_by_email.assert_called_once_with("test@example.com")
    
    @pytest.mark.asyncio
    async def test_authenticate_user_not_found(self, auth_service, mock_user_repo):
        """Authentication fails when user not found."""
        mock_user_repo.get_by_email.return_value = None
        
        with pytest.raises(AuthenticationError) as exc_info:
            await auth_service.authenticate("unknown@example.com", "password")
        
        assert "Invalid email or password" in str(exc_info.value)
    
    @pytest.mark.asyncio
    async def test_authenticate_wrong_password(self, auth_service, mock_user_repo, sample_user):
        """Authentication fails with wrong password."""
        mock_user_repo.get_by_email.return_value = sample_user
        
        with pytest.raises(AuthenticationError) as exc_info:
            await auth_service.authenticate("test@example.com", "wrongpassword")
        
        assert "Invalid email or password" in str(exc_info.value)
    
    @pytest.mark.asyncio
    async def test_authenticate_inactive_user(self, auth_service, mock_user_repo, sample_user):
        """Authentication fails for inactive user."""
        sample_user.is_active = False
        mock_user_repo.get_by_email.return_value = sample_user
        
        with pytest.raises(AuthenticationError) as exc_info:
            await auth_service.authenticate("test@example.com", "testpassword")
        
        assert "disabled" in str(exc_info.value).lower()
    
    @pytest.mark.asyncio
    async def test_get_current_user_success(self, auth_service, mock_user_repo, sample_user):
        """Get current user returns user when found and active."""
        mock_user_repo.get_by_id.return_value = sample_user
        
        user = await auth_service.get_current_user(1)
        
        assert user == sample_user
        mock_user_repo.get_by_id.assert_called_once_with(1)
    
    @pytest.mark.asyncio
    async def test_get_current_user_not_found(self, auth_service, mock_user_repo):
        """Get current user raises error when not found."""
        mock_user_repo.get_by_id.return_value = None
        
        with pytest.raises(EntityNotFoundError):
            await auth_service.get_current_user(999)
    
    @pytest.mark.asyncio
    async def test_get_current_user_inactive(self, auth_service, mock_user_repo, sample_user):
        """Get current user raises error when user is inactive."""
        sample_user.is_active = False
        mock_user_repo.get_by_id.return_value = sample_user
        
        with pytest.raises(AuthenticationError):
            await auth_service.get_current_user(1)


class TestUserService:
    """Tests for UserService."""
    
    @pytest.fixture
    def mock_user_repo(self):
        """Create mock user repository."""
        repo = AsyncMock()
        return repo
    
    @pytest.fixture
    def user_service(self, mock_session, mock_user_repo):
        """Create UserService with mocked dependencies."""
        service = UserService(mock_session)
        service.user_repo = mock_user_repo
        return service
    
    @pytest.fixture
    def sample_user(self):
        """Create sample user for tests."""
        user = MagicMock(spec=User)
        user.id = 1
        user.email = "test@example.com"
        user.hashed_password = get_password_hash("testpassword")
        user.full_name = "Test User"
        user.role = UserRole.USER
        user.is_active = True
        return user
    
    @pytest.mark.asyncio
    async def test_create_user_success(self, user_service, mock_user_repo, sample_user):
        """Create user succeeds with valid data."""
        mock_user_repo.email_exists.return_value = False
        mock_user_repo.create.return_value = sample_user
        
        user = await user_service.create_user(
            email="test@example.com",
            password="testpassword",
            full_name="Test User",
        )
        
        assert user == sample_user
        mock_user_repo.email_exists.assert_called_once_with("test@example.com")
        mock_user_repo.create.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_create_user_duplicate_email(self, user_service, mock_user_repo):
        """Create user fails with duplicate email."""
        mock_user_repo.email_exists.return_value = True
        
        with pytest.raises(EntityAlreadyExistsError):
            await user_service.create_user(
                email="existing@example.com",
                password="testpassword",
                full_name="Test User",
            )
    
    @pytest.mark.asyncio
    async def test_create_user_with_role(self, user_service, mock_user_repo, sample_user):
        """Create user with specified role."""
        sample_user.role = UserRole.ADMIN
        mock_user_repo.email_exists.return_value = False
        mock_user_repo.create.return_value = sample_user
        
        user = await user_service.create_user(
            email="admin@example.com",
            password="adminpassword",
            full_name="Admin User",
            role=UserRole.ADMIN,
        )

        # Verify the returned user has the correct role
        assert user.role == UserRole.ADMIN
        assert user.email == "admin@example.com"
        
        # Verify create was called with admin role
        call_kwargs = mock_user_repo.create.call_args.kwargs
        assert call_kwargs["role"] == UserRole.ADMIN
    
    @pytest.mark.asyncio
    async def test_get_user_success(self, user_service, mock_user_repo, sample_user):
        """Get user returns user when found."""
        mock_user_repo.get_by_id.return_value = sample_user
        
        user = await user_service.get_user(1)
        
        assert user == sample_user
    
    @pytest.mark.asyncio
    async def test_get_user_not_found(self, user_service, mock_user_repo):
        """Get user raises error when not found."""
        mock_user_repo.get_by_id.return_value = None
        
        with pytest.raises(EntityNotFoundError):
            await user_service.get_user(999)
    
    @pytest.mark.asyncio
    async def test_list_users(self, user_service, mock_user_repo, sample_user):
        """List users returns paginated results."""
        mock_user_repo.get_all.return_value = [sample_user]
        
        users = await user_service.list_users(skip=0, limit=10)
        
        assert len(users) == 1
        assert users[0] == sample_user
        mock_user_repo.get_all.assert_called_once_with(skip=0, limit=10)
    
    @pytest.mark.asyncio
    async def test_update_user_success(self, user_service, mock_user_repo, sample_user):
        """Update user succeeds with valid data."""
        mock_user_repo.get_by_id.return_value = sample_user
        mock_user_repo.update.return_value = sample_user
        
        user = await user_service.update_user(
            user_id=1,
            full_name="Updated Name",
        )
        
        assert user == sample_user
        mock_user_repo.update.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_update_user_role(self, user_service, mock_user_repo, sample_user):
        """Update user role."""
        mock_user_repo.get_by_id.return_value = sample_user
        mock_user_repo.update.return_value = sample_user
        
        await user_service.update_user(
            user_id=1,
            role=UserRole.ADMIN,
        )
        
        call_kwargs = mock_user_repo.update.call_args.kwargs
        assert call_kwargs["role"] == UserRole.ADMIN
    
    @pytest.mark.asyncio
    async def test_update_user_not_found(self, user_service, mock_user_repo):
        """Update user fails when not found."""
        mock_user_repo.get_by_id.return_value = None
        
        with pytest.raises(EntityNotFoundError):
            await user_service.update_user(user_id=999, full_name="New Name")
    
    @pytest.mark.asyncio
    async def test_update_user_no_changes(self, user_service, mock_user_repo, sample_user):
        """Update user with no changes doesn't call update."""
        mock_user_repo.get_by_id.return_value = sample_user
        
        user = await user_service.update_user(user_id=1)
        
        assert user == sample_user
        mock_user_repo.update.assert_not_called()
    
    @pytest.mark.asyncio
    async def test_delete_user_success(self, user_service, mock_user_repo, sample_user):
        """Delete user succeeds."""
        mock_user_repo.get_by_id.return_value = sample_user
        mock_user_repo.delete.return_value = None
        
        await user_service.delete_user(1)
        
        mock_user_repo.delete.assert_called_once_with(sample_user)
    
    @pytest.mark.asyncio
    async def test_delete_user_not_found(self, user_service, mock_user_repo):
        """Delete user fails when not found."""
        mock_user_repo.get_by_id.return_value = None
        
        with pytest.raises(EntityNotFoundError):
            await user_service.delete_user(999)
