-- ============================================
-- Terraria2D — Gameplay Root
-- Main scene tree, update loop
-- ============================================

local Theme = require("core/theme")
local UI = require("core/ui")
local Config = require("core/config")
local Camera = require("core/camera")
local Player = require("entities/player")
local Tiles = require("world/tiles")
local WorldGen = require("world/worldgen")
local WorldData = require("world/worlddata")
local WorldView = require("scenes/gameplay/worldview")
local Inventory = require("systems/inventory")
local DayNight = require("systems/daynight")
local Lighting = require("world/lighting")
local Combat = require("systems/combat")
local Enemy = require("entities/enemy")
local Spawning = require("systems/spawning")
local Projectile = require("entities/projectile")
local Particles = require("entities/particles")
local Drops = require("systems/drops")
local NPC = require("entities/npc")
local Boss = require("systems/boss")
local HUD = require("scenes/gameplay/hud")
local InventoryUI = require("scenes/gameplay/inventoryui")
local CraftingUI = require("scenes/gameplay/craftingui")
local PauseUI = require("scenes/gameplay/pauseui")

-- Cached colors
local _cDeathOverlay = Color.New(180, 0, 0, 80)
local _cDeathText    = Color.New(255, 50, 50)
local _cRespawnText  = Color.New(200, 200, 200)

local GameplayRoot = Node.new({
    name = "gameplay_root",
    shared = Theme.NewGameplayShared(),

    onEnter = function(self, shared)
        print("[Terraria2D] Generating world...")

        -- Register render layers (priority order: lower = drawn first)
        Drawing.RegisterLayer("world", 0, { blend = "alpha" })
        Drawing.RegisterLayer("entities", 10, { blend = "alpha" })
        Drawing.RegisterLayer("particles", 20, { blend = "additive" })
        Drawing.RegisterLayer("ui", 30, { blend = "alpha" })

        -- Assign world layers to the main camera (UI stays at native resolution)
        GameCamera.AddLayer("world")
        GameCamera.AddLayer("entities")
        GameCamera.AddLayer("particles")

        -- Generate world
        local spawnX, spawnY = WorldGen.Generate()
        shared.spawnX = spawnX
        shared.spawnY = spawnY

        -- Create player
        shared.player = Player.new(spawnX, spawnY)

        -- Initialize inventory with starter items
        shared.inventory = Inventory.New()
        Inventory.Add(shared.inventory, "wood", 10)
        Inventory.Add(shared.inventory, "torch", 50)
        Inventory.Add(shared.inventory, "gun", 1)
        Inventory.Add(shared.inventory, "bullet", 30)
        Inventory.Add(shared.inventory, "wooden_sword", 1)
        -- Default to slot 1 (wood) so player can mine/place immediately

        -- Initialize camera (viewport in world coords = screen / zoom)
        local TS = Config.TILE_SIZE
        local viewW = shared.W / Camera.zoom
        local viewH = shared.H / Camera.zoom
        Camera.Snap(
            spawnX * TS - viewW / 2,
            spawnY * TS - viewH / 2
        )

        -- Initialize systems
        DayNight.Init()
        shared.enemies = {}
        shared.npcs = {}
        shared.projectiles = {}
        shared.particles = {}
        shared.drops = {}
        shared.boss = nil
        shared.showInventory = false
        shared.showCrafting = false
        shared.showPause = false
        shared.gameOver = false
        shared.respawnTimer = 0
        shared.mineTarget = nil
        shared.mineProgress = 0

        -- Generate initial light map (need W/H for viewport-culled lighting)
        shared.W = Screen.Width()
        shared.H = Screen.Height()
        Lighting.Calculate(shared)

        -- Spawn NPCs near spawn
        NPC.SpawnGuide(shared, spawnX + 5, spawnY)
        NPC.SpawnMerchant(shared, spawnX - 5, spawnY)

        print("[Terraria2D] World ready. Spawn at " .. spawnX .. "," .. spawnY)
    end,

    onExit = function(self, shared)
        shared.player = nil
        shared.enemies = {}
        shared.projectiles = {}
        shared.particles = {}
        shared.drops = {}
    end,

    onUpdate = function(self, dt, totalTime, shared)
        shared.W = Screen.Width()
        shared.H = Screen.Height()
        UI.UpdateInput()

        -- Pause toggle
        if Input.IsKeyPressed("escape") then
            if shared.showInventory then
                shared.showInventory = false
            elseif shared.showCrafting then
                shared.showCrafting = false
            elseif shared.showPause then
                shared.showPause = false
            else
                shared.showPause = true
            end
        end

        if shared.showPause then
            PauseUI.Update(shared)
            return
        end

        -- Inventory toggle
        if Input.IsKeyPressed("e") then
            shared.showInventory = not shared.showInventory
            shared.showCrafting = false
        end

        -- Crafting toggle
        if Input.IsKeyPressed("c") then
            shared.showCrafting = not shared.showCrafting
            shared.showInventory = false
        end

        -- If overlays are open, handle them but don't update game
        if shared.showInventory then
            InventoryUI.Update(shared)
            return
        end
        if shared.showCrafting then
            CraftingUI.Update(shared)
            return
        end

        -- Day/Night (visual timer, variable rate is fine)
        DayNight.Update(dt, shared)

        -- Recalc lighting when camera crosses a margin boundary or day/night changes
        local TS = Config.TILE_SIZE
        local camTX = math.floor(Camera.GetX() / TS)
        local camTY = math.floor(Camera.GetY() / TS)
        local tileMargin = 20
        local aTX = math.floor(camTX / tileMargin) * tileMargin
        local aTY = math.floor(camTY / tileMargin) * tileMargin
        local nightChanged = (shared.isNight ~= shared._prevIsNight)
        shared._prevIsNight = shared.isNight
        if aTX ~= (shared._lightATX or -1) or aTY ~= (shared._lightATY or -1) or nightChanged then
            shared._lightATX = aTX
            shared._lightATY = aTY
            Lighting.Calculate(shared)
        end
    end,

    onFixedUpdate = function(self, fixedDt, shared)
        if shared.showPause or shared.showInventory or shared.showCrafting then
            return
        end

        -- Player dead? Handle respawn timer
        local p = shared.player
        if not p.alive then
            shared.respawnTimer = shared.respawnTimer - fixedDt
            if shared.respawnTimer <= 0 then
                Player.Respawn(p, shared)
            end
            Camera.Update(fixedDt)
            return
        end

        -- Player update (input + physics + camera)
        Player.Update(p, fixedDt, shared)

        -- Enemy updates (AI + physics + combat)
        Enemy.UpdateAll(shared, fixedDt)

        -- Spawning
        Spawning.Update(shared, fixedDt)

        -- Projectiles
        Projectile.UpdateAll(shared, fixedDt)

        -- Particles
        Particles.UpdateAll(shared, fixedDt)

        -- Drops
        Drops.UpdateAll(shared, fixedDt)

        -- NPCs
        NPC.UpdateAll(shared, fixedDt)

        -- Boss
        if shared.boss then
            Boss.Update(shared, fixedDt)
        end
    end,

    onDraw = function(self, shared)
        if not UI.ResolvePixel() then return end
        if not Theme.ResolveTextures(shared) then return end

        -- One-time tile config (deferred until UI.ResolvePixel succeeds)
        if not shared._tileMapConfigured then
            Drawing.SetTileMap({
                tiles = WorldData.GetTiles(), tileData = Tiles.data,
                tileSize = Config.TILE_SIZE, worldW = Config.WORLD_W, worldH = Config.WORLD_H,
                pixelId = UI.GetPixelId(), maxLight = Config.MAX_LIGHT, surfaceY = Config.SURFACE_Y,
                tileMargin = 20, rebuildCooldown = 3,
            })
            shared._tileMapConfigured = true
        end

        -- Compute world-space camera bounds for viewport culling
        shared.camBounds = Camera.GetWorldBounds(shared.W, shared.H)

        -- World layer: sky + tiles + mining indicator
        Drawing.SetLayer("world")
        WorldView.Draw(shared)
        UI.Flush() -- flush world-layer rects (sky, mining indicator)

        -- Entities layer: all game objects
        Drawing.SetLayer("entities")
        Drops.DrawAll(shared)
        NPC.DrawAll(shared)
        Enemy.DrawAll(shared)
        Player.Draw(shared.player, shared)
        Projectile.DrawAll(shared)
        if shared.boss then
            Boss.Draw(shared)
        end

        -- Particles layer: additive blend for glow effects
        Drawing.SetLayer("particles")
        Particles.DrawAll(shared)

        -- UI layer: HUD, overlays, death screen (always on top)
        Drawing.SetLayer("ui")
        HUD.Draw(shared)

        if not shared.player.alive then
            UI.Rect(0, 0, shared.W, shared.H, _cDeathOverlay)
            Drawing.Text("YOU DIED", shared.W / 2 - 60, shared.H / 2 - 20, 28, _cDeathText)
            local remaining = math.ceil(shared.respawnTimer)
            Drawing.Text("Respawning in " .. remaining .. "...", shared.W / 2 - 70, shared.H / 2 + 20, 14, _cRespawnText)
        end

        if shared.showInventory then
            InventoryUI.Draw(shared)
        end
        if shared.showCrafting then
            CraftingUI.Draw(shared)
        end
        if shared.showPause then
            PauseUI.Draw(shared)
        end

        UI.DrawTooltip()
        UI.Flush() -- flush all UI-layer rects (HUD, overlays, tooltip)
        Drawing.ResetLayer()
    end
})

GameplayRoot:registerAsScene("gameplay")

return GameplayRoot
