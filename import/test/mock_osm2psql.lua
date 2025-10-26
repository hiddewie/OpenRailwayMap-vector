-- Mock implementation of the Osm2psql Lua library
-- See https://osm2pgsql.org/doc/manual.html

-- Global mock
osm2pgsql = {}

local tables = {}
local data = {}

function osm2pgsql.define_table(table_structure)
  local name = table_structure.name
  if tables[name] then
    error("Table" .. name .. " is already defined")
  end
  tables[name] = table_structure

  return {
    insert = function (_, item)
      if not data[name] then
        data[name] = {}
      end

      table.insert(data[name], item)
    end,
  }
end

function osm2pgsql.make_check_values_func(values)
   local checker = {}
   for _, value in ipairs(values) do
     checker[value] = value
   end

   return function (check)
     return checker[check] or false
   end
end

function osm2pgsql.has_prefix(a, b)
  return a:sub(1, b:len()) == b
end

-- State functions for testing
function osm2pgsql.get_and_clear_imported_data()
  local old_data = data

  -- Clear data
  data = {}

  return old_data
end
