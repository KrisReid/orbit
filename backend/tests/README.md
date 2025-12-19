# Backend Test Suite

This directory contains the test suite for the Orbit backend application.

## Structure

```
tests/
├── conftest.py          # Shared fixtures and test configuration
├── unit/                # Unit tests (no external dependencies)
│   ├── test_security.py         # Security utilities tests
│   ├── test_exceptions.py       # Domain exceptions tests
│   └── test_services/           # Service layer tests
│       ├── test_auth_service.py
│       └── test_project_service.py
└── integration/         # Integration tests (with database)
    ├── test_auth_api.py         # Authentication API tests
    ├── test_projects_api.py     # Projects API tests
    └── test_themes_api.py       # Themes API tests
```

## Running Tests

### Prerequisites

1. Ensure you have a test database available:
   - Create a PostgreSQL database named `orbit_test`
   - Or configure `DATABASE_URL` environment variable

2. Install test dependencies:
   ```bash
   pip install -r requirements.txt
   ```

### Running All Tests

```bash
cd backend
pytest
```

### Running Specific Test Categories

```bash
# Unit tests only
pytest tests/unit/

# Integration tests only
pytest tests/integration/

# Specific test file
pytest tests/unit/test_security.py

# Specific test class
pytest tests/unit/test_security.py::TestPasswordHashing

# Specific test
pytest tests/unit/test_security.py::TestPasswordHashing::test_password_hash_creates_valid_hash
```

### Running with Coverage

```bash
pytest --cov=app --cov-report=html --cov-report=term-missing
```

This generates:
- Terminal output with coverage summary
- HTML report in `htmlcov/` directory

### Running with Verbose Output

```bash
pytest -v
```

### Running Async Tests

All async tests are automatically handled by `pytest-asyncio`. The `asyncio_mode = auto` setting in `pytest.ini` enables this.

## Writing Tests

### Unit Tests

Unit tests should:
- Not require database or external services
- Use mocks for dependencies
- Test single units of functionality

Example:
```python
from unittest.mock import AsyncMock, MagicMock

@pytest.mark.asyncio
async def test_service_method(mock_session):
    service = MyService(mock_session)
    service.repository = AsyncMock()
    service.repository.get_by_id.return_value = mock_entity
    
    result = await service.get_something(1)
    
    assert result == mock_entity
```

### Integration Tests

Integration tests should:
- Use the test database
- Test the full request/response cycle
- Use fixtures from `conftest.py`

Example:
```python
@pytest.mark.asyncio
async def test_create_entity(client: AsyncClient, auth_headers: dict):
    response = await client.post(
        "/api/v1/entities",
        headers=auth_headers,
        json={"name": "Test"},
    )
    
    assert response.status_code == 201
    assert response.json()["name"] == "Test"
```

## Fixtures

### Database Fixtures

- `db_engine`: Test database engine (session scope)
- `db_session`: Database session with automatic rollback (function scope)

### Authentication Fixtures

- `test_user`: Standard user fixture
- `admin_user`: Admin user fixture
- `auth_headers`: Authentication headers for standard user
- `admin_headers`: Authentication headers for admin user

### Entity Fixtures

- `test_team`: Test team
- `test_project_type`: Test project type
- `test_task_type`: Test task type
- `test_theme`: Test theme
- `test_project`: Test project (depends on type and theme)
- `test_task`: Test task (depends on team, type, project)

### Mock Fixtures

- `mock_session`: Mock AsyncSession for unit tests

## Test Markers

```python
@pytest.mark.unit       # Unit test
@pytest.mark.integration # Integration test
@pytest.mark.slow       # Slow test (skipped in CI fast mode)
```

## CI/CD Integration

Tests are designed to run in CI/CD pipelines. Key considerations:

1. **Database**: Use `DATABASE_URL` environment variable
2. **Parallelization**: Tests are isolated and can run in parallel
3. **Coverage**: Coverage reports are generated in CI

Example CI command:
```bash
DATABASE_URL=postgresql+asyncpg://user:pass@localhost/orbit_test \
  pytest --cov=app --cov-report=xml
```
