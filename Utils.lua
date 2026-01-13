local addonName, addon = ...

function addon:SpellName(spellID)
    local name = GetSpellInfo(spellID)
    return name
end

function addon:IsSpellLearned(spellID)
    local name = addon:SpellName(spellID)
    if not name then return false end

    for tab = 1, GetNumSpellTabs() do
        local _, _, offset, numSpells = GetSpellTabInfo(tab)
        for i = offset + 1, offset + numSpells do
            local spellName = GetSpellBookItemName(i, BOOKTYPE_SPELL)
            if spellName == name then
                return true
            end
        end
    end
    return false
end

function addon:IsSpellReady(spellID)
    local name = addon:SpellName(spellID)
    if not name then return false end
    if not addon:IsSpellLearned(spellID) then return false end

    local usable = IsUsableSpell(name)
    if not usable then return false end

    local start, duration = GetSpellCooldown(name)
    if start and duration and duration > 1.5 then return false end
    return true
end

function addon:CooldownRemaining(spellID)
    local name = addon:SpellName(spellID)
    if not name then return 999 end
    local start, duration = GetSpellCooldown(name)
    if not start or start == 0 then return 0 end
    local r = (start + duration - GetTime())
    if r < 0 then r = 0 end
    return r
end

function addon:UnitDebuffRemaining(unit, spellID)
    local name = addon:SpellName(spellID)
    if not name then return false, 0 end
    for i = 1, 40 do
        local dName, _, _, _, _, _, expirationTime, caster = UnitDebuff(unit, i)
        if not dName then break end
        if dName == name and caster == "player" then
            local remaining = expirationTime and (expirationTime - GetTime()) or 0
            if remaining < 0 then remaining = 0 end
            return true, remaining
        end
    end
    return false, 0
end

function addon:UnitBuffRemaining(unit, spellID)
    local name = addon:SpellName(spellID)
    if not name then return false, 0 end
    for i = 1, 40 do
        local bName, _, _, _, _, _, expirationTime = UnitBuff(unit, i)
        if not bName then break end
        if bName == name then
            local remaining = expirationTime and (expirationTime - GetTime()) or 999
            if remaining < 0 then remaining = 0 end
            return true, remaining
        end
    end
    return false, 0
end

function addon:IsInMeleeRange()
    if not UnitExists("target") then return false end
    local name = addon:SpellName(addon.spells.HeroicStrike)
    if not name then return false end
    return IsSpellInRange(name, "target") == 1
end

function addon:Rage()
    return UnitPower("player", 1) or UnitMana("player") or 0
end

function addon:TargetHPPercent()
    if not UnitExists("target") then return 100 end
    local maxhp = UnitHealthMax("target")
    if not maxhp or maxhp == 0 then return 100 end
    return (UnitHealth("target") / maxhp) * 100
end

function addon:GetKeybind(spellID)
    local name = GetSpellInfo(spellID)
    if not name then return "" end

    for slot = 1, 120 do
        local actionType, id = GetActionInfo(slot)
        if actionType == "spell" and id == spellID then
            local btn = ((slot - 1) % 12) + 1
            local key1, key2 = GetBindingKey("ACTIONBUTTON" .. btn)
            local key = key1 or key2
            if key then
                key = key:gsub("SHIFT%-", "S-")
                key = key:gsub("CTRL%-", "C-")
                key = key:gsub("ALT%-", "A-")
                return key
            end
        end
    end

    return ""
end