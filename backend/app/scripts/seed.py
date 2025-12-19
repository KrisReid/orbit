"""
Database seeding script for development data.

Run with: python -m app.scripts.seed
"""

import asyncio

from app.core.database import get_db_context, init_db
from app.core.security import get_password_hash
from app.domain.entities import (
    User,
    UserRole,
    Team,
    TeamMember,
    Theme,
    ProjectType,
    Project,
    TaskType,
    Task,
    Release,
    ReleaseStatus,
)


async def seed_database():
    """Seed the database with initial development data."""
    # Ensure tables exist
    print("📦 Ensuring database tables exist...")
    await init_db()

    async with get_db_context() as db:
        print("🌱 Seeding database...")

        # Check if already seeded
        from sqlalchemy import select

        result = await db.execute(select(User).limit(1))
        if result.scalar_one_or_none():
            print("⚠️  Database already seeded. Skipping.")
            return

        # =================================================================
        # Users
        # =================================================================
        print("  Creating users...")
        admin = User(
            email="admin@orbit.example.com",
            hashed_password=get_password_hash("admin123"),
            full_name="Admin User",
            role=UserRole.ADMIN,
            is_active=True,
        )
        user1 = User(
            email="alice@orbit.example.com",
            hashed_password=get_password_hash("password123"),
            full_name="Alice Engineer",
            role=UserRole.USER,
            is_active=True,
        )
        user2 = User(
            email="bob@orbit.example.com",
            hashed_password=get_password_hash("password123"),
            full_name="Bob Developer",
            role=UserRole.USER,
            is_active=True,
        )
        db.add_all([admin, user1, user2])
        await db.flush()

        # =================================================================
        # Teams
        # =================================================================
        print("  Creating teams...")
        team_platform = Team(
            name="Platform",
            slug="platform",
            description="Core platform and infrastructure team",
        )
        team_frontend = Team(
            name="Frontend",
            slug="frontend",
            description="User interface and experience team",
        )
        db.add_all([team_platform, team_frontend])
        await db.flush()

        # Add members to teams
        db.add_all(
            [
                TeamMember(team_id=team_platform.id, user_id=admin.id),
                TeamMember(team_id=team_platform.id, user_id=user1.id),
                TeamMember(team_id=team_frontend.id, user_id=user2.id),
            ]
        )
        await db.flush()

        # =================================================================
        # Themes
        # =================================================================
        print("  Creating themes...")
        theme_q4 = Theme(
            title="Q4 Platform Improvements",
            description="Strategic initiative to improve platform reliability and performance",
            status="active",
        )
        theme_ux = Theme(
            title="UX Modernization",
            description="Refresh the user interface for better usability",
            status="active",
        )
        db.add_all([theme_q4, theme_ux])
        await db.flush()

        # =================================================================
        # Project Types
        # =================================================================
        print("  Creating project types...")
        pt_feature = ProjectType(
            name="Feature",
            slug="feature",
            description="New feature development",
            workflow=["Planning", "In Progress", "Review", "Done"],
            color="#3B82F6",
        )
        pt_improvement = ProjectType(
            name="Improvement",
            slug="improvement",
            description="Improvements to existing functionality",
            workflow=["Backlog", "In Progress", "Done"],
            color="#10B981",
        )
        pt_tech_debt = ProjectType(
            name="Tech Debt",
            slug="tech-debt",
            description="Technical debt reduction",
            workflow=["Identified", "Prioritized", "In Progress", "Resolved"],
            color="#F59E0B",
        )
        db.add_all([pt_feature, pt_improvement, pt_tech_debt])
        await db.flush()

        # =================================================================
        # Projects
        # =================================================================
        print("  Creating projects...")
        project1 = Project(
            title="API Performance Optimization",
            description="Improve API response times by 50%",
            status="In Progress",
            project_type_id=pt_improvement.id,
            theme_id=theme_q4.id,
        )
        project2 = Project(
            title="New Dashboard",
            description="Build a new real-time dashboard",
            status="Planning",
            project_type_id=pt_feature.id,
            theme_id=theme_ux.id,
        )
        project3 = Project(
            title="Database Migration",
            description="Migrate to PostgreSQL 16",
            status="Identified",
            project_type_id=pt_tech_debt.id,
            theme_id=theme_q4.id,
        )
        db.add_all([project1, project2, project3])
        await db.flush()

        # =================================================================
        # Task Types
        # =================================================================
        print("  Creating task types...")
        tt_story = TaskType(
            name="Story",
            slug="story",
            team_id=team_platform.id,
            description="User story",
            workflow=["Backlog", "In Progress", "Review", "Done"],
            color="#3B82F6",
        )
        tt_bug = TaskType(
            name="Bug",
            slug="bug",
            team_id=team_platform.id,
            description="Bug fix",
            workflow=["Open", "In Progress", "Testing", "Closed"],
            color="#EF4444",
        )
        tt_task = TaskType(
            name="Task",
            slug="task",
            team_id=team_frontend.id,
            description="General task",
            workflow=["To Do", "In Progress", "Done"],
            color="#8B5CF6",
        )
        db.add_all([tt_story, tt_bug, tt_task])
        await db.flush()

        # =================================================================
        # Releases
        # =================================================================
        print("  Creating releases...")
        release1 = Release(
            version="1.0.0",
            title="Initial Release",
            description="First public release",
            status=ReleaseStatus.RELEASED,
        )
        release2 = Release(
            version="1.1.0",
            title="Performance Update",
            description="Performance improvements and bug fixes",
            status=ReleaseStatus.IN_PROGRESS,
        )
        release3 = Release(
            version="2.0.0",
            title="Major Update",
            description="New features and UI refresh",
            status=ReleaseStatus.PLANNED,
        )
        db.add_all([release1, release2, release3])
        await db.flush()

        # =================================================================
        # Tasks
        # =================================================================
        print("  Creating tasks...")
        tasks = [
            Task(
                display_id="CORE-1",
                title="Implement caching layer",
                description="Add Redis caching for frequently accessed data",
                status="In Progress",
                team_id=team_platform.id,
                task_type_id=tt_story.id,
                project_id=project1.id,
                release_id=release2.id,
                estimation="5",
            ),
            Task(
                display_id="CORE-2",
                title="Optimize database queries",
                description="Review and optimize slow queries",
                status="Backlog",
                team_id=team_platform.id,
                task_type_id=tt_story.id,
                project_id=project1.id,
                release_id=release2.id,
                estimation="3",
            ),
            Task(
                display_id="CORE-3",
                title="Fix memory leak in worker",
                description="Worker process memory grows unbounded",
                status="Open",
                team_id=team_platform.id,
                task_type_id=tt_bug.id,
                release_id=release2.id,
                estimation="2",
            ),
            Task(
                display_id="CORE-4",
                title="Design dashboard wireframes",
                description="Create wireframes for new dashboard",
                status="To Do",
                team_id=team_frontend.id,
                task_type_id=tt_task.id,
                project_id=project2.id,
                release_id=release3.id,
                estimation="3",
            ),
            Task(
                display_id="CORE-5",
                title="Implement dashboard components",
                description="Build React components for dashboard",
                status="To Do",
                team_id=team_frontend.id,
                task_type_id=tt_task.id,
                project_id=project2.id,
                release_id=release3.id,
                estimation="8",
            ),
        ]

        # Add task dependency (CORE-5 depends on CORE-4)
        # We do this BEFORE adding to session/flushing to avoid async loading issues
        task4 = tasks[3]
        task5 = tasks[4]
        task5.dependencies.append(task4)

        db.add_all(tasks)
        await db.flush()

        print("✅ Database seeded successfully!")
        print("\n📋 Test credentials:")
        print("   Email: admin@orbit.example.com")
        print("   Password: admin123")


if __name__ == "__main__":
    asyncio.run(seed_database())
