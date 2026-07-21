from __future__ import annotations

from datetime import date

from pydantic import BaseModel, Field


class PriceForecastRequest(BaseModel):
    commodity: str = Field(..., min_length=2, description="Crop/commodity name, e.g. 'Rice' or 'Vegetables (Tomato)'")
    lat: float = Field(..., ge=-90, le=90)
    lon: float = Field(..., ge=-180, le=180)
    language: str = Field("en", pattern="^(en|ta)$")


class MandiInfo(BaseModel):
    name: str
    distance_km: float
    latest_price_inr_per_quintal: float


class ForecastPoint(BaseModel):
    week_start: date
    predicted_price_inr_per_quintal: float
    lower_bound_inr_per_quintal: float
    upper_bound_inr_per_quintal: float


class PriceForecastResult(BaseModel):
    commodity: str
    current_price_inr_per_quintal: float
    near_term_low_inr_per_quintal: float
    near_term_high_inr_per_quintal: float
    best_selling_month: str
    best_selling_month_price_inr_per_quintal: float
    forecast_points: list[ForecastPoint]
    nearby_mandis: list[MandiInfo]
