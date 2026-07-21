"""Reference commodity data for market price forecasting. Deliberately a
standalone copy (not a cross-service import of crop_recommendation's
CROP_KNOWLEDGE_BASE) — each backend service here is built and deployed
independently (see any service's Dockerfile), so sharing Python modules
across them would mean coupling their deploy lifecycles. The reference
prices are the same ICAR/state package-of-practices-style figures used
in crop_recommendation/app/crop_knowledge_base.py; keep the two in sync
by hand if either changes.

`typical_harvest_month` and `seasonality_amplitude` are illustrative,
hand-set approximations of when regional mandi supply peaks (and price
typically dips) for each commodity — not sourced from a specific mandi's
historical record. They only shape the *synthetic* history in
history_provider.py, which is itself clearly labeled `live=False`
throughout this service until a real Agmarknet/data.gov.in data source
is wired in (see history_provider.py's module docstring).
"""

from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class CommodityProfile:
    name: str
    base_price_per_quintal_inr: int
    typical_harvest_month: int  # 1-12, the month regional supply (and price dip) typically peaks
    seasonality_amplitude: float  # fraction of base price the seasonal cycle swings +/-


COMMODITY_CATALOG: list[CommodityProfile] = [
    CommodityProfile("Rice", 2100, 11, 0.10),
    CommodityProfile("Cotton", 7000, 11, 0.14),
    CommodityProfile("Maize", 1800, 10, 0.12),
    CommodityProfile("Groundnut", 5500, 10, 0.13),
    CommodityProfile("Pulses (Tur)", 6500, 12, 0.16),
    CommodityProfile("Millets (Bajra)", 2200, 10, 0.10),
    CommodityProfile("Vegetables (Tomato)", 1200, 6, 0.30),  # perishable, highest swings
    CommodityProfile("Wheat", 2300, 4, 0.09),
    CommodityProfile("Banana", 1200, 8, 0.08),
    CommodityProfile("Sugarcane", 320, 2, 0.06),  # mostly price-controlled (FRP), low swing
    CommodityProfile("Papaya", 900, 9, 0.12),
    CommodityProfile("Mango", 3000, 5, 0.25),
    CommodityProfile("Coconut", 1800, 1, 0.08),
    CommodityProfile("Pomegranate", 6000, 1, 0.18),
    CommodityProfile("Guava", 1500, 9, 0.15),
    CommodityProfile("Drumstick", 1000, 3, 0.20),
]

_BY_NAME = {c.name.lower(): c for c in COMMODITY_CATALOG}


def all_commodity_names() -> list[str]:
    return [c.name for c in COMMODITY_CATALOG]


def find_commodity(name: str) -> CommodityProfile | None:
    """Case-insensitive exact match first, then a substring match so a
    farmer-facing 'Tomato' or a crop_recommendation output like
    'Vegetables (Tomato)' both resolve to the same catalog entry."""
    key = name.strip().lower()
    if key in _BY_NAME:
        return _BY_NAME[key]
    for commodity in COMMODITY_CATALOG:
        if key in commodity.name.lower() or commodity.name.lower() in key:
            return commodity
    return None
