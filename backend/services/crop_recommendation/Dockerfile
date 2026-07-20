FROM python:3.12-slim

WORKDIR /app

COPY shared ./shared
COPY services/crop_recommendation ./services/crop_recommendation

RUN pip install --no-cache-dir -e ./shared \
    && pip install --no-cache-dir -r ./services/crop_recommendation/requirements.txt

WORKDIR /app/services/crop_recommendation
ENV PYTHONPATH=/app/services/crop_recommendation
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
