-- ============================================
-- ExtractOrDie — Config
-- All game constants
-- ============================================

local Config = {}

-- Screen
Config.SCREEN_W = 800
Config.SCREEN_H = 600

-- Tiles
Config.TILE_SIZE = 12
Config.MAP_W = 100
Config.MAP_H = 100
Config.MAP_PX_W = Config.MAP_W * Config.TILE_SIZE
Config.MAP_PX_H = Config.MAP_H * Config.TILE_SIZE

-- Tile IDs
Config.VOID = 0
Config.FLOOR = 1
Config.WALL = 2

-- BSP dungeon generation
Config.BSP_SPLITS = 6
Config.ROOM_MIN = 6
Config.ROOM_MAX = 14
Config.CORRIDOR_W = 3

-- Player (3/4 angled view — taller visual sprite)
Config.PLAYER_W = 10
Config.PLAYER_H = 14
Config.PLAYER_SPEED = 140
Config.PLAYER_HP = 100
Config.INVINCIBILITY_TIME = 0.5

-- Weapons
Config.WEAPONS = {
    pistol = {
        name = "Pistol", damage = 12, fireRate = 0.3, spread = 0.05,
        magSize = 12, reloadTime = 1.2, pellets = 1, speed = 400,
        color = {180, 180, 180},
    },
    smg = {
        name = "SMG", damage = 7, fireRate = 0.08, spread = 0.12,
        magSize = 30, reloadTime = 1.8, pellets = 1, speed = 380,
        color = {100, 100, 120},
    },
    shotgun = {
        name = "Shotgun", damage = 8, fireRate = 0.7, spread = 0.25,
        magSize = 6, reloadTime = 2.0, pellets = 5, speed = 350,
        color = {140, 100, 60},
    },
    rifle = {
        name = "Rifle", damage = 35, fireRate = 0.9, spread = 0.02,
        magSize = 5, reloadTime = 2.5, pellets = 1, speed = 500,
        color = {60, 80, 60},
    },
}

-- Enemies
Config.ENEMIES = {
    grunt = {
        name = "Grunt", hp = 30, speed = 60, damage = 15,
        w = 10, h = 12, color = {180, 60, 60},
        ai = "chase", drops = {
            { id = "scrap", count = 2, chance = 0.6 },
            { id = "medkit", count = 1, chance = 0.2 },
        },
    },
    shooter = {
        name = "Shooter", hp = 25, speed = 40, damage = 8,
        w = 10, h = 12, color = {60, 60, 180},
        ai = "ranged", preferredRange = 200, fireRate = 1.2,
        drops = {
            { id = "ammo_box", count = 1, chance = 0.4 },
            { id = "scrap", count = 1, chance = 0.5 },
        },
    },
    runner = {
        name = "Runner", hp = 15, speed = 130, damage = 10,
        w = 8, h = 10, color = {180, 180, 60},
        ai = "rush", drops = {
            { id = "scrap", count = 1, chance = 0.4 },
            { id = "gold_chain", count = 1, chance = 0.1 },
        },
    },
    brute = {
        name = "Brute", hp = 200, speed = 30, damage = 25,
        w = 16, h = 20, color = {120, 40, 40},
        ai = "brute",
        -- Ability: ground slam (AoE around self)
        slamRange = 60,         -- triggers when player within this distance
        slamRadius = 80,        -- AoE damage radius
        slamDamage = 30,
        slamCooldown = 4.0,     -- seconds between slams
        slamWindup = 0.6,       -- telegraph time before slam hits
        -- Ability: charge (bull rush)
        chargeSpeed = 250,
        chargeDuration = 0.5,
        chargeCooldown = 6.0,
        chargeRange = 250,      -- triggers when player in this range
        -- Enrage: below 50% HP
        enrageSpeedMult = 1.8,
        enrageCooldownMult = 0.6,
        drops = {
            { id = "diamond", count = 1, chance = 0.3 },
            { id = "gold_chain", count = 2, chance = 0.6 },
            { id = "circuit", count = 1, chance = 0.5 },
            { id = "medkit", count = 1, chance = 0.5 },
        },
    },
}

-- Spawning
Config.SPAWN_RATE = 4.0
Config.SPAWN_RATE_EXTRACT = 0.8
Config.MAX_ENEMIES = 20
Config.SPAWN_RANGE_MIN = 200
Config.SPAWN_RANGE_MAX = 400

-- Extraction
Config.EXTRACT_TIME = 5.0
Config.EXTRACT_ZONE_SIZE = 4  -- tiles

-- Inventory
Config.BACKPACK_SIZE = 6
Config.STASH_SIZE = 20
Config.MAX_STACK = 99

-- Pickup
Config.PICKUP_RANGE = 30

-- Dodge roll
Config.DODGE_SPEED = 350
Config.DODGE_DURATION = 0.2
Config.DODGE_COOLDOWN = 0.8
Config.DODGE_IFRAMES = 0.25

-- Combat
Config.KNOCKBACK = 120

-- Loot items
Config.LOOT_ITEMS = {
    scrap       = { name = "Scrap",       rarity = "common",   color = {150, 150, 130} },
    medkit      = { name = "Medkit",      rarity = "common",   color = {200, 60, 60},   healAmount = 30 },
    ammo_box    = { name = "Ammo Box",    rarity = "common",   color = {80, 120, 80} },
    gold_chain  = { name = "Gold Chain",  rarity = "uncommon", color = {220, 200, 50} },
    circuit     = { name = "Circuit",     rarity = "uncommon", color = {50, 200, 200} },
    diamond     = { name = "Diamond",     rarity = "rare",     color = {180, 220, 255} },
    smg         = { name = "SMG",         rarity = "uncommon", color = {100, 100, 120}, isWeapon = true },
    shotgun     = { name = "Shotgun",     rarity = "uncommon", color = {140, 100, 60},  isWeapon = true },
    rifle       = { name = "Rifle",       rarity = "rare",     color = {60, 80, 60},    isWeapon = true },
}

-- Loot crate tables (weighted)
Config.CRATE_LOOT = {
    { id = "scrap",      weight = 30 },
    { id = "medkit",     weight = 20 },
    { id = "ammo_box",   weight = 20 },
    { id = "gold_chain", weight = 10 },
    { id = "circuit",    weight = 10 },
    { id = "diamond",    weight = 3 },
    { id = "smg",        weight = 4 },
    { id = "shotgun",    weight = 4 },
    { id = "rifle",      weight = 2 },
}

-- Loot crates
Config.NUM_CRATES = 15
Config.CRATE_HP = 20

return Config
