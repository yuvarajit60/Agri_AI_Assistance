"""Nearby-mandi estimates (docs/architecture/MODULES.md §10). No real
mandi/APMC directory is wired up yet, so this deliberately does NOT
invent specific-sounding market names (e.g. a fake "Nashik APMC") --
doing that would look like real, checkable data when it isn't, exactly
the kind of false specificity this project avoids elsewhere (see
water/app/providers.py's same reasoning for why it never invents a named
water body). Instead each entry is a generic, role-based label plus a
deterministic distance and price variance, seeded per location+commodity
so results are stable per farm/crop but not identical across mandis.

A real implementation would query a mandi/APMC directory (e.g. from
data.gov.in) by nearest distance to (lat, lon)."""

from __future__ import annotations

import hashlib

from .commodity_catalog import CommodityProfile
from .schemas import MandiInfo

_MANDI_ROLE_LABELS_EN = ["Nearest APMC market", "Regional wholesale market", "Secondary market yard"]
_MANDI_ROLE_LABELS_TA = ["அருகிலுள்ள APMC சந்தை", "பிராந்திய மொத்த விற்பனை சந்தை", "இரண்டாம் நிலை சந்தை முற்றம்"]


def nearby_mandis(
    commodity: CommodityProfile, lat: float, lon: float, current_price_inr: float, language: str
) -> list[MandiInfo]:
    seed = int(hashlib.sha256(f"market-mandi:{commodity.name.lower()}:{lat:.3f},{lon:.3f}".encode()).hexdigest(), 16)
    labels = _MANDI_ROLE_LABELS_TA if language == "ta" else _MANDI_ROLE_LABELS_EN

    mandis: list[MandiInfo] = []
    distance = 3.0 + ((seed >> 4) % 1000) / 1000 * 4.0  # first mandi 3-7km out
    for i, label in enumerate(labels):
        offset = 8 * (i + 1)
        price_variance = -0.06 + ((seed >> offset) % 1000) / 1000 * 0.12  # +/-6% mandi-to-mandi spread
        mandis.append(
            MandiInfo(
                name=label,
                distance_km=round(distance, 1),
                latest_price_inr_per_quintal=round(current_price_inr * (1 + price_variance), 2),
            )
        )
        distance += 5.0 + ((seed >> (offset + 3)) % 1000) / 1000 * 8.0  # each further mandi 5-13km further out
    return mandis
