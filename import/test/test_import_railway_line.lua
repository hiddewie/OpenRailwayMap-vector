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
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'rail',
    ['railway:radio'] = 'lte-r',
  },
  as_linestring = as_linestring_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  railway_line = {
    { id = '123-0', tunnel = false, bridge = false, highspeed = false, rank = 40, way_length = 1, way = way, feature = 'rail', state = 'present', radio = 'lte-r' },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'rail',
    ['railway:aws'] = 'yes',
    ['railway:tpws'] = 'yes',
    ['construction:railway:etcs'] = '3',
  },
  as_linestring = as_linestring_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  railway_line = {
    { id = '123-0', tunnel = false, bridge = false, highspeed = false, rank = 40, way_length = 1, way = way, feature = 'rail', state = 'present', train_protection = '{"aws","tpws"}', train_protection_rank = 33, train_protection_construction = 'etcs_2', train_protection_construction_rank = 66 },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'rail',
    ['railway:ktcs'] = '2',
    ['railway:etcs'] = '2',
  },
  as_linestring = as_linestring_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  railway_line = {
    { id = '123-0', tunnel = false, bridge = false, highspeed = false, rank = 40, way_length = 1, way = way, feature = 'rail', state = 'present', train_protection = '{"ktcs"}', train_protection_rank = 71 },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'rail',
    ['railway:acses'] = 'yes',
    ['railway:atc'] = 'yes',
    ['railway:ptc'] = 'yes',
  },
  as_linestring = as_linestring_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  railway_line = {
    { id = '123-0', tunnel = false, bridge = false, highspeed = false, rank = 40, way_length = 1, way = way, feature = 'rail', state = 'present', train_protection = '{"acses","atc"}', train_protection_rank = 65 },
  },
})
