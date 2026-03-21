FROM imresamu/postgis:18-3.6-alpine@sha256:1bb65bfdeaed8609b93f1d3bc8e2b2ec2d7d7e0fa54770f9f56db0c6c1fc982b

COPY tune-postgis.sh /docker-entrypoint-initdb.d/tune-postgis.sh
COPY operators.sql /docker-entrypoint-initdb.d/operators.sql
COPY types.sql /docker-entrypoint-initdb.d/types.sql
COPY extensions.sql /docker-entrypoint-initdb.d/extensions.sql

HEALTHCHECK --interval=5s --timeout=5s --retries=3 --start-period=1m --start-interval=1s \
  CMD ["psql", "-U", "postgres", "-d", "gis", "-c", "SELECT st_buffer(ST_SetSRID('POINT(0 0)'::GEOMETRY, 4326), 1)"]
