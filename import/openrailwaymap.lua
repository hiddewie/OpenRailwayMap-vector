local tag_functions = require('tags')

function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

function map(tbl, f)
    local t = {}
    for k,v in pairs(tbl) do
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
function wikimedia_commons_or_image(wikimedia_commons, image)
    if image and image:find('^File:') and not wikimedia_commons then
      return image, nil
    elseif image and image:find('^https://') then
      return wikimedia_commons, image
    else
      return wikimedia_commons, nil
    end
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
    or tags['railway:signal:distant:caption']
    or tags['railway:signal:electricity:caption']
    or tags['railway:signal:shunting:caption']
    or tags['railway:signal:workrules:caption']
    or tags['railway:signal:resetting_switch:caption']
    or tags['railway:signal:switch:caption']
    or tags['railway:signal:route:caption']
    or tags['railway:signal:dual_mode:caption']
    or tags['railway:signal:train_protection:caption']
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
    { column = 'traffic_mode', type = 'text' },
    { column = 'radio', type = 'text' },
    { column = 'wikidata', type = 'text' },
    { column = 'wikimedia_commons', type = 'text' },
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
    { column = 'railway', type = 'text' },
    { column = 'man_made', type = 'text' },
    { column = 'crossing_light', type = 'boolean' },
    { column = 'crossing_barrier', type = 'boolean' },
    { column = 'wikidata', type = 'text' },
    { column = 'wikimedia_commons', type = 'text' },
    { column = 'image', type = 'text' },
    { column = 'mapillary', type = 'text' },
    { column = 'wikipedia', type = 'text' },
    { column = 'note', type = 'text' },
    { column = 'description', type = 'text' },
  },
})

local stations = osm2pgsql.define_table({
  name = 'stations',
  ids = { type = 'node', id_column = 'osm_id' },
  columns = {
    { column = 'id', sql_type = 'serial', create_only = true },
    { column = 'way', type = 'point' },
    { column = 'railway', type = 'text' },
    { column = 'feature', type = 'text' },
    { column = 'name', type = 'text' },
    { column = 'ref', type = 'text' },
    { column = 'station', type = 'text' },
    { column = 'railway_ref', type = 'text' },
    { column = 'uic_ref', type = 'text' },
    { column = 'name_tags', type = 'hstore' },
    { column = 'operator', type = 'text' },
    { column = 'network', type = 'text' },
    { column = 'wikidata', type = 'text' },
    { column = 'wikimedia_commons', type = 'text' },
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
  },
})

local stop_positions = osm2pgsql.define_table({
  name = 'stop_positions',
  ids = { type = 'node', id_column = 'osm_id' },
  columns = {
    { column = 'id', sql_type = 'serial', create_only = true },
    { column = 'way', type = 'point' },
    { column = 'name', type = 'text' },
  },
})

local platforms = osm2pgsql.define_table({
  name = 'platforms',
  ids = { type = 'any', id_column = 'osm_id', type_column = 'osm_type' },
  columns = {
    { column = 'id', sql_type = 'serial', create_only = true },
    { column = 'way', type = 'point' },
    { column = 'name', type = 'text' },
  },
})

local subway_entrances = osm2pgsql.define_table({
  name = 'subway_entrances',
  ids = { type = 'any', id_column = 'osm_id', type_column = 'osm_type' },
  columns = {
    { column = 'id', sql_type = 'serial', create_only = true },
    { column = 'way', type = 'point' },
    { column = 'name', type = 'text' },
    { column = 'wikidata', type = 'text' },
    { column = 'wikimedia_commons', type = 'text' },
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
  { column = 'rank', type = 'smallint' },
  { column = 'deactivated', type = 'boolean' },
  { column = 'ref', type = 'text' },
  { column = 'ref_multiline', type = 'text' },
  { column = 'signal_direction', type = 'text' },
  { column = 'signal_position', type = 'text' },
  { column = 'dominant_speed', type = 'real' },
  { column = 'caption', type = 'text' },
  { column = 'wikidata', type = 'text' },
  { column = 'wikimedia_commons', type = 'text' },
  { column = 'image', type = 'text' },
  { column = 'mapillary', type = 'text' },
  { column = 'wikipedia', type = 'text' },
  { column = 'note', type = 'text' },
  { column = 'description', type = 'text' },
}
for _, tag in ipairs(tag_functions.signal_tags) do
  table.insert(signal_columns, { column = tag, type = 'text' })
end
local signals = osm2pgsql.define_table({
  name = 'signals',
  ids = { type = 'node', id_column = 'osm_id' },
  columns = signal_columns,
  -- The queried table is signals_with_azimuth
  cluster = 'no',
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
    { column = 'wikidata', type = 'text' },
    { column = 'wikimedia_commons', type = 'text' },
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
    { column = 'railway_position', type = 'text' },
    { column = 'railway_position_exact', type = 'text' },
    { column = 'name', type = 'text' },
    { column = 'ref', type = 'text' },
    { column = 'operator', type = 'text' },
    { column = 'wikidata', type = 'text' },
    { column = 'wikimedia_commons', type = 'text' },
    { column = 'image', type = 'text' },
    { column = 'mapillary', type = 'text' },
    { column = 'wikipedia', type = 'text' },
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
    { column = 'wikidata', type = 'text' },
    { column = 'wikimedia_commons', type = 'text' },
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
    { column = 'node_ref_ids', sql_type = 'int8[]' },
  },
  indexes = {
    { column = 'node_ref_ids', method = 'gin' },
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
  local railway = tags['railway']
  local usage = tags['usage']
  local service = tags['service']
  local name = tags['name']
  local gauge = tags['gauge']
  local highspeed = tags['highspeed'] == 'yes'

  -- map known railway state values to their state values
  mapped_railway = railway_line_states[railway]
  if mapped_railway then
    return mapped_railway.state,
      tags[mapped_railway.railway] or tags[railway] or 'rail',
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

-- Split a value and turn it into a raw SQL array (quoted and comma-delimited)
function split_semicolon_to_sql_array(value)
  local result = '{'

  local first = true
  if value then
    for part in string.gmatch(value, '[^;]+') do
      if part then

        if first then
          first = false
        else
          result = result .. ','
        end

        -- Raw SQL array syntax
        result = result .. "\"" .. part:gsub("\"", "\\\"") .. "\""
      end
    end
  end

  return result .. '}'
end

local railway_station_values = osm2pgsql.make_check_values_func({'station', 'halt', 'tram_stop', 'service_station', 'yard', 'junction', 'spur_junction', 'crossover', 'site'})
local railway_poi_values = osm2pgsql.make_check_values_func({'crossing', 'level_crossing', 'phone', 'border', 'owner_change', 'radio', 'lubricator', 'fuel', 'wash', 'water_tower', 'water_crane', 'sand_store', 'coaling_facility', 'waste_disposal', 'compressed_air_supply', 'preheating', 'loading_gauge', 'hump_yard', 'defect_detector', 'aei', 'buffer_stop', 'derail', 'workshop', 'engine_shed', 'museum', 'power_supply', 'rolling_highway'})
local railway_signal_values = osm2pgsql.make_check_values_func({'signal', 'buffer_stop', 'derail', 'vacancy_detection'})
local railway_position_values = osm2pgsql.make_check_values_func({'milestone', 'level_crossing', 'crossing'})
local railway_switch_values = osm2pgsql.make_check_values_func({'switch', 'railway_crossing'})
local railway_box_values = osm2pgsql.make_check_values_func({'signal_box', 'crossing_box', 'blockpost'})
local known_name_tags = {'name', 'alt_name', 'short_name', 'long_name', 'official_name', 'old_name', 'uic_name'}
function osm2pgsql.process_node(object)
  local tags = object.tags
  local wikimedia_commons, image = wikimedia_commons_or_image(tags.wikimedia_commons, tags.image)

  if railway_box_values(tags.railway) then
    local point = object:as_point()
    boxes:insert({
      way = point,
      center = point,
      way_area = 0,
      feature = tags.railway,
      ref = tags['railway:ref'],
      name = tags.name,
      wikimedia_commons = wikimedia_commons,
      image = image,
      mapillary = tags.mapillary,
      wikipedia = tags.wikipedia,
      note = tags.note,
      description = tags.description,
    })
  end

  if railway_station_values(tags['railway'])
     or railway_station_values(tags['construction:railway'])
     or railway_station_values(tags['proposed:railway'])
     or railway_station_values(tags['disused:railway'])
     or railway_station_values(tags['abandoned:railway'])
     or railway_station_values(tags['razed:railway'])
     or railway_station_values(tags['preserved:railway'])
   then

    local feature = tags['railway']
      or tags['construction:railway']
      or tags['proposed:railway']
      or tags['disused:railway']
      or tags['abandoned:railway']
      or tags['razed:railway']
      or tags['preserved:railway']

    -- Gather name tags for searching
    local name_tags = {}
    for key, value in pairs(tags) do
      for _, name_tag in ipairs(known_name_tags) do
        if key == name_tag or (key:find('^' .. name_tag .. ':') ~= nil) then
          name_tags[key] = value
          break
        end
      end
    end

    if tags.station then
      for station in string.gmatch(tags.station, '[^;]+') do
        stations:insert({
          way = object:as_point(),
          railway = tags['railway'],
          feature = feature,
          name = tags.name or tags.short_name,
          ref = tags.ref,
          station = station,
          railway_ref = tags['railway:ref'],
          uic_ref = tags['uic_ref'],
          name_tags = name_tags,
          operator = tags.operator,
          network = tags.network,
          wikidata = tags.wikidata,
          wikimedia_commons = wikimedia_commons,
          image = image,
          mapillary = tags.mapillary,
          wikipedia = tags.wikipedia,
          note = tags.note,
          description = tags.description,
        })
      end
    else
      stations:insert({
        way = object:as_point(),
        railway = tags['railway'],
        feature = feature,
        name = tags.name or tags.short_name,
        ref = tags.ref,
        station = nil,
        railway_ref = tags['railway:ref'],
        uic_ref = tags['uic_ref'],
        name_tags = name_tags,
        operator = tags.operator,
        network = tags.network,
        wikidata = tags.wikidata,
        wikimedia_commons = wikimedia_commons,
        image = image,
        mapillary = tags.mapillary,
        wikipedia = tags.wikipedia,
        note = tags.note,
        description = tags.description,
      })
    end
  end

  if railway_poi_values(tags.railway) then
    pois:insert({
      way = object:as_point(),
      railway = tags.railway,
      man_made = tags.man_made,
      crossing_light = tags['crossing:light'] and (tags['crossing:light'] ~= 'no'),
      crossing_barrier = tags['crossing:barrier'] and (tags['crossing:barrier'] ~= 'no'),
      wikidata = tags.wikidata,
      wikimedia_commons = wikimedia_commons,
      image = image,
      mapillary = tags.mapillary,
      wikipedia = tags.wikipedia,
      note = tags.note,
      description = tags.description,
    })
  end

  if tags.public_transport == 'stop_position' and tags.name then
    stop_positions:insert({
      way = object:as_point(),
      railway = tags.railway,
      name = tags.name,
    })
  end

  if tags.public_transport == 'platform' or tags.railway == 'platform' then
    platforms:insert({
      way = object:as_point(),
      name = tags.name,
    })
  end

  if tags.railway == 'subway_entrance' then
    subway_entrances:insert({
      way = object:as_point(),
      name = tags.name,
      wikidata = tags.wikidata,
      wikimedia_commons = wikimedia_commons,
      image = image,
      mapillary = tags.mapillary,
      wikipedia = tags.wikipedia,
      note = tags.note,
      description = tags.description,
    })
  end

  if railway_signal_values(tags.railway) then
    local ref_multiline, newline_count = (tags.ref or ''):gsub(' ', '\n')

    -- We cast the highest speed to text to make it possible to only select those speeds
    -- we have an icon for. Otherwise we might render an icon for 40 kph if
    -- 42 is tagged (but invalid tagging).
    local speed_limit_speed = tags['railway:signal:speed_limit'] and largest_speed_noconvert(tags['railway:signal:speed_limit:speed']) or tags['railway:signal:speed_limit:speed']
    local speed_limit_distant_speed = tags['railway:signal:speed_limit_distant'] and largest_speed_noconvert(tags['railway:signal:speed_limit_distant:speed']) or tags['railway:signal:speed_limit_distant:speed']

    local signal = {
      way = object:as_point(),
      railway = tags.railway,
      rank = tag_functions.signal_rank(tags),
      deactivated = tag_functions.signal_deactivated(tags),
      ref = tags.ref,
      ref_multiline = ref_multiline ~= '' and ref_multiline or nil,
      signal_direction = tags['railway:signal:direction'],
      signal_position = tags['railway:signal:position'],
      ["railway:signal:speed_limit:speed"] = speed_limit_speed,
      ["railway:signal:speed_limit_distant:speed"] = speed_limit_distant_speed,
      dominant_speed = speed_int(tostring(speed_limit_speed) or tostring(speed_limit_distant_speed)),
      caption = signal_caption(tags),
      wikidata = tags.wikidata,
      wikimedia_commons = wikimedia_commons,
      image = image,
      mapillary = tags.mapillary,
      wikipedia = tags.wikipedia,
      note = tags.note,
      description = tags.description,
    }

    for _, tag in ipairs(tag_functions.signal_tags) do
      if tag ~= 'railway:signal:speed_limit:speed' and tag ~= 'railway:signal:speed_limit_distant:speed' then
        signal[tag] = tags[tag]
      end
    end

    signals:insert(signal)
  end

  if railway_position_values(tags.railway) and (tags['railway:position'] or tags['railway:position:exact']) then
    railway_positions:insert({
      way = object:as_point(),
      railway = tags.railway,
      railway_position = strip_prefix(tags['railway:position'], 'mi:'),
      railway_position_exact = strip_prefix(tags['railway:position:exact'], 'mi:'),
      name = tags['name'],
      ref = tags['ref'],
      operator = tags['operator'],
      wikidata = tags.wikidata,
      wikimedia_commons = wikimedia_commons,
      image = image,
      mapillary = tags.mapillary,
      wikipedia = tags.wikipedia,
      note = tags.note,
      description = tags.description,
    })
  end

  if railway_switch_values(tags.railway) and tags.ref then
    railway_switches:insert({
      way = object:as_point(),
      railway = tags.railway,
      ref = tags.ref,
      type = tags['railway:switch'],
      turnout_side = tags['railway:turnout_side'],
      local_operated = tags['railway:local_operated'] == 'yes',
      resetting = tags['railway:switch:resetting'] == 'yes',
      wikidata = tags.wikidata,
      wikimedia_commons = wikimedia_commons,
      image = image,
      mapillary = tags.mapillary,
      wikipedia = tags.wikipedia,
      note = tags.note,
      description = tags.description,
    })
  end
end

local max_segment_length = 10000
local railway_values = osm2pgsql.make_check_values_func({'rail', 'tram', 'light_rail', 'subway', 'narrow_gauge', 'disused', 'abandoned', 'razed', 'construction', 'proposed', 'preserved', 'monorail', 'miniature'})
local railway_turntable_values = osm2pgsql.make_check_values_func({'turntable', 'traverser'})
function osm2pgsql.process_way(object)
  local tags = object.tags
  local wikimedia_commons, image = wikimedia_commons_or_image(tags.wikimedia_commons, tags.image)

  if railway_values(tags.railway) then
    local state, feature, usage, service, state_name, gauge, highspeed, rank = railway_line_state(tags)
    local railway_train_protection, railway_train_protection_rank = tag_functions.train_protection(tags, '')
    local train_protection_construction, train_protection_construction_rank = tag_functions.train_protection(tags, 'construction:')

    local current_electrification_state, voltage, frequency, future_voltage, future_frequency = electrification_state(tags)

    local tunnel = tags['tunnel'] and tags['tunnel'] ~= 'no' or false
    local bridge = tags['bridge'] and tags['bridge'] ~= 'no' or false
    local name = railway_line_name(state_name, tunnel, tags['tunnel:name'], bridge, tags['bridge:name'])

    local preferred_direction = tags['railway:preferred_direction']
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
        traffic_mode = tags['railway:traffic_mode'],
        radio = tags['railway:radio'],
        wikidata = tags.wikidata,
        wikimedia_commons = wikimedia_commons,
        image = image,
        mapillary = tags.mapillary,
        wikipedia = tags.wikipedia,
        note = tags.note,
        description = tags.description,
      })
    end
  end

  if tags.public_transport == 'platform' or tags.railway == 'platform' then
    platforms:insert({
      way = object:as_linestring():centroid(),
      name = tags.name,
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
    boxes:insert({
      way = polygon,
      center = polygon:centroid(),
      way_area = polygon:area(),
      feature = tags.railway,
      ref = tags['railway:ref'],
      name = tags.name,
      wikidata = tags.wikidata,
      wikimedia_commons = wikimedia_commons,
      image = image,
      mapillary = tags.mapillary,
      wikipedia = tags.wikipedia,
      note = tags.note,
      description = tags.description,
    })
  end

  if railway_poi_values(tags.railway) then
    pois:insert({
      way = object:as_polygon():centroid(),
      railway = tags.railway,
      man_made = tags.man_made,
      crossing_light = tags['crossing:light'] and (tags['crossing:light'] ~= 'no'),
      crossing_barrier = tags['crossing:barrier'] and (tags['crossing:barrier'] ~= 'no'),
      wikidata = tags.wikidata,
      wikimedia_commons = wikimedia_commons,
      image = image,
      mapillary = tags.mapillary,
      wikipedia = tags.wikipedia,
      note = tags.note,
      description = tags.description,
    })
  end
end

local route_values = osm2pgsql.make_check_values_func({'train', 'subway', 'tram', 'light_rail'})
local route_stop_relation_roles = osm2pgsql.make_check_values_func({'stop', 'station', 'stop_exit_only', 'stop_entry_only', 'forward_stop', 'backward_stop', 'forward:stop', 'backward:stop', 'stop_position', 'halt'})
local route_platform_relation_roles = osm2pgsql.make_check_values_func({'platform', 'platform_exit_only', 'platform_entry_only', 'forward:platform', 'backward:platform'})
function osm2pgsql.process_relation(object)
  local tags = object.tags

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
    local node_members = {}
    for _, member in ipairs(object.members) do
      if member.type == 'n' and member.role ~= 'stop' and member.role ~= 'platform' then
        table.insert(node_members, member.ref)
        has_members = true
      end
    end

    if has_members then
      stop_areas:insert({
        node_ref_ids = '{' .. table.concat(node_members, ',') .. '}',
      })
    end
  end
end
