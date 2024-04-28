FROM ghcr.io/hiddewie/template:v0.4.1 as build-lua

WORKDIR /build

RUN --mount=type=bind,source=import/openrailwaymap.lua,target=openrailwaymap.lua.tmpl \
  --mount=type=bind,source=features/electrification_signals.yaml,target=electrification_signals.yaml \
  --mount=type=bind,source=features/speed_railway_signals.yaml,target=speed_railway_signals.yaml \
  --mount=type=bind,source=features/train_protection.yaml,target=train_protection.yaml \
  --mount=type=bind,source=features/signals_railway_signals.yaml,target=signals_railway_signals.yaml \
  cat electrification_signals.yaml speed_railway_signals.yaml train_protection.yaml signals_railway_signals.yaml \
    | template --configuration - --format yaml --template openrailwaymap.lua.tmpl \
    > /build/openrailwaymap.lua

FROM ghcr.io/hiddewie/template:v0.4.1 as build-tile-views

WORKDIR /build

RUN --mount=type=bind,source=import/sql/tile_views.sql,target=tile_views.sql.tmpl \
  --mount=type=bind,source=features/electrification_signals.yaml,target=electrification_signals.yaml \
  --mount=type=bind,source=features/signals_railway_signals.yaml,target=signals_railway_signals.yaml \
  --mount=type=bind,source=features/speed_railway_signals.yaml,target=speed_railway_signals.yaml \
  cat electrification_signals.yaml signals_railway_signals.yaml speed_railway_signals.yaml \
    | template --configuration - --format yaml --template tile_views.sql.tmpl \
    > /build/tile_views.sql

FROM debian:unstable-20240211-slim

# https://serverfault.com/questions/949991/how-to-install-tzdata-on-a-ubuntu-docker-image
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    osm2pgsql \
    osmium-tool \
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

COPY --from=build-lua \
  /build/openrailwaymap.lua openrailwaymap.lua

COPY --from=build-tile-views \
  /build/tile_views.sql sql/tile_views.sql

ENTRYPOINT ["/openrailwaymap/docker-startup.sh"]

# Empty command for adding arguments to the startup script
CMD []
