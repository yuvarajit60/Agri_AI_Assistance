"""Forecasting engine for market_price. Tries Prophet first (handles the
yearly seasonal cycle in history_provider.py's synthetic data natively,
and is what most Agmarknet-price forecasting write-ups use); falls back
to a statsmodels SARIMAX model if Prophet is unavailable or its fit
fails for any reason at runtime, so this service never hard-fails just
because the heavier prophet/cmdstan dependency isn't usable in a given
deployment environment -- see main.py's model_used field for which
engine actually produced a given response.
"""

from __future__ import annotations

import logging
from dataclasses import dataclass

import pandas as pd

logger = logging.getLogger(__name__)

FORECAST_WEEKS = 52  # 12 months ahead
_INTERVAL_WIDTH = 0.8  # ~80% prediction interval, used consistently by both engines


@dataclass
class ForecastResult:
    engine: str  # "prophet" | "sarima"
    forecast: pd.DataFrame  # columns: ds, yhat, yhat_lower, yhat_upper -- future rows only


def _forecast_with_prophet(history: pd.DataFrame, seed: int) -> pd.DataFrame:
    import numpy as np
    from prophet import Prophet  # lazy import: a missing/broken install only affects this path

    # Prophet's confidence-interval sampling draws from numpy's global RNG
    # with no seed parameter of its own -- without pinning it here, yhat
    # stays identical across calls but yhat_lower/yhat_upper drift on every
    # request, breaking the "same commodity -> same result" determinism
    # this service relies on (see history_provider.py's own seeding).
    np.random.seed(seed)

    model = Prophet(
        yearly_seasonality=True,
        weekly_seasonality=False,
        daily_seasonality=False,
        interval_width=_INTERVAL_WIDTH,
    )
    model.fit(history)
    future = model.make_future_dataframe(periods=FORECAST_WEEKS, freq="W")
    forecast = model.predict(future)
    return forecast[["ds", "yhat", "yhat_lower", "yhat_upper"]].tail(FORECAST_WEEKS).reset_index(drop=True)


_YEARLY_PERIOD_WEEKS = 52.1775  # average weeks/year -- keeps the Fourier phase from drifting over 3 years of history


def _fourier_terms(t: range, harmonics: int = 2) -> dict[str, "np.ndarray"]:
    """Yearly-seasonality regressors as sin/cos harmonics of week index `t`.
    Returns plain numpy arrays, not pd.Series -- building the caller's
    DataFrame as `pd.DataFrame(dict_of_series, index=target_index)` would
    *align* each Series to target_index by its own (default RangeIndex)
    index rather than assign positionally; since a RangeIndex never
    overlaps a DatetimeIndex, every value silently becomes NaN. Plain
    arrays have no index to misalign, so this bug can't recur.

    Native seasonal ARIMA (`seasonal_order=(p,d,q,52)`) is numerically
    unreliable at a 52-week period -- its state-space dimension scales
    with the period, and seasonal differencing (D=1) alone consumes a
    full year of the 3-year history before any parameters can be
    estimated, which under-determines the model (verified: it degrades to
    an all-zero forecast on this exact dataset shape). Modeling yearly
    seasonality as exogenous Fourier regressors on a plain (non-seasonal)
    SARIMAX is the standard workaround for long seasonal periods and is
    what this project's other statsmodels-adjacent choices favor:
    reliable and inspectable over sophisticated (see crop_recommendation/
    app/engine.py's docstring on the same tradeoff)."""
    import numpy as np

    idx = np.array(t, dtype=float)
    terms: dict[str, np.ndarray] = {}
    for h in range(1, harmonics + 1):
        angle = 2 * np.pi * h * (idx / _YEARLY_PERIOD_WEEKS)
        terms[f"sin{h}"] = np.sin(angle)
        terms[f"cos{h}"] = np.cos(angle)
    return terms


def _forecast_with_sarima(history: pd.DataFrame) -> pd.DataFrame:
    from statsmodels.tsa.statespace.sarimax import SARIMAX  # lazy import, mirrors the Prophet path

    series = history.set_index("ds")["y"]
    # history_provider's dates are exactly 7 days apart but not necessarily
    # Sunday-anchored -- forcing a `W-SUN` frequency here doesn't match the
    # actual weekday present, and asfreq() then silently reindexes onto a
    # grid with zero overlap, turning the whole series into NaN (verified:
    # this was the actual root cause of the "too few observations" warning
    # below and an all-zero fit, not real data insufficiency). Infer the
    # real weekly anchor from the data instead.
    inferred_freq = pd.infer_freq(series.index)
    series = series.asfreq(inferred_freq)
    n = len(series)
    future_dates = pd.date_range(series.index[-1] + series.index.freq, periods=FORECAST_WEEKS, freq=inferred_freq)

    exog_train = pd.DataFrame(_fourier_terms(range(n)), index=series.index)
    # Index must match future_dates exactly -- get_forecast() aligns exog by
    # index, not position, so a mismatched (e.g. default RangeIndex) exog
    # silently reindexes to all-NaN rather than raising, which surfaces as
    # a confusing downstream "exog contains inf or nans" error.
    exog_future = pd.DataFrame(_fourier_terms(range(n, n + FORECAST_WEEKS)), index=future_dates)

    model = SARIMAX(
        series,
        exog=exog_train,
        order=(1, 1, 1),
        enforce_stationarity=False,
        enforce_invertibility=False,
    )
    fitted = model.fit(disp=False)
    pred = fitted.get_forecast(steps=FORECAST_WEEKS, exog=exog_future)
    ci = pred.conf_int(alpha=1 - _INTERVAL_WIDTH)

    return pd.DataFrame(
        {
            "ds": future_dates,
            "yhat": pred.predicted_mean.to_numpy(),
            "yhat_lower": ci.iloc[:, 0].to_numpy(),
            "yhat_upper": ci.iloc[:, 1].to_numpy(),
        }
    )


def forecast(history: pd.DataFrame, seed: int = 0) -> ForecastResult:
    try:
        return ForecastResult("prophet", _forecast_with_prophet(history, seed))
    except Exception as exc:  # noqa: BLE001 - deliberately broad: any prophet/cmdstan failure falls back to SARIMA
        logger.warning("Prophet forecast failed (%s); falling back to SARIMA.", exc)
        return ForecastResult("sarima", _forecast_with_sarima(history))
