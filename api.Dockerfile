FROM node:22-alpine@sha256:e4bf2a82ad0a4037d28035ae71529873c069b13eb0455466ae0bc13363826e34 AS build-yaml

WORKDIR /build

RUN npm install yaml@2.8.1

FROM build-yaml AS build-features

RUN --mount=type=bind,source=api/features.mjs,target=features.mjs \
  --mount=type=bind,source=features,target=features \
  node /build/features.mjs \
    > /build/features.json

FROM python:3-alpine@sha256:dd4d2bd5b53d9b25a51da13addf2be586beebd5387e289e798e4083d94ca837a

RUN apk add --no-cache \
        curl \
    && python3 -m pip install --no-cache-dir --no-color --no-python-version-warning --disable-pip-version-check --break-system-packages \
        fastapi[standard] \
        asyncpg \
        httpx

WORKDIR /app
COPY --from=build-features /build/features.json static/features.json
COPY api/openrailwaymap_api openrailwaymap_api
COPY api/api.py api.py

HEALTHCHECK CMD ["curl", "--fail", "localhost:5000/api/status"]

CMD ["ash", "-c", "fastapi run api.py --port \"$PORT\" --host \"$HOST\""]
