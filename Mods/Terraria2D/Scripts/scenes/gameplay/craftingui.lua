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

-- Cached colors
local _cOverlay      = Color.New(0, 0, 0, 150)
local _cPanelBg      = Color.New(25, 25, 40, 240)
local _cRowCraft     = Color.New(40, 50, 40, 200)
local _cRowNoCraft   = Color.New(50, 40, 40, 200)
local _cRowCraftHov  = Color.New(50, 70, 50, 220)
local _cRowNoCraftHov = Color.New(60, 50, 50, 220)
local _cCraftBtn     = Color.New(40, 80, 40, 230)
local _cCraftBtnHov  = Color.New(60, 110, 60, 240)

-- Item color cache (keyed by item id)
local _itemColorCache = {}
local function GetItemPackedColor(itemId)
    local cached = _itemColorCache[itemId]
    if cached then return cached end
    local c = Tiles.GetItemColor(itemId)
    cached = Color.New(c[1], c[2], c[3])
    _itemColorCache[itemId] = cached
    return cached
end

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
    UI.Rect(0, 0, W, H, _cOverlay)

    local panelW = 320
    local panelH = 400
    local panelX = math.floor(W / 2 - panelW / 2)
    local panelY = math.floor(H / 2 - panelH / 2)

    UI.Panel(panelX, panelY, panelW, panelH, _cPanelBg)

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
        local rowBg = canCraft and _cRowCraft or _cRowNoCraft
        if UI.IsHovered(panelX + 8, ry, panelW - 16, rowH - 2) then
            rowBg = canCraft and _cRowCraftHov or _cRowNoCraftHov
        end
        UI.Rect(panelX + 8, ry, panelW - 16, rowH - 2, rowBg)

        -- Output item icon
        UI.Rect(panelX + 14, ry + 6, 16, 16, GetItemPackedColor(recipe.output))

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
                color = _cCraftBtn,
                hoverColor = _cCraftBtnHov,
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
