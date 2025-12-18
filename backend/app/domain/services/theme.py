"""
Theme service for strategic initiative management.
"""
from sqlalchemy import update
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities import Theme
from app.domain.exceptions import EntityNotFoundError
from app.domain.repositories import ThemeRepository


class ThemeService:
    """Service for theme management operations."""
    
    def __init__(self, session: AsyncSession):
        self.session = session
        self.theme_repo = ThemeRepository(session)
    
    async def create_theme(
        self,
        title: str,
        description: str | None = None,
        status: str = "active",
    ) -> Theme:
        """
        Create a new theme.
        
        Args:
            title: Theme title
            description: Optional theme description
            status: Theme status (default: active)
            
        Returns:
            Created theme
        """
        return await self.theme_repo.create(
            title=title,
            description=description,
            status=status,
        )
    
    async def get_theme(self, theme_id: int) -> Theme:
        """Get a theme by ID with projects."""
        theme = await self.theme_repo.get_with_projects(theme_id)
        if not theme:
            raise EntityNotFoundError("Theme", theme_id)
        return theme
    
    async def list_themes(
        self,
        skip: int = 0,
        limit: int = 100,
        status: str | None = None,
        include_archived: bool = False,
    ) -> tuple[list[Theme], int]:
        """
        List themes with filtering.
        
        Returns:
            Tuple of (themes, total_count)
        """
        themes = await self.theme_repo.get_all_filtered(
            skip=skip,
            limit=limit,
            status=status,
            include_archived=include_archived,
        )
        total = await self.theme_repo.count_filtered(
            status=status,
            include_archived=include_archived,
        )
        return list(themes), total
    
    async def update_theme(
        self,
        theme_id: int,
        title: str | None = None,
        description: str | None = None,
        status: str | None = None,
    ) -> Theme:
        """Update a theme."""
        theme = await self.get_theme(theme_id)
        
        updates = {}
        if title is not None:
            updates["title"] = title
        if description is not None:
            updates["description"] = description
        if status is not None:
            updates["status"] = status
        
        if updates:
            theme = await self.theme_repo.update(theme, **updates)
        
        return theme
    
    async def delete_theme(self, theme_id: int) -> None:
        """Delete a theme."""
        theme = await self.get_theme(theme_id)
        await self.theme_repo.delete(theme)
    
    async def transition_status(self, old_status: str, new_status: str) -> int:
        """
        Transition all themes from one status to another.
        
        Args:
            old_status: The status to transition from
            new_status: The status to transition to
            
        Returns:
            Number of themes transitioned
        """
        # Normalize to lowercase for case-insensitive matching
        old_status_lower = old_status.lower()
        new_status_lower = new_status.lower()
        
        # Update all themes with the old status
        stmt = (
            update(Theme)
            .where(Theme.status == old_status_lower)
            .values(status=new_status_lower)
        )
        result = await self.session.execute(stmt)
        await self.session.flush()
        
        return result.rowcount
