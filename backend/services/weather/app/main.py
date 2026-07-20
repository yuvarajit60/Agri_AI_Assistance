from __future__ import annotations

from datetime import datetime, timezone

from agri_common import DataSource, Location, ModelUsed, RecommendationEnvelope
from fastapi import FastAPI

from .providers import HORIZON_CONFIDENCE, HORIZON_SOURCE, MockWeatherProvider
from .schemas import DailyForecastOut, Horizon, WeatherForecastResult

app = FastAPI(title="Weather Service", version="0.1.0")
_provider = MockWeatherProvider()


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/weather/forecast", response_model=RecommendationEnvelope[WeatherForecastResult])
def forecast(lat: float, lon: float, horizon: Horizon = "7d") -> RecommendationEnvelope[WeatherForecastResult]:
    location = Location(latitude=lat, longitude=lon)
    raw = _provider.get_forecast(location, horizon)
    now = datetime.now(timezone.utc)

    result = WeatherForecastResult(
        horizon=raw.horizon,  # type: ignore[arg-type]
        avg_temp_c=raw.avg_temp_c,
        min_temp_c=raw.min_temp_c,
        max_temp_c=raw.max_temp_c,
        total_rainfall_mm=raw.total_rainfall_mm,
        avg_humidity_percent=raw.avg_humidity_percent,
        evapotranspiration_mm=raw.evapotranspiration_mm,
        daily=[DailyForecastOut(**d.__dict__) for d in raw.daily],
    )

    confidence = HORIZON_CONFIDENCE[horizon]
    assumptions = ["Served by the mock weather provider — no live OpenWeather/IMD API key configured yet."]
    if horizon in ("90d", "seasonal", "annual"):
        assumptions.append(
            f"{horizon} figures are climatological/statistical outlooks, not a precise day-by-day forecast."
        )

    return RecommendationEnvelope[WeatherForecastResult](
        result=result,
        confidence_score=confidence,
        data_sources=[DataSource(name=HORIZON_SOURCE[horizon], as_of=now, live=False)],
        assumptions=assumptions,
        reasoning=f"{horizon} forecast confidence reflects typical predictability at this horizon; "
        "shorter horizons are backed by direct forecast models, longer ones by climatological averages.",
        model_used=ModelUsed(name="mock-weather-provider", version="0.1.0"),
        action_plan=(
            ["Treat this as indicative only — re-check closer to the date before making irrigation/harvest decisions."]
            if horizon != "7d"
            else []
        ),
    )
