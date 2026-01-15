local addonName, addon = ...

local Options = addon.ui.options

function addon:InitOptionsFury()
    local p = Options.pages.fury
    if not p then return end
    
    Options:CreateHeader(p, "Fury Rotation", 10, -10)
    
    Options:CreateCheckbox(p, "Enable Fury Rotation", 10, -40,
        function() return addon.db.fury.enabled end,
        function(v) addon.db.fury.enabled = v end
    )
    
    Options:CreateHeader(p, "Abilities", 10, -80)
    
    Options:CreateCheckbox(p, "Use Bloodthirst", 10, -110,
        function() return addon.db.fury.useBloodthirst end,
        function(v) addon.db.fury.useBloodthirst = v end
    )
    
    Options:CreateCheckbox(p, "Use Whirlwind", 10, -135,
        function() return addon.db.fury.useWhirlwind end,
        function(v) addon.db.fury.useWhirlwind = v end
    )
    
    Options:CreateCheckbox(p, "Use Execute", 10, -160,
        function() return addon.db.fury.useExecute end,
        function(v) addon.db.fury.useExecute = v end
    )
    
    Options:CreateCheckbox(p, "Use Slam (Bloodsurge)", 10, -185,
        function() return addon.db.fury.useSlam end,
        function(v) addon.db.fury.useSlam = v end
    )
    
    Options:CreateCheckbox(p, "Use Heroic Strike", 10, -210,
        function() return addon.db.fury.useHeroicStrike end,
        function(v) addon.db.fury.useHeroicStrike = v end
    )
    
    Options:CreateHeader(p, "Cooldowns", 10, -250)
    
    Options:CreateCheckbox(p, "Use Death Wish", 10, -280,
        function() return addon.db.fury.useDeathWish end,
        function(v) addon.db.fury.useDeathWish = v end
    )
    
    Options:CreateCheckbox(p, "Use Recklessness", 10, -305,
        function() return addon.db.fury.useRecklessness end,
        function(v) addon.db.fury.useRecklessness = v end
    )
    
    Options:CreateCheckbox(p, "Use Berserker Rage", 10, -330,
        function() return addon.db.fury.useBerserkerRage end,
        function(v) addon.db.fury.useBerserkerRage = v end
    )
    
    Options:CreateHeader(p, "Thresholds", 260, -80)
    
    Options:CreateSlider(p, "Execute Phase (%)", 10, 35, 1, 260, -120, 200,
        function() return addon.db.fury.executePhase or 20 end,
        function(v) addon.db.fury.executePhase = v end
    )
    
    Options:CreateSlider(p, "HS Rage Threshold", 20, 100, 5, 260, -180, 200,
        function() return addon.db.fury.hsRageThreshold or 50 end,
        function(v) addon.db.fury.hsRageThreshold = v end
    )
end