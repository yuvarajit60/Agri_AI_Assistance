from __future__ import annotations

from datetime import datetime, timezone

from agri_common import DataSource, ModelUsed, RecommendationEnvelope, RiskAnalysis, RiskLevel
from fastapi import FastAPI

from .engine import overall_confidence, recommend_crops
from .schemas import CropRecommendationRequest, CropRecommendationResult

app = FastAPI(title="Crop Recommendation Service", version="0.1.0")


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/crops/recommend", response_model=RecommendationEnvelope[CropRecommendationResult])
def recommend(req: CropRecommendationRequest) -> RecommendationEnvelope[CropRecommendationResult]:
    ranked = recommend_crops(req)
    confidence = overall_confidence(req)
    now = datetime.now(timezone.utc)

    if not ranked:
        # No crop clears the hard filter — say so rather than forcing a low-quality pick.
        return RecommendationEnvelope[CropRecommendationResult](
            result=CropRecommendationResult(
                crop_name="No suitable crop found",
                term="short-term",
                suitability_percent=0,
                expected_yield_quintals=0,
                water_requirement_mm=0,
                investment_inr=0,
                maintenance_cost_inr=0,
                expected_profit_inr=0,
                time_to_harvest_days=0,
                risk_level="high",
                roi_percent=0,
            ),
            confidence_score=confidence,
            data_sources=[DataSource(name="Internal crop knowledge base v0.1", as_of=now, live=False)],
            assumptions=[
                "No crop in the current knowledge base passed the water/season/soil-pH hard filter for these inputs."
            ],
            reasoning="No candidates cleared the minimum suitability thresholds for the given soil, water and season inputs.",
            model_used=ModelUsed(name="crop-hard-filter", version="0.1.0"),
            risk_analysis=RiskAnalysis(level=RiskLevel.HIGH, factors=["No viable crop identified for current conditions."]),
            action_plan=["Get a lab soil test and consider irrigation investment to widen viable crop options."],
        )

    top, *rest = ranked
    return RecommendationEnvelope[CropRecommendationResult](
        result=top,
        confidence_score=confidence,
        data_sources=[
            DataSource(name="Internal crop knowledge base v0.1", as_of=now, live=False),
            DataSource(name="Soil service output", as_of=now, live=req.soil_confidence >= 0.75),
            DataSource(name="Weather service forecast", as_of=now, live=req.weather_confidence >= 0.75),
        ],
        assumptions=[
            "Yield and cost figures are regional reference values from the curated crop knowledge base, "
            "not this specific farm's historical data.",
            "Expected profit uses each crop's reference price, not a live market forecast.",
        ],
        reasoning=(
            f"{top.crop_name} ranked highest ({top.suitability_percent}% suitability) based on soil pH fit, "
            "seasonal rainfall fit, and water availability margin."
        ),
        model_used=ModelUsed(name="crop-suitability-rule-engine", version="0.1.0"),
        alternatives=rest,
        risk_analysis=RiskAnalysis(
            level=RiskLevel(top.risk_level),
            factors=_risk_factors(top),
        ),
        action_plan=_action_plan(top),
    )


def _risk_factors(top: CropRecommendationResult) -> list[str]:
    factors = []
    if top.risk_level != "low":
        factors.append(f"{top.crop_name} carries {top.risk_level} inherent price/yield volatility risk.")
    if top.suitability_percent < 70:
        factors.append("Suitability is moderate — conditions are workable but not ideal for this crop.")
    return factors or ["No elevated risk factors identified for current conditions."]


def _action_plan(top: CropRecommendationResult) -> list[str]:
    plan = [f"Confirm local seed/sapling availability for {top.crop_name} before committing."]
    if top.water_requirement_mm > 1000:
        plan.append("Verify irrigation capacity can sustain this crop's water requirement through the full season.")
    plan.append("Get a lab soil test to replace estimated soil values before finalizing investment.")
    return plan
