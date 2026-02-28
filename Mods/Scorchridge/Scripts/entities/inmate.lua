-- ============================================
-- Scorchridge — InmateClass
-- Extends Character (inherits on/off/fire/isHovered/hitbox).
-- ============================================

local Character = require("entities/character")
local SFX = require("core/sound")

local InmateClass = setmetatable({}, {__index = Character})
InmateClass.__index = InmateClass

function InmateClass.hydrate(t)
    if t and getmetatable(t) ~= InmateClass then
        setmetatable(t, InmateClass)
        t._handlers = t._handlers or {}
        t.w = t.w or 16
        t.h = t.h or 24
        t.scale = t.scale or 2
        t.visible = t.visible ~= false
    end
    return t
end

function InmateClass.hydrateAll(arr)
    if not arr then return end
    for i = 1, #arr do
        InmateClass.hydrate(arr[i])
    end
    return arr
end

-- ---- Work / Economy ----

function InmateClass:calculateWork(production)
    if not self.alive or self.exhausted then
        return 0, 0
    end

    local tierIndex = self.assignedTier or 1
    local tier = production.oreTiers[tierIndex]
    if not tier then
        tierIndex = 1
        tier = production.oreTiers[1]
    end

    local staCost = tier.staCost

    if self.stamina < staCost then
        if self.stamina >= production.oreTiers[1].staCost then
            tier = production.oreTiers[1]
            staCost = tier.staCost
            tierIndex = 1
        else
            self.exhausted = true
            return 0, 0
        end
    end

    self.stamina = self.stamina - staCost

    local staBracket = (self.stamina > 50) and 10 or (self.stamina > 20) and 7 or 3
    local morBracket = (self.morale > 100) and 1.5 or (self.morale > 50) and 1.0 or 0.6
    local staminaPoints = math.max(1, math.floor(self.stamina / 10))
    local credits = math.floor(staminaPoints * staBracket * tier.mult * morBracket)
    credits = math.max(1, credits)
    self.credits = self.credits + credits

    if self.stamina <= 5 then
        self.exhausted = true
    end

    return credits, tierIndex
end

function InmateClass:processMeal(portionConfig)
    if not self.alive then return 0 end

    self.stamina = math.min(self.stamina + portionConfig.staRec, self.maxStamina)
    self.morale = math.min(self.morale + portionConfig.morRec, self.maxMorale)
    self.exhausted = false

    return portionConfig.pcho
end

function InmateClass:applyMoraleDecay()
    if not self.alive then return end

    local decay = 3
    self.morale = math.max(self.morale - decay, 0)

    if self.credits > 0 then
        self.morale = math.min(self.morale + 2, self.maxMorale)
    end
end

function InmateClass:getStatus()
    return Localize("scorchridge.inmate.status",
        self.name,
        tostring(math.floor(self.stamina)),
        tostring(math.floor(self.morale)),
        tostring(self.credits))
end

function InmateClass:previewWork(production, tierIndex)
    if not self.alive or self.exhausted then
        return 0, 0, false
    end

    local tier = production.oreTiers[tierIndex]
    if not tier then return 0, 0, false end

    local canWork = self.stamina >= tier.staCost
    if not canWork then return 0, tier.staCost, false end

    local staAfter = self.stamina - tier.staCost
    local staBracket = (staAfter > 50) and 10 or (staAfter > 20) and 7 or 3
    local morBracket = (self.morale > 100) and 1.5 or (self.morale > 50) and 1.0 or 0.6
    local staminaPoints = math.max(1, math.floor(staAfter / 10))
    local credits = math.max(1, math.floor(staminaPoints * staBracket * tier.mult * morBracket))
    return credits, tier.staCost, true
end

-- ---- Drug System ----

function InmateClass:administerDrug(resources)
    if not resources then
        return false, "Invalid target"
    end

    if not resources.drugSupply or resources.drugSupply <= 0 then
        return false, "No drug supply"
    end

    if self.dosedThisQuadrant then
        return false, "Already dosed this quadrant"
    end

    SFX.Drug()
    resources.drugSupply = resources.drugSupply - 1
    self.dosedThisQuadrant = true

    local eff = (self.drugEffectiveness or 100) / 100
    local staBost = math.floor(40 * eff)
    local morBoost = math.floor(25 * eff)

    self.stamina = math.min(self.stamina + staBost, self.maxStamina)
    self.morale = math.min(self.morale + morBoost, self.maxMorale)

    self.drugEffectiveness = math.max(0, (self.drugEffectiveness or 100) - 15)

    if not self.addicted and math.random() < 0.30 then
        self.addicted = true
        self.quadrantsClean = 0
    end

    self.quadrantsClean = 0

    return true, "Dosed: +" .. staBost .. " sta, +" .. morBoost .. " mor"
end

function InmateClass:processWithdrawal()
    if not self.alive then return end

    if self.addicted then
        if not self.dosedThisQuadrant then
            self.stamina = math.max(0, self.stamina - 10)
            self.morale = math.max(0, self.morale - 30)

            self.quadrantsClean = (self.quadrantsClean or 0) + 1

            if self.quadrantsClean >= 16 then
                self.addicted = false
                self.quadrantsClean = 0
                self.drugEffectiveness = math.min(100, (self.drugEffectiveness or 0) + 30)
            end
        else
            self.quadrantsClean = 0
        end
    end

    self.dosedThisQuadrant = false
end

-- ---- Wander / Idle Animation ----

function InmateClass:initWander()
    if not self._wander then
        self._wander = {
            x = 0, y = 0,
            tx = 0, ty = 0,
            timer = math.random() * 2,
            idleAnim = math.random() * 6,
            facing = 1,
            speed = 30 + math.random() * 20,
            settled = false,
            bounds = nil
        }
    end
    return self._wander
end

function InmateClass:wander()
    return self:initWander()
end

function InmateClass:updateWander(dt, bounds)
    local ws = self:initWander()
    if bounds then ws.bounds = bounds end
    ws.idleAnim = ws.idleAnim + dt

    if not ws.settled then
        ws.x = ws.tx
        ws.y = ws.ty
        ws.settled = true
    end

    local dx = ws.tx - ws.x
    local dy = ws.ty - ws.y
    local dist = math.sqrt(dx * dx + dy * dy)

    if dist > 2 then
        local step = ws.speed * dt
        if step > dist then step = dist end
        ws.x = ws.x + (dx / dist) * step
        ws.y = ws.y + (dy / dist) * step
        if math.abs(dx) > 1 then
            ws.facing = dx > 0 and 1 or -1
        end
    else
        ws.timer = ws.timer - dt
        if ws.timer <= 0 then
            local b = ws.bounds
            if b then
                ws.tx = b.x1 + math.random() * (b.x2 - b.x1)
                ws.ty = b.y1 + math.random() * (b.y2 - b.y1)
            end
            ws.timer = 1.5 + math.random() * 3
            ws.speed = 25 + math.random() * 25
        end
    end
end

function InmateClass:setWanderTarget(x, y)
    local ws = self:initWander()
    ws.tx = x
    ws.ty = y
    ws.settled = false
    ws.timer = 1 + math.random() * 2
end

function InmateClass:idleBob(scale)
    scale = scale or 1
    local ws = self:initWander()
    local breathe = math.sin(ws.idleAnim * 1.8) * 1.5 * scale
    local fidget = math.sin(ws.idleAnim * 0.4) * math.sin(ws.idleAnim * 1.1) * 1.0 * scale
    return breathe + fidget
end

return InmateClass
