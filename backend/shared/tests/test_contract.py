from datetime import datetime, timezone

import pytest
from agri_common import DataSource, RecommendationEnvelope
from pydantic import ValidationError


def test_envelope_requires_at_least_one_data_source():
    with pytest.raises(ValidationError):
        RecommendationEnvelope[str](
            result="x",
            confidence_score=0.5,
            data_sources=[],
            reasoning="test",
        )


def test_envelope_rejects_out_of_range_confidence():
    source = DataSource(name="test", as_of=datetime.now(timezone.utc), live=True)
    with pytest.raises(ValidationError):
        RecommendationEnvelope[str](
            result="x",
            confidence_score=1.4,
            data_sources=[source],
            reasoning="test",
        )


def test_envelope_accepts_a_valid_payload():
    source = DataSource(name="test", as_of=datetime.now(timezone.utc), live=True)
    envelope = RecommendationEnvelope[str](
        result="x",
        confidence_score=0.8,
        data_sources=[source],
        reasoning="test",
    )
    assert envelope.confidence_score == 0.8
    assert envelope.assumptions == []
    assert envelope.action_plan == []
