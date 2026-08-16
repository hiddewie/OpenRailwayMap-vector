package.path = package.path .. ";test/?.lua"

local assert = require('assert')

-- Global mock
require('mock_osm2psql')

local openrailwaymap = require('openrailwaymap')

osm2pgsql.process_relation({
  tags = {
    ['type'] = 'railway',
    ['railway'] = 'interlocking',
    ['name'] = "Shaw's Cove Interlocking",
    ['railway:ref'] = 'SHAWS',
  },
  members = {
    { role = 'switch', type = 'n', ref = 1 },
    { role = 'switch', type = 'w', ref = 2 },
    { role = 'switch', type = 'r', ref = 3 },
    { role = 'signal_box', type = 'n', ref = 4 },
    { role = 'signal_box', type = 'w', ref = 5 },
    { role = 'signal_box', type = 'r', ref = 6 },
    { role = 'landuse', type = 'n', ref = 7 },
    { role = 'landuse', type = 'w', ref = 8 },
    { role = 'landuse', type = 'r', ref = 9 },
    { type = 'n', ref = 10 },
    { type = 'w', ref = 11 },
    { type = 'r', ref = 12 },
    { role = 'signal', type = 'n', ref = 13 },
    { role = 'signal', type = 'w', ref = 14 },
    { role = 'signal', type = 'r', ref = 15 },
    { role = 'facility', type = 'n', ref = 16 },
    { role = 'facility', type = 'w', ref = 17 },
    { role = 'facility', type = 'r', ref = 18 },
  },
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  interlocking = {
    { feature = 'interlocking', name = "Shaw's Cove Interlocking", name_tags = {name = "Shaw's Cove Interlocking"}, references = {['railway-ref'] = 'SHAWS'} },
  },
  interlocking_switch = {
    { switch_id = 1 },
  },
  interlocking_landuse = {
    { landuse_id = 'way-8' },
    { landuse_id = 'relation-9' },
  },
  interlocking_signal_box = {
    { signal_box_id = 'node-4' },
    { signal_box_id = 'way-5' },
  },
  interlocking_signal = {
    { signal_id = 13 },
  },
  interlocking_facility = {
    { facility_id = 'node-16' },
    { facility_id = 'way-17' },
  },
})
