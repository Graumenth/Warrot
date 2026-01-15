local addonName, addon = ...

addon.rotations = addon.rotations or {}

local Prot = {}
addon.rotations.prot = Prot

local PRIORITY = {
    SHIELD_BLOCK = 110,
    SHIELD_SLAM_PROC = 100,
    REVENGE = 95,
    SHIELD_SLAM = 90,
    SHOCKWAVE = 85,
    CONCUSSION_BLOW = 80,
    THUNDER_CLAP = 75,
    DEMO_SHOUT = 70,
    DEVASTATE = 65,
    HEROIC_STRIKE = 50,
    HEROIC_THROW = 40,
}

function Prot:Build(queue, maxLen, state, Add)
    local db = addon.db.prot
    local sp = addon.spells
    
    if not db.enabled then return end
    
    local rage = state.rage
    local ssReady = addon:IsSpellReady(sp.ShieldSlam)
    local ssCooldown = addon:CooldownRemaining(sp.ShieldSlam)
    
    if db.useShieldBlock and addon:IsSpellReady(sp.ShieldBlock) then
        if rage >= addon:GetRageCost(sp.ShieldBlock) then
            Add(queue, sp.ShieldBlock, PRIORITY.SHIELD_BLOCK, maxLen)
        end
    end
    
    if db.useShieldSlam and state.swordAndBoard and ssReady then
        if rage >= addon:GetRageCost(sp.ShieldSlam) then
            Add(queue, sp.ShieldSlam, PRIORITY.SHIELD_SLAM_PROC, maxLen)
        end
    end
    
    if db.useRevenge then
        if state.revengeUsable and addon:IsSpellReady(sp.Revenge) then
            if rage >= addon:GetRageCost(sp.Revenge) then
                Add(queue, sp.Revenge, PRIORITY.REVENGE, maxLen)
            end
        end
    end
    
    if db.useShieldSlam and ssReady and not state.swordAndBoard then
        if rage >= addon:GetRageCost(sp.ShieldSlam) then
            Add(queue, sp.ShieldSlam, PRIORITY.SHIELD_SLAM, maxLen)
        end
    end
    
    if db.useShockwave and addon:IsSpellReady(sp.Shockwave) then
        if rage >= addon:GetRageCost(sp.Shockwave) then
            Add(queue, sp.Shockwave, PRIORITY.SHOCKWAVE, maxLen)
        end
    end
    
    if db.useConcussionBlow and addon:IsSpellReady(sp.ConcussionBlow) then
        if rage >= addon:GetRageCost(sp.ConcussionBlow) then
            Add(queue, sp.ConcussionBlow, PRIORITY.CONCUSSION_BLOW, maxLen)
        end
    end
    
    if db.maintainDebuffs then
        if db.useThunderClap and addon:IsSpellReady(sp.ThunderClap) then
            local shouldTC = false
            if not state.hasThunderClap then
                shouldTC = true
            elseif state.thunderClapRemaining < 3 then
                shouldTC = true
            end
            
            if shouldTC and rage >= addon:GetRageCost(sp.ThunderClap) then
                if state.stance == "battle" or state.stance == "defensive" then
                    Add(queue, sp.ThunderClap, PRIORITY.THUNDER_CLAP, maxLen)
                end
            end
        end
        
        if db.useDemoralizingShout and addon:IsSpellReady(sp.DemoralizingShout) then
            local shouldDS = false
            if not state.hasDemoShout then
                shouldDS = true
            elseif state.demoShoutRemaining < 5 then
                shouldDS = true
            end
            
            if shouldDS and rage >= addon:GetRageCost(sp.DemoralizingShout) then
                Add(queue, sp.DemoralizingShout, PRIORITY.DEMO_SHOUT, maxLen)
            end
        end
    end
    
    if db.useDevastate and addon:IsSpellReady(sp.Devastate) then
        if rage >= addon:GetRageCost(sp.Devastate) then
            local priority = PRIORITY.DEVASTATE
            
            if (state.sunderStacks or 0) < 5 then
                priority = PRIORITY.SHIELD_SLAM + 1 
            end

            local ssSoon = ssCooldown > 0 and ssCooldown < 1.5
            if not ssSoon or rage >= 40 or priority > PRIORITY.DEVASTATE then
                Add(queue, sp.Devastate, priority, maxLen)
            end
        end
    end
    
    if db.useHeroicStrike then
        local hsThreshold = db.hsRageThreshold or 50
        if rage >= hsThreshold then
            local safeToHS = true
            if ssCooldown > 0 and ssCooldown < 1.5 and rage < 60 then
                safeToHS = false
            end
            
            if safeToHS then
                Add(queue, sp.HeroicStrike, PRIORITY.HEROIC_STRIKE, maxLen)
            end
        end
    end
    
    if db.useHeroicThrow and addon:IsSpellReady(sp.HeroicThrow) then
        if not state.inMelee then
            Add(queue, sp.HeroicThrow, PRIORITY.HEROIC_THROW, maxLen)
        end
    end
    
    self:AddUpcoming(queue, maxLen, state, Add)
end

function Prot:AddUpcoming(queue, maxLen, state, Add)
    local db = addon.db.prot
    local sp = addon.spells
    
    if #queue >= maxLen then return end
    
    local window = addon.db.engine.predictionWindow or 1.5
    
    if db.useShieldSlam and addon:SpellWillBeReady(sp.ShieldSlam, window) then
        Add(queue, sp.ShieldSlam, PRIORITY.SHIELD_SLAM - 10, maxLen)
    end
    
    if db.useRevenge and addon:SpellWillBeReady(sp.Revenge, window) then
        Add(queue, sp.Revenge, PRIORITY.REVENGE - 10, maxLen)
    end
    
    if db.useShockwave and addon:SpellWillBeReady(sp.Shockwave, window) then
        Add(queue, sp.Shockwave, PRIORITY.SHOCKWAVE - 10, maxLen)
    end
end