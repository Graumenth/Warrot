local addonName, addon = ...

local Fury = {}
addon.rotations.fury = Fury

function Fury:Build(out, maxLen, s)
    local db = addon.db.fury
    local sp = addon.spells

    local function Add(id)
        if #out >= maxLen then return end
        out[#out + 1] = id
    end

    if db.useExecute and addon:IsSpellReady(sp.Execute) and (s.hp <= 20 or s.suddenDeath) then
        Add(sp.Execute)
    end

    if db.useDeathWish and addon:IsSpellReady(sp.DeathWish) then
        Add(sp.DeathWish)
    end

    if db.useRecklessness and addon:IsSpellReady(sp.Recklessness) then
        Add(sp.Recklessness)
    end

    if db.useBloodthirst and addon:IsSpellReady(sp.Bloodthirst) then
        Add(sp.Bloodthirst)
    end

    if db.useWhirlwind and addon:IsSpellReady(sp.Whirlwind) then
        Add(sp.Whirlwind)
    end

    if addon:IsSpellReady(sp.Slam) and s.bloodsurge then
        Add(sp.Slam)
    end

    if addon:IsSpellReady(sp.HeroicStrike) and s.rage >= (db.hsRageThreshold or 50) then
        Add(sp.HeroicStrike)
    end
end