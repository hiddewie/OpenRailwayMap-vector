FROM node:24-alpine@sha256:d1b3b4da11eefd5941e7f0b9cf17783fc99d9c6fc34884a665f40a06dbdfc94f AS build-lua

WORKDIR /build

RUN npm install yaml

RUN --mount=type=bind,source=import/tags.lua.js,target=tags.lua.js \
  --mount=type=bind,source=features/train_protection.yaml,target=train_protection.yaml \
  --mount=type=bind,source=features/signals_railway_signals.yaml,target=signals_railway_signals.yaml \
  --mount=type=bind,source=features/poi.yaml,target=poi.yaml \
  --mount=type=bind,source=features/stations.yaml,target=stations.yaml \
  node tags.lua.js \
    > /build/tags.lua

FROM node:24-alpine@sha256:d1b3b4da11eefd5941e7f0b9cf17783fc99d9c6fc34884a665f40a06dbdfc94f AS build-signals

WORKDIR /build

RUN npm install yaml

RUN --mount=type=bind,source=import/sql/signal_features.sql.js,target=signal_features.sql.js \
  --mount=type=bind,source=features/signals_railway_signals.yaml,target=signals_railway_signals.yaml \
  --mount=type=bind,source=symbols,target=symbols \
  node signal_features.sql.js \
    > /build/signal_features.sql

FROM node:24-alpine@sha256:d1b3b4da11eefd5941e7f0b9cf17783fc99d9c6fc34884a665f40a06dbdfc94f AS build-operators

WORKDIR /build

RUN npm install yaml

RUN --mount=type=bind,source=import/sql/operators.sql.js,target=operators.sql.js \
  --mount=type=bind,source=features/operators.yaml,target=operators.yaml \
  node operators.sql.js \
    > /build/operators.sql

FROM debian:trixie-slim@sha256:cedb1ef40439206b673ee8b33a46a03a0c9fa90bf3732f54704f99cb061d2c5a AS test

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

CMD ["lua", "test/test_all.lua"]

FROM debian:trixie-slim@sha256:cedb1ef40439206b673ee8b33a46a03a0c9fa90bf3732f54704f99cb061d2c5a

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

COPY --from=build-operators \
  /build/operators.sql sql/operators.sql

ENTRYPOINT ["/openrailwaymap/docker-startup.sh"]

# Empty command for adding arguments to the startup script
CMD []
