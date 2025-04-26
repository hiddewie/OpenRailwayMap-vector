#!/usr/bin/env bash

set -e

export PGUSER="$POSTGRES_USER"

psql -c 'CREATE EXTENSION IF NOT EXISTS postgis;'
psql -c 'CREATE EXTENSION IF NOT EXISTS hstore;'
psql -c 'DROP EXTENSION IF EXISTS postgis_topology;'
psql -c 'DROP EXTENSION IF EXISTS postgis_tiger_geocoder;'
psql -c 'DROP EXTENSION IF EXISTS fuzzystrmatch;'

psql -d gis -f /sql/facility_functions.sql
psql -d gis -f /sql/milestone_functions.sql
psql -d gis -f /sql/import.sql
