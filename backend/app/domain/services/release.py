"""
Release service for version management.
"""
from datetime import date

from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities import Release, ReleaseStatus
from app.domain.exceptions import EntityNotFoundError, EntityAlreadyExistsError
from app.domain.repositories import ReleaseRepository


class ReleaseService:
    """Service for release management operations."""
    
    def __init__(self, session: AsyncSession):
        self.session = session
        self.release_repo = ReleaseRepository(session)
    
    async def create_release(
        self,
        version: str,
        title: str,
        description: str | None = None,
        target_date: date | None = None,
        status: ReleaseStatus = ReleaseStatus.PLANNED,
    ) -> Release:
        """
        Create a new release.
        
        Args:
            version: Version string (e.g., "1.0.0")
            title: Release title
            description: Optional release description
            target_date: Optional target release date
            status: Release status (default: PLANNED)
            
        Returns:
            Created release
            
        Raises:
            EntityAlreadyExistsError: If version already exists
        """
        if await self.release_repo.version_exists(version):
            raise EntityAlreadyExistsError("Release", "version", version)
        
        return await self.release_repo.create(
            version=version,
            title=title,
            description=description,
            target_date=target_date,
            status=status,
        )
    
    async def get_release(self, release_id: int) -> Release:
        """Get a release by ID with tasks."""
        release = await self.release_repo.get_with_tasks(release_id)
        if not release:
            raise EntityNotFoundError("Release", release_id)
        return release
    
    async def get_release_by_version(self, version: str) -> Release:
        """Get a release by version string."""
        release = await self.release_repo.get_by_version(version)
        if not release:
            raise EntityNotFoundError("Release", version)
        return release
    
    async def list_releases(
        self,
        skip: int = 0,
        limit: int = 100,
        status: ReleaseStatus | None = None,
    ) -> tuple[list[Release], int]:
        """
        List releases with filtering.
        
        Returns:
            Tuple of (releases, total_count)
        """
        releases = await self.release_repo.get_all_filtered(
            skip=skip,
            limit=limit,
            status=status,
        )
        total = await self.release_repo.count_filtered(status=status)
        return list(releases), total
    
    async def update_release(
        self,
        release_id: int,
        version: str | None = None,
        title: str | None = None,
        description: str | None = None,
        target_date: date | None = None,
        release_date: date | None = None,
        status: ReleaseStatus | None = None,
    ) -> Release:
        """Update a release."""
        release = await self.get_release(release_id)
        
        # Check version uniqueness if being changed
        if version and version != release.version:
            if await self.release_repo.version_exists(version, exclude_id=release_id):
                raise EntityAlreadyExistsError("Release", "version", version)
        
        updates = {}
        if version is not None:
            updates["version"] = version
        if title is not None:
            updates["title"] = title
        if description is not None:
            updates["description"] = description
        if target_date is not None:
            updates["target_date"] = target_date
        if release_date is not None:
            updates["release_date"] = release_date
        if status is not None:
            updates["status"] = status
        
        if updates:
            release = await self.release_repo.update(release, **updates)
        
        return release
    
    async def delete_release(self, release_id: int) -> None:
        """Delete a release."""
        release = await self.get_release(release_id)
        await self.release_repo.delete(release)
