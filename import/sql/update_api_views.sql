-- Refresh facilities API views
REFRESH MATERIALIZED VIEW openrailwaymap_facilities_for_search;
REFRESH MATERIALIZED VIEW openrailwaymap_ref;

-- Refresh milestone API views
REFRESH MATERIALIZED VIEW openrailwaymap_milestones;
REFRESH MATERIALIZED VIEW openrailwaymap_tracks_with_ref;
