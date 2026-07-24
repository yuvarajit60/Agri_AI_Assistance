FROM python:3.12-slim

WORKDIR /app

COPY shared ./shared
COPY services/ai_chat ./services/ai_chat

RUN pip install --no-cache-dir -e ./shared \
    && pip install --no-cache-dir -r ./services/ai_chat/requirements.txt

WORKDIR /app/services/ai_chat
ENV PYTHONPATH=/app/services/ai_chat
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
