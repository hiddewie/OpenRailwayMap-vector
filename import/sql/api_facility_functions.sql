-- SPDX-License-Identifier: GPL-2.0-or-later

CREATE OR REPLACE FUNCTION openrailwaymap_hyphen_slash_to_space(str TEXT) RETURNS TEXT AS $$
BEGIN
  RETURN regexp_replace(str, '(\w)[-/](\w)', '\1 \2', 'g');
END;
$$ LANGUAGE plpgsql
  IMMUTABLE
  LEAKPROOF
  PARALLEL SAFE;

CREATE OR REPLACE FUNCTION openrailwaymap_name_rank(tsquery_str tsquery, tsvec_col tsvector, importance NUMERIC, feature TEXT, station TEXT) RETURNS NUMERIC AS $$
DECLARE
  factor FLOAT;
BEGIN
  IF feature = 'tram_stop' OR station IN ('light_rail', 'monorail', 'subway') THEN
    factor := 0.5;
  ELSIF feature = 'halt' THEN
    factor := 0.8;
  END IF;
  IF tsvec_col @@ tsquery_str THEN
    factor := 2.0;
  END IF;
  RETURN (factor * COALESCE(importance, 0))::NUMERIC;
END;
$$ LANGUAGE plpgsql
  IMMUTABLE
  LEAKPROOF
  PARALLEL SAFE;

CREATE OR REPLACE FUNCTION query_facilities_by_name(
  input_name text,
  input_language text,
  input_limit integer
) RETURNS TABLE(
  "osm_ids" bigint[],
  "osm_types" char[],
  "name" text,
  "localized_name" text,
  "feature" text,
  "state" text,
  "station" text,
  "railway_ref" text,
  "uic_ref" text,
  "references" hstore,
  "operator" text[],
  "owner" text[],
  "network" text[],
  "wikidata" text[],
  "wikimedia_commons" text[],
  "wikimedia_commons_file" text[],
  "image" text[],
  "mapillary" text[],
  "wikipedia" text[],
  "note" text[],
  "description" text[],
  "latitude" double precision,
  "longitude" double precision,
  "rank" numeric
) AS $$
  BEGIN
    RETURN QUERY
      SELECT DISTINCT ON (rank, gs.osm_ids)
        gs.osm_ids,
        gs.osm_types,
        gs.name,
        COALESCE(gs.name_tags['name:' || input_language], gs.name) as localized_name,
        gs.feature,
        gs.state,
        gs.station,
        gs.map_reference as railway_ref,
        gs.uic_ref,
        gs."references",
        gs.operator,
        gs.owner,
        gs.network,
        gs.wikidata,
        gs.wikimedia_commons,
        gs.wikimedia_commons_file,
        gs.image,
        gs.mapillary,
        gs.wikipedia,
        gs.note,
        gs.description,
        ST_X(ST_Transform(ST_PointOnSurface(gs.center), 4326)) AS latitude,
        ST_Y(ST_Transform(ST_PointOnSurface(gs.center), 4326)) AS longitude,
        openrailwaymap_name_rank(phraseto_tsquery('simple', unaccent(openrailwaymap_hyphen_slash_to_space(input_name))), fs.terms, gs.importance::numeric, gs.feature, gs.station) AS rank
      FROM openrailwaymap_facilities_for_name_search fs
      JOIN grouped_stations_with_importance gs
        ON fs.station_ids = gs.station_ids
      WHERE fs.terms @@ phraseto_tsquery('simple', unaccent(openrailwaymap_hyphen_slash_to_space(input_name)))
      ORDER BY rank DESC NULLS LAST
      LIMIT input_limit;
  END
$$ LANGUAGE plpgsql
  LEAKPROOF
  PARALLEL SAFE;

CREATE OR REPLACE FUNCTION query_facilities_by_ref(
  input_ref text,
  input_language text,
  input_limit integer
) RETURNS TABLE(
  "osm_ids" bigint[],
  "osm_types" char[],
  "name" text,
  "localized_name" text,
  "feature" text,
  "state" text,
  "station" text,
  "railway_ref" text,
  "uic_ref" text,
  "references" hstore,
  "operator" text[],
  "owner" text[],
  "network" text[],
  "wikidata" text[],
  "wikimedia_commons" text[],
  "wikimedia_commons_file" text[],
  "image" text[],
  "mapillary" text[],
  "wikipedia" text[],
  "note" text[],
  "description" text[],
  "latitude" double precision,
  "longitude" double precision,
  "rank" numeric
) AS $$
  BEGIN
    RETURN QUERY
      SELECT DISTINCT ON (rank, gs.osm_ids)
        gs.osm_ids,
        gs.osm_types,
        gs.name,
        COALESCE(gs.name_tags['name:' || input_language], gs.name) as localized_name,
        gs.feature,
        gs.state,
        gs.station,
        gs.map_reference as railway_ref,
        gs.uic_ref,
        gs."references",
        gs.operator,
        gs.owner,
        gs.network,
        gs.wikidata,
        gs.wikimedia_commons,
        gs.wikimedia_commons_file,
        gs.image,
        gs.mapillary,
        gs.wikipedia,
        gs.note,
        gs.description,
        ST_X(ST_Transform(ST_PointOnSurface(gs.center), 4326)) AS latitude,
        ST_Y(ST_Transform(ST_PointOnSurface(gs.center), 4326)) AS longitude,
        -- Determine rank by common facility reference IDs
        (CASE
          WHEN lower(input_ref) = lower(gs."references"->'railway-ref') THEN 100
          WHEN lower(input_ref) = lower(gs."references"->'uic') THEN 90
          WHEN lower(input_ref) = lower(gs."references"->'ibnr') THEN 80
          WHEN lower(input_ref) = lower(gs."references"->'ifopt') THEN 70
          WHEN lower(input_ref) = lower(gs."references"->'plc') THEN 60
          ELSE 0
        END)::numeric as rank
      FROM openrailwaymap_facilities_for_ref_search fs
      JOIN grouped_stations_with_importance gs
        ON fs.station_ids = gs.station_ids
      WHERE ARRAY[lower(input_ref)] <@ fs.terms
      ORDER BY rank DESC NULLS LAST
      LIMIT input_limit;
  END
$$ LANGUAGE plpgsql
  LEAKPROOF
  PARALLEL SAFE;
