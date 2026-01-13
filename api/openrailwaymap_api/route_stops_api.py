class RouteStopsAPI:
    def __init__(self, database):
        self.database = database

    async def __call__(self, osm_id):
        sql_query = """
            SELECT jsonb_build_object(
                'type',  'FeatureCollection',
                'features', jsonb_agg(features.feature)
            ) as data
            FROM (
                SELECT jsonb_build_object(
                    'type', 'Feature',
                    'id', osm_id,
                    'geometry', ST_AsGeoJSON(ST_Transform(way, 4326))::jsonb,
                    'properties', to_jsonb(row) - 'way'
                ) as feature
                FROM (SELECT
                    sp.osm_id,
                    sp.way,
                    sp.type,
                    sp.name,
                    sp.ref,
                    sp.local_ref,
                    CASE
                        WHEN rs.role = 'stop_entry_only' THEN true
                    END as entry_only,
                    CASE
                        WHEN rs.role = 'stop_exit_only' THEN true
                    END as exit_only
                    from routes r
                    join route_stop rs
                        on rs.route_id = r.osm_id
                    join stop_positions sp
                        on rs.stop_id=sp.osm_id
                    where r.osm_id = $1::bigint
                ) row
            ) features
        """

        async with self.database.acquire() as connection:
            statement = await connection.prepare(sql_query)
            async with connection.transaction():
                async for record in statement.cursor(osm_id):
                    return record['data']

        return None
