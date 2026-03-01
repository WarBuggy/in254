-- ============================================
-- Terraria2D — Config
-- All game constants
-- ============================================

local Config = {}

-- Screen
Config.SCREEN_W = 800
Config.SCREEN_H = 600

-- Tiles
Config.TILE_SIZE = 8

-- World dimensions (in tiles)
Config.WORLD_W = 400
Config.WORLD_H = 200

-- World dimensions (in pixels)
Config.WORLD_PX_W = Config.WORLD_W * Config.TILE_SIZE
Config.WORLD_PX_H = Config.WORLD_H * Config.TILE_SIZE

-- Terrain generation
Config.SURFACE_Y = 60
Config.DIRT_DEPTH = 5
Config.OBSIDIAN_Y = 195

-- Biome boundaries (tile X)
Config.BIOME_FOREST = 100
Config.BIOME_PLAINS = 200
Config.BIOME_DESERT = 300

-- Physics
Config.GRAVITY = 600
Config.JUMP_VEL = -280
Config.PLAYER_SPEED = 150
Config.TERMINAL_VEL = 500

-- Player
Config.PLAYER_W = 12
Config.PLAYER_H = 24
Config.PLAYER_HP = 100
Config.PLAYER_MANA = 50
Config.REACH_DIST = 5
Config.INVINCIBILITY_TIME = 1.0
Config.RESPAWN_TIME = 3.0

-- Mining
Config.MINE_RATE = 1.0

-- Day/Night
Config.DAY_LENGTH = 120
Config.NIGHT_START = 0.5

-- Lighting
Config.MAX_LIGHT = 15
Config.TORCH_LIGHT = 10

-- Spawning
Config.SPAWN_RATE = 3.0
Config.MAX_ENEMIES = 15
Config.SPAWN_RANGE = 300
Config.DESPAWN_RANGE = 600

-- Drops
Config.PICKUP_RANGE = 40
Config.PICKUP_MAGNET = 80
Config.DROP_VEL = -150

-- Combat
Config.KNOCKBACK = 200

-- Boss
Config.BOSS_HP = 1000
Config.BOSS_SIZE = 40

return Config
