local addonName, addon = ...

addon.rotations = addon.rotations or {}

local Prot = {}
addon.rotations.prot = Prot

local function EvaluateVariables(state, db)
    local vars = {}
    
    vars.should_sunder = db.maintainDebuffs
    vars.build_sunder = vars.should_sunder and (state.sunderStacks < 5)
    vars.maintain_sunder = vars.should_sunder and (state.sunderStacks == 5) and (state:GetDebuffRemains(addon.spells.SunderArmor) < 5)
    vars.emergency_sunder = vars.should_sunder and (state.sunderStacks > 0) and (state:GetDebuffRemains(addon.spells.SunderArmor) < 3)
    
    return vars
end

function Prot:GetNextAction(state)
    local db = addon.db.prot
    local sp = addon.spells
    
    local vars = EvaluateVariables(state, db)
    local active_enemies = 1 
    
    if sp.VictoryRush and state:CanCast(sp.VictoryRush) then
        return sp.VictoryRush
    end

    if sp.Bloodrage and state.rage < 30 and state:CanCast(sp.Bloodrage) then
        return sp.Bloodrage
    end
    
    local rageThreshold = db.hsRageThreshold or 50
    
    if state.rage >= rageThreshold then
        if active_enemies > 1 then
            if sp.Cleave and db.useHeroicStrike and state:CanCast(sp.Cleave) then 
                return sp.Cleave
            end
        else
            if sp.HeroicStrike and db.useHeroicStrike and state:CanCast(sp.HeroicStrike) then
                return sp.HeroicStrike
            end
        end
    end
    
    if sp.ShieldBlock and db.useShieldBlock and state:CanCast(sp.ShieldBlock) then
        if sp.ShieldSlam and state:IsKnown(sp.ShieldSlam) and state:GetCD(sp.ShieldSlam) < 2 then
            return sp.ShieldBlock
        end
    end

    if vars.emergency_sunder then
        if sp.Devastate and state:CanCast(sp.Devastate) then
            return sp.Devastate
        elseif sp.SunderArmor and state:CanCast(sp.SunderArmor) then
            return sp.SunderArmor
        end
    end

    if active_enemies > 1 then
        if sp.Shockwave and db.useShockwave and state:CanCast(sp.Shockwave) then
            return sp.Shockwave
        end
        
        if sp.ThunderClap and db.useThunderClap and state:CanCast(sp.ThunderClap) then
            return sp.ThunderClap
        end
        
        if sp.Revenge and db.useRevenge and state.revengeActive and state:CanCast(sp.Revenge) then
            return sp.Revenge
        end
        
        if sp.ShieldSlam and db.useShieldSlam and state:CanCast(sp.ShieldSlam) then
            return sp.ShieldSlam
        end
        
        if sp.Devastate and db.useDevastate and state:CanCast(sp.Devastate) then
            return sp.Devastate
        end
        
        if sp.SunderArmor and state:CanCast(sp.SunderArmor) then
            return sp.SunderArmor
        end

        return nil 
    end

    if sp.ShieldSlam and db.useShieldSlam and state:CanCast(sp.ShieldSlam) then
        return sp.ShieldSlam
    end
    
    if sp.Revenge and db.useRevenge and state.revengeActive and state:CanCast(sp.Revenge) then
        return sp.Revenge
    end
    
    if sp.Shockwave and db.useShockwave and state:CanCast(sp.Shockwave) then
        return sp.Shockwave
    end
    
    if sp.ConcussionBlow and db.useConcussionBlow and state:CanCast(sp.ConcussionBlow) then
        return sp.ConcussionBlow
    end
    
    if db.maintainDebuffs then
        if sp.DemoralizingShout and db.useDemoralizingShout and state:CanCast(sp.DemoralizingShout) then
            local demoRemains = state:GetDebuffRemains(sp.DemoralizingShout)
            if demoRemains < 3 then
                return sp.DemoralizingShout
            end
        end
        
        if sp.ThunderClap and db.useThunderClap and state:CanCast(sp.ThunderClap) then
            local tcRemains = state:GetDebuffRemains(sp.ThunderClap)
            if tcRemains < 3 then
                return sp.ThunderClap
            end
        end
    end
    
    if db.useDevastate then
        if sp.Devastate and state:IsKnown(sp.Devastate) then
            if state:CanCast(sp.Devastate) then
                return sp.Devastate
            end
        elseif sp.SunderArmor and state:IsKnown(sp.SunderArmor) and state:CanCast(sp.SunderArmor) then
            if state.sunderStacks < 5 or vars.maintain_sunder then
                return sp.SunderArmor
            end
        end
    end
    
    return nil
end