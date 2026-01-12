-- -- modJ: Consume MathUtils library from modA

-- -- Retrieve the MathUtils library
-- local MathUtils = Library.Get("ModH.MathUtils")

-- -- Call original Add function
-- local sum = MathUtils.Add(5, 7)
-- print("[ModJ] 5 + 7 =", sum)  -- Expected: 12

-- -- Call patched Subtract function added by modI
-- if MathUtils.Subtract then
--     local diff = MathUtils.Subtract(20, 8)
--     print("[ModJ] 20 - 8 =", diff)  -- Expected: 12
-- else
--     print("[ModJ] Subtract function not found!")
-- end

-- -- Call wrapped Div function (patched by modI)
-- local status, result = pcall(function()
--     return MathUtils.Div(10, 0)  -- This should trigger the Div by zero error
-- end)

-- if not status then
--     print("[ModJ] Caught error:", result)
-- end

-- -- Call Div safely with valid numbers
-- local safeDiv = MathUtils.Div(10, 2)
-- print("[ModJ] 10 / 2 =", safeDiv)  -- Expected: 5
