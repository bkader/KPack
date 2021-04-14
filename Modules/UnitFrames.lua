assert(KPack, "KPack not found!")
KPack:AddModule("UnitFrames", "Improve the standard blizzard unitframes without going beyond the boundaries set by them.", function(_, core, L)
    if core:IsDisabled("UnitFrames") then return end

    -- Setup some locals
    local KPack_UnitFrames_PlayerFrame_IsMoving = false
    local KPack_UnitFrames_TargetFrame_IsMoving = false

    local StaticPopup_Show = StaticPopup_Show

    local UnitColor
    local GetCVar, GetCVarBool = GetCVar, GetCVarBool
    local InCombatLockdown = InCombatLockdown
    local UnitClass = UnitClass
    local UnitClassification = UnitClassification
    local UnitExists = UnitExists
    local UnitGUID = UnitGUID
    local UnitIsConnected = UnitIsConnected
    local UnitIsDeadOrGhost = UnitIsDeadOrGhost
    local UnitIsEnemy = UnitIsEnemy
    local UnitIsFriend = UnitIsFriend
    local UnitIsPlayer = UnitIsPlayer
    local UnitIsPVP = UnitIsPVP
    local UnitIsPVPFreeForAll = UnitIsPVPFreeForAll
    local UnitIsTapped = UnitIsTapped
    local UnitIsTappedByAllThreatList = UnitIsTappedByAllThreatList
    local UnitIsTappedByPlayer = UnitIsTappedByPlayer
    local UnitPlayerControlled = UnitPlayerControlled
    local UnitSelectionColor = UnitSelectionColor

    local tinsert, tgetn = table.insert, table.getn
    local strgmatch, strsub, strlower = string.gmatch, string.sub, string.lower
    local ceil, format, tonumber, tostring = math.ceil, string.format, tonumber, tostring

    -- prepare our functions.
    local Print, Tokenize
    local KPack_UnitFrames_Enable
    local KPack_UnitFrames_BossTargetFrame_Show
    local KPack_UnitFrames_CapDisplayOfNumericValue
    local KPack_UnitFrames_FocusFrame_SetSmallSize
    local KPack_UnitFrames_FocusFrame_Show
    local KPack_UnitFrames_LoadDefaultSettings
    local KPack_UnitFrames_PlayerFrame_OnMouseDown
    local KPack_UnitFrames_PlayerFrame_OnMouseUp
    local KPack_UnitFrames_PlayerFrame_ToPlayerArt
    local KPack_UnitFrames_PlayerFrame_ToVehicleArt
    local KPack_UnitFrames_SetFrameScale
    local KPack_UnitFrames_Style_PlayerFrame
    local KPack_UnitFrames_TargetFrame_CheckClassification
    local KPack_UnitFrames_TargetFrame_CheckFaction
    local KPack_UnitFrames_TargetFrame_OnMouseDown
    local KPack_UnitFrames_TargetFrame_OnMouseUp
    local KPack_UnitFrames_TargetFrame_Update
    local KPack_UnitFrames_TextStatusBar_UpdateTextString

    local DB
    local defaults = {
        scale = 1,
        player = {x = -19, y = -4, point = "TOPLEFT", locked = true, moved = false},
        target = {x = 250, y = -4, point = "TOPLEFT", locked = true, moved = false}
    }

    -- Debug function. Adds message to the chatbox (only visible to the loacl player)
    function Print(msg)
        if msg then
            core:Print(msg, "UnitFrames")
        end
    end

    function Tokenize(str)
        local tbl = {}
        for v in strgmatch(str, "[^ ]+") do
            tinsert(tbl, v)
        end
        return tbl
    end

    function KPack_UnitFrames_ApplySettings(settings)
        settings = settings or DB
        KPack_UnitFrames_SetFrameScale(settings.scale)

        if settings.player.moved == true then
            PlayerFrame:ClearAllPoints()
            PlayerFrame:SetPoint(settings.player.point, settings.player.x, settings.player.y)
        end

        if settings.target.moved == true then
            TargetFrame:ClearAllPoints()
            TargetFrame:SetPoint(settings.target.point, settings.target.x, settings.target.y)
        end
    end

    function KPack_UnitFrames_LoadDefaultSettings()
        if type(core.char.UnitFrames) ~= "table" or not next(core.char.UnitFrames) then
            core.char.UnitFrames = CopyTable(defaults)
        end
        DB = core.char.UnitFrames
    end

    function KPack_UnitFrames_Enable()
        -- Generic status text hook and instantly update player
        hooksecurefunc("TextStatusBar_UpdateTextString", KPack_UnitFrames_TextStatusBar_UpdateTextString)
        KPack_UnitFrames_TextStatusBar_UpdateTextString(PlayerFrameHealthBar)
        KPack_UnitFrames_TextStatusBar_UpdateTextString(PlayerFrameManaBar)

        -- Hook PlayerFrame functions
        hooksecurefunc("PlayerFrame_ToPlayerArt", KPack_UnitFrames_PlayerFrame_ToPlayerArt)
        hooksecurefunc("PlayerFrame_ToVehicleArt", KPack_UnitFrames_PlayerFrame_ToVehicleArt)
        PlayerFrame:SetScript("OnMouseDown", KPack_UnitFrames_PlayerFrame_OnMouseDown)
        PlayerFrame:SetScript("OnMouseUp", KPack_UnitFrames_PlayerFrame_OnMouseUp)
        PlayerFrameHealthBar.capNumericDisplay = true

        -- Set up some stylings
        KPack_UnitFrames_Style_PlayerFrame()
        PlayerFrameHealthBar.lockColor = true

        -- Hook TargetFrame functions
        hooksecurefunc("TargetFrame_Update", KPack_UnitFrames_TargetFrame_Update)
        hooksecurefunc("TargetFrame_CheckFaction", KPack_UnitFrames_TargetFrame_CheckFaction)
        hooksecurefunc("TargetFrame_CheckClassification", KPack_UnitFrames_TargetFrame_CheckClassification)
        TargetFrame:SetMovable(true) -- make sure to make it movable.
        TargetFrame:SetScript("OnMouseDown", KPack_UnitFrames_TargetFrame_OnMouseDown)
        TargetFrame:SetScript("OnMouseUp", KPack_UnitFrames_TargetFrame_OnMouseUp)

        -- FocusFrame hooks
        hooksecurefunc("FocusFrame_SetSmallSize", KPack_UnitFrames_FocusFrame_SetSmallSize)
        hooksecurefunc(FocusFrame, "Show", KPack_UnitFrames_FocusFrame_Show)

        -- BossFrame hooks
        hooksecurefunc(Boss1TargetFrame, "Show", KPack_UnitFrames_BossTargetFrame_Show)
        hooksecurefunc(Boss2TargetFrame, "Show", KPack_UnitFrames_BossTargetFrame_Show)
        hooksecurefunc(Boss3TargetFrame, "Show", KPack_UnitFrames_BossTargetFrame_Show)
    end

    function KPack_UnitFrames_Style_PlayerFrame()
        PlayerFrameHealthBar:SetWidth(119)
        PlayerFrameHealthBar:SetHeight(29)
        PlayerFrameHealthBar:SetPoint("TOPLEFT", 106, -22)
        PlayerFrameHealthBarText:SetPoint("CENTER", 50, 6)
        PlayerFrameTexture:SetTexture("Interface\\AddOns\\KPack\\Media\\UnitFrames\\UI-TargetingFrame")
        PlayerStatusTexture:SetTexture("Interface\\AddOns\\KPack\\Media\\UnitFrames\\UI-Player-Status")
        PlayerFrameHealthBar:SetStatusBarColor(UnitColor("player"))
    end

    function KPack_UnitFrames_SetFrameScale(scale)
        PlayerFrame:SetScale(scale)
        TargetFrame:SetScale(scale)
        FocusFrame:SetScale(scale)
        Boss1TargetFrame:SetScale(scale * 0.9)
        Boss2TargetFrame:SetScale(scale * 0.9)
        Boss3TargetFrame:SetScale(scale * 0.9)

        DB.scale = scale
    end

    -- Slashcommand stuff
    SLASH_UNITFRAMESIMPROVED1 = "/uf"
    SLASH_UNITFRAMESIMPROVED2 = "/ufi"
    SlashCmdList["UNITFRAMESIMPROVED"] = function(msg)
        local cmd, rest = strsplit(" ", msg, 2)
        cmd = strlower(cmd)

        if cmd == "scale" then
            local scale = tonumber(rest)
            if scale and scale ~= DB.scale and (scale >= 0.5 and scale <= 3) then
                KPack_UnitFrames_SetFrameScale(scale)
            elseif scale then
                Print(L["Scale has to be a number, recommended to be between 0.5 and 3"])
            end
        elseif cmd == "reset" or cmd == "default" then
            StaticPopup_Show("LAYOUT_RESET")
        else
            Print(L:F("Acceptable commands for: |caaf49141%s|r", "/uf"))
            local helpStr = "|cffffd700%s|r: %s"
            print(helpStr:format("scale |cff00ffffn|r", L["changes the unit frames scale."]))
            print(helpStr:format("reset", L["Resets module settings to default."]))
            print(L["To move the player and target, hold SHIFT and ALT while dragging them around."])
        end
    end

    -- Setup the static popup dialog for resetting the UI
    StaticPopupDialogs["LAYOUT_RESET"] = {
        preferredIndex = 4,
        text = "Are you sure you want to reset your layout?\nThis will automatically reload the UI.",
        button1 = YES,
        button2 = NO,
        OnAccept = function()
            PlayerFrame:SetUserPlaced(false)
            TargetFrame:SetUserPlaced(false)
            core.char.UnitFrames = nil
            DB = nil
            KPack_UnitFrames_LoadDefaultSettings()
            ReloadUI()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true
    }

    -- Overloaded functions from Blizzard Unitframes Code
    function KPack_UnitFrames_PlayerFrame_OnMouseDown(self, button)
        if IsShiftKeyDown() and IsAltKeyDown() and button == "LeftButton" then
            KPack_UnitFrames_PlayerFrame_IsMoving = true
            PlayerFrame:SetUserPlaced(true)
            PlayerFrame:StartMoving()
        end
    end

    function KPack_UnitFrames_PlayerFrame_OnMouseUp(self, button)
        if KPack_UnitFrames_PlayerFrame_IsMoving == true and button == "LeftButton" then
            KPack_UnitFrames_PlayerFrame_IsMoving = false
            PlayerFrame:StopMovingOrSizing()

            local point, _, _, xOffset, yOffset = PlayerFrame:GetPoint(1)
            DB.player.moved = true
            DB.player.point = point
            DB.player.x = xOffset
            DB.player.y = yOffset
            return
        end
    end

    -- Overloaded functions from Blizzard Unitframes Code
    function KPack_UnitFrames_TargetFrame_OnMouseDown(self, button)
        if IsShiftKeyDown() and IsAltKeyDown() and button == "LeftButton" then
            KPack_UnitFrames_TargetFrame_IsMoving = true
            TargetFrame:SetUserPlaced(true)
            TargetFrame:StartMoving()
        end
    end

    function KPack_UnitFrames_TargetFrame_OnMouseUp(self, button)
        if KPack_UnitFrames_TargetFrame_IsMoving == true and button == "LeftButton" then
            KPack_UnitFrames_TargetFrame_IsMoving = false
            TargetFrame:StopMovingOrSizing()

            local point, _, _, xOffset, yOffset = TargetFrame:GetPoint(1)
            DB.target.moved = true
            DB.target.point = point
            DB.target.x = xOffset
            DB.target.y = yOffset
        end
    end

    function KPack_UnitFrames_TextStatusBar_UpdateTextString(textStatusBar)
        local textString = textStatusBar.TextString
        if textString then
            local value = textStatusBar:GetValue()
            local valueMin, valueMax = textStatusBar:GetMinMaxValues()

            if (tonumber(valueMax) ~= valueMax or valueMax > 0) and not (textStatusBar.pauseUpdates) then
                textStatusBar:Show()
                if value and valueMax > 0 and (GetCVarBool("statusTextPercentage") or textStatusBar.showPercentage) and not textStatusBar.showNumeric then
                    if value == 0 and textStatusBar.zeroText then
                        textString:SetText(textStatusBar.zeroText)
                        textStatusBar.isZero = 1
                        textString:Show()
                        return
                    end

                    value = format("%02.1f%%", 100 * value / valueMax)
                    if textStatusBar.prefix and (textStatusBar.alwaysPrefix or not (textStatusBar.cvar and GetCVar(textStatusBar.cvar) == "1" and textStatusBar.textLockable)) then
                        textString:SetText(textStatusBar.prefix .. " " .. KPack_UnitFrames_CapDisplayOfNumericValue(textStatusBar:GetValue()) .. " (" .. value .. ")")
                    else
                        textString:SetText(KPack_UnitFrames_CapDisplayOfNumericValue(textStatusBar:GetValue()) .. " (" .. value .. ")")
                    end
                elseif value == 0 and textStatusBar.zeroText then
                    textString:SetText(textStatusBar.zeroText)
                    textStatusBar.isZero = 1
                    textString:Show()
                    return
                else
                    textStatusBar.isZero = nil
                    if textStatusBar.capNumericDisplay then
                        value = KPack_UnitFrames_CapDisplayOfNumericValue(value)
                        valueMax = KPack_UnitFrames_CapDisplayOfNumericValue(valueMax)
                    end
                    if textStatusBar.prefix and (textStatusBar.alwaysPrefix or not (textStatusBar.cvar and GetCVar(textStatusBar.cvar) == "1" and textStatusBar.textLockable)) then
                        textString:SetText(textStatusBar.prefix .. " " .. value .. "/" .. valueMax)
                    else
                        textString:SetText(value .. "/" .. valueMax)
                    end
                end

                if (textStatusBar.cvar and GetCVar(textStatusBar.cvar) == "1" and textStatusBar.textLockable) or textStatusBar.forceShow then
                    textString:Show()
                elseif textStatusBar.lockShow > 0 and (not textStatusBar.forceHideText) then
                    textString:Show()
                else
                    textString:Hide()
                end
            else
                textString:Hide()
                textString:SetText("")
                if not textStatusBar.alwaysShow then
                    textStatusBar:Hide()
                else
                    textStatusBar:SetValue(0)
                end
            end
        end
    end

    function KPack_UnitFrames_PlayerFrame_ToPlayerArt(self)
        KPack_UnitFrames_Style_PlayerFrame()
        if DB.player.moved == true then
            core.After(0.35, function()
                PlayerFrame:ClearAllPoints()
                PlayerFrame:SetPoint(DB.player.point, DB.player.x, DB.player.y)
            end)
        end
    end

    function KPack_UnitFrames_PlayerFrame_ToVehicleArt(self)
        PlayerFrameHealthBar:SetHeight(12)
        PlayerFrameHealthBarText:SetPoint("CENTER", 50, 3)
        if DB.player.moved == true then
            core.After(0.35, function()
                PlayerFrame:ClearAllPoints()
                PlayerFrame:SetPoint(DB.player.point, DB.player.x, DB.player.y)
            end)
        end
    end

    function KPack_UnitFrames_TargetFrame_Update(self)
        local thisName = self:GetName()

        -- Layout elements
        self.healthbar.lockColor = true
        self.healthbar:SetWidth(119)
        self.healthbar:SetHeight(29)
        self.healthbar:SetPoint("TOPLEFT", 7, -22)
        _G[thisName .. "TextureFrameHealthBarText"]:SetPoint("CENTER", -50, 6)
        self.deadText:SetPoint("CENTER", -50, 6)
        self.nameBackground:Hide()

        -- Set back color of health bar
        if not UnitPlayerControlled(self.unit) and UnitIsTapped(self.unit) and not UnitIsTappedByPlayer(self.unit) and not UnitIsTappedByAllThreatList(self.unit) then
            -- Gray if npc is tapped by other player
            self.healthbar:SetStatusBarColor(0.5, 0.5, 0.5)
        else
            -- Standard by class etc if not
            self.healthbar:SetStatusBarColor(UnitColor(self.healthbar.unit))
        end
    end

    function KPack_UnitFrames_TargetFrame_CheckClassification(self, forceNormalTexture)
        local texture
        local classification = UnitClassification(self.unit)
        if classification == "worldboss" or classification == "elite" then
            texture = "Interface\\AddOns\\KPack\\Media\\UnitFrames\\UI-TargetingFrame-Elite"
        elseif classification == "rareelite" then
            texture = "Interface\\AddOns\\KPack\\Media\\UnitFrames\\UI-TargetingFrame-Rare-Elite"
        elseif classification == "rare" then
            texture = "Interface\\AddOns\\KPack\\Media\\UnitFrames\\UI-TargetingFrame-Rare"
        end
        if texture and not forceNormalTexture then
            self.borderTexture:SetTexture(texture)
        else
            self.borderTexture:SetTexture("Interface\\AddOns\\KPack\\Media\\UnitFrames\\UI-TargetingFrame")
        end
    end

    function KPack_UnitFrames_TargetFrame_CheckFaction(self)
        local factionGroup = UnitFactionGroup(self.unit)
        if UnitIsPVPFreeForAll(self.unit) then
            self.pvpIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-FFA")
            self.pvpIcon:Show()
        elseif factionGroup and UnitIsPVP(self.unit) and UnitIsEnemy("player", self.unit) then
            self.pvpIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-FFA")
            self.pvpIcon:Show()
        elseif factionGroup then
            self.pvpIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-" .. factionGroup)
            self.pvpIcon:Show()
        else
            self.pvpIcon:Hide()
        end

        -- Set back color of health bar
        if
            not UnitPlayerControlled(self.unit) and UnitIsTapped(self.unit) and not UnitIsTappedByPlayer(self.unit) and
                not UnitIsTappedByAllThreatList(self.unit)
         then
            -- Gray if npc is tapped by other player
            self.healthbar:SetStatusBarColor(0.5, 0.5, 0.5)
        else
            -- Standard by class etc if not
            self.healthbar:SetStatusBarColor(UnitColor(self.healthbar.unit))
        end
    end

    function KPack_UnitFrames_BossTargetFrame_Show(self)
        self.borderTexture:SetTexture("Interface\\AddOns\\KPack\\Media\\UnitFrames\\UI-UnitFrame-Boss")

        if not (DB.scale == nil) then
            self:SetScale(DB.scale * 0.9)
        end
    end

    function KPack_UnitFrames_FocusFrame_Show(self)
        if not FocusFrame.smallSize then
            FocusFrame.borderTexture:SetTexture("Interface\\AddOns\\KPack\\Media\\UnitFrames\\UI-FocusTargetingFrame")
        elseif FocusFrame.smallSize then
            FocusFrame.borderTexture:SetTexture("Interface\\AddOns\\KPack\\Media\\UnitFrames\\UI-TargetingFrame")
        end
    end

    function KPack_UnitFrames_FocusFrame_SetSmallSize(smallSize, onChange)
        if smallSize and not FocusFrame.smallSize then
            FocusFrame.borderTexture:SetTexture("Interface\\AddOns\\KPack\\Media\\UnitFrames\\UI-FocusTargetingFrame")
        elseif not smallSize and FocusFrame.smallSize then
            FocusFrame.borderTexture:SetTexture("Interface\\AddOns\\KPack\\Media\\UnitFrames\\UI-TargetingFrame")
        end
    end

    -- Utility functions
    function UnitColor(unit)
        local r, g, b
        if (not UnitIsPlayer(unit)) and ((not UnitIsConnected(unit)) or (UnitIsDeadOrGhost(unit))) then
            --Color it gray
            r, g, b = 0.5, 0.5, 0.5
        elseif UnitIsPlayer(unit) then
            --Try to color it by class.
            local localizedClass, englishClass = UnitClass(unit)
            local classColor = RAID_CLASS_COLORS[englishClass]
            if classColor then
                r, g, b = classColor.r, classColor.g, classColor.b
            else
                if UnitIsFriend("player", unit) then
                    r, g, b = 0.0, 1.0, 0.0
                else
                    r, g, b = 1.0, 0.0, 0.0
                end
            end
        else
            r, g, b = UnitSelectionColor(unit)
        end

        return r, g, b
    end

    function KPack_UnitFrames_CapDisplayOfNumericValue(value)
        local strLen = strlen(value)
        local retString = value
        if true then
            if strLen >= 10 then
                retString = strsub(value, 1, -10) .. "." .. strsub(value, -9, -9) .. "B"
            elseif strLen >= 7 then
                retString = strsub(value, 1, -7) .. "." .. strsub(value, -6, -6) .. "M"
            elseif strLen >= 4 then
                retString = strsub(value, 1, -4) .. "." .. strsub(value, -3, -3) .. "K"
            end
        end
        return retString
    end

    -- Event listener to make sure we've loaded our settings and thta we apply them
    core:RegisterForEvent("VARIABLES_LOADED", function()
        KPack_UnitFrames_LoadDefaultSettings()
        core.ufi = true
        KPack_UnitFrames_ApplySettings(core.char.UnitFrames)
    end)

    -- Event listener to make sure we enable the addon at the right time
    core:RegisterForEvent("PLAYER_ENTERING_WORLD", KPack_UnitFrames_Enable)

    core:RegisterForEvent("PLAYER_REGEN_ENABLED", function()
        PlayerFrame:SetScript("OnMouseDown", KPack_UnitFrames_PlayerFrame_OnMouseDown)
        PlayerFrame:SetScript("OnMouseUp", KPack_UnitFrames_PlayerFrame_OnMouseUp)
        TargetFrame:SetScript("OnMouseDown", KPack_UnitFrames_TargetFrame_OnMouseDown)
        TargetFrame:SetScript("OnMouseUp", KPack_UnitFrames_TargetFrame_OnMouseUp)
    end)

    core:RegisterForEvent("PLAYER_REGEN_DISABLED", function()
        PlayerFrame:SetScript("OnMouseDown", nil)
        PlayerFrame:SetScript("OnMouseUp", nil)
        TargetFrame:SetScript("OnMouseDown", nil)
        TargetFrame:SetScript("OnMouseUp", nil)
    end)

    core:RegisterForEvent("UNIT_ENTERED_VEHICLE", function(_, unit)
        if unit == "player" then
            PlayerFrame.state = "vehicle"
            UnitFrame_SetUnit(PlayerFrame, "vehicle", PlayerFrameHealthBar, PlayerFrameManaBar)
            UnitFrame_SetUnit(PetFrame, "player", PetFrameHealthBar, PetFrameManaBar)
            PetFrame_Update(PetFrame)
            PlayerFrame:Show()
            PlayerFrame_Update()
        end
    end)

    core:RegisterForEvent("UNIT_EXITED_VEHICLE", function(_, unit)
        if unit == "player" then
            PlayerFrame.state = "player"
            UnitFrame_SetUnit(PlayerFrame, "player", PlayerFrameHealthBar, PlayerFrameManaBar)
            UnitFrame_SetUnit(PetFrame, "pet", PetFrameHealthBar, PetFrameManaBar)
            PetFrame_Update(PetFrame)
            PlayerFrame_Update()
            PlayerFrame:Show()
        end
    end)
end)