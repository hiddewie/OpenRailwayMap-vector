package.path = package.path .. ";test/?.lua"

local assert = require('assert')

-- Global mock
require('mock_osm2psql')

local openrailwaymap = require('openrailwaymap')

-- Stop positions

osm2pgsql.process_node({
  tags = {
    ['public_transport'] = 'stop_position',
    ['name'] = 'name',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  stop_positions = {
    { name = 'name' },
  },
})
