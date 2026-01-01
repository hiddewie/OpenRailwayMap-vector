class RouteAPI:
    def __init__(self, database):
        self.database = database

    async def __call__(self, osm_id):
        sql_query = """
            SELECT jsonb_build_object(
                'type', 'Feature',
                'id', osm_id,
                'geometry', ST_AsGeoJSON(ST_Transform(way, 4326))::jsonb,
                'properties', to_jsonb(row) - 'gid' - 'geom'
            ) as data
            FROM (
                SELECT
                    r.osm_id as osm_id,
                    st_collect(l.way) as way,
                    any_value(r.type) as type,
                    any_value(r.name) as name,
                    any_value(r.ref) as ref,
                    any_value(r.from) as from,
                    any_value(r.to) as to,
                    any_value(r.operator) as operator,
                    any_value(r.brand) as brand,
                    any_value(r.color) as color
                from routes r
                join route_line rl
                    on rl.route_id = r.osm_id
                join railway_line l
                    on rl.line_id = l.osm_id
                where r.osm_id = $1::bigint
                group by r.osm_id
            ) row;
        """

        async with self.database.acquire() as connection:
            statement = await connection.prepare(sql_query)
            async with connection.transaction():
                async for record in statement.cursor(osm_id):
                    return record['data']

        return None
