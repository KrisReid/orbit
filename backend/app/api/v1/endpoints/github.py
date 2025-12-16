"""
GitHub integration API endpoints.
"""
import re
import hmac
import hashlib
from typing import Any

from fastapi import APIRouter, HTTPException, status, Request, Header

from app.api.deps import DbSession, CurrentUser
from app.core.config import settings
from app.domain.entities import GitHubLinkType, GitHubPRStatus
from app.domain.exceptions import EntityNotFoundError
from app.domain.services import GitHubService, TaskService
from app.schemas import (
    GitHubLinkCreate,
    GitHubLinkResponse,
    MessageResponse,
)

router = APIRouter(prefix="/github", tags=["GitHub"])


def extract_task_id_from_pr(title: str, body: str | None) -> str | None:
    """
    Extract task display ID from PR title or body.
    
    Looks for patterns like CORE-123, CORE-456, etc.
    """
    pattern = rf"{settings.TASK_ID_PREFIX}-\d+"
    
    # Check title first
    match = re.search(pattern, title)
    if match:
        return match.group()
    
    # Check body
    if body:
        match = re.search(pattern, body)
        if match:
            return match.group()
    
    return None


@router.post("/links", response_model=GitHubLinkResponse, status_code=status.HTTP_201_CREATED)
async def create_github_link(
    data: GitHubLinkCreate,
    db: DbSession,
    _: CurrentUser,
):
    """Manually create a GitHub link for a task."""
    try:
        service = GitHubService(db)
        link = await service.create_link(
            task_id=data.task_id,
            link_type=data.link_type,
            repository_owner=data.repository_owner,
            repository_name=data.repository_name,
            url=data.url,
            pr_number=data.pr_number,
            pr_title=data.pr_title,
            pr_status=data.pr_status,
            branch_name=data.branch_name,
            commit_sha=data.commit_sha,
        )
        return link
    except EntityNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.delete("/links/{link_id}", response_model=MessageResponse)
async def delete_github_link(
    link_id: int,
    db: DbSession,
    _: CurrentUser,
):
    """Delete a GitHub link."""
    try:
        service = GitHubService(db)
        await service.delete_link(link_id)
        return MessageResponse(message="GitHub link deleted successfully")
    except EntityNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.post("/webhook")
async def github_webhook(
    request: Request,
    db: DbSession,
    x_github_event: str | None = Header(None),
    x_hub_signature_256: str | None = Header(None),
):
    """
    Handle GitHub webhook events.
    
    Automatically links PRs to tasks based on ticket ID in title/body.
    Updates PR status on state changes.
    """
    # Verify webhook signature if secret is configured
    if settings.GITHUB_WEBHOOK_SECRET:
        body = await request.body()
        expected_signature = "sha256=" + hmac.new(
            settings.GITHUB_WEBHOOK_SECRET.encode(),
            body,
            hashlib.sha256,
        ).hexdigest()
        
        if not hmac.compare_digest(x_hub_signature_256 or "", expected_signature):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid signature",
            )
    
    payload = await request.json()
    
    # Only handle pull request events
    if x_github_event != "pull_request":
        return {"status": "ignored", "reason": "not a pull_request event"}
    
    action = payload.get("action")
    pr = payload.get("pull_request", {})
    repo = payload.get("repository", {})
    
    pr_number = pr.get("number")
    pr_title = pr.get("title", "")
    pr_body = pr.get("body", "")
    pr_url = pr.get("html_url", "")
    pr_state = pr.get("state", "")
    pr_merged = pr.get("merged", False)
    
    repo_owner = repo.get("owner", {}).get("login", "")
    repo_name = repo.get("name", "")
    
    # Determine PR status
    if pr_merged:
        pr_status = GitHubPRStatus.MERGED
    elif pr.get("draft"):
        pr_status = GitHubPRStatus.DRAFT
    elif pr_state == "closed":
        pr_status = GitHubPRStatus.CLOSED
    else:
        pr_status = GitHubPRStatus.OPEN
    
    github_service = GitHubService(db)
    task_service = TaskService(db)
    
    if action == "opened" or action == "reopened":
        # Try to extract task ID and create link
        task_display_id = extract_task_id_from_pr(pr_title, pr_body)
        
        if task_display_id:
            try:
                task = await task_service.get_task_by_display_id(task_display_id)
                await github_service.create_link(
                    task_id=task.id,
                    link_type=GitHubLinkType.PULL_REQUEST,
                    repository_owner=repo_owner,
                    repository_name=repo_name,
                    url=pr_url,
                    pr_number=pr_number,
                    pr_title=pr_title,
                    pr_status=pr_status,
                )
                return {"status": "linked", "task_id": task_display_id}
            except EntityNotFoundError:
                return {"status": "ignored", "reason": f"task {task_display_id} not found"}
        
        return {"status": "ignored", "reason": "no task ID found in PR"}
    
    elif action in ["closed", "edited", "synchronize", "converted_to_draft", "ready_for_review"]:
        # Update existing link status
        link = await github_service.update_pr_status(
            repository_owner=repo_owner,
            repository_name=repo_name,
            pr_number=pr_number,
            pr_status=pr_status,
            pr_title=pr_title,
        )
        
        if link:
            return {"status": "updated", "link_id": link.id}
        return {"status": "ignored", "reason": "no matching link found"}
    
    return {"status": "ignored", "reason": f"unhandled action: {action}"}
