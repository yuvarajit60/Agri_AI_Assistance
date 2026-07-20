"""Weather provider interface (docs/architecture/ARCHITECTURE.md §8,
multi-country DataSourceProvider pattern). Real implementations
(OpenWeatherProvider, IMDProvider, NASAPowerProvider) will implement this
same interface and be selected by country config; nothing above this
layer should need to change when they're added.
"""

from __future__ import annotations

import hashlib
import math
from abc import ABC, abstractmethod
from dataclasses import dataclass

from agri_common import Location

HORIZON_CONFIDENCE = {
    "7d": 0.86,
    "30d": 0.64,
    "90d": 0.45,
    "seasonal": 0.38,
    "annual": 0.25,
}

HORIZON_SOURCE = {
    "7d": "OpenWeather 7-day forecast",
    "30d": "OpenWeather 30-day outlook",
    "90d": "NASA POWER seasonal climatology",
    "seasonal": "IMD seasonal monsoon outlook",
    "annual": "NASA POWER long-term climatology trend",
}

HORIZON_DAYS = {"7d": 7, "30d": 30, "90d": 90, "seasonal": 120, "annual": 365}


@dataclass
class DailyForecast:
    day_offset: int
    avg_temp_c: float
    min_temp_c: float
    max_temp_c: float
    rain_probability_percent: int
    humidity_percent: int


@dataclass
class WeatherForecast:
    horizon: str
    avg_temp_c: float
    min_temp_c: float
    max_temp_c: float
    total_rainfall_mm: float
    avg_humidity_percent: int
    evapotranspiration_mm: float
    daily: list[DailyForecast]


class WeatherProvider(ABC):
    @abstractmethod
    def get_forecast(self, location: Location, horizon: str) -> WeatherForecast: ...


class MockWeatherProvider(WeatherProvider):
    """Deterministic (seeded by lat/lon) synthetic forecast so the API
    contract, confidence-by-horizon behavior, and downstream services are
    fully exercisable before a real weather API key is configured."""

    def get_forecast(self, location: Location, horizon: str) -> WeatherForecast:
        if horizon not in HORIZON_DAYS:
            raise ValueError(f"Unknown horizon '{horizon}'. Expected one of {list(HORIZON_DAYS)}.")

        seed = int(hashlib.sha256(f"{location.latitude:.3f},{location.longitude:.3f}".encode()).hexdigest(), 16)
        base_temp = 22 + (seed % 12)  # 22-33C baseline, deterministic per location
        days = HORIZON_DAYS[horizon]

        daily: list[DailyForecast] = []
        show_days = min(days, 7)  # only 7-day horizon returns a day-by-day breakdown
        for i in range(show_days):
            wobble = math.sin((seed % 97 + i) / 3.0) * 3
            avg = round(base_temp + wobble, 1)
            rain_p = int((seed >> (i % 8)) % 100)
            daily.append(
                DailyForecast(
                    day_offset=i,
                    avg_temp_c=avg,
                    min_temp_c=round(avg - 4, 1),
                    max_temp_c=round(avg + 4, 1),
                    rain_probability_percent=rain_p,
                    humidity_percent=45 + (rain_p % 40),
                )
            )

        avg_temp = round(sum(d.avg_temp_c for d in daily) / len(daily), 1) if daily else float(base_temp)
        total_rainfall = round(sum(d.rain_probability_percent for d in daily) / 100 * 8, 1) if daily else round(days * 2.1, 1)

        return WeatherForecast(
            horizon=horizon,
            avg_temp_c=avg_temp,
            min_temp_c=round(avg_temp - 5, 1),
            max_temp_c=round(avg_temp + 6, 1),
            total_rainfall_mm=total_rainfall,
            avg_humidity_percent=int(sum(d.humidity_percent for d in daily) / len(daily)) if daily else 60,
            evapotranspiration_mm=round(avg_temp * 0.18 * (days / 7), 1),
            daily=daily,
        )
