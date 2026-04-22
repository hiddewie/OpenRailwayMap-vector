-- SPDX-License-Identifier: GPL-2.0-or-later

-- Search by name
CREATE MATERIALIZED VIEW IF NOT EXISTS openrailwaymap_facilities_for_name_search AS
  SELECT
    station_ids,
    found_stations.name as terms
  FROM (
    SELECT
      s.id,
      to_tsvector('simple', unaccent(openrailwaymap_hyphen_slash_to_space((each(s.name_tags)).value))) as name
    FROM stations s
    WHERE s.name_tags IS NOT NULL
  ) found_stations
  JOIN grouped_stations_with_importance gs
    ON ARRAY[found_stations.id] <@ gs.station_ids
  GROUP BY station_ids, terms;

CREATE INDEX IF NOT EXISTS openrailwaymap_facilities_name_index
  ON openrailwaymap_facilities_for_name_search
    USING gin(terms);

-- Search by reference
CREATE MATERIALIZED VIEW IF NOT EXISTS openrailwaymap_facilities_for_ref_search AS
  SELECT
    station_ids,
    array_agg(DISTINCT reference) as terms
  FROM (
    SELECT
      id,
      lower(unnest(avals("references"))) as reference
    FROM stations
    WHERE "references" IS NOT NULL

    UNION ALL

    SELECT
      s.id,
      lower(unnest(avals(sa."references"))) as reference
    FROM stop_areas sa
    JOIN stations_stop_areas ssa
      ON ssa.stop_area_osm_id = sa.osm_id
    JOIN stations s
      ON ssa.station_id = s.id
    WHERE sa."references" IS NOT NULL
  ) found_stations
  JOIN grouped_stations_with_importance gs
    ON ARRAY[found_stations.id] <@ gs.station_ids
  GROUP BY station_ids;

CREATE INDEX IF NOT EXISTS openrailwaymap_facilities_ref_index
  ON openrailwaymap_facilities_for_ref_search
    USING gin(terms);
