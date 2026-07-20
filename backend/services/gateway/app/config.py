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

REQUEST_TIMEOUT_SECONDS = float(os.environ.get("UPSTREAM_TIMEOUT_SECONDS", "10"))
