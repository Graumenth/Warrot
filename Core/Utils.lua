local addonName, addon = ...

local GetTime = GetTime
local UnitBuff = UnitBuff
local UnitDebuff = UnitDebuff
local GetSpellInfo = GetSpellInfo
local GetSpellCooldown = GetSpellCooldown
local IsUsableSpell = IsUsableSpell
local IsSpellInRange = IsSpellInRange
local UnitPower = UnitPower
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitExists = UnitExists
local UnitIsDead = UnitIsDead
local UnitCanAttack = UnitCanAttack
local UnitAffectingCombat = UnitAffectingCombat

function addon:SpellName(spellID)
    if not spellID then return nil end
    return GetSpellInfo(spellID)
end

function addon:SpellTexture(spellID)
    if not spellID then return nil end
    local _, _, tex = GetSpellInfo(spellID)
    return tex
end

function addon:IsSpellKnown(spellID)
    local name = addon:SpellName(spellID)
    if not name then return false end
    -- Compatibility: different clients expose different spellbook APIs. Try
    -- several possible functions to read a spell name from a spellbook slot.
    local function GetSpellBookName(slot)
        if type(GetSpellBookItemName) == "function" then
            return GetSpellBookItemName(slot, BOOKTYPE_SPELL)
        end
        if type(GetSpellName) == "function" then
            return GetSpellName(slot, BOOKTYPE_SPELL)
        end
        if type(GetSpellBookItemInfo) == "function" then
            local n = GetSpellBookItemInfo(slot)
            return n
        end
        return nil
    end

    -- If we have a cached known-spells table, use it
    if addon.knownSpells and addon.knownSpells[name] then
        return true
    end

    for tab = 1, (GetNumSpellTabs and GetNumSpellTabs() or 0) do
        local a,b,offset,numSpells = GetSpellTabInfo(tab)
        for i = (offset or 0) + 1, (offset or 0) + (numSpells or 0) do
            local spellName = GetSpellBookName(i)
            if spellName == name then
                return true
            end
        end
    end
    return false
end

function addon:RefreshKnownSpells()
    addon.knownSpells = addon.knownSpells or {}
    wipe(addon.knownSpells)
    local function GetSpellBookName(slot)
        if type(GetSpellBookItemName) == "function" then
            return GetSpellBookItemName(slot, BOOKTYPE_SPELL)
        end
        if type(GetSpellName) == "function" then
            return GetSpellName(slot, BOOKTYPE_SPELL)
        end
        if type(GetSpellBookItemInfo) == "function" then
            return GetSpellBookItemInfo(slot)
        end
        return nil
    end

    for tab = 1, (GetNumSpellTabs and GetNumSpellTabs() or 0) do
        local a,b,offset,numSpells = GetSpellTabInfo(tab)
        for i = (offset or 0) + 1, (offset or 0) + (numSpells or 0) do
            local spellName = GetSpellBookName(i)
            if spellName and spellName ~= "" then
                -- try to get spellID from link if possible
                local id
                local hasLink, link
                if type(GetSpellLink) == "function" then
                    link = GetSpellLink(i, BOOKTYPE_SPELL)
                    if link and type(link) == "string" then
                        id = tonumber(link:match("spell:(%d+)") )
                    end
                end

                -- fallback: try GetSpellBookItemInfo to get name and possibly id
                if not id and type(GetSpellBookItemInfo) == "function" then
                    local info = { GetSpellBookItemInfo(i) }
                    -- GetSpellBookItemInfo may return spellName as first return
                    -- and sometimes spellID as other returns in some clients; try to find number
                    for _, v in ipairs(info) do
                        if type(v) == "number" then id = v; break end
                    end
                end

                -- store highest id for this base name (strip rank from display name)
                local base = spellName:gsub("%s*%(.+%)", "")
                base = base:gsub("^%s+", ""):gsub("%s+$", "")
                addon.knownSpells[base] = addon.knownSpells[base] or {}
                if id then
                    addon.knownSpells[base].id = math.max(addon.knownSpells[base].id or 0, id)
                end
                addon.knownSpells[base].name = base
            end
        end
    end
    if addon.UpdateKnownSpellsUI then pcall(addon.UpdateKnownSpellsUI, addon) end
end

function addon:GetKnownSpells()
    local list = {}
    for name, info in pairs(addon.knownSpells or {}) do
        list[#list+1] = { name = name, id = info.id }
    end
    table.sort(list, function(a,b) return a.name < b.name end)
    return list
end

function addon:GetGCD()
    local start, duration = GetSpellCooldown(78)
    if not start or start == 0 then
        return 0, 0
    end
    return start, duration
end

function addon:GCDRemaining()
    local start, duration = addon:GetGCD()
    if start == 0 then return 0 end
    local remaining = (start + duration) - GetTime()
    return remaining > 0 and remaining or 0
end

function addon:IsGCDReady()
    return addon:GCDRemaining() < (addon.db.engine.gcdTolerance or 0.1)
end

function addon:GetCooldown(spellID)
    local name = addon:SpellName(spellID)
    if not name then return 0, 0, false end
    
    local start, duration, enabled = GetSpellCooldown(name)
    if not start then return 0, 0, false end
    
    return start, duration, enabled == 1
end

function addon:CooldownRemaining(spellID)
    local start, duration = addon:GetCooldown(spellID)
    if not start or start == 0 then return 0 end
    
    local remaining = (start + duration) - GetTime()
    if remaining < 0 then remaining = 0 end
    
    local gcdStart, gcdDuration = addon:GetGCD()
    if gcdStart > 0 and duration <= 1.5 then
        local gcdRemaining = (gcdStart + gcdDuration) - GetTime()
        if gcdRemaining > remaining then
            remaining = 0
        end
    end
    
    return remaining
end

function addon:IsSpellReady(spellID, ignoreGCD)
    local name = addon:SpellName(spellID)
    if not name then return false end
    if not addon:IsSpellKnown(spellID) then return false end
    
    local usable, noMana = IsUsableSpell(name)
    if not usable then return false end
    
    local cdRemaining = addon:CooldownRemaining(spellID)
    local threshold = ignoreGCD and 0 or (addon.db.engine.gcdTolerance or 0.1)
    
    return cdRemaining <= threshold
end

function addon:SpellWillBeReady(spellID, timeWindow)
    local cdRemaining = addon:CooldownRemaining(spellID)
    return cdRemaining <= (timeWindow or addon.db.engine.predictionWindow or 1.5)
end

function addon:HasBuff(unit, spellID)
    local name = addon:SpellName(spellID)
    if not name then return false, 0, 0 end
    
    for i = 1, 40 do
        local buffName, _, _, count, _, duration, expirationTime = UnitBuff(unit, i)
        if not buffName then break end
        if buffName == name then
            local remaining = expirationTime and (expirationTime - GetTime()) or 999
            if remaining < 0 then remaining = 0 end
            return true, remaining, count or 1
        end
    end
    return false, 0, 0
end

function addon:HasDebuff(unit, spellID, onlyMine)
    local name = addon:SpellName(spellID)
    if not name then return false, 0, 0 end
    
    for i = 1, 40 do
        local debuffName, _, _, count, _, duration, expirationTime, caster = UnitDebuff(unit, i)
        if not debuffName then break end
        if debuffName == name then
            if onlyMine and caster ~= "player" then
            else
                local remaining = expirationTime and (expirationTime - GetTime()) or 0
                if remaining < 0 then remaining = 0 end
                return true, remaining, count or 1
            end
        end
    end
    return false, 0, 0
end

function addon:BuffStacks(unit, spellID)
    local _, _, count = addon:HasBuff(unit, spellID)
    return count
end

function addon:DebuffStacks(unit, spellID)
    local _, _, count = addon:HasDebuff(unit, spellID, true)
    return count
end

function addon:Rage()
    return UnitPower("player", 1) or 0
end

function addon:RageDeficit()
    return 100 - addon:Rage()
end

function addon:Health(unit)
    unit = unit or "player"
    return UnitHealth(unit) or 0
end

function addon:HealthMax(unit)
    unit = unit or "player"
    return UnitHealthMax(unit) or 1
end

function addon:HealthPercent(unit)
    unit = unit or "target"
    local max = addon:HealthMax(unit)
    if max == 0 then return 100 end
    return (addon:Health(unit) / max) * 100
end

function addon:IsInMeleeRange()
    if not UnitExists("target") then return false end
    local name = addon:SpellName(addon.spells and addon.spells.HeroicStrike or 78)
    if not name then return false end
    return IsSpellInRange(name, "target") == 1
end

function addon:IsInRange(spellID)
    if not UnitExists("target") then return false end
    local name = addon:SpellName(spellID)
    if not name then return false end
    local inRange = IsSpellInRange(name, "target")
    return inRange == 1 or inRange == nil
end

function addon:HasValidTarget()
    return UnitExists("target") and not UnitIsDead("target") and UnitCanAttack("player", "target")
end

function addon:InCombat()
    return addon.state.inCombat or UnitAffectingCombat("player")
end

function addon:GetStance()
    local stance = GetShapeshiftForm()
    if stance == 1 then return "battle"
    elseif stance == 2 then return "defensive"
    elseif stance == 3 then return "berserker"
    end
    return "none"
end

function addon:IsInStance(required)
    return addon:GetStance() == required
end

function addon:GetKeybind(spellID)
    local name = GetSpellInfo(spellID)
    if not name then return "" end

    for slot = 1, 120 do
        local actionType, id = GetActionInfo(slot)
        if actionType == "spell" and id == spellID then
            local bar = math.floor((slot - 1) / 12)
            local btn = ((slot - 1) % 12) + 1
            
            local barName = "ACTIONBUTTON"
            if bar == 1 then barName = "MULTIACTIONBAR1BUTTON"
            elseif bar == 2 then barName = "MULTIACTIONBAR2BUTTON"
            elseif bar == 3 then barName = "MULTIACTIONBAR3BUTTON"
            elseif bar == 4 then barName = "MULTIACTIONBAR4BUTTON"
            end
            
            local key1, key2 = GetBindingKey(barName .. btn)
            local key = key1 or key2
            if key then
                key = key:gsub("SHIFT%-", "S-")
                key = key:gsub("CTRL%-", "C-")
                key = key:gsub("ALT%-", "A-")
                key = key:gsub("NUMPAD", "N")
                return key
            end
        end
    end

    return ""
end

function addon:TimeToExecute()
    if not addon:HasValidTarget() then return 999 end
    local hp = addon:HealthPercent("target")
    local threshold = addon.db[addon.db.spec] and addon.db[addon.db.spec].executePhase or 20
    if hp <= threshold then return 0 end
    return 999
end

function addon:IsExecutePhase()
    return addon:TimeToExecute() == 0
end