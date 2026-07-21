FROM python:3.12-slim

WORKDIR /app

COPY shared ./shared
COPY services/water ./services/water

RUN pip install --no-cache-dir -e ./shared \
    && pip install --no-cache-dir -r ./services/water/requirements.txt

WORKDIR /app/services/water
ENV PYTHONPATH=/app/services/water
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
