package.path = package.path .. ";test/?.lua"

local assert = require('assert')

-- Global mock
require('mock_osm2psql')

local openrailwaymap = require('openrailwaymap')

-- Railway lines

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
    centroid = function ()
      return way
    end
  }
end
local polygon_way = {
  centroid = function () end,
  polygon = function () end,
  area = function () return 2.0 end,
}
local as_polygon_mock = function ()
  return {
    transform = function ()
      return polygon_way
    end
  }
end

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

-- Boxes

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'signal_box',
    ['railway:position'] = '1.2',
    ['railway:position:exact'] = '1.2345',
    name = 'name',
    ['railway:ref'] = 'ref',
    operator = 'operator',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  boxes = {
    { way_area = 2.0, feature = 'signal_box', ref = 'ref', name = 'name', operator = 'operator', position = '{"1.2 @ 1.2345 (km)"}', way = polygon_way },
  },
})
