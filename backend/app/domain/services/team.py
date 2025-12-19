"""
Team service for team management operations.
"""
import re
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, delete

from app.domain.entities import Team, Task, TaskType
from app.domain.exceptions import EntityNotFoundError, EntityAlreadyExistsError, ValidationError
from app.domain.repositories import TeamRepository, UserRepository


def generate_slug(name: str) -> str:
    """Generate a URL-friendly slug from a name."""
    slug = name.lower()
    slug = re.sub(r'[^a-z0-9\s-]', '', slug)
    slug = re.sub(r'[\s_]+', '-', slug)
    slug = re.sub(r'-+', '-', slug)
    return slug.strip('-')


class TeamService:
    """Service for team management operations."""
    
    def __init__(self, session: AsyncSession):
        self.session = session
        self.team_repo = TeamRepository(session)
        self.user_repo = UserRepository(session)
    
    async def create_team(
        self,
        name: str,
        description: str | None = None,
        slug: str | None = None,
        color: str | None = None,
    ) -> Team:
        """
        Create a new team.
        
        Args:
            name: Team name
            description: Optional team description
            slug: Optional custom slug (auto-generated if not provided)
            color: Optional team color (hex code)
            
        Returns:
            Created team with loaded relationships
            
        Raises:
            EntityAlreadyExistsError: If slug is already in use
        """
        if not slug:
            slug = generate_slug(name)
        
        if await self.team_repo.slug_exists(slug):
            raise EntityAlreadyExistsError("Team", "slug", slug)
        
        team = await self.team_repo.create(
            name=name,
            slug=slug,
            description=description,
            color=color,
        )
        
        # Return team with loaded relationships for proper serialization
        return await self.team_repo.get_with_members(team.id)
    
    async def get_team(self, team_id: int) -> Team:
        """Get a team by ID with members."""
        team = await self.team_repo.get_with_members(team_id)
        if not team:
            raise EntityNotFoundError("Team", team_id)
        return team
    
    async def get_team_by_slug(self, slug: str) -> Team:
        """Get a team by slug."""
        team = await self.team_repo.get_by_slug(slug)
        if not team:
            raise EntityNotFoundError("Team", slug)
        return team
    
    async def list_teams(self, skip: int = 0, limit: int = 100) -> list[Team]:
        """List all teams with members."""
        teams = await self.team_repo.get_all_with_members(skip=skip, limit=limit)
        return list(teams)
    
    async def update_team(
        self,
        team_id: int,
        name: str | None = None,
        description: str | None = None,
        slug: str | None = None,
        color: str | None = None,
    ) -> Team:
        """Update a team."""
        team = await self.get_team(team_id)
        
        if slug and slug != team.slug:
            if await self.team_repo.slug_exists(slug, exclude_id=team_id):
                raise EntityAlreadyExistsError("Team", "slug", slug)
        
        updates = {}
        if name is not None:
            updates["name"] = name
        if description is not None:
            updates["description"] = description
        if slug is not None:
            updates["slug"] = slug
        if color is not None:
            updates["color"] = color
        
        if updates:
            await self.team_repo.update(team, **updates)
        
        # Return team with loaded relationships for proper serialization
        return await self.team_repo.get_with_members(team_id)
    
    async def delete_team(
        self,
        team_id: int,
        reassign_tasks_to: int | None = None,
        delete_tasks: bool = False,
    ) -> None:
        """
        Delete a team with options for handling its tasks.
        
        Args:
            team_id: ID of the team to delete
            reassign_tasks_to: Team ID to reassign tasks to (if provided)
            delete_tasks: If True, delete all tasks; if False and no reassign_to, tasks go to 'unassigned' team
        """
        team = await self.get_team(team_id)
        
        # Prevent deleting the unassigned team
        if team.slug == "unassigned":
            raise ValidationError("Cannot delete the unassigned team")
        
        # Handle tasks before deleting team
        task_count = await self._get_task_count(team_id)
        
        if task_count > 0:
            if delete_tasks:
                # Delete all tasks in the team
                await self._delete_team_tasks(team_id)
            else:
                # Reassign tasks to another team
                target_team_id = reassign_tasks_to
                if not target_team_id:
                    # Default to unassigned team
                    unassigned_team = await self.team_repo.get_by_slug("unassigned")
                    if unassigned_team:
                        target_team_id = unassigned_team.id
                    else:
                        raise ValidationError("No target team specified and unassigned team not found")
                
                # Verify target team exists
                target_team = await self.team_repo.get_with_members(target_team_id)
                if not target_team:
                    raise EntityNotFoundError("Team", target_team_id)
                
                # Get the default task type from target team
                target_task_type = await self._get_default_task_type(target_team_id)
                
                # Reassign tasks
                await self._reassign_team_tasks(team_id, target_team_id, target_task_type.id if target_task_type else None)
        
        # Delete the team (cascade will delete task types)
        await self.team_repo.delete(team)
    
    async def _get_task_count(self, team_id: int) -> int:
        """Get the number of tasks in a team."""
        query = select(Task).where(Task.team_id == team_id)
        result = await self.session.execute(query)
        return len(result.scalars().all())
    
    async def _delete_team_tasks(self, team_id: int) -> None:
        """Delete all tasks in a team."""
        stmt = delete(Task).where(Task.team_id == team_id)
        await self.session.execute(stmt)
        await self.session.flush()
    
    async def _get_default_task_type(self, team_id: int) -> TaskType | None:
        """Get the first task type for a team (default)."""
        query = select(TaskType).where(TaskType.team_id == team_id).limit(1)
        result = await self.session.execute(query)
        return result.scalar_one_or_none()
    
    async def _reassign_team_tasks(
        self,
        source_team_id: int,
        target_team_id: int,
        target_task_type_id: int | None
    ) -> None:
        """Reassign all tasks from one team to another."""
        # Get all tasks from source team
        query = select(Task).where(Task.team_id == source_team_id)
        result = await self.session.execute(query)
        tasks = result.scalars().all()
        
        for task in tasks:
            task.team_id = target_team_id
            if target_task_type_id:
                task.task_type_id = target_task_type_id
                # Reset status to the first status of the new task type
                target_type_query = select(TaskType).where(TaskType.id == target_task_type_id)
                target_type_result = await self.session.execute(target_type_query)
                target_type = target_type_result.scalar_one_or_none()
                if target_type and target_type.workflow:
                    task.status = target_type.workflow[0]
        
        await self.session.flush()
    
    async def add_member(self, team_id: int, user_id: int) -> Team:
        """Add a member to a team."""
        # Verify team exists
        _team = await self.get_team(team_id)
        
        # Verify user exists
        user = await self.user_repo.get_by_id(user_id)
        if not user:
            raise EntityNotFoundError("User", user_id)
        
        # Check if already a member
        if await self.team_repo.is_member(team_id, user_id):
            raise ValidationError(f"User {user_id} is already a member of this team")
        
        await self.team_repo.add_member(team_id, user_id)
        
        # Refresh team with members
        return await self.get_team(team_id)
    
    async def remove_member(self, team_id: int, user_id: int) -> Team:
        """Remove a member from a team."""
        team = await self.get_team(team_id)
        
        if not await self.team_repo.is_member(team_id, user_id):
            raise ValidationError(f"User {user_id} is not a member of this team")
        
        await self.team_repo.remove_member(team_id, user_id)
        
        return await self.get_team(team_id)
    
    async def get_team_stats(self, team_id: int) -> dict:
        """Get task statistics for a team."""
        await self.get_team(team_id)  # Verify team exists
        return await self.team_repo.get_team_stats(team_id)
