package.path = package.path .. ";test/?.lua"

local assert = require('assert')

-- Global mock
require('mock_osm2psql')

local openrailwaymap = require('openrailwaymap')

local point_way = {}

local polygon_way = {
  centroid = function ()
    return point_way
  end,
  polygon = function () end,
  area = function () return 2.0 end,
}
local as_polygon_mock = function ()
  return polygon_way
end
local as_point_mock = function ()
  return point_way
end

-- Points of interest

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'border',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, way = point_way, center = point_way, feature = 'general/border', rank = 1, type = 'operator', minzoom = 10 },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'owner_change',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/owner-change', rank = 4, type = 'operator', minzoom = 12 },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'radio',
    ['man_made'] = 'antenna',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/radio-antenna', rank = 5, type = 'radio', minzoom = 12 },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'radio',
    ['man_made'] = 'mast',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/radio-mast', rank = 6, type = 'radio', minzoom = 12 },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'radio',
    ['man_made'] = 'tower',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/radio-mast', rank = 6, type = 'radio', minzoom = 12 },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'container_terminal',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/container-terminal', rank = 7, type = 'facility', minzoom = 12 },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'ferry_terminal',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/ferry-terminal', rank = 8, type = 'facility', minzoom = 12 },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'lubricator',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/lubricator', rank = 9, type = 'equipment', minzoom = 13 },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'fuel',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/fuel', rank = 10, type = 'equipment', minzoom = 13 },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'sand_store',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/sand_store', rank = 11, type = 'equipment', minzoom = 13 },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'defect_detector',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/defect_detector', rank = 12, type = 'equipment', minzoom = 13 },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'aei',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/aei', rank = 13, type = 'equipment', minzoom = 13 },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'hump_yard',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/hump_yard', rank = 14, type = 'facility', minzoom = 13 },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'loading_gauge',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/loading_gauge', rank = 15, type = 'equipment', minzoom = 13 },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'preheating',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/preheating', rank = 16, type = 'equipment', minzoom = 13 },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'compressed_air_supply',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/compressed_air_supply', rank = 17, type = 'equipment', minzoom = 13 },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'waste_disposal',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/waste_disposal', rank = 18, type = 'equipment', minzoom = 13 },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'coaling_facility',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/coaling_facility', rank = 19, type = 'facility', minzoom = 13 },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'wash',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/wash', rank = 20, type = 'facility', minzoom = 13 },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'water_crane',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/water_crane', rank = 21, type = 'facility', minzoom = 13 },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'water_tower',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/water_tower', rank = 22, type = 'facility', minzoom = 13 },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'workshop',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/workshop', rank = 23, type = 'facility', minzoom = 13 },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'engine_shed',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/engine_shed', rank = 24, type = 'facility', minzoom = 13 },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['tourism'] = 'museum',
    ['museum'] = 'railway',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/museum-rail-transport', rank = 25, type = 'facility', minzoom = 13 },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'museum',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/museum', rank = 26, type = 'facility', minzoom = 13 },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'power_supply',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/power_supply', rank = 27, type = 'equipment', minzoom = 13 },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'rolling_highway',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/rolling_highway', rank = 28, type = 'facility', minzoom = 13 },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'pit',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/pit', rank = 29, type = 'facility', minzoom = 13 },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'loading_rack',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/loading-rack', rank = 30, type = 'facility', minzoom = 13 },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'loading_ramp',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/loading-ramp', rank = 31, type = 'facility', minzoom = 13 },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'loading_tower',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/loading-tower', rank = 32, type = 'facility', minzoom = 13 },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'unloading_hole',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/unloading-hole', rank = 33, type = 'facility', minzoom = 13 },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'track_scale',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/track-scale', rank = 34, type = 'equipment', minzoom = 13 },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'carrier_truck_pit',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/carrier-truck-pit', rank = 35, type = 'equipment', minzoom = 13 },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'gauge_conversion',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/gauge-conversion', rank = 36, type = 'equipment', minzoom = 13 },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'car_shuttle',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/car-shuttle', rank = 37, type = 'facility', minzoom = 13 },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'car_dumper',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/car-dumper', rank = 38, type = 'equipment', minzoom = 13 },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'vacancy_detection',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/vacancy-detection-unknown', rank = 41, type = 'vacancy_detection', minzoom = 16 },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'vacancy_detection',
    ['railway:vacancy_detection'] = 'axle_counter',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/vacancy-detection-axle-counter', rank = 39, type = 'vacancy_detection', minzoom = 16 },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'vacancy_detection',
    ['railway:vacancy_detection'] = 'insulated_rail_joint',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/vacancy-detection-insulated-rail-joint', rank = 40, type = 'vacancy_detection', minzoom = 16 },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'isolated_track_section',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/isolated-track-section', rank = 42, type = 'electrical_equipment', minzoom = 14 },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'level_crossing',
    ['emergency:phone'] = '041/785302',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/level-crossing', rank = 46, type = 'level_crossing', minzoom = 15, emergency_phone = '041/785302' },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'level_crossing',
    ['crossing:light'] = 'yes',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/level-crossing-light', rank = 45, type = 'level_crossing', minzoom = 15 },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'level_crossing',
    ['crossing:barrier'] = 'yes',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/level-crossing-barrier', rank = 44, type = 'level_crossing', minzoom = 15 },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'level_crossing',
    ['crossing:light'] = 'yes',
    ['crossing:barrier'] = 'yes',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/level-crossing-light-barrier', rank = 43, type = 'level_crossing', minzoom = 15 },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'crossing',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/crossing', rank = 47, type = 'level_crossing', minzoom = 15 },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'hirail_access',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/hirail_access', rank = 48, type = 'facility', minzoom = 16 },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'phone',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/phone', rank = 49, type = 'equipment', minzoom = 16 },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'buffer_stop',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/buffer_stop', rank = 50, type = 'train_protection', minzoom = 16 },
  },
  signals = {
    { railway = 'buffer_stop', way = point_way },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'derail',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/derail', rank = 51, type = 'train_protection', minzoom = 16 },
  },
  signals = {
    { railway = 'derail', way = point_way },
  },
})

osm2pgsql.process_node({
  id = 123,
  type = 'node',
  tags = {
    ['railway'] = 'rail_brake',
  },
  as_point = as_point_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'node-123', way = point_way, center = point_way, feature = 'general/retarder', rank = 52, type = 'equipment', minzoom = 16 },
  },
})


-- Points of interest

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'border',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/border', rank = 1, type = 'operator', minzoom = 10 },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'turntable',
    ['diameter'] = '23m',
    ['operator'] = 'operator',
    ['note'] = 'note',
    ['description'] = 'description',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/turntable', diameter = '23m', rank = 2, type = 'facility', minzoom = 10, operator = 'operator', note = 'note', description = 'description' },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'traverser',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/traverser', rank = 3, type = 'facility', minzoom = 10 },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'owner_change',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/owner-change', rank = 4, type = 'operator', minzoom = 12 },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'radio',
    ['man_made'] = 'antenna',
    ['railway:radio'] = 'lte-r',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/radio-antenna', rank = 5, type = 'radio', minzoom = 12, radio = 'lte-r' },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'radio',
    ['man_made'] = 'mast',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/radio-mast', rank = 6, type = 'radio', minzoom = 12 },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'radio',
    ['man_made'] = 'tower',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/radio-mast', rank = 6, type = 'radio', minzoom = 12 },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'container_terminal',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/container-terminal', rank = 7, type = 'facility', minzoom = 12 },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'ferry_terminal',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/ferry-terminal', rank = 8, type = 'facility', minzoom = 12 },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'lubricator',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/lubricator', rank = 9, type = 'equipment', minzoom = 13 },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'fuel',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/fuel', rank = 10, type = 'equipment', minzoom = 13 },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'sand_store',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/sand_store', rank = 11, type = 'equipment', minzoom = 13 },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'defect_detector',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/defect_detector', rank = 12, type = 'equipment', minzoom = 13 },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'aei',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/aei', rank = 13, type = 'equipment', minzoom = 13 },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'hump_yard',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/hump_yard', rank = 14, type = 'facility', minzoom = 13 },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'loading_gauge',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/loading_gauge', rank = 15, type = 'equipment', minzoom = 13 },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'preheating',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/preheating', rank = 16, type = 'equipment', minzoom = 13 },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'compressed_air_supply',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/compressed_air_supply', rank = 17, type = 'equipment', minzoom = 13 },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'waste_disposal',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/waste_disposal', rank = 18, type = 'equipment', minzoom = 13 },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'coaling_facility',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/coaling_facility', rank = 19, type = 'facility', minzoom = 13 },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'wash',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/wash', rank = 20, type = 'facility', minzoom = 13 },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'water_crane',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/water_crane', rank = 21, type = 'facility', minzoom = 13 },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'water_tower',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/water_tower', rank = 22, type = 'facility', minzoom = 13 },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'workshop',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/workshop', rank = 23, type = 'facility', minzoom = 13 },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'engine_shed',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/engine_shed', rank = 24, type = 'facility', minzoom = 13 },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['tourism'] = 'museum',
    ['museum'] = 'railway',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/museum-rail-transport', rank = 25, type = 'facility', minzoom = 13 },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'museum',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/museum', rank = 26, type = 'facility', minzoom = 13 },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'power_supply',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/power_supply', rank = 27, type = 'equipment', minzoom = 13 },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'rolling_highway',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/rolling_highway', rank = 28, type = 'facility', minzoom = 13 },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'pit',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/pit', rank = 29, type = 'facility', minzoom = 13 },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'loading_rack',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/loading-rack', rank = 30, type = 'facility', minzoom = 13 },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'loading_ramp',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/loading-ramp', rank = 31, type = 'facility', minzoom = 13 },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'loading_tower',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/loading-tower', rank = 32, type = 'facility', minzoom = 13 },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'unloading_hole',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/unloading-hole', rank = 33, type = 'facility', minzoom = 13 },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'track_scale',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/track-scale', rank = 34, type = 'equipment', minzoom = 13 },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'carrier_truck_pit',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/carrier-truck-pit', rank = 35, type = 'equipment', minzoom = 13 },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'gauge_conversion',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/gauge-conversion', rank = 36, type = 'equipment', minzoom = 13 },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'car_shuttle',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/car-shuttle', rank = 37, type = 'facility', minzoom = 13 },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'car_dumper',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/car-dumper', rank = 38, type = 'equipment', minzoom = 13 },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'isolated_track_section',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/isolated-track-section', rank = 42, type = 'electrical_equipment', minzoom = 14 },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'level_crossing',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/level-crossing', rank = 46, type = 'level_crossing', minzoom = 15 },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'level_crossing',
    ['crossing:light'] = 'yes',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/level-crossing-light', rank = 45, type = 'level_crossing', minzoom = 15 },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'level_crossing',
    ['crossing:barrier'] = 'yes',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/level-crossing-barrier', rank = 44, type = 'level_crossing', minzoom = 15 },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'level_crossing',
    ['crossing:light'] = 'yes',
    ['crossing:barrier'] = 'yes',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/level-crossing-light-barrier', rank = 43, type = 'level_crossing', minzoom = 15 },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'crossing',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/crossing', rank = 47, type = 'level_crossing', minzoom = 15 },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'hirail_access',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/hirail_access', rank = 48, type = 'facility', minzoom = 16 },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'phone',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/phone', rank = 49, type = 'equipment', minzoom = 16 },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'buffer_stop',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/buffer_stop', rank = 50, type = 'train_protection', minzoom = 16 },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'derail',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/derail', rank = 51, type = 'train_protection', minzoom = 16 },
  },
})

osm2pgsql.process_way({
  id = 123,
  type = 'way',
  tags = {
    ['railway'] = 'rail_brake',
  },
  as_polygon = as_polygon_mock,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { id = 'way-123', way = polygon_way, center = point_way, feature = 'general/retarder', rank = 52, type = 'equipment', minzoom = 16 },
  },
})
