-- SPDX-License-Identifier: GPL-2.0-or-later

CREATE TABLE IF NOT EXISTS openrailwaymap_ref AS
  SELECT
      osm_id,
      name,
--       tags,
      railway,
      station,
      null as ref, -- TODO
      label as railway_ref,
      null as uic_ref, -- TODO tags->'uic_ref' as uic_ref,
      way AS geom
    FROM stations
    WHERE
      (label is not null) -- TODO OR tags ? 'uic_ref')
      AND (
        railway IN ('station', 'halt', 'tram_stop', 'service_station', 'yard', 'junction', 'spur_junction', 'crossover', 'site', 'tram_stop')
--         OR tags->'disused:railway' IN ('station', 'halt', 'tram_stop', 'service_station', 'yard', 'junction', 'spur_junction', 'crossover', 'site', 'tram_stop')
--         OR tags->'abandoned:railway' IN ('station', 'halt', 'tram_stop', 'service_station', 'yard', 'junction', 'spur_junction', 'crossover', 'site', 'tram_stop')
--         OR tags->'proposed:railway' IN ('station', 'halt', 'tram_stop', 'service_station', 'yard', 'junction', 'spur_junction', 'crossover', 'site', 'tram_stop')
--         OR tags->'razed:railway' IN ('station', 'halt', 'tram_stop', 'service_station', 'yard', 'junction', 'spur_junction', 'crossover', 'site', 'tram_stop')
      );

CREATE INDEX IF NOT EXISTS openrailwaymap_ref_railway_ref_idx
  ON openrailwaymap_ref
  USING BTREE(railway_ref);

CREATE INDEX IF NOT EXISTS openrailwaymap_ref_uic_ref_idx
  ON openrailwaymap_ref
  USING BTREE(uic_ref);

CREATE TABLE IF NOT EXISTS openrailwaymap_facilities_for_search AS
  SELECT
      osm_id,
      to_tsvector('simple', unaccent(openrailwaymap_hyphen_to_space(value))) AS terms,
      name,
      key AS name_key,
      value AS name_value,
--       tags,
      railway,
      station,
      ref,
      route_count,
      geom
    FROM (
      SELECT DISTINCT ON (osm_id, key, value, name, railway, station, ref, route_count, geom) -- key, value, tags
          osm_id,
          'name' as key,
          name as value,
--           (each(updated_tags)).key AS key,
--           (each(updated_tags)).value AS value,
--           tags,
          name,
          railway,
          station,
          ref,
          route_count,
          geom
        FROM (
          SELECT
              osm_id,
--               CASE
--                 WHEN name IS NOT NULL THEN tags || hstore('name', name)
--                 ELSE tags
--               END AS updated_tags,
              name,
--               tags,
              railway,
              station AS station,
              null as ref, -- tags->'ref' AS ref,
              route_count,
              way AS geom
            FROM stations_with_route_counts
            WHERE
              railway IN ('station', 'halt', 'tram_stop', 'service_station', 'yard', 'junction', 'spur_junction', 'crossover', 'site', 'tram_stop')
--               OR tags->'disused:railway' IN ('station', 'halt', 'tram_stop', 'service_station', 'yard', 'junction', 'spur_junction', 'crossover', 'site', 'tram_stop')
--               OR tags->'abandoned:railway' IN ('station', 'halt', 'tram_stop', 'service_station', 'yard', 'junction', 'spur_junction', 'crossover', 'site', 'tram_stop')
--               OR tags->'proposed:railway' IN ('station', 'halt', 'tram_stop', 'service_station', 'yard', 'junction', 'spur_junction', 'crossover', 'site', 'tram_stop')
--               OR tags->'razed:railway' IN ('station', 'halt', 'tram_stop', 'service_station', 'yard', 'junction', 'spur_junction', 'crossover', 'site', 'tram_stop')
          ) AS organised
      ) AS duplicated
    WHERE
      key = 'name'
      OR key = 'alt_name'
      OR key = 'short_name'
      OR key = 'long_name'
      OR key = 'official_name'
      OR key = 'old_name'
      OR key LIKE 'name:%'
      OR key LIKE 'alt_name:%'
      OR key LIKE 'short_name:%'
      OR key LIKE 'long_name:%'
      OR key LIKE 'official_name:%'
      OR key LIKE 'old_name:%';

CREATE INDEX IF NOT EXISTS openrailwaymap_facilities_name_index ON openrailwaymap_facilities_for_search USING gin(terms);
