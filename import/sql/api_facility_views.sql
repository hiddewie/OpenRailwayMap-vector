-- SPDX-License-Identifier: GPL-2.0-or-later

CREATE MATERIALIZED VIEW IF NOT EXISTS openrailwaymap_facilities_for_search AS
  SELECT
    id,
    osm_ids,
    osm_types,
    to_tsvector('simple', unaccent(openrailwaymap_hyphen_to_space(value))) AS terms,
    name,
    key AS name_key,
    value AS name_value,
    feature,
    state,
    station,
    railway_ref,
    uic_ref,
    importance,
    operator,
    network,
    wikidata,
    wikimedia_commons,
    wikimedia_commons_file,
    image,
    mapillary,
    wikipedia,
    note,
    description,
    geom
  FROM (
    SELECT DISTINCT ON (osm_ids, key, value, name, feature, state, station, railway_ref, uic_ref, importance, geom)
      id,
      osm_ids,
      osm_types,
      (each(name_tags)).key AS key,
      (each(name_tags)).value AS value,
      name,
      feature,
      state,
      station,
      railway_ref,
      uic_ref,
      importance,
      operator,
      network,
      wikidata,
      wikimedia_commons,
      wikimedia_commons_file,
      image,
      mapillary,
      wikipedia,
      note,
      description,
      center as geom
    FROM grouped_stations_with_importance
  ) AS duplicated;

CREATE INDEX IF NOT EXISTS openrailwaymap_facilities_name_index
  ON openrailwaymap_facilities_for_search
    USING gin(terms);
