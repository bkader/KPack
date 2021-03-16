local folder, core = ...

local mod = core.SCP or {}
core.SCP = mod

local E = core:Events()
local L = core.L

-- cache frequently used globals
local pairs = pairs
local UnitClass, unitClass = UnitClass
local CreateFrame = CreateFrame
local GetComboPoints = GetComboPoints
local IsAltKeyDown = IsAltKeyDown
local InCombatLockdown = InCombatLockdown
local ColorPickerFrame = ColorPickerFrame

-- some locales we need
local maxPoints, xPos, yPos = 5, 0, 0
local druidForm, shown = false, true
local pointsFrame = {}

-- saved variables and default options
SimpleComboPointsDB = {}
local defaults = {
    enabled = true,
    width = 22,
    height = 22,
    scale = 1,
    spacing = 1,
    anchor = "CENTER",
    combat = false,
    color = {
        r = 0.9686274509803922,
        g = 0.674509803921568,
        b = 0.1450980392156863
    },
    xPos = xPos,
    yPos = yPos
}
local disabled

-- local functions
local SCP_InitializeFrames, SCP_RefreshDisplay
local SCP_UpdatePoints, SCP_UpdateFrames
local SCP_DestroyFrames
local SCP_ColorPickCallback

-- module's print function
local function Print(msg)
    if msg then
        core:Print(msg, "ComboPoints")
    end
end

-- //////////////////////////////////////////////////////////////

-- initializes the frame
function SCP_InitializeFrames()
    for i = 1, maxPoints do
        pointsFrame[i] = CreateFrame("Frame", "KPackSCPFrame" .. i, i == 1 and UIParent or pointsFrame[i - 1])
        pointsFrame[i]:SetBackdrop(
            {
                bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
                edgeFile = [[Interface/Tooltips/UI-Tooltip-Border]],
                tile = true,
                tileSize = 4,
                edgeSize = 4,
                insets = {left = 0.5, right = 0.5, top = 0.5, bottom = 0.5}
            }
        )
    end
    SCP_UpdateFrames()
end

-- updates the combo points frames
function SCP_UpdatePoints()
    local power, i = GetComboPoints("player"), 1
    local r, g, b = SimpleComboPointsDB.color.r, SimpleComboPointsDB.color.g, SimpleComboPointsDB.color.b
    while i <= power do
        if pointsFrame[i] then
            pointsFrame[i]:SetBackdropColor(r, g, b, 1)
        end
        i = i + 1
    end
    while i <= maxPoints do
        if pointsFrame[i] then
            pointsFrame[i]:SetBackdropColor(r, g, b, 0.1)
        end
        i = i + 1
    end
    if SimpleComboPointsDB.combat then
        SCP_RefreshDisplay()
    end
end

-- updates the whole frame
function SCP_UpdateFrames()
    local width = SimpleComboPointsDB.width or 22
    local height = SimpleComboPointsDB.height or 22
    local r, g, b = SimpleComboPointsDB.color.r, SimpleComboPointsDB.color.g, SimpleComboPointsDB.color.b

    for i = 1, maxPoints do
        if pointsFrame[i] then
            pointsFrame[i]:SetSize(width, height)
            pointsFrame[i]:SetBackdropColor(r, g, b, 0.1)
            pointsFrame[i]:SetBackdropBorderColor(0, 0, 0, 1)

            if i == 1 then
                pointsFrame[i]:SetPoint(
                    SimpleComboPointsDB.anchor,
                    UIParent,
                    SimpleComboPointsDB.anchor,
                    SimpleComboPointsDB.xPos,
                    SimpleComboPointsDB.yPos
                )
                pointsFrame[i]:SetScale(SimpleComboPointsDB.scale)

                pointsFrame[i]:SetMovable(true)
                pointsFrame[i]:EnableMouse(true)
                pointsFrame[i]:RegisterForDrag("LeftButton")

                pointsFrame[i]:SetScript(
                    "OnDragStart",
                    function(self)
                        if IsAltKeyDown() then
                            self:StartMoving()
                        end
                    end
                )
                pointsFrame[i]:SetScript(
                    "OnDragStop",
                    function(self)
                        self:StopMovingOrSizing()
                        local anchor, _, _, x, y = self:GetPoint(1)
                        SimpleComboPointsDB.xPos = x
                        SimpleComboPointsDB.yPos = y
                        SimpleComboPointsDB.anchor = anchor
                    end
                )
            else
                pointsFrame[i]:SetPoint("RIGHT", width + 1 + (SimpleComboPointsDB.spacing or 0), 0)
            end
            pointsFrame[i]:Show()
        end
    end
    SCP_UpdatePoints()
end

-- simply refreshes the display of the frame
function SCP_RefreshDisplay()
    if druidForm then
        return
    end

    if not InCombatLockdown() and GetComboPoints("player") == 0 and SimpleComboPointsDB.combat then
        for i = 1, maxPoints do
            pointsFrame[i]:Hide()
        end
        shown = false
    elseif not shown then
        for i = 1, maxPoints do
            pointsFrame[i]:Show()
        end
        shown = true
    end
end

-- destroys the frames.
function SCP_DestroyFrames()
    for i = 1, maxPoints do
        if pointsFrame[i] then
            pointsFrame[i]:Hide()
            pointsFrame[i] = nil
        end
    end
    pointsFrame = {}
end

-- hooked to the ColorPickerFrame
function SCP_ColorPickCallback(restore)
    local r, g, b
    if restore then
        r, g, b = unpack(restore)
    else
        r, g, b = ColorPickerFrame:GetColorRGB()
    end

    if r and g and b then
        SimpleComboPointsDB.color.r = r
        SimpleComboPointsDB.color.g = g
        SimpleComboPointsDB.color.b = b
        SCP_UpdateFrames()
    end
end

-- //////////////////////////////////////////////////////////////

-- after the player enters the world
function E:PLAYER_ENTERING_WORLD()
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    if disabled then return end

    SCP_InitializeFrames()
    SCP_UpdatePoints()
    -- only for druids.
    if unitClass == "DRUID" then
        self:UPDATE_SHAPESHIFT_FORM()
    end
end

-- used to update combo points
function E:UNIT_COMBO_POINTS()
	if disabled then
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
		self:UnregisterEvent("PLAYER_TARGET_CHANGED")
		self:UnregisterEvent("UNIT_COMBO_POINTS")
	else
		SCP_UpdatePoints()
	end
end
E.PLAYER_REGEN_ENABLED = E.UNIT_COMBO_POINTS
E.PLAYER_TARGET_CHANGED = E.UNIT_COMBO_POINTS

-- used only for druids
function E:UPDATE_SHAPESHIFT_FORM()
    if disabled or unitClass ~= "DRUID" then
        self:UnregisterEvent("UPDATE_SHAPESHIFT_FORM")
        return
    end

    if GetShapeshiftForm() == 3 then
        for i = 1, maxPoints do
            pointsFrame[i]:Show()
        end
        druidForm = false
    else
        for i = 1, maxPoints do
            pointsFrame[i]:Hide()
        end
        druidForm = true
    end
    SCP_UpdatePoints()
end

-- //////////////////////////////////////////////////////////////

-- slash commands handler
local function SlashCommandHandler(txt)
    local cmd, msg = txt:match("^(%S*)%s*(.-)$")
    cmd, msg = cmd:lower(), msg:lower()

    -- enable or disable the module
    if cmd == "toggle" then
        -- reset settings
        SimpleComboPointsDB.enabled = not SimpleComboPointsDB.enabled
        SCP_DestroyFrames()
        if not SimpleComboPointsDB.enabled then
            SCP_UpdateFrames()
        else
            SCP_InitializeFrames()
        end
    elseif cmd == "reset" then
        -- changing size
        wipe(SimpleComboPointsDB)
        SimpleComboPointsDB = defaults

        SCP_DestroyFrames()
        SCP_InitializeFrames()

        Print(L["module's settings reset to default."])
    elseif cmd == "width" or cmd == "height" and SimpleComboPointsDB[cmd] ~= nil then
        -- scaling
        local num = tonumber(msg)
        if num then
            SimpleComboPointsDB[cmd] = num
            SCP_UpdateFrames()
        else
            Print(L["The " .. cmd .. " must be a valid number"])
        end
    elseif cmd == "scale" then
        local scale = tonumber(msg)
        if scale then
            SimpleComboPointsDB.scale = scale
            SCP_UpdateFrames()
        else
            Print(L["Scale has to be a number, recommended to be between 0.5 and 3"])
        end
    elseif cmd == "spacing" then
        -- changing color
        local spacing = tonumber(msg)
        if spacing then
            SimpleComboPointsDB.spacing = spacing
            SCP_UpdateFrames()
        else
            Print(L["Spacing has to be a number, recommended to be between 0.5 and 3"])
        end
    elseif cmd == "color" or cmd == "colour" then
        -- toggle in and out of combat
        local r, g, b = SimpleComboPointsDB.color.r, SimpleComboPointsDB.color.g, SimpleComboPointsDB.color.b
        ColorPickerFrame:SetColorRGB(r, g, b)
        ColorPickerFrame.previousValues = {r, g, b}
        ColorPickerFrame.func = SCP_ColorPickCallback
        ColorPickerFrame.opacityFunc = SCP_ColorPickCallback
        ColorPickerFrame.cancelFunc = SCP_ColorPickCallback
        ColorPickerFrame:Hide()
        ColorPickerFrame:Show()
    elseif cmd == "combat" or cmd == "nocombat" then
        -- otherwise, show commands help
        SimpleComboPointsDB.combat = not SimpleComboPointsDB.combat

        local status = (SimpleComboPointsDB.combat == false)
        Print(L:F("Show out of combat: %s", (status and "|cff00ff00ON|r" or "|cffff0000OFF|r")))

        SCP_RefreshDisplay()
    else
        Print(L:F("Acceptable commands for: |caaf49141%s|r", "/scp"))
        print("|cffffd700toggle|r", L["Enables or disables the module."])
        print("|cffffd700width or height |cff00ffffn|r|r", L["Changes the points width or height."])
        print("|cffffd700scale |cff00ffffn|r|r", L["Changes frame scale."])
        print("|cffffd700spacing |cff00ffffn|r|r", L["Changes spacing between points."])
        print("|cffffd700color|r", L["Changes points color."])
        print("|cffffd700combat|r", L["Toggles showing combo points out of combat."])
        print("|cffffd700reset|r", L["Resets module settings to default."])
    end
end

function E:ADDON_LOADED(name)
    if name ~= folder then
        return
    end
    self:UnregisterEvent("ADDON_LOADED")

    for k, v in pairs(defaults) do
        if SimpleComboPointsDB[k] == nil then
            SimpleComboPointsDB[k] = v
        end
    end

    -- hold the unit class
    unitClass = select(2, UnitClass("player"))

    -- if the player isn't a rogue or druid, ignore
    if unitClass ~= "ROGUE" and unitClass ~= "DRUID" then
        disabled = true
        return
    end

    -- register our slash commands handler
    SlashCmdList["KPACKSCP"] = SlashCommandHandler
    SLASH_KPACKSCP1, SLASH_KPACKSCP2 = "/scp", "/simplecombopoints"

    -- if the module is disabled, ignore
    if not SimpleComboPointsDB.enabled then
        return
    end
end