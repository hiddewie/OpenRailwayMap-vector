package.path = package.path .. ";test/?.lua"

local assert = require('assert')

-- Global mock
require('mock_osm2psql')

local openrailwaymap = require('openrailwaymap')

-- Entrances

osm2pgsql.process_node({
  tags = {
    ['railway'] = 'subway_entrance',
    ['name'] = 'name',
    ['ref'] = '47',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  station_entrances = {
    { type = 'subway', name = 'name', ref = '47' },
  },
})

osm2pgsql.process_node({
  tags = {
    ['railway'] = 'train_station_entrance',
    ['name'] = 'name',
    ['ref'] = '47',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  station_entrances = {
    { type = 'train', name = 'name', ref = '47' },
  },
})
