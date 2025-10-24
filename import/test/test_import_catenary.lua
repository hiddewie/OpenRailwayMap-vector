package.path = package.path .. ";test/?.lua"

local assert = require('assert')

-- Global mock
require('mock_osm2psql')

local openrailwaymap = require('openrailwaymap')

local way = {
  length = function () return 1 end,
}

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

-- Catenary portal

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
