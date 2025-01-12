#!/bin/bash

set -e
set -o pipefail

INPUT_FILE="/data/${DATAFILE:-data.osm.pbf}"
echo "Using input file $INPUT_FILE"

FILTERED_INPUT_FILE="/data/filtered/${DATAFILE:-data.osm.pbf}"
echo "Filtering input file $INPUT_FILE into $FILTERED_INPUT_FILE"
[[ -f "$FILTERED_INPUT_FILE" ]] || \
  osmium tags-filter \
    -o "$FILTERED_INPUT_FILE" \
    "$INPUT_FILE" \
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

for bbox in $BBOXES; do
  SPLIT_FILE="/data/split/$bbox/${DATAFILE:-data.osm.pbf}"
  echo "Processing bounding box $bbox into $SPLIT_FILE"

  mkdir -p "$(dirname "$SPLIT_FILE")"
  rm -f "$SPLIT_FILE"
  osmium extract "--bbox=$bbox" "$FILTERED_INPUT_FILE" -o "$SPLIT_FILE"
done

echo "Done"
