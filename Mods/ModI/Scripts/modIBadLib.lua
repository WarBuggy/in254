BadLib = {}

function BadLib.goodFoo(a, b)
    return a + b
end

badSyntax

function BadLib.ignoredFoo(a, b)
    return a - b
end