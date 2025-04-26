#!/bin/bash

set -e
set -o pipefail

# Filter the data for more efficient import
# Store the filtered data for future use in the data directory
OSM2PGSQL_INPUT_FILE="/data/${OSM2PGSQL_DATAFILE:-data.osm.pbf}"
OSM2PGSQL_FILTERED_FILE="/data/filtered/${OSM2PGSQL_DATAFILE:-data.osm.pbf}"

# For debugging, add --echo-queries
PSQL="psql --dbname gis --variable ON_ERROR_STOP=on --pset pager=off"

function filter_data() {
  if [[ ! -f "$OSM2PGSQL_FILTERED_FILE" ]]; then
    echo "Filtering data from $OSM2PGSQL_INPUT_FILE to $OSM2PGSQL_FILTERED_FILE"

    mkdir -p "$(dirname "$OSM2PGSQL_FILTERED_FILE")"

    osmium tags-filter \
      "$OSM2PGSQL_INPUT_FILE" \
      --output "$OSM2PGSQL_FILTERED_FILE" \
      --expressions osmium-tags-filter
  fi
}

function import_db() {
  $PSQL -c 'CREATE EXTENSION IF NOT EXISTS postgis;'
  $PSQL -c 'CREATE EXTENSION IF NOT EXISTS hstore;'
  $PSQL -c 'DROP EXTENSION IF EXISTS postgis_topology;'
  $PSQL -c 'DROP EXTENSION IF EXISTS postgis_tiger_geocoder;'
  $PSQL -c 'DROP EXTENSION IF EXISTS fuzzystrmatch;'

  echo "Importing data (${OSM2PGSQL_NUMPROC:-4} processes)"
  # Importing data to a database
  osm2pgsql \
    --create \
    --database gis \
    --drop \
    --output flex \
    --style openrailwaymap.lua \
    --number-processes "${OSM2PGSQL_NUMPROC:-4}" \
    "$OSM2PGSQL_FILTERED_FILE"
}

function update_datafile() {
  # This command may exit with non-zero exit codes
  #   in case there are more updates, or if no updates were performed
  # This uses the replication server as defined in the input file
  pyosmium-up-to-date \
    -v \
    --tmpdir /tmp \
    --force-update-of-old-planet \
    --size 10000 \
    -o "/tmp/data.osm.pbf" \
    "$OSM2PGSQL_FILTERED_FILE"  \
      || true

  [[ ! -f "/tmp/data.osm.pbf" ]] \
    || mv "/tmp/data.osm.pbf" "$OSM2PGSQL_FILTERED_FILE"

  # Ensure the data file is filtered to contain only interesting data
  osmium tags-filter \
    "$OSM2PGSQL_FILTERED_FILE" \
    --output "/tmp/data.osm.pbf" \
    --expressions osmium-tags-filter \
      && mv "/tmp/data.osm.pbf" "$OSM2PGSQL_FILTERED_FILE"
}

function reduce_data() {
  # Remove platforms which are not near any railway line, and also not part of any railway route
  $PSQL -c "delete from platforms p where not exists(select * from routes r where r.platform_ref_ids @> Array[p.osm_id]) and not exists(select * from railway_line l where st_dwithin(p.way, l.way, 20));"
}

function create_update_functions_views() {
  echo "Post processing imported data"
  $PSQL -f sql/functions.sql
  $PSQL -f sql/signals_with_azimuth.sql
  $PSQL -f sql/get_station_importance.sql
  $PSQL -f sql/tile_views.sql
}

function refresh_materialized_views() {
  echo "Updating materialized views"
  $PSQL -f sql/update_signals_with_azimuth.sql
  $PSQL -f sql/update_station_importance.sql
}

function print_summary() {
  echo "Database summary"
  $PSQL -c "select concat(relname, ' (', relkind ,')') as name, pg_size_pretty(pg_table_size(oid)) as size from pg_class where relkind in ('m', 'r', 'i') and relname not like 'pg_%' order by pg_table_size(oid) desc;"
  $PSQL -c "select pg_size_pretty(SUM(pg_table_size(oid))) as size from pg_class where relkind in ('m', 'r', 'i') and relname not like 'pg_%';"
}

case "$1" in
import)

  filter_data
  import_db
  reduce_data
  create_update_functions_views
  print_summary

  ;;

update)

  filter_data
  update_datafile

  ;;

refresh)

  create_update_functions_views
  refresh_materialized_views
  print_summary

  ;;

*)

  echo "Invalid argument '$1'. Supported: import, update, refresh"
  exit 1

  ;;

esac
