#!/usr/bin/env sh

# This script merges rendered tiles from several directories into a single MBTiles file.
# Documentation:
#  - https://maplibre.org/martin/martin-cp.html
#  - https://maplibre.org/martin/mbtiles-copy.html

set -e

OUTPUT_DIR="/tiles"
echo "Merging tiles into output directory $OUTPUT_DIR"

mkdir -p "$OUTPUT_DIR"

for name in railway_line_high standard_railway_text_stations_low standard_railway_text_stations_med high standard speed signals electrification; do
  output_file="$OUTPUT_DIR/$name.mbtiles"

  echo "Cleaning up existing tile file $output_file"
  rm -f "$output_file"

  for bbox in $BBOXES; do
    file="$OUTPUT_DIR/split/$bbox/$name.mbtiles"

    if [[ -f "$file" ]]; then
      echo "Copying $file into $output_file"
      mbtiles copy --on-duplicate override "$file" "$output_file"
    else
      echo "File $file does not exist, skipping."
    fi
  done

  if [[ -f "$output_file" ]]; then
    mbtiles summary "$output_file"
  fi
done

echo "Done"
