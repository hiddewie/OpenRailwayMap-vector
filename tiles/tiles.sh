#!/usr/bin/env sh

# This script renders tiles from Martin sources to MBTiles files
# The zoom levels of the sources are taken into account to avoid outputting unused data into tiles
# Documentation:
#  - https://maplibre.org/martin/martin-cp.html
#  - https://maplibre.org/martin/mbtiles-copy.html

# Input variables:
#  - BBOX: the bounding box of the region to generate
#  - TILES: generate only the low/medium zoom tiles if the value is "low-med", and only the high zoom tiles if the value is "high". Otherwise, generate everything

set -e

OUTPUT_DIR="/tiles"
echo "Exporting tiles for bounding box $BBOX into output directory $OUTPUT_DIR. Replication timestamp: ${REPLICATION_TIMESTAMP:-unknown}."

export MARTIN="martin-cp --config /config/configuration.yml --mbtiles-type flat --on-duplicate abort --skip-agg-tiles-hash --bbox=$BBOX"

mkdir -p "$OUTPUT_DIR"

if [[ "${TILES}" != 'high' ]]; then
  echo "Tiles: low-med"

  rm -f "$OUTPUT_DIR/railway_line_high.mbtiles"
  $MARTIN --min-zoom 0 --max-zoom 7 --source railway_line_high --output-file "$OUTPUT_DIR/railway_line_high.mbtiles"
  mbtiles meta-set "$OUTPUT_DIR/railway_line_high.mbtiles" replication_timestamp "$REPLICATION_TIMESTAMP"
  mbtiles summary "$OUTPUT_DIR/railway_line_high.mbtiles"

  rm -f "$OUTPUT_DIR/standard_railway_text_stations_low.mbtiles"
  $MARTIN --min-zoom 0 --max-zoom 6 --source standard_railway_text_stations_low --output-file "$OUTPUT_DIR/standard_railway_text_stations_low.mbtiles"
  mbtiles meta-set "$OUTPUT_DIR/standard_railway_text_stations_low.mbtiles" replication_timestamp "$REPLICATION_TIMESTAMP"
  mbtiles summary "$OUTPUT_DIR/standard_railway_text_stations_low.mbtiles"

  rm -f "$OUTPUT_DIR/standard_railway_text_stations_med.mbtiles"
  $MARTIN --min-zoom 7 --max-zoom 7 --source standard_railway_text_stations_med --output-file "$OUTPUT_DIR/standard_railway_text_stations_med.mbtiles"
  mbtiles meta-set "$OUTPUT_DIR/standard_railway_text_stations_med.mbtiles" replication_timestamp "$REPLICATION_TIMESTAMP"
  mbtiles summary "$OUTPUT_DIR/standard_railway_text_stations_med.mbtiles"
fi

if [[ "${TILES}" != 'low-med' ]]; then
  echo "Tiles: high"

  rm -f "$OUTPUT_DIR/high.mbtiles"
  $MARTIN --min-zoom 8 --max-zoom "$MAX_ZOOM" --source railway_line_high,railway_text_km --output-file "$OUTPUT_DIR/high.mbtiles"
  mbtiles meta-set "$OUTPUT_DIR/high.mbtiles" replication_timestamp "$REPLICATION_TIMESTAMP"
  mbtiles summary "$OUTPUT_DIR/high.mbtiles"

  echo "Tiles: standard"

  rm -f "$OUTPUT_DIR/standard.mbtiles"
  $MARTIN --min-zoom 8 --max-zoom "$MAX_ZOOM" --source standard_railway_turntables,standard_railway_text_stations,standard_railway_grouped_stations,standard_railway_symbols,standard_railway_switch_ref --output-file "$OUTPUT_DIR/standard.mbtiles"
  mbtiles meta-set "$OUTPUT_DIR/standard.mbtiles" replication_timestamp "$REPLICATION_TIMESTAMP"
  mbtiles summary "$OUTPUT_DIR/standard.mbtiles"

  echo "Tiles: speed"

  rm -f "$OUTPUT_DIR/speed.mbtiles"
  $MARTIN --min-zoom 13 --max-zoom "$MAX_ZOOM" --source speed_railway_signals --output-file "$OUTPUT_DIR/speed.mbtiles"
  mbtiles meta-set "$OUTPUT_DIR/speed.mbtiles" replication_timestamp "$REPLICATION_TIMESTAMP"
  mbtiles summary "$OUTPUT_DIR/speed.mbtiles"

  echo "Tiles: signals"

  rm -f "$OUTPUT_DIR/signals.mbtiles"
  $MARTIN --min-zoom 10 --max-zoom "$MAX_ZOOM" --source signals_railway_signals,signals_signal_boxes --output-file "$OUTPUT_DIR/signals.mbtiles"
  mbtiles meta-set "$OUTPUT_DIR/signals.mbtiles" replication_timestamp "$REPLICATION_TIMESTAMP"
  mbtiles summary "$OUTPUT_DIR/signals.mbtiles"

  echo "Tiles: electrification"

  rm -f "$OUTPUT_DIR/electrification.mbtiles"
  $MARTIN --min-zoom 13 --max-zoom "$MAX_ZOOM" --source electrification_signals,catenary --output-file "$OUTPUT_DIR/electrification.mbtiles"
  mbtiles meta-set "$OUTPUT_DIR/electrification.mbtiles" replication_timestamp "$REPLICATION_TIMESTAMP"
  mbtiles summary "$OUTPUT_DIR/electrification.mbtiles"
fi

echo "Done"
