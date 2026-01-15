local addonName, addon = ...

_G[addonName] = addon

addon.name = addonName
addon.version = "2.0.0"
addon.frames = addon.frames or {}
addon.modules = addon.modules or {}
addon.rotations = addon.rotations or {}
addon.classes = addon.classes or {}
addon.playerClass = nil
addon.playerSpec = nil

addon.state = addon.state or {
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
    "LEARNED_SPELL_IN_TAB",
    "SPELLS_CHANGED",
    "PLAYER_LEVEL_UP",
}

local function OnCombatLog(timestamp, eventType, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
    if srcGUID ~= UnitGUID("player") then return end
    
    if eventType == "SWING_MISSED" or eventType == "SPELL_MISSED" then
        local missType
        if eventType == "SWING_MISSED" then
            missType = select(1, ...)
        else
            missType = select(4, ...) -- spellId, spellName, spellSchool, missType
        end
        
        if missType == "DODGE" then
            addon.state.dodged = true
            addon.state.dodgeExpire = GetTime() + 5
        end
    end
    
    if eventType == "SPELL_CAST_SUCCESS" then
        local spellID = select(1, ...)
        addon.state.lastCast = spellID
        addon.state.lastCastTime = GetTime()
    end
end

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

local function OnEvent(self, event, ...)
    local arg1 = ...

    if event == "ADDON_LOADED" and arg1 == addonName then
        if addon.InitDB then addon:InitDB() end
        if addon.InitUI then addon:InitUI() end
        if addon.InitEngine then addon:InitEngine() end
        if addon.InitCommands then addon:InitCommands() end
        if addon.RefreshKnownSpells then addon:RefreshKnownSpells() end
        
    elseif event == "PLAYER_LOGIN" then
        local _, class = UnitClass("player")
        addon.playerClass = class
        
        if class ~= "WARRIOR" then
            if addon.frames.main then addon.frames.main:Hide() end
            return
        end
        
    if addon.DetectSpec then addon:DetectSpec() end
    if addon.RefreshUIFromDB then addon:RefreshUIFromDB() end
        
    elseif event == "PLAYER_ENTERING_WORLD" then
        if addon.DetectSpec then addon:DetectSpec() end
            if addon.RefreshKnownSpells then addon:RefreshKnownSpells() end
        
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
        OnCombatLog(...)
        
    elseif event == "UNIT_AURA" and arg1 == "player" then
        addon:UpdateProcs()
        
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" and arg1 == "player" then
        local spell = select(2, ...)
        addon:OnSpellCast(spell)
    -- spellbook / level changes may affect known spells
    elseif event == "LEARNED_SPELL_IN_TAB" or event == "SPELLS_CHANGED" or event == "PLAYER_LEVEL_UP" then
        if addon.RefreshKnownSpells then addon:RefreshKnownSpells() end
        if addon.RefreshUIFromDB then addon:RefreshUIFromDB() end
    end
end

-- event handler and registration will be set after all functions are defined

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
    addon.state.procs = addon.state.procs or {}
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
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00WarriorRotation|r: InitUI called")
    if not addon.db and addon.InitDB then addon:InitDB() end
    if addon.InitIcons then addon:InitIcons() end
    if addon.InitOptions then addon:InitOptions() end
    if addon.RefreshUIFromDB then addon:RefreshUIFromDB() end
    -- If user enabled showing spell IDs, install mouseover hook now
    if addon.db and addon.db.display and addon.db.display.showSpellIDs and addon.InstallSpellIDMouseoverHook then
        addon:InstallSpellIDMouseoverHook()
    end
end

function addon:RefreshUIFromDB()
    if addon.ApplyIconLayout then addon:ApplyIconLayout() end
    if addon.RefreshOptionsUI then addon:RefreshOptionsUI() end
end

eventFrame:SetScript("OnEvent", OnEvent)

for _, event in ipairs(events) do
    eventFrame:RegisterEvent(event)
end

if IsAddOnLoaded and IsAddOnLoaded(addonName) and not addon.db then
    if addon.InitDB then addon:InitDB() end
    if addon.InitEngine then addon:InitEngine() end
    if addon.InitCommands then addon:InitCommands() end
    -- If UI files are already loaded (InitIcons exists), run InitUI now; otherwise it will run later via events
    if addon.InitIcons and addon.InitOptions and addon.InitUI then
        addon:InitUI()
    end
end