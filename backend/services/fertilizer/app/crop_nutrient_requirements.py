"""Curated per-crop nutrient requirement reference data (extends the
pattern in services/crop_recommendation/app/crop_knowledge_base.py to the
same 17-crop list).

Source of truth for v1 is ICAR / state package-of-practices style N-P2O5-K2O
figures, entered by hand and versioned here — NOT invented by a model.
Convention: N, P and K are all expressed on the same basis Indian package-
of-practices figures and Indian fertilizer labels already use — P as P2O5
and K as K2O, not elemental P/K (a Soil Health Card's "available P/K" is
conventionally reported the same way). If a soil source instead reports
elemental P/K, the gap calculation below will be off — see the assumption
surfaced in the API response.

Illustrative, general-purpose figures meant to be replaced by region-
specific, periodically-refreshed recommendations (same caveat as the crop
knowledge base this extends)."""

from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class NutrientRequirement:
    crop_name: str
    nitrogen_kg_per_ha: float
    phosphorus_p2o5_kg_per_ha: float
    potassium_k2o_kg_per_ha: float


# Keyed by the same crop names used in crop_recommendation's CROP_KNOWLEDGE_BASE.
CROP_NUTRIENT_REQUIREMENTS: list[NutrientRequirement] = [
    NutrientRequirement("Rice", 120, 60, 40),
    NutrientRequirement("Cotton", 100, 50, 50),
    NutrientRequirement("Maize", 120, 60, 40),
    NutrientRequirement("Groundnut", 20, 40, 40),  # legume — low N need, fixes some of its own
    NutrientRequirement("Pulses (Tur)", 20, 50, 20),  # legume — low N need
    NutrientRequirement("Millets (Bajra)", 60, 30, 20),
    NutrientRequirement("Vegetables (Tomato)", 120, 60, 60),
    NutrientRequirement("Wheat", 120, 60, 40),
    NutrientRequirement("Banana", 200, 60, 200),  # heavy potassium feeder
    NutrientRequirement("Sugarcane", 250, 100, 100),
    NutrientRequirement("Papaya", 200, 200, 200),
    NutrientRequirement("Mango", 100, 50, 100),  # mature-orchard, hectare-equivalent basis
    NutrientRequirement("Coconut", 50, 32, 120),  # hectare-equivalent basis (usually quoted per-palm)
    NutrientRequirement("Pomegranate", 125, 60, 125),
    NutrientRequirement("Guava", 100, 50, 100),
    NutrientRequirement("Drumstick", 40, 40, 40),
    NutrientRequirement("Teak", 0, 0, 0),  # forestry — no standard annual fertilizer program
]

_BY_NAME = {r.crop_name.lower(): r for r in CROP_NUTRIENT_REQUIREMENTS}

# Used when a crop name isn't in the reference list — a moderate, generic
# field-crop requirement rather than refusing to answer, but flagged with
# reduced confidence and an explicit assumption (never silently guessed).
GENERIC_FALLBACK = NutrientRequirement("Generic field crop", 100, 50, 50)


def lookup(crop_name: str) -> tuple[NutrientRequirement, bool]:
    """Returns (requirement, found) — found=False means the generic
    fallback was used."""
    match = _BY_NAME.get(crop_name.strip().lower())
    if match is not None:
        return match, True
    return GENERIC_FALLBACK, False
