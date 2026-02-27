#!/usr/bin/env bash

set -eof pipefail

docker compose run --build -e OSM2PGSQL_DATAFILE=planet.osm.pbf import filter
rm -f data/filtered/data.osm.pbf
cp data/filtered/planet.osm.pbf data/filtered/data.osm.pbf
date +%s > data/import-date
docker compose build data
docker compose push data
