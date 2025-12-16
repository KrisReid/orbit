"""
Theme domain entity - strategic initiatives.
"""
from sqlalchemy import String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.domain.entities.base import TimestampMixin


class Theme(Base, TimestampMixin):
    """Theme model - strategic initiatives that group related projects."""
    
    __tablename__ = "themes"
    
    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    status: Mapped[str] = mapped_column(String(50), default="active", nullable=False)
    
    # Relationships
    # Using passive_deletes=True to let the database handle the SET NULL
    # behavior on the foreign key when a theme is deleted (projects should
    # be unlinked, not deleted)
    projects: Mapped[list["Project"]] = relationship(
        "Project",
        back_populates="theme",
        passive_deletes=True,
    )
    
    def __repr__(self) -> str:
        return f"<Theme(id={self.id}, title={self.title})>"


# Import for type hints
from app.domain.entities.project import Project
