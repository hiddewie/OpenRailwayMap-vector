FROM node:22-alpine as build-lua

WORKDIR /build

RUN npm install yaml

RUN --mount=type=bind,source=import/tags.lua.js,target=tags.lua.js \
  --mount=type=bind,source=features/train_protection.yaml,target=train_protection.yaml \
  --mount=type=bind,source=features/signals_railway_signals.yaml,target=signals_railway_signals.yaml \
  node tags.lua.js \
    > /build/tags.lua

FROM node:22-alpine as build-signals

WORKDIR /build

RUN npm install yaml

RUN --mount=type=bind,source=import/sql/signals_with_azimuth.sql.js,target=signals_with_azimuth.sql.js \
  --mount=type=bind,source=features/signals_railway_signals.yaml,target=signals_railway_signals.yaml \
  node signals_with_azimuth.sql.js \
    > /build/signals_with_azimuth.sql

FROM debian:trixie-slim

# https://serverfault.com/questions/949991/how-to-install-tzdata-on-a-ubuntu-docker-image
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    osm2pgsql \
    osmium-tool \
    pyosmium \
    gdal-bin \
    python3-psycopg2 \
    python3-yaml \
    python3-requests \
    unzip \
    postgresql-client \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get clean

RUN mkdir -p /openrailwaymap
WORKDIR /openrailwaymap

COPY import/sql sql
COPY import/docker-startup.sh docker-startup.sh
COPY import/openrailwaymap.lua openrailwaymap.lua

COPY --from=build-lua \
  /build/tags.lua tags.lua

COPY --from=build-signals \
  /build/signals_with_azimuth.sql sql/signals_with_azimuth.sql

ENTRYPOINT ["/openrailwaymap/docker-startup.sh"]

# Empty command for adding arguments to the startup script
CMD []
