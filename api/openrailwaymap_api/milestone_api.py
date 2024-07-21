# SPDX-License-Identifier: GPL-2.0-or-later
from fastapi import HTTPException
from openrailwaymap_api.abstract_api import AbstractAPI
from starlette.status import HTTP_400_BAD_REQUEST


class MilestoneAPI(AbstractAPI):
    def __init__(self, database):
        self.database = database
        self.route_ref = None
        self.position = None
        self.data = []
        self.status_code = 200
        self.limit = 2

    async def __call__(self, args):
        # Validate search arguments
        ref = args.get('ref')
        position = args.get('position')
        if ref is None or position is None:
            raise HTTPException(
                HTTP_400_BAD_REQUEST,
                {'type': 'no_query_arg', 'error': 'One or multiple mandatory parameters are missing.', 'detail': 'You have to provide both "ref" and "position".'}
            )
        self.route_ref = args.get('ref')
        try:
            self.position = float(args.get('position'))
        except ValueError:
            raise HTTPException(
                HTTP_400_BAD_REQUEST,
                {'type': 'position_not_float', 'error': 'Invalid value provided for parameter "position".', 'detail': 'The provided position cannot be parsed as a float.'}
            )
        if 'limit' in args:
            try:
                self.limit = int(args['limit'])
            except ValueError:
                raise HTTPException(
                    HTTP_400_BAD_REQUEST,
                    {'type': 'limit_not_integer', 'error': 'Invalid parameter value provided for parameter "limit".', 'detail': 'The provided limit cannot be parsed as an integer value.'}
                )
            if self.limit > self.MAX_LIMIT:
                raise HTTPException(
                    HTTP_400_BAD_REQUEST,
                    {'type': 'limit_too_high', 'error': 'Invalid parameter value provided for parameter "limit".', 'detail': 'Limit is too high. Please set up your own instance to query everything.'}
                )
        self.data = await self.get_milestones()
        return self.data

    async def get_milestones(self):
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
                                       -- TODO import operator
                                       NULL AS operator,
                                       ABS($1 - m.position) AS error
                                     FROM openrailwaymap_milestones AS m
                                     JOIN openrailwaymap_tracks_with_ref AS t
                                       ON t.geom && m.geom AND ST_Intersects(t.geom, m.geom) AND t.ref = $2
                                     WHERE m.position BETWEEN ($3 - 10.0)::FLOAT AND ($4 + 10.0)::FLOAT
                                     -- sort by distance from searched location, then osm_id for stable sorting
                                     ORDER BY error ASC, m.osm_id
                                   ) AS milestones
                                   GROUP BY position, error, route_ref, operator
                                 ) AS unique_milestones
                             ) AS top_of_array
                         ) AS ranked
                         WHERE grouped_rank <= $5
                         LIMIT $6;"""

        async with self.database.acquire() as connection:
            statement = await connection.prepare(sql_query)
            async with connection.transaction():
                data = []
                async for record in statement.cursor(self.position, self.route_ref, self.position, self.position, self.limit, self.limit):
                    data.append(dict(record))
                return data
