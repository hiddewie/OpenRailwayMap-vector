import json
import logging

logger = logging.getLogger(__name__)

with open('static/features.json', 'r') as features_file:
    features = json.load(features_file)


def localize_fields(fields, localized_fields, lang):
    loc = {}

    for field, spec in localized_fields.items():
        value = fields[spec['field']] or {}
        localized_value = value[spec['default']] if spec['default'] in value else None

        if lang is not None:
            key = spec['key'].replace('{lang}', lang)

            if key in value:
                localized_value = value[key]

        loc[field] = localized_value

    return fields | loc


class FeatureAPI:
    def __init__(self, database, wikidata_api):
        self.database = database
        self.wikidata_api = wikidata_api

    async def __call__(self, *, source, layer, id, lang=None):
        catalog_data = await self.feature_catalog_data(f'{source}-{layer}', id, lang)
        if not catalog_data:
            return None

        images = []

        if 'wikidata' in catalog_data and catalog_data['wikidata']:
            wikidata_ids = catalog_data['wikidata'] if type(catalog_data['wikidata']) == list else [catalog_data['wikidata']]
            for id in wikidata_ids:
                try:
                    image = await self.wikidata_api.wikidata_image(id=id)
                    if image:
                        images.append(image)
                except Exception as error:
                    logger.error(f'Error while fetching Wikidata for {catalog_data['wikidata']}', error)

        if 'wikimedia_commons_file' in catalog_data and catalog_data['wikimedia_commons_file']:
            wikimedia_commons_files = catalog_data['wikimedia_commons_file'] if type(catalog_data['wikimedia_commons_file']) == list else [catalog_data['wikimedia_commons_file']]
            for file in wikimedia_commons_files:
                try:
                    images.append(await self.wikidata_api.wikimedia_commons_file(file_name=file))
                except Exception as error:
                    logger.error(f'Error while fetching Wikimedia Commons file for {catalog_data['wikimedia_commons_file']}', error)

        return {
            'properties': catalog_data,
            'images': images,
        }

    async def feature_catalog_data(self, catalog_key, id, lang=None):
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
            WHERE id = $1 
        """

        async with self.database.acquire() as connection:
            statement = await connection.prepare(sql_query)
            async with connection.transaction():
                cast_id = int(id) if view_id_type == 'numeric' else id
                async for record in statement.cursor(cast_id):
                    return localize_fields(dict(record), localized_fields, lang)
                else:
                    return None
