"""
Authentication service for login and user management.
"""
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import verify_password, get_password_hash, create_access_token
from app.domain.entities import User, UserRole
from app.domain.exceptions import AuthenticationError, EntityNotFoundError, EntityAlreadyExistsError
from app.domain.repositories import UserRepository


class AuthService:
    """Service for authentication operations."""
    
    def __init__(self, session: AsyncSession):
        self.session = session
        self.user_repo = UserRepository(session)
    
    async def authenticate(self, email: str, password: str) -> tuple[User, str]:
        """
        Authenticate a user and return user with access token.
        
        Args:
            email: User's email address
            password: User's password
            
        Returns:
            Tuple of (User, access_token)
            
        Raises:
            AuthenticationError: If credentials are invalid
        """
        user = await self.user_repo.get_by_email(email)
        
        if not user:
            raise AuthenticationError("Invalid email or password")
        
        if not verify_password(password, user.hashed_password):
            raise AuthenticationError("Invalid email or password")
        
        if not user.is_active:
            raise AuthenticationError("User account is disabled")
        
        access_token = create_access_token(data={"sub": str(user.id)})
        
        return user, access_token
    
    async def get_current_user(self, user_id: int) -> User:
        """
        Get the current authenticated user.
        
        Args:
            user_id: User ID from token
            
        Returns:
            User entity
            
        Raises:
            EntityNotFoundError: If user not found
            AuthenticationError: If user is inactive
        """
        user = await self.user_repo.get_by_id(user_id)
        
        if not user:
            raise EntityNotFoundError("User", user_id)
        
        if not user.is_active:
            raise AuthenticationError("User account is disabled")
        
        return user


class UserService:
    """Service for user management operations."""
    
    def __init__(self, session: AsyncSession):
        self.session = session
        self.user_repo = UserRepository(session)
    
    async def create_user(
        self,
        email: str,
        password: str,
        full_name: str,
        role: UserRole = UserRole.USER,
    ) -> User:
        """
        Create a new user.
        
        Args:
            email: User's email address
            password: User's password
            full_name: User's full name
            role: User's role (default: USER)
            
        Returns:
            Created user
            
        Raises:
            EntityAlreadyExistsError: If email is already in use
        """
        if await self.user_repo.email_exists(email):
            raise EntityAlreadyExistsError("User", "email", email)
        
        hashed_password = get_password_hash(password)
        
        return await self.user_repo.create(
            email=email,
            hashed_password=hashed_password,
            full_name=full_name,
            role=role,
        )
    
    async def get_user(self, user_id: int) -> User:
        """Get a user by ID."""
        user = await self.user_repo.get_by_id(user_id)
        if not user:
            raise EntityNotFoundError("User", user_id)
        return user
    
    async def list_users(self, skip: int = 0, limit: int = 100) -> list[User]:
        """List all users."""
        users = await self.user_repo.get_all(skip=skip, limit=limit)
        return list(users)
    
    async def update_user(
        self,
        user_id: int,
        full_name: str | None = None,
        role: UserRole | None = None,
        is_active: bool | None = None,
    ) -> User:
        """Update a user."""
        user = await self.get_user(user_id)
        
        updates = {}
        if full_name is not None:
            updates["full_name"] = full_name
        if role is not None:
            updates["role"] = role
        if is_active is not None:
            updates["is_active"] = is_active
        
        if updates:
            user = await self.user_repo.update(user, **updates)
        
        return user
    
    async def delete_user(self, user_id: int) -> None:
        """Delete a user."""
        user = await self.get_user(user_id)
        await self.user_repo.delete(user)
