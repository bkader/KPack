local core = KPack
if not core or core.Ascension then return end
core:AddModule("UnitFrames", "Improve the standard blizzard unitframes without going beyond the boundaries set by them.", function(L)
	if core:IsDisabled("UnitFrames") or core.ElvUI then return end

	-- Setup some locals
	local UFI = CreateFrame("Frame")
	UFI:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)

	local tinsert, tgetn = table.insert, table.getn
	local strgmatch, strsub, strlower = string.gmatch, string.sub, string.lower
	local ceil, format, tonumber, tostring = math.ceil, string.format, tonumber, tostring

	local StaticPopup_Show = StaticPopup_Show

	local hooksecurefunc = hooksecurefunc
	local GetCVar, SetCVar, GetCVarBool = GetCVar, SetCVar, GetCVarBool
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

	-- prepare our functions.
	local __BossTargetFrame_Show
	local __FocusFrame_SetSmallSize
	local __FocusFrame_Show
	local __PartyMemberFrame_ToPlayerArt
	local __PartyMemberFrame_ToVehicleArt
	local __PartyMemberFrame_Style
	local __ColorHealthBar
	local __UnitFrameHealthBar_Update
	local __UnitFramePortrait_Update
	local __PlayerFrame_ToPlayerArt
	local __TargetFrame_CheckClassification
	local __TargetFrame_CheckFaction
	local __TargetFrame_Update
	local __TextStatusBar_UpdateTextString

	local DB
	local defaults = {
		scale = 1,
		improved = true,
		portrait = false,
		texture = "KPack Norm",
		font = "Friz Quadrata TT",
		fontSize = 10,
		fontOutline = "OUTLINE",
		friendly = {0, 1, 0},
		hostile = {1, 0, 0},
		neutral = {1, 1, 0}
	}

	-- [[ internal functions ]] --

	function __TextStatusBar_UpdateTextString(textStatusBar)
		local textString = textStatusBar.TextString
		if textString then
			local value = textStatusBar:GetValue()
			local valueMin, valueMax = textStatusBar:GetMinMaxValues()

			textString:SetFont(
				core:MediaFetch("font", DB.font or defaults.font),
				DB.fontSize or defaults.fontSize,
				DB.fontOutline or defaults.fontOutline
			)

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
						textString:SetText(textStatusBar.prefix .. " " .. UFI:CapDisplayOfNumericValue(textStatusBar:GetValue()) .. " (" .. value .. ")")
					else
						textString:SetText(UFI:CapDisplayOfNumericValue(textStatusBar:GetValue()) .. " (" .. value .. ")")
					end
				elseif value == 0 and textStatusBar.zeroText then
					textString:SetText(textStatusBar.zeroText)
					textStatusBar.isZero = 1
					textString:Show()
					return
				else
					textStatusBar.isZero = nil
					if textStatusBar.capNumericDisplay then
						value = UFI:CapDisplayOfNumericValue(value)
						valueMax = UFI:CapDisplayOfNumericValue(valueMax)
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

	function __PlayerFrame_ToPlayerArt()
		if DB.improved then
			PlayerFrameHealthBar:SetWidth(119)
			PlayerFrameHealthBar:SetHeight(29)
			PlayerFrameHealthBar:SetPoint("TOPLEFT", 106, -22)
			PlayerFrameHealthBarText:SetPoint("CENTER", 50, 6)
			PlayerFrameTexture:SetTexture([[Interface\AddOns\KPack\Media\UnitFrames\UI-TargetingFrame]])
			PlayerStatusTexture:SetTexture([[Interface\AddOns\KPack\Media\UnitFrames\UI-Player-Status]])
			PlayerFrameHealthBar:SetStatusBarTexture(core:MediaFetch("statusbar", DB.texture or defaults.texture))
			PlayerFrameManaBar:SetStatusBarTexture(core:MediaFetch("statusbar", DB.texture or defaults.texture))
		end
	end

	function __TargetFrame_Update(self)
		if InCombatLockdown() or not DB.improved then return end

		-- Layout elements
		self.healthbar.lockColor = true
		self.healthbar:SetWidth(119)
		self.healthbar:SetHeight(29)
		self.healthbar:SetPoint("TOPLEFT", 7, -22)
		_G[self:GetName() .. "TextureFrameHealthBarText"]:SetPoint("CENTER", -50, 6)
		self.deadText:SetPoint("CENTER", -50, 6)
		self.nameBackground:Hide()
		self.healthbar:SetStatusBarTexture(core:MediaFetch("statusbar", DB.texture or defaults.texture))
		self.manabar:SetStatusBarTexture(core:MediaFetch("statusbar", DB.texture or defaults.texture))
	end

	function __TargetFrame_CheckFaction(self)
		if not DB.improved then return end

		local factionGroup = UnitFactionGroup(self.unit)
		if UnitIsPVPFreeForAll(self.unit) then
			self.pvpIcon:SetTexture([[Interface\TargetingFrame\UI-PVP-FFA]])
			self.pvpIcon:Show()
		elseif factionGroup and UnitIsPVP(self.unit) and UnitIsEnemy("player", self.unit) then
			self.pvpIcon:SetTexture([[Interface\TargetingFrame\UI-PVP-FFA]])
			self.pvpIcon:Show()
		elseif factionGroup then
			self.pvpIcon:SetTexture([[Interface\TargetingFrame\UI-PVP-]] .. factionGroup)
			self.pvpIcon:Show()
		else
			self.pvpIcon:Hide()
		end
	end

	function __TargetFrame_CheckClassification(self, forceNormalTexture)
		if not DB.improved then return end

		local texture
		local classification = UnitClassification(self.unit)
		if classification == "worldboss" or classification == "elite" then
			texture = [[Interface\AddOns\KPack\Media\UnitFrames\UI-TargetingFrame-Elite]]
		elseif classification == "rareelite" then
			texture = [[Interface\AddOns\KPack\Media\UnitFrames\UI-TargetingFrame-Rare-Elite]]
		elseif classification == "rare" then
			texture = [[Interface\AddOns\KPack\Media\UnitFrames\UI-TargetingFrame-Rare]]
		end
		if texture and not forceNormalTexture then
			self.borderTexture:SetTexture(texture)
		else
			self.borderTexture:SetTexture([[Interface\AddOns\KPack\Media\UnitFrames\UI-TargetingFrame]])
		end
	end

	function __FocusFrame_SetSmallSize(smallSize, onChange)
		if not DB.improved then
			return
		elseif smallSize and not FocusFrame.smallSize then
			FocusFrame.borderTexture:SetTexture([[Interface\AddOns\KPack\Media\UnitFrames\UI-FocusTargetingFrame]])
		elseif not smallSize and FocusFrame.smallSize then
			FocusFrame.borderTexture:SetTexture([[Interface\AddOns\KPack\Media\UnitFrames\UI-TargetingFrame]])
		end
	end

	function __FocusFrame_Show(self)
		if not DB.improved then
			return
		elseif not self.smallSize then
			self.borderTexture:SetTexture([[Interface\AddOns\KPack\Media\UnitFrames\UI-FocusTargetingFrame]])
		elseif self.smallSize then
			self.borderTexture:SetTexture([[Interface\AddOns\KPack\Media\UnitFrames\UI-TargetingFrame]])
		end
	end

	function __PartyMemberFrame_ToPlayerArt(self)
		if not InCombatLockdown() then
			__PartyMemberFrame_Style()
		end
	end

	function __PartyMemberFrame_ToVehicleArt(self)
		if DB.improved then
			for i = 1, 4 do
				if UnitExists("party" .. i) and UnitInVehicle("party" .. i) then
					_G["PartyMemberFrame" .. i .. "VehicleTexture"]:SetTexture([[Interface\AddOns\KPack\Media\UnitFrames\UI-Vehicles-Partyframe]])
					if not InCombatLockdown() then
						_G["PartyMemberFrame" .. i .. "VehicleTexture"]:SetPoint("TOPLEFT", 0, 12)
						_G["PartyMemberFrame" .. i .. "VehicleTexture"]:SetHeight(75)
						_G["PartyMemberFrame" .. i .. "VehicleTexture"]:SetWidth(150)
					end
				end
			end
		end
	end

	function __PartyMemberFrame_Style()
		if not InCombatLockdown() and DB.improved then
			for i = 1, 4 do
				local frame = _G["PartyMemberFrame" .. i]
				if frame and not frame.kpacked then
					frame.kpacked = true
					__ColorHealthBar(_G["PartyMemberFrame" .. i .. "HealthBar"], "party" .. i)
					__UnitFramePortrait_Update(_G["PartyMemberFrame" .. i])

					_G["PartyMemberFrame" .. i .. "HealthBar"]:SetStatusBarTexture(core:MediaFetch("statusbar", DB.texture or defaults.texture))
					_G["PartyMemberFrame" .. i .. "ManaBar"]:SetStatusBarTexture(core:MediaFetch("statusbar", DB.texture or defaults.texture))
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
					_G["PartyMemberFrame" .. i .. "Texture"]:SetTexture([[Interface\AddOns\KPack\Media\UnitFrames\UI-PartyFrame]])
					_G["PartyMemberFrame" .. i .. "Flash"]:SetTexture([[Interface\AddOns\KPack\Media\UnitFrames\UI-Partyframe-Flash]])
				end
			end
		end
	end

	function __UnitFrameHealthBar_Update(statusbar, unit)
		if unit and unit ~= "mouseover" and UnitIsConnected(unit) and unit == statusbar.unit then
			__ColorHealthBar(statusbar, unit)
		end
	end

	function __UnitFramePortrait_Update(self)
		if DB.portrait and self.portrait and self.unit then
			if UnitIsPlayer(self.unit) then
				local tex = CLASS_ICON_TCOORDS[select(2, UnitClass(self.unit))]
				if tex then
					self.portrait:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles")
					self.portrait:SetTexCoord(unpack(tex))
				end
			else
				SetPortraitTexture(self.portrait, self.unit)
				self.portrait:SetTexCoord(0, 0, 0, 1, 1, 0, 1, 1)
			end
		end
	end

	function __BossTargetFrame_Show(self)
		if not InCombatLockdown() and DB.improved and not self.kpacked then
			self.kpacked = true
			self.borderTexture:SetTexture([[Interface\AddOns\KPack\Media\UnitFrames\UI-UnitFrame-Boss]])
			self:SetScale((DB.scale or 1) * 0.9)
		end
	end

	-- [[ end of internal functions ]] --

	-- Debug function. Adds message to the chatbox (only visible to the loacl player)
	function UFI:Print(msg)
		core:Print(msg, "UnitFrames")
	end

	function UFI:ApplySettings(settings)
		settings = settings or DB
		for k, v in pairs(defaults) do
			if settings[k] == nil then
				settings[k] = v
			end
		end
		core.ufi = settings.improved
		UFI:SetFrameScale(settings.scale)
	end

	function UFI:LoadDefaultSettings()
		if type(core.char.UnitFrames) ~= "table" or not next(core.char.UnitFrames) then
			core.char.UnitFrames = CopyTable(defaults)
		end
		for k, v in pairs(defaults) do
			if core.char.UnitFrames[k] == nil then
				core.char.UnitFrames[k] = v
			end
		end
		DB = core.char.UnitFrames
	end

	function UFI:Initialize()
		if InCombatLockdown() then return end

		-- Generic status text hook and instantly update player
		hooksecurefunc("TextStatusBar_UpdateTextString", __TextStatusBar_UpdateTextString)
		__TextStatusBar_UpdateTextString(PlayerFrameHealthBar)
		__TextStatusBar_UpdateTextString(PlayerFrameManaBar)

		-- Hook PlayerFrame functions
		hooksecurefunc("PlayerFrame_ToPlayerArt", __PlayerFrame_ToPlayerArt)

		-- Set up some stylings
		__PlayerFrame_ToPlayerArt()
		PlayerFrameHealthBar.lockColor = true

		-- Hook TargetFrame functions
		hooksecurefunc("TargetFrame_Update", __TargetFrame_Update)
		hooksecurefunc("TargetFrame_CheckFaction", __TargetFrame_CheckFaction)
		hooksecurefunc("TargetFrame_CheckClassification", __TargetFrame_CheckClassification)

		-- FocusFrame hooks
		hooksecurefunc("FocusFrame_SetSmallSize", __FocusFrame_SetSmallSize)
		hooksecurefunc(FocusFrame, "Show", __FocusFrame_Show)

		-- Hook PartyMember functions
		hooksecurefunc("PartyMemberFrame_ToPlayerArt", __PartyMemberFrame_ToPlayerArt)
		hooksecurefunc("PartyMemberFrame_ToVehicleArt", __PartyMemberFrame_ToVehicleArt)
		hooksecurefunc("UnitFrameHealthBar_Update", __UnitFrameHealthBar_Update)
		hooksecurefunc("HealthBar_OnValueChanged", function(statusbar) __ColorHealthBar(statusbar, statusbar.unit) end)
		hooksecurefunc("UnitFramePortrait_Update", __UnitFramePortrait_Update)

		__UnitFrameHealthBar_Update(PlayerFrameHealthBar, "player")
		__UnitFramePortrait_Update(PlayerFrame)
		__PartyMemberFrame_Style()

		-- BossFrame hooks
		hooksecurefunc(Boss1TargetFrame, "Show", __BossTargetFrame_Show)
		hooksecurefunc(Boss2TargetFrame, "Show", __BossTargetFrame_Show)
		hooksecurefunc(Boss3TargetFrame, "Show", __BossTargetFrame_Show)
		hooksecurefunc(Boss4TargetFrame, "Show", __BossTargetFrame_Show)
	end

	function UFI:SetFrameScale(scale)
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
				UFI:SetFrameScale(scale)
			elseif scale then
				UFI:Print(L["Scale has to be a number, recommended to be between 0.5 and 3"])
			end
		elseif cmd == "style" or cmd == "improve" then
			DB.improved = not DB.improved
			ReloadUI()
		elseif cmd == "reset" or cmd == "default" then
			StaticPopup_Show("KUFI_LAYOUT_RESET")
		elseif cmd == "config" or cmd == "options" then
			core:OpenConfig("Options", "UnitFrames")
		else
			UFI:Print(L:F("Acceptable commands for: |caaf49141%s|r", "/uf"))
			local helpStr = "|cffffd700%s|r: %s"
			print(helpStr:format("scale |cff00ffffn|r", L["changes the unit frames scale."]))
			print(helpStr:format("style", L["enables improved unit frames textures."]))
			print(helpStr:format("config", L["Access module settings."]))
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
			UFI:LoadDefaultSettings()
			ReloadUI()
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true
	}

	function __ColorHealthBar(statusbar, unit)
		if not unit then
			return
		elseif UnitIsPlayer(unit) then
			local _, class = UnitClass(unit)
			if class then
				local color = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class]
				statusbar:SetStatusBarColor(color.r, color.g, color.b)
				return
			end
		end

		local r, g, b = UnitSelectionColor(unit)
		if r == 0 then
			r, g, b = unpack(DB.friendly)
		elseif g == 0 then
			r, g, b = unpack(DB.hostile)
		else
			r, g, b = unpack(DB.neutral)
		end

		statusbar:SetStatusBarColor(r, g, b)
	end

	function UFI:CapDisplayOfNumericValue(value)
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

	function UFI:GetOptions()
		if not self.options then
			self.options = {
				type = "group",
				name = UNITFRAME_LABEL,
				get = function(i)
					return (DB[i[#i]] == nil) and defaults[i[#i]] or DB[i[#i]]
				end,
				set = function(i, val)
					DB[i[#i]] = val
					UFI:ApplySettings(DB)
				end,
				disabled = function()
					return InCombatLockdown()
				end,
				args = {
					note = {
						type = "description",
						name = L["Some settings require UI to be reloaded."],
						width = "full",
						order = 0
					},
					improved = {
						type = "toggle",
						name = L["Enhance Unit Frames"],
						order = 10
					},
					portrait = {
						type = "toggle",
						name = L["Class Icon Portrait"],
						order = 20
					},
					appearance = {
						type = "group",
						name = L["Appearance"],
						inline = true,
						order = 30,
						args = {
							scale = {
								type = "range",
								name = L["Scale"],
								min = 0.5,
								max = 3,
								step = 0.01,
								isPercent = true,
								order = 10
							},
							texture = {
								type = "select",
								name = L["Texture"],
								dialogControl = "LSM30_Statusbar",
								values = AceGUIWidgetLSMlists.statusbar,
								order = 20
							}
						}
					},
					text = {
						type = "group",
						name = L["Text Settings"],
						inline = true,
						order = 40,
						set = function(i, val)
							DB[i[#i]] = val
							UFI:ApplySettings(DB)
							__TextStatusBar_UpdateTextString(PlayerFrameHealthBar)
							__TextStatusBar_UpdateTextString(PlayerFrameManaBar)
						end,
						args = {
							font = {
								type = "select",
								name = L["Font"],
								dialogControl = "LSM30_Font",
								values = AceGUIWidgetLSMlists.font,
								order = 10
							},
							fontSize = {
								type = "range",
								name = L["Font Size"],
								min = 6,
								max = 30,
								step = 1,
								order = 20
							},
							fontOutline = {
								type = "select",
								name = L["Font Outline"],
								values = {
									[""] = NONE,
									["OUTLINE"] = L["Outline"],
									["THINOUTLINE"] = L["Thin outline"],
									["THICKOUTLINE"] = L["Thick outline"],
									["MONOCHROME"] = L["Monochrome"],
									["OUTLINEMONOCHROME"] = L["Outlined monochrome"]
								},
								order = 30
							},
							percent = {
								type = "toggle",
								name = L["Show percentage"],
								get = function()
									return (GetCVar("statusTextPercentage") == "1")
								end,
								set = function(_, val)
									SetCVar("statusTextPercentage", val and "1" or "0")
									UFI:ApplySettings(DB)
									__TextStatusBar_UpdateTextString(PlayerFrameHealthBar)
									__TextStatusBar_UpdateTextString(PlayerFrameManaBar)
								end,
								order = 40
							}
						}
					},
					colors = {
						type = "group",
						name = L["Colors"],
						inline = true,
						order = 50,
						get = function(i)
							local r, g, b = unpack(DB[i[#i]])
							return r, g, b
						end,
						set = function(i, r, g, b)
							DB[i[#i]][1] = r or 1
							DB[i[#i]][2] = g or 1
							DB[i[#i]][3] = b or 1
							UFI:ApplySettings(DB)
						end,
						args = {
							friendly = {
								type = "color",
								name = FRIENDLY,
								order = 10
							},
							neutral = {
								type = "color",
								name = FACTION_STANDING_LABEL4,
								order = 20
							},
							hostile = {
								type = "color",
								name = HOSTILE,
								order = 30
							}
						}
					},
					reset = {
						type = "execute",
						name = RESET,
						width = "full",
						order = 60,
						func = function()
							wipe(core.char.UnitFrames)
							wipe(DB)
							for k, v in pairs(defaults) do
								core.char.UnitFrames[k] = v
								DB[k] = v
							end
							UFI:ApplySettings(DB)
							core:Print(L["module's settings reset to default."], "UnitFrames")
						end
					}
				}
			}
		end
		return self.options
	end

	function UFI:PLAYER_ENTERING_WORLD()
		UFI:Initialize()
	end

	-- Event listener to make sure we've loaded our settings and thta we apply them
	core:RegisterForEvent("PLAYER_LOGIN", function()
		-- list of addons for which we disable the module.
		if core:AddOnIsLoaded("RUF", "ShadowUF", "ElvUI") then return end
		UFI:LoadDefaultSettings()
		UFI:RegisterEvent("PLAYER_ENTERING_WORLD")
		UFI:ApplySettings(core.char.UnitFrames)
		core.options.args.Options.args.UnitFrames = UFI:GetOptions()
	end)
end)