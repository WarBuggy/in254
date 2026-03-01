-- ============================================
-- ScorchridgeV2 — InmateClass
-- Inmate stats, work/meal/drug mechanics
-- Reused from V1 with minimal changes
-- ============================================

local SFX = require("core/sound")
local Inventory = require("systems/inventory")

local InmateClass = {}
InmateClass.__index = InmateClass

function InmateClass.hydrate(t)
    if t and getmetatable(t) ~= InmateClass then
        setmetatable(t, InmateClass)
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

function InmateClass:processMeal(portionConfig, hasPcho)
    if not self.alive then return 0 end

    self.stamina = math.min(self.stamina + portionConfig.staRec, self.maxStamina)
    self.morale = math.min(self.morale + portionConfig.morRec, self.maxMorale)
    self.exhausted = false

    if hasPcho then
        self.stamina = math.min(self.stamina + 15, self.maxStamina)
        self.morale = math.min(self.morale + 5, self.maxMorale)
    end

    return portionConfig.food
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
    return self.name ..
        " | STA:" .. math.floor(self.stamina) .. "/" .. self.maxStamina ..
        " MOR:" .. math.floor(self.morale) .. "/" .. self.maxMorale ..
        " CRD:" .. self.credits
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

function InmateClass:administerDrug()
    if not Inventory.HasStock("drug_dose", 1) then
        return false, "No drug supply"
    end

    if self.dosedThisQuadrant then
        return false, "Already dosed this quadrant"
    end

    SFX.Drug()
    Inventory.Consume("drug_dose", 1)
    self.dosedThisQuadrant = true

    local eff = (self.drugEffectiveness or 100) / 100
    local staBoost = math.floor(40 * eff)
    local morBoost = math.floor(25 * eff)

    self.stamina = math.min(self.stamina + staBoost, self.maxStamina)
    self.morale = math.min(self.morale + morBoost, self.maxMorale)

    self.drugEffectiveness = math.max(0, (self.drugEffectiveness or 100) - 15)

    if not self.addicted and math.random() < 0.30 then
        self.addicted = true
        self.quadrantsClean = 0
    end

    self.quadrantsClean = 0

    return true, "Dosed: +" .. staBoost .. " sta, +" .. morBoost .. " mor"
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

-- ---- Idle Animation ----

function InmateClass:initIdle()
    if not self._idle then
        self._idle = {
            timer = math.random() * 6,
        }
    end
    return self._idle
end

function InmateClass:updateIdle(dt)
    local idle = self:initIdle()
    idle.timer = idle.timer + dt
end

function InmateClass:idleBob(scale)
    scale = scale or 1
    local idle = self:initIdle()
    local breathe = math.sin(idle.timer * 1.8) * 1.5 * scale
    local fidget = math.sin(idle.timer * 0.4) * math.sin(idle.timer * 1.1) * 1.0 * scale
    return breathe + fidget
end

return InmateClass
