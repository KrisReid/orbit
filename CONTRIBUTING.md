# Contributing to Orbit

Thanks for your interest in contributing!

## Development Setup

### With Docker (Recommended)

```bash
docker-compose up
```

All services start with hot-reload enabled.

### Without Docker

**Backend:**
```bash
cd backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt

export DATABASE_URL="postgresql+asyncpg://orbit:orbit_secret@localhost:5432/orbit"
export SECRET_KEY="dev-secret-key"

python -m app.scripts.seed
uvicorn app.main:app --reload
```

**Frontend:**
```bash
cd frontend
npm install
npm run dev
```

## Code Style

### Python

- PEP 8 compliant
- Type hints on all function signatures
- Format with `black` (line length 100)
- Sort imports with `isort`

### TypeScript

- Strict mode enabled
- Functional components with hooks
- Named exports

### Commits

Use conventional commits: `type: short description`

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`

## Pull Requests

1. **Branch naming:** `feat/feature-name`, `fix/issue-description`
2. **Test locally:** `pytest` (backend), `npm run lint` (frontend)
3. **Keep PRs focused** — one feature or fix per PR
4. **Update docs** if behavior changes

## Architecture

### Adding a Backend Entity

1. Entity in `app/domain/entities/`
2. Repository in `app/domain/repositories/`
3. Service in `app/domain/services/`
4. Schemas in `app/schemas/__init__.py`
5. Endpoints in `app/api/v1/endpoints/`
6. Register router in `app/api/v1/router.py`

### Adding a Frontend Page

1. Page component in `src/pages/`
2. Route in `src/App.tsx`
3. API methods in `src/api/client.ts`
4. Types in `src/types/`

## Database Migrations

```bash
cd backend
alembic revision --autogenerate -m "description"
alembic upgrade head
```

## Questions?

Open an issue or start a discussion.
