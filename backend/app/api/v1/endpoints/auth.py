"""
Authentication API endpoints.
"""
from fastapi import APIRouter, HTTPException, status

from app.api.deps import DbSession, CurrentUser
from app.domain.exceptions import AuthenticationError
from app.domain.services import AuthService
from app.schemas import Token, LoginRequest, UserResponse

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/login", response_model=Token)
async def login(
    credentials: LoginRequest,
    db: DbSession,
):
    """
    Authenticate user and return access token.
    
    Use these credentials for the seeded test user:
    - email: admin@orbit.example.com
    - password: admin123
    """
    try:
        auth_service = AuthService(db)
        user, access_token = await auth_service.authenticate(
            email=credentials.email,
            password=credentials.password,
        )
        return Token(access_token=access_token)
    except AuthenticationError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e),
            headers={"WWW-Authenticate": "Bearer"},
        )


@router.get("/me", response_model=UserResponse)
async def get_current_user_info(
    current_user: CurrentUser,
):
    """Get current authenticated user information."""
    return current_user
