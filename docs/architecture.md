# Architecture Guide

This document describes the technical architecture of Orbit.

## System Overview

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│    Frontend     │────▶│     Backend     │────▶│   PostgreSQL    │
│   React + TS    │     │    FastAPI      │     │                 │
│   Port 3000     │     │   Port 8000     │     │   Port 5432     │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

All services run in Docker containers orchestrated by Docker Compose.

## Backend Architecture

### Layered Design

```
┌──────────────────────────────────────────┐
│              API Layer                    │
│         (FastAPI Endpoints)               │
├──────────────────────────────────────────┤
│            Service Layer                  │
│         (Business Logic)                  │
├──────────────────────────────────────────┤
│          Repository Layer                 │
│        (Data Access)                      │
├──────────────────────────────────────────┤
│            Entity Layer                   │
│       (SQLAlchemy Models)                 │
└──────────────────────────────────────────┘
```

### Directory Structure

```
backend/app/
├── api/
│   ├── deps.py              # Dependency injection (DB session, auth)
│   └── v1/
│       ├── router.py        # Combines all endpoint routers
│       └── endpoints/       # One file per resource
├── core/
│   ├── config.py            # Pydantic settings
│   ├── database.py          # Async SQLAlchemy setup
│   └── security.py          # JWT, password hashing
├── domain/
│   ├── entities/            # SQLAlchemy ORM models
│   ├── repositories/        # Database operations
│   ├── services/            # Business logic
│   └── exceptions.py        # Domain exceptions
├── schemas/                 # Pydantic request/response models
└── scripts/                 # CLI utilities
```

### Key Patterns

**Dependency Injection:**
```python
# api/deps.py
DbSession = Annotated[AsyncSession, Depends(get_db)]
CurrentUser = Annotated[User, Depends(get_current_user)]

# Usage in endpoints
@router.get("/projects")
async def list_projects(db: DbSession, user: CurrentUser):
    service = ProjectService(db)
    return await service.list_projects()
```

**Service Layer:**
```python
# Services encapsulate business logic and use repositories
class ProjectService:
    def __init__(self, session: AsyncSession):
        self.project_repo = ProjectRepository(session)
        self.task_repo = TaskRepository(session)
    
    async def delete_project(self, id: int, target_id: int | None):
        # Business logic: move tasks before deleting
        await self.task_repo.update_project_for_tasks(id, target_id)
        await self.project_repo.delete(project)
```

**Repository Layer:**
```python
# Repositories handle database operations only
class ProjectRepository(BaseRepository[Project]):
    async def get_with_relations(self, id: int) -> Project | None:
        query = (
            select(Project)
            .where(Project.id == id)
            .options(selectinload(Project.tasks))
        )
        result = await self.session.execute(query)
        return result.scalar_one_or_none()
```

### Database

**Async SQLAlchemy 2.0** with asyncpg driver:

```python
engine = create_async_engine(
    settings.DATABASE_URL,
    pool_pre_ping=True,
    pool_size=5,
    max_overflow=10,
)
```

**Key entities:**

| Entity | Description |
|--------|-------------|
| User | Authentication, roles (admin/user) |
| Team | Groups users and owns task types |
| Theme | Strategic initiatives |
| ProjectType | Defines project workflow and custom fields |
| Project | Cross-team work items |
| TaskType | Team-specific task configuration |
| Task | Work items with display IDs (e.g., ORBIT-123) |
| Release | Version tracking |

**Relationships:**
- Theme → many Projects
- ProjectType → many Projects
- Project → many Tasks
- Team → many TaskTypes → many Tasks
- Task ↔ Task (dependencies, self-referential many-to-many)

### Authentication

JWT-based with bearer tokens:

```
POST /api/v1/auth/login
  → Returns: { access_token, token_type }

All other endpoints:
  Authorization: Bearer <token>
```

Tokens are signed with HS256 and include user ID in the `sub` claim.

## Frontend Architecture

### State Management

**Zustand** for client state (auth, UI):
```typescript
export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  isAuthenticated: false,
  login: async (email, password) => { ... },
}));
```

**React Query** for server state:
```typescript
const { data: projects } = useQuery({
  queryKey: ['projects', filters],
  queryFn: () => api.projects.list(filters),
});
```

### Directory Structure

```
frontend/src/
├── api/
│   └── client.ts          # Axios-based API client
├── components/
│   ├── ui/                # Shared UI components
│   └── ...                # Feature-specific components
├── hooks/                 # Custom React hooks
├── pages/                 # Route pages
├── stores/                # Zustand stores
└── types/                 # TypeScript interfaces
```

### Component Patterns

**Shared UI components** in `components/ui/`:
- `FormModal`, `EditFormModal` — Modal dialogs with forms
- `DataTable` — Generic table with sorting/filtering
- `DetailPageLayout` — Consistent detail page structure
- `InlineEditable*` — Inline text editing
- `StatusBadge`, `WorkflowSelector` — Status display/selection

**Page structure:**
```typescript
export function ProjectsPage() {
  // Queries
  const { data, isLoading } = useQuery({ ... });
  
  // Mutations
  const createMutation = useMutation({ ... });
  
  // Local state
  const [filters, setFilters] = useState({ ... });
  
  // Render
  return (
    <PageHeader ... />
    <DataTable ... />
    <FormModal ... />
  );
}
```

### API Client

Single axios instance with interceptors for auth:

```typescript
// api/client.ts
const axiosInstance = axios.create({
  baseURL: import.meta.env.VITE_API_URL,
});

// Adds Authorization header automatically
axiosInstance.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});
```

## Gotchas & Known Issues

### Backend

1. **Async context**: All database operations must be awaited. SQLAlchemy lazy loading doesn't work with async — use `selectinload()`.

2. **Schema rebuilds**: Nested Pydantic models require `model_rebuild()` calls at the end of `schemas/__init__.py`.

3. **Soft deletes**: Theme deletion unlinks projects (sets `theme_id = NULL`), it doesn't cascade delete.

### Frontend

1. **Theme workflow**: Currently stored in localStorage, not synced with backend. Settings page manages this.

2. **Query invalidation**: After mutations, invalidate related queries:
   ```typescript
   queryClient.invalidateQueries({ queryKey: ['projects'] });
   ```

3. **Path aliases**: Uses `@/` alias for `src/` — configured in `vite.config.ts` and `tsconfig.json`.

## Future Considerations

- **Kubernetes/ArgoCD**: Production deployment target
- **Real-time updates**: WebSocket support for live collaboration
- **Audit logging**: Track changes to entities
- **Multi-tenancy**: Organization-level isolation
- 