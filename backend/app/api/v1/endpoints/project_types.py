"""
Project Types API.
"""
from fastapi import APIRouter, HTTPException, status, Query
from app.api.deps import DbSession, CurrentUser, CurrentAdmin
from app.domain.services import ProjectTypeService
from app.domain.exceptions import EntityNotFoundError, EntityAlreadyExistsError
from app.schemas import (
    ProjectTypeCreate, ProjectTypeUpdate, ProjectTypeResponse,
    PaginatedResponse, MessageResponse, EntityStatsResponse, MigrationRequest,
    CustomFieldCreate, CustomFieldResponse, CustomFieldUpdate
)

router = APIRouter(prefix="/project-types", tags=["Project Types"])

@router.get("", response_model=PaginatedResponse[ProjectTypeResponse])
async def list_project_types(db: DbSession, _: CurrentUser, skip: int = 0, limit: int = 100):
    service = ProjectTypeService(db)
    items, total = await service.list_project_types(skip=skip, limit=limit)
    return PaginatedResponse(items=items, total=total, page=skip // limit + 1, page_size=limit)

@router.post("", response_model=ProjectTypeResponse, status_code=status.HTTP_201_CREATED)
async def create_project_type(data: ProjectTypeCreate, db: DbSession, _: CurrentAdmin):
    try:
        service = ProjectTypeService(db)
        fields_dict = [f.model_dump() for f in data.fields] if data.fields else None
        return await service.create_project_type(
            name=data.name, workflow=data.workflow, description=data.description, 
            color=data.color, slug=data.slug, fields=fields_dict
        )
    except EntityAlreadyExistsError as e:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(e))

@router.get("/{id}", response_model=ProjectTypeResponse)
async def get_project_type(id: int, db: DbSession, _: CurrentUser):
    try:
        service = ProjectTypeService(db)
        return await service.get_project_type(id)
    except EntityNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))

@router.patch("/{id}", response_model=ProjectTypeResponse)
async def update_project_type(id: int, data: ProjectTypeUpdate, db: DbSession, _: CurrentAdmin):
    try:
        service = ProjectTypeService(db)
        fields_dict = [f.model_dump() for f in data.fields] if data.fields else None
        return await service.update_project_type(
            project_type_id=id, name=data.name, description=data.description,
            workflow=data.workflow, color=data.color, fields=fields_dict
        )
    except EntityNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))

@router.delete("/{id}", response_model=MessageResponse)
async def delete_project_type(id: int, db: DbSession, _: CurrentAdmin):
    try:
        service = ProjectTypeService(db)
        await service.delete_project_type(id)
        return MessageResponse(message="Project type deleted successfully")
    except EntityNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))

@router.get("/{id}/stats", response_model=EntityStatsResponse)
async def get_project_type_stats(id: int, db: DbSession, _: CurrentUser):
    """Used by UI Settings to show impact before deletion/migration."""
    try:
        service = ProjectTypeService(db)
        return await service.get_stats(id)
    except EntityNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))

@router.post("/{id}/migrate", response_model=MessageResponse)
async def migrate_project_type(id: int, data: MigrationRequest, db: DbSession, _: CurrentAdmin):
    """Migrates projects to a new type so this one can be safely deleted."""
    try:
        service = ProjectTypeService(db)
        status_map = {m.old_status: m.new_status for m in data.status_mappings}
        count = await service.migrate_projects(id, data.target_id, status_map)
        return MessageResponse(message=f"Successfully migrated {count} projects.")
    except EntityNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


# ============================================
# Field Management Endpoints
# ============================================

@router.post("/{id}/fields", response_model=CustomFieldResponse, status_code=status.HTTP_201_CREATED)
async def add_field(id: int, data: CustomFieldCreate, db: DbSession, _: CurrentAdmin):
    """Add a custom field to a project type."""
    try:
        service = ProjectTypeService(db)
        return await service.add_field(
            project_type_id=id,
            key=data.key,
            label=data.label,
            field_type=data.field_type,
            options=data.options,
            required=data.required,
            order=data.order
        )
    except EntityNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except EntityAlreadyExistsError as e:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(e))

@router.patch("/{id}/fields/{field_id}", response_model=CustomFieldResponse)
async def update_field(id: int, field_id: int, data: CustomFieldUpdate, db: DbSession, _: CurrentAdmin):
    """Update a custom field on a project type."""
    try:
        service = ProjectTypeService(db)
        return await service.update_field(
            project_type_id=id,
            field_id=field_id,
            label=data.label,
            options=data.options,
            required=data.required,
            order=data.order
        )
    except EntityNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))

@router.delete("/{id}/fields/{field_id}", response_model=MessageResponse)
async def delete_field(id: int, field_id: int, db: DbSession, _: CurrentAdmin):
    """Delete a custom field from a project type."""
    try:
        service = ProjectTypeService(db)
        await service.delete_field(project_type_id=id, field_id=field_id)
        return MessageResponse(message="Field deleted successfully")
    except EntityNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
