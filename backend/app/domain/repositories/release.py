"""
Release repository for database operations.
"""
from typing import Sequence

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.domain.entities import Release, ReleaseStatus
from app.domain.repositories.base import BaseRepository


class ReleaseRepository(BaseRepository[Release]):
    """Repository for Release entity operations."""
    
    def __init__(self, session: AsyncSession):
        super().__init__(Release, session)
    
    async def get_by_version(self, version: str) -> Release | None:
        """Get a release by version string."""
        query = (
            select(Release)
            .where(Release.version == version)
            .options(selectinload(Release.tasks))
        )
        result = await self.session.execute(query)
        return result.scalar_one_or_none()
    
    async def get_with_tasks(self, id: int) -> Release | None:
        """Get a release with tasks eagerly loaded."""
        query = (
            select(Release)
            .where(Release.id == id)
            .options(selectinload(Release.tasks))
        )
        result = await self.session.execute(query)
        return result.scalar_one_or_none()
    
    async def get_all_filtered(
        self,
        skip: int = 0,
        limit: int = 100,
        status: ReleaseStatus | None = None,
    ) -> Sequence[Release]:
        """Get releases with optional filtering."""
        query = select(Release).options(selectinload(Release.tasks))
        
        if status:
            query = query.where(Release.status == status)
        
        query = query.order_by(Release.target_date.desc().nullslast()).offset(skip).limit(limit)
        result = await self.session.execute(query)
        return result.scalars().all()
    
    async def count_filtered(
        self,
        status: ReleaseStatus | None = None,
    ) -> int:
        """Count releases with optional filtering."""
        query = select(func.count()).select_from(Release)
        
        if status:
            query = query.where(Release.status == status)
        
        result = await self.session.execute(query)
        return result.scalar_one()
    
    async def version_exists(self, version: str, exclude_id: int | None = None) -> bool:
        """Check if version is already in use."""
        query = select(Release.id).where(Release.version == version)
        if exclude_id:
            query = query.where(Release.id != exclude_id)
        result = await self.session.execute(query)
        return result.scalar_one_or_none() is not None
