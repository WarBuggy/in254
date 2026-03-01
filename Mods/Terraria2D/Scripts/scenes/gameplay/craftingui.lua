-- ============================================
-- Terraria2D — Crafting UI
-- Crafting panel overlay
-- ============================================

local UI = require("core/ui")
local Theme = require("core/theme")
local Tiles = require("world/tiles")
local Crafting = require("systems/crafting")
local Inventory = require("systems/inventory")
local C = Theme.Colors

local CraftingUI = {}

local scrollOffset = 0

function CraftingUI.Update(shared)
    local scroll = Input.ScrollDelta()
    if scroll ~= 0 then
        scrollOffset = math.max(0, scrollOffset - scroll)
    end
end

function CraftingUI.Draw(shared)
    local W = shared.W
    local H = shared.H
    local p = shared.player

    -- Overlay
    UI.Rect(0, 0, W, H, {0, 0, 0, 150})

    local panelW = 320
    local panelH = 400
    local panelX = math.floor(W / 2 - panelW / 2)
    local panelY = math.floor(H / 2 - panelH / 2)

    UI.Panel(panelX, panelY, panelW, panelH, {25, 25, 40, 240})

    -- Header
    local nearStation = Crafting.GetNearStation(p.x + p.w / 2, p.y + p.h / 2)
    local stationLabel = "Hand Crafting"
    if nearStation == "workbench" then stationLabel = "Workbench"
    elseif nearStation == "furnace" then stationLabel = "Furnace"
    elseif nearStation == "anvil" then stationLabel = "Anvil"
    end
    Drawing.Text("Crafting - " .. stationLabel, panelX + 10, panelY + 8, 14, C.YELLOW)
    Drawing.Text("[C] Close", panelX + panelW - 70, panelY + 10, 10, C.GRAY)

    -- Get available recipes
    local available = Crafting.GetAvailable(shared.inventory, nearStation)

    local startY = panelY + 30
    local rowH = 36
    local maxVisible = math.floor((panelH - 40) / rowH)

    scrollOffset = math.min(scrollOffset, math.max(0, #available - maxVisible))

    for i = 1, math.min(#available, maxVisible) do
        local entry = available[i + scrollOffset]
        if not entry then break end

        local recipe = entry.recipe
        local canCraft = entry.canCraft
        local ry = startY + (i - 1) * rowH

        -- Row background
        local rowBg = canCraft and {40, 50, 40, 200} or {50, 40, 40, 200}
        if UI.IsHovered(panelX + 8, ry, panelW - 16, rowH - 2) then
            rowBg = canCraft and {50, 70, 50, 220} or {60, 50, 50, 220}
        end
        UI.Rect(panelX + 8, ry, panelW - 16, rowH - 2, rowBg)

        -- Output item icon
        local outColor = Tiles.GetItemColor(recipe.output)
        UI.Rect(panelX + 14, ry + 6, 16, 16, outColor)

        -- Output name
        local outName = Tiles.GetName(recipe.output)
        if recipe.count > 1 then
            outName = outName .. " x" .. recipe.count
        end
        Drawing.Text(outName, panelX + 36, ry + 4, 12, canCraft and C.WHITE or C.DIM)

        -- Input list
        local inputStr = ""
        for j, input in ipairs(recipe.inputs) do
            if j > 1 then inputStr = inputStr .. " + " end
            inputStr = inputStr .. Tiles.GetName(input[1]) .. "x" .. input[2]
        end
        Drawing.Text(inputStr, panelX + 36, ry + 18, 9, C.GRAY)

        -- Craft button
        if canCraft then
            local btnX = panelX + panelW - 60
            if UI.Button(btnX, ry + 4, 44, 24, "Craft", {
                color = {40, 80, 40, 230},
                hoverColor = {60, 110, 60, 240},
                textSize = 10,
            }) then
                Crafting.Craft(shared.inventory, recipe)
            end
        end
    end

    -- Scroll indicator
    if #available > maxVisible then
        Drawing.Text("Scroll for more...", panelX + 10, panelY + panelH - 16, 9, C.DIM)
    end
end

return CraftingUI
