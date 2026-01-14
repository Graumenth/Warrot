local addonName, addon = ...

local MAX_ICONS = 4
local GetTime = GetTime

local function CreateIconFrame(parent, index, primary)
    local size = primary and 64 or 42
    
    local f = CreateFrame("Frame", "WarriorRotationIcon" .. index, parent)
    f:SetWidth(size)
    f:SetHeight(size)
    f:SetFrameStrata("MEDIUM")
    f:SetFrameLevel(10)
    
    local shadow = f:CreateTexture(nil, "BACKGROUND", nil, -2)
    shadow:SetPoint("TOPLEFT", -4, 4)
    shadow:SetPoint("BOTTOMRIGHT", 4, -4)
    shadow:SetTexture("Interface\\Buttons\\WHITE8X8")
    shadow:SetVertexColor(0, 0, 0, 0.6)
    f.shadow = shadow
    
    local border = f:CreateTexture(nil, "BACKGROUND", nil, -1)
    border:SetPoint("TOPLEFT", -2, 2)
    border:SetPoint("BOTTOMRIGHT", 2, -2)
    if primary then
        border:SetTexture("Interface\\Buttons\\WHITE8X8")
        border:SetVertexColor(1, 0.82, 0, 1)
    else
        border:SetTexture("Interface\\Buttons\\WHITE8X8")
        border:SetVertexColor(0.4, 0.4, 0.4, 1)
    end
    f.border = border
    
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetVertexColor(0, 0, 0, 0.8)
    f.bg = bg
    
    local icon = f:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    f.icon = icon
    
    local cooldown = CreateFrame("Cooldown", f:GetName() .. "Cooldown", f, "CooldownFrameTemplate")
    cooldown:SetAllPoints()
    cooldown:SetDrawEdge(true)
    cooldown:SetHideCountdownNumbers(false)
    f.cooldown = cooldown
    
    local rangeOverlay = f:CreateTexture(nil, "OVERLAY", nil, 1)
    rangeOverlay:SetAllPoints()
    rangeOverlay:SetTexture("Interface\\Buttons\\WHITE8X8")
    rangeOverlay:SetVertexColor(1, 0.2, 0.2, 0.5)
    rangeOverlay:Hide()
    f.rangeOverlay = rangeOverlay
    
    local keybind = f:CreateFontString(nil, "OVERLAY")
    keybind:SetFont("Fonts\\FRIZQT__.TTF", primary and 13 or 10, "OUTLINE")
    keybind:SetPoint("TOPLEFT", 2, -2)
    keybind:SetTextColor(1, 1, 1, 1)
    keybind:SetShadowOffset(1, -1)
    f.keybind = keybind
    
    if primary then
        local glow = f:CreateTexture(nil, "OVERLAY", nil, 2)
        glow:SetPoint("TOPLEFT", -12, 12)
        glow:SetPoint("BOTTOMRIGHT", 12, -12)
        glow:SetTexture("Interface\\SpellActivationOverlay\\IconAlert")
        glow:SetTexCoord(0.00781250, 0.50781250, 0.27734375, 0.52734375)
        glow:SetVertexColor(1, 0.82, 0, 1)
        glow:SetBlendMode("ADD")
        glow:SetAlpha(0.8)
        f.glow = glow
        
        local glowAnim = f:CreateAnimationGroup()
        local pulse1 = glowAnim:CreateAnimation("Alpha")
        pulse1:SetFromAlpha(0.6)
        pulse1:SetToAlpha(1)
        pulse1:SetDuration(0.5)
        pulse1:SetOrder(1)
        local pulse2 = glowAnim:CreateAnimation("Alpha")
        pulse2:SetFromAlpha(1)
        pulse2:SetToAlpha(0.6)
        pulse2:SetDuration(0.5)
        pulse2:SetOrder(2)
        glowAnim:SetLooping("REPEAT")
        f.glowAnim = glowAnim
    end
    
    local queueNum = f:CreateFontString(nil, "OVERLAY")
    queueNum:SetFont("Fonts\\FRIZQT__.TTF", primary and 18 or 14, "OUTLINE")
    queueNum:SetPoint("BOTTOMRIGHT", -2, 2)
    queueNum:SetTextColor(1, 1, 1, 0.9)
    queueNum:SetShadowOffset(1, -1)
    f.queueNum = queueNum
    
    f.primary = primary
    f.index = index
    f:Hide()
    
    return f
end

function addon:InitIcons()
    local main = CreateFrame("Frame", "WarriorRotationMain", UIParent)
    main:SetWidth(300)
    main:SetHeight(100)
    main:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
    main:SetFrameStrata("MEDIUM")
    addon.frames.main = main
    
    local icons = {}
    addon.frames.icons = icons
    
    icons[1] = CreateIconFrame(main, 1, true)
    icons[1]:SetPoint("LEFT", main, "LEFT", 0, 0)
    
    for i = 2, MAX_ICONS do
        icons[i] = CreateIconFrame(main, i, false)
    end
    
    local lastUpdate = 0
    local lastQueue = {}
    
    main:SetScript("OnUpdate", function(self, elapsed)
        lastUpdate = lastUpdate + elapsed
        local interval = addon.db.engine.updateInterval or 0.05
        if lastUpdate < interval then return end
        lastUpdate = 0
        
        local queue = addon:BuildQueue()
        
        addon:UpdateIcons(queue)
    end)
    
    main:EnableMouse(true)
    main:SetMovable(true)
    main:RegisterForDrag("LeftButton")
    
    main:SetScript("OnDragStart", function(self)
        if addon.db.locked then return end
        if IsShiftKeyDown() or not addon.db.locked then
            self:StartMoving()
        end
    end)
    
    main:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local _, _, _, x, y = self:GetPoint()
        addon.db.display.iconX = math.floor(x + 0.5)
        addon.db.display.iconY = math.floor(y + 0.5)
        if addon.RefreshOptionsUI then addon:RefreshOptionsUI() end
    end)
    
    main:SetScript("OnEnter", function(self)
        if addon.db.locked then return end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("WarriorRotation")
        GameTooltip:AddLine("Drag to move", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("/wr lock - to lock position", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    
    main:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
end

function addon:UpdateIcons(queue)
    local icons = addon.frames.icons
    if not icons then return end
    
    local db = addon.db.display
    local showCount = db.queueLength or 4
    
    if not queue or #queue == 0 then
        for i = 1, MAX_ICONS do
            icons[i]:Hide()
            if icons[i].glowAnim then
                icons[i].glowAnim:Stop()
            end
        end
        return
    end
    
    for i = 1, MAX_ICONS do
        local f = icons[i]
        local spellID = queue[i]
        
        if not spellID or i > showCount then
            f:Hide()
            if f.glowAnim then f.glowAnim:Stop() end
        else
            local name, _, tex = GetSpellInfo(spellID)
            
            if not tex then
                f:Hide()
                if f.glowAnim then f.glowAnim:Stop() end
            else
                f.icon:SetTexture(tex)
                
                if db.showKeybinds then
                    f.keybind:SetText(addon:GetKeybind(spellID))
                else
                    f.keybind:SetText("")
                end
                
                if db.showCooldowns then
                    local start, duration = addon:GetCooldown(spellID)
                    if start and start > 0 and duration and duration > 1.5 then
                        f.cooldown:SetCooldown(start, duration)
                        f.cooldown:Show()
                    else
                        f.cooldown:Hide()
                    end
                else
                    f.cooldown:Hide()
                end
                
                if i == 1 and db.showRange then
                    local inRange = addon:IsInMeleeRange()
                    if inRange then
                        f.rangeOverlay:Hide()
                        f.icon:SetVertexColor(1, 1, 1, 1)
                    else
                        if db.fadeOutOfRange then
                            f.rangeOverlay:Hide()
                            f.icon:SetVertexColor(1, 0.3, 0.3, db.fadeAmount or 0.4)
                        else
                            f.rangeOverlay:Show()
                            f.icon:SetVertexColor(1, 1, 1, 1)
                        end
                    end
                else
                    f.rangeOverlay:Hide()
                    f.icon:SetVertexColor(1, 1, 1, 1)
                end
                
                if i == 1 and f.glow and db.showGlow then
                    f.glow:Show()
                    if not f.glowAnim:IsPlaying() then
                        f.glowAnim:Play()
                    end
                elseif f.glow then
                    f.glow:Hide()
                    f.glowAnim:Stop()
                end
                
                f.queueNum:SetText(i > 1 and i or "")
                
                f:Show()
            end
        end
    end
end

function addon:ApplyIconLayout()
    local main = addon.frames.main
    if not main then return end
    
    local db = addon.db.display
    
    main:ClearAllPoints()
    main:SetPoint("CENTER", UIParent, "CENTER", db.iconX or 0, db.iconY or -200)
    
    local icons = addon.frames.icons
    if not icons then return end
    
    local primarySize = db.iconSize or 64
    local secondarySize = math.floor(primarySize * 0.65)
    local spacing = db.iconSpacing or 8
    
    icons[1]:ClearAllPoints()
    icons[1]:SetWidth(primarySize)
    icons[1]:SetHeight(primarySize)
    icons[1]:SetPoint("LEFT", main, "LEFT", 0, 0)
    
    if icons[1].glow then
        icons[1].glow:SetPoint("TOPLEFT", -primarySize * 0.2, primarySize * 0.2)
        icons[1].glow:SetPoint("BOTTOMRIGHT", primarySize * 0.2, -primarySize * 0.2)
    end
    
    icons[1].keybind:SetFont("Fonts\\FRIZQT__.TTF", math.max(10, math.floor(primarySize / 5)), "OUTLINE")
    icons[1].queueNum:SetFont("Fonts\\FRIZQT__.TTF", math.max(12, math.floor(primarySize / 4)), "OUTLINE")
    
    for i = 2, MAX_ICONS do
        icons[i]:ClearAllPoints()
        icons[i]:SetWidth(secondarySize)
        icons[i]:SetHeight(secondarySize)
        icons[i]:SetPoint("LEFT", icons[i-1], "RIGHT", spacing, 0)
        
        icons[i].keybind:SetFont("Fonts\\FRIZQT__.TTF", math.max(8, math.floor(secondarySize / 5)), "OUTLINE")
        icons[i].queueNum:SetFont("Fonts\\FRIZQT__.TTF", math.max(10, math.floor(secondarySize / 4)), "OUTLINE")
    end
    
    local totalWidth = primarySize + (MAX_ICONS - 1) * (secondarySize + spacing)
    main:SetWidth(totalWidth)
    main:SetHeight(primarySize)
end