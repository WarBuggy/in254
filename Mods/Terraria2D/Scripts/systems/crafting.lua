-- ============================================
-- Terraria2D — Crafting System
-- Recipes and stations
-- ============================================

local Inventory = require("systems/inventory")
local Tiles = require("world/tiles")

local Crafting = {}

-- station: nil = hand, "workbench", "furnace", "anvil"
Crafting.recipes = {
    -- Hand recipes
    { inputs = {{"wood", 1}},         output = "planks",       count = 4, station = nil },
    { inputs = {{"planks", 4}},       output = "workbench",    count = 1, station = nil },
    { inputs = {{"wood", 1}, {"coal", 1}}, output = "torch",   count = 3, station = nil },

    -- Workbench recipes
    { inputs = {{"planks", 7}},       output = "wooden_sword", count = 1, station = "workbench" },
    { inputs = {{"planks", 5}},       output = "bow",          count = 1, station = "workbench" },
    { inputs = {{"cobblestone", 1}, {"wood", 1}}, output = "arrow", count = 5, station = "workbench" },
    { inputs = {{"cobblestone", 10}, {"wood", 3}}, output = "furnace", count = 1, station = "workbench" },
    { inputs = {{"iron_bar", 5}},     output = "anvil",        count = 1, station = "workbench" },

    -- Furnace recipes
    { inputs = {{"iron_ore", 3}},     output = "iron_bar",     count = 1, station = "furnace" },
    { inputs = {{"gold_ore", 3}},     output = "gold_bar",     count = 1, station = "furnace" },
    { inputs = {{"copper_ore", 3}},   output = "copper_bar",   count = 1, station = "furnace" },
    { inputs = {{"sand", 4}},         output = "glass",        count = 4, station = "furnace" },
    { inputs = {{"cobblestone", 4}},  output = "brick",        count = 4, station = "furnace" },

    -- Anvil recipes
    { inputs = {{"iron_bar", 8}},     output = "iron_sword",   count = 1, station = "anvil" },
    { inputs = {{"gold_bar", 8}},     output = "gold_sword",   count = 1, station = "anvil" },
    { inputs = {{"diamond", 3}, {"gold_bar", 5}}, output = "magic_staff", count = 1, station = "anvil" },
}

-- Get available recipes based on inventory and nearby station
function Crafting.GetAvailable(inv, nearStation)
    local available = {}
    for _, recipe in ipairs(Crafting.recipes) do
        -- Check station requirement
        local stationOk = false
        if recipe.station == nil then
            stationOk = true
        elseif recipe.station == nearStation then
            stationOk = true
        end

        if stationOk then
            -- Check if player has all inputs
            local canCraft = true
            for _, input in ipairs(recipe.inputs) do
                if not Inventory.HasItem(inv, input[1], input[2]) then
                    canCraft = false
                    break
                end
            end

            table.insert(available, {
                recipe = recipe,
                canCraft = canCraft,
            })
        end
    end
    return available
end

-- Craft a recipe
function Crafting.Craft(inv, recipe)
    -- Consume inputs
    for _, input in ipairs(recipe.inputs) do
        Inventory.RemoveItem(inv, input[1], input[2])
    end
    -- Add output
    Inventory.Add(inv, recipe.output, recipe.count)
end

-- Check if player is near a crafting station
function Crafting.GetNearStation(playerX, playerY)
    local WorldData = require("world/worlddata")
    local Config = require("core/config")
    local TS = Config.TILE_SIZE
    local reach = Config.REACH_DIST

    local ptx = math.floor(playerX / TS)
    local pty = math.floor(playerY / TS)

    for dy = -reach, reach do
        for dx = -reach, reach do
            local tx = ptx + dx
            local ty = pty + dy
            local tileId = WorldData.Get(tx, ty)
            if tileId == Tiles.WORKBENCH then return "workbench"
            elseif tileId == Tiles.FURNACE then return "furnace"
            elseif tileId == Tiles.ANVIL then return "anvil"
            end
        end
    end
    return nil
end

return Crafting
