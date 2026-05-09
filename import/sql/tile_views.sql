--- Shared ---

-- TODO calculate labels in frontend
CREATE OR REPLACE VIEW railway_line_view AS
  SELECT
    r.id,
    osm_id,
    'W' as osm_type,
    way,
    way_length,
    layer,
    feature,
    state,
    usage,
    service,
    highspeed,
    tunnel,
    bridge,
    CASE
      WHEN ref IS NOT NULL AND r.name IS NOT NULL THEN ref || ' ' || r.name
      ELSE COALESCE(ref, r.name)
    END AS standard_label,
    ref,
    track_ref,
    track_class,
    reporting_marks,
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
    maximum_current,
    electrification_label,
    future_voltage,
    future_frequency,
    future_maximum_current,
    gauges,
    railway_to_int(gauge0) AS gaugeint0,
    gauge0,
    railway_to_int(gauge1) AS gaugeint1,
    gauge1,
    railway_to_int(gauge2) AS gaugeint2,
    gauge2,
    gauge_label,
    loading_gauge,
    operator,
    COALESCE(
      ro.color,
      'hsl(' || get_byte(sha256(primary_operator::bytea), 0) || ', 100%, 30%)'
    ) as operator_color,
    coalesce(ro.bright, get_byte(sha256(primary_operator::bytea), 0) between 44 AND 189) as operator_bright,
    primary_operator,
    owner,
    traffic_mode,
    radio,
    line_routes,
    route_count,
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
      maximum_current,
      railway_electrification_label(COALESCE(voltage, future_voltage), COALESCE(frequency, future_frequency)) AS electrification_label,
      future_voltage,
      future_frequency,
      future_maximum_current,
      gauges,
      gauges[1] AS gauge0,
      gauges[2] AS gauge1,
      gauges[3] AS gauge2,
      (select string_agg(gauge, ' | ') from unnest(gauges) as gauge where gauge ~ '^[0-9]+$') as gauge_label,
      loading_gauge,
      operator,
      owner,
      CASE
        WHEN ARRAY[owner] <@ operator THEN owner
        ELSE operator[1]
      END AS primary_operator,
      traffic_mode,
      radio,
      (select array_agg(hstore(ARRAY[ARRAY['route_id', r.osm_id::text], ARRAY['color', coalesce(r.color, '')], ARRAY['label', coalesce(r.name, '')]]) order by r.osm_id) from route_line rl join routes r on rl.route_id = r.osm_id where rl.line_id = l.osm_id) as line_routes,
      (select count(*) from route_line rl join routes r on rl.route_id = r.osm_id where rl.line_id = l.osm_id) as route_count,
      wikidata,
      wikimedia_commons,
      wikimedia_commons_file,
      image,
      mapillary,
      wikipedia,
      note,
      description
    FROM railway_line l
  ) AS r
  LEFT JOIN railway_operator ro
    ON ro.name = primary_operator;

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
    SELECT
      id,
      ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      way_length,
      feature,
      state,
      usage,
      service,
      highspeed,
      tunnel,
      bridge,
      standard_label,
      ref,
      track_ref,
      track_class,
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
      maximum_current,
      electrification_label,
      future_voltage,
      future_frequency,
      future_maximum_current,
      gauges,
      gaugeint0,
      gauge0,
      gaugeint1,
      gauge1,
      gaugeint2,
      gauge2,
      gauge_label,
      loading_gauge,
      operator,
      operator_color,
      operator_bright,
      primary_operator,
      owner,
      route_count
    FROM railway_line_view
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
          "id": "string",
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
          "maximum_current": "integer",
          "future_frequency": "number",
          "future_voltage": "integer",
          "future_maximum_current": "integer",
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
          "operator": "string",
          "operator_color": "string",
          "operator_bright": "string",
          "primary_operator": "string",
          "owner": "string",
          "route_count": "integer"
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
    osm_id,
    way,
    feature,
    state,
    usage,
    highspeed,
    ref,
    standard_label,
    speed_label,
    maxspeed,
    train_protection_rank,
    train_protection,
    train_protection_construction_rank,
    train_protection_construction,
    electrification_state,
    electrification_label,
    voltage,
    frequency,
    maximum_current,
    gaugeint0,
    gauge0,
    gauge_label,
    loading_gauge,
    track_class,
    operator,
    operator_color,
    operator_bright,
    primary_operator,
    owner,
    rank
  FROM railway_line_view
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
    ST_AsMVT(tile, 'standard_railway_line_low', 4096, 'way')
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
    FROM railway_line_low l
    WHERE way && ST_TileEnvelope(z, x, y)
    GROUP BY
      osm_id,
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
          "id": "string",
          "feature": "string",
          "state": "string",
          "usage": "string",
          "highspeed": "boolean",
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
    gs.id,
    osm_ids as osm_id,
    osm_types as osm_type,
    center as way,
    buffered,
    map_reference,
    "references",
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
    gs.name as name,
    name_tags,
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
    importance,
    discr_iso,
    count,
    gs.operator as operator,
    owner,
    network,
    COALESCE(
      ro.color,
      'hsl(' || get_byte(sha256(gs.operator[1]::bytea), 0) || ', 100%, 30%)'
    ) as operator_color,
    coalesce(ro.bright, get_byte(sha256(gs.operator[1]::bytea), 0) between 44 AND 189) as operator_bright,
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
    yard_hump,
    (select array_agg(hstore(ARRAY[ARRAY['route_id', r.osm_id::text], ARRAY['color', coalesce(r.color, '')], ARRAY['label', coalesce(r.name, '')]]) order by r.osm_id) from routes r where ARRAY[r.osm_id] <@ gs.route_ids) as station_routes
  FROM grouped_stations_with_importance gs
  LEFT JOIN railway_operator ro
    ON ro.name = operator[1]
  ORDER BY
    rank DESC NULLS LAST,
    importance DESC NULLS LAST;

CREATE OR REPLACE FUNCTION standard_railway_text_stations_low(z integer, x integer, y integer, query json)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
RETURN (
  SELECT
    ST_AsMVT(tile, 'standard_railway_text_stations_low', 4096, 'way')
  FROM (
    SELECT
      ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      id,
      map_reference as label,
      name,
      COALESCE(name_tags['name:' || (query->>'lang')::text], name) as localized_name,
      station_size,
      operator_color,
      operator_bright
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
          "id": "string",
          "label": "string",
          "name": "string",
          "localized_name": "string",
          "station_size": "string",
          "operator_color": "string",
          "operator_bright": "string"
        }
      }
    ]
  }
  $$::json || '$tj$';
END $do$;

CREATE OR REPLACE FUNCTION standard_railway_text_stations_med(z integer, x integer, y integer, query json)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
RETURN (
  SELECT
    ST_AsMVT(tile, 'standard_railway_text_stations_med', 4096, 'way')
  FROM (
    SELECT
      ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      id,
      map_reference as label,
      name,
      COALESCE(name_tags['name:' || (query->>'lang')::text], name) as localized_name,
      station_size,
      operator_color,
      operator_bright
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
          "id": "string",
          "label": "string",
          "name": "string",
          "localized_name": "string",
          "station_size": "string",
          "operator_color": "string",
          "operator_bright": "string"
        }
      }
    ]
  }
  $$::json || '$tj$';
END $do$;

CREATE OR REPLACE VIEW standard_railway_turntables_view AS
  SELECT
    osm_id as id,
    osm_id,
    'W' as osm_type,
    way,
    feature
  FROM turntables;

CREATE OR REPLACE FUNCTION standard_railway_turntables(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
RETURN (
  SELECT
    ST_AsMVT(tile, 'standard_railway_turntables', 4096, 'way')
  FROM (
    SELECT
      id,
      ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      feature
    FROM standard_railway_turntables_view
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
          "feature": "string"
        }
      }
    ]
  }
  $$::json || '$tj$';
END $do$;

CREATE OR REPLACE VIEW standard_station_entrances_view AS
  SELECT
    osm_id as id,
    osm_id,
    'N' as osm_type,
    way,
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
  FROM station_entrances;

CREATE OR REPLACE FUNCTION standard_station_entrances(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
RETURN (
  SELECT
    ST_AsMVT(tile, 'standard_station_entrances', 4096, 'way')
  FROM (
    SELECT
      id,
      ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      label
    FROM standard_station_entrances_view
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
          "label": "string"
        }
      }
    ]
  }
  $$::json || '$tj$';
END $do$;

CREATE OR REPLACE FUNCTION standard_railway_text_stations(z integer, x integer, y integer, query json)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
RETURN (
  SELECT
    ST_AsMVT(tile, 'standard_railway_text_stations', 4096, 'way')
  FROM (
    SELECT
      ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      id,
      state,
      feature,
      station,
      station_size,
      map_reference as label,
      name,
      COALESCE(name_tags['name:' || (query->>'lang')::text], name) as localized_name,
      count,
      operator_color,
      operator_bright
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
          "id": "string",
          "feature": "string",
          "state": "string",
          "station": "string",
          "station_size": "string",
          "label": "string",
          "name": "string",
          "localized_name": "string",
          "operator_color": "string",
          "operator_bright": "string",
          "count": "integer"
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
    ST_AsMVT(tile, 'standard_railway_grouped_stations', 4096, 'way')
  FROM (
    SELECT
      ST_AsMVTGeom(buffered, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      id,
      feature,
      state,
      station,
      operator_color,
      operator_bright
    FROM railway_text_stations
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
          "id": "string",
          "feature": "string",
          "state": "string",
          "station": "string",
          "operator_color": "string",
          "operator_bright": "string"
        }
      }
    ]
  }
  $$::json || '$tj$';
END $do$;

CREATE OR REPLACE VIEW poi_view AS
  SELECT
    way,
    id,
    osm_id,
    osm_type,
    feature,
    ref,
    name,
    minzoom,
    layer,
    rank,
    position,
    radio,
    emergency_phone,
    wikidata,
    wikimedia_commons,
    wikimedia_commons_file,
    image,
    mapillary,
    wikipedia,
    note,
    description
  FROM pois;

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
      ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      id,
      feature,
      ref
    FROM poi_view
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
          "id": "string",
          "feature": "string",
          "ref": "string"
        }
      }
    ]
  }
  $$::json || '$tj$';
END $do$;

CREATE OR REPLACE VIEW standard_railway_platforms_view AS
  SELECT
    id,
    osm_id,
    osm_type,
    way,
    'platform' as feature,
    name,
    ref,
    height,
    surface,
    elevator,
    shelter,
    lit,
    bin,
    bench,
    wheelchair,
    departures_board,
    tactile_paving,
    (select array_agg(hstore(ARRAY[ARRAY['route_id', r.osm_id::text], ARRAY['color', coalesce(r.color, '')], ARRAY['label', coalesce(r.name, '')]]) order by r.osm_id) from routes r where r.platform_ref_ids @> Array[p.osm_id]) as platform_routes
  FROM platforms p;

CREATE OR REPLACE FUNCTION standard_railway_platforms(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
RETURN (
  SELECT
    ST_AsMVT(tile, 'standard_railway_platforms', 4096, 'way')
  FROM (
    SELECT
      id,
      ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      'platform' as feature,
      name
    FROM standard_railway_platforms_view
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
          "id": "string",
          "name": "string"
        }
      }
    ]
  }
  $$::json || '$tj$';
END $do$;

CREATE OR REPLACE VIEW standard_railway_platform_edges_view AS
  SELECT
    osm_id as id,
    osm_id,
    'W' as osm_type,
    way,
    'platform_edge' as feature,
    ref,
    height,
    tactile_paving
  FROM platform_edge;

CREATE OR REPLACE FUNCTION standard_railway_platform_edges(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
RETURN (
  SELECT
    ST_AsMVT(tile, 'standard_railway_platform_edges', 4096, 'way')
  FROM (
    SELECT
      id,
      ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      ref
    FROM standard_railway_platform_edges_view
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
          "ref": "string"
        }
      }
    ]
  }
  $$::json || '$tj$';
END $do$;

CREATE OR REPLACE VIEW standard_railway_stop_positions_view AS
  SELECT
    osm_id as id,
    osm_id,
    'N' as osm_type,
    way,
    name,
    type,
    ref,
    local_ref,
    (select array_agg(hstore(ARRAY[ARRAY['route_id', r.osm_id::text], ARRAY['color', coalesce(r.color, '')], ARRAY['label', coalesce(r.name, '')]]) order by r.osm_id) from route_stop rs join routes r on rs.route_id = r.osm_id where rs.stop_id = sp.osm_id) as stop_position_routes
  FROM stop_positions sp;

CREATE OR REPLACE FUNCTION standard_railway_stop_positions(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
RETURN (
  SELECT
    ST_AsMVT(tile, 'standard_railway_stop_positions', 4096, 'way')
  FROM (
    SELECT
      id,
      ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      type
    FROM standard_railway_stop_positions_view
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
          "type": "string"
        }
      }
    ]
  }
  $$::json || '$tj$';
END $do$;

CREATE OR REPLACE VIEW railway_text_km_view AS
  SELECT
    id,
    osm_id,
    'N' as osm_type,
    way,
    railway,
    position_text as pos,
    position_exact as pos_exact,
    zero,
    round(position_numeric) as pos_int,
    type,
    operator,
    wikidata,
    wikimedia_commons,
    wikimedia_commons_file,
    image,
    mapillary,
    wikipedia,
    note,
    description
  FROM railway_positions;

CREATE OR REPLACE FUNCTION railway_text_km(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
RETURN (
  SELECT
    ST_AsMVT(tile, 'railway_text_km', 4096, 'way')
  FROM (
    SELECT
      id,
      ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      pos,
      pos_int
    FROM railway_text_km_view
    WHERE way && ST_TileEnvelope(z, x, y)
      AND (z >= 13 OR (z >= 10 AND zero))
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
          "id": "string",
          "pos": "string",
          "pos_int": "integer"
        }
      }
    ]
  }
  $$::json || '$tj$';
END $do$;

CREATE OR REPLACE VIEW standard_railway_switch_view AS
  SELECT
    osm_id as id,
    osm_id,
    'N' as osm_type,
    way,
    railway,
    ref,
    type,
    turnout_side,
    local_operated,
    resetting,
    position,
    wikidata,
    wikimedia_commons,
    wikimedia_commons_file,
    image,
    mapillary,
    wikipedia,
    note,
    description
  FROM railway_switches;

CREATE OR REPLACE FUNCTION standard_railway_switch_ref(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
RETURN (
  SELECT
    ST_AsMVT(tile, 'standard_railway_switch_ref', 4096, 'way')
  FROM (
    SELECT
      osm_id as id,
      ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      railway,
      ref,
      type,
      turnout_side,
      local_operated,
      resetting
    FROM standard_railway_switch_view
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
          "resetting": "boolean"
        }
      }
    ]
  }
  $$::json || '$tj$';
END $do$;

CREATE OR REPLACE VIEW standard_railway_grouped_station_areas_view AS
  SELECT
    osm_id as id,
    osm_id,
    'R' as osm_type,
    'station_area_group' as feature,
    way
  FROM stop_area_groups_buffered;

CREATE OR REPLACE FUNCTION standard_railway_grouped_station_areas(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
RETURN (
  SELECT
    ST_AsMVT(tile, 'standard_railway_grouped_station_areas', 4096, 'way')
  FROM (
    SELECT
      id,
      ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way
    FROM standard_railway_grouped_station_areas_view
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
          "id": "integer"
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
    ST_AsMVT(tile, 'speed_railway_line_low', 4096, 'way')
  FROM (
    SELECT
      min(id) as id,
      ST_AsMVTGeom(st_simplify(st_collect(way), 100000), ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      feature,
      any_value(state) as state,
      any_value(usage) as usage,
      maxspeed,
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
      maxspeed
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
          "id": "string",
          "feature": "string",
          "state": "string",
          "usage": "string",
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
    ST_AsMVT(tile, 'signals_railway_line_low', 4096, 'way')
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
          "id": "string",
          "feature": "string",
          "state": "string",
          "usage": "string",
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

CREATE OR REPLACE VIEW signal_boxes_view AS
  SELECT
    b.id,
    way,
    center,
    osm_id,
    osm_type,
    feature,
    ref,
    b.name,
    operator,
    COALESCE(
      ro.color,
      'hsl(' || get_byte(sha256(operator::bytea), 0) || ', 100%, 30%)'
    ) as operator_color,
    coalesce(ro.bright, get_byte(sha256(operator::bytea), 0) between 44 AND 189) as operator_bright,
    position,
    wikimedia_commons,
    wikimedia_commons_file,
    wikidata,
    image,
    mapillary,
    wikipedia,
    note,
    description
  FROM boxes b
  LEFT JOIN railway_operator ro
    ON ro.name = operator;

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
          extent => 4096, buffer => 64, clip_geom => true
        ) AS way,
        id,
        feature,
        ref,
        name,
        operator_color,
        operator_bright
      FROM signal_boxes_view b
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
          "id": "string",
          "feature": "string",
          "ref": "string",
          "name": "string",
          "operator_color": "string",
          "operator_bright": "string"
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
    ST_AsMVT(tile, 'electrification_railway_line_low', 4096, 'way')
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
      maximum_current,
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
      frequency,
      maximum_current
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
          "id": "string",
          "feature": "string",
          "state": "string",
          "usage": "string",
          "ref": "string",
          "standard_label": "string",
          "electrification_state": "string",
          "frequency": "number",
          "voltage": "integer",
          "maximum_current": "integer",
          "future_frequency": "number",
          "future_voltage": "integer",
          "future_maximum_current": "integer",
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
    ST_AsMVT(tile, 'electrification_railway_symbols', 4096, 'way')
  FROM (
    SELECT
      ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      id,
      feature,
      ref
    FROM poi_view
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
          "id": "string",
          "feature": "string",
          "ref": "string"
        }
      }
    ]
  }
  $$::json || '$tj$';
END $do$;

CREATE OR REPLACE VIEW electrification_catenary_view AS
  SELECT
    id,
    osm_id,
    osm_type,
    way,
    feature,
    ref,
    transition,
    structure,
    supporting,
    attachment,
    tensioning,
    insulator,
    position,
    note,
    description
  FROM catenary;

CREATE OR REPLACE FUNCTION electrification_catenary(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
RETURN (
  SELECT
    ST_AsMVT(tile, 'electrification_catenary', 4096, 'way')
  FROM (
    SELECT
      id,
      ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      feature,
      ref,
      transition
    FROM electrification_catenary_view
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
          "id": "string",
          "ref": "string",
          "feature": "string",
          "transition": "boolean"
        }
      }
    ]
  }
  $$::json || '$tj$';
END $do$;

CREATE OR REPLACE VIEW electrification_substation_view AS
  SELECT
    osm_id as id,
    osm_id,
    'W' as osm_type,
    way,
    feature,
    ref,
    name,
    location,
    operator,
    voltage,
    wikidata,
    wikimedia_commons,
    wikimedia_commons_file,
    image,
    mapillary,
    wikipedia,
    note,
    description
  FROM substation;

CREATE OR REPLACE FUNCTION electrification_substation(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
RETURN (
  SELECT
    ST_AsMVT(tile, 'electrification_substation', 4096, 'way')
  FROM (
    SELECT
      id,
      ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      name
    FROM electrification_substation_view
    WHERE way && ST_TileEnvelope(z, x, y)
  ) as tile
  WHERE way IS NOT NULL
);

DO $do$ BEGIN
  EXECUTE 'COMMENT ON FUNCTION electrification_substation IS $tj$' || $$
  {
    "vector_layers": [
      {
        "id": "electrification_substation",
        "fields": {
          "id": "integer",
          "name": "string"
        }
      }
    ]
  }
  $$::json || '$tj$';
END $do$;

--- Track ---

CREATE OR REPLACE FUNCTION track_railway_line_low(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
RETURN (
  SELECT
    ST_AsMVT(tile, 'track_railway_line_low', 4096, 'way')
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
      track_class,
      loading_gauge,
      max(rank) as rank
    FROM railway_line_low
    WHERE way && ST_TileEnvelope(z, x, y)
    GROUP BY
      feature,
      ref,
      standard_label,
      gauge0,
      gaugeint0,
      gauge_label,
      track_class,
      loading_gauge
    ORDER by
      rank NULLS LAST
  ) as tile
  WHERE way IS NOT NULL
);

DO $do$ BEGIN
  EXECUTE 'COMMENT ON FUNCTION track_railway_line_low IS $tj$' || $$
  {
    "vector_layers": [
      {
        "id": "track_railway_line_low",
        "fields": {
          "id": "string",
          "feature": "string",
          "state": "string",
          "usage": "string",
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

--- Operator ---

CREATE OR REPLACE FUNCTION operator_railway_line_low(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
RETURN (
  SELECT
    ST_AsMVT(tile, 'operator_railway_line_low', 4096, 'way')
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
      any_value(operator_color) as operator_color,
      any_value(operator_bright) as operator_bright,
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
          "id": "string",
          "feature": "string",
          "state": "string",
          "usage": "string",
          "ref": "string",
          "standard_label": "string",
          "operator": "string",
          "operator_color": "string",
          "operator_bright": "string",
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
    ST_AsMVT(tile, 'operator_railway_symbols', 4096, 'way')
  FROM (
    SELECT
      ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      id,
      feature,
      ref
    FROM poi_view
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
          "id": "string",
          "feature": "string",
          "ref": "string"
        }
      }
    ]
  }
  $$::json || '$tj$';
END $do$;

--- Route ---

CREATE OR REPLACE FUNCTION route_railway_line_low(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
RETURN (
  SELECT
    ST_AsMVT(tile, 'route_railway_line_low', 4096, 'way')
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
      (select count(*) from route_line rl join routes r on rl.route_id = r.osm_id where rl.line_id = l.osm_id) as route_count,
      ref,
      standard_label,
      max(rank) as rank
    FROM railway_line_low l
    WHERE way && ST_TileEnvelope(z, x, y)
    GROUP BY
      osm_id,
      feature,
      ref,
      standard_label,
      highspeed
    ORDER by
      route_count NULLS FIRST,
      rank NULLS LAST
  ) as tile
  WHERE way IS NOT NULL
);

DO $do$ BEGIN
  EXECUTE 'COMMENT ON FUNCTION route_railway_line_low IS $tj$' || $$
  {
    "vector_layers": [
      {
        "id": "route_railway_line_low",
        "fields": {
          "id": "string",
          "feature": "string",
          "state": "string",
          "usage": "string",
          "route_count": "integer",
          "ref": "string",
          "standard_label": "string"
        }
      }
    ]
  }
  $$::json || '$tj$';
END $do$;
