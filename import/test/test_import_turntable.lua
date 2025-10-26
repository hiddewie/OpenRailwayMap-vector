package.path = package.path .. ";test/?.lua"

local assert = require('assert')

-- Global mock
require('mock_osm2psql')

local openrailwaymap = require('openrailwaymap')

local way = {
  length = function () return 1 end,
}

-- Turntables

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'turntable',
  },
  as_polygon = function()
    return way
  end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  turntables = {
    { feature = 'turntable', way = way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'traverser',
  },
  as_polygon = function()
    return way
  end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  turntables = {
    { feature = 'traverser', way = way },
  },
})
