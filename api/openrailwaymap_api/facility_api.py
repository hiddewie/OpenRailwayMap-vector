from fastapi import HTTPException
from starlette.status import HTTP_400_BAD_REQUEST, HTTP_422_UNPROCESSABLE_ENTITY

QUERY_PARAMETERS = ['q', 'name', 'ref', 'uic_ref']

class FacilityAPI:
    def __init__(self, database):
        self.database = database

    def eliminate_duplicates(self, data, limit):
        seen_osm_ids = set()
        results = []
        for item in data:
            osm_ids = tuple(item['osm_ids'])
            if osm_ids not in seen_osm_ids:
                seen_osm_ids.add(osm_ids)
                results.append(item)

                if len(results) == limit:
                    break

        return results

    async def __call__(self, *, q, name, ref, uic_ref, language, limit):
        # Validate search arguments
        search_args_count = sum(1 for search_arg in [q, name, ref, uic_ref] if search_arg)

        if search_args_count > 1:
            args = ', '.join(QUERY_PARAMETERS)
            raise HTTPException(
                HTTP_422_UNPROCESSABLE_ENTITY,
                {'type': 'multiple_query_args', 'error': 'More than one argument with a search term provided.', 'detail': f'Provide only one of the following query parameters: {args}'}
            )
        elif search_args_count == 0:
            args = ', '.join(QUERY_PARAMETERS)
            raise HTTPException(
                HTTP_422_UNPROCESSABLE_ENTITY,
                {'type': 'no_query_arg', 'error': 'No argument with a search term provided.', 'detail': f'Provide one of the following query parameters: {args}'}
            )

        if name:
            return await self.search_by_name(name, language, limit)
        if ref:
            return await self.search_by_ref(ref, language, limit)
        if uic_ref:
            return await self.search_by_uic_ref(uic_ref, language, limit)
        if q:
            return self.eliminate_duplicates((await self.search_by_name(q, language, limit)) + (await self.search_by_ref(q, language, limit)) + (await self.search_by_uic_ref(q, language, limit)), limit)

    def query_has_no_wildcards(self, q):
        if '%' in q or '_' in q:
            return False
        return True

    async def search_by_name(self, q, language, limit):
        if not self.query_has_no_wildcards(q):
            raise HTTPException(
                HTTP_400_BAD_REQUEST,
                {'type': 'wildcard_in_query', 'error': 'Wildcard in query.', 'detail': 'Query contains any of the wildcard characters: %_'}
            )

        sql_query = """
          SELECT * FROM query_facilities_by_name($1, $2, $3)
        """
        return await self.query_result(sql_query, (q, language, limit))

    async def _search_by_ref(self, search_function, ref, language, limit):
        sql_query = f"""
          SELECT * FROM {search_function}($1, $2, $3)
        """
        return await self.query_result(sql_query, (ref, language, limit))

    async def search_by_ref(self, ref, language, limit):
        return await self._search_by_ref("query_facilities_by_ref", ref, language, limit)

    async def search_by_uic_ref(self, ref, language, limit):
        return await self._search_by_ref("query_facilities_by_uic_ref", ref, language, limit)

    async def query_result(self, sql_query, parameters):
        async with self.database.acquire() as connection:
            statement = await connection.prepare(sql_query)
            async with connection.transaction():
                data = []
                async for record in statement.cursor(*parameters):
                    data.append(dict(record))
                return data
