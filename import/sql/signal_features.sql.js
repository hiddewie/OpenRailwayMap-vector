import fs from 'fs'
import yaml from 'yaml'

const signals_railway_signals = yaml.parse(fs.readFileSync('signals_railway_signals.yaml', 'utf8'))

const layers = [...new Set(signals_railway_signals.types.map(type => type.layer))]

// Determine a signal type per layer such that combined matching does not try to match other signal types for the same feature
const signalsWithSignalType = signals_railway_signals.features.map(feature => ({
  ...feature,
  signalTypes: Object.fromEntries(
    layers.map(layer =>
      [layer, signals_railway_signals.types.filter(type => type.layer === layer).find(type => feature.tags.find(it => it.tag === `railway:signal:${type.type}`))?.type]
    )
  ),
}));

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

/**
 * Template that builds the SQL view taking the YAML configuration into account
 */
const sql = `
-- Table with functional signal features
CREATE OR REPLACE VIEW signal_features_view AS
  -- For every type of signal, generate the feature and related metadata
  WITH signals_with_features_0 AS (
    SELECT
      id as signal_id,
      ${signals_railway_signals.types.map(type => `
      CASE 
        WHEN "railway:signal:${type.type}" IS NOT NULL THEN
          CASE ${signalsWithSignalType.map((feature, index) => ({...feature, rank: index })).filter(feature => feature.tags.find(it => it.tag === `railway:signal:${type.type}`)).map(feature => `
            -- ${feature.country ? `(${feature.country}) ` : ''}${feature.description}
            WHEN ${feature.tags.map(tag => tag.value ? matchTagValueSql(tag.tag, tag.value) : tag.all ? matchTagAllValuesSql(tag.tag, tag.all) : matchTagAnyValueSql(tag.tag, tag.any)).join(' AND ')}
              THEN ${feature.signalTypes[type.layer] === type.type ? (feature.icon.match ? `CASE ${feature.icon.cases.map(iconCase => `
                WHEN ${matchIconCase(feature.icon.match, iconCase)} THEN ${iconCase.value.includes('{}') ? `ARRAY[CONCAT('${iconCase.value.replace(/\{}.*$/, '{')}', ${stringSql(feature.icon.match, iconCase)}, '${iconCase.value.replace(/^.*\{}/, '}')}'), ${stringSql(feature.icon.match, iconCase)}, ${feature.type ? `'${feature.type}'` : 'NULL'}, '${type.layer}', '${feature.rank}']` : `ARRAY['${iconCase.value}', NULL, ${feature.type ? `'${feature.type}'` : 'NULL'}, '${type.layer}', '${feature.rank}']`}`).join('')}
                ${feature.icon.default ? `ELSE ARRAY['${feature.icon.default}', NULL, ${feature.type ? `'${feature.type}'` : 'NULL'}, '${type.layer}', '${feature.rank}']` : ''}
              END` : `ARRAY['${feature.icon.default}', NULL, ${feature.type ? `'${feature.type}'` : 'NULL'}, '${type.layer}', '${feature.rank}']`) : 'NULL'}
            `).join('')}
            -- Unknown signal (${type.type})
            ELSE
              ARRAY['general/signal-unknown-${type.type}', NULL, NULL, '${type.layer}', NULL]
        END
      END as feature_${type.type}`).join(',')}
    FROM signals s
  ),
  -- Output a feature row for every feature
  signals_with_features_1 AS (
    ${signals_railway_signals.types.map(type => `
    SELECT
      signal_id,
      feature_${type.type}[1] as feature,
      feature_${type.type}[2] as feature_variable,
      feature_${type.type}[3] as type,
      feature_${type.type}[4]::signal_layer as layer,
      feature_${type.type}[5]::INT as rank
    FROM signals_with_features_0
    WHERE feature_${type.type} IS NOT NULL
  `).join(`
    UNION ALL
  `)}
  ),
  -- Group features by signal, and aggregate the results
  signals_with_features AS (
    SELECT
      signal_id,
      any_value(type) as type,
      layer,
      array_agg(feature ORDER BY rank ASC NULLS LAST) as features,
      MAX(rank) as rank
    FROM signals_with_features_1 sf
    GROUP BY signal_id, layer
  )
  -- Calculate signal-specific details like fields, azimuth and features
  SELECT
    s.*,
    sf.type,
    sf.layer,
    sf.features,
    sf.rank,
    (signal_direction = 'both') as direction_both,
    degrees(ST_Azimuth(
      st_lineinterpolatepoint(sl.way, greatest(0, st_linelocatepoint(sl.way, ST_ClosestPoint(sl.way, s.way)) - 0.01)),
      st_lineinterpolatepoint(sl.way, least(1, st_linelocatepoint(sl.way, ST_ClosestPoint(sl.way, s.way)) + 0.01))
    )) + (CASE WHEN signal_direction = 'backward' THEN 180.0 ELSE 0.0 END) as azimuth
  FROM signals_with_features sf
  JOIN signals s
    ON s.id = sf.signal_id
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
CREATE MATERIALIZED VIEW IF NOT EXISTS signal_features AS
  SELECT
    *
  FROM
    signal_features_view;

CREATE INDEX IF NOT EXISTS signal_features_way_index
  ON signal_features
  USING gist(way);

CLUSTER signal_features 
  USING signal_features_way_index;
  
--- Speed ---

CREATE OR REPLACE FUNCTION speed_railway_signals(z integer, x integer, y integer)
  RETURNS bytea
  LANGUAGE SQL
  IMMUTABLE
  STRICT
  PARALLEL SAFE
  RETURN (
    SELECT
      ST_AsMVT(tile, 'speed_railway_signals', 4096, 'way')
    FROM (
      SELECT
        id,
        osm_id,
        ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), extent => 4096) AS way,
        direction_both,
        ref,
        caption,
        deactivated,
        nullif(array_to_string(position, U&'\\001E'), '') as position,
        wikidata,
        wikimedia_commons,
        wikimedia_commons_file,
        image,
        mapillary,
        wikipedia,
        note,
        description,
        azimuth,${signals_railway_signals.tags.map(tag => `
        ${tag.type === 'array' ? `array_to_string("${tag.tag}", U&'\\001E') as "${tag.tag}"` : `"${tag.tag}"`},`).join('')}
        features[1] as feature0,
        features[2] as feature1,
        type
      FROM signal_features
      WHERE way && ST_TileEnvelope(z, x, y)
        AND layer = 'speed'
      ORDER BY rank NULLS FIRST
    ) as tile
    WHERE way IS NOT NULL
  );
  
-- Function metadata
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
          "deactivated": "boolean",
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
      ST_AsMVT(tile, 'signals_railway_signals', 4096, 'way')
    FROM (
      SELECT
        id,
        osm_id,
        ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), extent => 4096) AS way,
        direction_both,
        ref,
        caption,
        deactivated,
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
        azimuth,${signals_railway_signals.tags.map(tag => `
        ${tag.type === 'array' ? `array_to_string("${tag.tag}", U&'\\001E') as "${tag.tag}"` : `"${tag.tag}"`},`).join('')}
        features[1] as feature0,
        features[2] as feature1,
        features[3] as feature2,
        features[4] as feature3,
        features[5] as feature4,
        type
      FROM signal_features
      WHERE way && ST_TileEnvelope(z, x, y)
        AND layer = 'signals'
      ORDER BY rank NULLS FIRST
    ) as tile
    WHERE way IS NOT NULL
  );

-- Function metadata
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
          "deactivated": "boolean",
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
      ST_AsMVT(tile, 'electrification_signals', 4096, 'way')
    FROM (
      SELECT
        id,
        osm_id,
        ST_AsMVTGeom(way, ST_TileEnvelope(z, x, y), extent => 4096) AS way,
        direction_both,
        ref,
        caption,
        deactivated,
        nullif(array_to_string(position, U&'\\001E'), '') as position,
        wikidata,
        wikimedia_commons,
        wikimedia_commons_file,
        image,
        mapillary,
        wikipedia,
        note,
        description,
        azimuth,${signals_railway_signals.tags.map(tag => `
        ${tag.type === 'array' ? `array_to_string("${tag.tag}", U&'\\001E') as "${tag.tag}"` : `"${tag.tag}"`},`).join('')}
        features[1] as feature,
        type as type
      FROM signal_features
      WHERE way && ST_TileEnvelope(z, x, y)
        AND layer = 'electrification'
      ORDER BY rank NULLS FIRST
    ) as tile
    WHERE way IS NOT NULL
  );

-- Function metadata
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
          "deactivated": "boolean",
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
          "feature": "string"
        }
      }
    ]
  }
  $$::json || '$tj$';
END $do$;
`

console.log(sql);
