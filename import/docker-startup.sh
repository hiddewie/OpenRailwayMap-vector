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

echo "Using osm2psql cache ${OSM2PGSQL_CACHE:-256}MB, ${OSM2PGSQL_NUMPROC:-4} processes and data file ${OSM2PGSQL_DATAFILE:-data.osm.pbf}"

# Filter the data for more efficient import
# Store the filtered data for future use in the data directory
OSM2PGSQL_INPUT_FILE="/data/${OSM2PGSQL_DATAFILE:-data.osm.pbf}"
OSM2PGSQL_FILTERED_FILE="/data/filtered/${OSM2PGSQL_DATAFILE:-data.osm.pbf}"
echo "Filtering data from $OSM2PGSQL_INPUT_FILE to $OSM2PGSQL_FILTERED_FILE"
[[ -f "$OSM2PGSQL_FILTERED_FILE" ]] || \
  osmium tags-filter \
    -o "$OSM2PGSQL_FILTERED_FILE" \
    "$OSM2PGSQL_INPUT_FILE" \
    nwr/railway \
    nwr/disused:railway \
    nwr/abandoned:railway \
    nwr/razed:railway \
    nwr/construction:railway \
    nwr/proposed:railway \
    n/public_transport=stop_position \
    nwr/public_transport=platform \
    r/route=train \
    r/route=tram \
    r/route=light_rail \
    r/route=subway

#echo "Importing data"
## Importing data to a database
#osm2pgsql \
#  --create \
#  --database gis \
#  --slim \
#  --middle-database-format new \
#  --output flex \
#  --style openrailwaymap.lua \
#  --cache "${OSM2PGSQL_CACHE:-256}" \
#  --number-processes "${OSM2PGSQL_NUMPROC:-4}" \
#  "$OSM2PGSQL_FILTERED_FILE"
#
#osm2pgsql-replication init --database gis

echo "Updating data"
osm2pgsql-replication update --database gis -- \
  --slim \
  --output flex \
  --style openrailwaymap.lua \
  --cache "${OSM2PGSQL_CACHE:-256}" \
  --number-processes "${OSM2PGSQL_NUMPROC:-4}"

echo "Post processing imported data"
psql -d gis -f sql/functions.sql
psql -d gis -f sql/get_station_importance.sql
psql -d gis -f sql/signals_with_azimuth.sql
psql -d gis -f sql/tile_views.sql

echo "Vacuuming database"
psql -d gis -c "VACUUM FULL;"

echo "Import summary"
psql -d gis -c "select table_name as table, pg_size_pretty(pg_total_relation_size(quote_ident(table_name))) as size from information_schema.tables where table_schema = 'public' order by table_name;"
psql -d gis -c "select pg_size_pretty(sum(pg_total_relation_size(quote_ident(table_name)))) as total_size from information_schema.tables where table_schema = 'public';"
