"""
Unit tests for ProjectService and ProjectTypeService.

Tests project management logic with mocked repositories.
"""

from unittest.mock import AsyncMock, MagicMock

import pytest

from app.domain.entities import Project, ProjectType, Theme
from app.domain.exceptions import (
    EntityNotFoundError,
    EntityAlreadyExistsError,
    ValidationError,
)
from app.domain.services.project import (
    ProjectService,
    ProjectTypeService,
    generate_slug,
)


class TestGenerateSlug:
    """Tests for slug generation helper."""

    def test_basic_slug(self):
        """Simple name becomes lowercase hyphenated."""
        assert generate_slug("My Project") == "my-project"

    def test_special_characters_removed(self):
        """Special characters are removed."""
        assert generate_slug("Project!@#$%") == "project"

    def test_underscores_are_removed(self):
        """Underscores are removed (filtered by alphanumeric regex)."""
        assert generate_slug("my_project_name") == "myprojectname"

    def test_multiple_spaces(self):
        """Multiple spaces become single hyphen."""
        assert generate_slug("My   Project   Name") == "my-project-name"

    def test_leading_trailing_stripped(self):
        """Leading/trailing special chars stripped."""
        assert generate_slug("  My Project  ") == "my-project"


class TestProjectTypeService:
    """Tests for ProjectTypeService."""

    @pytest.fixture
    def mock_project_type_repo(self):
        """Create mock project type repository."""
        repo = AsyncMock()
        return repo

    @pytest.fixture
    def mock_project_repo(self):
        """Create mock project repository."""
        repo = AsyncMock()
        return repo

    @pytest.fixture
    def project_type_service(
        self, mock_session, mock_project_type_repo, mock_project_repo
    ):
        """Create ProjectTypeService with mocked dependencies."""
        service = ProjectTypeService(mock_session)
        service.project_type_repo = mock_project_type_repo
        service.project_repo = mock_project_repo
        return service

    @pytest.fixture
    def sample_project_type(self):
        """Create sample project type."""
        pt = MagicMock(spec=ProjectType)
        pt.id = 1
        pt.name = "Feature"
        pt.slug = "feature"
        pt.description = "Feature projects"
        pt.workflow = ["Backlog", "In Progress", "Done"]
        pt.color = "#3498db"
        pt.fields = []
        return pt

    @pytest.mark.asyncio
    async def test_create_project_type_success(
        self, project_type_service, mock_project_type_repo, sample_project_type
    ):
        """Create project type succeeds with valid data."""
        mock_project_type_repo.slug_exists.return_value = False
        mock_project_type_repo.create.return_value = sample_project_type
        mock_project_type_repo.get_with_fields.return_value = sample_project_type

        result = await project_type_service.create_project_type(
            name="Feature",
            workflow=["Backlog", "In Progress", "Done"],
        )

        assert result == sample_project_type
        mock_project_type_repo.create.assert_called_once()

    @pytest.mark.asyncio
    async def test_create_project_type_generates_slug(
        self, project_type_service, mock_project_type_repo, sample_project_type
    ):
        """Slug is auto-generated from name."""
        mock_project_type_repo.slug_exists.return_value = False
        mock_project_type_repo.create.return_value = sample_project_type
        mock_project_type_repo.get_with_fields.return_value = sample_project_type

        await project_type_service.create_project_type(
            name="My Feature Type",
            workflow=["New", "Done"],
        )

        call_kwargs = mock_project_type_repo.create.call_args.kwargs
        assert call_kwargs["slug"] == "my-feature-type"

    @pytest.mark.asyncio
    async def test_create_project_type_custom_slug(
        self, project_type_service, mock_project_type_repo, sample_project_type
    ):
        """Custom slug is used when provided."""
        mock_project_type_repo.slug_exists.return_value = False
        mock_project_type_repo.create.return_value = sample_project_type
        mock_project_type_repo.get_with_fields.return_value = sample_project_type

        await project_type_service.create_project_type(
            name="Feature",
            workflow=["New", "Done"],
            slug="custom-slug",
        )

        call_kwargs = mock_project_type_repo.create.call_args.kwargs
        assert call_kwargs["slug"] == "custom-slug"

    @pytest.mark.asyncio
    async def test_create_project_type_duplicate_slug(
        self, project_type_service, mock_project_type_repo
    ):
        """Create fails with duplicate slug."""
        mock_project_type_repo.slug_exists.return_value = True

        with pytest.raises(EntityAlreadyExistsError):
            await project_type_service.create_project_type(
                name="Feature",
                workflow=["New", "Done"],
            )

    @pytest.mark.asyncio
    async def test_get_project_type_success(
        self, project_type_service, mock_project_type_repo, sample_project_type
    ):
        """Get project type returns when found."""
        mock_project_type_repo.get_with_fields.return_value = sample_project_type

        result = await project_type_service.get_project_type(1)

        assert result == sample_project_type

    @pytest.mark.asyncio
    async def test_get_project_type_not_found(
        self, project_type_service, mock_project_type_repo
    ):
        """Get project type raises error when not found."""
        mock_project_type_repo.get_with_fields.return_value = None

        with pytest.raises(EntityNotFoundError):
            await project_type_service.get_project_type(999)

    @pytest.mark.asyncio
    async def test_list_project_types(
        self, project_type_service, mock_project_type_repo, sample_project_type
    ):
        """List project types returns paginated results."""
        mock_project_type_repo.get_all_with_fields.return_value = [sample_project_type]
        mock_project_type_repo.count.return_value = 1

        items, total = await project_type_service.list_project_types()

        assert len(items) == 1
        assert total == 1

    @pytest.mark.asyncio
    async def test_update_project_type(
        self, project_type_service, mock_project_type_repo, sample_project_type
    ):
        """Update project type succeeds."""
        mock_project_type_repo.get_with_fields.return_value = sample_project_type
        mock_project_type_repo.update.return_value = sample_project_type

        result = await project_type_service.update_project_type(
            project_type_id=1,
            name="Updated Feature",
        )

        assert result == sample_project_type
        mock_project_type_repo.update.assert_called_once()

    @pytest.mark.asyncio
    async def test_delete_project_type(
        self, project_type_service, mock_project_type_repo, sample_project_type
    ):
        """Delete project type succeeds."""
        mock_project_type_repo.get_with_fields.return_value = sample_project_type

        await project_type_service.delete_project_type(1)

        mock_project_type_repo.delete.assert_called_once_with(sample_project_type)

    @pytest.mark.asyncio
    async def test_get_stats(
        self,
        project_type_service,
        mock_project_type_repo,
        mock_project_repo,
        sample_project_type,
    ):
        """Get stats returns distribution of projects."""
        mock_project_type_repo.get_with_fields.return_value = sample_project_type

        # Create mock projects with different statuses
        project1 = MagicMock()
        project1.status = "Backlog"
        project2 = MagicMock()
        project2.status = "In Progress"
        project3 = MagicMock()
        project3.status = "Backlog"

        mock_project_repo.get_all_filtered.return_value = [project1, project2, project3]

        stats = await project_type_service.get_stats(1)

        assert stats["project_type_id"] == 1
        assert stats["total_projects"] == 3
        assert stats["projects_by_status"]["Backlog"] == 2
        assert stats["projects_by_status"]["In Progress"] == 1

    @pytest.mark.asyncio
    async def test_migrate_projects_same_type_fails(
        self, project_type_service, mock_project_type_repo, sample_project_type
    ):
        """Migration to same type fails."""
        with pytest.raises(ValidationError):
            await project_type_service.migrate_projects(1, 1, {})

    @pytest.mark.asyncio
    async def test_migrate_projects_invalid_status_fails(
        self, project_type_service, mock_project_type_repo, sample_project_type
    ):
        """Migration with invalid target status fails."""
        target_type = MagicMock(spec=ProjectType)
        target_type.id = 2
        target_type.workflow = ["New", "Done"]

        mock_project_type_repo.get_with_fields.return_value = target_type

        with pytest.raises(ValidationError):
            await project_type_service.migrate_projects(
                1, 2, {"Backlog": "InvalidStatus"}
            )


class TestProjectService:
    """Tests for ProjectService."""

    @pytest.fixture
    def mock_project_repo(self):
        """Create mock project repository."""
        repo = AsyncMock()
        return repo

    @pytest.fixture
    def mock_project_type_repo(self):
        """Create mock project type repository."""
        repo = AsyncMock()
        return repo

    @pytest.fixture
    def mock_theme_repo(self):
        """Create mock theme repository."""
        repo = AsyncMock()
        return repo

    @pytest.fixture
    def mock_task_repo(self):
        """Create mock task repository."""
        repo = AsyncMock()
        return repo

    @pytest.fixture
    def project_service(
        self,
        mock_session,
        mock_project_repo,
        mock_project_type_repo,
        mock_theme_repo,
        mock_task_repo,
    ):
        """Create ProjectService with mocked dependencies."""
        service = ProjectService(mock_session)
        service.project_repo = mock_project_repo
        service.project_type_repo = mock_project_type_repo
        service.theme_repo = mock_theme_repo
        service.task_repo = mock_task_repo
        return service

    @pytest.fixture
    def sample_project_type(self):
        """Create sample project type."""
        pt = MagicMock(spec=ProjectType)
        pt.id = 1
        pt.name = "Feature"
        pt.workflow = ["Backlog", "In Progress", "Done"]
        pt.fields = []
        return pt

    @pytest.fixture
    def sample_theme(self):
        """Create sample theme."""
        theme = MagicMock(spec=Theme)
        theme.id = 1
        theme.title = "Q1 Initiatives"
        return theme

    @pytest.fixture
    def sample_project(self, sample_project_type, sample_theme):
        """Create sample project."""
        project = MagicMock(spec=Project)
        project.id = 1
        project.title = "Test Project"
        project.description = "A test project"
        project.status = "Backlog"
        project.project_type_id = sample_project_type.id
        project.project_type = sample_project_type
        project.theme_id = sample_theme.id
        project.theme = sample_theme
        return project

    @pytest.mark.asyncio
    async def test_create_project_success(
        self,
        project_service,
        mock_project_repo,
        mock_project_type_repo,
        sample_project_type,
        sample_project,
    ):
        """Create project succeeds with valid data."""
        mock_project_type_repo.get_with_fields.return_value = sample_project_type
        mock_project_repo.create.return_value = sample_project
        mock_project_repo.get_with_relations.return_value = sample_project

        result = await project_service.create_project(
            title="Test Project",
            project_type_id=1,
        )

        assert result == sample_project
        mock_project_repo.create.assert_called_once()

    @pytest.mark.asyncio
    async def test_create_project_with_theme(
        self,
        project_service,
        mock_project_repo,
        mock_project_type_repo,
        mock_theme_repo,
        sample_project_type,
        sample_theme,
        sample_project,
    ):
        """Create project with theme succeeds."""
        mock_project_type_repo.get_with_fields.return_value = sample_project_type
        mock_theme_repo.get_by_id.return_value = sample_theme
        mock_project_repo.create.return_value = sample_project
        mock_project_repo.get_with_relations.return_value = sample_project

        result = await project_service.create_project(
            title="Test Project",
            project_type_id=1,
            theme_id=1,
        )

        assert result == sample_project
        mock_theme_repo.get_by_id.assert_called_once_with(1)

    @pytest.mark.asyncio
    async def test_create_project_invalid_type(
        self, project_service, mock_project_type_repo
    ):
        """Create project fails with invalid project type."""
        mock_project_type_repo.get_with_fields.return_value = None

        with pytest.raises(EntityNotFoundError):
            await project_service.create_project(
                title="Test Project",
                project_type_id=999,
            )

    @pytest.mark.asyncio
    async def test_create_project_invalid_theme(
        self,
        project_service,
        mock_project_type_repo,
        mock_theme_repo,
        sample_project_type,
    ):
        """Create project fails with invalid theme."""
        mock_project_type_repo.get_with_fields.return_value = sample_project_type
        mock_theme_repo.get_by_id.return_value = None

        with pytest.raises(EntityNotFoundError):
            await project_service.create_project(
                title="Test Project",
                project_type_id=1,
                theme_id=999,
            )

    @pytest.mark.asyncio
    async def test_create_project_default_status(
        self,
        project_service,
        mock_project_repo,
        mock_project_type_repo,
        sample_project_type,
        sample_project,
    ):
        """Create project uses first workflow status as default."""
        mock_project_type_repo.get_with_fields.return_value = sample_project_type
        mock_project_repo.create.return_value = sample_project
        mock_project_repo.get_with_relations.return_value = sample_project

        await project_service.create_project(
            title="Test Project",
            project_type_id=1,
        )

        call_kwargs = mock_project_repo.create.call_args.kwargs
        assert call_kwargs["status"] == "Backlog"  # First in workflow

    @pytest.mark.asyncio
    async def test_get_project_success(
        self, project_service, mock_project_repo, sample_project
    ):
        """Get project returns when found."""
        mock_project_repo.get_with_relations.return_value = sample_project

        result = await project_service.get_project(1)

        assert result == sample_project

    @pytest.mark.asyncio
    async def test_get_project_not_found(self, project_service, mock_project_repo):
        """Get project raises error when not found."""
        mock_project_repo.get_with_relations.return_value = None

        with pytest.raises(EntityNotFoundError):
            await project_service.get_project(999)

    @pytest.mark.asyncio
    async def test_list_projects(
        self, project_service, mock_project_repo, sample_project
    ):
        """List projects returns paginated results."""
        mock_project_repo.get_all_filtered.return_value = [sample_project]
        mock_project_repo.count_filtered.return_value = 1

        items, total = await project_service.list_projects()

        assert len(items) == 1
        assert total == 1

    @pytest.mark.asyncio
    async def test_list_projects_with_filters(
        self, project_service, mock_project_repo, sample_project
    ):
        """List projects applies filters."""
        mock_project_repo.get_all_filtered.return_value = [sample_project]
        mock_project_repo.count_filtered.return_value = 1

        await project_service.list_projects(
            project_type_ids=[1],
            theme_id=1,
            statuses=["Backlog"],
        )

        mock_project_repo.get_all_filtered.assert_called_once()
        call_kwargs = mock_project_repo.get_all_filtered.call_args.kwargs
        assert call_kwargs["project_type_ids"] == [1]
        assert call_kwargs["theme_id"] == 1
        assert call_kwargs["statuses"] == ["Backlog"]

    @pytest.mark.asyncio
    async def test_update_project_title(
        self, project_service, mock_project_repo, sample_project
    ):
        """Update project title."""
        mock_project_repo.get_with_relations.return_value = sample_project
        mock_project_repo.update.return_value = sample_project

        await project_service.update_project(
            project_id=1,
            title="Updated Title",
        )

        call_kwargs = mock_project_repo.update.call_args.kwargs
        assert call_kwargs["title"] == "Updated Title"

    @pytest.mark.asyncio
    async def test_update_project_clear_theme(
        self, project_service, mock_project_repo, sample_project
    ):
        """Update project to clear theme."""
        mock_project_repo.get_with_relations.return_value = sample_project
        mock_project_repo.update.return_value = sample_project

        await project_service.update_project(
            project_id=1,
            clear_theme=True,
        )

        call_kwargs = mock_project_repo.update.call_args.kwargs
        assert call_kwargs["theme_id"] is None

    @pytest.mark.asyncio
    async def test_delete_project_success(
        self, project_service, mock_project_repo, mock_task_repo, sample_project
    ):
        """Delete project succeeds."""
        mock_project_repo.get_with_relations.return_value = sample_project

        await project_service.delete_project(1)

        mock_task_repo.update_project_for_tasks.assert_called_once_with(1, None)
        mock_project_repo.delete.assert_called_once_with(sample_project)

    @pytest.mark.asyncio
    async def test_delete_project_with_task_migration(
        self, project_service, mock_project_repo, mock_task_repo, sample_project
    ):
        """Delete project with task migration."""
        target_project = MagicMock(spec=Project)
        target_project.id = 2

        mock_project_repo.get_with_relations.return_value = sample_project
        mock_project_repo.get_by_id.return_value = target_project

        await project_service.delete_project(1, target_project_id=2)

        mock_task_repo.update_project_for_tasks.assert_called_once_with(1, 2)

    @pytest.mark.asyncio
    async def test_delete_project_same_target_fails(
        self, project_service, mock_project_repo, sample_project
    ):
        """Delete project with same target project fails."""
        mock_project_repo.get_with_relations.return_value = sample_project

        with pytest.raises(ValidationError):
            await project_service.delete_project(1, target_project_id=1)

    @pytest.mark.asyncio
    async def test_add_dependency_success(
        self, project_service, mock_project_repo, sample_project
    ):
        """Add dependency succeeds."""
        dependency = MagicMock(spec=Project)
        dependency.id = 2

        mock_project_repo.get_with_relations.return_value = sample_project

        await project_service.add_dependency(1, 2)

        mock_project_repo.add_dependency.assert_called_once_with(1, 2)

    @pytest.mark.asyncio
    async def test_add_dependency_self_reference_fails(
        self, project_service, mock_project_repo, sample_project
    ):
        """Adding self as dependency fails."""
        mock_project_repo.get_with_relations.return_value = sample_project

        with pytest.raises(ValidationError):
            await project_service.add_dependency(1, 1)

    @pytest.mark.asyncio
    async def test_get_task_count(self, project_service, mock_task_repo):
        """Get task count returns count."""
        mock_task_repo.count_filtered.return_value = 5

        count = await project_service.get_task_count(1)

        assert count == 5
        mock_task_repo.count_filtered.assert_called_once_with(project_id=1)
