"""
Project repository for database operations.
"""
from typing import Sequence

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.domain.entities import Project, ProjectType, ProjectTypeField
from app.domain.repositories.base import BaseRepository


class ProjectTypeRepository(BaseRepository[ProjectType]):
    """Repository for ProjectType entity operations."""
    
    def __init__(self, session: AsyncSession):
        super().__init__(ProjectType, session)
    
    async def get_by_slug(self, slug: str) -> ProjectType | None:
        """Get a project type by slug."""
        query = (
            select(ProjectType)
            .where(ProjectType.slug == slug)
            .options(selectinload(ProjectType.fields))
        )
        result = await self.session.execute(query)
        return result.scalar_one_or_none()
    
    async def get_with_fields(self, id: int) -> ProjectType | None:
        """Get a project type with fields eagerly loaded."""
        query = (
            select(ProjectType)
            .where(ProjectType.id == id)
            .options(selectinload(ProjectType.fields))
        )
        result = await self.session.execute(query)
        return result.scalar_one_or_none()
    
    async def get_all_with_fields(
        self,
        skip: int = 0,
        limit: int = 100,
    ) -> Sequence[ProjectType]:
        """Get all project types with fields."""
        query = (
            select(ProjectType)
            .options(selectinload(ProjectType.fields))
            .offset(skip)
            .limit(limit)
        )
        result = await self.session.execute(query)
        return result.scalars().all()
    
    async def slug_exists(self, slug: str, exclude_id: int | None = None) -> bool:
        """Check if slug is already in use."""
        query = select(ProjectType.id).where(ProjectType.slug == slug)
        if exclude_id:
            query = query.where(ProjectType.id != exclude_id)
        result = await self.session.execute(query)
        return result.scalar_one_or_none() is not None
    
    async def add_field(self, project_type_id: int, **kwargs) -> ProjectTypeField:
        """Add a field to a project type."""
        field = ProjectTypeField(project_type_id=project_type_id, **kwargs)
        self.session.add(field)
        await self.session.flush()
        await self.session.refresh(field)
        return field
    
    async def update_fields(
        self,
        project_type_id: int,
        fields_data: list[dict]
    ) -> list[ProjectTypeField]:
        """Replace all fields for a project type."""
        # Delete existing fields
        from sqlalchemy import delete
        await self.session.execute(
            delete(ProjectTypeField).where(
                ProjectTypeField.project_type_id == project_type_id
            )
        )
        
        # Create new fields
        fields = []
        for i, field_data in enumerate(fields_data):
            field = ProjectTypeField(
                project_type_id=project_type_id,
                order=i,
                **field_data
            )
            self.session.add(field)
            fields.append(field)
        
        await self.session.flush()
        return fields
    
    async def field_key_exists(self, project_type_id: int, key: str) -> bool:
        """Check if a field key already exists for a project type."""
        query = select(ProjectTypeField.id).where(
            ProjectTypeField.project_type_id == project_type_id,
            ProjectTypeField.key == key
        )
        result = await self.session.execute(query)
        return result.scalar_one_or_none() is not None
    
    async def get_field(self, project_type_id: int, field_id: int) -> ProjectTypeField | None:
        """Get a specific field by ID."""
        query = select(ProjectTypeField).where(
            ProjectTypeField.id == field_id,
            ProjectTypeField.project_type_id == project_type_id
        )
        result = await self.session.execute(query)
        return result.scalar_one_or_none()
    
    async def update_field_by_id(
        self,
        field_id: int,
        label: str | None = None,
        options: list[str] | None = None,
        required: bool | None = None,
        order: int | None = None
    ) -> ProjectTypeField:
        """Update a field by ID."""
        query = select(ProjectTypeField).where(ProjectTypeField.id == field_id)
        result = await self.session.execute(query)
        field = result.scalar_one_or_none()
        
        if field:
            if label is not None:
                field.label = label
            if options is not None:
                field.options = options
            if required is not None:
                field.required = required
            if order is not None:
                field.order = order
            await self.session.flush()
            await self.session.refresh(field)
        
        return field
    
    async def delete_field(self, field_id: int) -> None:
        """Delete a field by ID."""
        from sqlalchemy import delete
        await self.session.execute(
            delete(ProjectTypeField).where(ProjectTypeField.id == field_id)
        )
        await self.session.flush()


class ProjectRepository(BaseRepository[Project]):
    """Repository for Project entity operations."""
    
    def __init__(self, session: AsyncSession):
        super().__init__(Project, session)
    
    async def get_with_relations(self, id: int) -> Project | None:
        """Get a project with all relations eagerly loaded."""
        query = (
            select(Project)
            .where(Project.id == id)
            .options(
                selectinload(Project.project_type).selectinload(ProjectType.fields),
                selectinload(Project.theme),
                selectinload(Project.tasks),
                selectinload(Project.dependencies),
                selectinload(Project.dependents),
            )
        )
        result = await self.session.execute(query)
        return result.scalar_one_or_none()
    
    async def get_all_filtered(
        self,
        skip: int = 0,
        limit: int = 100,
        project_type_ids: list[int] | None = None,
        theme_id: int | None = None,
        statuses: list[str] | None = None,
    ) -> Sequence[Project]:
        """Get projects with optional filtering."""
        query = (
            select(Project)
            .options(
                selectinload(Project.project_type),
                selectinload(Project.theme),
            )
        )
        
        if project_type_ids:
            query = query.where(Project.project_type_id.in_(project_type_ids))
        
        if theme_id:
            query = query.where(Project.theme_id == theme_id)
        
        if statuses:
            query = query.where(Project.status.in_(statuses))
        
        query = query.order_by(Project.updated_at.desc()).offset(skip).limit(limit)
        result = await self.session.execute(query)
        return result.scalars().all()
    
    async def count_filtered(
        self,
        project_type_ids: list[int] | None = None,
        theme_id: int | None = None,
        statuses: list[str] | None = None,
    ) -> int:
        """Count projects with optional filtering."""
        query = select(func.count()).select_from(Project)
        
        if project_type_ids:
            query = query.where(Project.project_type_id.in_(project_type_ids))
        
        if theme_id:
            query = query.where(Project.theme_id == theme_id)
        
        if statuses:
            query = query.where(Project.status.in_(statuses))
        
        result = await self.session.execute(query)
        return result.scalar_one()
    
    async def add_dependency(self, project_id: int, depends_on_id: int) -> None:
        """Add a dependency to a project."""
        project = await self.get_by_id(project_id, [Project.dependencies])
        if project:
            depends_on = await self.get_by_id(depends_on_id)
            if depends_on and depends_on not in project.dependencies:
                project.dependencies.append(depends_on)
                await self.session.flush()
    
    async def remove_dependency(self, project_id: int, depends_on_id: int) -> None:
        """Remove a dependency from a project."""
        project = await self.get_by_id(project_id, [Project.dependencies])
        if project:
            depends_on = await self.get_by_id(depends_on_id)
            if depends_on and depends_on in project.dependencies:
                project.dependencies.remove(depends_on)
                await self.session.flush()
