from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field

IrrigationMethod = Literal["gravity_fed", "pumped", "limited"]


class IrrigationPlanRequest(BaseModel):
    crop_name: str
    crop_water_requirement_mm: float = Field(..., gt=0, description="Season-total water requirement, e.g. from the Crop Recommendation service")
    crop_duration_days: int = Field(120, gt=0, description="Season length — from the Crop Recommendation service's time_to_harvest_days if available")
    farm_area_acres: float = Field(..., gt=0)
    irrigation_method: IrrigationMethod | None = Field(
        None, description="From the Water Resource service — None is treated as 'limited' with reduced confidence"
    )
    soil_moisture_percent: float | None = Field(None, ge=0, le=100, description="From the Soil service, if available")
    language: str = Field("en", pattern="^(en|ta)$")


class IrrigationScheduleEntry(BaseModel):
    irrigation_number: int
    day_offset: int = Field(..., description="Days after sowing/transplanting")
    volume_liters: float


class IrrigationPlanResult(BaseModel):
    crop_name: str
    method: IrrigationMethod
    method_assumed: bool = Field(..., description="True if irrigation_method wasn't supplied and 'limited' was assumed")
    application_efficiency_percent: int
    total_water_requirement_liters: float
    number_of_irrigations: int
    frequency_days: int
    per_irrigation_volume_liters: float
    method_notes: str
    critical_stage_alert: str
    schedule: list[IrrigationScheduleEntry]
