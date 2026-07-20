# Agri AI Assistant — Backend

Phase 0/1 microservices scaffold per [../docs/architecture/ROADMAP.md](../docs/architecture/ROADMAP.md). Every recommendation-producing endpoint returns the [Standard Output Contract](../docs/architecture/ARCHITECTURE.md#9-standard-output-contract) (`RecommendationEnvelope` in `shared/agri_common`) — confidence score, data sources, assumptions, reasoning, risk analysis, action plan. Enforced by `shared/tests/test_contract.py`.

## Services

| Service | Port (compose) | What it does now | Real integration point (later) |
|---|---|---|---|
| `gateway` | 8000 | Composes `/dashboard` from soil+weather+crop services in parallel; degrades gracefully (`warnings[]`) if a downstream service is unreachable | Add farm_registry lookup by `farm_id`, auth |
| `crop_recommendation` | 8001 | Rule-based hard filter + weighted suitability ranking against a curated 17-crop knowledge base | Swap in a learned ranking model once yield-outcome data exists |
| `weather` | 8002 | Deterministic mock forecast, confidence scaled by horizon (7d=0.86 → annual=0.25) | Real `WeatherProvider` implementation (OpenWeather/IMD) — interface already defined in `services/weather/app/providers.py` |
| `soil` | 8003 | Satellite-estimated soil properties + Land Health Score (0-100, interpretable weighted formula) | `SoilHealthCardProvider` implementation — interface in `services/soil/app/providers.py` |
| `gis` | 8004 | Real geodesic area calculation (WGS84) from a GeoJSON boundary; mock elevation/slope | Google Earth Engine DEM sampling — interface in `services/gis/app/providers.py` |
| `farm_registry` | 8005 | Postgres-backed User/Farm CRUD (create/get/patch/delete), proxied through the gateway | Switch `boundary_geojson` (plain JSON) to a real PostGIS `Geometry` column once boundary-drawing exists |
| `disease_kb` | 8006 | RAG over a curated 12-disease organic-treatment knowledge base (TNAU/ICAR/ICRISAT-sourced) — BGE-M3 embeddings, local Qdrant vector search. Photo upload works end-to-end but is honestly unanalyzed without an LLM vision key; chemical-treatment guidance deliberately isn't fabricated (see main.py) | Wire `ANTHROPIC_API_KEY` for real photo-based detection; add a verified government-approved-pesticide dataset for the chemical path |

All "mock provider" services follow the same pattern: an abstract `*Provider` interface plus a deterministic `Mock*Provider`, so swapping in a real API client later doesn't touch the FastAPI route or the contract-shaping code around it.

## Running locally

**With Docker** (recommended once you have Docker installed):
```bash
docker compose up --build
curl "http://localhost:8000/dashboard?lat=19.99&lon=73.78&area_acres=4.2&season=kharif"
```

**Without Docker** (what was used to build/verify this scaffold): each service is a standalone FastAPI app with its own `requirements.txt`. From `backend/`:
```bash
python -m venv .venv
./.venv/Scripts/pip install -e ./shared
./.venv/Scripts/pip install -r services/<name>/requirements.txt   # per service you want to run
./.venv/Scripts/python -m uvicorn app.main:app --app-dir services/<name> --port <port>
```
Run `weather` (8002), `soil` (8003), `crop_recommendation` (8001), `farm_registry` (8005), and `disease_kb` (8006), then `gateway` with matching env vars:
```bash
SOIL_SERVICE_URL=http://127.0.0.1:8003 WEATHER_SERVICE_URL=http://127.0.0.1:8002 CROP_SERVICE_URL=http://127.0.0.1:8001 FARM_REGISTRY_URL=http://127.0.0.1:8005 DISEASE_KB_SERVICE_URL=http://127.0.0.1:8006 \
  ./.venv/Scripts/python -m uvicorn app.main:app --app-dir services/gateway --port 8000
```
`disease_kb` downloads the BGE-M3 embedding model (~2.3GB) from Hugging Face on first startup and builds its local Qdrant index — this takes a while the first time, then it's cached. No API key needed for the knowledge-base search itself; only photo-based detection needs `ANTHROPIC_API_KEY`.
`farm_registry` needs a real Postgres instance — set `DATABASE_URL` (defaults to `postgresql+psycopg2://agri:agri@localhost:5432/agri_farm_registry`). Locally (no Docker): install PostgreSQL, then:
```sql
CREATE USER agri WITH PASSWORD 'agri';
CREATE DATABASE agri_farm_registry OWNER agri;
```
No PostGIS extension needed — `boundary_geojson` is a plain JSON column until boundary-drawing is built (see models.py). Tables are created automatically on first startup (`Base.metadata.create_all`, no migrations framework yet — add Alembic before this needs to survive schema changes against real data).

## Tests

```bash
./.venv/Scripts/python -m pytest shared/tests -q
cd services/crop_recommendation && ../../.venv/Scripts/python -m pytest tests -q
```

## Environment variables

See `.env.example`. Nothing is required for local dev — every service runs on its mock/estimated provider until real API keys are supplied.

## What's verified vs. not

- **Verified by actually running it**: `crop_recommendation`, `weather`, `soil`, `gis`, and `farm_registry` all start and respond correctly against a real local PostgreSQL instance (full CRUD — create user, create/update/list/delete farm, including an embedded soil report — tested via curl). The `gateway` was proven to compose soil+weather+crop into one `/dashboard` response (including graceful degradation when a downstream service was killed mid-test) and to transparently proxy the farm_registry CRUD routes.
- **Written but not yet confirmed working**: `disease_kb`. Code is complete (knowledge base, embedding/indexing, all three endpoints, gateway proxy including multipart photo forwarding), but the BGE-M3 model download (~2.3GB from Hugging Face) was still in progress when work paused — never confirmed to finish, and the search/indexing behavior has not been tested end-to-end. **Before relying on this service, restart it and confirm `/disease/search-organic-guidance` returns real results.**
- **Not live-tested here**: the full `docker-compose.yml` (needs Docker — not available in this environment; services were run directly with `uvicorn` instead). Alembic migrations aren't set up — schema changes currently require dropping/recreating tables.
- **Not built yet** (see roadmap Phase 2+): water resource, market, fertilizer, irrigation, disaster, government schemes, AI advisor, satellite monitoring, alerts services. Disease is partially built (`disease_kb` — organic guidance RAG); pest prediction and chemical-pesticide guidance are not.
