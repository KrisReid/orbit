"""
Unit tests for security utilities.

Tests JWT token generation/verification and password hashing.
"""

from datetime import timedelta


from app.core.security import (
    verify_password,
    get_password_hash,
    create_access_token,
    decode_token,
)


class TestPasswordHashing:
    """Tests for password hashing utilities."""

    def test_password_hash_creates_valid_hash(self):
        """Password hash should be different from plain text."""
        password = "testpassword123"
        hashed = get_password_hash(password)

        assert hashed != password
        assert len(hashed) > 0

    def test_password_hash_is_unique(self):
        """Same password should produce different hashes (due to salt)."""
        password = "testpassword123"
        hash1 = get_password_hash(password)
        hash2 = get_password_hash(password)

        assert hash1 != hash2

    def test_verify_password_correct(self):
        """Correct password should verify successfully."""
        password = "testpassword123"
        hashed = get_password_hash(password)

        assert verify_password(password, hashed) is True

    def test_verify_password_incorrect(self):
        """Incorrect password should fail verification."""
        password = "testpassword123"
        wrong_password = "wrongpassword"
        hashed = get_password_hash(password)

        assert verify_password(wrong_password, hashed) is False

    def test_verify_password_empty(self):
        """Empty password should fail verification."""
        password = "testpassword123"
        hashed = get_password_hash(password)

        assert verify_password("", hashed) is False


class TestJWTTokens:
    """Tests for JWT token creation and verification."""

    def test_create_access_token_basic(self):
        """Should create a valid JWT token."""
        data = {"sub": "123"}
        token = create_access_token(data)

        assert token is not None
        assert len(token) > 0
        assert token.count(".") == 2  # JWT has 3 parts

    def test_create_access_token_with_custom_expiry(self):
        """Should create token with custom expiry."""
        data = {"sub": "123"}
        expires = timedelta(minutes=30)
        token = create_access_token(data, expires_delta=expires)

        decoded = decode_token(token)
        assert decoded is not None
        assert "exp" in decoded

    def test_decode_token_valid(self):
        """Valid token should decode successfully."""
        data = {"sub": "123", "custom": "value"}
        token = create_access_token(data)

        decoded = decode_token(token)

        assert decoded is not None
        assert decoded["sub"] == "123"
        assert decoded["custom"] == "value"
        assert "exp" in decoded

    def test_decode_token_invalid(self):
        """Invalid token should return None."""
        invalid_token = "invalid.token.here"

        decoded = decode_token(invalid_token)

        assert decoded is None

    def test_decode_token_tampered(self):
        """Tampered token should return None."""
        data = {"sub": "123"}
        token = create_access_token(data)

        # Tamper with the token
        parts = token.split(".")
        parts[1] = parts[1][:-4] + "XXXX"  # Modify payload
        tampered_token = ".".join(parts)

        decoded = decode_token(tampered_token)

        assert decoded is None

    def test_decode_token_empty(self):
        """Empty token should return None."""
        assert decode_token("") is None

    def test_token_contains_subject(self):
        """Token should properly encode subject claim."""
        user_id = "42"
        token = create_access_token(data={"sub": user_id})

        decoded = decode_token(token)

        assert decoded["sub"] == user_id
