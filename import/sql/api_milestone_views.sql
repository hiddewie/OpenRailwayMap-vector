-- SPDX-License-Identifier: GPL-2.0-or-later
-- Prepare the database for querying milestones

CREATE MATERIALIZED VIEW openrailwaymap_milestones AS
  SELECT DISTINCT ON (osm_id)
    osm_id,
    position,
    precision,
    railway,
    name,
    ref,
    operator,
    geom,
    wikidata,
    wikimedia_commons,
    wikimedia_commons_file,
    image,
    mapillary,
    wikipedia,
    note,
    description
  FROM (
    SELECT
      osm_id,
      position,
      precision,
      railway,
      name,
      ref,
      operator,
      geom,
      wikidata,
      wikimedia_commons,
      wikimedia_commons_file,
      image,
      mapillary,
      wikipedia,
      note,
      description
    FROM (
      SELECT
        osm_id,
        railway_api_valid_float(unnest(string_to_array(railway_position, ';'))) AS position,
        1::SMALLINT AS precision,
        railway,
        name,
        ref,
        operator,
        way AS geom,
        wikidata,
        wikimedia_commons,
        wikimedia_commons_file,
        image,
        mapillary,
        wikipedia,
        note,
        description
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
        operator,
        way AS geom,
        wikidata,
        wikimedia_commons,
        wikimedia_commons_file,
        image,
        mapillary,
        wikipedia,
        note,
        description
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
