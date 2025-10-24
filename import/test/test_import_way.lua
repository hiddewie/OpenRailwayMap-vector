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
    centroid = function ()
      return polygon_way
    end,
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

-- Places of interest

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'border',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/border', rank = 1, layer = 'operator', minzoom = 10, way = polygon_way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'owner_change',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/owner-change', rank = 2, layer = 'operator', minzoom = 12, way = polygon_way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'radio',
    ['man_made'] = 'antenna',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/radio-antenna', rank = 3, layer = 'standard', minzoom = 12, way = polygon_way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'radio',
    ['man_made'] = 'mast',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/radio-mast', rank = 4, layer = 'standard', minzoom = 12, way = polygon_way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'radio',
    ['man_made'] = 'tower',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/radio-mast', rank = 4, layer = 'standard', minzoom = 12, way = polygon_way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'container_terminal',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/container-terminal', rank = 5, layer = 'standard', minzoom = 12, way = polygon_way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'ferry_terminal',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/ferry-terminal', rank = 6, layer = 'standard', minzoom = 12, way = polygon_way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'lubricator',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/lubricator', rank = 7, layer = 'standard', minzoom = 13, way = polygon_way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'fuel',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/fuel', rank = 8, layer = 'standard', minzoom = 13, way = polygon_way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'sand_store',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/sand_store', rank = 9, layer = 'standard', minzoom = 13, way = polygon_way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'defect_detector',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/defect_detector', rank = 10, layer = 'standard', minzoom = 13, way = polygon_way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'aei',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/aei', rank = 11, layer = 'standard', minzoom = 13, way = polygon_way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'hump_yard',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/hump_yard', rank = 12, layer = 'standard', minzoom = 13, way = polygon_way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'loading_gauge',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/loading_gauge', rank = 13, layer = 'standard', minzoom = 13, way = polygon_way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'preheating',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/preheating', rank = 14, layer = 'standard', minzoom = 13, way = polygon_way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'compressed_air_supply',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/compressed_air_supply', rank = 15, layer = 'standard', minzoom = 13, way = polygon_way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'waste_disposal',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/waste_disposal', rank = 16, layer = 'standard', minzoom = 13, way = polygon_way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'coaling_facility',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/coaling_facility', rank = 17, layer = 'standard', minzoom = 13, way = polygon_way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'wash',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/wash', rank = 18, layer = 'standard', minzoom = 13, way = polygon_way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'water_crane',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/water_crane', rank = 19, layer = 'standard', minzoom = 13, way = polygon_way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'water_tower',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/water_tower', rank = 20, layer = 'standard', minzoom = 13, way = polygon_way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'workshop',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/workshop', rank = 21, layer = 'standard', minzoom = 13, way = polygon_way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'engine_shed',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/engine_shed', rank = 22, layer = 'standard', minzoom = 13, way = polygon_way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['tourism'] = 'museum',
    ['museum'] = 'railway',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/museum-rail-transport', rank = 23, layer = 'standard', minzoom = 13, way = polygon_way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'museum',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/museum', rank = 24, layer = 'standard', minzoom = 13, way = polygon_way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'power_supply',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/power_supply', rank = 25, layer = 'electrification', minzoom = 13, way = polygon_way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'rolling_highway',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/rolling_highway', rank = 26, layer = 'standard', minzoom = 13, way = polygon_way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'pit',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/pit', rank = 27, layer = 'standard', minzoom = 13, way = polygon_way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'loading_rack',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/loading-rack', rank = 28, layer = 'standard', minzoom = 13, way = polygon_way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'loading_ramp',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/loading-ramp', rank = 29, layer = 'standard', minzoom = 13, way = polygon_way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'loading_tower',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/loading-tower', rank = 30, layer = 'standard', minzoom = 13, way = polygon_way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'unloading_hole',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/unloading-hole', rank = 31, layer = 'standard', minzoom = 13, way = polygon_way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'track_scale',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/track-scale', rank = 32, layer = 'standard', minzoom = 13, way = polygon_way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'carrier_truck_pit',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/carrier-truck-pit', rank = 33, layer = 'standard', minzoom = 13, way = polygon_way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'gauge_conversion',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/gauge-conversion', rank = 34, layer = 'standard', minzoom = 13, way = polygon_way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'car_shuttle',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/car-shuttle', rank = 35, layer = 'standard', minzoom = 13, way = polygon_way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'car_dumper',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/car-dumper', rank = 36, layer = 'standard', minzoom = 13, way = polygon_way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'isolated_track_section',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/isolated-track-section', rank = 37, layer = 'electrification', minzoom = 14, way = polygon_way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'level_crossing',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/level-crossing', rank = 41, layer = 'standard', minzoom = 15, way = polygon_way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'level_crossing',
    ['crossing:light'] = 'yes',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/level-crossing-light', rank = 40, layer = 'standard', minzoom = 15, way = polygon_way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'level_crossing',
    ['crossing:barrier'] = 'yes',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/level-crossing-barrier', rank = 39, layer = 'standard', minzoom = 15, way = polygon_way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'level_crossing',
    ['crossing:light'] = 'yes',
    ['crossing:barrier'] = 'yes',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/level-crossing-light-barrier', rank = 38, layer = 'standard', minzoom = 15, way = polygon_way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'crossing',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/crossing', rank = 42, layer = 'standard', minzoom = 15, way = polygon_way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'hirail_access',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/hirail_access', rank = 43, layer = 'standard', minzoom = 16, way = polygon_way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'phone',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/phone', rank = 44, layer = 'standard', minzoom = 16, way = polygon_way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'buffer_stop',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/buffer_stop', rank = 45, layer = 'standard', minzoom = 16, way = polygon_way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'derail',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/derail', rank = 46, layer = 'standard', minzoom = 16, way = polygon_way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'rail_brake',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/retarder', rank = 47, layer = 'standard', minzoom = 16, way = polygon_way },
  },
})

-- Catenary

osm2pgsql.process_way({
  tags = {
    ['power'] = 'catenary_portal',
    ['ref'] = '22',
    ['location:transition'] = 'yes',
    ['structure'] = 'structure',
    ['tensioning'] = 'tensioning',
    ['insulator'] = 'insulator',
  },
  as_linestring = function ()
    return way
  end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  catenary = {
    { structure = 'structure', tensioning = 'tensioning', ref = '22', feature = 'portal', transition = true, insulator = 'insulator', way = way },
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
