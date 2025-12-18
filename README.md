# Core PM

An open-source, engineer-friendly project management tool built with FastAPI and React.

## Overview

Core PM is a flexible project management system designed for engineering teams. It supports customizable workflows, team-based task management, and strategic initiative tracking through themes and projects.

### Key Features

- **Customizable Workflows** — Define your own statuses per project type and task type
- **Team-Based Organization** — Tasks belong to teams with their own task types
- **Strategic Alignment** — Group projects under themes for initiative tracking
- **Flexible Custom Fields** — Add custom fields to projects and tasks
- **Dependency Tracking** — Track dependencies between tasks and projects
- **Release Management** — Associate tasks with releases
- **GitHub Integration** — Link PRs and repositories to tasks

## Quick Start

### Prerequisites

- Docker and Docker Compose
- Git

### Running Locally

```bash
# Clone the repository
git clone https://github.com/your-org/core-pm.git
cd core-pm

# Start all services
docker-compose up

# The app will be available at:
# - Frontend: http://localhost:3000
# - Backend API: http://localhost:8000
# - API Docs: http://localhost:8000/docs
```

### Default Login

```
Email: admin@corepm.example.com
Password: admin123
```

The database is seeded with sample data including users, teams, projects, and tasks.

## Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | React 18, TypeScript, Vite, Tailwind CSS |
| State | Zustand (client), React Query (server) |
| Backend | FastAPI, Python 3.11+, Pydantic v2 |
| Database | PostgreSQL 16, SQLAlchemy 2.0 (async) |
| Auth | JWT (python-jose), bcrypt |

## Project Structure

```
core-pm/
├── backend/
│   ├── app/
│   │   ├── api/v1/endpoints/    # REST endpoints
│   │   ├── core/                # Config, security, database
│   │   ├── domain/
│   │   │   ├── entities/        # SQLAlchemy models
│   │   │   ├── repositories/    # Data access layer
│   │   │   └── services/        # Business logic
│   │   ├── schemas/             # Pydantic schemas
│   │   └── scripts/             # CLI scripts (seed, etc.)
│   ├── requirements.txt
│   └── Dockerfile
├── frontend/
│   ├── src/
│   │   ├── api/                 # API client
│   │   ├── components/          # React components
│   │   ├── hooks/               # Custom hooks
│   │   ├── pages/               # Route pages
│   │   ├── stores/              # Zustand stores
│   │   └── types/               # TypeScript types
│   ├── package.json
│   └── Dockerfile.dev
└── docker-compose.yml
```

## API Reference

When running locally, interactive API documentation is available at:

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

### Core Endpoints

| Resource | Endpoint | Description |
|----------|----------|-------------|
| Auth | `POST /api/v1/auth/login` | Get JWT token |
| Users | `/api/v1/users` | User management (admin) |
| Teams | `/api/v1/teams` | Team CRUD + members |
| Themes | `/api/v1/themes` | Strategic initiatives |
| Project Types | `/api/v1/project-types` | Project type config |
| Projects | `/api/v1/projects` | Project CRUD |
| Task Types | `/api/v1/task-types` | Task type config (per team) |
| Tasks | `/api/v1/tasks` | Task CRUD |
| Releases | `/api/v1/releases` | Release management |

## Data Model

```
Theme (strategic initiative)
  └── Project (cross-team work item)
        ├── belongs to ProjectType (defines workflow)
        └── has many Tasks

Team
  ├── has many TaskTypes (each with own workflow)
  └── has many Tasks
        ├── belongs to TaskType
        ├── optionally linked to Project
        ├── optionally linked to Release
        └── can have dependencies on other Tasks
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | (required) |
| `SECRET_KEY` | JWT signing key | (required) |
| `CORS_ORIGINS` | Allowed CORS origins | `http://localhost:3000` |
| `DEBUG` | Enable debug mode | `false` |
| `TASK_ID_PREFIX` | Prefix for task display IDs | `CORE` |

## Documentation

- [Architecture Guide](docs/architecture.md) — Detailed technical architecture
- [Contributing Guide](CONTRIBUTING.md) — How to contribute

## License

This project is licensed under the MIT License — see [LICENSE](LICENSE) for details.

---

**Questions?** Open an issue or start a discussion.