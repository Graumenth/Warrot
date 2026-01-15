local addonName, addon = ...

local Options = addon.ui.options

function addon:InitOptionsGeneral()
    local p = Options.pages.general
    if not p then return end
    
    Options:CreateHeader(p, "General Settings", 10, -10)
    
    Options:CreateCheckbox(p, "Enable Addon", 10, -40,
        function() return addon.db.enabled end,
        function(v) addon.db.enabled = v end
    )
    
    Options:CreateCheckbox(p, "Lock Icon Position", 10, -65,
        function() return addon.db.locked end,
        function(v) addon.db.locked = v end
    )
    
    Options:CreateCheckbox(p, "Only Show In Combat", 10, -90,
        function() return addon.db.engine.onlyInCombat end,
        function(v) addon.db.engine.onlyInCombat = v end
    )
    
    Options:CreateHeader(p, "Active Spec", 10, -130)
    
    local specButtons = {}
    local specs = { "Arms", "Fury", "Prot" }
    local specX = 10
    
    local function UpdateSpecButtons()
        for _, btn in ipairs(specButtons) do
            if btn._spec == addon.db.spec then
                btn:SetNormalFontObject("GameFontHighlight")
            else
                btn:SetNormalFontObject("GameFontNormal")
            end
        end
    end
    
    for _, spec in ipairs(specs) do
        local btn = Options:CreateButton(p, spec, specX, -160, 90, 26, function()
            addon.db.spec = spec:lower()
            UpdateSpecButtons()
        end)
        btn._spec = spec:lower()
        specButtons[#specButtons + 1] = btn
        specX = specX + 100
    end
    
    Options:CreateButton(p, "Auto-Detect", specX + 20, -160, 100, 26, function()
        addon:DetectSpec()
        addon.db.spec = addon.playerSpec
        UpdateSpecButtons()
        addon:Print("Spec detected: " .. (addon.playerSpec or "none"):upper())
    end)
    
    Options.specButtons = specButtons
    Options.UpdateSpecButtons = UpdateSpecButtons
    
    Options:CreateHeader(p, "Engine Settings", 10, -210)
    
    Options:CreateSlider(p, "Update Interval (ms)", 20, 200, 10, 10, -250, 220,
        function() return (addon.db.engine.updateInterval or 0.05) * 1000 end,
        function(v) addon.db.engine.updateInterval = v / 1000 end
    )
    
    Options:CreateSlider(p, "Prediction Window (sec)", 0.5, 3, 0.1, 10, -310, 220,
        function() return addon.db.engine.predictionWindow or 1.5 end,
        function(v) addon.db.engine.predictionWindow = v end
    )
    
    Options:CreateHeader(p, "Reset", 10, -370)
    
    Options:CreateButton(p, "Reset Position", 10, -400, 120, 24, function()
        addon.db.display.iconX = 0
        addon.db.display.iconY = -200
        if addon.ApplyIconLayout then addon:ApplyIconLayout() end
        addon:Print("Position reset")
    end)
    
    Options:CreateButton(p, "Reset All Settings", 140, -400, 130, 24, function()
        StaticPopup_Show("WARRIORROTATION_RESET_CONFIRM")
    end)
end