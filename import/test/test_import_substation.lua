package.path = package.path .. ";test/?.lua"

local assert = require('assert')

-- Global mock
require('mock_osm2psql')

local openrailwaymap = require('openrailwaymap')

local way = {
  length = function () return 1 end,
}

-- Substation

osm2pgsql.process_way({
  tags = {
    ['power'] = 'substation',
  },
  as_polygon = function ()
    return way
  end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {})

osm2pgsql.process_way({
  tags = {
    ['power'] = 'substation',
    ['substation'] = 'traction',
    ['location'] = 'indoor',
    ['voltage'] = '400000;225000;63000',
    ['frequency'] = '50;0',
    ['name'] = 'name',
    ['ref'] = 'ref',
    ['operator'] = 'operator',
  },
  as_polygon = function ()
    return way
  end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  substation = {
    { feature = 'traction', location = 'indoor', voltage = '{400000,225000,63000}', frequency = '{50,0}', name = 'name', ref = 'ref', operator = 'operator', way = way },
  },
})

osm2pgsql.process_way({
  tags = {
    ['power'] = 'substation',
    ['substation'] = 'traction',
    ['voltage'] = '400000;750',
    ['frequency'] = '50;0',
  },
  as_polygon = function ()
    return way
  end,
})
assert.eq(osm2pgsql.get_and_clear_imported_data(), {
  substation = {
    { feature = 'traction', conversion = '400kV 50 Hz ⇒ 750V =', way = way },
  },
})
