"""Deterministic irrigation scheduling (docs/architecture/ROADMAP.md
Phase 2 — Irrigation Planning Service). Converts a crop's season-total
water requirement (mm) into a real liters-per-irrigation schedule, using
the irrigation method the Water Resource service already determined
(gravity_fed / pumped / limited) to set application efficiency and
frequency — same "reuse what an upstream service already established"
pattern as Crop Recommendation consuming Water's irrigation_method.

Returns raw computed values only (no rendered prose) — app/main.py owns
turning these into a bilingual sentence."""

from __future__ import annotations

import math
from dataclasses import dataclass

from .schemas import IrrigationMethod, IrrigationPlanRequest, IrrigationScheduleEntry

ACRE_TO_HECTARE = 0.4047
MM_PER_HA_TO_LITERS = 10_000  # 1 mm of water over 1 hectare = 10,000 liters

# (frequency_days, application_efficiency_percent)
_METHOD_PROFILE: dict[IrrigationMethod, tuple[int, int]] = {
    "gravity_fed": (10, 55),
    "pumped": (12, 65),
    "limited": (18, 90),
}


@dataclass
class IrrigationPlan:
    method: IrrigationMethod
    method_assumed: bool
    application_efficiency_percent: int
    total_water_requirement_liters: float
    number_of_irrigations: int
    frequency_days: int
    per_irrigation_volume_liters: float
    schedule: list[IrrigationScheduleEntry]


def compute_plan(req: IrrigationPlanRequest) -> IrrigationPlan:
    method: IrrigationMethod = req.irrigation_method or "limited"
    method_assumed = req.irrigation_method is None
    frequency_days, efficiency = _METHOD_PROFILE[method]

    area_ha = req.farm_area_acres * ACRE_TO_HECTARE
    raw_liters = req.crop_water_requirement_mm * MM_PER_HA_TO_LITERS * area_ha

    # Higher soil moisture offsets a modest share of the requirement — a
    # deliberately small, illustrative adjustment, not a water-balance model.
    moisture_offset = 0.0
    if req.soil_moisture_percent is not None and req.soil_moisture_percent > 40:
        moisture_offset = min((req.soil_moisture_percent - 40) / 100, 0.15)
    adjusted_liters = raw_liters * (1 - moisture_offset)

    # Application losses (evaporation/runoff/percolation) mean more must be
    # applied at the source than the crop actually consumes.
    total_liters = adjusted_liters / (efficiency / 100)

    number_of_irrigations = max(1, math.ceil(req.crop_duration_days / frequency_days))
    per_irrigation_volume = round(total_liters / number_of_irrigations, 1)

    schedule = [
        IrrigationScheduleEntry(
            irrigation_number=i + 1,
            day_offset=min((i + 1) * frequency_days, req.crop_duration_days),
            volume_liters=per_irrigation_volume,
        )
        for i in range(number_of_irrigations)
    ]

    return IrrigationPlan(
        method=method,
        method_assumed=method_assumed,
        application_efficiency_percent=efficiency,
        total_water_requirement_liters=round(total_liters, 0),
        number_of_irrigations=number_of_irrigations,
        frequency_days=frequency_days,
        per_irrigation_volume_liters=per_irrigation_volume,
        schedule=schedule,
    )
