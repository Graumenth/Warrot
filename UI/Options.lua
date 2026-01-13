local addonName, addon = ...

local function CreateHeader(parent, text, x, y)
    local t = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    t:SetPoint("TOPLEFT", x, y)
    t:SetText(text)
    t:SetTextColor(1, 0.82, 0)
    return t
end

local function CreateCheckbox(parent, label, getFn, setFn, x, y)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", x, y)
    cb.text = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cb.text:SetPoint("LEFT", cb, "RIGHT", 5, 0)
    cb.text:SetText(label)
    cb:SetScript("OnClick", function(self) setFn(self:GetChecked() and true or false) end)
    cb._get = getFn
    return cb
end

local function CreateSlider(parent, label, minVal, maxVal, step, getFn, setFn, x, y, w)
    local s = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    s:SetPoint("TOPLEFT", x, y)
    s:SetWidth(w or 220)
    s:SetMinMaxValues(minVal, maxVal)
    s:SetValueStep(step)
    s:SetObeyStepOnDrag(true)
    s.Low:SetText(minVal)
    s.High:SetText(maxVal)
    s.Text:SetText(label)

    local vt = s:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    vt:SetPoint("TOP", s, "BOTTOM", 0, 0)
    s.valueText = vt

    s:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        self.valueText:SetText(value)
        setFn(value)
    end)

    s._get = getFn
    return s
end

local function CreateTabButton(parent, text, x)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetWidth(90)
    b:SetHeight(22)
    b:SetText(text)
    b:SetPoint("TOPLEFT", x, -28)
    return b
end

function addon:InitOptions()
    local f = CreateFrame("Frame", "WarriorRotationOptions", UIParent, "BasicFrameTemplateWithInset")
    f:SetWidth(520)
    f:SetHeight(520)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    f:Hide()

    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.title:SetPoint("TOP", 0, -6)
    f.title:SetText("WarriorRotation Options")

    addon.frames.options = f

    local tabs = {}
    f.tabs = tabs

    local pages = {}
    f.pages = pages

    local function ShowPage(key)
        for k, p in pairs(pages) do
            if k == key then p:Show() else p:Hide() end
        end
    end

    local function CreatePage()
        local p = CreateFrame("Frame", nil, f)
        p:SetPoint("TOPLEFT", 10, -60)
        p:SetPoint("BOTTOMRIGHT", -10, 10)
        return p
    end

    tabs.general = CreateTabButton(f, "General", 12)
    tabs.display = CreateTabButton(f, "Display", 110)
    tabs.arms = CreateTabButton(f, "Arms", 208)
    tabs.fury = CreateTabButton(f, "Fury", 306)
    tabs.prot = CreateTabButton(f, "Prot", 404)

    pages.general = CreatePage()
    pages.display = CreatePage()
    pages.arms = CreatePage()
    pages.fury = CreatePage()
    pages.prot = CreatePage()

    tabs.general:SetScript("OnClick", function() ShowPage("general") end)
    tabs.display:SetScript("OnClick", function() ShowPage("display") end)
    tabs.arms:SetScript("OnClick", function() ShowPage("arms") end)
    tabs.fury:SetScript("OnClick", function() ShowPage("fury") end)
    tabs.prot:SetScript("OnClick", function() ShowPage("prot") end)

    local ui = { checkboxes = {}, sliders = {}, specButtons = {} }
    f.ui = ui

    do
        local p = pages.general
        CreateHeader(p, "General", 10, -10)

        ui.checkboxes[#ui.checkboxes + 1] = CreateCheckbox(p, "Enable Addon", function() return addon.db.enabled end, function(v) addon.db.enabled = v end, 10, -40)
        ui.checkboxes[#ui.checkboxes + 1] = CreateCheckbox(p, "Only In Combat", function() return addon.db.onlyInCombat end, function(v) addon.db.onlyInCombat = v end, 10, -65)

        local y = -110
        CreateHeader(p, "Active Spec", 10, y)
        y = y - 30

        local function SpecBtn(spec, xPos)
            local b = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
            b:SetWidth(110)
            b:SetHeight(24)
            b:SetPoint("TOPLEFT", xPos, y)
            b:SetText(spec:upper())
            b:SetScript("OnClick", function()
                addon.db.spec = spec
                addon:RefreshOptionsUI()
            end)
            ui.specButtons[#ui.specButtons + 1] = b
            b._spec = spec
        end

        SpecBtn("arms", 10)
        SpecBtn("fury", 130)
        SpecBtn("prot", 250)

        y = y - 60
        ui.sliders[#ui.sliders + 1] = CreateSlider(p, "Update Interval (ms)", 50, 300, 10,
            function() return math.floor((addon.db.updateInterval or 0.10) * 1000 + 0.5) end,
            function(v) addon.db.updateInterval = v / 1000 end,
            10, y, 260
        )
    end

    do
        local p = pages.display
        CreateHeader(p, "Display", 10, -10)

        ui.checkboxes[#ui.checkboxes + 1] = CreateCheckbox(p, "Show Cooldowns", function() return addon.db.showCooldowns end, function(v) addon.db.showCooldowns = v end, 10, -40)
        ui.checkboxes[#ui.checkboxes + 1] = CreateCheckbox(p, "Show Range Indicator", function() return addon.db.showRange end, function(v) addon.db.showRange = v end, 10, -65)
        ui.checkboxes[#ui.checkboxes + 1] = CreateCheckbox(p, "Show Keybinds", function() return addon.db.showKeybinds end, function(v) addon.db.showKeybinds = v end, 10, -90)

        ui.sliders[#ui.sliders + 1] = CreateSlider(p, "Icon Size", 32, 128, 8, function() return addon.db.iconSize end, function(v) addon.db.iconSize = v; addon:ApplyIconLayout() end, 10, -140, 260)
        ui.sliders[#ui.sliders + 1] = CreateSlider(p, "Queue Length", 1, 4, 1, function() return addon.db.queueLength end, function(v) addon.db.queueLength = v end, 10, -200, 260)
        ui.sliders[#ui.sliders + 1] = CreateSlider(p, "Icon X", -500, 500, 10, function() return addon.db.iconX end, function(v) addon.db.iconX = v; addon:ApplyIconLayout() end, 10, -260, 260)
        ui.sliders[#ui.sliders + 1] = CreateSlider(p, "Icon Y", -500, 500, 10, function() return addon.db.iconY end, function(v) addon.db.iconY = v; addon:ApplyIconLayout() end, 10, -320, 260)
    end

    do
        local p = pages.arms
        CreateHeader(p, "Arms", 10, -10)
        ui.checkboxes[#ui.checkboxes + 1] = CreateCheckbox(p, "Use Rend", function() return addon.db.arms.useRend end, function(v) addon.db.arms.useRend = v end, 10, -40)
        ui.checkboxes[#ui.checkboxes + 1] = CreateCheckbox(p, "Use Overpower", function() return addon.db.arms.useOverpower end, function(v) addon.db.arms.useOverpower = v end, 10, -65)
        ui.checkboxes[#ui.checkboxes + 1] = CreateCheckbox(p, "Use Mortal Strike", function() return addon.db.arms.useMortalStrike end, function(v) addon.db.arms.useMortalStrike = v end, 10, -90)
        ui.checkboxes[#ui.checkboxes + 1] = CreateCheckbox(p, "Use Execute", function() return addon.db.arms.useExecute end, function(v) addon.db.arms.useExecute = v end, 10, -115)
        ui.checkboxes[#ui.checkboxes + 1] = CreateCheckbox(p, "Use Bladestorm", function() return addon.db.arms.useBladestorm end, function(v) addon.db.arms.useBladestorm = v end, 10, -140)

        ui.sliders[#ui.sliders + 1] = CreateSlider(p, "Rend Refresh (sec)", 1, 10, 1, function() return addon.db.arms.rendRefresh end, function(v) addon.db.arms.rendRefresh = v end, 10, -190, 260)
        ui.sliders[#ui.sliders + 1] = CreateSlider(p, "HS Rage Threshold", 20, 100, 5, function() return addon.db.arms.hsRageThreshold end, function(v) addon.db.arms.hsRageThreshold = v end, 10, -250, 260)
    end

    do
        local p = pages.fury
        CreateHeader(p, "Fury", 10, -10)
        ui.checkboxes[#ui.checkboxes + 1] = CreateCheckbox(p, "Use Bloodthirst", function() return addon.db.fury.useBloodthirst end, function(v) addon.db.fury.useBloodthirst = v end, 10, -40)
        ui.checkboxes[#ui.checkboxes + 1] = CreateCheckbox(p, "Use Whirlwind", function() return addon.db.fury.useWhirlwind end, function(v) addon.db.fury.useWhirlwind = v end, 10, -65)
        ui.checkboxes[#ui.checkboxes + 1] = CreateCheckbox(p, "Use Execute", function() return addon.db.fury.useExecute end, function(v) addon.db.fury.useExecute = v end, 10, -90)
        ui.checkboxes[#ui.checkboxes + 1] = CreateCheckbox(p, "Use Death Wish", function() return addon.db.fury.useDeathWish end, function(v) addon.db.fury.useDeathWish = v end, 10, -115)
        ui.checkboxes[#ui.checkboxes + 1] = CreateCheckbox(p, "Use Recklessness", function() return addon.db.fury.useRecklessness end, function(v) addon.db.fury.useRecklessness = v end, 10, -140)

        ui.sliders[#ui.sliders + 1] = CreateSlider(p, "HS Rage Threshold", 20, 100, 5, function() return addon.db.fury.hsRageThreshold end, function(v) addon.db.fury.hsRageThreshold = v end, 10, -190, 260)
    end

    do
        local p = pages.prot
        CreateHeader(p, "Protection", 10, -10)
        ui.checkboxes[#ui.checkboxes + 1] = CreateCheckbox(p, "Use Shield Slam", function() return addon.db.prot.useShieldSlam end, function(v) addon.db.prot.useShieldSlam = v end, 10, -40)
        ui.checkboxes[#ui.checkboxes + 1] = CreateCheckbox(p, "Use Revenge", function() return addon.db.prot.useRevenge end, function(v) addon.db.prot.useRevenge = v end, 10, -65)
        ui.checkboxes[#ui.checkboxes + 1] = CreateCheckbox(p, "Use Devastate", function() return addon.db.prot.useDevastate end, function(v) addon.db.prot.useDevastate = v end, 10, -90)
        ui.checkboxes[#ui.checkboxes + 1] = CreateCheckbox(p, "Use Shockwave", function() return addon.db.prot.useShockwave end, function(v) addon.db.prot.useShockwave = v end, 10, -115)
        ui.checkboxes[#ui.checkboxes + 1] = CreateCheckbox(p, "Use Concussion Blow", function() return addon.db.prot.useConcussionBlow end, function(v) addon.db.prot.useConcussionBlow = v end, 10, -140)

        ui.sliders[#ui.sliders + 1] = CreateSlider(p, "HS Rage Threshold", 20, 100, 5, function() return addon.db.prot.hsRageThreshold end, function(v) addon.db.prot.hsRageThreshold = v end, 10, -190, 260)
    end

    function addon:RefreshOptionsUI()
        for _, cb in ipairs(ui.checkboxes) do
            cb:SetChecked(cb._get() and true or false)
        end
        for _, s in ipairs(ui.sliders) do
            local v = s._get()
            s:SetValue(v)
            s.valueText:SetText(v)
        end
        for _, b in ipairs(ui.specButtons) do
            if b._spec == addon.db.spec then
                b:SetNormalFontObject("GameFontHighlight")
            else
                b:SetNormalFontObject("GameFontNormal")
            end
        end
    end

    ShowPage("general")
end

function addon:ShowOptions()
    local f = addon.frames.options
    if not f then return end
    addon:RefreshOptionsUI()
    f:Show()
end

function addon:HideOptions()
    local f = addon.frames.options
    if not f then return end
    f:Hide()
end