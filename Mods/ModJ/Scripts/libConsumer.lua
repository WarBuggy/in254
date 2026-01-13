print("This is libConsumer.lua from ModJ")

print("Can consume good library NathUtils")
local result = MathUtils.add(10, 5)
print(result)

print("Cannot consume bad library BadLib, even goodFoo")
BadLib.goodFoo(1,2)