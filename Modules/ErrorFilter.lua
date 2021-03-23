assert(KPack, "KPack not found!")
KPack:AddModule("ErrorFilter", "Manages the errors that are displayed in the blizzard UIErrorsFrame.", function(_, core, L)
    if core:IsDisabled("ErrorFilter") then return end

    local mod = core.ErrorFilter or {}
    core.ErrorFilter = mod

	local strfind = string.find
	local strlower = string.lower

    local DB
    local function Print(msg)
        if msg then
            core:Print(msg, "ErrorFilter")
        end
    end

    local options = {enabled = true, shown = true}

    local filters = {
        "your target is dead",
        "there is nothing to attack",
        "not enough rage",
        "not enough energy",
        "that ability requires combo points",
        "not enough runic power",
        "not enough runes",
        "you have no target",
        "invalid target",
        "you cannot attack that target",
        "spell is not ready yet",
        "ability is not ready yet",
        "you can't do that yet",
        "you are too far away",
        "out of range",
        "another action is in progress",
        "not enough mana",
        "not enough focus"
    }

    local SlashCommandHandler
    do
        local exec = {}

        exec.status = function()
            Print(L:F("Filter Enabled: %s - Frame Shown: %s", tostring(DB.options.enabled), tostring(DB.options.shown)))
        end

        exec.enable = function()
            if not DB.options.enabled then
                DB.options.enabled = true
                Print(L["module enabled."])
            end
        end

        exec.disable = function()
            if DB.options.enabled then
                DB.options.enabled = false
                Print(L["module disabled."])
            end
        end

        exec.hide = function()
            if DB.options.shown then
                DB.options.shown = false
                UIErrorsFrame:Hide()
                Print(L["Error frame is now hidden."])
            end
        end

        exec.show = function()
            if not DB.options.shown then
                DB.options.shown = true
                UIErrorsFrame:Show()
                Print(L["Error frame is now visible."])
            end
        end

        exec.list = function()
            Print(L["filter database:"])
            for i, filter in ipairs(DB.filters) do
                print("|cff00ff00" .. i .. "|r " .. filter)
            end
        end

        exec.clear = function()
            DB.filters = {}
            Print(L["database cleared."])
        end

        exec.reset = function()
            for k, v in pairs(options) do
                DB.options[k] = v
            end

            for i, filter in ipairs(filters) do
                DB.filters[i] = filter
            end

            Print(L["module's settings reset to default."])
        end
        exec.default = exec.reset

        exec.add = function(filter)
            if filter and filter ~= "" then
                tinsert(DB.filters, filter)
                Print(L:F("filter added: %s", filter))
            end
        end

        exec.delete = function(num)
            num = tonumber(num)
            for i, filter in ipairs(DB.filters) do
                if i == num then
                    table.remove(DB.filters, i)
                    Print(L:F("filter added: %s", filter))
                    break
                end
            end
        end
        exec.del = exec.delete

        function SlashCommandHandler(msg)
            local cmd, rest = strsplit(" ", msg, 2)
            if type(exec[cmd]) == "function" then
                exec[cmd](rest)
            else
                Print(L:F("Acceptable commands for: |caaf49141%s|r", "/erf"))
                print("|cffffd700status|r", L["show module status."])
                print("|cffffd700enable|r", L["enable the module."])
                print("|cffffd700disable|r", L["disable the module."])
                print("|cffffd700hide|r", L["hide error frame."])
                print("|cffffd700show|r", L["show error frame."])
                print("|cffffd700list|r", L["list of filtered errors."])
                print("|cffffd700clear|r", L["clear the list of filtered errors."])
                print("|cffffd700add|r |cff00ffffcontent|r : ", L["add an error filter"])
                print("|cffffd700delete|r |cff00ffffn|r : ", L["delete a filter by index"])
                print("|cffffd700reset|r", L["Resets module settings to default."])
            end
        end
    end

    local UIErrorsFrame_OldOnEvent = UIErrorsFrame:GetScript("OnEvent")
    UIErrorsFrame:SetScript("OnEvent", function(self, event, ...)
        if self[event] then
            return self[event](self, event, ...)
        end

        return UIErrorsFrame_OldOnEvent(self, event, ...)
    end)

    function UIErrorsFrame:UI_ERROR_MESSAGE(event, name, ...)
        if DB.options.enabled and DB.options.shown and DB.filters[1] then
            for k, v in next, DB.filters do
                if strfind(strlower(name), v) then
                    return
                end
            end
        end

        return UIErrorsFrame_OldOnEvent(self, event, name, ...)
    end

    local function SetupDatabase()
        if not DB then
            core.db.ErrorFilter = core.db.ErrorFilter or {}
            DB = core.db.ErrorFilter

            DB.options = DB.options or {}
            for k, v in pairs(options) do
                if DB.options[k] == nil then
                    DB.options[k] = v
                end
            end

            DB.filters = DB.filters or {}
            if not DB.filters[1] then
                for i, filter in ipairs(filters) do
                    DB.filters[i] = filter
                end
            end
        end
    end

    core:RegisterForEvent("PLAYER_LOGIN", function()
        SetupDatabase()
        if DB.options.shown then
            UIErrorsFrame:Show()
        else
            UIErrorsFrame:Hide()
        end
    end)

    SlashCmdList["KPACKERRORFILTER"] = SlashCommandHandler
    _G.SLASH_KPACKERRORFILTER1 = "/erf"
    _G.SLASH_KPACKERRORFILTER2 = "/errorfilter"
end)