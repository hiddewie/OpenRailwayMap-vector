class ReplicationAPI:
    def __init__(self, database):
        self.database = database

    async def __call__(self):
      sql_query = """
                  select
                    (select "value" from osm2pgsql_properties where property='replication_timestamp' limit 1) as replication_timestamp,
                    (select "value" from osm2pgsql_properties where property='initial_import_timestamp' limit 1) as initial_import_timestamp
                  """

      async with self.database.acquire() as connection:
        statement = await connection.prepare(sql_query)
        async with connection.transaction():
          async for record in statement.cursor():
            return dict(record)
          return None
