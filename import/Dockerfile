FROM node:22-alpine AS build-lua

WORKDIR /build

RUN npm install yaml

RUN --mount=type=bind,source=import/tags.lua.js,target=tags.lua.js \
  --mount=type=bind,source=features/train_protection.yaml,target=train_protection.yaml \
  --mount=type=bind,source=features/signals_railway_signals.yaml,target=signals_railway_signals.yaml \
  --mount=type=bind,source=features/poi.yaml,target=poi.yaml \
  node tags.lua.js \
    > /build/tags.lua

FROM node:22-alpine AS build-signals

WORKDIR /build

RUN npm install yaml

RUN --mount=type=bind,source=import/sql/signal_features.sql.js,target=signal_features.sql.js \
  --mount=type=bind,source=features/signals_railway_signals.yaml,target=signals_railway_signals.yaml \
  --mount=type=bind,source=symbols,target=symbols \
  node signal_features.sql.js \
    > /build/signal_features.sql

FROM debian:trixie-slim AS test

# https://serverfault.com/questions/949991/how-to-install-tzdata-on-a-ubuntu-docker-image
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    lua5.4 \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get clean

COPY --from=build-lua \
  /build/tags.lua tags.lua

COPY import/openrailwaymap.lua openrailwaymap.lua
COPY import/test test

CMD ["lua", "test/test_openrailwaymap.lua"]

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
COPY import/osmium-tags-filter osmium-tags-filter

RUN echo '\\timing' >> ~/.psqlrc

COPY --from=build-lua \
  /build/tags.lua tags.lua

COPY --from=build-signals \
  /build/signal_features.sql sql/signal_features.sql

ENTRYPOINT ["/openrailwaymap/docker-startup.sh"]

# Empty command for adding arguments to the startup script
CMD []
