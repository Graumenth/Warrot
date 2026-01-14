local addonName, addon = ...
local _sliderCounter = 0

local function CreateHeader(parent, text, x, y)
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", x, y)
    header:SetText(text)
    header:SetTextColor(1, 0.82, 0)
    return header
end

local function CreateLabel(parent, text, x, y)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", x, y)
    label:SetText(text)
    return label
end

local function CreateCheckbox(parent, label, x, y, getFn, setFn)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", x, y)
    cb.text = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cb.text:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    cb.text:SetText(label)
    cb:SetScript("OnClick", function(self)
        setFn(self:GetChecked() and true or false)
    end)
    cb._get = getFn
    cb._set = setFn
    return cb
end

local function CreateSlider(parent, label, minVal, maxVal, step, x, y, width, getFn, setFn)
    _sliderCounter = _sliderCounter + 1
    local name = addonName .. "Slider" .. _sliderCounter
    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", x, y)
    slider:SetWidth(width or 200)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)

    local low = _G[name .. "Low"]
    local high = _G[name .. "High"]
    local text = _G[name .. "Text"]

    if low then low:SetText(minVal) end
    if high then high:SetText(maxVal) end
    if text then text:SetText(label) end

    local value = slider:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    value:SetPoint("TOP", slider, "BOTTOM", 0, -2)
    slider.value = value

    slider:SetScript("OnValueChanged", function(self, val)
        val = math.floor(val / step + 0.5) * step
        self.value:SetText(val)
        if setFn then pcall(setFn, val) end
    end)

    slider._get = getFn
    slider._set = setFn
    return slider
end

local function CreateButton(parent, text, x, y, width, height, onClick)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetPoint("TOPLEFT", x, y)
    btn:SetWidth(width or 100)
    btn:SetHeight(height or 22)
    btn:SetText(text)
    btn:SetScript("OnClick", onClick)
    return btn
end

local function CreateTabButton(parent, text, x, id)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetPoint("TOPLEFT", x, -30)
    btn:SetWidth(80)
    btn:SetHeight(24)
    btn:SetText(text)
    btn._id = id
    return btn
end

function addon:InitOptions()
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00WarriorRotation|r: InitOptions called")
    local frame = CreateFrame("Frame", "WarriorRotationOptions", UIParent, "UIPanelDialogTemplate")
    frame:SetWidth(550)
    frame:SetHeight(550)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    frame:SetFrameStrata("DIALOG")
    frame:Hide()
    
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    frame.title:SetPoint("TOP", 0, -5)
    frame.title:SetText("WarriorRotation Options")
    
    addon.frames.options = frame
    
    local ui = {
        checkboxes = {},
        sliders = {},
        tabs = {},
        pages = {},
        specButtons = {},
    }
    frame.ui = ui
    
    local tabs = { "General", "Display", "Arms", "Fury", "Prot" }
    local tabX = 15
    for i, name in ipairs(tabs) do
        local tab = CreateTabButton(frame, name, tabX, name:lower())
        ui.tabs[name:lower()] = tab
        tabX = tabX + 85
    end
    
    local function CreatePage()
        local page = CreateFrame("Frame", nil, frame)
        page:SetPoint("TOPLEFT", 15, -60)
        page:SetPoint("BOTTOMRIGHT", -15, 15)
        page:Hide()
        return page
    end
    
    for _, name in ipairs(tabs) do
        ui.pages[name:lower()] = CreatePage()
    end
    
    local currentPage = "general"
    
    local function ShowPage(id)
        currentPage = id
        for name, page in pairs(ui.pages) do
            if name == id then
                page:Show()
            else
                page:Hide()
            end
        end
        for name, tab in pairs(ui.tabs) do
            if name == id then
                tab:SetNormalFontObject("GameFontHighlight")
            else
                tab:SetNormalFontObject("GameFontNormal")
            end
        end
    end
    
    for name, tab in pairs(ui.tabs) do
        tab:SetScript("OnClick", function() ShowPage(name) end)
    end
    
    do
        local p = ui.pages.general
        CreateHeader(p, "General Settings", 10, -10)
        
        ui.checkboxes[#ui.checkboxes+1] = CreateCheckbox(p, "Enable Addon", 10, -40,
            function() return addon.db.enabled end,
            function(v) addon.db.enabled = v end
        )
        
        ui.checkboxes[#ui.checkboxes+1] = CreateCheckbox(p, "Lock Icon Position", 10, -65,
            function() return addon.db.locked end,
            function(v) addon.db.locked = v end
        )
        
        ui.checkboxes[#ui.checkboxes+1] = CreateCheckbox(p, "Only Show In Combat", 10, -90,
            function() return addon.db.engine.onlyInCombat end,
            function(v) addon.db.engine.onlyInCombat = v end
        )
        
        CreateHeader(p, "Active Spec", 10, -130)
        
        local specNames = { "Arms", "Fury", "Prot" }
        local specX = 10
        for _, spec in ipairs(specNames) do
            local btn = CreateButton(p, spec, specX, -160, 90, 26, function()
                addon.db.spec = spec:lower()
                addon:RefreshOptionsUI()
            end)
            btn._spec = spec:lower()
            ui.specButtons[#ui.specButtons+1] = btn
            specX = specX + 100
        end
        
        CreateButton(p, "Auto-Detect", specX + 20, -160, 100, 26, function()
            addon:DetectSpec()
            addon.db.spec = addon.playerSpec
            addon:RefreshOptionsUI()
            addon:Print("Spec detected: " .. (addon.playerSpec or "none"):upper())
        end)
        
        CreateHeader(p, "Engine Settings", 10, -210)
        
        ui.sliders[#ui.sliders+1] = CreateSlider(p, "Update Interval (ms)", 20, 200, 10, 10, -250, 220,
            function() return (addon.db.engine.updateInterval or 0.05) * 1000 end,
            function(v) addon.db.engine.updateInterval = v / 1000 end
        )
        
        ui.sliders[#ui.sliders+1] = CreateSlider(p, "Prediction Window (sec)", 0.5, 3, 0.1, 10, -310, 220,
            function() return addon.db.engine.predictionWindow or 1.5 end,
            function(v) addon.db.engine.predictionWindow = v end
        )
        
        CreateHeader(p, "Reset", 10, -370)
        
        CreateButton(p, "Reset Position", 10, -400, 120, 24, function()
            addon.db.display.iconX = 0
            addon.db.display.iconY = -200
            if addon.ApplyIconLayout then addon:ApplyIconLayout() end
            addon:Print("Position reset")
        end)
        
        CreateButton(p, "Reset All Settings", 140, -400, 130, 24, function()
            StaticPopup_Show("WARRIORROTATION_RESET_CONFIRM")
        end)
    end
    
    do
        local p = ui.pages.display
        CreateHeader(p, "Display Settings", 10, -10)
        
        ui.checkboxes[#ui.checkboxes+1] = CreateCheckbox(p, "Show Cooldown Spirals", 10, -40,
            function() return addon.db.display.showCooldowns end,
            function(v) addon.db.display.showCooldowns = v end
        )
        
        ui.checkboxes[#ui.checkboxes+1] = CreateCheckbox(p, "Show Range Indicator", 10, -65,
            function() return addon.db.display.showRange end,
            function(v) addon.db.display.showRange = v end
        )
        
        ui.checkboxes[#ui.checkboxes+1] = CreateCheckbox(p, "Show Keybinds", 10, -90,
            function() return addon.db.display.showKeybinds end,
            function(v) addon.db.display.showKeybinds = v end
        )
        
        ui.checkboxes[#ui.checkboxes+1] = CreateCheckbox(p, "Show Glow Effect", 10, -115,
            function() return addon.db.display.showGlow end,
            function(v) addon.db.display.showGlow = v end
        )
        
        ui.checkboxes[#ui.checkboxes+1] = CreateCheckbox(p, "Fade When Out of Range", 10, -140,
            function() return addon.db.display.fadeOutOfRange end,
            function(v) addon.db.display.fadeOutOfRange = v end
        )
        
        CreateHeader(p, "Size & Position", 10, -180)
        
        ui.sliders[#ui.sliders+1] = CreateSlider(p, "Icon Size", 32, 128, 4, 10, -220, 220,
            function() return addon.db.display.iconSize or 64 end,
            function(v) addon.db.display.iconSize = v; if addon.ApplyIconLayout then addon:ApplyIconLayout() end end
        )
        
        ui.sliders[#ui.sliders+1] = CreateSlider(p, "Icon Spacing", 0, 20, 1, 10, -280, 220,
            function() return addon.db.display.iconSpacing or 8 end,
            function(v) addon.db.display.iconSpacing = v; if addon.ApplyIconLayout then addon:ApplyIconLayout() end end
        )
        
        ui.sliders[#ui.sliders+1] = CreateSlider(p, "Queue Length", 1, 4, 1, 10, -340, 220,
            function() return addon.db.display.queueLength or 4 end,
            function(v) addon.db.display.queueLength = v end
        )
        
        ui.sliders[#ui.sliders+1] = CreateSlider(p, "Position X", -600, 600, 10, 260, -220, 220,
            function() return addon.db.display.iconX or 0 end,
            function(v) addon.db.display.iconX = v; if addon.ApplyIconLayout then addon:ApplyIconLayout() end end
        )
        
        ui.sliders[#ui.sliders+1] = CreateSlider(p, "Position Y", -500, 500, 10, 260, -280, 220,
            function() return addon.db.display.iconY or -200 end,
            function(v) addon.db.display.iconY = v; if addon.ApplyIconLayout then addon:ApplyIconLayout() end end
        )

        ui.checkboxes[#ui.checkboxes+1] = CreateCheckbox(p, "Show Placeholder Icons", 10, -370,
            function() return addon.db.display.showPlaceholders end,
            function(v) addon.db.display.showPlaceholders = v; addon:RefreshUIFromDB() end
        )
        
        ui.sliders[#ui.sliders+1] = CreateSlider(p, "Fade Amount", 0.2, 1, 0.1, 260, -340, 220,
            function() return addon.db.display.fadeAmount or 0.4 end,
            function(v) addon.db.display.fadeAmount = v end
        )
    end
    
    do
        local p = ui.pages.arms
        CreateHeader(p, "Arms Rotation", 10, -10)
        
        ui.checkboxes[#ui.checkboxes+1] = CreateCheckbox(p, "Enable Arms Rotation", 10, -40,
            function() return addon.db.arms.enabled end,
            function(v) addon.db.arms.enabled = v end
        )
        
        CreateHeader(p, "Abilities", 10, -80)
        
        ui.checkboxes[#ui.checkboxes+1] = CreateCheckbox(p, "Use Rend", 10, -110,
            function() return addon.db.arms.useRend end,
            function(v) addon.db.arms.useRend = v end
        )
        
        ui.checkboxes[#ui.checkboxes+1] = CreateCheckbox(p, "Use Overpower", 10, -135,
            function() return addon.db.arms.useOverpower end,
            function(v) addon.db.arms.useOverpower = v end
        )
        
        ui.checkboxes[#ui.checkboxes+1] = CreateCheckbox(p, "Use Mortal Strike", 10, -160,
            function() return addon.db.arms.useMortalStrike end,
            function(v) addon.db.arms.useMortalStrike = v end
        )
        
        ui.checkboxes[#ui.checkboxes+1] = CreateCheckbox(p, "Use Execute", 10, -185,
            function() return addon.db.arms.useExecute end,
            function(v) addon.db.arms.useExecute = v end
        )
        
        ui.checkboxes[#ui.checkboxes+1] = CreateCheckbox(p, "Use Bladestorm", 10, -210,
            function() return addon.db.arms.useBladestorm end,
            function(v) addon.db.arms.useBladestorm = v end
        )
        
        ui.checkboxes[#ui.checkboxes+1] = CreateCheckbox(p, "Use Slam", 10, -235,
            function() return addon.db.arms.useSlam end,
            function(v) addon.db.arms.useSlam = v end
        )
        
        ui.checkboxes[#ui.checkboxes+1] = CreateCheckbox(p, "Use Heroic Strike", 10, -260,
            function() return addon.db.arms.useHeroicStrike end,
            function(v) addon.db.arms.useHeroicStrike = v end
        )
        
        ui.checkboxes[#ui.checkboxes+1] = CreateCheckbox(p, "Pool Rage for MS", 10, -285,
            function() return addon.db.arms.poolRageForMS end,
            function(v) addon.db.arms.poolRageForMS = v end
        )
        
        CreateHeader(p, "Thresholds", 260, -80)
        
        ui.sliders[#ui.sliders+1] = CreateSlider(p, "Execute Phase (%)", 10, 35, 1, 260, -120, 200,
            function() return addon.db.arms.executePhase or 20 end,
            function(v) addon.db.arms.executePhase = v end
        )
        
        ui.sliders[#ui.sliders+1] = CreateSlider(p, "Rend Refresh (sec)", 1, 10, 1, 260, -180, 200,
            function() return addon.db.arms.rendRefresh or 5 end,
            function(v) addon.db.arms.rendRefresh = v end
        )
        
        ui.sliders[#ui.sliders+1] = CreateSlider(p, "HS Rage Threshold", 20, 100, 5, 260, -240, 200,
            function() return addon.db.arms.hsRageThreshold or 60 end,
            function(v) addon.db.arms.hsRageThreshold = v end
        )
        
        ui.sliders[#ui.sliders+1] = CreateSlider(p, "HS Execute Threshold", 15, 60, 5, 260, -300, 200,
            function() return addon.db.arms.hsExecuteThreshold or 30 end,
            function(v) addon.db.arms.hsExecuteThreshold = v end
        )
        
        ui.sliders[#ui.sliders+1] = CreateSlider(p, "Pool Amount", 20, 50, 5, 260, -360, 200,
            function() return addon.db.arms.poolAmount or 30 end,
            function(v) addon.db.arms.poolAmount = v end
        )
    end
    
    do
        local p = ui.pages.fury
        CreateHeader(p, "Fury Rotation", 10, -10)
        
        ui.checkboxes[#ui.checkboxes+1] = CreateCheckbox(p, "Enable Fury Rotation", 10, -40,
            function() return addon.db.fury.enabled end,
            function(v) addon.db.fury.enabled = v end
        )
        
        CreateHeader(p, "Abilities", 10, -80)
        
        ui.checkboxes[#ui.checkboxes+1] = CreateCheckbox(p, "Use Bloodthirst", 10, -110,
            function() return addon.db.fury.useBloodthirst end,
            function(v) addon.db.fury.useBloodthirst = v end
        )
        
        ui.checkboxes[#ui.checkboxes+1] = CreateCheckbox(p, "Use Whirlwind", 10, -135,
            function() return addon.db.fury.useWhirlwind end,
            function(v) addon.db.fury.useWhirlwind = v end
        )
        
        ui.checkboxes[#ui.checkboxes+1] = CreateCheckbox(p, "Use Execute", 10, -160,
            function() return addon.db.fury.useExecute end,
            function(v) addon.db.fury.useExecute = v end
        )
        
        ui.checkboxes[#ui.checkboxes+1] = CreateCheckbox(p, "Use Slam (Bloodsurge)", 10, -185,
            function() return addon.db.fury.useSlam end,
            function(v) addon.db.fury.useSlam = v end
        )
        
        ui.checkboxes[#ui.checkboxes+1] = CreateCheckbox(p, "Use Heroic Strike", 10, -210,
            function() return addon.db.fury.useHeroicStrike end,
            function(v) addon.db.fury.useHeroicStrike = v end
        )
        
        CreateHeader(p, "Cooldowns", 10, -250)
        
        ui.checkboxes[#ui.checkboxes+1] = CreateCheckbox(p, "Use Death Wish", 10, -280,
            function() return addon.db.fury.useDeathWish end,
            function(v) addon.db.fury.useDeathWish = v end
        )
        
        ui.checkboxes[#ui.checkboxes+1] = CreateCheckbox(p, "Use Recklessness", 10, -305,
            function() return addon.db.fury.useRecklessness end,
            function(v) addon.db.fury.useRecklessness = v end
        )
        
        ui.checkboxes[#ui.checkboxes+1] = CreateCheckbox(p, "Use Berserker Rage", 10, -330,
            function() return addon.db.fury.useBerserkerRage end,
            function(v) addon.db.fury.useBerserkerRage = v end
        )
        
        CreateHeader(p, "Thresholds", 260, -80)
        
        ui.sliders[#ui.sliders+1] = CreateSlider(p, "Execute Phase (%)", 10, 35, 1, 260, -120, 200,
            function() return addon.db.fury.executePhase or 20 end,
            function(v) addon.db.fury.executePhase = v end
        )
        
        ui.sliders[#ui.sliders+1] = CreateSlider(p, "HS Rage Threshold", 20, 100, 5, 260, -180, 200,
            function() return addon.db.fury.hsRageThreshold or 50 end,
            function(v) addon.db.fury.hsRageThreshold = v end
        )
    end
    
    do
        local p = ui.pages.prot
        CreateHeader(p, "Protection Rotation", 10, -10)
        
        ui.checkboxes[#ui.checkboxes+1] = CreateCheckbox(p, "Enable Protection Rotation", 10, -40,
            function() return addon.db.prot.enabled end,
            function(v) addon.db.prot.enabled = v end
        )
        
        CreateHeader(p, "Abilities", 10, -80)
        
        ui.checkboxes[#ui.checkboxes+1] = CreateCheckbox(p, "Use Shield Slam", 10, -110,
            function() return addon.db.prot.useShieldSlam end,
            function(v) addon.db.prot.useShieldSlam = v end
        )
        
        ui.checkboxes[#ui.checkboxes+1] = CreateCheckbox(p, "Use Revenge", 10, -135,
            function() return addon.db.prot.useRevenge end,
            function(v) addon.db.prot.useRevenge = v end
        )
        
        ui.checkboxes[#ui.checkboxes+1] = CreateCheckbox(p, "Use Devastate", 10, -160,
            function() return addon.db.prot.useDevastate end,
            function(v) addon.db.prot.useDevastate = v end
        )
        
        ui.checkboxes[#ui.checkboxes+1] = CreateCheckbox(p, "Use Shockwave", 10, -185,
            function() return addon.db.prot.useShockwave end,
            function(v) addon.db.prot.useShockwave = v end
        )
        
        ui.checkboxes[#ui.checkboxes+1] = CreateCheckbox(p, "Use Concussion Blow", 10, -210,
            function() return addon.db.prot.useConcussionBlow end,
            function(v) addon.db.prot.useConcussionBlow = v end
        )
        
        ui.checkboxes[#ui.checkboxes+1] = CreateCheckbox(p, "Use Heroic Strike", 10, -235,
            function() return addon.db.prot.useHeroicStrike end,
            function(v) addon.db.prot.useHeroicStrike = v end
        )
        
        ui.checkboxes[#ui.checkboxes+1] = CreateCheckbox(p, "Use Heroic Throw", 10, -260,
            function() return addon.db.prot.useHeroicThrow end,
            function(v) addon.db.prot.useHeroicThrow = v end
        )
        
        CreateHeader(p, "Debuffs", 260, -80)
        
        ui.checkboxes[#ui.checkboxes+1] = CreateCheckbox(p, "Maintain Debuffs", 260, -110,
            function() return addon.db.prot.maintainDebuffs end,
            function(v) addon.db.prot.maintainDebuffs = v end
        )
        
        ui.checkboxes[#ui.checkboxes+1] = CreateCheckbox(p, "Use Thunder Clap", 260, -135,
            function() return addon.db.prot.useThunderClap end,
            function(v) addon.db.prot.useThunderClap = v end
        )
        
        ui.checkboxes[#ui.checkboxes+1] = CreateCheckbox(p, "Use Demoralizing Shout", 260, -160,
            function() return addon.db.prot.useDemoralizingShout end,
            function(v) addon.db.prot.useDemoralizingShout = v end
        )
        
        CreateHeader(p, "Thresholds", 260, -200)
        
        ui.sliders[#ui.sliders+1] = CreateSlider(p, "HS Rage Threshold", 20, 100, 5, 260, -240, 200,
            function() return addon.db.prot.hsRageThreshold or 50 end,
            function(v) addon.db.prot.hsRageThreshold = v end
        )
    end
    
    StaticPopupDialogs["WARRIORROTATION_RESET_CONFIRM"] = {
        text = "Are you sure you want to reset all WarriorRotation settings?",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
            addon:ResetDB()
            addon:Print("All settings reset to defaults")
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }
    
    ShowPage("general")
end

function addon:RefreshOptionsUI()
    local frame = addon.frames.options
    if not frame or not frame.ui then return end
    
    local ui = frame.ui
    
    for _, cb in ipairs(ui.checkboxes) do
        if cb._get then
            cb:SetChecked(cb._get())
        end
    end
    
    for _, slider in ipairs(ui.sliders) do
        if slider._get then
            local val = slider._get()
            slider:SetValue(val)
            slider.value:SetText(val)
        end
    end
    
    for _, btn in ipairs(ui.specButtons) do
        if btn._spec == addon.db.spec then
            btn:SetNormalFontObject("GameFontHighlight")
        else
            btn:SetNormalFontObject("GameFontNormal")
        end
    end
end

function addon:ShowOptions()
    if not addon.frames.options and addon.InitOptions then
        addon:InitOptions()
    end
    local frame = addon.frames.options
    if not frame then return end
    addon:RefreshOptionsUI()
    frame:Show()
end

function addon:HideOptions()
    local frame = addon.frames.options
    if not frame then return end
    frame:Hide()
end