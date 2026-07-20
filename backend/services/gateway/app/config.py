import os

SOIL_SERVICE_URL = os.environ.get("SOIL_SERVICE_URL", "http://localhost:8003")
WEATHER_SERVICE_URL = os.environ.get("WEATHER_SERVICE_URL", "http://localhost:8002")
CROP_SERVICE_URL = os.environ.get("CROP_SERVICE_URL", "http://localhost:8001")
GIS_SERVICE_URL = os.environ.get("GIS_SERVICE_URL", "http://localhost:8004")
FARM_REGISTRY_URL = os.environ.get("FARM_REGISTRY_URL", "http://localhost:8005")
DISEASE_KB_SERVICE_URL = os.environ.get("DISEASE_KB_SERVICE_URL", "http://localhost:8006")

REQUEST_TIMEOUT_SECONDS = float(os.environ.get("UPSTREAM_TIMEOUT_SECONDS", "10"))
