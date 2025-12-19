"""
Task repository for database operations.
"""

from typing import Sequence

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.domain.entities import Task, TaskType, TaskTypeField, GitHubLink
from app.domain.repositories.base import BaseRepository
from app.core.config import settings


class TaskTypeRepository(BaseRepository[TaskType]):
    """Repository for TaskType entity operations."""

    def __init__(self, session: AsyncSession):
        super().__init__(TaskType, session)

    async def get_by_slug_and_team(self, slug: str, team_id: int) -> TaskType | None:
        """Get a task type by slug and team."""
        query = (
            select(TaskType)
            .where(TaskType.slug == slug, TaskType.team_id == team_id)
            .options(selectinload(TaskType.fields))
        )
        result = await self.session.execute(query)
        return result.scalar_one_or_none()

    async def get_with_fields(self, id: int) -> TaskType | None:
        """Get a task type with fields eagerly loaded."""
        query = (
            select(TaskType)
            .where(TaskType.id == id)
            .options(selectinload(TaskType.fields))
        )
        result = await self.session.execute(query)
        return result.scalar_one_or_none()

    async def get_by_team(
        self,
        team_id: int,
        skip: int = 0,
        limit: int = 100,
    ) -> Sequence[TaskType]:
        """Get all task types for a team."""
        query = (
            select(TaskType)
            .where(TaskType.team_id == team_id)
            .options(selectinload(TaskType.fields))
            .offset(skip)
            .limit(limit)
        )
        result = await self.session.execute(query)
        return result.scalars().all()

    async def get_all_with_fields(
        self,
        skip: int = 0,
        limit: int = 100,
        team_id: int | None = None,
    ) -> Sequence[TaskType]:
        """Get all task types with optional team filter."""
        query = select(TaskType).options(selectinload(TaskType.fields))

        if team_id:
            query = query.where(TaskType.team_id == team_id)

        query = query.offset(skip).limit(limit)
        result = await self.session.execute(query)
        return result.scalars().all()

    async def add_field(self, task_type_id: int, **kwargs) -> TaskTypeField:
        """Add a field to a task type."""
        field = TaskTypeField(task_type_id=task_type_id, **kwargs)
        self.session.add(field)
        await self.session.flush()
        await self.session.refresh(field)
        return field

    async def update_fields(
        self, task_type_id: int, fields_data: list[dict]
    ) -> list[TaskTypeField]:
        """Replace all fields for a task type."""
        from sqlalchemy import delete

        await self.session.execute(
            delete(TaskTypeField).where(TaskTypeField.task_type_id == task_type_id)
        )

        fields = []
        for i, field_data in enumerate(fields_data):
            field = TaskTypeField(task_type_id=task_type_id, order=i, **field_data)
            self.session.add(field)
            fields.append(field)

        await self.session.flush()
        return fields


class TaskRepository(BaseRepository[Task]):
    """Repository for Task entity operations."""

    def __init__(self, session: AsyncSession):
        super().__init__(Task, session)

    async def get_next_display_id(self) -> str:
        """Generate the next display ID for a task."""
        query = select(func.max(Task.id))
        result = await self.session.execute(query)
        max_id = result.scalar_one() or 0
        return f"{settings.TASK_ID_PREFIX}-{max_id + 1}"

    async def get_by_display_id(self, display_id: str) -> Task | None:
        """Get a task by display ID."""
        query = (
            select(Task)
            .where(Task.display_id == display_id)
            .options(
                selectinload(Task.team),
                selectinload(Task.task_type),
                selectinload(Task.project),
                selectinload(Task.release),
                selectinload(Task.github_links),
                selectinload(Task.dependencies),
                selectinload(Task.dependents),
            )
        )
        result = await self.session.execute(query)
        return result.scalar_one_or_none()

    async def get_with_relations(self, id: int) -> Task | None:
        """Get a task with all relations eagerly loaded."""
        query = (
            select(Task)
            .where(Task.id == id)
            .options(
                selectinload(Task.team),
                selectinload(Task.task_type).selectinload(TaskType.fields),
                selectinload(Task.project),
                selectinload(Task.release),
                selectinload(Task.github_links),
                selectinload(Task.dependencies),
                selectinload(Task.dependents),
            )
        )
        result = await self.session.execute(query)
        return result.scalar_one_or_none()

    async def get_all_filtered(
        self,
        skip: int = 0,
        limit: int = 100,
        team_id: int | None = None,
        task_type_id: int | None = None,
        project_id: int | None = None,
        release_id: int | None = None,
        statuses: list[str] | None = None,
    ) -> Sequence[Task]:
        """Get tasks with optional filtering."""
        query = select(Task).options(
            selectinload(Task.team),
            selectinload(Task.task_type),
            selectinload(Task.project),
            selectinload(Task.release),
            selectinload(Task.github_links),
            selectinload(Task.dependencies),
            selectinload(Task.dependents),
        )

        if team_id:
            query = query.where(Task.team_id == team_id)

        if task_type_id:
            query = query.where(Task.task_type_id == task_type_id)

        if project_id:
            query = query.where(Task.project_id == project_id)

        if release_id:
            query = query.where(Task.release_id == release_id)

        if statuses:
            query = query.where(Task.status.in_(statuses))

        query = query.order_by(Task.updated_at.desc()).offset(skip).limit(limit)
        result = await self.session.execute(query)
        return result.scalars().all()

    async def count_filtered(
        self,
        team_id: int | None = None,
        task_type_id: int | None = None,
        project_id: int | None = None,
        release_id: int | None = None,
        statuses: list[str] | None = None,
    ) -> int:
        """Count tasks with optional filtering."""
        query = select(func.count()).select_from(Task)

        if team_id:
            query = query.where(Task.team_id == team_id)

        if task_type_id:
            query = query.where(Task.task_type_id == task_type_id)

        if project_id:
            query = query.where(Task.project_id == project_id)

        if release_id:
            query = query.where(Task.release_id == release_id)

        if statuses:
            query = query.where(Task.status.in_(statuses))

        result = await self.session.execute(query)
        return result.scalar_one()

    async def update_project_for_tasks(
        self, current_project_id: int, new_project_id: int | None
    ) -> int:
        """Update project_id for all tasks of a project. Returns count of updated tasks."""
        from sqlalchemy import update

        query = (
            update(Task)
            .where(Task.project_id == current_project_id)
            .values(project_id=new_project_id)
        )
        result = await self.session.execute(query)
        await self.session.flush()
        return result.rowcount

    async def add_dependency(self, task_id: int, depends_on_id: int) -> None:
        """Add a dependency to a task."""
        task = await self.get_by_id(task_id, [Task.dependencies])
        if task:
            depends_on = await self.get_by_id(depends_on_id)
            if depends_on and depends_on not in task.dependencies:
                task.dependencies.append(depends_on)
                await self.session.flush()

    async def remove_dependency(self, task_id: int, depends_on_id: int) -> None:
        """Remove a dependency from a task."""
        task = await self.get_by_id(task_id, [Task.dependencies])
        if task:
            depends_on = await self.get_by_id(depends_on_id)
            if depends_on and depends_on in task.dependencies:
                task.dependencies.remove(depends_on)
                await self.session.flush()


class GitHubLinkRepository(BaseRepository[GitHubLink]):
    """Repository for GitHubLink entity operations."""

    def __init__(self, session: AsyncSession):
        super().__init__(GitHubLink, session)

    async def get_by_task(self, task_id: int) -> Sequence[GitHubLink]:
        """Get all GitHub links for a task."""
        query = select(GitHubLink).where(GitHubLink.task_id == task_id)
        result = await self.session.execute(query)
        return result.scalars().all()

    async def get_by_pr(
        self, repository_owner: str, repository_name: str, pr_number: int
    ) -> GitHubLink | None:
        """Get a GitHub link by PR details."""
        query = select(GitHubLink).where(
            GitHubLink.repository_owner == repository_owner,
            GitHubLink.repository_name == repository_name,
            GitHubLink.pr_number == pr_number,
        )
        result = await self.session.execute(query)
        return result.scalar_one_or_none()
