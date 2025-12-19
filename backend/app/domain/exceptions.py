"""
Domain exceptions for business logic errors.

These exceptions represent business rule violations and are distinct
from HTTP errors. They are translated to appropriate HTTP responses
by the exception handlers in the API layer.
"""

from typing import Any


class DomainException(Exception):
    """Base exception for all domain errors."""

    def __init__(self, message: str, details: dict[str, Any] | None = None):
        self.message = message
        self.details = details or {}
        super().__init__(self.message)


class EntityNotFoundError(DomainException):
    """Raised when a requested entity does not exist."""

    def __init__(self, entity_type: str, entity_id: Any):
        super().__init__(
            message=f"{entity_type} with id {entity_id} not found",
            details={"entity_type": entity_type, "entity_id": entity_id},
        )
        self.entity_type = entity_type
        self.entity_id = entity_id


class EntityAlreadyExistsError(DomainException):
    """Raised when attempting to create a duplicate entity."""

    def __init__(self, entity_type: str, field: str, value: Any):
        super().__init__(
            message=f"{entity_type} with {field}={value} already exists",
            details={"entity_type": entity_type, "field": field, "value": value},
        )


class ValidationError(DomainException):
    """Raised when input validation fails."""

    def __init__(self, message: str, field: str | None = None):
        super().__init__(message=message, details={"field": field} if field else {})


class AuthenticationError(DomainException):
    """Raised when authentication fails."""

    def __init__(self, message: str = "Invalid credentials"):
        super().__init__(message=message)


class AuthorizationError(DomainException):
    """Raised when authorization fails."""

    def __init__(self, message: str = "Not authorized to perform this action"):
        super().__init__(message=message)


class BusinessRuleViolation(DomainException):
    """Raised when a business rule is violated."""

    def __init__(self, rule: str, message: str):
        super().__init__(message=message, details={"rule": rule})
        self.rule = rule


class DependencyError(DomainException):
    """Raised when there's an issue with entity dependencies."""

    def __init__(self, message: str, blocking_entities: list[Any] | None = None):
        super().__init__(
            message=message, details={"blocking_entities": blocking_entities or []}
        )


class IntegrationError(DomainException):
    """Raised when an external integration fails."""

    def __init__(self, service: str, message: str):
        super().__init__(
            message=f"{service} integration error: {message}",
            details={"service": service},
        )
