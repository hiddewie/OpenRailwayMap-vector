#!/bin/bash

set -e
set -o pipefail

DATAFILE="/data/${DATAFILE:-data.osm.pbf}"

echo "Updating data file $DATAFILE within bounding box $BBOX"
pyosmium-up-to-date "$DATAFILE"

# Ensure the data is constrained to the bounding box after update
osmium extract "--bbox=$BBOX" "$DATAFILE" -o "/tmp/filtered.osm.pbf" \
  && mv /tmp/filtered.osm.pbf "$DATAFILE"

echo "Done"
