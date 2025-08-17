"""
Pydantic (v2) models for request/response contracts.
"""
from __future__ import annotations
from typing import List
from pydantic import BaseModel, Field, ConfigDict

class ListOpRequest(BaseModel):
    items: List[str] = Field(alias="list", description="Array of strings to operate on")
    count: int = Field(default=1, ge=0, description="How many items to return/skip")
    model_config = ConfigDict(populate_by_name=True, extra="forbid")

class ListOpResponse(BaseModel):
    result: List[str]
