local addonName, addon = ...

addon.rotations = addon.rotations or {}

local Arms = {}
addon.rotations.arms = Arms

function Arms:GetNextAction(state)
    local db = addon.db.arms
    local sp = addon.spells
    
    if sp.VictoryRush and state:CanCast(sp.VictoryRush) then
        return sp.VictoryRush
    end

    if sp.Bloodrage and state.rage < 30 and state:CanCast(sp.Bloodrage) then
        return sp.Bloodrage
    end
    
    if sp.Execute and state.targetHP < 20 and state:CanCast(sp.Execute) then
        return sp.Execute
    end
    
    if sp.Overpower and state:CanCast(sp.Overpower) then
        if state:HasBuff(sp.TasteForBlood) or state:CanCast(sp.Overpower) then
            return sp.Overpower
        end
    end
    
    if sp.Rend and state:IsKnown(sp.Rend) and state:CanCast(sp.Rend) then
        if state:GetDebuffRemains(sp.Rend) < 3 then
            return sp.Rend
        end
    end
    
    if sp.MortalStrike and state:CanCast(sp.MortalStrike) then
        return sp.MortalStrike
    end
    
    if sp.Bladestorm and state:CanCast(sp.Bladestorm) then
        return sp.Bladestorm
    end
    
    if sp.Slam and state:CanCast(sp.Slam) then
        return sp.Slam
    end

    if sp.HeroicStrike and state.rage > 60 and state:CanCast(sp.HeroicStrike) then
        return sp.HeroicStrike
    end
    
    return nil
end