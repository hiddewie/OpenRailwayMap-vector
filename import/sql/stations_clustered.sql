-- Clustered stations without importance
CREATE MATERIALIZED VIEW IF NOT EXISTS stations_clustered AS
  SELECT
    row_number() over (order by name, station, railway_ref, uic_ref, feature) as id,
    name,
    station,
    railway_ref,
    uic_ref,
    feature,
    state,
    array_agg(facilities.id) as station_ids,
    CASE feature
      WHEN 'yard' THEN ST_PointOnSurface(ST_RemoveRepeatedPoints(ST_Collect(way)))
      ELSE ST_Centroid(ST_ConvexHull(ST_RemoveRepeatedPoints(ST_Collect(way))))
    END as center,
    CASE feature
      WHEN 'yard' THEN ST_Buffer(ST_RemoveRepeatedPoints(ST_Collect(way)), 10)
      ELSE ST_Buffer(ST_ConvexHull(ST_RemoveRepeatedPoints(ST_Collect(way))), 50)
    END as buffered,
    ST_NumGeometries(ST_RemoveRepeatedPoints(ST_Collect(way))) as count
  FROM (
    SELECT
      *,
      ST_ClusterDBSCAN(way, 400, 1) OVER (PARTITION BY name, station, railway_ref, uic_ref, feature, state) AS cluster_id
    FROM (
      SELECT
        st_collect(any_value(s.way), st_collect(distinct q.way)) as way,
        name,
        station,
        railway_ref,
        uic_ref,
        feature,
        state,
        id
      FROM stations s
      left join stop_areas sa
        ON (ARRAY[s.osm_id] <@ sa.node_ref_ids AND s.osm_type = 'N')
          OR (ARRAY[s.osm_id] <@ sa.way_ref_ids AND s.osm_type = 'W')
          OR (ARRAY[s.osm_id] <@ sa.stop_ref_ids AND s.osm_type = 'N')
      left join (
        select
          sa.osm_id as stop_area_id,
          se.way
        from stop_areas sa
        join station_entrances se
          on array[se.osm_id] <@ sa.node_ref_ids

        union all

        select
          sa.osm_id as stop_area_id,
          pl.way
        from stop_areas sa
        join platforms pl
          on array[pl.osm_id] <@ sa.platform_ref_ids
      ) q on q.stop_area_id = sa.osm_id
      group by name, station, railway_ref, uic_ref, feature, state, id
    ) stations_with_entrances
  ) AS facilities
  GROUP BY cluster_id, name, station, railway_ref, uic_ref, feature, state;

CREATE INDEX IF NOT EXISTS stations_clustered_station_ids
  ON stations_clustered
    USING gin(station_ids);

-- Final table with station nodes and the number of route relations
-- needs about 3 to 4 minutes for whole Germany
-- or about 20 to 30 minutes for the whole planet
CREATE MATERIALIZED VIEW IF NOT EXISTS grouped_stations_with_importance AS
  SELECT
    -- Aggregated station columns
    array_agg(DISTINCT station_id ORDER BY station_id) as station_ids,
    hstore(string_agg(nullif(name_tags::text, ''), ',')) as name_tags,
    array_agg(osm_id ORDER BY osm_id) as osm_ids,
    array_agg(osm_type ORDER BY osm_id) as osm_types,
    array_remove(string_to_array(array_to_string(array_agg(DISTINCT array_to_string(s.operator, U&'\001E')), U&'\001E'), U&'\001E'), null) as operator,
    array_remove(string_to_array(array_to_string(array_agg(DISTINCT array_to_string(s.network, U&'\001E')), U&'\001E'), U&'\001E'), null) as network,
    array_remove(string_to_array(array_to_string(array_agg(DISTINCT array_to_string(s.position, U&'\001E')), U&'\001E'), U&'\001E'), null) as position,
    array_remove(array_agg(DISTINCT s.wikidata ORDER BY s.wikidata), null) as wikidata,
    array_remove(array_agg(DISTINCT s.wikimedia_commons ORDER BY s.wikimedia_commons), null) as wikimedia_commons,
    array_remove(array_agg(DISTINCT s.wikimedia_commons_file ORDER BY s.wikimedia_commons_file), null) as wikimedia_commons_file,
    array_remove(array_agg(DISTINCT s.wikipedia ORDER BY s.wikipedia), null) as wikipedia,
    array_remove(array_agg(DISTINCT s.image ORDER BY s.image), null) as image,
    array_remove(array_agg(DISTINCT s.mapillary ORDER BY s.mapillary), null) as mapillary,
    array_remove(array_agg(DISTINCT s.note ORDER BY s.note), null) as note,
    array_remove(array_agg(DISTINCT s.description ORDER BY s.description), null) as description,
    array_remove(string_to_array(array_to_string(array_agg(DISTINCT array_to_string(s.yard_purpose, U&'\001E')), U&'\001E'), U&'\001E'), null) as yard_purpose,
    bool_or(s.yard_hump) as yard_hump,
    -- Aggregated importance
    max(sr.importance) as importance,
    max(sr.discr_iso) as discr_iso,
    -- Re-grouped clustered stations columns
    clustered.id as id,
    any_value(clustered.center) as center,
    any_value(clustered.buffered) as buffered,
    any_value(clustered.name) as name,
    any_value(clustered.station) as station,
    any_value(clustered.railway_ref) as railway_ref,
    any_value(clustered.uic_ref) as uic_ref,
    any_value(clustered.feature) as feature,
    any_value(clustered.state) as state,
    any_value(clustered.count) as count
  FROM (
    SELECT
      id,
      UNNEST(sc.station_ids) as station_id,
      name, station, railway_ref, uic_ref, feature, state, station_ids, center, buffered, count
    FROM stations_clustered sc
  ) clustered
  JOIN stations s
    ON clustered.station_id = s.id
  JOIN stations_with_importance sr
    ON clustered.station_id = sr.id
  GROUP BY clustered.id;

CREATE INDEX IF NOT EXISTS grouped_stations_with_importance_center_index
  ON grouped_stations_with_importance
    USING GIST(center);

CREATE INDEX IF NOT EXISTS grouped_stations_with_importance_buffered_index
  ON grouped_stations_with_importance
    USING GIST(buffered);

CREATE INDEX IF NOT EXISTS grouped_stations_with_importance_osm_ids_index
  ON grouped_stations_with_importance
    USING GIN(osm_ids);

CLUSTER grouped_stations_with_importance
  USING grouped_stations_with_importance_center_index;

CREATE MATERIALIZED VIEW IF NOT EXISTS stop_area_groups_buffered AS
  SELECT
    sag.osm_id,
    ST_Buffer(ST_ConvexHull(ST_RemoveRepeatedPoints(ST_Collect(gs.buffered))), 20) as way
  FROM stop_area_groups sag
  JOIN stop_areas sa
    ON ARRAY[sa.osm_id] <@ sag.stop_area_ref_ids
  JOIN stations s
    ON (ARRAY[s.osm_id] <@ sa.node_ref_ids AND s.osm_type = 'N')
      OR (ARRAY[s.osm_id] <@ sa.way_ref_ids AND s.osm_type = 'W')
      OR (ARRAY[s.osm_id] <@ sa.stop_ref_ids AND s.osm_type = 'N')
  JOIN (
    SELECT
      unnest(osm_ids) AS osm_id,
      unnest(osm_types) AS osm_type,
      buffered
    FROM grouped_stations_with_importance
  ) gs
    ON s.osm_id = gs.osm_id and s.osm_type = gs.osm_type
  GROUP BY sag.osm_id
  -- Only use station area groups that have more than one station area
  HAVING COUNT(distinct sa.osm_id) > 1;

CREATE INDEX IF NOT EXISTS stop_area_groups_buffered_index
  ON stop_area_groups_buffered
    USING GIST(way);

CLUSTER stop_area_groups_buffered
  USING stop_area_groups_buffered_index;
