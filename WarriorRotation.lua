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
    arms = {
        useRend = true,
        useOverpower = true,
        useMortalStrike = true,
        useExecute = true,
        useSweepingStrikes = true,
        useBladestorm = true,
        rendThreshold = 5,
    },
    fury = {
        useBloodthirst = true,
        useWhirlwind = true,
        useHeroicStrike = true,
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
        useHeroicStrike = true,
        hsRageThreshold = 60,
    },
}

local function DeepCopy(orig)
    local copy
    if type(orig) == 'table' then
        copy = {}
        for k, v in pairs(orig) do
            copy[k] = DeepCopy(v)
        end
    else
        copy = orig
    end
    return copy
end

local function MergeDefaults(db, def)
    for k, v in pairs(def) do
        if type(v) == "table" then
            if type(db[k]) ~= "table" then db[k] = {} end
            MergeDefaults(db[k], v)
        elseif db[k] == nil then
            db[k] = v
        end
    end
end

local mainFrame = CreateFrame("Frame", "WarriorRotationFrame", UIParent)
mainFrame:SetSize(300, 80)
mainFrame:SetPoint("CENTER", 0, -200)

local NUM_QUEUE_ICONS = 4
local iconFrames = {}

local function CreateIconFrame(parent, size, isPrimary)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(size, size)
    
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", -2, 2)
    bg:SetPoint("BOTTOMRIGHT", 2, -2)
    bg:SetColorTexture(0, 0, 0, 0.8)
    f.bg = bg
    
    local border = f:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT", -3, 3)
    border:SetPoint("BOTTOMRIGHT", 3, -3)
    if isPrimary then
        border:SetColorTexture(1, 0.82, 0, 1)
    else
        border:SetColorTexture(0.3, 0.3, 0.3, 1)
    end
    f.border = border
    
    local icon = f:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    f.icon = icon
    
    local cd = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
    cd:SetAllPoints()
    cd:SetDrawEdge(false)
    cd:SetHideCountdownNumbers(false)
    f.cooldown = cd
    
    local rangeOverlay = f:CreateTexture(nil, "OVERLAY")
    rangeOverlay:SetAllPoints()
    rangeOverlay:SetColorTexture(1, 0, 0, 0.4)
    rangeOverlay:Hide()
    f.rangeOverlay = rangeOverlay
    
    local keybind = f:CreateFontString(nil, "OVERLAY")
    keybind:SetFont("Fonts\\FRIZQT__.TTF", isPrimary and 14 or 10, "OUTLINE")
    keybind:SetPoint("TOPLEFT", 2, -2)
    keybind:SetTextColor(1, 1, 1, 1)
    f.keybind = keybind
    
    if isPrimary then
        local glow = f:CreateTexture(nil, "OVERLAY")
        glow:SetPoint("TOPLEFT", -8, 8)
        glow:SetPoint("BOTTOMRIGHT", 8, -8)
        glow:SetTexture("Interface\\SpellActivationOverlay\\IconAlert")
        glow:SetTexCoord(0, 1, 0, 1)
        glow:SetVertexColor(1, 0.82, 0, 0.5)
        glow:SetBlendMode("ADD")
        f.glow = glow
    end
    
    f:Hide()
    return f
end

local primaryIcon = CreateIconFrame(mainFrame, 64, true)
primaryIcon:SetPoint("LEFT", mainFrame, "LEFT", 0, 0)
iconFrames[1] = primaryIcon

for i = 2, NUM_QUEUE_ICONS do
    local queueIcon = CreateIconFrame(mainFrame, 40, false)
    queueIcon:SetPoint("LEFT", iconFrames[i-1], "RIGHT", 8, 0)
    iconFrames[i] = queueIcon
end

local function GetKeybindText(spellID)
    local name = GetSpellName(spellID)
    if not name then return "" end
    
    for i = 1, 120 do
        local actionType, id = GetActionInfo(i)
        if actionType == "spell" and id == spellID then
            local key = GetBindingKey("ACTIONBUTTON" .. i)
            if key then
                key = key:gsub("SHIFT%-", "S-")
                key = key:gsub("CTRL%-", "C-")
                key = key:gsub("ALT%-", "A-")
                return key
            end
        end
    end
    return ""
end

local function UpdateIconFrame(index, spellID, showRange)
    local f = iconFrames[index]
    if not spellID or index > WarriorRotationDB.queueLength then
        f:Hide()
        return
    end
    
    local name, _, spellIcon = GetSpellInfo(spellID)
    if not spellIcon then
        f:Hide()
        return
    end
    
    f.icon:SetTexture(spellIcon)
    
    if WarriorRotationDB.showKeybinds then
        f.keybind:SetText(GetKeybindText(spellID))
    else
        f.keybind:SetText("")
    end
    
    if WarriorRotationDB.showCooldowns then
        local start, duration = GetSpellCooldown(name)
        if start and duration and duration > 0 then
            f.cooldown:SetCooldown(start, duration)
        else
            f.cooldown:Clear()
        end
    else
        f.cooldown:Clear()
    end
    
    if showRange and WarriorRotationDB.showRange and index == 1 then
        local inRange = IsInMeleeRange()
        if inRange then
            f.rangeOverlay:Hide()
            f.icon:SetVertexColor(1, 1, 1, 1)
        else
            f.rangeOverlay:Show()
            f.icon:SetVertexColor(0.8, 0.2, 0.2, 1)
        end
    else
        f.rangeOverlay:Hide()
        f.icon:SetVertexColor(1, 1, 1, 1)
    end
    
    f:Show()
end

local spellIDs = {
    Rend = 47465,
    Overpower = 7384,
    MortalStrike = 47486,
    Execute = 47471,
    SweepingStrikes = 12328,
    Bladestorm = 46924,
    Bloodthirst = 23881,
    Whirlwind = 1680,
    HeroicStrike = 47450,
    DeathWish = 12292,
    Recklessness = 1719,
    ShieldSlam = 47488,
    Revenge = 57823,
    Devastate = 47498,
    Shockwave = 46968,
    ConcussionBlow = 12809,
    BattleShout = 47436,
    CommandingShout = 47440,
    ThunderClap = 47502,
    SunderArmor = 7386,
    VictoryRush = 34428,
    Slam = 47475,
    Cleave = 47520,
    Charge = 11578,
    Intercept = 20252,
    BerserkerRage = 18499,
    Pummel = 6552,
    ShieldBash = 72,
    Taunt = 355,
    MockingBlow = 694,
    ChallengingShout = 1161,
    ShieldBlock = 2565,
    ShieldWall = 871,
    LastStand = 12975,
    Enrage = 12880,
}

local function GetSpellName(spellID)
    return GetSpellInfo(spellID)
end

local function IsSpellLearned(spellID)
    local name = GetSpellName(spellID)
    if not name then return false end
    
    local spellLink = GetSpellLink(name)
    if not spellLink then return false end
    
    for tab = 1, GetNumSpellTabs() do
        local _, _, offset, numSpells = GetSpellTabInfo(tab)
        for i = offset + 1, offset + numSpells do
            local spellName = GetSpellBookItemName(i, BOOKTYPE_SPELL)
            if spellName == name then
                return true
            end
        end
    end
    return false
end

local function IsSpellReady(spellID)
    local name = GetSpellName(spellID)
    if not name then return false end
    
    if not IsSpellLearned(spellID) then return false end
    
    local usable, nomana = IsUsableSpell(name)
    if not usable then return false end
    local start, duration = GetSpellCooldown(name)
    if start and duration and duration > 1.5 then return false end
    return true
end

local function GetSpellCooldownRemaining(spellID)
    local name = GetSpellName(spellID)
    if not name then return 999 end
    local start, duration = GetSpellCooldown(name)
    if not start or start == 0 then return 0 end
    return (start + duration - GetTime())
end

local function IsInMeleeRange()
    if not UnitExists("target") then return false end
    return IsSpellInRange(GetSpellName(spellIDs.HeroicStrike), "target") == 1
end

local function GetCurrentRage()
    return UnitPower("player", 1)
end

local function HasDebuff(unit, spellID)
    local name = GetSpellName(spellID)
    if not name then return false, 0 end
    for i = 1, 40 do
        local dName, _, _, _, _, duration, expirationTime, caster = UnitDebuff(unit, i)
        if not dName then break end
        if dName == name and caster == "player" then
            local remaining = expirationTime - GetTime()
            return true, remaining
        end
    end
    return false, 0
end

local function HasBuff(unit, spellID)
    local name = GetSpellName(spellID)
    if not name then return false, 0 end
    for i = 1, 40 do
        local bName, _, _, _, _, duration, expirationTime = UnitBuff(unit, i)
        if not bName then break end
        if bName == name then
            local remaining = expirationTime and (expirationTime - GetTime()) or 999
            return true, remaining
        end
    end
    return false, 0
end

local function HasOverpowerProc()
    local hasProc = HasBuff("player", 60503)
    if hasProc then return true end
    return false
end

local function GetCurrentSpec()
    local arms, fury, prot = 0, 0, 0
    local numTabs = GetNumTalentTabs()
    for i = 1, numTabs do
        local _, _, pointsSpent = GetTalentTabInfo(i)
        if i == 1 then arms = pointsSpent
        elseif i == 2 then fury = pointsSpent
        elseif i == 3 then prot = pointsSpent
        end
    end
    if arms >= fury and arms >= prot then return "arms"
    elseif fury >= arms and fury >= prot then return "fury"
    else return "prot"
    end
end

local function GetArmsRotation()
    local db = WarriorRotationDB.arms
    local rage = GetCurrentRage()
    local targetHP = UnitHealth("target") / UnitHealthMax("target") * 100
    local queue = {}
    
    if db.useExecute and targetHP <= 20 and IsSpellLearned(spellIDs.Execute) then
        table.insert(queue, spellIDs.Execute)
    end
    
    if db.useOverpower and IsSpellLearned(spellIDs.Overpower) then
        table.insert(queue, spellIDs.Overpower)
    end
    
    if db.useRend and IsSpellLearned(spellIDs.Rend) then
        local hasRend, remaining = HasDebuff("target", spellIDs.Rend)
        if not hasRend or remaining < db.rendThreshold then
            table.insert(queue, spellIDs.Rend)
        end
    end
    
    if db.useMortalStrike and IsSpellLearned(spellIDs.MortalStrike) then
        table.insert(queue, spellIDs.MortalStrike)
    end
    
    if db.useBladestorm and IsSpellLearned(spellIDs.Bladestorm) then
        table.insert(queue, spellIDs.Bladestorm)
    end
    
    if IsSpellLearned(spellIDs.Slam) then
        table.insert(queue, spellIDs.Slam)
    end
    
    if IsSpellLearned(spellIDs.HeroicStrike) then
        table.insert(queue, spellIDs.HeroicStrike)
    end
    
    table.sort(queue, function(a, b)
        local cdA = GetSpellCooldownRemaining(a)
        local cdB = GetSpellCooldownRemaining(b)
        if cdA <= 0 and cdB <= 0 then
            return false
        end
        return cdA < cdB
    end)
    
    local result = {}
    for i, spellID in ipairs(queue) do
        if #result < NUM_QUEUE_ICONS then
            table.insert(result, spellID)
        end
    end
    
    return result
end

local function GetFuryRotation()
    local db = WarriorRotationDB.fury
    local rage = GetCurrentRage()
    local targetHP = UnitHealth("target") / UnitHealthMax("target") * 100
    local queue = {}
    
    if db.useExecute and targetHP <= 20 and IsSpellLearned(spellIDs.Execute) then
        table.insert(queue, spellIDs.Execute)
    end
    
    if db.useDeathWish and IsSpellLearned(spellIDs.DeathWish) then
        table.insert(queue, spellIDs.DeathWish)
    end
    
    if db.useRecklessness and IsSpellLearned(spellIDs.Recklessness) then
        table.insert(queue, spellIDs.Recklessness)
    end
    
    if db.useBloodthirst and IsSpellLearned(spellIDs.Bloodthirst) then
        table.insert(queue, spellIDs.Bloodthirst)
    end
    
    if db.useWhirlwind and IsSpellLearned(spellIDs.Whirlwind) then
        table.insert(queue, spellIDs.Whirlwind)
    end
    
    if IsSpellLearned(spellIDs.Slam) then
        table.insert(queue, spellIDs.Slam)
    end
    
    if IsSpellLearned(spellIDs.HeroicStrike) and rage >= db.hsRageThreshold then
        table.insert(queue, spellIDs.HeroicStrike)
    end
    
    table.sort(queue, function(a, b)
        local cdA = GetSpellCooldownRemaining(a)
        local cdB = GetSpellCooldownRemaining(b)
        if cdA <= 0 and cdB <= 0 then
            return false
        end
        return cdA < cdB
    end)
    
    local result = {}
    for i, spellID in ipairs(queue) do
        if #result < NUM_QUEUE_ICONS then
            table.insert(result, spellID)
        end
    end
    
    return result
end

local function GetProtRotation()
    local db = WarriorRotationDB.prot
    local rage = GetCurrentRage()
    local queue = {}
    
    if db.useShieldSlam and IsSpellLearned(spellIDs.ShieldSlam) then
        table.insert(queue, spellIDs.ShieldSlam)
    end
    
    if db.useRevenge and IsSpellLearned(spellIDs.Revenge) then
        table.insert(queue, spellIDs.Revenge)
    end
    
    if db.useShockwave and IsSpellLearned(spellIDs.Shockwave) then
        table.insert(queue, spellIDs.Shockwave)
    end
    
    if db.useConcussionBlow and IsSpellLearned(spellIDs.ConcussionBlow) then
        table.insert(queue, spellIDs.ConcussionBlow)
    end
    
    if db.useDevastate and IsSpellLearned(spellIDs.Devastate) then
        table.insert(queue, spellIDs.Devastate)
    end
    
    if IsSpellLearned(spellIDs.SunderArmor) then
        table.insert(queue, spellIDs.SunderArmor)
    end
    
    if db.useHeroicStrike and IsSpellLearned(spellIDs.HeroicStrike) and rage >= db.hsRageThreshold then
        table.insert(queue, spellIDs.HeroicStrike)
    end
    
    table.sort(queue, function(a, b)
        local cdA = GetSpellCooldownRemaining(a)
        local cdB = GetSpellCooldownRemaining(b)
        if cdA <= 0 and cdB <= 0 then
            return false
        end
        return cdA < cdB
    end)
    
    local result = {}
    for i, spellID in ipairs(queue) do
        if #result < NUM_QUEUE_ICONS then
            table.insert(result, spellID)
        end
    end
    
    return result
end

local function GetSpellQueue()
    if not WarriorRotationDB.enabled then return {} end
    if not UnitExists("target") or UnitIsDead("target") or not UnitCanAttack("player", "target") then
        return {}
    end
    
    local spec = WarriorRotationDB.spec
    if spec == "arms" then
        return GetArmsRotation()
    elseif spec == "fury" then
        return GetFuryRotation()
    elseif spec == "prot" then
        return GetProtRotation()
    end
    return {}
end

local lastUpdate = 0
local updateInterval = 0.05

local function OnUpdate(self, elapsed)
    lastUpdate = lastUpdate + elapsed
    if lastUpdate < updateInterval then return end
    lastUpdate = 0
    
    local queue = GetSpellQueue()
    
    if #queue == 0 then
        for i = 1, NUM_QUEUE_ICONS do
            iconFrames[i]:Hide()
        end
        return
    end
    
    for i = 1, NUM_QUEUE_ICONS do
        UpdateIconFrame(i, queue[i], i == 1)
    end
end

mainFrame:SetScript("OnUpdate", OnUpdate)

local settingsFrame = CreateFrame("Frame", "WarriorRotationSettings", UIParent, "BasicFrameTemplateWithInset")
settingsFrame:SetSize(400, 500)
settingsFrame:SetPoint("CENTER")
settingsFrame:SetMovable(true)
settingsFrame:EnableMouse(true)
settingsFrame:RegisterForDrag("LeftButton")
settingsFrame:SetScript("OnDragStart", settingsFrame.StartMoving)
settingsFrame:SetScript("OnDragStop", settingsFrame.StopMovingOrSizing)
settingsFrame:Hide()

settingsFrame.title = settingsFrame:CreateFontString(nil, "OVERLAY")
settingsFrame.title:SetFontObject("GameFontHighlight")
settingsFrame.title:SetPoint("TOP", 0, -5)
settingsFrame.title:SetText("Warrior Rotation Settings")

local scrollFrame = CreateFrame("ScrollFrame", "WarriorRotationSettingsScroll", settingsFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 10, -30)
scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

local scrollChild = CreateFrame("Frame", nil, scrollFrame)
scrollChild:SetSize(350, 800)
scrollFrame:SetScrollChild(scrollChild)

local yOffset = -10

local function CreateCheckbox(parent, label, dbPath, subKey)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", 10, yOffset)
    cb.text = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cb.text:SetPoint("LEFT", cb, "RIGHT", 5, 0)
    cb.text:SetText(label)
    cb.dbPath = dbPath
    cb.subKey = subKey
    cb:SetScript("OnClick", function(self)
        if self.dbPath then
            WarriorRotationDB[self.dbPath][self.subKey] = self:GetChecked()
        else
            WarriorRotationDB[self.subKey] = self:GetChecked()
        end
    end)
    yOffset = yOffset - 25
    return cb
end

local function CreateSlider(parent, label, minVal, maxVal, step, dbPath, subKey)
    local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", 20, yOffset)
    slider:SetWidth(200)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider.Low:SetText(minVal)
    slider.High:SetText(maxVal)
    slider.Text:SetText(label)
    slider.dbPath = dbPath
    slider.subKey = subKey
    
    local valueText = slider:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    valueText:SetPoint("TOP", slider, "BOTTOM", 0, 0)
    slider.valueText = valueText
    
    slider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        self.valueText:SetText(value)
        if self.dbPath then
            WarriorRotationDB[self.dbPath][self.subKey] = value
        else
            WarriorRotationDB[self.subKey] = value
        end
    end)
    yOffset = yOffset - 50
    return slider
end

local function CreateHeader(parent, text)
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", 10, yOffset)
    header:SetText(text)
    header:SetTextColor(1, 0.82, 0)
    yOffset = yOffset - 25
    return header
end

local function CreateSpecButton(parent, spec, label)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(100, 25)
    btn:SetText(label)
    btn:SetScript("OnClick", function()
        WarriorRotationDB.spec = spec
        addon:UpdateSpecButtons()
    end)
    btn.spec = spec
    return btn
end

CreateHeader(scrollChild, "General Settings")

local enabledCB = CreateCheckbox(scrollChild, "Enable Addon", nil, "enabled")
local showCooldownsCB = CreateCheckbox(scrollChild, "Show Cooldowns", nil, "showCooldowns")
local showRangeCB = CreateCheckbox(scrollChild, "Show Range Indicator", nil, "showRange")
local showKeybindsCB = CreateCheckbox(scrollChild, "Show Keybinds", nil, "showKeybinds")

yOffset = yOffset - 10
CreateHeader(scrollChild, "Spec Selection")

local specButtonFrame = CreateFrame("Frame", nil, scrollChild)
specButtonFrame:SetPoint("TOPLEFT", 10, yOffset)
specButtonFrame:SetSize(340, 30)

local armsBtn = CreateSpecButton(specButtonFrame, "arms", "Arms")
armsBtn:SetPoint("LEFT", 0, 0)

local furyBtn = CreateSpecButton(specButtonFrame, "fury", "Fury")
furyBtn:SetPoint("LEFT", armsBtn, "RIGHT", 10, 0)

local protBtn = CreateSpecButton(specButtonFrame, "prot", "Protection")
protBtn:SetPoint("LEFT", furyBtn, "RIGHT", 10, 0)

addon.specButtons = {armsBtn, furyBtn, protBtn}

function addon:UpdateSpecButtons()
    for _, btn in ipairs(addon.specButtons) do
        if btn.spec == WarriorRotationDB.spec then
            btn:SetNormalFontObject("GameFontHighlight")
        else
            btn:SetNormalFontObject("GameFontNormal")
        end
    end
end

yOffset = yOffset - 40

local autoDetectBtn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
autoDetectBtn:SetPoint("TOPLEFT", 10, yOffset)
autoDetectBtn:SetSize(150, 25)
autoDetectBtn:SetText("Auto-Detect Spec")
autoDetectBtn:SetScript("OnClick", function()
    WarriorRotationDB.spec = GetCurrentSpec()
    addon:UpdateSpecButtons()
    print("|cFF00FF00Warrior Rotation:|r Spec detected: " .. WarriorRotationDB.spec)
end)

yOffset = yOffset - 40

CreateHeader(scrollChild, "Icon Settings")

local iconSizeSlider = CreateSlider(scrollChild, "Icon Size", 32, 128, 8, nil, "iconSize")

local iconXSlider = CreateSlider(scrollChild, "Icon X Position", -500, 500, 10, nil, "iconX")

local iconYSlider = CreateSlider(scrollChild, "Icon Y Position", -500, 500, 10, nil, "iconY")

local queueLengthSlider = CreateSlider(scrollChild, "Queue Length (icons shown)", 1, 4, 1, nil, "queueLength")

yOffset = yOffset - 10
CreateHeader(scrollChild, "Arms Settings")

local armsRendCB = CreateCheckbox(scrollChild, "Use Rend", "arms", "useRend")
local armsOverpowerCB = CreateCheckbox(scrollChild, "Use Overpower", "arms", "useOverpower")
local armsMSCB = CreateCheckbox(scrollChild, "Use Mortal Strike", "arms", "useMortalStrike")
local armsExecuteCB = CreateCheckbox(scrollChild, "Use Execute", "arms", "useExecute")
local armsBladestormCB = CreateCheckbox(scrollChild, "Use Bladestorm", "arms", "useBladestorm")

local armsRendThreshold = CreateSlider(scrollChild, "Rend Refresh (seconds left)", 1, 10, 1, "arms", "rendThreshold")

yOffset = yOffset - 10
CreateHeader(scrollChild, "Fury Settings")

local furyBTCB = CreateCheckbox(scrollChild, "Use Bloodthirst", "fury", "useBloodthirst")
local furyWWCB = CreateCheckbox(scrollChild, "Use Whirlwind", "fury", "useWhirlwind")
local furyExecuteCB = CreateCheckbox(scrollChild, "Use Execute", "fury", "useExecute")
local furyDeathWishCB = CreateCheckbox(scrollChild, "Use Death Wish", "fury", "useDeathWish")

local furyHSThreshold = CreateSlider(scrollChild, "Heroic Strike Rage Threshold", 20, 80, 5, "fury", "hsRageThreshold")

yOffset = yOffset - 10
CreateHeader(scrollChild, "Protection Settings")

local protSSCB = CreateCheckbox(scrollChild, "Use Shield Slam", "prot", "useShieldSlam")
local protRevengeCB = CreateCheckbox(scrollChild, "Use Revenge", "prot", "useRevenge")
local protDevastateCB = CreateCheckbox(scrollChild, "Use Devastate", "prot", "useDevastate")
local protShockwaveCB = CreateCheckbox(scrollChild, "Use Shockwave", "prot", "useShockwave")
local protConcussionCB = CreateCheckbox(scrollChild, "Use Concussion Blow", "prot", "useConcussionBlow")

local protHSThreshold = CreateSlider(scrollChild, "Heroic Strike Rage Threshold", 30, 90, 5, "prot", "hsRageThreshold")

local allCheckboxes = {
    {cb = enabledCB, path = nil, key = "enabled"},
    {cb = showCooldownsCB, path = nil, key = "showCooldowns"},
    {cb = showRangeCB, path = nil, key = "showRange"},
    {cb = showKeybindsCB, path = nil, key = "showKeybinds"},
    {cb = armsRendCB, path = "arms", key = "useRend"},
    {cb = armsOverpowerCB, path = "arms", key = "useOverpower"},
    {cb = armsMSCB, path = "arms", key = "useMortalStrike"},
    {cb = armsExecuteCB, path = "arms", key = "useExecute"},
    {cb = armsBladestormCB, path = "arms", key = "useBladestorm"},
    {cb = furyBTCB, path = "fury", key = "useBloodthirst"},
    {cb = furyWWCB, path = "fury", key = "useWhirlwind"},
    {cb = furyExecuteCB, path = "fury", key = "useExecute"},
    {cb = furyDeathWishCB, path = "fury", key = "useDeathWish"},
    {cb = protSSCB, path = "prot", key = "useShieldSlam"},
    {cb = protRevengeCB, path = "prot", key = "useRevenge"},
    {cb = protDevastateCB, path = "prot", key = "useDevastate"},
    {cb = protShockwaveCB, path = "prot", key = "useShockwave"},
    {cb = protConcussionCB, path = "prot", key = "useConcussionBlow"},
}

local allSliders = {
    {slider = iconSizeSlider, path = nil, key = "iconSize"},
    {slider = iconXSlider, path = nil, key = "iconX"},
    {slider = iconYSlider, path = nil, key = "iconY"},
    {slider = queueLengthSlider, path = nil, key = "queueLength"},
    {slider = armsRendThreshold, path = "arms", key = "rendThreshold"},
    {slider = furyHSThreshold, path = "fury", key = "hsRageThreshold"},
    {slider = protHSThreshold, path = "prot", key = "hsRageThreshold"},
}

local function RefreshSettingsUI()
    for _, data in ipairs(allCheckboxes) do
        local value
        if data.path then
            value = WarriorRotationDB[data.path][data.key]
        else
            value = WarriorRotationDB[data.key]
        end
        data.cb:SetChecked(value)
    end
    
    for _, data in ipairs(allSliders) do
        local value
        if data.path then
            value = WarriorRotationDB[data.path][data.key]
        else
            value = WarriorRotationDB[data.key]
        end
        data.slider:SetValue(value)
    end
    
    addon:UpdateSpecButtons()
end

local function UpdateIconPosition()
    mainFrame:ClearAllPoints()
    mainFrame:SetPoint("CENTER", UIParent, "CENTER", WarriorRotationDB.iconX, WarriorRotationDB.iconY)
    
    local size = WarriorRotationDB.iconSize
    primaryIcon:SetSize(size, size)
    
    local queueSize = math.floor(size * 0.65)
    for i = 2, NUM_QUEUE_ICONS do
        iconFrames[i]:SetSize(queueSize, queueSize)
    end
end

iconSizeSlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value + 0.5)
    self.valueText:SetText(value)
    WarriorRotationDB.iconSize = value
    UpdateIconPosition()
end)

iconXSlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value + 0.5)
    self.valueText:SetText(value)
    WarriorRotationDB.iconX = value
    UpdateIconPosition()
end)

iconYSlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value + 0.5)
    self.valueText:SetText(value)
    WarriorRotationDB.iconY = value
    UpdateIconPosition()
end)

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "WarriorRotation" then
        MergeDefaults(WarriorRotationDB, defaults)
        UpdateIconPosition()
    elseif event == "PLAYER_LOGIN" then
        local _, class = UnitClass("player")
        if class ~= "WARRIOR" then
            print("|cFFFF0000Warrior Rotation:|r This addon is only for Warriors!")
            frame:Hide()
            return
        end
        print("|cFF00FF00Warrior Rotation:|r Loaded! Type /wr or /warriorrotation to open settings.")
        RefreshSettingsUI()
        UpdateIconPosition()
    end
end)

SLASH_WARRIORROTATION1 = "/wr"
SLASH_WARRIORROTATION2 = "/warriorrotation"
SlashCmdList["WARRIORROTATION"] = function(msg)
    msg = msg:lower():trim()
    if msg == "toggle" then
        WarriorRotationDB.enabled = not WarriorRotationDB.enabled
        print("|cFF00FF00Warrior Rotation:|r " .. (WarriorRotationDB.enabled and "Enabled" or "Disabled"))
        enabledCB:SetChecked(WarriorRotationDB.enabled)
    elseif msg == "arms" then
        WarriorRotationDB.spec = "arms"
        addon:UpdateSpecButtons()
        print("|cFF00FF00Warrior Rotation:|r Spec set to Arms")
    elseif msg == "fury" then
        WarriorRotationDB.spec = "fury"
        addon:UpdateSpecButtons()
        print("|cFF00FF00Warrior Rotation:|r Spec set to Fury")
    elseif msg == "prot" then
        WarriorRotationDB.spec = "prot"
        addon:UpdateSpecButtons()
        print("|cFF00FF00Warrior Rotation:|r Spec set to Protection")
    elseif msg == "detect" then
        WarriorRotationDB.spec = GetCurrentSpec()
        addon:UpdateSpecButtons()
        print("|cFF00FF00Warrior Rotation:|r Spec detected: " .. WarriorRotationDB.spec)
    else
        if settingsFrame:IsShown() then
            settingsFrame:Hide()
        else
            RefreshSettingsUI()
            settingsFrame:Show()
        end
    end
end

mainFrame:EnableMouse(true)
mainFrame:SetMovable(true)
mainFrame:RegisterForDrag("LeftButton")
mainFrame:SetScript("OnDragStart", function(self)
    if IsShiftKeyDown() then
        self:StartMoving()
    end
end)
mainFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local _, _, _, x, y = self:GetPoint()
    WarriorRotationDB.iconX = math.floor(x + 0.5)
    WarriorRotationDB.iconY = math.floor(y + 0.5)
    iconXSlider:SetValue(WarriorRotationDB.iconX)
    iconYSlider:SetValue(WarriorRotationDB.iconY)
end)
