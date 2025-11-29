--- Shared ---

CREATE OR REPLACE FUNCTION railway_line_high(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
RETURN (
  SELECT
    ST_AsMVT(tile, 'railway_line_high', 4096, 'way', 'id')
  FROM (
    -- TODO calculate labels in frontend
    SELECT
      id,
      osm_id,
      ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
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
      operator,
      get_byte(sha256(primary_operator::bytea), 0) as operator_hash,
      primary_operator,
      owner,
      traffic_mode,
      radio,
      wikidata,
      wikimedia_commons,
      wikimedia_commons_file,
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
        array_to_string(operator, U&'\\001E') as operator,
        owner,
        CASE
          WHEN ARRAY[owner] <@ operator THEN owner
          ELSE operator[1]
        END AS primary_operator,
        traffic_mode,
        radio,
        wikidata,
        wikimedia_commons,
        wikimedia_commons_file,
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
          -- Zooms < 7 are handled in the low zoom tiles
          WHEN z < 8 THEN
            state = 'present'
              AND service IS NULL
              AND (
                feature IN ('rail', 'ferry') AND usage IN ('main', 'branch')
              )
          WHEN z < 9 THEN
            state IN ('present', 'construction', 'proposed')
              AND service IS NULL
              AND (
                feature IN ('rail', 'ferry') AND usage IN ('main', 'branch')
              )
          WHEN z < 10 THEN
            state IN ('present', 'construction', 'proposed')
              AND service IS NULL
              AND (
                feature IN ('rail', 'ferry') AND usage IN ('main', 'branch', 'industrial')
                  OR (feature = 'light_rail' AND usage IN ('main', 'branch'))
              )
          WHEN z < 11 THEN
            state IN ('present', 'construction', 'proposed')
              AND service IS NULL
              AND (
                feature IN ('rail', 'ferry', 'narrow_gauge', 'light_rail', 'monorail', 'subway', 'tram')
              )
          WHEN z < 12 THEN
            (service IS NULL OR service IN ('spur', 'yard'))
              AND (
                feature IN ('rail', 'ferry', 'narrow_gauge', 'light_rail')
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
          "operator_hash": "number",
          "primary_operator": "string",
          "owner": "string",
          "traffic_mode": "string",
          "radio": "string",
          "wikidata": "string",
          "wikimedia_commons": "string",
          "wikimedia_commons_file": "string",
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

-- Reusable view for low railway line tiles, grouped per layer
CREATE OR REPLACE VIEW railway_line_low AS
  SELECT
    id,
    way,
    feature,
    state,
    usage,
    highspeed,
    ref,
    CASE
      WHEN ref IS NOT NULL AND name IS NOT NULL THEN ref || ' ' || name
      ELSE COALESCE(ref, name)
    END AS standard_label,
    speed_label,
    maxspeed,
    train_protection_rank,
    train_protection,
    train_protection_construction_rank,
    train_protection_construction,
    electrification_state,
    railway_electrification_label(COALESCE(voltage, future_voltage), COALESCE(frequency, future_frequency)) AS electrification_label,
    voltage,
    frequency,
    railway_to_int(gauges[1]) AS gaugeint0,
    gauges[1] as gauge0,
    (select string_agg(gauge, ' | ') from unnest(gauges) as gauge where gauge ~ '^[0-9]+$') as gauge_label,
    loading_gauge,
    track_class,
    operator,
    get_byte(sha256(primary_operator::bytea), 0) as operator_hash,
    primary_operator,
    owner,
    rank
  FROM (
    SELECT
      *,
      CASE
        WHEN ARRAY[owner] <@ operator THEN owner
        ELSE operator[1]
      END AS primary_operator
    from railway_line
  ) as r
  WHERE
    state = 'present'
      AND feature IN ('rail', 'ferry')
      AND usage = 'main'
      AND service IS NULL;

--- Standard ---

CREATE OR REPLACE FUNCTION standard_railway_line_low(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
RETURN (
  SELECT
    ST_AsMVT(tile, 'standard_railway_line_low', 4096, 'way', 'id')
  FROM (
    SELECT
      min(id) as id,
      ST_AsMVTGeom(
        st_simplify(st_collect(way), 100000),
        ST_TileEnvelope(z, x, y),
        4096, 64, true
      ) as way,
      feature,
      any_value(state) as state,
      any_value(usage) as usage,
      highspeed,
      ref,
      standard_label,
      max(rank) as rank
    FROM railway_line_low
    WHERE way && ST_TileEnvelope(z, x, y)
    GROUP BY
      feature,
      ref,
      standard_label,
      highspeed
    ORDER by
      rank NULLS LAST
  ) as tile
  WHERE way IS NOT NULL
);

DO $do$ BEGIN
  EXECUTE 'COMMENT ON FUNCTION standard_railway_line_low IS $tj$' || $$
  {
    "vector_layers": [
      {
        "id": "standard_railway_line_low",
        "fields": {
          "id": "integer",
          "feature": "string",
          "state": "string",
          "usage": "string",
          "highspeed": "boolean",
          "tunnel": "boolean",
          "bridge": "boolean",
          "ref": "string",
          "standard_label": "string"
        }
      }
    ]
  }
  $$::json || '$tj$';
END $do$;

CREATE OR REPLACE VIEW railway_text_stations AS
  SELECT
    id,
    nullif(array_to_string(osm_ids, U&'\001E'), '') as osm_id,
    nullif(array_to_string(osm_types, U&'\001E'), '') as osm_type,
    center as way,
    railway_ref,
    feature,
    state,
    station,
    -- Importance determines the station size.
    -- For stations, it is made up of the number of routes.
    -- For yards, it is made up of the (scaled) rail length.
    CASE
      WHEN importance >= 21 THEN 'large'
      WHEN importance >= 9 THEN 'normal'
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
    importance,
    discr_iso,
    count,
    nullif(array_to_string(operator, U&'\001E'), '') as operator,
    nullif(array_to_string(network, U&'\001E'), '') as network,
    get_byte(sha256(operator[1]::bytea), 0) as operator_hash,
    nullif(array_to_string(position, U&'\001E'), '') as position,
    nullif(array_to_string(wikidata, U&'\001E'), '') as wikidata,
    nullif(array_to_string(wikimedia_commons, U&'\001E'), '') as wikimedia_commons,
    nullif(array_to_string(wikimedia_commons_file, U&'\001E'), '') as wikimedia_commons_file,
    nullif(array_to_string(image, U&'\001E'), '') as image,
    nullif(array_to_string(mapillary, U&'\001E'), '') as mapillary,
    nullif(array_to_string(wikipedia, U&'\001E'), '') as wikipedia,
    nullif(array_to_string(note, U&'\001E'), '') as note,
    nullif(array_to_string(description, U&'\001E'), '') as description,
    nullif(array_to_string(yard_purpose, U&'\001E'), '') as yard_purpose,
    yard_hump
  FROM grouped_stations_with_importance
  ORDER BY
    rank DESC NULLS LAST,
    importance DESC NULLS LAST;

CREATE OR REPLACE FUNCTION standard_railway_text_stations_low(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
RETURN (
  SELECT
    ST_AsMVT(tile, 'standard_railway_text_stations_low', 4096, 'way', 'id')
  FROM (
    SELECT
      ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      id as id,
      osm_id,
      osm_type,
      feature,
      state,
      station,
      station_size,
      railway_ref as label,
      name,
      uic_ref,
      operator,
      operator_hash,
      network,
      position,
      wikidata,
      wikimedia_commons,
      wikimedia_commons_file,
      image,
      mapillary,
      wikipedia,
      note,
      description,
      yard_purpose,
      yard_hump
    FROM railway_text_stations
    WHERE way && ST_TileEnvelope(z, x, y)
      AND feature = 'station'
      AND state = 'present'
      AND (station IS NULL OR station NOT IN ('light_rail', 'monorail', 'subway'))
      AND 213000 * exp(-0.33 * z) - 18000 < discr_iso
      AND station_size IN ('large', 'normal')
    ORDER BY
      importance DESC NULLS LAST
  ) as tile
  WHERE way IS NOT NULL
);

DO $do$ BEGIN
  EXECUTE 'COMMENT ON FUNCTION standard_railway_text_stations_low IS $tj$' || $$
  {
    "vector_layers": [
      {
        "id": "standard_railway_text_stations_low",
        "fields": {
          "id": "integer",
          "osm_id": "string",
          "osm_type": "string",
          "feature": "string",
          "state": "string",
          "station": "string",
          "station_size": "string",
          "label": "string",
          "name": "string",
          "operator": "string",
          "operator_hash": "string",
          "network": "string",
          "position": "string",
          "uic_ref": "string",
          "wikidata": "string",
          "wikimedia_commons": "string",
          "wikimedia_commons_file": "string",
          "image": "string",
          "mapillary": "string",
          "wikipedia": "string",
          "note": "string",
          "description": "string",
          "yard_purpose": "string",
          "yard_hump": "boolean"
        }
      }
    ]
  }
  $$::json || '$tj$';
END $do$;

CREATE OR REPLACE FUNCTION standard_railway_text_stations_med(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
RETURN (
  SELECT
    ST_AsMVT(tile, 'standard_railway_text_stations_med', 4096, 'way', 'id')
  FROM (
    SELECT
      ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      id,
      osm_id,
      osm_type,
      feature,
      state,
      station,
      station_size,
      railway_ref as label,
      name,
      uic_ref,
      operator,
      operator_hash,
      network,
      position,
      wikidata,
      wikimedia_commons,
      wikimedia_commons_file,
      image,
      mapillary,
      wikipedia,
      note,
      description,
      yard_purpose,
      yard_hump
    FROM railway_text_stations
    WHERE way && ST_TileEnvelope(z, x, y)
      AND feature = 'station'
      AND state = 'present'
      AND (station IS NULL OR station NOT IN ('light_rail', 'monorail', 'subway'))
      AND 213000 * exp(-0.33 * z) - 18000 < discr_iso
    ORDER BY
      importance DESC NULLS LAST
  ) as tile
  WHERE way IS NOT NULL
);

DO $do$ BEGIN
  EXECUTE 'COMMENT ON FUNCTION standard_railway_text_stations_med IS $tj$' || $$
  {
    "vector_layers": [
      {
        "id": "standard_railway_text_stations_med",
        "fields": {
          "id": "integer",
          "osm_id": "string",
          "osm_type": "string",
          "feature": "string",
          "state": "string",
          "station": "string",
          "station_size": "string",
          "label": "string",
          "name": "string",
          "operator": "string",
          "operator_hash": "string",
          "network": "string",
          "position": "string",
          "uic_ref": "string",
          "wikidata": "string",
          "wikimedia_commons": "string",
          "wikimedia_commons_file": "string",
          "image": "string",
          "mapillary": "string",
          "wikipedia": "string",
          "note": "string",
          "description": "string",
          "yard_purpose": "string",
          "yard_hump": "boolean"
        }
      }
    ]
  }
  $$::json || '$tj$';
END $do$;

CREATE OR REPLACE FUNCTION standard_railway_turntables(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
RETURN (
  SELECT
    ST_AsMVT(tile, 'standard_railway_turntables', 4096, 'way', 'id')
  FROM (
    SELECT
      id,
      ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      osm_id,
      feature
    FROM turntables
    WHERE way && ST_TileEnvelope(z, x, y)
  ) as tile
  WHERE way IS NOT NULL
);

DO $do$ BEGIN
  EXECUTE 'COMMENT ON FUNCTION standard_railway_turntables IS $tj$' || $$
  {
    "vector_layers": [
      {
        "id": "standard_railway_turntables",
        "fields": {
          "id": "integer",
          "osm_id": "integer",
          "feature": "string"
        }
      }
    ]
  }
  $$::json || '$tj$';
END $do$;

CREATE OR REPLACE FUNCTION standard_station_entrances(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
RETURN (
  SELECT
    ST_AsMVT(tile, 'standard_station_entrances', 4096, 'way', 'id')
  FROM (
    SELECT
      ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      id,
      osm_id,
      type,
      name,
      ref,
      CASE
        WHEN name IS NOT NULL AND ref IS NOT NULL THEN CONCAT(name, ' (', ref, ')')
        ELSE COALESCE(name, ref)
      END AS label,
      wikidata,
      wikimedia_commons,
      wikimedia_commons_file,
      image,
      mapillary,
      wikipedia,
      note,
      description
    FROM station_entrances
    WHERE way && ST_TileEnvelope(z, x, y)
  ) as tile
  WHERE way IS NOT NULL
);

DO $do$ BEGIN
  EXECUTE 'COMMENT ON FUNCTION standard_station_entrances IS $tj$' || $$
  {
    "vector_layers": [
      {
        "id": "standard_station_entrances",
        "fields": {
          "id": "integer",
          "osm_id": "integer",
          "type": "string",
          "name": "string",
          "ref": "string",
          "wikidata": "string",
          "wikimedia_commons": "string",
          "wikimedia_commons_file": "string",
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

CREATE OR REPLACE FUNCTION standard_railway_text_stations(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
RETURN (
  SELECT
    ST_AsMVT(tile, 'standard_railway_text_stations', 4096, 'way', 'id')
  FROM (
    SELECT
      ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      id,
      osm_id,
      osm_type,
      feature,
      state,
      station,
      station_size,
      railway_ref as label,
      name,
      count,
      uic_ref,
      operator,
      operator_hash,
      network,
      position,
      wikidata,
      wikimedia_commons,
      wikimedia_commons_file,
      image,
      mapillary,
      wikipedia,
      note,
      description,
      yard_purpose,
      yard_hump
    FROM railway_text_stations
    WHERE way && ST_TileEnvelope(z, x, y)
      AND name IS NOT NULL
  ) as tile
  WHERE way IS NOT NULL
);

DO $do$ BEGIN
  EXECUTE 'COMMENT ON FUNCTION standard_railway_text_stations IS $tj$' || $$
  {
    "vector_layers": [
      {
        "id": "standard_railway_text_stations",
        "fields": {
          "id": "integer",
          "osm_id": "string",
          "osm_type": "string",
          "feature": "string",
          "state": "string",
          "station": "string",
          "station_size": "string",
          "label": "string",
          "name": "string",
          "operator": "string",
          "operator_hash": "string",
          "network": "string",
          "position": "string",
          "count": "integer",
          "uic_ref": "string",
          "wikidata": "string",
          "wikimedia_commons": "string",
          "wikimedia_commons_file": "string",
          "image": "string",
          "mapillary": "string",
          "wikipedia": "string",
          "note": "string",
          "description": "string",
          "yard_purpose": "string",
          "yard_hump": "boolean"
        }
      }
    ]
  }
  $$::json || '$tj$';
END $do$;

CREATE OR REPLACE FUNCTION standard_railway_grouped_stations(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
RETURN (
  SELECT
    ST_AsMVT(tile, 'standard_railway_grouped_stations', 4096, 'way', 'id')
  FROM (
    SELECT
      id,
      nullif(array_to_string(osm_ids, U&'\001E'), '') as osm_id,
      nullif(array_to_string(osm_types, U&'\001E'), '') as osm_type,
      ST_AsMVTGeom(buffered, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      feature,
      state,
      station,
      railway_ref as label,
      name,
      uic_ref,
      nullif(array_to_string(operator, U&'\001E'), '') as operator,
      nullif(array_to_string(network, U&'\001E'), '') as network,
      nullif(array_to_string(position, U&'\001E'), '') as position,
      get_byte(sha256(operator[1]::bytea), 0) as operator_hash,
      nullif(array_to_string(wikidata, U&'\001E'), '') as wikidata,
      nullif(array_to_string(wikimedia_commons, U&'\001E'), '') as wikimedia_commons,
      nullif(array_to_string(wikimedia_commons_file, U&'\001E'), '') as wikimedia_commons_file,
      nullif(array_to_string(image, U&'\001E'), '') as image,
      nullif(array_to_string(mapillary, U&'\001E'), '') as mapillary,
      nullif(array_to_string(wikipedia, U&'\001E'), '') as wikipedia,
      nullif(array_to_string(note, U&'\001E'), '') as note,
      nullif(array_to_string(description, U&'\001E'), '') as description
    FROM grouped_stations_with_importance
    WHERE buffered && ST_TileEnvelope(z, x, y)
  ) as tile
  WHERE way IS NOT NULL
);

DO $do$ BEGIN
  EXECUTE 'COMMENT ON FUNCTION standard_railway_grouped_stations IS $tj$' || $$
  {
    "vector_layers": [
      {
        "id": "standard_railway_grouped_stations",
        "fields": {
          "id": "integer",
          "osm_id": "string",
          "osm_type": "string",
          "feature": "string",
          "state": "string",
          "station": "string",
          "label": "string",
          "name": "string",
          "operator": "string",
          "operator_hash": "string",
          "network": "string",
          "position": "string",
          "uic_ref": "string",
          "wikidata": "string",
          "wikimedia_commons": "string",
          "wikimedia_commons_file": "string",
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

CREATE OR REPLACE FUNCTION standard_railway_symbols(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
RETURN (
  SELECT
    ST_AsMVT(tile, 'standard_railway_symbols', 4096, 'way', 'id')
  FROM (
    SELECT
      ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      id,
      osm_id,
      osm_type,
      feature,
      ref,
      name,
      nullif(array_to_string(position, U&'\001E'), '') as position,
      wikidata,
      wikimedia_commons,
      wikimedia_commons_file,
      image,
      mapillary,
      wikipedia,
      note,
      description
    FROM pois
    WHERE way && ST_TileEnvelope(z, x, y)
      AND z >= minzoom
      AND layer = 'standard'
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
          "name": "string",
          "minzoom": "integer",
          "position": "string",
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

CREATE OR REPLACE FUNCTION standard_railway_platforms(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
RETURN (
  SELECT
    ST_AsMVT(tile, 'standard_railway_platforms', 4096, 'way', 'id')
  FROM (
    SELECT
      id,
      osm_id,
      osm_type,
      ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      'platform' as feature,
      name,
      nullif(array_to_string(ref, U&'\001E'), '') as ref,
      height,
      surface,
      elevator,
      shelter,
      lit,
      bin,
      bench,
      wheelchair,
      departures_board,
      tactile_paving
    FROM platforms
    WHERE way && ST_TileEnvelope(z, x, y)
  ) as tile
  WHERE way IS NOT NULL
);

DO $do$ BEGIN
  EXECUTE 'COMMENT ON FUNCTION standard_railway_platforms IS $tj$' || $$
  {
    "vector_layers": [
      {
        "id": "standard_railway_platforms",
        "fields": {
          "id": "integer",
          "osm_id": "string",
          "osm_type": "string",
          "feature": "string",
          "name": "string",
          "ref": "string",
          "height": "string",
          "surface": "boolean",
          "elevator": "boolean",
          "shelter": "boolean",
          "lit": "boolean",
          "bin": "boolean",
          "bench": "boolean",
          "wheelchair": "boolean",
          "departures_board": "boolean",
          "tactile_paving": "boolean"
        }
      }
    ]
  }
  $$::json || '$tj$';
END $do$;

CREATE OR REPLACE FUNCTION standard_railway_platform_edges(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
RETURN (
  SELECT
    ST_AsMVT(tile, 'standard_railway_platform_edges', 4096, 'way', 'id')
  FROM (
    SELECT
      id,
      osm_id,
      ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      'platform_edge' as feature,
      ref,
      height,
      tactile_paving
    FROM platform_edge
    WHERE way && ST_TileEnvelope(z, x, y)
  ) as tile
  WHERE way IS NOT NULL
);

DO $do$ BEGIN
  EXECUTE 'COMMENT ON FUNCTION standard_railway_platform_edges IS $tj$' || $$
  {
    "vector_layers": [
      {
        "id": "standard_railway_platform_edges",
        "fields": {
          "id": "integer",
          "osm_id": "string",
          "feature": "string",
          "ref": "string",
          "height": "string",
          "tactile_paving": "boolean"
        }
      }
    ]
  }
  $$::json || '$tj$';
END $do$;

CREATE OR REPLACE FUNCTION standard_railway_stop_positions(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
RETURN (
  SELECT
    ST_AsMVT(tile, 'standard_railway_stop_positions', 4096, 'way', 'id')
  FROM (
    SELECT
      id,
      osm_id,
      ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      'stop_position' as feature,
      name,
      type
    FROM stop_positions
    WHERE way && ST_TileEnvelope(z, x, y)
  ) as tile
  WHERE way IS NOT NULL
);

DO $do$ BEGIN
  EXECUTE 'COMMENT ON FUNCTION standard_railway_stop_positions IS $tj$' || $$
  {
    "vector_layers": [
      {
        "id": "standard_railway_stop_positions",
        "fields": {
          "id": "integer",
          "osm_id": "string",
          "feature": "string",
          "name": "string",
          "type": "string"
        }
      }
    ]
  }
  $$::json || '$tj$';
END $do$;

CREATE OR REPLACE FUNCTION railway_text_km(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
RETURN (
  SELECT
    ST_AsMVT(tile, 'railway_text_km', 4096, 'way', 'id')
  FROM (
    SELECT
      id,
      osm_id,
      ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      railway,
      position_text as pos,
      position_exact as pos_exact,
      zero,
      round(position_numeric) as pos_int,
      type,
      wikidata,
      wikimedia_commons,
      wikimedia_commons_file,
      image,
      mapillary,
      wikipedia,
      note,
      description
    FROM railway_positions
    WHERE way && ST_TileEnvelope(z, x, y)
    ORDER by zero
  ) as tile
  WHERE way IS NOT NULL
);

DO $do$ BEGIN
  EXECUTE 'COMMENT ON FUNCTION railway_text_km IS $tj$' || $$
  {
    "vector_layers": [
      {
        "id": "railway_text_km",
        "fields": {
          "id": "integer",
          "osm_id": "integer",
          "railway": "string",
          "pos": "string",
          "pos_exact": "string",
          "pos_int": "integer",
          "zero": "boolean",
          "type": "string",
          "wikidata": "string",
          "wikimedia_commons": "string",
          "wikimedia_commons_file": "string",
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

CREATE OR REPLACE FUNCTION standard_railway_switch_ref(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
RETURN (
  SELECT
    ST_AsMVT(tile, 'standard_railway_switch_ref', 4096, 'way', 'id')
  FROM (
    SELECT
      id,
      osm_id,
      ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      railway,
      ref,
      type,
      turnout_side,
      local_operated,
      resetting,
      nullif(array_to_string(position, U&'\001E'), '') as position,
      wikidata,
      wikimedia_commons,
      wikimedia_commons_file,
      image,
      mapillary,
      wikipedia,
      note,
      description
    FROM railway_switches
    WHERE way && ST_TileEnvelope(z, x, y)
    ORDER by char_length(ref)
  ) as tile
  WHERE way IS NOT NULL
);

DO $do$ BEGIN
  EXECUTE 'COMMENT ON FUNCTION standard_railway_switch_ref IS $tj$' || $$
  {
    "vector_layers": [
      {
        "id": "standard_railway_switch_ref",
        "fields": {
          "id": "integer",
          "osm_id": "integer",
          "railway": "string",
          "ref": "string",
          "type": "string",
          "turnout_side": "string",
          "local_operated": "boolean",
          "resetting": "boolean",
          "position": "string",
          "wikidata": "string",
          "wikimedia_commons": "string",
          "wikimedia_commons_file": "string",
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


CREATE OR REPLACE FUNCTION standard_railway_grouped_station_areas(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
RETURN (
  SELECT
    ST_AsMVT(tile, 'standard_railway_grouped_station_areas', 4096, 'way', 'id')
  FROM (
    SELECT
      osm_id as id,
      osm_id,
      'station_area_group' as feature,
      ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way
    FROM stop_area_groups_buffered
    WHERE way && ST_TileEnvelope(z, x, y)
  ) as tile
  WHERE way IS NOT NULL
);

DO $do$ BEGIN
  EXECUTE 'COMMENT ON FUNCTION standard_railway_grouped_station_areas IS $tj$' || $$
  {
    "vector_layers": [
      {
        "id": "standard_railway_grouped_station_areas",
        "fields": {
          "id": "integer",
          "osm_id": "integer",
          "feature": "string"
        }
      }
    ]
  }
  $$::json || '$tj$';
END $do$;

--- Speed ---

CREATE OR REPLACE FUNCTION speed_railway_line_low(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
RETURN (
  SELECT
    ST_AsMVT(tile, 'speed_railway_line_low', 4096, 'way', 'id')
  FROM (
    SELECT
      min(id) as id,
      ST_AsMVTGeom(st_simplify(st_collect(way), 100000), ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      feature,
      any_value(state) as state,
      any_value(usage) as usage,
      maxspeed,
      highspeed,
      ref,
      standard_label,
      speed_label,
      max(rank) as rank
    FROM railway_line_low
    WHERE way && ST_TileEnvelope(z, x, y)
    GROUP BY
      feature,
      ref,
      standard_label,
      speed_label,
      maxspeed,
      highspeed
    ORDER by
      rank NULLS LAST,
      maxspeed NULLS FIRST
  ) as tile
  WHERE way IS NOT NULL
);

DO $do$ BEGIN
  EXECUTE 'COMMENT ON FUNCTION speed_railway_line_low IS $tj$' || $$
  {
    "vector_layers": [
      {
        "id": "speed_railway_line_low",
        "fields": {
          "id": "integer",
          "feature": "string",
          "state": "string",
          "usage": "string",
          "highspeed": "boolean",
          "tunnel": "boolean",
          "bridge": "boolean",
          "ref": "string",
          "standard_label": "string",
          "maxspeed": "number",
          "speed_label": "string"
        }
      }
    ]
  }
  $$::json || '$tj$';
END $do$;

--- Signals ---


CREATE OR REPLACE FUNCTION signals_railway_line_low(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
RETURN (
  SELECT
    ST_AsMVT(tile, 'signals_railway_line_low', 4096, 'way', 'id')
  FROM (
    SELECT
      min(id) as id,
      ST_AsMVTGeom(st_simplify(st_collect(way), 100000), ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      feature,
      any_value(state) as state,
      any_value(usage) as usage,
      ref,
      standard_label,
      train_protection_rank,
      train_protection,
      train_protection_construction_rank,
      train_protection_construction,
      max(rank) as rank
    FROM railway_line_low
    WHERE way && ST_TileEnvelope(z, x, y)
    GROUP BY
      feature,
      ref,
      standard_label,
      train_protection_rank,
      train_protection,
      train_protection_construction_rank,
      train_protection_construction
    ORDER by
      rank NULLS LAST
  ) as tile
  WHERE way IS NOT NULL
);

DO $do$ BEGIN
  EXECUTE 'COMMENT ON FUNCTION signals_railway_line_low IS $tj$' || $$
  {
    "vector_layers": [
      {
        "id": "signals_railway_line_low",
        "fields": {
          "id": "integer",
          "feature": "string",
          "state": "string",
          "usage": "string",
          "tunnel": "boolean",
          "bridge": "boolean",
          "ref": "string",
          "standard_label": "string",
          "train_protection": "string",
          "train_protection_rank": "integer",
          "train_protection_construction": "string",
          "train_protection_construction_rank": "integer"
        }
      }
    ]
  }
  $$::json || '$tj$';
END $do$;

--- Signals ---

CREATE OR REPLACE FUNCTION signals_signal_boxes(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
  RETURN (
    SELECT
      ST_AsMVT(tile, 'signals_signal_boxes', 4096, 'way', 'id')
    FROM (
      SELECT
        ST_AsMVTGeom(
          CASE
            WHEN z >= 14 THEN way
            ELSE center
          END,
          ST_TileEnvelope(z, x, y),
          extent => 4096, buffer => 64, clip_geom => true
        ) AS way,
        id,
        osm_id,
        osm_type,
        feature,
        ref,
        name,
        operator,
        get_byte(sha256(operator::bytea), 0) as operator_hash,
        nullif(array_to_string(position, U&'\001E'), '') as position,
        wikimedia_commons,
        wikimedia_commons_file,
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
          "operator": "string",
          "operator_hash": "string",
          "position": "string",
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

--- Electrification ---

CREATE OR REPLACE FUNCTION electrification_railway_line_low(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
RETURN (
  SELECT
    ST_AsMVT(tile, 'electrification_railway_line_low', 4096, 'way', 'id')
  FROM (
    SELECT
      min(id) as id,
      ST_AsMVTGeom(st_simplify(st_collect(way), 100000), ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      feature,
      any_value(state) as state,
      any_value(usage) as usage,
      ref,
      standard_label,
      electrification_state,
      electrification_label,
      voltage,
      frequency,
      max(rank) as rank
    FROM railway_line_low
    WHERE way && ST_TileEnvelope(z, x, y)
    GROUP BY
      feature,
      ref,
      standard_label,
      electrification_state,
      electrification_label,
      voltage,
      frequency
    ORDER by
      rank NULLS LAST
  ) as tile
  WHERE way IS NOT NULL
);

DO $do$ BEGIN
  EXECUTE 'COMMENT ON FUNCTION electrification_railway_line_low IS $tj$' || $$
  {
    "vector_layers": [
      {
        "id": "electrification_railway_line_low",
        "fields": {
          "id": "integer",
          "feature": "string",
          "state": "string",
          "usage": "string",
          "tunnel": "boolean",
          "bridge": "boolean",
          "ref": "string",
          "standard_label": "string",
          "electrification_state": "string",
          "frequency": "number",
          "voltage": "integer",
          "future_frequency": "number",
          "future_voltage": "integer",
          "electrification_label": "string"
        }
      }
    ]
  }
  $$::json || '$tj$';
END $do$;

CREATE OR REPLACE FUNCTION electrification_railway_symbols(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
RETURN (
  SELECT
    ST_AsMVT(tile, 'electrification_railway_symbols', 4096, 'way', 'id')
  FROM (
    SELECT
      ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      id,
      osm_id,
      osm_type,
      feature,
      ref,
      nullif(array_to_string(position, U&'\001E'), '') as position,
      wikidata,
      wikimedia_commons,
      wikimedia_commons_file,
      image,
      mapillary,
      wikipedia,
      note,
      description
    FROM pois
    WHERE way && ST_TileEnvelope(z, x, y)
      AND z >= minzoom
      AND layer = 'electrification'
    ORDER BY rank DESC
  ) as tile
  WHERE way IS NOT NULL
);

DO $do$ BEGIN
  EXECUTE 'COMMENT ON FUNCTION electrification_railway_symbols IS $tj$' || $$
  {
    "vector_layers": [
      {
        "id": "electrification_railway_symbols",
        "fields": {
          "id": "integer",
          "osm_id": "integer",
          "osm_type": "string",
          "feature": "string",
          "ref": "string",
          "minzoom": "integer",
          "position": "string",
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

CREATE OR REPLACE FUNCTION electrification_catenary(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
RETURN (
  SELECT
    ST_AsMVT(tile, 'electrification_catenary', 4096, 'way', 'id')
  FROM (
    SELECT
      id,
      osm_id,
      osm_type,
      ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      feature,
      ref,
      transition,
      structure,
      supporting,
      attachment,
      tensioning,
      insulator,
      nullif(array_to_string(position, U&'\001E'), '') as position,
      note,
      description
    FROM catenary
    WHERE way && ST_TileEnvelope(z, x, y)
  ) as tile
  WHERE way IS NOT NULL
);

DO $do$ BEGIN
  EXECUTE 'COMMENT ON FUNCTION electrification_catenary IS $tj$' || $$
  {
    "vector_layers": [
      {
        "id": "electrification_catenary",
        "fields": {
          "id": "integer",
          "osm_id": "integer",
          "osm_type": "string",
          "ref": "string",
          "feature": "string",
          "transition": "boolean",
          "structure": "string",
          "supporting": "string",
          "attachment": "string",
          "tensioning": "string",
          "insulator": "string",
          "position": "string",
          "note": "string",
          "description": "string"
        }
      }
    ]
  }
  $$::json || '$tj$';
END $do$;

--- Gauge ---

CREATE OR REPLACE FUNCTION gauge_railway_line_low(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
RETURN (
  SELECT
    ST_AsMVT(tile, 'gauge_railway_line_low', 4096, 'way', 'id')
  FROM (
    SELECT
      min(id) as id,
      ST_AsMVTGeom(st_simplify(st_collect(way), 100000), ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      feature,
      any_value(state) as state,
      any_value(usage) as usage,
      ref,
      standard_label,
      gaugeint0,
      gauge0,
      gauge_label,
      max(rank) as rank
    FROM railway_line_low
    WHERE way && ST_TileEnvelope(z, x, y)
    GROUP BY
      feature,
      ref,
      standard_label,
      gauge0,
      gaugeint0,
      gauge_label
    ORDER by
      rank NULLS LAST
  ) as tile
  WHERE way IS NOT NULL
);

DO $do$ BEGIN
  EXECUTE 'COMMENT ON FUNCTION gauge_railway_line_low IS $tj$' || $$
  {
    "vector_layers": [
      {
        "id": "gauge_railway_line_low",
        "fields": {
          "id": "integer",
          "feature": "string",
          "state": "string",
          "usage": "string",
          "tunnel": "boolean",
          "bridge": "boolean",
          "ref": "string",
          "standard_label": "string",
          "gauge0": "string",
          "gaugeint0": "number",
          "gauge_label": "string"
        }
      }
    ]
  }
  $$::json || '$tj$';
END $do$;

--- Loading gauge ---

CREATE OR REPLACE FUNCTION loading_gauge_railway_line_low(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
RETURN (
  SELECT
    ST_AsMVT(tile, 'loading_gauge_railway_line_low', 4096, 'way', 'id')
  FROM (
    SELECT
      min(id) as id,
      ST_AsMVTGeom(st_simplify(st_collect(way), 100000), ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      feature,
      any_value(state) as state,
      any_value(usage) as usage,
      ref,
      standard_label,
      loading_gauge,
      max(rank) as rank
    FROM railway_line_low
    WHERE way && ST_TileEnvelope(z, x, y)
    GROUP BY
      feature,
      ref,
      standard_label,
      loading_gauge
    ORDER by
      rank NULLS LAST
  ) as tile
  WHERE way IS NOT NULL
);

DO $do$ BEGIN
  EXECUTE 'COMMENT ON FUNCTION loading_gauge_railway_line_low IS $tj$' || $$
  {
    "vector_layers": [
      {
        "id": "loading_gauge_railway_line_low",
        "fields": {
          "id": "integer",
          "feature": "string",
          "state": "string",
          "usage": "string",
          "tunnel": "boolean",
          "bridge": "boolean",
          "ref": "string",
          "standard_label": "string",
          "loading_gauge": "string"
        }
      }
    ]
  }
  $$::json || '$tj$';
END $do$;

--- Track class ---

CREATE OR REPLACE FUNCTION track_class_railway_line_low(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
RETURN (
  SELECT
    ST_AsMVT(tile, 'track_class_railway_line_low', 4096, 'way', 'id')
  FROM (
    SELECT
      min(id) as id,
      ST_AsMVTGeom(st_simplify(st_collect(way), 100000), ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      feature,
      any_value(state) as state,
      any_value(usage) as usage,
      ref,
      standard_label,
      track_class,
      max(rank) as rank
    FROM railway_line_low
    WHERE way && ST_TileEnvelope(z, x, y)
    GROUP BY
      feature,
      ref,
      standard_label,
      track_class
    ORDER by
      rank NULLS LAST
  ) as tile
  WHERE way IS NOT NULL
);

DO $do$ BEGIN
  EXECUTE 'COMMENT ON FUNCTION track_class_railway_line_low IS $tj$' || $$
  {
    "vector_layers": [
      {
        "id": "track_class_railway_line_low",
        "fields": {
          "id": "integer",
          "feature": "string",
          "state": "string",
          "usage": "string",
          "tunnel": "boolean",
          "bridge": "boolean",
          "ref": "string",
          "standard_label": "string",
          "track_class": "string"
        }
      }
    ]
  }
  $$::json || '$tj$';
END $do$;

--- Operator ---

CREATE OR REPLACE FUNCTION operator_railway_line_low(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
RETURN (
  SELECT
    ST_AsMVT(tile, 'operator_railway_line_low', 4096, 'way', 'id')
  FROM (
    SELECT
      min(id) as id,
      ST_AsMVTGeom(st_simplify(st_collect(way), 100000), ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      feature,
      any_value(state) as state,
      any_value(usage) as usage,
      ref,
      standard_label,
      operator,
      operator_hash,
      primary_operator,
      owner,
      max(rank) as rank
    FROM railway_line_low
    WHERE way && ST_TileEnvelope(z, x, y)
    GROUP BY
      feature,
      ref,
      standard_label,
      operator,
      operator_hash,
      primary_operator,
      owner
    ORDER by
      rank NULLS LAST
  ) as tile
  WHERE way IS NOT NULL
);

DO $do$ BEGIN
  EXECUTE 'COMMENT ON FUNCTION operator_railway_line_low IS $tj$' || $$
  {
    "vector_layers": [
      {
        "id": "operator_railway_line_low",
        "fields": {
          "id": "integer",
          "feature": "string",
          "state": "string",
          "usage": "string",
          "tunnel": "boolean",
          "bridge": "boolean",
          "ref": "string",
          "standard_label": "string",
          "operator": "string",
          "operator_hash": "number",
          "primary_operator": "string",
          "owner": "string"
        }
      }
    ]
  }
  $$::json || '$tj$';
END $do$;

CREATE OR REPLACE FUNCTION operator_railway_symbols(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
RETURN (
  SELECT
    ST_AsMVT(tile, 'operator_railway_symbols', 4096, 'way', 'id')
  FROM (
         SELECT
           ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
           id,
           osm_id,
           osm_type,
           feature,
           ref,
           nullif(array_to_string(position, U&'\001E'), '') as position,
           wikidata,
           wikimedia_commons,
           wikimedia_commons_file,
           image,
           mapillary,
           wikipedia,
           note,
           description
         FROM pois
         WHERE way && ST_TileEnvelope(z, x, y)
           AND z >= minzoom
           AND layer = 'operator'
         ORDER BY rank DESC
       ) as tile
  WHERE way IS NOT NULL
);

DO $do$ BEGIN
  EXECUTE 'COMMENT ON FUNCTION operator_railway_symbols IS $tj$' || $$
  {
    "vector_layers": [
      {
        "id": "operator_railway_symbols",
        "fields": {
          "id": "integer",
          "osm_id": "integer",
          "osm_type": "string",
          "feature": "string",
          "ref": "string",
          "minzoom": "integer",
          "position": "string",
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
