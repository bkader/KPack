local addonName, addon = ...
local L = addon.L

local mod = addon.CLF
if not mod then
    mod = CreateFrame("Frame")
    addon.CLF = mod
end
mod:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
mod:RegisterEvent("ADDON_LOADED")

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
local CombatLogClearEntries = CombatLogClearEntries
local IsInInstance = IsInInstance
local GetTime = GetTime
local lower, trim, print = string.lower, string.trim, print
local next, select = next, select
local setmetatable, rawset, rawget = setmetatable, rawset, rawget

-- main print function
local function Print(msg)
    if msg then
        addon:Print(msg, "CombatLogFix")
    end
end

-- handles events registeration for the main frame.
local function CombatLogFix_CheckEvents()
    -- check zone
    if CombatLogFixDB.zone then
        mod:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        mod:RegisterEvent("PLAYER_ENTERING_WORLD")
    else
        mod:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
        mod:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end

    -- auto fix
    if CombatLogFixDB.auto then
        mod:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        mod:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
        mod:RegisterEvent("PLAYER_REGEN_ENABLED")
    else
        mod:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        mod:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
        mod:UnregisterEvent("PLAYER_REGEN_ENABLED")
    end
end

-- handles frame's OnUpdate event
local function UpdateUIFrame(self, elapsed)
    self.timeout = self.timeout - elapsed
    if self.timeout > 0 then return end
    self:Hide()

    -- if the last combat log event was within a second
    -- of the case succeeding, we stop.
    if lastEvent and ((GetTime() - lastEvent) <= 1) then
        return
    end

    -- tell the player about filtered events
    if CombatLogFixDB.report then
        if not throttleBreak or throttleBreak < GetTime() then
            Print(L:F("%d filtered/%d events found. Cleared combat log, as it broke.", CombatLogGetNumEntries(), CombatLogGetNumEntries(true)))
            throttleBreak = GetTime() + 60
        end
    end

    -- we queue the clear for later if the plauyer is in combat.
    if CombatLogFixDB.wait and InCombatLockdown() then
        mod:RegisterEvent("PLAYER_REGEN_ENABLED")
    else
        CombatLogClearEntries()
    end
end
do
    -- set of options and their texts
    local options = {
        toggle = L["Module Status"],
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
            CombatLogFix_CheckEvents()
            Print(L["module's settings reset to default."])
        elseif options[msg] then
            -- non-existing command
            CombatLogFixDB[msg] = not CombatLogFixDB[msg]
            CombatLogFix_CheckEvents() -- recheck events.
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
function mod:ADDON_LOADED(name)
    if name ~= addonName then return end
    self:UnregisterEvent("ADDON_LOADED")

    if next(CombatLogFixDB) == nil then
        CombatLogFixDB = defaults
    end

    -- register our slash commands
    SlashCmdList["KPACKLOGFIXER"] = SlashCommandHandler
    _G.SLASH_KPACKLOGFIXER1 = "/clf"
    _G.SLASH_KPACKLOGFIXER2 = "/fixer"
    _G.SLASH_KPACKLOGFIXER3 = "/logfix"

    if CombatLogFixDB.enabled then
        CombatLogFix_CheckEvents()
        self:SetScript("OnUpdate", UpdateUIFrame)
	else
		self:SetScript("OnUpdate", nil)
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")
		self:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
		self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	end

    self:Hide()
end

-- clear combat log on zone change.
function mod:ZONE_CHANGED_NEW_AREA()
    local t = select(2, IsInInstance())
    if instanceType and t ~= instanceType then
        CombatLogClearEntries()
    end
    instanceType = t
end
mod.PLAYER_ENTERING_WORLD = mod.ZONE_CHANGED_NEW_AREA

-- queued clear after combat ends
function mod:PLAYER_REGEN_ENABLED()
    CombatLogClearEntries()
end

do
    -- if a cast is sent, we expect a combat log event.
    local spells = setmetatable({}, {
        __index = function(tbl, name)
            local cost = select(4, GetSpellInfo(name))
            rawset(tbl, name, not (not (cost and cost > 0)))
            return rawget(tbl, name)
        end
    })

    function mod:UNIT_SPELLCAST_SUCCEEDED(event, unit, name, range, castId)
        if unit == "player" and name and spells[name] then
            self.timeout = 0.5
            self:Show()
        end
    end
end

function mod:COMBAT_LOG_EVENT_UNFILTERED()
    lastEvent = GetTime()
end