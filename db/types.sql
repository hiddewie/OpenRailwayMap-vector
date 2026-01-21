CREATE TYPE signal_layer AS ENUM (
  'speed',
  'electrification',
  'signals'
);

CREATE TYPE route_type AS ENUM (
  'train',
  'subway',
  'tram',
  'light_rail',
  'funicular',
  'monorail',
  'miniature'
);

CREATE TYPE route_stop_type AS ENUM (
  'stop_exit_only',
  'stop_entry_only'
);
