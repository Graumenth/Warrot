local addonName, addon = ...

local Options = addon.ui.options

function addon:InitOptionsArms()
    local p = Options.pages.arms
    if not p then return end
    
    Options:CreateHeader(p, "Arms Rotation", 10, -10)
    
    Options:CreateCheckbox(p, "Enable Arms Rotation", 10, -40,
        function() return addon.db.arms.enabled end,
        function(v) addon.db.arms.enabled = v end
    )
    
    Options:CreateHeader(p, "Abilities", 10, -80)
    
    Options:CreateCheckbox(p, "Use Rend", 10, -110,
        function() return addon.db.arms.useRend end,
        function(v) addon.db.arms.useRend = v end
    )
    
    Options:CreateCheckbox(p, "Use Overpower", 10, -135,
        function() return addon.db.arms.useOverpower end,
        function(v) addon.db.arms.useOverpower = v end
    )
    
    Options:CreateCheckbox(p, "Use Mortal Strike", 10, -160,
        function() return addon.db.arms.useMortalStrike end,
        function(v) addon.db.arms.useMortalStrike = v end
    )
    
    Options:CreateCheckbox(p, "Use Execute", 10, -185,
        function() return addon.db.arms.useExecute end,
        function(v) addon.db.arms.useExecute = v end
    )
    
    Options:CreateCheckbox(p, "Use Bladestorm", 10, -210,
        function() return addon.db.arms.useBladestorm end,
        function(v) addon.db.arms.useBladestorm = v end
    )
    
    Options:CreateCheckbox(p, "Use Slam", 10, -235,
        function() return addon.db.arms.useSlam end,
        function(v) addon.db.arms.useSlam = v end
    )
    
    Options:CreateCheckbox(p, "Use Heroic Strike", 10, -260,
        function() return addon.db.arms.useHeroicStrike end,
        function(v) addon.db.arms.useHeroicStrike = v end
    )
    
    Options:CreateCheckbox(p, "Pool Rage for MS", 10, -285,
        function() return addon.db.arms.poolRageForMS end,
        function(v) addon.db.arms.poolRageForMS = v end
    )
    
    Options:CreateHeader(p, "Thresholds", 260, -80)
    
    Options:CreateSlider(p, "Execute Phase (%)", 10, 35, 1, 260, -120, 200,
        function() return addon.db.arms.executePhase or 20 end,
        function(v) addon.db.arms.executePhase = v end
    )
    
    Options:CreateSlider(p, "Rend Refresh (sec)", 1, 10, 1, 260, -180, 200,
        function() return addon.db.arms.rendRefresh or 5 end,
        function(v) addon.db.arms.rendRefresh = v end
    )
    
    Options:CreateSlider(p, "HS Rage Threshold", 20, 100, 5, 260, -240, 200,
        function() return addon.db.arms.hsRageThreshold or 60 end,
        function(v) addon.db.arms.hsRageThreshold = v end
    )
    
    Options:CreateSlider(p, "HS Execute Threshold", 15, 60, 5, 260, -300, 200,
        function() return addon.db.arms.hsExecuteThreshold or 30 end,
        function(v) addon.db.arms.hsExecuteThreshold = v end
    )
    
    Options:CreateSlider(p, "Pool Amount", 20, 50, 5, 260, -360, 200,
        function() return addon.db.arms.poolAmount or 30 end,
        function(v) addon.db.arms.poolAmount = v end
    )
end