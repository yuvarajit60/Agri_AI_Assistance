"""Water resource provider interface (docs/architecture/MODULES.md §3). A
real implementation would run a PostGIS spatial query against an ingested
water-bodies layer (JRC Global Surface Water + India-WRIS + OSM waterways)
with an expanding search radius, plus a CGWB block-level groundwater
lookup. Until that ingestion pipeline exists, this deterministic
per-location estimate stands in — same pattern as soil's
SatelliteEstimatedSoilProvider — and is always surfaced with reduced
confidence."""

from __future__ import annotations

import hashlib
from abc import ABC, abstractmethod
from dataclasses import dataclass, field

from agri_common import Location

from .schemas import (
    GroundwaterAssessment,
    GroundwaterCategory,
    IrrigationFeasibility,
    IrrigationMethod,
    SeasonalAvailability,
    WaterFeature,
    WaterFeatureType,
)

_FEATURE_TYPES = list(WaterFeatureType)
_SEASONAL_OPTIONS = list(SeasonalAvailability)
_AVAILABILITY_LABELS = ["low", "moderate", "high"]
_GROUNDWATER_CATEGORIES = list(GroundwaterCategory)


@dataclass
class WaterResourceData:
    features: list[WaterFeature] = field(default_factory=list)
    groundwater: GroundwaterAssessment | None = None
    irrigation_feasibility: IrrigationFeasibility | None = None


class WaterResourceProvider(ABC):
    @abstractmethod
    def assess(self, location: Location) -> WaterResourceData: ...


class MockWaterResourceProvider(WaterResourceProvider):
    """Deterministic per-location estimate — same coordinates always
    produce the same result, different coordinates produce plausible but
    different results, so this behaves consistently in demos and tests
    without pretending to be a real spatial dataset."""

    def assess(self, location: Location) -> WaterResourceData:
        seed = int(
            hashlib.sha256(f"water:{location.latitude:.3f},{location.longitude:.3f}".encode()).hexdigest(), 16
        )

        def band(offset: int, lo: float, hi: float) -> float:
            return round(lo + ((seed >> offset) % 1000) / 1000 * (hi - lo), 2)

        def pick(offset: int, options: list) -> object:
            return options[(seed >> offset) % len(options)]

        feature_count = 2 + (seed % 3)  # 2-4 nearby features, expanding-radius style
        features: list[WaterFeature] = []
        distance = band(0, 0.8, 2.5)  # first feature within the initial 1km-ish search ring
        for i in range(feature_count):
            offset = 6 * (i + 1)
            features.append(
                WaterFeature(
                    type=pick(offset, _FEATURE_TYPES),
                    name=None,
                    distance_km=round(distance, 2),
                    seasonal_availability=pick(offset + 3, _SEASONAL_OPTIONS),
                    estimated_water_availability=pick(offset + 5, _AVAILABILITY_LABELS),
                )
            )
            distance += band(offset + 2, 1.0, 3.5)  # each subsequent feature further out

        category = pick(40, _GROUNDWATER_CATEGORIES)
        depth = band(44, 4.0, 45.0)
        groundwater = GroundwaterAssessment(
            category=category,
            depth_to_water_table_m=depth,
            borewell_feasibility=_borewell_feasibility(category, depth),
        )

        nearest = min((f.distance_km for f in features), default=None)
        elevation_relative = band(48, -18.0, 18.0)
        irrigation_feasibility = _irrigation_feasibility(nearest, elevation_relative)

        return WaterResourceData(features=features, groundwater=groundwater, irrigation_feasibility=irrigation_feasibility)


def _borewell_feasibility(category: GroundwaterCategory, depth_m: float) -> str:
    if category == GroundwaterCategory.OVER_EXPLOITED:
        return "Poor — this block is officially over-exploited; a new borewell may not be sanctioned. Consult CGWB before drilling."
    if category == GroundwaterCategory.CRITICAL:
        return "Weak — groundwater is under heavy stress in this block. A borewell may run dry in summer; consider rainwater recharge alongside it."
    if depth_m > 30:
        return "Moderate — groundwater is available but at significant depth, raising drilling and pumping cost."
    return "Good — this block's groundwater status and water-table depth both support a borewell."


def _irrigation_feasibility(nearest_source_km: float | None, elevation_relative_m: float) -> IrrigationFeasibility:
    if nearest_source_km is None:
        return IrrigationFeasibility(
            method=IrrigationMethod.LIMITED,
            nearest_source_distance_km=None,
            farm_elevation_relative_m=elevation_relative_m,
            notes="No surface water feature found nearby — irrigation would rely on groundwater/borewell only.",
        )
    if nearest_source_km <= 3.0 and elevation_relative_m < 0:
        return IrrigationFeasibility(
            method=IrrigationMethod.GRAVITY_FED,
            nearest_source_distance_km=nearest_source_km,
            farm_elevation_relative_m=elevation_relative_m,
            notes="The farm sits lower than the nearest water source and it's close by — gravity-fed "
            "channel irrigation is likely feasible, which is far cheaper to run than pumping.",
        )
    if nearest_source_km <= 8.0:
        return IrrigationFeasibility(
            method=IrrigationMethod.PUMPED,
            nearest_source_distance_km=nearest_source_km,
            farm_elevation_relative_m=elevation_relative_m,
            notes="A water source is within reach but pumping (electric or diesel) would be needed — "
            "either the farm sits higher than the source or the distance is too far for gravity flow.",
        )
    return IrrigationFeasibility(
        method=IrrigationMethod.LIMITED,
        nearest_source_distance_km=nearest_source_km,
        farm_elevation_relative_m=elevation_relative_m,
        notes="The nearest surface water source is far enough that surface irrigation would be costly — "
        "groundwater/borewell is likely the more practical option here.",
    )
