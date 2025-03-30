-- SPDX-License-Identifier: GPL-2.0-or-later

DROP TABLE IF EXISTS openrailwaymap_ref;
CREATE TABLE openrailwaymap_ref AS
  SELECT
    ARRAY[osm_id] as osm_ids,
    name,
    railway,
    station,
    ref,
    railway_ref,
    uic_ref,
    operator,
    network,
    wikidata,
    wikimedia_commons,
    image,
    mapillary,
    wikipedia,
    note,
    description,
    way AS geom
  FROM stations
  WHERE
    -- TODO support other states as well
    (railway_ref IS NOT NULL OR uic_ref IS NOT NULL);

CREATE INDEX openrailwaymap_ref_railway_ref_idx
  ON openrailwaymap_ref
    USING BTREE(railway_ref)
  WHERE railway_ref IS NOT NULL;

CREATE INDEX openrailwaymap_ref_uic_ref_idx
  ON openrailwaymap_ref
    USING BTREE(uic_ref)
  WHERE uic_ref IS NOT NULL;

DROP TABLE IF EXISTS openrailwaymap_facilities_for_search;
CREATE TABLE openrailwaymap_facilities_for_search AS
  SELECT
    id,
    osm_ids,
    to_tsvector('simple', unaccent(openrailwaymap_hyphen_to_space(value))) AS terms,
    name,
    key AS name_key,
    value AS name_value,
    railway,
    station,
    railway_ref,
    uic_ref,
    route_count,
    operator,
    network,
    wikidata,
    wikimedia_commons,
    image,
    mapillary,
    wikipedia,
    note,
    description,
    geom
  FROM (
    SELECT DISTINCT ON (osm_ids, key, value, name, railway, station, railway_ref, uic_ref, route_count, geom)
      id,
      osm_ids,
      (each(name_tags)).key AS key,
      (each(name_tags)).value AS value,
      name,
      railway,
      station,
      railway_ref,
      uic_ref,
      route_count,
      operator,
      network,
      wikidata,
      wikimedia_commons,
      image,
      mapillary,
      wikipedia,
      note,
      description,
      center as geom
    FROM grouped_stations_with_route_count
    -- TODO support other states as well
  ) AS duplicated;

CREATE INDEX openrailwaymap_facilities_name_index
  ON openrailwaymap_facilities_for_search
    USING gin(terms);
