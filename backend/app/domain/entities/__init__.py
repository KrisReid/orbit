"""
Domain entities package.

Exports all SQLAlchemy models for use throughout the application.
"""

from app.domain.entities.base import (
    TimestampMixin,
    UserRole,
    ReleaseStatus,
    FieldType,
    GitHubLinkType,
    GitHubPRStatus,
)
from app.domain.entities.identity import User, Team, TeamMember
from app.domain.entities.project import (
    Theme,
    Project,
    ProjectType,
    ProjectTypeField,
    project_dependencies,
)
from app.domain.entities.task import (
    Task,
    TaskType,
    TaskTypeField,
    GitHubLink,
    task_dependencies,
)
from app.domain.entities.release import Release

__all__ = [
    # Base
    "TimestampMixin",
    "UserRole",
    "ReleaseStatus",
    "FieldType",
    "GitHubLinkType",
    "GitHubPRStatus",
    # Entities
    "User",
    "Team",
    "TeamMember",
    "Theme",
    "Project",
    "ProjectType",
    "ProjectTypeField",
    "Task",
    "TaskType",
    "TaskTypeField",
    "GitHubLink",
    "Release",
    # Association tables
    "project_dependencies",
    "task_dependencies",
]
