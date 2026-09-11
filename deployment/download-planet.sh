#!/usr/bin/env bash

set -eof pipefail

wget -O data/planet.osm.pbf https://ftp.snt.utwente.nl/pub/misc/openstreetmap/planet-latest.osm.pbf
rm -f data/filtered/planet.osm.pbf
rm -f data/filtered/planet.osm.pbf.timestamp
