# SPDX-License-Identifier: GPL-2.0-or-later
from openrailwaymap_api.abstract_api import AbstractAPI

class FacilityAPI(AbstractAPI):
    def __init__(self, db_conn):
        self.db_conn = db_conn
        self.search_args = ['q', 'name', 'ref', 'uic_ref']
        self.data = []
        self.status_code = 200
        self.limit = 20

    def eliminate_duplicates(self, data):
        data.sort(key=lambda k: k['osm_id'])
        i = 1
        while i < len(data):
            if data[i]['osm_id'] == data[i-1]['osm_id']:
                data.pop(i)
            i += 1
        if len(data) > self.limit:
            return data[:self.limit]
        return data

    def __call__(self, args):
        data = []
        # Validate search arguments
        search_args_count = 0
        for search_arg in self.search_args:
            if search_arg in args and args[search_arg]:
                search_args_count += 1
        if search_args_count > 1:
            self.data = {'type': 'multiple_query_args', 'error': 'More than one argument with a search term provided.', 'detail': 'Provide only one of the following arguments: {}'.format(', '.join(self.search_args))}
            self.status_code = 400
            return self.build_response()
        elif search_args_count == 0:
            self.data = {'type': 'no_query_arg', 'error': 'No argument with a search term provided.', 'detail': 'Provide one of the following arguments: {}'.format(', '.join(self.search_args))}
            self.status_code = 400
            return self.build_response()
        if 'limit' in args:
            try:
                self.limit = int(args['limit'])
            except ValueError:
                self.data = {'type': 'limit_not_integer', 'error': 'Invalid paramter value provided for parameter "limit".', 'detail': 'The provided limit cannot be parsed as an integer value.'}
                self.status_code = 400
                return self.build_response()
            if self.limit > self.MAX_LIMIT:
                self.data = {'type': 'limit_too_high', 'error': 'Invalid paramter value provided for parameter "limit".', 'detail': 'Limit is too high. Please set up your own instance to query everything.'}
                self.status_code = 400
                return self.build_response()
        if args.get('name'):
            self.data = self.search_by_name(args['name'])
        if args.get('ref'):
            self.data = self.search_by_ref(args['ref'])
        if args.get('uic_ref'):
            self.data = self.search_by_uic_ref(args['uic_ref'])
        if args.get('q'):
            self.data = self.eliminate_duplicates(self.search_by_name(args['q']) + self.search_by_ref(args['q']) + self.search_by_uic_ref(args['q']))
        return self.build_response()

    def query_has_no_wildcards(self, q):
        if '%' in q or '_' in q:
            return False
        return True

    def search_by_name(self, q):
        if not self.query_has_no_wildcards(q):
            self.status_code = 400
            return {'type': 'wildcard_in_query', 'error': 'Wildcard in query.', 'detail': 'Query contains any of the wildcard characters: %_'}
        with self.db_conn.cursor() as cursor:
            data = []
            # TODO support filtering on state of feature: abandoned, in construction, disused, preserved, etc.
            # We do not sort the result although we use DISTINCT ON because osm_id is sufficient to sort out duplicates.
            sql_query = """SELECT
                {fields}, latitude, longitude, rank
                FROM (
                  SELECT DISTINCT ON (osm_id)
                    {fields}, latitude, longitude, rank
                  FROM (
                    SELECT
                        {fields}, ST_X(ST_Transform(geom, 4326)) AS latitude, ST_Y(ST_Transform(geom, 4326)) AS longitude, openrailwaymap_name_rank(phraseto_tsquery('simple', unaccent(openrailwaymap_hyphen_to_space(%s))), terms, route_count, railway, station) AS rank
                      FROM openrailwaymap_facilities_for_search
                      WHERE terms @@ phraseto_tsquery('simple', unaccent(openrailwaymap_hyphen_to_space(%s)))
                    ) AS a
                  ) AS b
                  ORDER BY rank DESC NULLS LAST
              LIMIT %s;""".format(fields=self.sql_select_fieldlist())
            cursor.execute(sql_query, (q, q, self.limit))
            results = cursor.fetchall()
            for r in results:
                data.append(self.build_result_item_dict(cursor.description, r))
        return data

    def _search_by_ref(self, search_key, ref):
        with self.db_conn.cursor() as cursor:
            data = []
            # We do not sort the result although we use DISTINCT ON because osm_id is sufficient to sort out duplicates.
            sql_query = """SELECT DISTINCT ON (osm_id)
              {}, ST_X(ST_Transform(geom, 4326)) AS latitude, ST_Y(ST_Transform(geom, 4326)) AS longitude
              FROM openrailwaymap_ref
              WHERE {} = %s
              LIMIT %s;""".format(self.sql_select_fieldlist(), search_key)
            cursor.execute(sql_query, (ref, self.limit))
            results = cursor.fetchall()
            for r in results:
                data.append(self.build_result_item_dict(cursor.description, r))
        return data

    def search_by_ref(self, ref):
        return self._search_by_ref("railway_ref", ref)

    def search_by_uic_ref(self, ref):
        return self._search_by_ref("uic_ref", ref)

    def sql_select_fieldlist(self):
        return "osm_id, name, railway, railway_ref"
