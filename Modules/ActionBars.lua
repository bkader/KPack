assert(KPack, "KPack not found!")
KPack:AddModule("ActionBars", "Allows you to tweak your action bars in the limit of the allowed.", function(_, core, L)
    if core:IsDisabled("ActionBars") then return end

    local mod = core.ActionBars or {}
    core.ActionBars = mod
    LibStub("AceHook-3.0"):Embed(mod)

    local _LoadAddOn = LoadAddOn
    local _IsActionInRange = IsActionInRange
    local _InCombatLockdown = InCombatLockdown
    local _UnitAffectingCombat = UnitAffectingCombat
    local _UnitInVehicle = UnitInVehicle

    local _UnitLevel = UnitLevel
    local _IsXPUserDisabled = IsXPUserDisabled
    local _GetWatchedFactionInfo = GetWatchedFactionInfo
    local _TextStatusBar_UpdateTextString = TextStatusBar_UpdateTextString
    local _MainMenuExpBar_Update = MainMenuExpBar_Update
    local _UIParent_ManageFramePositions = UIParent_ManageFramePositions

    local _pairs, _ipairs, _type, _next = pairs, ipairs, type, next
    local _format, _match, _tostring, _tonumber = string.format, string.match, tostring, tonumber
    local math_min, math__max, _select = math.min, math.max, select
    local _SetCVar, _GetCVar = SetCVar, GetCVar

    local DB
    local defaults = {
        scale = 1,
        dark = true,
        range = true,
        art = true,
        hotkeys = 1,
        hover = false
    }
    local disabled
    local LoadSettings

    -- module's print function
    local function Print(msg)
        if msg then
            core:Print(msg, "ActionBars")
        end
    end

    -- used to kill functions
    local function noFunc()
        return
    end

    -- utility functions used to show/hide a frame only if it exists
    local function Show(frame)
        if frame and frame.Show then
            frame:Show()
        end
    end
    local function Hide(frame)
        if frame and frame.Hide then
            frame:Hide()
        end
    end
    local function ShowHide(frame, cond)
        if not frame or not frame.Show then
            return
        elseif cond and not frame:IsShown() then
            frame:Show()
        elseif not cond and frame:IsShown() then
            frame:Hide()
        end
    end

    --
    -- scales action bar elements
    --
    local function ActionBars_ScaleBars(scale)
        DB = DB or core.db.ActionBars or {}
        scale = scale or DB.scale or 1
        _G.MainMenuBar:SetScale(scale)
        _G.MultiBarBottomLeft:SetScale(scale)
        _G.MultiBarBottomRight:SetScale(scale)
        _G.MultiBarRight:SetScale(scale)
        _G.MultiBarLeft:SetScale(scale)
        _G.VehicleMenuBar:SetScale(scale)
    end

    --
    -- Dark mode
    --
    local function ActionBars_DarkMode()
        local vertex = DB.dark and 0.32 or 1.00
        for i, v in pairs(
            {
                -- UnitFrames
                PlayerFrameTexture,
                TargetFrameTextureFrameTexture,
                PetFrameTexture,
                PartyMemberFrame1Texture,
                PartyMemberFrame2Texture,
                PartyMemberFrame3Texture,
                PartyMemberFrame4Texture,
                PartyMemberFrame1PetFrameTexture,
                PartyMemberFrame2PetFrameTexture,
                PartyMemberFrame3PetFrameTexture,
                PartyMemberFrame4PetFrameTexture,
                FocusFrameTextureFrameTexture,
                TargetFrameToTTextureFrameTexture,
                FocusFrameToTTextureFrameTexture,
                Boss1TargetFrameTextureFrameTexture,
                Boss2TargetFrameTextureFrameTexture,
                Boss3TargetFrameTextureFrameTexture,
                Boss4TargetFrameTextureFrameTexture,
                Boss5TargetFrameTextureFrameTexture,
                Boss1TargetFrameSpellBarBorder,
                Boss2TargetFrameSpellBarBorder,
                Boss3TargetFrameSpellBarBorder,
                Boss4TargetFrameSpellBarBorder,
                Boss5TargetFrameSpellBarBorder,
                RuneButtonIndividual1BorderTexture,
                RuneButtonIndividual2BorderTexture,
                RuneButtonIndividual3BorderTexture,
                RuneButtonIndividual4BorderTexture,
                RuneButtonIndividual5BorderTexture,
                RuneButtonIndividual6BorderTexture,
                CastingBarFrameBorder,
                FocusFrameSpellBarBorder,
                TargetFrameSpellBarBorder,
                -- MainMenuBar
                SlidingActionBarTexture0,
                SlidingActionBarTexture1,
                BonusActionBarTexture0,
                BonusActionBarTexture1,
                BonusActionBarTexture,
                MainMenuBarTexture0,
                MainMenuBarTexture1,
                MainMenuBarTexture2,
                MainMenuBarTexture3,
                MainMenuMaxLevelBar0,
                MainMenuMaxLevelBar1,
                MainMenuMaxLevelBar2,
                MainMenuMaxLevelBar3,
                MainMenuXPBarTextureLeftCap,
                MainMenuXPBarTextureRightCap,
                MainMenuXPBarTextureMid,
                ReputationWatchBarTexture0,
                ReputationWatchBarTexture1,
                ReputationWatchBarTexture2,
                ReputationWatchBarTexture3,
                ReputationXPBarTexture0,
                ReputationXPBarTexture1,
                ReputationXPBarTexture2,
                ReputationXPBarTexture3,
                MainMenuBarLeftEndCap,
                MainMenuBarRightEndCap,
                StanceBarLeft,
                StanceBarMiddle,
                StanceBarRight,
                -- ArenaFrames
                -- ActionBarUpButton:GetNormalTexture(),
                -- ActionBarUpButton:GetPushedTexture(),
                -- ActionBarUpButton:GetHighlightTexture(),
                -- ActionBarDownButton:GetNormalTexture(),
                -- ActionBarDownButton:GetPushedTexture(),
                -- ActionBarDownButton:GetHighlightTexture(),
                ShapeshiftBarLeft,
                ShapeshiftBarMiddle,
                ShapeshiftBarRight,
                ArenaEnemyFrame1Texture,
                ArenaEnemyFrame2Texture,
                ArenaEnemyFrame3Texture,
                ArenaEnemyFrame4Texture,
                ArenaEnemyFrame5Texture,
                ArenaEnemyFrame1SpecBorder,
                ArenaEnemyFrame2SpecBorder,
                ArenaEnemyFrame3SpecBorder,
                ArenaEnemyFrame4SpecBorder,
                ArenaEnemyFrame5SpecBorder,
                ArenaEnemyFrame1PetFrameTexture,
                ArenaEnemyFrame2PetFrameTexture,
                ArenaEnemyFrame3PetFrameTexture,
                ArenaEnemyFrame4PetFrameTexture,
                ArenaEnemyFrame5PetFrameTexture,
                ArenaPrepFrame1Texture,
                ArenaPrepFrame2Texture,
                ArenaPrepFrame3Texture,
                ArenaPrepFrame4Texture,
                ArenaPrepFrame5Texture,
                ArenaPrepFrame1SpecBorder,
                ArenaPrepFrame2SpecBorder,
                ArenaPrepFrame3SpecBorder,
                ArenaPrepFrame4SpecBorder,
                ArenaPrepFrame5SpecBorder,
                -- PANES
                CharacterFrameTitleBg,
                CharacterFrameBg,
                -- MINIMAP
                MinimapBorder,
                MinimapBorderTop,
                MiniMapTrackingButtonBorder
            }
        ) do
            v:SetVertexColor(vertex, vertex, vertex)
        end
    end

    --
    -- turns button red if target out of range
    --
    local ActionBars_Range
    do
        function mod:ActionButton_OnEvent(btn, event, ...)
            if event == "PLAYER_TARGET_CHANGED" or event == "UPDATE_MOUSEOVER_UNIT" then
                btn.newTimer = btn.rangeTimer
            end
        end

        function mod:ActionButton_UpdateUsable(btn)
            local icon = _G[btn:GetName() .. "Icon"]
            local valid = _IsActionInRange(btn.action)
            if valid == 0 then
                icon:SetVertexColor(1.0, 0.1, 0.1)
            end
        end

        function mod:ActionButton_OnUpdate(btn, elapsed)
            local rangeTimer = btn.newTimer
            if rangeTimer then
                rangeTimer = rangeTimer - elapsed
                if rangeTimer <= 0 then
                    mod:ActionButton_UpdateUsable(btn)
                    rangeTimer = _G.TOOLTIP_UPDATE_TIME
                end
                btn.newTimer = rangeTimer
            end
        end

        function ActionBars_Range()
            if DB.range == true and not mod:IsHooked("ActionButton_OnEvent") then
                mod:SecureHook("ActionButton_OnEvent")
                mod:SecureHook("ActionButton_UpdateUsable")
                mod:SecureHook("ActionButton_OnUpdate")
            elseif not DB.range and mod:IsHooked("ActionButton_OnEvent") then
                mod:UnhookAll()
            end
        end
    end

    --
    -- handle hiding/showing action bar gryphons
    --
    local function ActionBars_Gryphons()
        if DB.art then
            _G.MainMenuBarLeftEndCap:Hide()
            _G.MainMenuBarRightEndCap:Hide()
        else
            _G.MainMenuBarLeftEndCap:Show()
            _G.MainMenuBarRightEndCap:Show()
        end
    end

    local function ActionBars_Hotkeys(opacity)
        opacity = opacity or DB.hotkeys or 1
        local mopacity = opacity / 1.2 -- macro name opacity
        for i = 1, 12 do
            _G["ActionButton" .. i .. "HotKey"]:SetAlpha(opacity)
            _G["MultiBarBottomRightButton" .. i .. "HotKey"]:SetAlpha(opacity)
            _G["MultiBarBottomLeftButton" .. i .. "HotKey"]:SetAlpha(opacity)
            _G["MultiBarRightButton" .. i .. "HotKey"]:SetAlpha(opacity)
            _G["MultiBarLeftButton" .. i .. "HotKey"]:SetAlpha(opacity)

            _G["ActionButton" .. i .. "Name"]:SetAlpha(mopacity)
            _G["MultiBarBottomRightButton" .. i .. "Name"]:SetAlpha(mopacity)
            _G["MultiBarBottomLeftButton" .. i .. "Name"]:SetAlpha(mopacity)
            _G["MultiBarRightButton" .. i .. "Name"]:SetAlpha(mopacity)
            _G["MultiBarLeftButton" .. i .. "Name"]:SetAlpha(mopacity)
        end
    end

    --
    -- mouseover right action bars
    --
    local ActionBars_MouseOver
    do
        local function MouseOver_OnUpdate(self, elapsed)
            self.lastUpdate = self.lastUpdate + elapsed
            if self.lastUpdate > 0.5 then
                self:SetAlpha(MouseIsOver(self) and 1 or 0)
            end
        end

        function ActionBars_MouseOver()
            if DB.hover == true then
                for _, frame in _ipairs({MultiBarLeft, MultiBarRight}) do
                    if frame:IsShown() then
                        frame.lastUpdate = 0
                        frame:SetScript("OnUpdate", MouseOver_OnUpdate)
                    else
                        frame:SetScript("OnUpdate", nil)
                    end
                end
            else
                for _, frame in _ipairs({MultiBarLeft, MultiBarRight}) do
                    if frame:IsShown() and frame.lastUpdate then
                        frame.lastUpdate = nil
                        frame:SetScript("OnUpdate", nil)
                        frame:SetAlpha(1)
                    end
                end
            end
        end
    end

    -- ========================================================== --

    local options = {
        type = "group",
        name = "ActionBars",
        get = function(i)
            return DB[i[#i]]
        end,
        set = function(i, val)
            DB[i[#i]] = val
            LoadSettings()
        end,
        args = {
            art = {
                type = "toggle",
                name = L["Hide Gryphons"],
                order = 1,
                set = function(_, val)
                    DB.art = val
                    ActionBars_Gryphons()
                end
            },
            range = {
                type = "toggle",
                name = L["Range Detection"],
                desc = L["Turns your buttons red if your target is out of range."],
                order = 2
            },
            dark = {
                type = "toggle",
                name = L["Dark Mode"],
                order = 3
            },
            hover = {
                type = "toggle",
                name = L["Hover Mode"],
                desc = L["Shows your right action bars on hover."],
                order = 4
            },
            scale = {
                type = "range",
                name = L["Scale"],
                desc = L["Changes action bars scale"],
                order = 7,
                width = "full",
                min = 0.5,
                max = 3,
                step = 0.01,
                bigStep = 0.1
            },
            hotkeys = {
                type = "range",
                name = L["Hotkeys"],
                desc = L["Changes the opacity of action bar hotkeys."],
                order = 8,
                width = "full",
                min = 0,
                max = 1,
                step = 0.01,
                bigStep = 0.1
            },
            reset = {
                type = "execute",
                name = RESET,
                order = 9,
                width = "full",
                confirm = function()
                    return L:F("Are you sure you want to reset %s to default?", "Automate")
                end,
                func = function()
                    wipe(DB)
                    DB = defaults
                    Print(L["module's settings reset to default."])
                    LoadSettings()
                end
            }
        }
    }

    local function SetupDatabase()
        if not DB then
            if type(core.db.ActionBars) ~= "table" or not next(core.db.ActionBars) then
                core.db.ActionBars = CopyTable(defaults)
            end
            DB = core.db.ActionBars
        end
    end

	core:RegisterForEvent("PLAYER_LOGIN", function()
        SetupDatabase()

        -- if we are using an action bars addon, better skip.
        for _, n in _ipairs({"Dominos", "Bartender4", "MiniMainBar", "ElvUI", "KActionBars"}) do
            if _G[n] then
                disabled = true
                return
            end
        end

        SLASH_KPACKABM1 = "/abm"
        SlashCmdList.KPACKABM = function()
            return core:OpenConfig("ActionBars")
        end
        core.options.args.options.args.ActionBars = options
    end)

    function LoadSettings()
        SetupDatabase()
        ActionBars_Gryphons()
        ActionBars_Range()
        ActionBars_DarkMode()
        ActionBars_MouseOver()
        ActionBars_ScaleBars()
        ActionBars_Hotkeys()
    end

    core:RegisterForEvent("PLAYER_ENTERING_WORLD", function()
        if not disabled then
            LoadSettings()
        end
    end)
end)