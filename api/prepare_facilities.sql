-- SPDX-License-Identifier: GPL-2.0-or-later
CREATE EXTENSION IF NOT EXISTS unaccent;

CREATE OR REPLACE FUNCTION openrailwaymap_hyphen_to_space(str TEXT) RETURNS TEXT AS $$
BEGIN
  RETURN regexp_replace(str, '(\w)-(\w)', '\1 \2', 'g');
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE MATERIALIZED VIEW IF NOT EXISTS openrailwaymap_ref AS
  SELECT
      osm_id,
      name,
      tags,
      railway,
      tags->'station' as station,
      ref,
      tags->'railway:ref' as railway_ref,
      tags->'uic_ref' as uic_ref,
      way AS geom
    FROM planet_osm_point
    WHERE
      (tags ? 'railway:ref' OR tags ? 'uic_ref')
      AND (
        railway IN ('station', 'halt', 'tram_stop', 'service_station', 'yard', 'junction', 'spur_junction', 'crossover', 'site', 'tram_stop')
        OR tags->'disused:railway' IN ('station', 'halt', 'tram_stop', 'service_station', 'yard', 'junction', 'spur_junction', 'crossover', 'site', 'tram_stop')
        OR tags->'abandoned:railway' IN ('station', 'halt', 'tram_stop', 'service_station', 'yard', 'junction', 'spur_junction', 'crossover', 'site', 'tram_stop')
        OR tags->'proposed:railway' IN ('station', 'halt', 'tram_stop', 'service_station', 'yard', 'junction', 'spur_junction', 'crossover', 'site', 'tram_stop')
        OR tags->'razed:railway' IN ('station', 'halt', 'tram_stop', 'service_station', 'yard', 'junction', 'spur_junction', 'crossover', 'site', 'tram_stop')
      );

CREATE INDEX IF NOT EXISTS openrailwaymap_ref_railway_ref_idx
  ON openrailwaymap_ref
  USING BTREE(railway_ref);

CREATE INDEX IF NOT EXISTS openrailwaymap_ref_uic_ref_idx
  ON openrailwaymap_ref
  USING BTREE(uic_ref);

CREATE MATERIALIZED VIEW IF NOT EXISTS openrailwaymap_facilities_for_search AS
  SELECT
      osm_id,
      to_tsvector('simple', unaccent(openrailwaymap_hyphen_to_space(value))) AS terms,
      name,
      key AS name_key,
      value AS name_value,
      tags,
      railway,
      station,
      ref,
      route_count,
      geom
    FROM (
      SELECT DISTINCT ON (osm_id, key, value, tags, name, railway, station, ref, route_count, geom)
          osm_id,
          (each(updated_tags)).key AS key,
          (each(updated_tags)).value AS value,
          tags,
          name,
          railway,
          station,
          ref,
          route_count,
          geom
        FROM (
          SELECT
              osm_id,
              CASE
                WHEN name IS NOT NULL THEN tags || hstore('name', name)
                ELSE tags
              END AS updated_tags,
              name,
              tags,
              railway,
              tags->'station' AS station,
              tags->'ref' AS ref,
              route_count,
              way AS geom
            FROM stations_with_route_counts
            WHERE
              railway IN ('station', 'halt', 'tram_stop', 'service_station', 'yard', 'junction', 'spur_junction', 'crossover', 'site', 'tram_stop')
              OR tags->'disused:railway' IN ('station', 'halt', 'tram_stop', 'service_station', 'yard', 'junction', 'spur_junction', 'crossover', 'site', 'tram_stop')
              OR tags->'abandoned:railway' IN ('station', 'halt', 'tram_stop', 'service_station', 'yard', 'junction', 'spur_junction', 'crossover', 'site', 'tram_stop')
              OR tags->'proposed:railway' IN ('station', 'halt', 'tram_stop', 'service_station', 'yard', 'junction', 'spur_junction', 'crossover', 'site', 'tram_stop')
              OR tags->'razed:railway' IN ('station', 'halt', 'tram_stop', 'service_station', 'yard', 'junction', 'spur_junction', 'crossover', 'site', 'tram_stop')
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

CREATE OR REPLACE FUNCTION openrailwaymap_name_rank(tsquery_str tsquery, tsvec_col tsvector, route_count INTEGER, railway TEXT, station TEXT) RETURNS INTEGER AS $$
DECLARE
  factor FLOAT;
BEGIN
  IF railway = 'tram_stop' OR station IN ('light_rail', 'monorail', 'subway') THEN
    factor := 0.5;
  ELSIF railway = 'halt' THEN
    factor := 0.8;
  END IF;
  IF tsvec_col @@ tsquery_str THEN
    factor := 2.0;
  END IF;
  RETURN (factor * COALESCE(route_count, 0))::INTEGER;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
