-- Assign a numeric rank to passenger train stations

-- Relevant objects referenced by route relations: railway=station, railway=halt, public_transport=stop_position, public_transport=platform, railway=platform

-- Get OSM IDs route relations referencing a stop position or a station/halt node
CREATE OR REPLACE VIEW stops_and_route_relations AS
  SELECT
      r.osm_id AS rel_id, sp.osm_id AS stop_id, sp.name AS stop_name, sp.way AS geom
    FROM stop_positions AS sp
    JOIN routes AS r
      ON r.stop_ref_ids @> Array[sp.osm_id]
  WHERE sp.name IS NOT NULL;

-- Get OSM IDs of route relations referencing a platform (all except nodes)
CREATE OR REPLACE VIEW platforms_route_relations AS
  SELECT
    r.osm_id AS rel_id, sp.osm_id AS stop_id, sp.name AS stop_name, sp.way AS geom
  FROM platforms AS sp
  JOIN routes AS r
    ON r.platform_ref_ids @> Array[-sp.osm_id];

-- Cluster stop positions with equal name
CREATE OR REPLACE VIEW stop_positions_and_their_routes_clustered AS
  SELECT ST_CollectionExtract(unnest(ST_ClusterWithin(srr.geom, 400)), 1) AS geom, srr.stop_name AS stop_name, ARRAY_AGG(DISTINCT(srr.rel_id)) AS route_ids
    FROM stops_and_route_relations AS srr
    GROUP BY stop_name, geom;

-- Cluster platforms in close distance
CREATE OR REPLACE VIEW platforms_and_their_routes_clustered AS
  WITH clusters as (
    SELECT
      ST_ClusterDBSCAN(srr.geom, 40, 1) OVER () AS cluster_id,
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
  SELECT s.osm_id, s.name AS name, s.station as station, s.label as label, s.railway AS railway, sprc.route_ids AS route_ids, s.way AS way
    FROM stations AS s
    LEFT OUTER JOIN stop_positions_and_their_routes_clustered AS sprc
      ON (sprc.stop_name = s.name AND ST_DWithin(s.way, sprc.geom, 400))
    WHERE s.railway IN ('station', 'halt', 'tram_stop', 'service_station', 'yard', 'junction', 'spur_junction', 'crossover', 'site', 'tram_stop');

-- Join clustered platforms with station nodes
CREATE OR REPLACE VIEW station_nodes_platforms_rel_count AS
  SELECT s.osm_id AS osm_id, s.name AS name, s.station as station, s.label as label, s.railway AS railway, sprc.route_ids AS route_ids, s.way AS way
    FROM stations AS s
    JOIN platforms_and_their_routes_clustered AS sprc
      ON (ST_DWithin(s.way, sprc.geom, 60))
    WHERE s.railway IN ('station', 'halt', 'tram_stop');

-- Final table with station nodes and the number of route relations
-- needs about 3 to 4 minutes for whole Germany
-- or about 20 to 30 minutes for the whole planet
CREATE MATERIALIZED VIEW IF NOT EXISTS stations_with_route_counts AS
  SELECT DISTINCT ON (osm_id, name, station, label, railway) osm_id, name, station, label, railway, route_count, way
    FROM (
      SELECT osm_id, name, station, label, railway, ARRAY_LENGTH(ARRAY_AGG(DISTINCT route_id), 1) AS route_count, way
        FROM (
          SELECT osm_id, name, station, label, railway, UNNEST(route_ids) AS route_id, way
            FROM station_nodes_stop_positions_rel_count
          UNION ALL
          SELECT osm_id, name, station, label, railway, UNNEST(route_ids) AS route_id, way
            FROM station_nodes_platforms_rel_count
        ) AS a
        GROUP BY osm_id, name, station, label, railway, way
      UNION ALL
      SELECT osm_id, name, station, label, railway, 0 AS route_count, way
        FROM stations
        WHERE railway IN ('station', 'halt', 'tram_stop', 'service_station', 'yard', 'junction', 'spur_junction', 'crossover', 'site', 'tram_stop')
    ) AS facilities
    -- ORDER BY is required to ensure that the larger route_count is used.
    ORDER BY osm_id, name, station, label, railway, route_count DESC;
