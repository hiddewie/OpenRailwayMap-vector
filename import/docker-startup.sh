#!/bin/bash

set -e
set -o pipefail

case "$1" in
import)

  echo "Creating default database"
  psql -c "SELECT 1 FROM pg_database WHERE datname = 'gis';" | grep -q 1 || createdb gis
  psql -d gis -c 'CREATE EXTENSION IF NOT EXISTS postgis;'
  psql -d gis -c 'CREATE EXTENSION IF NOT EXISTS hstore;'

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

  echo "Importing data (osm2psql cache ${OSM2PGSQL_CACHE:-256}MB, ${OSM2PGSQL_NUMPROC:-4} processes)"
  # Importing data to a database
  osm2pgsql \
    --create \
    --database gis \
    --slim \
    --middle-database-format new \
    --output flex \
    --style openrailwaymap.lua \
    --cache "${OSM2PGSQL_CACHE:-256}" \
    --number-processes "${OSM2PGSQL_NUMPROC:-4}" \
    "$OSM2PGSQL_FILTERED_FILE"

  echo "Initializing replication configuration"
  osm2pgsql-replication init --database gis

  ;;

update)

  echo "Updating data (osm2psql cache ${OSM2PGSQL_CACHE:-256}MB, ${OSM2PGSQL_NUMPROC:-4} processes)"
  osm2pgsql-replication update \
    --database gis \
    -- \
    --slim \
    --output flex \
    --style openrailwaymap.lua \
    --cache "${OSM2PGSQL_CACHE:-256}" \
    --number-processes "${OSM2PGSQL_NUMPROC:-4}"

  ;;

*)

  echo "Invalid argument '$1'. Supported: import, update"
  exit 1

  ;;

esac

# Clear all tags from the Osm2Psql tables
psql -d gis -c "update planet_osm_nodes set tags = null where tags is not null;"
psql -d gis -c "update planet_osm_ways set tags = null where tags is not null;"
psql -d gis -c "update planet_osm_rels set tags = null where tags is not null;"

echo "Post processing imported data"
psql -d gis -f sql/functions.sql
psql -d gis -f sql/get_station_importance.sql
psql -d gis -f sql/signals_with_azimuth.sql
psql -d gis -f sql/tile_views.sql

echo "Updating materialized views"
psql -d gis -f sql/update_signals_with_azimuth.sql
psql -d gis -f sql/update_station_importance.sql

echo "Vacuuming database"
psql -d gis -c "VACUUM FULL;"

echo "Database summary"
psql -d gis -c "select table_name as table, pg_size_pretty(pg_total_relation_size(quote_ident(table_name))) as size from information_schema.tables where table_schema = 'public' order by table_name;"
psql -d gis -c "select pg_size_pretty(sum(pg_total_relation_size(quote_ident(table_name)))) as total_size from information_schema.tables where table_schema = 'public';"
