#!/bin/sh

# This script is used to start the import of kosmtik containers for the Docker development environment.
# You can read details about that in SETUP.md

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

case "$1" in
import)
  # Creating default database
  psql -c "SELECT 1 FROM pg_database WHERE datname = 'gis';" | grep -q 1 || createdb gis && \
  psql -d gis -c 'CREATE EXTENSION IF NOT EXISTS postgis;' && \
  psql -d gis -c 'CREATE EXTENSION IF NOT EXISTS hstore;'

  # Creating default import settings file editable by user and passing values for osm2pgsql
  if [ ! -e ".env" ]; then
    cat > .env <<EOF
# Environment settings for importing to a Docker container database
PG_WORK_MEM=${PG_WORK_MEM:-16MB}
PG_MAINTENANCE_WORK_MEM=${PG_MAINTENANCE_WORK_MEM:-256MB}
OSM2PGSQL_CACHE=${OSM2PGSQL_CACHE:-512}
OSM2PGSQL_NUMPROC=${OSM2PGSQL_NUMPROC:-1}
OSM2PGSQL_DATAFILE=${OSM2PGSQL_DATAFILE:-data.osm.pbf}
EXTERNAL_DATA_SCRIPT_FLAGS=${EXTERNAL_DATA_SCRIPT_FLAGS:-}
EOF
    chmod a+rw .env
    export OSM2PGSQL_CACHE=${OSM2PGSQL_CACHE:-512}
    export OSM2PGSQL_NUMPROC=${OSM2PGSQL_NUMPROC:-1}
    export OSM2PGSQL_DATAFILE=${OSM2PGSQL_DATAFILE:-data.osm.pbf}
  fi

  osmium tags-filter \
    --output /tmp/filtered.osm.pbf \
    "$OSM2PGSQL_DATAFILE" \
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

  # Importing data to a database
  # --slim \
  osm2pgsql \
    --create \
    --database gis \
    --hstore \
    --merc \
    --style setup/openstreetmap-carto.style \
    --tag-transform setup/openstreetmap-carto.lua \
    --multi-geometry \
    --cache $OSM2PGSQL_CACHE \
    --number-processes $OSM2PGSQL_NUMPROC \
    /tmp/filtered.osm.pbf

  # Post processing imported data
  psql -d gis -f sql/functions.sql
  psql -d gis -f sql/osm_carto_views.sql
  psql -d gis -f sql/get_station_importance.sql
  psql -d gis -f sql/tile_views.sql
  ;;

kosmtik)
  # Creating default Kosmtik settings file
  if [ ! -e ".kosmtik-config.yml" ]; then
    cp /tmp/.kosmtik-config.yml .kosmtik-config.yml
  fi
  export KOSMTIK_CONFIGPATH=".kosmtik-config.yml"

  # Second argument is the kosmtik options
  shift
  # Starting Kosmtik
  exec kosmtik serve --host 0.0.0.0 "$@"
  # It needs Ctrl+C to be interrupted
  ;;

esac
