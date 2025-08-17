from __future__ import annotations
from .. import service


class ListController:
    """
    Thin orchestration layer over the domain service.
    Keeps HTTP concerns (status/headers) out of controllers.
    """

    def head(self, items: list[str], count: int) -> list[str]:
        """Return the first `count` elements of the list."""
        try:
            return service.head(items, count)
        except service.ListServiceError as e:
            raise ValueError(str(e)) from e

    def tail(self, items: list[str], count: int) -> list[str]:
        """Return the last `count` elements of the list."""
        try:
            return service.tail(items, count)
        except service.ListServiceError as e:
            raise ValueError(str(e)) from e
