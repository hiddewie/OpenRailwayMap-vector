package.path = package.path .. ";test/?.lua"

local assert = require('assert')

-- Global mock
require('mock_osm2psql')

local openrailwaymap = require('openrailwaymap')

local way = {
  length = function () return 1 end,
}

-- Platforms

osm2pgsql.process_way({
  tags = {
    ['public_transport'] = 'platform',
  },
  as_polygon = function()
    return way
  end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  platforms = {
    { bench = false, shelter = false, elevator = false, departures_board = false, bin = false, tactile_paving = false, wheelchair = false, lit = false, way = way },
  },
})

-- Platform edge

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'platform_edge',
    ['ref'] = '4',
    ['height'] = '0.4',
    ['tactile_paving'] = 'yes',
  },
  as_linestring = function ()
    return way
  end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  platform_edge = {
    { ref = '4', height = '0.4', tactile_paving = true, way = way },
  },
})
