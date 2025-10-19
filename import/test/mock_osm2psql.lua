-- Mock implementation of the Osm2psql Lua library
-- See https://osm2pgsql.org/doc/manual.html

function define_table() end

function make_check_values_func(values)
   checker = {}
   for _, value in ipairs(values) do
     if value == check then
       checker[value] = true
     end
   end

   return function (check)
     return checker[check] or false
   end
end

function has_prefix(a, b)
  return a:sub(1, b:len()) == b
end

return {
  define_table = define_table,
  make_check_values_func = make_check_values_func,
  has_prefix = has_prefix,
}
