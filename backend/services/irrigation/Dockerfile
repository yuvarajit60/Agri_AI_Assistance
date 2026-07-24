FROM python:3.12-slim

WORKDIR /app

COPY shared ./shared
COPY services/irrigation ./services/irrigation

RUN pip install --no-cache-dir -e ./shared \
    && pip install --no-cache-dir -r ./services/irrigation/requirements.txt

WORKDIR /app/services/irrigation
ENV PYTHONPATH=/app/services/irrigation
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
