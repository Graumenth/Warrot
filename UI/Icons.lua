local addonName, addon = ...

local MAX_ICONS = 4
local GetTime = GetTime

local main = CreateFrame("Frame", "WarriorRotationFrame", UIParent)
addon.frames = addon.frames or {}
addon.frames.main = main
addon.frames.icons = addon.frames.icons or {}

main:SetPoint("CENTER", 0, -200)
main:SetWidth(200)
main:SetHeight(60)
main:SetMovable(true)
main:EnableMouse(true)
main:RegisterForDrag("LeftButton")
main:SetClampedToScreen(true)

main:SetScript("OnDragStart", function(self)
    if addon.db and addon.db.locked then return end
    if IsShiftKeyDown() then
        self:StartMoving()
    end
end)
main:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    if not addon.db then return end
    local _, _, _, x, y = self:GetPoint()
    addon.db.display.iconX = math.floor((x or 0) + 0.5)
    addon.db.display.iconY = math.floor((y or -200) + 0.5)
    if addon.ApplyIconLayout then addon:ApplyIconLayout() end
    if addon.RefreshOptionsUI then addon:RefreshOptionsUI() end
end)

local function CreateIcon(i)
    local f = CreateFrame("Frame", nil, main)
    f:SetWidth(64)
    f:SetHeight(64)

    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(f)
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetVertexColor(0, 0, 0, 0.5)
    f.bg = bg

    local tex = f:CreateTexture(nil, "ARTWORK")
    tex:SetPoint("TOPLEFT", f, "TOPLEFT", 2, -2)
    tex:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -2, 2)
    tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    f.tex = tex

    local cd = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
    cd:SetAllPoints(tex)
    f.cd = cd

    local keybind = f:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmallGray")
    keybind:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -2)
    f.keybind = keybind

    local border = f:CreateTexture(nil, "OVERLAY")
    border:SetAllPoints(f)
    border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    border:SetBlendMode("ADD")
    border:SetAlpha(0)
    f.border = border

    f:Hide()
    return f
end
function addon:ApplyIconLayout()
    if not addon.db then return end
    -- Defensive: ensure frames/icons table exists (other files may load in any order)
    addon.frames = addon.frames or {}
    addon.frames.icons = addon.frames.icons or {}
    local main = addon.frames.main
    if not main then return end

    local d = addon.db.display

    local size = d.iconSize or 64
    local spacing = d.iconSpacing or 8
    local count = d.queueLength or 4

    main:ClearAllPoints()
    main:SetPoint("CENTER", UIParent, "CENTER", d.iconX or 0, d.iconY or -200)

    main:SetWidth((size * count) + (spacing * (count - 1)))
    main:SetHeight(size)

    for i = 1, count do
        if not addon.frames.icons[i] then
            addon.frames.icons[i] = CreateIcon(i)
        end

        local f = addon.frames.icons[i]
        f:SetWidth(size)
        f:SetHeight(size)
        f:ClearAllPoints()
        f:SetPoint("LEFT", main, "LEFT", (i - 1) * (size + spacing), 0)
    end

    for i = count + 1, #addon.frames.icons do
        if addon.frames.icons[i] then addon.frames.icons[i]:Hide() end
    end
end

function addon:UpdateIcons(queue)
    if not addon.db then return end
    local d = addon.db.display
    local icons = addon.frames.icons
    local count = d.queueLength or 4

    for i = 1, count do
        local f = icons[i]
        if not f then break end

        local spellID = queue and queue[i] or nil
        if not spellID then
            if d.showPlaceholders then
                f.tex:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                f.tex:SetVertexColor(0.5, 0.5, 0.5)
                f.keybind:SetText("")
                CooldownFrame_SetTimer(f.cd, 0, 0, 0)
                f.cd:Hide()
                f.border:SetAlpha(0)
                f:Show()
            else
                f:Hide()
            end
        else
            local _, _, icon = GetSpellInfo(spellID)
            f.tex:SetTexture(icon)

            if d.showKeybinds then
                f.keybind:SetText(addon:GetKeybind(spellID))
            else
                f.keybind:SetText("")
            end

            if d.showCooldowns then
                local name = addon:SpellName(spellID)
                local start, duration, enabled = GetSpellCooldown(name)
                if enabled == 1 and start > 0 and duration > 0 then
                    f.cd:Show()
                    CooldownFrame_SetTimer(f.cd, start, duration, 1)
                else
                    CooldownFrame_SetTimer(f.cd, 0, 0, 0)
                    f.cd:Hide()
                end
            else
                CooldownFrame_SetTimer(f.cd, 0, 0, 0)
                f.cd:Hide()
            end

            if d.showRange and i == 1 then
                local inRange = addon:IsInRange(spellID)
                if not inRange and d.fadeOutOfRange then
                    local a = d.fadeAmount or 0.4
                    f.tex:SetVertexColor(1, 1, 1, a)
                else
                    f.tex:SetVertexColor(1, 1, 1, 1)
                end
            else
                f.tex:SetVertexColor(1, 1, 1, 1)
            end

            if d.showGlow and i == 1 then
                f.border:SetAlpha(1)
            else
                f.border:SetAlpha(0)
            end

            f:Show()
        end
    end
end

function addon:InitIcons()
    addon:ApplyIconLayout()

    local last = 0
    main:SetScript("OnUpdate", function(self, elapsed)
        if not addon.db then return end
        if addon.engine and addon.engine.pausedUntil and GetTime() < addon.engine.pausedUntil then return end
        last = last + elapsed
        local interval = addon.db.engine.updateInterval or 0.05
        if last < interval then return end
        last = 0
        addon:UpdateIcons(addon:BuildQueue())
    end)
end

-- Icons module loaded