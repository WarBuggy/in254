-- ============================================
-- Terraria2D — Day/Night Cycle
-- Timer, sky color interpolation
-- ============================================

local Config = require("core/config")
local Theme = require("core/theme")

local DayNight = {}

local time = 0 -- 0 to DAY_LENGTH

function DayNight.Init()
    time = 0
end

function DayNight.Update(dt, shared)
    time = time + dt
    if time >= Config.DAY_LENGTH then
        time = time - Config.DAY_LENGTH
    end

    local fraction = time / Config.DAY_LENGTH
    shared.dayTime = time
    shared.dayFraction = fraction
    shared.isNight = fraction >= Config.NIGHT_START

    -- Sky color interpolation
    local C = Theme.Colors
    local skyColor

    if fraction < 0.25 then
        -- Morning: day
        skyColor = C.SKY_DAY
    elseif fraction < 0.4 then
        -- Approaching sunset
        local t = (fraction - 0.25) / 0.15
        skyColor = Theme.LerpColor(C.SKY_DAY, C.SKY_SUNSET, t)
    elseif fraction < 0.5 then
        -- Sunset to night
        local t = (fraction - 0.4) / 0.1
        skyColor = Theme.LerpColor(C.SKY_SUNSET, C.SKY_NIGHT, t)
    elseif fraction < 0.85 then
        -- Night
        skyColor = C.SKY_NIGHT
    elseif fraction < 0.95 then
        -- Night to sunrise
        local t = (fraction - 0.85) / 0.1
        skyColor = Theme.LerpColor(C.SKY_NIGHT, C.SKY_SUNSET, t)
    else
        -- Sunrise to day
        local t = (fraction - 0.95) / 0.05
        skyColor = Theme.LerpColor(C.SKY_SUNSET, C.SKY_DAY, t)
    end

    shared.skyColor = skyColor
end

function DayNight.GetTime()
    return time
end

function DayNight.GetFraction()
    return time / Config.DAY_LENGTH
end

function DayNight.IsNight()
    return (time / Config.DAY_LENGTH) >= Config.NIGHT_START
end

function DayNight.GetTimeString()
    local fraction = time / Config.DAY_LENGTH
    local hours = math.floor(fraction * 24)
    local minutes = math.floor((fraction * 24 - hours) * 60)
    return string.format("%02d:%02d", hours, minutes)
end

return DayNight
