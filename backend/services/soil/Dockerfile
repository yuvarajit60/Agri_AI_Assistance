FROM python:3.12-slim

WORKDIR /app

COPY shared ./shared
COPY services/soil ./services/soil

RUN pip install --no-cache-dir -e ./shared \
    && pip install --no-cache-dir -r ./services/soil/requirements.txt

WORKDIR /app/services/soil
ENV PYTHONPATH=/app/services/soil
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
