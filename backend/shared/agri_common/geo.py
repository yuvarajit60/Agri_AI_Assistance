from __future__ import annotations

from pydantic import BaseModel, Field


class Location(BaseModel):
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)


class GeoJSONPolygon(BaseModel):
    """Minimal GeoJSON Polygon wrapper — coordinates follow the
    [ [ [lon, lat], ... ] ] GeoJSON convention (longitude first)."""

    type: str = Field(default="Polygon", frozen=True)
    coordinates: list[list[tuple[float, float]]]
