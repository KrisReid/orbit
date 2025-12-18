# Contributing to Orbit

Thanks for your interest in contributing! This guide will help you get started.

## Development Setup

### Prerequisites

- Docker and Docker Compose
- Node.js 18+ (for frontend development outside Docker)
- Python 3.11+ (for backend development outside Docker)

### Running with Docker (Recommended)

```bash
docker-compose up
```

This starts all services with hot-reload enabled. Changes to source files will automatically restart the relevant service.

### Running Without Docker

**Backend:**
```bash
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt

# Set environment variables
export DATABASE_URL="postgresql+asyncpg://orbit:orbit_secret@localhost:5432/orbit"
export SECRET_KEY="dev-secret-key"

# Run migrations and seed
python -m app.scripts.seed

# Start server
uvicorn app.main:app --reload
```

**Frontend:**
```bash
cd frontend
npm install
npm run dev
```

## Code Style

### Python (Backend)

- Follow PEP 8
- Use type hints for all function signatures
- Format with `black` (line length 100)
- Sort imports with `isort`
- Docstrings for public functions and classes

```python
# Good
async def create_project(
    self,
    title: str,
    project_type_id: int,
    description: str | None = None,
) -> Project:
    """
    Create a new project.
    
    Args:
        title: Project title
        project_type_id: ID of the project type
        description: Optional description
        
    Returns:
        Created project with relations loaded
    """
    ...
```

### TypeScript (Frontend)

- Use TypeScript strict mode
- Prefer functional components with hooks
- Use named exports
- Follow the existing component patterns

```typescript
// Good
export function ProjectCard({ project, onEdit }: ProjectCardProps) {
  const queryClient = useQueryClient();
  // ...
}
```

### Commit Messages

Use conventional commits:

```
feat: add task dependency visualization
fix: resolve duplicate task ID generation
docs: update API reference for releases
refactor: extract shared modal components
chore: update dependencies
```

Format: `type: short description`

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`

## Pull Request Process

### 1. Create a Branch

```bash
git checkout -b feat/your-feature-name
# or
git checkout -b fix/issue-description
```

Branch naming:
- `feat/` — new features
- `fix/` — bug fixes
- `docs/` — documentation
- `refactor/` — code refactoring
- `chore/` — maintenance tasks

### 2. Make Your Changes

- Keep PRs focused and reasonably sized
- Add tests for new functionality
- Update documentation if needed
- Ensure existing tests pass

### 3. Test Locally

```bash
# Backend tests
cd backend
pytest

# Frontend linting
cd frontend
npm run lint
```

### 4. Submit PR

- Fill out the PR template
- Link related issues
- Request review from maintainers

### 5. Review Process

- Address reviewer feedback
- Keep discussion focused on the code
- Squash commits before merge if requested

## Architecture Guidelines

### Backend

**Adding a new entity:**

1. Create entity in `app/domain/entities/`
2. Create repository in `app/domain/repositories/`
3. Create service in `app/domain/services/`
4. Add schemas in `app/schemas/__init__.py`
5. Create endpoints in `app/api/v1/endpoints/`
6. Register router in `app/api/v1/router.py`

**Pattern:**
```
Endpoint → Service → Repository → Entity
    ↓         ↓           ↓
 Schema    Business    Database
           Logic       Operations
```

### Frontend

**Adding a new page:**

1. Create page component in `src/pages/`
2. Add route in `src/App.tsx`
3. Create API methods in `src/api/client.ts`
4. Add types in `src/types/`

**Shared components** go in `src/components/ui/` and should be:
- Generic and reusable
- Well-typed with TypeScript
- Exported from the index file

## Database Migrations

We use Alembic for migrations:

```bash
cd backend

# Create a new migration
alembic revision --autogenerate -m "add_field_to_task"

# Apply migrations
alembic upgrade head

# Rollback one migration
alembic downgrade -1
```

## Questions?

- Check existing issues and discussions
- Open a new issue for bugs or feature requests
- Start a discussion for questions

## Code of Conduct

Be respectful and constructive. We're all here to build something useful together.