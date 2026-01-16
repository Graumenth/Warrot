local addonName, addon = ...

local GetTime = GetTime
local tinsert = table.insert
local ipairs = ipairs
local pairs = pairs
local math_max = math.max
local math_min = math.min
local random = math.random

addon.engine = {
    queue = {},
}

local ActionDefinitions = {}

local function Define(key, data)
    local id = addon.spells and addon.spells[key]
    if id and id > 0 then
        ActionDefinitions[id] = data
    end
end

local function InitActionDefinitions()
    Define("ShieldSlam", {
        cd = 6,
        gcd = 1.5,
        rageCost = function(s)
            if s:HasBuff(addon.spells.SwordAndBoard) then return 0 end
            return 20 
        end,
        handler = function(s)
            s.buffs[addon.spells.SwordAndBoard] = 0
            s.buffs[addon.spells.ShieldBlock] = s.buffs[addon.spells.ShieldBlock] or 0
            s.rage = math_min(100, s.rage + 20) 
        end
    })
    
    Define("Revenge", {
        cd = 5,
        gcd = 1.5,
        rageCost = 5,
        handler = function(s)
            s.revengeActive = false
        end
    })
    
    Define("Devastate", {
        cd = 0,
        gcd = 1.5,
        rageCost = 15, 
        handler = function(s)
            if s.swordAndBoardProcChance then
                if random() < 0.30 then 
                    s.cooldowns[addon.spells.ShieldSlam] = 0
                    s.buffs[addon.spells.SwordAndBoard] = s.time + 5
                end
            end
            
            if s.sunderStacks < 5 then
                s.sunderStacks = s.sunderStacks + 1
                s.debuffs[addon.spells.SunderArmor] = s.time + 30
            else
                s.debuffs[addon.spells.SunderArmor] = s.time + 30
            end
        end
    })
    
    Define("SunderArmor", {
        cd = 0,
        gcd = 1.5,
        rageCost = 15,
        handler = function(s)
            if s.sunderStacks < 5 then
                s.sunderStacks = s.sunderStacks + 1
                s.debuffs[addon.spells.SunderArmor] = s.time + 30
            else
                s.debuffs[addon.spells.SunderArmor] = s.time + 30
            end
        end
    })
    
    Define("Shockwave", {
        cd = 20,
        gcd = 1.5,
        rageCost = 15
    })
    
    Define("ConcussionBlow", {
        cd = 30,
        gcd = 1.5,
        rageCost = 15
    })
    
    Define("HeroicStrike", {
        cd = 1.5, 
        gcd = 0,  
        rageCost = 15,
        handler = function(s)
            s.swingLockout = s.time + 3.0 
        end
    })
    
    Define("Cleave", {
        cd = 1.5,
        gcd = 0,
        rageCost = 20,
        handler = function(s)
            s.swingLockout = s.time + 3.0
        end
    })
    
    Define("ThunderClap", {
        cd = 6,
        gcd = 1.5,
        rageCost = 20,
        handler = function(s)
            s.debuffs[addon.spells.ThunderClap] = s.time + 30
        end
    })
    
    Define("DemoralizingShout", {
        cd = 0,
        gcd = 1.5,
        rageCost = 10,
        handler = function(s)
            s.debuffs[addon.spells.DemoralizingShout] = s.time + 30
        end
    })
    
    Define("ShieldBlock", {
        cd = 60,
        gcd = 0, 
        rageCost = 10,
        handler = function(s)
            s.buffs[addon.spells.ShieldBlock] = s.time + 10
        end
    })
    
    Define("Execute", {
        cd = 0,
        gcd = 1.5,
        rageCost = function(s)
            local cost = 15
            local extra = math_min(30 - cost, s.rage - cost)
            return cost + math_max(0, extra)
        end
    })
    
    Define("Slam", {
        cd = 0,
        gcd = 1.5,
        rageCost = 15,
        castTime = function(s)
            if s:HasBuff(addon.spells.Bloodsurge) then return 0 end
            return 1.5
        end,
        handler = function(s)
            s.buffs[addon.spells.Bloodsurge] = 0
        end
    })
    
    Define("Bloodrage", {
        cd = 60,
        gcd = 0,
        rageCost = 0,
        handler = function(s)
            s.rage = math_min(100, s.rage + 20)
        end
    })
    
    Define("VictoryRush", {
        cd = 0,
        gcd = 1.5,
        rageCost = 0
    })
end

local function GetSnapshot()
    local s = {}
    s.time = GetTime()
    s.rage = addon:Rage()
    s.inCombat = addon:InCombat()
    s.targetHP = addon:HealthPercent("target")
    s.gcdEnd = 0
    s.sunderStacks = addon:DebuffStacks("target", addon.spells.SunderArmor) or 0
    
    s.swingLockout = 0 
    
    s.cooldowns = {}
    s.buffs = {}
    s.debuffs = {}
    
    local relevantBuffs = {
        addon.spells.SwordAndBoard,
        addon.spells.ShieldBlock,
        addon.spells.SuddenDeath,
        addon.spells.Bloodsurge,
        addon.spells.VictoryRush
    }
    
    for _, id in ipairs(relevantBuffs) do
        if id then
            local has, expires = addon:HasBuff("player", id)
            if has then
                s.buffs[id] = s.time + expires
            else
                s.buffs[id] = 0
            end
        end
    end

    local relevantDebuffs = {
        addon.spells.SunderArmor,
        addon.spells.ThunderClap,
        addon.spells.DemoralizingShout
    }

    for _, id in ipairs(relevantDebuffs) do
        if id then
            local has, expires = addon:HasDebuff("target", id)
            if has then
                s.debuffs[id] = s.time + expires
            else
                s.debuffs[id] = 0
            end
        end
    end

    local relevantCDs = {
        addon.spells.ShieldSlam,
        addon.spells.Revenge,
        addon.spells.Shockwave,
        addon.spells.ConcussionBlow,
        addon.spells.ThunderClap,
        addon.spells.ShieldBlock,
        addon.spells.Bladestorm,
        addon.spells.MortalStrike,
        addon.spells.Bloodthirst,
        addon.spells.Whirlwind,
        addon.spells.HeroicThrow,
        addon.spells.Bloodrage
    }

    for _, id in ipairs(relevantCDs) do
        if id then
            local start, duration = addon:GetCooldown(id)
            if start > 0 then
                s.cooldowns[id] = start + duration
            else
                s.cooldowns[id] = 0
            end
        end
    end
    
    s.revengeActive = addon.state.revengeAvailable and (addon.state.revengeExpire > s.time)
    s.swordAndBoardProcChance = true 

    function s:HasBuff(id)
        if not id then return false end
        return (self.buffs[id] or 0) > self.time
    end

    function s:GetDebuffRemains(id)
        if not id then return 0 end
        return math_max(0, (self.debuffs[id] or 0) - self.time)
    end
    
    function s:IsKnown(id)
        if not id then return false end
        return addon:IsSpellKnown(id)
    end
    
    function s:GetCD(id)
        if not id then return 9999 end
        return math_max(0, (self.cooldowns[id] or 0) - self.time)
    end
    
    function s:CanCast(id)
        if not id then return false end
        if not self:IsKnown(id) then return false end

        local def = ActionDefinitions[id]
        if not def then return true end 
        
        if self:GetCD(id) > 0.1 then return false end
        
        local cost = 0
        if type(def.rageCost) == "function" then
            cost = def.rageCost(self)
        else
            cost = def.rageCost or 0
        end
        
        if self.rage < cost then return false end
        
        return true
    end
    
    function s:Advance(dt)
        self.time = self.time + dt
        
        if self.inCombat then
            if self.time > self.swingLockout then
                local ragePerSec = 3 
                self.rage = math_min(100, self.rage + (ragePerSec * dt))
            end
        end
        
        local gcdRem = math_max(0, self.gcdEnd - GetTime())
        if gcdRem > 0 and self.time < (GetTime() + gcdRem) then
             self.time = GetTime() + gcdRem
        end
        
        if self.revengeActive and addon.state.revengeExpire < self.time then
            self.revengeActive = false
        end
    end
    
    function s:Cast(id)
        local def = ActionDefinitions[id]
        if not def then return 1.5 end
        
        local castTime = 0
        if type(def.castTime) == "function" then
            castTime = def.castTime(self)
        else
            castTime = def.castTime or 0
        end
        
        local cost = 0
        if type(def.rageCost) == "function" then
            cost = def.rageCost(self)
        else
            cost = def.rageCost or 0
        end
        
        self.rage = math_max(0, self.rage - cost)
        
        if def.cd > 0 then
            self.cooldowns[id] = self.time + def.cd
        end
        
        if def.handler then
            def.handler(self)
        end
        
        return math_max(def.gcd, castTime)
    end

    return s
end

function addon:BuildQueue()
    local db = addon.db
    if not db.enabled then return {} end
    if not addon:HasValidTarget() then return {} end
    
    local spec = db.spec
    local rotation = addon.rotations[spec]
    if not rotation then return {} end
    
    local queue = {}
    local maxLen = db.display.queueLength or 4
    
    local state = GetSnapshot()
    
    local gcdStart, gcdDuration = addon:GetGCD()
    if gcdStart > 0 then
        state.gcdEnd = gcdStart + gcdDuration
        state.time = math_max(state.time, state.gcdEnd)
    end
    
    for i = 1, maxLen do
        local bestSpell = rotation:GetNextAction(state)
        
        if bestSpell then
            tinsert(queue, bestSpell)
            local dt = state:Cast(bestSpell)
            
            if dt > 0 then
                state:Advance(dt)
            end
        else
            state:Advance(0.2)
        end
        
        if state.time > (GetTime() + 15) then break end
    end
    
    addon.engine.queue = queue
    return queue
end

function addon:GetRecommendation()
    local queue = addon:BuildQueue()
    return queue[1]
end

function addon:InitEngine()
    if addon.RefreshSpellIDs then addon:RefreshSpellIDs() end
    InitActionDefinitions()
    addon.engine.queue = {}
end