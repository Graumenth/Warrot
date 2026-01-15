local addonName, addon = ...

addon.spells = {}

local spellList = {
    { key = "HeroicStrike",      name = "Heroic Strike",      rage = 15,  stance = "any",                    onNext = true },
    { key = "Cleave",            name = "Cleave",             rage = 20,  stance = "any",                    onNext = true },
    { key = "Execute",           name = "Execute",            rage = 15,  stance = {"battle", "berserker"},  execute = true },
    { key = "Slam",              name = "Slam",               rage = 15,  stance = "any",                    cast = 1.5 },
    { key = "VictoryRush",       name = "Victory Rush",       rage = 0,   stance = "any" },
    { key = "Rend",              name = "Rend",               rage = 10,  stance = {"battle", "defensive"},  dot = true, duration = 15 },
    { key = "Overpower",         name = "Overpower",          rage = 5,   stance = "battle",                 cooldown = 5 },
    { key = "MortalStrike",      name = "Mortal Strike",      rage = 30,  stance = "any",                    cooldown = 6 },
    { key = "Bladestorm",        name = "Bladestorm",         rage = 25,  stance = "any",                    cooldown = 90, channel = 6 },
    { key = "Bloodthirst",       name = "Bloodthirst",        rage = 20,  stance = "berserker",              cooldown = 4 },
    { key = "Whirlwind",         name = "Whirlwind",          rage = 25,  stance = "berserker",              cooldown = 10, aoe = true },
    { key = "ShieldSlam",        name = "Shield Slam",        rage = 20,  stance = "defensive",              cooldown = 6, requireShield = true },
    { key = "Revenge",           name = "Revenge",            rage = 5,   stance = "defensive",              cooldown = 5, requireShield = true },
    { key = "Devastate",         name = "Devastate",          rage = 15,  stance = "defensive",              requireShield = true },
    { key = "Shockwave",         name = "Shockwave",          rage = 15,  stance = "defensive",              cooldown = 20, aoe = true },
    { key = "ConcussionBlow",    name = "Concussion Blow",    rage = 15,  stance = "any",                    cooldown = 30, stun = true },
    { key = "SunderArmor",       name = "Sunder Armor",       rage = 15,  stance = "any",                    stacks = 5 },
    { key = "ThunderClap",       name = "Thunder Clap",       rage = 20,  stance = {"battle", "defensive"},  cooldown = 6, aoe = true },
    { key = "DemoralizingShout", name = "Demoralizing Shout", rage = 10,  stance = "any",                    aoe = true, duration = 30 },
    { key = "Hamstring",         name = "Hamstring",          rage = 10,  stance = {"battle", "berserker"} },
    { key = "Charge",            name = "Charge",             rage = -15, stance = "battle",                 cooldown = 15, generate = true },
    { key = "Intercept",         name = "Intercept",          rage = 10,  stance = "berserker",              cooldown = 30 },
    { key = "Intervene",         name = "Intervene",          rage = 10,  stance = "defensive",              cooldown = 30 },
    { key = "HeroicThrow",       name = "Heroic Throw",       rage = 0,   stance = "any",                    cooldown = 60, ranged = true },
    { key = "BattleShout",       name = "Battle Shout",       rage = 10,  stance = "any",                    buff = true, duration = 120 },
    { key = "CommandingShout",   name = "Commanding Shout",   rage = 10,  stance = "any",                    buff = true, duration = 120 },
    { key = "BerserkerRage",     name = "Berserker Rage",     rage = 0,   stance = "berserker",              cooldown = 30, buff = true },
    { key = "Bloodrage",         name = "Bloodrage",          rage = -20, stance = "any",                    cooldown = 60, generate = true },
    { key = "DeathWish",         name = "Death Wish",         rage = 10,  stance = "any",                    cooldown = 180, buff = true },
    { key = "Recklessness",      name = "Recklessness",       rage = 0,   stance = "berserker",              cooldown = 300, buff = true },
    { key = "ShieldWall",        name = "Shield Wall",        rage = 0,   stance = "defensive",              cooldown = 300, defensive = true },
    { key = "LastStand",         name = "Last Stand",         rage = 0,   stance = "any",                    cooldown = 180, defensive = true },
    { key = "ShieldBlock",       name = "Shield Block",       rage = 10,  stance = "defensive",              cooldown = 60, defensive = true },
    { key = "BattleStance",      name = "Battle Stance",      rage = 0,   stance = "any" },
    { key = "DefensiveStance",   name = "Defensive Stance",   rage = 0,   stance = "any" },
    { key = "BerserkerStance",   name = "Berserker Stance",   rage = 0,   stance = "any" },
    { key = "SuddenDeath",       name = "Sudden Death",       rage = 0,   stance = "any",                    proc = true },
    { key = "TasteForBlood",     name = "Taste for Blood",    rage = 0,   stance = "any",                    proc = true },
    { key = "Bloodsurge",        name = "Bloodsurge",         rage = 0,   stance = "any",                    proc = true },
    { key = "SwordAndBoard",     name = "Sword and Board",    rage = 0,   stance = "any",                    proc = true },
}

addon.spellInfo = {}
addon.spellNames = {}

for _, spell in ipairs(spellList) do
    addon.spellNames[spell.key] = spell.name
    addon.spellInfo[spell.key] = spell
end

-- Fix: Use the robust scanner from Utils.lua
local function FindSpellID(targetName)
    if not targetName then return nil end
    
    -- 1. Try cache populated by Utils.lua (Robust)
    if addon.knownSpells and addon.knownSpells[targetName] then
        return addon.knownSpells[targetName].id
    end
    
    -- 2. Try direct link (Backup)
    local link = GetSpellLink(targetName)
    if link then
        local id = link:match("spell:(%d+)")
        if id then return tonumber(id) end
    end
    
    return nil
end

function addon:RefreshSpellIDs()
    -- Ensure we have the latest known spells
    if addon.RefreshKnownSpells then 
        addon:RefreshKnownSpells() 
    end

    for key, _ in pairs(addon.spellNames) do
        addon.spells[key] = nil
    end
    
    for _, spell in ipairs(spellList) do
        local id = FindSpellID(spell.name)
        if id then
            addon.spells[spell.key] = id
        else
            -- Debug log if debug enabled
            -- if addon.db and addon.db.debug then addon:Debug("Spell not found: " .. spell.name) end
        end
    end
end

function addon:GetSpellKey(spellID)
    for key, id in pairs(addon.spells) do
        if id == spellID then return key end
    end
    return nil
end

function addon:GetSpellInfo(spellID)
    local key = addon:GetSpellKey(spellID)
    if key then return addon.spellInfo[key] end
    return nil
end

function addon:GetRageCost(spellID)
    local info = addon:GetSpellInfo(spellID)
    if info then return info.rage or 0 end
    return 0
end

function addon:CanUseInStance(spellID, currentStance)
    local info = addon:GetSpellInfo(spellID)
    if not info then return true end
    local stance = info.stance
    if not stance or stance == "any" then return true end
    if type(stance) == "table" then
        for _, s in ipairs(stance) do
            if s == currentStance then return true end
        end
        return false
    end
    return stance == currentStance
end

function addon:IsOnNextSwing(spellID)
    local info = addon:GetSpellInfo(spellID)
    return info and info.onNext
end

function addon:IsAoESpell(spellID)
    local info = addon:GetSpellInfo(spellID)
    return info and info.aoe
end