print("This is scriptI.lua from ModI")
print("2 + 3 =", MathUtils.add(2, 3))      -- patched version
print("5 - 2 =", MathUtils.subtract(5, 2))      -- added by ModI
print("10 / 2 =", MathUtils.divide(10, 2))    -- original function

-- local function printSomething()
--     print("Animation loaded acknowledged in LUA script.")
-- end

-- Events.OnAnimationsLoaded.Add(printSomething)
