-- SPDX-License-Identifier: GPL-2.0-or-later

DROP TABLE IF EXISTS openrailwaymap_ref;
CREATE TABLE openrailwaymap_ref AS
  -- TODO add all available fields / tags from object
  SELECT
      osm_id,
      name,
      railway,
      station,
      ref,
      railway_ref,
      uic_ref,
      way AS geom
    FROM stations
    WHERE
      (railway_ref IS NOT NULL OR uic_ref IS NOT NULL)
      AND (
        railway IN ('station', 'halt', 'tram_stop', 'service_station', 'yard', 'junction', 'spur_junction', 'crossover', 'site')
        -- TODO support other states as well
      );

CREATE INDEX openrailwaymap_ref_railway_ref_idx
  ON openrailwaymap_ref
  USING BTREE(railway_ref);

CREATE INDEX openrailwaymap_ref_uic_ref_idx
  ON openrailwaymap_ref
  USING BTREE(uic_ref);

DROP TABLE IF EXISTS openrailwaymap_facilities_for_search;
CREATE TABLE openrailwaymap_facilities_for_search AS
  -- TODO add all available fields / tags from object
  SELECT
      osm_id,
      to_tsvector('simple', unaccent(openrailwaymap_hyphen_to_space(value))) AS terms,
      name,
      key AS name_key,
      value AS name_value,
      railway,
      station,
      railway_ref,
      route_count,
      geom
    FROM (
      SELECT DISTINCT ON (osm_id, key, value, name, railway, station, railway_ref, route_count, geom)
          osm_id,
          (each(name_tags)).key AS key,
          (each(name_tags)).value AS value,
          name,
          railway,
          station,
          railway_ref,
          route_count,
          geom
        FROM (
          SELECT
              osm_id,
              name,
              railway,
              station,
              railway_ref,
              name_tags,
              route_count,
              ST_Centroid(way) AS geom
            FROM stations_with_route_counts
            WHERE
              railway IN ('station', 'halt', 'tram_stop', 'service_station', 'yard', 'junction', 'spur_junction', 'crossover', 'site')
              -- TODO support other states as well
          ) AS organised
      ) AS duplicated;

CREATE INDEX openrailwaymap_facilities_name_index ON openrailwaymap_facilities_for_search USING gin(terms);
