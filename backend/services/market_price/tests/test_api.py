import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from app.main import app  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402

client = TestClient(app)


def test_health():
    resp = client.get("/health")
    assert resp.status_code == 200


def test_list_commodities_nonempty():
    resp = client.get("/market/commodities")
    assert resp.status_code == 200
    names = resp.json()
    assert "Rice" in names
    assert len(names) >= 10


def test_forecast_returns_full_contract():
    resp = client.post(
        "/market/price-forecast",
        json={"commodity": "Rice", "lat": 20.5, "lon": 78.9, "language": "en"},
    )
    assert resp.status_code == 200
    body = resp.json()
    assert 0 < body["confidence_score"] <= 0.5
    assert len(body["data_sources"]) >= 1
    assert body["reasoning"]
    result = body["result"]
    assert result["commodity"] == "Rice"
    assert result["current_price_inr_per_quintal"] > 0
    assert result["near_term_low_inr_per_quintal"] <= result["near_term_high_inr_per_quintal"]
    assert len(result["forecast_points"]) == 52
    assert len(result["nearby_mandis"]) == 3
    # forecast weeks are in chronological order
    weeks = [p["week_start"] for p in result["forecast_points"]]
    assert weeks == sorted(weeks)


def test_forecast_is_deterministic_for_same_commodity():
    payload = {"commodity": "Wheat", "lat": 22.0, "lon": 79.0, "language": "en"}
    first = client.post("/market/price-forecast", json=payload).json()
    second = client.post("/market/price-forecast", json=payload).json()
    assert first["result"]["current_price_inr_per_quintal"] == second["result"]["current_price_inr_per_quintal"]
    assert first["result"]["forecast_points"] == second["result"]["forecast_points"]


def test_unknown_commodity_returns_404():
    resp = client.post(
        "/market/price-forecast",
        json={"commodity": "Unobtainium", "lat": 20.0, "lon": 78.0, "language": "en"},
    )
    assert resp.status_code == 404


def test_fuzzy_commodity_name_resolves():
    """crop_recommendation emits names like 'Vegetables (Tomato)' — the
    catalog lookup should resolve a bare 'Tomato' to the same entry."""
    resp = client.post(
        "/market/price-forecast",
        json={"commodity": "Tomato", "lat": 20.0, "lon": 78.0, "language": "en"},
    )
    assert resp.status_code == 200
    assert resp.json()["result"]["commodity"] == "Vegetables (Tomato)"


def test_tamil_language_localizes_text_fields():
    resp = client.post(
        "/market/price-forecast",
        json={"commodity": "Rice", "lat": 20.5, "lon": 78.9, "language": "ta"},
    )
    assert resp.status_code == 200
    body = resp.json()
    assert body["data_sources"][0]["name"] != ""
    # Tamil month names come from a hand-written table -- confirm it's actually used
    assert body["result"]["best_selling_month"] not in [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December",
    ]
