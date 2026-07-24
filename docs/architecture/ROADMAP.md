# Phased Roadmap

Goal: get a truthful, narrow slice in front of real farmers fast, then widen. Every phase must still honor "never hallucinate" — a phase ships with fewer features, not with fake data filling gaps.

## Current status vs. this plan

Development so far has been request-driven (built what was asked for, in the order it was asked), not a clean phase-by-phase march — so progress is scattered across phases rather than "Phase 0 done, Phase 1 in progress." Honest snapshot:

- **Phase 0/1 — mostly done**: gateway, farm_registry (now real **PostgreSQL**, not just designed — see backend/README.md), GIS, weather (mock provider), soil (estimated + farmer-submitted lab report), crop recommendation engine (now irrigation-aware — see Phase 2 note), Flutter app with GPS + location-search + drawn-boundary-*less* land identification (boundary drawing itself is still not built), full dashboard. **6 of the 7 Render-eligible services are deployed to the cloud (Render free tier + Neon Postgres)**; the market_price service (below) is built but not yet deployed — see "Deployment reality" below.
- **Phase 2 — mostly done**: Smart Comparison view is done; full crop economics (investment/profit/ROI) is done; **Water Resource Service is built** (`backend/services/water` — surface-water proximity, groundwater category, irrigation method feasibility; same mock-provider-with-honest-confidence pattern as soil, real JRC/India-WRIS/OSM/CGWB ingestion not wired up yet) **and now feeds the Crop Recommendation Engine directly** (irrigation access widens/boosts effective water availability, not just display); **Market Price & Intelligence Service is built** (`backend/services/market_price` — Prophet primary/SARIMA-fallback 12-month price forecast + nearby-mandi estimates, wired into the dashboard and its own Market tab; training data is an honestly-labeled synthetic seasonal series, real Agmarknet/data.gov.in ingestion not wired up yet — see MODULES.md §10). **Fertilizer Recommendation Service is built** (`backend/services/fertilizer` — deterministic N-P2O5-K2O gap calculation between a curated per-crop requirement reference and the Soil service's values, converted into real Urea/DAP/MOP quantities for the farm's area, plus pH and organic-matter notes; not a mock/estimate step like soil/water — it's arithmetic over already-known inputs) and **Irrigation Planning Service is built** (`backend/services/irrigation` — converts the Crop Recommendation service's water requirement into a liters-per-irrigation schedule, using the Water service's irrigation method to set frequency and application efficiency). Both are wired into the gateway's `/dashboard` composition (sequenced after the top crop pick resolves, same pattern as market forecast), have their own proxy endpoints, **and now have full mobile UI** — dashboard cards + dedicated Fertilizer/Irrigation detail screens (`mobile_app/lib/features/fertilizer`, `.../irrigation`), fully English/Tamil localized end-to-end (both services accept `language` like Water/Weather do, not just the mobile UI layer). Soil Health Card API integration is not built (farmers can manually enter lab values instead, which covers the same need less automatically).
- **Phase 3 — partial, out of order**: Disease *guidance* exists (`disease_kb` — RAG over a curated organic-treatment knowledge base) **and photo-based diagnosis is now real** — Claude vision, RAG-grounded (constrained to picking a disease_id from the curated knowledge base, never freeform), both built ahead of schedule because they were requested directly. This is still reactive diagnosis from a submitted photo/symptom, not proactive Disease/Pest *prediction* from conditions — that, plus Natural Disaster Prediction, Satellite Monitoring, and Alerts, are **not built**.
- **Phase 4 — partial, out of order**: the vector DB + knowledge base ingestion piece exists (BGE-M3 + Qdrant, but scoped to organic disease guidance only, not a general AI Advisor). Multi-language support in the app is **done** (English/Tamil, live-switchable) — well ahead of schedule. `ANTHROPIC_API_KEY` is now wired and working (photo disease diagnosis uses it); AI Chat is still canned replies, not RAG/LLM-backed — extending it is now mostly plumbing since the key and vision-call pattern already exist. AI Advisor doesn't exist.
- **Phase 5/6 — not started.**

## Original phase plan (for reference — see status above for what's actually true today)

## Phase 0 — Foundations (infra, no farmer-facing features)
- GCP project setup, GKE/Cloud Run environments (dev/staging/prod), CI/CD
- Postgres+PostGIS schema for Farm/User registry
- API Gateway skeleton + shared Standard Output Contract enforcement (Pydantic model + contract tests)
- Firebase Auth (phone OTP) integration
- Flutter app skeleton with auth flow

## Phase 1 — MVP: one location method → one useful report
- Land Identification: GPS coordinates + drawn boundary only (defer survey number/document upload — they need state-specific cadastral integration)
- GIS/Elevation Service (area, elevation, slope via GEE)
- Weather Service: 7-day + 30-day forecast only (OpenWeather + IMD warnings)
- Soil Service: satellite-estimated properties only (Soil Health Card integration is Phase 2 — coverage is patchy and needs per-state onboarding)
- Land Health Score v1 (weighted-formula version)
- Crop Recommendation Engine: rule-based hard filter + simple suitability score (no ML ranking yet, no market-linked profit projection yet)
- Dashboard: farm summary + weather + Land Health Score + crop shortlist
- **Success criterion:** a farmer can identify a farm and get a trustworthy, clearly-labeled (confidence + sources) crop shortlist in under a minute.

## Phase 2 — Water, Market, Fertilizer, Irrigation
- Water Resource Service (surface water + groundwater feasibility)
- Soil Health Card integration where available, by state
- Market Price & Intelligence Service (price prediction + nearby mandi)
- Crop Recommendation Engine v2: full economics (investment, maintenance cost, expected profit, ROI) using Market Service output
- Fertilizer Recommendation Service
- Irrigation Planning Service
- Smart Comparison view

## Phase 3 — Risk & Monitoring
- Disease Prediction Service
- Pest Prediction Service
- Natural Disaster Prediction Service
- Satellite Monitoring (NDVI/stress tracking) + Alerts Service
- Push/SMS notifications end-to-end

## Phase 4 — AI Advisor & Chat
- Vector DB + knowledge base ingestion (ICAR guides, scheme text)
- AI Advisor Service (daily/weekly synthesized task list)
- AI Chat Service (RAG + tool-calling)
- Multi-language support in the app and LLM layer

## Phase 5 — Government Schemes, Admin Console, Scale-out
- Government Schemes Service (curated catalog + eligibility matching)
- Admin/Agronomist web console
- ML upgrades: gradient-boosted crop ranking, learned Land Health Score, time-series price model upgrade
- Multi-state Soil Health Card / cadastral coverage expansion

## Phase 6 — Multi-country readiness
- Second-country `DataSourceProvider` implementation as a proof of the abstraction (choose a country with reasonably open agri data to validate the pattern before committing further)
- Currency/unit localization, region-specific crop knowledge base

## Explicitly out of scope until later
- Land document upload/OCR (brief marks this "future enhancement")
- LLM fine-tuning (RAG is sufficient through at least Phase 5)
- Chemical/pesticide-specific treatment recommendations — deliberately not built even as a stub; see `backend/services/disease_kb/app/main.py`'s `chemical_guidance` endpoint for why (real safety/legal risk in guessing a product without a verified government-approved-pesticide dataset).

## Deployment reality (as of the Render migration)

- **6 services are live on Render's free tier**: gateway, crop_recommendation, weather, soil, gis, water, plus farm_registry backed by a free Neon Postgres. Free-tier web services spin down after ~15 min idle and take up to ~60s to wake — the gateway retries once on a failed/empty upstream response to smooth over the common case, but an occasional slow or degraded dashboard on the very first request after a break is expected, not a bug.
- **`market_price` is built but NOT yet deployed to Render** — it needs a Blueprint sync to create `agri-market-price` plus a manual `MARKET_SERVICE_URL` entry on `agri-gateway` once that service has a URL. Until then the dashboard degrades gracefully (null section + a warning), same as any other unreachable service. Also heavier than the other free-tier services (Prophet's `cmdstan` native backend, ~150-250MB) — if the Render build times out or the container struggles at runtime, dropping `prophet` from `services/market_price/requirements.txt` makes the statsmodels SARIMA fallback the only path with no code change.
- **`disease_kb` is NOT deployed to Render** — its BGE-M3 embedding model needs ~3-4GB RAM, well past free-tier limits. It runs locally and is reached through a free ngrok tunnel (`DISEASE_KB_SERVICE_URL` on the gateway points at the tunnel's public URL). This is a real fragility: it only works while the developer's PC, the local `disease_kb` process, and the ngrok tunnel are all running, and the URL changes if ngrok ever restarts (free tier has no fixed domain guarantee). This is the single weakest link in the deployed system. Photo-based vision diagnosis (Claude, RAG-grounded to the curated 12-disease knowledge base) runs here too, so it inherits the same fragility.
- render.yaml intentionally leaves every cross-service URL and `DATABASE_URL` unset (`sync: false`) — Render assigns public hostnames with an unpredictable random suffix at creation, and secrets never belong in a committed file. These are pasted in manually via the dashboard after each service's URL is known.

---

## Next steps (updated)

Given actual progress, the highest-leverage next items are probably:
1. **Deploy `market_price`, `fertilizer`, and `irrigation` to Render** (Blueprint sync + manual `MARKET_SERVICE_URL`/`FERTILIZER_SERVICE_URL`/`IRRIGATION_SERVICE_URL` entries) — all three services are built and tested locally but not yet live. `fertilizer` and `irrigation` are lightweight (no heavy ML dependency like `market_price`'s Prophet/cmdstan) and should build/deploy without the sizing concerns that apply to `market_price`.
2. **Make `disease_kb` reliably reachable without depending on a developer's PC staying on** — either find/pay for enough RAM somewhere to host it permanently, or accept the ngrok-tunnel fragility as a known limitation for now.
3. Real water-bodies (JRC/India-WRIS/OSM) and CGWB groundwater data ingestion to replace the Water service's mock provider — same "estimate first, wire up the real feed later" pattern already used for soil.
4. Real Agmarknet/data.gov.in price data to replace market_price's synthetic training series — same pattern, now that the forecasting pipeline itself is proven.
5. Extend the now-working Claude integration (vision diagnosis) into AI Chat — move it off canned replies onto real RAG/LLM, and/or build the AI Advisor Service (Phase 4).
