local addonName, addon = ...

addon.spells = {}

local spellList = {
    { key = "HeroicStrike",      name = "Heroic Strike",      id = 47450 },
    { key = "Cleave",            name = "Cleave",             id = 47520 },
    { key = "Execute",           name = "Execute",            id = 47471 },
    { key = "Slam",              name = "Slam",               id = 47475 },
    { key = "VictoryRush",       name = "Victory Rush",       id = 34428 },
    { key = "Rend",              name = "Rend",               id = 47465 },
    { key = "Overpower",         name = "Overpower",          id = 7384 },
    { key = "MortalStrike",      name = "Mortal Strike",      id = 47486 },
    { key = "Bladestorm",        name = "Bladestorm",         id = 46924 },
    { key = "Bloodthirst",       name = "Bloodthirst",        id = 23881 },
    { key = "Whirlwind",         name = "Whirlwind",          id = 1680 },
    { key = "ShieldSlam",        name = "Shield Slam",        id = 47488 },
    { key = "Revenge",           name = "Revenge",            id = 57823 },
    { key = "Devastate",         name = "Devastate",          id = 47498 },
    { key = "Shockwave",         name = "Shockwave",          id = 46968 },
    { key = "ConcussionBlow",    name = "Concussion Blow",    id = 12809 },
    { key = "SunderArmor",       name = "Sunder Armor",       id = 7386 },
    { key = "ThunderClap",       name = "Thunder Clap",       id = 47502 },
    { key = "DemoralizingShout", name = "Demoralizing Shout", id = 25203 },
    { key = "Hamstring",         name = "Hamstring",          id = 1715 },
    { key = "Charge",            name = "Charge",             id = 11578 },
    { key = "Intercept",         name = "Intercept",          id = 20252 },
    { key = "Intervene",         name = "Intervene",          id = 3411 },
    { key = "HeroicThrow",       name = "Heroic Throw",       id = 57755 },
    { key = "BattleShout",       name = "Battle Shout",       id = 47436 },
    { key = "CommandingShout",   name = "Commanding Shout",   id = 47440 },
    { key = "BerserkerRage",     name = "Berserker Rage",     id = 18499 },
    { key = "Bloodrage",         name = "Bloodrage",          id = 2687 },
    { key = "DeathWish",         name = "Death Wish",         id = 12292 },
    { key = "Recklessness",      name = "Recklessness",       id = 1719 },
    { key = "ShieldWall",        name = "Shield Wall",        id = 871 },
    { key = "LastStand",         name = "Last Stand",         id = 12975 },
    { key = "ShieldBlock",       name = "Shield Block",       id = 2565 },
    { key = "SuddenDeath",       name = "Sudden Death",       id = 52437 },
    { key = "TasteForBlood",     name = "Taste for Blood",    id = 60503 },
    { key = "Bloodsurge",        name = "Bloodsurge",         id = 46916 },
    { key = "SwordAndBoard",     name = "Sword and Board",    id = 50227 },
}

addon.spellInfo = {}
addon.spellNames = {}

for _, spell in ipairs(spellList) do
    addon.spellNames[spell.key] = spell.name
    addon.spellInfo[spell.key] = spell
end

local function FindSpellID(targetName)
    if not targetName then return nil end
    if addon.knownSpells and addon.knownSpells[targetName] then
        return addon.knownSpells[targetName].id
    end
    local link = GetSpellLink(targetName)
    if link then
        local id = link:match("spell:(%d+)")
        if id then return tonumber(id) end
    end
    return nil
end

function addon:RefreshSpellIDs()
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
        elseif spell.id then
            addon.spells[spell.key] = spell.id
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