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
  },
  members = {
    -- stops
    { role = 'stop', ref = 1 },
    { role = 'station', ref = 2 },
    { role = 'stop_exit_only', ref = 3 },
    { role = 'stop_entry_only', ref = 4 },
    { role = 'forward_stop', ref = 5 },
    { role = 'backward_stop', ref = 6 },
    { role = 'forward:stop', ref = 7 },
    { role = 'backward:stop', ref = 8 },
    { role = 'stop_position', ref = 9 },
    { role = 'halt', ref = 10 },

    -- platforms
    { role = 'platform', ref = 11 },
    { role = 'platform_exit_only', ref = 12 },
    { role = 'platform_entry_only', ref = 13 },
    { role = 'forward:platform', ref = 14 },
    { role = 'backward:platform', ref = 15 },

    -- other, ignored
    { role = 'other', ref = 20 },
    { ref = 21 },
  },
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  routes = {
    { stop_ref_ids = '{1,2,3,4,5,6,7,8,9,10}', platform_ref_ids = '{11,12,13,14,15}' },
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
    { stop_ref_ids = '{1}', platform_ref_ids = '{}' },
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
    { stop_ref_ids = '{1}', platform_ref_ids = '{}' },
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
    { stop_ref_ids = '{1}', platform_ref_ids = '{}' },
  },
})
