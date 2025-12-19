"""
Unit tests for domain exceptions.

Tests exception creation and attribute access.
"""
import pytest

from app.domain.exceptions import (
    DomainException,
    EntityNotFoundError,
    EntityAlreadyExistsError,
    ValidationError,
    AuthenticationError,
    AuthorizationError,
    BusinessRuleViolation,
    DependencyError,
    IntegrationError,
)


class TestDomainException:
    """Tests for base DomainException."""
    
    def test_message_is_set(self):
        """Exception should store message."""
        exc = DomainException("Test message")
        
        assert exc.message == "Test message"
        assert str(exc) == "Test message"
    
    def test_details_default_empty(self):
        """Details should default to empty dict."""
        exc = DomainException("Test")
        
        assert exc.details == {}
    
    def test_details_can_be_provided(self):
        """Details should be stored when provided."""
        details = {"key": "value", "count": 42}
        exc = DomainException("Test", details=details)
        
        assert exc.details == details


class TestEntityNotFoundError:
    """Tests for EntityNotFoundError."""
    
    def test_message_format(self):
        """Should format message with entity type and ID."""
        exc = EntityNotFoundError("User", 123)
        
        assert exc.message == "User with id 123 not found"
        assert exc.entity_type == "User"
        assert exc.entity_id == 123
    
    def test_details_contain_entity_info(self):
        """Details should contain entity type and ID."""
        exc = EntityNotFoundError("Project", "abc-123")
        
        assert exc.details["entity_type"] == "Project"
        assert exc.details["entity_id"] == "abc-123"
    
    def test_string_id_support(self):
        """Should support string IDs (like slugs)."""
        exc = EntityNotFoundError("Team", "engineering")
        
        assert "engineering" in exc.message


class TestEntityAlreadyExistsError:
    """Tests for EntityAlreadyExistsError."""
    
    def test_message_format(self):
        """Should format message with entity, field, and value."""
        exc = EntityAlreadyExistsError("User", "email", "test@example.com")
        
        assert exc.message == "User with email=test@example.com already exists"
    
    def test_details_contain_field_info(self):
        """Details should contain field and value."""
        exc = EntityAlreadyExistsError("Team", "slug", "engineering")
        
        assert exc.details["entity_type"] == "Team"
        assert exc.details["field"] == "slug"
        assert exc.details["value"] == "engineering"


class TestValidationError:
    """Tests for ValidationError."""
    
    def test_message_only(self):
        """Should work with just a message."""
        exc = ValidationError("Invalid input")
        
        assert exc.message == "Invalid input"
        assert exc.details == {}
    
    def test_with_field(self):
        """Should include field in details when provided."""
        exc = ValidationError("Must be positive", field="amount")
        
        assert exc.details["field"] == "amount"


class TestAuthenticationError:
    """Tests for AuthenticationError."""
    
    def test_default_message(self):
        """Should have default message."""
        exc = AuthenticationError()
        
        assert exc.message == "Invalid credentials"
    
    def test_custom_message(self):
        """Should accept custom message."""
        exc = AuthenticationError("Token expired")
        
        assert exc.message == "Token expired"


class TestAuthorizationError:
    """Tests for AuthorizationError."""
    
    def test_default_message(self):
        """Should have default message."""
        exc = AuthorizationError()
        
        assert exc.message == "Not authorized to perform this action"
    
    def test_custom_message(self):
        """Should accept custom message."""
        exc = AuthorizationError("Admin access required")
        
        assert exc.message == "Admin access required"


class TestBusinessRuleViolation:
    """Tests for BusinessRuleViolation."""
    
    def test_rule_and_message(self):
        """Should store rule name and message."""
        exc = BusinessRuleViolation(
            rule="unique_email",
            message="Email must be unique per organization"
        )
        
        assert exc.rule == "unique_email"
        assert exc.message == "Email must be unique per organization"
        assert exc.details["rule"] == "unique_email"


class TestDependencyError:
    """Tests for DependencyError."""
    
    def test_message_only(self):
        """Should work with just a message."""
        exc = DependencyError("Cannot delete: has dependencies")
        
        assert exc.message == "Cannot delete: has dependencies"
        assert exc.details["blocking_entities"] == []
    
    def test_with_blocking_entities(self):
        """Should include blocking entities when provided."""
        exc = DependencyError(
            "Cannot delete team",
            blocking_entities=[1, 2, 3]
        )
        
        assert exc.details["blocking_entities"] == [1, 2, 3]


class TestIntegrationError:
    """Tests for IntegrationError."""
    
    def test_formats_service_and_message(self):
        """Should format message with service name."""
        exc = IntegrationError("GitHub", "Rate limit exceeded")
        
        assert exc.message == "GitHub integration error: Rate limit exceeded"
        assert exc.details["service"] == "GitHub"
