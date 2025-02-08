#!/bin/bash

set -e
set -o pipefail

# Filter the data for more efficient import
# Store the filtered data for future use in the data directory
OSM2PGSQL_INPUT_FILE="/data/${OSM2PGSQL_DATAFILE:-data.osm.pbf}"
OSM2PGSQL_FILTERED_FILE="/data/filtered/${OSM2PGSQL_DATAFILE:-data.osm.pbf}"

PSQL="psql --dbname gis --variable ON_ERROR_STOP=on --pset pager=off"

if [[ ! -f "$OSM2PGSQL_FILTERED_FILE" ]]; then
  echo "Filtering data from $OSM2PGSQL_INPUT_FILE to $OSM2PGSQL_FILTERED_FILE"

  mkdir -p "$(dirname "$OSM2PGSQL_FILTERED_FILE")"

  osmium tags-filter \
    "$OSM2PGSQL_INPUT_FILE" \
    --output "$OSM2PGSQL_FILTERED_FILE" \
    --expressions osmium-tags-filter
fi

case "$1" in
import)

  echo "Creating default database"
  psql -c "SELECT 1 FROM pg_database WHERE datname = 'gis';" | grep -q 1 || createdb gis
  $PSQL -c 'CREATE EXTENSION IF NOT EXISTS postgis;'
  $PSQL -c 'CREATE EXTENSION IF NOT EXISTS hstore;'
  $PSQL -c 'DROP EXTENSION IF EXISTS postgis_topology;'
  $PSQL -c 'DROP EXTENSION IF EXISTS fuzzystrmatch;'
  $PSQL -c 'DROP EXTENSION IF EXISTS postgis_tiger_geocoder;'

  echo "Importing data (osm2psql cache ${OSM2PGSQL_CACHE:-256}MB, ${OSM2PGSQL_NUMPROC:-4} processes)"
  # Importing data to a database
  osm2pgsql \
    --create \
    --database gis \
    --slim \
    --output flex \
    --style openrailwaymap.lua \
    --cache "${OSM2PGSQL_CACHE:-256}" \
    --number-processes "${OSM2PGSQL_NUMPROC:-4}" \
    "$OSM2PGSQL_FILTERED_FILE"

  ;;

update)

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

  ;;

refresh)

  echo "Refreshing tables and views"

  ;;

*)

  echo "Invalid argument '$1'. Supported: import, update, refresh"
  exit 1

  ;;

esac

# Clear all tags from the Osm2Psql tables
$PSQL -c "update planet_osm_nodes set tags = null where tags is not null;"
$PSQL -c "update planet_osm_ways set tags = null where tags is not null;"
$PSQL -c "update planet_osm_rels set tags = null where tags is not null;"
# Remove platforms which are not near any railway line, and also not part of any railway route
$PSQL -c "delete from platforms p where not exists(select * from routes r where r.platform_ref_ids @> Array[-p.osm_id]) and not exists(select * from railway_line l where st_dwithin(p.way, l.way, 20));"

echo "Post processing imported data"
$PSQL -f sql/functions.sql
$PSQL -f sql/signals_with_azimuth.sql
$PSQL -f sql/get_station_importance.sql
$PSQL -f sql/tile_views.sql

case "$1" in
import)

  echo "Skipping updating of materialized views"

  ;;

update)

  # Fallthrough
  ;&

refresh)

  echo "Updating materialized views"
  $PSQL -f sql/update_signals_with_azimuth.sql
  $PSQL -f sql/update_station_importance.sql

  ;;

*)

  echo "Invalid argument '$1'. Supported: import, update, refresh"
  exit 1

  ;;

esac

echo "Vacuuming database"
$PSQL -c "VACUUM FULL;"

$PSQL --tuples-only -c "with bounds as (SELECT st_transform(st_setsrid(ST_Extent(way), 3857), 4326) as table_extent FROM railway_line) select '[[' || ST_XMin(table_extent) || ', ' || ST_YMin(table_extent) || '], [' || ST_XMax(table_extent) || ', ' || ST_YMax(table_extent) || ']]' from bounds;" > /data/import/bounds.json
echo "Import bounds: $(cat /data/import/bounds.json)"

echo "Database summary"
$PSQL -c "select concat(relname, ' (', relkind ,')') as name, pg_size_pretty(pg_table_size(oid)) as size from pg_class where relkind in ('m', 'r', 'i') and relname not like 'pg_%' order by pg_table_size(oid) desc;"
$PSQL -c "select pg_size_pretty(SUM(pg_table_size(oid))) as size from pg_class where relkind in ('m', 'r', 'i') and relname not like 'pg_%';"
