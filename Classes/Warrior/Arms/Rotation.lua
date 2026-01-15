local addonName, addon = ...

addon.rotations = addon.rotations or {}

local Arms = {}
addon.rotations.arms = Arms

local PRIORITY = {
    EXECUTE_SD = 100,
    OVERPOWER = 95,
    EXECUTE = 90,
    MORTAL_STRIKE = 85,
    REND = 80,
    BLADESTORM = 75,
    SLAM = 70,
    HEROIC_STRIKE = 50,
}

function Arms:Build(queue, maxLen, state, Add)
    local db = addon.db.arms
    local sp = addon.spells
    
    if not db.enabled then return end

    if addon:IsSpellReady(sp.Charge) and state.stance == "battle" and addon:IsInRange(sp.Charge) and not addon:IsInRange(sp.MortalStrike) and state.hasTarget then
        Add(queue, sp.Charge, 200, maxLen) -- Give it the highest priority
        if not state.inCombat then
            return
        end
    end
    
    local rage = state.rage
    local msReady = addon:IsSpellReady(sp.MortalStrike)
    local msCooldown = addon:CooldownRemaining(sp.MortalStrike)
    local pooling = false
    
    if db.poolRageForMS and msCooldown > 0 and msCooldown < 2 then
        local needed = addon:GetRageCost(sp.MortalStrike)
        if rage < needed + 10 then
            pooling = true
        end
    end
    
    if db.useExecute and state.suddenDeath and addon:IsSpellReady(sp.Execute) then
        Add(queue, sp.Execute, PRIORITY.EXECUTE_SD, maxLen)
    end
    
    if db.useOverpower and addon:IsSpellReady(sp.Overpower) then
        if state.tasteForBlood or state.dodged then
            Add(queue, sp.Overpower, PRIORITY.OVERPOWER, maxLen)
        end
    end
    
    if db.useExecute and state.executePhase and addon:IsSpellReady(sp.Execute) then
        if rage >= 15 then
            Add(queue, sp.Execute, PRIORITY.EXECUTE, maxLen)
        end
    end
    
    if db.useMortalStrike and msReady then
        if rage >= addon:GetRageCost(sp.MortalStrike) then
            Add(queue, sp.MortalStrike, PRIORITY.MORTAL_STRIKE, maxLen)
        end
    end
    
    if db.useRend and addon:IsSpellReady(sp.Rend) and not pooling then
        local shouldRend = false
        if not state.hasRend then
            shouldRend = true
        elseif state.rendRemaining < (db.rendRefresh or 5) then
            shouldRend = true
        end
        
        if shouldRend and rage >= addon:GetRageCost(sp.Rend) then
            Add(queue, sp.Rend, PRIORITY.REND, maxLen)
        end
    end

    if db.useRend and addon.db and addon.db.debug then
        if not addon:IsSpellKnown(sp.Rend) then addon:Debug("Arms: Rend not known") end
        if not addon:IsSpellReady(sp.Rend) then addon:Debug("Arms: Rend not ready (cooldown or unusable)") end
        if pooling then addon:Debug("Arms: Not casting Rend because pooling for MS") end
    end
    
    if db.useBladestorm and addon:IsSpellReady(sp.Bladestorm) and not pooling then
        if rage >= addon:GetRageCost(sp.Bladestorm) and not state.executePhase then
            Add(queue, sp.Bladestorm, PRIORITY.BLADESTORM, maxLen)
        end
    end
    
    if db.useSlam and addon:IsSpellReady(sp.Slam) and not pooling then
        if not state.executePhase then
            if rage >= addon:GetRageCost(sp.Slam) then
                local msSoon = msCooldown > 0 and msCooldown < 1.5
                if not msSoon then
                    Add(queue, sp.Slam, PRIORITY.SLAM, maxLen)
                end
            end
        end
    end
    
    if db.useHeroicStrike and not pooling then
        local hsThreshold = db.hsRageThreshold or 60
        if state.executePhase then
            hsThreshold = db.hsExecuteThreshold or 30
        end
        
        if rage >= hsThreshold then
            Add(queue, sp.HeroicStrike, PRIORITY.HEROIC_STRIKE, maxLen)
        end
    end
    
    self:AddUpcoming(queue, maxLen, state, Add)
end

function Arms:AddUpcoming(queue, maxLen, state, Add)
    local db = addon.db.arms
    local sp = addon.spells
    
    if #queue >= maxLen then return end
    
    local window = addon.db.engine.predictionWindow or 1.5
    
    if db.useMortalStrike and addon:SpellWillBeReady(sp.MortalStrike, window) then
        Add(queue, sp.MortalStrike, PRIORITY.MORTAL_STRIKE - 10, maxLen)
    end
    
    if db.useOverpower and addon:SpellWillBeReady(sp.Overpower, window) then
        if state.tasteForBlood then
            Add(queue, sp.Overpower, PRIORITY.OVERPOWER - 10, maxLen)
        end
    end
end