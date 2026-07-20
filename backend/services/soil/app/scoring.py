"""Land Health Score v1 — interpretable weighted composite
(docs/architecture/MODULES.md §4). Replace with a learned model only once
enough labeled outcomes exist; keep this formula as the auditable baseline.
"""

from __future__ import annotations

from .providers import SoilProperties


def _npk_balance_index(soil: SoilProperties) -> float:
    # Reference "well-balanced" midpoints for Indian topsoil; distance from
    # them (normalized) penalizes both deficiency and excess.
    n_fit = 1 - min(abs(soil.nitrogen_kg_per_ha - 240) / 240, 1)
    p_fit = 1 - min(abs(soil.phosphorus_kg_per_ha - 30) / 30, 1)
    k_fit = 1 - min(abs(soil.potassium_kg_per_ha - 180) / 180, 1)
    return round((n_fit + p_fit + k_fit) / 3, 3)


def _ph_suitability_index(ph: float) -> float:
    # Most field crops are happiest between pH 6.0-7.5.
    if 6.0 <= ph <= 7.5:
        return 1.0
    distance = min(abs(ph - 6.0), abs(ph - 7.5))
    return round(max(0.0, 1 - distance / 2.5), 3)


def land_health_score(soil: SoilProperties) -> tuple[float, dict[str, float]]:
    organic_carbon_index = round(min(soil.organic_carbon_percent / 1.0, 1.0), 3)
    npk_index = _npk_balance_index(soil)
    ph_index = _ph_suitability_index(soil.ph)
    moisture_index = round(min(soil.moisture_percent / 30, 1.0), 3)

    sub_indices = {
        "fertility_index": round(soil.fertility_index, 3),
        "organic_carbon_index": organic_carbon_index,
        "npk_balance_index": npk_index,
        "ph_suitability_index": ph_index,
        "moisture_index": moisture_index,
        "erosion_risk": round(soil.erosion_risk, 3),
        "salinity_index": round(soil.salinity_index, 3),
        "degradation_index": round(soil.degradation_index, 3),
    }

    score = (
        0.20 * sub_indices["fertility_index"]
        + 0.15 * sub_indices["organic_carbon_index"]
        + 0.15 * sub_indices["npk_balance_index"]
        + 0.15 * sub_indices["ph_suitability_index"]
        + 0.10 * sub_indices["moisture_index"]
        + 0.10 * (1 - sub_indices["erosion_risk"])
        + 0.10 * (1 - sub_indices["salinity_index"])
        + 0.05 * (1 - sub_indices["degradation_index"])
    )
    return round(score * 100, 1), sub_indices
