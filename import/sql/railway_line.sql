-- Views for railway lines grouped and simplified for low zooms

CREATE OR REPLACE VIEW railway_line_low_grouped_view AS
  SELECT feature, ref, name, highspeed, radio, maxspeed, speed_label, train_protection,train_protection_construction ,electrification_state,voltage, frequency, maximum_current,gauges[0],track_class,loading_gauge,passenger_lines,CASE
                                                                                                                                                                                                                                      WHEN ARRAY[owner] <@ operator THEN owner
                                                                                                                                                                                                                                      ELSE operator[1]
    END as primary_operator , max(rank) as rank,ST_Simplify( (ST_Dump(ST_LineMerge(ST_Collect(way)))).geom, 100000) as way, MIN(id) as id
  FROM railway_line WHERE state = 'present' AND feature IN ('rail', 'ferry') AND usage = 'main' AND service IS NULL GROUP BY feature, ref, name, highspeed, radio, maxspeed, speed_label, train_protection,train_protection_construction ,electrification_state,voltage, frequency, maximum_current,gauges[0],track_class,loading_gauge,passenger_lines,primary_operator;

CREATE MATERIALIZED VIEW IF NOT EXISTS railway_line_low_grouped AS
  SELECT
    *
  FROM railway_line_low_grouped_view;
