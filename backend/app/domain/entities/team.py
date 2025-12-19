"""
Team domain entity.
"""
from sqlalchemy import String, ForeignKey, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.domain.entities.base import TimestampMixin


class TeamMember(Base):
    """Association table for team membership."""
    
    __tablename__ = "team_members"
    
    team_id: Mapped[int] = mapped_column(
        ForeignKey("teams.id", ondelete="CASCADE"),
        primary_key=True,
    )
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        primary_key=True,
    )
    
    # Relationships
    team: Mapped["Team"] = relationship("Team", back_populates="memberships")
    user: Mapped["User"] = relationship("User", back_populates="team_memberships")


class Team(Base, TimestampMixin):
    """Team model for organizing users and tasks."""
    
    __tablename__ = "teams"
    
    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    slug: Mapped[str] = mapped_column(String(100), unique=True, index=True, nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    color: Mapped[str | None] = mapped_column(String(20), nullable=True)
    
    # Relationships
    memberships: Mapped[list["TeamMember"]] = relationship(
        "TeamMember",
        back_populates="team",
        cascade="all, delete-orphan",
    )
    task_types: Mapped[list["TaskType"]] = relationship(
        "TaskType",
        back_populates="team",
        cascade="all, delete-orphan",
    )
    tasks: Mapped[list["Task"]] = relationship(
        "Task",
        back_populates="team",
        cascade="all, delete-orphan",
    )
    
    @property
    def members(self) -> list["User"]:
        """Get list of team members."""
        return [m.user for m in self.memberships]
    
    def __repr__(self) -> str:
        return f"<Team(id={self.id}, name={self.name})>"


# Type hints imports
from app.domain.entities.user import User
from app.domain.entities.task import Task, TaskType
