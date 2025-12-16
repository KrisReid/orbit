"""
Release management API endpoints.
"""
from fastapi import APIRouter, HTTPException, status

from app.api.deps import DbSession, CurrentUser, CurrentAdmin
from app.domain.entities import ReleaseStatus
from app.domain.exceptions import EntityNotFoundError, EntityAlreadyExistsError
from app.domain.services import ReleaseService
from app.schemas import (
    ReleaseCreate,
    ReleaseUpdate,
    ReleaseResponse,
    PaginatedResponse,
    MessageResponse,
)

router = APIRouter(prefix="/releases", tags=["Releases"])


@router.get("", response_model=PaginatedResponse[ReleaseResponse])
async def list_releases(
    db: DbSession,
    _: CurrentUser,
    skip: int = 0,
    limit: int = 100,
    status_filter: ReleaseStatus | None = None,
):
    """List all releases with optional filtering."""
    service = ReleaseService(db)
    releases, total = await service.list_releases(
        skip=skip,
        limit=limit,
        status=status_filter,
    )
    return PaginatedResponse(
        items=releases,
        total=total,
        page=skip // limit + 1 if limit else 1,
        page_size=limit,
    )


@router.post("", response_model=ReleaseResponse, status_code=status.HTTP_201_CREATED)
async def create_release(
    data: ReleaseCreate,
    db: DbSession,
    _: CurrentUser,
):
    """Create a new release."""
    try:
        service = ReleaseService(db)
        release = await service.create_release(
            version=data.version,
            title=data.title,
            description=data.description,
            target_date=data.target_date,
            status=data.status,
        )
        return release
    except EntityAlreadyExistsError as e:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(e))


@router.get("/{release_id}", response_model=ReleaseResponse)
async def get_release(
    release_id: int,
    db: DbSession,
    _: CurrentUser,
):
    """Get a release by ID."""
    try:
        service = ReleaseService(db)
        return await service.get_release(release_id)
    except EntityNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.patch("/{release_id}", response_model=ReleaseResponse)
async def update_release(
    release_id: int,
    data: ReleaseUpdate,
    db: DbSession,
    _: CurrentUser,
):
    """Update a release."""
    try:
        service = ReleaseService(db)
        return await service.update_release(
            release_id=release_id,
            version=data.version,
            title=data.title,
            description=data.description,
            target_date=data.target_date,
            release_date=data.release_date,
            status=data.status,
        )
    except EntityNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except EntityAlreadyExistsError as e:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(e))


@router.delete("/{release_id}", response_model=MessageResponse)
async def delete_release(
    release_id: int,
    db: DbSession,
    _: CurrentAdmin,
):
    """Delete a release. Admin only."""
    try:
        service = ReleaseService(db)
        await service.delete_release(release_id)
        return MessageResponse(message="Release deleted successfully")
    except EntityNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
