-- Views for railway lines, materialized for more efficient queries

CREATE MATERIALIZED VIEW line_route_count AS
  SELECT
    count(*) AS route_count,
    l.id AS id
  FROM railway_line l
  JOIN route_line rl
    ON rl.line_id = l.osm_id
  JOIN routes r
    ON rl.route_id = r.osm_id
  GROUP BY l.id;

CREATE UNIQUE INDEX line_route_count_id
  ON line_route_count (id);

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
    preserved,
    tunnel,
    bridge,
    r.name as name,
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
    rubber_tires,
    workrules,
    passenger_lines,
    rack,
    line_routes,
    rl.route_count as route_count,
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
      preserved,
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
      future_voltage,
      future_frequency,
      future_maximum_current,
      gauges,
      gauges[1] AS gauge0,
      gauges[2] AS gauge1,
      gauges[3] AS gauge2,
      loading_gauge,
      operator,
      owner,
      CASE
        WHEN ARRAY[owner] <@ operator THEN owner
        ELSE operator[1]
      END AS primary_operator,
      traffic_mode,
      radio,
      rubber_tires,
      workrules,
      passenger_lines,
      rack,
      (select array_agg(hstore(ARRAY[ARRAY['route_id', r.osm_id::text], ARRAY['color', coalesce(r.color, '')], ARRAY['label', coalesce(r.name, '')]]) order by r.osm_id) from route_line rl join routes r on rl.route_id = r.osm_id where rl.line_id = l.osm_id) as line_routes,
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
    ON ro.name = primary_operator
  LEFT JOIN line_route_count rl
    ON rl.id = r.id;

CREATE OR REPLACE VIEW railway_line_low_grouped_view AS
  SELECT
    MIN(l.id) AS id,
    ST_Simplify((ST_Dump(ST_LineMerge(ST_Collect(way)))).geom, 1000) AS way,
    feature,
    'present' as state,
    'main' as usage,
    null as service,
    l.ref,
    l.name,
    highspeed,
    radio,
    maxspeed,
    speed_label,
    train_protection[1] as train_protection0,
    max(train_protection_rank) as train_protection_rank,
    train_protection_construction,
    max(train_protection_construction_rank) as train_protection_construction_rank,
    electrification_state,
    voltage,
    frequency,
    maximum_current,
    gaugeint0,
    gauge0,
    track_class,
    loading_gauge,
    passenger_lines,
    operator_color,
    route_count,
    max(rank) as rank
  FROM railway_line_view l
  WHERE
    state = 'present' AND
    feature IN ('rail', 'ferry') AND
    usage = 'main' AND
    service IS NULL
  GROUP BY
    feature,
    l.ref,
    l.name,
    highspeed,
    radio,
    maxspeed,
    speed_label,
    train_protection0,
    train_protection_construction,
    electrification_state,
    voltage,
    frequency,
    maximum_current,
    gaugeint0,
    gauge0,
    track_class,
    loading_gauge,
    passenger_lines,
    operator_color,
    route_count;

CREATE MATERIALIZED VIEW IF NOT EXISTS railway_line_low_grouped AS
  SELECT
    *
  FROM railway_line_low_grouped_view;

CREATE INDEX railway_line_low_grouped_way
  ON railway_line_low_grouped
    USING GIST(way);

CLUSTER railway_line_low_grouped
  USING railway_line_low_grouped_way;
