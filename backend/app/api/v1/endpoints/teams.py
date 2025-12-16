"""
Team management API endpoints.
"""
from fastapi import APIRouter, HTTPException, status

from app.api.deps import DbSession, CurrentUser, CurrentAdmin
from app.domain.exceptions import EntityNotFoundError, EntityAlreadyExistsError, ValidationError
from app.domain.services import TeamService
from app.schemas import (
    TeamCreate,
    TeamUpdate,
    TeamResponse,
    TeamStatsResponse,
    PaginatedResponse,
    MessageResponse,
)

router = APIRouter(prefix="/teams", tags=["Teams"])


@router.get("", response_model=PaginatedResponse[TeamResponse])
async def list_teams(
    db: DbSession,
    _: CurrentUser,
    skip: int = 0,
    limit: int = 100,
):
    """List all teams."""
    service = TeamService(db)
    teams = await service.list_teams(skip=skip, limit=limit)
    return PaginatedResponse(
        items=teams,
        total=len(teams),
        page=skip // limit + 1 if limit else 1,
        page_size=limit,
    )


@router.post("", response_model=TeamResponse, status_code=status.HTTP_201_CREATED)
async def create_team(
    data: TeamCreate,
    db: DbSession,
    _: CurrentAdmin,
):
    """Create a new team. Admin only."""
    try:
        service = TeamService(db)
        team = await service.create_team(
            name=data.name,
            description=data.description,
            slug=data.slug,
        )
        return team
    except EntityAlreadyExistsError as e:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(e))


@router.get("/{team_id}", response_model=TeamResponse)
async def get_team(
    team_id: int,
    db: DbSession,
    _: CurrentUser,
):
    """Get a team by ID."""
    try:
        service = TeamService(db)
        return await service.get_team(team_id)
    except EntityNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.get("/slug/{slug}", response_model=TeamResponse)
async def get_team_by_slug(
    slug: str,
    db: DbSession,
    _: CurrentUser,
):
    """Get a team by slug."""
    try:
        service = TeamService(db)
        return await service.get_team_by_slug(slug)
    except EntityNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.patch("/{team_id}", response_model=TeamResponse)
async def update_team(
    team_id: int,
    data: TeamUpdate,
    db: DbSession,
    _: CurrentAdmin,
):
    """Update a team. Admin only."""
    try:
        service = TeamService(db)
        return await service.update_team(
            team_id=team_id,
            name=data.name,
            description=data.description,
            slug=data.slug,
        )
    except EntityNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except EntityAlreadyExistsError as e:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(e))


@router.delete("/{team_id}", response_model=MessageResponse)
async def delete_team(
    team_id: int,
    db: DbSession,
    _: CurrentAdmin,
):
    """Delete a team. Admin only."""
    try:
        service = TeamService(db)
        await service.delete_team(team_id)
        return MessageResponse(message="Team deleted successfully")
    except EntityNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.get("/{team_id}/stats", response_model=TeamStatsResponse)
async def get_team_stats(
    team_id: int,
    db: DbSession,
    _: CurrentUser,
):
    """Get team task statistics."""
    try:
        service = TeamService(db)
        return await service.get_team_stats(team_id)
    except EntityNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.post("/{team_id}/members/{user_id}", response_model=TeamResponse)
async def add_team_member(
    team_id: int,
    user_id: int,
    db: DbSession,
    _: CurrentAdmin,
):
    """Add a member to a team. Admin only."""
    try:
        service = TeamService(db)
        return await service.add_member(team_id, user_id)
    except EntityNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except ValidationError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.delete("/{team_id}/members/{user_id}", response_model=TeamResponse)
async def remove_team_member(
    team_id: int,
    user_id: int,
    db: DbSession,
    _: CurrentAdmin,
):
    """Remove a member from a team. Admin only."""
    try:
        service = TeamService(db)
        return await service.remove_member(team_id, user_id)
    except EntityNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except ValidationError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
