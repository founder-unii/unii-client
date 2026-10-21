from typing import Any, Optional


class UniiError(Exception):
    """Base exception for Unii SDK."""
    pass


class UniiApiError(UniiError):
    """Exception raised when server returns non-2xx status code."""
    def __init__(self, status: int, message: str, body: Optional[Any] = None) -> None:
        super().__init__(f"HTTP {status}: {message}")
        self.status = status
        self.message = message
        self.body = body
