-- SPDX-License-Identifier: GPL-2.0-or-later
CREATE EXTENSION IF NOT EXISTS unaccent;

CREATE OR REPLACE FUNCTION openrailwaymap_hyphen_to_space(str TEXT) RETURNS TEXT AS $$
BEGIN
  RETURN regexp_replace(str, '(\w)-(\w)', '\1 \2', 'g');
END;
$$ LANGUAGE plpgsql
  IMMUTABLE
  LEAKPROOF
  PARALLEL SAFE;

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
$$ LANGUAGE plpgsql
  IMMUTABLE
  LEAKPROOF
  PARALLEL SAFE;

DROP FUNCTION query_facilities_by_name(text, integer);
CREATE OR REPLACE FUNCTION query_facilities_by_name(
  input_name text,
  input_limit integer
) RETURNS TABLE(
  "osm_ids" bigint[],
  "name" text,
  "railway" text,
  "railway_ref" text,
  "station" text,
  "uic_ref" text,
  "operator" text[],
  "network" text[],
  "wikidata" text[],
  "wikimedia_commons" text[],
  "image" text[],
  "mapillary" text[],
  "wikipedia" text[],
  "note" text[],
  "description" text[],
  "latitude" double precision,
  "longitude" double precision,
  "rank" integer
) AS $$
  BEGIN
    -- We do not sort the result, although we use DISTINCT ON because osm_ids is sufficient to sort out duplicates.
    RETURN QUERY
      SELECT
        b.osm_ids,
        b.name,
        b.railway,
        b.railway_ref,
        b.station,
        b.uic_ref,
        b.operator,
        b.network,
        b.wikidata,
        b.wikimedia_commons,
        b.image,
        b.mapillary,
        b.wikipedia,
        b.note,
        b.description,
        b.latitude,
        b.longitude,
        b.rank
      FROM (
        SELECT DISTINCT ON (a.osm_ids)
          a.osm_ids,
          a.name,
          a.railway,
          a.railway_ref,
          a.station,
          a.uic_ref,
          a.operator,
          a.network,
          a.wikidata,
          a.wikimedia_commons,
          a.image,
          a.mapillary,
          a.wikipedia,
          a.note,
          a.description,
          a.latitude,
          a.longitude,
          a.rank
        FROM (
          SELECT
            fs.osm_ids,
            fs.name,
            fs.railway,
            fs.railway_ref,
            fs.station,
            fs.uic_ref,
            fs.operator,
            fs.network,
            fs.wikidata,
            fs.wikimedia_commons,
            fs.image,
            fs.mapillary,
            fs.wikipedia,
            fs.note,
            fs.description,
            ST_X(ST_Transform(fs.geom, 4326)) AS latitude,
            ST_Y(ST_Transform(fs.geom, 4326)) AS longitude,
            openrailwaymap_name_rank(phraseto_tsquery('simple', unaccent(openrailwaymap_hyphen_to_space(input_name))), fs.terms, fs.route_count::INTEGER, fs.railway, fs.station) AS rank
          FROM openrailwaymap_facilities_for_search fs
          WHERE fs.terms @@ phraseto_tsquery('simple', unaccent(openrailwaymap_hyphen_to_space(input_name)))
        ) AS a
      ) AS b
      ORDER BY b.rank DESC NULLS LAST
      LIMIT input_limit;
  END
$$ LANGUAGE plpgsql
  LEAKPROOF
  PARALLEL SAFE;

DROP FUNCTION query_facilities_by_ref(text, integer);
CREATE OR REPLACE FUNCTION query_facilities_by_ref(
  input_ref text,
  input_limit integer
) RETURNS TABLE(
  "osm_ids" bigint[],
  "name" text,
  "railway" text,
  "railway_ref" text,
  "station" text,
  "uic_ref" text,
  "operator" text[],
  "network" text[],
  "wikidata" text[],
  "wikimedia_commons" text[],
  "image" text[],
  "mapillary" text[],
  "wikipedia" text[],
  "note" text[],
  "description" text[],
  "latitude" double precision,
  "longitude" double precision
) AS $$
  BEGIN
    RETURN QUERY
      -- We do not sort the result, although we use DISTINCT ON because osm_ids is sufficient to sort out duplicates.
      SELECT
        DISTINCT ON (osm_ids)
        r.osm_ids,
        r.name,
        r.feature,
        r.state,
        r.railway_ref,
        r.station,
        r.uic_ref,
        r.operator,
        r.network,
        r.wikidata,
        r.wikimedia_commons,
        r.image,
        r.mapillary,
        r.wikipedia,
        r.note,
        r.description,
        ST_X(ST_Transform(r.geom, 4326)) AS latitude,
        ST_Y(ST_Transform(r.geom, 4326)) AS longitude
      FROM openrailwaymap_ref r
      WHERE r.railway_ref = input_ref
      LIMIT input_limit;
  END
$$ LANGUAGE plpgsql
  LEAKPROOF
  PARALLEL SAFE;

DROP FUNCTION query_facilities_by_uic_ref(text, integer);
CREATE OR REPLACE FUNCTION query_facilities_by_uic_ref(
  input_uic_ref text,
  input_limit integer
) RETURNS TABLE(
  "osm_ids" bigint[],
  "name" text,
  "railway" text,
  "railway_ref" text,
  "station" text,
  "uic_ref" text,
  "operator" text[],
  "network" text[],
  "wikidata" text[],
  "wikimedia_commons" text[],
  "image" text[],
  "mapillary" text[],
  "wikipedia" text[],
  "note" text[],
  "description" text[],
  "latitude" double precision,
  "longitude" double precision
) AS $$
  BEGIN
    RETURN QUERY
      -- We do not sort the result, although we use DISTINCT ON because osm_ids is sufficient to sort out duplicates.
      SELECT
        DISTINCT ON (osm_ids)
        r.osm_ids,
        r.name,
        r.feature,
        r.state,
        r.railway_ref,
        r.station,
        r.uic_ref,
        r.operator,
        r.network,
        r.wikidata,
        r.wikimedia_commons,
        r.image,
        r.mapillary,
        r.wikipedia,
        r.note,
        r.description,
        ST_X(ST_Transform(r.geom, 4326)) AS latitude,
        ST_Y(ST_Transform(r.geom, 4326)) AS longitude
      FROM openrailwaymap_ref r
      WHERE r.uic_ref = input_uic_ref
      LIMIT input_limit;
  END
$$ LANGUAGE plpgsql
  LEAKPROOF
  PARALLEL SAFE;
