"""
Theme management API endpoints.
"""
from fastapi import APIRouter, HTTPException, status

from app.api.deps import DbSession, CurrentUser, CurrentAdmin
from app.domain.exceptions import EntityNotFoundError
from app.domain.services import ThemeService
from app.schemas import (
    ThemeCreate,
    ThemeUpdate,
    ThemeResponse,
    ThemeWithProjectsResponse,
    PaginatedResponse,
    MessageResponse,
)

router = APIRouter(prefix="/themes", tags=["Themes"])


@router.get("", response_model=PaginatedResponse[ThemeResponse])
async def list_themes(
    db: DbSession,
    _: CurrentUser,
    skip: int = 0,
    limit: int = 100,
    status_filter: str | None = None,
    include_archived: bool = False,
):
    """List all themes with optional filtering."""
    service = ThemeService(db)
    themes, total = await service.list_themes(
        skip=skip,
        limit=limit,
        status=status_filter,
        include_archived=include_archived,
    )
    return PaginatedResponse(
        items=themes,
        total=total,
        page=skip // limit + 1 if limit else 1,
        page_size=limit,
    )


@router.post("", response_model=ThemeResponse, status_code=status.HTTP_201_CREATED)
async def create_theme(
    data: ThemeCreate,
    db: DbSession,
    _: CurrentUser,
):
    """Create a new theme."""
    service = ThemeService(db)
    theme = await service.create_theme(
        title=data.title,
        description=data.description,
        status=data.status,
    )
    return theme


@router.get("/{theme_id}", response_model=ThemeWithProjectsResponse)
async def get_theme(
    theme_id: int,
    db: DbSession,
    _: CurrentUser,
):
    """Get a theme by ID with its projects."""
    try:
        service = ThemeService(db)
        return await service.get_theme(theme_id)
    except EntityNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.patch("/{theme_id}", response_model=ThemeResponse)
async def update_theme(
    theme_id: int,
    data: ThemeUpdate,
    db: DbSession,
    _: CurrentUser,
):
    """Update a theme."""
    try:
        service = ThemeService(db)
        return await service.update_theme(
            theme_id=theme_id,
            title=data.title,
            description=data.description,
            status=data.status,
        )
    except EntityNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.delete("/{theme_id}", response_model=MessageResponse)
async def delete_theme(
    theme_id: int,
    db: DbSession,
    _: CurrentAdmin,
):
    """Delete a theme. Admin only."""
    try:
        service = ThemeService(db)
        await service.delete_theme(theme_id)
        return MessageResponse(message="Theme deleted successfully")
    except EntityNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
