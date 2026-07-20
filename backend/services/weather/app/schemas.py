from __future__ import annotations

from typing import Literal

from pydantic import BaseModel

Horizon = Literal["7d", "30d", "90d", "seasonal", "annual"]


class DailyForecastOut(BaseModel):
    day_offset: int
    avg_temp_c: float
    min_temp_c: float
    max_temp_c: float
    rain_probability_percent: int
    humidity_percent: int


class WeatherForecastResult(BaseModel):
    horizon: Horizon
    avg_temp_c: float
    min_temp_c: float
    max_temp_c: float
    total_rainfall_mm: float
    avg_humidity_percent: int
    evapotranspiration_mm: float
    daily: list[DailyForecastOut]
