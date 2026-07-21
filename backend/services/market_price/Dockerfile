FROM python:3.12-slim

WORKDIR /app

COPY shared ./shared
COPY services/market_price ./services/market_price

RUN pip install --no-cache-dir -e ./shared \
    && pip install --no-cache-dir -r ./services/market_price/requirements.txt

WORKDIR /app/services/market_price
ENV PYTHONPATH=/app/services/market_price
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
