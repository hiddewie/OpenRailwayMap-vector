FROM imresamu/postgis:18-3.6-alpine@sha256:5603f164abe087bf3c3bf779f1e47a0e17ff197b594730c55e55bfd2d288f79a

COPY tune-postgis.sh /docker-entrypoint-initdb.d/tune-postgis.sh
COPY operators.sql /docker-entrypoint-initdb.d/operators.sql
COPY types.sql /docker-entrypoint-initdb.d/types.sql
COPY extensions.sql /docker-entrypoint-initdb.d/extensions.sql

HEALTHCHECK --interval=5s --timeout=5s --retries=3 --start-period=1m --start-interval=1s \
  CMD ["psql", "-h", "127.0.0.1", "-U", "postgres", "-d", "gis", "-c", "SELECT st_buffer(ST_SetSRID('POINT(0 0)'::GEOMETRY, 4326), 1)"]
