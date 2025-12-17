"""
Task type management API endpoints.
"""
from fastapi import APIRouter, HTTPException, status

from app.api.deps import DbSession, CurrentUser, CurrentAdmin
from app.domain.exceptions import EntityNotFoundError
from app.domain.services import TaskTypeService
from app.schemas import (
    TaskTypeCreate,
    TaskTypeUpdate,
    TaskTypeResponse,
    PaginatedResponse,
    MessageResponse,
)

router = APIRouter(prefix="/task-types", tags=["Task Types"])


@router.get("", response_model=PaginatedResponse[TaskTypeResponse])
async def list_task_types(
    db: DbSession,
    _: CurrentUser,
    skip: int = 0,
    limit: int = 100,
    team_id: int | None = None,
):
    """List all task types with optional team filter."""
    service = TaskTypeService(db)
    task_types, total = await service.list_task_types(
        skip=skip,
        limit=limit,
        team_id=team_id,
    )
    return PaginatedResponse(
        items=task_types,
        total=total,
        page=skip // limit + 1 if limit else 1,
        page_size=limit,
    )


@router.post("", response_model=TaskTypeResponse, status_code=status.HTTP_201_CREATED)
async def create_task_type(
    data: TaskTypeCreate,
    db: DbSession,
    _: CurrentAdmin,
):
    """Create a new task type. Admin only.
    
    The team_id is now included in the request body.
    """
    try:
        service = TaskTypeService(db)
        # Convert field schemas to dicts
        fields = None
        if data.fields:
            fields = [f.model_dump() for f in data.fields]
        
        task_type = await service.create_task_type(
            name=data.name,
            team_id=data.team_id,
            workflow=data.workflow,
            description=data.description,
            color=data.color,
            slug=data.slug,
            fields=fields,
        )
        return task_type
    except EntityNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.get("/{task_type_id}", response_model=TaskTypeResponse)
async def get_task_type(
    task_type_id: int,
    db: DbSession,
    _: CurrentUser,
):
    """Get a task type by ID."""
    try:
        service = TaskTypeService(db)
        return await service.get_task_type(task_type_id)
    except EntityNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.patch("/{task_type_id}", response_model=TaskTypeResponse)
async def update_task_type(
    task_type_id: int,
    data: TaskTypeUpdate,
    db: DbSession,
    _: CurrentAdmin,
):
    """Update a task type. Admin only."""
    try:
        service = TaskTypeService(db)
        # Convert field schemas to dicts
        fields = None
        if data.fields:
            fields = [f.model_dump() for f in data.fields]
        
        return await service.update_task_type(
            task_type_id=task_type_id,
            name=data.name,
            description=data.description,
            workflow=data.workflow,
            color=data.color,
            fields=fields,
        )
    except EntityNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.delete("/{task_type_id}", response_model=MessageResponse)
async def delete_task_type(
    task_type_id: int,
    db: DbSession,
    _: CurrentAdmin,
):
    """Delete a task type. Admin only."""
    try:
        service = TaskTypeService(db)
        await service.delete_task_type(task_type_id)
        return MessageResponse(message="Task type deleted successfully")
    except EntityNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
