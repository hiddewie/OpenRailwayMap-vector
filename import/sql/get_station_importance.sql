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
    s.id as id,
    sprc.route_ids AS route_ids
  FROM stations AS s
  LEFT OUTER JOIN stop_positions_and_their_routes_clustered AS sprc
    ON (sprc.stop_name = s.name AND ST_DWithin(s.way, sprc.geom, 400));

-- Join clustered platforms with station nodes
CREATE OR REPLACE VIEW station_nodes_platforms_rel_count AS
  SELECT
    s.id as id,
    sprc.route_ids AS route_ids
  FROM stations AS s
  JOIN platforms_and_their_routes_clustered AS sprc
    ON (ST_DWithin(s.way, sprc.geom, 60))
  WHERE s.railway IN ('station', 'halt', 'tram_stop');

-- Clustered stations without route counts
CREATE MATERIALIZED VIEW IF NOT EXISTS stations_clustered AS
  SELECT
    row_number() over (order by name, station, railway_ref, uic_ref, railway) as id,
    name,
    station,
    railway_ref,
    uic_ref,
    railway,
    array_agg(facilities.id) as station_ids,
    ST_Centroid(ST_RemoveRepeatedPoints(ST_Collect(way)) ) as center,
    ST_Buffer(ST_ConvexHull(ST_RemoveRepeatedPoints(ST_Collect(way))), 50) as buffered,
    ST_NumGeometries(ST_RemoveRepeatedPoints(ST_Collect(way))) as count
  FROM (
    SELECT
      *,
      ST_ClusterDBSCAN(way, 400, 1) OVER (PARTITION BY name, station, railway_ref, uic_ref, railway) AS cluster_id
    FROM stations
  ) AS facilities
  GROUP BY cluster_id, name, station, railway_ref, uic_ref, railway;

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
    array_agg(station_id ORDER BY station_id) as station_ids,
    hstore(string_agg(nullif(name_tags::text, ''), ',')) as name_tags,
    array_agg(osm_id ORDER BY osm_id) as osm_ids,
    array_remove(array_agg(DISTINCT s.operator ORDER BY s.operator), null) as operator,
    array_remove(array_agg(DISTINCT s.network ORDER BY s.network), null) as network,
    array_remove(array_agg(DISTINCT s.wikidata ORDER BY s.wikidata), null) as wikidata,
    array_remove(array_agg(DISTINCT s.wikimedia_commons ORDER BY s.wikimedia_commons), null) as wikimedia_commons,
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
    any_value(clustered.railway) as railway,
    any_value(clustered.count) as count
  FROM (
    SELECT
      id,
      UNNEST(sc.station_ids) as station_id,
      name, station, railway_ref, uic_ref, railway, station_ids, center, buffered, count
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
