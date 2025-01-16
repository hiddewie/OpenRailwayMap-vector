class MilestoneAPI:
    def __init__(self, database):
        self.database = database

    async def __call__(self, *, ref, position, limit):
        return await self.get_milestones(position, ref, limit)

    async def get_milestones(self, position, route_ref, limit):
        # We do not sort the result, although we use DISTINCT ON because osm_id is sufficient to sort out duplicates.
        sql_query = """SELECT
                         osm_id,
                         railway,
                         position,
                         ST_X(geom) AS latitude,
                         ST_Y(geom) As longitude,
                         route_ref AS ref,
                         operator
                       FROM (
                         SELECT
                             osm_id,
                             railway,
                             position,
                             geom,
                             route_ref,
                             operator,
                             -- We use rank(), not row_number() to get the closest and all second closest in cases like this:
                             --   A B x   C
                             -- where A is as far from the searched location x than C.
                             rank() OVER (PARTITION BY operator ORDER BY error) AS grouped_rank
                           FROM (
                             SELECT
                               -- Sort out duplicates which origin from tracks being split at milestones
                               DISTINCT ON (osm_id)
                                 osm_id[1] AS osm_id,
                                 railway[1] AS railway,
                                 position,
                                 geom[1] AS geom,
                                 route_ref,
                                 operator,
                                 error
                               FROM (
                                 SELECT
                                     array_agg(osm_id) AS osm_id,
                                     array_agg(railway) AS railway,
                                     position AS position,
                                     array_agg(geom) AS geom,
                                     route_ref,
                                     operator,
                                     error
                                   FROM (
                                     SELECT
                                       m.osm_id,
                                       m.railway,
                                       m.position,
                                       ST_Transform(m.geom, 4326) AS geom,
                                       t.ref AS route_ref,
                                       operator,
                                       ABS($1 - m.position) AS error
                                     FROM openrailwaymap_milestones AS m
                                     JOIN openrailwaymap_tracks_with_ref AS t
                                       ON t.geom && m.geom AND ST_Intersects(t.geom, m.geom) AND t.ref = $2
                                     WHERE m.position BETWEEN ($1 - 10.0)::FLOAT AND ($1 + 10.0)::FLOAT
                                     -- sort by distance from searched location, then osm_id for stable sorting
                                     ORDER BY error ASC, m.osm_id
                                   ) AS milestones
                                   GROUP BY position, error, route_ref, operator
                                 ) AS unique_milestones
                             ) AS top_of_array
                         ) AS ranked
                         WHERE grouped_rank <= $3
                         LIMIT $3;"""

        async with self.database.acquire() as connection:
            statement = await connection.prepare(sql_query)
            async with connection.transaction():
                data = []
                async for record in statement.cursor(position, route_ref, limit):
                    data.append(dict(record))
                return data
