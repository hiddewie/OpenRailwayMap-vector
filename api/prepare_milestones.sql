-- SPDX-License-Identifier: GPL-2.0-or-later
-- Prepare the database for querying milestones

CREATE OR REPLACE FUNCTION railway_api_valid_float(value TEXT) RETURNS FLOAT AS $$
BEGIN
  IF value ~ '^-?[0-9]+(\.[0-9]+)?$' THEN
    RETURN value::FLOAT;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TABLE IF EXISTS openrailwaymap_milestones;
CREATE TABLE openrailwaymap_milestones AS
  -- TODO add all available fields / tags from object
  SELECT DISTINCT ON (osm_id) osm_id, position, precision, railway, name, ref, geom
    FROM (
      SELECT osm_id, position, precision, railway, name, ref, geom
        FROM (
          SELECT
              osm_id,
              railway_api_valid_float(unnest(string_to_array(railway_position, ';'))) AS position,
              1::SMALLINT AS precision,
              railway,
              name,
              ref,
              way AS geom
            FROM railway_positions
            WHERE railway_position IS NOT NULL
          UNION ALL
          SELECT
              osm_id,
              railway_api_valid_float(unnest(string_to_array(railway_position_exact, ';'))) AS position,
              3::SMALLINT AS precision,
              railway,
              name,
              ref,
              way AS geom
            FROM railway_positions
            WHERE railway_position_exact IS NOT NULL
          ) AS features_with_position
        WHERE position IS NOT NULL
        ORDER BY osm_id ASC, precision DESC
      ) AS duplicates_merged;

CREATE INDEX openrailwaymap_milestones_geom_idx
  ON openrailwaymap_milestones
  USING gist(geom);

CREATE INDEX openrailwaymap_milestones_position_idx
  ON openrailwaymap_milestones
  USING gist(geom);

DROP TABLE IF EXISTS openrailwaymap_tracks_with_ref;
CREATE TABLE openrailwaymap_tracks_with_ref AS
  SELECT
      osm_id,
      feature,
      name,
      ref,
      way AS geom
    FROM railway_line
    WHERE
      feature IN ('rail', 'narrow_gauge', 'subway', 'light_rail', 'tram')
      AND (service IS NULL OR usage IN ('industrial', 'military', 'test'))
      AND ref IS NOT NULL
      AND osm_id > 0;

CREATE INDEX planet_osm_line_ref_geom_idx
  ON openrailwaymap_tracks_with_ref
  USING gist(geom);

CREATE INDEX planet_osm_line_ref_idx
  ON openrailwaymap_tracks_with_ref
  USING btree(ref);
