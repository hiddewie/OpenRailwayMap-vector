local tag_functions = require('tags')

function dump(o)
  if type(o) == 'table' then
    local s = '{ '
    local first = true
    for k, v in pairs(o) do
      if first then
        first = false
      else
        s = s .. ', '
      end
      if type(k) ~= 'number' then
        k = '"'..k..'"'
      end
      s = s .. '['..k..'] = ' .. dump(v)
    end
    return s .. ' }'
  else
    return tostring(o)
  end
end

function map(tbl, f)
  if not tbl then
    return nil
  end

  local t = {}
  for k, v in pairs(tbl) do
    t[k] = f(v)
  end

  return t
end

function strip_prefix(value, prefix)
  if osm2pgsql.has_prefix(value, prefix) then
    return value:sub(prefix:len() + 1)
  else
    return value
  end
end

-- Convert a speed number from text to integer but not convert units
function speed_int_noconvert(value)
  if not value then
    return nil
  end

  local _, _, match = value:find('^(%d+%.?%d*)$')
  if match then
    return tonumber(match)
  end

  local _, _, match = value:find('^(%d+%.?%d*) ?mph$')
  if match then
    return tonumber(match)
  end

  return nil
end

-- Convert a speed number from text to integer with unit conversion
function speed_int(value)
  if not value then
    return nil
  end

  local _, _, match = value:find('^(%d+%.?%d*)$')
  if match then
    return tonumber(match)
  end

  local _, _, match = value:find('^(%d+%.?%d*) ?mph$')
  if match then
    return tonumber(match) * 1.609344
  end

  return nil
end

-- Get the largest speed from a list of speed values (common at light speed signals)
function largest_speed_noconvert(value)
  if not value then
    return nil
  end

  local largest_speed = nil
  for elem in string.gmatch(value, '[^;]+') do
    if elem then
      local speed = speed_int_noconvert(elem)
      if speed ~= nil and (largest_speed == nil or largest_speed < speed) then
        largest_speed = speed
      end
    end
  end

  return largest_speed
end

-- Speed label and dominant speed, taking the preferred direction and forward, backward an non-directional speed into account
function dominant_speed_label(state, preferred_direction, speed, forward_speed, backward_speed)
  if state == 'abandoned' or state == 'razed' then
    return nil, nil
  elseif (not speed) and (not forward_speed) and (not backward_speed) then
    return nil, nil
  elseif speed and (not forward_speed) and (not backward_speed) then
    return speed_int(speed), speed
  elseif speed then
    return nil, nil
  end

  if preferred_direction == 'forward' then
    return speed_int(forward_speed), (forward_speed or '-') .. ' (' .. (backward_speed or '-') .. ')'
  elseif preferred_direction == 'backward' then
    return speed_int(backward_speed), (backward_speed or '-') .. ' (' .. (forward_speed or '-') .. ')'
  elseif preferred_direction == 'both' or (not preferred_direction) then
    return speed_int(forward_speed), (forward_speed or '-') .. ' / ' .. (backward_speed or '-')
  else
    return speed_int(forward_speed), (forward_speed or '-') .. ' / ' .. (backward_speed or '-')
  end
end

-- Protect against unwanted links in the UI
local file_prefix_length = string.len('File:')
function wikimedia_commons_or_image(wikimedia_commons, image)
    local image_https = (image and image:find('^https://') and image) or nil
    local image_wikimedia_commons_file = (image and image:find('^File:') and image:sub(file_prefix_length + 1)) or nil
    local wikimedia_commons_file = (wikimedia_commons and wikimedia_commons:find('^File:') and wikimedia_commons:sub(file_prefix_length + 1)) or nil
    local wikimedia_commons_not_file = (wikimedia_commons and (not wikimedia_commons:find('^File:')) and wikimedia_commons) or nil

    return wikimedia_commons_not_file, image_wikimedia_commons_file or wikimedia_commons_file, image_https
end

function signal_caption(tags)
  return tags['railway:signal:crossing_info:caption']
    or tags['railway:signal:stop:caption']
    or tags['railway:signal:crossing_hint:caption']
    or tags['railway:signal:station_distant:caption']
    or tags['railway:signal:crossing_distant:caption']
    or tags['railway:signal:speed_limit:caption']
    or tags['railway:signal:crossing:caption']
    or tags['railway:signal:passing:caption']
    or tags['railway:signal:automatic_marker:caption']
    or tags['railway:signal:whistle:caption']
    or tags['railway:signal:caption']
    or tags['railway:signal:minor:caption']
    or tags['railway:signal:main:caption']
    or tags['railway:signal:main_repeated:caption']
    or tags['railway:signal:distant:caption']
    or tags['railway:signal:electricity:caption']
    or tags['railway:signal:shunting:caption']
    or tags['railway:signal:fouling_point:caption']
    or tags['railway:signal:workrules:caption']
    or tags['railway:signal:resetting_switch:caption']
    or tags['railway:signal:switch:caption']
    or tags['railway:signal:route:caption']
    or tags['railway:signal:dual_mode:caption']
    or tags['railway:signal:train_protection:caption']
    or tags['railway:signal:radio:frequency']
end

local railway_line = osm2pgsql.define_table({
  name = 'railway_line',
  ids = { type = 'way', id_column = 'osm_id' },
  columns = {
    { column = 'id', sql_type = 'serial', create_only = true },
    { column = 'way', type = 'linestring' },
    { column = 'way_length', type = 'real' },
    { column = 'feature', type = 'text' },
    { column = 'state', type = 'text' },
    { column = 'rank', type = 'integer' },
    { column = 'service', type = 'text' },
    { column = 'usage', type = 'text' },
    { column = 'highspeed', type = 'boolean' },
    { column = 'layer', type = 'text' },
    { column = 'ref', type = 'text' },
    { column = 'track_ref', type = 'text' },
    { column = 'name', type = 'text' },
    { column = 'construction', type = 'text' },
    { column = 'tunnel', type = 'boolean' },
    { column = 'bridge', type = 'boolean' },
    { column = 'maxspeed', type = 'real' },
    { column = 'preferred_direction', type = 'text' },
    { column = 'speed_label', type = 'text' },
    { column = 'frequency', type = 'real' },
    { column = 'voltage', type = 'integer' },
    { column = 'electrification_state', type = 'text' },
    { column = 'future_frequency', type = 'real' },
    { column = 'future_voltage', type = 'integer' },
    { column = 'gauges', sql_type = 'text[]' },
    { column = 'loading_gauge', type = 'text' },
    { column = 'track_class', type = 'text' },
    { column = 'reporting_marks', sql_type = 'text[]' },
    { column = 'train_protection', type = 'text' },
    { column = 'train_protection_rank', type = 'smallint' },
    { column = 'train_protection_construction', type = 'text' },
    { column = 'train_protection_construction_rank', type = 'smallint' },
    { column = 'operator', sql_type = 'text[]' },
    { column = 'owner', sql_type = 'text' },
    { column = 'traffic_mode', type = 'text' },
    { column = 'radio', type = 'text' },
    { column = 'wikidata', type = 'text' },
    { column = 'wikimedia_commons', type = 'text' },
    { column = 'wikimedia_commons_file', type = 'text' },
    { column = 'image', type = 'text' },
    { column = 'mapillary', type = 'text' },
    { column = 'wikipedia', type = 'text' },
    { column = 'note', type = 'text' },
    { column = 'description', type = 'text' },
  },
})

local pois = osm2pgsql.define_table({
  name = 'pois',
  ids = { type = 'any', id_column = 'osm_id', type_column = 'osm_type' },
  columns = {
    { column = 'id', sql_type = 'serial', create_only = true },
    { column = 'way', type = 'point' },
    { column = 'feature', type = 'text' },
    { column = 'rank', type = 'integer' },
    { column = 'minzoom', type = 'integer' },
    { column = 'layer', type = 'text' },
    { column = 'name', type = 'text' },
    { column = 'ref', type = 'text' },
    { column = 'position', sql_type = 'text[]' },
    { column = 'wikidata', type = 'text' },
    { column = 'wikimedia_commons', type = 'text' },
    { column = 'wikimedia_commons_file', type = 'text' },
    { column = 'image', type = 'text' },
    { column = 'mapillary', type = 'text' },
    { column = 'wikipedia', type = 'text' },
    { column = 'note', type = 'text' },
    { column = 'description', type = 'text' },
  },
})

local stations = osm2pgsql.define_table({
  name = 'stations',
  ids = { type = 'any', id_column = 'osm_id', type_column = 'osm_type' },
  columns = {
    { column = 'id', sql_type = 'serial', create_only = true },
    { column = 'way', type = 'geometry' },
    { column = 'feature', type = 'text' },
    { column = 'state', type = 'text' },
    { column = 'name', type = 'text' },
    { column = 'ref', type = 'text' },
    { column = 'station', type = 'text' },
    { column = 'railway_ref', type = 'text' },
    { column = 'uic_ref', type = 'text' },
    { column = 'name_tags', type = 'hstore' },
    { column = 'operator', type = 'text' },
    { column = 'network', type = 'text' },
    { column = 'position', sql_type = 'text[]' },
    { column = 'yard_purpose', sql_type = 'text[]' },
    { column = 'yard_hump', type = 'boolean' },
    { column = 'wikidata', type = 'text' },
    { column = 'wikimedia_commons', type = 'text' },
    { column = 'wikimedia_commons_file', type = 'text' },
    { column = 'image', type = 'text' },
    { column = 'mapillary', type = 'text' },
    { column = 'wikipedia', type = 'text' },
    { column = 'note', type = 'text' },
    { column = 'description', type = 'text' },
  },
  indexes = {
    -- For joining grouped_stations_with_route_count with metadata from this table
    { column = 'id', method = 'btree', unique = true },
    { column = 'way', method = 'gist' },
    { column = 'uic_ref', method = 'btree', where = 'uic_ref IS NOT NULL' },
    { column = 'railway_ref', method = 'btree', where = 'railway_ref IS NOT NULL' },
  },
})

local stop_positions = osm2pgsql.define_table({
  name = 'stop_positions',
  ids = { type = 'node', id_column = 'osm_id' },
  columns = {
    { column = 'id', sql_type = 'serial', create_only = true },
    { column = 'way', type = 'point' },
    { column = 'name', type = 'text' },
    { column = 'type', type = 'text' },
  },
})

local platforms = osm2pgsql.define_table({
  name = 'platforms',
  ids = { type = 'any', id_column = 'osm_id', type_column = 'osm_type' },
  columns = {
    { column = 'id', sql_type = 'serial', create_only = true },
    { column = 'way', type = 'geometry' },
    { column = 'name', type = 'text' },
    { column = 'ref', sql_type = 'text[]' },
    { column = 'height', type = 'real' },
    { column = 'surface', type = 'text' },
    { column = 'elevator', type = 'boolean' },
    { column = 'shelter', type = 'boolean' },
    { column = 'lit', type = 'boolean' },
    { column = 'bin', type = 'boolean' },
    { column = 'bench', type = 'boolean' },
    { column = 'wheelchair', type = 'boolean' },
    { column = 'departures_board', type = 'boolean' },
    { column = 'tactile_paving', type = 'boolean' },
  },
})

local platform_edge = osm2pgsql.define_table({
  name = 'platform_edge',
  ids = { type = 'way', id_column = 'osm_id' },
  columns = {
    { column = 'id', sql_type = 'serial', create_only = true },
    { column = 'way', type = 'linestring' },
    { column = 'ref', sql_type = 'text' },
    { column = 'height', type = 'real' },
    { column = 'tactile_paving', type = 'boolean' },
  },
})

local station_entrances = osm2pgsql.define_table({
  name = 'station_entrances',
  ids = { type = 'any', id_column = 'osm_id', type_column = 'osm_type' },
  columns = {
    { column = 'id', sql_type = 'serial', create_only = true },
    { column = 'way', type = 'point' },
    { column = 'name', type = 'text' },
    { column = 'type', type = 'text' },
    { column = 'ref', type = 'text' },
    { column = 'wikidata', type = 'text' },
    { column = 'wikimedia_commons', type = 'text' },
    { column = 'wikimedia_commons_file', type = 'text' },
    { column = 'image', type = 'text' },
    { column = 'mapillary', type = 'text' },
    { column = 'wikipedia', type = 'text' },
    { column = 'note', type = 'text' },
    { column = 'description', type = 'text' },
  },
})

local signal_columns = {
  { column = 'id', sql_type = 'serial', create_only = true },
  { column = 'way', type = 'point' },
  { column = 'railway', type = 'text' },
  { column = 'ref', type = 'text' },
  { column = 'signal_direction', type = 'text' },
  { column = 'caption', type = 'text' },
  { column = 'position', sql_type = 'text[]' },
  { column = 'wikidata', type = 'text' },
  { column = 'wikimedia_commons', type = 'text' },
  { column = 'wikimedia_commons_file', type = 'text' },
  { column = 'image', type = 'text' },
  { column = 'mapillary', type = 'text' },
  { column = 'wikipedia', type = 'text' },
  { column = 'note', type = 'text' },
  { column = 'description', type = 'text' },
}
local osm2psql_types = {
  boolean = 'boolean',
  array = 'text',
}
local sql_types = {
  boolean = 'boolean',
  array = 'text[]',
}
for _, tag in ipairs(tag_functions.signal_tags) do
  local definition = {
    column = tag.tag,
    type = (tag.type and osm2psql_types[tag.type] or 'text'),
    sql_type = (tag.type and sql_types[tag.type] or 'text'),
  }
  table.insert(signal_columns, definition)
end
local signals = osm2pgsql.define_table({
  name = 'signals',
  ids = { type = 'node', id_column = 'osm_id' },
  columns = signal_columns,
})

local boxes = osm2pgsql.define_table({
  name = 'boxes',
  ids = { type = 'any', id_column = 'osm_id', type_column = 'osm_type' },
  columns = {
    { column = 'id', sql_type = 'serial', create_only = true },
    { column = 'way', type = 'geometry' },
    { column = 'center', type = 'geometry' },
    { column = 'way_area', type = 'real' },
    { column = 'feature', type = 'text' },
    { column = 'ref', type = 'text' },
    { column = 'name', type = 'text' },
    { column = 'operator', type = 'text' },
    { column = 'position', sql_type = 'text[]' },
    { column = 'wikidata', type = 'text' },
    { column = 'wikimedia_commons', type = 'text' },
    { column = 'wikimedia_commons_file', type = 'text' },
    { column = 'image', type = 'text' },
    { column = 'mapillary', type = 'text' },
    { column = 'wikipedia', type = 'text' },
    { column = 'note', type = 'text' },
    { column = 'description', type = 'text' },
  },
})

local turntables = osm2pgsql.define_table({
  name = 'turntables',
  ids = { type = 'way', id_column = 'osm_id' },
  columns = {
    { column = 'id', sql_type = 'serial', create_only = true },
    { column = 'way', type = 'polygon' },
    { column = 'feature', type = 'text' },
  },
})

local railway_positions = osm2pgsql.define_table({
  name = 'railway_positions',
  ids = { type = 'node', id_column = 'osm_id' },
  columns = {
    { column = 'id', sql_type = 'serial', create_only = true },
    { column = 'way', type = 'point' },
    { column = 'railway', type = 'text' },
    { column = 'position_numeric', type = 'real' },
    { column = 'position_text', type = 'text', not_null = true },
    { column = 'position_exact', type = 'text' },
    { column = 'type', type = 'text', not_null = true },
    { column = 'zero', type = 'boolean' },
    { column = 'line', type = 'text' },
    { column = 'name', type = 'text' },
    { column = 'ref', type = 'text' },
    { column = 'operator', type = 'text' },
    { column = 'wikidata', type = 'text' },
    { column = 'wikimedia_commons', type = 'text' },
    { column = 'wikimedia_commons_file', type = 'text' },
    { column = 'image', type = 'text' },
    { column = 'mapillary', type = 'text' },
    { column = 'wikipedia', type = 'text' },
    { column = 'note', type = 'text' },
    { column = 'description', type = 'text' },
  },
  indexes = {
    { column = 'way', method = 'gist' },
    { column = 'position_numeric', method = 'btree', where = 'position_numeric IS NOT NULL' },
  },
})

local catenary = osm2pgsql.define_table({
  name = 'catenary',
  ids = { type = 'any', id_column = 'osm_id', type_column = 'osm_type' },
  columns = {
    { column = 'id', sql_type = 'serial', create_only = true },
    { column = 'way', type = 'geometry' },
    { column = 'feature', type = 'text' },
    { column = 'ref', type = 'text' },
    { column = 'transition', type = 'boolean' },
    { column = 'structure', type = 'text' },
    { column = 'supporting', type = 'text' },
    { column = 'attachment', type = 'text' },
    { column = 'tensioning', type = 'text' },
    { column = 'insulator', type = 'text' },
    { column = 'position', sql_type = 'text[]' },
    { column = 'note', type = 'text' },
    { column = 'description', type = 'text' },
  },
})

local railway_switches = osm2pgsql.define_table({
  name = 'railway_switches',
  ids = { type = 'node', id_column = 'osm_id' },
  columns = {
    { column = 'id', sql_type = 'serial', create_only = true },
    { column = 'way', type = 'point' },
    { column = 'railway', type = 'text' },
    { column = 'ref', type = 'text' },
    { column = 'type', type = 'text' },
    { column = 'turnout_side', type = 'text' },
    { column = 'local_operated', type = 'boolean' },
    { column = 'resetting', type = 'boolean' },
    { column = 'position', sql_type = 'text[]' },
    { column = 'wikidata', type = 'text' },
    { column = 'wikimedia_commons', type = 'text' },
    { column = 'wikimedia_commons_file', type = 'text' },
    { column = 'image', type = 'text' },
    { column = 'mapillary', type = 'text' },
    { column = 'wikipedia', type = 'text' },
    { column = 'note', type = 'text' },
    { column = 'description', type = 'text' },
  },
})

local routes = osm2pgsql.define_table({
  name = 'routes',
  ids = { type = 'relation', id_column = 'osm_id' },
  columns = {
    { column = 'platform_ref_ids', sql_type = 'int8[]' },
    { column = 'stop_ref_ids', sql_type = 'int8[]' },
  },
  indexes = {
    { column = 'platform_ref_ids', method = 'gin' },
    { column = 'stop_ref_ids', method = 'gin' },
  },
})

local stop_areas = osm2pgsql.define_table({
  name = 'stop_areas',
  ids = { type = 'relation', id_column = 'osm_id' },
  columns = {
    { column = 'platform_ref_ids', sql_type = 'int8[]' },
    { column = 'stop_ref_ids', sql_type = 'int8[]' },
    { column = 'node_ref_ids', sql_type = 'int8[]' },
    { column = 'way_ref_ids', sql_type = 'int8[]' },
  },
  indexes = {
    { column = 'platform_ref_ids', method = 'gin' },
    { column = 'stop_ref_ids', method = 'gin' },
    { column = 'node_ref_ids', method = 'gin' },
    { column = 'way_ref_ids', method = 'gin' },
  },
})

local stop_area_groups = osm2pgsql.define_table({
  name = 'stop_area_groups',
  ids = { type = 'relation', id_column = 'osm_id' },
  columns = {
    { column = 'stop_area_ref_ids', sql_type = 'int8[]' },
  },
  indexes = {
    { column = 'stop_area_ref_ids', method = 'gin' },
  },
})

local railway_line_states = {}
-- ordered from lower to higher importance
local states = {'razed', 'abandoned', 'disused', 'proposed', 'construction', 'preserved'}
for index, state in ipairs(states) do
  railway_line_states[state] = {
    state = state,
    railway = state .. ':railway',
    usage = state .. ':usage',
    service = state .. ':service',
    name = state .. ':name',
    gauge = state .. ':gauge',
    rank = index + 1,
  }
end

function railway_line_state(tags)
  local preserved = tags['railway:preserved'] == 'yes' or tags['railway'] == 'preserved'
  local railway = tags['railway'] == 'preserved' and 'rail' or tags['railway']
  local usage = tags['usage']
  local service = tags['service']
  local name = tags['name']
  local gauge = tags['gauge']
  local highspeed = tags['highspeed'] == 'yes'

  -- map known railway state values to their state values
  local mapped_railway = railway_line_states[railway]
  if mapped_railway then
    return mapped_railway.state,
      tags[mapped_railway.railway] or (tags['railway:preserved'] == 'yes' and tags['railway']) or tags[railway] or 'rail',
      tags[mapped_railway.usage] or usage,
      tags[mapped_railway.service] or service,
      tags[mapped_railway.name] or name,
      tags[mapped_railway.gauge] or gauge,
      highspeed,
      mapped_railway.rank
  else

    if usage == 'main' and (not service) and highspeed then rank = 200
    elseif usage == 'main' and (not service) then rank = 110
    elseif usage == 'branch' and (not service) then rank = 100
    elseif (usage == 'main' or usage == 'branch') and service == 'spur' then rank = 98
    elseif (usage == 'main' or usage == 'branch') and service == 'siding' then rank = 97
    elseif (usage == 'main' or usage == 'branch') and service == 'yard' then rank = 96
    elseif (usage == 'main' or usage == 'branch') and service == 'crossover' then rank = 95
    elseif (not usage) and service == 'spur' then rank = 88
    elseif (not usage) and service == 'siding' then rank = 87
    elseif (not usage) and service == 'yard' then rank = 86
    elseif (not usage) and service == 'crossover' then rank = 85
    elseif usage == 'industrial' and (not service) then rank = 75
    elseif usage == 'industrial' and (service == 'siding' or service == 'spur' or service == 'yard' or service == 'crossover') then rank = 74
    elseif (usage == 'tourism' or usage == 'military' or usage == 'test') and (not service) then rank = 55
    elseif (usage == 'tourism' or usage == 'military' or usage == 'test') and (service == 'siding' or service == 'spur' or service == 'yard' or service == 'crossover') then rank = 54
    elseif (not service) then rank = 40
    elseif service == 'spur' then rank = 38
    elseif service == 'siding' then rank = 37
    elseif service == 'yard' then rank = 36
    elseif service == 'crossover' then rank = 35
    else rank = 10
    end

    return 'present', railway, usage, service, name, gauge, highspeed, rank
  end
end

function railway_line_name(name, tunnel, tunnel_name, bridge, bridge_name)
  if tunnel then
    return tunnel_name or name
  elseif bridge then
    return bridge_name or name
  else
    return name
  end
end

local electrification_values = osm2pgsql.make_check_values_func({'contact_line', 'yes', 'rail', 'ground-level_power_supply', '4th_rail', 'contact_line;rail', 'rail;contact_line'})
function electrification_state(tags)
  local electrified = tags['electrified']

  if electrification_values(electrified) then
    return 'present', tonumber(tags['voltage']), tonumber(tags['frequency']), nil, nil
  end
  if electrification_values(tags['construction:electrified']) then
    return 'construction', nil, nil, tonumber(tags['construction:voltage']), tonumber(tags['construction:frequency'])
  end
  if electrification_values(tags['proposed:electrified']) then
    return 'proposed', nil, nil, tonumber(tags['proposed:voltage']), tonumber(tags['proposed:frequency'])
  end
    if electrified == 'no' then
        if electrification_values(tags['deelectrified']) then
            return 'deelectrified', nil, nil, nil, nil
        end
        if electrification_values(tags['abandoned:electrified']) then
            return 'abandoned', nil, nil, nil, nil
        end

        return 'no', nil, nil, nil, nil
    end

    return nil, nil, nil
end

function to_sql_array(items)
  -- Put the items in a table into a raw SQL array string (quoted and comma-delimited)
  if not items then
    return nil
  end

  local result = '{'

  for index, item in ipairs(items) do
    if index > 1 then
      result = result .. ','
    end

    -- Raw SQL array syntax
    result = result .. "\"" .. item:gsub("\\", "\\\\"):gsub("\"", "\\\"") .. "\""
  end

  return result .. '}'
end

-- Split a value and turn it into a raw SQL array (quoted and comma-delimited)
function split_semicolon_to_sql_array(value)
  if not value then
    return nil
  end

  local items = {}

  if value then
    for part in string.gmatch(value, '[^;]+') do
      local stripped_part = strip_prefix(part, ' ')
      if stripped_part then
        table.insert(items, stripped_part)
      end
    end
  end

  return to_sql_array(items)
end

function semicolon_to_record_separator(value)
  return value and value:gsub(";", "\u{001E}") or nil
end

local railway_state_tags = {
  present = 'railway',
  construction = 'construction:railway',
  proposed = 'proposed:railway',
  disused = 'disused:railway',
  abandoned = 'abandoned:railway',
  preserved = 'preserved:railway',
  -- Razed is not included
}
function railway_feature_and_state(tags, railway_value_func)
  for state, railway_tag in pairs(railway_state_tags) do
    local feature = railway_value_func(tags[railway_tag])
    if feature then
      return feature, state
    end
  end

  return nil, nil
end

local vehicles = {'train', 'subway', 'light_rail', 'tram', 'monorail', 'funicular', 'miniature'}
function station_type(tags)
  -- Determine the type of station
  local feature_stations = {}
  local has_entries = false

  if tags.station then
    for station in string.gmatch(tags.station, '[^;]+') do
      feature_stations[station] = true
      has_entries = true
    end
  else
    for _, vehicle in ipairs(vehicles) do
      if tags[vehicle] == 'yes' then
        feature_stations[vehicle] = true
        has_entries = true
      end
    end
  end

  if not has_entries then
    if tags.railway == 'tram_stop' then
      feature_stations['tram'] = true
    else
      feature_stations['train'] = true
    end
  end

  return feature_stations
end

local known_name_tags = {'name', 'alt_name', 'short_name', 'long_name', 'official_name', 'old_name', 'uic_name'}
function name_tags(tags)
  -- Gather name tags for searching
  local found_name_tags = {}

  for key, value in pairs(tags) do
    for _, name_tag in ipairs(known_name_tags) do
      if key == name_tag or (key:find('^' .. name_tag .. ':') ~= nil) then
        found_name_tags[key] = value
        break
      end
    end
  end

  return found_name_tags
end

function position_is_zero(position)
  if position:find('^%-?%d+$') or position:find('^%-?%d*[,/.]0*$') then
    return true
  else
    return false
  end
end

function parse_railway_position(position, line)
  if not position then
    return nil
  end

  if position:find('^mi:') then
    local stripped_position = position:gsub('^mi: ?', '')
    local position_with_dot = stripped_position:gsub(',', '.')

    return {
      text = stripped_position,
      numeric = tonumber(position_with_dot),
      type = 'mi',
      zero = position_is_zero(stripped_position),
      exact = nil,
      line = line,
    }
  elseif position:find('^pkm:') then
    local stripped_position = position:gsub('^pkm: ?', '')
    local position_with_dot = stripped_position:gsub(',', '.')

    return {
      text = stripped_position,
      numeric = tonumber(position_with_dot),
      type = 'pkm',
      zero = position_is_zero(stripped_position),
      exact = nil,
      line = line,
    }
  else
    local position_with_dot = position:gsub(',', '.')

    return {
      text = position,
      numeric = tonumber(position_with_dot),
      type = 'km',
      zero = position_is_zero(position),
      exact = nil,
      line = line,
    }
  end
end

function find_position_tags(tags)
  local position, position_exact = tags['railway:position'], tags['railway:position:exact']

  local exact_line_position_prefix = 'railway:position:exact:'
  local line_positions = {}
  for tag, value in pairs(tags) do
    if osm2pgsql.has_prefix(tag, exact_line_position_prefix) then
      line_positions[tag:sub(exact_line_position_prefix:len() + 1)] = value
    end
  end

  return position, position_exact, line_positions
end

function parse_railway_positions(position, position_exact, line_positions)
  -- Collect positions, from both normal and exact positions, eliminating duplicates
  -- Parsing is ordered from least specific to most specific

  local parsed_positions = {}
  local found_positions = false

  if position then
    for part in string.gmatch(position, '[^;]+') do
      local stripped_part = part:gsub('^ ', '')
      local parsed_position = parse_railway_position(stripped_part, nil)

      if parsed_position then
        table.insert(parsed_positions, parsed_position)
        found_positions = true
      end
    end
  end

  if position_exact then
    for part in string.gmatch(position_exact, '[^;]+') do
      local stripped_part = part:gsub('^ ', '')
      local parsed_position = parse_railway_position(stripped_part, nil)

      if parsed_position then
        local found_existing_position = false

        if found_positions and parsed_position.numeric ~= nil then
          for _, existing_position in ipairs(parsed_positions) do
            -- Verify if the position is close to another position. Note that this matches slightly outside the first decimal's precision.
            if existing_position.numeric ~= nil and math.abs(existing_position.numeric - parsed_position.numeric) < 0.1 then
              existing_position.numeric = parsed_position.numeric
              existing_position.exact = parsed_position.text
              found_existing_position = true
            end
          end
        end

        if not found_existing_position then
          table.insert(parsed_positions, parsed_position)
          found_positions = true
        end
      end
    end
  end

  for line, line_position in pairs(line_positions) do
    local parsed_position = parse_railway_position(line_position, line)

    if parsed_position then
      local found_existing_position = false

      if found_positions and parsed_position.numeric ~= nil then
        for _, existing_position in ipairs(parsed_positions) do
          -- Verify if the position is close to another position. Note that this matches slightly outside the first decimal's precision.
          if existing_position.numeric ~= nil and math.abs(existing_position.numeric - parsed_position.numeric) < 0.1 then
            existing_position.numeric = parsed_position.numeric
            existing_position.exact = parsed_position.text
            existing_position.line = parsed_position.line
            found_existing_position = true
          end
        end
      end

      if not found_existing_position then
        table.insert(parsed_positions, parsed_position)
        found_positions = true
      end
    end
  end

  if found_positions then
    return parsed_positions
  else
    return nil
  end
end

function format_railway_position(item)
  return item.text .. (item.exact and (' @ ' .. item.exact) or '') .. ' (' .. item.type .. ')' .. (item.line and (' on ' .. item.line) or '')
end

function is_railway_platform(tags)
  -- Ignore non-railway platforms
  return tags.railway == 'platform'
    or (
      tags.public_transport == 'platform'
      and (
        tags.train == 'yes'
        or tags.tram == 'yes'
        or tags.subway == 'yes'
        or tags.light_rail == 'yes'
        or not (
          tags.bus == 'yes'
          or tags.trolleybus == 'yes'
          or tags.share_taxi == 'yes'
          or tags.ferry == 'yes'
        )
      )
    )
end

function stop_position_type(tags)
  -- Assumption: a stop position is valid for a single transport modality
  if tags.train == 'yes' then
    return 'train'
  elseif tags.tram == 'yes' then
    return 'tram'
  elseif tags.light_rail == 'yes' then
    return 'light_rail'
  elseif tags.subway == 'yes' then
    return 'subway'
  elseif tags.funicular == 'yes' then
    return 'funicular'
  elseif tags.monorail == 'yes' then
    return 'monorail'
  elseif tags.miniature == 'yes' then
    return 'miniature'
  elseif tags.bus == 'yes' or tags.trolleybus == 'yes' or tags.share_taxi == 'yes' or tags.ferry == 'yes' then
    return nil
  else
    -- Default to train
    return 'train'
  end
end

local railway_station_values = osm2pgsql.make_check_values_func({'station', 'halt', 'tram_stop', 'service_station', 'yard', 'junction', 'spur_junction', 'crossover', 'site'})
local railway_poi_values = osm2pgsql.make_check_values_func(tag_functions.poi_railway_values)
local railway_signal_values = osm2pgsql.make_check_values_func({'signal', 'buffer_stop', 'derail', 'vacancy_detection'})
local railway_position_values = osm2pgsql.make_check_values_func({'milestone', 'level_crossing', 'crossing'})
local railway_switch_values = osm2pgsql.make_check_values_func({'switch', 'railway_crossing'})
local railway_box_values = osm2pgsql.make_check_values_func({'signal_box', 'crossing_box', 'blockpost'})
local railway_entrances_values = osm2pgsql.make_check_values_func({'subway_entrance', 'train_station_entrance'})
local entrance_types = {
  subway_entrance = 'subway',
  train_station_entrance = 'train',
}
local reversed_signal_position = {
  right = 'left',
  left = 'right',
}
function osm2pgsql.process_node(object)
  local tags = object.tags
  local wikimedia_commons, wikimedia_commons_file, image = wikimedia_commons_or_image(tags.wikimedia_commons, tags.image)
  local position, position_exact, line_positions = find_position_tags(tags)

  if railway_box_values(tags.railway) then
    local point = object:as_point()
    boxes:insert({
      way = point,
      center = point,
      way_area = 0,
      feature = tags.railway,
      ref = tags['railway:ref'],
      name = tags.name,
      operator = tags.operator,
      position = to_sql_array(map(parse_railway_positions(position, position_exact, line_positions), format_railway_position)),
      wikimedia_commons = wikimedia_commons,
      wikimedia_commons_file = wikimedia_commons_file,
      image = image,
      mapillary = tags.mapillary,
      wikipedia = tags.wikipedia,
      note = tags.note,
      description = tags.description,
    })
  end

  local station_feature, station_state = railway_feature_and_state(tags, railway_station_values)
  if station_feature then
    for station, _ in pairs(station_type(tags)) do
      stations:insert({
        way = object:as_point(),
        feature = station_feature,
        state = station_state,
        name = tags.name or tags.short_name,
        ref = tags.ref,
        station = station,
        railway_ref = tags['railway:ref'] or tags['ref:crs'],
        uic_ref = tags['uic_ref'],
        name_tags = name_tags(tags),
        operator = tags.operator,
        network = tags.network,
        position = to_sql_array(map(parse_railway_positions(position, position_exact, line_positions), format_railway_position)),
        yard_purpose = split_semicolon_to_sql_array(tags['railway:yard:purpose']),
        yard_hump = tags['railway:yard:hump'] == 'yes' or nil,
        wikidata = tags.wikidata,
        wikimedia_commons = wikimedia_commons,
        wikimedia_commons_file = wikimedia_commons_file,
        image = image,
        mapillary = tags.mapillary,
        wikipedia = tags.wikipedia,
        note = tags.note,
        description = tags.description,
      })
    end
  end

  if railway_poi_values(tags.railway) or tags['tourism'] == 'museum' then
    local feature, rank, minzoom, layer = tag_functions.poi(tags)

    pois:insert({
      way = object:as_point(),
      feature = feature,
      rank = rank,
      minzoom = minzoom,
      layer = layer,
      name = tags.name,
      ref = tags.ref,
      position = to_sql_array(map(parse_railway_positions(position, position_exact, line_positions), format_railway_position)),
      wikidata = tags.wikidata,
      wikimedia_commons = wikimedia_commons,
      wikimedia_commons_file = wikimedia_commons_file,
      image = image,
      mapillary = tags.mapillary,
      wikipedia = tags.wikipedia,
      note = tags.note,
      description = tags.description,
    })
  end

  if tags.public_transport == 'stop_position' and tags.name then
    local type = stop_position_type(tags)
    if type then
      stop_positions:insert({
        way = object:as_point(),
        name = tags.name,
        type = type,
      })
    end
  end

  if is_railway_platform(tags) then
    platforms:insert({
      way = object:as_point(),
      name = tags.name,
      ref = split_semicolon_to_sql_array(tags.ref),
      height = tags.height,
      surface = tags.surface,
      elevator = tags.elevator == 'yes',
      shelter = tags.shelter == 'yes',
      lit = tags.lit == 'yes',
      bin = tags.bin == 'yes',
      bench = tags.bench == 'yes',
      wheelchair = tags.wheelchair == 'yes',
      departures_board = tags.departures_board == 'yes',
      tactile_paving = tags.tactile_paving == 'yes',
    })
  end

  if railway_entrances_values(tags.railway) then
    station_entrances:insert({
      way = object:as_point(),
      type = entrance_types[tags.railway],
      ref = tags.ref,
      name = tags.name,
      wikidata = tags.wikidata,
      wikimedia_commons = wikimedia_commons,
      wikimedia_commons_file = wikimedia_commons_file,
      image = image,
      mapillary = tags.mapillary,
      wikipedia = tags.wikipedia,
      note = tags.note,
      description = tags.description,
    })
  end

  if railway_signal_values(tags.railway) then
    local signal = {
      way = object:as_point(),
      railway = tags.railway,
      ref = tags.ref,
      signal_direction = tags['railway:signal:direction'],
      caption = signal_caption(tags),
      position = to_sql_array(map(parse_railway_positions(position, position_exact, line_positions), format_railway_position)),
      wikidata = tags.wikidata,
      wikimedia_commons = wikimedia_commons,
      wikimedia_commons_file = wikimedia_commons_file,
      image = image,
      mapillary = tags.mapillary,
      wikipedia = tags.wikipedia,
      note = tags.note,
      description = tags.description,
    }

    for _, tag in ipairs(tag_functions.signal_tags) do
      if tag.type == 'boolean' then
        signal[tag.tag] = tags[tag.tag] == 'yes'
      elseif tag.type == 'array' then
        signal[tag.tag] = split_semicolon_to_sql_array(tags[tag.tag])
      else
        signal[tag.tag] = tags[tag.tag]
      end
    end

    -- Special handling for signal position: flip position if reversed signal direction
    if signal.signal_direction == 'backward' and signal["railway:signal:position"] then
      signal["railway:signal:position"] = reversed_signal_position[signal["railway:signal:position"]] or signal["railway:signal:position"]
    end

    signals:insert(signal)
  end

  if railway_position_values(tags.railway) and (position or position_exact) then
    for _, position in ipairs(parse_railway_positions(position, position_exact, line_positions)) do
      railway_positions:insert({
        way = object:as_point(),
        railway = tags.railway,
        position_numeric = position.numeric,
        position_text = position.text,
        position_exact = position.exact,
        type = position.type,
        zero = position.zero,
        line = position.line,
        name = tags['name'],
        ref = tags['ref'],
        operator = tags['operator'],
        wikidata = tags.wikidata,
        wikimedia_commons = wikimedia_commons,
        wikimedia_commons_file = wikimedia_commons_file,
        image = image,
        mapillary = tags.mapillary,
        wikipedia = tags.wikipedia,
        note = tags.note,
        description = tags.description,
      })
    end
  end

  if railway_switch_values(tags.railway) then
    railway_switches:insert({
      way = object:as_point(),
      railway = tags.railway,
      ref = tags.ref,
      type = tags['railway:switch'],
      turnout_side = tags['railway:turnout_side'],
      local_operated = tags['railway:local_operated'] == 'yes',
      resetting = tags['railway:switch:resetting'] == 'yes',
      position = to_sql_array(map(parse_railway_positions(position, position_exact, line_positions), format_railway_position)),
      wikidata = tags.wikidata,
      wikimedia_commons = wikimedia_commons,
      wikimedia_commons_file = wikimedia_commons_file,
      image = image,
      mapillary = tags.mapillary,
      wikipedia = tags.wikipedia,
      note = tags.note,
      description = tags.description,
    })
  end

  if tags.power == 'catenary_mast' then
    catenary:insert({
      way = object:as_point(),
      ref = tags.ref,
      feature = 'mast',
      transition = tags['location:transition'] == 'yes',
      structure = tags.structure,
      supporting = tags['catenary_mast:supporting'],
      attachment = tags['catenary_mast:attachment'],
      tensioning = tags.tensioning,
      insulator = tags.insulator,
      position = to_sql_array(map(parse_railway_positions(position, position_exact, line_positions), format_railway_position)),
      note = tags.note,
      description = tags.description,
    })
  end
end

local max_segment_length = 10000
local railway_values = osm2pgsql.make_check_values_func({'rail', 'tram', 'light_rail', 'subway', 'narrow_gauge', 'disused', 'abandoned', 'razed', 'construction', 'proposed', 'preserved', 'monorail', 'miniature', 'funicular', 'ferry'})
local railway_turntable_values = osm2pgsql.make_check_values_func({'turntable', 'traverser'})
function osm2pgsql.process_way(object)
  local tags = object.tags
  local wikimedia_commons, wikimedia_commons_file, image = wikimedia_commons_or_image(tags.wikimedia_commons, tags.image)

  if railway_values(tags.railway) then
    local state, feature, usage, service, state_name, gauge, highspeed, rank = railway_line_state(tags)
    local railway_train_protection, railway_train_protection_rank = tag_functions.train_protection(tags, '')
    local train_protection_construction, train_protection_construction_rank = tag_functions.train_protection(tags, 'construction:')

    local current_electrification_state, voltage, frequency, future_voltage, future_frequency = electrification_state(tags)

    local tunnel = tags['tunnel'] and tags['tunnel'] ~= 'no' or false
    local bridge = tags['bridge'] and tags['bridge'] ~= 'no' or false
    local name = railway_line_name(state_name, tunnel, tags['tunnel:name'], bridge, tags['bridge:name'])

    local oneway_map = {
      ['yes'] = 'forward',
      ['-1'] = 'backward',
      ['no'] = 'both',
      ['alternating'] = 'both',
      ['reversible'] = 'both',
    }
    local preferred_direction = tags['railway:preferred_direction'] or oneway_map[tags['oneway']]
    local dominant_speed, speed_label = dominant_speed_label(state, preferred_direction, tags['maxspeed'], tags['maxspeed:forward'], tags['maxspeed:backward'])

    -- Segmentize linestring to optimize tile queries
    for way in object:as_linestring():transform(3857):segmentize(max_segment_length):geometries() do
      railway_line:insert({
        way = way,
        way_length = way:length(),
        feature = feature,
        state = state,
        service = service,
        usage = usage,
        rank = rank,
        highspeed = highspeed,
        layer = tags['layer'],
        ref = tags['ref'],
        track_ref = tags['railway:track_ref'],
        name = name,
        public_transport = tags['public_transport'],
        construction = tags['construction'],
        tunnel = tunnel,
        bridge = bridge,
        preferred_direction = preferred_direction,
        maxspeed = dominant_speed,
        speed_label = speed_label,
        electrification_state = current_electrification_state,
        frequency = frequency,
        voltage = voltage,
        future_frequency = future_frequency,
        future_voltage = future_voltage,
        gauges = split_semicolon_to_sql_array(gauge),
        loading_gauge = tags['loading_gauge'],
        track_class = tags['railway:track_class'],
        reporting_marks = split_semicolon_to_sql_array(tags['reporting_marks']),
        train_protection = railway_train_protection,
        train_protection_rank = railway_train_protection_rank,
        train_protection_construction = train_protection_construction,
        train_protection_construction_rank = train_protection_construction_rank,
        operator = split_semicolon_to_sql_array(tags['operator']),
        owner = tags.owner,
        traffic_mode = tags['railway:traffic_mode'],
        radio = tags['railway:radio'],
        wikidata = tags.wikidata,
        wikimedia_commons = wikimedia_commons,
        wikimedia_commons_file = wikimedia_commons_file,
        image = image,
        mapillary = tags.mapillary,
        wikipedia = tags.wikipedia,
        note = tags.note,
        description = tags.description,
      })
    end
  end

  local station_feature, station_state = railway_feature_and_state(tags, railway_station_values)
  if station_feature then
    for station, _ in pairs(station_type(tags)) do
      stations:insert({
        way = object:as_polygon(),
        feature = station_feature,
        state = station_state,
        name = tags.name or tags.short_name,
        ref = tags.ref,
        station = station,
        railway_ref = tags['railway:ref'] or tags['ref:crs'],
        uic_ref = tags['uic_ref'],
        name_tags = name_tags(tags),
        operator = tags.operator,
        network = tags.network,
        yard_purpose = split_semicolon_to_sql_array(tags['railway:yard:purpose']),
        yard_hump = tags['railway:yard:hump'] == 'yes' or nil,
        wikidata = tags.wikidata,
        wikimedia_commons = wikimedia_commons,
        wikimedia_commons_file = wikimedia_commons_file,
        image = image,
        mapillary = tags.mapillary,
        wikipedia = tags.wikipedia,
        note = tags.note,
        description = tags.description,
      })
    end
  end

  if is_railway_platform(tags) then
    platforms:insert({
      way = object.is_closed and object:as_polygon() or object:as_linestring(),
      name = tags.name,
      ref = split_semicolon_to_sql_array(tags.ref),
      height = tags.height,
      surface = tags.surface,
      elevator = tags.elevator == 'yes',
      shelter = tags.shelter == 'yes',
      lit = tags.lit == 'yes',
      bin = tags.bin == 'yes',
      bench = tags.bench == 'yes',
      wheelchair = tags.wheelchair == 'yes',
      departures_board = tags.departures_board == 'yes',
      tactile_paving = tags.tactile_paving == 'yes',
    })
  end

  if railway_turntable_values(tags.railway) then
    turntables:insert({
      way = object:as_polygon(),
      feature = tags.railway,
    })
  end

  if railway_box_values(tags.railway) then
    local polygon = object:as_polygon():transform(3857)
    local position, position_exact, line_positions = find_position_tags(tags)

    boxes:insert({
      way = polygon,
      center = polygon:centroid(),
      way_area = polygon:area(),
      feature = tags.railway,
      ref = tags['railway:ref'],
      name = tags.name,
      operator = tags.operator,
      position = to_sql_array(map(parse_railway_positions(position, position_exact, line_positions), format_railway_position)),
      wikidata = tags.wikidata,
      wikimedia_commons = wikimedia_commons,
      wikimedia_commons_file = wikimedia_commons_file,
      image = image,
      mapillary = tags.mapillary,
      wikipedia = tags.wikipedia,
      note = tags.note,
      description = tags.description,
    })
  end

  if railway_poi_values(tags.railway) or tags['tourism'] == 'museum' then
    local feature, rank, minzoom, layer = tag_functions.poi(tags)
    local position, position_exact, line_positions = find_position_tags(tags)

    pois:insert({
      way = object:as_polygon():centroid(),
      feature = feature,
      rank = rank,
      minzoom = minzoom,
      layer = layer,
      name = tags.name,
      ref = tags.ref,
      position = to_sql_array(map(parse_railway_positions(position, position_exact, line_positions), format_railway_position)),
      wikidata = tags.wikidata,
      wikimedia_commons = wikimedia_commons,
      wikimedia_commons_file = wikimedia_commons_file,
      image = image,
      mapillary = tags.mapillary,
      wikipedia = tags.wikipedia,
      note = tags.note,
      description = tags.description,
    })
  end

  if tags.power == 'catenary_portal' then
    local position, position_exact, line_positions = find_position_tags(tags)

    catenary:insert({
      way = object:as_linestring(),
      ref = tags.ref,
      feature = 'portal',
      transition = tags['location:transition'] == 'yes',
      structure = tags.structure,
      supporting = nil,
      attachment = nil,
      tensioning = tags.tensioning,
      insulator = tags.insulator,
      position = to_sql_array(map(parse_railway_positions(position, position_exact, line_positions), format_railway_position)),
      note = tags.note,
      description = tags.description,
    })
  end

  if tags.railway == 'platform_edge' then
    platform_edge:insert({
      way = object:as_linestring(),
      ref = tags.ref,
      height = tags.height,
      tactile_paving = tags.tactile_paving == 'yes',
    })
  end
end

local route_values = osm2pgsql.make_check_values_func({'train', 'subway', 'tram', 'light_rail'})
local route_stop_relation_roles = osm2pgsql.make_check_values_func({'stop', 'station', 'stop_exit_only', 'stop_entry_only', 'forward_stop', 'backward_stop', 'forward:stop', 'backward:stop', 'stop_position', 'halt'})
local route_platform_relation_roles = osm2pgsql.make_check_values_func({'platform', 'platform_exit_only', 'platform_entry_only', 'forward:platform', 'backward:platform'})
function osm2pgsql.process_relation(object)
  local tags = object.tags

  if is_railway_platform(tags) then
    platforms:insert({
      way = object:as_multipolygon(),
      name = tags.name,
      ref = split_semicolon_to_sql_array(tags.ref),
      height = tags.height,
      surface = tags.surface,
      elevator = tags.elevator == 'yes',
      shelter = tags.shelter == 'yes',
      lit = tags.lit == 'yes',
      bin = tags.bin == 'yes',
      bench = tags.bench == 'yes',
      wheelchair = tags.wheelchair == 'yes',
      departures_board = tags.departures_board == 'yes',
      tactile_paving = tags.tactile_paving == 'yes',
    })
  end

  if tags.type == 'route' and route_values(tags.route) then
    local has_members = false
    local stop_members = {}
    local platform_members = {}
    for _, member in ipairs(object.members) do
      if route_stop_relation_roles(member.role) then
        table.insert(stop_members, member.ref)
        has_members = true
      end

      if route_platform_relation_roles(member.role) then
        table.insert(platform_members, member.ref)
        has_members = true
      end
    end

    if has_members then
      routes:insert({
        stop_ref_ids = '{' .. table.concat(stop_members, ',') .. '}',
        platform_ref_ids = '{' .. table.concat(platform_members, ',') .. '}',
      })
    end
  end

  if tags.type == 'public_transport' and tags.public_transport == 'stop_area' then
    local has_members = false
    local stop_members = {}
    local platform_members = {}
    local node_members = {}
    local way_members = {}
    for _, member in ipairs(object.members) do
      if member.role == 'stop' and member.type == 'n' then
        table.insert(stop_members, member.ref)
      elseif member.role == 'platform' then
        table.insert(platform_members, member.ref)
      elseif member.type == 'n' then
        -- Station has no role defined
        table.insert(node_members, member.ref)
        has_members = true
      elseif member.type == 'w' then
        -- Station has no role defined
        table.insert(way_members, member.ref)
        has_members = true
      end
    end

    if has_members then
      stop_areas:insert({
        stop_ref_ids = '{' .. table.concat(stop_members, ',') .. '}',
        platform_ref_ids = '{' .. table.concat(platform_members, ',') .. '}',
        node_ref_ids = '{' .. table.concat(node_members, ',') .. '}',
        way_ref_ids = '{' .. table.concat(way_members, ',') .. '}',
      })
    end
  end

  if tags.type == 'public_transport' and tags.public_transport == 'stop_area_group' then
    local has_members = false
    local stop_area_members = {}
    for _, member in ipairs(object.members) do
      if member.type == 'r' then
        table.insert(stop_area_members, member.ref)
        has_members = true
      end
    end

    if has_members then
      stop_area_groups:insert({
        stop_area_ref_ids = '{' .. table.concat(stop_area_members, ',') .. '}',
      })
    end
  end
end
