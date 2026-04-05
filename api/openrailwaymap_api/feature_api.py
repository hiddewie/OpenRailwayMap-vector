class FeatureAPI:
    def __init__(self, database):
        self.database = database

    async def __call__(self, *, source, layer, id):
        if source == 'openrailwaymap_signals':
            if layer == 'signals_railway_signals':
                return await self.signal_data(id)
        return None

    # TODO merge this query and metadata with the features.json file
    async def signal_data(self, id):
        # TODO:
        #   ${signals_railway_signals.tags.map(tag => `
        #       ${tag.type === 'array' ? `array_to_string("${tag.tag}", U&'\\001E') as "${tag.tag}"` : `"${tag.tag}"`},`).join('')}
        sql_query = """
            SELECT
                osm_id,
                direction_both,
                ref,
                caption,
                railway,
                position,
                wikidata,
                wikimedia_commons,
                wikimedia_commons_file,
                image,
                mapillary,
                wikipedia,
                note,
                description,
                feature0,
                feature1,
                feature2,
                feature3,
                feature4,
                feature5,
                deactivated0,
                deactivated1,
                deactivated2,
                deactivated3,
                deactivated4,
                deactivated5,
                type
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
