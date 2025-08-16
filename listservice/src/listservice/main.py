from __future__ import annotations
import logging
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .settings import settings
from .routes import api_v1
from .routes import health as health_routes
from .routes import list_ops as list_routes

LOG = logging.getLogger("listservice")
logging.basicConfig(level=getattr(logging, settings.log_level, logging.INFO))

app = FastAPI(
    title=settings.app_name,
    version="1.0.0",
    description="Serverless ListService: head/tail operations. Versioned under /v1.",
)

# CORS (tighten for production)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"] if settings.cors_allow_origins == "*" else [settings.cors_allow_origins],
    allow_credentials=False,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["*"],
)

# Unversioned health endpoint
app.include_router(health_routes.router)

# Versioned API
api_v1.include_router(list_routes.router)
app.include_router(api_v1)
