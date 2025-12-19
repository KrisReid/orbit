"""
Team repository for database operations.
"""

from typing import Sequence

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.domain.entities import Team, TeamMember, TaskType
from app.domain.repositories.base import BaseRepository


class TeamRepository(BaseRepository[Team]):
    """Repository for Team entity operations."""

    def __init__(self, session: AsyncSession):
        super().__init__(Team, session)

    async def get_by_slug(self, slug: str) -> Team | None:
        """Get a team by slug."""
        query = (
            select(Team)
            .where(Team.slug == slug)
            .options(
                selectinload(Team.memberships).selectinload(TeamMember.user),
                selectinload(Team.task_types).selectinload(TaskType.fields),
            )
        )
        result = await self.session.execute(query)
        return result.scalar_one_or_none()

    async def get_with_members(self, id: int) -> Team | None:
        """Get a team with members and task types eagerly loaded."""
        query = (
            select(Team)
            .where(Team.id == id)
            .options(
                selectinload(Team.memberships).selectinload(TeamMember.user),
                selectinload(Team.task_types).selectinload(TaskType.fields),
            )
        )
        result = await self.session.execute(query)
        return result.scalar_one_or_none()

    async def get_all_with_members(
        self, skip: int = 0, limit: int = 100
    ) -> Sequence[Team]:
        """Get all teams with members and task types eagerly loaded."""
        query = (
            select(Team)
            .options(
                selectinload(Team.memberships).selectinload(TeamMember.user),
                selectinload(Team.task_types).selectinload(TaskType.fields),
            )
            .offset(skip)
            .limit(limit)
        )
        result = await self.session.execute(query)
        return result.scalars().all()

    async def slug_exists(self, slug: str, exclude_id: int | None = None) -> bool:
        """Check if slug is already in use."""
        query = select(Team.id).where(Team.slug == slug)
        if exclude_id:
            query = query.where(Team.id != exclude_id)
        result = await self.session.execute(query)
        return result.scalar_one_or_none() is not None

    async def add_member(self, team_id: int, user_id: int) -> TeamMember:
        """Add a member to a team."""
        member = TeamMember(team_id=team_id, user_id=user_id)
        self.session.add(member)
        await self.session.flush()
        return member

    async def remove_member(self, team_id: int, user_id: int) -> bool:
        """Remove a member from a team."""
        query = select(TeamMember).where(
            TeamMember.team_id == team_id, TeamMember.user_id == user_id
        )
        result = await self.session.execute(query)
        member = result.scalar_one_or_none()
        if member:
            await self.session.delete(member)
            await self.session.flush()
            return True
        return False

    async def is_member(self, team_id: int, user_id: int) -> bool:
        """Check if a user is a member of a team."""
        query = select(TeamMember).where(
            TeamMember.team_id == team_id, TeamMember.user_id == user_id
        )
        result = await self.session.execute(query)
        return result.scalar_one_or_none() is not None

    async def get_team_stats(self, team_id: int) -> dict:
        """Get comprehensive task statistics for a team."""
        from app.domain.entities import Task

        # Get team info
        team = await self.get_by_id(team_id)
        if not team:
            return None

        # Count total tasks
        total_query = (
            select(func.count()).select_from(Task).where(Task.team_id == team_id)
        )
        total_result = await self.session.execute(total_query)
        task_count = total_result.scalar_one()

        # Count task types
        type_count_query = (
            select(func.count())
            .select_from(TaskType)
            .where(TaskType.team_id == team_id)
        )
        type_count_result = await self.session.execute(type_count_query)
        task_type_count = type_count_result.scalar_one()

        # Count tasks by status
        status_query = (
            select(Task.status, func.count())
            .where(Task.team_id == team_id)
            .group_by(Task.status)
        )
        status_result = await self.session.execute(status_query)
        by_status = {row[0]: row[1] for row in status_result.all()}

        return {
            "team_id": team_id,
            "team_name": team.name,
            "task_count": task_count,
            "task_type_count": task_type_count,
            "is_unassigned_team": team.slug == "unassigned",
            "tasks_by_status": by_status,
        }
