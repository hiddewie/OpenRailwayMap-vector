package.path = package.path .. ";test/?.lua"

local assert = require('assert')

-- Global mock
require('mock_osm2psql')

local openrailwaymap = require('openrailwaymap')

-- Switches

osm2pgsql.process_node({
  tags = {
    ['railway'] = 'switch',
    ['ref'] = '22',
    ['railway:switch'] = 'curved',
    ['railway:local_operated'] = 'yes',
    ['railway:switch:resetting'] = 'yes',
    ['railway:turnout_side'] = 'right',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  railway_switches = {
    { railway = 'switch' , ref = '22', type = 'curved', turnout_side = 'right', local_operated = true, resetting = true },
  },
})

osm2pgsql.process_node({
  tags = {
    ['railway'] = 'railway_crossing',
    ['ref'] = '22',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  railway_switches = {
    { railway = 'railway_crossing' , ref = '22', resetting = false, local_operated = false },
  },
})
