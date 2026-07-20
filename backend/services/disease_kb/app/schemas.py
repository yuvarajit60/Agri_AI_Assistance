from __future__ import annotations

from pydantic import BaseModel, Field


class DiseaseSummary(BaseModel):
    id: str
    disease_name: str
    crops: list[str]


class GuidanceQuery(BaseModel):
    query: str = Field(..., min_length=2, description="Free text: crop + symptoms, or a disease name")
    crop: str | None = Field(None, description="Optional crop filter, e.g. 'Rice'")
    top_k: int = Field(3, ge=1, le=10)
    language: str = Field("en", pattern="^(en|ta)$", description="Response language: 'en' or 'ta'")


class DiseaseSource(BaseModel):
    name: str
    url: str


class DiseaseMatch(BaseModel):
    disease_id: str
    disease_name: str
    pathogen: str
    crops: list[str]
    symptoms: str
    favorable_conditions: str
    organic_treatment: str
    prevention: str
    sources: list[DiseaseSource]
    similarity_score: float = Field(..., ge=0, le=1)
