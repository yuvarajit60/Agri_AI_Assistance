FROM python:3.12-slim

WORKDIR /app

COPY shared ./shared
COPY services/fertilizer ./services/fertilizer

RUN pip install --no-cache-dir -e ./shared \
    && pip install --no-cache-dir -r ./services/fertilizer/requirements.txt

WORKDIR /app/services/fertilizer
ENV PYTHONPATH=/app/services/fertilizer
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
