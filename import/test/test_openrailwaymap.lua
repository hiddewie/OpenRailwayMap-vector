package.path = package.path .. ";test/?.lua"

-- Global mock
osm2pgsql = require('mock_osm2psql')

local openrailwaymap = require('openrailwaymap')

function assert_eq(actual, expected)
  if type(expected) == 'table' then
    if type(actual) ~= 'table' then
      error("Expected table " .. dump(expected) .. ", got " .. dump(actual))
    else
      for k, v in pairs(expected) do
        if expected[k] and not actual[k] then
          error("Expected key " .. k .. ", but actual does not contain key (expected " .. dump(expected) .. ", got " .. dump(actual) .. ")")
        else
          assert_eq(actual[k], expected[k])
        end
      end

      for k, v in pairs(actual) do
        if actual[k] and not expected[k] then
          error("Actual has key " .. k .. ", but expected does not contain key (expected " .. dump(expected) .. ", got " .. dump(actual) .. ")")
        else
          assert_eq(actual[k], expected[k])
        end
      end
    end
  else
    if expected ~= actual then
      error("Expected " .. dump(expected) .. ", got " .. dump(actual))
    end
  end
end

-- Parse single position
local position1, position1_exact, position1_line_positions = find_position_tags({
  ["railway:position"] = "123",
  ["railway:position:exact"] = "123.0",
  ["railway:position:exact:L123"] = "123.0",
  ["railway:position:exact:AA1"] = "1.0",
})
assert_eq(position1, "123")
assert_eq(position1_exact, "123.0")
assert_eq(position1_line_positions, {L123 = "123.0", AA1 = "1.0"})

local positions1 = parse_railway_positions("1.0", "1.05", {})
assert_eq(positions1, {{zero = true, numeric = 1.05, text = "1.0", type = "km", exact = "1.05"}})

local positions2 = parse_railway_positions("1.0", nil, {})
assert_eq(positions2, {{zero = true, numeric = 1.0, text = "1.0", type = "km", exact = nil}})

local positions3 = parse_railway_positions(nil, "1.05", {})
assert_eq(positions3, {{zero = false, numeric = 1.05, text = "1.05", type = "km", exact = nil}})

local positions4 = parse_railway_positions("1.05", "1.05", {L123 = "1.05"})
assert_eq(positions4, {{zero = false, numeric = 1.05, text = "1.05", type = "km", exact = "1.05", line = "L123"}})

local positions5 = parse_railway_positions("1.3", "1.05", {L123 = "1.05"})
assert_eq(positions5, {
  {zero = false, numeric = 1.3, text = "1.3", type = "km"},
  {zero = false, numeric = 1.05, text = "1.05", type = "km", exact = "1.05", line = "L123"},
})

assert_eq(position_is_zero(''), false)
assert_eq(position_is_zero('1'), true)
assert_eq(position_is_zero('1.0'), true)
assert_eq(position_is_zero('1.1'), false)
assert_eq(position_is_zero('0.9'), false)
assert_eq(position_is_zero('11.0'), true)
assert_eq(position_is_zero('-1.0'), true)
assert_eq(position_is_zero('1.'), true)
assert_eq(position_is_zero('0.0'), true)
assert_eq(position_is_zero('0.000'), true)
assert_eq(position_is_zero('0.001'), false)
assert_eq(position_is_zero('-0.001'), false)
assert_eq(position_is_zero('.01'), false)
assert_eq(position_is_zero('.00'), true)
