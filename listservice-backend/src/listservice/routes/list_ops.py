from __future__ import annotations
import hashlib, json
from typing import Optional, Callable
from fastapi import APIRouter, Query, Body, Response, status, Depends

from ..schemas import ListOpRequest, ListOpResponse
from ..settings import settings
from ..controllers.list_controller import ListController
from ..deps import get_list_controller

router = APIRouter(
    prefix="/lists",
    tags=["List Operations"],
    responses={400: {"description": "Invalid input"}},
)


# ------------------------------
# Helpers
# ------------------------------

def _set_cache_headers(response: Response, payload: dict, cacheable: bool) -> None:
    """Attach appropriate caching headers to the response."""
    if cacheable and response.status_code == 200:
        body = json.dumps(payload, separators=(",", ":")).encode()
        ttl = settings.cache_ttl_seconds
        response.headers["Cache-Control"] = f"public, max-age={ttl}, s-maxage={ttl}"
        response.headers["ETag"] = hashlib.sha256(body).hexdigest()
    else:
        response.headers["Cache-Control"] = "no-store"


def _parse_csv_list(s: Optional[str]) -> list[str]:
    """Convert comma-separated query string into list of strings."""
    return [p.strip() for p in s.split(",") if p.strip()] if s else []


def _handle_request(
    response: Response,
    func: Callable[..., list[str]],
    items: list[str],
    count: int,
    cacheable: bool,
) -> dict:
    """Shared logic for invoking controller functions and formatting response."""
    try:
        result = func(items, count)
        payload, response.status_code = {"result": result}, status.HTTP_200_OK
    except ValueError as e:
        payload, response.status_code = {"error": str(e)}, status.HTTP_400_BAD_REQUEST

    _set_cache_headers(response, payload, cacheable=cacheable)
    return payload


# ------------------------------
# GET (cacheable)
# ------------------------------

@router.get(
    "/head",
    response_model=ListOpResponse,
    summary="Get first N elements",
    description="""
Return the first **N** elements of the provided list.  
Input is a comma-separated string via query parameter `list`.

✅ Cacheable (ETag + Cache-Control headers)
""",
    responses={200: {"description": "First N elements"}},
)
def get_head(
    response: Response,
    list_param: Optional[str] = Query(
        None,
        alias="list",
        description="Comma-separated strings, e.g. `foo,bar,baz`",
        example="foo,bar,baz",
    ),
    count: int = Query(1, ge=0, description="Number of items to return", example=2),
    ctrl: ListController = Depends(get_list_controller),
):
    return _handle_request(response, ctrl.head, _parse_csv_list(list_param), count, cacheable=True)


@router.get(
    "/tail",
    response_model=ListOpResponse,
    summary="Get last N elements",
    description="""
Return the last **N** elements of the provided list.  
Input is a comma-separated string via query parameter `list`.

✅ Cacheable (ETag + Cache-Control headers)
""",
    responses={200: {"description": "Last N elements"}},
)
def get_tail(
    response: Response,
    list_param: Optional[str] = Query(
        None,
        alias="list",
        description="Comma-separated strings, e.g. `foo,bar,baz`",
        example="foo,bar,baz",
    ),
    count: int = Query(1, ge=0, description="Number of items to return", example=2),
    ctrl: ListController = Depends(get_list_controller),
):
    return _handle_request(response, ctrl.tail, _parse_csv_list(list_param), count, cacheable=True)


# ------------------------------
# POST (non-cacheable)
# ------------------------------

@router.post(
    "/head",
    response_model=ListOpResponse,
    summary="Get first N elements (POST)",
    description="""
Same as GET `/lists/head`, but accepts a JSON body instead of query parameters.  
Use this for larger inputs or structured clients.

❌ Not cacheable
""",
    responses={200: {"description": "First N elements"}},
)
def post_head(
    response: Response,
    body: ListOpRequest = Body(
        ...,
        example={"list": ["one", "two", "three"], "count": 2},
    ),
    ctrl: ListController = Depends(get_list_controller),
):
    return _handle_request(response, ctrl.head, body.items, body.count, cacheable=False)


@router.post(
    "/tail",
    response_model=ListOpResponse,
    summary="Get last N elements (POST)",
    description="""
Same as GET `/lists/tail`, but accepts a JSON body instead of query parameters.  
Use this for larger inputs or structured clients.

❌ Not cacheable
""",
    responses={200: {"description": "Last N elements"}},
)
def post_tail(
    response: Response,
    body: ListOpRequest = Body(
        ...,
        example={"list": ["one", "two", "three"], "count": 2},
    ),
    ctrl: ListController = Depends(get_list_controller),
):
    return _handle_request(response, ctrl.tail, body.items, body.count, cacheable=False)
