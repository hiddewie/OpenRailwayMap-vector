FROM postgis/postgis:16-3.4-alpine as import

COPY api.sql /sql/import.sql
COPY init.sh /docker-entrypoint-initdb.d/20-init.sh

ENV POSTGRES_DB gis
ENV POSTGRES_HOST_AUTH_METHOD trust

HEALTHCHECK CMD ["pg_isready", "--host", "localhost", "--user", "postgres", "--dbname", "gis", "--port", "5432"]

FROM postgis/postgis:16-3.4-alpine as runtime

RUN apk add --no-cache \
    python3 \
    py3-pip \
    py3-werkzeug \
    py3-psycopg2

WORKDIR /app
COPY openrailwaymap_api openrailwaymap_api
COPY api.py api.py
COPY start.sh start.sh

COPY postgres-data /var/lib/postgresql/postgres-data

ENV POSTGRES_DB gis
ENV POSTGRES_HOST_AUTH_METHOD trust

CMD ["/app/start.sh"]
