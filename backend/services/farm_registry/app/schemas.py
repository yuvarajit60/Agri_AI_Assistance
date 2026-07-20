from __future__ import annotations

import uuid
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field

from .models import RESOLUTION_METHODS

ResolutionMethod = Literal[
    "country", "region", "state", "district", "city_village", "survey_number",
    "gps_coordinates", "google_maps_location", "drawn_boundary", "uploaded_document",
    "location_search",
]


class UserCreate(BaseModel):
    phone_number: str = Field(..., min_length=8, max_length=20)


class UserUpdate(BaseModel):
    name: str | None = None
    state: str | None = None
    district: str | None = None
    preferred_language: str | None = None


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    phone_number: str
    name: str | None
    state: str | None
    district: str | None
    preferred_language: str
    created_at: datetime


class GeoJSONPolygon(BaseModel):
    type: Literal["Polygon"] = "Polygon"
    coordinates: list[list[tuple[float, float]]]


class SoilReport(BaseModel):
    """Farmer-submitted lab values — mirrors services/soil/app/schemas.py's
    SoilLabReportRequest fields, minus lat/lon (the farm already has those)."""

    ph: float = Field(..., ge=0, le=14)
    ec_ds_per_m: float = Field(..., ge=0)
    organic_carbon_percent: float = Field(..., ge=0)
    nitrogen_kg_per_ha: float = Field(..., ge=0)
    phosphorus_kg_per_ha: float = Field(..., ge=0)
    potassium_kg_per_ha: float = Field(..., ge=0)


class FarmCreate(BaseModel):
    owner_id: uuid.UUID
    name: str = Field(..., min_length=1, max_length=120)
    resolution_method: ResolutionMethod
    centroid_lat: float = Field(..., ge=-90, le=90)
    centroid_lon: float = Field(..., ge=-180, le=180)
    boundary: GeoJSONPolygon | None = None
    area_acres: float | None = None
    soil_report: SoilReport | None = None


class FarmUpdate(BaseModel):
    name: str | None = Field(None, min_length=1, max_length=120)
    area_acres: float | None = None
    soil_report: SoilReport | None = None
    clear_soil_report: bool = False


class FarmOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    owner_id: uuid.UUID
    name: str
    resolution_method: str
    resolution_confidence: float
    centroid_lat: float
    centroid_lon: float
    area_acres: float | None
    boundary: GeoJSONPolygon | None = None
    soil_report: SoilReport | None = None
    created_at: datetime


assert set(ResolutionMethod.__args__) == set(RESOLUTION_METHODS)  # keep schema/model enums in sync
