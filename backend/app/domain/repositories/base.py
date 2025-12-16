"""
Base repository with common CRUD operations.

Provides a generic repository pattern implementation that can be
extended for specific entity types.
"""
from typing import TypeVar, Generic, Type, Sequence, Any

from sqlalchemy import select, func, Select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.database import Base

ModelType = TypeVar("ModelType", bound=Base)


class BaseRepository(Generic[ModelType]):
    """
    Generic repository for common CRUD operations.
    
    Extend this class for entity-specific operations.
    """
    
    def __init__(self, model: Type[ModelType], session: AsyncSession):
        self.model = model
        self.session = session
    
    async def get_by_id(
        self, 
        id: int, 
        load_relations: list[Any] | None = None
    ) -> ModelType | None:
        """
        Get a single entity by ID.
        
        Args:
            id: Primary key value
            load_relations: Optional list of relationships to eagerly load
            
        Returns:
            Entity if found, None otherwise
        """
        query = select(self.model).where(self.model.id == id)
        
        if load_relations:
            for relation in load_relations:
                query = query.options(selectinload(relation))
        
        result = await self.session.execute(query)
        return result.scalar_one_or_none()
    
    async def get_all(
        self,
        skip: int = 0,
        limit: int = 100,
        load_relations: list[Any] | None = None,
    ) -> Sequence[ModelType]:
        """
        Get all entities with pagination.
        
        Args:
            skip: Number of records to skip
            limit: Maximum number of records to return
            load_relations: Optional list of relationships to eagerly load
            
        Returns:
            List of entities
        """
        query = select(self.model).offset(skip).limit(limit)
        
        if load_relations:
            for relation in load_relations:
                query = query.options(selectinload(relation))
        
        result = await self.session.execute(query)
        return result.scalars().all()
    
    async def count(self) -> int:
        """Get total count of entities."""
        query = select(func.count()).select_from(self.model)
        result = await self.session.execute(query)
        return result.scalar_one()
    
    async def create(self, **kwargs) -> ModelType:
        """
        Create a new entity.
        
        Args:
            **kwargs: Entity field values
            
        Returns:
            Created entity
        """
        entity = self.model(**kwargs)
        self.session.add(entity)
        await self.session.flush()
        await self.session.refresh(entity)
        return entity
    
    async def update(self, entity: ModelType, **kwargs) -> ModelType:
        """
        Update an existing entity.
        
        Args:
            entity: Entity to update
            **kwargs: Field values to update
            
        Returns:
            Updated entity
        """
        for key, value in kwargs.items():
            if hasattr(entity, key):
                setattr(entity, key, value)
        
        await self.session.flush()
        await self.session.refresh(entity)
        return entity
    
    async def delete(self, entity: ModelType) -> None:
        """
        Delete an entity.
        
        Args:
            entity: Entity to delete
        """
        await self.session.delete(entity)
        await self.session.flush()
    
    async def delete_by_id(self, id: int) -> bool:
        """
        Delete an entity by ID.
        
        Args:
            id: Primary key value
            
        Returns:
            True if entity was deleted, False if not found
        """
        entity = await self.get_by_id(id)
        if entity:
            await self.delete(entity)
            return True
        return False
    
    def _apply_filters(self, query: Select, **filters) -> Select:
        """
        Apply filters to a query.
        
        Override this method in subclasses for entity-specific filtering.
        """
        for key, value in filters.items():
            if value is not None and hasattr(self.model, key):
                query = query.where(getattr(self.model, key) == value)
        return query
