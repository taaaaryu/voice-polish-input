FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .
COPY templates ./templates

ENV VOICE_POLISH_STATE_PATH=/data/state.json
ENV FLASK_RUN_HOST=0.0.0.0
ENV FLASK_RUN_PORT=8765

CMD ["python", "app.py"]

