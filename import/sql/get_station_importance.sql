-- Assign a numeric rank to passenger train stations

-- Relevant objects referenced by route relations: railway=station, railway=halt, public_transport=stop_position, public_transport=platform, railway=platform

-- CREATE OR REPLACE VIEW stops_platforms AS
--  SELECT osm_id, name, railway, public_transport, tags, way AS geom, 1::smallint AS objtype
--    FROM planet_osm_point
--    WHERE railway IN ('station', 'halt', 'platform') OR public_transport IN ('stop_position', 'platform')
--  UNION ALL
--  SELECT osm_id, name, railway, public_transport, tags, way AS geom, 2::smallint AS objtype
--    FROM planet_osm_line
--    WHERE
--      osm_id > 0
--      AND (
--	railway IN ('station', 'halt', 'platform') OR public_transport IN ('stop_position', 'platform')
--      )
--  UNION ALL
--  SELECT osm_id, name, railway, public_transport, tags, way AS geom, CASE WHEN osm_id > 0 THEN 2::smallint ELSE 3::smallint END AS objtype
--    FROM planet_osm_polygon
--    WHERE railway IN ('station', 'halt', 'platform') OR public_transport IN ('stop_position', 'platform');

-- CREATE INDEX IF NOT EXISTS planet_osm_point_railway_geom_idx ON planet_osm_point USING GIST(way) WHERE railway IN ('station', 'halt', 'tram_stop', 'service_station', 'yard', 'junction', 'spur_junction', 'crossover', 'site', 'tram_stop', 'signal_box');
-- CREATE INDEX IF NOT EXISTS planet_osm_polygon_railway_geom_idx ON planet_osm_polygon USING GIST(way) WHERE railway IN ('signal_box');

-- Node members in relations
-- TODO optionally check array_length(parts, 1) against way_off or rel_off
-- TODO Use materialised view and explode arrays to rows.
CREATE OR REPLACE VIEW relations_node_members AS
  SELECT id, parts[0:way_off] AS parts FROM planet_osm_rels WHERE way_off > 0;

-- Way members in relations
-- TODO optionally check array_length(parts, 1) against way_off or rel_off
-- TODO Use materialised view and explode arrays to rows.
CREATE OR REPLACE VIEW relations_way_members AS
  SELECT id, parts[way_off:rel_off] AS parts FROM planet_osm_rels WHERE rel_off > 0;

-- Relation members in relations
-- TODO optionally check array_length(parts, 1) against way_off or rel_off
-- TODO Use materialised view and explode arrays to rows.
CREATE OR REPLACE VIEW relations_rel_members AS
  SELECT id, parts[rel_off:-1] AS parts FROM planet_osm_rels WHERE ARRAY_LENGTH(parts, 1) > 1;

-- Get OSM IDs route relations referencing a stop position or a station/halt node
CREATE OR REPLACE VIEW stops_and_route_relations AS
  SELECT
      rnm.id AS rel_id, sp.osm_id AS stop_id, sp.name AS stop_name, sp.way AS geom
    FROM openrailwaymap_osm_point AS sp
    JOIN planet_osm_line AS pl
      ON (pl.osm_id < 0 AND pl.route IN ('train', 'subway', 'tram', 'light_rail') AND sp.way && pl.way)
    JOIN relations_node_members AS rnm
      ON (-pl.osm_id = rnm.id AND sp.osm_id = ANY(rnm.parts))
    WHERE sp.public_transport = 'stop_position'; -- OR sp.railway IN ('station', 'halt');

-- Get OSM IDs route relations referencing a platform (linear ways)
CREATE OR REPLACE VIEW platforms_linear_route_relations AS
  SELECT
      rnm.id AS rel_id, sp.osm_id AS stop_id, sp.name AS stop_name, sp.way AS geom
    FROM openrailwaymap_osm_line AS sp
    JOIN planet_osm_line AS pl
      ON (pl.osm_id < 0 AND pl.route IN ('train', 'subway', 'tram', 'light_rail') AND sp.way && pl.way)
    JOIN relations_way_members AS rnm
      ON (-pl.osm_id = rnm.id AND sp.osm_id = ANY(rnm.parts))
    WHERE (sp.public_transport = 'platform' OR sp.railway = 'platform') AND sp.osm_id > 0;

-- Get OSM IDs route relations referencing a platform (closed ways)
CREATE OR REPLACE VIEW platforms_closed_ways_route_relations AS
  SELECT
      rnm.id AS rel_id, sp.osm_id AS stop_id, sp.name AS stop_name, sp.way AS geom
    FROM openrailwaymap_osm_polygon AS sp
    JOIN planet_osm_line AS pl
      ON (pl.osm_id < 0 AND pl.route IN ('train', 'subway', 'tram', 'light_rail') AND sp.way && pl.way)
    JOIN relations_way_members AS rnm
      ON (-pl.osm_id = rnm.id AND sp.osm_id = ANY(rnm.parts))
    WHERE (sp.public_transport = 'platform' OR sp.railway = 'platform') AND sp.osm_id > 0;

-- Get OSM IDs route relations referencing a platform (multipolygons)
CREATE OR REPLACE VIEW platforms_mp_route_relations AS
  SELECT
      rnm.id AS rel_id, sp.osm_id AS stop_id, sp.name AS stop_name, sp.way AS geom
    FROM openrailwaymap_osm_polygon AS sp
    JOIN planet_osm_line AS pl
      ON (pl.osm_id < 0 AND pl.route IN ('train', 'subway', 'tram', 'light_rail') AND sp.way && pl.way)
    JOIN relations_rel_members AS rnm
      ON (-pl.osm_id = rnm.id AND sp.osm_id = ANY(rnm.parts))
    WHERE (sp.public_transport = 'platform' OR sp.railway = 'platform') AND sp.osm_id < 0;

-- Get OSM IDs of route relations referencing a platform (all except nodes)
CREATE OR REPLACE VIEW platforms_route_relations AS
  SELECT rel_id, stop_id AS platform_id, geom
    FROM platforms_linear_route_relations
  UNION ALL
  SELECT rel_id, stop_id AS platform_id, geom
    FROM platforms_closed_ways_route_relations
  UNION ALL
  SELECT rel_id, stop_id AS platform_id, geom
    FROM platforms_mp_route_relations;

-- Cluster stop positions with equal name
CREATE OR REPLACE VIEW stop_positions_and_their_routes_clustered AS
  SELECT ST_CollectionExtract(unnest(ST_ClusterWithin(srr.geom, 400)), 1) AS geom, srr.stop_name AS stop_name, ARRAY_AGG(DISTINCT(srr.rel_id)) AS route_ids
    FROM stops_and_route_relations AS srr
    WHERE srr.stop_name IS NOT NULL
    GROUP BY stop_name;

-- Cluster platforms in close distance
CREATE OR REPLACE VIEW platforms_and_their_routes_clustered AS
  SELECT ST_CollectionExtract(unnest(ST_ClusterWithin(srr.geom, 40)), 1) AS geom, ARRAY_AGG(DISTINCT(srr.rel_id)) AS route_ids
    FROM platforms_route_relations AS srr;

-- Join clustered stop positions with station nodes
CREATE OR REPLACE VIEW station_nodes_stop_positions_rel_count AS
  SELECT s.osm_id, s.name AS name, s.tags AS tags, s.railway AS railway, sprc.route_ids AS route_ids, s.way AS way
    FROM openrailwaymap_osm_point AS s
    LEFT OUTER JOIN stop_positions_and_their_routes_clustered AS sprc
      ON (sprc.stop_name = s.name AND ST_DWithin(s.way, sprc.geom, 400))
    WHERE s.railway IN ('station', 'halt', 'tram_stop', 'service_station', 'yard', 'junction', 'spur_junction', 'crossover', 'site', 'tram_stop');

-- Join clustered platforms with station nodes
CREATE OR REPLACE VIEW station_nodes_platforms_rel_count AS
  SELECT s.osm_id AS osm_id, s.name AS name, s.tags AS tags, s.railway AS railway, sprc.route_ids AS route_ids, s.way AS way
    FROM openrailwaymap_osm_point AS s
    JOIN platforms_and_their_routes_clustered AS sprc
      ON (ST_DWithin(s.way, sprc.geom, 60))
    WHERE s.railway IN ('station', 'halt', 'tram_stop');

-- Final table with station nodes and the number of route relations
-- needs about 3 to 4 minutes for whole Germany
-- or about 20 to 30 minutes for the whole planet
CREATE MATERIALIZED VIEW IF NOT EXISTS stations_with_route_counts AS
  SELECT DISTINCT ON (osm_id, name, tags, railway) osm_id, name, tags, railway, route_count, way
    FROM (
      SELECT osm_id, name, tags, railway, ARRAY_LENGTH(ARRAY_AGG(DISTINCT route_id), 1) AS route_count, way
        FROM (
          SELECT osm_id, name, tags, railway, UNNEST(route_ids) AS route_id, way
            FROM station_nodes_stop_positions_rel_count
          UNION ALL
          SELECT osm_id, name, tags, railway, UNNEST(route_ids) AS route_id, way
            FROM station_nodes_platforms_rel_count
        ) AS a
        GROUP BY osm_id, name, tags, railway, way
      UNION ALL
      SELECT osm_id, name, tags, railway, 0 AS route_count, way
        FROM planet_osm_point
        WHERE railway IN ('station', 'halt', 'tram_stop', 'service_station', 'yard', 'junction', 'spur_junction', 'crossover', 'site', 'tram_stop')
    ) AS facilities
    -- ORDER BY is required to ensure that the larger route_count is used.
    ORDER BY osm_id, name, tags, railway, route_count DESC;
