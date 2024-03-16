-- Table with signals including their azimuth based on the direction of the signal and the railway line
CREATE MATERIALIZED VIEW IF NOT EXISTS signals_with_azimuth AS
  SELECT
    s.*,
    degrees(ST_Azimuth(
      st_lineinterpolatepoint(sl.way, greatest(0, st_linelocatepoint(sl.way, ST_ClosestPoint(sl.way, s.way)) - 0.01)),
      st_lineinterpolatepoint(sl.way, least(1, st_linelocatepoint(sl.way, ST_ClosestPoint(sl.way, s.way)) + 0.01))
    )) + (CASE WHEN s.signal_direction = 'backward' THEN 180.0 ELSE 0.0 END) as azimuth
  FROM signals s
  CROSS JOIN LATERAL (
    SELECT line.way as way
    FROM railway_line line
    WHERE st_dwithin(s.way, line.way, 10) AND line.railway = 'rail' -- TODO use feature
    ORDER BY s.way <-> line.way
    LIMIT 1
  ) as sl
  WHERE
    (railway IN ('signal', 'buffer_stop') AND signal_direction IS NOT NULL)
    OR railway = 'derail';

CREATE INDEX IF NOT EXISTS signals_with_azimuth_geom_index
  ON signals_with_azimuth
  USING GIST(way);
