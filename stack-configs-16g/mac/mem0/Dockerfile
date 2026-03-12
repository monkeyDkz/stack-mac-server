FROM python:3.11-slim

RUN pip install --no-cache-dir "mem0ai[graph]" "fastapi" "uvicorn[standard]" "chromadb" "pyyaml" "kuzu"

COPY server.py /app/server.py
WORKDIR /app

EXPOSE 8050

CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8050"]
