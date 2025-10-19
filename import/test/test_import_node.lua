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
