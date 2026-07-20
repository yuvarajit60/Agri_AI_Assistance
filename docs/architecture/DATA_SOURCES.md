# Data Sources & API Matrix

Legend — **Cost**: Free / Freemium / Paid · **Reliability**: how authoritative/stable the source is for India · **Fallback**: what the platform does when the source is unavailable or a location falls outside its coverage.

## Location, Boundary & Terrain

| Source | Used by | Provides | Auth | Cost | Fallback |
|---|---|---|---|---|---|
| Google Maps Platform (Geocoding, Places, Elevation, Maps SDK) | Land ID, GIS Service | Address→coordinates, place search, elevation, boundary drawing UI | API key | Paid (metered) | OpenStreetMap Nominatim for geocoding if quota exhausted |
| Google Earth Engine | GIS, Water, Soil, Satellite services | DEM/SRTM (elevation, slope), Sentinel-2/Landsat imagery, JRC Global Surface Water | Service account | Free (noncommercial)/Paid tier for commercial scale | Cache last computed terrain values |
| ISRO Bhuvan | GIS, Water, Satellite services | India-specific land use/land cover, cadastral overlays, high-res Indian satellite data | Registration required | Free | Fall back to GEE global datasets |
| Survey of India / State Revenue Dept (Bhu-Naksha, Dharani, etc., state-dependent) | Land ID (Survey Number method) | Cadastral survey number → plot boundary | Varies by state, often no public API | Free/restricted | Manual boundary draw if lookup unavailable |
| Copernicus / Sentinel Hub | Satellite Monitoring | Sentinel-1 (SAR, flood detection) & Sentinel-2 (optical) processed imagery | API key | Freemium | GEE as primary, Sentinel Hub for faster/processed access |

## Weather & Climate

| Source | Used by | Provides | Auth | Cost | Fallback |
|---|---|---|---|---|---|
| IMD (India Meteorological Department) / Mausam API | Weather, Disaster services | Authoritative Indian forecasts, cyclone/heatwave warnings | Varies (some public, some via NIC) | Free | OpenWeather as primary forecast source, IMD as ground-truth/warning layer |
| OpenWeather | Weather Service | Global historical + forecast (hourly/daily), UV index, current conditions | API key | Freemium | NASA POWER for historicals |
| NASA POWER | Weather, Disaster, Soil services | Long-term historical meteorological + solar data, ET reference inputs | Open, no key for basic use | Free | — (already the fallback) |
| NASA SMAP / MODIS | Soil, Disaster services | Soil moisture, drought indicators, land surface temperature | Earthdata login | Free | GEE-derived proxies |

## Soil & Land

| Source | Used by | Provides | Auth | Cost | Fallback |
|---|---|---|---|---|---|
| Soil Health Card (soilhealth.dac.gov.in) | Soil & Land Health Service | Govt-issued soil test results (NPK, pH, EC, OC, micronutrients) by location | Registration/data-sharing agreement (data availability varies by district) | Free | SoilGrids + satellite-estimated values, flagged `estimated: true`, with lab-test recommendation |
| SoilGrids (ISRIC) | Soil Service | Global modeled soil properties (texture, OC, pH) at 250m resolution | Open | Free | — |
| data.gov.in (Agriculture datasets) | Soil, Fertilizer, Scheme services | District-level agri statistics, fertilizer recommendation norms | API key (data.gov.in) | Free | — |

## Water Resources

| Source | Used by | Provides | Auth | Cost | Fallback |
|---|---|---|---|---|---|
| India-WRIS (Water Resources Information System) | Water Service | Rivers, canals, reservoirs, dams, water availability data | Public portal, limited API | Free | GEE JRC Global Surface Water for surface water body detection |
| Central Ground Water Board (CGWB) | Water Service | Groundwater level, borewell feasibility by district/block | Public reports, limited API | Free | Regional statistical priors by aquifer type |
| OpenStreetMap (Overpass API) | Water Service | Crowd-sourced waterways/ponds/wells as a supplementary layer | Open | Free | — |

## Market & Price

| Source | Used by | Provides | Auth | Cost | Fallback |
|---|---|---|---|---|---|
| Agmarknet | Market Price & Intelligence Service | Daily APMC mandi prices by commodity/market across India | Public data, scraping/CSV or data.gov.in API | Free | Last-known price + statistical trend projection, confidence lowered |
| data.gov.in Market APIs | Market Service | Structured access to APMC/commodity datasets | API key | Free | Agmarknet direct |
| FAOSTAT | Market Service | Global production/trade context for export-demand signals | Open | Free | — |
| e-NAM (National Agriculture Market) | Market Service | Electronic trading price/volume data | Public portal | Free | Agmarknet |

## Government Schemes

| Source | Used by | Provides | Auth | Cost | Fallback |
|---|---|---|---|---|---|
| PM-Kisan portal | Government Schemes Service | Eligibility & benefit info | Public info pages (no live API — curated + periodic refresh) | Free | Curated dataset, manually refreshed quarterly |
| PMFBY (crop insurance) | Schemes Service | Insurance scheme details, eligibility | Public info | Free | Curated dataset |
| State agriculture department portals | Schemes Service | State-specific subsidies/equipment schemes | Varies, mostly no API | Free | Curated dataset per state, refreshed on a schedule |

## LLM / AI

| Source | Used by | Provides | Auth | Cost |
|---|---|---|---|---|
| Claude API (Anthropic) | AI Advisor, AI Chat | Reasoning, summarization, natural-language Q&A, tool-calling orchestration | API key | Paid (metered) |
| Vertex AI | Crop/Disease/Pest/Market ML models | Training, batch/online prediction, model registry, feature store | GCP service account | Paid |

---

## Notes on reliability & the "never hallucinate" requirement

- Government sources (Soil Health Card, Agmarknet, IMD, scheme portals) frequently lack stable public APIs and have inconsistent district-level coverage. Where no live API exists, the platform ingests via **scheduled batch jobs** (scraping/CSV/bulk download where legally permitted) into our own store, and every value served carries an `as_of` timestamp — never presented as real-time when it isn't.
- Any time a service falls back to a modeled/estimated value instead of a live authoritative source, the response's `confidence_score` is reduced and `assumptions[]` states exactly what was estimated and why (per the [Standard Output Contract](./ARCHITECTURE.md#9-standard-output-contract)).
