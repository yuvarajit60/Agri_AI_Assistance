from __future__ import annotations

from pyproj import Geod
from shapely.geometry import Polygon, shape

from .schemas import GeoJSONPolygonIn

_GEOD = Geod(ellps="WGS84")

SQ_METERS_PER_ACRE = 4046.8564224
SQ_METERS_PER_HECTARE = 10000


def polygon_from_geojson(boundary: GeoJSONPolygonIn) -> Polygon:
    return shape(boundary.model_dump())


def geodesic_area_and_centroid(polygon: Polygon) -> tuple[float, float, float, float]:
    """Returns (area_acres, area_hectares, centroid_lat, centroid_lon)."""
    area_m2, _perimeter_m = _GEOD.geometry_area_perimeter(polygon)
    area_m2 = abs(area_m2)
    centroid = polygon.centroid
    return (
        round(area_m2 / SQ_METERS_PER_ACRE, 3),
        round(area_m2 / SQ_METERS_PER_HECTARE, 3),
        round(centroid.y, 6),
        round(centroid.x, 6),
    )
