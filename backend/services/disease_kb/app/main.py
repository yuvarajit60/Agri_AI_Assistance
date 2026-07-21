from __future__ import annotations

import os
from datetime import datetime, timezone

from agri_common import DataSource, ModelUsed, RecommendationEnvelope, RiskAnalysis, RiskLevel
from fastapi import FastAPI, File, Form, UploadFile

from . import vector_store, vision
from .knowledge_base import load_knowledge_base, localize
from .schemas import DiseaseMatch, DiseaseSource, DiseaseSummary, GuidanceQuery

app = FastAPI(title="Disease Organic Knowledge Base (RAG)", version="0.1.0")

ANTHROPIC_API_KEY = os.environ.get("ANTHROPIC_API_KEY", "")

# Fixed/generated response text (not knowledge-base content) — the same
# "never leave the app half-translated" convention as
# mobile_app/lib/core/localization/app_strings.dart, kept backend-side
# because this text is composed at request time, not stored per-entry.
_STRINGS: dict[str, dict[str, str]] = {
    "no_match_name": {"en": "No match found", "ta": "பொருத்தம் எதுவும் கிடைக்கவில்லை"},
    "no_match_source": {
        "en": "Organic disease knowledge base (starter set, 12 diseases)",
        "ta": "இயற்கை நோய் தரவுத்தளம் (ஆரம்ப தொகுப்பு, 12 நோய்கள்)",
    },
    "no_match_assumption": {
        "en": "No entry in the current knowledge base matched this query closely enough.",
        "ta": "தற்போதைய தரவுத்தளத்தில் இந்த கேள்விக்கு நெருக்கமான பொருத்தம் எதுவும் இல்லை.",
    },
    "no_match_reasoning": {
        "en": "No results above a usable similarity threshold were returned by the vector search.",
        "ta": "பயன்படுத்தக்கூடிய ஒற்றுமை அளவை எட்டிய முடிவுகள் எதுவும் தேடலில் கிடைக்கவில்லை.",
    },
    "no_match_action": {
        "en": "Try describing the crop and visible symptoms differently, or consult your local KVK.",
        "ta": "பயிர் மற்றும் தெரியும் அறிகுறிகளை வேறு விதமாக விவரிக்க முயற்சிக்கவும், அல்லது உங்கள் அருகிலுள்ள KVK-ஐ அணுகவும்.",
    },
    "match_source_fallback": {
        "en": "Organic disease knowledge base (starter set)",
        "ta": "இயற்கை நோய் தரவுத்தளம் (ஆரம்ப தொகுப்பு)",
    },
    "match_assumption_1": {
        "en": "Retrieved from a curated starter knowledge base of 12 common Indian crop diseases — "
        "not exhaustive. Treat this as a lead to verify, not a confirmed diagnosis.",
        "ta": "12 பொதுவான இந்திய பயிர் நோய்களை உள்ளடக்கிய ஆரம்ப தரவுத்தளத்திலிருந்து பெறப்பட்டது — "
        "முழுமையானது அல்ல. இதை உறுதிப்படுத்தப்பட்ட கண்டறிதலாக அல்லாமல், சரிபார்க்க வேண்டிய ஒரு துப்பாக கருதவும்.",
    },
    "match_assumption_2": {
        "en": "Always cross-check visually (or with a local agriculture extension officer) before applying any treatment.",
        "ta": "எந்த சிகிச்சையையும் பயன்படுத்தும் முன் எப்போதும் கண்ணால் சரிபார்க்கவும் (அல்லது உள்ளூர் வேளாண் அலுவலரிடம் கலந்தாலோசிக்கவும்).",
    },
    "match_risk_factor": {
        "en": "Retrieval-based match, not a confirmed lab or expert diagnosis.",
        "ta": "தேடலின் அடிப்படையிலான பொருத்தம், ஆய்வக அல்லது நிபுணர் உறுதிப்படுத்திய கண்டறிதல் அல்ல.",
    },
    "match_action_1": {
        "en": "Compare the symptom description above against what you're seeing before treating.",
        "ta": "சிகிச்சை அளிக்கும் முன் மேலே உள்ள அறிகுறி விவரணையை நீங்கள் காண்பதுடன் ஒப்பிடவும்.",
    },
    "match_action_2": {
        "en": "Start with the organic treatment listed; reassess after 5-7 days.",
        "ta": "பட்டியலிடப்பட்ட இயற்கை சிகிச்சையுடன் தொடங்கவும்; 5-7 நாட்களுக்குப் பிறகு மீண்டும் மதிப்பாய்வு செய்யவும்.",
    },
    "chemical_source": {
        "en": "No chemical-treatment knowledge base configured yet",
        "ta": "வேதி சிகிச்சை தரவுத்தளம் இன்னும் அமைக்கப்படவில்லை",
    },
    "chemical_assumption": {
        "en": "Recommending a specific pesticide product or dosage without a verified, "
        "government-approved-pesticide dataset risks suggesting something unsafe, banned, "
        "or mismatched to the actual disease — so this isn't guessed.",
        "ta": "சரிபார்க்கப்பட்ட, அரசு அங்கீகரித்த பூச்சிக்கொல்லி தரவுத்தளம் இல்லாமல் ஒரு குறிப்பிட்ட பூச்சிக்கொல்லி "
        "பொருள் அல்லது அளவை பரிந்துரைப்பது பாதுகாப்பற்றது, தடைசெய்யப்பட்டது, அல்லது நோய்க்கு பொருந்தாதது "
        "ஆகலாம் — எனவே இது யூகிக்கப்படவில்லை.",
    },
    "chemical_reasoning": {
        "en": "Chemical treatment guidance needs an authoritative, regularly-updated source "
        "(Central Insecticides Board & Registration Committee data) that isn't wired up yet.",
        "ta": "வேதி சிகிச்சை வழிகாட்டுதலுக்கு ஒரு அதிகாரப்பூர்வ, தொடர்ந்து புதுப்பிக்கப்படும் மூலம் "
        "(மத்திய பூச்சிக்கொல்லி வாரியம் & பதிவு குழு தரவு) தேவை, இது இன்னும் இணைக்கப்படவில்லை.",
    },
    "chemical_risk_factor": {
        "en": "No verified chemical product data available — do not guess a pesticide.",
        "ta": "சரிபார்க்கப்பட்ட வேதிப் பொருள் தரவு எதுவும் இல்லை — ஒரு பூச்சிக்கொல்லியை யூகிக்க வேண்டாம்.",
    },
    "chemical_action_1": {
        "en": "Call the Kisan Call Centre (1800-180-1551) or visit your local Krishi Vigyan Kendra (KVK) "
        "for a government-approved pesticide recommendation for this crop and disease.",
        "ta": "இந்த பயிர் மற்றும் நோய்க்கு அரசு அங்கீகரித்த பூச்சிக்கொல்லி பரிந்துரைக்காக கிசான் கால் சென்டரை "
        "(1800-180-1551) அழைக்கவும் அல்லது உங்கள் அருகிலுள்ள கிருஷி விஞ்ஞான கேந்திராவை (KVK) அணுகவும்.",
    },
    "chemical_action_2": {
        "en": "The organic guidance search above still works for cultural/biological options in the meantime.",
        "ta": "இதற்கிடையில், மேலே உள்ள இயற்கை வழிகாட்டுதல் தேடல் சாகுபடி/உயிரியல் வழிமுறைகளுக்கு இன்னும் பயன்படுத்தலாம்.",
    },
    "photo_data_source": {
        "en": "Uploaded photo (not analyzed)",
        "ta": "பதிவேற்றிய புகைப்படம் (பகுப்பாய்வு செய்யப்படவில்லை)",
    },
    "photo_assumption": {
        "en": "No vision-capable LLM API key is configured on this backend, so the photo could not be "
        "automatically analyzed. It was received successfully — only the analysis step is unavailable.",
        "ta": "இந்த பின்தளத்தில் பட-பகுப்பாய்வு செய்யக்கூடிய LLM API கீ அமைக்கப்படவில்லை, எனவே புகைப்படத்தை "
        "தானாக பகுப்பாய்வு செய்ய முடியவில்லை. அது வெற்றிகரமாக பெறப்பட்டது — பகுப்பாய்வு படி மட்டும் இல்லை.",
    },
    "photo_reasoning": {
        "en": "Photo-based detection requires a vision model; that step is not yet configured. "
        "Text-based symptom search against the organic guidance library works independently of this.",
        "ta": "புகைப்பட அடிப்படையிலான கண்டறிதலுக்கு ஒரு பட-மாதிரி தேவை; அந்த படி இன்னும் அமைக்கப்படவில்லை. "
        "இயற்கை வழிகாட்டுதல் நூலகத்திற்கு எதிரான உரை அடிப்படையிலான அறிகுறி தேடல் இதை சாராமல் வேலை செய்கிறது.",
    },
    "photo_risk_factor": {
        "en": "No automated diagnosis was performed for this photo.",
        "ta": "இந்த புகைப்படத்திற்கு தானியங்கு கண்டறிதல் எதுவும் செய்யப்படவில்லை.",
    },
    "photo_action_1": {
        "en": "Describe the crop and visible symptoms in the search box instead — that search works today.",
        "ta": "அதற்கு பதிலாக தேடல் பெட்டியில் பயிர் மற்றும் தெரியும் அறிகுறிகளை விவரிக்கவும் — அந்த தேடல் இப்போது வேலை செய்கிறது.",
    },
    "photo_action_2": {
        "en": "Keep the photo; once vision diagnosis is enabled it can be re-analyzed.",
        "ta": "புகைப்படத்தை வைத்திருங்கள்; பட கண்டறிதல் இயக்கப்பட்டவுடன் அதை மீண்டும் பகுப்பாய்வு செய்யலாம்.",
    },
    "photo_match_source": {
        "en": "Claude vision analysis, grounded in the organic disease knowledge base (12 diseases)",
        "ta": "க்ளாட் பட பகுப்பாய்வு, இயற்கை நோய் தரவுத்தளத்தை (12 நோய்கள்) அடிப்படையாகக் கொண்டது",
    },
    "photo_match_assumption_1": {
        "en": "This match came from automated photo analysis restricted to our 12-disease knowledge base — "
        "it cannot identify a disease outside that list. Treat it as a lead to verify, not a lab-confirmed diagnosis.",
        "ta": "இந்த பொருத்தம் எங்கள் 12-நோய் தரவுத்தளத்திற்கு மட்டுப்படுத்தப்பட்ட தானியங்கு புகைப்பட பகுப்பாய்விலிருந்து "
        "பெறப்பட்டது — அந்த பட்டியலுக்கு வெளியே உள்ள நோயை இது கண்டறியாது. இதை ஆய்வகம் உறுதிப்படுத்திய கண்டறிதலாக அல்லாமல், "
        "சரிபார்க்க வேண்டிய ஒரு துப்பாக கருதவும்.",
    },
    "photo_match_risk_factor": {
        "en": "AI vision-based match against a 12-disease starter catalog, not a confirmed lab or expert diagnosis.",
        "ta": "12-நோய் ஆரம்ப பட்டியலுக்கு எதிரான AI பட அடிப்படையிலான பொருத்தம், ஆய்வக அல்லது நிபுணர் "
        "உறுதிப்படுத்திய கண்டறிதல் அல்ல.",
    },
    "photo_no_match_name": {
        "en": "No clear match in photo",
        "ta": "புகைப்படத்தில் தெளிவான பொருத்தம் இல்லை",
    },
    "photo_no_match_source": {
        "en": "Claude vision analysis, grounded in the organic disease knowledge base (12 diseases)",
        "ta": "க்ளாட் பட பகுப்பாய்வு, இயற்கை நோய் தரவுத்தளத்தை (12 நோய்கள்) அடிப்படையாகக் கொண்டது",
    },
    "photo_no_match_assumption": {
        "en": "The photo was analyzed but did not clearly match any of the 12 diseases currently in the "
        "knowledge base. This does not mean the crop is healthy — only that this tool couldn't identify it.",
        "ta": "புகைப்படம் பகுப்பாய்வு செய்யப்பட்டது ஆனால் தரவுத்தளத்தில் உள்ள 12 நோய்களில் எதுவும் தெளிவாக "
        "பொருந்தவில்லை. இது பயிர் ஆரோக்கியமாக உள்ளது என்று அர்த்தமல்ல — இந்த கருவியால் அதை கண்டறிய முடியவில்லை என்பதே அர்த்தம்.",
    },
    "photo_no_match_reasoning": {
        "en": "No catalog entry was a confident visual match for this photo.",
        "ta": "இந்த புகைப்படத்திற்கு தரவுத்தளத்தில் நம்பகமான காட்சி பொருத்தம் எதுவும் இல்லை.",
    },
    "photo_no_match_risk_factor": {
        "en": "No automated match was found — treat this as inconclusive, not as confirmation the crop is disease-free.",
        "ta": "தானியங்கு பொருத்தம் எதுவும் கிடைக்கவில்லை — இதை பயிர் நோய் இல்லாதது என்ற உறுதிப்பாடாக அல்லாமல், "
        "முடிவற்றது என கருதவும்.",
    },
    "photo_no_match_action_1": {
        "en": "Try a clearer, closer photo in good light, or describe the symptoms in the search box instead.",
        "ta": "தெளிவான, நெருக்கமான புகைப்படத்தை நல்ல வெளிச்சத்தில் எடுக்க முயற்சிக்கவும், அல்லது தேடல் பெட்டியில் "
        "அறிகுறிகளை விவரிக்கவும்.",
    },
    "photo_failed_source": {
        "en": "Uploaded photo (analysis temporarily unavailable)",
        "ta": "பதிவேற்றிய புகைப்படம் (பகுப்பாய்வு தற்காலிகமாக கிடைக்கவில்லை)",
    },
    "photo_failed_assumption": {
        "en": "The photo was received, but the vision analysis service returned an error just now — this is a "
        "temporary issue, not a finding that the crop is healthy. Try again in a moment.",
        "ta": "புகைப்படம் பெறப்பட்டது, ஆனால் பட பகுப்பாய்வு சேவை இப்போது ஒரு பிழையை வழங்கியது — இது ஒரு "
        "தற்காலிக சிக்கல், பயிர் ஆரோக்கியமாக உள்ளது என்ற கண்டுபிடிப்பு அல்ல. சிறிது நேரத்தில் மீண்டும் முயற்சிக்கவும்.",
    },
    "photo_failed_reasoning": {
        "en": "The vision analysis call failed for this request.",
        "ta": "இந்த கோரிக்கைக்கு பட பகுப்பாய்வு அழைப்பு தோல்வியடைந்தது.",
    },
    "photo_failed_risk_factor": {
        "en": "No automated diagnosis was performed for this photo due to a service error.",
        "ta": "ஒரு சேவை பிழை காரணமாக இந்த புகைப்படத்திற்கு தானியங்கு கண்டறிதல் செய்யப்படவில்லை.",
    },
}


def _t(key: str, language: str) -> str:
    return _STRINGS[key].get(language, _STRINGS[key]["en"])


@app.on_event("startup")
def on_startup() -> None:
    vector_store.ensure_indexed()


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/disease/list", response_model=list[DiseaseSummary])
def list_diseases() -> list[DiseaseSummary]:
    return [
        DiseaseSummary(id=e["id"], disease_name=e["disease_name"], crops=e["crops"])
        for e in load_knowledge_base()
    ]


def _to_match(raw: dict, language: str) -> DiseaseMatch:
    localized = localize(raw, language)
    return DiseaseMatch(
        disease_id=localized["id"],
        disease_name=localized["disease_name"],
        pathogen=localized["pathogen"],
        crops=localized["crops"],
        symptoms=localized["symptoms"],
        favorable_conditions=localized["favorable_conditions"],
        organic_treatment=localized["organic_treatment"],
        prevention=localized["prevention"],
        sources=[DiseaseSource(**s) for s in localized["sources"]],
        similarity_score=round(localized["score"], 3),
    )


@app.post("/disease/search-organic-guidance", response_model=RecommendationEnvelope[DiseaseMatch])
def search_organic_guidance(payload: GuidanceQuery) -> RecommendationEnvelope[DiseaseMatch]:
    """Real RAG retrieval — BGE-M3 embeds the query, Qdrant returns the
    nearest matches from the curated organic knowledge base. No LLM
    involved in this step; it's the LLM-free "extractive" half of RAG,
    which works today regardless of whether an LLM API key is configured
    (see /disease/diagnose-photo for the half that needs one)."""
    lang = payload.language
    raw_results = vector_store.search(payload.query, top_k=payload.top_k, crop=payload.crop)
    now = datetime.now(timezone.utc)

    if not raw_results:
        return RecommendationEnvelope[DiseaseMatch](
            result=DiseaseMatch(
                disease_id="none",
                disease_name=_t("no_match_name", lang),
                pathogen="",
                crops=[],
                symptoms="",
                favorable_conditions="",
                organic_treatment="",
                prevention="",
                sources=[],
                similarity_score=0,
            ),
            confidence_score=0.0,
            data_sources=[DataSource(name=_t("no_match_source", lang), as_of=now, live=False)],
            assumptions=[_t("no_match_assumption", lang)],
            reasoning=_t("no_match_reasoning", lang),
            model_used=ModelUsed(name="bge-m3-qdrant-retrieval", version="0.1.0"),
            action_plan=[_t("no_match_action", lang)],
        )

    matches = [_to_match(r, lang) for r in raw_results]
    top, *rest = matches

    # Similarity score alone isn't the full confidence story — a mediocre
    # match on a 12-disease starter KB should read as "worth checking",
    # not "confirmed diagnosis".
    confidence = round(min(top.similarity_score, 0.85), 2)

    _reasoning_templates = {
        "en": "'{name}' matched your query via BGE-M3 embedding similarity ({pct:.0%}) against the organic guidance knowledge base.",
        "ta": "'{name}' என்பது BGE-M3 எம்பெடிங் ஒற்றுமையின் ({pct:.0%}) அடிப்படையில் இயற்கை வழிகாட்டுதல் தரவுத்தளத்தில் உங்கள் கேள்விக்கு பொருந்தியது.",
    }
    reasoning_template = _reasoning_templates.get(lang, _reasoning_templates["en"])

    return RecommendationEnvelope[DiseaseMatch](
        result=top,
        confidence_score=confidence,
        data_sources=[
            DataSource(name=s.name, as_of=now, live=False) for s in top.sources
        ] or [DataSource(name=_t("match_source_fallback", lang), as_of=now, live=False)],
        assumptions=[_t("match_assumption_1", lang), _t("match_assumption_2", lang)],
        reasoning=reasoning_template.format(name=top.disease_name, pct=top.similarity_score),
        model_used=ModelUsed(name="bge-m3-qdrant-retrieval", version="0.1.0"),
        alternatives=rest,
        risk_analysis=RiskAnalysis(
            level=RiskLevel.MEDIUM if confidence >= 0.5 else RiskLevel.HIGH,
            factors=[_t("match_risk_factor", lang)],
        ),
        action_plan=[_t("match_action_1", lang), _t("match_action_2", lang)],
    )


_ALLOWED_IMAGE_MEDIA_TYPES = {"image/jpeg", "image/png", "image/gif", "image/webp"}


def _photo_match_reasoning(language: str, disease_name: str, confidence: float) -> str:
    templates = {
        "en": "Photo analysis matched '{name}' with {pct:.0%} confidence, restricted to the organic disease knowledge base.",
        "ta": "புகைப்பட பகுப்பாய்வு '{name}' உடன் {pct:.0%} நம்பகத்தன்மையுடன் பொருந்தியது, இயற்கை நோய் "
        "தரவுத்தளத்திற்கு மட்டுப்படுத்தப்பட்டது.",
    }
    return templates.get(language, templates["en"]).format(name=disease_name, pct=confidence)


@app.post("/disease/diagnose-photo", response_model=RecommendationEnvelope[dict])
async def diagnose_photo(
    crop: str = Form(...),
    notes: str = Form(""),
    photo: UploadFile = File(...),
    language: str = Form("en"),
) -> RecommendationEnvelope[dict]:
    """RAG-grounded computer-vision diagnosis: Claude looks at the photo but
    is constrained (via structured output) to pick a disease_id from THIS
    backend's curated knowledge base, or 'none' — see vision.py. All
    display text for a match (symptoms/treatment/prevention/sources)
    still comes from knowledge_base.py, never from Claude's own words, so
    the "never hallucinate" contract holds exactly as it does for the
    text-based search in search_organic_guidance() above."""
    now = datetime.now(timezone.utc)
    contents = await photo.read()
    received_kb = round(len(contents) / 1024, 1)

    if not ANTHROPIC_API_KEY:
        return RecommendationEnvelope[dict](
            result={"crop": crop, "notes": notes, "photo_received_kb": received_kb, "vision_diagnosis_available": False},
            confidence_score=0.0,
            data_sources=[DataSource(name=_t("photo_data_source", language), as_of=now, live=False)],
            assumptions=[_t("photo_assumption", language)],
            reasoning=_t("photo_reasoning", language),
            model_used=None,
            risk_analysis=RiskAnalysis(level=RiskLevel.MEDIUM, factors=[_t("photo_risk_factor", language)]),
            action_plan=[_t("photo_action_1", language), _t("photo_action_2", language)],
        )

    media_type = photo.content_type if photo.content_type in _ALLOWED_IMAGE_MEDIA_TYPES else "image/jpeg"
    vision_result = vision.diagnose(
        image_bytes=contents, media_type=media_type, crop_hint=crop, notes=notes, api_key=ANTHROPIC_API_KEY
    )

    if vision_result is None:
        return RecommendationEnvelope[dict](
            result={"crop": crop, "notes": notes, "photo_received_kb": received_kb, "vision_diagnosis_available": True},
            confidence_score=0.0,
            data_sources=[DataSource(name=_t("photo_failed_source", language), as_of=now, live=False)],
            assumptions=[_t("photo_failed_assumption", language)],
            reasoning=_t("photo_failed_reasoning", language),
            model_used=ModelUsed(name="claude-opus-4-8-vision", version="0.1.0"),
            risk_analysis=RiskAnalysis(level=RiskLevel.MEDIUM, factors=[_t("photo_failed_risk_factor", language)]),
            action_plan=[_t("photo_action_1", language)],
        )

    matched_id = vision_result.get("matched_disease_id", "none")
    if matched_id == "none":
        return RecommendationEnvelope[dict](
            result={
                "crop": crop,
                "notes": notes,
                "photo_received_kb": received_kb,
                "vision_diagnosis_available": True,
                "disease_name": _t("photo_no_match_name", language),
                "observed_symptoms": vision_result.get("observed_symptoms", ""),
            },
            confidence_score=0.0,
            data_sources=[DataSource(name=_t("photo_no_match_source", language), as_of=now, live=True)],
            assumptions=[_t("photo_no_match_assumption", language)],
            reasoning=_t("photo_no_match_reasoning", language),
            model_used=ModelUsed(name="claude-opus-4-8-vision", version="0.1.0"),
            risk_analysis=RiskAnalysis(level=RiskLevel.HIGH, factors=[_t("photo_no_match_risk_factor", language)]),
            action_plan=[_t("photo_no_match_action_1", language)],
        )

    raw_entry = next((e for e in load_knowledge_base() if e["id"] == matched_id), None)
    if raw_entry is None:
        # Model returned an id outside the enum we sent it — treat like "none" rather than crash.
        return RecommendationEnvelope[dict](
            result={"crop": crop, "notes": notes, "photo_received_kb": received_kb, "vision_diagnosis_available": True},
            confidence_score=0.0,
            data_sources=[DataSource(name=_t("photo_no_match_source", language), as_of=now, live=True)],
            assumptions=[_t("photo_no_match_assumption", language)],
            reasoning=_t("photo_no_match_reasoning", language),
            model_used=ModelUsed(name="claude-opus-4-8-vision", version="0.1.0"),
            risk_analysis=RiskAnalysis(level=RiskLevel.HIGH, factors=[_t("photo_no_match_risk_factor", language)]),
            action_plan=[_t("photo_no_match_action_1", language)],
        )

    confidence = max(0.0, min(1.0, float(vision_result.get("confidence", 0.0))))
    match = _to_match({**raw_entry, "score": confidence}, language)

    return RecommendationEnvelope[dict](
        result=match.model_dump(),
        confidence_score=round(confidence, 2),
        data_sources=[DataSource(name=_t("photo_match_source", language), as_of=now, live=True)],
        assumptions=[_t("photo_match_assumption_1", language), _t("match_assumption_2", language)],
        reasoning=_photo_match_reasoning(language, match.disease_name, confidence),
        model_used=ModelUsed(name="claude-opus-4-8-vision", version="0.1.0"),
        risk_analysis=RiskAnalysis(
            level=RiskLevel.MEDIUM if confidence >= 0.5 else RiskLevel.HIGH,
            factors=[_t("photo_match_risk_factor", language)],
        ),
        action_plan=[_t("match_action_1", language), _t("match_action_2", language)],
    )


@app.post("/disease/chemical-guidance", response_model=RecommendationEnvelope[dict])
def chemical_guidance(payload: GuidanceQuery) -> RecommendationEnvelope[dict]:
    """The non-organic path deliberately does NOT get its own curated
    knowledge base or RAG pipeline right now — chemical/pesticide
    recommendations carry real safety and legal risk if wrong (using a
    banned or mismatched product), so this project's policy is: no
    fabricated specific product/dosage without a properly sourced,
    government-approved-pesticide dataset (see docs/architecture/
    MODULES.md §9, "Government Approved Pesticides" — not built yet).
    Farmers are pointed to real institutional channels instead."""
    lang = payload.language
    now = datetime.now(timezone.utc)
    return RecommendationEnvelope[dict](
        result={"query": payload.query, "crop": payload.crop},
        confidence_score=0.0,
        data_sources=[DataSource(name=_t("chemical_source", lang), as_of=now, live=False)],
        assumptions=[_t("chemical_assumption", lang)],
        reasoning=_t("chemical_reasoning", lang),
        model_used=None,
        risk_analysis=RiskAnalysis(
            level=RiskLevel.HIGH,
            factors=[_t("chemical_risk_factor", lang)],
        ),
        action_plan=[_t("chemical_action_1", lang), _t("chemical_action_2", lang)],
    )
