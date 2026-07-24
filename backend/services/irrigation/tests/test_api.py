import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from app.main import app  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402

client = TestClient(app)


def _payload(**overrides):
    base = {
        "crop_name": "Rice",
        "crop_water_requirement_mm": 1200,
        "crop_duration_days": 120,
        "farm_area_acres": 2.0,
        "irrigation_method": "pumped",
        "soil_moisture_percent": 30,
    }
    base.update(overrides)
    return base


def test_health():
    resp = client.get("/health")
    assert resp.status_code == 200


def test_plan_returns_full_contract():
    resp = client.post("/irrigation/plan", json=_payload())
    assert resp.status_code == 200
    body = resp.json()
    assert 0 <= body["confidence_score"] <= 1
    assert len(body["data_sources"]) >= 1
    assert body["reasoning"]
    result = body["result"]
    assert result["method"] == "pumped"
    assert result["method_assumed"] is False
    assert result["total_water_requirement_liters"] > 0
    assert result["number_of_irrigations"] >= 1
    assert len(result["schedule"]) == result["number_of_irrigations"]


def test_missing_irrigation_method_assumes_limited_with_lower_confidence():
    with_method = client.post("/irrigation/plan", json=_payload()).json()
    without_method = client.post("/irrigation/plan", json=_payload(irrigation_method=None)).json()
    assert without_method["result"]["method"] == "limited"
    assert without_method["result"]["method_assumed"] is True
    assert without_method["confidence_score"] < with_method["confidence_score"]
    assert any("assumed" in a.lower() for a in without_method["assumptions"])


def test_gravity_fed_has_lowest_application_efficiency():
    gravity = client.post("/irrigation/plan", json=_payload(irrigation_method="gravity_fed")).json()
    pumped = client.post("/irrigation/plan", json=_payload(irrigation_method="pumped")).json()
    limited = client.post("/irrigation/plan", json=_payload(irrigation_method="limited")).json()
    assert (
        gravity["result"]["application_efficiency_percent"]
        < pumped["result"]["application_efficiency_percent"]
        < limited["result"]["application_efficiency_percent"]
    )


def test_larger_area_requires_more_total_water():
    small = client.post("/irrigation/plan", json=_payload(farm_area_acres=1)).json()
    large = client.post("/irrigation/plan", json=_payload(farm_area_acres=5)).json()
    assert large["result"]["total_water_requirement_liters"] > small["result"]["total_water_requirement_liters"]


def test_plan_is_deterministic():
    resp1 = client.post("/irrigation/plan", json=_payload())
    resp2 = client.post("/irrigation/plan", json=_payload())
    assert resp1.json()["result"] == resp2.json()["result"]
