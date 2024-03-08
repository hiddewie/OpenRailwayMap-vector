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

local openrailwaymap_osm_line = osm2pgsql.define_table({
  name = 'openrailwaymap_osm_line',
  ids = { type = 'way', id_column = 'osm_id' },
  columns = {
    { column = 'way', type = 'linestring' },
    { column = 'railway', type = 'text' },
    { column = 'feature', type = 'text' },
    { column = 'service', type = 'text' },
    { column = 'usage', type = 'text' },
    { column = 'highspeed', type = 'text' },
    { column = 'layer', type = 'text' },
    { column = 'ref', type = 'text' },
    { column = 'name', type = 'text' },
    { column = 'public_transport', type = 'text' },
    { column = 'construction', type = 'text' },
    { column = 'tunnel', type = 'text' },
    { column = 'bridge', type = 'text' },
    { column = 'maxspeed', type = 'text' },
    { column = 'maxspeed_forward', type = 'text' },
    { column = 'maxspeed_backward', type = 'text' },
    { column = 'preferred_direction', type = 'text' },
    { column = 'electrified', type = 'text' },
    { column = 'frequency', type = 'text' },
    { column = 'voltage', type = 'text' },
    { column = 'construction_electrified', type = 'text' },
    { column = 'construction_frequency', type = 'text' },
    { column = 'construction_voltage', type = 'text' },
    { column = 'proposed_electrified', type = 'text' },
    { column = 'proposed_frequency', type = 'text' },
    { column = 'proposed_voltage', type = 'text' },
    { column = 'deelectrified', type = 'text' },
    { column = 'abandoned_electrified', type = 'text' },
    { column = 'tags', type = 'hstore' },
  },
})

local openrailwaymap_osm_polygon = osm2pgsql.define_table({
  name = 'openrailwaymap_osm_polygon',
  ids = { type = 'way', id_column = 'osm_id' },
  columns = {
    { column = 'way', type = 'polygon' },
    { column = 'railway', type = 'text' },
    { column = 'public_transport', type = 'text' },
    { column = 'name', type = 'text' },
    { column = 'way_area', type = 'area' },
    { column = 'tags', type = 'hstore' },
  },
})

local openrailwaymap_osm_point = osm2pgsql.define_table({
  name = 'openrailwaymap_osm_point',
  ids = { type = 'node', id_column = 'osm_id' },
  columns = {
    { column = 'way', type = 'point' },
    { column = 'railway', type = 'text' },
    { column = 'ref', type = 'text' },
    { column = 'name', type = 'text' },
    { column = 'man_made', type = 'text' },
    { column = "railway_position", type = "text" },
    { column = "railway_position_detail", type = "text" },
    { column = "public_transport", type = "text" },
    { column = "signal_direction", type = "text" },
    { column = "signal_speed_limit", type = "text" },
    { column = "signal_speed_limit_form", type = "text" },
    { column = "signal_speed_limit_speed", type = "text" },
    { column = "signal_speed_limit_distant", type = "text" },
    { column = "signal_speed_limit_distant_form", type = "text" },
    { column = "signal_speed_limit_distant_speed", type = "text" },
    { column = "railway_local_operated", type = "text" },
    { column = 'tags', type = 'hstore' },
  },
})

local openrailwaymap_osm_signals = osm2pgsql.define_table({
  name = 'openrailwaymap_osm_signals',
  ids = { type = 'node', id_column = 'osm_id' },
  columns = {
    { column = 'way', type = 'point' },
    { column = 'railway', type = 'text' },
    { column = 'ref', type = 'text' },
    { column = 'signal_direction', type = 'text' },
    { column = 'tags', type = 'hstore' },
  },
})

local signal_boxes = osm2pgsql.define_table({
  name = 'signal_boxes',
  ids = { type = 'any', id_column = 'osm_id' },
  columns = {
    { column = 'way', type = 'geometry' },
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

local railway_point_values = osm2pgsql.make_check_values_func({'station', 'halt', 'tram_stop', 'service_station', 'yard', 'junction', 'spur_junction', 'crossover', 'site', 'tram_stop'})
  -- TODO, include derail?
local railway_signal_values = osm2pgsql.make_check_values_func({'signal', 'buffer_stop'})
local railway_position_values = osm2pgsql.make_check_values_func({'milestone', 'level_crossing', 'crossing'})
function osm2pgsql.process_node(object)
  local tags = object.tags

  if tags.railway == 'signal_box' then
    signal_boxes:insert({
      way = object:as_point(),
      ref = tags['railway:ref'],
      name = tags.name,
    })
  end

  if railway_point_values(tags.railway) then
    openrailwaymap_osm_point:insert({
      way = object:as_point(),
      railway = tags.railway,
      public_transport = tags.public_transport,
      name = tags.name,
      tags = tags,
    })
  end

  if railway_signal_values(tags.railway) then
    openrailwaymap_osm_signals:insert({
      way = object:as_point(),
      railway = tags.railway,
      ref = tags.ref,
      signal_direction = tags['railway:signal:direction'],
      tags = tags,
    })
  end

  if railway_position_values(tags.railway) then
    railway_positions:insert({
      way = object:as_point(),
      railway = tags.railway,
      railway_position = tags['railway:position'],
      railway_position_detail = tags['railway:position:detail'],
    })
  end
end

local railway_values = osm2pgsql.make_check_values_func({'rail', 'tram', 'light_rail', 'subway', 'narrow_gauge', 'construction', 'preserved', 'monorail', 'miniature'})
local railway_turntable_values = osm2pgsql.make_check_values_func({'turntable', 'traverser'})
function osm2pgsql.process_way(object)
  local tags = object.tags

  if railway_values(tags.railway) then
    openrailwaymap_osm_line:insert({
      way = object:as_linestring(),
      railway = tags['railway'],
      service = tags['service'],
      usage = tags['usage'],
      highspeed = tags['highspeed'],
      layer = tags['layer'],
      ref = tags['ref'],
      name = tags['name'],
      public_transport = tags['public_transport'],
      construction = tags['construction'],
      tunnel = tags['tunnel'],
      bridge = tags['bridge'],
      maxspeed = tags['maxspeed'],
      maxspeed_forward = tags['maxspeed:forward'],
      maxspeed_backward = tags['maxspeed:backward'],
      preferred_direction = tags['railway:preferred_direction'],
      electrified = tags['electrified'],
      frequency = tags['frequency'],
      voltage = tags['voltage'],
      construction_electrified = tags['construction:electrified'],
      construction_frequency = tags['construction:frequency'],
      construction_voltage = tags['construction:voltage'],
      proposed_electrified = tags['proposed:electrified'],
      proposed_frequency = tags['proposed:frequency'],
      proposed_voltage = tags['proposed:voltage'],
      deelectrified = tags['deelectrified'],
      abandoned_electrified = tags['abandoned:electrified'],
      tags = tags,
    })
  end

  -- TODO route relations
  if tags.public_transport == 'platform' or tags.railway == 'platform' then
    openrailwaymap_osm_polygon:insert({
      way = object:as_polygon(),
      railway = tags.railway,
      public_transport = tags.public_transport,
      name = tags.name,
      tags = tags,
    })
  end

  if railway_turntable_values(tags.railway) then
    turntables:insert({
      way = object:as_polygon(),
    })
  end

  if tags.railway == 'signal_box' then
    signal_boxes:insert({
      way = object:as_polygon(),
      ref = tags['railway:ref'],
      name = tags.name,
    })
  end
end

function osm2pgsql.process_relation(object)
  -- Ignored

  -- TODO route relations
end