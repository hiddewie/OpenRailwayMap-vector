#!/bin/bash

set -e
set -o pipefail

echo "Updating materialized views"
psql -d gis -f sql/update_signals_with_azimuth.sql
psql -d gis -f sql/update_station_importance.sql
