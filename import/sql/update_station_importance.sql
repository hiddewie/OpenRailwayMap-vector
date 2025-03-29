-- Refresh materialized view of stations and their importance

REFRESH MATERIALIZED VIEW stations_clustered;
REFRESH MATERIALIZED VIEW grouped_stations_with_route_count;
