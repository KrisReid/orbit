"""
Service package.

Exports all service classes for dependency injection.
"""
from app.domain.services.auth import AuthService, UserService
from app.domain.services.team import TeamService
from app.domain.services.theme import ThemeService
from app.domain.services.project import ProjectService, ProjectTypeService
from app.domain.services.task import TaskService, TaskTypeService, GitHubService
from app.domain.services.release import ReleaseService

__all__ = [
    "AuthService",
    "UserService",
    "TeamService",
    "ThemeService",
    "ProjectService",
    "ProjectTypeService",
    "TaskService",
    "TaskTypeService",
    "GitHubService",
    "ReleaseService",
]
