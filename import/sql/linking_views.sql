CREATE MATERIALIZED VIEW IF NOT EXISTS stations_stop_areas AS
  SELECT
    s.id AS station_id,
    sa.osm_id as stop_area_osm_id
  FROM (
    SELECT
      osm_id,
      UNNEST(sa.node_ref_ids) as station_osm_id
    FROM stop_areas sa
  ) sa
  JOIN stations s
    ON s.osm_id = station_osm_id AND s.osm_type = 'N'

  UNION

  SELECT
    s.id AS station_id,
    sa.osm_id as stop_area_osm_id
  FROM (
    SELECT
    osm_id,
    UNNEST(sa.way_ref_ids) as station_osm_id
    FROM stop_areas sa
  ) sa
  JOIN stations s
    ON s.osm_id = station_osm_id AND s.osm_type = 'W';

CREATE INDEX IF NOT EXISTS stations_stop_areas_station_id
  ON stations_stop_areas
    USING btree(station_id);

CREATE INDEX IF NOT EXISTS stations_stop_areas_stop_area_osm_id
  ON stations_stop_areas
    USING btree(stop_area_osm_id);

CREATE MATERIALIZED VIEW IF NOT EXISTS stop_area_entrances AS
  SELECT
    se.osm_id AS entrance_osm_id,
    sa.osm_id as stop_area_osm_id
  FROM (
    SELECT
      osm_id,
      UNNEST(sa.node_ref_ids) as entrance_osm_id
    FROM stop_areas sa
  ) sa
  JOIN station_entrances se
    ON se.osm_id = entrance_osm_id;

CREATE INDEX IF NOT EXISTS stop_area_entrances_entrance_osm_id
  ON stop_area_entrances
    USING btree(entrance_osm_id);

CREATE INDEX IF NOT EXISTS stop_area_entrances_stop_area_osm_id
  ON stop_area_entrances
    USING btree(stop_area_osm_id);
