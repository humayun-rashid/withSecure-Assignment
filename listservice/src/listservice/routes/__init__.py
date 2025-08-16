from fastapi import APIRouter

# Versioned API root. Mount feature routers under this.
api_v1 = APIRouter(prefix="/v1", tags=["v1"])
