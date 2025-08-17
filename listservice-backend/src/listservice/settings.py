"""
Runtime settings with sensible defaults.
"""
from __future__ import annotations
import os
from dataclasses import dataclass

@dataclass(frozen=True)
class Settings:
    app_name: str = os.getenv("APP_NAME", "ListService")
    log_level: str = os.getenv("LOG_LEVEL", "INFO").upper()
    # Cache TTL (seconds) for cacheable GET responses
    cache_ttl_seconds: int = int(os.getenv("CACHE_TTL_SECONDS", "60"))
    # CORS (tighten in production)
    cors_allow_origins: str = os.getenv("CORS_ALLOW_ORIGINS", "*")

settings = Settings()
