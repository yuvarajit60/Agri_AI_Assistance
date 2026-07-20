FROM python:3.12-slim

WORKDIR /app

COPY shared ./shared
COPY services/weather ./services/weather

RUN pip install --no-cache-dir -e ./shared \
    && pip install --no-cache-dir -r ./services/weather/requirements.txt

WORKDIR /app/services/weather
ENV PYTHONPATH=/app/services/weather
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
