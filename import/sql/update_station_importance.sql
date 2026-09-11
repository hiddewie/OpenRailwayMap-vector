BEGIN;

TRUNCATE stations_with_importance;

INSERT INTO stations_with_importance (station_id, way, importance)
  SELECT
    s.id,
    ST_Centroid(s.way),
    siv.importance
  FROM stations_with_importance_view siv
  JOIN stations s
    ON s.id = siv.id;

COMMIT;
