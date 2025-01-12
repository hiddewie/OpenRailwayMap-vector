#!/bin/bash

set -e
set -o pipefail

INPUT_FILE="/data/${DATAFILE:-data.osm.pbf}"
echo "Using input file $INPUT_FILE"

for bbox in $BBOXES; do
  SPLIT_FILE="/data/split/$bbox/${DATAFILE:-data.osm.pbf}"
  echo "Processing bounding box $bbox into $SPLIT_FILE"

  mkdir -p "$(dirname "$SPLIT_FILE")"
  rm -f "$SPLIT_FILE"
  osmium extract --strategy=smart "--bbox=$bbox" "$INPUT_FILE" --output="$SPLIT_FILE"
done

echo "Done"
