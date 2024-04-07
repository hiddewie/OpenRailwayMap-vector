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

local railway_line = osm2pgsql.define_table({
  name = 'railway_line',
  ids = { type = 'way', id_column = 'osm_id' },
  columns = {
    { column = 'way', type = 'linestring' },
    { column = 'railway', type = 'text' },
    -- TODO build feature column
    { column = 'feature', type = 'text' },
    { column = 'service', type = 'text' },
    { column = 'usage', type = 'text' },
    { column = 'highspeed', type = 'boolean' },
    { column = 'layer', type = 'text' },
    { column = 'ref', type = 'text' },
    { column = 'track_ref', type = 'text' },
    { column = 'name', type = 'text' },
    { column = 'construction', type = 'text' },
    { column = 'tunnel', type = 'text' },
    { column = 'tunnel_name', type = 'text' },
    { column = 'bridge', type = 'text' },
    { column = 'bridge_name', type = 'text' },
    { column = 'maxspeed', type = 'text' },
    { column = 'maxspeed_forward', type = 'text' },
    { column = 'maxspeed_backward', type = 'text' },
    { column = 'preferred_direction', type = 'text' },
    { column = 'electrified', type = 'text' },
    { column = 'deelectrified', type = 'text' },
    { column = 'frequency', type = 'text' },
    { column = 'voltage', type = 'text' },
    { column = 'gauge', type = 'text' },
    { column = 'construction_railway', type = 'text' },
    { column = 'construction_electrified', type = 'text' },
    { column = 'construction_frequency', type = 'text' },
    { column = 'construction_voltage', type = 'text' },
    { column = 'construction_gauge', type = 'text' },
    { column = 'proposed_railway', type = 'text' },
    { column = 'proposed_electrified', type = 'text' },
    { column = 'proposed_frequency', type = 'text' },
    { column = 'proposed_voltage', type = 'text' },
    { column = 'disused_railway', type = 'text' },
    { column = 'abandoned_railway', type = 'text' },
    { column = 'abandoned_name', type = 'text' },
    { column = 'abandoned_electrified', type = 'text' },
    { column = 'razed_railway', type = 'text' },
    { column = 'razed_name', type = 'text' },
    { column = 'preserved_railway', type = 'text' },
    { column = 'train_protection', type = 'text' },
    { column = 'train_protection_rank', type = 'smallint' },
  },
})

local pois = osm2pgsql.define_table({
  name = 'pois',
  ids = { type = 'node', id_column = 'osm_id' },
  columns = {
    { column = 'way', type = 'point' },
    { column = 'railway', type = 'text' },
    { column = 'man_made', type = 'text' },
  },
})

local stations = osm2pgsql.define_table({
  name = 'stations',
  ids = { type = 'node', id_column = 'osm_id' },
  columns = {
    { column = 'way', type = 'point' },
    { column = 'railway', type = 'text' },
    { column = 'name', type = 'text' },
    { column = 'station', type = 'text' },
    { column = 'label', type = 'text' },
  },
})

local stop_positions = osm2pgsql.define_table({
  name = 'stop_positions',
  ids = { type = 'node', id_column = 'osm_id' },
  columns = {
    { column = 'way', type = 'point' },
    { column = 'name', type = 'text' },
  },
})

local platforms = osm2pgsql.define_table({
  name = 'platforms',
  ids = { type = 'any', id_column = 'osm_id' },
  columns = {
    { column = 'way', type = 'point' },
    { column = 'name', type = 'text' },
  },
})

local signals = osm2pgsql.define_table({
  name = 'signals',
  ids = { type = 'node', id_column = 'osm_id' },
  columns = {
    { column = 'way', type = 'point' },
    { column = 'railway', type = 'text' },
    { column = 'feature', type = 'text' },
    { column = 'rank', type = 'smallint' },
    { column = 'deactivated', type = 'boolean' },
    { column = 'ref', type = 'text' },
    { column = 'ref_multiline', type = 'text' },
    { column = 'ref_width', type = 'smallint' },
    { column = 'ref_height', type = 'smallint' },
    { column = 'signal_direction', type = 'text' },
    { column = 'wrong_road', type = 'text' },
    { column = 'wrong_road_form', type = 'text' },
    { column = 'combined_form', type = 'text' },
    { column = 'main_form', type = 'text' },
    { column = 'distant_form', type = 'text' },
    { column = 'train_protection_form', type = 'text' },
    { column = 'main_repeated_form', type = 'text' },
    { column = 'minor_form', type = 'text' },
    { column = 'passing_form', type = 'text' },
    { column = 'shunting_form', type = 'text' },
    { column = 'stop_form', type = 'text' },
    { column = 'stop_demand_form', type = 'text' },
    { column = 'station_distant_form', type = 'text' },
    { column = 'crossing_form', type = 'text' },
    { column = 'departure_form', type = 'text' },
    { column = 'speed_limit_form', type = 'text' },
    { column = 'main_height', type = 'text' },
    { column = 'minor_height', type = 'text' },
    { column = 'combined_states', type = 'text' },
    { column = 'main_states', type = 'text' },
    { column = 'distant_states', type = 'text' },
    { column = 'minor_states', type = 'text' },
    { column = 'shunting_states', type = 'text' },
    { column = 'main_repeated_states', type = 'text' },
    { column = 'speed_limit_states', type = 'text' },
    { column = 'distant_repeated', type = 'text' },
    { column = 'crossing_repeated', type = 'text' },
    { column = 'combined_shortened', type = 'text' },
    { column = 'distant_shortened', type = 'text' },
    { column = 'crossing_distant_shortened', type = 'text' },
    { column = 'crossing_shortened', type = 'text' },
    { column = 'ring_only_transit', type = 'text' },
    { column = 'whistle_only_transit', type = 'text' },
    { column = 'train_protection_type', type = 'text' },
    { column = 'passing_type', type = 'text' },
    { column = 'train_protection_shape', type = 'text' },
    { column = 'signal_speed_limit', type = 'text' },
    { column = 'signal_speed_limit_form', type = 'text' },
    { column = 'signal_speed_limit_speed', type = 'text' },
    { column = 'signal_speed_limit_distant', type = 'text' },
    { column = 'signal_speed_limit_distant_form', type = 'text' },
    { column = 'signal_speed_limit_distant_speed', type = 'text' },
    { column = 'signal_electricity', type = 'text'},
    { column = 'electricity_form', type = 'text'},
    { column = 'electricity_turn_direction', type = 'text'},
    { column = 'electricity_type', type = 'text'},
    { column = 'resetting_switch_form', type = 'text'},
    { column = 'resetting_switch_distant_form', type = 'text'},
  },
})

local signal_boxes = osm2pgsql.define_table({
  name = 'signal_boxes',
  ids = { type = 'any', id_column = 'osm_id' },
  columns = {
    { column = 'way', type = 'geometry' },
    { column = 'way_area', type = 'real' },
    { column = 'ref', type = 'text' },
    { column = 'name', type = 'text' },
  },
})

local turntables = osm2pgsql.define_table({
  name = 'turntables',
  ids = { type = 'way', id_column = 'osm_id' },
  columns = {
    { column = 'way', type = 'polygon' },
  },
})

local railway_positions = osm2pgsql.define_table({
  name = 'railway_positions',
  ids = { type = 'node', id_column = 'osm_id' },
  columns = {
    { column = 'way', type = 'point' },
    { column = 'railway', type = 'text' },
    { column = 'railway_position', type = 'text' },
    { column = 'railway_position_detail', type = 'text' },
  },
})

local railway_switches = osm2pgsql.define_table({
  name = 'railway_switches',
  ids = { type = 'node', id_column = 'osm_id' },
  columns = {
    { column = 'way', type = 'point' },
    { column = 'railway', type = 'text' },
    { column = 'ref', type = 'text' },
    { column = 'railway_local_operated', type = 'text' },
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

-- Set a value to 'no' if it is null or 0.
function railway_null_or_zero_to_no(value)
  if value == '0' or (not value) then
    return 'no'
  else
    return value
  end
end

-- Get rank by train protection a track is equipped with
-- Other code expects 1 for no protection, 0 for default/unknown
function train_protection(tags)
  if railway_null_or_zero_to_no(tags['railway:ptc']) ~= 'no' then return 'ptc', 13 end
  if railway_null_or_zero_to_no(tags['railway:etcs']) ~= 'no' then return 'etcs', 12 end
  if railway_null_or_zero_to_no(tags['construction:railway:etcs']) ~= 'no' then return 'construction_etcs', 11 end
  if tags['railway:asfa'] == 'yes' then return 'asfa', 10 end
  if tags['railway:scmt'] == 'yes' then return 'scmt', 9 end
  if railway_null_or_zero_to_no(tags['railway:tvm']) ~= 'no' then return 'tvm', 8 end
  if tags['railway:kvb'] == 'yes' then return 'kvb', 7 end
  if tags['railway:atc'] == 'yes' then return 'atc', 6 end
  if (tags['railway:atb'] or tags['railway:atb-eg'] or tags['railway:atb-ng'] or tags['railway:atb-vv']) == 'yes' then return 'atb', 5 end
  if tags['railway:zsi127'] == 'yes' then return 'zsi127', 4 end
  if tags['railway:lzb'] == 'yes' then return 'lzb', 3 end
  if tags['railway:pzb'] == 'yes' then return 'pzb', 2 end

  if (tags['railway:pzb'] == 'no' and tags['railway:lzb'] == 'no' and tags['railway:etcs'] == 'no')
    or (tags['railway:atb'] == 'no' and tags['railway:etcs'] == 'no')
    or (tags['railway:atc'] == 'no' and tags['railway:etcs'] == 'no')
    or (tags['railway:scmt'] == 'no' and tags['railway:etcs'] == 'no')
    or (tags['railway:asfa'] == 'no' and tags['railway:etcs'] == 'no')
    or (tags['railway:kvb'] == 'no' and tags['railway:tvm'] == 'no' and tags['railway:etcs'] == 'no')
    or (tags['railway:zsi127'] == 'no') then
    return 'other', 1
  end

  return nil, 0
end

-- TODO clean up unneeded tags

local railway_station_values = osm2pgsql.make_check_values_func({'station', 'halt', 'tram_stop', 'service_station', 'yard', 'junction', 'spur_junction', 'crossover', 'site', 'tram_stop'})
local railway_poi_values = osm2pgsql.make_check_values_func({'crossing', 'level_crossing', 'phone', 'tram_stop', 'border', 'owner_change', 'radio'})
-- TODO, include derail?
local railway_signal_values = osm2pgsql.make_check_values_func({'signal', 'buffer_stop'})
local railway_position_values = osm2pgsql.make_check_values_func({'milestone', 'level_crossing', 'crossing'})
local railway_switch_values = osm2pgsql.make_check_values_func({'switch', 'railway_crossing'})
function osm2pgsql.process_node(object)
  local tags = object.tags

  if tags.railway == 'signal_box' then
    signal_boxes:insert({
      way = object:as_point(),
      way_area = 0,
      ref = tags['railway:ref'],
      name = tags.name,
    })
  end

  if railway_station_values(tags.railway) then
    if tags.station then
      for station in string.gmatch(tags.station, '[^;]+') do
        stations:insert({
          way = object:as_point(),
          railway = tags.railway,
          name = tags.short_name or tags.name,
          station = station,
          label = tags['railway:ref'],
        })
      end
    else
      stations:insert({
        way = object:as_point(),
        railway = tags.railway,
        name = tags.short_name or tags.name,
        station = nil,
        label = tags['railway:ref'],
      })
    end
  end

  if railway_poi_values(tags.railway) then
    pois:insert({
      way = object:as_point(),
      railway = tags.railway,
      man_made = tags.man_made,
    })
  end

  if tags.public_transport == 'stop_position' then
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

  if railway_signal_values(tags.railway) then
    local feature = (
      tags['railway:signal:combined'] or
      tags['railway:signal:main'] or
      tags['railway:signal:distant'] or
      tags['railway:signal:train_protection'] or
      tags['railway:signal:main_repeated'] or
      tags['railway:signal:minor'] or
      tags['railway:signal:passing'] or
      tags['railway:signal:shunting'] or
      tags['railway:signal:stop'] or
      tags['railway:signal:stop_demand'] or
      tags['railway:signal:station_distant'] or
      tags['railway:signal:crossing_distant'] or
      tags['railway:signal:crossing'] or
      tags['railway:signal:ring'] or
      tags['railway:signal:whistle'] or
      tags['railway:signal:departure'] or
      tags['railway:signal:main_repeated'] or
      tags['railway:signal:humping'] or
      tags['railway:signal:speed_limit'] or
      tags['railway:signal:resetting_switch'] or
      tags['railway:signal:resetting_switch_distant']
    )
    local rank = (
      (tags['railway:signal:main'] and 10000) or
      (tags['railway:signal:combined'] and 10000) or
      (tags['railway:signal:distant'] and 9000) or
      (tags['railway:signal:train_protection'] and 8500) or
      (tags['railway:signal:main_repeated'] and 8000) or
      (tags['railway:signal:minor'] and 4000) or
      (tags['railway:signal:passing'] and 3500) or
      (tags['railway:signal:shunting'] and 3000) or
      (tags['railway:signal:stop'] and 1000) or
      (tags['railway:signal:stop_demand'] and 900) or
      (tags['railway:signal:station_distant'] and 550) or
      (tags['railway:signal:crossing'] and 1000) or
      (tags['railway:signal:crossing_distant'] and 500) or
      (tags['railway:signal:ring'] and 500) or
      (tags['railway:signal:whistle'] and 500) or
      (tags['railway:signal:departure'] and 400) or
      (tags['railway:signal:resetting_switch'] and 300) or
      (tags['railway:signal:resetting_switch_distant'] and 200) or
      0
    )
    local deactivated = (
      tags['railway:signal:combined:deactivated'] or
      tags['railway:signal:main:deactivated'] or
      tags['railway:signal:distant:deactivated'] or
      tags['railway:signal:train_protection:deactivated'] or
      tags['railway:signal:main_repeated:deactivated'] or
      tags['railway:signal:minor:deactivated'] or
      tags['railway:signal:passing:deactivated'] or
      tags['railway:signal:shunting:deactivated'] or
      tags['railway:signal:stop:deactivated'] or
      tags['railway:signal:stop_demand:deactivated'] or
      tags['railway:signal:station_distant:deactivated'] or
      tags['railway:signal:crossing_distant:deactivated'] or
      tags['railway:signal:crossing:deactivated'] or
      tags['railway:signal:ring:deactivated'] or
      tags['railway:signal:whistle:deactivated'] or
      tags['railway:signal:departure:deactivated'] or
      tags['railway:signal:main_repeated:deactivated'] or
      tags['railway:signal:humping:deactivated'] or
      tags['railway:signal:speed_limit:deactivated']
    ) == 'yes'
    local ref_multiline, newline_count = (tags.ref or ''):gsub(' ', '\n')
    local ref_height = newline_count + 1
    local ref_width = 0
    for part in string.gmatch(tags.ref or '', '[^ ]+') do
      ref_width = math.max(ref_width, part:len())
    end

    signals:insert({
      way = object:as_point(),
      railway = tags.railway,
      feature = feature,
      rank = rank,
      deactivated = deactivated,
      ref = tags.ref,
      ref_multiline = ref_multiline ~= '' and ref_multiline or nil,
      ref_height = ref_multiline ~= '' and ref_height or nil,
      ref_width = ref_multiline ~= '' and ref_width or nil,
      signal_direction = tags['railway:signal:direction'],
      wrong_road = tags['railway:signal:wrong_road'],
      wrong_road_form = tags['railway:signal:wrong_road:form'],
      combined_form = tags['railway:signal:combined:form'],
      main_form = tags['railway:signal:main:form'],
      distant_form = tags['railway:signal:distant:form'],
      train_protection_form = tags['railway:signal:train_protection:form'],
      main_repeated_form = tags['railway:signal:main_repeated:form'],
      minor_form = tags['railway:signal:minor:form'],
      passing_form = tags['railway:signal:passing:form'],
      shunting_form = tags['railway:signal:shunting:form'],
      stop_form = tags['railway:signal:stop:form'],
      stop_demand_form = tags['railway:signal:stop_demand:form'],
      station_distant_form = tags['railway:signal:station:distant:form'],
      crossing_form = tags['railway:signal:crossing:form'],
      departure_form = tags['railway:signal:departure:form'],
      speed_limit_form = tags['railway:signal:speed_limit:form'],
      main_height = tags['railway:signal:main:height'],
      minor_height = tags['railway:signal:minor:height'],
      combined_states = tags['railway:signal:combined:states'],
      main_states = tags['railway:signal:main:states'],
      distant_states = tags['railway:signal:distant:states'],
      minor_states = tags['railway:signal:minor:states'],
      shunting_states = tags['railway:signal:shunting:states'],
      main_repeated_states = tags['railway:signal:main_repeated:states'],
      speed_limit_states = tags['railway:signal:speed_limit:states'],
      distant_repeated = tags['railway:signal:distant:repeated'],
      crossing_repeated = tags['railway:signal:crossing:repeated'],
      combined_shortened = tags['railway:signal:combined:shortened'],
      distant_shortened = tags['railway:signal:distant:shortened'],
      crossing_distant_shortened = tags['railway:signal:crossing_distant:shortened'],
      crossing_shortened = tags['railway:signal:crossing:shortened'],
      ring_only_transit = tags['railway:signal:ring:only_transit'],
      whistle_only_transit = tags['railway:signal:whistle:only_transit'],
      train_protection_type = tags['railway:signal:train_protection:type'],
      passing_type = tags['railway:signal:passing:type'],
      train_protection_shape = tags['railway:signal:train_protection:shape'],
      signal_speed_limit = tags['railway:signal:speed_limit'],
      signal_speed_limit_form = tags['railway:signal:speed_limit:form'],
      signal_speed_limit_speed = tags['railway:signal:speed_limit:speed'],
      signal_speed_limit_distant = tags['railway:signal:speed_limit_distant'],
      signal_speed_limit_distant_form = tags['railway:signal:speed_limit_distant:form'],
      signal_speed_limit_distant_speed = tags['railway:signal:speed_limit_distant:speed'],
      signal_electricity = tags['railway:signal:electricity'],
      electricity_form = tags['railway:signal:electricity:form'],
      electricity_turn_direction = tags['railway:signal:electricity:turn_direction'],
      electricity_type = tags['railway:signal:electricity:type'],
      resetting_switch_form = tags['railway:signal:resetting_switch:form'],
      resetting_switch_distant_form = tags['railway:signal:resetting_switch_distant:form'],
    })
  end

  if railway_position_values(tags.railway) and (tags['railway:position'] or tags['railway:position:detail']) then
    railway_positions:insert({
      way = object:as_point(),
      railway = tags.railway,
      railway_position = tags['railway:position'],
      railway_position_detail = tags['railway:position:detail'],
    })
  end

  if railway_switch_values(tags.railway) and tags.ref then
    railway_switches:insert({
      way = object:as_point(),
      railway = tags.railway,
      ref = tags.ref,
      railway_local_operated = tags['railway:local_operated'], -- TODO make boolean
    })
  end
end

local railway_values = osm2pgsql.make_check_values_func({'rail', 'tram', 'light_rail', 'subway', 'narrow_gauge', 'construction', 'preserved', 'monorail', 'miniature'})
local railway_turntable_values = osm2pgsql.make_check_values_func({'turntable', 'traverser'})
function osm2pgsql.process_way(object)
  local tags = object.tags

  if railway_values(tags.railway) then
    local railway_train_protection, railway_train_protection_rank = train_protection(tags)

    railway_line:insert({
      way = object:as_linestring(),
      railway = tags['railway'],
      service = tags['service'],
      usage = tags['usage'],
      highspeed = tags['highspeed'] == 'yes',
      layer = tags['layer'],
      ref = tags['ref'],
      track_ref = tags['railway:track_ref'],
      name = tags['name'],
      public_transport = tags['public_transport'],
      construction = tags['construction'],
      tunnel = tags['tunnel'],
      tunnel_name = tags['tunnel_name'],
      bridge = tags['bridge'],
      bridge_name = tags['bridge'],
      maxspeed = tags['maxspeed'],
      maxspeed_forward = tags['maxspeed:forward'],
      maxspeed_backward = tags['maxspeed:backward'],
      preferred_direction = tags['railway:preferred_direction'],
      electrified = tags['electrified'],
      deelectrified = tags['deelectrified'],
      frequency = tags['frequency'],
      voltage = tags['voltage'],
      gauge = tags['gauge'],
      construction_railway = tags['construction:railway'],
      construction_electrified = tags['construction:electrified'],
      construction_frequency = tags['construction:frequency'],
      construction_voltage = tags['construction:voltage'],
      construction_gauge = tags['construction:gauge'],
      proposed_railway = tags['proposed:railway'],
      proposed_electrified = tags['proposed:electrified'],
      proposed_frequency = tags['proposed:frequency'],
      proposed_voltage = tags['proposed:voltage'],
      disused_railway = tags['disused:railway'],
      abandoned_railway = tags['abandoned:railway'],
      abandoned_name = tags['abandoned:name'],
      abandoned_electrified = tags['abandoned:electrified'],
      razed_railway = tags['razed:railway'],
      razed_name = tags['razed:name'],
      preserved_railway = tags['preserved:railway'],
      train_protection = railway_train_protection,
      train_protection_rank = railway_train_protection_rank,
    })
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
    })
  end

  if tags.railway == 'signal_box' then
    local polygon = object:as_polygon():transform(3857)
    signal_boxes:insert({
      way = polygon,
      way_area = polygon:area(),
      ref = tags['railway:ref'],
      name = tags.name,
    })
  end
end

local route_values = osm2pgsql.make_check_values_func({'train', 'subway', 'tram', 'light_rail'})
local route_stop_relation_roles = osm2pgsql.make_check_values_func({'stop', 'station', 'stop_exit_only', 'stop_entry_only', 'forward_stop', 'backward_stop', 'forward:stop', 'backward:stop', 'stop_position', 'halt'})
local route_platform_relation_roles = osm2pgsql.make_check_values_func({'platform', 'platform_exit_only', 'platform_entry_only', 'forward:platform', 'backward:platform'})
function osm2pgsql.process_relation(object)
  local tags = object.tags

  if tags.type == 'route' and route_values(tags.route) then
    local stop_members = {}
    local platform_members = {}
    for _, member in ipairs(object.members) do
      if route_stop_relation_roles(member.role) then
        table.insert(stop_members, member.ref)
      end

      if route_platform_relation_roles(member.role) then
        table.insert(platform_members, member.ref)
      end
    end

    if (#stop_members > 0) or (#platform_members > 0) then
      routes:insert({
        stop_ref_ids = '{' .. table.concat(stop_members, ',') .. '}',
        platform_ref_ids = '{' .. table.concat(platform_members, ',') .. '}',
      })
    end
  end
end
