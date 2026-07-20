"""The Standard Output Contract every recommendation-producing endpoint in
the platform must return (docs/architecture/ARCHITECTURE.md §9).

The rule this encodes: never hand back a bare number. Every prediction
carries where it came from, how confident we are, what was assumed, and
what a farmer or admin should do about it. Services should return
`RecommendationEnvelope[SomeResultModel]` rather than inventing their own
response shape.
"""

from __future__ import annotations

from datetime import datetime
from enum import Enum
from typing import Generic, TypeVar

from pydantic import BaseModel, Field, field_validator

ResultT = TypeVar("ResultT")


class RiskLevel(str, Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"


class DataSource(BaseModel):
    name: str = Field(..., description="Human-readable source, e.g. 'OpenWeather 7-day forecast'")
    as_of: datetime = Field(..., description="Timestamp the underlying data was produced/fetched")
    live: bool = Field(..., description="False if this came from a cached/batch/estimated fallback")


class ModelUsed(BaseModel):
    name: str
    version: str


class RiskAnalysis(BaseModel):
    level: RiskLevel
    factors: list[str] = Field(default_factory=list)


class RecommendationEnvelope(BaseModel, Generic[ResultT]):
    result: ResultT
    confidence_score: float = Field(..., ge=0.0, le=1.0)
    data_sources: list[DataSource]
    assumptions: list[str] = Field(default_factory=list)
    reasoning: str
    model_used: ModelUsed | None = None
    alternatives: list[ResultT] = Field(default_factory=list)
    risk_analysis: RiskAnalysis | None = None
    action_plan: list[str] = Field(default_factory=list)

    @field_validator("data_sources")
    @classmethod
    def _must_cite_at_least_one_source(cls, v: list[DataSource]) -> list[DataSource]:
        if not v:
            raise ValueError(
                "A recommendation must cite at least one data source, even an estimated/fallback one "
                "(mark it live=False rather than omitting it)."
            )
        return v
