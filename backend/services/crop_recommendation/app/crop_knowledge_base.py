"""Curated crop reference data (docs/architecture/MODULES.md §6).

Source of truth for v1 is ICAR / state package-of-practices style figures,
entered by hand and versioned here — NOT invented by a model. Costs are
INR per acre, yields are quintals/acre, illustrative and meant to be
replaced by region-specific, periodically-refreshed figures.
"""

from __future__ import annotations

from dataclasses import dataclass, field


@dataclass(frozen=True)
class CropProfile:
    name: str
    term: str  # short-term | medium-term | long-term
    water_need_mm_per_season: int
    suitable_soil_ph: tuple[float, float]
    min_rainfall_mm: int
    max_rainfall_mm: int
    time_to_harvest_days: int
    investment_per_acre_inr: int
    maintenance_cost_per_acre_inr: int
    expected_yield_quintal_per_acre: float
    base_price_per_quintal_inr: int
    risk_level: str  # low | medium | high
    seasons: tuple[str, ...] = field(default_factory=tuple)  # kharif | rabi | zaid | perennial


CROP_KNOWLEDGE_BASE: list[CropProfile] = [
    CropProfile("Rice", "short-term", 1200, (5.5, 7.0), 1000, 2500, 120, 22000, 9000, 22, 2100, "medium", ("kharif",)),
    CropProfile("Cotton", "short-term", 700, (6.0, 8.0), 500, 1000, 165, 25000, 11000, 8, 7000, "medium", ("kharif",)),
    CropProfile("Maize", "short-term", 500, (5.8, 7.5), 500, 1000, 100, 15000, 6000, 25, 1800, "low", ("kharif", "rabi")),
    CropProfile("Groundnut", "short-term", 500, (6.0, 7.5), 500, 1000, 110, 18000, 7000, 12, 5500, "medium", ("kharif",)),
    CropProfile("Pulses (Tur)", "short-term", 450, (6.0, 7.5), 400, 900, 150, 12000, 5000, 8, 6500, "low", ("kharif",)),
    CropProfile("Millets (Bajra)", "short-term", 350, (6.5, 8.5), 300, 700, 90, 9000, 3500, 12, 2200, "low", ("kharif",)),
    CropProfile("Vegetables (Tomato)", "short-term", 500, (6.0, 7.0), 400, 900, 75, 30000, 15000, 90, 1200, "high", ("kharif", "rabi", "zaid")),
    CropProfile("Wheat", "short-term", 450, (6.0, 7.5), 400, 800, 130, 16000, 6500, 18, 2300, "low", ("rabi",)),
    CropProfile("Banana", "medium-term", 1800, (6.0, 7.5), 1200, 2200, 330, 90000, 35000, 300, 1200, "medium", ("perennial",)),
    CropProfile("Sugarcane", "medium-term", 2000, (6.0, 7.5), 1000, 2500, 365, 45000, 20000, 350, 320, "medium", ("perennial",)),
    CropProfile("Papaya", "medium-term", 1000, (6.0, 7.0), 1000, 2000, 300, 60000, 18000, 250, 900, "high", ("perennial",)),
    CropProfile("Mango", "long-term", 900, (5.5, 7.5), 750, 2500, 1460, 40000, 15000, 60, 3000, "medium", ("perennial",)),
    CropProfile("Coconut", "long-term", 1500, (5.2, 8.0), 1200, 3500, 1825, 35000, 12000, 80, 1800, "low", ("perennial",)),
    CropProfile("Pomegranate", "long-term", 600, (6.5, 7.5), 500, 1100, 730, 120000, 30000, 90, 6000, "high", ("perennial",)),
    CropProfile("Guava", "long-term", 800, (6.0, 7.5), 700, 1800, 730, 35000, 12000, 120, 1500, "medium", ("perennial",)),
    CropProfile("Drumstick", "long-term", 500, (6.3, 7.5), 400, 1500, 240, 20000, 8000, 100, 1000, "low", ("perennial",)),
    CropProfile("Teak", "long-term", 900, (6.5, 7.5), 900, 2000, 7300, 15000, 3000, 0, 0, "low", ("perennial",)),
]
