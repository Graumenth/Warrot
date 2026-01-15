local addonName, addon = ...

local Options = addon.ui.options

function addon:InitOptionsProt()
    local p = Options.pages.prot
    if not p then return end
    
    Options:CreateHeader(p, "Protection Rotation", 10, -10)
    
    Options:CreateCheckbox(p, "Enable Prot Rotation", 10, -40,
        function() return addon.db.prot.enabled end,
        function(v) addon.db.prot.enabled = v end
    )
    
    Options:CreateHeader(p, "Abilities", 10, -80)
    
    Options:CreateCheckbox(p, "Use Shield Slam", 10, -110,
        function() return addon.db.prot.useShieldSlam end,
        function(v) addon.db.prot.useShieldSlam = v end
    )
    
    Options:CreateCheckbox(p, "Use Revenge", 10, -135,
        function() return addon.db.prot.useRevenge end,
        function(v) addon.db.prot.useRevenge = v end
    )
    
    Options:CreateCheckbox(p, "Use Devastate", 10, -160,
        function() return addon.db.prot.useDevastate end,
        function(v) addon.db.prot.useDevastate = v end
    )
    
    Options:CreateCheckbox(p, "Use Shockwave", 10, -185,
        function() return addon.db.prot.useShockwave end,
        function(v) addon.db.prot.useShockwave = v end
    )
    
    Options:CreateCheckbox(p, "Use Concussion Blow", 10, -210,
        function() return addon.db.prot.useConcussionBlow end,
        function(v) addon.db.prot.useConcussionBlow = v end
    )
    
    Options:CreateCheckbox(p, "Use Heroic Strike", 10, -235,
        function() return addon.db.prot.useHeroicStrike end,
        function(v) addon.db.prot.useHeroicStrike = v end
    )
    
    Options:CreateCheckbox(p, "Use Heroic Throw", 10, -260,
        function() return addon.db.prot.useHeroicThrow end,
        function(v) addon.db.prot.useHeroicThrow = v end
    )
    
    Options:CreateHeader(p, "Debuffs", 260, -80)
    
    Options:CreateCheckbox(p, "Maintain Debuffs", 260, -110,
        function() return addon.db.prot.maintainDebuffs end,
        function(v) addon.db.prot.maintainDebuffs = v end
    )
    
    Options:CreateCheckbox(p, "Use Thunder Clap", 260, -135,
        function() return addon.db.prot.useThunderClap end,
        function(v) addon.db.prot.useThunderClap = v end
    )
    
    Options:CreateCheckbox(p, "Use Demo Shout", 260, -160,
        function() return addon.db.prot.useDemoralizingShout end,
        function(v) addon.db.prot.useDemoralizingShout = v end
    )
    
    Options:CreateHeader(p, "Thresholds", 260, -200)
    
    Options:CreateSlider(p, "HS Rage Threshold", 20, 100, 5, 260, -240, 200,
        function() return addon.db.prot.hsRageThreshold or 50 end,
        function(v) addon.db.prot.hsRageThreshold = v end
    )
    
    Options:CreateSlider(p, "Shockwave Min Targets", 1, 5, 1, 260, -300, 200,
        function() return addon.db.prot.shockwaveMinTargets or 2 end,
        function(v) addon.db.prot.shockwaveMinTargets = v end
    )
end