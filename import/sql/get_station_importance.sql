-- Assign a numeric rank to passenger train stations

-- Relevant objects referenced by route relations: railway=station, railway=halt, public_transport=stop_position, public_transport=platform, railway=platform

-- Get OSM IDs route relations referencing a stop position or a station/halt node
CREATE OR REPLACE VIEW stops_and_route_relations AS
  SELECT
    r.osm_id AS rel_id,
    sp.osm_id AS stop_id,
    sp.name AS stop_name,
    sp.way AS geom
  FROM stop_positions AS sp
  JOIN routes AS r
    ON r.stop_ref_ids @> Array[sp.osm_id];

-- Get OSM IDs of route relations referencing a platform (all except nodes)
CREATE OR REPLACE VIEW platforms_route_relations AS
  SELECT
    r.osm_id AS rel_id,
    sp.osm_id AS stop_id,
    sp.name AS stop_name,
    sp.way AS geom
  FROM platforms AS sp
  JOIN routes AS r
    ON r.platform_ref_ids @> Array[sp.osm_id];

-- Cluster stop positions with equal name
CREATE OR REPLACE VIEW stop_positions_and_their_routes_clustered AS
  SELECT
    ST_CollectionExtract(unnest(ST_ClusterWithin(srr.geom, 400)), 1) AS geom,
    srr.stop_name AS stop_name,
    ARRAY_AGG(DISTINCT(srr.rel_id)) AS route_ids
  FROM stops_and_route_relations AS srr
  GROUP BY stop_name, geom;

-- Cluster platforms in close distance
CREATE OR REPLACE VIEW platforms_and_their_routes_clustered AS
  WITH clusters as (
    SELECT
      ST_ClusterDBSCAN(srr.geom, 50, 1) OVER () AS cluster_id,
      srr.geom,
      srr.rel_id
    FROM platforms_route_relations AS srr
  )
  SELECT
    ST_collect(clusters.geom) as geom,
    ARRAY_AGG(DISTINCT(clusters.rel_id)) AS route_ids
  FROM clusters
  group by cluster_id;

-- Join clustered stop positions with station nodes
CREATE OR REPLACE VIEW station_nodes_stop_positions_rel_count AS
  SELECT
    id,
    array_agg(route_id) as route_ids
  FROM (
    SELECT
      s.id as id,
      UNNEST(sprc.route_ids) as route_id
    FROM stations AS s
    LEFT OUTER JOIN stop_positions_and_their_routes_clustered AS sprc
      ON (sprc.stop_name = s.name AND ST_DWithin(s.way, sprc.geom, 400))

    UNION ALL

    SELECT
      s.id as id,
      r.osm_id as route_id
    FROM stations s
    JOIN stop_areas sa
      ON (ARRAY[s.osm_id] <@ sa.node_ref_ids AND s.osm_type = 'N')
        OR (ARRAY[s.osm_id] <@ sa.way_ref_ids AND s.osm_type = 'W')
    JOIN routes r
      ON sa.stop_ref_ids && r.stop_ref_ids
  ) sr
  GROUP BY id;

-- Join clustered platforms with station nodes
CREATE OR REPLACE VIEW station_nodes_platforms_rel_count AS
  SELECT
    id,
    array_agg(route_id) as route_ids
  FROM (
    SELECT
      s.id as id,
      UNNEST(sprc.route_ids) as route_id
    FROM stations AS s
    JOIN platforms_and_their_routes_clustered AS sprc
      ON (ST_DWithin(s.way, sprc.geom, 60))
    WHERE s.feature IN ('station', 'halt', 'tram_stop')

    UNION ALL

    SELECT
      s.id as id,
      r.osm_id as route_id
    FROM stations s
    JOIN stop_areas sa
      ON (ARRAY[s.osm_id] <@ sa.node_ref_ids AND s.osm_type = 'N')
        OR (ARRAY[s.osm_id] <@ sa.way_ref_ids AND s.osm_type = 'W')
    JOIN routes r
      ON sa.platform_ref_ids && r.platform_ref_ids
  ) sr
  GROUP BY id;

-- Clustered stations without route counts
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
    ST_Centroid(ST_RemoveRepeatedPoints(ST_Collect(way))) as center,
    ST_Buffer(ST_ConvexHull(ST_RemoveRepeatedPoints(ST_Collect(way))), 50) as buffered,
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

CREATE MATERIALIZED VIEW IF NOT EXISTS stations_with_route_count AS
  SELECT
    id,
    max(route_count) as route_count
  FROM (
    SELECT
      id,
      COUNT(DISTINCT route_id) AS route_count
    FROM (
      SELECT
        id,
        UNNEST(route_ids) AS route_id
      FROM station_nodes_stop_positions_rel_count

      UNION ALL

      SELECT
        id,
        UNNEST(route_ids) AS route_id
      FROM station_nodes_platforms_rel_count
    ) stations_that_have_routes
    GROUP BY id

    UNION ALL

    SELECT
      id,
      0 AS route_count
    FROM stations
  ) all_stations_with_route_count
  GROUP BY id;

CREATE INDEX IF NOT EXISTS stations_with_route_count_idx
  ON stations_with_route_count
    USING btree(id);

-- Final table with station nodes and the number of route relations
-- needs about 3 to 4 minutes for whole Germany
-- or about 20 to 30 minutes for the whole planet
CREATE MATERIALIZED VIEW IF NOT EXISTS grouped_stations_with_route_count AS
  SELECT
    -- Aggregated station columns
    array_agg(DISTINCT station_id ORDER BY station_id) as station_ids,
    hstore(string_agg(nullif(name_tags::text, ''), ',')) as name_tags,
    array_agg(osm_id ORDER BY osm_id) as osm_ids,
    array_agg(osm_type ORDER BY osm_id) as osm_types,
    array_remove(array_agg(DISTINCT s.operator ORDER BY s.operator), null) as operator,
    array_remove(array_agg(DISTINCT s.network ORDER BY s.network), null) as network,
    array_remove(string_to_array(array_to_string(array_agg(DISTINCT array_to_string(s.position, U&'\\001E')), U&'\\001E'), U&'\\001E'), null) as position,
    array_remove(array_agg(DISTINCT s.wikidata ORDER BY s.wikidata), null) as wikidata,
    array_remove(array_agg(DISTINCT s.wikimedia_commons ORDER BY s.wikimedia_commons), null) as wikimedia_commons,
    array_remove(array_agg(DISTINCT s.wikimedia_commons_file ORDER BY s.wikimedia_commons_file), null) as wikimedia_commons_file,
    array_remove(array_agg(DISTINCT s.wikipedia ORDER BY s.wikipedia), null) as wikipedia,
    array_remove(array_agg(DISTINCT s.image ORDER BY s.image), null) as image,
    array_remove(array_agg(DISTINCT s.mapillary ORDER BY s.mapillary), null) as mapillary,
    array_remove(array_agg(DISTINCT s.note ORDER BY s.note), null) as note,
    array_remove(array_agg(DISTINCT s.description ORDER BY s.description), null) as description,
    -- Aggregated route count columns
    max(sr.route_count) as route_count,
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
  JOIN stations_with_route_count sr
    ON clustered.station_id = sr.id
  GROUP BY clustered.id;

CREATE INDEX IF NOT EXISTS grouped_stations_with_route_count_center_index
  ON grouped_stations_with_route_count
    USING GIST(center);

CREATE INDEX IF NOT EXISTS grouped_stations_with_route_count_buffered_index
  ON grouped_stations_with_route_count
    USING GIST(buffered);

CREATE INDEX IF NOT EXISTS grouped_stations_with_route_count_osm_ids_index
  ON grouped_stations_with_route_count
    USING GIN(osm_ids);

CLUSTER grouped_stations_with_route_count
  USING grouped_stations_with_route_count_center_index;

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
    FROM grouped_stations_with_route_count
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
