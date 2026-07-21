from __future__ import annotations

from datetime import datetime, timezone

from agri_common import DataSource, Location, ModelUsed, RecommendationEnvelope
from fastapi import FastAPI

from .providers import MockWaterResourceProvider
from .schemas import WaterResourceResult

app = FastAPI(title="Water Resource Service", version="0.1.0")
_provider = MockWaterResourceProvider()

ESTIMATE_CONFIDENCE = 0.5


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/water/analyze", response_model=RecommendationEnvelope[WaterResourceResult])
def analyze(lat: float, lon: float) -> RecommendationEnvelope[WaterResourceResult]:
    """Surface water proximity, groundwater feasibility, and irrigation
    method suitability for a location — see docs/architecture/MODULES.md
    §3. Real ingestion (JRC/India-WRIS/OSM water-bodies layer + CGWB
    groundwater categories) isn't wired up yet; this always returns a
    clearly-labeled estimate."""
    location = Location(latitude=lat, longitude=lon)
    data = _provider.assess(location)
    now = datetime.now(timezone.utc)

    result = WaterResourceResult(
        features=data.features,
        groundwater=data.groundwater,
        irrigation_feasibility=data.irrigation_feasibility,
    )

    return RecommendationEnvelope[WaterResourceResult](
        result=result,
        confidence_score=ESTIMATE_CONFIDENCE,
        data_sources=[
            DataSource(name="Water-bodies proximity estimate (mock provider)", as_of=now, live=False),
            DataSource(name="CGWB groundwater category estimate (mock provider)", as_of=now, live=False),
        ],
        assumptions=[
            "No real water-bodies or CGWB groundwater dataset is ingested yet — feature list, distances "
            "and groundwater category are estimated, not measured.",
            "Irrigation feasibility is a rough method suggestion (gravity-fed / pumped / limited), not an "
            "engineering assessment — a site visit is needed before investing in irrigation infrastructure.",
        ],
        reasoning=f"Found {len(result.features)} nearby water feature(s) in the estimate; groundwater block "
        f"status is '{result.groundwater.category.value}' with an irrigation method suggestion of "
        f"'{result.irrigation_feasibility.method.value}'.",
        model_used=ModelUsed(name="water-resource-estimator", version="0.1.0"),
        risk_analysis=None,
        action_plan=[
            "Verify groundwater category and borewell permissions with your local CGWB/irrigation "
            "department office before drilling.",
            "Confirm surface water access rights (canal/reservoir allocation) with the relevant irrigation "
            "authority before planning irrigation infrastructure.",
        ],
    )
