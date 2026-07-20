from __future__ import annotations

from pydantic import BaseModel, Field


class SoilAnalysisResult(BaseModel):
    land_health_score: float
    sub_indices: dict[str, float]
    fertility_index: float
    organic_carbon_percent: float
    nitrogen_kg_per_ha: float
    phosphorus_kg_per_ha: float
    potassium_kg_per_ha: float
    ph: float
    ec_ds_per_m: float
    moisture_percent: float
    salinity_index: float
    erosion_risk: float
    degradation_index: float
    is_lab_report: bool


class SoilLabReportRequest(BaseModel):
    """Values a farmer would read straight off a Soil Health Card or lab
    report. Moisture/erosion/salinity/degradation aren't part of a
    standard report, so those stay satellite-estimated even here — see
    docs/architecture/MODULES.md §4."""

    lat: float = Field(..., ge=-90, le=90)
    lon: float = Field(..., ge=-180, le=180)
    ph: float = Field(..., ge=0, le=14)
    ec_ds_per_m: float = Field(..., ge=0)
    organic_carbon_percent: float = Field(..., ge=0)
    nitrogen_kg_per_ha: float = Field(..., ge=0)
    phosphorus_kg_per_ha: float = Field(..., ge=0)
    potassium_kg_per_ha: float = Field(..., ge=0)
