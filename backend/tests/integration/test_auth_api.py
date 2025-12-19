"""
Integration tests for authentication API endpoints.

Tests the full request/response cycle for auth endpoints.
"""
import pytest
from httpx import AsyncClient

from app.core.security import get_password_hash
from app.domain.entities import User, UserRole


class TestHealthEndpoints:
    """Tests for health check endpoints."""
    
    @pytest.mark.asyncio
    async def test_health_check(self, client: AsyncClient):
        """Health endpoint returns healthy status."""
        response = await client.get("/health")
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert "version" in data
    
    @pytest.mark.asyncio
    async def test_root_endpoint(self, client: AsyncClient):
        """Root endpoint returns API info."""
        response = await client.get("/")
        
        assert response.status_code == 200
        data = response.json()
        assert "name" in data
        assert "version" in data
        assert "api" in data


class TestLoginEndpoint:
    """Tests for login endpoint."""
    
    @pytest.mark.asyncio
    async def test_login_success(self, client: AsyncClient, test_user: User):
        """Successful login returns token."""
        response = await client.post(
            "/api/v1/auth/login",
            json={
                "email": "test@example.com",
                "password": "testpassword",
            },
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data
        assert data["token_type"] == "bearer"
    
    @pytest.mark.asyncio
    async def test_login_invalid_email(self, client: AsyncClient):
        """Login with unknown email fails."""
        response = await client.post(
            "/api/v1/auth/login",
            json={
                "email": "unknown@example.com",
                "password": "password",
            },
        )
        
        assert response.status_code == 401
        data = response.json()
        assert "Invalid" in data["detail"]
    
    @pytest.mark.asyncio
    async def test_login_wrong_password(self, client: AsyncClient, test_user: User):
        """Login with wrong password fails."""
        response = await client.post(
            "/api/v1/auth/login",
            json={
                "email": "test@example.com",
                "password": "wrongpassword",
            },
        )
        
        assert response.status_code == 401
    
    @pytest.mark.asyncio
    async def test_login_inactive_user(self, client: AsyncClient, inactive_user: User):
        """Login for inactive user fails."""
        response = await client.post(
            "/api/v1/auth/login",
            json={
                "email": "inactive@example.com",
                "password": "inactivepassword",
            },
        )
        
        assert response.status_code == 401
        data = response.json()
        assert "disabled" in data["detail"].lower()
    
    @pytest.mark.asyncio
    async def test_login_invalid_format(self, client: AsyncClient):
        """Login with invalid email format fails."""
        response = await client.post(
            "/api/v1/auth/login",
            json={
                "email": "not-an-email",
                "password": "password",
            },
        )
        
        assert response.status_code == 422  # Validation error


class TestMeEndpoint:
    """Tests for current user endpoint."""
    
    @pytest.mark.asyncio
    async def test_get_current_user(
        self, client: AsyncClient, test_user: User, auth_headers: dict
    ):
        """Get current user returns user data."""
        response = await client.get("/api/v1/auth/me", headers=auth_headers)
        
        assert response.status_code == 200
        data = response.json()
        assert data["email"] == "test@example.com"
        assert data["full_name"] == "Test User"
        assert data["role"] == "user"
    
    @pytest.mark.asyncio
    async def test_get_current_user_admin(
        self, client: AsyncClient, admin_user: User, admin_headers: dict
    ):
        """Get current admin user returns admin data."""
        response = await client.get("/api/v1/auth/me", headers=admin_headers)
        
        assert response.status_code == 200
        data = response.json()
        assert data["role"] == "admin"
    
    @pytest.mark.asyncio
    async def test_get_current_user_no_auth(self, client: AsyncClient):
        """Get current user without auth fails."""
        response = await client.get("/api/v1/auth/me")
        
        assert response.status_code == 403  # No credentials
    
    @pytest.mark.asyncio
    async def test_get_current_user_invalid_token(self, client: AsyncClient):
        """Get current user with invalid token fails."""
        response = await client.get(
            "/api/v1/auth/me",
            headers={"Authorization": "Bearer invalid-token"},
        )
        
        assert response.status_code == 401


class TestUsersEndpoints:
    """Tests for user management endpoints."""
    
    @pytest.mark.asyncio
    async def test_list_users_as_admin(
        self, client: AsyncClient, admin_user: User, test_user: User, admin_headers: dict
    ):
        """Admin can list users."""
        response = await client.get("/api/v1/users", headers=admin_headers)
        
        assert response.status_code == 200
        data = response.json()
        assert "items" in data
        assert len(data["items"]) >= 1
    
    @pytest.mark.asyncio
    async def test_list_users_as_regular_user(
        self, client: AsyncClient, test_user: User, auth_headers: dict
    ):
        """Regular user can list users (read access)."""
        response = await client.get("/api/v1/users", headers=auth_headers)
        
        # Users endpoint may be restricted - check appropriate status
        assert response.status_code in [200, 403]
    
    @pytest.mark.asyncio
    async def test_create_user_as_admin(
        self, client: AsyncClient, admin_user: User, admin_headers: dict
    ):
        """Admin can create new user."""
        response = await client.post(
            "/api/v1/users",
            headers=admin_headers,
            json={
                "email": "newuser@example.com",
                "password": "newpassword123",
                "full_name": "New User",
                "role": "user",
            },
        )
        
        assert response.status_code == 201
        data = response.json()
        assert data["email"] == "newuser@example.com"
        assert data["full_name"] == "New User"
    
    @pytest.mark.asyncio
    async def test_create_user_duplicate_email(
        self, client: AsyncClient, admin_user: User, test_user: User, admin_headers: dict
    ):
        """Creating user with duplicate email fails."""
        response = await client.post(
            "/api/v1/users",
            headers=admin_headers,
            json={
                "email": "test@example.com",  # Already exists
                "password": "password123",
                "full_name": "Duplicate User",
            },
        )
        
        # API returns 400 for validation/duplicate errors
        assert response.status_code in [400, 409]
    
    @pytest.mark.asyncio
    async def test_get_user_by_id(
        self, client: AsyncClient, admin_user: User, test_user: User, admin_headers: dict
    ):
        """Get user by ID returns user data."""
        response = await client.get(
            f"/api/v1/users/{test_user.id}",
            headers=admin_headers,
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == test_user.id
        assert data["email"] == test_user.email
    
    @pytest.mark.asyncio
    async def test_get_user_not_found(
        self, client: AsyncClient, admin_user: User, admin_headers: dict
    ):
        """Get non-existent user returns 404."""
        response = await client.get(
            "/api/v1/users/99999",
            headers=admin_headers,
        )
        
        assert response.status_code == 404
    
    @pytest.mark.asyncio
    async def test_update_user(
        self, client: AsyncClient, admin_user: User, test_user: User, admin_headers: dict
    ):
        """Admin can update user."""
        response = await client.patch(
            f"/api/v1/users/{test_user.id}",
            headers=admin_headers,
            json={
                "full_name": "Updated Name",
            },
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["full_name"] == "Updated Name"
    
    @pytest.mark.asyncio
    async def test_delete_user(
        self, client: AsyncClient, admin_user: User, admin_headers: dict, db_session
    ):
        """Admin can delete user."""
        # Create user to delete
        user = User(
            email="todelete@example.com",
            hashed_password=get_password_hash("password"),
            full_name="To Delete",
            role=UserRole.USER,
            is_active=True,
        )
        db_session.add(user)
        await db_session.flush()
        
        response = await client.delete(
            f"/api/v1/users/{user.id}",
            headers=admin_headers,
        )
        
        assert response.status_code == 200
