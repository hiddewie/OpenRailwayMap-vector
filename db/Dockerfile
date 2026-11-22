# This image is a replacement for postgis/postgis, until issue https://github.com/postgis/docker-postgis/issues/216 is resolved.
# See .github/workflows/build-postgis.yml for the workflow that builds the image.
FROM ghcr.io/hiddewie/postgis:19rc1-3.7-alpine

USER root
RUN mkdir -p /data/postgresql && chown postgres:postgres /data/postgresql
USER postgres

COPY tune-postgis.sh /docker-entrypoint-initdb.d/tune-postgis.sh
COPY operators.sql /docker-entrypoint-initdb.d/operators.sql
COPY types.sql /docker-entrypoint-initdb.d/types.sql
COPY extensions.sql /docker-entrypoint-initdb.d/extensions.sql

HEALTHCHECK --interval=5s --timeout=5s --retries=3 --start-period=1m --start-interval=1s \
  CMD ["psql", "-h", "127.0.0.1", "-U", "postgres", "-d", "gis", "-c", "SELECT st_buffer(ST_SetSRID('POINT(0 0)'::GEOMETRY, 4326), 1)"]
