-- ============================================
-- Terraria2D — NPCs
-- Guide and Merchant
-- ============================================

local Config = require("core/config")
local Physics = require("systems/physics")
local Camera = require("core/camera")
local UI = require("core/ui")
local NPC = {}

local floor = math.floor
local _DR = Drawing.Rect
local _ps -- pixel sprite id

function NPC.SpawnGuide(shared, tileX, tileY)
    local TS = Config.TILE_SIZE
    local npc = {
        type = "guide",
        name = "Guide",
        x = tileX * TS,
        y = (tileY - 3) * TS,
        vx = 0,
        vy = 0,
        w = 12,
        h = 24,
        onGround = false,
        facingRight = true,
        walkTimer = 0,
        walkDir = 0,
        homeX = tileX * TS,
        dialogLines = {
            "Welcome to Terraria 2D!",
            "Use A/D to move, Space to jump.",
            "Left click to mine blocks.",
            "Right click to place blocks.",
            "Press C to open crafting.",
            "Build a workbench to unlock more recipes!",
        },
        dialogIndex = 1,
        showDialog = false,
        dialogTimer = 0,
    }
    table.insert(shared.npcs, npc)
end

function NPC.SpawnMerchant(shared, tileX, tileY)
    local TS = Config.TILE_SIZE
    local npc = {
        type = "merchant",
        name = "Merchant",
        x = tileX * TS,
        y = (tileY - 3) * TS,
        vx = 0,
        vy = 0,
        w = 12,
        h = 24,
        onGround = false,
        facingRight = false,
        walkTimer = 0,
        walkDir = 0,
        homeX = tileX * TS,
        dialogLines = {
            "I'm the Merchant!",
            "Trade ores for useful items.",
            "Explore deeper for rare resources!",
        },
        dialogIndex = 1,
        showDialog = false,
        dialogTimer = 0,
    }
    table.insert(shared.npcs, npc)
end

function NPC.UpdateAll(shared, dt)
    local p = shared.player

    for _, npc in ipairs(shared.npcs) do
        -- Physics
        Physics.Update(npc, dt)

        -- Simple wander AI
        npc.walkTimer = npc.walkTimer - dt
        if npc.walkTimer <= 0 then
            npc.walkTimer = 2 + math.random() * 3
            npc.walkDir = math.random(-1, 1)
        end

        -- Walk but stay near home
        local distFromHome = npc.x - npc.homeX
        if math.abs(distFromHome) > 60 then
            npc.walkDir = distFromHome > 0 and -1 or 1
        end

        npc.vx = npc.walkDir * 30
        if npc.walkDir ~= 0 then
            npc.facingRight = npc.walkDir > 0
        end

        -- Dialog proximity
        local dx = math.abs(p.x - npc.x)
        local dy = math.abs(p.y - npc.y)
        local near = dx < 40 and dy < 40

        if near then
            if not npc.showDialog then
                npc.showDialog = true
                npc.dialogTimer = 0
            end
            -- Cycle dialog
            npc.dialogTimer = npc.dialogTimer + dt
            if npc.dialogTimer > 4 then
                npc.dialogTimer = 0
                npc.dialogIndex = npc.dialogIndex + 1
                if npc.dialogIndex > #npc.dialogLines then
                    npc.dialogIndex = 1
                end
            end
        else
            npc.showDialog = false
        end
    end
end

-- Pre-packed NPC colors
local _cSkin = Color.New(230, 190, 150)
local _cGuideHair = Color.New(80, 50, 20)
local _cGuideBody = Color.New(40, 140, 40)
local _cGuideLeg = Color.New(30, 100, 30)
local _cMerchHat = Color.New(60, 60, 60)
local _cMerchBody = Color.New(40, 40, 140)
local _cMerchLeg = Color.New(30, 30, 100)
local _cEye = Color.New(40, 40, 40)
local _cDialogBg = Color.New(0, 0, 0, 200)
local _cNameLabel = Color.New(255, 255, 100)
local _cDialogText = Color.New(255, 255, 255)

function NPC.DrawAll(shared)
    -- Lazy init pixel sprite
    if not _ps then _ps = Drawing.RegisterPixelSprite(UI.GetPixelId()) end

    local b = shared.camBounds
    local R = _DR

    for _, npc in ipairs(shared.npcs) do
        local sx = math.floor(npc.x)
        local sy = math.floor(npc.y)

        -- World-space culling (80px margin for dialog boxes)
        if npc.x + 80 >= b.x and npc.x - 80 <= b.x + b.w and npc.y + npc.h >= b.y and npc.y - 30 <= b.y + b.h then
            if npc.type == "guide" then
                R(_ps, sx + 3, sy, 6, 6, _cSkin)
                R(_ps, sx + 3, sy, 6, 2, _cGuideHair)
                R(_ps, sx + 2, sy + 6, 8, 10, _cGuideBody)
                R(_ps, sx + 2, sy + 16, 3, 8, _cGuideLeg)
                R(_ps, sx + 7, sy + 16, 3, 8, _cGuideLeg)
            elseif npc.type == "merchant" then
                R(_ps, sx + 3, sy, 6, 6, _cSkin)
                R(_ps, sx + 3, sy, 6, 2, _cMerchHat)
                R(_ps, sx + 2, sy + 6, 8, 10, _cMerchBody)
                R(_ps, sx + 2, sy + 16, 3, 8, _cMerchLeg)
                R(_ps, sx + 7, sy + 16, 3, 8, _cMerchLeg)
            end

            local eyeX = npc.facingRight and (sx + 7) or (sx + 4)
            R(_ps, eyeX, sy + 2, 1, 2, _cEye)

            -- Name label + dialog on UI layer (scale sizes by zoom for screen-space)
            Drawing.SetLayer("ui")
            local zoom = Camera.zoom
            local uiX = math.floor(Camera.WorldToScreenX(npc.x))
            local uiY = math.floor(Camera.WorldToScreenY(npc.y))

            Drawing.Text(npc.name, uiX - floor(4 * zoom), uiY - floor(12 * zoom), floor(8 * zoom), _cNameLabel)

            if npc.showDialog then
                local line = npc.dialogLines[npc.dialogIndex]
                local bw = floor((#line * 5 + 16) * zoom)
                local bx = floor(uiX - bw / 2 + 6 * zoom)
                local by = floor(uiY - 28 * zoom)
                R(_ps, bx, by, bw, floor(14 * zoom), _cDialogBg)
                Drawing.Text(line, bx + floor(4 * zoom), by + floor(2 * zoom), floor(9 * zoom), _cDialogText)
            end
            Drawing.SetLayer("entities")
        end
    end
end

return NPC
