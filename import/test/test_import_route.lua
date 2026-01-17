package.path = package.path .. ";test/?.lua"

local assert = require('assert')

-- Global mock
require('mock_osm2psql')

local openrailwaymap = require('openrailwaymap')

local polygon_way = {
  centroid = function () end,
  polygon = function () end,
  area = function () return 2.0 end,
}
local as_polygon_mock = function ()
  return {
    centroid = function ()
      return polygon_way
    end,
    transform = function ()
      return polygon_way
    end
  }
end

-- Routes

osm2pgsql.process_relation({
  tags = {
    ['type'] = 'route',
    ['route'] = 'train',
  },
  members = {},
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {})

osm2pgsql.process_relation({
  tags = {
    ['type'] = 'route',
    ['route'] = 'train',
    ['from'] = 'Driebergen-Zeist',
    ['to'] = 'Uitgeest',
    ['name'] = '7400: Driebergen-Zeist - Uitgeest',
    ['ref'] = '7400',
    ['colour'] = 'orange',
    ['operator'] = 'Nederlandse Spoorwegen',
    ['brand'] = 'Sprinter',
  },
  members = {
    -- stops
    { role = 'stop', ref = 1, type = 'n' },
    { role = 'station', ref = 2, type = 'n' },
    { role = 'stop_exit_only', ref = 3, type = 'n' },
    { role = 'stop_entry_only', ref = 4, type = 'n' },
    { role = 'forward_stop', ref = 5, type = 'n' },
    { role = 'backward_stop', ref = 6, type = 'n' },
    { role = 'forward:stop', ref = 7, type = 'n' },
    { role = 'backward:stop', ref = 8, type = 'n' },
    { role = 'stop_position', ref = 9, type = 'n' },
    { role = 'halt', ref = 10, type = 'n' },

    -- platforms
    { role = 'platform', ref = 11, type = 'w' },
    { role = 'platform_exit_only', ref = 12, type = 'w' },
    { role = 'platform_entry_only', ref = 13, type = 'w' },
    { role = 'forward:platform', ref = 14, type = 'w' },
    { role = 'backward:platform', ref = 15, type = 'w' },

    -- ways
    { ref = 20, type = 'w' },
    { role = '', ref = 21, type = 'w' },

    -- other, ignored
    { role = 'other', ref = 30, type = 'n' },
    { role = 'other', ref = 31, type = 'w' },
    { role = 'other', ref = 32, type = 'r' },
    { ref = 33, type = 'n' },
    { ref = 34, type = 'r' },
  },
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  routes = {
    { type = 'train', from = 'Driebergen-Zeist', to = 'Uitgeest', name = '7400: Driebergen-Zeist - Uitgeest', ref = '7400', color = 'orange', operator = 'Nederlandse Spoorwegen', brand = 'Sprinter', platform_ref_ids = '{11,12,13,14,15}' },
  },
  route_line = {
    { line_id = 20 },
    { line_id = 21 },
  },
  route_stop = {
    { stop_id = 1 },
    { stop_id = 2 },
    { stop_id = 3, role = 'stop_exit_only' },
    { stop_id = 4, role = 'stop_entry_only' },
    { stop_id = 5 },
    { stop_id = 6 },
    { stop_id = 7 },
    { stop_id = 8 },
    { stop_id = 9 },
    { stop_id = 10 },
  },
})

osm2pgsql.process_relation({
  tags = {
    ['type'] = 'route',
    ['route'] = 'subway',
  },
  members = {
    { role = 'stop', ref = 1 },
  },
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  routes = {
    { type = 'subway', platform_ref_ids = '{}' },
  },
  route_stop = {
    { stop_id = 1 },
  },
})

osm2pgsql.process_relation({
  tags = {
    ['type'] = 'route',
    ['route'] = 'tram',
  },
  members = {
    { role = 'stop', ref = 1 },
  },
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  routes = {
    { type = 'tram', platform_ref_ids = '{}' },
  },
  route_stop = {
    { stop_id = 1 },
  },
})

osm2pgsql.process_relation({
  tags = {
    ['type'] = 'route',
    ['route'] = 'light_rail',
  },
  members = {
    { role = 'stop', ref = 1 },
  },
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  routes = {
    { type = 'light_rail', platform_ref_ids = '{}' },
  },
  route_stop = {
    { stop_id = 1 },
  },
})
