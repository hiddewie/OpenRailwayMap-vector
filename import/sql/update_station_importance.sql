BEGIN;

TRUNCATE stations_with_importance;

INSERT INTO stations_with_importance (station_id, way, importance, di_importance)
  SELECT
    s.id,
    ST_Centroid(s.way),
    siv.importance,
    -- For the discrite isolation, only consider stations shown at low zoom levels
    CASE
      WHEN feature = 'station' AND state = 'present' AND (station IS NULL OR station NOT IN ('light_rail', 'monorail', 'subway')) THEN siv.importance
      ELSE 0
    END as di_importance
  FROM stations_with_importance_view siv
  JOIN stations s
    ON s.id = siv.id;

COMMIT;
