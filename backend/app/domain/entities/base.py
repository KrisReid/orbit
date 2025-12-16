"""
SQLAlchemy model base and common utilities.
"""
from datetime import datetime
from enum import Enum as PyEnum
from typing import Any

from sqlalchemy import DateTime, func
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class TimestampMixin:
    """Mixin that adds created_at and updated_at columns."""
    
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )


class UserRole(str, PyEnum):
    """User roles for authorization."""
    ADMIN = "admin"
    USER = "user"


class ReleaseStatus(str, PyEnum):
    """Release lifecycle statuses."""
    PLANNED = "planned"
    IN_PROGRESS = "in_progress"
    RELEASED = "released"
    CANCELLED = "cancelled"


class FieldType(str, PyEnum):
    """Custom field types."""
    TEXT = "text"
    TEXTAREA = "textarea"
    NUMBER = "number"
    SELECT = "select"
    MULTISELECT = "multiselect"
    URL = "url"
    DATE = "date"
    CHECKBOX = "checkbox"


class GitHubLinkType(str, PyEnum):
    """Types of GitHub links."""
    PULL_REQUEST = "pull_request"
    BRANCH = "branch"
    COMMIT = "commit"


class GitHubPRStatus(str, PyEnum):
    """GitHub PR statuses."""
    OPEN = "open"
    CLOSED = "closed"
    MERGED = "merged"
    DRAFT = "draft"
