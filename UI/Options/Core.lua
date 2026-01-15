local addonName, addon = ...

addon.ui = addon.ui or {}
addon.ui.options = {}

local Options = addon.ui.options
Options.checkboxes = {}
Options.sliders = {}
Options.tabs = {}
Options.pages = {}

local _sliderCounter = 0

function Options:CreateHeader(parent, text, x, y)
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", x, y)
    header:SetText(text)
    header:SetTextColor(1, 0.82, 0)
    return header
end

function Options:CreateCheckbox(parent, label, x, y, getFn, setFn)
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
    self.checkboxes[#self.checkboxes + 1] = cb
    return cb
end

function Options:CreateSlider(parent, label, minVal, maxVal, step, x, y, width, getFn, setFn)
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
    self.sliders[#self.sliders + 1] = slider
    return slider
end

function Options:CreateButton(parent, text, x, y, width, height, onClick)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetPoint("TOPLEFT", x, y)
    btn:SetWidth(width or 100)
    btn:SetHeight(height or 22)
    btn:SetText(text)
    btn:SetScript("OnClick", onClick)
    return btn
end

function Options:ShowPage(id)
    for name, page in pairs(self.pages) do
        if name == id then
            page:Show()
        else
            page:Hide()
        end
    end
    for name, tab in pairs(self.tabs) do
        if name == id then
            tab:SetNormalFontObject("GameFontHighlight")
        else
            tab:SetNormalFontObject("GameFontNormal")
        end
    end
end

function Options:Refresh()
    for _, cb in ipairs(self.checkboxes) do
        if cb._get then
            cb:SetChecked(cb._get())
        end
    end
    for _, slider in ipairs(self.sliders) do
        if slider._get then
            local val = slider._get()
            slider:SetValue(val)
            slider.value:SetText(val)
        end
    end
end

function addon:InitOptions()
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00WarriorRotation|r: InitOptions called")
    
    local frame = CreateFrame("Frame", "WarriorRotationOptions", UIParent)
    frame:SetWidth(550)
    frame:SetHeight(550)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    frame:SetFrameStrata("DIALOG")
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    frame:Hide()
    
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    frame.title:SetPoint("TOP", frame, "TOP", 0, -15)
    frame.title:SetText("WarriorRotation Options")
    
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    
    addon.frames.options = frame
    Options.frame = frame
    
    local tabContainer = CreateFrame("Frame", nil, frame)
    tabContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -40)
    tabContainer:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -15, -40)
    tabContainer:SetHeight(30)
    
    local tabNames = { "General", "Display", "Arms", "Fury", "Prot", "Known" }
    local tabX = 0
    for _, name in ipairs(tabNames) do
        local tab = CreateFrame("Button", nil, tabContainer, "UIPanelButtonTemplate")
        tab:SetPoint("LEFT", tabContainer, "LEFT", tabX, 0)
        tab:SetWidth(80)
        tab:SetHeight(24)
        tab:SetText(name)
        local id = name:lower()
        tab:SetScript("OnClick", function() Options:ShowPage(id) end)
        Options.tabs[id] = tab
        tabX = tabX + 85
    end
    
    local contentArea = CreateFrame("Frame", nil, frame)
    contentArea:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -75)
    contentArea:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -15, 15)
    Options.contentArea = contentArea
    
    for _, name in ipairs(tabNames) do
        local page = CreateFrame("Frame", nil, contentArea)
        page:SetAllPoints(contentArea)
        page:Hide()
        Options.pages[name:lower()] = page
    end
    
    if addon.InitOptionsGeneral then addon:InitOptionsGeneral() end
    if addon.InitOptionsDisplay then addon:InitOptionsDisplay() end
    if addon.InitOptionsArms then addon:InitOptionsArms() end
    if addon.InitOptionsFury then addon:InitOptionsFury() end
    if addon.InitOptionsProt then addon:InitOptionsProt() end
    if addon.InitOptionsKnown then addon:InitOptionsKnown() end
    
    StaticPopupDialogs["WARRIORROTATION_RESET_CONFIRM"] = {
        text = "Reset all WarriorRotation settings?",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
            addon:ResetDB()
            addon:Print("Settings reset")
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }
    
    Options:ShowPage("general")
end

function addon:ShowOptions()
    if not addon.frames.options then
        addon:InitOptions()
    end
    Options:Refresh()
    if addon.UpdateKnownSpellsUI then addon:UpdateKnownSpellsUI() end
    addon.frames.options:Show()
end

function addon:HideOptions()
    if addon.frames.options then
        addon.frames.options:Hide()
    end
end

function addon:RefreshOptionsUI()
    Options:Refresh()
end