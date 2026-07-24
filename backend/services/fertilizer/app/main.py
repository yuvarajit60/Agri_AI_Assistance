from __future__ import annotations

from datetime import datetime, timezone

from agri_common import DataSource, ModelUsed, RecommendationEnvelope
from fastapi import FastAPI

from .engine import compute_plan
from .schemas import FertilizerRecommendationRequest, FertilizerRecommendationResult

app = FastAPI(title="Fertilizer Recommendation Service", version="0.1.0")

BASE_CONFIDENCE = 0.75

_STRINGS: dict[str, dict[str, str]] = {
    "lime_note": {
        "en": "Soil pH is acidic ({ph}). Illustrative agricultural lime dose: ~{dose:.0f} kg/acre — get a "
        "lime requirement test before applying, this is a rough starting estimate, not a substitute for one.",
        "ta": "மண் pH அமிலத்தன்மை உடையது ({ph}). தோராயமான சுண்ணாம்பு (lime) அளவு: ஏக்கருக்கு ~{dose:.0f} கிலோ — "
        "பயன்படுத்தும் முன் சுண்ணாம்பு தேவை சோதனை (lime requirement test) செய்யவும், இது ஒரு தோராயமான தொடக்க "
        "மதிப்பீடு மட்டுமே.",
    },
    "gypsum_note": {
        "en": "Soil pH is alkaline ({ph}). Illustrative gypsum dose: ~{dose:.0f} kg/acre — confirm with a "
        "local soil-testing lab before applying.",
        "ta": "மண் pH காரத்தன்மை உடையது ({ph}). தோராயமான ஜிப்சம் (gypsum) அளவு: ஏக்கருக்கு ~{dose:.0f} கிலோ — "
        "பயன்படுத்தும் முன் உள்ளூர் மண் பரிசோதனை ஆய்வகத்தில் உறுதிப்படுத்தவும்.",
    },
    "organic_note": {
        "en": "Organic carbon is low ({oc}%). Adding ~2 tonnes/acre of farmyard manure or compost alongside "
        "chemical fertilizer will improve soil structure and nutrient retention over time.",
        "ta": "இயற்கை கார்பன் (organic carbon) அளவு குறைவாக உள்ளது ({oc}%). இரசாயன உரத்துடன் ஏக்கருக்கு ~2 டன் "
        "தொழுவ உரம் அல்லது எரு (FYM/compost) சேர்ப்பது மண் அமைப்பு மற்றும் ஊட்டச்சத்து தக்கவைப்பை காலப்போக்கில் "
        "மேம்படுத்தும்.",
    },
    "reasoning": {
        "en": "For {crop} on {area} acre(s), the estimated nutrient gap requires: {products}.",
        "ta": "{crop} பயிருக்கு {area} ஏக்கரில், மதிப்பிடப்பட்ட ஊட்டச்சத்து இடைவெளிக்கு தேவை: {products}.",
    },
    "no_products": {
        "en": "no additional fertilizer needed",
        "ta": "கூடுதல் உரம் தேவையில்லை",
    },
    "assumption_convention": {
        "en": "Soil phosphorus and potassium values are treated as P2O5/K2O-equivalent (the common Indian "
        "soil-test reporting convention) — if your source instead reports elemental P/K, actual "
        "quantities will differ.",
        "ta": "மண் பாஸ்பரஸ் மற்றும் பொட்டாசியம் மதிப்புகள் P2O5/K2O-சமமானதாக கருதப்படுகின்றன (பொதுவான இந்திய "
        "மண் பரிசோதனை அறிக்கை மரபு) — உங்கள் ஆதாரம் அடிப்படை (elemental) P/K-ஐ பயன்படுத்தினால், உண்மையான "
        "அளவுகள் மாறுபடும்.",
    },
    "assumption_kb": {
        "en": "Crop nutrient requirements are illustrative ICAR-style package-of-practices figures, not "
        "region- or variety-specific — a local Krishi Vigyan Kendra or agriculture office can refine these.",
        "ta": "பயிர் ஊட்டச்சத்து தேவைகள் தோராயமான ICAR-பாணி பரிந்துரை மதிப்புகள், பிராந்திய அல்லது வகை-குறிப்பிட்டவை "
        "அல்ல — உள்ளூர் கிருஷி விஞ்ஞான் கேந்திரா அல்லது வேளாண் அலுவலகம் இவற்றை மேலும் துல்லியப்படுத்த முடியும்.",
    },
    "assumption_schedule": {
        "en": "Application timing is a generic basal / top-dressing split, not a crop-specific schedule.",
        "ta": "பயன்பாட்டு நேரம் ஒரு பொதுவான அடிப்படை / மேல்-உரமிடல் பிரிவு மட்டுமே, பயிர்-குறிப்பிட்ட அட்டவணை அல்ல.",
    },
    "assumption_unmatched": {
        "en": "'{crop}' isn't in the curated crop reference list — a generic field-crop nutrient requirement "
        "was used instead, so this recommendation is less precise than for a matched crop.",
        "ta": "'{crop}' தேர்ந்தெடுக்கப்பட்ட பயிர் பட்டியலில் இல்லை — பொதுவான வயல்-பயிர் ஊட்டச்சத்து தேவை பயன்படுத்தப்பட்டது, "
        "எனவே இந்த பரிந்துரை பொருந்திய பயிரை விட குறைவான துல்லியம் கொண்டது.",
    },
    "action_apply": {
        "en": "Apply basal-dose fertilizer at sowing/transplanting, then top-dress remaining nitrogen as scheduled.",
        "ta": "விதைப்பு/நடவு நேரத்தில் அடிப்படை உரத்தை பயன்படுத்தவும், பின்னர் மீதமுள்ள நைட்ரஜனை அட்டவணைப்படி "
        "மேல்-உரமிடவும்.",
    },
    "action_retest": {
        "en": "Get a fresh soil test after 2-3 seasons to keep these gap calculations accurate.",
        "ta": "இந்த இடைவெளி கணக்கீடுகளை துல்லியமாக வைத்திருக்க 2-3 பருவங்களுக்குப் பிறகு புதிய மண் பரிசோதனை "
        "செய்யவும்.",
    },
}


def _t(key: str, language: str, **kwargs: object) -> str:
    template = _STRINGS[key].get(language, _STRINGS[key]["en"])
    return template.format(**kwargs) if kwargs else template


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/fertilizer/recommend", response_model=RecommendationEnvelope[FertilizerRecommendationResult])
def recommend(req: FertilizerRecommendationRequest) -> RecommendationEnvelope[FertilizerRecommendationResult]:
    """N-P2O5-K2O gap between crop requirement and soil-supplied nutrients,
    converted into real fertilizer product quantities for the farm's area —
    see docs/architecture/MODULES.md and app/engine.py for the method."""
    plan = compute_plan(req)
    now = datetime.now(timezone.utc)
    language = req.language

    ph_correction = None
    if plan.ph_status == "acidic":
        ph_correction = _t("lime_note", language, ph=req.soil_ph, dose=plan.ph_correction_dose_kg_per_acre)
    elif plan.ph_status == "alkaline":
        ph_correction = _t("gypsum_note", language, ph=req.soil_ph, dose=plan.ph_correction_dose_kg_per_acre)

    organic_matter_note = _t("organic_note", language, oc=req.organic_carbon_percent) if plan.organic_matter_low else None

    result = FertilizerRecommendationResult(
        crop_name=req.crop_name,
        crop_reference_matched=plan.crop_found,
        nutrient_gap_per_ha=plan.gap,
        products=plan.products,
        ph_correction=ph_correction,
        organic_matter_note=organic_matter_note,
        application_schedule=plan.application_schedule,
    )

    assumptions = [
        _t("assumption_convention", language),
        _t("assumption_kb", language),
        _t("assumption_schedule", language),
    ]
    if not plan.crop_found:
        assumptions.insert(0, _t("assumption_unmatched", language, crop=req.crop_name))

    confidence = BASE_CONFIDENCE * req.soil_confidence
    if not plan.crop_found:
        confidence *= 0.6
    confidence = round(min(max(confidence, 0.0), 1.0), 2)

    total_products = ", ".join(f"{p.quantity_kg_total} kg {p.product}" for p in plan.products) or _t(
        "no_products", language
    )

    return RecommendationEnvelope[FertilizerRecommendationResult](
        result=result,
        confidence_score=confidence,
        data_sources=[
            DataSource(name="Curated crop nutrient requirement reference (ICAR-style)", as_of=now, live=False),
            DataSource(name="Soil nutrient values (from Soil service)", as_of=now, live=req.soil_confidence >= 0.9),
        ],
        assumptions=assumptions,
        reasoning=_t("reasoning", language, crop=req.crop_name, area=req.farm_area_acres, products=total_products),
        model_used=ModelUsed(name="fertilizer-gap-calculator", version="0.1.0"),
        risk_analysis=None,
        action_plan=[_t("action_apply", language), _t("action_retest", language)],
    )
