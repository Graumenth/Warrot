local addonName, addon = ...

WarriorRotationDB = WarriorRotationDB or {}

local defaults = {
    enabled = true,
    spec = "arms",
    iconSize = 64,
    iconX = 0,
    iconY = -200,
    showCooldowns = true,
    showRange = true,
    showKeybinds = true,
    queueLength = 4,
    onlyInCombat = false,
    updateInterval = 0.10,
    arms = {
        useRend = true,
        useOverpower = true,
        useMortalStrike = true,
        useExecute = true,
        useBladestorm = true,
        rendRefresh = 5,
        hsRageThreshold = 60,
    },
    fury = {
        useBloodthirst = true,
        useWhirlwind = true,
        useExecute = true,
        useDeathWish = true,
        useRecklessness = true,
        hsRageThreshold = 50,
    },
    prot = {
        useShieldSlam = true,
        useRevenge = true,
        useDevastate = true,
        useShockwave = true,
        useConcussionBlow = true,
        hsRageThreshold = 60,
    },
}

local function Merge(db, def)
    for k, v in pairs(def) do
        if type(v) == "table" then
            if type(db[k]) ~= "table" then db[k] = {} end
            Merge(db[k], v)
        else
            if db[k] == nil then db[k] = v end
        end
    end
end

function addon:InitDB()
    WarriorRotationDB = WarriorRotationDB or {}
    Merge(WarriorRotationDB, defaults)
    addon.db = WarriorRotationDB
end