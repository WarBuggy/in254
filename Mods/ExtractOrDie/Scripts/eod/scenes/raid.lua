-- ============================================
-- ExtractOrDie — Raid Scene
-- Main gameplay: dungeon, HUD, minimap
-- ============================================

local Theme = require("eod/core/theme")
local UI = require("eod/core/ui")
local Config = require("eod/core/config")
local Camera = require("eod/core/camera")
local Tilemap = require("eod/world/tilemap")
local MapGen = require("eod/world/mapgen")
local Physics = require("eod/systems/physics")
local Player = require("eod/entities/player")
local Enemy = require("eod/entities/enemy")
local Projectile = require("eod/entities/projectile")
local Particles = require("eod/entities/particles")
local Spawning = require("eod/systems/spawning")
local Extraction = require("eod/systems/extraction")
local Inventory = require("eod/systems/inventory")
local Weapons = require("eod/systems/weapons")
local LootCrate = require("eod/entities/lootcrate")
local Stash = require("eod/systems/stash")
local Combat = require("eod/systems/combat")

local C = Theme.Colors

-- Cached draw colors — Dungeon palette
local _cVoid     = Color.New(8, 8, 12)
local _cFloorA   = Color.New(45, 42, 38)
local _cFloorB   = Color.New(50, 47, 42)
local _cWallTop  = Color.New(80, 75, 68)
local _cWallFace = Color.New(55, 52, 48)

-- Forest palette
local _cForestVoid     = Color.New(10, 20, 8)
local _cForestFloorA   = Color.New(45, 75, 35)
local _cForestFloorB   = Color.New(50, 82, 40)
local _cForestWallTop  = Color.New(30, 90, 30)
local _cForestWallFace = Color.New(60, 50, 30)
local _cExtract  = Color.New(50, 255, 50, 40)
local _cExtractB = Color.New(50, 255, 50, 120)
local _cDropHighlight = Color.New(255, 255, 255, 80)
local _cHpBg     = Color.New(30, 10, 10, 200)
local _cHpFg     = Color.New(220, 50, 50)
local _cAmmoBg   = Color.New(30, 30, 10, 200)
local _cAmmoFg   = Color.New(220, 200, 50)
local _cReload   = Color.New(200, 200, 200)
local _cBackpackBg = Color.New(20, 20, 30, 220)
local _cSlotBg   = Color.New(40, 40, 55, 200)
local _cExtractBar = Color.New(50, 200, 50)
local _cExtractBarBg = Color.New(20, 60, 20, 200)
local _cMinimapBg = Color.New(0, 0, 0, 160)
local _cMinimapFloor = Color.New(80, 75, 65)
local _cMinimapPlayer = Color.New(50, 255, 50)
local _cMinimapExtract = Color.New(50, 255, 50, 150)
local _cMinimapEnemy = Color.New(255, 60, 60)
local _cMinimapForestFloor = Color.New(55, 90, 45)
local _cMinimapForestWall = Color.New(35, 55, 25)

local _ps -- pixel sprite id

local _showBackpack = false
local _raidEndTimer = 0
local _totalTime = 0

local RaidScene = Node.new({
    name = "raid",
    shared = Theme.NewRaidShared(),

    onEnter = function(self, shared)
        -- Reset shared
        local newShared = Theme.NewRaidShared()
        for k, v in pairs(newShared) do
            shared[k] = v
        end

        print("[ExtractOrDie] Generating " .. shared.mapType .. " map...")

        -- Register layers
        Drawing.RegisterLayer("world", 0, { blend = "alpha" })
        Drawing.RegisterLayer("entities", 10, { blend = "alpha" })
        Drawing.RegisterLayer("particles", 20, { blend = "additive" })
        Drawing.RegisterLayer("ui", 30, { blend = "alpha" })

        GameCamera.AddLayer("world")
        GameCamera.AddLayer("entities")
        GameCamera.AddLayer("particles")

        -- Generate map based on type
        local result = MapGen.Generate(shared.mapType)
        shared.rooms = result.rooms
        shared.extractZones = result.extractZones
        shared.spawnRoom = result.spawnRoom

        -- Create player at spawn room center
        local TS = Config.TILE_SIZE
        local spawnCX = (result.spawnRoom.x + result.spawnRoom.w / 2) * TS
        local spawnCY = (result.spawnRoom.y + result.spawnRoom.h / 2) * TS
        shared.player = Player.New(spawnCX - Config.PLAYER_W / 2, spawnCY - Config.PLAYER_H / 2, Theme.GetSelectedWeapon())

        -- Init backpack
        shared.backpack = Inventory.New()

        -- Spawn crates
        LootCrate.SpawnAll(shared, result.cratePositions)

        -- Init camera
        shared.W = Screen.Width()
        shared.H = Screen.Height()
        Camera.Snap(spawnCX - shared.W / 2 / Camera.zoom, spawnCY - shared.H / 2 / Camera.zoom)

        -- Reset projectile pool
        Projectile.Reset()

        _showBackpack = false
        _raidEndTimer = 0
        _totalTime = 0

        print("[ExtractOrDie] " .. shared.mapType .. " ready. " .. #result.rooms .. " rooms, " .. #result.extractZones .. " extract zones.")
    end,

    onExit = function(self, shared)
        shared.player = nil
        shared.enemies = {}
        shared.particles = {}
        shared.drops = {}
        shared.crates = {}
    end,

    onUpdate = function(self, dt, totalTime, shared)
        shared.W = Screen.Width()
        shared.H = Screen.Height()
        _totalTime = totalTime
        UI.UpdateInput()

        -- Backpack toggle
        if Input.IsKeyPressed("tab") then
            _showBackpack = not _showBackpack
        end

        -- Escape goes to title (abandon raid)
        if Input.IsKeyPressed("escape") then
            shared.raidOver = true
            shared.raidResult = "died"
        end

        -- Handle raid end with brief delay
        if shared.raidOver then
            _raidEndTimer = _raidEndTimer + dt
            if _raidEndTimer > 1.0 then
                if shared.raidResult == "extracted" then
                    -- Save loot to stash
                    local savedLoot = Stash.TransferFromBackpack(shared.backpack)
                    Theme.SetRaidResult("extracted", savedLoot)
                    Scene.Switch("eod_extract_success")
                else
                    -- Collect list of lost items for death screen
                    local lostLoot = Inventory.GetContents(shared.backpack)
                    Theme.SetRaidResult("died", lostLoot)
                    Scene.Switch("eod_death")
                end
            end
            return
        end
    end,

    onFixedUpdate = function(self, fixedDt, shared)
        if shared.raidOver then return end
        if _showBackpack then return end

        local p = shared.player
        if not p.alive then return end

        -- Player update
        Player.Update(p, fixedDt, shared)

        -- Enemies
        Enemy.UpdateAll(shared, fixedDt)

        -- Spawning
        Spawning.Update(shared, fixedDt)

        -- Projectiles
        Projectile.UpdateAll(shared, fixedDt)

        -- Particles
        Particles.UpdateAll(shared, fixedDt)

        -- Extraction
        Extraction.Update(shared, fixedDt)

        -- Drop lifetime
        local drops = shared.drops
        local n = #drops
        local i = 1
        while i <= n do
            drops[i].lifetime = drops[i].lifetime + fixedDt
            if drops[i].lifetime > 120 then
                drops[i] = drops[n]
                drops[n] = nil
                n = n - 1
            else
                i = i + 1
            end
        end
    end,

    onDraw = function(self, shared)
        if not UI.ResolvePixel() then return end
        if not shared.extractZones then return end -- not yet initialized
        if not _ps then _ps = Drawing.RegisterPixelSprite(UI.GetPixelId()) end

        local W, H = shared.W, shared.H
        local TS = Config.TILE_SIZE
        local R = Drawing.Rect

        -- Compute camera bounds
        shared.camBounds = Camera.GetWorldBounds(W, H)
        local b = shared.camBounds

        -- === WORLD LAYER ===
        Drawing.SetLayer("world")

        -- Select palette by map type
        local isForest = shared.mapType == "forest"
        local cVoid = isForest and _cForestVoid or _cVoid
        local cFloorA = isForest and _cForestFloorA or _cFloorA
        local cFloorB = isForest and _cForestFloorB or _cFloorB
        local cWallTop = isForest and _cForestWallTop or _cWallTop
        local cWallFace = isForest and _cForestWallFace or _cWallFace

        -- Background void
        UI.Rect(0, 0, W, H, cVoid)

        -- Draw tiles (viewport-culled)
        local startTX = math.max(0, math.floor(b.x / TS) - 1)
        local startTY = math.max(0, math.floor(b.y / TS) - 1)
        local endTX = math.min(Config.MAP_W - 1, math.floor((b.x + b.w) / TS) + 1)
        local endTY = math.min(Config.MAP_H - 1, math.floor((b.y + b.h) / TS) + 1)

        for ty = startTY, endTY do
            for tx = startTX, endTX do
                local tile = Tilemap.Get(tx, ty)
                if tile == Config.FLOOR then
                    -- Checkerboard floor
                    local color = ((tx + ty) % 2 == 0) and cFloorA or cFloorB
                    R(_ps, tx * TS, ty * TS, TS, TS, color)
                elseif tile == Config.WALL then
                    -- 3/4 angled wall: show top surface + front face
                    local wx = tx * TS
                    local wy = ty * TS
                    local floorAbove = Tilemap.Get(tx, ty - 1) == Config.FLOOR
                    if floorAbove then
                        R(_ps, wx, wy, TS, 4, cWallTop)
                        R(_ps, wx, wy + 4, TS, TS - 4, cWallFace)
                    else
                        R(_ps, wx, wy, TS, TS, cWallFace)
                    end
                end
            end
        end

        -- Draw extraction zones
        for _, zone in ipairs(shared.extractZones) do
            local zx = zone.x * TS
            local zy = zone.y * TS
            local zw = zone.w * TS
            local zh = zone.h * TS
            -- Pulsing green overlay
            local pulse = math.sin(_totalTime * 3) * 0.3 + 0.7
            local alpha = math.floor(40 * pulse)
            R(_ps, zx, zy, zw, zh, Color.New(50, 255, 50, alpha))
            -- Border
            R(_ps, zx, zy, zw, 2, _cExtractB)
            R(_ps, zx, zy + zh - 2, zw, 2, _cExtractB)
            R(_ps, zx, zy, 2, zh, _cExtractB)
            R(_ps, zx + zw - 2, zy, 2, zh, _cExtractB)
        end

        UI.Flush()

        -- === ENTITIES LAYER ===
        Drawing.SetLayer("entities")

        -- Drops
        for _, drop in ipairs(shared.drops) do
            local sx = math.floor(drop.x)
            local sy = math.floor(drop.y)
            if drop.x + drop.w >= b.x and drop.x <= b.x + b.w and drop.y + drop.h >= b.y and drop.y <= b.y + b.h then
                local lootDef = Config.LOOT_ITEMS[drop.itemId]
                if lootDef then
                    local c = lootDef.color
                    R(_ps, sx, sy, drop.w, drop.h, Color.New(c[1], c[2], c[3]))
                else
                    R(_ps, sx, sy, drop.w, drop.h, C.WHITE)
                end
                R(_ps, sx - 1, sy - 1, drop.w + 2, 1, _cDropHighlight)
            end
        end

        -- Crates
        LootCrate.DrawAll(shared)

        -- Enemies
        Enemy.DrawAll(shared)

        -- Player
        Player.Draw(shared.player, shared)

        -- Projectiles
        Projectile.DrawAll(shared)

        -- === PARTICLES LAYER ===
        Drawing.SetLayer("particles")
        Particles.DrawAll(shared)

        -- === UI LAYER ===
        Drawing.SetLayer("ui")

        local p = shared.player

        -- HP bar
        local hpBarW = 120
        local hpBarH = 10
        UI.Rect(10, H - 30, hpBarW, hpBarH, _cHpBg)
        if p.alive and p.maxHp > 0 then
            local fill = math.max(0, p.hp / p.maxHp)
            UI.Rect(10, H - 30, math.floor(hpBarW * fill), hpBarH, _cHpFg)
        end
        Drawing.Text("HP: " .. math.max(0, p.hp) .. "/" .. p.maxHp, 12, H - 29, 9, C.WHITE)

        -- Ammo display
        if p.weapon then
            local wep = p.weapon
            local def = Config.WEAPONS[wep.id]
            Drawing.Text(def.name, 10, H - 50, 12, C.WHITE)
            if wep.reloading then
                local reloadPct = 1 - (wep.reloadTimer / def.reloadTime)
                UI.Rect(140, H - 30, 60, hpBarH, _cAmmoBg)
                UI.Rect(140, H - 30, math.floor(60 * reloadPct), hpBarH, _cAmmoFg)
                Drawing.Text("RELOADING", 142, H - 29, 9, _cReload)
            else
                Drawing.Text(wep.ammo .. "/" .. wep.maxAmmo, 140, H - 29, 10, C.YELLOW)
            end
        end

        -- Extraction timer
        if shared.extracting then
            local barW = 200
            local barH = 16
            local barX = math.floor(W / 2) - 100
            local barY = math.floor(H * 0.75)
            UI.Rect(barX, barY, barW, barH, _cExtractBarBg)
            local fill = math.min(1, shared.extractTimer / Config.EXTRACT_TIME)
            UI.Rect(barX, barY, math.floor(barW * fill), barH, _cExtractBar)
            Drawing.Text("EXTRACTING...", barX + 60, barY + 2, 12, C.WHITE)
        end

        -- Backpack display
        if _showBackpack then
            local bpW = 220
            local bpH = 100
            local bpX = math.floor(W / 2) - bpW / 2
            local bpY = 60
            UI.Rect(bpX, bpY, bpW, bpH, _cBackpackBg)
            Drawing.Text("BACKPACK", bpX + 70, bpY + 4, 14, C.WHITE)

            local slotSize = 30
            local gap = 4
            local startX = bpX + 10
            local startY = bpY + 24
            for i = 1, Config.BACKPACK_SIZE do
                local sx = startX + (i - 1) * (slotSize + gap)
                UI.Rect(sx, startY, slotSize, slotSize, _cSlotBg)
                local slot = shared.backpack.slots[i]
                if slot then
                    local lootDef = Config.LOOT_ITEMS[slot.id]
                    if lootDef then
                        local c = lootDef.color
                        UI.Rect(sx + 5, startY + 5, slotSize - 10, slotSize - 10, Color.New(c[1], c[2], c[3]))
                    end
                    if slot.count > 1 then
                        Drawing.Text(tostring(slot.count), sx + 2, startY + slotSize - 11, 9, C.WHITE)
                    end
                end
                if UI.IsHovered(sx, startY, slotSize, slotSize) and slot then
                    local lootDef = Config.LOOT_ITEMS[slot.id]
                    local name = lootDef and lootDef.name or slot.id
                    UI.Tooltip(name .. " x" .. slot.count)
                end
            end

            -- Instructions
            Drawing.Text("Press F near items to pick up", bpX + 30, startY + slotSize + 8, 10, C.GRAY)
        end

        -- Minimap (top-right corner)
        local mmSize = 100
        local mmX = W - mmSize - 10
        local mmY = 10
        UI.Rect(mmX, mmY, mmSize, mmSize, _cMinimapBg)

        -- Draw minimap tiles (1 pixel per tile, centered on player)
        local pTX = math.floor((p.x + p.w / 2) / TS)
        local pTY = math.floor((p.y + p.h / 2) / TS)
        local mmHalf = math.floor(mmSize / 2)

        local mmFloor = isForest and _cMinimapForestFloor or _cMinimapFloor
        local mmWall = isForest and _cMinimapForestWall or Color.New(50, 48, 44)
        for my = 0, mmSize - 1 do
            for mx = 0, mmSize - 1 do
                local tx = pTX - mmHalf + mx
                local ty = pTY - mmHalf + my
                local tile = Tilemap.Get(tx, ty)
                if tile == Config.FLOOR then
                    R(_ps, mmX + mx, mmY + my, 1, 1, mmFloor)
                elseif tile == Config.WALL then
                    R(_ps, mmX + mx, mmY + my, 1, 1, mmWall)
                end
            end
        end

        -- Extraction zones on minimap
        for _, zone in ipairs(shared.extractZones) do
            local zMX = mmX + mmHalf + (zone.x + zone.w / 2 - pTX)
            local zMY = mmY + mmHalf + (zone.y + zone.h / 2 - pTY)
            if zMX >= mmX and zMX < mmX + mmSize and zMY >= mmY and zMY < mmY + mmSize then
                R(_ps, math.floor(zMX) - 1, math.floor(zMY) - 1, 3, 3, _cMinimapExtract)
            end
        end

        -- Enemies on minimap
        for _, e in ipairs(shared.enemies) do
            if e.alive then
                local eMX = mmX + mmHalf + math.floor(e.x / TS) - pTX
                local eMY = mmY + mmHalf + math.floor(e.y / TS) - pTY
                if eMX >= mmX and eMX < mmX + mmSize and eMY >= mmY and eMY < mmY + mmSize then
                    R(_ps, eMX, eMY, 1, 1, _cMinimapEnemy)
                end
            end
        end

        -- Player dot on minimap (center)
        R(_ps, mmX + mmHalf, mmY + mmHalf, 2, 2, _cMinimapPlayer)

        -- Raid end overlay
        if shared.raidOver then
            UI.Rect(0, 0, W, H, Color.New(0, 0, 0, math.floor(150 * math.min(1, _raidEndTimer))))
            if shared.raidResult == "extracted" then
                Drawing.Text("EXTRACTED!", math.floor(W / 2) - 60, math.floor(H / 2), 24, C.GREEN)
            else
                Drawing.Text("YOU DIED", math.floor(W / 2) - 50, math.floor(H / 2), 24, C.RED)
            end
        end

        UI.DrawTooltip()
        UI.Flush()
        Drawing.ResetLayer()
    end
})

RaidScene:registerAsScene("eod_raid")

return RaidScene
