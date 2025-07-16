-- SPDX-License-Identifier: GPL-2.0-or-later
-- Prepare the database for querying milestones

CREATE MATERIALIZED VIEW openrailwaymap_milestones AS
  SELECT DISTINCT ON (osm_id)
    osm_id,
    position,
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
        position_numeric AS position,
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
      WHERE position_numeric IS NOT NULL
    ) AS features_with_position
    WHERE position IS NOT NULL
    ORDER BY osm_id DESC
  ) AS duplicates_merged;

CREATE INDEX openrailwaymap_milestones_geom_idx
  ON openrailwaymap_milestones
    USING gist(geom);

CREATE INDEX openrailwaymap_milestones_position_idx
  ON openrailwaymap_milestones
    USING gist(geom);
