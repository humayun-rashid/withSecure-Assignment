from fastapi import APIRouter

# Versioned API root
api_v1 = APIRouter(prefix="/v1", tags=["v1"])
