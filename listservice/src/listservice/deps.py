"""
FastAPI dependencies. This is where you'd wire clients, caches, etc.
"""
from __future__ import annotations
from .controllers.list_controller import ListController

_controller = ListController()

def get_list_controller() -> ListController:
    # Swap this out for mocks in tests, or construct richer controllers here.
    return _controller
