-- Views for railway lines grouped and simplified for low zooms

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

CREATE INDEX line_route_count_id
  ON line_route_count (id);

CREATE OR REPLACE VIEW railway_line_low_grouped_view AS
  SELECT
    MIN(l.id) AS id,
    ST_Simplify((ST_Dump(ST_LineMerge(ST_Collect(way)))).geom, 100000) AS way,
    feature,
    l.ref,
    l.name,
    highspeed,
    radio,
    maxspeed,
    speed_label,
    train_protection,
    train_protection_construction ,
    electrification_state,
    voltage,
    frequency,
    maximum_current,
    railway_to_int(gauges[1]) as gaugeint0,
    gauges[1] as gauge0,
    track_class,
    loading_gauge,
    passenger_lines,
    CASE
      WHEN ARRAY[owner] <@ l.operator THEN owner
      ELSE l.operator[1]
    END AS primary_operator,
    coalesce(rl.route_count, 0) AS route_count,
    max(rank) as rank
  FROM railway_line l
  LEFT JOIN line_route_count rl
    ON rl.id = l.id
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
    train_protection,
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
    primary_operator,
    route_count;

CREATE MATERIALIZED VIEW IF NOT EXISTS railway_line_low_grouped AS
  SELECT
    *
  FROM railway_line_low_grouped_view;

CREATE INDEX railway_line_low_grouped_way
  ON railway_line_low_grouped
    USING GIST(way);
