assert(KPack, "KPack not found!")
KPack:AddModule("Minimap", function(_, core, L)
    if core:IsDisabled("Minimap") then return end

    local DB, SetupDatabase
    local defaults = {
        enabled = true,
        locked = true,
        hide = false,
        scale = 1,
        combat = false,
        moved = false,
        point = "TOPRIGHT",
        x = 0,
        y = 0
    }
    local disabled

    -- cache frequently used globals
    local ToggleCharacter = ToggleCharacter
    local ToggleSpellBook = ToggleSpellBook
    local ToggleTalentFrame = ToggleTalentFrame
    local ToggleAchievementFrame = ToggleAchievementFrame
    local ToggleFriendsFrame = ToggleFriendsFrame
    local ToggleHelpFrame = ToggleHelpFrame
    local ToggleFrame = ToggleFrame
    local inCombat

    local PLAYER_ENTERING_WORLD

    -- function used to kill or replace other functions.
    local function noFunc()
    end

    local function Print(msg)
        if msg then
            core:Print(msg, "Minimap")
        end
    end

    local SlashCommandHandler
    do
        local exec = {}
        local help = "|cffffd700%s|r: %s"

        exec.enable = function()
            if not DB.enabled then
                DB.enabled = true
                Print(L:F("module status: %s", L["|cff00ff00enabled|r"]))
                Print(L["Please reload ui."])
                PLAYER_ENTERING_WORLD()
            end
        end
        exec.on = exec.enable

        exec.disable = function()
            if DB.enabled then
                DB.enabled = false
                Print(L:F("module status: %s", L["|cff00ff00enabled|r"]))
                Print(L["Please reload ui."])
                PLAYER_ENTERING_WORLD()
            end
        end
        exec.off = exec.disable

        exec.lock = function()
            if not DB.locked then
                DB.locked = true
                Print(L["minimap locked."])
                PLAYER_ENTERING_WORLD()
            end
        end

        exec.unlock = function()
            if DB.locked then
                DB.locked = false
                Print(L["minimap unlocked. Hold SHIFT+ALT to move it."])
                PLAYER_ENTERING_WORLD()
            end
        end

        exec.show = function()
            if DB.hide then
                DB.hide = false
                Print(L["minimap shown."])
                PLAYER_ENTERING_WORLD()
            end
        end

        exec.hide = function()
            if not DB.hide then
                DB.hide = true
                Print(L["minimap hidden."])
                PLAYER_ENTERING_WORLD()
            end
        end

        exec.combat = function()
            DB.combat = not DB.combat
            if DB.combat then
                Print(L:F("hide in combat: %s", L["|cff00ff00ON|r"]))
            else
                Print(L:F("hide in combat: %s", L["|cffff0000OFF|r"]))
                if not DB.hide and not MinimapCluster:IsShown() then
                    MinimapCluster:Show()
                end
            end
            PLAYER_ENTERING_WORLD()
        end

        exec.scale = function(n)
            n = tonumber(n)
            if n then
                DB.scale = n
                PLAYER_ENTERING_WORLD()
            end
        end

        exec.reset = function()
            -- moved? Put it back to its position
            if DB.moved then
                MinimapCluster:ClearAllPoints()
                MinimapCluster:SetPoint(defaults.point, defaults.x, defaults.y)
            end
            wipe(DB)
            DB = defaults
            Print(L["module's settings reset to default."])
            PLAYER_ENTERING_WORLD()
        end
        exec.defaults = exec.reset

        function SlashCommandHandler(msg)
            local cmd, rest = strsplit(" ", msg, 2)
            if type(exec[cmd]) == "function" then
                exec[cmd](rest)
            else
                Print(L:F("Acceptable commands for: |caaf49141%s|r", "/mm"))
                print(format(help, "enable", L["enable module"]))
                print(format(help, "disable", L["disable module"]))
                print(format(help, "show", L["show minimap"]))
                print(format(help, "hide", L["hide minimap"]))
                print(format(help, "combat", L["toggle hiding minimap in combat"]))
                print(format(help, "scale|r |cff00ffffn|r", L["change minimap scale"]))
                print(format(help, "lock", L["lock the minimap"]))
                print(format(help, "unlock", L["unlocks the minimap"]))
                print(format(help, "reset", L["Resets module settings to default."]))
                print(L["Once unlocked, the minimap can be moved by holding both SHIFT and ALT buttons."])
            end
        end
    end

    function SetupDatabase()
        if not DB then
            if type(core.db.Minimap) ~= "table" or not next(core.db.Minimap) then
                core.db.Minimap = CopyTable(defaults)
            end
            DB = core.db.Minimap
        end
    end

    core:RegisterForEvent("PLAYER_LOGIN", function()
        SetupDatabase()

        core.options.args.options.args.minimap = {
            type = "group",
            name = MINIMAP_LABEL,
            get = function(i)
                return DB[i[#i]]
            end,
            set = function(i, val)
                DB[i[#i]] = val
                PLAYER_ENTERING_WORLD()
            end,
            args = {
                enabled = {
                    type = "toggle",
                    name = L["Enable"],
                    order = 1
                },
                locked = {
                    type = "toggle",
                    name = L["Lock Minimap"],
                    order = 2
                },
                hide = {
                    type = "toggle",
                    name = L["Hide Minimap"],
                    order = 3
                },
                combat = {
                    type = "toggle",
                    name = L["Hide in combat"],
                    order = 4
                },
                scale = {
                    type = "range",
                    name = L["Scale"],
                    order = 5,
                    width = "full",
                    min = 0.5,
                    max = 3,
                    step = 0.01,
                    bigStep = 0.1
                },
                reset = {
                    type = "execute",
                    name = RESET,
                    order = 9,
                    width = "full",
                    confirm = function()
                        return L:F("Are you sure you want to reset %s to default?", MINIMAP_LABEL)
                    end,
                    func = function()
                        wipe(DB)
                        DB = defaults
                        Print(L["module's settings reset to default."])
                        PLAYER_ENTERING_WORLD()
                    end
                }
            }
        }
    end)

    do
        -- the dopdown menu frame
        local menuFrame

        -- menu list
        local menuList = {
            {
                text = CHARACTER_BUTTON,
                notCheckable = 1,
                func = function()
                    ToggleCharacter("PaperDollFrame")
                end
            },
            {
                text = SPELLBOOK_ABILITIES_BUTTON,
                notCheckable = 1,
                func = function()
                    ToggleFrame(SpellBookFrame)
                end
            },
            {
                text = TALENTS_BUTTON,
                notCheckable = 1,
                func = ToggleTalentFrame
            },
            {
                text = ACHIEVEMENT_BUTTON,
                notCheckable = 1,
                func = ToggleAchievementFrame
            },
            {
                text = QUESTLOG_BUTTON,
                notCheckable = 1,
                func = function()
                    ToggleFrame(QuestLogFrame)
                end
            },
            {
                text = SOCIAL_BUTTON,
                notCheckable = 1,
                func = function()
                    ToggleFriendsFrame(1)
                end
            },
            {
                text = L["Calendar"],
                notCheckable = 1,
                func = function()
                    GameTimeFrame:Click()
                end
            },
            {
                text = BATTLEFIELD_MINIMAP,
                notCheckable = 1,
                func = ToggleBattlefieldMinimap
            },
            {
                text = TIMEMANAGER_TITLE,
                notCheckable = 1,
                func = ToggleTimeManager
            },
            {
                text = PLAYER_V_PLAYER,
                notCheckable = 1,
                func = function()
                    ToggleFrame(PVPParentFrame)
                end
            },
            {
                text = LFG_TITLE,
                notCheckable = 1,
                func = function()
                    ToggleFrame(LFDParentFrame)
                end
            },
            {
                text = LOOKING_FOR_RAID,
                notCheckable = 1,
                func = function()
                    ToggleFrame(LFRParentFrame)
                end
            },
            {
                text = MAINMENU_BUTTON,
                notCheckable = 1,
                func = function()
                    if GameMenuFrame:IsShown() then
                        PlaySound("igMainMenuQuit")
                        HideUIPanel(GameMenuFrame)
                    else
                        PlaySound("igMainMenuOpen")
                        ShowUIPanel(GameMenuFrame)
                    end
                end
            },
            {
                text = HELP_BUTTON,
                notCheckable = 1,
                func = ToggleHelpFrame
            }
        }

        -- handles mouse wheel action on minimap
        local function Minimap_OnMouseWheel(self, z)
            local c = Minimap:GetZoom()
            if z > 0 and c < 5 then
                Minimap:SetZoom(c + 1)
            elseif (z < 0 and c > 0) then
                Minimap:SetZoom(c - 1)
            end
        end

        local function Cluster_OnMouseDown(self, button)
            if DB.lock then
                return
            end
            if IsAltKeyDown() and IsShiftKeyDown() and button == "LeftButton" then
                self:StartMoving()
            end
        end

        local function Cluster_OnMouseUp(self, button)
            if DB.lock then
                return
            end
            if button == "LeftButton" then
                self:StopMovingOrSizing()
                local point, _, _, xOfs, yOfs = self:GetPoint(1)
                DB.moved = true
                DB.point = point
                DB.x = xOfs
                DB.y = yOfs
            end
        end

        -- handle mouse clicks on minimap
        local function Minimap_OnMouseUp(self, button)
            -- create the menu frame
            menuFrame =
                menuFrame or CreateFrame("Frame", "KPack_MinimapRightClickMenu", UIParent, "UIDropDownMenuTemplate")

            if button == "RightButton" then
                EasyMenu(menuList, menuFrame, "cursor", 0, 0, "MENU", 2)
            elseif button == "MiddleButton" then
                ToggleDropDownMenu(1, nil, MiniMapTrackingDropDown, self)
            else
                Minimap_OnClick(self)
            end
        end

        -- called once the user enter the world
        function PLAYER_ENTERING_WORLD()
            if _G.SexyMap or _G.MinimapBar or not DB.enabled then
                disabled = true
                return
            end
            -- fix the stupid buff with MoveAnything Condolidate buffs
            if not (_G.MOVANY or _G.MovAny or core.MA) then
                ConsolidatedBuffs:SetParent(UIParent)
                ConsolidatedBuffs:ClearAllPoints()
                ConsolidatedBuffs:SetPoint("TOPRIGHT", -205, -13)
                ConsolidatedBuffs.SetPoint = noFunc
            end

            for i, v in pairs({
                MinimapBorder,
                MiniMapMailBorder,
                QueueStatusMinimapButtonBorder,
                -- select(1, TimeManagerClockButton:GetRegions()),
                select(1, GameTimeFrame:GetRegions())
            }) do
                v:SetVertexColor(.3, .3, .3)
            end

            MinimapBorderTop:Hide()
            MinimapZoomIn:Hide()
            MinimapZoomOut:Hide()
            MiniMapWorldMapButton:Hide()
            core:Kill(GameTimeFrame)
            core:Kill(MiniMapTracking)
            MinimapZoneText:SetPoint("TOPLEFT", "MinimapZoneTextButton", "TOPLEFT", 5, 5)
            Minimap:EnableMouseWheel(true)

            Minimap:SetScript("OnMouseWheel", Minimap_OnMouseWheel)
            Minimap:SetScript("OnMouseUp", Minimap_OnMouseUp)

            -- Make is square
            MinimapBorder:SetTexture(nil)
            Minimap:SetFrameLevel(2)
            Minimap:SetFrameStrata("BACKGROUND")
            Minimap:SetMaskTexture([[Interface\ChatFrame\ChatFrameBackground]])
            Minimap:SetBackdrop({
                bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
                insets = {top = -2, bottom = -2, left = -2, right = -2}
            })
            Minimap:SetBackdropColor(0, 0, 0, 1)
            MinimapCluster:SetScale(DB.scale or 1)

            if DB.hide then
                MinimapCluster:Hide()
            elseif not DB.combat and not inCombat then
                MinimapCluster:Show()
            end

            if DB.locked then
                MinimapCluster:SetMovable(false)
                MinimapCluster:SetClampedToScreen(false)
                MinimapCluster:RegisterForDrag(nil)
                MinimapCluster:SetScript("OnMouseDown", nil)
                MinimapCluster:SetScript("OnMouseUp", nil)
            else
                MinimapCluster:SetMovable(true)
                MinimapCluster:SetClampedToScreen(true)
                MinimapCluster:RegisterForDrag("LeftButton")
                MinimapCluster:SetScript("OnMouseDown", Cluster_OnMouseDown)
                MinimapCluster:SetScript("OnMouseUp", Cluster_OnMouseUp)
            end

            -- move to position
            if DB.moved then
                MinimapCluster:ClearAllPoints()
                MinimapCluster:SetPoint(DB.point, DB.x, DB.y)
                MinimapCluster.SetPoint = function()
                end
            end
        end
        core:RegisterForEvent("PLAYER_ENTERING_WORLD", PLAYER_ENTERING_WORLD)
    end

    core:RegisterForEvent("PLAYER_REGEN_ENABLED", function()
        inCombat = false
        if not disabled and DB.enabled and DB.combat and not MinimapCluster:IsShown() and not DB.hide then
            MinimapCluster:Show()
        end
    end)

    core:RegisterForEvent("PLAYER_REGEN_DISABLED", function()
        inCombat = true
        if not disabled and DB.enabled and DB.combat and MinimapCluster:IsShown() then
            MinimapCluster:Hide()
        end
    end)

    SlashCmdList["KPACKMINIMAP"] = SlashCommandHandler
    SLASH_KPACKMINIMAP1, SLASH_KPACKMINIMAP2 = "/minimap", "/mm"

    local pinger, timer
    local frame = CreateFrame("Frame")
    core:RegisterForEvent("MINIMAP_PING", function(_, unit, coordx, coordy)
        if UnitName(unit) ~= core.name then
            -- create the pinger
            if not pinger then
                pinger = frame:CreateFontString(nil, "OVERLAY")
                pinger:SetFont("Fonts\\FRIZQT__.ttf", 13, "OUTLINE")
                pinger:SetPoint("CENTER", Minimap, "CENTER", 0, 0)
                pinger:SetJustifyH("CENTER")
            end

            if timer and time() - timer > 1 or not timer then
                local Class = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS[select(2, UnitClass(unit))]
                pinger:SetText(format("|cffff0000*|r %s |cffff0000*|r", UnitName(unit)))
                pinger:SetTextColor(Class.r, Class.g, Class.b)
                UIFrameFlash(frame, 0.2, 2.8, 5, false, 0, 5)
                timer = time()
            end
        end
    end)

    local taint = CreateFrame("Frame")
    taint:RegisterEvent("PLAYER_ENTERING_WORLD")
    taint:SetScript("OnEvent", function(self)
        ToggleFrame(SpellBookFrame)
        ToggleFrame(SpellBookFrame)
    end)
end)