local folder, core = ...

local mod = core.ErrorFilter or {}
core.ErrorFilter = mod

local E = core:Events()
local L = core.L

ErrorFilterDB = {}

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
        Print(
            "Filter Enabled: " ..
                tostring(ErrorFilterDB.options.enabled) .. " - Frame Shown:" .. tostring(ErrorFilterDB.options.shown)
        )
    end

    exec.enable = function()
        if not ErrorFilterDB.options.enabled then
            ErrorFilterDB.options.enabled = true
            Print(L["module enabled."])
        end
    end

    exec.disable = function()
        if ErrorFilterDB.options.enabled then
            ErrorFilterDB.options.enabled = false
            Print(L["module disable."])
        end
    end

    exec.hide = function()
        if ErrorFilterDB.options.shown then
            ErrorFilterDB.options.shown = false
            UIErrorsFrame:Hide()
            Print(L["Error frame is now hidden."])
        end
    end

    exec.show = function()
        if not ErrorFilterDB.options.shown then
            ErrorFilterDB.options.shown = true
            UIErrorsFrame:Show()
            Print(L["Error frame is now visible."])
        end
    end

    exec.list = function()
        Print(L["filter database:"])
        for i, filter in ipairs(ErrorFilterDB.filters) do
            print("|cff00ff00" .. i .. "|r " .. filter)
        end
    end

    exec.clear = function()
        ErrorFilterDB.filters = {}
        Print(L["database cleared."])
    end

    exec.reset = function()
        for k, v in pairs(options) do
            ErrorFilterDB.options[k] = v
        end

        for i, filter in ipairs(filters) do
            ErrorFilterDB.filters[i] = filter
        end

        Print(L["module's settings reset to default."])
    end
    exec.default = exec.reset

    exec.add = function(filter)
        if filter and filter ~= "" then
            tinsert(ErrorFilterDB.filters, filter)
            Print(L:F("filter added: %s", filter))
        end
    end

    exec.delete = function(num)
        num = tonumber(num)
        for i, filter in ipairs(ErrorFilterDB.filters) do
            if i == num then
                table.remove(ErrorFilterDB.filters, i)
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

function E:ADDON_LOADED(name)
	if name ~= folder then return end
	self:UnregisterEvent("ADDON_LOADED")

    SlashCmdList["KPACKERRORFILTER"] = SlashCommandHandler
    _G.SLASH_KPACKERRORFILTER1 = "/erf"
    _G.SLASH_KPACKERRORFILTER2 = "/errorfilter"

    ErrorFilterDB.options = ErrorFilterDB.options or {}
    for k, v in pairs(options) do
        if ErrorFilterDB.options[k] == nil then
            ErrorFilterDB.options[k] = v
        end
    end

    ErrorFilterDB.filters = ErrorFilterDB.filters or {}
    if not ErrorFilterDB.filters[1] then
        for i, filter in ipairs(filters) do
            ErrorFilterDB.filters[i] = filter
        end
    end

    if ErrorFilterDB.options.shown then
        UIErrorsFrame:Show()
    else
        UIErrorsFrame:Hide()
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
    if ErrorFilterDB.options.enabled and ErrorFilterDB.options.shown and ErrorFilterDB.filters[1] then
        for k, v in next, ErrorFilterDB.filters do
            if string.find(string.lower(name), v) then
                return
            end
        end
    end

    return UIErrorsFrame_OldOnEvent(self, event, name, ...)
end