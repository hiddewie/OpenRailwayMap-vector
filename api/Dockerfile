FROM python:3.13-alpine

RUN apk add --no-cache \
        curl \
    && python3 -m pip install --no-cache-dir --no-color --no-python-version-warning --disable-pip-version-check --break-system-packages \
        fastapi[standard] \
        asyncpg \
        httpx

WORKDIR /app
COPY openrailwaymap_api openrailwaymap_api
COPY api.py api.py

HEALTHCHECK CMD ["curl", "--fail", "localhost:5000/api/status"]

CMD ["ash", "-c", "fastapi run api.py --port \"$PORT\" --host \"$HOST\""]
