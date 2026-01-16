local addonName, addon = ...

addon.rotations = addon.rotations or {}

local Fury = {}
addon.rotations.fury = Fury

function Fury:GetNextAction(state)
    local db = addon.db.fury
    local sp = addon.spells
    
    if sp.VictoryRush and state:CanCast(sp.VictoryRush) then
        return sp.VictoryRush
    end

    if sp.Bloodrage and state.rage < 30 and state:CanCast(sp.Bloodrage) then
        return sp.Bloodrage
    end
    
    if sp.Slam and state:HasBuff(sp.Bloodsurge) and state:CanCast(sp.Slam) then
        return sp.Slam
    end
    
    if sp.Bloodthirst and state:CanCast(sp.Bloodthirst) then
        return sp.Bloodthirst
    end
    
    if sp.Whirlwind and state:CanCast(sp.Whirlwind) then
        return sp.Whirlwind
    end
    
    if sp.Execute and state.targetHP < 20 and state:CanCast(sp.Execute) then
        return sp.Execute
    end

    if sp.HeroicStrike and state.rage > 50 and state:CanCast(sp.HeroicStrike) then
        return sp.HeroicStrike
    end
    
    return nil
end