function eq(actual, expected)
  if type(expected) == 'table' then
    if type(actual) ~= 'table' then
      error("Expected table " .. dump(expected) .. ", got " .. dump(actual))
    else
      for k, v in pairs(expected) do
        if expected[k] and not actual[k] then
          error("Expected key " .. k .. ", but actual does not contain key (expected " .. dump(expected) .. ", got " .. dump(actual) .. ")")
        else
          eq(actual[k], expected[k])
        end
      end

      for k, v in pairs(actual) do
        if actual[k] and not expected[k] then
          error("Actual has key " .. k .. ", but expected does not contain key (expected " .. dump(expected) .. ", got " .. dump(actual) .. ")")
        else
          eq(actual[k], expected[k])
        end
      end
    end
  else
    if expected ~= actual then
      error("Expected " .. dump(expected) .. ", got " .. dump(actual))
    end
  end
end

return {
  eq = eq,
}
