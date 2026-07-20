from __future__ import annotations

from datetime import datetime
from typing import Any, Literal

from pydantic import BaseModel


class DashboardResponse(BaseModel):
    generated_at: datetime
    farm: dict[str, float]
    land_health: dict[str, Any] | None
    weather: dict[str, Any] | None
    crop_recommendations: dict[str, Any] | None
    warnings: list[str] = []


class CropRequestOverrides(BaseModel):
    current_season: Literal["kharif", "rabi", "zaid", "any"] = "any"
    water_availability_mm: float | None = None
