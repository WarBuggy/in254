-- ============================================
-- ScorchridgeV2 — Overlays Sub-Scene
-- Merits store + event modal + tooltip
-- ============================================

local Theme = require("core/theme")
local SFX = require("core/sound")
local UI = require("core/ui")

local Merits = require("systems/merits")
local GameEvents = require("systems/events")
local Resupply = require("systems/resupply")
local Inventory = require("systems/inventory")

local modId = "ScorchridgeV2"
local C = Theme.Colors

return SceneNode.new({
    name = "overlays",
    blocksInput = false,

    onUpdate = function(self, dt, totalTime, shared)
        local blocking = Merits.IsStoreOpen() or GameEvents.HasPending() or Resupply.IsOpen()
        Scene.SetNodeBlocksInput("overlays", blocking)
    end,

    onDraw = function(self, shared)
        local resources = shared.resources
        local W, H = shared.W, shared.H

        local rawMouseX = Input.MouseX()
        local rawMouseY = Input.MouseY()
        local rawMouseDown = Input.IsMouseDown("left")
        local rawMouseReleased = Input.IsMouseReleased("left")

        local function isHovered(x, y, w, h)
            return rawMouseX >= x and rawMouseX < x + w and rawMouseY >= y and rawMouseY < y + h
        end
        local function isClicked(x, y, w, h)
            return rawMouseReleased and isHovered(x, y, w, h)
        end

        -- ---- Merits Store ----
        if Merits.IsStoreOpen() and resources then
            UI.Rect(0, 0, W, H, {0, 0, 0, 140})

            local pw = 340
            local ph = 280
            local px = math.floor((W - pw) / 2)
            local py = math.floor((H - ph) / 2)
            UI.Panel(px, py, pw, ph, {30, 30, 50, 240})

            Text.Draw("MERIT STORE", px + 10, py + 8, 16, C.CYAN)
            Text.Draw("Merits: " .. (resources.colonyMerits or 0), px + 150, py + 8, 14, C.WHITE)

            local y = py + 34
            local items = Merits.GetStoreItems()
            for _, item in ipairs(items) do
                local canBuy = (resources.colonyMerits or 0) >= item.cost
                local label = item.name .. " (" .. item.cost .. "M)"

                local bx, by, bw, bh = px + 10, y, pw - 20, 28
                local hovered = isHovered(bx, by, bw, bh)
                local bg = {60, 60, 80, 220}
                if not canBuy then
                    bg = {40, 40, 50, 180}
                elseif hovered and rawMouseDown then
                    bg = {50, 50, 70, 240}
                elseif hovered then
                    bg = {80, 80, 110, 230}
                end
                UI.Rect(bx, by, bw, bh, bg)
                Text.Draw(label, bx + 8, by + math.floor((bh - 12) / 2), 12,
                    canBuy and C.WHITE or C.DIM)

                if canBuy and isClicked(bx, by, bw, bh) then
                    Merits.Purchase(item.id, resources)
                    GameData:SetTo(modId, "colony.resources", resources)
                    SFX.Click()
                end
                Text.Draw(item.desc, px + 20, y + 30, 10, C.GRAY)
                y = y + 44
            end

            local cbx, cby, cbw, cbh = px + pw - 70, py + ph - 34, 60, 26
            local cbHovered = isHovered(cbx, cby, cbw, cbh)
            local cbBg = cbHovered and {80, 80, 110, 230} or {60, 60, 80, 220}
            UI.Rect(cbx, cby, cbw, cbh, cbBg)
            Text.Draw("Close", cbx + 8, cby + math.floor((cbh - 12) / 2), 12, C.YELLOW)
            if isClicked(cbx, cby, cbw, cbh) then
                Merits.ToggleStore()
                SFX.Click()
            end
        end

        -- ---- Event Modal ----
        if GameEvents.HasPending() then
            local evt = GameEvents.GetPending()
            if evt then
                UI.Rect(0, 0, W, H, {0, 0, 0, 160})

                local pw = 400
                local ph = 200
                local px = math.floor((W - pw) / 2)
                local py = math.floor((H - ph) / 2)

                local borderColor = evt.type == "negative" and {180, 40, 40, 255} or {40, 180, 40, 255}
                UI.Rect(px - 2, py - 2, pw + 4, ph + 4, borderColor)
                UI.Panel(px, py, pw, ph, {25, 25, 40, 245})

                local icon = evt.type == "negative" and "!!" or "++"
                local iconColor = evt.type == "negative" and C.RED or C.GREEN
                Text.Draw(icon, px + 10, py + 10, 24, iconColor)
                Text.Draw(evt.name, px + 50, py + 12, 18, C.WHITE)
                Text.Draw(evt.desc, px + 20, py + 50, 13, C.GRAY)

                local abx = px + math.floor(pw / 2) - 60
                local aby = py + ph - 50
                local abw, abh = 120, 34
                local abHovered = isHovered(abx, aby, abw, abh)
                local abBg = abHovered and {80, 80, 110, 240} or {60, 60, 80, 230}
                UI.Rect(abx, aby, abw, abh, abBg)
                Text.Draw("Acknowledge", abx + 8, aby + math.floor((abh - 14) / 2), 14, C.YELLOW)
                if isClicked(abx, aby, abw, abh) then
                    GameEvents.Dismiss()
                    SFX.Click()
                end
            end
        end

        -- ---- Resupply Overlay ----
        if Resupply.IsOpen() and resources then
            UI.Rect(0, 0, W, H, {0, 0, 0, 160})

            local pw = 380
            local ph = 340
            local px = math.floor((W - pw) / 2)
            local py = math.floor((H - ph) / 2)
            UI.Panel(px, py, pw, ph, {25, 30, 40, 245})

            Text.Draw("CYCLE RESUPPLY", px + 10, py + 8, 18, C.YELLOW)
            Text.Draw("Credits: $" .. (resources.colonyCredits or 0), px + 200, py + 10, 14, C.GREEN)

            -- Current stock display
            local sy = py + 34
            Text.Draw("Current Stock:", px + 10, sy, 11, C.GRAY)
            sy = sy + 16
            Text.Draw("O2: " .. (resources.oxygen or 0), px + 10, sy, 10, C.WHITE)
            Text.Draw("Food: " .. (resources.food or 0), px + 100, sy, 10, C.WHITE)
            Text.Draw("PCHO: " .. Inventory.GetCount("pcho_ration"), px + 200, sy, 10, C.WHITE)
            Text.Draw("Drugs: " .. Inventory.GetCount("drug_dose"), px + 300, sy, 10, C.WHITE)
            sy = sy + 22

            -- Shop items
            local items = Resupply.GetShopItems()
            for _, item in ipairs(items) do
                local canBuy = (resources.colonyCredits or 0) >= item.cost
                local label = item.name .. " ($" .. item.cost .. ") - " .. item.desc

                local bx, by, bw, bh = px + 10, sy, pw - 20, 32
                local hovered = isHovered(bx, by, bw, bh)
                local bg = {50, 55, 70, 220}
                if not canBuy then
                    bg = {35, 35, 45, 180}
                elseif hovered and rawMouseDown then
                    bg = {45, 50, 65, 240}
                elseif hovered then
                    bg = {70, 75, 95, 230}
                end
                UI.Rect(bx, by, bw, bh, bg)
                Text.Draw(label, bx + 8, by + math.floor((bh - 12) / 2), 12,
                    canBuy and C.WHITE or C.DIM)

                if canBuy and isClicked(bx, by, bw, bh) then
                    Resupply.Purchase(item.id, resources)
                    SFX.Click()
                end
                sy = sy + 40
            end

            -- Launch Cycle button
            local lbw, lbh = 160, 40
            local lbx = px + math.floor((pw - lbw) / 2)
            local lby = py + ph - 54
            local lbHovered = isHovered(lbx, lby, lbw, lbh)
            local lbBg = lbHovered and {60, 90, 60, 240} or {45, 70, 45, 230}
            UI.Rect(lbx, lby, lbw, lbh, lbBg)
            Text.Draw("Launch Cycle", lbx + 20, lby + math.floor((lbh - 16) / 2), 16, C.YELLOW)
            if isClicked(lbx, lby, lbw, lbh) then
                Resupply.Close()
                SFX.Click()
            end
        end

        -- ---- Tooltip (always last) ----
        UI.DrawTooltip()
    end
})
