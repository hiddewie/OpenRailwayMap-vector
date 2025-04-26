import fs from 'fs'
import yaml from 'yaml'

const signals_railway_signals = yaml.parse(fs.readFileSync('signals_railway_signals.yaml', 'utf8'))

const speedFeatureTypes = signals_railway_signals.types.filter(type => type.layer === 'speed').map(type => type.type);
const electrificationFeatureTypes = signals_railway_signals.types.filter(type => type.layer === 'electrification').map(type => type.type);
const signalFeatureTypes = signals_railway_signals.types.filter(type => type.layer === 'signals').map(type => type.type);

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
  ${signals_railway_signals.types.map(type => `
  SELECT
    *
  FROM (
    SELECT
      id as signal_id,
      '${type.type}'::signal_type as type,
      '${type.layer}'::signal_layer as layer,
  
      CASE ${signals_railway_signals.features.filter(feature => feature.tags.find(it => it.tag === `railway:signal:${type.type}`)).map(feature => `
        -- ${feature.country ? `(${feature.country}) ` : ''}${feature.description}
        WHEN ${feature.tags.map(tag => `"${tag.tag}" ${tag.value ? `= '${tag.value}'`: tag.values ? `IN (${tag.values.map(value => `'${value}'`).join(', ')})` : ''}`).join(' AND ')}
          THEN ${feature.icon.match ? `CASE ${feature.icon.cases.map(iconCase => `
            WHEN "${feature.icon.match}" ~ '${iconCase.regex}' THEN ${iconCase.value.includes('{}') ? `CONCAT('${iconCase.value.replace(/\{}.*$/, '{')}', "${feature.icon.match}", '${iconCase.value.replace(/^.*\{}/, '}')}')` : `'${iconCase.value}'`}`).join('')}
            ${feature.icon.default ? `ELSE '${feature.icon.default}'` : ''}
          END` : `'${feature.icon.default}'`}
      `).join('')}
        -- Unknown signal (${type.type})
        WHEN "railway:signal:${type.type}" IS NOT NULL THEN
          'general/signal-unknown-${type.type}'
      END as feature
      
    FROM signals s
    WHERE
      railway IN ('signal', 'buffer_stop', 'derail', 'vacancy_detection')
  ) sf
  WHERE feature IS NOT NULL
`).join(`
  UNION ALL
`)};

-- Use the view directly such that the query in the view can be updated
CREATE MATERIALIZED VIEW IF NOT EXISTS signal_features AS
  SELECT
    *
  FROM
    signal_features_view;

CREATE INDEX IF NOT EXISTS signal_features_signal_id_index
  ON signal_features
  USING btree(signal_id, layer);

CLUSTER signal_features 
  USING signal_features_signal_id_index;

CREATE OR REPLACE VIEW speed_signal_features AS
  SELECT *
  FROM signal_features
  WHERE layer = 'speed';

CREATE OR REPLACE VIEW electrification_signal_features AS
  SELECT *
  FROM signal_features
  WHERE layer = 'electrification';

CREATE OR REPLACE VIEW signal_signal_features AS
  SELECT *
  FROM signal_features
  WHERE layer = 'signals';

-- Table with signals including their azimuth based on the direction of the signal and the railway line
CREATE OR REPLACE VIEW signals_with_azimuth_view AS
  SELECT
    id as signal_id,
    CASE WHEN "railway:signal:electricity:voltage" ~ '^[0-9]+$' then "railway:signal:electricity:voltage"::int ELSE NULL END as voltage,
    CASE WHEN "railway:signal:electricity:frequency" ~ '^[0-9]+(\\.[0-9]+)?$' then "railway:signal:electricity:frequency"::real ELSE NULL END as frequency,
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
CREATE MATERIALIZED VIEW IF NOT EXISTS signals_with_azimuth AS
  SELECT
    *
  FROM
    signals_with_azimuth_view;

CREATE INDEX IF NOT EXISTS signals_with_azimuth_signal_id_index
  ON signals_with_azimuth
  USING btree(signal_id);
  
CLUSTER signals_with_azimuth 
  USING signals_with_azimuth_signal_id_index;
`

console.log(sql);
