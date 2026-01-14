local addonName, addon = ...

_G[addonName] = addon

addon.name = addonName
addon.version = "2.0.0"
addon.frames = {}
addon.modules = {}
addon.rotations = {}
addon.classes = {}
addon.playerClass = nil
addon.playerSpec = nil

addon.state = {
    inCombat = false,
    gcdStart = 0,
    gcdDuration = 0,
    lastCast = nil,
    lastCastTime = 0,
    targetGUID = nil,
    procs = {},
    dodged = false,
    dodgeExpire = 0,
}

local eventFrame = CreateFrame("Frame")
addon.eventFrame = eventFrame

local events = {
    "ADDON_LOADED",
    "PLAYER_LOGIN",
    "PLAYER_ENTERING_WORLD",
    "PLAYER_REGEN_ENABLED",
    "PLAYER_REGEN_DISABLED",
    "PLAYER_TARGET_CHANGED",
    "COMBAT_LOG_EVENT_UNFILTERED",
    "UNIT_AURA",
    "SPELL_UPDATE_COOLDOWN",
    "ACTIONBAR_UPDATE_COOLDOWN",
    "UNIT_SPELLCAST_SUCCEEDED",
    "UNIT_SPELLCAST_START",
    "UNIT_SPELLCAST_STOP",
    "UNIT_SPELLCAST_FAILED",
}

for _, event in ipairs(events) do
    eventFrame:RegisterEvent(event)
end

local function OnCombatLog()
    local timestamp, eventType, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags = CombatLogGetCurrentEventInfo()
    
    if srcGUID ~= UnitGUID("player") then return end
    
    if eventType == "SWING_MISSED" or eventType == "SPELL_MISSED" then
        local missType
        if eventType == "SWING_MISSED" then
            missType = select(9, CombatLogGetCurrentEventInfo())
        else
            missType = select(12, CombatLogGetCurrentEventInfo())
        end
        
        if missType == "DODGE" then
            addon.state.dodged = true
            addon.state.dodgeExpire = GetTime() + 5
        end
    end
    
    if eventType == "SPELL_CAST_SUCCESS" then
        local spellID = select(9, CombatLogGetCurrentEventInfo()) or select(12, CombatLogGetCurrentEventInfo())
        addon.state.lastCast = spellID
        addon.state.lastCastTime = GetTime()
    end
end

local function OnEvent(self, event, arg1, ...)
    if event == "ADDON_LOADED" and arg1 == addonName then
        addon:InitDB()
        addon:InitUI()
        addon:InitEngine()
        addon:InitCommands()
        
    elseif event == "PLAYER_LOGIN" then
        local _, class = UnitClass("player")
        addon.playerClass = class
        
        if class ~= "WARRIOR" then
            if addon.frames.main then addon.frames.main:Hide() end
            return
        end
        
        addon:DetectSpec()
        addon:RefreshUIFromDB()
        
    elseif event == "PLAYER_ENTERING_WORLD" then
        addon:DetectSpec()
        
    elseif event == "PLAYER_REGEN_DISABLED" then
        addon.state.inCombat = true
        
    elseif event == "PLAYER_REGEN_ENABLED" then
        addon.state.inCombat = false
        addon.state.dodged = false
        addon.state.procs = {}
        
    elseif event == "PLAYER_TARGET_CHANGED" then
        addon.state.targetGUID = UnitGUID("target")
        addon.state.dodged = false
        
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        OnCombatLog()
        
    elseif event == "UNIT_AURA" and arg1 == "player" then
        addon:UpdateProcs()
        
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" and arg1 == "player" then
        local spell = ...
        addon:OnSpellCast(spell)
    end
end

eventFrame:SetScript("OnEvent", OnEvent)

function addon:DetectSpec()
    local _, _, _, _, points1 = GetTalentTabInfo(1)
    local _, _, _, _, points2 = GetTalentTabInfo(2)
    local _, _, _, _, points3 = GetTalentTabInfo(3)
    
    if points1 > points2 and points1 > points3 then
        addon.playerSpec = "arms"
    elseif points2 > points1 and points2 > points3 then
        addon.playerSpec = "fury"
    else
        addon.playerSpec = "prot"
    end
    
    if not addon.db.spec or addon.db.spec == "" then
        addon.db.spec = addon.playerSpec
    end
end

function addon:UpdateProcs()
    local procs = addon.state.procs
    local spells = addon.spells
    if not spells then return end
    
    procs.suddenDeath = addon:HasBuff("player", spells.SuddenDeath)
    procs.tasteForBlood = addon:HasBuff("player", spells.TasteForBlood)
    procs.bloodsurge = addon:HasBuff("player", spells.Bloodsurge)
    procs.swordAndBoard = addon:HasBuff("player", spells.SwordAndBoard)
    procs.revenge = addon:HasBuff("player", spells.RevengeProc)
end

function addon:OnSpellCast(spell)
    local spells = addon.spells
    if not spells then return end
    
    if spell == addon:SpellName(spells.Overpower) then
        addon.state.dodged = false
    end
end

function addon:InitUI()
    addon:InitIcons()
    addon:InitOptions()
end

function addon:RefreshUIFromDB()
    addon:ApplyIconLayout()
    if addon.RefreshOptionsUI then addon:RefreshOptionsUI() end
end