"""Synthetic historical mandi price data (docs/architecture/MODULES.md
§10, market_price service). No live Agmarknet/data.gov.in integration is
wired up yet -- data.gov.in publishes a free-registration "Variety-wise
Daily Market Prices of Commodities" API that is the natural real source
to wire in later, the same "interface ready, provider swapped in when a
key is configured" pattern used for ANTHROPIC_API_KEY in disease_kb.
Until then this is honestly labeled `live=False` throughout this service
(see main.py's data_sources) -- it is NOT sourced from any real mandi.

Generates a deterministic, seeded weekly price series per commodity with:
- A seasonal cycle keyed to the commodity's typical harvest month (price
  dips near harvest, when regional supply peaks, and rises in the lean
  season) -- see commodity_catalog.py for the per-commodity parameters.
- A modest year-over-year upward trend (broad reference inflation, not a
  specific forecast).
- Small bounded weekly noise, seeded so the same commodity always
  produces the same history -- this is what makes the Prophet/SARIMA fit
  in forecasting.py reproducible and testable, not just "random each run".
"""

from __future__ import annotations

import hashlib
import math
from datetime import date, timedelta

import numpy as np
import pandas as pd

from .commodity_catalog import CommodityProfile

WEEKS_OF_HISTORY = 156  # 3 years -- gives a 52-week-seasonal SARIMA fallback enough cycles to fit
_ANNUAL_TREND_RATE = 0.06  # ~6%/year broad agri-inflation reference, not a specific claim
_NOISE_FRACTION_OF_BASE = 0.02


def seed_for(commodity_name: str) -> int:
    digest = hashlib.sha256(f"market-history:{commodity_name.lower()}".encode()).hexdigest()
    return int(digest[:8], 16)


def generate_weekly_history(commodity: CommodityProfile, *, as_of: date | None = None) -> pd.DataFrame:
    """Returns a DataFrame with columns ['ds', 'y'] (Prophet's expected
    shape; forecasting.py's SARIMA path reindexes the same frame on 'ds')."""
    as_of = as_of or date.today()
    rng = np.random.RandomState(seed_for(commodity.name))

    start = as_of - timedelta(weeks=WEEKS_OF_HISTORY - 1)
    dates = [start + timedelta(weeks=i) for i in range(WEEKS_OF_HISTORY)]

    base = commodity.base_price_per_quintal_inr
    amplitude = base * commodity.seasonality_amplitude
    harvest_frac = (commodity.typical_harvest_month - 1) / 12

    prices = []
    for i, d in enumerate(dates):
        month_frac = (d.month - 1 + (d.day - 1) / 30) / 12
        # Cosine trough exactly at the harvest month (supply peak -> price dip),
        # crest at the opposite point in the year (lean season -> price peak).
        phase = 2 * math.pi * (month_frac - harvest_frac)
        seasonal = -amplitude * math.cos(phase)

        years_elapsed = i / 52
        trend = base * _ANNUAL_TREND_RATE * years_elapsed

        noise = rng.normal(0, base * _NOISE_FRACTION_OF_BASE)
        price = max(base * 0.4, base + seasonal + trend + noise)
        prices.append(round(price, 2))

    return pd.DataFrame({"ds": pd.to_datetime(dates), "y": prices})
