local addonName, addon = ...

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00WarriorRotation|r: " .. msg)
end

local function PrintHelp()
    Print("Commands:")
    Print("  |cFFFFFF00/wr|r - Toggle options panel")
    Print("  |cFFFFFF00/wr toggle|r - Enable/disable addon")
    Print("  |cFFFFFF00/wr lock|r - Lock/unlock icon frame")
    Print("  |cFFFFFF00/wr reset|r - Reset icon position")
    Print("  |cFFFFFF00/wr arms|r - Switch to Arms")
    Print("  |cFFFFFF00/wr fury|r - Switch to Fury")
    Print("  |cFFFFFF00/wr prot|r - Switch to Protection")
    Print("  |cFFFFFF00/wr status|r - Show current status")
    Print("  |cFFFFFF00/wr debug|r - Toggle debug mode")
end

local function PrintStatus()
    local db = addon.db
    Print("Status:")
    Print("  Enabled: " .. (db.enabled and "|cFF00FF00Yes|r" or "|cFFFF0000No|r"))
    Print("  Spec: |cFFFFFF00" .. (db.spec or "none"):upper() .. "|r")
    Print("  Detected: |cFFFFFF00" .. (addon.playerSpec or "none"):upper() .. "|r")
    Print("  In Combat: " .. (addon:InCombat() and "|cFFFF0000Yes|r" or "|cFF00FF00No|r"))
    Print("  Stance: |cFFFFFF00" .. (addon:GetStance() or "none") .. "|r")
    Print("  Rage: |cFFFFFF00" .. addon:Rage() .. "|r")
end

local commands = {
    [""] = function()
        if addon.frames.options and addon.frames.options:IsShown() then
            addon:HideOptions()
        else
            addon:ShowOptions()
        end
    end,
    
    ["options"] = function()
        addon:ShowOptions()
    end,
    
    ["opt"] = function()
        addon:ShowOptions()
    end,
    
    ["toggle"] = function()
        addon.db.enabled = not addon.db.enabled
        Print("Addon " .. (addon.db.enabled and "|cFF00FF00enabled|r" or "|cFFFF0000disabled|r"))
    end,
    
    ["on"] = function()
        addon.db.enabled = true
        Print("Addon |cFF00FF00enabled|r")
    end,
    
    ["off"] = function()
        addon.db.enabled = false
        Print("Addon |cFFFF0000disabled|r")
    end,
    
    ["lock"] = function()
        addon.db.locked = not addon.db.locked
        Print("Icons " .. (addon.db.locked and "|cFFFF0000locked|r" or "|cFF00FF00unlocked|r (Shift+Drag to move)"))
    end,
    
    ["reset"] = function()
        addon.db.display.iconX = 0
        addon.db.display.iconY = -200
        addon.db.display.iconSize = 64
        addon:ApplyIconLayout()
        Print("Icon position reset")
    end,
    
    ["resetall"] = function()
        addon:ResetDB()
        Print("All settings reset to defaults")
    end,
    
    ["arms"] = function()
        addon.db.spec = "arms"
        Print("Spec set to |cFFC79C6EArms|r")
        if addon.RefreshOptionsUI then addon:RefreshOptionsUI() end
    end,
    
    ["fury"] = function()
        addon.db.spec = "fury"
        Print("Spec set to |cFFC79C6EFury|r")
        if addon.RefreshOptionsUI then addon:RefreshOptionsUI() end
    end,
    
    ["prot"] = function()
        addon.db.spec = "prot"
        Print("Spec set to |cFFC79C6EProtection|r")
        if addon.RefreshOptionsUI then addon:RefreshOptionsUI() end
    end,
    
    ["protection"] = function()
        commands["prot"]()
    end,
    
    ["status"] = function()
        PrintStatus()
    end,
    
    ["debug"] = function()
        addon.db.debug = not addon.db.debug
        Print("Debug mode " .. (addon.db.debug and "|cFF00FF00enabled|r" or "|cFFFF0000disabled|r"))
    end,
    
    ["help"] = function()
        PrintHelp()
    end,
}

function addon:InitCommands()
    SLASH_WARRIORROTATION1 = "/warriorrotation"
    SLASH_WARRIORROTATION2 = "/warrot"
    SLASH_WARRIORROTATION3 = "/wr"

    SlashCmdList["WARRIORROTATION"] = function(msg)
        msg = (msg or ""):lower():match("^%s*(.-)%s*$") or ""
        
        local cmd, args = msg:match("^(%S*)%s*(.*)$")
        cmd = cmd or ""
        
        if commands[cmd] then
            commands[cmd](args)
        else
            Print("Unknown command: |cFFFF0000" .. cmd .. "|r")
            PrintHelp()
        end
    end
end

function addon:Print(msg)
    Print(msg)
end

function addon:Debug(msg)
    if addon.db and addon.db.debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF888888WR Debug|r: " .. tostring(msg))
    end
end