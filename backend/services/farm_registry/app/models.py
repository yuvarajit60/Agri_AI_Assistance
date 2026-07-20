from __future__ import annotations

import uuid
from datetime import datetime
from typing import Any

from sqlalchemy import DateTime, Float, ForeignKey, JSON, String, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .db import Base

RESOLUTION_METHODS = (
    "country",
    "region",
    "state",
    "district",
    "city_village",
    "survey_number",
    "gps_coordinates",
    "google_maps_location",
    "drawn_boundary",
    "uploaded_document",
    "location_search",
)


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    phone_number: Mapped[str] = mapped_column(String(20), unique=True, index=True, nullable=False)
    name: Mapped[str | None] = mapped_column(String(120))
    state: Mapped[str | None] = mapped_column(String(80))
    district: Mapped[str | None] = mapped_column(String(80))
    preferred_language: Mapped[str] = mapped_column(String(10), default="en")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    farms: Mapped[list["Farm"]] = relationship(back_populates="owner", cascade="all, delete-orphan")


class Farm(Base):
    __tablename__ = "farms"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    owner_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    name: Mapped[str] = mapped_column(String(120), nullable=False)

    # Stored as plain GeoJSON (not a PostGIS geometry column) until the
    # boundary-drawing feature actually produces polygons to persist —
    # see docs/architecture/ROADMAP.md. Switch to a PostGIS `Geometry`
    # column (spatial indexing, ST_* queries) once that's real; a plain
    # JSON column needs no PostGIS extension in the meantime.
    boundary_geojson: Mapped[dict[str, Any] | None] = mapped_column(JSON, nullable=True)
    centroid_lat: Mapped[float] = mapped_column(Float, nullable=False)
    centroid_lon: Mapped[float] = mapped_column(Float, nullable=False)
    area_acres: Mapped[float | None] = mapped_column(Float, nullable=True)

    resolution_method: Mapped[str] = mapped_column(String(30), nullable=False)
    resolution_confidence: Mapped[float] = mapped_column(Float, nullable=False)

    # Farmer-submitted lab values (docs/architecture/MODULES.md §4) — kept
    # as JSON here rather than normalized columns since the soil service
    # already owns the canonical scoring schema; this is just durable
    # storage of what the farmer typed in.
    soil_report: Mapped[dict[str, Any] | None] = mapped_column(JSON, nullable=True)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    owner: Mapped[User] = relationship(back_populates="farms")
