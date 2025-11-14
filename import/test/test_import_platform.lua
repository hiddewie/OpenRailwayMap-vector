package.path = package.path .. ";test/?.lua"

local assert = require('assert')

-- Global mock
require('mock_osm2psql')

local openrailwaymap = require('openrailwaymap')

local way = {
  length = function () return 1 end,
}

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

osm2pgsql.process_way({
  tags = {
    ['public_transport'] = 'platform',
  },
  is_closed = true,
  as_polygon = function()
    return way
  end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  platforms = {
    { bench = false, shelter = false, elevator = false, departures_board = false, bin = false, tactile_paving = false, wheelchair = false, lit = false, way = way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['public_transport'] = 'platform',
  },
  is_closed = false,
  as_linestring = function()
    return way
  end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  platforms = {
    { bench = false, shelter = false, elevator = false, departures_board = false, bin = false, tactile_paving = false, wheelchair = false, lit = false, way = way },
  },
})

osm2pgsql.process_relation({
  tags = {
    ['public_transport'] = 'platform',
  },
  as_multipolygon = function()
    return way
  end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  platforms = {
    { bench = false, shelter = false, elevator = false, departures_board = false, bin = false, tactile_paving = false, wheelchair = false, lit = false, way = way },
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
