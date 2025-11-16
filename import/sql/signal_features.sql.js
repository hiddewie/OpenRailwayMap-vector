import fs from 'fs'
import yaml from 'yaml'

const signals_railway_signals = yaml.parse(fs.readFileSync('signals_railway_signals.yaml', 'utf8'))

const layers = [...new Set(signals_railway_signals.types.map(type => type.layer))]

async function parseSvgDimensions(feature) {
  const svg = await fs.promises.readFile(`symbols/${feature}.svg`, 'utf8')
  // Crude way of parsing SVG width/height. But given that all SVG icons are compressed and similar SVG content, this works fine.
  const matches = svg.match(/<svg .*width="([^"]+)".*height="([^"]+)".*>/)
  if (!matches) {
    throw new Error(`Could not find <svg> element with width/height for feature ${feature} in SVG content "${svg}"`)
  }
  return {
    width: parseFloat(matches[1]),
    height: parseFloat(matches[2]),
  }
}

const signalsWithSignalType = await Promise.all(
  signals_railway_signals.features
    // Determine a signal type per layer such that combined matching does not try to match other signal types for the same feature
    .map(feature => ({
      ...feature,
      signalTypes: Object.fromEntries(
        layers.map(layer =>
          [layer, signals_railway_signals.types.filter(type => type.layer === layer).find(type => feature.tags.find(it => it.tag === `railway:signal:${type.type}`))?.type]
        )
      )})
    )
    // Determine icon dimensions
    .map(async feature => ({
      ...feature,
      feature: feature.feature,
      icon: await Promise.all(feature.icon.map(async icon => ({
        ...icon,
        cases: icon.cases
          ? await Promise.all(icon.cases.map(async iconCase => ({
              ...iconCase,
              dimensions: await parseSvgDimensions(iconCase.example ?? iconCase.value)
            })))
          : undefined,
        dimensions: icon.default ? await parseSvgDimensions(icon.default) : undefined,
      }))),
    }))
);

const tagTypes = Object.fromEntries(signals_railway_signals.tags.map(tag =>
  [tag.tag, tag.type]))

function matchTagValueSql(tag, value) {
  switch (tagTypes[tag]) {
    case 'array':
      return `'${value}' = ANY("${tag}")`
    case 'boolean':
      if (value) {
        throw new Error(`Value given for boolean tag '${tag}' ('${value}')`)
      }
      return `"${tag}"`
    default:
      return `"${tag}" = '${value}'`
  }
}

function matchTagAllValuesSql(tag, values) {
  switch (tagTypes[tag]) {
    case 'array':
      return `ARRAY[${values.map(value => `'${value}'`).join(', ')}] <@ "${tag}"`
    case 'boolean':
      if (values) {
        throw new Error(`Values given for boolean tag '${tag}' ('${values}')`)
      }
      return `"${tag}"`
    default:
      return `false`
  }
}

function matchTagAnyValueSql(tag, values) {
  switch (tagTypes[tag]) {
    case 'array':
      return `ARRAY[${values.map(value => `'${value}'`).join(', ')}] && "${tag}"`
    case 'boolean':
      if (values) {
        throw new Error(`Values given for boolean tag '${tag}' ('${values}')`)
      }
      return `"${tag}"`
    default:
      return `"${tag}" IN (${values.map(value => `'${value}'`).join(', ')})`
  }
}

function matchTagRegexSql(tag, regex) {
  switch (tagTypes[tag]) {
    case 'array':
      return `'${regex}' ~!@# ANY("${tag}")`
    case 'boolean':
      if (regex) {
        throw new Error(`Regex given for boolean tag '${tag}' ('${regex}')`)
      }
      return `"${tag}"`
    default:
      return `"${tag}" ~ '${regex}'`
  }
}

function stringSql(tag, matchCase) {
  switch (tagTypes[tag]) {
    case 'array':
      return `(select match from (select regexp_substr(match, '${matchCase.regex}') as match from (select unnest("${tag}") as match) matches1) matches2 where match is not null order by length(match) desc, match desc limit 1)`
    case 'boolean':
      return `"${tag}"`
    default:
      if (matchCase.regex) {
        return `regexp_substr("${tag}", '${matchCase.regex}', 1, 1, '', 1)`
      } else {
        return `"${tag}"`
      }
  }
}

function matchFeatureTagsSql(tags) {
  return tags.map(tag => tag.value ? matchTagValueSql(tag.tag, tag.value) : tag.all ? matchTagAllValuesSql(tag.tag, tag.all) : matchTagAnyValueSql(tag.tag, tag.any)).join(' AND ')
}

function matchIconCase(tag, iconCase) {
  if (iconCase.regex) {
    return matchTagRegexSql(tag, iconCase.regex)
  } else if (iconCase.all) {
    return matchTagAllValuesSql(tag, iconCase.all)
  } else if (iconCase.any) {
    return matchTagAnyValueSql(tag, iconCase.any)
  } else {
    return matchTagValueSql(tag, iconCase.exact);
  }
}

function iconCaseSql(iconCase, matchTag, position) {
  if (iconCase.value.includes('{}')) {
    return `ARRAY[CONCAT('${iconCase.value.replace(/\{}.*$/, '{')}', ${stringSql(matchTag, iconCase)}, '${iconCase.value.replace(/^.*\{}/, '}')}${position ? `@${position}` : ''}'), ${stringSql(matchTag, iconCase)}, '${iconCase.dimensions.height}']`
  } else {
    return `ARRAY['${iconCase.value}${position ? `@${position}` : ''}', NULL, '${iconCase.dimensions.height}']`
  }
}

function featureIconSql(icon) {
  const defaultIconSql = icon.default ? `ARRAY['${icon.default}${icon.position ? `@${icon.position}` : ''}', NULL, '${icon.dimensions.height}']` : 'NULL'

  if (icon.match) {
    return `CASE ${icon.cases.map(iconCase => `
                    WHEN ${matchIconCase(icon.match, iconCase)} THEN ${iconCaseSql(iconCase, icon.match, icon.position)}`).join('')}
                    ${icon.default ? `ELSE ${defaultIconSql}` : ''}
                  END`
  } else {
    return defaultIconSql
  }
}

function featureIconsSql(icons) {
  if (icons.length === 1) {
    // Avoid complex SQL for the single icon case
    return featureIconSql(icons[0])
  } else {
    return `(
                SELECT ARRAY[string_agg(icon[1], '|'), string_agg(COALESCE(icon[2], ''), '|'), MAX(icon[3]::numeric)::text]
                FROM (
                  ${icons.map(icon => `SELECT ${featureIconSql(icon)} as icon`).join(`
                  UNION ALL
                  `)}
                ) icons
                WHERE icon[1] IS NOT NULL
              )`
  }
}

/**
 * Template that builds the SQL view taking the YAML configuration into account
 */
const sql = `
CREATE OR REPLACE VIEW signal_direction_view AS
  SELECT
    s.id as signal_id,
    (signal_direction = 'both') as direction_both,
    degrees(ST_Azimuth(
      st_lineinterpolatepoint(sl.way, greatest(0, st_linelocatepoint(sl.way, ST_ClosestPoint(sl.way, s.way)) - 0.01)),
      st_lineinterpolatepoint(sl.way, least(1, st_linelocatepoint(sl.way, ST_ClosestPoint(sl.way, s.way)) + 0.01))
    )) + (CASE WHEN signal_direction = 'backward' THEN 180.0 ELSE 0.0 END) as azimuth
  FROM signals s
  LEFT JOIN LATERAL (
    SELECT line.way as way
    FROM railway_line line
    WHERE st_dwithin(s.way, line.way, 10) AND line.feature IN ('rail', 'tram', 'light_rail', 'subway', 'narrow_gauge', 'monorail', 'miniature', 'funicular')
    ORDER BY s.way <-> line.way
    LIMIT 1
  ) as sl ON true
  WHERE
    (railway IN ('signal', 'buffer_stop') AND signal_direction IS NOT NULL)
      OR railway IN ('derail', 'vacancy_detection');

-- Use the view directly such that the query in the view can be updated
CREATE MATERIALIZED VIEW IF NOT EXISTS signal_direction AS
  SELECT
    *
  FROM
    signal_direction_view;

CREATE INDEX IF NOT EXISTS signal_direction_signal_id_index
  ON signal_direction
    USING btree(signal_id);

CLUSTER signal_direction
  USING signal_direction_signal_id_index;
    
-- Table with functional signal features
CREATE OR REPLACE VIEW signal_features_view AS
  -- For every type of signal, generate the feature and related metadata
  WITH signals_with_features_0 AS (
    SELECT
      id as signal_id,
      railway,
      ${signals_railway_signals.types.map(type => `
      CASE 
        WHEN "railway:signal:${type.type}" IS NOT NULL THEN
          CASE ${signalsWithSignalType.map((feature, index) => ({...feature, rank: index })).filter(feature => feature.tags.find(it => it.tag === `railway:signal:${type.type}`)).map(feature => `
            -- ${feature.country ? `(${feature.country}) ` : ''}${feature.description}
            WHEN ${matchFeatureTagsSql(feature.tags)}
              THEN ${feature.signalTypes[type.layer] === type.type ? `array_cat(${featureIconsSql(feature.icon)}, ARRAY[${feature.type ? `'${feature.type}'` : 'NULL'}, "railway:signal:${type.type}:deactivated"::text, '${type.layer}', '${feature.rank}'])` : 'NULL'}
            `).join('')}
            -- Unknown signal (${type.type})
            ELSE
              ARRAY['general/signal-unknown-${type.type}', NULL, '17.1', NULL, 'false', '${type.layer}', NULL]
        END
      END as feature_${type.type}`).join(',')}
    FROM signals s
    WHERE
      (railway IN ('signal', 'buffer_stop') AND signal_direction IS NOT NULL)
        OR railway IN ('derail', 'vacancy_detection')
  ),
  -- Output a feature row for every feature
  signals_with_features_1 AS (
    ${signals_railway_signals.types.map(type => `
    SELECT
      signal_id,
      feature_${type.type}[1] as feature,
      feature_${type.type}[2] as feature_variable,
      feature_${type.type}[3]::REAL as icon_height,
      feature_${type.type}[4] as type,
      feature_${type.type}[5]::boolean as deactivated,
      feature_${type.type}[6]::signal_layer as layer,
      feature_${type.type}[7]::INT as rank
    FROM signals_with_features_0
    WHERE feature_${type.type} IS NOT NULL
  `).join(`
    UNION ALL
  `)}
    UNION ALL
    SELECT
      signal_id,
      'general/signal-unknown' as feature,
      NULL as feature_variable,
      17.1 as icon_height,
      NULL as type,
      false as deactivated,
      'signals' as layer,
      NULL as rank
    FROM signals_with_features_0
    WHERE railway = 'signal'
      AND ${signals_railway_signals.types.map(type => `feature_${type.type} IS NULL`).join(' AND ')}
  )
  -- Group features by signal, and aggregate the results
  SELECT
    signal_id,
    any_value(type) as type,
    layer,
    array_agg(feature ORDER BY rank ASC NULLS LAST) as features,
    array_agg(deactivated ORDER BY rank ASC NULLS LAST) as deactivated,
    array_agg(icon_height ORDER BY rank ASC NULLS LAST) as icon_height,
    MAX(rank) as rank
  FROM signals_with_features_1 sf
  GROUP BY signal_id, layer;

-- Use the view directly such that the query in the view can be updated
CREATE MATERIALIZED VIEW IF NOT EXISTS signal_features AS
  SELECT
    *
  FROM
    signal_features_view;

CREATE INDEX IF NOT EXISTS signal_features_signal_id_index
  ON signal_features
    USING btree(signal_id);

CLUSTER signal_features
  USING signal_features_signal_id_index;

--- Speed ---

CREATE OR REPLACE FUNCTION speed_railway_signals(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
  RETURN (
    SELECT
      ST_AsMVT(tile, 'speed_railway_signals', 4096, 'way', 'id')
    FROM (
      SELECT
        id,
        osm_id,
        ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
        sd.direction_both,
        ref,
        caption,
        nullif(array_to_string(position, U&'\\001E'), '') as position,
        wikidata,
        wikimedia_commons,
        wikimedia_commons_file,
        image,
        mapillary,
        wikipedia,
        note,
        description,
        sd.azimuth,${signals_railway_signals.tags.map(tag => `
        ${tag.type === 'array' ? `array_to_string("${tag.tag}", U&'\\001E') as "${tag.tag}"` : `"${tag.tag}"`},`).join('')}
        features[1] as feature0,
        features[2] as feature1,
        deactivated[1] as deactivated0,
        deactivated[2] as deactivated1,
        CEIL(icon_height[1] / 2 + icon_height[2] / 2) as offset1,
        type
      FROM signals s
      JOIN signal_features sf
        ON s.id = sf.signal_id
      JOIN signal_direction sd
        ON s.id = sd.signal_id
      WHERE way && ST_TileEnvelope(z, x, y)
        AND layer = 'speed'
      ORDER BY rank NULLS FIRST
    ) as tile
    WHERE way IS NOT NULL
  );

DO $do$ BEGIN
  EXECUTE 'COMMENT ON FUNCTION speed_railway_signals IS $tj$' || $$
  {
    "vector_layers": [
      {
        "id": "speed_railway_signals",
        "fields": {
          "id": "integer",
          "osm_id": "integer",
          "ref": "string",
          "caption": "string",
          "azimuth": "number",
          "direction_both": "boolean",
          "position": "string",
          "wikidata": "string",
          "wikimedia_commons": "string",
          "wikimedia_commons_file": "string",
          "image": "string",
          "mapillary": "string",
          "wikipedia": "string",
          "note": "string",
          "description": "string",${signals_railway_signals.tags.map(tag => `
          "${tag.tag}": "${tag.type === 'boolean' ? `boolean` : `string`}",`).join('')}
          "feature0": "string",
          "feature1": "string",
          "deactivated0": "boolean",
          "deactivated1": "boolean",
          "offset1": "number",
          "type": "string"
        }
      }
    ]
  }
  $$::json || '$tj$';
END $do$;

--- Signals ---

CREATE OR REPLACE FUNCTION signals_railway_signals(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
  RETURN (
    SELECT
      ST_AsMVT(tile, 'signals_railway_signals', 4096, 'way', 'id')
    FROM (
      SELECT
        id,
        osm_id,
        ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
        sd.direction_both,
        ref,
        caption,
        railway,
        nullif(array_to_string(position, U&'\\001E'), '') as position,
        wikidata,
        wikimedia_commons,
        wikimedia_commons_file,
        image,
        mapillary,
        wikipedia,
        note,
        description,
        sd.azimuth,${signals_railway_signals.tags.map(tag => `
        ${tag.type === 'array' ? `array_to_string("${tag.tag}", U&'\\001E') as "${tag.tag}"` : `"${tag.tag}"`},`).join('')}
        features[1] as feature0,
        features[2] as feature1,
        features[3] as feature2,
        features[4] as feature3,
        features[5] as feature4,
        features[6] as feature5,
        deactivated[1] as deactivated0,
        deactivated[2] as deactivated1,
        deactivated[3] as deactivated2,
        deactivated[4] as deactivated3,
        deactivated[5] as deactivated4,
        deactivated[6] as deactivated5,
        CEIL(icon_height[1] / 2 + icon_height[2] / 2) as offset1,
        CEIL(icon_height[1] / 2 + icon_height[2] + icon_height[3] / 2) as offset2,
        CEIL(icon_height[1] / 2 + icon_height[2] + icon_height[3] + icon_height[4] / 2) as offset3,
        CEIL(icon_height[1] / 2 + icon_height[2] + icon_height[3] + icon_height[4] + icon_height[5] / 2) as offset4,
        CEIL(icon_height[1] / 2 + icon_height[2] + icon_height[3] + icon_height[4] + icon_height[5] + icon_height[6] / 2) as offset5,
        type
      FROM signals s
      JOIN signal_features sf
        ON s.id = sf.signal_id
      JOIN signal_direction sd
        ON s.id = sd.signal_id
      WHERE way && ST_TileEnvelope(z, x, y)
        AND layer = 'signals'
      ORDER BY rank NULLS FIRST
    ) as tile
    WHERE way IS NOT NULL
  );

DO $do$ BEGIN
  EXECUTE 'COMMENT ON FUNCTION signals_railway_signals IS $tj$' || $$
  {
    "vector_layers": [
      {
        "id": "signals_railway_signals",
        "fields": {
          "id": "integer",
          "osm_id": "integer",
          "railway": "string",
          "ref": "string",
          "caption": "string",
          "azimuth": "number",
          "direction_both": "boolean",
          "position": "string",
          "wikidata": "string",
          "wikimedia_commons": "string",
          "wikimedia_commons_file": "string",
          "image": "string",
          "mapillary": "string",
          "wikipedia": "string",
          "note": "string",
          "description": "string",${signals_railway_signals.tags.map(tag => `
          "${tag.tag}": "${tag.type === 'boolean' ? `boolean` : `string`}",`).join('')}
          "feature0": "string",
          "feature1": "string",
          "feature2": "string",
          "feature3": "string",
          "feature4": "string",
          "feature5": "string",
          "deactivated0": "boolean",
          "deactivated1": "boolean",
          "deactivated2": "boolean",
          "deactivated3": "boolean",
          "deactivated4": "boolean",
          "deactivated5": "boolean",
          "offset1": "number",
          "offset2": "number",
          "offset3": "number",
          "offset4": "number",
          "offset5": "number",
          "type": "string"
        }
      }
    ]
  }
  $$::json || '$tj$';
END $do$;

--- Electrification ---

CREATE OR REPLACE FUNCTION electrification_signals(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
  RETURN (
    SELECT
      ST_AsMVT(tile, 'electrification_signals', 4096, 'way', 'id')
    FROM (
      SELECT
        id,
        osm_id,
        ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), extent => 4096, buffer => 64, clip_geom => true) AS way,
        sd.direction_both,
        ref,
        caption,
        nullif(array_to_string(position, U&'\\001E'), '') as position,
        wikidata,
        wikimedia_commons,
        wikimedia_commons_file,
        image,
        mapillary,
        wikipedia,
        note,
        description,
        sd.azimuth,${signals_railway_signals.tags.map(tag => `
        ${tag.type === 'array' ? `array_to_string("${tag.tag}", U&'\\001E') as "${tag.tag}"` : `"${tag.tag}"`},`).join('')}
        features[1] as feature,
        deactivated[1] as deactivated,
        type as type
      FROM signals s
      JOIN signal_features sf
        ON s.id = sf.signal_id
      JOIN signal_direction sd
        ON s.id = sd.signal_id
      WHERE way && ST_TileEnvelope(z, x, y)
        AND layer = 'electrification'
      ORDER BY rank NULLS FIRST
    ) as tile
    WHERE way IS NOT NULL
  );

DO $do$ BEGIN
  EXECUTE 'COMMENT ON FUNCTION electrification_signals IS $tj$' || $$
  {
    "vector_layers": [
      {
        "id": "electrification_signals",
        "fields": {
          "id": "integer",
          "osm_id": "integer",
          "azimuth": "number",
          "direction_both": "boolean",
          "ref": "string",
          "caption": "string",
          "frequency": "number",
          "voltage": "integer",
          "position": "string",
          "wikidata": "string",
          "wikimedia_commons": "string",
          "wikimedia_commons_file": "string",
          "image": "string",
          "mapillary": "string",
          "wikipedia": "string",
          "note": "string",
          "description": "string",${signals_railway_signals.tags.map(tag => `
          "${tag.tag}": "${tag.type === 'boolean' ? `boolean` : `string`}",`).join('')}
          "feature": "string",
          "deactivated": "boolean"
        }
      }
    ]
  }
  $$::json || '$tj$';
END $do$;
`

console.log(sql);
