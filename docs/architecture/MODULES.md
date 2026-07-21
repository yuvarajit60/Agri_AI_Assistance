# Functional Modules — Detailed Design

Each module below maps directly to a section of the original brief and to a service in [ARCHITECTURE.md](./ARCHITECTURE.md#3-microservice-catalog). All responses follow the [Standard Output Contract](./ARCHITECTURE.md#9-standard-output-contract).

## 1. Land Identification

Nine input methods resolve to one internal representation: `Farm { polygon: Geometry, centroid: Point, resolution_method: enum, resolution_confidence: float }`.

| Method | Resolution strategy | Confidence |
|---|---|---|
| Country/Region/State/District/City-Village | Geocode to a region centroid; farmer must then narrow via GPS pin or drawn boundary before a full report generates | Low until narrowed |
| Survey Number | Lookup against state cadastral service where available (Bhu-Naksha/Dharani/etc.) | High if state has a public cadastral API, else falls back to manual boundary draw |
| GPS Coordinates | Direct point; buffer to an estimated plot size unless a boundary is drawn | Medium (point known, exact boundary assumed) |
| Google Maps Location | Reverse-geocoded point, same as GPS | Medium |
| Draw boundary | Farmer-drawn polygon on the map UI | High |
| Upload land document (future) | OCR + document parsing → boundary/coordinates | N/A — deferred |

The dashboard is intentionally degraded (fewer/lower-confidence sections) until resolution reaches at least "point known"; boundary-level resolution unlocks area-dependent figures (yield totals, investment totals) with full confidence.

## 2. Land Profile (boundary, area, elevation, terrain, slope, drainage, water-holding capacity)

Computed once at farm creation, refreshed on boundary edit or annually:
- **Area** — PostGIS `ST_Area` on the resolved polygon (geodesic).
- **Elevation/slope** — GEE DEM sampled across the polygon; slope classified (flat/gentle/moderate/steep) using standard agronomic slope bands.
- **Land classification & terrain** — derived from slope + land-cover layer (Bhuvan LULC / GEE).
- **Drainage capability & water-holding capacity** — derived from soil texture (from Soil & Land Health Service) cross-referenced with slope; reported qualitatively (poor/moderate/good) with the underlying texture/slope values shown for transparency.

## 3. Water Resource Identification

For each nearby water feature type (river, canal, lake, pond, well, borewell, reservoir, check dam, irrigation channel):
- **Detection** — PostGIS spatial query against an ingested water-bodies layer (JRC Global Surface Water + India-WRIS + OSM waterways), buffered search radius expanding from 1km to 10km until results found.
- **Per-feature output**: `type, name (if known), distance_km, seasonal_availability (perennial/seasonal/monsoon-only), estimated_water_availability`.
- **Groundwater possibility** — CGWB district/block-level groundwater category (safe/semi-critical/critical/over-exploited) + depth-to-water-table estimate, translated into a plain-language "borewell feasibility" rating.
- **Irrigation feasibility** — composite of nearest surface water distance + groundwater category + farm elevation relative to nearest source (gravity-fed vs. pumped).

**Implementation note:** built — `backend/services/water` follows the same "always-estimated, honestly-labeled" pattern as the Soil service: `MockWaterResourceProvider` returns a deterministic per-location estimate (2-4 nearby features, a groundwater category, and a gravity-fed/pumped/limited irrigation suggestion), always at `confidence_score=0.5` with `data_sources` marked `live=false`. Real JRC/India-WRIS/OSM water-bodies ingestion and a CGWB groundwater feed aren't wired up yet — that's the natural next step once this pattern needs to graduate from estimate to measurement. Composed into the gateway `/dashboard` response and has its own mobile screen (Water Resources card → full detail screen).

## 4. Land Health Analysis

Pipeline: check for a farmer-submitted/Soil-Health-Card lab report first → if none, estimate from SoilGrids + satellite spectral indices, explicitly flagged as estimated with a lab-test recommendation.

Properties covered: fertility, texture, organic carbon, N/P/K, pH, EC, micronutrients, moisture, salinity, degradation, erosion risk.

**Land Health Score (0–100)** — a weighted composite, v1 formula (interpretable, replaceable by a learned model once labeled outcomes accumulate):

```
score = 0.20*fertility_index + 0.15*organic_carbon_index + 0.15*npk_balance_index
      + 0.15*ph_suitability_index + 0.10*moisture_index + 0.10*(1 - erosion_risk)
      + 0.10*(1 - salinity_index) + 0.05*(1 - degradation_index)
```

Every sub-index and its data source (lab report vs. estimated) is returned alongside the final score so an agronomist can audit exactly why a farm scored 62 vs. 85.

## 5. Weather Analysis

- **Historical** — pulled from NASA POWER/IMD archives, cached in BigQuery.
- **Forecast** — 7-day (high confidence, OpenWeather/IMD direct), 30-day (medium, statistical/ensemble), 90-day & seasonal (lower confidence, climatological + monsoon outlook models from IMD), annual (trend-level only, framed as an outlook not a forecast).
- Every horizon returns an explicit `confidence_score` that decreases with horizon length — this is stated to the farmer in plain language ("7-day: high confidence · 90-day: indicative only").
- Derived metrics: heat index, evapotranspiration (Penman-Monteith using temp/humidity/wind/solar inputs), computed server-side, not sourced externally.

## 6. Crop Recommendation Engine

Two-stage pipeline:
1. **Hard filter** — eliminate crops whose water requirement exceeds availability, whose agro-climatic zone doesn't match, or that are out of season.
2. **Ranking** — remaining candidates scored by suitability (soil/water/weather match), then enriched with expected yield, water requirement, investment, maintenance cost, expected profit (yield × predicted market price − costs, from Market Service), time to harvest, risk level, ROI.

Crops are grouped short/medium/long-term per the brief's examples; the crop knowledge base (agro-climatic requirements, typical costs, typical yields per region) is a curated, versioned dataset seeded from ICAR/state agriculture department package-of-practices documents, not invented by the LLM.

**Implementation note:** the "soil/water/weather match" this section describes was soil+weather only until the Water Resource Service existed to provide the water half. Now wired up — the gateway passes the Water service's `irrigation_method` (gravity_fed/pumped/limited) into `/crops/recommend`, and a reliable irrigation source genuinely widens the hard filter (not just the score): gravity-fed access treats water as effectively abundant (any crop in the knowledge base can be irrigated), pumped access multiplies rainfall-derived availability by 1.6x, and no source falls back to the original rainfall-only behavior. See `backend/services/crop_recommendation/app/engine.py`'s `_effective_water_availability`.

## 7. Smart Comparison

A stateless view over Crop Recommendation Engine output — no new computation, just a side-by-side table (suitability, investment, water need, yield, profit, risk, ROI, harvest duration, rank) for farmer-selected crops. Lives at the API Gateway composition layer.

## 8. Market Price Prediction & Intelligence

- **Price prediction** — time-series model per commodity/market cluster (Prophet/SARIMA baseline), inputs include historical Agmarknet prices, seasonality, weather-driven supply shocks, and where available export/import trend signals from FAOSTAT.
- Output always a **range + expected value + confidence**, plus best selling month/market derived from historical seasonal price patterns.
- **Market intelligence** — nearby markets/mandis via PostGIS proximity join against an ingested mandi-location dataset; wholesale/retail spread, demand trend (rising/stable/falling from recent price momentum), export opportunity flagged from FAOSTAT trade trend, processing industry & cold storage proximity from a curated infrastructure dataset.

## 9. Disease & Pest Prediction

- **Disease** — crop-stage-aware + weather-correlated risk model (many crop diseases have known temp/humidity/leaf-wetness thresholds from agronomy literature); each predicted disease returns probability, symptoms, causes, early detection signs, preventive measures, organic treatment, chemical treatment, **government-approved pesticide list** (sourced from Central Insecticides Board & Registration Committee data), expected loss, recovery chance.
- **Pest** — same weather-driven approach using known pest lifecycle/outbreak conditions (e.g., brown planthopper favored by high humidity + still water in rice); returns pest name, probability, risk level, biological control, chemical control, recommended monitoring frequency.
- Both modules are designed to accept a future photo-upload input (computer-vision classifier) without changing their output contract — deferred per [ARCHITECTURE.md §12](./ARCHITECTURE.md#12-whats-deliberately-deferred).

**Implementation note (built out of order, organic-only so far):** the *organic treatment* half of Disease is real — `backend/services/disease_kb` is a RAG service (BGE-M3 embeddings, local Qdrant vector search) over a curated ~12-disease knowledge base sourced from TNAU/ICAR/ICRISAT, with a mobile "Diagnose a crop problem" screen (photo + symptom text). Photo *upload* works end-to-end; automated photo *analysis* doesn't (needs a vision-capable LLM key, not configured — see `ANTHROPIC_API_KEY`). The chemical-treatment/government-approved-pesticide half described above is deliberately **not implemented**, even as a stub — the service explicitly refuses to guess a pesticide product without a verified dataset, and instead points farmers to the Kisan Call Centre / local KVK. Pest Prediction is untouched.

## 10. Fertilizer Recommendation

Derived directly from the Soil & Land Health Service's NPK/pH/micronutrient values plus the selected crop's nutrient uptake curve (ICAR fertilizer recommendation norms, state-specific where available): organic, chemical, bio-fertilizer options, application schedule tied to crop growth stage, dosage, and cost estimate (using current input-cost reference data).

## 11. Irrigation Planning

Weekly/monthly schedule computed from crop water requirement (FAO CROPWAT-style Kc-based ET crop = ET₀ × Kc) minus effective rainfall (from Weather Service forecast) minus soil moisture buffer (from Soil Service water-holding capacity). Method recommendation (drip/sprinkler/flood/rain-fed) driven by crop type, water availability tier, and farm slope/terrain.

## 12. Natural Disaster Prediction

For flood, drought, cyclone, heat wave, cold wave, heavy rain, hailstorm, landslide, storm: prefer direct IMD/NDMA warnings when issued (authoritative, short-horizon); supplement with a historical base-rate + current-season anomaly model for longer-horizon "risk outlook" (e.g., "this district has a 30% historical drought incidence in low-monsoon years, and this year's monsoon onset is 9 days late"). Each risk includes probability, expected window (not a false-precision date when the true forecast horizon doesn't support one), severity, impact, preparation steps, and an insurance suggestion pointing to the relevant PMFBY/state scheme.

## 13. Government Benefits

A curated, periodically-refreshed catalog (subsidies, insurance, loans, seed schemes, equipment subsidies, PM-Kisan, state schemes) matched to the farmer's profile (land size, crop, state, category) with eligibility logic expressed as explicit rules (not LLM-inferred) and direct application links.

## 14. AI Advisor

A synthesis layer: pulls today's/this-week's outputs from Weather, Irrigation, Fertilizer, Disease/Pest, Market, and Alerts services, and asks the LLM to compose a prioritized, plain-language task list ("irrigate Tuesday morning before the forecast heat spike; disease risk is elevated for your paddy — check for leaf spots this week"). The LLM only *composes and prioritizes* — it does not invent the underlying facts, which all come from tool calls to the domain services.

## 15. AI Chat

RAG-grounded conversational interface (see [ARCHITECTURE.md §5.2](./ARCHITECTURE.md#52-llm-layer-ai-advisor--ai-chat)). Example queries route to tool calls: "Will it rain next week?" → Weather Service; "Can I grow coconut here?" → Crop Recommendation Engine scoped to coconut; "Why are my leaves turning yellow?" → Disease Service + a clarifying question flow (crop stage, symptom detail) since this query is inherently under-specified from text alone — the module is designed to ask for a photo upload here once that capability exists.

## 16. Satellite Monitoring

Weekly NDVI/NDWI computation per active farm polygon (see [ARCHITECTURE.md §6](./ARCHITECTURE.md#6-gis--satellite-pipeline)); stress/growth-stage/flooding/drought flags derived from anomaly detection against the farm's own historical trend plus regional crop-type baselines, not absolute thresholds (a "stressed" reading is relative to what's normal for that farm/crop/season).

## 17. Alerts

Event-driven (Pub/Sub) — any service emitting a threshold-crossing event (rain forecast, disease risk spike, NDVI stress, harvest window, price spike) publishes an alert event; the Alerts Service dedupes, respects farmer-configured quiet hours/channel preference, and delivers via FCM push (primary) with SMS as a fallback channel for connectivity-constrained users.

## 18. Dashboard

A gateway-composed read (not its own data owner): farm summary, Land Health Score, weather snapshot, water resources, top crop recommendations, disease/pest risk summary, market prediction, expected profit/ROI, disaster risk — one API call fans out to the relevant services in parallel and returns a single composed payload, with per-section `confidence_score` so the UI can visually distinguish high- vs. low-confidence sections (this is the natural home for the traffic-light/score-card visual pattern).
