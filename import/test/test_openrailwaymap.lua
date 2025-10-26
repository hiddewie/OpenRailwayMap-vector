package.path = package.path .. ";test/?.lua"

local assert = require('assert')

-- Global mock
require('mock_osm2psql')

local openrailwaymap = require('openrailwaymap')

-- Parse single position
local position1, position1_exact, position1_line_positions = find_position_tags({
  ["railway:position"] = "123",
  ["railway:position:exact"] = "123.0",
  ["railway:position:exact:L123"] = "123.0",
  ["railway:position:exact:AA1"] = "1.0",
})
assert.eq(position1, "123")
assert.eq(position1_exact, "123.0")
assert.eq(position1_line_positions, {L123 = "123.0", AA1 = "1.0"})

local positions1 = parse_railway_positions("1.0", "1.05", {})
assert.eq(positions1, {{zero = true, numeric = 1.05, text = "1.0", type = "km", exact = "1.05"}})

local positions2 = parse_railway_positions("1.0", nil, {})
assert.eq(positions2, {{zero = true, numeric = 1.0, text = "1.0", type = "km", exact = nil}})

local positions3 = parse_railway_positions(nil, "1.05", {})
assert.eq(positions3, {{zero = false, numeric = 1.05, text = "1.05", type = "km", exact = nil}})

local positions4 = parse_railway_positions("1.05", "1.05", {L123 = "1.05"})
assert.eq(positions4, {{zero = false, numeric = 1.05, text = "1.05", type = "km", exact = "1.05", line = "L123"}})

local positions5 = parse_railway_positions("1.3", "1.05", {L123 = "1.05"})
assert.eq(positions5, {
  {zero = false, numeric = 1.3, text = "1.3", type = "km"},
  {zero = false, numeric = 1.05, text = "1.05", type = "km", exact = "1.05", line = "L123"},
})

assert.eq(position_is_zero(''), false)
assert.eq(position_is_zero('1'), true)
assert.eq(position_is_zero('1.0'), true)
assert.eq(position_is_zero('1.1'), false)
assert.eq(position_is_zero('0.9'), false)
assert.eq(position_is_zero('11.0'), true)
assert.eq(position_is_zero('-1.0'), true)
assert.eq(position_is_zero('1.'), true)
assert.eq(position_is_zero('0.0'), true)
assert.eq(position_is_zero('0.000'), true)
assert.eq(position_is_zero('0.001'), false)
assert.eq(position_is_zero('-0.001'), false)
assert.eq(position_is_zero('.01'), false)
assert.eq(position_is_zero('.00'), true)
