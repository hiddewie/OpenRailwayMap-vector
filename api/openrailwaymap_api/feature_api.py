import json

with open('static/features.json', 'r') as features_file:
    features = json.load(features_file)

class FeatureAPI:
    def __init__(self, database):
        self.database = database

    async def __call__(self, *, source, layer, id):
        # TODO make this work for all sources and layers
        if source == 'openrailwaymap_signals':
            if layer == 'signals_railway_signals':
                return await self.signal_data(id)
        return None

    async def signal_data(self, id):
        properties = features['openrailwaymap_signals-signals_railway_signals']['properties'].keys()
        sql_query = f"""
            SELECT {', '.join(f'"{property}"' for property in properties)}
            FROM signals_railway_signals_view 
            WHERE id = $1::numeric 
        """

        async with self.database.acquire() as connection:
            statement = await connection.prepare(sql_query)
            async with connection.transaction():
                async for record in statement.cursor(id):
                    return dict(record)
                else:
                    return None
