package.path = package.path .. ";test/?.lua"

local assert = require('assert')

-- Global mock
require('mock_osm2psql')

local openrailwaymap = require('openrailwaymap')

-- Boxes

osm2pgsql.process_node({
  tags = {
    ['railway'] = 'signal_box',
    ['railway:position'] = '1.2',
    ['railway:position:exact'] = '1.2345',
    name = 'name',
    ['railway:ref'] = 'ref',
    operator = 'operator',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  boxes = {
    { way_area = 0, feature = 'signal_box', ref = 'ref', name = 'name', operator = 'operator', position = '{"1.2 @ 1.2345 (km)"}' },
  },
})

osm2pgsql.process_node({
  tags = {
    ['railway'] = 'crossing_box',
    ['railway:position'] = '1.2',
    ['railway:position:exact'] = '1.2345',
    name = 'name',
    ['railway:ref'] = 'ref',
    operator = 'operator',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  boxes = {
    { way_area = 0, feature = 'crossing_box', ref = 'ref', name = 'name', operator = 'operator', position = '{"1.2 @ 1.2345 (km)"}' },
  },
})

osm2pgsql.process_node({
  tags = {
    ['railway'] = 'blockpost',
    ['railway:position'] = '1.2',
    ['railway:position:exact'] = '1.2345',
    name = 'name',
    ['railway:ref'] = 'ref',
    operator = 'operator',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  boxes = {
    { way_area = 0, feature = 'blockpost', ref = 'ref', name = 'name', operator = 'operator', position = '{"1.2 @ 1.2345 (km)"}' },
  },
})

-- Stations

osm2pgsql.process_node({
  tags = {
    ['railway'] = 'station',
    name = 'name',
    ['railway:ref'] = 'ref',
    operator = 'operator',
  },
  as_point = function () end,
})

assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  stations = {
    { feature = 'station', state = 'present', railway_ref = 'ref', operator = 'operator', station = 'train', name_tags = { name = 'name' }, name = 'name' },
  },
})
osm2pgsql.process_node({
  tags = {
    ['railway'] = 'halt',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  stations = {
    { feature = 'halt', state = 'present', station = 'train', name_tags = {} },
  },
})

osm2pgsql.process_node({
  tags = {
    ['railway'] = 'tram_stop',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  stations = {
    { feature = 'tram_stop', state = 'present', station = 'tram', name_tags = {} },
  },
})

osm2pgsql.process_node({
  tags = {
    ['railway'] = 'service_station',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  stations = {
    { feature = 'service_station', state = 'present', station = 'train', name_tags = {} },
  },
})

osm2pgsql.process_node({
  tags = {
    ['preserved:railway'] = 'yard',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  stations = {
    { feature = 'yard', state = 'preserved', station = 'train', name_tags = {} },
  },
})

osm2pgsql.process_node({
  tags = {
    ['abandoned:railway'] = 'junction',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  stations = {
    { feature = 'junction', state = 'abandoned', station = 'train', name_tags = {} },
  },
})

osm2pgsql.process_node({
  tags = {
    ['disused:railway'] = 'spur_junction',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  stations = {
    { feature = 'spur_junction', state = 'disused', station = 'train', name_tags = {} },
  },
})

osm2pgsql.process_node({
  tags = {
    ['proposed:railway'] = 'crossover',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  stations = {
    { feature = 'crossover', state = 'proposed', station = 'train', name_tags = {} },
  },
})

osm2pgsql.process_node({
  tags = {
    ['construction:railway'] = 'site',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  stations = {
    { feature = 'site', state = 'construction', station = 'train', name_tags = {} },
  },
})

osm2pgsql.process_node({
  tags = {
    ['razed:railway'] = 'station',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {})

-- Places of interest

osm2pgsql.process_node({
  tags = {
    ['railway'] = 'border',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/border', rank = 1, layer = 'operator', minzoom = 10 },
  },
})

osm2pgsql.process_node({
  tags = {
    ['railway'] = 'owner_change',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/owner-change', rank = 2, layer = 'operator', minzoom = 12 },
  },
})

osm2pgsql.process_node({
  tags = {
    ['railway'] = 'radio',
    ['man_made'] = 'antenna',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/radio-antenna', rank = 3, layer = 'standard', minzoom = 12 },
  },
})

osm2pgsql.process_node({
  tags = {
    ['railway'] = 'radio',
    ['man_made'] = 'mast',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/radio-mast', rank = 4, layer = 'standard', minzoom = 12 },
  },
})

osm2pgsql.process_node({
  tags = {
    ['railway'] = 'radio',
    ['man_made'] = 'tower',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/radio-mast', rank = 4, layer = 'standard', minzoom = 12 },
  },
})

osm2pgsql.process_node({
  tags = {
    ['railway'] = 'container_terminal',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/container-terminal', rank = 5, layer = 'standard', minzoom = 12 },
  },
})

osm2pgsql.process_node({
  tags = {
    ['railway'] = 'ferry_terminal',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/ferry-terminal', rank = 6, layer = 'standard', minzoom = 12 },
  },
})

osm2pgsql.process_node({
  tags = {
    ['railway'] = 'lubricator',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/lubricator', rank = 7, layer = 'standard', minzoom = 13 },
  },
})

osm2pgsql.process_node({
  tags = {
    ['railway'] = 'fuel',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/fuel', rank = 8, layer = 'standard', minzoom = 13 },
  },
})

osm2pgsql.process_node({
  tags = {
    ['railway'] = 'sand_store',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/sand_store', rank = 9, layer = 'standard', minzoom = 13 },
  },
})

osm2pgsql.process_node({
  tags = {
    ['railway'] = 'defect_detector',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/defect_detector', rank = 10, layer = 'standard', minzoom = 13 },
  },
})

osm2pgsql.process_node({
  tags = {
    ['railway'] = 'aei',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/aei', rank = 11, layer = 'standard', minzoom = 13 },
  },
})

osm2pgsql.process_node({
  tags = {
    ['railway'] = 'hump_yard',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/hump_yard', rank = 12, layer = 'standard', minzoom = 13 },
  },
})

osm2pgsql.process_node({
  tags = {
    ['railway'] = 'loading_gauge',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/loading_gauge', rank = 13, layer = 'standard', minzoom = 13 },
  },
})

osm2pgsql.process_node({
  tags = {
    ['railway'] = 'preheating',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/preheating', rank = 14, layer = 'standard', minzoom = 13 },
  },
})

osm2pgsql.process_node({
  tags = {
    ['railway'] = 'compressed_air_supply',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/compressed_air_supply', rank = 15, layer = 'standard', minzoom = 13 },
  },
})

osm2pgsql.process_node({
  tags = {
    ['railway'] = 'waste_disposal',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/waste_disposal', rank = 16, layer = 'standard', minzoom = 13 },
  },
})

osm2pgsql.process_node({
  tags = {
    ['railway'] = 'coaling_facility',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/coaling_facility', rank = 17, layer = 'standard', minzoom = 13 },
  },
})

osm2pgsql.process_node({
  tags = {
    ['railway'] = 'wash',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  pois = {
    { feature = 'general/wash', rank = 18, layer = 'standard', minzoom = 13 },
  },
})

-- Milestones

osm2pgsql.process_node({
  tags = {
    ['railway'] = 'milestone',
    ['railway:position'] = '1.2',
    ['railway:position:exact'] = '1.2345',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  railway_positions = {
    { railway = 'milestone', position_text = '1.2', position_exact = '1.2345', zero = false, type = 'km', position_numeric = 1.2345 },
  },
})
