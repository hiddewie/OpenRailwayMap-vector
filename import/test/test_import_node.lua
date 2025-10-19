package.path = package.path .. ";test/?.lua"

local assert = require('assert')

-- Global mock
require('mock_osm2psql')

local openrailwaymap = require('openrailwaymap')

local node = {
  tags = {
    ['railway'] = 'milestone',
    ['railway:position'] = '1.2',
    ['railway:position:exact'] = '1.2345',
  },
  as_point = function () end,
}
osm2pgsql.process_node(node)
local imported = osm2pgsql.get_and_clear_imported_data()
assert.eq(imported, {
  railway_positions = {
    { railway = 'milestone', position_text = '1.2', position_exact = '1.2345', zero = false, type = 'km', position_numeric = 1.2345}
  },
})
