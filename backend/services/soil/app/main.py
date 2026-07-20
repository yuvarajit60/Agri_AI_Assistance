from __future__ import annotations

from datetime import datetime, timezone

from agri_common import DataSource, Location, ModelUsed, RecommendationEnvelope
from fastapi import FastAPI

from .providers import SatelliteEstimatedSoilProvider, SoilProperties
from .schemas import SoilAnalysisResult, SoilLabReportRequest
from .scoring import land_health_score

app = FastAPI(title="Soil & Land Health Service", version="0.1.0")
_provider = SatelliteEstimatedSoilProvider()

ESTIMATE_CONFIDENCE = 0.55
LAB_REPORT_CONFIDENCE = 0.92


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/soil/analyze", response_model=RecommendationEnvelope[SoilAnalysisResult])
def analyze(lat: float, lon: float) -> RecommendationEnvelope[SoilAnalysisResult]:
    """No lab report path (Soil Health Card lookup will plug in here —
    see docs/architecture/DATA_SOURCES.md). Always estimated for now."""
    location = Location(latitude=lat, longitude=lon)
    soil: SoilProperties = _provider.estimate(location)
    score, sub_indices = land_health_score(soil)
    now = datetime.now(timezone.utc)

    result = SoilAnalysisResult(
        land_health_score=score,
        sub_indices=sub_indices,
        is_lab_report=False,
        **soil.__dict__,
    )

    return RecommendationEnvelope[SoilAnalysisResult](
        result=result,
        confidence_score=ESTIMATE_CONFIDENCE,
        data_sources=[
            DataSource(name="Satellite spectral-index soil estimate (mock provider)", as_of=now, live=False),
        ],
        assumptions=[
            "No Soil Health Card or lab report found for this location — all values are satellite/regional-prior estimates.",
            "Estimated values can be off by a wide margin for micro-scale variation within the farm.",
        ],
        reasoning=f"Land Health Score of {score}/100 computed from estimated fertility, organic carbon, "
        "NPK balance, pH suitability, moisture, erosion, salinity and degradation sub-indices.",
        model_used=ModelUsed(name="satellite-soil-estimator", version="0.1.0"),
        risk_analysis=None,
        action_plan=["Get a lab soil test to replace these estimated values and unlock full-confidence recommendations."],
    )


@app.post("/soil/lab-report", response_model=RecommendationEnvelope[SoilAnalysisResult])
def submit_lab_report(req: SoilLabReportRequest) -> RecommendationEnvelope[SoilAnalysisResult]:
    """Farmer-submitted values take over pH/EC/organic carbon/NPK; the
    environmental sub-indices a standard lab report doesn't cover
    (moisture, erosion, salinity, degradation) still come from the
    satellite estimate."""
    location = Location(latitude=req.lat, longitude=req.lon)
    environmental = _provider.estimate(location)

    soil = SoilProperties(
        fertility_index=0,  # filled in below, once organic_carbon/npk sub-indices are known
        organic_carbon_percent=req.organic_carbon_percent,
        nitrogen_kg_per_ha=req.nitrogen_kg_per_ha,
        phosphorus_kg_per_ha=req.phosphorus_kg_per_ha,
        potassium_kg_per_ha=req.potassium_kg_per_ha,
        ph=req.ph,
        ec_ds_per_m=req.ec_ds_per_m,
        moisture_percent=environmental.moisture_percent,
        salinity_index=environmental.salinity_index,
        erosion_risk=environmental.erosion_risk,
        degradation_index=environmental.degradation_index,
    )
    _, preview_sub_indices = land_health_score(soil)
    soil.fertility_index = round(
        (preview_sub_indices["organic_carbon_index"] + preview_sub_indices["npk_balance_index"]) / 2, 2
    )
    score, sub_indices = land_health_score(soil)
    now = datetime.now(timezone.utc)

    result = SoilAnalysisResult(land_health_score=score, sub_indices=sub_indices, is_lab_report=True, **soil.__dict__)

    return RecommendationEnvelope[SoilAnalysisResult](
        result=result,
        confidence_score=LAB_REPORT_CONFIDENCE,
        data_sources=[
            DataSource(name="Farmer-submitted soil test report", as_of=now, live=True),
            DataSource(name="Satellite estimate (moisture/erosion/salinity/degradation only)", as_of=now, live=False),
        ],
        assumptions=[
            "pH, EC, organic carbon and NPK are from your submitted report.",
            "Moisture, erosion risk, salinity and degradation aren't part of a standard soil test — "
            "those are still satellite-estimated.",
        ],
        reasoning=f"Land Health Score of {score}/100 computed from your submitted lab values for fertility, "
        "organic carbon, NPK balance and pH, blended with satellite-derived environmental factors.",
        model_used=ModelUsed(name="lab-report-scorer", version="0.1.0"),
        risk_analysis=None,
        action_plan=[],
    )
