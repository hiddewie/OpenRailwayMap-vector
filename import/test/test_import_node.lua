package.path = package.path .. ";test/?.lua"

local assert = require('assert')

-- Global mock
osm2pgsql = require('mock_osm2psql')

local openrailwaymap = require('openrailwaymap')


local node = {
  tags = {
    ['railway'] = 'milestone',
    ['railway:position'] = '1.2',
    ['railway:position:exact'] = '1.2345',
  }
}
openrailwaymap.process_node(node)
local imported = osm2pgsql.get_and_clear_imported_data()
assert.eq(imported, {})
