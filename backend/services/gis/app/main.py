from __future__ import annotations

from datetime import datetime, timezone

from agri_common import DataSource, Location, ModelUsed, RecommendationEnvelope
from fastapi import FastAPI, HTTPException

from .geometry import geodesic_area_and_centroid, polygon_from_geojson
from .providers import MockElevationProvider, classify_drainage, classify_slope, describe_terrain
from .schemas import LandProfileRequest, LandProfileResult

app = FastAPI(title="GIS / Boundary / Elevation Service", version="0.1.0")
_elevation_provider = MockElevationProvider()


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/gis/land-profile", response_model=RecommendationEnvelope[LandProfileResult])
def land_profile(req: LandProfileRequest) -> RecommendationEnvelope[LandProfileResult]:
    try:
        polygon = polygon_from_geojson(req.boundary)
        if not polygon.is_valid or polygon.is_empty:
            raise ValueError("Polygon is empty or self-intersecting.")
    except Exception as exc:  # noqa: BLE001 - surfaced to the caller as a 400
        raise HTTPException(status_code=400, detail=f"Invalid boundary geometry: {exc}") from exc

    area_acres, area_hectares, centroid_lat, centroid_lon = geodesic_area_and_centroid(polygon)
    terrain_sample = _elevation_provider.sample(Location(latitude=centroid_lat, longitude=centroid_lon))
    slope_class = classify_slope(terrain_sample.slope_percent)
    drainage = classify_drainage(terrain_sample.slope_percent)
    terrain_desc = describe_terrain(terrain_sample.slope_percent, terrain_sample.elevation_m)
    now = datetime.now(timezone.utc)

    result = LandProfileResult(
        area_acres=area_acres,
        area_hectares=area_hectares,
        centroid_lat=centroid_lat,
        centroid_lon=centroid_lon,
        elevation_m=terrain_sample.elevation_m,
        slope_percent=terrain_sample.slope_percent,
        slope_class=slope_class,  # type: ignore[arg-type]
        terrain=terrain_desc,
        drainage_capability=drainage,  # type: ignore[arg-type]
    )

    return RecommendationEnvelope[LandProfileResult](
        result=result,
        confidence_score=0.9 if area_acres > 0.05 else 0.5,
        data_sources=[
            DataSource(name="Geodesic area calculation (WGS84)", as_of=now, live=True),
            DataSource(name="DEM elevation/slope sample (mock provider)", as_of=now, live=False),
        ],
        assumptions=[
            "Elevation and slope are from a mock provider — Google Earth Engine DEM integration is not yet configured.",
            "Drainage capability is a coarse slope-based heuristic pending cross-reference with soil texture data.",
        ],
        reasoning=f"Area computed geodesically from the supplied boundary ({area_acres} acres); "
        f"terrain classified as {slope_class} slope based on sampled elevation data.",
        model_used=ModelUsed(name="gis-land-profile", version="0.1.0"),
        action_plan=[],
    )
