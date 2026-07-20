"""Elevation/terrain provider interface. Real implementation will sample
Google Earth Engine's DEM (docs/architecture/ARCHITECTURE.md §6); the mock
below is a deterministic per-location stand-in."""

from __future__ import annotations

import hashlib
from abc import ABC, abstractmethod
from dataclasses import dataclass

from agri_common import Location


@dataclass
class TerrainSample:
    elevation_m: float
    slope_percent: float


class ElevationProvider(ABC):
    @abstractmethod
    def sample(self, location: Location) -> TerrainSample: ...


class MockElevationProvider(ElevationProvider):
    def sample(self, location: Location) -> TerrainSample:
        seed = int(hashlib.sha256(f"elev:{location.latitude:.3f},{location.longitude:.3f}".encode()).hexdigest(), 16)
        elevation = 50 + (seed % 900)  # 50-950m, deterministic per location
        slope = round(((seed >> 10) % 250) / 10, 1)  # 0-25%
        return TerrainSample(elevation_m=float(elevation), slope_percent=slope)


def classify_slope(slope_percent: float) -> str:
    if slope_percent < 3:
        return "flat"
    if slope_percent < 8:
        return "gentle"
    if slope_percent < 15:
        return "moderate"
    return "steep"


def classify_drainage(slope_percent: float) -> str:
    # Coarse heuristic until this is cross-referenced with the Soil
    # service's texture data (docs/architecture/MODULES.md §2).
    if slope_percent < 2:
        return "poor"
    if slope_percent < 10:
        return "moderate"
    return "good"


def describe_terrain(slope_percent: float, elevation_m: float) -> str:
    slope_class = classify_slope(slope_percent)
    if elevation_m > 600:
        return f"Upland, {slope_class} terrain"
    if elevation_m > 250:
        return f"Mid-elevation, {slope_class} terrain"
    return f"Lowland plain, {slope_class} terrain"
