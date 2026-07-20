FROM python:3.12-slim

WORKDIR /app

COPY shared ./shared
COPY services/gateway ./services/gateway

RUN pip install --no-cache-dir -e ./shared \
    && pip install --no-cache-dir -r ./services/gateway/requirements.txt

WORKDIR /app/services/gateway
ENV PYTHONPATH=/app/services/gateway
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
