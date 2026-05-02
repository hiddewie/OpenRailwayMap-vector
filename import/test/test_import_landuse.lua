package.path = package.path .. ";test/?.lua"

local assert = require('assert')

-- Global mock
require('mock_osm2psql')

local openrailwaymap = require('openrailwaymap')

local way = {
  length = function () return 1 end,
}

-- Landuse

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    landuse = 'railway',
  },
  as_polygon = function () return way end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  landuse = {
    { id = 'way-123', way = way },
  },
})

osm2pgsql.process_relation({
  id = 123,
  type = 'relation',
  tags = {
    landuse = 'railway',
  },
  as_multipolygon = function () return way end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  landuse = {
    { id = 'relation-123', way = way },
  },
})
