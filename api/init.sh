#!/usr/bin/env bash

set -e

export PGUSER="$POSTGRES_USER"

echo "Creating default database"
psql -c "SELECT 1 FROM pg_database WHERE datname = 'gis';" | grep -q 1 || createdb gis
psql -c 'CREATE EXTENSION IF NOT EXISTS postgis;'
psql -c 'CREATE EXTENSION IF NOT EXISTS hstore;'

psql -d gis -f /sql/import.sql
psql -d gis -f /sql/prepare_facilities.sql
psql -d gis -f /sql/prepare_milestones.sql
