#!/usr/bin/env sh

# This script renders tiles from Martin sources to MBTiles files
# The zoom levels of the sources are taken into account to avoid outputting unused data into tiles
# Documentation:
#  - https://maplibre.org/martin/martin-cp.html
#  - httpshttps://maplibre.org/martin/mbtiles-copy.html

set -e

export MARTIN="martin-cp --config /config/configuration.yml --mbtiles-type flat --on-duplicate abort --skip-agg-tiles-hash --bbox=$BBOX"

if [ "$TILES" = "low-med" ]; then
  rm -f /tiles/railway_line_high.mbtiles
  $MARTIN --min-zoom 0 --max-zoom 7 --source railway_line_high --output-file /tiles/railway_line_high.mbtiles
  mbtiles summary /tiles/railway_line_high.mbtiles

  rm -f /tiles/standard_railway_text_stations_low.mbtiles
  $MARTIN --min-zoom 0 --max-zoom 6 --source standard_railway_text_stations_low --output-file /tiles/standard_railway_text_stations_low.mbtiles
  mbtiles summary /tiles/standard_railway_text_stations_low.mbtiles

  rm -f /tiles/standard_railway_text_stations_med.mbtiles
  $MARTIN --min-zoom 7 --max-zoom 7 --source standard_railway_text_stations_med --output-file /tiles/standard_railway_text_stations_med.mbtiles
  mbtiles summary /tiles/standard_railway_text_stations_med.mbtiles
fi

if [ "$TILES" = "high" ] || [ "$TILES" = "high8" ]; then
  rm -f /tiles/high8.mbtiles
  $MARTIN --min-zoom 8 --max-zoom 12 --source railway_line_high,railway_text_km --output-file /tiles/high8.mbtiles
  mbtiles summary /tiles/high8.mbtiles
fi

if [ "$TILES" = "high" ] || [ "$TILES" = "high13" ]; then
  rm -f /tiles/high13.mbtiles
  $MARTIN --min-zoom 13 --max-zoom 13 --source railway_line_high,railway_text_km --output-file /tiles/high13.mbtiles
  mbtiles summary /tiles/high13.mbtiles
fi


if [ "$TILES" = "high" ] || [ "$TILES" = "high14" ]; then
  rm -f /tiles/high14.mbtiles
  $MARTIN --min-zoom 14 --max-zoom 14 --source railway_line_high,railway_text_km --output-file /tiles/high14.mbtiles
  mbtiles summary /tiles/high14.mbtiles
fi

if [ "$TILES" = "high" ] || [ "$TILES" = "high-merge" ]; then
  [[ -f /tiles/high8.mbtiles ]] || (echo 'Tiles file /tiles/high8.mbtiles is missing'; exit 1)
  [[ -f /tiles/high13.mbtiles ]] || (echo 'Tiles file /tiles/high13.mbtiles is missing'; exit 1)
  [[ -f /tiles/high14.mbtiles ]] || (echo 'Tiles file /tiles/high14.mbtiles is missing'; exit 1)

  rm -f /tiles/high.mbtiles

  mbtiles copy --copy all --on-duplicate abort /tiles/high8.mbtiles "/tiles/high.mbtiles"
  mbtiles copy --copy tiles --on-duplicate abort /tiles/high13.mbtiles "/tiles/high.mbtiles"
  mbtiles copy --copy tiles --on-duplicate abort /tiles/high14.mbtiles "/tiles/high.mbtiles"

  mbtiles meta-set /tiles/high.mbtiles minzoom 8
  mbtiles meta-set /tiles/high.mbtiles maxzoom 14

  mbtiles summary /tiles/high.mbtiles

  rm -f /tiles/high8.mbtiles
  rm -f /tiles/high13.mbtiles
  rm -f /tiles/high14.mbtiles
fi

if [ "$TILES" = "standard" ]; then
  rm -f /tiles/standard.mbtiles
  $MARTIN --min-zoom 8 --max-zoom "$MAX_ZOOM" --source standard_railway_turntables,standard_railway_text_stations,standard_railway_grouped_stations,standard_railway_symbols,standard_railway_switch_ref --output-file /tiles/standard.mbtiles
  mbtiles summary /tiles/standard.mbtiles
fi

if [ "$TILES" = "speed" ]; then
  rm -f /tiles/speed.mbtiles
  $MARTIN --min-zoom 8 --max-zoom "$MAX_ZOOM" --source speed_railway_signals --output-file /tiles/speed.mbtiles
  mbtiles summary /tiles/speed.mbtiles
fi

if [ "$TILES" = "signals" ]; then
  rm -f /tiles/signals.mbtiles
  $MARTIN --min-zoom 8 --max-zoom "$MAX_ZOOM" --source signals_railway_signals,signals_signal_boxes --output-file /tiles/signals.mbtiles
  mbtiles summary /tiles/signals.mbtiles
fi

if [ "$TILES" = "electrification" ]; then
  rm -f /tiles/electrification.mbtiles
  $MARTIN --min-zoom 8 --max-zoom "$MAX_ZOOM" --source electrification_signals --output-file /tiles/electrification.mbtiles
  mbtiles summary /tiles/electrification.mbtiles
fi
