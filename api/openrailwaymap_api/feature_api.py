import json

with open('static/features.json', 'r') as features_file:
    features = json.load(features_file)


def localize_fields(fields, localized_fields, lang):
    loc = {field: fields[spec['field']][spec['default']] for field, spec in localized_fields.items()}

    if lang is not None:
        for field, spec in localized_fields.items():
            value = fields[spec['field']]
            key = spec['key'].replace('{lang}', lang)
            if key in value:
                loc[field] = value[key]

    return fields | loc


class FeatureAPI:
    def __init__(self, database):
        self.database = database

    async def __call__(self, *, source, layer, id, lang = None):
        return await self.feature_catalog_data(f'{source}-{layer}', id, lang)

    async def feature_catalog_data(self, catalog_key, id, lang = None):
        if catalog_key not in features:
            return None
        catalog = features[catalog_key]

        if 'view' not in catalog:
            return None
        view_name = catalog['view']['name']
        view_id_type = catalog['view']['id_type']
        localized_fields = catalog['view']['localizedFields'] if 'localizedFields' in catalog['view'] else {}

        if 'properties' not in catalog:
            return None

        # Combine all property references in the catalog for the view query
        properties = (
            {'osm_id', 'osm_type'} |
            catalog['properties'].keys() |
            {catalog['featureProperty'] if 'featureProperty' in catalog else 'feature'} |
            {catalog['colorProperty'] if 'colorProperty' in catalog else None} |
            set(catalog['labelProperties'] if 'labelProperties' in catalog else []) |
            {field['field'] for field in localized_fields.values()}
        ) - (
            localized_fields.keys()
        )

        sql_query = f"""
            SELECT {', '.join(f'"{property}"' for property in properties if property)}
            FROM "{view_name}" 
            WHERE id = $1::{view_id_type} 
        """

        async with self.database.acquire() as connection:
            statement = await connection.prepare(sql_query)
            async with connection.transaction():
                async for record in statement.cursor(id):
                    return localize_fields(dict(record), localized_fields, lang)
                else:
                    return None
