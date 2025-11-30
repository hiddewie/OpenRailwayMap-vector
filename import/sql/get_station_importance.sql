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

CREATE OR REPLACE VIEW stations_with_importance_view AS
  SELECT
    id,
    1 + max(importance) as importance
  FROM (
    SELECT
      id,
      COUNT(DISTINCT route_id) AS importance
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

    -- Yards have no routes but measure track length instead
    SELECT
      s.id,
      -- The square root and factor are made to align the importance factors of yards
      --   with stations. A 320 km yard is equivalent to a station with 140 routes.
      SQRT(
        SUM(ST_Length(ST_Intersection(ST_Buffer(s.way, 50), l.way)))
      ) / 4 AS importance
    FROM stations s
    JOIN railway_line l
      ON ST_DWithin(s.way, l.way, 50)
    WHERE s.feature = 'yard'
    GROUP BY s.id

    UNION ALL

    SELECT
      id,
      0 AS importance
    FROM stations
  ) all_stations_with_importance
  GROUP BY id;

-- Not a materialized view because the Osm2Pgsql scripts update the discrete isolation values
CREATE TABLE IF NOT EXISTS stations_with_importance (
  id BIGINT NOT NULL PRIMARY KEY,
  way GEOMETRY NOT NULL,
  importance NUMERIC NOT NULL DEFAULT 0,
  discr_iso REAL NOT NULL DEFAULT 0.0, -- Column name is fixed
  irank BIGINT NOT NULL DEFAULT 0, -- Column name is fixed
  dirank BIGINT NOT NULL DEFAULT 0 -- Column name is fixed
);
