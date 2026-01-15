local addonName, addon = ...

local Options = addon.ui.options

function addon:InstallSpellIDMouseoverHook()
    if addon._spellIDHookInstalled then return end
    addon._spellIDHookInstalled = true
    
    local function OnTooltipSetSpell(self)
        if not addon.db or not addon.db.display or not addon.db.display.showSpellIDs then return end
        
        local name, rank = self:GetSpell()
        if not name then return end

        local id = nil
        
        local link = GetSpellLink(name)
        if link then
             id = link:match("spell:(%d+)")
        end
        
        if not id and addon.knownSpells then
            local info = addon.knownSpells[name]
            if info then
                id = info.id
            end
        end

        if id then
            self:AddLine("Spell ID: " .. id, 0.8, 0.8, 0.8)
            self:Show()
        end
    end
    
    if GameTooltip and GameTooltip.HookScript then
        GameTooltip:HookScript("OnTooltipSetSpell", OnTooltipSetSpell)
    end
end

function addon:InitOptionsDisplay()
    local p = Options.pages.display
    if not p then return end
    
    Options:CreateHeader(p, "Display Settings", 10, -10)
    
    Options:CreateCheckbox(p, "Show Cooldown Spirals", 10, -40,
        function() return addon.db.display.showCooldowns end,
        function(v) addon.db.display.showCooldowns = v end
    )
    
    Options:CreateCheckbox(p, "Show Range Indicator", 10, -65,
        function() return addon.db.display.showRange end,
        function(v) addon.db.display.showRange = v end
    )
    
    Options:CreateCheckbox(p, "Show Keybinds", 10, -90,
        function() return addon.db.display.showKeybinds end,
        function(v) addon.db.display.showKeybinds = v end
    )
    
    Options:CreateCheckbox(p, "Show Glow Effect", 10, -115,
        function() return addon.db.display.showGlow end,
        function(v) addon.db.display.showGlow = v end
    )
    
    Options:CreateCheckbox(p, "Fade Out of Range", 10, -140,
        function() return addon.db.display.fadeOutOfRange end,
        function(v) addon.db.display.fadeOutOfRange = v end
    )
    
    Options:CreateHeader(p, "Size & Layout", 10, -210)
    
    Options:CreateSlider(p, "Icon Size", 32, 128, 4, 10, -250, 200,
        function() return addon.db.display.iconSize or 64 end,
        function(v)
            addon.db.display.iconSize = v
            if addon.ApplyIconLayout then addon:ApplyIconLayout() end
        end
    )
    
    Options:CreateSlider(p, "Icon Spacing", 0, 20, 1, 10, -310, 200,
        function() return addon.db.display.iconSpacing or 8 end,
        function(v)
            addon.db.display.iconSpacing = v
            if addon.ApplyIconLayout then addon:ApplyIconLayout() end
        end
    )
    
    Options:CreateSlider(p, "Queue Length", 1, 4, 1, 10, -370, 200,
        function() return addon.db.display.queueLength or 4 end,
        function(v) addon.db.display.queueLength = v end
    )
    
    Options:CreateHeader(p, "Position", 270, -210)
    
    Options:CreateSlider(p, "Position X", -600, 600, 10, 270, -250, 200,
        function() return addon.db.display.iconX or 0 end,
        function(v)
            addon.db.display.iconX = v
            if addon.ApplyIconLayout then addon:ApplyIconLayout() end
        end
    )
    
    Options:CreateSlider(p, "Position Y", -500, 500, 10, 270, -310, 200,
        function() return addon.db.display.iconY or -200 end,
        function(v)
            addon.db.display.iconY = v
            if addon.ApplyIconLayout then addon:ApplyIconLayout() end
        end
    )
    
    Options:CreateSlider(p, "Fade Amount", 0.2, 1, 0.1, 270, -370, 200,
        function() return addon.db.display.fadeAmount or 0.4 end,
        function(v) addon.db.display.fadeAmount = v end
    )
    
    Options:CreateCheckbox(p, "Show Spell IDs (Tooltip)", 10, -410,
        function() return addon.db.display.showSpellIDs end,
        function(v)
            addon.db.display.showSpellIDs = v
            if v and addon.InstallSpellIDMouseoverHook then
                addon:InstallSpellIDMouseoverHook()
            end
        end
    )
end