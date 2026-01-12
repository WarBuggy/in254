-- Get the MathUtils library from ModH
local MathUtils = Library.Get("ModH.MathUtils")

-- Print the table itself for debugging
print("MathUtils table:", MathUtils)

-- Iterate over all keys and values
for k, v in pairs(MathUtils) do
    print("  Key:", k, "Value type:", type(v), "Value:", v)
end

-- Use functions / fields from the library
local sum = MathUtils.Add(2, 3)
print("2 + 3 =", sum)

-- Optional: use other functions
local divResult = MathUtils.Div(10, 2)
print("10 / 2 =", divResult)
print("Special value =", MathUtils.SpecialValue)

-- -- Optional: patch the library
-- Library.Patch("ModH.MathUtils", function()
--     function MathUtils.Mul(a, b)
--         return a * b
--     end
-- end)

-- -- Test the patch
-- local prod = MathUtils.Mul(4, 5)
-- print("4 * 5 =", prod)
