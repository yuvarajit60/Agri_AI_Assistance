"""Default confidence per land-identification method
(docs/architecture/MODULES.md §1) — used when a caller doesn't supply its
own (e.g. from a GIS-service-computed value)."""

DEFAULT_RESOLUTION_CONFIDENCE: dict[str, float] = {
    "country": 0.1,
    "region": 0.15,
    "state": 0.2,
    "district": 0.3,
    "city_village": 0.4,
    "survey_number": 0.75,
    "gps_coordinates": 0.6,
    "google_maps_location": 0.6,
    "drawn_boundary": 0.9,
    "uploaded_document": 0.5,
    "location_search": 0.45,
}
