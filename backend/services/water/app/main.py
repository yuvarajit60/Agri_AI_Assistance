from __future__ import annotations

from datetime import datetime, timezone

from agri_common import DataSource, Location, ModelUsed, RecommendationEnvelope
from fastapi import FastAPI

from .providers import MockWaterResourceProvider
from .schemas import WaterResourceResult

app = FastAPI(title="Water Resource Service", version="0.1.0")
_provider = MockWaterResourceProvider()

ESTIMATE_CONFIDENCE = 0.5

_STRINGS: dict[str, dict[str, str]] = {
    "source_1": {
        "en": "Water-bodies proximity estimate (mock provider)",
        "ta": "நீர்நிலை அருகாமை மதிப்பீடு (மாதிரி வழங்குநர்)",
    },
    "source_2": {
        "en": "CGWB groundwater category estimate (mock provider)",
        "ta": "CGWB நிலத்தடி நீர் வகைப்பாடு மதிப்பீடு (மாதிரி வழங்குநர்)",
    },
    "assumption_1": {
        "en": "No real water-bodies or CGWB groundwater dataset is ingested yet — feature list, distances "
        "and groundwater category are estimated, not measured.",
        "ta": "உண்மையான நீர்நிலை அல்லது CGWB நிலத்தடி நீர் தரவுத்தளம் இன்னும் சேர்க்கப்படவில்லை — அம்சங்கள், தூரங்கள் "
        "மற்றும் நிலத்தடி நீர் வகைப்பாடு அளக்கப்படவில்லை, மதிப்பிடப்பட்டவை.",
    },
    "assumption_2": {
        "en": "Irrigation feasibility is a rough method suggestion (gravity-fed / pumped / limited), not an "
        "engineering assessment — a site visit is needed before investing in irrigation infrastructure.",
        "ta": "பாசன சாத்தியக்கூறு ஒரு தோராயமான வழிமுறை பரிந்துரை (ஈர்ப்பு விசை / பம்ப் / மட்டுப்படுத்தப்பட்டது), "
        "பொறியியல் மதிப்பீடு அல்ல — பாசன உள்கட்டமைப்பில் முதலீடு செய்யும் முன் இடத்தை நேரில் பார்வையிட வேண்டும்.",
    },
    "action_1": {
        "en": "Verify groundwater category and borewell permissions with your local CGWB/irrigation "
        "department office before drilling.",
        "ta": "துளையிடும் முன் உங்கள் உள்ளூர் CGWB/பாசனத் துறை அலுவலகத்தில் நிலத்தடி நீர் வகைப்பாடு மற்றும் "
        "ஆழ்குழாய் கிணறு அனுமதிகளை சரிபார்க்கவும்.",
    },
    "action_2": {
        "en": "Confirm surface water access rights (canal/reservoir allocation) with the relevant irrigation "
        "authority before planning irrigation infrastructure.",
        "ta": "பாசன உள்கட்டமைப்பை திட்டமிடும் முன், தொடர்புடைய பாசன ஆணையத்திடம் மேற்பரப்பு நீர் அணுகல் உரிமைகளை "
        "(கால்வாய்/நீர்த்தேக்க ஒதுக்கீடு) உறுதிப்படுத்திக் கொள்ளவும்.",
    },
}


def _t(key: str, language: str) -> str:
    return _STRINGS[key].get(language, _STRINGS[key]["en"])


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/water/analyze", response_model=RecommendationEnvelope[WaterResourceResult])
def analyze(lat: float, lon: float, language: str = "en") -> RecommendationEnvelope[WaterResourceResult]:
    """Surface water proximity, groundwater feasibility, and irrigation
    method suitability for a location — see docs/architecture/MODULES.md
    §3. Real ingestion (JRC/India-WRIS/OSM water-bodies layer + CGWB
    groundwater categories) isn't wired up yet; this always returns a
    clearly-labeled estimate."""
    location = Location(latitude=lat, longitude=lon)
    data = _provider.assess(location, language)
    now = datetime.now(timezone.utc)

    result = WaterResourceResult(
        features=data.features,
        groundwater=data.groundwater,
        irrigation_feasibility=data.irrigation_feasibility,
    )

    _reasoning_templates = {
        "en": "Found {count} nearby water feature(s) in the estimate; groundwater block status is "
        "'{category}' with an irrigation method suggestion of '{method}'.",
        "ta": "மதிப்பீட்டில் {count} அருகிலுள்ள நீர் அம்சங்கள் கண்டறியப்பட்டன; நிலத்தடி நீர் வட்டார நிலை "
        "'{category}' மற்றும் பரிந்துரைக்கப்படும் பாசன வழிமுறை '{method}'.",
    }
    reasoning_template = _reasoning_templates.get(language, _reasoning_templates["en"])

    return RecommendationEnvelope[WaterResourceResult](
        result=result,
        confidence_score=ESTIMATE_CONFIDENCE,
        data_sources=[
            DataSource(name=_t("source_1", language), as_of=now, live=False),
            DataSource(name=_t("source_2", language), as_of=now, live=False),
        ],
        assumptions=[_t("assumption_1", language), _t("assumption_2", language)],
        reasoning=reasoning_template.format(
            count=len(result.features),
            category=result.groundwater.category.value,
            method=result.irrigation_feasibility.method.value,
        ),
        model_used=ModelUsed(name="water-resource-estimator", version="0.1.0"),
        risk_analysis=None,
        action_plan=[_t("action_1", language), _t("action_2", language)],
    )
