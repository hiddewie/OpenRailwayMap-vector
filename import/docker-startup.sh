#!/bin/bash

set -e
set -o pipefail

# Testing if database is ready
i=1
MAXCOUNT=60
echo "Waiting for PostgreSQL to be running"
while [ $i -le $MAXCOUNT ]
do
  pg_isready -q && echo "PostgreSQL running" && break
  sleep 2
  i=$((i+1))
done
test $i -gt $MAXCOUNT && echo "Timeout while waiting for PostgreSQL to be running"

echo "Creating default database"
psql -c "SELECT 1 FROM pg_database WHERE datname = 'gis';" | grep -q 1 || createdb gis
psql -d gis -c 'CREATE EXTENSION IF NOT EXISTS postgis;'
psql -d gis -c 'CREATE EXTENSION IF NOT EXISTS hstore;'

echo "Using osm2psql cache ${OSM2PGSQL_CACHE}MB, ${OSM2PGSQL_NUMPROC} processes and data file ${OSM2PGSQL_DATAFILE}"

echo "Importing data"
# Importing data to a database
osm2pgsql \
  --create \
  --database gis \
  --hstore \
  --slim \
  --merc \
  --output flex \
  --style openrailwaymap.lua \
  --multi-geometry \
  --cache $OSM2PGSQL_CACHE \
  --number-processes $OSM2PGSQL_NUMPROC \
  "/data/${OSM2PGSQL_DATAFILE}"

echo "Post processing imported data"
psql -d gis -f sql/functions.sql
psql -d gis -f sql/osm_carto_views.sql
psql -d gis -f sql/get_station_importance.sql
psql -d gis -f sql/tile_views.sql
