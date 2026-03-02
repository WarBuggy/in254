-- ============================================
-- ExtractOrDie — Weapons Registry
-- Weapon definitions and state management
-- ============================================

local Config = require("eod/core/config")

local Weapons = {}

function Weapons.GetDef(weaponId)
    return Config.WEAPONS[weaponId]
end

-- Create weapon state for a raid
function Weapons.NewState(weaponId)
    local def = Config.WEAPONS[weaponId]
    if not def then return nil end
    return {
        id = weaponId,
        ammo = def.magSize,
        maxAmmo = def.magSize,
        fireTimer = 0,
        reloading = false,
        reloadTimer = 0,
    }
end

function Weapons.Update(wep, dt)
    if not wep then return end

    -- Fire cooldown
    if wep.fireTimer > 0 then
        wep.fireTimer = wep.fireTimer - dt
    end

    -- Reload
    if wep.reloading then
        wep.reloadTimer = wep.reloadTimer - dt
        if wep.reloadTimer <= 0 then
            wep.ammo = wep.maxAmmo
            wep.reloading = false
        end
    end
end

function Weapons.CanFire(wep)
    if not wep then return false end
    return wep.fireTimer <= 0 and wep.ammo > 0 and not wep.reloading
end

function Weapons.Fire(wep)
    if not wep then return end
    local def = Config.WEAPONS[wep.id]
    wep.ammo = wep.ammo - 1
    wep.fireTimer = def.fireRate
end

function Weapons.StartReload(wep)
    if not wep or wep.reloading or wep.ammo == wep.maxAmmo then return end
    local def = Config.WEAPONS[wep.id]
    wep.reloading = true
    wep.reloadTimer = def.reloadTime
end

return Weapons
