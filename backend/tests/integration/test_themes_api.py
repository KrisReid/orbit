"""
Integration tests for themes API endpoints.

Tests the full request/response cycle for theme endpoints.
"""
import pytest
from httpx import AsyncClient

from app.domain.entities import Theme, User


class TestThemesEndpoints:
    """Tests for themes API endpoints."""
    
    @pytest.mark.asyncio
    async def test_list_themes(
        self, client: AsyncClient, test_user: User, test_theme: Theme, auth_headers: dict
    ):
        """List themes returns paginated results."""
        response = await client.get("/api/v1/themes", headers=auth_headers)
        
        assert response.status_code == 200
        data = response.json()
        assert "items" in data
        assert "total" in data
        assert len(data["items"]) >= 1
    
    @pytest.mark.asyncio
    async def test_create_theme(
        self, client: AsyncClient, test_user: User, auth_headers: dict
    ):
        """User can create theme."""
        response = await client.post(
            "/api/v1/themes",
            headers=auth_headers,
            json={
                "title": "New Theme",
                "description": "A new strategic theme",
                "status": "active",
            },
        )
        
        assert response.status_code == 201
        data = response.json()
        assert data["title"] == "New Theme"
        assert data["description"] == "A new strategic theme"
        assert data["status"] == "active"
    
    @pytest.mark.asyncio
    async def test_create_theme_minimal(
        self, client: AsyncClient, test_user: User, auth_headers: dict
    ):
        """Create theme with minimal required fields."""
        response = await client.post(
            "/api/v1/themes",
            headers=auth_headers,
            json={
                "title": "Minimal Theme",
            },
        )
        
        assert response.status_code == 201
        data = response.json()
        assert data["title"] == "Minimal Theme"
        assert data["status"] == "active"  # Default status
    
    @pytest.mark.asyncio
    async def test_get_theme(
        self, client: AsyncClient, test_user: User, test_theme: Theme, auth_headers: dict
    ):
        """Get theme by ID with projects."""
        response = await client.get(
            f"/api/v1/themes/{test_theme.id}",
            headers=auth_headers,
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == test_theme.id
        assert data["title"] == test_theme.title
        # Response includes projects
        assert "projects" in data
    
    @pytest.mark.asyncio
    async def test_get_theme_not_found(
        self, client: AsyncClient, test_user: User, auth_headers: dict
    ):
        """Get non-existent theme returns 404."""
        response = await client.get(
            "/api/v1/themes/99999",
            headers=auth_headers,
        )
        
        assert response.status_code == 404
    
    @pytest.mark.asyncio
    async def test_update_theme(
        self, client: AsyncClient, test_user: User, test_theme: Theme, auth_headers: dict
    ):
        """User can update theme."""
        response = await client.patch(
            f"/api/v1/themes/{test_theme.id}",
            headers=auth_headers,
            json={
                "title": "Updated Theme",
                "description": "Updated description",
            },
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["title"] == "Updated Theme"
        assert data["description"] == "Updated description"
    
    @pytest.mark.asyncio
    async def test_update_theme_status(
        self, client: AsyncClient, test_user: User, test_theme: Theme, auth_headers: dict
    ):
        """User can update theme status."""
        response = await client.patch(
            f"/api/v1/themes/{test_theme.id}",
            headers=auth_headers,
            json={
                "status": "completed",
            },
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "completed"
    
    @pytest.mark.asyncio
    async def test_delete_theme_admin_only(
        self, client: AsyncClient, test_user: User, test_theme: Theme, auth_headers: dict
    ):
        """Regular user cannot delete theme."""
        response = await client.delete(
            f"/api/v1/themes/{test_theme.id}",
            headers=auth_headers,
        )
        
        assert response.status_code == 403
    
    @pytest.mark.asyncio
    async def test_delete_theme_as_admin(
        self, client: AsyncClient, admin_user: User, admin_headers: dict, db_session
    ):
        """Admin can delete theme."""
        # Create theme to delete
        theme = Theme(
            title="To Delete",
            description="A theme to delete",
            status="active",
        )
        db_session.add(theme)
        await db_session.flush()
        
        response = await client.delete(
            f"/api/v1/themes/{theme.id}",
            headers=admin_headers,
        )
        
        assert response.status_code == 200


class TestThemeWithProjects:
    """Tests for themes with related projects."""
    
    @pytest.mark.asyncio
    async def test_get_theme_includes_projects(
        self, client: AsyncClient, test_user: User, test_project, auth_headers: dict
    ):
        """Theme detail includes related projects."""
        # test_project has a theme_id linked to test_theme
        response = await client.get(
            f"/api/v1/themes/{test_project.theme_id}",
            headers=auth_headers,
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "projects" in data
        # Should include our test project
        project_ids = [p["id"] for p in data["projects"]]
        assert test_project.id in project_ids
    
    @pytest.mark.asyncio
    async def test_theme_project_count(
        self, client: AsyncClient, test_user: User, test_theme: Theme, test_project, auth_headers: dict
    ):
        """Theme should show correct project count."""
        response = await client.get(
            f"/api/v1/themes/{test_theme.id}",
            headers=auth_headers,
        )
        
        assert response.status_code == 200
        data = response.json()
        assert len(data["projects"]) >= 1
