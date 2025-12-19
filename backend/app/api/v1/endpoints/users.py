"""
Users API Endpoints.
"""

from typing import Any
from fastapi import APIRouter, HTTPException, status

from app.api.deps import DbSession, CurrentUser, CurrentAdmin
from app.core.security import get_password_hash
from app.domain.repositories import UserRepository
from app.schemas import UserResponse, UserCreate, UserUpdate, PaginatedResponse

router = APIRouter(prefix="/users", tags=["Users"])


@router.get("", response_model=PaginatedResponse[UserResponse])
async def list_users(
    db: DbSession, _: CurrentAdmin, skip: int = 0, limit: int = 100
) -> Any:
    repo = UserRepository(db)
    items = await repo.get_all(skip=skip, limit=limit)
    total = await repo.count()
    return PaginatedResponse(
        items=items, total=total, page=skip // limit + 1, page_size=limit
    )


@router.post("", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def create_user(data: UserCreate, db: DbSession, _: CurrentAdmin) -> Any:
    repo = UserRepository(db)
    user = await repo.get_by_email(data.email)
    if user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="The user with this email already exists in the system.",
        )

    user = await repo.create(
        email=data.email,
        full_name=data.full_name,
        hashed_password=get_password_hash(data.password),
        role=data.role,
    )
    return user


@router.get("/me", response_model=UserResponse)
async def read_user_me(
    current_user: CurrentUser,
) -> Any:
    return current_user


@router.patch("/me", response_model=UserResponse)
async def update_user_me(
    data: UserUpdate,
    db: DbSession,
    current_user: CurrentUser,
) -> Any:
    repo = UserRepository(db)

    updates = data.model_dump(exclude_unset=True)
    if "password" in updates:
        updates["hashed_password"] = get_password_hash(updates.pop("password"))

    user = await repo.update(current_user, **updates)
    return user


@router.get("/{user_id}", response_model=UserResponse)
async def read_user_by_id(
    user_id: int,
    db: DbSession,
    _: CurrentUser,
) -> Any:
    repo = UserRepository(db)
    user = await repo.get_by_id(user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )
    return user


@router.patch("/{user_id}", response_model=UserResponse)
async def update_user(
    user_id: int,
    data: UserUpdate,
    db: DbSession,
    _: CurrentAdmin,
) -> Any:
    repo = UserRepository(db)
    user = await repo.get_by_id(user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )

    updates = data.model_dump(exclude_unset=True)
    if "password" in updates:
        updates["hashed_password"] = get_password_hash(updates.pop("password"))

    user = await repo.update(user, **updates)
    return user


@router.delete("/{user_id}")
async def delete_user(
    user_id: int,
    db: DbSession,
    current_user: CurrentAdmin,
) -> Any:
    """Delete a user by ID. Admins cannot delete themselves."""
    repo = UserRepository(db)
    user = await repo.get_by_id(user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )

    # Prevent admins from deleting themselves
    if user.id == current_user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot delete your own account",
        )

    await repo.delete(user)
    return {"message": "User deleted successfully"}
