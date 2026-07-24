from __future__ import annotations

from datetime import datetime, timezone

from agri_common import DataSource, ModelUsed, RecommendationEnvelope
from fastapi import FastAPI

from .engine import compute_plan
from .schemas import IrrigationPlanRequest, IrrigationPlanResult

app = FastAPI(title="Irrigation Planning Service", version="0.1.0")

BASE_CONFIDENCE = 0.7

_METHOD_NOTES: dict[str, dict[str, str]] = {
    "gravity_fed": {
        "en": "Gravity-fed channel/flood irrigation is available and cheap to run, but has the lowest "
        "application efficiency of the three methods — expect real water use to be noticeably higher "
        "than the crop's raw requirement.",
        "ta": "ஈர்ப்பு விசை மூலம் கால்வாய்/வெள்ள பாசனம் கிடைக்கிறது, இயக்க செலவும் குறைவு, ஆனால் மூன்று "
        "வழிமுறைகளிலும் மிகக் குறைந்த பயன்பாட்டு திறன் கொண்டது — உண்மையான நீர் பயன்பாடு பயிரின் அடிப்படை "
        "தேவையை விட கணிசமாக அதிகமாக இருக்கும்.",
    },
    "pumped": {
        "en": "A pumped water source is available. Switching from flood to drip/sprinkler on this connection "
        "would meaningfully cut both water use and pumping cost — worth considering for a high-value crop.",
        "ta": "பம்ப் செய்யப்பட்ட நீர் ஆதாரம் கிடைக்கிறது. இந்த இணைப்பில் வெள்ளத்திலிருந்து சொட்டு/தெளிப்பு "
        "பாசனத்திற்கு மாறுவது நீர் பயன்பாடு மற்றும் பம்பிங் செலவை குறிப்பிடத்தக்க அளவு குறைக்கும் — அதிக "
        "மதிப்புள்ள பயிருக்கு இதை கருத்தில் கொள்ளலாம்.",
    },
    "limited": {
        "en": "Water access is limited. Drip irrigation and mulching are strongly recommended to keep the "
        "crop viable on this little water — consider a more drought-tolerant crop if this irrigation "
        "method can't be improved.",
        "ta": "நீர் அணுகல் மட்டுப்படுத்தப்பட்டுள்ளது. இந்த குறைந்த நீரில் பயிரை நிலைநிறுத்த சொட்டு பாசனம் மற்றும் "
        "மல்ச்சிங் கடுமையாக பரிந்துரைக்கப்படுகிறது — இந்த பாசன முறையை மேம்படுத்த முடியாவிட்டால் வறட்சியை "
        "தாங்கும் பயிரை கருத்தில் கொள்ளவும்.",
    },
}

_STRINGS: dict[str, dict[str, str]] = {
    "critical_alert": {
        "en": "Never skip irrigation around the mid-season flowering/fruit-set window for {crop} — water "
        "stress at that stage causes the largest yield loss of any growth stage.",
        "ta": "{crop} பயிருக்கு பருவத்தின் நடுப்பகுதியில் பூக்கும்/காய்க்கும் கட்டத்தில் பாசனத்தை தவறவிடாதீர்கள் — "
        "அந்த கட்டத்தில் நீர் பற்றாக்குறை மற்ற எந்த வளர்ச்சி கட்டத்தையும் விட அதிக மகசூல் இழப்பை ஏற்படுத்தும்.",
    },
    "reasoning": {
        "en": "{crop} needs an estimated {liters:,.0f} liters total over {area} acre(s), applied as "
        "{count} irrigation(s) roughly every {freq} days via {method} irrigation.",
        "ta": "{crop} பயிருக்கு {area} ஏக்கரில் மொத்தம் தோராயமாக {liters:,.0f} லிட்டர் தேவை, {method} மூலம் "
        "ஏறத்தாழ ஒவ்வொரு {freq} நாட்களுக்கும் {count} முறை பாசனமாக பயன்படுத்தப்படும்.",
    },
    "assumption_efficiency": {
        "en": "Application efficiency figures per method (gravity-fed/pumped/limited) are typical "
        "illustrative values, not a site-measured figure — actual losses vary with soil type and field layout.",
        "ta": "ஒவ்வொரு வழிமுறைக்கும் (ஈர்ப்பு விசை/பம்ப்/மட்டுப்படுத்தப்பட்ட) பயன்பாட்டு திறன் மதிப்புகள் "
        "பொதுவான தோராயமானவை, தள-அளவிடப்பட்டவை அல்ல — உண்மையான இழப்புகள் மண் வகை மற்றும் வயல் அமைப்பைப் "
        "பொறுத்து மாறுபடும்.",
    },
    "assumption_demand": {
        "en": "Irrigation frequency assumes even water need across the season; actual crop water demand is "
        "higher during flowering/fruiting and lower at early growth — see the critical-stage alert.",
        "ta": "பாசன அதிர்வெண் பருவம் முழுவதும் சமமான நீர் தேவையை கருதுகிறது; உண்மையான பயிர் நீர் தேவை பூக்கும்/"
        "காய்க்கும் போது அதிகமாகவும், ஆரம்ப வளர்ச்சியில் குறைவாகவும் இருக்கும் — முக்கிய-கட்ட எச்சரிக்கையைப் "
        "பார்க்கவும்.",
    },
    "assumption_method_missing": {
        "en": "No irrigation method was supplied by the Water Resource service — 'limited' (the most "
        "conservative option) was assumed, which increases estimated water requirement and reduces confidence.",
        "ta": "நீர் வள சேவையிலிருந்து பாசன முறை எதுவும் வழங்கப்படவில்லை — 'மட்டுப்படுத்தப்பட்டது' (மிகவும் "
        "பாதுகாப்பான தேர்வு) கருதப்பட்டது, இது மதிப்பிடப்பட்ட நீர் தேவையை அதிகரித்து நம்பகத்தன்மையை குறைக்கிறது.",
    },
    "action_follow": {
        "en": "Follow the irrigation schedule below, and always prioritize irrigation during the "
        "flowering/fruit-set stage even if it means skipping a less critical one.",
        "ta": "கீழே உள்ள பாசன அட்டவணையை பின்பற்றவும், குறைவான முக்கியமான ஒன்றை தவிர்க்க வேண்டியிருந்தாலும் "
        "பூக்கும்/காய்க்கும் கட்டத்தில் பாசனத்திற்கு எப்போதும் முன்னுரிமை கொடுங்கள்.",
    },
}

_METHOD_LABEL_EN = {"gravity_fed": "gravity-fed", "pumped": "pumped", "limited": "limited"}
_METHOD_LABEL_TA = {"gravity_fed": "ஈர்ப்பு விசை பாசனம்", "pumped": "பம்ப் மூலம்", "limited": "மட்டுப்படுத்தப்பட்ட"}


def _t(key: str, language: str, **kwargs: object) -> str:
    template = _STRINGS[key].get(language, _STRINGS[key]["en"])
    return template.format(**kwargs) if kwargs else template


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/irrigation/plan", response_model=RecommendationEnvelope[IrrigationPlanResult])
def plan(req: IrrigationPlanRequest) -> RecommendationEnvelope[IrrigationPlanResult]:
    """Season-total water requirement (mm) converted into a real
    liters-per-irrigation schedule, using the irrigation method already
    determined by the Water Resource service — see app/engine.py."""
    result_data = compute_plan(req)
    now = datetime.now(timezone.utc)
    language = req.language

    result = IrrigationPlanResult(
        crop_name=req.crop_name,
        method=result_data.method,
        method_assumed=result_data.method_assumed,
        application_efficiency_percent=result_data.application_efficiency_percent,
        total_water_requirement_liters=result_data.total_water_requirement_liters,
        number_of_irrigations=result_data.number_of_irrigations,
        frequency_days=result_data.frequency_days,
        per_irrigation_volume_liters=result_data.per_irrigation_volume_liters,
        method_notes=_METHOD_NOTES[result_data.method].get(language, _METHOD_NOTES[result_data.method]["en"]),
        critical_stage_alert=_t("critical_alert", language, crop=req.crop_name),
        schedule=result_data.schedule,
    )

    assumptions = [_t("assumption_efficiency", language), _t("assumption_demand", language)]
    if result_data.method_assumed:
        assumptions.insert(0, _t("assumption_method_missing", language))

    confidence = BASE_CONFIDENCE * (0.7 if result_data.method_assumed else 1.0)
    confidence = round(min(max(confidence, 0.0), 1.0), 2)

    return RecommendationEnvelope[IrrigationPlanResult](
        result=result,
        confidence_score=confidence,
        data_sources=[
            DataSource(name="Crop water requirement (from Crop Recommendation service)", as_of=now, live=False),
            DataSource(
                name="Irrigation method (from Water Resource service)",
                as_of=now,
                live=not result_data.method_assumed,
            ),
        ],
        assumptions=assumptions,
        reasoning=_t(
            "reasoning",
            language,
            crop=req.crop_name,
            liters=result.total_water_requirement_liters,
            area=req.farm_area_acres,
            count=result.number_of_irrigations,
            freq=result.frequency_days,
            method=(_METHOD_LABEL_TA if language == "ta" else _METHOD_LABEL_EN)[result_data.method],
        ),
        model_used=ModelUsed(name="irrigation-schedule-calculator", version="0.1.0"),
        risk_analysis=None,
        action_plan=[_t("action_follow", language)],
    )
