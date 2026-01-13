local addonName, addon = ...

_G[addonName] = addon

addon.name = addonName
addon.frames = {}
addon.modules = {}
addon.rotations = {}

local eventFrame = CreateFrame("Frame")
addon.eventFrame = eventFrame

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        addon:InitDB()
        addon:InitUI()
        addon:InitEngine()
        addon:InitCommands()
    elseif event == "PLAYER_LOGIN" then
        local _, class = UnitClass("player")
        if class ~= "WARRIOR" then
            if addon.frames.main then addon.frames.main:Hide() end
            return
        end
        addon:RefreshUIFromDB()
        addon:ApplyIconLayout()
    end
end)

function addon:InitUI()
    addon:InitIcons()
    addon:InitOptions()
end

function addon:RefreshUIFromDB()
    addon:ApplyIconLayout()
    if addon.RefreshOptionsUI then addon:RefreshOptionsUI() end
end