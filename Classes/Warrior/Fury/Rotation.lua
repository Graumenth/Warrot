local addonName, addon = ...

addon.rotations = addon.rotations or {}

local Fury = {}
addon.rotations.fury = Fury

local PRIORITY = {
    EXECUTE = 100,
    BLOODSURGE_SLAM = 95,
    BLOODTHIRST = 90,
    WHIRLWIND = 85,
    DEATH_WISH = 80,
    BERSERKER_RAGE = 75,
    RECKLESSNESS = 70,
    HEROIC_STRIKE = 50,
}

function Fury:Build(queue, maxLen, state, Add)
    local db = addon.db.fury
    local sp = addon.spells
    
    if not db.enabled then return end
    
    local rage = state.rage
    local btReady = addon:IsSpellReady(sp.Bloodthirst)
    local btCooldown = addon:CooldownRemaining(sp.Bloodthirst)
    local wwReady = addon:IsSpellReady(sp.Whirlwind)
    local wwCooldown = addon:CooldownRemaining(sp.Whirlwind)
    
    if db.useExecute and state.executePhase and addon:IsSpellReady(sp.Execute) then
        if rage >= 15 or state.suddenDeath then
            Add(queue, sp.Execute, PRIORITY.EXECUTE, maxLen)
        end
    end
    
    if db.useSlam and state.bloodsurge and addon:IsSpellReady(sp.Slam) then
        Add(queue, sp.Slam, PRIORITY.BLOODSURGE_SLAM, maxLen)
    end
    
    if db.useDeathWish and addon:IsSpellReady(sp.DeathWish) and state.inCombat then
        if rage >= addon:GetRageCost(sp.DeathWish) then
            Add(queue, sp.DeathWish, PRIORITY.DEATH_WISH, maxLen)
        end
    end
    
    if db.useBerserkerRage and addon:IsSpellReady(sp.BerserkerRage) then
        if state.stance == "berserker" then
            Add(queue, sp.BerserkerRage, PRIORITY.BERSERKER_RAGE, maxLen)
        end
    end
    
    if db.useRecklessness and addon:IsSpellReady(sp.Recklessness) and state.inCombat then
        if state.stance == "berserker" then
            local deathWishActive = addon:HasBuff("player", sp.DeathWish)
            if deathWishActive then
                Add(queue, sp.Recklessness, PRIORITY.RECKLESSNESS, maxLen)
            end
        end
    end
    
    if db.useBloodthirst and btReady then
        if rage >= addon:GetRageCost(sp.Bloodthirst) then
            Add(queue, sp.Bloodthirst, PRIORITY.BLOODTHIRST, maxLen)
        end
    end
    
    if db.useWhirlwind and wwReady then
        if rage >= addon:GetRageCost(sp.Whirlwind) then
            local btSoon = btCooldown > 0 and btCooldown < 1
            if not btSoon or rage >= 45 then
                Add(queue, sp.Whirlwind, PRIORITY.WHIRLWIND, maxLen)
            end
        end
    end
    
    if db.useHeroicStrike then
        local hsThreshold = db.hsRageThreshold or 50
        
        if state.executePhase then
            hsThreshold = 30
        end
        
        if rage >= hsThreshold then
            Add(queue, sp.HeroicStrike, PRIORITY.HEROIC_STRIKE, maxLen)
        end
    end
    
    self:AddUpcoming(queue, maxLen, state, Add)
end

function Fury:AddUpcoming(queue, maxLen, state, Add)
    local db = addon.db.fury
    local sp = addon.spells
    
    if #queue >= maxLen then return end
    
    local window = addon.db.engine.predictionWindow or 1.5
    
    if db.useBloodthirst and addon:SpellWillBeReady(sp.Bloodthirst, window) then
        Add(queue, sp.Bloodthirst, PRIORITY.BLOODTHIRST - 10, maxLen)
    end
    
    if db.useWhirlwind and addon:SpellWillBeReady(sp.Whirlwind, window) then
        Add(queue, sp.Whirlwind, PRIORITY.WHIRLWIND - 10, maxLen)
    end
end