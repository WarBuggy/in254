-- ============================================
-- Terraria2D — Gameplay Root
-- Main scene tree, update loop
-- ============================================

local Theme = require("core/theme")
local UI = require("core/ui")
local Config = require("core/config")
local Camera = require("core/camera")
local Player = require("entities/player")
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

local GameplayRoot = SceneNode.new({
    name = "gameplay_root",
    shared = Theme.NewGameplayShared(),

    onEnter = function(self, shared)
        print("[Terraria2D] Generating world...")

        -- Generate world
        local spawnX, spawnY = WorldGen.Generate()
        shared.spawnX = spawnX
        shared.spawnY = spawnY

        -- Create player
        shared.player = Player.new(spawnX, spawnY)

        -- Initialize inventory with starter items
        shared.inventory = Inventory.New()
        Inventory.Add(shared.inventory, "wooden_sword", 1)
        Inventory.Add(shared.inventory, "torch", 50)
        Inventory.Add(shared.inventory, "wood", 10)

        -- Initialize camera
        local TS = Config.TILE_SIZE
        Camera.Snap(
            spawnX * TS - shared.W / 2,
            spawnY * TS - shared.H / 2
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

        -- Generate initial light map
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

        -- Day/Night
        DayNight.Update(dt, shared)

        -- Player dead? Handle respawn timer
        local p = shared.player
        if not p.alive then
            shared.respawnTimer = shared.respawnTimer - dt
            if shared.respawnTimer <= 0 then
                Player.Respawn(p, shared)
            end
            Camera.Update(dt)
            return
        end

        -- Player update
        Player.Update(p, dt, shared)

        -- Enemy updates
        Enemy.UpdateAll(shared, dt)

        -- Spawning
        Spawning.Update(shared, dt)

        -- Projectiles
        Projectile.UpdateAll(shared, dt)

        -- Particles
        Particles.UpdateAll(shared, dt)

        -- Drops
        Drops.UpdateAll(shared, dt)

        -- NPCs
        NPC.UpdateAll(shared, dt)

        -- Boss
        if shared.boss then
            Boss.Update(shared, dt)
        end

        -- Recalculate lighting periodically (every 0.5s for performance)
        shared.lightTimer = (shared.lightTimer or 0) + dt
        if shared.lightTimer >= 0.5 then
            shared.lightTimer = 0
            Lighting.Calculate(shared)
        end
    end,

    onDraw = function(self, shared)
        if not UI.ResolvePixel() then return end
        if not Theme.ResolveTextures(shared) then return end

        shared.W = Screen.Width()
        shared.H = Screen.Height()

        -- World tiles
        WorldView.Draw(shared)

        -- Drops
        Drops.DrawAll(shared)

        -- NPCs
        NPC.DrawAll(shared)

        -- Enemies
        Enemy.DrawAll(shared)

        -- Player
        Player.Draw(shared.player, shared)

        -- Projectiles
        Projectile.DrawAll(shared)

        -- Particles
        Particles.DrawAll(shared)

        -- Boss
        if shared.boss then
            Boss.Draw(shared)
        end

        -- HUD (always on top)
        HUD.Draw(shared)

        -- Death overlay
        if not shared.player.alive then
            UI.Rect(0, 0, shared.W, shared.H, {180, 0, 0, 80})
            Text.Draw("YOU DIED", shared.W / 2 - 60, shared.H / 2 - 20, 28, {255, 50, 50})
            local remaining = math.ceil(shared.respawnTimer)
            Text.Draw("Respawning in " .. remaining .. "...", shared.W / 2 - 70, shared.H / 2 + 20, 14, {200, 200, 200})
        end

        -- Overlays
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
    end
})

GameplayRoot:registerAsScene("gameplay")

return GameplayRoot
