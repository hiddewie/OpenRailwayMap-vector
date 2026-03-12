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

-- Stop areas

osm2pgsql.process_relation({
  tags = {
    ['type'] = 'public_transport',
    ['public_transport'] = 'stop_area',
  },
  members = {},
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {})

osm2pgsql.process_relation({
  tags = {
    ['type'] = 'public_transport',
    ['public_transport'] = 'stop_area',
  },
  members = {
    { role = 'stop', type = 'n', ref = 1 },
    { role = 'platform', type = 'n', ref = 2 },
    { role = 'platform', type = 'w', ref = 3 },
    { role = 'platform', type = 'r', ref = 4 },
    { type = 'n', ref = 5 },
    { type = 'w', ref = 6 },
  },
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  stop_areas = {
    { way_ref_ids = '{6}', node_ref_ids = '{5}', references = {} },
  },
  stop_area_platforms = {
    { platform_id = 2 },
    { platform_id = 3 },
    { platform_id = 4 },
  },
  stop_area_route_stops = {
    { route_stop_id = 1 },
  },
})

osm2pgsql.process_relation({
  tags = {
    ['type'] = 'public_transport',
    ['public_transport'] = 'stop_area',
    ['ref:SE:rikshållplats'] = 'rikshållplats'
  },
  members = {
    { role = 'stop', type = 'n', ref = 1 },
  },
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  stop_areas = {
    { way_ref_ids = '{}', node_ref_ids = '{}', references = {['se-rikshållplats'] = 'rikshållplats'} },
  },
  stop_area_route_stops = {
    { route_stop_id = 1 },
  },
})

-- Stop area groups

osm2pgsql.process_relation({
  tags = {
    ['type'] = 'public_transport',
    ['public_transport'] = 'stop_area_group',
  },
  members = {},
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {})

osm2pgsql.process_relation({
  tags = {
    ['type'] = 'public_transport',
    ['public_transport'] = 'stop_area_group',
  },
  members = {
    { type = 'n', ref = 1 },
    { type = 'w', ref = 2 },
    { type = 'r', ref = 3 },
    { type = 'r', ref = 4 },
  },
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  stop_area_groups = {
    { stop_area_ref_ids = '{3,4}' },
  },
})
