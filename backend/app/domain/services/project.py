"""
Project Service.
Now includes migration and stats logic required by the UI.
"""
import re
from typing import Any
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities import Project, ProjectType
from app.domain.exceptions import EntityNotFoundError, EntityAlreadyExistsError, ValidationError
from app.domain.repositories import ProjectRepository, ProjectTypeRepository, ThemeRepository

# Helper
def generate_slug(name: str) -> str:
    slug = name.lower()
    slug = re.sub(r'[^a-z0-9\s-]', '', slug)
    slug = re.sub(r'[\s_]+', '-', slug)
    return slug.strip('-')

class ProjectTypeService:
    def __init__(self, session: AsyncSession):
        self.session = session
        self.project_type_repo = ProjectTypeRepository(session)
        # We need project repo to calc stats/migrations
        self.project_repo = ProjectRepository(session) 
    
    async def create_project_type(self, name: str, workflow: list[str], description: str = None, color: str = None, slug: str = None, fields: list[dict] = None) -> ProjectType:
        if not slug:
            slug = generate_slug(name)
        if await self.project_type_repo.slug_exists(slug):
            raise EntityAlreadyExistsError("ProjectType", "slug", slug)
        
        project_type = await self.project_type_repo.create(
            name=name, slug=slug, description=description, workflow=workflow, color=color
        )
        if fields:
            await self.project_type_repo.update_fields(project_type.id, fields)
        return await self.project_type_repo.get_with_fields(project_type.id)

    async def get_project_type(self, id: int) -> ProjectType:
        pt = await self.project_type_repo.get_with_fields(id)
        if not pt:
            raise EntityNotFoundError("ProjectType", id)
        return pt

    async def list_project_types(self, skip=0, limit=100) -> tuple[list[ProjectType], int]:
        items = await self.project_type_repo.get_all_with_fields(skip=skip, limit=limit)
        total = await self.project_type_repo.count()
        return list(items), total

    async def update_project_type(self, project_type_id: int, name: str = None, description: str = None, workflow: list[str] = None, color: str = None, fields: list[dict] = None) -> ProjectType:
        project_type = await self.get_project_type(project_type_id)
        updates = {}
        if name is not None: updates["name"] = name
        if description is not None: updates["description"] = description
        if workflow is not None: updates["workflow"] = workflow
        if color is not None: updates["color"] = color
        
        if updates:
            project_type = await self.project_type_repo.update(project_type, **updates)
        if fields is not None:
            await self.project_type_repo.update_fields(project_type_id, fields)
            project_type = await self.project_type_repo.get_with_fields(project_type_id)
        return project_type

    async def delete_project_type(self, project_type_id: int) -> None:
        project_type = await self.get_project_type(project_type_id)
        await self.project_type_repo.delete(project_type)

    async def get_stats(self, id: int) -> dict:
        """
        Calculates project distribution for the UI settings page.
        """
        pt = await self.get_project_type(id)
        
        # Logic to count items by status
        projects, _ = await self.project_repo.get_all_filtered(limit=10000, project_type_ids=[id])
        
        stats = {status: 0 for status in pt.workflow}
        for p in projects:
            if p.status in stats:
                stats[p.status] += 1
            else:
                stats[p.status] = 1 # Handle unknown statuses
        
        return {
            "id": pt.id,
            "name": pt.name,
            "workflow": pt.workflow,
            "total_items": len(projects),
            "items_by_status": stats
        }

    async def migrate_projects(self, current_type_id: int, target_type_id: int, status_map: dict[str, str]) -> int:
        """
        Migrates all projects from one type to another.
        """
        # Validations
        if current_type_id == target_type_id:
            raise ValidationError("Cannot migrate to the same project type")
        
        target_pt = await self.get_project_type(target_type_id)
        
        # Validate statuses
        target_workflow = set(target_pt.workflow)
        for new_status in status_map.values():
            if new_status not in target_workflow:
                raise ValidationError(f"Target status '{new_status}' not in target workflow")

        # Perform Migration
        projects, _ = await self.project_repo.get_all_filtered(limit=10000, project_type_ids=[current_type_id])
        
        migrated_count = 0
        default_status = target_pt.workflow[0] if target_pt.workflow else "New"
        
        for project in projects:
            new_status = status_map.get(project.status, default_status)
            await self.project_repo.update(
                project, 
                project_type_id=target_type_id, 
                status=new_status
            )
            migrated_count += 1
            
        return migrated_count

class ProjectService:
    def __init__(self, session: AsyncSession):
        self.session = session
        self.project_repo = ProjectRepository(session)
        self.project_type_repo = ProjectTypeRepository(session)
        self.theme_repo = ThemeRepository(session)
    
    async def create_project(self, title: str, project_type_id: int, description: str = None, theme_id: int = None, custom_data: dict[str, Any] = None) -> Project:
        project_type = await self.project_type_repo.get_with_fields(project_type_id)
        if not project_type:
            raise EntityNotFoundError("ProjectType", project_type_id)
        
        default_status = project_type.workflow[0] if project_type.workflow else "New"
        
        if theme_id:
            theme = await self.theme_repo.get_by_id(theme_id)
            if not theme:
                raise EntityNotFoundError("Theme", theme_id)
        
        return await self.project_repo.create(
            title=title,
            description=description,
            project_type_id=project_type_id,
            theme_id=theme_id,
            status=default_status,
            custom_data=custom_data,
        )
    
    async def get_project(self, project_id: int) -> Project:
        project = await self.project_repo.get_with_relations(project_id)
        if not project:
            raise EntityNotFoundError("Project", project_id)
        return project
    
    async def list_projects(self, skip: int = 0, limit: int = 100, project_type_ids: list[int] = None, theme_id: int = None, statuses: list[str] = None) -> tuple[list[Project], int]:
        projects = await self.project_repo.get_all_filtered(
            skip=skip, limit=limit, project_type_ids=project_type_ids, theme_id=theme_id, statuses=statuses
        )
        total = await self.project_repo.count_filtered(
            project_type_ids=project_type_ids, theme_id=theme_id, statuses=statuses
        )
        return list(projects), total
    
    async def update_project(self, project_id: int, title: str = None, description: str = None, status: str = None, theme_id: int = None, clear_theme: bool = False, custom_data: dict[str, Any] = None) -> Project:
        project = await self.get_project(project_id)
        updates = {}
        
        if title is not None: updates["title"] = title
        if description is not None: updates["description"] = description
        if status is not None: updates["status"] = status
        if custom_data is not None: updates["custom_data"] = custom_data
        
        if clear_theme:
            updates["theme_id"] = None
        elif theme_id is not None:
            theme = await self.theme_repo.get_by_id(theme_id)
            if not theme:
                raise EntityNotFoundError("Theme", theme_id)
            updates["theme_id"] = theme_id
        
        if updates:
            project = await self.project_repo.update(project, **updates)
        return project
    
    async def delete_project(self, project_id: int) -> None:
        project = await self.get_project(project_id)
        await self.project_repo.delete(project)
    
    async def add_dependency(self, project_id: int, depends_on_id: int) -> Project:
        await self.get_project(project_id)
        await self.get_project(depends_on_id)
        if project_id == depends_on_id:
            raise ValidationError("A project cannot depend on itself")
        await self.project_repo.add_dependency(project_id, depends_on_id)
        return await self.get_project(project_id)
    
    async def remove_dependency(self, project_id: int, depends_on_id: int) -> Project:
        await self.project_repo.remove_dependency(project_id, depends_on_id)
        return await self.get_project(project_id)
