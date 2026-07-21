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


def test_gravity_fed_irrigation_rescues_otherwise_unviable_water_availability():
    """Same rainfall-starved inputs as the no-viable-crop case above, but
    with a gravity-fed water source nearby — should now find a candidate,
    proving irrigation access actually widens the hard filter, not just
    the score."""
    base_payload = {
        "farm_area_acres": 1,
        "soil_ph": 6.5,
        "seasonal_rainfall_mm": 800,
        "water_availability_mm": 10,
        "current_season": "kharif",
    }
    without_irrigation = client.post("/crops/recommend", json=base_payload).json()
    assert without_irrigation["result"]["crop_name"] == "No suitable crop found"

    with_irrigation = client.post(
        "/crops/recommend", json={**base_payload, "irrigation_method": "gravity_fed"}
    ).json()
    assert with_irrigation["result"]["crop_name"] != "No suitable crop found"
    assert with_irrigation["result"]["suitability_percent"] > 0
    assert any("irrigation" in a.lower() for a in with_irrigation["assumptions"])


def test_pumped_irrigation_improves_suitability_over_rainfall_alone():
    payload = {
        "farm_area_acres": 1,
        "soil_ph": 6.8,
        "seasonal_rainfall_mm": 850,
        "water_availability_mm": 900,
        "current_season": "kharif",
    }
    without = client.post("/crops/recommend", json=payload).json()
    with_pump = client.post("/crops/recommend", json={**payload, "irrigation_method": "pumped"}).json()
    assert with_pump["result"]["suitability_percent"] >= without["result"]["suitability_percent"]
