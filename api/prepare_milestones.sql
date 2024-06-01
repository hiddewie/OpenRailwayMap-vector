-- SPDX-License-Identifier: GPL-2.0-or-later
-- Prepare the database for querying milestones

CREATE OR REPLACE FUNCTION railway_api_valid_float(value TEXT) RETURNS FLOAT AS $$
BEGIN
  IF value ~ '^-?[0-9]+(\.[0-9]+)$' THEN
    RETURN value::FLOAT;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE MATERIALIZED VIEW IF NOT EXISTS openrailwaymap_milestones AS
  SELECT DISTINCT ON (osm_id) osm_id, position, precision, railway, name, ref, tags, geom
    FROM (
      SELECT osm_id, position, precision, railway, name, ref, tags, geom
        FROM (
          SELECT
              osm_id,
              railway_api_valid_float(unnest(string_to_array(tags->'railway:position', ';'))) AS position,
              1::SMALLINT AS precision,
              railway,
              name,
              ref,
              tags,
              way AS geom
            FROM planet_osm_point
            WHERE
              (
                railway IS NOT NULL
                OR tags?'disused:railway'
                OR tags?'abandoned:railway'
                OR tags?'construction:railway'
                OR tags?'proposed:railway'
                OR tags?'razed:railway'
              ) AND tags?'railway:position'
          UNION ALL
          SELECT
              osm_id,
              railway_api_valid_float(unnest(string_to_array(tags->'railway:position:exact', ';'))) AS position,
              3::SMALLINT AS precision,
              railway,
              name,
              ref,
              tags,
              way AS geom
            FROM planet_osm_point
            WHERE
              (
                railway IS NOT NULL
                OR tags?'disused:railway'
                OR tags?'abandoned:railway'
                OR tags?'construction:railway'
                OR tags?'proposed:railway'
                OR tags?'razed:railway'
              ) AND tags?'railway:position:exact'
          ) AS features_with_position
        WHERE position IS NOT NULL
        ORDER BY osm_id ASC, precision DESC
      ) AS duplicates_merged;

CREATE INDEX IF NOT EXISTS openrailwaymap_milestones_geom_idx
  ON openrailwaymap_milestones
  USING gist(geom);

CREATE INDEX IF NOT EXISTS openrailwaymap_milestones_position_idx
  ON openrailwaymap_milestones
  USING gist(geom);

CREATE OR REPLACE VIEW openrailwaymap_tracks_with_ref AS
  SELECT
      osm_id,
      railway,
      name,
      ref,
      tags,
      way AS geom
    FROM planet_osm_line
    WHERE
      railway IN ('rail', 'narrow_gauge', 'subway', 'light_rail', 'tram', 'construction', 'proposed', 'disused', 'abandoned', 'razed')
      AND (NOT (tags?'service') OR tags->'usage' IN ('industrial', 'military', 'test'))
      AND ref IS NOT NULL
      AND osm_id > 0;

CREATE INDEX IF NOT EXISTS planet_osm_line_ref_geom_idx
  ON planet_osm_line
  USING gist(way)
  WHERE 
    railway IN ('rail', 'narrow_gauge', 'subway', 'light_rail', 'tram', 'construction', 'proposed', 'disused', 'abandoned', 'razed')
    AND (NOT tags?'service' OR tags->'usage' IN ('industrial', 'military', 'test'))
    AND ref IS NOT NULL
    AND osm_id > 0;

CREATE INDEX IF NOT EXISTS planet_osm_line_ref_idx
  ON planet_osm_line
  USING btree(ref)
  WHERE 
    railway IN ('rail', 'narrow_gauge', 'subway', 'light_rail', 'tram', 'construction', 'proposed', 'disused', 'abandoned', 'razed')
    AND (NOT tags?'service' OR tags->'usage' IN ('industrial', 'military', 'test'))
    AND ref IS NOT NULL
    AND osm_id > 0;
