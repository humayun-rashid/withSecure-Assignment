"""
Business logic (pure functions). Easy to unit test.
"""

from __future__ import annotations
from typing import List


class ListServiceError(ValueError):
    """Custom exception for invalid list operations."""
    pass


def validate(items: List[str], count: int) -> None:
    """Validate inputs before performing list operations."""
    if not isinstance(items, list) or not all(isinstance(x, str) for x in items):
        raise ListServiceError("'list' must be an array of strings")
    if not isinstance(count, int):
        raise ListServiceError("'count' must be an integer")
    if count < 0:
        raise ListServiceError("'count' must be >= 0")
    if count > len(items):
        raise ListServiceError("'count' cannot exceed the length of 'list'")


def head(items: List[str], count: int = 1) -> List[str]:
    """
    Return the first `count` elements of the list.
    Example: head(["a","b","c"], 2) → ["a","b"]
    """
    validate(items, count)
    return items[:count]


def tail(items: List[str], count: int = 1) -> List[str]:
    """
    Return the last `count` elements of the list.
    Example: tail(["a","b","c"], 2) → ["b","c"]
    """
    validate(items, count)
    return items[-count:] if count > 0 else []
