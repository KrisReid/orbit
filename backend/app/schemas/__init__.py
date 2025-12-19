"""
Unified Pydantic schemas.
Merges Orbit Hub's clean structure with KrisReid's feature requirements.
"""

from datetime import date, datetime
from typing import Any, Generic, TypeVar
from pydantic import BaseModel, ConfigDict, EmailStr
from app.domain.entities.base import (
    UserRole,
    ReleaseStatus,
    FieldType,
    GitHubLinkType,
    GitHubPRStatus,
)

T = TypeVar("T")


# --- Common Wrappers ---
class PaginatedResponse(BaseModel, Generic[T]):
    items: list[T]
    total: int
    page: int = 1
    page_size: int = 100


class MessageResponse(BaseModel):
    message: str


# --- Migration & Stats Schemas ---
class StatusMigration(BaseModel):
    old_status: str
    new_status: str


class MigrationRequest(BaseModel):
    target_id: int
    status_mappings: list[StatusMigration] = []


class EntityStatsResponse(BaseModel):
    id: int
    name: str
    workflow: list[str]
    total_items: int
    items_by_status: dict[str, int]


class ProjectTypeStatsResponse(BaseModel):
    project_type_id: int
    project_type_name: str
    workflow: list[str]
    total_projects: int
    projects_by_status: dict[str, int]


class TaskTypeStatsResponse(BaseModel):
    task_type_id: int
    task_type_name: str
    team_id: int
    workflow: list[str]
    total_tasks: int
    tasks_by_status: dict[str, int]


# --- Project Type Schemas ---
class CustomFieldBase(BaseModel):
    key: str
    label: str
    field_type: FieldType
    options: list[str] | None = None
    required: bool = False


class CustomFieldCreate(CustomFieldBase):
    order: int | None = None


class CustomFieldUpdate(BaseModel):
    label: str | None = None
    options: list[str] | None = None
    required: bool | None = None
    order: int | None = None


class CustomFieldResponse(CustomFieldBase):
    model_config = ConfigDict(from_attributes=True)
    id: int
    order: int


class ProjectTypeBase(BaseModel):
    name: str
    description: str | None = None
    workflow: list[str]
    color: str | None = None


class ProjectTypeCreate(ProjectTypeBase):
    slug: str | None = None
    fields: list[CustomFieldCreate] | None = None


class ProjectTypeUpdate(BaseModel):
    name: str | None = None
    description: str | None = None
    workflow: list[str] | None = None
    color: str | None = None
    fields: list[CustomFieldCreate] | None = None


class ProjectTypeResponse(ProjectTypeBase):
    model_config = ConfigDict(from_attributes=True)
    id: int
    slug: str
    fields: list[CustomFieldResponse] = []
    created_at: datetime
    updated_at: datetime


# --- Task Type Schemas (Added) ---
class TaskTypeBase(BaseModel):
    name: str
    description: str | None = None
    workflow: list[str]
    color: str | None = None


class TaskTypeCreate(TaskTypeBase):
    team_id: int
    slug: str | None = None
    fields: list[CustomFieldCreate] | None = None


class TaskTypeUpdate(BaseModel):
    name: str | None = None
    description: str | None = None
    workflow: list[str] | None = None
    color: str | None = None
    fields: list[CustomFieldCreate] | None = None


class TaskTypeResponse(TaskTypeBase):
    model_config = ConfigDict(from_attributes=True)
    id: int
    slug: str
    team_id: int
    fields: list[CustomFieldResponse] = []
    created_at: datetime
    updated_at: datetime


# --- Theme Schemas ---
class ThemeBase(BaseModel):
    title: str
    description: str | None = None
    status: str = "active"


class ThemeCreate(ThemeBase):
    pass


class ThemeUpdate(BaseModel):
    title: str | None = None
    description: str | None = None
    status: str | None = None


class ThemeResponse(ThemeBase):
    model_config = ConfigDict(from_attributes=True)
    id: int
    created_at: datetime
    updated_at: datetime


class ProjectSummary(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    title: str
    status: str


class ThemeWithProjectsResponse(ThemeResponse):
    projects: list[ProjectSummary] = []


# --- Project Schemas ---
class ProjectBase(BaseModel):
    title: str
    description: str | None = None


class ProjectCreate(ProjectBase):
    project_type_id: int
    theme_id: int | None = None
    custom_data: dict[str, Any] | None = None


class ProjectUpdate(BaseModel):
    title: str | None = None
    description: str | None = None
    status: str | None = None
    theme_id: int | None = None
    project_type_id: int | None = None
    custom_data: dict[str, Any] | None = None


class ThemeSummary(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    title: str
    status: str


class ProjectTypeSummary(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    name: str
    color: str | None = None


class ProjectResponse(ProjectBase):
    model_config = ConfigDict(from_attributes=True)
    id: int
    status: str
    project_type_id: int
    project_type: ProjectTypeSummary | None = None
    theme_id: int | None = None
    theme: ThemeSummary | None = None
    custom_data: dict[str, Any] | None = None
    created_at: datetime
    updated_at: datetime


class TaskSummary(BaseModel):
    """Summary of a task for inclusion in project details."""

    model_config = ConfigDict(from_attributes=True)
    id: int
    display_id: str
    title: str
    status: str


class ProjectDetailResponse(ProjectResponse):
    dependencies: list[ProjectSummary] = []
    dependents: list[ProjectSummary] = []
    tasks: list[TaskSummary] = []


# --- Release Schemas ---
class ReleaseBase(BaseModel):
    version: str
    title: str
    description: str | None = None


class ReleaseCreate(ReleaseBase):
    target_date: date | None = None
    status: ReleaseStatus = ReleaseStatus.PLANNED


class ReleaseUpdate(BaseModel):
    version: str | None = None
    title: str | None = None
    description: str | None = None
    target_date: date | None = None
    release_date: date | None = None
    status: ReleaseStatus | None = None


class ReleaseResponse(ReleaseBase):
    model_config = ConfigDict(from_attributes=True)
    id: int
    status: ReleaseStatus
    target_date: date | None = None
    release_date: date | None = None
    created_at: datetime
    updated_at: datetime


class ReleaseSummary(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    version: str
    title: str
    status: ReleaseStatus


# --- GitHub Schemas (moved before Tasks for forward reference) ---
class GitHubLinkCreate(BaseModel):
    task_id: int
    link_type: GitHubLinkType
    repository_owner: str
    repository_name: str
    url: str
    pr_number: int | None = None
    pr_title: str | None = None
    pr_status: GitHubPRStatus | None = None


class GitHubLinkResponse(GitHubLinkCreate):
    model_config = ConfigDict(from_attributes=True)
    id: int
    created_at: datetime
    updated_at: datetime


# --- Auth/User Schemas ---
class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class UserBase(BaseModel):
    email: EmailStr
    full_name: str


class UserCreate(UserBase):
    password: str
    role: UserRole = UserRole.USER


class UserUpdate(BaseModel):
    email: EmailStr | None = None
    full_name: str | None = None
    password: str | None = None
    is_active: bool | None = None
    role: UserRole | None = None


class UserResponse(UserBase):
    model_config = ConfigDict(from_attributes=True)
    id: int
    role: UserRole
    is_active: bool
    created_at: datetime
    updated_at: datetime


# --- Task Schemas ---
class TaskCreate(BaseModel):
    title: str
    team_id: int
    task_type_id: int
    description: str | None = None
    project_id: int | None = None
    release_id: int | None = None
    estimation: str | None = None
    custom_data: dict[str, Any] | None = None


class TaskUpdate(BaseModel):
    title: str | None = None
    description: str | None = None
    status: str | None = None
    team_id: int | None = None
    task_type_id: int | None = None
    project_id: int | None = None
    release_id: int | None = None
    estimation: str | None = None
    custom_data: dict[str, Any] | None = None


class TeamSummary(BaseModel):
    """Summary of a team for task responses."""

    model_config = ConfigDict(from_attributes=True)
    id: int
    name: str
    slug: str
    color: str | None = None


class TaskTypeSummary(BaseModel):
    """Summary of a task type for task responses."""

    model_config = ConfigDict(from_attributes=True)
    id: int
    name: str
    slug: str
    color: str | None = None


class DependencySummary(BaseModel):
    """Summary of a dependency for task responses."""

    model_config = ConfigDict(from_attributes=True)
    id: int
    display_id: str
    title: str
    status: str


class TaskResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    display_id: str
    title: str
    status: str
    team_id: int
    task_type_id: int
    description: str | None = None
    project_id: int | None = None
    release_id: int | None = None
    estimation: str | None = None
    custom_data: dict[str, Any] | None = None
    created_at: datetime
    updated_at: datetime
    # Nested relationships
    team: TeamSummary | None = None
    task_type: TaskTypeSummary | None = None
    project: ProjectSummary | None = None
    release: ReleaseSummary | None = None
    dependencies: list[DependencySummary] = []
    dependents: list[DependencySummary] = []
    github_links: list[GitHubLinkResponse] = []


# --- Team Schemas ---
class TeamMemberResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    team_id: int
    user_id: int
    user: UserResponse | None = None


class TeamCreate(BaseModel):
    name: str
    description: str | None = None
    slug: str | None = None
    color: str | None = None


class TeamUpdate(BaseModel):
    name: str | None = None
    description: str | None = None
    slug: str | None = None
    color: str | None = None


class TeamResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    name: str
    slug: str
    description: str | None = None
    color: str | None = None
    created_at: datetime
    updated_at: datetime
    memberships: list[TeamMemberResponse] = []
    task_types: list[TaskTypeResponse] = []


class TeamStatsResponse(BaseModel):
    team_id: int
    team_name: str
    task_count: int
    task_type_count: int
    is_unassigned_team: bool
    tasks_by_status: dict[str, int] = {}


class TeamDeleteRequest(BaseModel):
    reassign_tasks_to: int | None = None
    delete_tasks: bool = False


# --- Aliases for Backward Compatibility ---
# These map the "Response" models to the generic names expected by old endpoints
User = UserResponse
Project = ProjectResponse
Task = TaskResponse
Team = TeamResponse
Release = ReleaseResponse
Theme = ThemeResponse
TaskType = TaskTypeResponse
ProjectType = ProjectTypeResponse

# --- Forward Reference Rebuilds ---
# Critical for nested Pydantic models to work correctly
ProjectResponse.model_rebuild()
ProjectDetailResponse.model_rebuild()
ThemeWithProjectsResponse.model_rebuild()
TeamResponse.model_rebuild()
TaskResponse.model_rebuild()
