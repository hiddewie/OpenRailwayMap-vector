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
      way AS geom
    FROM railway_line
    WHERE
      railway IN ('rail', 'narrow_gauge', 'subway', 'light_rail', 'tram', 'construction', 'proposed', 'disused', 'abandoned', 'razed')
      AND (service IS NULL OR usage IN ('industrial', 'military', 'test'))
      AND ref IS NOT NULL
      AND osm_id > 0;

CREATE INDEX IF NOT EXISTS planet_osm_line_ref_geom_idx
  ON railway_line
  USING gist(way)
  WHERE
    railway IN ('rail', 'narrow_gauge', 'subway', 'light_rail', 'tram', 'construction', 'proposed', 'disused', 'abandoned', 'razed')
    AND (service IS NULL OR usage IN ('industrial', 'military', 'test'))
    AND ref IS NOT NULL
    AND osm_id > 0;

CREATE INDEX IF NOT EXISTS planet_osm_line_ref_idx
  ON railway_line
  USING btree(ref)
  WHERE
    railway IN ('rail', 'narrow_gauge', 'subway', 'light_rail', 'tram', 'construction', 'proposed', 'disused', 'abandoned', 'razed')
    AND (service IS NULL OR usage IN ('industrial', 'military', 'test'))
    AND ref IS NOT NULL
    AND osm_id > 0;
