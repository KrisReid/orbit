"""
Pytest configuration and fixtures for backend tests.

Provides shared fixtures for database sessions, test client, and common test data.
Uses the same PostgreSQL database as production for integration tests (with rollback).
"""

import os
from typing import AsyncGenerator
from unittest.mock import AsyncMock, MagicMock

import pytest
import pytest_asyncio
from fastapi import FastAPI
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.core.database import Base, get_db
from app.core.security import get_password_hash, create_access_token
from app.domain.entities import (
    User,
    UserRole,
    Team,
    ProjectType,
    TaskType,
    Project,
    Theme,
    Task,
)
from app.main import app


# Test database URL - uses same PostgreSQL but with test database
# Can be overridden with TEST_DATABASE_URL environment variable
# Default uses orbit credentials from docker-compose
DEFAULT_TEST_DB_URL = (
    "postgresql+asyncpg://orbit:orbit_secret@localhost:5432/orbit_test"
)
TEST_DATABASE_URL = os.environ.get("TEST_DATABASE_URL", DEFAULT_TEST_DB_URL)


# Check database availability once at module load
def _check_database_available() -> bool:
    """Check if the test database is available."""
    import asyncio
    from sqlalchemy import text
    from sqlalchemy.ext.asyncio import create_async_engine

    async def _check():
        try:
            engine = create_async_engine(TEST_DATABASE_URL, pool_pre_ping=True)
            async with engine.connect() as conn:
                await conn.execute(text("SELECT 1"))
            await engine.dispose()
            return True
        except Exception:
            return False

    try:
        # Create a new event loop for the check
        loop = asyncio.new_event_loop()
        result = loop.run_until_complete(_check())
        loop.close()
        return result
    except Exception:
        return False


# Run check once
DATABASE_AVAILABLE = _check_database_available()

# Skip marker for integration tests when database is unavailable
requires_db = pytest.mark.skipif(
    not DATABASE_AVAILABLE, reason="Database not available - skipping integration tests"
)


# Create tables once at session start using synchronous approach
def _setup_database():
    """Create database tables using sync engine."""
    if not DATABASE_AVAILABLE:
        return

    # Convert async URL to sync URL for initial setup
    sync_url = TEST_DATABASE_URL.replace("+asyncpg", "")

    from sqlalchemy import create_engine

    engine = create_engine(sync_url)
    Base.metadata.create_all(engine)
    engine.dispose()


def _teardown_database():
    """Drop database tables using sync engine."""
    if not DATABASE_AVAILABLE:
        return

    sync_url = TEST_DATABASE_URL.replace("+asyncpg", "")

    from sqlalchemy import create_engine

    engine = create_engine(sync_url)
    Base.metadata.drop_all(engine)
    engine.dispose()


# Setup tables at module load
_setup_database()


# Cleanup at session end
@pytest.fixture(scope="session", autouse=True)
def cleanup_database():
    """Cleanup database tables at end of test session."""
    yield
    _teardown_database()


@pytest_asyncio.fixture(scope="function")
async def db_session() -> AsyncGenerator[AsyncSession, None]:
    """
    Create async test database session with transaction rollback.

    Each test runs in its own transaction that is rolled back,
    ensuring test isolation without database cleanup overhead.
    """
    if not DATABASE_AVAILABLE:
        pytest.skip("Database not available")

    engine = create_async_engine(
        TEST_DATABASE_URL,
        echo=False,
        pool_pre_ping=True,
    )

    async_session_factory = async_sessionmaker(
        engine,
        class_=AsyncSession,
        expire_on_commit=False,
        autocommit=False,
        autoflush=False,
    )

    async with async_session_factory() as session:
        async with session.begin():
            yield session
            await session.rollback()

    await engine.dispose()


@pytest_asyncio.fixture(scope="function")
async def test_app(db_session: AsyncSession) -> FastAPI:
    """Create test FastAPI application with overridden dependencies."""

    async def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    yield app
    app.dependency_overrides.clear()


@pytest_asyncio.fixture(scope="function")
async def client(test_app: FastAPI) -> AsyncGenerator[AsyncClient, None]:
    """Create async HTTP test client."""
    transport = ASGITransport(app=test_app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


# --- Test Data Fixtures ---


@pytest_asyncio.fixture
async def test_user(db_session: AsyncSession) -> User:
    """Create a standard test user."""
    user = User(
        email="test@example.com",
        hashed_password=get_password_hash("testpassword"),
        full_name="Test User",
        role=UserRole.USER,
        is_active=True,
    )
    db_session.add(user)
    await db_session.flush()
    await db_session.refresh(user)
    return user


@pytest_asyncio.fixture
async def admin_user(db_session: AsyncSession) -> User:
    """Create an admin test user."""
    user = User(
        email="admin@example.com",
        hashed_password=get_password_hash("adminpassword"),
        full_name="Admin User",
        role=UserRole.ADMIN,
        is_active=True,
    )
    db_session.add(user)
    await db_session.flush()
    await db_session.refresh(user)
    return user


@pytest_asyncio.fixture
async def inactive_user(db_session: AsyncSession) -> User:
    """Create an inactive test user."""
    user = User(
        email="inactive@example.com",
        hashed_password=get_password_hash("inactivepassword"),
        full_name="Inactive User",
        role=UserRole.USER,
        is_active=False,
    )
    db_session.add(user)
    await db_session.flush()
    await db_session.refresh(user)
    return user


@pytest_asyncio.fixture
async def test_team(db_session: AsyncSession) -> Team:
    """Create a test team."""
    team = Team(
        name="Test Team",
        slug="test-team",
        description="A test team",
        color="#FF5733",
    )
    db_session.add(team)
    await db_session.flush()
    await db_session.refresh(team)
    return team


@pytest_asyncio.fixture
async def test_project_type(db_session: AsyncSession) -> ProjectType:
    """Create a test project type."""
    project_type = ProjectType(
        name="Feature",
        slug="feature",
        description="Feature projects",
        workflow=["Backlog", "In Progress", "Done"],
        color="#3498db",
    )
    db_session.add(project_type)
    await db_session.flush()
    await db_session.refresh(project_type)
    return project_type


@pytest_asyncio.fixture
async def test_task_type(db_session: AsyncSession, test_team: Team) -> TaskType:
    """Create a test task type."""
    task_type = TaskType(
        name="Bug",
        slug="bug",
        description="Bug tracking",
        workflow=["Open", "In Progress", "Resolved", "Closed"],
        team_id=test_team.id,
        color="#e74c3c",
    )
    db_session.add(task_type)
    await db_session.flush()
    await db_session.refresh(task_type)
    return task_type


@pytest_asyncio.fixture
async def test_theme(db_session: AsyncSession) -> Theme:
    """Create a test theme."""
    theme = Theme(
        title="Q1 Initiatives",
        description="Q1 2024 initiatives",
        status="active",
    )
    db_session.add(theme)
    await db_session.flush()
    await db_session.refresh(theme)
    return theme


@pytest_asyncio.fixture
async def test_project(
    db_session: AsyncSession, test_project_type: ProjectType, test_theme: Theme
) -> Project:
    """Create a test project."""
    project = Project(
        title="Test Project",
        description="A test project",
        status="Backlog",
        project_type_id=test_project_type.id,
        theme_id=test_theme.id,
    )
    db_session.add(project)
    await db_session.flush()
    await db_session.refresh(project)
    return project


@pytest_asyncio.fixture
async def test_task(
    db_session: AsyncSession,
    test_team: Team,
    test_task_type: TaskType,
    test_project: Project,
) -> Task:
    """Create a test task."""
    task = Task(
        display_id="TEST-1",
        title="Test Task",
        description="A test task",
        status="Open",
        team_id=test_team.id,
        task_type_id=test_task_type.id,
        project_id=test_project.id,
    )
    db_session.add(task)
    await db_session.flush()
    await db_session.refresh(task)
    return task


# --- Authentication Fixtures ---


@pytest.fixture
def user_token(test_user: User) -> str:
    """Generate JWT token for test user."""
    return create_access_token(data={"sub": str(test_user.id)})


@pytest.fixture
def admin_token(admin_user: User) -> str:
    """Generate JWT token for admin user."""
    return create_access_token(data={"sub": str(admin_user.id)})


@pytest.fixture
def auth_headers(user_token: str) -> dict:
    """HTTP headers with user authentication."""
    return {"Authorization": f"Bearer {user_token}"}


@pytest.fixture
def admin_headers(admin_token: str) -> dict:
    """HTTP headers with admin authentication."""
    return {"Authorization": f"Bearer {admin_token}"}


# --- Mock Fixtures for Unit Tests ---


@pytest.fixture
def mock_session() -> AsyncMock:
    """Create a mock AsyncSession for unit tests."""
    session = AsyncMock(spec=AsyncSession)
    session.commit = AsyncMock()
    session.rollback = AsyncMock()
    session.flush = AsyncMock()
    session.refresh = AsyncMock()
    session.execute = AsyncMock()
    session.add = MagicMock()
    session.delete = AsyncMock()
    return session


@pytest.fixture
def mock_user() -> User:
    """Create a mock user object for unit tests (no database)."""
    user = MagicMock(spec=User)
    user.id = 1
    user.email = "mock@example.com"
    user.hashed_password = get_password_hash("mockpassword")
    user.full_name = "Mock User"
    user.role = UserRole.USER
    user.is_active = True
    return user


@pytest.fixture
def mock_admin() -> User:
    """Create a mock admin object for unit tests (no database)."""
    admin = MagicMock(spec=User)
    admin.id = 2
    admin.email = "mockadmin@example.com"
    admin.hashed_password = get_password_hash("mockadminpassword")
    admin.full_name = "Mock Admin"
    admin.role = UserRole.ADMIN
    admin.is_active = True
    return admin
