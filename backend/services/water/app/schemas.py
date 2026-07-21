from __future__ import annotations

from enum import Enum

from pydantic import BaseModel, Field


class WaterFeatureType(str, Enum):
    RIVER = "river"
    CANAL = "canal"
    LAKE = "lake"
    POND = "pond"
    WELL = "well"
    BOREWELL = "borewell"
    RESERVOIR = "reservoir"
    CHECK_DAM = "check_dam"
    IRRIGATION_CHANNEL = "irrigation_channel"


class SeasonalAvailability(str, Enum):
    PERENNIAL = "perennial"
    SEASONAL = "seasonal"
    MONSOON_ONLY = "monsoon_only"


class WaterFeature(BaseModel):
    type: WaterFeatureType
    name: str | None = Field(None, description="Known name if available, e.g. a named river or reservoir")
    distance_km: float = Field(..., ge=0)
    seasonal_availability: SeasonalAvailability
    estimated_water_availability: str = Field(
        ..., description="Plain-language availability rating: low / moderate / high"
    )


class GroundwaterCategory(str, Enum):
    """CGWB (Central Ground Water Board) block-level assessment categories."""

    SAFE = "safe"
    SEMI_CRITICAL = "semi_critical"
    CRITICAL = "critical"
    OVER_EXPLOITED = "over_exploited"


class GroundwaterAssessment(BaseModel):
    category: GroundwaterCategory
    depth_to_water_table_m: float = Field(..., ge=0)
    borewell_feasibility: str = Field(..., description="Plain-language feasibility rating for drilling a borewell here")


class IrrigationMethod(str, Enum):
    GRAVITY_FED = "gravity_fed"
    PUMPED = "pumped"
    LIMITED = "limited"


class IrrigationFeasibility(BaseModel):
    method: IrrigationMethod
    nearest_source_distance_km: float | None = Field(None, ge=0)
    farm_elevation_relative_m: float = Field(
        ..., description="Farm elevation minus nearest water source elevation; negative means the farm sits lower"
    )
    notes: str


class WaterResourceResult(BaseModel):
    features: list[WaterFeature]
    groundwater: GroundwaterAssessment
    irrigation_feasibility: IrrigationFeasibility
