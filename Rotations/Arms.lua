local addonName, addon = ...

local Arms = {}
addon.rotations.arms = Arms

function Arms:Build(out, maxLen, s)
    local db = addon.db.arms
    local sp = addon.spells

    local function Add(id)
        if #out >= maxLen then return end
        out[#out + 1] = id
    end

    if db.useExecute and addon:IsSpellReady(sp.Execute) and (s.hp <= 20 or s.suddenDeath) then
        Add(sp.Execute)
    end

    if db.useOverpower and addon:IsSpellReady(sp.Overpower) and s.tasteForBlood then
        Add(sp.Overpower)
    end

    if db.useRend and addon:IsSpellReady(sp.Rend) then
        if (not s.hasRend) or (s.rendRem < (db.rendRefresh or 5)) then
            Add(sp.Rend)
        end
    end

    if db.useMortalStrike and addon:IsSpellReady(sp.MortalStrike) then
        Add(sp.MortalStrike)
    end

    if db.useBladestorm and addon:IsSpellReady(sp.Bladestorm) then
        Add(sp.Bladestorm)
    end

    if addon:IsSpellReady(sp.Slam) then
        Add(sp.Slam)
    end

    if addon:IsSpellReady(sp.HeroicStrike) and s.rage >= (db.hsRageThreshold or 60) then
        Add(sp.HeroicStrike)
    end
end