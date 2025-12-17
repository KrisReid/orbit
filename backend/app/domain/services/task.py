"""
Task service for task and task type management.
"""
import re
from typing import Any

from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities import Task, TaskType, GitHubLink, GitHubLinkType, GitHubPRStatus
from app.domain.exceptions import EntityNotFoundError, EntityAlreadyExistsError, ValidationError
from app.domain.repositories import (
    TaskRepository, 
    TaskTypeRepository, 
    GitHubLinkRepository,
    TeamRepository,
    ProjectRepository,
    ReleaseRepository,
)


def generate_slug(name: str) -> str:
    """Generate a URL-friendly slug from a name."""
    slug = name.lower()
    slug = re.sub(r'[^a-z0-9\s-]', '', slug)
    slug = re.sub(r'[\s_]+', '-', slug)
    slug = re.sub(r'-+', '-', slug)
    return slug.strip('-')


class TaskTypeService:
    """Service for task type management."""
    
    def __init__(self, session: AsyncSession):
        self.session = session
        self.task_type_repo = TaskTypeRepository(session)
        self.team_repo = TeamRepository(session)
    
    async def create_task_type(
        self,
        name: str,
        team_id: int,
        workflow: list[str],
        description: str | None = None,
        color: str | None = None,
        slug: str | None = None,
        fields: list[dict] | None = None,
    ) -> TaskType:
        """Create a new task type."""
        # Verify team exists
        team = await self.team_repo.get_by_id(team_id)
        if not team:
            raise EntityNotFoundError("Team", team_id)
        
        if not slug:
            slug = generate_slug(name)
        
        task_type = await self.task_type_repo.create(
            name=name,
            slug=slug,
            team_id=team_id,
            description=description,
            workflow=workflow,
            color=color,
        )
        
        if fields:
            await self.task_type_repo.update_fields(task_type.id, fields)
        
        return await self.task_type_repo.get_with_fields(task_type.id)
    
    async def get_task_type(self, task_type_id: int) -> TaskType:
        """Get a task type by ID with fields."""
        task_type = await self.task_type_repo.get_with_fields(task_type_id)
        if not task_type:
            raise EntityNotFoundError("TaskType", task_type_id)
        return task_type
    
    async def list_task_types(
        self,
        skip: int = 0,
        limit: int = 100,
        team_id: int | None = None,
    ) -> tuple[list[TaskType], int]:
        """List task types with optional team filter."""
        task_types = await self.task_type_repo.get_all_with_fields(
            skip=skip, 
            limit=limit, 
            team_id=team_id
        )
        total = await self.task_type_repo.count()
        return list(task_types), total
    
    async def update_task_type(
        self,
        task_type_id: int,
        name: str | None = None,
        description: str | None = None,
        workflow: list[str] | None = None,
        color: str | None = None,
        fields: list[dict] | None = None,
    ) -> TaskType:
        """Update a task type."""
        task_type = await self.get_task_type(task_type_id)
        
        updates = {}
        if name is not None:
            updates["name"] = name
        if description is not None:
            updates["description"] = description
        if workflow is not None:
            updates["workflow"] = workflow
        if color is not None:
            updates["color"] = color
        
        if updates:
            task_type = await self.task_type_repo.update(task_type, **updates)
        
        if fields is not None:
            await self.task_type_repo.update_fields(task_type_id, fields)
            task_type = await self.task_type_repo.get_with_fields(task_type_id)
        
        return task_type
    
    async def delete_task_type(self, task_type_id: int) -> None:
        """Delete a task type."""
        task_type = await self.get_task_type(task_type_id)
        await self.task_type_repo.delete(task_type)
    
    async def get_stats(self, task_type_id: int) -> dict:
        """Get statistics for a task type."""
        task_type = await self.get_task_type(task_type_id)
        
        # Get task repository to count tasks
        task_repo = TaskRepository(self.session)
        
        # Count tasks by status for this task type
        tasks_by_status = {}
        total_tasks = 0
        
        for status in task_type.workflow:
            count = await task_repo.count_filtered(task_type_id=task_type_id, statuses=[status])
            tasks_by_status[status] = count
            total_tasks += count
        
        return {
            "task_type_id": task_type.id,
            "task_type_name": task_type.name,
            "team_id": task_type.team_id,
            "workflow": task_type.workflow,
            "total_tasks": total_tasks,
            "tasks_by_status": tasks_by_status,
        }
    
    async def migrate_tasks(
        self,
        source_type_id: int,
        target_type_id: int,
        status_mappings: dict[str, str],
    ) -> int:
        """Migrate tasks from one task type to another with status mapping."""
        # Verify both task types exist
        source_type = await self.get_task_type(source_type_id)
        target_type = await self.get_task_type(target_type_id)
        
        # Get task repository
        task_repo = TaskRepository(self.session)
        
        # Get all tasks of source type
        tasks = await task_repo.get_all_filtered(
            task_type_id=source_type_id,
            limit=10000  # High limit to get all
        )
        
        # Migrate each task
        count = 0
        for task in tasks:
            old_status = task.status
            new_status = status_mappings.get(old_status, target_type.workflow[0] if target_type.workflow else "Backlog")
            
            await task_repo.update(
                task,
                task_type_id=target_type_id,
                status=new_status,
            )
            count += 1
        
        return count


class TaskService:
    """Service for task management."""
    
    def __init__(self, session: AsyncSession):
        self.session = session
        self.task_repo = TaskRepository(session)
        self.task_type_repo = TaskTypeRepository(session)
        self.team_repo = TeamRepository(session)
        self.project_repo = ProjectRepository(session)
        self.release_repo = ReleaseRepository(session)
        self.github_link_repo = GitHubLinkRepository(session)
    
    async def create_task(
        self,
        title: str,
        team_id: int,
        task_type_id: int,
        description: str | None = None,
        project_id: int | None = None,
        release_id: int | None = None,
        estimation: str | None = None,
        custom_data: dict[str, Any] | None = None,
    ) -> Task:
        """Create a new task."""
        # Verify team exists
        team = await self.team_repo.get_by_id(team_id)
        if not team:
            raise EntityNotFoundError("Team", team_id)
        
        # Verify task type exists and get default status
        task_type = await self.task_type_repo.get_with_fields(task_type_id)
        if not task_type:
            raise EntityNotFoundError("TaskType", task_type_id)
        
        # Use first workflow status as default
        default_status = task_type.workflow[0] if task_type.workflow else "Backlog"
        
        # Verify project exists if provided
        if project_id:
            project = await self.project_repo.get_by_id(project_id)
            if not project:
                raise EntityNotFoundError("Project", project_id)
        
        # Verify release exists if provided
        if release_id:
            release = await self.release_repo.get_by_id(release_id)
            if not release:
                raise EntityNotFoundError("Release", release_id)
        
        # Generate display ID
        display_id = await self.task_repo.get_next_display_id()
        
        return await self.task_repo.create(
            title=title,
            description=description,
            display_id=display_id,
            team_id=team_id,
            task_type_id=task_type_id,
            project_id=project_id,
            release_id=release_id,
            status=default_status,
            estimation=estimation,
            custom_data=custom_data,
        )
    
    async def get_task(self, task_id: int) -> Task:
        """Get a task by ID with all relations."""
        task = await self.task_repo.get_with_relations(task_id)
        if not task:
            raise EntityNotFoundError("Task", task_id)
        return task
    
    async def get_task_by_display_id(self, display_id: str) -> Task:
        """Get a task by display ID."""
        task = await self.task_repo.get_by_display_id(display_id)
        if not task:
            raise EntityNotFoundError("Task", display_id)
        return task
    
    async def list_tasks(
        self,
        skip: int = 0,
        limit: int = 100,
        team_id: int | None = None,
        task_type_id: int | None = None,
        project_id: int | None = None,
        release_id: int | None = None,
        statuses: list[str] | None = None,
    ) -> tuple[list[Task], int]:
        """List tasks with filtering."""
        tasks = await self.task_repo.get_all_filtered(
            skip=skip,
            limit=limit,
            team_id=team_id,
            task_type_id=task_type_id,
            project_id=project_id,
            release_id=release_id,
            statuses=statuses,
        )
        total = await self.task_repo.count_filtered(
            team_id=team_id,
            task_type_id=task_type_id,
            project_id=project_id,
            release_id=release_id,
            statuses=statuses,
        )
        return list(tasks), total
    
    async def update_task(
        self,
        task_id: int,
        title: str | None = None,
        description: str | None = None,
        status: str | None = None,
        team_id: int | None = None,
        task_type_id: int | None = None,
        project_id: int | None = None,
        release_id: int | None = None,
        estimation: str | None = None,
        custom_data: dict[str, Any] | None = None,
    ) -> Task:
        """Update a task."""
        task = await self.get_task(task_id)
        
        # Verify foreign keys if being changed
        if team_id is not None and team_id != task.team_id:
            team = await self.team_repo.get_by_id(team_id)
            if not team:
                raise EntityNotFoundError("Team", team_id)
        
        if task_type_id is not None and task_type_id != task.task_type_id:
            task_type = await self.task_type_repo.get_by_id(task_type_id)
            if not task_type:
                raise EntityNotFoundError("TaskType", task_type_id)
        
        if project_id is not None and project_id != task.project_id:
            if project_id:
                project = await self.project_repo.get_by_id(project_id)
                if not project:
                    raise EntityNotFoundError("Project", project_id)
        
        if release_id is not None and release_id != task.release_id:
            if release_id:
                release = await self.release_repo.get_by_id(release_id)
                if not release:
                    raise EntityNotFoundError("Release", release_id)
        
        updates = {}
        if title is not None:
            updates["title"] = title
        if description is not None:
            updates["description"] = description
        if status is not None:
            updates["status"] = status
        if team_id is not None:
            updates["team_id"] = team_id
        if task_type_id is not None:
            updates["task_type_id"] = task_type_id
        if project_id is not None:
            updates["project_id"] = project_id if project_id else None
        if release_id is not None:
            updates["release_id"] = release_id if release_id else None
        if estimation is not None:
            updates["estimation"] = estimation
        if custom_data is not None:
            updates["custom_data"] = custom_data
        
        if updates:
            task = await self.task_repo.update(task, **updates)
        
        return task
    
    async def delete_task(self, task_id: int) -> None:
        """Delete a task."""
        task = await self.get_task(task_id)
        await self.task_repo.delete(task)
    
    async def add_dependency(self, task_id: int, depends_on_id: int) -> Task:
        """Add a dependency to a task."""
        await self.get_task(task_id)
        await self.get_task(depends_on_id)
        
        if task_id == depends_on_id:
            raise ValidationError("A task cannot depend on itself")
        
        await self.task_repo.add_dependency(task_id, depends_on_id)
        return await self.get_task(task_id)
    
    async def remove_dependency(self, task_id: int, depends_on_id: int) -> Task:
        """Remove a dependency from a task."""
        await self.task_repo.remove_dependency(task_id, depends_on_id)
        return await self.get_task(task_id)


class GitHubService:
    """Service for GitHub integration."""
    
    def __init__(self, session: AsyncSession):
        self.session = session
        self.github_link_repo = GitHubLinkRepository(session)
        self.task_repo = TaskRepository(session)
    
    async def create_link(
        self,
        task_id: int,
        link_type: GitHubLinkType,
        repository_owner: str,
        repository_name: str,
        url: str,
        pr_number: int | None = None,
        pr_title: str | None = None,
        pr_status: GitHubPRStatus | None = None,
        branch_name: str | None = None,
        commit_sha: str | None = None,
    ) -> GitHubLink:
        """Create a GitHub link for a task."""
        # Verify task exists
        task = await self.task_repo.get_by_id(task_id)
        if not task:
            raise EntityNotFoundError("Task", task_id)
        
        return await self.github_link_repo.create(
            task_id=task_id,
            link_type=link_type,
            repository_owner=repository_owner,
            repository_name=repository_name,
            url=url,
            pr_number=pr_number,
            pr_title=pr_title,
            pr_status=pr_status,
            branch_name=branch_name,
            commit_sha=commit_sha,
        )
    
    async def update_pr_status(
        self,
        repository_owner: str,
        repository_name: str,
        pr_number: int,
        pr_status: GitHubPRStatus,
        pr_title: str | None = None,
    ) -> GitHubLink | None:
        """Update PR status from webhook."""
        link = await self.github_link_repo.get_by_pr(
            repository_owner, 
            repository_name, 
            pr_number
        )
        
        if link:
            updates = {"pr_status": pr_status}
            if pr_title:
                updates["pr_title"] = pr_title
            link = await self.github_link_repo.update(link, **updates)
        
        return link
    
    async def delete_link(self, link_id: int) -> None:
        """Delete a GitHub link."""
        link = await self.github_link_repo.get_by_id(link_id)
        if not link:
            raise EntityNotFoundError("GitHubLink", link_id)
        await self.github_link_repo.delete(link)
