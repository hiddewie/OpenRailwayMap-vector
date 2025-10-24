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


-- Stop positions

osm2pgsql.process_node({
  tags = {
    ['public_transport'] = 'stop_position',
    ['name'] = 'name',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  stop_positions = {
    { name = 'name' },
  },
})

-- Platforms

osm2pgsql.process_node({
  tags = {
    ['railway'] = 'platform',
    ['name'] = 'name',
    ['ref'] = '1;2',
    ['height'] = '0.3',
    ['surface'] = 'concrete',
    ['elevator'] = 'yes',
    ['shelter'] = 'yes',
    ['lit'] = 'yes',
    ['bin'] = 'yes',
    ['bench'] = 'yes',
    ['wheelchair'] = 'yes',
    ['departures_board'] = 'yes',
    ['tactile_paving'] = 'yes',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  platforms = {
    { name = 'name', bench = true, shelter = true, elevator = true, departures_board = true, surface = 'concrete', height = '0.3', bin = true, ref = '{"1","2"}', tactile_paving = true, wheelchair = true, lit = true },
  },
})

osm2pgsql.process_node({
  tags = {
    ['public_transport'] = 'platform',
    ['train'] = 'yes',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  platforms = {
    { bench = false, shelter = false, elevator = false, departures_board = false, bin = false, tactile_paving = false, wheelchair = false, lit = false },
  },
})

osm2pgsql.process_node({
  tags = {
    ['public_transport'] = 'platform',
    ['tram'] = 'yes',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  platforms = {
    { bench = false, shelter = false, elevator = false, departures_board = false, bin = false, tactile_paving = false, wheelchair = false, lit = false },
  },
})

osm2pgsql.process_node({
  tags = {
    ['public_transport'] = 'platform',
    ['subway'] = 'yes',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  platforms = {
    { bench = false, shelter = false, elevator = false, departures_board = false, bin = false, tactile_paving = false, wheelchair = false, lit = false },
  },
})

osm2pgsql.process_node({
  tags = {
    ['public_transport'] = 'platform',
    ['light_rail'] = 'yes',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  platforms = {
    { bench = false, shelter = false, elevator = false, departures_board = false, bin = false, tactile_paving = false, wheelchair = false, lit = false },
  },
})

osm2pgsql.process_node({
  tags = {
    ['public_transport'] = 'platform',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  platforms = {
    { bench = false, shelter = false, elevator = false, departures_board = false, bin = false, tactile_paving = false, wheelchair = false, lit = false },
  },
})

osm2pgsql.process_node({
  tags = {
    ['public_transport'] = 'platform',
    ['bus'] = 'yes',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {})

osm2pgsql.process_node({
  tags = {
    ['public_transport'] = 'platform',
    ['trolleybus'] = 'yes',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {})

osm2pgsql.process_node({
  tags = {
    ['public_transport'] = 'platform',
    ['share_taxi'] = 'yes',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {})

osm2pgsql.process_node({
  tags = {
    ['public_transport'] = 'platform',
    ['ferry'] = 'yes',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {})

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

-- Catenary mast

osm2pgsql.process_node({
  tags = {
    ['power'] = 'catenary_mast',
    ['ref'] = '22',
    ['location:transition'] = 'yes',
    ['structure'] = 'structure',
    ['catenary_mast:supporting'] = 'supporting',
    ['catenary_mast:attachment'] = 'attachment',
    ['tensioning'] = 'tensioning',
    ['insulator'] = 'insulator',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  catenary = {
    { structure = 'structure', tensioning = 'tensioning', ref = '22', feature = 'mast', supporting = 'supporting', transition = true, insulator = 'insulator', attachment = 'attachment' },
  },
})
