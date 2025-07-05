#!/usr/bin/env bash

set -e
set -o pipefail
set -u

echo 'Preparing API'

echo 'Preparing facility functions'
docker compose exec -T db psql \
  --host 127.0.0.1 \
  --user postgres \
  --port 5432 \
  --dbname gis \
  < api/facility_functions.sql

echo 'Preparing milestones functions'
docker compose exec -T db psql \
  --host 127.0.0.1 \
  --user postgres \
  --port 5432 \
  --dbname gis \
  < api/milestone_functions.sql

echo 'Preparing facilities'
docker compose exec -T db psql \
  --host 127.0.0.1 \
  --user postgres \
  --port 5432 \
  --dbname gis \
  < api/prepare_facilities.sql

echo 'Preparing milestones'
docker compose exec -T db psql \
  --host 127.0.0.1 \
  --user postgres \
  --port 5432 \
  --dbname gis \
  < api/prepare_milestones.sql

echo 'Extract API data from database'
docker compose exec db pg_dump \
  --host 127.0.0.1 \
  --user postgres \
  --port 5432 \
  --dbname gis \
  --table openrailwaymap_facilities_for_search \
  --table openrailwaymap_ref \
  --table openrailwaymap_milestones \
  --table openrailwaymap_tracks_with_ref \
  --table osm2pgsql_properties \
  > api/api.sql

echo 'Importing API data into Postgres container'
docker compose up --build --wait api-import
docker compose stop api-import
DB_CONTAINER_ID="$(docker compose ps --all --format json | jq -r 'select(.Service == "api-import") | .ID')"
# Persist and squash data in new image
docker cp "$DB_CONTAINER_ID:/var/lib/postgresql/postgres-data" api/postgres-data

echo 'Building API container'
docker compose build api

echo 'Cleaning up'
[ -n "${SKIP_CLEANUP:-}" ] || rm -rf api/postgres-data
[ -n "${SKIP_CLEANUP:-}" ] || rm -f api/api.sql
