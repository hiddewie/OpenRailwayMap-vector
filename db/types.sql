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

CREATE TYPE route_platform_type AS ENUM (
  'platform',
  'platform_exit_only',
  'platform_entry_only',
  'forward:platform',
  'backward:platform'
);
