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
    dodged = false,       -- Overpower için (Rakip dodge'larsa)
    dodgeExpire = 0,
    revengeAvailable = false, -- Revenge için (Ben dodge/parry/block yaparsam)
    revengeExpire = 0,
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
    local isSrcPlayer = (srcGUID == UnitGUID("player"))
    local isDstPlayer = (dstGUID == UnitGUID("player"))
    
    -- OVERPOWER MANTIĞI: Ben vurdum, rakip Dodge'ladı
    if isSrcPlayer then
        if eventType == "SWING_MISSED" then
            local missType = select(1, ...)
            if missType == "DODGE" then
                addon.state.dodged = true
                addon.state.dodgeExpire = GetTime() + 5
            end
        elseif eventType == "SPELL_MISSED" then
            local _, _, _, missType = ...
            if missType == "DODGE" then
                addon.state.dodged = true
                addon.state.dodgeExpire = GetTime() + 5
            end
        end
    end

    -- REVENGE MANTIĞI: Rakip vurdu, ben Block/Dodge/Parry yaptım
    if isDstPlayer then
        local isRevengeProc = false
        
        if eventType == "SWING_MISSED" then
            local missType = select(1, ...)
            if missType == "BLOCK" or missType == "DODGE" or missType == "PARRY" then
                isRevengeProc = true
            end
        elseif eventType == "SPELL_MISSED" then
            local _, _, _, missType = ...
            if missType == "BLOCK" or missType == "DODGE" or missType == "PARRY" then
                isRevengeProc = true
            end
        elseif eventType == "SWING_DAMAGE" then
            -- 3.3.5 SWING_DAMAGE args: amount, overkill, school, resisted, blocked, ...
            local blocked = select(5, ...)
            if blocked and blocked > 0 then 
                isRevengeProc = true 
            end
        elseif eventType == "SPELL_DAMAGE" then
            -- 3.3.5 SPELL_DAMAGE args: spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, ...
            local blocked = select(8, ...)
            if blocked and blocked > 0 then 
                isRevengeProc = true 
            end
        end

        if isRevengeProc then
            addon.state.revengeAvailable = true
            addon.state.revengeExpire = GetTime() + 5
        end
    end
    
    -- Revenge kullanınca proc'u sil
    if isSrcPlayer and eventType == "SPELL_CAST_SUCCESS" then
        local spellName = select(2, ...)
        if spellName == "Revenge" or spellName == addon:SpellName(addon.spells and addon.spells.Revenge or 57823) then
            addon.state.revengeAvailable = false
        end
    end
    
    -- Overpower kullanınca proc'u sil
    if isSrcPlayer and eventType == "SPELL_CAST_SUCCESS" then
        local spellName = select(2, ...)
        if spellName == "Overpower" or spellName == addon:SpellName(addon.spells and addon.spells.Overpower or 7384) then
            addon.state.dodged = false
        end
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

function addon:UpdateProcs()
    addon.state.procs = addon.state.procs or {}
    local procs = addon.state.procs
    local spells = addon.spells
    if not spells then return end
    
    procs.suddenDeath = addon:HasBuff("player", spells.SuddenDeath)
    procs.tasteForBlood = addon:HasBuff("player", spells.TasteForBlood)
    procs.bloodsurge = addon:HasBuff("player", spells.Bloodsurge)
    procs.swordAndBoard = addon:HasBuff("player", spells.SwordAndBoard)
    -- RevengeProc buff'ı WotLK'da görünmezdir, o yüzden Combat Log kullanıyoruz.
end

function addon:OnSpellCast(spell)
    -- Yedek temizleme (OnCombatLog kaçırırsa diye)
    local spells = addon.spells
    if not spells then return end
    
    if spell == addon:SpellName(spells.Overpower) then
        addon.state.dodged = false
    elseif spell == addon:SpellName(spells.Revenge) then
        addon.state.revengeAvailable = false
    end
end

function addon:InitUI()
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00WarriorRotation|r: InitUI called")
    if not addon.db and addon.InitDB then addon:InitDB() end
    if addon.InitIcons then addon:InitIcons() end
    if addon.InitOptions then addon:InitOptions() end
    if addon.RefreshUIFromDB then addon:RefreshUIFromDB() end
    if addon.db and addon.db.display and addon.db.display.showSpellIDs and addon.InstallSpellIDMouseoverHook then
        addon:InstallSpellIDMouseoverHook()
    end
end

function addon:RefreshUIFromDB()
    if addon.ApplyIconLayout then addon:ApplyIconLayout() end
    if addon.RefreshOptionsUI then addon:RefreshOptionsUI() end
end

local function OnEvent(self, event, ...)
    local arg1 = ...

    if event == "ADDON_LOADED" and arg1 == addonName then
        if addon.InitDB then addon:InitDB() end
        if addon.RefreshSpellIDs then addon:RefreshSpellIDs() end
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
        
        if addon.RefreshSpellIDs then addon:RefreshSpellIDs() end
        if addon.DetectSpec then addon:DetectSpec() end
        if addon.RefreshUIFromDB then addon:RefreshUIFromDB() end
        
    elseif event == "PLAYER_ENTERING_WORLD" then
        if addon.RefreshSpellIDs then addon:RefreshSpellIDs() end
        if addon.DetectSpec then addon:DetectSpec() end
        if addon.RefreshKnownSpells then addon:RefreshKnownSpells() end
        
    elseif event == "PLAYER_REGEN_DISABLED" then
        addon.state.inCombat = true
        
    elseif event == "PLAYER_REGEN_ENABLED" then
        addon.state.inCombat = false
        addon.state.dodged = false
        addon.state.revengeAvailable = false
        addon.state.procs = {}
        
    elseif event == "PLAYER_TARGET_CHANGED" then
        addon.state.targetGUID = UnitGUID("target")
        -- Hedef değişince procları silme, Warrior'da proclar oyuncu üzerindedir.
        
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        OnCombatLog(...)
        
    elseif event == "UNIT_AURA" and arg1 == "player" then
        addon:UpdateProcs()
        
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" and arg1 == "player" then
        local _, spell, _, _, spellID = ...
        addon:OnSpellCast(spell)

        if addon.engine and addon.engine.queue and #addon.engine.queue > 0 and spellID == addon.engine.queue[1] then
            addon.engine.pausedUntil = GetTime() + 0.3
        end
        
    elseif event == "LEARNED_SPELL_IN_TAB" or event == "SPELLS_CHANGED" or event == "PLAYER_LEVEL_UP" then
        if addon.RefreshSpellIDs then addon:RefreshSpellIDs() end
        if addon.RefreshKnownSpells then addon:RefreshKnownSpells() end
        if addon.RefreshUIFromDB then addon:RefreshUIFromDB() end
    end
end

eventFrame:SetScript("OnEvent", OnEvent)

for _, event in ipairs(events) do
    eventFrame:RegisterEvent(event)
end

if IsAddOnLoaded and IsAddOnLoaded(addonName) and not addon.db then
    if addon.InitDB then addon:InitDB() end
    if addon.RefreshSpellIDs then addon:RefreshSpellIDs() end
    if addon.InitEngine then addon:InitEngine() end
    if addon.InitCommands then addon:InitCommands() end
    if addon.InitIcons and addon.InitOptions and addon.InitUI then
        addon:InitUI()
    end
end