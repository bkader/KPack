local folder, core = ...
local E = core:Events()
local L = core.L

-- cache frequently used glboals
local CreateFrame = CreateFrame
local UnitHealth, UnitHealthMax = UnitHealth, UnitHealthMax
local UnitPowerType, UnitPower, UnitPowerMax = UnitPowerType, UnitPower, UnitPowerMax
local floor, format = math.floor, string.format

-- saved variables and default
PersonalResourcesDB = {}
local defaults = {
    enabled = true,
    xOfs = 0,
    yOfs = -120,
    anchor = "CENTER",
    combat = false,
    width = 180,
    height = 32,
    scale = 1

}

local fname = "KPack_PersonalResources"

-- module print function
local function Print(msg)
    if msg then
        core:Print(msg, "PersonalResources")
    end
end

-- utility to show/hide frame
local function ShowHide(f, cond)
    if not f then
        return
    elseif cond and not f:IsShown() then
        f:Show()
    elseif not cond and f:IsShown() then
        f:Hide()
    end
end

-- ///////////////////////////////////////////////////////

local PersonalResources_Initialize
do
    -- creates bars

    local function PersonalResources_CreateBar(parent)
        if not parent then
            return
        end

        local bar = CreateFrame("StatusBar", nil, parent)
        bar:SetPoint("CENTER", 0, -120)
        bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        bar:GetStatusBarTexture():SetHorizTile(false)
        bar:GetStatusBarTexture():SetVertTile(false)
        bar:SetMinMaxValues(0, 100)
        return bar
    end

    -- handles OnDragStart event
    local function Frame_OnDragStart(self)
        if IsAltKeyDown() or IsShiftKeyDown() then
            self:StartMoving()
            self.moving = true
        end
    end

    -- handles OnDragStop event
    local function Frame_OnDragStop(self)
        self:StopMovingOrSizing()
        self.moving = false
        local anchor, _, _, x, y = self:GetPoint(1)
        PersonalResourcesDB.anchor = anchor
        PersonalResourcesDB.xOfs = x
        PersonalResourcesDB.yOfs = y
    end

    -- frame event handler
    local function Frame_OnEvent(self, event, ...)
        if event == "PLAYER_REGEN_ENABLED" then
            ShowHide(self, PersonalResourcesDB.combat)
        elseif event == "PLAYER_REGEN_DISABLED" then
            self:Show()
        end
    end

    local nextUpdate, updateInterval = 0, 0.05
    local Frame_OnUpdate
    local PersonalResources_UpdateValues
    do
        -- simple calculate
        local function PersonalResources_Calculate(val, maxVal)
            local res = (val / maxVal) * 100
            local mult = 10 ^ 2
            return math.floor(res * mult + 0.5) / mult
        end

        -- power color
        local function PersonalResources_PowerColor(t)
            local r, g, b = 0, 0, 1

            if t == "RAGE" then
                r, g, b = 1, 0, 0
            elseif t == "ENERGY" then
                r, g, b = 1, 1, 0
            elseif t == "RUNIC_POWER" then
                r, g, b = 0, 0.82, 1
            elseif t == "FOCUS" then
                r, g, b = 1, .5, .25
            end

            return r, g, b
        end

        function PersonalResources_UpdateValues(self)
            local hp, hpMax = UnitHealth("player"), UnitHealthMax("player")
            self.health:SetValue(PersonalResources_Calculate(hp, hpMax))

            local _, power = UnitPowerType("player")
            local pw, pwMax = UnitPower("player"), UnitPowerMax("player")
            self.power:SetValue(PersonalResources_Calculate(pw, pwMax))
            self.power:SetStatusBarColor(PersonalResources_PowerColor(power))
        end

        -- handles OnUpdate event
        function Frame_OnUpdate(self, elapsed)
            if not PersonalResourcesDB.enabled then
                self:SetScript("OnUpdate", nil)
            end

            nextUpdate = nextUpdate + (elapsed or 0)
            while nextUpdate > updateInterval do
                PersonalResources_UpdateValues(self)
                nextUpdate = nextUpdate - updateInterval
            end
        end
    end

    -- initializes personal resources
    function PersonalResources_Initialize(force)
		if force and frame then
			frame:Hide()
			frame = nil
		end

        local width = PersonalResourcesDB.width or 180
        local height = PersonalResourcesDB.height or 32
        local scale = PersonalResourcesDB.scale or 1

        local anchor = PersonalResourcesDB.anchor or "CENTER"
        local xOfs = PersonalResourcesDB.xOfs or 0
        local yOfs = PersonalResourcesDB.yOfs or -120

        -- create main frame
		frame = frame or CreateFrame("Frame", fname, UIParent)
        frame:SetSize(width, height)
        frame:SetPoint(anchor, xOfs, yOfs)

        -- health bar
        frame.health = PersonalResources_CreateBar(frame)
        frame.health:SetPoint("TOPLEFT", 2, -2)
        frame.health:SetPoint("RIGHT", -2, 0)
        frame.health:SetHeight(height * 0.53)
        frame.health:SetStatusBarColor(0, 0.65, 0)

        -- power bar
        frame.power = PersonalResources_CreateBar(frame)
        frame.power:SetPoint("BOTTOMLEFT", 2, 2)
        frame.power:SetPoint("RIGHT", -2, 0)
        frame.power:SetHeight(height * 0.40)
        frame.power:SetStatusBarColor(nil)
        ShowHide(frame, PersonalResourcesDB.enabled and PersonalResourcesDB.combat)
        frame:SetScale(scale)

        -- background & border
        frame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            insets = {left = 2, right = 2, top = 2, bottom = 2}
        })
        frame:SetBackdropColor(0, 0, 0, .65)

        -- make the frame movable
        frame:EnableMouse(true)
        frame:SetMovable(true)
        frame:RegisterForDrag("LeftButton")

        -- register our frame event
        if PersonalResourcesDB.enabled then
            frame:RegisterEvent("PLAYER_REGEN_ENABLED")
            frame:RegisterEvent("PLAYER_REGEN_DISABLED")
        else
            frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
            frame:UnregisterEvent("PLAYER_REGEN_DISABLED")
        end

        -- register events and set our scripts
        frame:SetScript("OnEvent", Frame_OnEvent)
        frame:SetScript("OnDragStart", Frame_OnDragStart)
        frame:SetScript("OnDragStop", Frame_OnDragStop)
        frame:SetScript("OnUpdate", Frame_OnUpdate)
        PersonalResources_UpdateValues(frame)
    end
end

function E:PLAYER_ENTERING_WORLD(cmd)
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    PersonalResources_Initialize(cmd)
end

-- slash commands handler
local SlashCommandHandler
do
    local commands = {}
    local help = "|cffffd700%s|r: %s"

    -- enable the module
    commands.enable = function()
        PersonalResourcesDB.enabled = true
        Print(L:F("module status: %s", L["|cff00ff00enabled|r"]))
    end
    commands.on = commands.enable

    -- disable the module
    commands.disable = function()
        PersonalResourcesDB.enabled = false
        Print(L:F("module status: %s", L["|cffff0000disabled|r"]))
    end
    commands.off = commands.disable

    -- hide the bar
    commands.show = function()
        ShowHide(frame, PersonalResourcesDB.enabled)
    end

    -- hide bar
    commands.hide = function()
        frame:Hide()
    end

    -- change scale
    commands.scale = function(n)
        n = tonumber(n)
        if n then PersonalResourcesDB.scale = n end
    end

    -- change width
    commands.width = function(n)
        n = tonumber(n)
        if n then PersonalResourcesDB.width = n end
    end

    -- change height
    commands.height = function(n)
        n = tonumber(n)
        if n then PersonalResourcesDB.height = n end
    end

    -- reset module
    commands.reset = function()
        wipe(PersonalResourcesDB)
        PersonalResourcesDB = defaults
        Print(L["module's settings reset to default."])
    end
    commands.default = commands.reset

    -- toggle combat
    commands.combat = function()
        PersonalResourcesDB.combat = not PersonalResourcesDB.combat
        if PersonalResourcesDB.combat then
            Print(L:F("show out on combat: %s", L["|cff00ff00ON|r"]))
            frame:Hide()
        else
            Print(L:F("show out on combat: %s", L["|cffff0000OFF|r"]))
            frame:Show()
        end
    end

    function SlashCommandHandler(msg)
        if InCombatLockdown() then
            Print("|cffffe02e" .. ERR_NOT_IN_COMBAT .. "|r")
            return
        end

        local cmd, rest = strsplit(" ", msg, 2)
        if type(commands[cmd]) == "function" then
            commands[cmd](rest)
            E:PLAYER_ENTERING_WORLD(true)
        else
            Print(L:F("Acceptable commands for: |caaf49141%s|r", "/ps"))
            print(format(help, "enable", L["enable module"]))
            print(format(help, "disable", L["disable module"]))
            print(format(help, "show", L["show personal resources"]))
            print(format(help, "hide", L["hide personal resources"]))
            print(format(help, "scale|r |cff00ffffn|r", L["change personal resources scale"]))
            print(format(help, "width|r |cff00ffffn|r", L["change personal resources width"]))
            print(format(help, "height|r |cff00ffffn|r", L["change personal resources height"]))
            print(format(help, "combat", L["toggle showing personal resources out of combat"]))
            print(format(help, "reset", L["Resets module settings to default."]))
        end
    end
end

-- frame event handler
function E:ADDON_LOADED(name)
	if name == folder then
        self:UnregisterEvent("ADDON_LOADED")

        if next(PersonalResourcesDB) == nil then
            PersonalResourcesDB = defaults
        end

        SlashCmdList["KPACKPLAYERRESOURCES"] = SlashCommandHandler
        _G.SLASH_KPACKPLAYERRESOURCES1 = "/ps"
        _G.SLASH_KPACKPLAYERRESOURCES2 = "/resources"
	end
end