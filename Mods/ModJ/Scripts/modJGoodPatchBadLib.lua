-- ModJ patch bad library BadLib

function BadLib.divide(a, b)
    if b == 0 then
        error("Division by zero")
    end
    return a / b
end