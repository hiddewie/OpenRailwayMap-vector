class MilestoneAPI:
    def __init__(self, database):
        self.database = database

    async def __call__(self, *, ref, position, limit):
        return await self.get_milestones(position, ref, limit)

    async def get_milestones(self, position, line_ref, limit):
        # We do not sort the result, although we use DISTINCT ON because osm_id is sufficient to sort out duplicates.
        sql_query = """
          SELECT
            osm_id,
            railway,
            position,
            ST_X(geom) AS latitude,
            ST_Y(geom) As longitude,
            line_ref,
            milestone_ref,
            operator,
            wikidata,
            wikimedia_commons,
            image,
            mapillary,
            wikipedia,
            note,
            description
           FROM (
            SELECT
              osm_id,
              railway,
              position,
              geom,
              line_ref,
              milestone_ref,
              operator,
              wikidata,
              wikimedia_commons,
              image,
              mapillary,
              wikipedia,
              note,
              description,
              -- We use rank(), not row_number() to get the closest and all second closest in cases like this:
              --   A B x   C
              -- where A is as far from the searched location x than C.
              rank() OVER (PARTITION BY operator ORDER BY error) AS grouped_rank
            FROM (
              SELECT
                -- Sort out duplicates which origin from tracks being split at milestones
                DISTINCT ON (osm_id)
                  osm_id[1] AS osm_id,
                  railway[1] AS railway,
                  position,
                  geom[1] AS geom,
                  line_ref,
                  milestone_ref[1] AS milestone_ref,
                  operator,
                  wikidata[1] AS wikidata,
                  wikimedia_commons[1] AS wikimedia_commons,
                  image[1] AS image,
                  mapillary[1] AS mapillary,
                  wikipedia[1] AS wikipedia,
                  note[1] AS note,
                  description[1] AS description,
                  error
                FROM (
                  SELECT
                    array_agg(osm_id) AS osm_id,
                    array_agg(railway) AS railway,
                    position AS position,
                    array_agg(geom) AS geom,
                    line_ref,
                    operator,
                    array_agg(milestone_ref) AS milestone_ref,
                    array_agg(wikidata) AS wikidata,
                    array_agg(wikimedia_commons) AS wikimedia_commons,
                    array_agg(image) AS image,
                    array_agg(mapillary) AS mapillary,
                    array_agg(wikipedia) AS wikipedia,
                    array_agg(note) AS note,
                    array_agg(description) AS description,
                    error
                  FROM (
                    SELECT
                      m.osm_id,
                      m.railway,
                      m.position,
                      ST_Transform(m.geom, 4326) AS geom,
                      t.ref AS line_ref,
                      m.ref AS milestone_ref,
                      wikidata,
                      wikimedia_commons,
                      image,
                      mapillary,
                      wikipedia,
                      note,
                      description,
                      operator,
                      ABS($1 - m.position) AS error
                    FROM openrailwaymap_milestones AS m
                    JOIN openrailwaymap_tracks_with_ref AS t
                      ON t.geom && m.geom AND ST_Intersects(t.geom, m.geom) AND t.ref = $2
                    WHERE m.position BETWEEN ($1 - 10.0)::FLOAT AND ($1 + 10.0)::FLOAT
                    -- sort by distance from searched location, then osm_id for stable sorting
                    ORDER BY error ASC, m.osm_id
                  ) AS milestones
                  GROUP BY position, error, line_ref, operator
                ) AS unique_milestones
              ) AS top_of_array
            ) AS ranked
            WHERE grouped_rank <= $3
            LIMIT $3;
        """

        async with self.database.acquire() as connection:
            statement = await connection.prepare(sql_query)
            async with connection.transaction():
                data = []
                async for record in statement.cursor(position, line_ref, limit):
                    data.append(dict(record))
                return data
