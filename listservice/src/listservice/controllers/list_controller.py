from __future__ import annotations
from .. import service

class ListController:
    """
    Thin orchestration layer over the domain service.
    Keep HTTP concerns (status/headers) out of controllers.
    """
    def head(self, items: list[str], count: int) -> list[str]:
        return service.head(items, count)

    def tail(self, items: list[str], count: int) -> list[str]:
        return service.tail(items, count)
