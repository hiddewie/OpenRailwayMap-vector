package.path = package.path .. ";test/?.lua"

local assert = require('assert')

-- Global mock
require('mock_osm2psql')

local openrailwaymap = require('openrailwaymap')

local way = {
  length = function () return 1 end,
}
local as_linestring_mock = function ()
  return {
    centroid = function ()
      return way
    end
  }
end

-- Stations

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'station',
    name = 'name',
    ['railway:ref'] = 'ref',
    operator = 'operator',
  },
  as_linestring = as_linestring_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  stations = {
    { feature = 'station', state = 'present', railway_ref = 'ref', operator = 'operator', station = 'train', name_tags = { name = 'name' }, name = 'name', way = way },
  },
})
