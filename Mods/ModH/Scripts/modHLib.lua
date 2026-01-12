local MathUtils = {}

function MathUtils.Add(a, b)
    return a + b
end

MathUtils.SpecialValue = 42

function MathUtils.Div(a, b)
    if b == 0 then
        error("Division by zero!")
    end
    return a / b
end

-- Return the table so LibraryManager can pick it up
return MathUtils