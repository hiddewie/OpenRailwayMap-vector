# SPDX-License-Identifier: GPL-2.0-or-later
from openrailwaymap_api.abstract_api import AbstractAPI

class MilestoneAPI(AbstractAPI):
    def __init__(self, db_conn):
        self.db_conn = db_conn
        self.route_ref = None
        self.position = None
        self.data = []
        self.status_code = 200
        self.limit = 2

    def __call__(self, args):
        data = []
        # Validate search arguments
        ref = args.get('ref')
        position = args.get('position')
        if ref is None or position is None:
            self.data = {'type': 'no_query_arg', 'error': 'One or multiple mandatory parameters are missing.', 'detail': 'You have to provide both "ref" and "position".'}
            self.status_code = 400
            return self.build_response()
        self.route_ref = args.get('ref')
        try:
            self.position = float(args.get('position'))
        except ValueError:
            self.data = {'type': 'position_not_float', 'error': 'Invalid value provided for parameter "position".', 'detail': 'The provided position cannot be parsed as a float.'}
            self.status_code = 400
            return self.build_response()
        if 'limit' in args:
            try:
                self.limit = int(args['limit'])
            except ValueError:
                self.data = {'type': 'limit_not_integer', 'error': 'Invalid parameter value provided for parameter "limit".', 'detail': 'The provided limit cannot be parsed as an integer value.'}
                self.status_code = 400
                return self.build_response()
            if self.limit > self.MAX_LIMIT:
                self.data = {'type': 'limit_too_high', 'error': 'Invalid parameter value provided for parameter "limit".', 'detail': 'Limit is too high. Please set up your own instance to query everything.'}
                self.status_code = 400
                return self.build_response()
        print(ref, position)
        self.data = self.get_milestones()
        return self.build_response()

    def get_milestones(self):
        with self.db_conn.cursor() as cursor:
            data = []
            # We do not sort the result although we use DISTINCT ON because osm_id is sufficient to sort out duplicates.
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
                                   -- Sort out duplicates which origin from tracks being splitted at milestones
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
                                         unnest(ST_ClusterWithin(geom, 25)) AS geom_collection,
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
                                           ABS(%s - m.position) AS error
                                         FROM openrailwaymap_milestones AS m
                                         JOIN openrailwaymap_tracks_with_ref AS t
                                           ON t.geom && m.geom AND ST_Intersects(t.geom, m.geom) AND t.ref = %s
                                         WHERE m.position BETWEEN (%s - 10.0)::FLOAT AND (%s + 10.0)::FLOAT
                                         -- sort by distance from searched location, then osm_id for stable sorting
                                         ORDER BY error ASC, m.osm_id
                                       ) AS milestones
                                       GROUP BY position, error, route_ref, operator
                                     ) AS unique_milestones
                                 ) AS top_of_array
                             ) AS ranked
                             WHERE grouped_rank <= %s
                             LIMIT %s;"""
            print(sql_query,  (self.position, self.route_ref, self.position, self.position, self.limit, self.limit))
            cursor.execute(sql_query, (self.position, self.route_ref, self.position, self.position, self.limit, self.limit))
            results = cursor.fetchall()
            for r in results:
                data.append(self.build_result_item_dict(cursor.description, r))
        return data
