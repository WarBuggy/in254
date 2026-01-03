-- Hook for FunctionA
function OnFunctionA(a, v, c, d, f)
    ctx:Set("commonVarName", c * 10)
    print("[Lua] OnFunctionA: stored c*10 in mod context")
end

-- Hook for FunctionZ
function OnFunctionZ()
    local val = ctx:Get("commonVarName", 0)
    print("[Lua] OnFunctionZ: retrieved value from FunctionA: " .. tostring(val))
end
