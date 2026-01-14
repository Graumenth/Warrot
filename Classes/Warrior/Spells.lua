local addonName, addon = ...

addon.spells = {
    HeroicStrike = 47450,
    Cleave = 47520,
    Execute = 47471,
    Slam = 47475,
    VictoryRush = 34428,
    
    Rend = 47465,
    Overpower = 7384,
    MortalStrike = 47486,
    Bladestorm = 46924,
    
    Bloodthirst = 23881,
    Whirlwind = 1680,
    
    ShieldSlam = 47488,
    Revenge = 57823,
    Devastate = 47498,
    Shockwave = 46968,
    ConcussionBlow = 12809,
    
    SunderArmor = 7386,
    ThunderClap = 47502,
    DemoralizingShout = 25203,
    Hamstring = 1715,
    
    Charge = 11578,
    Intercept = 20252,
    Intervene = 3411,
    HeroicThrow = 57755,
    
    BattleShout = 47436,
    CommandingShout = 47440,
    BerserkerRage = 18499,
    Bloodrage = 2687,
    DeathWish = 12292,
    Recklessness = 1719,
    ShieldWall = 871,
    LastStand = 12975,
    Retaliation = 20230,
    ShieldBlock = 2565,
    Enrage = 12880,
    
    BattleStance = 2457,
    DefensiveStance = 71,
    BerserkerStance = 2458,
    
    SuddenDeath = 52437,
    TasteForBlood = 60503,
    Bloodsurge = 46916,
    SwordAndBoard = 50227,
    RevengeProc = 5302,
}

addon.spellInfo = {
    [47450] = { name = "Heroic Strike", rage = 15, stance = "any", onNext = true },
    [47520] = { name = "Cleave", rage = 20, stance = "any", onNext = true },
    [47471] = { name = "Execute", rage = 15, stance = {"battle", "berserker"}, execute = true },
    [47475] = { name = "Slam", rage = 15, stance = "any", cast = 1.5 },
    [34428] = { name = "Victory Rush", rage = 0, stance = "any" },
    
    [47465] = { name = "Rend", rage = 10, stance = {"battle", "defensive"}, dot = true, duration = 15 },
    [7384] = { name = "Overpower", rage = 5, stance = "battle", cooldown = 5, requireDodge = true },
    [47486] = { name = "Mortal Strike", rage = 30, stance = "any", cooldown = 6 },
    [46924] = { name = "Bladestorm", rage = 25, stance = "any", cooldown = 90, channel = 6 },
    
    [23881] = { name = "Bloodthirst", rage = 20, stance = "berserker", cooldown = 4 },
    [1680] = { name = "Whirlwind", rage = 25, stance = "berserker", cooldown = 10, aoe = true },
    
    [47488] = { name = "Shield Slam", rage = 20, stance = "defensive", cooldown = 6, requireShield = true },
    [57823] = { name = "Revenge", rage = 5, stance = "defensive", cooldown = 5, requireShield = true },
    [47498] = { name = "Devastate", rage = 15, stance = "defensive", requireShield = true },
    [46968] = { name = "Shockwave", rage = 15, stance = "defensive", cooldown = 20, aoe = true, cone = true },
    [12809] = { name = "Concussion Blow", rage = 15, stance = "any", cooldown = 30, stun = true },
    
    [7386] = { name = "Sunder Armor", rage = 15, stance = "any", stacks = 5 },
    [47502] = { name = "Thunder Clap", rage = 20, stance = {"battle", "defensive"}, cooldown = 6, aoe = true },
    [25203] = { name = "Demoralizing Shout", rage = 10, stance = "any", aoe = true, duration = 30 },
    [1715] = { name = "Hamstring", rage = 10, stance = {"battle", "berserker"} },
    
    [11578] = { name = "Charge", rage = -15, stance = "battle", cooldown = 15, generate = true },
    [20252] = { name = "Intercept", rage = 10, stance = "berserker", cooldown = 30 },
    [3411] = { name = "Intervene", rage = 10, stance = "defensive", cooldown = 30 },
    [57755] = { name = "Heroic Throw", rage = 0, stance = "any", cooldown = 60, ranged = true },
    
    [47436] = { name = "Battle Shout", rage = 10, stance = "any", buff = true, duration = 120 },
    [47440] = { name = "Commanding Shout", rage = 10, stance = "any", buff = true, duration = 120 },
    [18499] = { name = "Berserker Rage", rage = 0, stance = "berserker", cooldown = 30, buff = true },
    [2687] = { name = "Bloodrage", rage = -20, stance = "any", cooldown = 60, generate = true },
    [12292] = { name = "Death Wish", rage = 10, stance = "any", cooldown = 180, buff = true },
    [1719] = { name = "Recklessness", rage = 0, stance = "berserker", cooldown = 300, buff = true },
    [871] = { name = "Shield Wall", rage = 0, stance = "defensive", cooldown = 300, defensive = true },
    [12975] = { name = "Last Stand", rage = 0, stance = "any", cooldown = 180, defensive = true },
    [2565] = { name = "Shield Block", rage = 10, stance = "defensive", cooldown = 60, defensive = true },
}

function addon:GetSpellInfo(spellID)
    return addon.spellInfo[spellID]
end

function addon:GetRageCost(spellID)
    local info = addon.spellInfo[spellID]
    if info then return info.rage or 0 end
    return 0
end

function addon:CanUseInStance(spellID, currentStance)
    local info = addon.spellInfo[spellID]
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
    local info = addon.spellInfo[spellID]
    return info and info.onNext
end

function addon:IsAoESpell(spellID)
    local info = addon.spellInfo[spellID]
    return info and info.aoe
end