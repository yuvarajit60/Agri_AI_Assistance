"""Loads the curated organic-treatment knowledge base
(knowledge_base/organic_diseases.json). This is a starter set — ~12
diseases covering the crops already in the crop knowledge base
(services/crop_recommendation), sourced from TNAU/ICAR/ICRISAT and peer-
reviewed research, each with citations. Not exhaustive; meant to be
expanded over time, the same way the crop knowledge base is.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

_KB_PATH = Path(__file__).parent / "knowledge_base" / "organic_diseases.json"


def load_knowledge_base() -> list[dict[str, Any]]:
    with open(_KB_PATH, encoding="utf-8") as f:
        return json.load(f)


_TRANSLATABLE_FIELDS = ["disease_name", "symptoms", "favorable_conditions", "organic_treatment", "prevention"]


def localize(entry: dict[str, Any], language: str) -> dict[str, Any]:
    """Returns a copy of entry with the display fields swapped to the
    requested language. pathogen/crops/sources/id are never translated —
    pathogen names are scientific Latin binomials, crops is used for
    filter-matching, sources are citations. Falls back to English per
    field if a translation is missing, so a partially-translated future
    entry degrades gracefully instead of showing a blank."""
    if language == "en":
        return entry
    localized = dict(entry)
    for field in _TRANSLATABLE_FIELDS:
        translated = entry.get(f"{field}_ta")
        if translated:
            localized[field] = translated
    return localized


def embedding_text(entry: dict[str, Any]) -> str:
    """The text actually embedded for retrieval — combines everything a
    farmer might search on (disease name, crop, symptoms, conditions,
    treatment) so both symptom-based and treatment-based queries match."""
    return (
        f"{entry['disease_name']} ({entry['pathogen']}). "
        f"Crops: {', '.join(entry['crops'])}. "
        f"Symptoms: {entry['symptoms']} "
        f"Favorable conditions: {entry['favorable_conditions']} "
        f"Organic treatment: {entry['organic_treatment']} "
        f"Prevention: {entry['prevention']}"
    )
