assert(KPack, "KPack not found!")
KPack:AddModule("SimpleComboPoints", function(_, core, L)
    if core:IsDisabled("SimpleComboPoints") then return end

    local mod = core.SCP or {}
    core.SCP = mod

    -- cache frequently used globals
    local pairs = pairs
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
    local DB, _
    local defaults = {
        enabled = true,
        width = 22,
        height = 22,
        scale = 1,
        spacing = 1,
        combat = false,
        anchor = "CENTER",
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
    local UPDATE_SHAPESHIFT_FORM

    -- module's print function
    local function Print(msg)
        if msg then
            core:Print(msg, "ComboPoints")
        end
    end

    local function SetupDatabase()
        if not DB then
            if type(core.char.SCP) ~= "table" or not next(core.char.SCP) then
                core.char.SCP = CopyTable(defaults)
            end
            DB = core.char.SCP
        end
    end

    -- //////////////////////////////////////////////////////////////

    -- initializes the frame
    function SCP_InitializeFrames()
        for i = 1, maxPoints do
            pointsFrame[i] = CreateFrame("Frame", "KPackSCPFrame" .. i, i == 1 and UIParent or pointsFrame[i - 1])
            pointsFrame[i]:SetBackdrop({
                bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
                edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
                tile = true,
                tileSize = 4,
                edgeSize = 4,
                insets = {left = 0.5, right = 0.5, top = 0.5, bottom = 0.5}
            })
        end
        SCP_UpdateFrames()
    end

    -- updates the combo points frames
    function SCP_UpdatePoints()
        if disabled then
            return
        end
        local power, i = GetComboPoints("player"), 1
        local r, g, b = DB.color.r, DB.color.g, DB.color.b
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
        if DB.combat then
            SCP_RefreshDisplay()
        end
    end

    -- updates the whole frame
    function SCP_UpdateFrames()
        local width = DB.width or 22
        local height = DB.height or 22
        local r, g, b = DB.color.r, DB.color.g, DB.color.b

        for i = 1, maxPoints do
            if pointsFrame[i] then
                pointsFrame[i]:SetSize(width, height)
                pointsFrame[i]:SetBackdropColor(r, g, b, 0.1)
                pointsFrame[i]:SetBackdropBorderColor(0, 0, 0, 1)

                if i == 1 then
                    pointsFrame[i]:SetPoint(DB.anchor, UIParent, DB.anchor, DB.xPos, DB.yPos)
                    pointsFrame[i]:SetScale(DB.scale)

                    pointsFrame[i]:SetMovable(true)
                    pointsFrame[i]:EnableMouse(true)
                    pointsFrame[i]:RegisterForDrag("LeftButton")

                    pointsFrame[i]:SetScript("OnDragStart", function(self)
                        if IsAltKeyDown() then
                            self:StartMoving()
                        end
                    end)
                    pointsFrame[i]:SetScript("OnDragStop", function(self)
                        self:StopMovingOrSizing()
                        DB.anchor, _, _, DB.xPos, DB.yPos = self:GetPoint(1)
                    end)
                else
                    pointsFrame[i]:SetPoint("RIGHT", width + 1 + (DB.spacing or 0), 0)
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

        if not InCombatLockdown() and GetComboPoints("player") == 0 and DB.combat then
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
            DB.color.r = r
            DB.color.g = g
            DB.color.b = b
            SCP_UpdateFrames()
        end
    end

    -- //////////////////////////////////////////////////////////////

    -- after the player enters the world
    core:RegisterForEvent("PLAYER_ENTERING_WORLD", function()
        if disabled then return end
        SetupDatabase()
        SCP_InitializeFrames()
        SCP_UpdatePoints()
        -- only for druids.
        if core.class == "DRUID" then
            UPDATE_SHAPESHIFT_FORM()
        end
    end)

    -- used to update combo points
    core:RegisterForEvent("UNIT_COMBO_POINTS", SCP_UpdatePoints)
    core:RegisterForEvent("PLAYER_REGEN_ENABLED", SCP_UpdatePoints)
    core:RegisterForEvent("PLAYER_TARGET_CHANGED", SCP_UpdatePoints)

    -- used only for druids
    function UPDATE_SHAPESHIFT_FORM()
        if disabled or core.class ~= "DRUID" then
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
    core:RegisterForEvent("UPDATE_SHAPESHIFT_FORM", UPDATE_SHAPESHIFT_FORM)

    -- //////////////////////////////////////////////////////////////

    -- slash commands handler
    local function SlashCommandHandler(txt)
        local cmd, msg = txt:match("^(%S*)%s*(.-)$")
        cmd, msg = cmd:lower(), msg:lower()

        -- enable or disable the module
        if cmd == "toggle" then
            -- reset settings
            DB.enabled = not DB.enabled
            SCP_DestroyFrames()
            if not DB.enabled then
                SCP_UpdateFrames()
            else
                SCP_InitializeFrames()
            end
        elseif cmd == "reset" then
            -- changing size
            wipe(DB)
            DB = defaults

            SCP_DestroyFrames()
            SCP_InitializeFrames()

            Print(L["module's settings reset to default."])
        elseif cmd == "width" or cmd == "height" and DB[cmd] ~= nil then
            -- scaling
            local num = tonumber(msg)
            if num then
                DB[cmd] = num
                SCP_UpdateFrames()
            else
                Print(L["The " .. cmd .. " must be a valid number"])
            end
        elseif cmd == "scale" then
            local scale = tonumber(msg)
            if scale then
                DB.scale = scale
                SCP_UpdateFrames()
            else
                Print(L["Scale has to be a number, recommended to be between 0.5 and 3"])
            end
        elseif cmd == "spacing" then
            -- changing color
            local spacing = tonumber(msg)
            if spacing then
                DB.spacing = spacing
                SCP_UpdateFrames()
            else
                Print(L["Spacing has to be a number, recommended to be between 0.5 and 3"])
            end
        elseif cmd == "color" or cmd == "colour" then
            -- toggle in and out of combat
            local r, g, b = DB.color.r, DB.color.g, DB.color.b
            ColorPickerFrame:SetColorRGB(r, g, b)
            ColorPickerFrame.previousValues = {r, g, b}
            ColorPickerFrame.func = SCP_ColorPickCallback
            ColorPickerFrame.opacityFunc = SCP_ColorPickCallback
            ColorPickerFrame.cancelFunc = SCP_ColorPickCallback
            ColorPickerFrame:Hide()
            ColorPickerFrame:Show()
        elseif cmd == "combat" or cmd == "nocombat" then
            -- otherwise, show commands help
            DB.combat = not DB.combat

            local status = (DB.combat == false)
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

    core:RegisterForEvent("PLAYER_LOGIN", function()
        if core.class ~= "ROGUE" and core.class ~= "DRUID" then
            disabled = true
            return
        end

        SetupDatabase()

        SlashCmdList["KPACKSCP"] = SlashCommandHandler
        SLASH_KPACKSCP1, SLASH_KPACKSCP2 = "/scp", "/simplecombopoints"

        local function _disabled()
            return not DB.enabled
        end

        core.options.args.options.args.scp = {
            type = "group",
            name = "Simple Combo Points",
            get = function(i)
                return DB[i[#i]]
            end,
            set = function(i, val)
                DB[i[#i]] = val
                SCP_DestroyFrames()
                SCP_InitializeFrames()
            end,
            args = {
                enabled = {
                    type = "toggle",
                    name = L["Enable"],
                    order = 1
                },
                combat = {
                    type = "toggle",
                    name = L["Hide out of combat"],
                    order = 2
                },
                width = {
                    type = "range",
                    name = L["Width"],
                    order = 3,
                    min = 10,
                    max = 50,
                    step = 0.1,
                    bigStep = 1
                },
                height = {
                    type = "range",
                    name = L["Height"],
                    order = 4,
                    min = 10,
                    max = 50,
                    step = 0.1,
                    bigStep = 1
                },
                scale = {
                    type = "range",
                    name = L["Scale"],
                    order = 5,
                    min = 0.5,
                    max = 3,
                    step = 0.01,
                    bigStep = 0.1
                },
                spacing = {
                    type = "range",
                    name = L["Spacing"],
                    order = 6,
                    min = 0,
                    max = 50,
                    step = 0.1,
                    bigStep = 1
                },
                color = {
                    type = "color",
                    name = L["Color"],
                    hasAlpha = false,
                    order = 7,
                    get = function()
                        return DB.color.r, DB.color.g, DB.color.b
                    end,
                    set = function(i, r, g, b)
                        DB.color.r, DB.color.g, DB.color.b = r, g, b
                        SCP_DestroyFrames()
                        SCP_InitializeFrames()
                    end
                },
                reset = {
                    type = "execute",
                    name = RESET,
                    order = 9,
                    width = "full",
                    confirm = function()
                        return L:F("Are you sure you want to reset %s to default?", "SimpleComboPoints")
                    end,
                    func = function()
                        wipe(DB)
                        DB = defaults
                        Print(L["module's settings reset to default."])
                        SCP_DestroyFrames()
                        SCP_InitializeFrames()
                    end
                }
            }
        }
    end)
end)