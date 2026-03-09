-- SPDX-License-Identifier: GPL-2.0-or-later

CREATE OR REPLACE FUNCTION openrailwaymap_hyphen_to_space(str TEXT) RETURNS TEXT AS $$
BEGIN
  RETURN regexp_replace(str, '(\w)-(\w)', '\1 \2', 'g');
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
    -- We do not sort the result, although we use DISTINCT ON because osm_ids is sufficient to sort out duplicates.
    RETURN QUERY
      SELECT
        b.osm_ids,
        b.osm_types,
        b.name,
        b.localized_name,
        b.feature,
        b.state,
        b.station,
        b.railway_ref,
        b.uic_ref,
        b."references",
        b.operator,
        b.network,
        b.wikidata,
        b.wikimedia_commons,
        b.wikimedia_commons_file,
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
          a.osm_types,
          a.name,
          a.localized_name,
          a.feature,
          a.state,
          a.station,
          a.railway_ref,
          a.uic_ref,
          a."references",
          a.operator,
          a.network,
          a.wikidata,
          a.wikimedia_commons,
          a.wikimedia_commons_file,
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
            fs.osm_types,
            fs.name,
            COALESCE(fs.name_tags['name:' || input_language], fs.name) as localized_name,
            fs.feature,
            fs.state,
            fs.station,
            fs.railway_ref,
            fs.uic_ref,
            fs."references",
            fs.operator,
            fs.network,
            fs.wikidata,
            fs.wikimedia_commons,
            fs.wikimedia_commons_file,
            fs.image,
            fs.mapillary,
            fs.wikipedia,
            fs.note,
            fs.description,
            ST_X(ST_Transform(fs.geom, 4326)) AS latitude,
            ST_Y(ST_Transform(fs.geom, 4326)) AS longitude,
            openrailwaymap_name_rank(phraseto_tsquery('simple', unaccent(openrailwaymap_hyphen_to_space(input_name))), fs.terms, fs.importance::numeric, fs.feature, fs.station) AS rank
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
      SELECT
        ARRAY[s.osm_id] as osm_ids,
        ARRAY[s.osm_type] as osm_types,
        s.name,
        COALESCE(name_tags['name:' || input_language], s.name) as localized_name,
        s.feature,
        s.state,
        s.station,
        s.map_reference as railway_ref,
        s."references"->'uic' as uic_ref,
        hs_concat(sa."references", s."references") as "references",
        s.operator AS operator,
        s.network AS network,
        array_remove(ARRAY[s.wikidata], null) AS wikidata,
        array_remove(ARRAY[s.wikimedia_commons], null) AS wikimedia_commons,
        array_remove(ARRAY[s.wikimedia_commons_file], null) AS wikimedia_commons_file,
        array_remove(ARRAY[s.image], null) AS image,
        array_remove(ARRAY[s.mapillary], null) AS mapillary,
        array_remove(ARRAY[s.wikipedia], null) AS wikipedia,
        array_remove(ARRAY[s.note], null) AS note,
        array_remove(ARRAY[s.description], null) AS description,
        ST_X(ST_Transform(s.way, 4326)) AS latitude,
        ST_Y(ST_Transform(s.way, 4326)) AS longitude,
        -- Determine rank by common facility reference IDs
        (CASE
          WHEN input_ref = s."references"->'railway-ref' THEN 100
          WHEN input_ref = s."references"->'uic' THEN 90
          WHEN input_ref = s."references"->'ibnr' THEN 80
          WHEN input_ref = s."references"->'ifopt' THEN 70
          WHEN input_ref = s."references"->'plc' THEN 60
          ELSE 0
        END)::numeric as rank
      FROM (
        SELECT s.id
        FROM stations s
        WHERE ARRAY[input_ref] <@ avals(s."references")

        UNION

        SELECT s.id
        FROM stop_areas sa
        JOIN stations s
          ON (s.osm_id = ANY(sa.node_ref_ids) AND s.osm_type = 'N')
            OR (s.osm_id = ANY(sa.way_ref_ids) AND s.osm_type = 'W')
        WHERE ARRAY[input_ref] <@ avals(sa."references")
      ) station_ids
      JOIN stations s
        ON station_ids.id = s.id
      LEFT JOIN stop_areas sa
        ON (ARRAY[s.osm_id] <@ sa.node_ref_ids AND s.osm_type = 'N')
          OR (ARRAY[s.osm_id] <@ sa.way_ref_ids AND s.osm_type = 'W')
      ORDER BY rank DESC
      LIMIT input_limit;
  END
$$ LANGUAGE plpgsql
  LEAKPROOF
  PARALLEL SAFE;
