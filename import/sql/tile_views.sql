--- Shared ---

CREATE OR REPLACE FUNCTION railway_line_high(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
RETURN (
  SELECT
    ST_AsMVT(tile, 'railway_line_high', 4096, 'way')
  FROM (
    -- TODO calculate labels in frontend
    SELECT
      id,
      osm_id,
      way,
      way_length,
      feature,
      state,
      usage,
      service,
      highspeed,
      tunnel,
      bridge,
      CASE
        WHEN ref IS NOT NULL AND name IS NOT NULL THEN ref || ' ' || name
        ELSE COALESCE(ref, name)
      END AS standard_label,
      ref,
      track_ref,
      track_class,
      array_to_string(reporting_marks, ', ') as reporting_marks,
      preferred_direction,
      rank,
      maxspeed,
      speed_label,
      train_protection_rank,
      train_protection,
      train_protection_construction_rank,
      train_protection_construction,
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
      array_to_string(operator, ', ') as operator,
      traffic_mode,
      radio,
      wikidata,
      wikimedia_commons,
      image,
      mapillary,
      wikipedia,
      note,
      description
    FROM (
      SELECT
        id,
        osm_id,
        ST_AsMVTGeom(
          way,
          ST_TileEnvelope(z, x, y),
          4096, 64, true
        ) as way,
        way_length,
        feature,
        state,
        usage,
        service,
        rank,
        highspeed,
        reporting_marks,
        layer,
        bridge,
        tunnel,
        track_ref,
        track_class,
        ref,
        name,
        preferred_direction,
        maxspeed,
        speed_label,
        train_protection_rank,
        train_protection,
        train_protection_construction_rank,
        train_protection_construction,
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
        operator,
        traffic_mode,
        radio,
        wikidata,
        wikimedia_commons,
        image,
        mapillary,
        wikipedia,
        note,
        description
      FROM railway_line
      WHERE
        way && ST_TileEnvelope(z, x, y)
        -- conditionally include features based on zoom level
        AND CASE
          WHEN z < 7 THEN
            state = 'present'
              AND service IS NULL
              AND (
                feature = 'rail' AND usage = 'main'
              )
          WHEN z < 8 THEN
            state = 'present'
              AND service IS NULL
              AND (
                feature = 'rail' AND usage IN ('main', 'branch')
              )
          WHEN z < 9 THEN
            state IN ('present', 'construction', 'proposed')
              AND service IS NULL
              AND (
                feature = 'rail' AND usage IN ('main', 'branch')
              )
          WHEN z < 10 THEN
            state IN ('present', 'construction', 'proposed')
              AND service IS NULL
              AND (
                feature = 'rail' AND usage IN ('main', 'branch', 'industrial')
                  OR (feature = 'light_rail' AND usage IN ('main', 'branch'))
              )
          WHEN z < 11 THEN
            state IN ('present', 'construction', 'proposed')
              AND service IS NULL
              AND (
                feature IN ('rail', 'narrow_gauge', 'light_rail', 'monorail', 'subway', 'tram')
              )
          WHEN z < 12 THEN
            (service IS NULL OR service IN ('spur', 'yard'))
              AND (
                feature IN ('rail', 'narrow_gauge', 'light_rail')
                  OR (feature IN ('monorail', 'subway', 'tram') AND service IS NULL)
              )
          ELSE
            true
        END
    ) AS r
    ORDER by
      layer,
      rank NULLS LAST,
      maxspeed NULLS FIRST
  ) as tile
  WHERE way IS NOT NULL
);

-- Function metadata
DO $do$ BEGIN
  EXECUTE 'COMMENT ON FUNCTION railway_line_high IS $tj$' || $$
  {
    "vector_layers": [
      {
        "id": "railway_line_high",
        "fields": {
          "id": "integer",
          "osm_id": "integer",
          "way_length": "number",
          "feature": "string",
          "state": "string",
          "usage": "string",
          "service": "string",
          "highspeed": "boolean",
          "preferred_direction": "string",
          "tunnel": "boolean",
          "bridge": "boolean",
          "ref": "string",
          "standard_label": "string",
          "track_ref": "string",
          "maxspeed": "number",
          "speed_label": "string",
          "train_protection": "string",
          "train_protection_rank": "integer",
          "train_protection_construction": "string",
          "train_protection_construction_rank": "integer",
          "electrification_state": "string",
          "frequency": "number",
          "voltage": "integer",
          "future_frequency": "number",
          "future_voltage": "integer",
          "electrification_label": "string",
          "gauge0": "string",
          "gaugeint0": "number",
          "gauge1": "string",
          "gaugeint1": "number",
          "gauge2": "string",
          "gaugeint2": "number",
          "gauge_label": "string",
          "loading_gauge": "string",
          "track_class": "string",
          "reporting_marks": "string",
          "operator": "string",
          "traffic_mode": "string",
          "radio": "string",
          "wikidata": "string",
          "wikimedia_commons": "string",
          "image": "string",
          "mapillary": "string",
          "wikipedia": "string",
          "note": "string",
          "description": "string"
        }
      }
    ]
  }
  $$::json || '$tj$';
END $do$;

--- Standard ---

CREATE OR REPLACE VIEW railway_text_stations AS
  SELECT
    id,
    nullif(array_to_string(osm_ids, U&'\001E'), '') as osm_id,
    center as way,
    railway_ref,
    feature,
    state,
    station,
    CASE
      WHEN route_count >= 20 AND railway_ref IS NOT NULL THEN 'large'
      WHEN route_count >= 8 THEN 'normal'
      ELSE 'small'
    END AS station_size,
    name,
    CASE
      WHEN state != 'present' THEN 100
      WHEN feature = 'station' AND station = 'light_rail' THEN 450
      WHEN feature = 'station' AND station = 'subway' THEN 400
      WHEN feature = 'station' THEN 800
      WHEN feature = 'halt' AND station = 'light_rail' THEN 500
      WHEN feature = 'halt' THEN 550
      WHEN feature = 'tram_stop' THEN 300
      WHEN feature = 'service_station' THEN 600
      WHEN feature = 'yard' THEN 700
      WHEN feature = 'junction' THEN 650
      WHEN feature = 'spur_junction' THEN 420
      WHEN feature = 'site' THEN 600
      WHEN feature = 'crossover' THEN 700
      ELSE 50
    END AS rank,
    uic_ref,
    route_count,
    count,
    nullif(array_to_string(wikidata, U&'\001E'), '') as wikidata,
    nullif(array_to_string(wikimedia_commons, U&'\001E'), '') as wikimedia_commons,
    nullif(array_to_string(image, U&'\001E'), '') as image,
    nullif(array_to_string(mapillary, U&'\001E'), '') as mapillary,
    nullif(array_to_string(wikipedia, U&'\001E'), '') as wikipedia,
    nullif(array_to_string(note, U&'\001E'), '') as note,
    nullif(array_to_string(description, U&'\001E'), '') as description
  FROM
    grouped_stations_with_route_count
  ORDER BY
    rank DESC NULLS LAST,
    route_count DESC NULLS LAST;

CREATE OR REPLACE VIEW standard_railway_text_stations_low AS
  SELECT
    way,
    id,
    osm_id,
    feature,
    state,
    station,
    station_size,
    railway_ref as label,
    name,
    uic_ref,
    wikidata,
    wikimedia_commons,
    image,
    mapillary,
    wikipedia,
    note,
    description
  FROM
    railway_text_stations
  WHERE
    feature = 'station'
    AND state = 'present'
    AND (station IS NULL OR station NOT IN ('light_rail', 'monorail', 'subway'))
    AND railway_ref IS NOT NULL
    AND route_count >= 20;

CREATE OR REPLACE VIEW standard_railway_text_stations_med AS
  SELECT
    way,
    id,
    osm_id,
    feature,
    state,
    station,
    station_size,
    railway_ref as label,
    name,
    uic_ref,
    wikidata,
    wikimedia_commons,
    image,
    mapillary,
    wikipedia,
    note,
    description
  FROM
    railway_text_stations
  WHERE
    feature = 'station'
    AND state = 'present'
    AND (station IS NULL OR station NOT IN ('light_rail', 'monorail', 'subway'))
    AND railway_ref IS NOT NULL
    AND route_count >= 8
  ORDER BY
    route_count DESC NULLS LAST;

CREATE OR REPLACE VIEW standard_railway_text_stations AS
  SELECT
    way,
    id,
    osm_id,
    feature,
    state,
    station,
    station_size,
    railway_ref as label,
    name,
    count,
    uic_ref,
    wikidata,
    wikimedia_commons,
    image,
    mapillary,
    wikipedia,
    note,
    description
  FROM
    railway_text_stations
  WHERE
    name IS NOT NULL;

CREATE OR REPLACE VIEW standard_railway_grouped_stations AS
  SELECT
    id,
    nullif(array_to_string(osm_ids, U&'\001E'), '') as osm_id,
    buffered as way,
    feature,
    state,
    station,
    railway_ref as label,
    name,
    uic_ref,
    nullif(array_to_string(wikidata, U&'\001E'), '') as wikidata,
    nullif(array_to_string(wikimedia_commons, U&'\001E'), '') as wikimedia_commons,
    nullif(array_to_string(image, U&'\001E'), '') as image,
    nullif(array_to_string(mapillary, U&'\001E'), '') as mapillary,
    nullif(array_to_string(wikipedia, U&'\001E'), '') as wikipedia,
    nullif(array_to_string(note, U&'\001E'), '') as note,
    nullif(array_to_string(description, U&'\001E'), '') as description
  FROM
    grouped_stations_with_route_count;

CREATE OR REPLACE FUNCTION standard_railway_symbols(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
RETURN (
  SELECT
    ST_AsMVT(tile, 'standard_railway_symbols', 4096, 'way')
  FROM (
    SELECT
      ST_AsMVTGeom(
        way,
        ST_TileEnvelope(z, x, y),
        4096, 64, true
      ) AS way,
      id,
      osm_id,
      osm_type,
      feature,
      ref,
      wikidata,
      wikimedia_commons,
      image,
      mapillary,
      wikipedia,
      note,
      description
    FROM pois
    WHERE way && ST_TileEnvelope(z, x, y)
      -- Tiles are generated from zoom 14 onwards
      AND (z >= 14 OR z >= minzoom)
    ORDER BY rank DESC
  ) as tile
  WHERE way IS NOT NULL
);

DO $do$ BEGIN
  EXECUTE 'COMMENT ON FUNCTION standard_railway_symbols IS $tj$' || $$
  {
    "vector_layers": [
      {
        "id": "standard_railway_symbols",
        "fields": {
          "id": "integer",
          "osm_id": "integer",
          "osm_type": "string",
          "feature": "string",
          "ref": "string",
          "minzoom": "integer",
          "wikidata": "string",
          "wikimedia_commons": "string",
          "image": "string",
          "mapillary": "string",
          "wikipedia": "string",
          "note": "string",
          "description": "string"
        }
      }
    ]
  }
  $$::json || '$tj$';
END $do$;

CREATE OR REPLACE VIEW railway_text_km AS
  SELECT
    id,
    osm_id,
    way,
    railway,
    pos,
    (railway_pos_decimal(pos) = '0') as zero,
    railway_pos_round(pos, 0)::text as pos_int,
    wikidata,
    wikimedia_commons,
    image,
    mapillary,
    wikipedia,
    note,
    description
  FROM (
    SELECT
      id,
      osm_id,
      way,
      railway,
      COALESCE(railway_position, railway_pos_round(railway_position_exact, 1)::text) AS pos,
      wikidata,
      wikimedia_commons,
      image,
      mapillary,
      wikipedia,
      note,
      description
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
    type,
    turnout_side,
    local_operated,
    resetting,
    wikidata,
    wikimedia_commons,
    image,
    mapillary,
    wikipedia,
    note,
    description
  FROM railway_switches
  ORDER by char_length(ref);

--- Electrification ---

CREATE OR REPLACE VIEW electrification_catenary AS
  SELECT
    id,
    osm_id,
    osm_type,
    way,
    ref,
    feature,
    railway_position_exact as position,
    structure,
    supporting,
    attachment,
    tensioning,
    insulator,
    note,
    description
  FROM catenary;

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
        osm_type,
        feature,
        ref,
        name,
        wikimedia_commons,
        image,
        mapillary,
        wikipedia,
        note,
        description
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
          "osm_type": "string",
          "feature": "string",
          "ref": "string",
          "name": "string",
          "wikidata": "string",
          "wikimedia_commons": "string",
          "image": "string",
          "mapillary": "string",
          "wikipedia": "string",
          "note": "string",
          "description": "string"
        }
      }
    ]
  }
  $$::json || '$tj$';
END $do$;
