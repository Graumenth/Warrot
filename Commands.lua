local addonName, addon = ...

function addon:InitCommands()
    SLASH_WARRIORROTATION1 = "/warrot"
    SLASH_WARRIORROTATION2 = "/wr"

    SlashCmdList["WARRIORROTATION"] = function(msg)
        msg = ((msg or ""):lower()):match("^%s*(.-)%s*$") or ""

        if msg == "" then
            if addon.frames.options and addon.frames.options:IsShown() then
                addon:HideOptions()
            else
                addon:ShowOptions()
            end
            return
        end

        if msg == "options" or msg == "opt" or msg == "o" then
            addon:ShowOptions()
            return
        end

        if msg == "toggle" then
            addon.db.enabled = not addon.db.enabled
            return
        end

        if msg == "arms" or msg == "fury" or msg == "prot" then
            addon.db.spec = msg
            if addon.RefreshOptionsUI then addon:RefreshOptionsUI() end
            return
        end
    end
end