from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field

SlopeClass = Literal["flat", "gentle", "moderate", "steep"]
DrainageClass = Literal["poor", "moderate", "good"]


class GeoJSONPolygonIn(BaseModel):
    type: Literal["Polygon"] = "Polygon"
    coordinates: list[list[tuple[float, float]]] = Field(
        ..., description="GeoJSON ring(s), [lon, lat] pairs, first/last point repeated to close the ring"
    )


class LandProfileRequest(BaseModel):
    boundary: GeoJSONPolygonIn


class LandProfileResult(BaseModel):
    area_acres: float
    area_hectares: float
    centroid_lat: float
    centroid_lon: float
    elevation_m: float
    slope_percent: float
    slope_class: SlopeClass
    terrain: str
    drainage_capability: DrainageClass
