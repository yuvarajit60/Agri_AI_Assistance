"""API Gateway / BFF (docs/architecture/ARCHITECTURE.md §2). Composes the
mobile dashboard from independent downstream services in parallel, and
degrades gracefully — one unreachable service produces a `warnings` entry
and a null section, never a failed dashboard, mirroring why each data
source sits behind its own service in the first place.
"""

from __future__ import annotations

import asyncio
from datetime import datetime, timezone
from typing import Any, Literal

import httpx
from fastapi import FastAPI, File, Form, Query, Response, UploadFile
from fastapi.responses import JSONResponse

from .config import (
    AI_CHAT_SERVICE_URL,
    CROP_SERVICE_URL,
    DISEASE_KB_SERVICE_URL,
    FARM_REGISTRY_URL,
    FERTILIZER_SERVICE_URL,
    IRRIGATION_SERVICE_URL,
    MARKET_SERVICE_URL,
    REQUEST_TIMEOUT_SECONDS,
    SOIL_SERVICE_URL,
    WATER_SERVICE_URL,
    WEATHER_SERVICE_URL,
)

app = FastAPI(title="API Gateway", version="0.1.0")


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


_RETRY_ATTEMPTS = 2
_RETRY_DELAY_SECONDS = 3


async def _request(client: httpx.AsyncClient, method: str, url: str, **kwargs: Any) -> httpx.Response:
    """A free-tier Render service waking from a cold start (~15 min idle
    triggers spin-down) can hand back a connection error or an empty,
    unparseable body on the very first request that wakes it — the origin
    container hasn't actually finished booting yet even though something
    already answered. A short, single retry turns that into "a bit
    slower" instead of "the app is down," which is what farmers would
    otherwise experience for a backend that's actually fine a few seconds
    later."""
    last_exc: Exception = RuntimeError("unreachable")
    for attempt in range(_RETRY_ATTEMPTS):
        try:
            resp = await client.request(method, url, timeout=REQUEST_TIMEOUT_SECONDS, **kwargs)
            resp.raise_for_status()
            if resp.status_code != 204 and resp.content:
                resp.json()  # validate the body actually parses before trusting this response
            return resp
        except (httpx.HTTPError, ValueError) as exc:
            last_exc = exc
            if attempt < _RETRY_ATTEMPTS - 1:
                await asyncio.sleep(_RETRY_DELAY_SECONDS)
    raise last_exc


async def _get(client: httpx.AsyncClient, url: str, params: dict[str, Any]) -> dict[str, Any] | None:
    try:
        resp = await _request(client, "GET", url, params=params)
        return resp.json()
    except (httpx.HTTPError, ValueError):
        return None


async def _post(client: httpx.AsyncClient, url: str, json: dict[str, Any]) -> dict[str, Any] | None:
    try:
        resp = await _request(client, "POST", url, json=json)
        return resp.json()
    except (httpx.HTTPError, ValueError):
        return None


async def _none() -> None:
    """A no-op coroutine so a conditionally-skipped call can still sit in
    an asyncio.gather() alongside the calls that do run."""
    return None


@app.get("/dashboard")
async def dashboard(
    lat: float = Query(..., ge=-90, le=90),
    lon: float = Query(..., ge=-180, le=180),
    area_acres: float = Query(..., gt=0),
    season: Literal["kharif", "rabi", "zaid", "any"] = "any",
    soil_ph: float | None = Query(None, ge=0, le=14, description="Farmer-submitted lab report override"),
    soil_ec: float | None = Query(None, ge=0),
    soil_oc: float | None = Query(None, ge=0),
    soil_n: float | None = Query(None, ge=0),
    soil_p: float | None = Query(None, ge=0),
    soil_k: float | None = Query(None, ge=0),
    language: str = Query("en", pattern="^(en|ta)$"),
) -> dict[str, Any]:
    warnings: list[str] = []
    lab_report_supplied = None not in (soil_ph, soil_ec, soil_oc, soil_n, soil_p, soil_k)

    async with httpx.AsyncClient() as client:
        if lab_report_supplied:
            soil_task = _post(
                client,
                f"{SOIL_SERVICE_URL}/soil/lab-report",
                {
                    "lat": lat,
                    "lon": lon,
                    "ph": soil_ph,
                    "ec_ds_per_m": soil_ec,
                    "organic_carbon_percent": soil_oc,
                    "nitrogen_kg_per_ha": soil_n,
                    "phosphorus_kg_per_ha": soil_p,
                    "potassium_kg_per_ha": soil_k,
                },
            )
        else:
            soil_task = _get(client, f"{SOIL_SERVICE_URL}/soil/analyze", {"lat": lat, "lon": lon})
        weather_task = _get(
            client, f"{WEATHER_SERVICE_URL}/weather/forecast", {"lat": lat, "lon": lon, "horizon": "7d"}
        )
        water_task = _get(client, f"{WATER_SERVICE_URL}/water/analyze", {"lat": lat, "lon": lon, "language": language})
        soil, weather, water = await asyncio.gather(soil_task, weather_task, water_task)

        if soil is None:
            warnings.append("Soil service unavailable — land health and crop recommendations may be degraded.")
        if weather is None:
            warnings.append("Weather service unavailable — crop recommendations may be degraded.")
        if water is None:
            warnings.append("Water resource service unavailable.")

        crop_recommendations = None
        if soil is not None and weather is not None:
            crop_recommendations = await _post(
                client,
                f"{CROP_SERVICE_URL}/crops/recommend",
                {
                    "farm_area_acres": area_acres,
                    "soil_ph": soil["result"]["ph"],
                    # Crude 7-day -> seasonal extrapolation until the Weather service exposes
                    # a native seasonal-rainfall figure (see weather horizon options).
                    "seasonal_rainfall_mm": weather["result"]["total_rainfall_mm"] * 12,
                    "water_availability_mm": weather["result"]["total_rainfall_mm"] * 12,
                    "current_season": season,
                    "soil_confidence": soil["confidence_score"],
                    "weather_confidence": weather["confidence_score"],
                    "irrigation_method": water["result"]["irrigation_feasibility"]["method"] if water else None,
                    "top_n": 5,
                },
            )
            if crop_recommendations is None:
                warnings.append("Crop recommendation service unavailable.")
        else:
            warnings.append("Skipped crop recommendations — requires both soil and weather data.")

        # Market forecast, fertilizer, and irrigation all need the top
        # recommended crop's name, which only exists once
        # crop_recommendations has resolved above — a genuine sequential
        # dependency, unlike soil/weather/water which gather() in parallel
        # with no such ordering constraint. The three of them have no
        # dependency on each other, so they gather() together.
        market_forecast = None
        fertilizer_recommendation = None
        irrigation_plan = None
        top_crop_name = (
            crop_recommendations["result"]["crop_name"] if crop_recommendations is not None else None
        )
        if top_crop_name and top_crop_name != "No suitable crop found":
            market_task = _post(
                client,
                f"{MARKET_SERVICE_URL}/market/price-forecast",
                {"commodity": top_crop_name, "lat": lat, "lon": lon, "language": language},
            )
            fertilizer_task = (
                _post(
                    client,
                    f"{FERTILIZER_SERVICE_URL}/fertilizer/recommend",
                    {
                        "crop_name": top_crop_name,
                        "farm_area_acres": area_acres,
                        "soil_nitrogen_kg_per_ha": soil["result"]["nitrogen_kg_per_ha"],
                        "soil_phosphorus_kg_per_ha": soil["result"]["phosphorus_kg_per_ha"],
                        "soil_potassium_kg_per_ha": soil["result"]["potassium_kg_per_ha"],
                        "soil_ph": soil["result"]["ph"],
                        "organic_carbon_percent": soil["result"]["organic_carbon_percent"],
                        "soil_confidence": soil["confidence_score"],
                        "language": language,
                    },
                )
                if soil is not None
                else _none()
            )
            irrigation_task = _post(
                client,
                f"{IRRIGATION_SERVICE_URL}/irrigation/plan",
                {
                    "crop_name": top_crop_name,
                    "crop_water_requirement_mm": crop_recommendations["result"]["water_requirement_mm"],
                    "crop_duration_days": crop_recommendations["result"]["time_to_harvest_days"],
                    "farm_area_acres": area_acres,
                    "irrigation_method": water["result"]["irrigation_feasibility"]["method"] if water else None,
                    "soil_moisture_percent": soil["result"]["moisture_percent"] if soil else None,
                    "language": language,
                },
            )
            market_forecast, fertilizer_recommendation, irrigation_plan = await asyncio.gather(
                market_task, fertilizer_task, irrigation_task
            )

            if market_forecast is None:
                warnings.append("Market price service unavailable.")
            if soil is None:
                warnings.append("Skipped fertilizer recommendation — requires soil data.")
            elif fertilizer_recommendation is None:
                warnings.append("Fertilizer recommendation service unavailable.")
            if irrigation_plan is None:
                warnings.append("Irrigation planning service unavailable.")
        else:
            warnings.append("Skipped market forecast, fertilizer recommendation, and irrigation planning — no recommended crop.")

    return {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "farm": {"lat": lat, "lon": lon, "area_acres": area_acres},
        "land_health": soil,
        "weather": weather,
        "water_resources": water,
        "crop_recommendations": crop_recommendations,
        "market_forecast": market_forecast,
        "fertilizer_recommendation": fertilizer_recommendation,
        "irrigation_plan": irrigation_plan,
        "warnings": warnings,
    }


# --- Farm Registry proxy -----------------------------------------------
# Transparent passthrough so the mobile app only ever needs one base URL
# (docs/architecture/ARCHITECTURE.md §2). Errors (404, validation, etc.)
# are forwarded with the same status code and body farm_registry returned,
# rather than being modeled twice.


async def _proxy(
    method: str, path: str, json: dict[str, Any] | None = None, base_url: str = FARM_REGISTRY_URL
) -> Response:
    try:
        async with httpx.AsyncClient() as client:
            resp = await _request(client, method, f"{base_url}{path}", json=json)
        if resp.status_code == 204 or not resp.content:
            return Response(status_code=resp.status_code)
        return JSONResponse(content=resp.json(), status_code=resp.status_code)
    except (httpx.HTTPError, ValueError) as exc:
        return JSONResponse(
            status_code=503,
            content={"detail": f"Upstream service unavailable: {exc}"},
        )


@app.post("/users")
async def proxy_create_user(payload: dict[str, Any]) -> Response:
    return await _proxy("POST", "/users", json=payload)


@app.patch("/users/{user_id}")
async def proxy_update_user(user_id: str, payload: dict[str, Any]) -> Response:
    return await _proxy("PATCH", f"/users/{user_id}", json=payload)


@app.get("/users/{user_id}")
async def proxy_get_user(user_id: str) -> Response:
    return await _proxy("GET", f"/users/{user_id}")


@app.get("/users/{user_id}/farms")
async def proxy_list_user_farms(user_id: str) -> Response:
    return await _proxy("GET", f"/users/{user_id}/farms")


@app.post("/farms")
async def proxy_create_farm(payload: dict[str, Any]) -> Response:
    return await _proxy("POST", "/farms", json=payload)


@app.get("/farms/{farm_id}")
async def proxy_get_farm(farm_id: str) -> Response:
    return await _proxy("GET", f"/farms/{farm_id}")


@app.patch("/farms/{farm_id}")
async def proxy_update_farm(farm_id: str, payload: dict[str, Any]) -> Response:
    return await _proxy("PATCH", f"/farms/{farm_id}", json=payload)


@app.delete("/farms/{farm_id}")
async def proxy_delete_farm(farm_id: str) -> Response:
    return await _proxy("DELETE", f"/farms/{farm_id}")


# --- Water Resource proxy ------------------------------------------------


@app.get("/water/analyze")
async def proxy_water_analyze(
    lat: float = Query(..., ge=-90, le=90),
    lon: float = Query(..., ge=-180, le=180),
    language: str = Query("en", pattern="^(en|ta)$"),
) -> Response:
    return await _proxy("GET", f"/water/analyze?lat={lat}&lon={lon}&language={language}", base_url=WATER_SERVICE_URL)


# --- Market Price Prediction proxy ---------------------------------------


@app.post("/market/price-forecast")
async def proxy_market_price_forecast(payload: dict[str, Any]) -> Response:
    return await _proxy("POST", "/market/price-forecast", json=payload, base_url=MARKET_SERVICE_URL)


# --- Fertilizer Recommendation proxy -------------------------------------


@app.post("/fertilizer/recommend")
async def proxy_fertilizer_recommend(payload: dict[str, Any]) -> Response:
    return await _proxy("POST", "/fertilizer/recommend", json=payload, base_url=FERTILIZER_SERVICE_URL)


# --- Irrigation Planning proxy --------------------------------------------


@app.post("/irrigation/plan")
async def proxy_irrigation_plan(payload: dict[str, Any]) -> Response:
    return await _proxy("POST", "/irrigation/plan", json=payload, base_url=IRRIGATION_SERVICE_URL)


# --- AI Chat (Farm Advisor) proxy -----------------------------------------


@app.post("/chat/ask")
async def proxy_chat_ask(payload: dict[str, Any]) -> Response:
    # Adaptive thinking + effort can genuinely take longer than the other
    # (non-LLM) proxied calls' shared timeout — same reasoning as the photo
    # diagnosis proxy's own extended budget.
    try:
        async with httpx.AsyncClient() as client:
            resp = await client.post(
                f"{AI_CHAT_SERVICE_URL}/chat/ask",
                json=payload,
                timeout=max(REQUEST_TIMEOUT_SECONDS, 60.0),
            )
    except httpx.HTTPError as exc:
        return JSONResponse(status_code=503, content={"detail": f"AI chat unavailable: {exc}"})
    return JSONResponse(content=resp.json(), status_code=resp.status_code)


# --- Disease Organic Knowledge Base (RAG) proxy -------------------------


@app.get("/disease/list")
async def proxy_disease_list() -> Response:
    try:
        async with httpx.AsyncClient() as client:
            resp = await client.get(f"{DISEASE_KB_SERVICE_URL}/disease/list", timeout=REQUEST_TIMEOUT_SECONDS)
    except httpx.HTTPError as exc:
        return JSONResponse(status_code=503, content={"detail": f"Disease knowledge base unavailable: {exc}"})
    return JSONResponse(content=resp.json(), status_code=resp.status_code)


@app.post("/disease/search-organic-guidance")
async def proxy_search_organic_guidance(payload: dict[str, Any]) -> Response:
    return await _proxy("POST", "/disease/search-organic-guidance", json=payload, base_url=DISEASE_KB_SERVICE_URL)


@app.post("/disease/chemical-guidance")
async def proxy_chemical_guidance(payload: dict[str, Any]) -> Response:
    return await _proxy("POST", "/disease/chemical-guidance", json=payload, base_url=DISEASE_KB_SERVICE_URL)


@app.post("/disease/diagnose-photo")
async def proxy_diagnose_photo(
    crop: str = Form(""),
    notes: str = Form(""),
    photo: UploadFile = File(...),
    language: str = Form("en"),
) -> Response:
    contents = await photo.read()
    try:
        # Vision analysis (disease_kb -> Claude) plus the image upload itself
        # routinely take longer than the other proxied calls' text-only
        # REQUEST_TIMEOUT_SECONDS, especially over the local ngrok tunnel —
        # give it its own longer budget rather than risk a false 503.
        async with httpx.AsyncClient() as client:
            resp = await client.post(
                f"{DISEASE_KB_SERVICE_URL}/disease/diagnose-photo",
                data={"crop": crop, "notes": notes, "language": language},
                files={"photo": (photo.filename, contents, photo.content_type)},
                timeout=max(REQUEST_TIMEOUT_SECONDS, 60.0),
            )
    except httpx.HTTPError as exc:
        return JSONResponse(status_code=503, content={"detail": f"Disease knowledge base unavailable: {exc}"})
    return JSONResponse(content=resp.json(), status_code=resp.status_code)
