# Orbit

An open-source, engineer-friendly project management tool built with FastAPI and React.

## Overview

Orbit is a flexible project management system designed for engineering teams. It supports customizable workflows, team-based task management, and strategic initiative tracking.

### Key Features

- **Customizable Workflows** — Define your own statuses per project type and task type
- **Team-Based Organization** — Tasks belong to teams with their own task types
- **Strategic Alignment** — Group projects under themes for initiative tracking
- **Flexible Custom Fields** — Add custom fields to projects and tasks
- **Dependency Tracking** — Track dependencies between tasks and projects
- **Release Management** — Associate tasks with releases

## Quick Start

```bash
git clone https://github.com/your-org/orbit.git
cd orbit
docker-compose up
```

**Access:**
- Frontend: http://localhost:3000
- API Docs: http://localhost:8000/docs

**Default Login:** `admin@orbit.example.com` / `admin123`

## Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | React 18, TypeScript, Vite, Tailwind CSS |
| Backend | FastAPI, Python 3.11+, SQLAlchemy 2.0 (async) |
| Database | PostgreSQL 16 |

## Documentation

| Document | Description |
|----------|-------------|
| [Self-Hosting Guide](docs/SELF-HOSTING.md) | Local and cloud deployment options |
| [Architecture Guide](docs/architecture.md) | Technical architecture and patterns |
| [Contributing Guide](CONTRIBUTING.md) | Development setup and guidelines |
| [Infrastructure](infrastructure/README.md) | Terraform/CrossPlane IaC for cloud deployment |

## License

MIT License — see [LICENSE](LICENSE) for details.
