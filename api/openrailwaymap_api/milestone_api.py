class MilestoneAPI:
    def __init__(self, database):
        self.database = database

    async def __call__(self, *, ref, position, limit):
        return await self.get_milestones(position, ref, limit)

    async def get_milestones(self, position, line_ref, limit):
        sql_query = """
          SELECT * from query_milestones($1::double precision, $2::text, $3::integer)
        """

        async with self.database.acquire() as connection:
            statement = await connection.prepare(sql_query)
            async with connection.transaction():
                data = []
                async for record in statement.cursor(position, line_ref, limit):
                    data.append(dict(record))
                return data
