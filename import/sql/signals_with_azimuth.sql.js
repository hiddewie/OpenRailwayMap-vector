import fs from 'fs'
import yaml from 'yaml'

const signals_railway_signals = yaml.parse(fs.readFileSync('signals_railway_signals.yaml', 'utf8'))

/**
 * Template that builds the SQL view taking the YAML configuration into account
 */
const sql = `
-- Table with signals including their azimuth based on the direction of the signal and the railway line
-- and the functional signal feature
CREATE OR REPLACE VIEW signals_with_azimuth_view AS
  SELECT
    id,
    osm_id,
    s.way as way,
    railway,
    ref,
    ref_multiline,
    deactivated,
    signal_direction,
    dominant_speed,
    CASE WHEN "railway:signal:electricity:voltage" ~ '^[0-9]+$' then "railway:signal:electricity:voltage"::int ELSE NULL END as voltage,
    CASE WHEN "railway:signal:electricity:frequency" ~ '^[0-9]+(\\.[0-9]+)?$' then "railway:signal:electricity:frequency"::real ELSE NULL END as frequency,
    rank,
    degrees(ST_Azimuth(
      st_lineinterpolatepoint(sl.way, greatest(0, st_linelocatepoint(sl.way, ST_ClosestPoint(sl.way, s.way)) - 0.01)),
      st_lineinterpolatepoint(sl.way, least(1, st_linelocatepoint(sl.way, ST_ClosestPoint(sl.way, s.way)) + 0.01))
    )) + (CASE WHEN signal_direction = 'backward' THEN 180.0 ELSE 0.0 END) as azimuth,
      
    ${signals_railway_signals.types.map(type => `
    CASE ${signals_railway_signals.features.filter(feature => feature.tags.find(it => it.tag === `railway:signal:${type}`)).map(feature => `
      -- ${feature.country ? `(${feature.country}) ` : ''}${feature.description}
      WHEN ${feature.tags.map(tag => `"${tag.tag}" ${tag.value ? `= '${tag.value}'`: tag.values ? `IN (${tag.values.map(value => `'${value}'`).join(', ')})` : ''}`).join(' AND ')}
        THEN ${feature.icon.match ? `CASE ${feature.icon.cases.map(iconCase => `
          WHEN "${feature.icon.match}" ~ '${iconCase.regex}' THEN ${iconCase.value.includes('{}') ? `CONCAT('${iconCase.value.replace(/\{}.*$/, '')}', "${feature.icon.match}", '${iconCase.value.replace(/^.*\{}/, '')}')` : `'${iconCase.value}'`}`).join('')}
          ${feature.icon.default ? `ELSE '${feature.icon.default}'` : ''}
        END` : `'${feature.icon.default}'`}
    `).join('')}
    END as feature_${type},
    `).join('')}
      
    -- TODO support type per feature
    CASE ${signals_railway_signals.features.map(feature => feature.type ? `
      -- ${feature.country ? `(${feature.country}) ` : ''}${feature.description}
      WHEN ${feature.tags.map(tag => `"${tag.tag}" ${tag.value ? `= '${tag.value}'`: tag.values ? `IN (${tag.values.map(value => `'${value}'`).join(', ')})` : ''}`).join(' AND ')} THEN '${feature.type}'
    ` : '').join('')}
    END as type
    
  FROM signals s
  LEFT JOIN LATERAL (
    SELECT line.way as way
    FROM railway_line line
    WHERE st_dwithin(s.way, line.way, 10) AND line.railway IN ('rail', 'tram', 'light_rail', 'subway', 'narrow_gauge', 'construction', 'preserved', 'monorail', 'miniature') -- TODO use feature
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
    signals_with_azimuth_view
  WHERE
    ${signals_railway_signals.types.map(type => `feature_${type} IS NOT NULL`).join(' OR ')};

CREATE INDEX IF NOT EXISTS signals_with_azimuth_geom_index
  ON signals_with_azimuth
  USING GIST(way);

CREATE OR REPLACE VIEW signals_railway_signal_features AS
  SELECT *
  FROM (
    SELECT
      signals_with_azimuth.*,
      -- Build up array of available features
      -- The order of the array is hardcoded, defining the importance of features (earlier is more important)
      -- Does not include: speed_limit, speed_limit_distant, electricity
      array_remove(
        ARRAY[${signals_railway_signals.types.filter(type => !['speed_limit', 'speed_limit_distant', 'electricity'].includes(type)).map(type => `feature_${type}`).join(', ')}],
        NULL
      ) AS features
    FROM signals_with_azimuth
  ) AS s
  WHERE array_length(features, 1) > 0;

CREATE OR REPLACE VIEW speed_railway_signal_features AS
  SELECT *
  FROM (
    SELECT
      signals_with_azimuth.*,
      -- Build up array of available features
      -- The order of the array is hardcoded, defining the importance of features (earlier is more important)
      -- Does not include: speed_limit, speed_limit_distant, electricity
      array_remove(
        ARRAY[${signals_railway_signals.types.filter(type => ['speed_limit', 'speed_limit_distant'].includes(type)).map(type => `feature_${type}`).join(', ')}],
        NULL
        ) AS features
      FROM signals_with_azimuth
  ) AS s
  WHERE array_length(features, 1) > 0;

CREATE OR REPLACE VIEW electricity_railway_signal_features AS
  SELECT *
  FROM (
    SELECT
      signals_with_azimuth.*,
      -- Build up array of available features
      -- The order of the array is hardcoded, defining the importance of features (earlier is more important)
      -- Does not include: speed_limit, speed_limit_distant, electricity
      array_remove(
        ARRAY[${signals_railway_signals.types.filter(type => ['electricity'].includes(type)).map(type => `feature_${type}`).join(', ')}],
        NULL
        ) AS features
      FROM signals_with_azimuth
  ) AS s
  WHERE array_length(features, 1) > 0;
`

console.log(sql);
