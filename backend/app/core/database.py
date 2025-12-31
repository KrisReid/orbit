"""
Database configuration and session management.

Provides async SQLAlchemy engine and session factory with proper
connection pooling and lifecycle management.
"""

from collections.abc import AsyncGenerator
from contextlib import asynccontextmanager

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import declarative_base

from app.core.config import settings

# Create async engine with connection pooling
engine = create_async_engine(
    settings.DATABASE_URL,
    echo=settings.DATABASE_ECHO,
    pool_pre_ping=True,
    pool_size=5,
    max_overflow=10,
)

# Session factory
AsyncSessionLocal = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)

# Base class for all models
Base = declarative_base()


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """
    Dependency that provides a database session.

    Yields a session that is automatically closed after use.
    Use with FastAPI's Depends() for automatic injection.
    """
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


@asynccontextmanager
async def get_db_context() -> AsyncGenerator[AsyncSession, None]:
    """
    Context manager for database sessions outside of request context.

    Useful for background tasks, CLI commands, and testing.
    """
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


async def init_db() -> None:
    """Initialize database tables and create default admin user if none exists."""
    # Import all models to register them with Base.metadata
    from app.domain.entities import (  # noqa: F401
        User,
        UserRole,
        Team,
        TeamMember,
        Theme,
        ProjectType,
        Project,
        TaskType,
        Task,
        Release,
    )

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    # Create default admin user if no users exist
    await _create_default_admin()


async def _create_default_admin() -> None:
    """Create a default admin user if the database is empty."""
    from sqlalchemy import select
    from app.domain.entities import User, UserRole
    from app.core.security import get_password_hash
    from app.core.config import settings
    
    async with AsyncSessionLocal() as session:
        # Check if any users exist
        result = await session.execute(select(User).limit(1))
        if result.scalar_one_or_none() is not None:
            return  # Users already exist, skip
        
        # Get admin credentials from environment or use defaults
        admin_email = settings.DEFAULT_ADMIN_EMAIL
        admin_password = settings.DEFAULT_ADMIN_PASSWORD
        
        if not admin_email or not admin_password:
            return  # No default credentials configured
        
        # Create admin user
        admin = User(
            email=admin_email,
            hashed_password=get_password_hash(admin_password),
            full_name="Admin User",
            role=UserRole.ADMIN,
            is_active=True,
        )
        session.add(admin)
        await session.commit()
        print(f"✅ Created default admin user: {admin_email}")


async def close_db() -> None:
    """Close database connections."""
    await engine.dispose()
