FROM python:3-alpine@sha256:faee120f7885a06fcc9677922331391fa690d911c020abb9e8025ff3d908e510

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
