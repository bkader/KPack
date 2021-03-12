local addonName, addon = ...
local L = addon.L

local mod = CreateFrame("Frame")
mod:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
mod:RegisterEvent("ADDON_LOADED")

CombatTimeDB = {}
local defaults = {
    enabled = false,
    stopwatch = false
}

local math_min, math_floor = math.min, math.floor
local _GetTime = GetTime
local _format = string.format

local function Print(msg)
    if msg then
        addon:Print(msg, "CombatTime")
    end
end

local CombatTime_CreateFrame
do
    local function CombatTime_OnUpdate(self, elapsed)
        self.updated = self.updated + elapsed

        if self.updated > 1 then
            local total = _GetTime() - self.starttime
            local _hor = math_min(math_floor(total / 3600), 99)
            local _min = math_min(math_floor(total / 60), 60)
            local _sec = math_min(math_floor(total), 60)

            self.timer:SetText(_format("%02d:%02d:%02d", _hor, _min, _sec))
            self.updated = 0
        end
    end

    function CombatTime_CreateFrame()
        local frame = CreateFrame("Frame", "KPackCombatTime")
        frame:SetSize(100, 40)
        frame:SetFrameStrata("LOW")
        frame:SetPoint("TOPLEFT", Minimap, "BOTTOMLEFT", 0, -10)

        -- make the frame movable
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:SetClampedToScreen(true)
        frame:RegisterForDrag("RightButton")
        frame:SetScript("OnDragStart", function(self)
            self.moving = true
            self:StartMoving()
        end)
        frame:SetScript("OnDragStop", function(self)
            self.moving = false
            self:StopMovingOrSizing()
        end)

        -- frame background
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            tile = true,
            tileSize = 32,
            insets = {left = 11, right = 12, top = 12, bottom = 11}
        })

        -- timer text
        local timer = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        timer:SetJustifyH("CENTER")
        timer:SetAllPoints(frame)
        timer:SetText("00:00:00")
        frame.timer = timer

        -- add out events and scripts
        frame:RegisterEvent("PLAYER_REGEN_DISABLED")
        frame:RegisterEvent("PLAYER_REGEN_ENABLED")
        frame:SetScript("OnEvent", function(self, event, ...)
            if event == "PLAYER_REGEN_ENABLED" then
                -- change the text and color
                self.timer:SetTextColor(0.5, 0.5, 0, 1)

                -- remove the update event
                self.updated = nil
                self:SetScript("OnUpdate", nil)

                -- are we using the stopwatch? reset it
                if mod.db.stopwatch and StopwatchFrame and StopwatchFrame:IsShown() then
                    Stopwatch_Pause()
                    self:Hide()
                else
                    self:Show()
                end
            elseif event == "PLAYER_REGEN_DISABLED" then
                if mod.db.stopwatch then
                    if not StopwatchFrame:IsShown() then
                        Stopwatch_Toggle()
                    end
                    Stopwatch_Clear()
                    Stopwatch_Play()

                    self:Hide()
                    self:SetScript("OnUpdate", nil)
                else
                    -- change the text and color
                    self.timer:SetTextColor(1, 1, 0, 1)

                    -- add the update event
                    self.starttime = _GetTime() - 1
                    self.updated = 0
                    self:SetScript("OnUpdate", CombatTime_OnUpdate)
                    self:Show()
                end
            end
        end)

        if mod.db.stopwatch then
            frame:Hide()
        else
            frame:Show()
        end

        return frame
    end
end

do
    local exec, help = {}, "|cffffd700%s|r: %s"

    exec.on = function()
        if mod.db.enabled ~= true then
            mod.db.enabled = true
            Print(L["|cff00ff00enabled|r"])
            mod.frame = mod.frame or CombatTime_CreateFrame()
        end
    end
    exec.enable = exec.on

    exec.off = function()
        if mod.db.enabled == true then
            mod.db.enabled = false
            Print(L["|cffff0000disabled|r"])
            if mod.frame then
                mod.frame:Hide()
                mod.frame:UnregisterAllEvents()
            end
        end
    end
    exec.disable = exec.off

    exec.stopwatch = function()
        if mod.db.stopwatch == true then
            mod.db.stopwatch = false
            Print(L:F("using stopwatch: %s", L["|cffff0000disabled|r"]))
        else
            Print(L:F("using stopwatch: %s", L["|cff00ff00enabled|r"]))
            mod.db.stopwatch = true
        end
    end

    exec.reset = function()
        wipe(CombatTimeDB)
        CombatTimeDB = CopyTable(defaults)
        Print(L["module's settings reset to default."])
        if mod.frame then
            mod.frame:Hide()
            mod.frame:UnregisterAllEvents()
            mod.frame = nil
            mod:ADDON_LOADED(addonName)
        end
    end
    exec.defaults = exec.reset

    local function SlashCommandHandler(msg)
        local cmd = msg:trim():lower()
        if type(exec[cmd]) == "function" then
            exec[cmd]()
        else
            Print(L:F("Acceptable commands for: |caaf49141%s|r", "/ct"))
            print(_format(help, "on", L["enable the module."]))
            print(_format(help, "off", L["disable the module."]))
            print(_format(help, "stopwatch", L["trigger the in-game stopwatch on combat"]))
            print(_format(help, "reset", L["Resets module settings to default."]))
        end
    end

    function mod:ADDON_LOADED(name)
        if name ~= addonName then
            return
        end

        -- disabled by default
        if next(CombatTimeDB) == nil then
            CombatTimeDB = CopyTable(defaults)
        end
        self.db = CombatTimeDB

        -- register our slash commands
        _G.SLASH_KPACKCOMBATTIME1 = "/ctm"
        SlashCmdList["KPACKCOMBATTIME"] = SlashCommandHandler

        -- we create the combat time frame only if enabled
        if self.db.enabled == true then
            self.frame = self.frame or CombatTime_CreateFrame()
        end
    end
end