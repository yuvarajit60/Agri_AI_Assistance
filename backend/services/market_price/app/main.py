"""Market Price Prediction Service (docs/architecture/MODULES.md §10).

Forecasts near-term mandi price movement for a commodity using Prophet
(falling back to a statsmodels SARIMAX model — see forecasting.py) fit
on a *synthetic* historical price series (see history_provider.py). This
is the same "real algorithm, honestly-labeled synthetic data until a
live source is wired in" pattern used by soil/weather/water's mock
providers — the forecasting pipeline itself is real and reusable, only
the training data underneath it is a stand-in for a future
Agmarknet/data.gov.in integration.
"""

from __future__ import annotations

import calendar
from datetime import datetime, timezone

from agri_common import DataSource, ModelUsed, RecommendationEnvelope, RiskAnalysis, RiskLevel
from fastapi import FastAPI, HTTPException

from . import forecasting, history_provider
from .commodity_catalog import all_commodity_names, find_commodity
from .mandi_provider import nearby_mandis
from .schemas import ForecastPoint, PriceForecastRequest, PriceForecastResult

app = FastAPI(title="Market Price Prediction Service", version="0.1.0")

# Synthetic-training-data ceiling -- mirrors crop_recommendation's own
# knowledge_base_confidence cap (0.75) for the same reason (see
# crop_recommendation/app/engine.py's overall_confidence), but lower
# because that knowledge base is curated real reference data while this
# service's training series is entirely synthetic until a real
# Agmarknet/data.gov.in source is wired in.
_CONFIDENCE_CAP = 0.5

_MONTH_NAMES_TA = [
    "ஜனவரி", "பிப்ரவரி", "மார்ச்", "ஏப்ரல்", "மே", "ஜூன்",
    "ஜூலை", "ஆகஸ்ட்", "செப்டம்பர்", "அக்டோபர்", "நவம்பர்", "டிசம்பர்",
]

_STRINGS: dict[str, dict[str, str]] = {
    "unknown_commodity": {
        "en": "'{commodity}' isn't in our commodity catalog yet — try one of the crops from your recommendation results.",
        "ta": "'{commodity}' இன்னும் எங்கள் பொருள் பட்டியலில் இல்லை — உங்கள் பரிந்துரை முடிவுகளில் உள்ள பயிர்களில் ஒன்றை முயற்சிக்கவும்.",
    },
    "data_source": {
        "en": "Synthetic reference price series modeled on typical seasonal patterns for this commodity — not live Agmarknet data yet.",
        "ta": "இந்த பொருளுக்கான வழக்கமான பருவகால போக்குகளை மாதிரியாகக் கொண்ட செயற்கை குறிப்பு விலை தொடர் — இன்னும் நேரடி "
        "அக்மார்க்நெட் தரவு அல்ல.",
    },
    "assumption_synthetic": {
        "en": "Prices are forecast from a synthetic reference series (seasonal pattern + broad trend), not live Agmarknet "
        "mandi records — treat this as an illustrative trend, not a trading signal.",
        "ta": "விலைகள் ஒரு செயற்கை குறிப்பு தொடரிலிருந்து (பருவகால போக்கு + பொதுவான போக்கு) கணிக்கப்படுகின்றன, நேரடி "
        "அக்மார்க்நெட் சந்தை பதிவுகளிலிருந்து அல்ல — இதை ஒரு விளக்கமளிக்கும் போக்காகக் கருதவும், வர்த்தக சமிக்ஞையாக அல்ல.",
    },
    "assumption_mandi": {
        "en": "Nearby mandi entries are role-based estimates (nearest APMC / regional wholesale / secondary market), not a "
        "real market directory lookup.",
        "ta": "அருகிலுள்ள சந்தை பதிவுகள் பங்கு அடிப்படையிலான மதிப்பீடுகள் (அருகிலுள்ள APMC / பிராந்திய மொத்த விற்பனை / "
        "இரண்டாம் நிலை சந்தை), உண்மையான சந்தை அடைவு தேடல் அல்ல.",
    },
    "risk_factor": {
        "en": "Forecast trained on synthetic seasonal data, not live mandi records — do not use this alone for a sell/hold decision.",
        "ta": "செயற்கை பருவகால தரவில் பயிற்சி பெற்ற முன்னறிவிப்பு, நேரடி சந்தை பதிவுகள் அல்ல — விற்பனை/வைத்திருத்தல் "
        "முடிவுக்கு இதை மட்டும் நம்பாதீர்கள்.",
    },
    "action_1": {
        "en": "Confirm today's actual price with your local mandi or the Agmarknet website before deciding when to sell.",
        "ta": "விற்பனை செய்யும் நேரத்தை முடிவு செய்யும் முன் உங்கள் உள்ளூர் சந்தை அல்லது அக்மார்க்நெட் இணையதளத்தில் "
        "இன்றைய உண்மையான விலையை உறுதிப்படுத்தவும்.",
    },
    "action_2": {
        "en": "If storage is available, the forecast lean-season peak may be worth waiting for — weigh that against storage cost and spoilage risk.",
        "ta": "சேமிப்பு வசதி இருந்தால், முன்னறிவிக்கப்பட்ட பருவகால உச்ச விலைக்காக காத்திருப்பது மதிப்புள்ளதாக இருக்கலாம் — "
        "அதை சேமிப்பு செலவு மற்றும் கெட்டுப்போகும் அபாயத்துடன் ஒப்பிடவும்.",
    },
}


def _t(key: str, language: str, **kwargs: object) -> str:
    template = _STRINGS[key].get(language, _STRINGS[key]["en"])
    return template.format(**kwargs) if kwargs else template


def _month_name(month: int, language: str) -> str:
    if language == "ta":
        return _MONTH_NAMES_TA[month - 1]
    return calendar.month_name[month]


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/market/commodities")
def list_commodities() -> list[str]:
    return all_commodity_names()


@app.post("/market/price-forecast", response_model=RecommendationEnvelope[PriceForecastResult])
def price_forecast(req: PriceForecastRequest) -> RecommendationEnvelope[PriceForecastResult]:
    commodity = find_commodity(req.commodity)
    if commodity is None:
        raise HTTPException(status_code=404, detail=_t("unknown_commodity", req.language, commodity=req.commodity))

    history = history_provider.generate_weekly_history(commodity)
    result = forecasting.forecast(history, seed=history_provider.seed_for(commodity.name))
    fc = result.forecast

    near_term = fc.head(4)
    near_term_low = round(float(near_term["yhat"].min()), 2)
    near_term_high = round(float(near_term["yhat"].max()), 2)

    peak_idx = fc["yhat"].idxmax()
    peak_row = fc.loc[peak_idx]
    best_month = _month_name(int(peak_row["ds"].month), req.language)

    forecast_points = [
        ForecastPoint(
            week_start=row["ds"].date(),
            predicted_price_inr_per_quintal=round(float(row["yhat"]), 2),
            lower_bound_inr_per_quintal=round(float(row["yhat_lower"]), 2),
            upper_bound_inr_per_quintal=round(float(row["yhat_upper"]), 2),
        )
        for _, row in fc.iterrows()
    ]

    current_price = round(float(history["y"].iloc[-1]), 2)
    mandis = nearby_mandis(commodity, req.lat, req.lon, current_price, req.language)

    now = datetime.now(timezone.utc)
    payload = PriceForecastResult(
        commodity=commodity.name,
        current_price_inr_per_quintal=current_price,
        near_term_low_inr_per_quintal=near_term_low,
        near_term_high_inr_per_quintal=near_term_high,
        best_selling_month=best_month,
        best_selling_month_price_inr_per_quintal=round(float(peak_row["yhat"]), 2),
        forecast_points=forecast_points,
        nearby_mandis=mandis,
    )

    engine_label = "prophet-yearly-seasonal" if result.engine == "prophet" else "sarima-seasonal-fallback"
    return RecommendationEnvelope[PriceForecastResult](
        result=payload,
        confidence_score=_CONFIDENCE_CAP,
        data_sources=[DataSource(name=_t("data_source", req.language), as_of=now, live=False)],
        assumptions=[_t("assumption_synthetic", req.language), _t("assumption_mandi", req.language)],
        reasoning=(
            f"{commodity.name} forecast over the next 12 months using a {result.engine} model fit on a synthetic "
            f"seasonal reference series; near-term expected range is INR {near_term_low:.0f}-{near_term_high:.0f} "
            f"per quintal, with the modeled peak in {best_month}."
        ),
        model_used=ModelUsed(name=engine_label, version="0.1.0"),
        risk_analysis=RiskAnalysis(level=RiskLevel.MEDIUM, factors=[_t("risk_factor", req.language)]),
        action_plan=[_t("action_1", req.language), _t("action_2", req.language)],
    )
