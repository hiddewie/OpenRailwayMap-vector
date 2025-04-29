import fs from 'fs'
import yaml from 'yaml'

const signals_railway_signals = yaml.parse(fs.readFileSync('signals_railway_signals.yaml', 'utf8'))

const layerByType = Object.fromEntries(
  signals_railway_signals.types.map(type => [type.type, type.layer])
);

/**
 * Template that builds the SQL view taking the YAML configuration into account
 */
const sql = `
DO $$ BEGIN
  CREATE TYPE signal_layer AS ENUM (
    'speed',
    'electrification',
    'signals'
  );
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE signal_type AS ENUM (${signals_railway_signals.types.map(type => `
    '${type.type}'`).join(',')}
  );
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Table with functional signal features
CREATE OR REPLACE VIEW signal_features_view AS
  -- For every type of signal, generate the feature and related metadata
  WITH signals_with_features_0 AS (
    SELECT
      id as signal_id,
      ${signals_railway_signals.types.map(type => `
      CASE ${signals_railway_signals.features.map((feature, index) => ({...feature, rank: index })).filter(feature => feature.tags.find(it => it.tag === `railway:signal:${type.type}`)).map(feature => `
        -- ${feature.country ? `(${feature.country}) ` : ''}${feature.description}
        WHEN ${feature.tags.map(tag => `"${tag.tag}" ${tag.value ? `= '${tag.value}'`: tag.values ? `IN (${tag.values.map(value => `'${value}'`).join(', ')})` : ''}`).join(' AND ')}
          THEN ${feature.icon.match ? `CASE ${feature.icon.cases.map(iconCase => `
            WHEN "${feature.icon.match}" ~ '${iconCase.regex}' THEN ${iconCase.value.includes('{}') ? `ARRAY[CONCAT('${iconCase.value.replace(/\{}.*$/, '{')}', "${feature.icon.match}", '${iconCase.value.replace(/^.*\{}/, '}')}'), "${feature.icon.match}", ${feature.type ? `'${feature.type}'` : 'NULL'}, '${type.layer}', '${feature.rank}']` : `ARRAY['${iconCase.value}', NULL, ${feature.type ? `'${feature.type}'` : 'NULL'}, '${type.layer}', '${feature.rank}']`}`).join('')}
            ${feature.icon.default ? `ELSE ARRAY['${feature.icon.default}', NULL, ${feature.type ? `'${feature.type}'` : 'NULL'}, '${type.layer}', '${feature.rank}']` : ''}
          END` : `ARRAY['${feature.icon.default}', NULL, ${feature.type ? `'${feature.type}'` : 'NULL'}, '${type.layer}', '${feature.rank}']`}
      `).join('')}
        -- Unknown signal (${type.type})
        WHEN "railway:signal:${type.type}" IS NOT NULL THEN
          ARRAY['general/signal-unknown-${type.type}', NULL, NULL, '${type.layer}', NULL]
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
`

console.log(sql);
