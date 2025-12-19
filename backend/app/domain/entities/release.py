"""
Release domain entity - version management.
"""

from __future__ import annotations

from datetime import date
from typing import TYPE_CHECKING

from sqlalchemy import String, Date, Text, Enum
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.domain.entities.base import TimestampMixin, ReleaseStatus

if TYPE_CHECKING:
    from app.domain.entities.task import Task


class Release(Base, TimestampMixin):
    """Release model for version management."""

    __tablename__ = "releases"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    version: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)

    target_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    release_date: Mapped[date | None] = mapped_column(Date, nullable=True)

    status: Mapped[ReleaseStatus] = mapped_column(
        Enum(ReleaseStatus),
        default=ReleaseStatus.PLANNED,
        nullable=False,
    )

    # Relationships
    tasks: Mapped[list[Task]] = relationship(
        "Task",
        back_populates="release",
    )

    def __repr__(self) -> str:
        return f"<Release(id={self.id}, version={self.version})>"
