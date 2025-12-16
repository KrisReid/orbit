"""
Theme repository for database operations.
"""
from typing import Sequence

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.domain.entities import Theme
from app.domain.repositories.base import BaseRepository


class ThemeRepository(BaseRepository[Theme]):
    """Repository for Theme entity operations."""
    
    def __init__(self, session: AsyncSession):
        super().__init__(Theme, session)
    
    async def get_with_projects(self, id: int) -> Theme | None:
        """Get a theme with projects eagerly loaded."""
        query = (
            select(Theme)
            .where(Theme.id == id)
            .options(selectinload(Theme.projects))
        )
        result = await self.session.execute(query)
        return result.scalar_one_or_none()
    
    async def get_all_filtered(
        self,
        skip: int = 0,
        limit: int = 100,
        status: str | None = None,
        include_archived: bool = False,
    ) -> Sequence[Theme]:
        """Get themes with optional filtering."""
        query = select(Theme).options(selectinload(Theme.projects))
        
        if status:
            query = query.where(Theme.status == status)
        
        if not include_archived:
            query = query.where(Theme.status != "archived")
        
        query = query.offset(skip).limit(limit)
        result = await self.session.execute(query)
        return result.scalars().all()
    
    async def count_filtered(
        self,
        status: str | None = None,
        include_archived: bool = False,
    ) -> int:
        """Count themes with optional filtering."""
        from sqlalchemy import func
        
        query = select(func.count()).select_from(Theme)
        
        if status:
            query = query.where(Theme.status == status)
        
        if not include_archived:
            query = query.where(Theme.status != "archived")
        
        result = await self.session.execute(query)
        return result.scalar_one()
