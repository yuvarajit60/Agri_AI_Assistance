from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field

Season = Literal["kharif", "rabi", "zaid", "any"]
Term = Literal["short-term", "medium-term", "long-term"]
IrrigationMethod = Literal["gravity_fed", "pumped", "limited"]


class CropRecommendationRequest(BaseModel):
    farm_area_acres: float = Field(..., gt=0)
    soil_ph: float = Field(..., ge=0, le=14)
    seasonal_rainfall_mm: float = Field(..., ge=0)
    water_availability_mm: float = Field(..., ge=0, description="Estimated water available to the crop this season")
    current_season: Season = "any"
    soil_confidence: float = Field(0.6, ge=0, le=1, description="Confidence carried over from the Soil service")
    weather_confidence: float = Field(0.8, ge=0, le=1, description="Confidence carried over from the Weather service")
    irrigation_method: IrrigationMethod | None = Field(
        None, description="From the Water Resource Service — a reliable irrigation source lets a crop draw on more than rainfall alone"
    )
    term_filter: Term | None = None
    top_n: int = Field(5, ge=1, le=17)


class CropRecommendationResult(BaseModel):
    crop_name: str
    term: Term
    suitability_percent: float
    expected_yield_quintals: float
    water_requirement_mm: int
    investment_inr: float
    maintenance_cost_inr: float
    expected_profit_inr: float
    time_to_harvest_days: int
    risk_level: Literal["low", "medium", "high"]
    roi_percent: float
