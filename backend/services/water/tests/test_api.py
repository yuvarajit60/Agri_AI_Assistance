import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from app.main import app  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402

client = TestClient(app)


def test_health():
    resp = client.get("/health")
    assert resp.status_code == 200


def test_analyze_returns_full_contract():
    resp = client.get("/water/analyze", params={"lat": 11.0168, "lon": 76.9558})
    assert resp.status_code == 200
    body = resp.json()
    assert 0 <= body["confidence_score"] <= 1
    assert len(body["data_sources"]) >= 1
    assert body["reasoning"]
    result = body["result"]
    assert 2 <= len(result["features"]) <= 4
    for feature in result["features"]:
        assert feature["distance_km"] >= 0
    assert result["groundwater"]["category"] in ("safe", "semi_critical", "critical", "over_exploited")
    assert result["irrigation_feasibility"]["method"] in ("gravity_fed", "pumped", "limited")


def test_analyze_is_deterministic_per_location():
    resp1 = client.get("/water/analyze", params={"lat": 12.9, "lon": 77.6})
    resp2 = client.get("/water/analyze", params={"lat": 12.9, "lon": 77.6})
    assert resp1.json()["result"] == resp2.json()["result"]
