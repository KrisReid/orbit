"""
Task management API endpoints.
"""
from typing import List

from fastapi import APIRouter, HTTPException, status, Query

from app.api.deps import DbSession, CurrentUser
from app.domain.exceptions import EntityNotFoundError, ValidationError
from app.domain.services import TaskService
from app.schemas import (
    TaskCreate,
    TaskUpdate,
    TaskResponse,
    PaginatedResponse,
    MessageResponse,
)

router = APIRouter(prefix="/tasks", tags=["Tasks"])


@router.get("", response_model=PaginatedResponse[TaskResponse])
async def list_tasks(
    db: DbSession,
    _: CurrentUser,
    skip: int = 0,
    limit: int = 100,
    team_id: int | None = None,
    task_type_id: int | None = None,
    project_id: int | None = None,
    release_id: int | None = None,
    statuses: List[str] | None = Query(None),
):
    """List all tasks with optional filtering."""
    service = TaskService(db)
    tasks, total = await service.list_tasks(
        skip=skip,
        limit=limit,
        team_id=team_id,
        task_type_id=task_type_id,
        project_id=project_id,
        release_id=release_id,
        statuses=statuses,
    )
    return PaginatedResponse(
        items=tasks,
        total=total,
        page=skip // limit + 1 if limit else 1,
        page_size=limit,
    )


@router.post("", response_model=TaskResponse, status_code=status.HTTP_201_CREATED)
async def create_task(
    data: TaskCreate,
    db: DbSession,
    _: CurrentUser,
):
    """Create a new task."""
    try:
        service = TaskService(db)
        task = await service.create_task(
            title=data.title,
            team_id=data.team_id,
            task_type_id=data.task_type_id,
            description=data.description,
            project_id=data.project_id,
            release_id=data.release_id,
            estimation=data.estimation,
            custom_data=data.custom_data,
        )
        return task
    except EntityNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.get("/by-display-id/{display_id}", response_model=TaskResponse)
async def get_task_by_display_id(
    display_id: str,
    db: DbSession,
    _: CurrentUser,
):
    """Get a task by display ID (e.g., CORE-123)."""
    try:
        service = TaskService(db)
        return await service.get_task_by_display_id(display_id)
    except EntityNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.get("/{task_id}", response_model=TaskResponse)
async def get_task(
    task_id: int,
    db: DbSession,
    _: CurrentUser,
):
    """Get a task by ID."""
    try:
        service = TaskService(db)
        return await service.get_task(task_id)
    except EntityNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.patch("/{task_id}", response_model=TaskResponse)
async def update_task(
    task_id: int,
    data: TaskUpdate,
    db: DbSession,
    _: CurrentUser,
):
    """Update a task."""
    try:
        service = TaskService(db)
        return await service.update_task(
            task_id=task_id,
            title=data.title,
            description=data.description,
            status=data.status,
            team_id=data.team_id,
            task_type_id=data.task_type_id,
            project_id=data.project_id,
            release_id=data.release_id,
            estimation=data.estimation,
            custom_data=data.custom_data,
        )
    except EntityNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.delete("/{task_id}", response_model=MessageResponse)
async def delete_task(
    task_id: int,
    db: DbSession,
    _: CurrentUser,
):
    """Delete a task."""
    try:
        service = TaskService(db)
        await service.delete_task(task_id)
        return MessageResponse(message="Task deleted successfully")
    except EntityNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.post("/{task_id}/dependencies/{depends_on_id}", response_model=TaskResponse)
async def add_task_dependency(
    task_id: int,
    depends_on_id: int,
    db: DbSession,
    _: CurrentUser,
):
    """Add a dependency (blocker) to a task."""
    try:
        service = TaskService(db)
        return await service.add_dependency(task_id, depends_on_id)
    except EntityNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except ValidationError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.delete("/{task_id}/dependencies/{depends_on_id}", response_model=TaskResponse)
async def remove_task_dependency(
    task_id: int,
    depends_on_id: int,
    db: DbSession,
    _: CurrentUser,
):
    """Remove a dependency from a task."""
    try:
        service = TaskService(db)
        return await service.remove_dependency(task_id, depends_on_id)
    except EntityNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
