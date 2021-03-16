local folder, core = ...

local mod = core.CLF or {}
core.CLF = mod
local frame = CreateFrame("Frame")

local E = core:Events()
local L = core.L

-- saved variables and default settings
CombatLogFixDB = {}
local defaults = {
    enabled = true,
    zone = true,
    auto = true,
    report = false,
    wait = false
}

-- main locals.
local instanceType, lastEvent, throttleBreak
local SlashCommandHandler

-- cache frequently used globals
local CombatLogGetNumEntries = CombatLogGetNumEntries
local IsInInstance = IsInInstance
local GetTime = GetTime
local lower, trim, print = string.lower, string.trim, print
local next, select = next, select
local setmetatable, rawset, rawget = setmetatable, rawset, rawget

-- main print function
local function Print(msg)
    if msg then
        core:Print(msg, "CombatLogFix")
    end
end

local function CombatLogReportEntries()
    if CombatLogFixDB.enabled and CombatLogFixDB.report and (not throttleBreak or throttleBreak < GetTime()) then
        Print(L:F("%d filtered/%d events found. Cleared combat log, as it broke.", CombatLogGetNumEntries(), CombatLogGetNumEntries(true)))
        throttleBreak = GetTime() + 60 -- every 60sec so we don't spam.
    end
end

local OldCombatLogClearEntries = CombatLogClearEntries
_G.CombatLogClearEntries = function()
    CombatLogReportEntries()
    OldCombatLogClearEntries()
end

-- handles frame's OnUpdate event
local function UpdateUIFrame(self, elapsed)
    if not CombatLogFixDB.enabled then
        self:SetScript("OnUpdate", nil)
        self:Hide()
        return
    end

    self.lastUpdated = (self.lastUpdated or 0) + elapsed
    if self.lastUpdated > 0.5 then
        if lastEvent and ((GetTime() - lastEvent) <= 1) then
            return
        end

        -- we queue the clear for later if the plauyer is in combat.
        if not (CombatLogFixDB.wait and InCombatLockdown()) then
            CombatLogClearEntries()
        end
        self.lastUpdated = 0
    end
end
do
    -- set of options and their texts
    local options = {
        enabled = L["Module Status"],
        zone = L["Zone Clearing"],
        auto = L["Auto Clearing"],
        wait = L["Queued Clearing"],
        report = L["Message Report"]
    }

    -- main slash commands handler.
    function SlashCommandHandler(msg)
        msg = lower(trim(msg or ""))
        if msg == "status" then
            -- reset to default
            Print(L["Show set options"])
            for k, v in pairs(options) do
                if CombatLogFixDB[k] then
                    print(v, ": |cff00ff00ON|r")
                else
                    print(v, ": |cffff0000OFF|r")
                end
            end
        elseif msg == "reset" then
            -- existing command
            wipe(CombatLogFixDB)
            CombatLogFixDB = defaults
            Print(L["module's settings reset to default."])
        elseif msg == "toggle" then
            CombatLogFixDB.enabled = not CombatLogFixDB.enabled
            if CombatLogFixDB.enabled then
                frame:SetScript("OnUpdate", UpdateUIFrame)
                frame:Show()
                Print(L:F("module status: %s", "|cff00ff00ON|r"))
            else
                frame:SetScript("OnUpdate", nil)
                frame:Hide()
                Print(L:F("module status: %s", "|cffff0000OFF|r"))
            end
        elseif msg ~= "enabled" and options[msg] then
            -- non-existing command
            CombatLogFixDB[msg] = not CombatLogFixDB[msg]
            local status = (CombatLogFixDB[msg] == true)
            Print(options[msg] .. " - " .. (status and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
        else
            Print(L:F("Acceptable commands for: |caaf49141%s|r", "/logfix"))
            print("|cffffd700toggle|r", L["Enables or disables the module."])
            print("|cffffd700status|r", L["List of set options."])
            print("|cffffd700zone|r", L["Toggles clearing on zone type change."])
            print("|cffffd700auto|r", L["Toggles clearing combat log when it breaks."])
            print("|cffffd700wait|r", L["Toggles not clearing until you drop combat."])
            print("|cffffd700report|r", L["Toggles reporting how many messages were found when it broke."])
            print("|cffffd700reset|r", L["Resets module settings to default."])
        end
    end
end

-- main frame event handler
function E:ADDON_LOADED(name)
    if name == folder then
        if next(CombatLogFixDB) == nil then
            CombatLogFixDB = defaults
        end

        -- register our slash commands
        SlashCmdList["KPACKLOGFIXER"] = SlashCommandHandler
        _G.SLASH_KPACKLOGFIXER1 = "/clf"
        _G.SLASH_KPACKLOGFIXER2 = "/fixer"
        _G.SLASH_KPACKLOGFIXER3 = "/logfix"

        frame:SetScript("OnUpdate", CombatLogFixDB.enabled and UpdateUIFrame or nil)
    end
end

-- clear combat log on zone change.
function E:ZONE_CHANGED_NEW_AREA()
    if CombatLogFixDB.enabled and CombatLogFixDB.zone then
        local t = select(2, IsInInstance())
        if instanceType and t ~= instanceType then
            CombatLogClearEntries()
        end
        instanceType = t
    end
end
E.PLAYER_ENTERING_WORLD = E.ZONE_CHANGED_NEW_AREA

-- queued clear after combat ends
function E:PLAYER_REGEN_ENABLED()
    if CombatLogFixDB.enabled and CombatLogFixDB.wait then
        CombatLogClearEntries()
    end
end

function E:COMBAT_LOG_EVENT_UNFILTERED()
    if CombatLogFixDB.enabled then
        lastEvent = GetTime()
    end
end