"""Farm-advisor chat (docs/architecture/ROADMAP.md next-step — "extend the
now-working Claude integration into AI Chat"). Grounds each reply in the
farm context the mobile app already has loaded client-side (crop/weather/
water/market — composed once by the gateway's /dashboard, not re-fetched
here) plus general, safe agronomy knowledge.

Single call, not a multi-step agent loop — the same "simpler, cheaper, more
predictable than a multi-turn agent loop" choice this project already
documents for the Tech Mahindra LogicApp Monitor Agent this pattern is
modeled on. Uses the streaming client + get_final_message() purely for
timeout safety on a call using adaptive thinking — the mobile app still
gets a single plain JSON response, no SSE plumbed through."""

from __future__ import annotations

import logging

import anthropic

from .schemas import ChatRequest

logger = logging.getLogger(__name__)

_MODEL = "claude-opus-4-8"
_MAX_TOKENS = 2048

_LANGUAGE_NAME = {"en": "English", "ta": "Tamil"}

_SYSTEM_TEMPLATE = """You are a friendly, practical farm advisor for Indian farmers using the \
Uzhavanin Nanban (Farmer's Friend) app. Answer in {language_name}, in plain language a farmer \
would understand -- avoid jargon, keep it to 2-4 sentences unless the question genuinely needs more.

Only use the farm context below and general, safe agronomy knowledge. Never invent a specific \
number (an exact price, temperature, or yield figure) beyond what's given in the context -- if \
you don't have what's needed to answer precisely, say so honestly and give general guidance instead.

If the farmer describes possible disease or pest symptoms in text, give brief general guidance \
only, and point them to the app's photo diagnosis feature for a properly grounded identification \
-- never name a specific disease from a text description alone.

FARM CONTEXT:
{context_text}"""


def _context_text(req: ChatRequest) -> str:
    c = req.context
    lines: list[str] = []
    if c.farm_area_acres is not None:
        lines.append(f"- Farm size: {c.farm_area_acres} acres")
    if c.land_health_score is not None:
        lines.append(f"- Land health score: {c.land_health_score}/100")
    if c.top_recommended_crop is not None:
        suit = f" ({c.crop_suitability_percent}% suitability)" if c.crop_suitability_percent is not None else ""
        lines.append(f"- Top recommended crop: {c.top_recommended_crop}{suit}")
    if c.avg_temp_c is not None:
        lines.append(f"- Current avg temperature: {c.avg_temp_c} C")
    if c.total_rainfall_mm_7d is not None:
        lines.append(f"- Rainfall (last 7 days): {c.total_rainfall_mm_7d} mm")
    if c.irrigation_method is not None:
        lines.append(f"- Irrigation access: {c.irrigation_method}")
    if c.groundwater_category is not None:
        lines.append(f"- Groundwater status: {c.groundwater_category}")
    if c.market_commodity is not None and c.market_price_low_inr is not None and c.market_price_high_inr is not None:
        lines.append(
            f"- Market forecast for {c.market_commodity}: Rs.{c.market_price_low_inr}-{c.market_price_high_inr}/quintal"
        )
    return "\n".join(lines) if lines else "(no farm context available for this farmer yet)"


def ask(*, req: ChatRequest, api_key: str) -> str | None:
    """Returns the reply text, or None if the call itself failed (network,
    auth, refusal, empty response) -- the caller falls back to an honest
    "temporarily unavailable" response rather than fabricating one."""
    system_prompt = _SYSTEM_TEMPLATE.format(
        language_name=_LANGUAGE_NAME.get(req.language, "English"),
        context_text=_context_text(req),
    )
    messages = [{"role": t.role, "content": t.content} for t in req.history]
    messages.append({"role": "user", "content": req.question})

    client = anthropic.Anthropic(api_key=api_key)
    try:
        with client.messages.stream(
            model=_MODEL,
            max_tokens=_MAX_TOKENS,
            thinking={"type": "adaptive"},
            output_config={"effort": "medium"},
            system=system_prompt,
            messages=messages,
        ) as stream:
            response = stream.get_final_message()
    except anthropic.APIError as exc:
        logger.warning("Chat call failed: %s", exc)
        return None

    if response.stop_reason == "refusal":
        logger.warning("Chat reply declined by model safety classifier")
        return None

    text_block = next((b for b in response.content if b.type == "text"), None)
    if text_block is None or not text_block.text.strip():
        return None
    return text_block.text.strip()
