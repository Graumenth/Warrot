local addonName, addon = ...

local defaults = {
    enabled = true,
    locked = false,
    spec = "",
    
    display = {
        iconSize = 64,
        iconSpacing = 8,
        queueLength = 4,
        iconX = 0,
        iconY = -200,
        showCooldowns = true,
        showRange = true,
        showKeybinds = true,
        showGlow = true,
        fadeOutOfRange = true,
        fadeAmount = 0.4,
    },
    
    engine = {
        updateInterval = 0.05,
        onlyInCombat = false,
        predictionWindow = 1.5,
        gcdTolerance = 0.1,
    },
    
    arms = {
        enabled = true,
        useRend = true,
        rendRefresh = 5,
        useOverpower = true,
        useMortalStrike = true,
        useExecute = true,
        executePhase = 20,
        useBladestorm = false,
        useSlam = true,
        useHeroicStrike = true,
        hsRageThreshold = 60,
        hsExecuteThreshold = 30,
        poolRageForMS = true,
        poolAmount = 30,
    },
    
    fury = {
        enabled = true,
        useBloodthirst = true,
        useWhirlwind = true,
        useExecute = true,
        executePhase = 20,
        useSlam = true,
        useHeroicStrike = true,
        hsRageThreshold = 50,
        useDeathWish = true,
        useRecklessness = false,
        useBerserkerRage = true,
    },
    
    prot = {
        enabled = true,
        useShieldSlam = true,
        useRevenge = true,
        useDevastate = true,
        useShockwave = true,
        shockwaveMinTargets = 2,
        useConcussionBlow = true,
        useHeroicStrike = true,
        hsRageThreshold = 50,
        useHeroicThrow = true,
        useThunderClap = true,
        useDemoralizingShout = true,
        maintainDebuffs = true,
    },
}

local function DeepCopy(src)
    if type(src) ~= "table" then return src end
    local copy = {}
    for k, v in pairs(src) do
        copy[k] = DeepCopy(v)
    end
    return copy
end

local function Merge(target, source)
    for k, v in pairs(source) do
        if type(v) == "table" then
            if type(target[k]) ~= "table" then
                target[k] = {}
            end
            Merge(target[k], v)
        else
            if target[k] == nil then
                target[k] = v
            end
        end
    end
end

function addon:InitDB()
    WarriorRotationDB = WarriorRotationDB or {}
    Merge(WarriorRotationDB, DeepCopy(defaults))
    addon.db = WarriorRotationDB
    addon.defaults = defaults
end

function addon:ResetDB(section)
    if section and defaults[section] then
        addon.db[section] = DeepCopy(defaults[section])
    else
        WarriorRotationDB = DeepCopy(defaults)
        addon.db = WarriorRotationDB
    end
    addon:RefreshUIFromDB()
end

function addon:GetSpecDB()
    local spec = addon.db.spec
    if spec and addon.db[spec] then
        return addon.db[spec]
    end
    return {}
end