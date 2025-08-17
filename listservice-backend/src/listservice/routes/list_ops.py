from __future__ import annotations
import hashlib, json
from typing import Optional
from fastapi import APIRouter, Query, Body, Response, status, Depends

from ..schemas import ListOpRequest, ListOpResponse
from ..settings import settings
from ..controllers.list_controller import ListController
from ..deps import get_list_controller

router = APIRouter(prefix="/lists", tags=["lists"])

def _set_cache_headers(response: Response, payload: dict, cacheable: bool) -> None:
    if cacheable and response.status_code == 200:
        body = json.dumps(payload, separators=(",", ":")).encode()
        ttl = settings.cache_ttl_seconds
        response.headers["Cache-Control"] = f"public, max-age={ttl}, s-maxage={ttl}"
        response.headers["ETag"] = hashlib.sha256(body).hexdigest()
    else:
        response.headers["Cache-Control"] = "no-store"

def _parse_csv_list(s: Optional[str]) -> list[str]:
    return [p.strip() for p in s.split(",") if p.strip()] if s else []

# ---------- GET (cacheable) ----------
@router.get("/head", response_model=ListOpResponse)
def get_head(
    response: Response,
    list_param: Optional[str] = Query(None, alias="list", description="Comma-separated strings"),
    count: int = Query(1, ge=0),
    ctrl: ListController = Depends(get_list_controller),
):
    try:
        result = ctrl.head(_parse_csv_list(list_param), count)
        payload, response.status_code = {"result": result}, status.HTTP_200_OK
    except ValueError as e:
        payload, response.status_code = {"error": str(e)}, status.HTTP_400_BAD_REQUEST
    _set_cache_headers(response, payload, cacheable=True)
    return payload

@router.get("/tail", response_model=ListOpResponse)
def get_tail(
    response: Response,
    list_param: Optional[str] = Query(None, alias="list", description="Comma-separated strings"),
    count: int = Query(1, ge=0),
    ctrl: ListController = Depends(get_list_controller),
):
    try:
        result = ctrl.tail(_parse_csv_list(list_param), count)
        payload, response.status_code = {"result": result}, status.HTTP_200_OK
    except ValueError as e:
        payload, response.status_code = {"error": str(e)}, status.HTTP_400_BAD_REQUEST
    _set_cache_headers(response, payload, cacheable=True)
    return payload

# ---------- POST (non-cacheable) ----------
@router.post("/head", response_model=ListOpResponse)
def post_head(
    response: Response,
    body: ListOpRequest = Body(...),
    ctrl: ListController = Depends(get_list_controller),
):
    try:
        result = ctrl.head(body.items, body.count)
        payload, response.status_code = {"result": result}, status.HTTP_200_OK
    except ValueError as e:
        payload, response.status_code = {"error": str(e)}, status.HTTP_400_BAD_REQUEST
    _set_cache_headers(response, payload, cacheable=False)
    return payload

@router.post("/tail", response_model=ListOpResponse)
def post_tail(
    response: Response,
    body: ListOpRequest = Body(...),
    ctrl: ListController = Depends(get_list_controller),
):
    try:
        result = ctrl.tail(body.items, body.count)
        payload, response.status_code = {"result": result}, status.HTTP_200_OK
    except ValueError as e:
        payload, response.status_code = {"error": str(e)}, status.HTTP_400_BAD_REQUEST
    _set_cache_headers(response, payload, cacheable=False)
    return payload
