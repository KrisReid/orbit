"""
Integration tests for projects API endpoints.

Tests the full request/response cycle for project endpoints.
"""

import pytest
from httpx import AsyncClient

from app.domain.entities import Project, ProjectType, Theme, User


class TestProjectTypesEndpoints:
    """Tests for project types API endpoints."""

    @pytest.mark.asyncio
    async def test_list_project_types(
        self,
        client: AsyncClient,
        test_user: User,
        test_project_type: ProjectType,
        auth_headers: dict,
    ):
        """List project types returns paginated results."""
        response = await client.get("/api/v1/project-types", headers=auth_headers)

        assert response.status_code == 200
        data = response.json()
        assert "items" in data
        assert "total" in data
        assert len(data["items"]) >= 1

    @pytest.mark.asyncio
    async def test_create_project_type(
        self, client: AsyncClient, admin_user: User, admin_headers: dict
    ):
        """Admin can create project type."""
        response = await client.post(
            "/api/v1/project-types",
            headers=admin_headers,
            json={
                "name": "New Type",
                "workflow": ["New", "In Progress", "Complete"],
                "description": "A new project type",
                "color": "#FF5733",
            },
        )

        assert response.status_code == 201
        data = response.json()
        assert data["name"] == "New Type"
        assert data["slug"] == "new-type"
        assert data["workflow"] == ["New", "In Progress", "Complete"]

    @pytest.mark.asyncio
    async def test_create_project_type_custom_slug(
        self, client: AsyncClient, admin_user: User, admin_headers: dict
    ):
        """Create project type with custom slug."""
        response = await client.post(
            "/api/v1/project-types",
            headers=admin_headers,
            json={
                "name": "Custom Slug Type",
                "slug": "my-custom-slug",
                "workflow": ["Open", "Closed"],
            },
        )

        assert response.status_code == 201
        data = response.json()
        assert data["slug"] == "my-custom-slug"

    @pytest.mark.asyncio
    async def test_get_project_type(
        self,
        client: AsyncClient,
        test_user: User,
        test_project_type: ProjectType,
        auth_headers: dict,
    ):
        """Get project type by ID."""
        response = await client.get(
            f"/api/v1/project-types/{test_project_type.id}",
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert data["id"] == test_project_type.id
        assert data["name"] == test_project_type.name

    @pytest.mark.asyncio
    async def test_get_project_type_not_found(
        self, client: AsyncClient, test_user: User, auth_headers: dict
    ):
        """Get non-existent project type returns 404."""
        response = await client.get(
            "/api/v1/project-types/99999",
            headers=auth_headers,
        )

        assert response.status_code == 404

    @pytest.mark.asyncio
    @pytest.mark.xfail(
        reason="App bug: MissingGreenlet due to lazy-loaded relationships in response"
    )
    async def test_update_project_type(
        self,
        client: AsyncClient,
        admin_user: User,
        test_project_type: ProjectType,
        admin_headers: dict,
    ):
        """Admin can update project type."""
        response = await client.patch(
            f"/api/v1/project-types/{test_project_type.id}",
            headers=admin_headers,
            json={
                "name": "Updated Name",
                "description": "Updated description",
            },
        )

        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "Updated Name"
        assert data["description"] == "Updated description"

    @pytest.mark.asyncio
    @pytest.mark.xfail(
        reason="App bug: MissingGreenlet due to lazy-loaded relationships in response"
    )
    async def test_update_project_type_workflow(
        self,
        client: AsyncClient,
        admin_user: User,
        test_project_type: ProjectType,
        admin_headers: dict,
    ):
        """Admin can update project type workflow."""
        response = await client.patch(
            f"/api/v1/project-types/{test_project_type.id}",
            headers=admin_headers,
            json={
                "workflow": ["Todo", "Doing", "Done", "Archived"],
            },
        )

        assert response.status_code == 200
        data = response.json()
        assert data["workflow"] == ["Todo", "Doing", "Done", "Archived"]

    @pytest.mark.asyncio
    async def test_delete_project_type(
        self, client: AsyncClient, admin_user: User, admin_headers: dict, db_session
    ):
        """Admin can delete project type."""
        # Create project type to delete
        pt = ProjectType(
            name="To Delete",
            slug="to-delete",
            workflow=["Open", "Closed"],
        )
        db_session.add(pt)
        await db_session.flush()

        response = await client.delete(
            f"/api/v1/project-types/{pt.id}",
            headers=admin_headers,
        )

        assert response.status_code == 200


class TestProjectsEndpoints:
    """Tests for projects API endpoints."""

    @pytest.mark.asyncio
    async def test_list_projects(
        self,
        client: AsyncClient,
        test_user: User,
        test_project: Project,
        auth_headers: dict,
    ):
        """List projects returns paginated results."""
        response = await client.get("/api/v1/projects", headers=auth_headers)

        assert response.status_code == 200
        data = response.json()
        assert "items" in data
        assert "total" in data
        assert len(data["items"]) >= 1

    @pytest.mark.asyncio
    async def test_list_projects_with_filters(
        self,
        client: AsyncClient,
        test_user: User,
        test_project: Project,
        test_project_type: ProjectType,
        auth_headers: dict,
    ):
        """List projects with filters."""
        response = await client.get(
            "/api/v1/projects",
            headers=auth_headers,
            params={
                "project_type_ids": [test_project_type.id],
                "statuses": ["Backlog"],
            },
        )

        assert response.status_code == 200
        data = response.json()
        assert all(p["status"] == "Backlog" for p in data["items"])

    @pytest.mark.asyncio
    async def test_create_project(
        self,
        client: AsyncClient,
        test_user: User,
        test_project_type: ProjectType,
        auth_headers: dict,
    ):
        """User can create project."""
        response = await client.post(
            "/api/v1/projects",
            headers=auth_headers,
            json={
                "title": "New Project",
                "description": "A new project",
                "project_type_id": test_project_type.id,
            },
        )

        assert response.status_code == 201
        data = response.json()
        assert data["title"] == "New Project"
        assert data["status"] == "Backlog"  # First workflow status
        assert data["project_type_id"] == test_project_type.id

    @pytest.mark.asyncio
    async def test_create_project_with_theme(
        self,
        client: AsyncClient,
        test_user: User,
        test_project_type: ProjectType,
        test_theme: Theme,
        auth_headers: dict,
    ):
        """Create project with theme."""
        response = await client.post(
            "/api/v1/projects",
            headers=auth_headers,
            json={
                "title": "Themed Project",
                "project_type_id": test_project_type.id,
                "theme_id": test_theme.id,
            },
        )

        assert response.status_code == 201
        data = response.json()
        assert data["theme_id"] == test_theme.id

    @pytest.mark.asyncio
    async def test_create_project_invalid_type(
        self, client: AsyncClient, test_user: User, auth_headers: dict
    ):
        """Create project with invalid type fails."""
        response = await client.post(
            "/api/v1/projects",
            headers=auth_headers,
            json={
                "title": "Invalid Project",
                "project_type_id": 99999,
            },
        )

        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_get_project(
        self,
        client: AsyncClient,
        test_user: User,
        test_project: Project,
        auth_headers: dict,
    ):
        """Get project by ID with relations."""
        response = await client.get(
            f"/api/v1/projects/{test_project.id}",
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert data["id"] == test_project.id
        assert data["title"] == test_project.title
        # Detail response includes relations
        assert "dependencies" in data
        assert "dependents" in data
        assert "tasks" in data

    @pytest.mark.asyncio
    async def test_get_project_not_found(
        self, client: AsyncClient, test_user: User, auth_headers: dict
    ):
        """Get non-existent project returns 404."""
        response = await client.get(
            "/api/v1/projects/99999",
            headers=auth_headers,
        )

        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_update_project_title(
        self,
        client: AsyncClient,
        test_user: User,
        test_project: Project,
        auth_headers: dict,
    ):
        """User can update project title."""
        response = await client.patch(
            f"/api/v1/projects/{test_project.id}",
            headers=auth_headers,
            json={
                "title": "Updated Title",
            },
        )

        assert response.status_code == 200
        data = response.json()
        assert data["title"] == "Updated Title"

    @pytest.mark.asyncio
    async def test_update_project_status(
        self,
        client: AsyncClient,
        test_user: User,
        test_project: Project,
        auth_headers: dict,
    ):
        """User can update project status."""
        response = await client.patch(
            f"/api/v1/projects/{test_project.id}",
            headers=auth_headers,
            json={
                "status": "In Progress",
            },
        )

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "In Progress"

    @pytest.mark.asyncio
    async def test_update_project_clear_theme(
        self,
        client: AsyncClient,
        test_user: User,
        test_project: Project,
        auth_headers: dict,
    ):
        """User can clear project theme."""
        # Verify project has theme
        assert test_project.theme_id is not None

        response = await client.patch(
            f"/api/v1/projects/{test_project.id}",
            headers=auth_headers,
            json={
                "theme_id": None,
            },
        )

        assert response.status_code == 200
        data = response.json()
        assert data["theme_id"] is None

    @pytest.mark.asyncio
    async def test_get_project_task_count(
        self,
        client: AsyncClient,
        test_user: User,
        test_project: Project,
        auth_headers: dict,
    ):
        """Get project task count."""
        response = await client.get(
            f"/api/v1/projects/{test_project.id}/task-count",
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert "count" in data
        assert isinstance(data["count"], int)

    @pytest.mark.asyncio
    async def test_delete_project_admin_only(
        self,
        client: AsyncClient,
        test_user: User,
        test_project: Project,
        auth_headers: dict,
    ):
        """Regular user cannot delete project."""
        response = await client.delete(
            f"/api/v1/projects/{test_project.id}",
            headers=auth_headers,
        )

        assert response.status_code == 403

    @pytest.mark.asyncio
    async def test_delete_project_as_admin(
        self,
        client: AsyncClient,
        admin_user: User,
        admin_headers: dict,
        test_project_type: ProjectType,
        db_session,
    ):
        """Admin can delete project."""
        # Create project to delete
        project = Project(
            title="To Delete",
            description="A project to delete",
            status="Backlog",
            project_type_id=test_project_type.id,
        )
        db_session.add(project)
        await db_session.flush()

        response = await client.delete(
            f"/api/v1/projects/{project.id}",
            headers=admin_headers,
        )

        assert response.status_code == 200


class TestProjectDependencies:
    """Tests for project dependency endpoints."""

    @pytest.mark.asyncio
    async def test_add_dependency(
        self,
        client: AsyncClient,
        test_user: User,
        test_project_type: ProjectType,
        auth_headers: dict,
        db_session,
    ):
        """Add dependency to project."""
        # Create two projects
        project1 = Project(
            title="Project 1",
            status="Backlog",
            project_type_id=test_project_type.id,
        )
        project2 = Project(
            title="Project 2",
            status="Backlog",
            project_type_id=test_project_type.id,
        )
        db_session.add(project1)
        db_session.add(project2)
        await db_session.flush()

        response = await client.post(
            f"/api/v1/projects/{project1.id}/dependencies/{project2.id}",
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert any(d["id"] == project2.id for d in data["dependencies"])

    @pytest.mark.asyncio
    async def test_add_self_dependency_fails(
        self,
        client: AsyncClient,
        test_user: User,
        test_project: Project,
        auth_headers: dict,
    ):
        """Adding self as dependency fails."""
        response = await client.post(
            f"/api/v1/projects/{test_project.id}/dependencies/{test_project.id}",
            headers=auth_headers,
        )

        assert response.status_code == 400

    @pytest.mark.asyncio
    async def test_remove_dependency(
        self,
        client: AsyncClient,
        test_user: User,
        test_project_type: ProjectType,
        auth_headers: dict,
        db_session,
    ):
        """Remove dependency from project."""
        # Create two projects with dependency
        project1 = Project(
            title="Project A",
            status="Backlog",
            project_type_id=test_project_type.id,
        )
        project2 = Project(
            title="Project B",
            status="Backlog",
            project_type_id=test_project_type.id,
        )
        db_session.add(project1)
        db_session.add(project2)
        await db_session.flush()

        # First add dependency
        await client.post(
            f"/api/v1/projects/{project1.id}/dependencies/{project2.id}",
            headers=auth_headers,
        )

        # Then remove it
        response = await client.delete(
            f"/api/v1/projects/{project1.id}/dependencies/{project2.id}",
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert not any(d["id"] == project2.id for d in data["dependencies"])
