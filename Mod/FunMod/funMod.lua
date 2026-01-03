-- Hook for FunctionA
function OnFunctionA(a, v, c, d, f)
    ctx:Set("commonVarName", c * 100)
    print("[Lua] FunMod OnFunctionA: stored c*100 in mod context")
end

-- Hook for FunctionZ
function OnFunctionZ()
    local val = ctx:Get("commonVarName", 0)
    print("[Lua] FunMod OnFunctionZ: retrieved value from FunctionA: " .. tostring(val))
end
