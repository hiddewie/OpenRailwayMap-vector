--- Shared ---

CREATE OR REPLACE VIEW railway_line_high AS
    SELECT
        id,
        osm_id,
        way,
        way_length,
        railway,
        CASE
            WHEN railway = 'proposed' THEN COALESCE(proposed_railway, 'rail')
            WHEN railway = 'construction' THEN COALESCE(construction_railway, 'rail')
            WHEN railway = 'razed' THEN COALESCE(razed_railway, 'rail')
            WHEN railway = 'abandoned' THEN COALESCE(abandoned_railway, 'rail')
            WHEN railway = 'disused' THEN COALESCE(disused_railway, 'rail')
            WHEN railway = 'preserved' THEN COALESCE(preserved_railway, 'rail')
            ELSE railway
        END as feature,
        usage,
        service,
        highspeed,
        (tunnel IS NOT NULL AND tunnel != 'no') as tunnel,
        (bridge IS NOT NULL AND bridge != 'no') as bridge,
        CASE
            WHEN ref IS NOT NULL AND label_name IS NOT NULL THEN ref || ' ' || label_name
            ELSE COALESCE(ref, label_name)
        END AS standard_label,
        ref,
        track_ref,
        track_class,
        array_to_string(reporting_marks, ', ') as reporting_marks,
        preferred_direction,
        CASE
            WHEN railway = 'rail' AND usage IN ('tourism', 'military', 'test') AND service IS NULL THEN 400
            WHEN railway = 'rail' AND usage IS NULL AND service IS NULL THEN 400
            WHEN railway = 'rail' AND usage IS NULL AND service = 'siding' THEN 870
            WHEN railway = 'rail' AND usage IS NULL AND service = 'yard' THEN 860
            WHEN railway = 'rail' AND usage IS NULL AND service = 'spur' THEN 880
            WHEN railway = 'rail' AND usage IS NULL AND service = 'crossover' THEN 300
            WHEN railway = 'rail' AND usage = 'main' AND service IS NULL AND highspeed THEN 2000
            WHEN railway = 'rail' AND usage = 'main' AND service IS NULL THEN 1100
            WHEN railway = 'rail' AND usage = 'branch' AND service IS NULL THEN 1000
            WHEN railway = 'rail' AND usage = 'industrial' AND service IS NULL THEN 850
            WHEN railway = 'rail' AND usage = 'industrial' AND service IN ('siding', 'spur', 'yard', 'crossover') THEN 850
            WHEN railway IN ('preserved', 'construction') THEN 400
            WHEN railway = 'proposed' THEN 350
            WHEN railway = 'disused' THEN 300
            WHEN railway = 'abandoned' THEN 250
            WHEN railway = 'razed' THEN 200
            ELSE 50
        END AS rank,
        maxspeed,
        speed_label,
        train_protection_rank,
        train_protection,
        electrification_state,
        voltage,
        frequency,
        electrification_label,
        future_voltage,
        future_frequency,
        railway_to_int(gauge0) AS gaugeint0,
        gauge0,
        railway_to_int(gauge1) AS gaugeint1,
        gauge1,
        railway_to_int(gauge2) AS gaugeint2,
        gauge2,
        gauge_label,
        loading_gauge,
        array_to_string(operator, ', ') as operator
    FROM
        (SELECT
             id,
             osm_id,
             way,
             way_length,
             railway,
             usage,
             service,
             highspeed,
             reporting_marks,
             disused_railway,
             abandoned_railway,
             razed_railway,
             construction_railway,
             proposed_railway,
             preserved_railway,
             layer,
             bridge,
             tunnel,
             track_ref,
             track_class,
             ref,
             CASE
                 WHEN railway = 'abandoned' THEN railway_label_name(COALESCE(abandoned_name, name), tunnel, tunnel_name, bridge, bridge_name)
                 WHEN railway = 'razed' THEN railway_label_name(COALESCE(razed_name, name), tunnel, tunnel_name, bridge, bridge_name)
                 ELSE railway_label_name(name, tunnel, tunnel_name, bridge, bridge_name)
             END AS label_name,
             preferred_direction,
             maxspeed,
             speed_label,
             train_protection_rank,
             train_protection,
             electrification_state,
             voltage,
             frequency,
             railway_electrification_label(COALESCE(voltage, future_voltage), COALESCE(frequency, future_frequency)) AS electrification_label,
             future_voltage,
             future_frequency,
             gauges[1] AS gauge0,
             gauges[2] AS gauge1,
             gauges[3] AS gauge2,
             (select string_agg(gauge, ' | ') from unnest(gauges) as gauge where gauge ~ '^[0-9]+$') as gauge_label,
             loading_gauge,
             operator
         FROM railway_line
         WHERE railway IN ('rail', 'tram', 'light_rail', 'subway', 'narrow_gauge', 'disused', 'abandoned', 'razed', 'construction', 'proposed', 'preserved')
        ) AS r
    ORDER by
        layer,
        rank NULLS LAST,
        maxspeed NULLS FIRST;

CREATE OR REPLACE VIEW railway_line_med AS
    SELECT
        *
    FROM
        railway_line_high
    WHERE railway = 'rail' AND usage IN ('main', 'branch') AND service IS NULL;

CREATE OR REPLACE VIEW railway_line_low AS
    SELECT
        *
    FROM
        railway_line_high
    WHERE railway = 'rail' AND usage = 'main' AND service IS NULL;

--- Standard ---

CREATE OR REPLACE VIEW standard_railway_text_stations_low AS
  SELECT
    id,
    osm_id,
    center as way,
    railway_ref as label,
    uic_ref
  FROM stations_with_route_counts
  WHERE
    railway = 'station'
    AND railway_ref IS NOT NULL
    AND route_count >= 8
  ORDER BY
    route_count DESC NULLS LAST;

CREATE OR REPLACE VIEW standard_railway_text_stations_med AS
  SELECT
    id,
    osm_id,
    center as way,
    railway_ref as label,
    uic_ref
  FROM stations_with_route_counts
  WHERE
    railway = 'station'
    AND railway_ref IS NOT NULL
  ORDER BY
    route_count DESC NULLS LAST;

CREATE OR REPLACE VIEW standard_railway_text_stations AS
  SELECT
    id,
    osm_id,
    center as way,
    railway,
    station,
    railway_ref as label,
    name,
    CASE
      WHEN railway = 'station' AND station = 'light_rail' THEN 450
      WHEN railway = 'station' AND station = 'subway' THEN 400
      WHEN railway = 'station' THEN 800
      WHEN railway = 'halt' AND station = 'light_rail' THEN 500
      WHEN railway = 'halt' THEN 550
      WHEN railway = 'tram_stop' THEN 300
      WHEN railway = 'service_station' THEN 600
      WHEN railway = 'yard' THEN 700
      WHEN railway = 'junction' THEN 650
      WHEN railway = 'spur_junction' THEN 420
      WHEN railway = 'site' THEN 600
      WHEN railway = 'crossover' THEN 700
      ELSE 50
    END AS rank,
    count,
    uic_ref
  FROM stations_with_route_counts
  WHERE railway IN ('station', 'halt', 'service_station', 'yard', 'junction', 'spur_junction', 'crossover', 'site', 'tram_stop')
    AND name IS NOT NULL
  ORDER by rank DESC NULLS LAST, route_count DESC NULLS LAST;

CREATE OR REPLACE VIEW standard_railway_grouped_stations AS
  SELECT
    id,
    osm_id,
    buffered as way,
    railway,
    station,
    railway_ref as label,
    name,
    uic_ref
  FROM stations_with_route_counts
  WHERE railway IN ('station', 'halt', 'service_station', 'yard', 'junction', 'spur_junction', 'crossover', 'site', 'tram_stop');

CREATE OR REPLACE VIEW standard_railway_symbols AS
  SELECT
    id,
    osm_id,
    way,
    CASE
      WHEN railway = 'crossing' THEN 'general/crossing'
      WHEN railway = 'level_crossing' THEN
        CASE
          WHEN crossing_barrier AND crossing_light AND crossing_bell THEN 'general/level-crossing-barrier'
          WHEN crossing_light AND crossing_bell THEN 'general/level-crossing-light'
          ELSE 'general/level-crossing'
        END
      WHEN railway = 'phone' THEN 'general/phone'
      WHEN railway = 'tram_stop' THEN 'general/tram-stop'
      WHEN railway = 'border' THEN 'general/border'
      WHEN railway = 'owner_change' THEN 'general/owner-change'
      WHEN railway = 'lubricator' THEN 'general/lubricator'
      WHEN railway = 'fuel' THEN 'general/fuel'
      WHEN railway = 'sand_store' THEN 'general/sand_store'
      WHEN railway = 'aei' THEN 'general/aei'
      WHEN railway = 'buffer_stop' THEN 'general/buffer_stop'
      WHEN railway = 'derail' THEN 'general/derail'
      WHEN railway = 'defect_detector' THEN 'general/defect_detector'
      WHEN railway = 'hump_yard' THEN 'general/hump_yard'
      WHEN railway = 'loading_gauge' THEN 'general/loading_gauge'
      WHEN railway = 'preheating' THEN 'general/preheating'
      WHEN railway = 'compressed_air_supply' THEN 'general/compressed_air_supply'
      WHEN railway = 'waste_disposal' THEN 'general/waste_disposal'
      WHEN railway = 'coaling_facility' THEN 'general/coaling_facility'
      WHEN railway = 'wash' THEN 'general/wash'
      WHEN railway = 'water_tower' THEN 'general/water_tower'
      WHEN railway = 'water_crane' THEN 'general/water_crane'
      WHEN railway = 'radio' THEN
        CASE
          WHEN man_made IN ('mast', 'tower') THEN 'general/radio-mast'
          WHEN man_made = 'antenna' THEN 'general/radio-antenna'
        END
    END AS feature,
    CASE
      WHEN railway = 'crossing' THEN -1::int
      WHEN railway = 'tram_stop' THEN 1::int
      ELSE 0
    END AS priority
  FROM pois
  WHERE railway IN ('crossing', 'level_crossing', 'phone', 'tram_stop', 'border', 'owner_change', 'radio', 'lubricator', 'fuel', 'sand_store', 'coaling_facility', 'wash', 'water_tower', 'water_crane', 'waste_disposal', 'compressed_air_supply', 'preheating', 'loading_gauge', 'hump_yard', 'defect_detector', 'aei', 'buffer_stop', 'derail')
  ORDER BY priority DESC;

CREATE OR REPLACE VIEW railway_text_km AS
  SELECT
    id,
    osm_id,
    way,
    railway,
    pos,
    (railway_pos_decimal(pos) = '0') as zero,
    railway_pos_round(pos, 0)::text as pos_int
  FROM
    (SELECT
       id,
       osm_id,
       way,
       railway,
       COALESCE(railway_position, railway_pos_round(railway_position_exact, 1)::text) AS pos
     FROM railway_positions
    ) AS r
  WHERE pos IS NOT NULL
  ORDER by zero;

CREATE OR REPLACE VIEW standard_railway_switch_ref AS
  SELECT
    id,
    osm_id,
    way,
    railway,
    ref,
    railway_local_operated
  FROM railway_switches
  ORDER by char_length(ref);


--- Speed ---

CREATE OR REPLACE VIEW speed_railway_signals AS
  SELECT
    id,
    osm_id,
    way,
    speed_feature as feature,
    speed_feature_type as type,
    azimuth,
    (signal_direction = 'both') as direction_both,
    ref,
    deactivated,
    dominant_speed as speed
  FROM signals_with_azimuth
  WHERE railway = 'signal'
    AND speed_feature IS NOT NULL
  ORDER BY
    -- distant signals are less important, signals for slower speeds are more important
    ("railway:signal:speed_limit" IS NOT NULL) DESC NULLS FIRST,
    dominant_speed DESC NULLS FIRST;


--- Signals ---

CREATE OR REPLACE FUNCTION signals_signal_boxes(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
  RETURN (
    SELECT
      ST_AsMVT(tile, 'signals_signal_boxes', 4096, 'way')
    FROM (
      SELECT
        ST_AsMVTGeom(
          CASE
            WHEN z >= 14 THEN way
            ELSE center
          END,
          ST_TileEnvelope(z, x, y),
          4096, 64, true
        ) AS way,
        id,
        osm_id,
        feature,
        ref,
        name
      FROM boxes
      WHERE way && ST_TileEnvelope(z, x, y)
    ) as tile
    WHERE way IS NOT NULL
  );

-- Function metadata
DO $do$ BEGIN
  EXECUTE 'COMMENT ON FUNCTION signals_signal_boxes IS $tj$' || $$
  {
    "vector_layers": [
      {
        "id": "signals_signal_boxes",
        "fields": {
          "id": "integer",
          "osm_id": "integer",
          "feature": "string",
          "ref": "string",
          "name": "string"
        }
      }
    ]
  }
  $$::json || '$tj$';
END $do$;

CREATE OR REPLACE VIEW signals_railway_signals AS
  SELECT
    id,
    osm_id,
    way,
    railway,
    ref,
    ref_multiline,
    deactivated,
    signal_feature as feature,
    azimuth,
    (signal_direction = 'both') as direction_both
  FROM signals_with_azimuth
  WHERE signal_feature IS NOT NULL
  ORDER BY rank NULLS FIRST;

--- Electrification ---

CREATE OR REPLACE VIEW electrification_signals AS
  SELECT
    id,
    osm_id,
    way,
    electrification_feature as feature,
    azimuth,
    (signal_direction = 'both') as direction_both,
    ref,
    deactivated,
    voltage,
    frequency
  FROM signals_with_azimuth
  WHERE
    railway = 'signal'
    AND electrification_feature IS NOT NULL;
