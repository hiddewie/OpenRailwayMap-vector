FROM ghcr.io/baosystems/postgis:17-3.5 AS import

COPY api.sql /sql/import.sql
COPY facility_functions.sql /sql/facility_functions.sql
COPY milestone_functions.sql /sql/milestone_functions.sql
COPY init.sh /docker-entrypoint-initdb.d/20-init.sh

ENV POSTGRES_DB=gis
ENV POSTGRES_USER=postgres
ENV POSTGRES_HOST=127.0.0.1
ENV POSTGRES_HOST_AUTH_METHOD=trust
ENV PGDATA=/var/lib/postgresql/postgres-data

HEALTHCHECK CMD ["pg_isready", "--host", "localhost", "--user", "postgres", "--dbname", "gis", "--port", "5432"]

FROM ghcr.io/baosystems/postgis:17-3.5 AS runtime

RUN apk add --no-cache \
        curl \
        python3 \
        py3-pip \
    && python3 -m pip install --no-cache-dir --no-color --no-python-version-warning --disable-pip-version-check --break-system-packages \
        fastapi[standard] \
        asyncpg

WORKDIR /app
COPY openrailwaymap_api openrailwaymap_api
COPY api.py api.py
COPY start.sh start.sh

COPY postgres-data /var/lib/postgresql/postgres-data

ENV POSTGRES_DB=gis
ENV POSTGRES_USER=postgres
ENV POSTGRES_HOST=127.0.0.1
ENV POSTGRES_HOST_AUTH_METHOD=trust
ENV PGDATA=/var/lib/postgresql/postgres-data

HEALTHCHECK CMD ["curl", "--fail", "localhost:5000/api/status"]

CMD ["/app/start.sh"]
