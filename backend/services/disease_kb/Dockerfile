FROM python:3.12-slim

WORKDIR /app

COPY shared ./shared
COPY services/disease_kb ./services/disease_kb

RUN pip install --no-cache-dir -e ./shared \
    && pip install --no-cache-dir -r ./services/disease_kb/requirements.txt

WORKDIR /app/services/disease_kb
ENV PYTHONPATH=/app/services/disease_kb
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
