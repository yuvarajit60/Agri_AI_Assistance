"""Two-stage crop recommendation: hard filter, then weighted suitability
scoring (docs/architecture/MODULES.md §6). Deliberately a transparent,
inspectable formula for v1 — replace with a learned ranking model only
once there's real yield-outcome data to train on (see ARCHITECTURE.md §5.1).
"""

from __future__ import annotations

from .crop_knowledge_base import CROP_KNOWLEDGE_BASE, CropProfile
from .schemas import CropRecommendationRequest, CropRecommendationResult

WATER_TOLERANCE = 1.15  # a crop needing slightly more than what's available isn't auto-rejected
PH_TOLERANCE = 0.5

# Highest water_need_mm_per_season in the knowledge base is Sugarcane at
# 2000mm — a gravity-fed source is cheap enough to run that it's treated as
# removing water as the binding constraint entirely for any crop here,
# rather than trying to invent a precise volumetric flow-rate estimate the
# Water service doesn't actually provide. Pumped is real but costs money to
# run, so it's a meaningful boost, not a ceiling.
GRAVITY_FED_WATER_FLOOR_MM = 2500.0
PUMPED_WATER_MULTIPLIER = 1.6


def _effective_water_availability(req: CropRecommendationRequest) -> float:
    """Rainfall alone understates what a farm with real irrigation access
    can actually give a crop, and overstates what a farm with no nearby
    source can rely on through a dry spell — see docs/architecture/
    MODULES.md §6. irrigation_method comes from the Water Resource
    Service; None (service unreachable, or genuinely no source) falls
    back to the original rainfall-only behavior."""
    if req.irrigation_method == "gravity_fed":
        return max(req.water_availability_mm, GRAVITY_FED_WATER_FLOOR_MM)
    if req.irrigation_method == "pumped":
        return req.water_availability_mm * PUMPED_WATER_MULTIPLIER
    return req.water_availability_mm


def _passes_hard_filter(crop: CropProfile, req: CropRecommendationRequest, effective_water_mm: float) -> bool:
    if req.term_filter is not None and crop.term != req.term_filter:
        return False
    if req.current_season != "any" and "perennial" not in crop.seasons and req.current_season not in crop.seasons:
        return False
    if crop.water_need_mm_per_season > effective_water_mm * WATER_TOLERANCE:
        return False
    lo, hi = crop.suitable_soil_ph
    if not (lo - PH_TOLERANCE <= req.soil_ph <= hi + PH_TOLERANCE):
        return False
    return True


def _ph_fit(crop: CropProfile, ph: float) -> float:
    lo, hi = crop.suitable_soil_ph
    mid = (lo + hi) / 2
    half_range = max((hi - lo) / 2, 0.1)
    distance = abs(ph - mid)
    return max(0.0, 1 - (distance / (half_range + PH_TOLERANCE)))


def _rainfall_fit(crop: CropProfile, rainfall_mm: float) -> float:
    if crop.min_rainfall_mm <= rainfall_mm <= crop.max_rainfall_mm:
        return 1.0
    span = crop.max_rainfall_mm - crop.min_rainfall_mm
    if rainfall_mm < crop.min_rainfall_mm:
        deficit = crop.min_rainfall_mm - rainfall_mm
    else:
        deficit = rainfall_mm - crop.max_rainfall_mm
    return max(0.0, 1 - deficit / max(span, 1))


def _water_margin_fit(crop: CropProfile, water_availability_mm: float) -> float:
    if crop.water_need_mm_per_season <= 0:
        return 1.0
    ratio = water_availability_mm / crop.water_need_mm_per_season
    return max(0.0, min(1.0, ratio))


def _suitability(crop: CropProfile, req: CropRecommendationRequest, effective_water_mm: float) -> float:
    ph_fit = _ph_fit(crop, req.soil_ph)
    rainfall_fit = _rainfall_fit(crop, req.seasonal_rainfall_mm)
    water_fit = _water_margin_fit(crop, effective_water_mm)
    score = 0.35 * ph_fit + 0.30 * rainfall_fit + 0.35 * water_fit
    return round(score * 100, 1)


def _economics(
    crop: CropProfile, req: CropRecommendationRequest, suitability: float, effective_water_mm: float
) -> CropRecommendationResult:
    # Yield scales down from the reference figure as suitability drops below 100%,
    # floored at 40% of reference so a marginal-but-passing crop isn't zeroed out.
    yield_factor = 0.4 + 0.6 * (suitability / 100)
    expected_yield = round(crop.expected_yield_quintal_per_acre * req.farm_area_acres * yield_factor, 1)

    investment = crop.investment_per_acre_inr * req.farm_area_acres
    maintenance = crop.maintenance_cost_per_acre_inr * req.farm_area_acres
    revenue = expected_yield * crop.base_price_per_quintal_inr
    profit = revenue - investment - maintenance
    total_cost = investment + maintenance
    roi = round((profit / total_cost) * 100, 1) if total_cost > 0 else 0.0

    risk_level = crop.risk_level
    if _water_margin_fit(crop, effective_water_mm) < 0.85 and risk_level == "low":
        risk_level = "medium"  # tight water margin bumps risk even for an otherwise-safe crop

    return CropRecommendationResult(
        crop_name=crop.name,
        term=crop.term,
        suitability_percent=suitability,
        expected_yield_quintals=expected_yield,
        water_requirement_mm=crop.water_need_mm_per_season,
        investment_inr=investment,
        maintenance_cost_inr=maintenance,
        expected_profit_inr=round(profit, 0),
        time_to_harvest_days=crop.time_to_harvest_days,
        risk_level=risk_level,  # type: ignore[arg-type]
        roi_percent=roi,
    )


def recommend_crops(req: CropRecommendationRequest) -> list[CropRecommendationResult]:
    effective_water_mm = _effective_water_availability(req)
    candidates = [c for c in CROP_KNOWLEDGE_BASE if _passes_hard_filter(c, req, effective_water_mm)]
    scored = [(c, _suitability(c, req, effective_water_mm)) for c in candidates]
    scored.sort(key=lambda pair: pair[1], reverse=True)
    return [_economics(c, req, score, effective_water_mm) for c, score in scored[: req.top_n]]


def overall_confidence(req: CropRecommendationRequest) -> float:
    # Crop knowledge base itself is curated but not yet outcome-validated (see
    # crop_knowledge_base.py docstring), so it caps confidence even when
    # upstream soil/weather data is high-confidence.
    knowledge_base_confidence = 0.75
    return round(min(req.soil_confidence, req.weather_confidence, knowledge_base_confidence), 2)
