assert(KPack, "KPack not found!")
KPack:AddModule("UnitFrames", "Improve the standard blizzard unitframes without going beyond the boundaries set by them.", function(_, core, L)
	if core:IsDisabled("UnitFrames") or core.ElvUI then return end

	-- Setup some locals
	local UFI = CreateFrame("Frame")
	UFI:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)

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
	local Print
	local KPack_UnitFrames_BossTargetFrame_Show
	local KPack_UnitFrames_CapDisplayOfNumericValue
	local KPack_UnitFrames_Initialize
	local KPack_UnitFrames_FocusFrame_SetSmallSize
	local KPack_UnitFrames_FocusFrame_Show
	local KPack_UnitFrames_LoadDefaultSettings
	local KPack_UnitFrames_PartyMemberFrame_ToPlayerArt
	local KPack_UnitFrames_PartyMemberFrame_ToVehicleArt
	local KPack_UnitFrames_SetFrameScale
	local KPack_UnitFrames_Style_PartyMemberFrame
	local KPack_UnitFrames_Style_PartyMemberFrameColor
	local KPack_UnitFrames_Style_PlayerFrame
	local KPack_UnitFrames_TargetFrame_CheckClassification
	local KPack_UnitFrames_TargetFrame_CheckFaction
	local KPack_UnitFrames_TargetFrame_OnMouseDown
	local KPack_UnitFrames_TargetFrame_OnMouseUp
	local KPack_UnitFrames_TargetFrame_Update
	local KPack_UnitFrames_TextStatusBar_UpdateTextString

	local DB
	local defaults = {scale = 1, improved = true}

	-- Debug function. Adds message to the chatbox (only visible to the loacl player)
	function Print(msg)
		core:Print(msg, "UnitFrames")
	end

	function KPack_UnitFrames_ApplySettings(settings)
		settings = settings or DB
		core.ufi = settings.improved
		KPack_UnitFrames_SetFrameScale(settings.scale)
	end

	function KPack_UnitFrames_LoadDefaultSettings()
		if type(core.char.UnitFrames) ~= "table" or not next(core.char.UnitFrames) then
			core.char.UnitFrames = CopyTable(defaults)
		end
		if core.char.UnitFrames.improved == nil then
			core.char.UnitFrames.improved = true
		end
		DB = core.char.UnitFrames
	end

	function KPack_UnitFrames_Initialize()
		if InCombatLockdown() then return end

		-- Generic status text hook and instantly update player
		hooksecurefunc("TextStatusBar_UpdateTextString", KPack_UnitFrames_TextStatusBar_UpdateTextString)
		KPack_UnitFrames_TextStatusBar_UpdateTextString(PlayerFrameHealthBar)
		KPack_UnitFrames_TextStatusBar_UpdateTextString(PlayerFrameManaBar)

		-- Hook PlayerFrame functions
		hooksecurefunc("PlayerFrame_ToPlayerArt", KPack_UnitFrames_Style_PlayerFrame)

		-- Set up some stylings
		KPack_UnitFrames_Style_PlayerFrame()
		PlayerFrameHealthBar.lockColor = true

		-- Hook TargetFrame functions
		hooksecurefunc("TargetFrame_Update", KPack_UnitFrames_TargetFrame_Update)
		hooksecurefunc("TargetFrame_CheckFaction", KPack_UnitFrames_TargetFrame_CheckFaction)
		hooksecurefunc("TargetFrame_CheckClassification", KPack_UnitFrames_TargetFrame_CheckClassification)

		-- FocusFrame hooks
		hooksecurefunc("FocusFrame_SetSmallSize", KPack_UnitFrames_FocusFrame_SetSmallSize)
		hooksecurefunc(FocusFrame, "Show", KPack_UnitFrames_FocusFrame_Show)

		-- Hook PartyMember functions
		hooksecurefunc("PartyMemberFrame_ToPlayerArt", KPack_UnitFrames_PartyMemberFrame_ToPlayerArt)
		hooksecurefunc("PartyMemberFrame_ToVehicleArt", KPack_UnitFrames_PartyMemberFrame_ToVehicleArt)
		hooksecurefunc("HealthBar_OnValueChanged", KPack_UnitFrames_Style_PartyMemberFrameColor)
		hooksecurefunc("UnitFrameHealthBar_Update", KPack_UnitFrames_Style_PartyMemberFrameColor)
		KPack_UnitFrames_Style_PartyMemberFrame()
		core.After(0.1, KPack_UnitFrames_Style_PartyMemberFrameColor)

		-- BossFrame hooks
		hooksecurefunc(Boss1TargetFrame, "Show", KPack_UnitFrames_BossTargetFrame_Show)
		hooksecurefunc(Boss2TargetFrame, "Show", KPack_UnitFrames_BossTargetFrame_Show)
		hooksecurefunc(Boss3TargetFrame, "Show", KPack_UnitFrames_BossTargetFrame_Show)
		hooksecurefunc(Boss4TargetFrame, "Show", KPack_UnitFrames_BossTargetFrame_Show)
	end

	function KPack_UnitFrames_Style_PlayerFrame()
		if DB.improved then
			PlayerFrameHealthBar:SetWidth(119)
			PlayerFrameHealthBar:SetHeight(29)
			PlayerFrameHealthBar:SetPoint("TOPLEFT", 106, -22)
			PlayerFrameHealthBarText:SetPoint("CENTER", 50, 6)
			PlayerFrameTexture:SetTexture("Interface\\AddOns\\KPack\\Media\\UnitFrames\\UI-TargetingFrame")
			PlayerStatusTexture:SetTexture("Interface\\AddOns\\KPack\\Media\\UnitFrames\\UI-Player-Status")
		end
		PlayerFrameHealthBar:SetStatusBarColor(UnitColor("player"))
	end

	function KPack_UnitFrames_SetFrameScale(scale)
		if not InCombatLockdown() then
			PlayerFrame:SetScale(scale)
			TargetFrame:SetScale(scale)
			FocusFrame:SetScale((FocusFrame.smallSize and 0.75 or 1) * scale)
			Boss1TargetFrame:SetScale(scale * 0.9)
			Boss2TargetFrame:SetScale(scale * 0.9)
			Boss3TargetFrame:SetScale(scale * 0.9)
			Boss4TargetFrame:SetScale(scale * 0.9)
			DB.scale = scale
		end
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
		elseif cmd == "style" or cmd == "improve" then
			DB.improved = not DB.improved
			ReloadUI()
		elseif cmd == "reset" or cmd == "default" then
			StaticPopup_Show("KUFI_LAYOUT_RESET")
		else
			Print(L:F("Acceptable commands for: |caaf49141%s|r", "/uf"))
			local helpStr = "|cffffd700%s|r: %s"
			print(helpStr:format("scale |cff00ffffn|r", L["changes the unit frames scale."]))
			print(helpStr:format("style", L["enables improved unit frames textures."]))
			print(helpStr:format("reset", L["Resets module settings to default."]))
		end
	end

	-- Setup the static popup dialog for resetting the UI
	StaticPopupDialogs["KUFI_LAYOUT_RESET"] = {
		preferredIndex = 4,
		text = "Are you sure you want to reset your layout?\nThis will automatically reload the UI.",
		button1 = YES,
		button2 = NO,
		OnAccept = function()
			core.char.UnitFrames = nil
			DB = nil
			KPack_UnitFrames_LoadDefaultSettings()
			ReloadUI()
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true
	}

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
	do
		function UnitColor(unit)
			local r, g, b
			if not UnitIsPlayer(unit) and not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit) then
				r, g, b = 0.5, 0.5, 0.5
			elseif UnitIsPlayer(unit) then
				local class = select(2, UnitClass(unit))
				local color = RAID_CLASS_COLORS[class]
				if color then
					r, g, b = color.r, color.g, color.b
				else
					if UnitIsFriend("player", unit) then
						r, g, b = 0, 1, 0
					else
						r, g, b = 1, 0, 0
					end
				end
			else
				r, g, b = UnitSelectionColor(unit)
			end

			return r, g, b
		end

		function KPack_UnitFrames_Style_PartyMemberFrameColor()
			if InCombatLockdown() then return end
			for i = 1, GetNumPartyMembers() do
				_G["PartyMemberFrame" .. i .. "HealthBar"]:SetStatusBarColor(UnitColor("party" .. i))
				_G["PartyMemberFrame" .. i .. "HealthBar"].lockColor = true
			end
		end

		function KPack_UnitFrames_Style_PartyMemberFrame()
			if not InCombatLockdown() and DB.improved then
				for i = 1, GetNumPartyMembers() do
					-- Text
					_G["PartyMemberFrame" .. i .. "Name"]:SetPoint("BOTTOMLEFT", 57, 35)
					_G["PartyMemberFrame" .. i .. "HealthBarText"]:ClearAllPoints()
					_G["PartyMemberFrame" .. i .. "HealthBarText"]:SetPoint("BOTTOM", 32, 21)
					_G["PartyMemberFrame" .. i .. "ManaBarText"]:ClearAllPoints()
					_G["PartyMemberFrame" .. i .. "ManaBarText"]:SetPoint("BOTTOM", 32, 9)
					-- Border Texture
					_G["PartyMemberFrame" .. i .. "Texture"]:SetPoint("TOPLEFT", 0, 12)
					_G["PartyMemberFrame" .. i .. "Texture"]:SetHeight(75)
					_G["PartyMemberFrame" .. i .. "Texture"]:SetWidth(150)
					-- Border Flash
					_G["PartyMemberFrame" .. i .. "Flash"]:SetPoint("TOPLEFT", 0, 12)
					_G["PartyMemberFrame" .. i .. "Flash"]:SetHeight(75)
					_G["PartyMemberFrame" .. i .. "Flash"]:SetWidth(150)
					-- Health Bar
					_G["PartyMemberFrame" .. i .. "HealthBar"]:ClearAllPoints()
					_G["PartyMemberFrame" .. i .. "HealthBar"]:SetPoint("TOPLEFT", 55, -7)
					_G["PartyMemberFrame" .. i .. "HealthBar"]:SetHeight(27)
					_G["PartyMemberFrame" .. i .. "HealthBar"]:SetWidth(80)
					-- Mana Bar
					_G["PartyMemberFrame" .. i .. "ManaBar"]:ClearAllPoints()
					_G["PartyMemberFrame" .. i .. "ManaBar"]:SetPoint("TOPLEFT", 54, -34)
					_G["PartyMemberFrame" .. i .. "ManaBar"]:SetHeight(10)
					_G["PartyMemberFrame" .. i .. "ManaBar"]:SetWidth(80)
					-- Portrait
					_G["PartyMemberFrame" .. i .. "Portrait"]:SetPoint("TOPLEFT", 7, -2)
					_G["PartyMemberFrame" .. i .. "Portrait"]:SetHeight(43)
					_G["PartyMemberFrame" .. i .. "Portrait"]:SetWidth(43)
					-- Background
					_G["PartyMemberFrame" .. i .. "Background"]:ClearAllPoints()
					_G["PartyMemberFrame" .. i .. "Background"]:SetPoint("TOPLEFT", 55, -7)
					_G["PartyMemberFrame" .. i .. "Background"]:SetHeight(35)
					_G["PartyMemberFrame" .. i .. "Background"]:SetWidth(80)
					_G["PartyMemberFrame" .. i .. "Texture"]:SetTexture("Interface\\AddOns\\KPack\\Media\\UnitFrames\\UI-PartyFrame")
					_G["PartyMemberFrame" .. i .. "Flash"]:SetTexture("Interface\\AddOns\\KPack\\Media\\UnitFrames\\UI-Partyframe-Flash")
				end
			end
		end

		function KPack_UnitFrames_PartyMemberFrame_ToPlayerArt(self)
			if not InCombatLockdown() then
				KPack_UnitFrames_Style_PartyMemberFrame()
			end
		end

		function KPack_UnitFrames_PartyMemberFrame_ToVehicleArt(self)
			if not InCombatLockdown() and DB.improved then
				for i = 1, GetNumPartyMembers() do
					if UnitInVehicle("party" .. i) then
						_G["PartyMemberFrame" .. i .. "VehicleTexture"]:SetTexture("Interface\\AddOns\\KPack\\Media\\UnitFrames\\UI-Vehicles-Partyframe")
						_G["PartyMemberFrame" .. i .. "VehicleTexture"]:SetPoint("TOPLEFT", 0, 12)
						_G["PartyMemberFrame" .. i .. "VehicleTexture"]:SetHeight(75)
						_G["PartyMemberFrame" .. i .. "VehicleTexture"]:SetWidth(150)
					end
				end
			end
		end
	end

	function KPack_UnitFrames_TargetFrame_Update(self)

		-- Set back color of health bar
		if not UnitPlayerControlled(self.unit) and UnitIsTapped(self.unit) and not UnitIsTappedByPlayer(self.unit) and not UnitIsTappedByAllThreatList(self.unit) then
			-- Gray if npc is tapped by other player
			self.healthbar:SetStatusBarColor(0.5, 0.5, 0.5)
		else
			-- Standard by class etc if not
			self.healthbar:SetStatusBarColor(UnitColor(self.healthbar.unit))
		end

		if not DB.improved then return end
		-- Layout elements
		local thisName = self:GetName()
		self.healthbar.lockColor = true
		self.healthbar:SetWidth(119)
		self.healthbar:SetHeight(29)
		self.healthbar:SetPoint("TOPLEFT", 7, -22)
		_G[thisName .. "TextureFrameHealthBarText"]:SetPoint("CENTER", -50, 6)
		self.deadText:SetPoint("CENTER", -50, 6)
		self.nameBackground:Hide()
	end

	function KPack_UnitFrames_TargetFrame_CheckClassification(self, forceNormalTexture)
		if not DB.improved then return end
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
		if not DB.improved then return end
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
		if not UnitPlayerControlled(self.unit) and UnitIsTapped(self.unit) and not UnitIsTappedByPlayer(self.unit) and not UnitIsTappedByAllThreatList(self.unit) then
			-- Gray if npc is tapped by other player
			self.healthbar:SetStatusBarColor(0.5, 0.5, 0.5)
		else
			-- Standard by class etc if not
			self.healthbar:SetStatusBarColor(UnitColor(self.healthbar.unit))
		end
	end

	function KPack_UnitFrames_BossTargetFrame_Show(self)
		if not InCombatLockdown() and DB.improved then
			self.borderTexture:SetTexture("Interface\\AddOns\\KPack\\Media\\UnitFrames\\UI-UnitFrame-Boss")
			self:SetScale((DB.scale or 1) * 0.9)
		end
	end

	function KPack_UnitFrames_FocusFrame_Show(self)
		if not DB.improved then
			return
		elseif not FocusFrame.smallSize then
			FocusFrame.borderTexture:SetTexture("Interface\\AddOns\\KPack\\Media\\UnitFrames\\UI-FocusTargetingFrame")
		elseif FocusFrame.smallSize then
			FocusFrame.borderTexture:SetTexture("Interface\\AddOns\\KPack\\Media\\UnitFrames\\UI-TargetingFrame")
		end
	end

	function KPack_UnitFrames_FocusFrame_SetSmallSize(smallSize, onChange)
		if not DB.improved then
			return
		elseif smallSize and not FocusFrame.smallSize then
			FocusFrame.borderTexture:SetTexture("Interface\\AddOns\\KPack\\Media\\UnitFrames\\UI-FocusTargetingFrame")
		elseif not smallSize and FocusFrame.smallSize then
			FocusFrame.borderTexture:SetTexture("Interface\\AddOns\\KPack\\Media\\UnitFrames\\UI-TargetingFrame")
		end
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
	core:RegisterForEvent("PLAYER_LOGIN", function()
		KPack_UnitFrames_LoadDefaultSettings()
		UFI:RegisterEvent("PLAYER_ENTERING_WORLD")
		KPack_UnitFrames_ApplySettings(core.char.UnitFrames)
	end)

	function UFI:PLAYER_ENTERING_WORLD()
		KPack_UnitFrames_Initialize()
		UFI:RegisterEvent("PLAYER_REGEN_ENABLED")
	end

	function UFI:PLAYER_REGEN_ENABLED()
		core.After(0.5, function()
			if not UnitInVehicle("player") and not UnitExists("playerpet") then
				PetFrame:Hide()
			end
		end)
	end
end)