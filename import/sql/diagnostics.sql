CREATE OR REPLACE VIEW diagnostics_view AS
  SELECT
    feature,
    signal_id,
    'unknown_signal' AS diagnostic,
    null::text[] AS parameters
  FROM (
    SELECT
      signal_id,
      unnest(features) AS feature
    FROM signal_features
   ) split_features
  WHERE feature LIKE 'general/signal-unknown%';

CREATE MATERIALIZED VIEW IF NOT EXISTS diagnostics AS
  SELECT
    *
  FROM diagnostics_view;
