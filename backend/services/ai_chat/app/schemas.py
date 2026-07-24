from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field


class ChatTurn(BaseModel):
    role: Literal["user", "assistant"]
    content: str


class FarmContext(BaseModel):
    """Deliberately a handful of decision-relevant fields, not the entire
    dashboard payload — the mobile app already has this loaded from its own
    /dashboard call, so it's passed straight through rather than re-fetched
    here (same "client aggregates what it already has" pattern as the
    Market/Fertilizer/Irrigation crop selectors)."""

    farm_area_acres: float | None = None
    land_health_score: float | None = None
    top_recommended_crop: str | None = None
    crop_suitability_percent: float | None = None
    avg_temp_c: float | None = None
    total_rainfall_mm_7d: float | None = None
    irrigation_method: str | None = None
    groundwater_category: str | None = None
    market_commodity: str | None = None
    market_price_low_inr: float | None = None
    market_price_high_inr: float | None = None


class ChatRequest(BaseModel):
    question: str = Field(..., min_length=1)
    history: list[ChatTurn] = Field(default_factory=list, max_length=20)
    context: FarmContext = Field(default_factory=FarmContext)
    language: str = Field("en", pattern="^(en|ta)$")


class ChatResult(BaseModel):
    reply: str
