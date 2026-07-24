from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field


class FertilizerRecommendationRequest(BaseModel):
    crop_name: str = Field(..., description="Recommended/chosen crop, e.g. from the Crop Recommendation service")
    farm_area_acres: float = Field(..., gt=0)
    soil_nitrogen_kg_per_ha: float = Field(..., ge=0)
    soil_phosphorus_kg_per_ha: float = Field(
        ..., ge=0, description="Treated as P2O5-equivalent — see response assumptions"
    )
    soil_potassium_kg_per_ha: float = Field(
        ..., ge=0, description="Treated as K2O-equivalent — see response assumptions"
    )
    soil_ph: float = Field(..., ge=0, le=14)
    organic_carbon_percent: float = Field(..., ge=0)
    soil_confidence: float = Field(0.6, ge=0, le=1, description="Confidence carried over from the Soil service")
    language: str = Field("en", pattern="^(en|ta)$")


class NutrientGap(BaseModel):
    nitrogen_kg_per_ha: float
    phosphorus_p2o5_kg_per_ha: float
    potassium_k2o_kg_per_ha: float


class ProductQuantity(BaseModel):
    product: str
    nutrient_supplied: str
    quantity_kg_total: float = Field(..., description="Total quantity for the whole farm area, not per hectare")


# Fixed-vocabulary tokens (not prose) so the mobile app can translate them
# client-side, the same way it already does for water's irrigation_method /
# groundwater_category enum values.
ApplicationStageToken = Literal["basal", "top_dressing_1", "none_needed"]
ApplicationTimingToken = Literal["at_sowing", "vegetative_stage", "none"]


class ApplicationStage(BaseModel):
    stage: ApplicationStageToken
    timing: ApplicationTimingToken
    products: list[str]


class FertilizerRecommendationResult(BaseModel):
    crop_name: str
    crop_reference_matched: bool = Field(..., description="False if the crop wasn't found and a generic fallback requirement was used")
    nutrient_gap_per_ha: NutrientGap
    products: list[ProductQuantity]
    ph_correction: str | None = None
    organic_matter_note: str | None = None
    application_schedule: list[ApplicationStage]
