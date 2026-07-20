"""Soil provider interface (docs/architecture/MODULES.md §4). Real
implementations (SoilHealthCardProvider, SoilGridsProvider) implement this
same interface; the estimate below stands in until they're wired up, and
is always surfaced to the caller with reduced confidence."""

from __future__ import annotations

import hashlib
from abc import ABC, abstractmethod
from dataclasses import dataclass

from agri_common import Location


@dataclass
class SoilProperties:
    fertility_index: float  # 0-1
    organic_carbon_percent: float
    nitrogen_kg_per_ha: float
    phosphorus_kg_per_ha: float
    potassium_kg_per_ha: float
    ph: float
    ec_ds_per_m: float
    moisture_percent: float
    salinity_index: float  # 0-1, higher = more saline
    erosion_risk: float  # 0-1, higher = more risk
    degradation_index: float  # 0-1, higher = more degraded


class SoilProvider(ABC):
    @abstractmethod
    def estimate(self, location: Location) -> SoilProperties: ...


class SatelliteEstimatedSoilProvider(SoilProvider):
    """Deterministic per-location estimate standing in for a real
    SoilGrids + spectral-index pipeline. Always used as a fallback when
    no Soil Health Card / lab report is available for the farm."""

    def estimate(self, location: Location) -> SoilProperties:
        seed = int(hashlib.sha256(f"soil:{location.latitude:.3f},{location.longitude:.3f}".encode()).hexdigest(), 16)

        def band(offset: int, lo: float, hi: float) -> float:
            return round(lo + ((seed >> offset) % 1000) / 1000 * (hi - lo), 2)

        return SoilProperties(
            fertility_index=band(4, 0.3, 0.85),
            organic_carbon_percent=band(8, 0.3, 1.2),
            nitrogen_kg_per_ha=band(12, 120, 320),
            phosphorus_kg_per_ha=band(16, 10, 55),
            potassium_kg_per_ha=band(20, 90, 280),
            ph=band(24, 5.8, 8.2),
            ec_ds_per_m=band(28, 0.2, 1.6),
            moisture_percent=band(32, 12, 35),
            salinity_index=band(36, 0.05, 0.4),
            erosion_risk=band(40, 0.1, 0.5),
            degradation_index=band(44, 0.05, 0.35),
        )
