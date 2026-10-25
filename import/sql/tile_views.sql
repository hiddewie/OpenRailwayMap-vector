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
    SELECT
      id,
      ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      way_length,
      feature,
      state,
      usage,
      service,
      highspeed,
      preserved,
      tunnel,
      bridge,
      name,
      ref,
      track_ref,
      track_class,
      preferred_direction,
      rank,
      maxspeed,
      speed_label,
      train_protection_rank,
      train_protection[1] as train_protection0,
      train_protection[2] as train_protection1,
      train_protection[3] as train_protection2,
      train_protection_construction_rank,
      train_protection_construction,
      electrification_state,
      voltage,
      frequency,
      maximum_current,
      future_voltage,
      future_frequency,
      future_maximum_current,
      array_to_string(gauges, ', ') as gauges,
      gaugeint0,
      gauge0,
      gaugeint1,
      gauge1,
      gaugeint2,
      gauge2,
      loading_gauge,
      operator,
      operator_color,
      operator_bright,
      primary_operator,
      owner,
      route_count,
      passenger_lines,
      rack,
      radio
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
          state IN ('present', 'construction', 'proposed', 'disused')
            AND (service IS NULL OR service IN ('spur', 'yard'))
            AND (
              feature IN ('rail', 'ferry', 'narrow_gauge', 'light_rail')
                OR (feature IN ('monorail', 'subway', 'tram') AND service IS NULL)
            )
        ELSE
          true
      END
    ORDER by
      coalesce(layer, 0),
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
          "name": "string",
          "track_ref": "string",
          "maxspeed": "number",
          "speed_label": "string",
          "train_protection0": "string",
          "train_protection1": "string",
          "train_protection2": "string",
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
          "gauge0": "string",
          "gaugeint0": "number",
          "gauge1": "string",
          "gaugeint1": "number",
          "gauge2": "string",
          "gaugeint2": "number",
          "gauges": "string",
          "loading_gauge": "string",
          "track_class": "string",
          "operator": "string",
          "operator_color": "string",
          "operator_bright": "string",
          "primary_operator": "string",
          "owner": "string",
          "route_count": "integer",
          "passenger_lines": "integer",
          "rack": "string",
          "radio": "string"
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
    preserved,
    ref,
    name,
    speed_label,
    maxspeed,
    train_protection_rank,
    train_protection,
    train_protection_construction_rank,
    train_protection_construction,
    electrification_state,
    voltage,
    frequency,
    maximum_current,
    gaugeint0,
    gauge0,
    loading_gauge,
    track_class,
    operator,
    operator_color,
    operator_bright,
    primary_operator,
    owner,
    passenger_lines,
    radio,
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
      id,
      ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), 4096, 64, true) as way,
      feature,
      state,
      highspeed,
      radio
    FROM railway_line_low_grouped l
    WHERE way && ST_TileEnvelope(z, x, y)
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
          "highspeed": "boolean",
          "radio": "string"
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
    center,
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
      ST_AsMVTGeom(center, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      id,
      map_reference as label,
      name,
      COALESCE(localize(name_tags, 'name:', string_to_array(query->>'lang', ',')), name) AS localized_name,
      station_size,
      operator_color,
      operator_bright
    FROM railway_text_stations
    WHERE buffered && ST_TileEnvelope(z, x, y)
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
      ST_AsMVTGeom(center, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      id,
      map_reference as label,
      name,
      COALESCE(localize(name_tags, 'name:', string_to_array(query->>'lang', ',')), name) AS localized_name,
      station_size,
      operator_color,
      operator_bright
    FROM railway_text_stations
    WHERE buffered && ST_TileEnvelope(z, x, y)
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
      ST_AsMVTGeom(center, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      id,
      state,
      feature,
      station,
      station_size,
      map_reference as label,
      name,
      COALESCE(localize(name_tags, 'name:', string_to_array(query->>'lang', ',')), name) AS localized_name,
      count,
      operator_color,
      operator_bright
    FROM railway_text_stations
    WHERE buffered && ST_TileEnvelope(z, x, y)
      -- conditionally include features based on zoom level
      AND CASE
        -- Zooms < 8 are handled in the low and medium zoom tiles
        WHEN z < 9 THEN
          state = 'present'
            AND feature IN ('station', 'yard')
            AND NOT (station IN ('light_rail', 'subway', 'monorail', 'funicular', 'miniature'))
        WHEN z < 10 THEN
          state = 'present'
            AND feature IN ('station', 'yard', 'halt')
            AND NOT (station IN ('light_rail', 'tram', 'subway', 'monorail', 'funicular', 'miniature'))
        WHEN z < 11 THEN
          state NOT IN ('disused', 'abandoned', 'razed')
            AND NOT (station IN ('tram', 'funicular', 'miniature'))
        WHEN z < 12 THEN
          state NOT IN ('abandoned', 'razed')
            AND NOT (station IN ('funicular', 'miniature'))
        ELSE
          true
      END
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
    center,
    id,
    osm_id,
    osm_type,
    feature,
    ref,
    operator,
    name,
    minzoom,
    type,
    rank,
    position,
    radio,
    emergency_phone,
    diameter,
    wikidata,
    wikimedia_commons,
    wikimedia_commons_file,
    image,
    mapillary,
    wikipedia,
    note,
    description
  FROM pois
  WHERE
    -- Level crossings grouped are covered by level_crossings_grouped_view
    type != 'level_crossing';

CREATE OR REPLACE FUNCTION points_of_interest(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
RETURN (
  SELECT
    ST_AsMVT(tile, 'points_of_interest', 4096, 'way')
  FROM (
    SELECT
      ST_AsMVTGeom(center, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      id,
      feature,
      type,
      ref
    FROM poi_view
    WHERE way && ST_TileEnvelope(z, x, y)
      AND z >= minzoom
    ORDER BY rank DESC
  ) as tile
  WHERE way IS NOT NULL
);

DO $do$ BEGIN
  EXECUTE 'COMMENT ON FUNCTION points_of_interest IS $tj$' || $$
  {
    "vector_layers": [
      {
        "id": "points_of_interest",
        "fields": {
          "id": "string",
          "feature": "string",
          "type": "string",
          "ref": "string"
        }
      }
    ]
  }
  $$::json || '$tj$';
END $do$;

CREATE OR REPLACE FUNCTION points_of_interest_areas(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
RETURN (
  SELECT
    ST_AsMVT(tile, 'points_of_interest_areas', 4096, 'way')
  FROM (
    SELECT
      ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      id,
      type
    FROM poi_view
    WHERE way && ST_TileEnvelope(z, x, y)
      AND z >= minzoom
      AND osm_type = 'W'
    ORDER BY rank DESC
  ) as tile
  WHERE way IS NOT NULL
);

DO $do$ BEGIN
  EXECUTE 'COMMENT ON FUNCTION points_of_interest_areas IS $tj$' || $$
  {
    "vector_layers": [
      {
        "id": "points_of_interest_areas",
        "fields": {
          "id": "string",
          "type": "string"
        }
      }
    ]
  }
  $$::json || '$tj$';
END $do$;

CREATE OR REPLACE VIEW level_crossings_grouped_view AS
  SELECT
    lcg.id as id,
    lcg.buffered,
    lcg.center,
    array_agg(osm_id ORDER BY osm_id) as osm_id,
    array_agg(osm_type ORDER BY osm_id) as osm_type,
    lcg.feature,
    lcg.ref,
    lcg.count,
    nullif(array_remove(array_agg(DISTINCT operator), null), '{}'::text[]) as operator,
    nullif(array_remove(array_agg(DISTINCT name), null), '{}'::text[]) as name,
    min(minzoom) as minzoom,
    nullif(array_remove(array_agg(DISTINCT type), null), '{}'::text[]) as type,
    min(rank) as rank,
    nullif(array_remove(string_to_array(array_to_string(array_agg(DISTINCT array_to_string(position, U&'\001E')), U&'\001E'), U&'\001E'), null), '{}'::text[]) as position,
    nullif(array_remove(array_agg(DISTINCT emergency_phone), null), '{}'::text[]) as emergency_phone,
    nullif(array_remove(array_agg(DISTINCT wikidata), null), '{}'::text[]) as wikidata,
    nullif(array_remove(array_agg(DISTINCT wikimedia_commons), null), '{}'::text[]) as wikimedia_commons,
    nullif(array_remove(array_agg(DISTINCT wikimedia_commons_file), null), '{}'::text[]) as wikimedia_commons_file,
    nullif(array_remove(array_agg(DISTINCT image), null), '{}'::text[]) as image,
    nullif(array_remove(array_agg(DISTINCT mapillary), null), '{}'::text[]) as mapillary,
    nullif(array_remove(array_agg(DISTINCT wikipedia), null), '{}'::text[]) as wikipedia,
    nullif(array_remove(array_agg(DISTINCT note), null), '{}'::text[]) as note,
    nullif(array_remove(array_agg(DISTINCT description), null), '{}'::text[]) as description
  FROM level_crossings_grouped lcg
  JOIN pois p
    ON p.id = ANY(lcg.level_crossing_ids)
  GROUP BY lcg.id, lcg.buffered, lcg.center, lcg.feature, lcg.ref, lcg.count;

CREATE OR REPLACE FUNCTION level_crossings_grouped(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
RETURN (
  SELECT
    ST_AsMVT(tile, 'level_crossings_grouped', 4096, 'way')
  FROM (
    SELECT
      ST_AsMVTGeom(center, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      id,
      ref,
      feature
    FROM level_crossings_grouped_view
    WHERE buffered && ST_TileEnvelope(z, x, y)
  ) as tile
  WHERE way IS NOT NULL
);

DO $do$ BEGIN
  EXECUTE 'COMMENT ON FUNCTION level_crossings_grouped IS $tj$' || $$
  {
    "vector_layers": [
      {
        "id": "level_crossings_grouped",
        "fields": {
          "id": "string",
          "ref": "string",
          "feature": "string"
        }
      }
    ]
  }
  $$::json || '$tj$';
END $do$;

CREATE OR REPLACE FUNCTION level_crossings_grouped_buffered(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
RETURN (
  SELECT
    ST_AsMVT(tile, 'level_crossings_grouped_buffered', 4096, 'way')
  FROM (
    SELECT
      ST_AsMVTGeom(buffered, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      id
    FROM level_crossings_grouped_view
    WHERE buffered && ST_TileEnvelope(z, x, y)
      AND count > 1
  ) as tile
  WHERE way IS NOT NULL
);

DO $do$ BEGIN
  EXECUTE 'COMMENT ON FUNCTION level_crossings_grouped_buffered IS $tj$' || $$
  {
    "vector_layers": [
      {
        "id": "level_crossings_grouped_buffered",
        "fields": {
          "id": "string"
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
    st_length(st_transform(way, 4326), false) as length,
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
    operator,
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

CREATE OR REPLACE VIEW standard_interlocking_view AS
  SELECT
    i.osm_id as id,
    i.osm_id,
    'R' as osm_type,
    i.has_facility,
    center,
    buffered,
    feature,
    name,
    name_tags,
    "references",
    operator,
    owner,
    network,
    wikidata,
    wikimedia_commons,
    wikimedia_commons_file,
    image,
    mapillary,
    wikipedia,
    note,
    description
  FROM interlocking_buffered ib
  JOIN interlocking i
    ON ib.id = i.osm_id;

CREATE OR REPLACE FUNCTION standard_interlocking(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
RETURN (
  SELECT
    ST_AsMVT(tile, 'standard_interlocking', 4096, 'way')
  FROM (
    SELECT
      id,
      ST_AsMVTGeom(buffered, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way
    FROM standard_interlocking_view
    WHERE buffered && ST_TileEnvelope(z, x, y)
  ) as tile
  WHERE way IS NOT NULL
);

DO $do$ BEGIN
  EXECUTE 'COMMENT ON FUNCTION standard_interlocking IS $tj$' || $$
  {
    "vector_layers": [
      {
        "id": "standard_interlocking",
        "fields": {
          "id": "integer"
        }
      }
    ]
  }
  $$::json || '$tj$';
END $do$;

CREATE OR REPLACE FUNCTION standard_interlocking_text(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
RETURN (
  SELECT
    ST_AsMVT(tile, 'standard_interlocking_text', 4096, 'way')
  FROM (
    SELECT
      id,
      ST_AsMVTGeom(center, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      name
    FROM standard_interlocking_view
    WHERE buffered && ST_TileEnvelope(z, x, y)
      AND NOT has_facility
  ) as tile
  WHERE way IS NOT NULL
);

DO $do$ BEGIN
  EXECUTE 'COMMENT ON FUNCTION standard_interlocking_text IS $tj$' || $$
  {
    "vector_layers": [
      {
        "id": "standard_interlocking_text",
        "fields": {
          "id": "integer",
          "name": "string"
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
      id,
      ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      feature,
      state,
      maxspeed
    FROM railway_line_low_grouped
    WHERE way && ST_TileEnvelope(z, x, y)
      AND feature != 'ferry'
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
          "maxspeed": "number"
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
      id,
      ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      feature,
      state,
      train_protection0,
      train_protection_construction
    FROM railway_line_low_grouped
    WHERE way && ST_TileEnvelope(z, x, y)
      AND feature != 'ferry'
    ORDER by
      train_protection_rank DESC,
      train_protection_construction_rank DESC NULLS LAST
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
          "train_protection0": "string",
          "train_protection_construction": "string"
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
      id,
      ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      feature,
      state,
      electrification_state,
      voltage,
      frequency,
      maximum_current
    FROM railway_line_low_grouped
    WHERE way && ST_TileEnvelope(z, x, y)
      AND feature != 'ferry'
    ORDER by
      voltage NULLS FIRST,
      frequency NULLS FIRST
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
          "electrification_state": "string",
          "frequency": "number",
          "voltage": "integer",
          "maximum_current": "integer"
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
    operator,
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
    frequency,
    conversion,
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
      id,
      ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      feature,
      state,
      usage,
      gauge0,
      gaugeint0,
      track_class,
      loading_gauge,
      passenger_lines
    FROM railway_line_low_grouped
    WHERE way && ST_TileEnvelope(z, x, y)
      AND feature != 'ferry'
    ORDER by
      gaugeint0 NULLS FIRST
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
          "gauge0": "string",
          "gaugeint0": "number",
          "track_class": "string",
          "loading_gauge": "string",
          "passenger_lines": "number"
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
      l.id,
      ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
      feature,
      state,
      operator_color
    FROM railway_line_low_grouped l
    WHERE way && ST_TileEnvelope(z, x, y)
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
          "operator_color": "string"
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
      id,
      ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), 4096, 64, true) as way,
      feature,
      state,
      route_count
    FROM railway_line_low_grouped
    WHERE way && ST_TileEnvelope(z, x, y)
    ORDER by route_count
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
          "route_count": "integer"
        }
      }
    ]
  }
  $$::json || '$tj$';
END $do$;
