"""Deterministic fertilizer gap calculation (docs/architecture/ROADMAP.md
Phase 2 — Fertilizer Recommendation Service). Standard agronomic gap
method: crop requirement minus soil-supplied nutrient = shortfall, then
convert the shortfall to real fertilizer product quantities using their
published nutrient content. No estimation/mock-provider step is needed
here (unlike soil/water) — this is arithmetic over already-known inputs,
not a stand-in for a missing dataset.

Returns raw computed values only (no rendered prose) — app/main.py owns
turning these into a bilingual sentence, same computation/presentation
split as app/main.py already does elsewhere in the platform."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Literal

from .crop_nutrient_requirements import NutrientRequirement, lookup
from .schemas import ApplicationStage, FertilizerRecommendationRequest, NutrientGap, ProductQuantity

ACRE_TO_HECTARE = 0.4047

# Standard published nutrient content of common Indian fertilizer products.
UREA_N_FRACTION = 0.46
DAP_N_FRACTION = 0.18
DAP_P2O5_FRACTION = 0.46
MOP_K2O_FRACTION = 0.60

PhStatus = Literal["acidic", "alkaline", "neutral"]


@dataclass
class FertilizerPlan:
    gap: NutrientGap
    products: list[ProductQuantity]
    ph_status: PhStatus
    ph_correction_dose_kg_per_acre: float | None
    organic_matter_low: bool
    application_schedule: list[ApplicationStage]
    requirement: NutrientRequirement
    crop_found: bool


def _round(value: float) -> float:
    return round(max(value, 0.0), 1)


def compute_plan(req: FertilizerRecommendationRequest) -> FertilizerPlan:
    requirement, found = lookup(req.crop_name)
    area_ha = req.farm_area_acres * ACRE_TO_HECTARE

    gap_n_per_ha = max(0.0, requirement.nitrogen_kg_per_ha - req.soil_nitrogen_kg_per_ha)
    gap_p_per_ha = max(0.0, requirement.phosphorus_p2o5_kg_per_ha - req.soil_phosphorus_kg_per_ha)
    gap_k_per_ha = max(0.0, requirement.potassium_k2o_kg_per_ha - req.soil_potassium_kg_per_ha)

    gap_n_farm = gap_n_per_ha * area_ha
    gap_p_farm = gap_p_per_ha * area_ha
    gap_k_farm = gap_k_per_ha * area_ha

    products: list[ProductQuantity] = []

    dap_kg = 0.0
    if gap_p_farm > 0:
        dap_kg = gap_p_farm / DAP_P2O5_FRACTION
        products.append(
            ProductQuantity(product="DAP (18-46-0)", nutrient_supplied="Phosphorus (P2O5)", quantity_kg_total=_round(dap_kg))
        )

    n_supplied_by_dap = dap_kg * DAP_N_FRACTION
    remaining_n_farm = max(0.0, gap_n_farm - n_supplied_by_dap)
    if remaining_n_farm > 0:
        urea_kg = remaining_n_farm / UREA_N_FRACTION
        products.append(ProductQuantity(product="Urea (46-0-0)", nutrient_supplied="Nitrogen (N)", quantity_kg_total=_round(urea_kg)))

    if gap_k_farm > 0:
        mop_kg = gap_k_farm / MOP_K2O_FRACTION
        products.append(
            ProductQuantity(product="MOP (0-0-60)", nutrient_supplied="Potassium (K2O)", quantity_kg_total=_round(mop_kg))
        )

    ph_status: PhStatus = "neutral"
    ph_dose: float | None = None
    if req.soil_ph < 6.0:
        ph_status = "acidic"
        ph_dose = round((6.0 - req.soil_ph) * 200, 0)
    elif req.soil_ph > 8.0:
        ph_status = "alkaline"
        ph_dose = round((req.soil_ph - 8.0) * 250, 0)

    organic_matter_low = req.organic_carbon_percent < 0.5

    schedule: list[ApplicationStage] = []
    basal_products = [p.product for p in products if p.product.startswith(("DAP", "MOP"))]
    if any(p.product.startswith("Urea") for p in products):
        basal_products.append("Urea (46-0-0) — half dose")
    if basal_products:
        schedule.append(ApplicationStage(stage="basal", timing="at_sowing", products=basal_products))
    if any(p.product.startswith("Urea") for p in products):
        schedule.append(
            ApplicationStage(stage="top_dressing_1", timing="vegetative_stage", products=["Urea (46-0-0) — remaining half"])
        )
    if not schedule:
        schedule.append(ApplicationStage(stage="none_needed", timing="none", products=[]))

    return FertilizerPlan(
        gap=NutrientGap(
            nitrogen_kg_per_ha=_round(gap_n_per_ha),
            phosphorus_p2o5_kg_per_ha=_round(gap_p_per_ha),
            potassium_k2o_kg_per_ha=_round(gap_k_per_ha),
        ),
        products=products,
        ph_status=ph_status,
        ph_correction_dose_kg_per_acre=ph_dose,
        organic_matter_low=organic_matter_low,
        application_schedule=schedule,
        requirement=requirement,
        crop_found=found,
    )
