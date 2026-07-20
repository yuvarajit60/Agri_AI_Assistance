FROM python:3.12-slim

WORKDIR /app

COPY shared ./shared
COPY services/farm_registry ./services/farm_registry

RUN pip install --no-cache-dir -e ./shared \
    && pip install --no-cache-dir -r ./services/farm_registry/requirements.txt

WORKDIR /app/services/farm_registry
ENV PYTHONPATH=/app/services/farm_registry
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
