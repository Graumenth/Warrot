local addonName, addon = ...

addon.state = {}

function addon:BuildState()
    local s = addon.state
    s.inCombat = UnitAffectingCombat("player") and true or false
    s.rage = addon:Rage()
    s.hp = addon:TargetHPPercent()
    s.melee = addon:IsInMeleeRange()
    s.hasTarget = UnitExists("target") and not UnitIsDead("target") and UnitCanAttack("player", "target")
    s.suddenDeath = (select(1, addon:UnitBuffRemaining("player", addon.spells.SuddenDeath))) and true or false
    s.tasteForBlood = (select(1, addon:UnitBuffRemaining("player", addon.spells.TasteForBlood))) and true or false
    s.bloodsurge = (select(1, addon:UnitBuffRemaining("player", addon.spells.Bloodsurge))) and true or false
    s.hasRend, s.rendRem = addon:UnitDebuffRemaining("target", addon.spells.Rend)
    return s
end

function addon:NextQueue()
    local db = addon.db
    if not db.enabled then return {} end

    local s = addon:BuildState()
    if not s.hasTarget then return {} end
    if db.onlyInCombat and not s.inCombat then return {} end

    local rot = addon.rotations[db.spec]
    if not rot then return {} end

    local maxLen = db.queueLength or 4
    local out = {}

    rot:Build(out, maxLen, s)

    return out
end

function addon:InitEngine()
    addon.engine = addon.engine or {}
end