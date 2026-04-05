import json

with open('static/features.json', 'r') as features_file:
    features = json.load(features_file)

class FeatureAPI:
    def __init__(self, database):
        self.database = database

    async def __call__(self, *, source, layer, id):
        return await self.feature_catalog_data(f'{source}-{layer}', id)

    async def feature_catalog_data(self, catalog_key, id):
        if catalog_key not in features:
            return None
        catalog = features[catalog_key]

        if 'view' not in catalog:
            return None
        view = catalog['view']

        if 'properties' not in catalog:
            return None
        properties = catalog['properties'].keys()

        sql_query = f"""
            SELECT {', '.join(f'"{property}"' for property in properties)}
            FROM "{view}" 
            WHERE id = $1::numeric 
        """

        async with self.database.acquire() as connection:
            statement = await connection.prepare(sql_query)
            async with connection.transaction():
                async for record in statement.cursor(id):
                    return dict(record)
                else:
                    return None
