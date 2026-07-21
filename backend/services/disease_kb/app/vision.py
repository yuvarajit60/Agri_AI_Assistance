"""Computer-vision disease diagnosis (docs/architecture/MODULES.md §9,
`/disease/diagnose-photo`). RAG-grounded the same way the text search in
`vector_store.py` is: Claude's vision call is constrained via
`output_config.format` to pick a `disease_id` from THIS backend's curated
12-entry knowledge base (or "none") — it never invents a disease, pathogen,
or treatment. All display text for a match still comes from
`knowledge_base.py`'s localized entry, never from Claude's own words;
Claude's only job here is the visual classification step retrieval can't
do on its own.
"""

from __future__ import annotations

import base64
import json
import logging
from typing import Any

import anthropic

from .knowledge_base import load_knowledge_base

logger = logging.getLogger(__name__)

_MODEL = "claude-opus-4-8"


def _catalog_text() -> str:
    lines = []
    for entry in load_knowledge_base():
        crops = ", ".join(entry["crops"])
        lines.append(
            f"- id: {entry['id']} | name: {entry['disease_name']} | crops: {crops} | "
            f"symptoms: {entry['symptoms'][:220]}"
        )
    return "\n".join(lines)


def diagnose(
    *,
    image_bytes: bytes,
    media_type: str,
    crop_hint: str,
    notes: str,
    api_key: str,
) -> dict[str, Any] | None:
    """Returns {"matched_disease_id", "confidence", "observed_symptoms",
    "reasoning"}, or None if the call itself failed (network, auth,
    refusal, unparseable output, rate limit) — the caller falls back to
    the honest "not analyzed" response rather than fabricating a result."""
    valid_ids = [e["id"] for e in load_knowledge_base()]
    schema = {
        "type": "object",
        "properties": {
            "matched_disease_id": {
                "type": "string",
                "enum": [*valid_ids, "none"],
                "description": (
                    "The single best-matching disease id from the catalog, or 'none' if the "
                    "photo does not clearly match any catalog entry — including if the photo "
                    "is not a diseased plant, is too blurry/unclear, or shows symptoms of a "
                    "disease outside this catalog."
                ),
            },
            "confidence": {
                "type": "number",
                "description": "0.0-1.0 confidence in the match; 0.0 if matched_disease_id is 'none'.",
            },
            "observed_symptoms": {
                "type": "string",
                "description": "What is actually visible in the photo, in plain language, independent of the catalog.",
            },
            "reasoning": {
                "type": "string",
                "description": "One or two sentences on why this catalog entry (or none) fits.",
            },
        },
        "required": ["matched_disease_id", "confidence", "observed_symptoms", "reasoning"],
        "additionalProperties": False,
    }

    system_prompt = (
        "You are assisting Indian farmers with crop disease identification from a photo. "
        "You must ONLY select from the fixed disease catalog below — never diagnose a "
        "disease, pathogen, or treatment outside it, even if you recognize something else "
        "in the photo. If the photo does not clearly match a catalog entry, return "
        "matched_disease_id 'none' rather than guessing the closest one. A wrong specific "
        "match is worse than an honest 'none' for a farmer deciding how to treat their crop."
        "\n\nCATALOG:\n" + _catalog_text()
    )
    user_text = (
        f"Crop (farmer-reported, may be inaccurate or blank): {crop_hint or 'not specified'}\n"
        f"Farmer's notes: {notes or 'none'}\n\n"
        "Identify which catalog entry (if any) best matches the visible symptoms in this photo."
    )

    client = anthropic.Anthropic(api_key=api_key)
    try:
        response = client.messages.create(
            model=_MODEL,
            max_tokens=1024,
            system=system_prompt,
            messages=[
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "image",
                            "source": {
                                "type": "base64",
                                "media_type": media_type,
                                "data": base64.standard_b64encode(image_bytes).decode("utf-8"),
                            },
                        },
                        {"type": "text", "text": user_text},
                    ],
                }
            ],
            output_config={"format": {"type": "json_schema", "schema": schema}},
        )
    except anthropic.APIError as exc:
        logger.warning("Vision diagnosis call failed: %s", exc)
        return None

    if response.stop_reason == "refusal":
        logger.warning("Vision diagnosis declined by model safety classifier")
        return None

    text_block = next((b for b in response.content if b.type == "text"), None)
    if text_block is None:
        return None
    try:
        parsed = json.loads(text_block.text)
    except json.JSONDecodeError:
        logger.warning("Vision diagnosis returned unparseable JSON: %r", text_block.text)
        return None

    if parsed.get("matched_disease_id") not in {*valid_ids, "none"}:
        return None
    return parsed
