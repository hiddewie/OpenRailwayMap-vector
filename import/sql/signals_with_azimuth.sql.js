import fs from 'fs'
import yaml from 'yaml'

const speed_railway_signals = yaml.parse(fs.readFileSync('speed_railway_signals.yaml', 'utf8')).speed_railway_signals
const signals_railway_signals = yaml.parse(fs.readFileSync('signals_railway_signals.yaml', 'utf8')).signals_railway_signals
const electrification_signals = yaml.parse(fs.readFileSync('electrification_signals.yaml', 'utf8')).electrification_signals

/**
 * Template that builds the SQL view taking the YAML configuration into account
 */
const sql = `
-- Table with signals including their azimuth based on the direction of the signal and the railway line
-- and the functional signal feature
CREATE OR REPLACE VIEW signals_with_azimuth_view AS
  SELECT
    id,
    s.way as way,
    railway,
    ref,
    ref_multiline,
    deactivated,
    signal_direction,
    "railway:signal:speed_limit",
    dominant_speed,
    degrees(ST_Azimuth(
      st_lineinterpolatepoint(sl.way, greatest(0, st_linelocatepoint(sl.way, ST_ClosestPoint(sl.way, s.way)) - 0.01)),
      st_lineinterpolatepoint(sl.way, least(1, st_linelocatepoint(sl.way, ST_ClosestPoint(sl.way, s.way)) + 0.01))
    )) + (CASE WHEN signal_direction = 'backward' THEN 180.0 ELSE 0.0 END) as azimuth,
    CASE ${signals_railway_signals.features.map(feature => `
      -- ${feature.country ? `(${feature.country}) ` : ''}${feature.description}
      WHEN ${feature.tags.map(tag => `"${tag.tag}"${tag.value ? ` = '${tag.value}'`: tag.values ? `IN (${tag.values.map(value => `'${value}'`).join(', ')})` : ''}`).join(' AND ')}
        THEN ${feature.icon.match ? `CASE ${feature.icon.cases.map(iconCase => `
          WHEN "${feature.icon.match}" ~ '${iconCase.regex}' THEN '${iconCase.value}'`).join('')}
          ${feature.icon.default ? `ELSE '${feature.icon.default}'` : ''}
        END` : `'${feature.icon.default}'`}
    `).join('')}
    END as signal_feature,
    
    CASE ${speed_railway_signals.features.map(feature => `
      -- ${feature.country ? `(${feature.country}) ` : ''}${feature.description}
      WHEN ${feature.tags.map(tag => `"${tag.tag}"${tag.value ? ` = '${tag.value}'`: tag.values ? `IN (${tag.values.map(value => `'${value}'`).join(', ')})` : ''}`).join(' AND ')}
        THEN ${feature.icon.match ? `CASE ${feature.icon.cases.map(iconCase => `
          WHEN "${feature.icon.match}" ~ '${iconCase.regex}' THEN ${iconCase.value.includes('{}') ? `CONCAT('${iconCase.value.replace(/\{}.*$/, '')}', "${feature.icon.match}", '${iconCase.value.replace(/^.*\{}/, '')}')` : `'${iconCase.value}'`}`).join('')}
          ${feature.icon.default ? `ELSE '${feature.icon.default}'` : ''}
        END` : `'${feature.icon.default}'`}
    `).join('')}
    END as speed_feature,
    
    CASE ${speed_railway_signals.features.map(feature => feature.type ? `
      -- ${feature.country ? `(${feature.country}) ` : ''}${feature.description}
      WHEN ${feature.tags.map(tag => `"${tag.tag}"${tag.value ? ` = '${tag.value}'`: tag.values ? `IN (${tag.values.map(value => `'${value}'`).join(', ')})` : ''}`).join(' AND ')} THEN '${feature.type}'
    ` : '').join('')}
    END as speed_feature_type,
    
    CASE ${electrification_signals.features.map(feature => `
      -- ${feature.country ? `(${feature.country}) ` : ''}${feature.description}
      WHEN ${feature.tags.map(tag => `"${tag.tag}"${tag.value ? ` = '${tag.value}'`: tag.values ? `IN (${tag.values.map(value => `'${value}'`).join(', ')})` : ''}`).join(' AND ')}
        THEN ${feature.icon.match ? `CASE ${feature.icon.cases.map(iconCase => `
          WHEN "${feature.icon.match}" ~ '${iconCase.regex}' THEN '${iconCase.value}'`).join('')}
          ${feature.icon.default ? `ELSE '${feature.icon.default}'` : ''}
        END` : `'${feature.icon.default}'`}
    `).join('')}
    END as electrification_feature
    
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
    signals_with_azimuth_view;

CREATE INDEX IF NOT EXISTS signals_with_azimuth_geom_index
  ON signals_with_azimuth
  USING GIST(way);
`

console.log(sql);
