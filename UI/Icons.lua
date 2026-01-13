local addonName, addon = ...

local NUM = 4

local function CreateIconFrame(parent, size, primary)
    local f = CreateFrame("Frame", nil, parent)
    f:SetWidth(size)
    f:SetHeight(size)

    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", -2, 2)
    bg:SetPoint("BOTTOMRIGHT", 2, -2)
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetVertexColor(0, 0, 0, 0.8)
    f.bg = bg

    local border = f:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT", -3, 3)
    border:SetPoint("BOTTOMRIGHT", 3, -3)
    border:SetTexture("Interface\\Buttons\\WHITE8X8")
    if primary then
        border:SetVertexColor(1, 0.82, 0, 1)
    else
        border:SetVertexColor(0.3, 0.3, 0.3, 1)
    end
    f.border = border

    local icon = f:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    f.icon = icon

    local cd = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
    cd:SetAllPoints()
    f.cooldown = cd

    local rangeOverlay = f:CreateTexture(nil, "OVERLAY")
    rangeOverlay:SetAllPoints()
    rangeOverlay:SetTexture("Interface\\Buttons\\WHITE8X8")
    rangeOverlay:SetVertexColor(1, 0, 0, 0.4)
    rangeOverlay:Hide()
    f.rangeOverlay = rangeOverlay

    local keybind = f:CreateFontString(nil, "OVERLAY")
    keybind:SetFont("Fonts\\FRIZQT__.TTF", primary and 14 or 10, "OUTLINE")
    keybind:SetPoint("TOPLEFT", 2, -2)
    keybind:SetTextColor(1, 1, 1, 1)
    f.keybind = keybind

    if primary then
        local glow = f:CreateTexture(nil, "OVERLAY")
        glow:SetPoint("TOPLEFT", -8, 8)
        glow:SetPoint("BOTTOMRIGHT", 8, -8)
        glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        glow:SetVertexColor(1, 0.82, 0, 0.5)
        glow:SetBlendMode("ADD")
        f.glow = glow
    end

    f:Hide()
    return f
end

function addon:InitIcons()
    local main = CreateFrame("Frame", "WarriorRotationMain", UIParent)
    main:SetWidth(300)
    main:SetHeight(80)
    main:SetPoint("CENTER", 0, -200)
    addon.frames.main = main

    local icons = {}
    addon.frames.icons = icons

    icons[1] = CreateIconFrame(main, 64, true)
    icons[1]:SetPoint("LEFT", main, "LEFT", 0, 0)

    for i = 2, NUM do
        icons[i] = CreateIconFrame(main, 40, false)
        icons[i]:SetPoint("LEFT", icons[i - 1], "RIGHT", 8, 0)
    end

    local lastUpdate = 0

    main:SetScript("OnUpdate", function(self, elapsed)
        lastUpdate = lastUpdate + elapsed
        local interval = addon.db.updateInterval or 0.10
        if lastUpdate < interval then return end
        lastUpdate = 0

        local queue = addon:NextQueue()
        if not queue or #queue == 0 then
            for i = 1, NUM do
                icons[i].cooldown:Hide()
                icons[i]:Hide()
            end
            return
        end

        for i = 1, NUM do
            local f = icons[i]
            local spellID = queue[i]
            if not spellID or i > addon.db.queueLength then
                f.cooldown:Hide()
                f:Hide()
            else
                local name, _, tex = GetSpellInfo(spellID)
                if not tex then
                    f.cooldown:Hide()
                    f:Hide()
                else
                    f.icon:SetTexture(tex)

                    if addon.db.showKeybinds then
                        f.keybind:SetText(addon:GetKeybind(spellID))
                    else
                        f.keybind:SetText("")
                    end

                    if addon.db.showCooldowns then
                        local start, duration = GetSpellCooldown(name)
                        if start and duration and duration > 0 then
                            CooldownFrame_SetTimer(f.cooldown, start, duration, 1)
                            f.cooldown:Show()
                        else
                            CooldownFrame_SetTimer(f.cooldown, 0, 0, 0)
                            f.cooldown:Hide()
                        end
                    else
                        CooldownFrame_SetTimer(f.cooldown, 0, 0, 0)
                        f.cooldown:Hide()
                    end

                    if addon.db.showRange and i == 1 then
                        if addon:IsInMeleeRange() then
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
            end
        end
    end)

    main:EnableMouse(true)
    main:SetMovable(true)
    main:RegisterForDrag("LeftButton")
    main:SetScript("OnDragStart", function(self)
        if IsShiftKeyDown() then
            self:StartMoving()
        end
    end)
    main:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local _, _, _, x, y = self:GetPoint()
        addon.db.iconX = math.floor(x + 0.5)
        addon.db.iconY = math.floor(y + 0.5)
        addon:ApplyIconLayout()
        if addon.RefreshOptionsUI then addon:RefreshOptionsUI() end
    end)
end

function addon:ApplyIconLayout()
    local main = addon.frames.main
    if not main then return end

    main:ClearAllPoints()
    main:SetPoint("CENTER", UIParent, "CENTER", addon.db.iconX or 0, addon.db.iconY or -200)

    local size = addon.db.iconSize or 64
    local icons = addon.frames.icons
    if not icons then return end

    local qSize = math.floor(size * 0.65)

    icons[1]:ClearAllPoints()
    icons[1]:SetWidth(size)
    icons[1]:SetHeight(size)
    icons[1]:SetPoint("LEFT", main, "LEFT", 0, 0)

    for i = 2, NUM do
        icons[i]:ClearAllPoints()
        icons[i]:SetWidth(qSize)
        icons[i]:SetHeight(qSize)
        icons[i]:SetPoint("LEFT", icons[i - 1], "RIGHT", 8, 0)
    end
end