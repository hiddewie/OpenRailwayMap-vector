package.path = package.path .. ";test/?.lua"

local assert = require('assert')

-- Global mock
require('mock_osm2psql')

local openrailwaymap = require('openrailwaymap')

local way = {
  length = function () return 1 end,
}

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
    { feature = 'station', state = 'present', railway_ref = 'ref', operator = '{"operator"}', station = 'train', name_tags = { name = 'name' }, name = 'name' },
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
    ['railway'] = 'yard',
    ['railway:yard:purpose'] = 'transloading;manifest',
    ['railway:yard:hump'] = 'yes',
  },
  as_point = function () end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  stations = {
    { feature = 'yard', state = 'present', station = 'train', name_tags = {}, yard_hump = true, yard_purpose = '{"transloading","manifest"}' },
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

osm2pgsql.process_way({
  tags = {
    ['railway'] = 'station',
    name = 'name',
    ['railway:ref'] = 'ref',
    operator = 'operator',
  },
  is_closed = true,
  as_polygon = function () return way end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  stations = {
    { feature = 'station', state = 'present', railway_ref = 'ref', operator = '{"operator"}', station = 'train', name_tags = { name = 'name' }, name = 'name', way = way },
  },
})
