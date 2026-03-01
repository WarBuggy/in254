-- ============================================
-- Terraria2D — Tile Registry
-- Tile types, colors, hardness, drops
-- ============================================

local Tiles = {}

-- Tile IDs
Tiles.AIR        = 0
Tiles.DIRT       = 1
Tiles.STONE      = 2
Tiles.GRASS      = 3
Tiles.SAND       = 4
Tiles.WOOD       = 5
Tiles.IRON_ORE   = 6
Tiles.GOLD_ORE   = 7
Tiles.COPPER_ORE = 8
Tiles.COAL       = 9
Tiles.DIAMOND    = 10
Tiles.TORCH      = 11
Tiles.WORKBENCH  = 12
Tiles.FURNACE    = 13
Tiles.ANVIL      = 14
Tiles.OBSIDIAN   = 15
Tiles.PLANKS     = 16
Tiles.BRICK      = 17
Tiles.GLASS      = 18
Tiles.LEAVES     = 19
Tiles.TRUNK      = 20

-- Tile data: { name, solid, hardness, color, drop, light }
Tiles.data = {
    [0]  = { name = "air",        solid = false, hardness = 0,   color = {0, 0, 0, 0},       drop = nil,           light = 0 },
    [1]  = { name = "dirt",       solid = true,  hardness = 1,   color = {139, 90, 43},       drop = "dirt",        light = 0 },
    [2]  = { name = "stone",      solid = true,  hardness = 2,   color = {128, 128, 128},     drop = "cobblestone", light = 0 },
    [3]  = { name = "grass",      solid = true,  hardness = 1,   color = {76, 153, 0},        drop = "dirt",        light = 0 },
    [4]  = { name = "sand",       solid = true,  hardness = 0.5, color = {220, 200, 120},     drop = "sand",        light = 0 },
    [5]  = { name = "wood",       solid = true,  hardness = 1.5, color = {160, 110, 50},      drop = "wood",        light = 0 },
    [6]  = { name = "iron_ore",   solid = true,  hardness = 3,   color = {180, 140, 120},     drop = "iron_ore",    light = 0 },
    [7]  = { name = "gold_ore",   solid = true,  hardness = 3,   color = {220, 200, 80},      drop = "gold_ore",    light = 0 },
    [8]  = { name = "copper_ore", solid = true,  hardness = 2,   color = {200, 120, 60},      drop = "copper_ore",  light = 0 },
    [9]  = { name = "coal",       solid = true,  hardness = 2,   color = {50, 50, 50},        drop = "coal",        light = 0 },
    [10] = { name = "diamond",    solid = true,  hardness = 4,   color = {140, 220, 255},     drop = "diamond",     light = 0 },
    [11] = { name = "torch",      solid = false, hardness = 0,   color = {255, 200, 50},      drop = "torch",       light = 10 },
    [12] = { name = "workbench",  solid = true,  hardness = 1,   color = {180, 130, 60},      drop = "workbench",   light = 0 },
    [13] = { name = "furnace",    solid = true,  hardness = 2,   color = {200, 80, 40},       drop = "furnace",     light = 3 },
    [14] = { name = "anvil",      solid = true,  hardness = 2,   color = {100, 100, 110},     drop = "anvil",       light = 0 },
    [15] = { name = "obsidian",   solid = true,  hardness = 5,   color = {30, 10, 50},        drop = "obsidian",    light = 0 },
    [16] = { name = "planks",     solid = true,  hardness = 1,   color = {190, 150, 80},      drop = "planks",      light = 0 },
    [17] = { name = "brick",      solid = true,  hardness = 2,   color = {160, 70, 50},       drop = "brick",       light = 0 },
    [18] = { name = "glass",      solid = true,  hardness = 0.5, color = {200, 230, 255, 120},drop = "glass",       light = 0 },
    [19] = { name = "leaves",     solid = false, hardness = 0.2, color = {30, 130, 30},       drop = "wood",        light = 0 },
    [20] = { name = "trunk",      solid = false, hardness = 1.0, color = {120, 80, 40},       drop = "wood",        light = 0 },
}

-- Item to tile mapping (for placing blocks)
Tiles.itemToTile = {
    dirt       = Tiles.DIRT,
    cobblestone= Tiles.STONE,
    sand       = Tiles.SAND,
    wood       = Tiles.WOOD,
    iron_ore   = Tiles.IRON_ORE,
    gold_ore   = Tiles.GOLD_ORE,
    copper_ore = Tiles.COPPER_ORE,
    coal       = Tiles.COAL,
    diamond    = Tiles.DIAMOND,
    torch      = Tiles.TORCH,
    workbench  = Tiles.WORKBENCH,
    furnace    = Tiles.FURNACE,
    anvil      = Tiles.ANVIL,
    obsidian   = Tiles.OBSIDIAN,
    planks     = Tiles.PLANKS,
    brick      = Tiles.BRICK,
    glass      = Tiles.GLASS,
}

-- Item display names
Tiles.itemNames = {
    dirt = "Dirt", cobblestone = "Cobblestone", sand = "Sand", wood = "Wood",
    iron_ore = "Iron Ore", gold_ore = "Gold Ore", copper_ore = "Copper Ore",
    coal = "Coal", diamond = "Diamond", torch = "Torch",
    workbench = "Workbench", furnace = "Furnace", anvil = "Anvil",
    obsidian = "Obsidian", planks = "Planks", brick = "Brick", glass = "Glass",
    iron_bar = "Iron Bar", gold_bar = "Gold Bar", copper_bar = "Copper Bar",
    wooden_sword = "Wooden Sword", iron_sword = "Iron Sword", gold_sword = "Gold Sword",
    bow = "Bow", arrow = "Arrow", magic_staff = "Magic Staff",
    gun = "Gun", bullet = "Bullet",
}

-- Item colors (for rendering in inventory)
Tiles.itemColors = {
    dirt       = {139, 90, 43},
    cobblestone= {128, 128, 128},
    sand       = {220, 200, 120},
    wood       = {160, 110, 50},
    iron_ore   = {180, 140, 120},
    gold_ore   = {220, 200, 80},
    copper_ore = {200, 120, 60},
    coal       = {50, 50, 50},
    diamond    = {140, 220, 255},
    torch      = {255, 200, 50},
    workbench  = {180, 130, 60},
    furnace    = {200, 80, 40},
    anvil      = {100, 100, 110},
    obsidian   = {30, 10, 50},
    planks     = {190, 150, 80},
    brick      = {160, 70, 50},
    glass      = {200, 230, 255},
    iron_bar   = {200, 200, 210},
    gold_bar   = {255, 215, 60},
    copper_bar = {210, 140, 70},
    wooden_sword = {160, 110, 50},
    iron_sword = {200, 200, 210},
    gold_sword = {255, 215, 60},
    bow        = {140, 100, 40},
    arrow      = {180, 180, 180},
    magic_staff= {180, 100, 255},
    gun        = {80, 80, 90},
    bullet     = {220, 200, 50},
}

-- Weapon stats: { damage, knockback, speed, type, manaCost }
Tiles.weapons = {
    wooden_sword = { damage = 8,  knockback = 4, speed = 0.4, type = "melee" },
    iron_sword   = { damage = 15, knockback = 5, speed = 0.35, type = "melee" },
    gold_sword   = { damage = 22, knockback = 6, speed = 0.3, type = "melee" },
    bow          = { damage = 10, knockback = 2, speed = 0.5, type = "ranged", ammo = "arrow" },
    magic_staff  = { damage = 18, knockback = 3, speed = 0.6, type = "magic", manaCost = 8 },
    gun          = { damage = 12, knockback = 2, speed = 0.15, type = "ranged", ammo = "bullet" },
}

function Tiles.IsSolid(id)
    local d = Tiles.data[id]
    return d and d.solid
end

function Tiles.GetData(id)
    return Tiles.data[id] or Tiles.data[0]
end

function Tiles.IsPlaceable(itemId)
    return Tiles.itemToTile[itemId] ~= nil
end

function Tiles.IsWeapon(itemId)
    return Tiles.weapons[itemId] ~= nil
end

function Tiles.GetName(itemId)
    return Tiles.itemNames[itemId] or itemId
end

function Tiles.GetItemColor(itemId)
    return Tiles.itemColors[itemId] or {200, 200, 200}
end

return Tiles
