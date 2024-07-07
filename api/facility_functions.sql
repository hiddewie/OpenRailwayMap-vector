-- SPDX-License-Identifier: GPL-2.0-or-later
CREATE EXTENSION IF NOT EXISTS unaccent;

CREATE OR REPLACE FUNCTION openrailwaymap_hyphen_to_space(str TEXT) RETURNS TEXT AS $$
BEGIN
  RETURN regexp_replace(str, '(\w)-(\w)', '\1 \2', 'g');
END;
$$ LANGUAGE plpgsql IMMUTABLE;

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
$$ LANGUAGE plpgsql IMMUTABLE;
