local addonName, addon = ...

local GetTime = GetTime

addon.engine = {
    queue = {},
    lastUpdate = 0,
    currentPriority = 0,
}

local function BuildState()
    local s = {}
    local db = addon.db
    local specDB = addon:GetSpecDB()
    
    s.time = GetTime()
    s.inCombat = addon:InCombat()
    s.hasTarget = addon:HasValidTarget()
    s.inMelee = addon:IsInMeleeRange()
    s.stance = addon:GetStance()
    
    s.rage = addon:Rage()
    s.rageDeficit = addon:RageDeficit()
    
    s.gcdRemaining = addon:GCDRemaining()
    s.gcdReady = addon:IsGCDReady()
    
    s.targetHP = addon:HealthPercent("target")
    s.executePhase = addon:IsExecutePhase()
    s.executeThreshold = specDB.executePhase or 20
    
    s.dodged = addon.state.dodged and (addon.state.dodgeExpire > s.time)
    
    local procs = addon.state.procs
    s.suddenDeath = procs.suddenDeath or false
    s.tasteForBlood = procs.tasteForBlood or false
    s.bloodsurge = procs.bloodsurge or false
    s.swordAndBoard = procs.swordAndBoard or false
    s.revengeReady = procs.revenge or false
    
    local spells = addon.spells
    if spells then
        s.hasRend, s.rendRemaining = addon:HasDebuff("target", spells.Rend, true)
        s.hasSunderArmor, s.sunderRemaining, s.sunderStacks = addon:HasDebuff("target", spells.SunderArmor, false)
        s.hasThunderClap, s.thunderClapRemaining = addon:HasDebuff("target", spells.ThunderClap, false)
        s.hasDemoShout, s.demoShoutRemaining = addon:HasDebuff("target", spells.DemoralizingShout, false)
    end
    
    return s
end

local function CanCast(spellID, state, rageCost)
    if not addon:IsSpellKnown(spellID) then return false end
    if not addon:IsSpellReady(spellID) then return false end
    if rageCost and state.rage < rageCost then return false end
    return true
end

local function WillBeReady(spellID, timeWindow)
    return addon:SpellWillBeReady(spellID, timeWindow or 1.5)
end

local function AddToQueue(queue, spellID, priority, maxLen)
    if #queue >= maxLen then return false end
    if not spellID then return false end
    if not addon:SpellTexture(spellID) then return false end
    
    for _, entry in ipairs(queue) do
        if entry.spellID == spellID then return false end
    end
    
    queue[#queue + 1] = {
        spellID = spellID,
        priority = priority,
    }
    return true
end

local function SortQueue(queue)
    table.sort(queue, function(a, b)
        return a.priority > b.priority
    end)
end

local function FlattenQueue(queue)
    local result = {}
    for i, entry in ipairs(queue) do
        result[i] = entry.spellID
    end
    return result
end

function addon:BuildQueue()
    local db = addon.db
    if not db.enabled then return {} end
    
    local state = BuildState()
    if not state.hasTarget then return {} end
    if db.engine.onlyInCombat and not state.inCombat then return {} end
    
    local spec = db.spec
    local rotation = addon.rotations[spec]
    if not rotation then return {} end
    
    local maxLen = db.display.queueLength or 4
    local queue = {}
    
    rotation:Build(queue, maxLen, state, AddToQueue)
    
    SortQueue(queue)
    
    return FlattenQueue(queue)
end

function addon:GetRecommendation()
    local queue = addon:BuildQueue()
    if #queue > 0 then
        return queue[1]
    end
    return nil
end

function addon:ShouldPoolRage(state, spellID, poolAmount)
    if not addon.db[addon.db.spec].poolRageForMS then return false end
    
    local cdRemaining = addon:CooldownRemaining(spellID)
    if cdRemaining > 2 then return false end
    if cdRemaining <= 0 then return false end
    
    local rageCost = poolAmount or addon.db[addon.db.spec].poolAmount or 30
    if state.rage < rageCost then
        return true
    end
    
    return false
end

function addon:InitEngine()
    addon.engine.queue = {}
    addon.engine.lastUpdate = 0
end

function addon:GetEngineState()
    return BuildState()
end