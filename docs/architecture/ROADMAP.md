# Phased Roadmap

Goal: get a truthful, narrow slice in front of real farmers fast, then widen. Every phase must still honor "never hallucinate" — a phase ships with fewer features, not with fake data filling gaps.

## Current status vs. this plan

Development so far has been request-driven (built what was asked for, in the order it was asked), not a clean phase-by-phase march — so progress is scattered across phases rather than "Phase 0 done, Phase 1 in progress." Honest snapshot:

- **Phase 0/1 — mostly done**: gateway, farm_registry (now real **PostgreSQL**, not just designed — see backend/README.md), GIS, weather (mock provider), soil (estimated + farmer-submitted lab report), crop recommendation engine, Flutter app with GPS + location-search + drawn-boundary-*less* land identification (boundary drawing itself is still not built), full dashboard.
- **Phase 2 — partial**: Smart Comparison view is done; full crop economics (investment/profit/ROI) is done; Water Resource Service, Fertilizer Recommendation, Irrigation Planning are **not built**; Soil Health Card API integration is not built (farmers can manually enter lab values instead, which covers the same need less automatically).
- **Phase 3 — partial, out of order**: Disease guidance exists (`disease_kb` — RAG over a curated organic-treatment knowledge base), built ahead of schedule because it was requested directly. Pest Prediction, Natural Disaster Prediction, Satellite Monitoring, and Alerts are **not built**.
- **Phase 4 — partial, out of order**: the vector DB + knowledge base ingestion piece exists (BGE-M3 + Qdrant, but scoped to organic disease guidance only, not a general AI Advisor). Multi-language support in the app is **done** (English/Tamil, live-switchable) — well ahead of schedule. AI Chat is still canned replies, not RAG/LLM-backed; AI Advisor doesn't exist.
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
- Computer-vision disease detection from photos — the *photo upload* now exists and works end-to-end (`disease_kb` service, Diagnose screen), but automated visual analysis is still deferred: it needs a vision-capable LLM API key that isn't configured. Text/symptom-based diagnosis works today via RAG.
- LLM fine-tuning (RAG is sufficient through at least Phase 5)
- Chemical/pesticide-specific treatment recommendations — deliberately not built even as a stub; see `backend/services/disease_kb/app/main.py`'s `chemical_guidance` endpoint for why (real safety/legal risk in guessing a product without a verified government-approved-pesticide dataset).

---

## Next steps (updated)

Given actual progress, the highest-leverage next items are probably:
1. **Confirm `disease_kb` actually works** — the BGE-M3 model download was mid-flight when work last paused; verify indexing completes and a real search query returns sensible results before building further on top of it.
2. **Wire an `ANTHROPIC_API_KEY`** if/when available — unlocks real photo-based disease detection and would let AI Chat move off canned replies.
3. **Water Resource Service** — the most-requested-sounding Phase 2 gap that's still fully unbuilt, and the "Water Resource Identification" section of the original product brief hasn't been touched at all yet.
4. A real cloud deployment — everything currently runs on one developer's LAN; there's no path yet for a farmer outside that WiFi network to reach any of this.
