import fs from 'fs'
import yaml from 'yaml'

const signals_railway_signals = yaml.parse(fs.readFileSync('signals_railway_signals.yaml', 'utf8'))

const speedFeatureTypes = signals_railway_signals.types.filter(type => type.layer === 'speed').map(type => type.type);
const electrificationFeatureTypes = signals_railway_signals.types.filter(type => type.layer === 'electrification').map(type => type.type);
const otherFeatureTypes = signals_railway_signals.types.filter(type => !(type.layer === 'speed' || type.layer === 'electrification')).map(type => type.type);

/**
 * Template that builds the SQL view taking the YAML configuration into account
 */
const sql = `
-- Table with functional signal features
CREATE OR REPLACE VIEW signal_features_view AS
  SELECT
    *
  FROM (
    ${signals_railway_signals.types.map(type => `
    SELECT
      id as signal_id,
      '${type.type}' as type,
  
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
`).join(`
UNION ALL
`)}
  ) q
  WHERE feature IS NOT NULL;

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

-- Table with signals including their azimuth based on the direction of the signal and the railway line
CREATE OR REPLACE VIEW signals_with_azimuth_view AS
  SELECT
    id as signal_id,
    CASE WHEN "railway:signal:electricity:voltage" ~ '^[0-9]+$' then "railway:signal:electricity:voltage"::int ELSE NULL END as voltage,
    CASE WHEN "railway:signal:electricity:frequency" ~ '^[0-9]+(\\.[0-9]+)?$' then "railway:signal:electricity:frequency"::real ELSE NULL END as frequency,
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

CREATE OR REPLACE VIEW signals_railway_signal_features AS
  SELECT
    s.id,
    s.osm_id,
    s.way,
    s.signal_direction,
    s.ref,
    s.ref_multiline,
    s.caption,
    s.deactivated,
    s.rank,
    s.railway,
    s.wikidata,
    s.wikimedia_commons,
    s.image,
    s.mapillary,
    s.wikipedia,
    s.note,
    s.description,
    ANY_VALUE(sa.azimuth) as azimuth,
    array_agg(sf.feature) as features,
    ANY_VALUE(sf.type) as type
  FROM signals s
  JOIN signals_with_azimuth sa
    ON s.id = sa.signal_id
  JOIN signal_features sf
    ON s.id = sf.signal_id 
      AND sf.type IN (${otherFeatureTypes.map(type => `'${type}'`).join(', ')})
  GROUP BY 
    s.id,
    s.osm_id,
    s.way,
    s.signal_direction,
    s.ref,
    s.ref_multiline,
    s.rank,
    s.railway,
    s.caption,
    s.deactivated,
    s.wikidata,
    s.wikimedia_commons,
    s.image,
    s.mapillary,
    s.wikipedia,
    s.note,
    s.description
;

CREATE OR REPLACE VIEW speed_railway_signal_features AS
  SELECT
    s.id,
    s.osm_id,
    s.way,
    s.signal_direction,
    s.ref,
    s.rank,
    s.dominant_speed,
    s.caption,
    s.deactivated,
    s.speed_limit_speed,
    s.speed_limit_distant_speed,
    s.wikidata,
    s.wikimedia_commons,
    s.image,
    s.mapillary,
    s.wikipedia,
    s.note,
    s.description,
    ANY_VALUE(sa.azimuth) as azimuth,
    array_agg(sf.feature) as features,
    ANY_VALUE(sf.type) as type
  FROM signals s
  JOIN signals_with_azimuth sa
    ON s.id = sa.signal_id
  JOIN signal_features sf
    ON s.id = sf.signal_id 
      AND sf.type IN (${speedFeatureTypes.map(type => `'${type}'`).join(', ')})
  GROUP BY 
    s.id,
    s.osm_id,
    s.way,
    s.signal_direction,
    s.ref,
    s.rank,
    s.dominant_speed,
    s.caption,
    s.deactivated,
    s.speed_limit_speed,
    s.speed_limit_distant_speed,
    s.wikidata,
    s.wikimedia_commons,
    s.image,
    s.mapillary,
    s.wikipedia,
    s.note,
    s.description
;

CREATE OR REPLACE VIEW electricity_railway_signal_features AS
  SELECT
    s.id,
    s.osm_id,
    s.way,
    s.signal_direction,
    s.ref,
    s.rank,
    s.caption,
    s.deactivated,
    ANY_VALUE(sa.voltage) as voltage,
    ANY_VALUE(sa.frequency) as frequency,
    s.wikidata,
    s.wikimedia_commons,
    s.image,
    s.mapillary,
    s.wikipedia,
    s.note,
    s.description,
    ANY_VALUE(sa.azimuth) as azimuth,
    array_agg(sf.feature) as features,
    ANY_VALUE(sf.type) as type
  FROM signals s
  JOIN signals_with_azimuth sa
    ON s.id = sa.signal_id
  JOIN signal_features sf
    ON s.id = sf.signal_id 
      AND sf.type IN (${electrificationFeatureTypes.map(type => `'${type}'`).join(', ')})
  GROUP BY 
    s.id,
    s.osm_id,
    s.way,
    s.signal_direction,
    s.ref,
    s.rank,
    s.caption,
    s.deactivated,
    sa.voltage,
    sa.frequency,
    s.wikidata,
    s.wikimedia_commons,
    s.image,
    s.mapillary,
    s.wikipedia,
    s.note,
    s.description
;
`

console.log(sql);
