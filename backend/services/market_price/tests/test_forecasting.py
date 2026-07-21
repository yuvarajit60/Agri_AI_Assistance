import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from app import forecasting, history_provider  # noqa: E402
from app.commodity_catalog import find_commodity  # noqa: E402


def test_sarima_fallback_produces_a_valid_forecast():
    """Exercises the fallback path directly -- normal /market/price-forecast
    calls always succeed via Prophet, so this is the only test that
    actually runs SARIMA and would catch a regression there."""
    commodity = find_commodity("Rice")
    assert commodity is not None
    history = history_provider.generate_weekly_history(commodity)

    forecast_df = forecasting._forecast_with_sarima(history)  # noqa: SLF001 - intentionally exercising the fallback directly

    assert len(forecast_df) == forecasting.FORECAST_WEEKS
    assert (forecast_df["yhat"] > 0).all()
    assert (forecast_df["yhat_lower"] <= forecast_df["yhat"]).all()
    assert (forecast_df["yhat"] <= forecast_df["yhat_upper"]).all()
    weeks = forecast_df["ds"].tolist()
    assert weeks == sorted(weeks)


def test_forecast_falls_back_to_sarima_when_prophet_unavailable(monkeypatch):
    def _boom(history, seed):
        raise RuntimeError("simulated prophet/cmdstan failure")

    monkeypatch.setattr(forecasting, "_forecast_with_prophet", _boom)

    commodity = find_commodity("Wheat")
    assert commodity is not None
    history = history_provider.generate_weekly_history(commodity)

    result = forecasting.forecast(history, seed=history_provider.seed_for(commodity.name))

    assert result.engine == "sarima"
    assert len(result.forecast) == forecasting.FORECAST_WEEKS
