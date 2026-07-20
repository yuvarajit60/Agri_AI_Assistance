FROM python:3.12-slim

WORKDIR /app

COPY shared ./shared
COPY services/gis ./services/gis

RUN pip install --no-cache-dir -e ./shared \
    && pip install --no-cache-dir -r ./services/gis/requirements.txt

WORKDIR /app/services/gis
ENV PYTHONPATH=/app/services/gis
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
