package.path = package.path .. ";test/?.lua"

local assert = require('assert')

-- Global mock
require('mock_osm2psql')

local openrailwaymap = require('openrailwaymap')

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
    { name = 'name', type = 'train' },
  },
})

osm2pgsql.process_node({
  tags = {
    ['public_transport'] = 'stop_position',
    ['name'] = 'name',
    ['train'] = 'yes',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  stop_positions = {
    { name = 'name', type = 'train' },
  },
})

osm2pgsql.process_node({
  tags = {
    ['public_transport'] = 'stop_position',
    ['name'] = 'name',
    ['tram'] = 'yes',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  stop_positions = {
    { name = 'name', type = 'tram' },
  },
})

osm2pgsql.process_node({
  tags = {
    ['public_transport'] = 'stop_position',
    ['name'] = 'name',
    ['light_rail'] = 'yes',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  stop_positions = {
    { name = 'name', type = 'light_rail' },
  },
})

osm2pgsql.process_node({
  tags = {
    ['public_transport'] = 'stop_position',
    ['name'] = 'name',
    ['funicular'] = 'yes',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  stop_positions = {
    { name = 'name', type = 'funicular' },
  },
})

osm2pgsql.process_node({
  tags = {
    ['public_transport'] = 'stop_position',
    ['name'] = 'name',
    ['monorail'] = 'yes',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  stop_positions = {
    { name = 'name', type = 'monorail' },
  },
})

osm2pgsql.process_node({
  tags = {
    ['public_transport'] = 'stop_position',
    ['name'] = 'name',
    ['miniature'] = 'yes',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  stop_positions = {
    { name = 'name', type = 'miniature' },
  },
})

osm2pgsql.process_node({
  tags = {
    ['public_transport'] = 'stop_position',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {})

osm2pgsql.process_node({
  tags = {
    ['public_transport'] = 'stop_position',
    ['name'] = 'name',
    ['bus'] = 'yes',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {})

osm2pgsql.process_node({
  tags = {
    ['public_transport'] = 'stop_position',
    ['name'] = 'name',
    ['trolleybus'] = 'yes',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {})

osm2pgsql.process_node({
  tags = {
    ['public_transport'] = 'stop_position',
    ['name'] = 'name',
    ['share_taxi'] = 'yes',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {})

osm2pgsql.process_node({
  tags = {
    ['public_transport'] = 'stop_position',
    ['name'] = 'name',
    ['ferry'] = 'yes',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {})
