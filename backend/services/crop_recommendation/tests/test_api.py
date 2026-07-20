import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from app.main import app  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402

client = TestClient(app)


def test_health():
    resp = client.get("/health")
    assert resp.status_code == 200


def test_recommend_returns_ranked_crops_with_full_contract():
    resp = client.post(
        "/crops/recommend",
        json={
            "farm_area_acres": 4.2,
            "soil_ph": 6.8,
            "seasonal_rainfall_mm": 850,
            "water_availability_mm": 900,
            "current_season": "kharif",
            "top_n": 5,
        },
    )
    assert resp.status_code == 200
    body = resp.json()
    assert 0 <= body["confidence_score"] <= 1
    assert len(body["data_sources"]) >= 1
    assert body["reasoning"]
    assert body["result"]["suitability_percent"] > 0
    # Ranked descending
    scores = [body["result"]["suitability_percent"]] + [a["suitability_percent"] for a in body["alternatives"]]
    assert scores == sorted(scores, reverse=True)


def test_recommend_handles_no_viable_crop():
    resp = client.post(
        "/crops/recommend",
        json={
            "farm_area_acres": 1,
            "soil_ph": 6.5,
            "seasonal_rainfall_mm": 800,
            "water_availability_mm": 10,  # too little water for anything in the KB
            "current_season": "kharif",
        },
    )
    assert resp.status_code == 200
    body = resp.json()
    assert body["result"]["crop_name"] == "No suitable crop found"
    assert body["risk_analysis"]["level"] == "high"
