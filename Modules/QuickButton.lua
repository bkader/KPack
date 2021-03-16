if not LibStub then return end -- required

local folder, core = ...
local E = core:Events()
local L = core.L

local mod = core.QuickButton or {}
core.QuickButton = mod

-- events frame
local updateInterval = 0.1

-- saved variables and defaults
local DB
local defaults = {
    enabled = true,
    scale = 1,
    assigned = "player",
    point = "CENTER",
    rPoint = "CENTER",
    xOfs = 0,
    yOfs = 0,
    macro = false
}

-- cache frequently used globals
local UnitIsPlayer, UnitName, UnitClass = UnitIsPlayer, UnitName, UnitClass
local UnitInRaid = UnitInRaid
local GetPartyAssignment = GetPartyAssignment
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local GetNumPartyMembers = GetNumPartyMembers
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local GetSpellInfo, GetSpellCooldown = GetSpellInfo, GetSpellCooldown
local IsUsableSpell, IsSpellInRange = IsUsableSpell, IsSpellInRange
local CreateMacro, EditMacro, DeleteMacro = CreateMacro, EditMacro, DeleteMacro

local lower, trim, format = string.lower, string.trim, string.format
local next, select, type = next, select, type
local pairs, ipairs = pairs, ipairs
local tonumber = tonumber

-- needed locals
local unitClass, unitLevel
local spellId, spellName, spellIcon, maxRange, tooltip
local LibQTip = LibStub("LibQTip-1.0")
local unitId, assigned, disabled

-- classes and their spells
local classes = {
    DEATHKNIGHT = 49016, -- Hysteria,
    DRUID = 29166, -- Innervate
    HUNTER = 34477, -- Misdirection
    MAGE = 54648, -- Focus Magic
    PALADIN = 6940, -- Hand of Sacrifice
    PRIEST = 6346, -- Fear Ward
    ROGUE = 57934, -- Tricks of the Trade
    SHAMAN = 974, -- Earth Shield
    WARRIOR = 50720 -- Vigilance
}

-- classes that can cast the spell on themsevles or pets
local selfClasses = {
    DEATHKNIGHT = true,
    DRUID = true,
    HUNTER = true,
    PRIEST = true,
    SHAMAN = true
}

local macroFormat = [[
#showtooltip %s
/use [@%s] %s
]]

local btnName, button = "QuickButtonFrame"

-- module's print function
local function Print(msg)
    if msg then
        core:Print(msg, "QuickButton")
    end
end

-- utility function to show or hide
local function ShowHide(frame, cond)
    if not frame then
        return
    elseif cond and not frame:IsShown() then
        frame:Show()
    elseif not cond and frame:IsShown() then
        frame:Hide()
    end
end

-- destroys the button
local function QuickButton_DestroyButton()
    if button and button.Hide then
        button:Hide()
        button:SetScript("OnUpdate", nil)
    end
    if _G[btnName] then
        _G[btnName]:Hide()
    end
end

-- creates the macro
local function QuickButton_Macro()
    if DB.macro == false then
        DeleteMacro("KPackQuickButton")
        return
    end

    local i = GetMacroIndexByName("KPackQuickButton")
    local macroBody = format(macroFormat, spellName, unitId, spellName)
    if i > 0 then
        EditMacro(i, "KPackQuickButton", nil, macroBody)
    else
        CreateMacro("KPackQuickButton", 1, macroBody)
    end
end

local SlashCommandHandler
do
    local exec = {}
    local help = "|cffffd700%s|r: %s"

    -- toggle module status
    exec.toggle = function()
        DB.enabled = not DB.enabled
        Print(DB.enabled and L["|cff00ff00enabled|r"] or L["|cffff0000disabled|r"])
    end

    -- set scale
    exec.scale = function(n)
        n = tonumber(n)
        if n and n ~= DB.scale then
            DB.scale = n
            button:SetScale(n)
        end
    end

    -- toggle macro creation
    exec.macro = function()
        DB.macro = not DB.macro
        QuickButton_Macro()
        Print(L:F("macro creation %s", DB.macro and L["|cff00ff00enabled|r"] or L["|cffff0000disabled|r"]))
    end

    -- reset to default
    exec.reset = function()
        wipe(DB)
        DB = defaults
        Print(L["module's settings reset to default."])
    end
    exec.default = exec.reset

    function SlashCommandHandler(msg)
        local cmd, rest = strsplit(" ", msg, 2)
        if type(exec[cmd]) == "function" then
            exec[cmd](rest)
            E:PLAYER_ENTERING_WORLD()
        else
            Print(L:F("Acceptable commands for: |caaf49141%s|r", "/qb"))
            print("|cffffd700toggle|r : ", L["Turns module |cff00ff00ON|r or |cffff0000OFF|r."])
            print("|cffffd700macro|r : ", L["Creates or deletes the QuickButton macro."])
            print("|cffffd700scale|r |cff00ffffn|r : ", L["Scales the button."])
            print("|cffffd700reset|r : ", L["Resets module settings to default."])
        end
    end
end

-- frame events handler
function E:ADDON_LOADED(name)
	if name ~= folder then return end
	self:UnregisterEvent("ADDON_LOADED")

    if type(KPackCharDB.QuickButton) ~= "table" or not next(KPackCharDB.QuickButton) then
        KPackCharDB.QuickButton = CopyTable(defaults)
    end
    DB = defaults

    unitClass = select(2, UnitClass("player"))
    if not classes[unitClass] or not LibQTip then
        disabled = true
        return
    end

    SlashCmdList["KPACKQUICKBUTTON"] = SlashCommandHandler
    _G.SLASH_KPACKQUICKBUTTON1 = "/qb"
    _G.SLASH_KPACKQUICKBUTTON2 = "/quickbutton"
    E:PLAYER_ENTERING_WORLD()
end

do
    local QuickButton_CreateButton
    local QuickButton_CreateTip

    do
        do
            -- creates lines for unit selection
            local function QuickButton_CreateLine(unit, icon)
                if not icon then
                    return
                end
                local y, x = tooltip:AddLine()
                if assigned == UnitName(unit) or assigned == UnitName(unit .. "pet") then
                    tooltip:SetCell(y, 1, "|TInterface\\Buttons\\UI-CheckBox-Check:20:20|t")
                else
                    tooltip:SetCell(y, 1, "|TInterface\\Buttons\\UI-CheckBox-UP:20:20|t")
                end

                if UnitInRaid("player") then
                    if GetPartyAssignment("MAINTANK", unit) then
                        tooltip:SetCell(y, 2, "|TInterface\\GroupFrame\\UI-Group-MainTankIcon:0|t")
                    elseif GetPartyAssignment("MAINASSIST", unit) then
                        tooltip:SetCell(y, 2, "|TInterface\\GroupFrame\\UI-Group-MainAssistIcon:0|t")
                    else
                        tooltip:SetCell(y, 2, "")
                    end
                else
                    local isTank, isHealer, isDPS = UnitGroupRolesAssigned(unit)
                    if isTank then
                        tooltip:SetCell(
                            y,
                            2,
                            "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES.blp:20:20:0:0:64:64:0:19:22:41|t"
                        )
                    elseif isHealer then
                        tooltip:SetCell(
                            y,
                            2,
                            "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES.blp:20:20:0:0:64:64:20:39:1:20|t"
                        )
                    elseif isDPS then
                        tooltip:SetCell(
                            y,
                            2,
                            "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES.blp:20:20:0:0:64:64:20:39:22:41|t"
                        )
                    else
                        tooltip:SetCell(y, 2, "")
                    end
                end

                local c = RAID_CLASS_COLORS[select(2, UnitClass(unit))]
                tooltip:SetCell(y, 3, format("|cff%02x%02x%02x%s|r", c.r * 255, c.g * 255, c.b * 255, UnitName(unit)))
                tooltip:SetLineScript(
                    y,
                    "OnMouseUp",
                    function()
                        unitId = (unit == "player" and unitClass == "HUNTER") and "pet" or unit
                        assigned = UnitName(unitId)
                        DB.assigned = assigned
                        icon:SetAttribute("unit", unitId)
                        tooltip:Hide()
                        Print(L:F("%s will be placed on %s.", spellName, assigned))
                    end
                )
            end

            -- handles the tooltip menu
            function QuickButton_CreateTip(self)
                if GetNumPartyMembers() == 0 and not UnitInRaid("player") then
                    assigned = UnitName("player")
                end

                if tooltip then
                    LibQTip:Release(tooltip)
                end

                tooltip = LibQTip:Acquire("QuickButtonTooltip", 3, "CENTER", "CENTER", "LEFT")
                tooltip:Clear()
                self.tooltip = tooltip

                local prefix, min, max = "raid", 1, GetNumRaidMembers()
                if max == 0 then
                    prefix, min, max = "party", 0, GetNumPartyMembers()
                end

                for i = min, max do
                    local unit = (i == 0) and "player" or tostring(prefix .. i)
                    if UnitIsPlayer(unit) then
                        QuickButton_CreateLine(unit, self)
                    end
                end

                tooltip:SetAutoHideDelay(0.01, self)
                tooltip:SmartAnchorTo(self)
                tooltip:Show()
            end
        end

        -- handles button OnDragStart event
        local function Icon_OnDragStart(self)
            if IsShiftKeyDown() then
                self.moving = true
                self:StartMoving()
            end
        end

        -- handles button OnDragStop event
        local function Icon_OnDragStop(self)
            local point, _, rPoint, xOfs, yOfs = self:GetPoint()
            DB.point = point
            DB.rPoint = rPoint
            DB.xOfs = xOfs
            DB.yOfs = yOfs

            self.moving = false
            self:StopMovingOrSizing()
        end

        -- creates the class button
        function QuickButton_CreateButton()
            button =
                button or CreateFrame("Button", btnName, UIParent, "SecureActionButtonTemplate, ActionButtonTemplate")
            button:SetFrameStrata("HIGH")
            button.texture = _G[btnName .. "Icon"]
            button.cooldown = _G[btnName .. "Cooldown"]
            button.hotkey = _G[btnName .. "HotKey"]
            button.texture:SetTexture(spellIcon)
            -- button.texture:SetAllPoints(button)
            button:SetScale(DB.scale or 1)

            -- make the icon movable and clamp it to screen
            button:SetMovable(true)
            button:RegisterForClicks("AnyUp")
            button:RegisterForDrag("LeftButton")
            button:SetClampedToScreen(true)
            button:SetScript("OnDragStart", Icon_OnDragStart)
            button:SetScript("OnDragStop", Icon_OnDragStop)

            -- position the icon
            button:SetPoint("CENTER", UIParent, "CENTER")
            button:SetPoint(DB.point, UIParent, DB.rPoint, DB.xOfs, DB.yOfs)

            -- set button attributes
            button:SetAttribute("type1", "spell")
            button:SetAttribute("spell", spellName)
            button:SetAttribute("unit", unitId)
            button:SetAttribute("checkselfcast", true)
            button:SetAttribute("checkfocuscast", true)

            button.CreateTip = QuickButton_CreateTip
            button:SetAttribute("type2", "macro")
            button:SetAttribute("macrotext2", "/script QuickButtonFrame:CreateTip()")

            button.newTimer = 0
            button:Show()
        end
    end

    -- button's OnUpdate function
    local function Icon_OnUpdate(self, elapsed)
        local rangeTimer = self.newTimer
        if rangeTimer then
            rangeTimer = rangeTimer - elapsed
            if rangeTimer <= 0 then
                if not unitId or unitId == "player" then
                    self.texture:SetVertexColor(1, 1, 1, 1)
                elseif unitId then
                    local usable, noMana = IsUsableSpell(spellId)
                    local inRange = IsSpellInRange(spellName, unitId)

                    if not maxRange or inRange == nil then
                        inRange = 1
                    end
                    if inRange == 1 and not noMana then
                        self.texture:SetVertexColor(1, 1, 1, 1)
                    else
                        self.texture:SetVertexColor(1.0, 0.1, 0.1)
                    end
                end

                -- spell on cooldown
                local startTime, duration, _ = GetSpellCooldown(spellId)
                if duration and duration > 0 then
                    CooldownFrame_SetTimer(self.cooldown, startTime, duration, 1)
                end

                rangeTimer = 0.05
            end
            self.newTimer = rangeTimer
        end
    end

    local IsInRaid = _G.IsInRaid
    if not IsInRaid then
        IsInRaid = function()
            return (GetNumRaidMembers() > 0)
        end
    end

    local IsInParty = _G.IsInParty
    if not IsInParty then
        IsInParty = function()
            return (GetNumPartyMembers() > 0)
        end
    end

    local IsInGroup = _G.IsInGroup
    if not IsInGroup then
        IsInGroup = function()
            return (IsInRaid() or IsInParty())
        end
    end

    -- called upon initialization or party/raid update
    local function QuickButton_Initialize()
        if not DB.enabled then
            unitId = unitClass == "HUNTER" and "pet" or "player"
            assigned = UnitName(unitId)
            QuickButton_DestroyButton()
            return
        end

        assigned = assigned or DB.assigned

        if IsInGroup() then
            local prefix, min, max = "raid", 1, GetNumRaidMembers()
            if max == 0 then
                prefix, min, max = "party", 0, GetNumPartyMembers()
            end

            for i = min, max do
                local unit = (i == 0) and "player" or tostring(prefix .. i)
                if UnitIsPlayer(unit) and UnitName(unit) == assigned then
                    unitId = unit
                    break
                end
            end

            unitId = unitId or "player"

            if UnitName(unitId) == UnitName("player") and selfClasses[unitClass] then
                unitId = (unitClass == "HUNTER") and "pet" or "player"
            end
            assigned = UnitName(unitId)
            QuickButton_CreateButton()
            QuickButton_Macro()
            button:SetScript("OnUpdate", Icon_OnUpdate)
        elseif selfClasses[unitClass] then
            unitId = (unitClass == "HUNTER") and "pet" or "player"
            assigned = UnitName(unitId)
            QuickButton_CreateButton()
            QuickButton_Macro()
            button:SetScript("OnUpdate", Icon_OnUpdate)
        else
            QuickButton_DestroyButton()
        end
    end

    -- on PLAYER_ENTERING_WORLD event
    function E:PLAYER_ENTERING_WORLD()
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        if disabled then
			self:UnregisterEvent("SPELLS_CHANGED")
			return
        end

        spellId = classes[unitClass]
        spellName = select(1, GetSpellInfo(spellId))
        if not spellName then
	        self:UnregisterEvent("SPELLS_CHANGED")
	        self:UnregisterEvent("UPDATE_BINDINGS")
            disabled = true
            return
        end
        spellIcon = select(3, GetSpellInfo(spellId))
        maxRange = select(9, GetSpellInfo(spellId))

        QuickButton_Initialize()

        if DB.enabled and button then
            ShowHide(button, IsUsableSpell(spellName) == 1)
            self:UPDATE_BINDINGS()
        elseif button then
            button:Hide()
        end
    end
    E.SPELLS_CHANGED = E.PLAYER_ENTERING_WORLD

    -- on PLAYER_TALENT_UPDATE event
    function E:PLAYER_TALENT_UPDATE()
		if disabled then
			self:UnregisterEvent("PLAYER_TALENT_UPDATE")
			self:UnregisterEvent("RAID_ROSTER_UPDATE")
			self:UnregisterEvent("PARTY_MEMBERS_CHANGED")
			return
		end

		QuickButton_Initialize()
    end
    E.RAID_ROSTER_UPDATE = E.PLAYER_TALENT_UPDATE
    E.PARTY_MEMBERS_CHANGED = E.PLAYER_TALENT_UPDATE

    function E:UPDATE_BINDINGS()
        if not disabled and button and button.hotkey then
            button.hotkey:SetText(GetBindingKey("CLICK QuickButtonFrame:LeftButton") or "")
        end
    end
end

-- keybindings
_G.BINDING_HEADER_KPACKQUICKBUTTON = "|cff69ccf0K|r|caaf49141Pack|r QuickButton"