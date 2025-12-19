"""
Project domain entities - strategic themes and cross-team work items.
"""

from __future__ import annotations

from typing import TYPE_CHECKING, Any

from sqlalchemy import String, Integer, ForeignKey, Text, Enum, Column, Table
from sqlalchemy.dialects.postgresql import ARRAY, JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.domain.entities.base import TimestampMixin, FieldType

if TYPE_CHECKING:
    from app.domain.entities.task import Task


# Association table for project dependencies
project_dependencies = Table(
    "project_dependencies",
    Base.metadata,
    Column(
        "project_id",
        Integer,
        ForeignKey("projects.id", ondelete="CASCADE"),
        primary_key=True,
    ),
    Column(
        "depends_on_id",
        Integer,
        ForeignKey("projects.id", ondelete="CASCADE"),
        primary_key=True,
    ),
)


class Theme(Base, TimestampMixin):
    """Theme model - strategic initiatives that group related projects."""

    __tablename__ = "themes"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    status: Mapped[str] = mapped_column(String(50), default="active", nullable=False)

    # Relationships
    projects: Mapped[list[Project]] = relationship(
        "Project",
        back_populates="theme",
        passive_deletes=True,
    )

    def __repr__(self) -> str:
        return f"<Theme(id={self.id}, title={self.title})>"


class ProjectTypeField(Base):
    """Custom field definition for a project type."""

    __tablename__ = "project_type_fields"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    project_type_id: Mapped[int] = mapped_column(
        ForeignKey("project_types.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    key: Mapped[str] = mapped_column(String(100), nullable=False)
    label: Mapped[str] = mapped_column(String(255), nullable=False)
    field_type: Mapped[FieldType] = mapped_column(Enum(FieldType), nullable=False)

    # Options for select/multiselect fields
    options: Mapped[list[str] | None] = mapped_column(ARRAY(String), nullable=True)

    # Field configuration
    required: Mapped[bool] = mapped_column(default=False, nullable=False)
    order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    # Relationships
    project_type: Mapped[ProjectType] = relationship(
        "ProjectType", back_populates="fields"
    )

    def __repr__(self) -> str:
        return f"<ProjectTypeField(id={self.id}, key={self.key})>"


class ProjectType(Base, TimestampMixin):
    """Project type with customizable workflow and fields."""

    __tablename__ = "project_types"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    slug: Mapped[str] = mapped_column(
        String(100), unique=True, index=True, nullable=False
    )
    description: Mapped[str | None] = mapped_column(String(500), nullable=True)
    workflow: Mapped[list[str]] = mapped_column(ARRAY(String), nullable=False)
    color: Mapped[str | None] = mapped_column(String(20), nullable=True)

    # Relationships
    fields: Mapped[list[ProjectTypeField]] = relationship(
        "ProjectTypeField",
        back_populates="project_type",
        cascade="all, delete-orphan",
        order_by="ProjectTypeField.order",
    )
    projects: Mapped[list[Project]] = relationship(
        "Project",
        back_populates="project_type",
    )

    def __repr__(self) -> str:
        return f"<ProjectType(id={self.id}, name={self.name})>"


class Project(Base, TimestampMixin):
    """Project model - cross-team work items."""

    __tablename__ = "projects"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    status: Mapped[str] = mapped_column(String(50), nullable=False)

    # Foreign keys
    project_type_id: Mapped[int] = mapped_column(
        ForeignKey("project_types.id"),
        nullable=False,
        index=True,
    )
    theme_id: Mapped[int | None] = mapped_column(
        ForeignKey("themes.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )

    # Custom fields data
    custom_data: Mapped[dict[str, Any] | None] = mapped_column(JSONB, nullable=True)

    # Relationships
    project_type: Mapped[ProjectType] = relationship(
        "ProjectType", back_populates="projects"
    )
    theme: Mapped[Theme | None] = relationship("Theme", back_populates="projects")
    tasks: Mapped[list[Task]] = relationship(
        "Task",
        back_populates="project",
        cascade="all, delete-orphan",
    )

    # Self-referential many-to-many for dependencies
    dependencies: Mapped[list[Project]] = relationship(
        "Project",
        secondary=project_dependencies,
        primaryjoin=id == project_dependencies.c.project_id,
        secondaryjoin=id == project_dependencies.c.depends_on_id,
        backref="dependents",
    )

    def __repr__(self) -> str:
        return f"<Project(id={self.id}, title={self.title})>"
