FROM imresamu/postgis:18-3.6-alpine

COPY tune-postgis.sh /docker-entrypoint-initdb.d/tune-postgis.sh
COPY operators.sql /docker-entrypoint-initdb.d/operators.sql
COPY types.sql /docker-entrypoint-initdb.d/types.sql
