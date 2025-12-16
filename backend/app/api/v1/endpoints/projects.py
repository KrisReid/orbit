"""
Project management API endpoints.
"""
from typing import List

from fastapi import APIRouter, HTTPException, status, Query

from app.api.deps import DbSession, CurrentUser, CurrentAdmin
from app.domain.exceptions import EntityNotFoundError, ValidationError
from app.domain.services import ProjectService
from app.schemas import (
    ProjectCreate,
    ProjectUpdate,
    ProjectResponse,
    ProjectDetailResponse,
    PaginatedResponse,
    MessageResponse,
)

router = APIRouter(prefix="/projects", tags=["Projects"])


@router.get("", response_model=PaginatedResponse[ProjectResponse])
async def list_projects(
    db: DbSession,
    _: CurrentUser,
    skip: int = 0,
    limit: int = 100,
    project_type_ids: List[int] | None = Query(None),
    theme_id: int | None = None,
    statuses: List[str] | None = Query(None),
):
    """List all projects with optional filtering."""
    service = ProjectService(db)
    projects, total = await service.list_projects(
        skip=skip,
        limit=limit,
        project_type_ids=project_type_ids,
        theme_id=theme_id,
        statuses=statuses,
    )
    return PaginatedResponse(
        items=projects,
        total=total,
        page=skip // limit + 1 if limit else 1,
        page_size=limit,
    )


@router.post("", response_model=ProjectResponse, status_code=status.HTTP_201_CREATED)
async def create_project(
    data: ProjectCreate,
    db: DbSession,
    _: CurrentUser,
):
    """Create a new project."""
    try:
        service = ProjectService(db)
        project = await service.create_project(
            title=data.title,
            project_type_id=data.project_type_id,
            description=data.description,
            theme_id=data.theme_id,
            custom_data=data.custom_data,
        )
        return project
    except EntityNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.get("/{project_id}", response_model=ProjectDetailResponse)
async def get_project(
    project_id: int,
    db: DbSession,
    _: CurrentUser,
):
    """Get a project by ID with all relations."""
    try:
        service = ProjectService(db)
        return await service.get_project(project_id)
    except EntityNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.patch("/{project_id}", response_model=ProjectResponse)
async def update_project(
    project_id: int,
    data: ProjectUpdate,
    db: DbSession,
    _: CurrentUser,
):
    """Update a project.
    
    Note: To unlink a project from a theme, explicitly set theme_id to null.
    This is different from not providing the field at all.
    """
    try:
        service = ProjectService(db)
        
        # Build update kwargs only from fields that were explicitly provided
        # This allows distinguishing between "not provided" and "explicitly null"
        update_kwargs: dict = {"project_id": project_id}
        
        if "title" in data.model_fields_set:
            update_kwargs["title"] = data.title
        if "description" in data.model_fields_set:
            update_kwargs["description"] = data.description
        if "status" in data.model_fields_set:
            update_kwargs["status"] = data.status
        if "theme_id" in data.model_fields_set:
            # theme_id was explicitly provided (could be an int or null)
            update_kwargs["theme_id"] = data.theme_id
            update_kwargs["clear_theme"] = data.theme_id is None
        if "custom_data" in data.model_fields_set:
            update_kwargs["custom_data"] = data.custom_data
        
        return await service.update_project(**update_kwargs)
    except EntityNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.delete("/{project_id}", response_model=MessageResponse)
async def delete_project(
    project_id: int,
    db: DbSession,
    _: CurrentAdmin,
):
    """Delete a project. Admin only."""
    try:
        service = ProjectService(db)
        await service.delete_project(project_id)
        return MessageResponse(message="Project deleted successfully")
    except EntityNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.post("/{project_id}/dependencies/{depends_on_id}", response_model=ProjectDetailResponse)
async def add_project_dependency(
    project_id: int,
    depends_on_id: int,
    db: DbSession,
    _: CurrentUser,
):
    """Add a dependency to a project."""
    try:
        service = ProjectService(db)
        return await service.add_dependency(project_id, depends_on_id)
    except EntityNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except ValidationError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.delete("/{project_id}/dependencies/{depends_on_id}", response_model=ProjectDetailResponse)
async def remove_project_dependency(
    project_id: int,
    depends_on_id: int,
    db: DbSession,
    _: CurrentUser,
):
    """Remove a dependency from a project."""
    try:
        service = ProjectService(db)
        return await service.remove_dependency(project_id, depends_on_id)
    except EntityNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
