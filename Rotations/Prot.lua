local addonName, addon = ...

local Prot = {}
addon.rotations.prot = Prot

function Prot:Build(out, maxLen, s)
    local db = addon.db.prot
    local sp = addon.spells

    local function Add(id)
        if #out >= maxLen then return end
        out[#out + 1] = id
    end

    if db.useShieldSlam and addon:IsSpellReady(sp.ShieldSlam) then
        Add(sp.ShieldSlam)
    end

    if db.useRevenge and addon:IsSpellReady(sp.Revenge) then
        Add(sp.Revenge)
    end

    if db.useShockwave and addon:IsSpellReady(sp.Shockwave) then
        Add(sp.Shockwave)
    end

    if db.useConcussionBlow and addon:IsSpellReady(sp.ConcussionBlow) then
        Add(sp.ConcussionBlow)
    end

    if db.useDevastate and addon:IsSpellReady(sp.Devastate) then
        Add(sp.Devastate)
    end

    if addon:IsSpellReady(sp.SunderArmor) then
        Add(sp.SunderArmor)
    end

    if addon:IsSpellReady(sp.HeroicStrike) and s.rage >= (db.hsRageThreshold or 60) then
        Add(sp.HeroicStrike)
    end
end