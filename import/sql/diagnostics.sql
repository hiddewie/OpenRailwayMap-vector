CREATE OR REPLACE VIEW diagnostics_collected_view AS
  SELECT
    row_number() over () as id,
    way,
    feature,
    signal_id,
    'unknown_signal' AS diagnostic,
    null::text[] AS parameters
  FROM (
    SELECT
      signal_id,
      unnest(features) AS feature,
      way
    FROM signal_features sf
    JOIN signals s
      ON s.osm_id = sf.signal_id
   ) split_features
  WHERE feature LIKE 'general/signal-unknown%';

CREATE MATERIALIZED VIEW IF NOT EXISTS diagnostics_collected AS
  SELECT
    *
  FROM diagnostics_collected_view;
