local addonName, addon = ...

local Options = addon.ui.options

function addon:InitOptionsKnown()
    local p = Options.pages.known
    if not p then return end
    
    Options:CreateHeader(p, "Known Spells", 10, -10)
    
    Options:CreateButton(p, "Refresh", 10, -40, 100, 24, function()
        if addon.RefreshSpellIDs then addon:RefreshSpellIDs() end
        addon:UpdateKnownSpellsUI()
    end)
    
    local scroll = CreateFrame("ScrollFrame", "WRKnownScroll", p, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", p, "TOPLEFT", 10, -75)
    scroll:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -30, 10)
    
    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(480)
    content:SetHeight(600)
    scroll:SetScrollChild(content)
    
    local text = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("TOPLEFT", 0, 0)
    text:SetWidth(460)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("TOP")
    text:SetText("")
    
    p.textDisplay = text
end

function addon:UpdateKnownSpellsUI()
    local p = Options.pages.known
    if not p or not p.textDisplay then return end
    
    if addon.RefreshSpellIDs then addon:RefreshSpellIDs() end
    
    local specSpells = {
        { name = "ARMS", spells = { "Rend", "Overpower", "MortalStrike", "Bladestorm", "Slam", "HeroicStrike", "Execute" } },
        { name = "FURY", spells = { "Bloodthirst", "Whirlwind", "DeathWish", "BerserkerRage", "Recklessness", "Slam", "HeroicStrike", "Execute" } },
        { name = "PROT", spells = { "ShieldSlam", "Revenge", "Devastate", "Shockwave", "ConcussionBlow", "ThunderClap", "DemoralizingShout", "HeroicThrow" } },
    }
    
    local lines = {}
    
    for _, spec in ipairs(specSpells) do
        lines[#lines + 1] = "|cFFFFD100" .. spec.name .. "|r"
        
        for _, key in ipairs(spec.spells) do
            local id = addon.spells[key]
            local displayName = addon.spellNames[key] or key
            local status, idText
            
            if id then
                status = "|cFF00FF00known|r"
                idText = tostring(id)
            else
                status = "|cFFFF0000unknown|r"
                idText = "-"
            end
            
            lines[#lines + 1] = string.format("  %s (%s) ID: %s", displayName, status, idText)
        end
        
        lines[#lines + 1] = ""
    end
    
    p.textDisplay:SetText(table.concat(lines, "\n"))
end