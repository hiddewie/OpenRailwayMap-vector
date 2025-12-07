FROM imresamu/postgis:18-3.6-alpine

COPY tune-postgis.sh /docker-entrypoint-initdb.d/tune-postgis.sh
COPY operators.sql /docker-entrypoint-initdb.d/operators.sql
COPY types.sql /docker-entrypoint-initdb.d/types.sql

HEALTHCHECK --interval=5s --timeout=5s --retries=3 --start-period=1m --start-interval=1s \
  CMD ["psql", "-U", "postgres", "-d", "gis", "-c", "SELECT st_buffer(ST_SetSRID('POINT(0 0)'::GEOMETRY, 4326), 1)"]
