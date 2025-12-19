"""
Repository package.

Exports all repository classes for dependency injection.
"""

from app.domain.repositories.base import BaseRepository
from app.domain.repositories.user import UserRepository
from app.domain.repositories.team import TeamRepository
from app.domain.repositories.theme import ThemeRepository
from app.domain.repositories.project import ProjectRepository, ProjectTypeRepository
from app.domain.repositories.task import (
    TaskRepository,
    TaskTypeRepository,
    GitHubLinkRepository,
)
from app.domain.repositories.release import ReleaseRepository

__all__ = [
    "BaseRepository",
    "UserRepository",
    "TeamRepository",
    "ThemeRepository",
    "ProjectRepository",
    "ProjectTypeRepository",
    "TaskRepository",
    "TaskTypeRepository",
    "GitHubLinkRepository",
    "ReleaseRepository",
]
