BEGIN;

TRUNCATE stations_with_importance;

INSERT INTO stations_with_importance (id, way, importance)
  SELECT
    s.id as id,
    ST_Centroid(s.way) as way,
    siv.importance
  FROM stations_with_importance_view siv
  JOIN stations s
    ON s.id = siv.id;

COMMIT;
