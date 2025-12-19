"""
User repository for database operations.
"""
from typing import Sequence

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities import User
from app.domain.repositories.base import BaseRepository


class UserRepository(BaseRepository[User]):
    """Repository for User entity operations."""
    
    def __init__(self, session: AsyncSession):
        super().__init__(User, session)
    
    async def get_by_email(self, email: str) -> User | None:
        """Get a user by email address."""
        query = select(User).where(User.email == email)
        result = await self.session.execute(query)
        return result.scalar_one_or_none()
    
    async def get_active_users(
        self, 
        skip: int = 0, 
        limit: int = 100
    ) -> Sequence[User]:
        """Get all active users."""
        query = (
            select(User)
            .where(User.is_active)
            .offset(skip)
            .limit(limit)
        )
        result = await self.session.execute(query)
        return result.scalars().all()
    
    async def email_exists(self, email: str, exclude_id: int | None = None) -> bool:
        """Check if email is already in use."""
        query = select(User.id).where(User.email == email)
        if exclude_id:
            query = query.where(User.id != exclude_id)
        result = await self.session.execute(query)
        return result.scalar_one_or_none() is not None
