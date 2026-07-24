import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from app.main import app  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402

client = TestClient(app)


def _payload(**overrides):
    base = {
        "crop_name": "Rice",
        "farm_area_acres": 2.0,
        "soil_nitrogen_kg_per_ha": 40,
        "soil_phosphorus_kg_per_ha": 20,
        "soil_potassium_kg_per_ha": 15,
        "soil_ph": 6.8,
        "organic_carbon_percent": 0.6,
        "soil_confidence": 0.55,
    }
    base.update(overrides)
    return base


def test_health():
    resp = client.get("/health")
    assert resp.status_code == 200


def test_recommend_returns_full_contract():
    resp = client.post("/fertilizer/recommend", json=_payload())
    assert resp.status_code == 200
    body = resp.json()
    assert 0 <= body["confidence_score"] <= 1
    assert len(body["data_sources"]) >= 1
    assert body["reasoning"]
    result = body["result"]
    assert result["crop_reference_matched"] is True
    assert result["nutrient_gap_per_ha"]["nitrogen_kg_per_ha"] >= 0
    assert len(result["products"]) >= 1
    assert len(result["application_schedule"]) >= 1


def test_soil_already_sufficient_needs_no_fertilizer():
    resp = client.post(
        "/fertilizer/recommend",
        json=_payload(soil_nitrogen_kg_per_ha=500, soil_phosphorus_kg_per_ha=500, soil_potassium_kg_per_ha=500),
    )
    body = resp.json()
    assert body["result"]["products"] == []
    assert body["result"]["nutrient_gap_per_ha"] == {
        "nitrogen_kg_per_ha": 0.0,
        "phosphorus_p2o5_kg_per_ha": 0.0,
        "potassium_k2o_kg_per_ha": 0.0,
    }


def test_unknown_crop_uses_generic_fallback_with_reduced_confidence():
    known = client.post("/fertilizer/recommend", json=_payload()).json()
    unknown = client.post("/fertilizer/recommend", json=_payload(crop_name="Dragonfruit")).json()
    assert unknown["result"]["crop_reference_matched"] is False
    assert any("generic field-crop" in a for a in unknown["assumptions"])
    assert unknown["confidence_score"] < known["confidence_score"]


def test_acidic_soil_gets_lime_recommendation():
    resp = client.post("/fertilizer/recommend", json=_payload(soil_ph=5.2))
    body = resp.json()
    assert body["result"]["ph_correction"] is not None
    assert "lime" in body["result"]["ph_correction"].lower()


def test_low_organic_carbon_gets_organic_matter_note():
    resp = client.post("/fertilizer/recommend", json=_payload(organic_carbon_percent=0.3))
    body = resp.json()
    assert body["result"]["organic_matter_note"] is not None


def test_larger_farm_area_scales_product_quantity():
    small = client.post("/fertilizer/recommend", json=_payload(farm_area_acres=1)).json()
    large = client.post("/fertilizer/recommend", json=_payload(farm_area_acres=3)).json()
    small_total = sum(p["quantity_kg_total"] for p in small["result"]["products"])
    large_total = sum(p["quantity_kg_total"] for p in large["result"]["products"])
    assert large_total > small_total
