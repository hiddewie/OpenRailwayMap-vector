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

        # Combine all property references in the catalog for the view query
        properties = (
            {'osm_id', 'osm_type'} |
            catalog['properties'].keys() |
            {catalog['featureProperty'] if 'featureProperty' in catalog else 'feature'} |
            {catalog['colorProperty'] if 'colorProperty' in catalog else None} |
            set(catalog['labelProperties'] if 'labelProperties' in catalog else [])
        )

        # TODO filter between numeric and text ID
        sql_query = f"""
            SELECT {', '.join(f'"{property}"' for property in properties if property)}
            FROM "{view}" 
            WHERE id = $1::text 
        """

        async with self.database.acquire() as connection:
            statement = await connection.prepare(sql_query)
            async with connection.transaction():
                async for record in statement.cursor(id):
                    return dict(record)
                else:
                    return None
