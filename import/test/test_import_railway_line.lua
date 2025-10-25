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
    transform = function ()
      return {
        segmentize = function ()
          return {
            geometries = function ()
              first = true
              return function ()
                if first then
                  first = false
                  return way
                else
                  return nil
                end
              end
            end
          }
        end
      }
    end,
  }
end

-- Railway lines

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'rail',
  },
  as_linestring = as_linestring_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  railway_line = {
    { tunnel = false, bridge = false, highspeed = false, rank = 40, train_protection_rank = 0, way_length = 1, way = way, feature = 'rail', state = 'present', train_protection_construction_rank = 0 },
  },
})
