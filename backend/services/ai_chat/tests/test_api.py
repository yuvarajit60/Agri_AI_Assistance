import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from app.main import app  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402

client = TestClient(app)


def test_health():
    resp = client.get("/health")
    assert resp.status_code == 200


def test_ask_without_api_key_returns_honest_placeholder(monkeypatch):
    monkeypatch.setattr("app.main.ANTHROPIC_API_KEY", "")
    resp = client.post("/chat/ask", json={"question": "What crop should I grow?"})
    assert resp.status_code == 200
    body = resp.json()
    assert body["confidence_score"] == 0.0
    assert body["model_used"] is None
    assert body["result"]["reply"]
    assert len(body["data_sources"]) >= 1


def test_ask_validates_empty_question(monkeypatch):
    monkeypatch.setattr("app.main.ANTHROPIC_API_KEY", "")
    resp = client.post("/chat/ask", json={"question": ""})
    assert resp.status_code == 422


def test_ask_rejects_bad_language(monkeypatch):
    monkeypatch.setattr("app.main.ANTHROPIC_API_KEY", "")
    resp = client.post("/chat/ask", json={"question": "hi", "language": "fr"})
    assert resp.status_code == 422


def test_ask_accepts_full_context_and_history_shape(monkeypatch):
    """No API key configured here — this only checks the request schema
    accepts a full context + history payload, not the real Claude call
    (that's verified manually against the live service, same as the
    fertilizer/irrigation end-to-end checks)."""
    monkeypatch.setattr("app.main.ANTHROPIC_API_KEY", "")
    resp = client.post(
        "/chat/ask",
        json={
            "question": "Is now a good time to sell?",
            "history": [
                {"role": "user", "content": "hi"},
                {"role": "assistant", "content": "hello, how can I help?"},
            ],
            "context": {
                "farm_area_acres": 2.0,
                "top_recommended_crop": "Mango",
                "market_commodity": "Mango",
                "market_price_low_inr": 1300,
                "market_price_high_inr": 1400,
            },
            "language": "ta",
        },
    )
    assert resp.status_code == 200


def test_ask_rejects_history_over_limit(monkeypatch):
    monkeypatch.setattr("app.main.ANTHROPIC_API_KEY", "")
    resp = client.post(
        "/chat/ask",
        json={
            "question": "hi",
            "history": [{"role": "user", "content": "x"}] * 21,
        },
    )
    assert resp.status_code == 422
