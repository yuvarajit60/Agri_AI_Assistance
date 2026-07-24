import os


def _service_url(env_key: str, default_port: int) -> str:
    """Render's private-network service discovery (fromService: hostport)
    injects a bare 'host:port' with no scheme, while local dev's .env uses
    full 'http://localhost:PORT' URLs. Accept either."""
    value = os.environ.get(env_key, f"localhost:{default_port}")
    return value if value.startswith("http://") or value.startswith("https://") else f"http://{value}"


SOIL_SERVICE_URL = _service_url("SOIL_SERVICE_URL", 8003)
WEATHER_SERVICE_URL = _service_url("WEATHER_SERVICE_URL", 8002)
CROP_SERVICE_URL = _service_url("CROP_SERVICE_URL", 8001)
GIS_SERVICE_URL = _service_url("GIS_SERVICE_URL", 8004)
FARM_REGISTRY_URL = _service_url("FARM_REGISTRY_URL", 8005)
DISEASE_KB_SERVICE_URL = _service_url("DISEASE_KB_SERVICE_URL", 8006)
WATER_SERVICE_URL = _service_url("WATER_SERVICE_URL", 8007)
MARKET_SERVICE_URL = _service_url("MARKET_SERVICE_URL", 8008)
FERTILIZER_SERVICE_URL = _service_url("FERTILIZER_SERVICE_URL", 8009)
IRRIGATION_SERVICE_URL = _service_url("IRRIGATION_SERVICE_URL", 8010)

# Free-tier Render services spin down after ~15 min idle and take 12-22s
# to wake on the next request (observed directly) — a 10s upstream timeout
# gives up before a cold start finishes, degrading a dashboard that would
# have succeeded a few seconds later.
REQUEST_TIMEOUT_SECONDS = float(os.environ.get("UPSTREAM_TIMEOUT_SECONDS", "30"))
