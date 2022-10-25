local core = KPack
if not core then return end
core:AddModule("Nameplates", function(L)
	if core:IsDisabled("Nameplates") or core.ElvUI then return end
	local disabled, reason

	-- SavedVariables
	local options, GetOptions
	local DB, CharDB, changed
	local defaults = {
		enabled = true,
		barTexture = "Blizzard",
		barWidth = 120,
		barHeight = 12,
		font = "Yanone",
		fontSize = 11,
		fontOutline = "THINOUTLINE",
		hideName = false,
		abbrevName = false,
		hideLevel = false,
		showHealthText = false,
		showHealthMax = false,
		shortenNumbers = true,
		showHealthPercent = false,
		hideHealthFull = false,
		textFont = "Yanone",
		textFontSize = 11,
		textFontOutline = "THINOUTLINE",
		decimals = 1,
		textOfsX = 0,
		textOfsY = 0,
		arrow = "arrow0",
		customColor = false,
		FRIENDLY = {0, 1.0, 0}, -- green for friendly
		NEUTRAL = {1.0, 1.0, 0}, -- yellow for  neutral
		HOSTILE = {1.0, 0, 0} -- red for hostile
	}
	local defaultsChar = {
		tankMode = false,
		tankColor = {0.2, 0.9, 0.1, 1}
	}
	local path = "Interface\\AddOns\\KPack\\Media\\"

	-- ::::::::::::::::::::::::: START of Configuration ::::::::::::::::::::::::: --

	local config = {
		glowTexture = path .. "StatusBar\\glowTex",
		solidTexture = [[Interface\Buttons\WHITE8X8]],
		tankMode = false,
		tankColor = {0.2, 0.9, 0.1, 1}
	}

	-- Non-Latin Font Bypass
	if core.nonLatin then
		config.font = NAMEPLATE_FONT -- here goes the path
	end
	core.NP = config

	-- :::::::::::::::::::::::::: END of Configuration ::::::::::::::::::::::::: --

	local backdrop = {
		edgeFile = config.glowTexture,
		edgeSize = 5,
		insets = {left = 3, right = 2, top = 3, bottom = 2}
	}

	local type, select = type, select
	local format = string.format
	local max = math.max
	local floor = math.floor
	local unpack = unpack
	local UnitExists = UnitExists
	local targetExists

	local Nameplate_Create
	local Nameplate_OnShow
	local Nameplate_OnHide
	local Nameplate_OnUpdate

	-- events frame
	local NP = CreateFrame("Frame")
	NP:SetScript("OnEvent", function(self, event, ...)
		if DB.enabled and event == "PLAYER_TARGET_CHANGED" then
			targetExists = (UnitExists("target") ~= nil)
		end
	end)

	-- module's print function
	local function Print(msg)
		core:Print(msg, L["Nameplates"])
	end

	-- :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

	local ClassReference = {}
	local RaidIconCoordinate = {
		[0] = {[0] = "STAR", [0.25] = "MOON"},
		[0.25] = {[0] = "CIRCLE", [0.25] = "SQUARE"},
		[0.5] = {[0] = "DIAMOND", [0.25] = "CROSS"},
		[0.75] = {[0] = "TRIANGLE", [0.25] = "SKULL"}
	}
	local RaidIconColors = {
		STAR = {0.85, 0.81, 0.27},
		MOON = {0.60, 0.75, 0.85},
		CIRCLE = {0.93, 0.51, 0.06},
		SQUARE = {0, 0.64, 1},
		DIAMOND = {0.7, 0.06, 0.84},
		CROSS = {0.82, 0.18, 0.18},
		TRIANGLE = {0.14, 0.66, 0.14},
		SKULL = {0.89, 0.83, 0.74}
	}

	local function ColorToString(r, g, b)
		return "C" .. floor((100 * r) + 0.5) .. floor((100 * g) + 0.5) .. floor((100 * b) + 0.5)
	end

	-- :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

	local Nameplate_GetTotemTable
	do
		local GetSpellInfo = GetSpellInfo
		local totemsTable = nil

		local function TotemsTable_Build()
			if totemsTable and next(totemsTable) ~= nil then return end
			totemsTable = totemsTable or {}

			local function TotemName(spellid, suffix)
				local name = GetSpellInfo(spellid)
				if suffix then
					return name .. " " .. suffix
				end
				return name
			end

			local function TotemTexture(spellid)
				return (select(3, GetSpellInfo(spellid)))
			end

			--Air Totems
			totemsTable[TotemName(8177)] = {TotemTexture(8177), 1, "Grounding Totem"}
			totemsTable[TotemName(10595, "I")] = {TotemTexture(10595), 1, "Nature Resistance Totem I"}
			totemsTable[TotemName(10600, "II")] = {TotemTexture(10600), 1, "Nature Resistance Totem II"}
			totemsTable[TotemName(10601, "III")] = {TotemTexture(10601), 1, "Nature Resistance Totem III"}
			totemsTable[TotemName(25574, "IV")] = {TotemTexture(25574), 1, "Nature Resistance Totem IV"}
			totemsTable[TotemName(58746, "V")] = {TotemTexture(58746), 1, "Nature Resistance Totem V"}
			totemsTable[TotemName(58749, "VI")] = {TotemTexture(58749), 1, "Nature Resistance Totem VI"}
			totemsTable[TotemName(6495)] = {TotemTexture(6495), 1, "Sentry Totem"}
			totemsTable[TotemName(8512)] = {TotemTexture(8512), 1, "Windfury Totem"}
			totemsTable[TotemName(3738)] = {TotemTexture(3738), 1, "Wrath of Air Totem"}
			--Earth Totems
			totemsTable[TotemName(2062)] = {TotemTexture(2062), 2, "Earth Elemental Totem"}
			totemsTable[TotemName(2484)] = {TotemTexture(2484), 2, "Earthbind Totem"}
			totemsTable[TotemName(5730, "I")] = {TotemTexture(5730), 2, "Stoneclaw Totem I"}
			totemsTable[TotemName(6390, "II")] = {TotemTexture(6390), 2, "Stoneclaw Totem II"}
			totemsTable[TotemName(6391, "III")] = {TotemTexture(6391), 2, "Stoneclaw Totem III"}
			totemsTable[TotemName(6392, "IV")] = {TotemTexture(6392), 2, "Stoneclaw Totem IV"}
			totemsTable[TotemName(10427, "V")] = {TotemTexture(10427), 2, "Stoneclaw Totem V"}
			totemsTable[TotemName(10428, "VI")] = {TotemTexture(10428), 2, "Stoneclaw Totem VI"}
			totemsTable[TotemName(25525, "VII")] = {TotemTexture(25525), 2, "Stoneclaw Totem VII"}
			totemsTable[TotemName(58580, "VIII")] = {TotemTexture(58580), 2, "Stoneclaw Totem VIII"}
			totemsTable[TotemName(58581, "IX")] = {TotemTexture(58581), 2, "Stoneclaw Totem IX"}
			totemsTable[TotemName(58582, "X")] = {TotemTexture(58582), 2, "Stoneclaw Totem X"}
			totemsTable[TotemName(8071, "I")] = {TotemTexture(8071), 2, "Stoneskin Totem I"}
			totemsTable[TotemName(8154, "II")] = {TotemTexture(8154), 2, "Stoneskin Totem II"}
			totemsTable[TotemName(8155, "III")] = {TotemTexture(8155), 2, "Stoneskin Totem III"}
			totemsTable[TotemName(10406, "IV")] = {TotemTexture(10406), 2, "Stoneskin Totem IV"}
			totemsTable[TotemName(10407, "V")] = {TotemTexture(10407), 2, "Stoneskin Totem V"}
			totemsTable[TotemName(10408, "VI")] = {TotemTexture(10408), 2, "Stoneskin Totem VI"}
			totemsTable[TotemName(25508, "VII")] = {TotemTexture(25508), 2, "Stoneskin Totem VII"}
			totemsTable[TotemName(25509, "VIII")] = {TotemTexture(25509), 2, "Stoneskin Totem VIII"}
			totemsTable[TotemName(58751, "IX")] = {TotemTexture(58751), 2, "Stoneskin Totem IX"}
			totemsTable[TotemName(58753, "X")] = {TotemTexture(58753), 2, "Stoneskin Totem X"}
			totemsTable[TotemName(8075, "I")] = {TotemTexture(8075), 2, "Strength of Earth Totem I"}
			totemsTable[TotemName(8160, "II")] = {TotemTexture(8160), 2, "Strength of Earth Totem II"}
			totemsTable[TotemName(8161, "III")] = {TotemTexture(8161), 2, "Strength of Earth Totem III"}
			totemsTable[TotemName(10442, "IV")] = {TotemTexture(10442), 2, "Strength of Earth Totem IV"}
			totemsTable[TotemName(25361, "V")] = {TotemTexture(25361), 2, "Strength of Earth Totem V"}
			totemsTable[TotemName(25528, "VI")] = {TotemTexture(25528), 2, "Strength of Earth Totem VI"}
			totemsTable[TotemName(57622, "VII")] = {TotemTexture(57622), 2, "Strength of Earth Totem VII"}
			totemsTable[TotemName(58643, "VIII")] = {TotemTexture(58643), 2, "Strength of Earth Totem VIII"}
			totemsTable[TotemName(8143)] = {TotemTexture(8143), 2}
			--Fire Totems
			totemsTable[TotemName(2894)] = {TotemTexture(2894), 3, "Fire Elemental Totem"}
			totemsTable[TotemName(8227, "I")] = {TotemTexture(8227), 3, "Flametongue Totem I"}
			totemsTable[TotemName(8249, "II")] = {TotemTexture(8249), 3, "Flametongue Totem II"}
			totemsTable[TotemName(10526, "III")] = {TotemTexture(10526), 3, "Flametongue Totem III"}
			totemsTable[TotemName(16387, "IV")] = {TotemTexture(16387), 3, "Flametongue Totem IV"}
			totemsTable[TotemName(25557, "V")] = {TotemTexture(25557), 3, "Flametongue Totem V"}
			totemsTable[TotemName(58649, "VI")] = {TotemTexture(58649), 3, "Flametongue Totem VI"}
			totemsTable[TotemName(58652, "VII")] = {TotemTexture(58652), 3, "Flametongue Totem VII"}
			totemsTable[TotemName(58656, "VIII")] = {TotemTexture(58656), 3, "Flametongue Totem VIII"}
			totemsTable[TotemName(8181, "I")] = {TotemTexture(8181), 3, "Frost Resistance Totem I"}
			totemsTable[TotemName(10478, "II")] = {TotemTexture(10478), 3, "Frost Resistance Totem II"}
			totemsTable[TotemName(10479, "III")] = {TotemTexture(10479), 3, "Frost Resistance Totem III"}
			totemsTable[TotemName(25560, "IV")] = {TotemTexture(25560), 3, "Frost Resistance Totem IV"}
			totemsTable[TotemName(58741, "V")] = {TotemTexture(58741), 3, "Frost Resistance Totem V"}
			totemsTable[TotemName(58745, "VI")] = {TotemTexture(58745), 3, "Frost Resistance Totem VI"}
			totemsTable[TotemName(8190, "I")] = {TotemTexture(8190), 3, "Magma Totem I"}
			totemsTable[TotemName(10585, "II")] = {TotemTexture(10585), 3, "Magma Totem II"}
			totemsTable[TotemName(10586, "III")] = {TotemTexture(10586), 3, "Magma Totem III"}
			totemsTable[TotemName(10587, "IV")] = {TotemTexture(10587), 3, "Magma Totem IV"}
			totemsTable[TotemName(25552, "V")] = {TotemTexture(25552), 3, "Magma Totem V"}
			totemsTable[TotemName(58731, "VI")] = {TotemTexture(58731), 3, "Magma Totem VI"}
			totemsTable[TotemName(58734, "VII")] = {TotemTexture(58734), 3, "Magma Totem VII"}
			totemsTable[TotemName(3599, "I")] = {TotemTexture(3599), 3, "Searing Totem I"}
			totemsTable[TotemName(6363, "II")] = {TotemTexture(6363), 3, "Searing Totem II"}
			totemsTable[TotemName(6364, "III")] = {TotemTexture(6364), 3, "Searing Totem III"}
			totemsTable[TotemName(6365, "IV")] = {TotemTexture(6365), 3, "Searing Totem IV"}
			totemsTable[TotemName(10437, "V")] = {TotemTexture(10437), 3, "Searing Totem V"}
			totemsTable[TotemName(10438, "VI")] = {TotemTexture(10438), 3, "Searing Totem VI"}
			totemsTable[TotemName(25533, "VII")] = {TotemTexture(25533), 3, "Searing Totem VII"}
			totemsTable[TotemName(58699, "VIII")] = {TotemTexture(58699), 3, "Searing Totem VIII"}
			totemsTable[TotemName(58703, "IX")] = {TotemTexture(58703), 3, "Searing Totem IX"}
			totemsTable[TotemName(58704, "X")] = {TotemTexture(58704), 3, "Searing Totem X"}
			totemsTable[TotemName(30706, "I")] = {TotemTexture(30706), 3, "Totem of Wrath I"}
			totemsTable[TotemName(57720, "II")] = {TotemTexture(57720), 3, "Totem of Wrath II"}
			totemsTable[TotemName(57721, "III")] = {TotemTexture(57721), 3, "Totem of Wrath III"}
			totemsTable[TotemName(57722, "IV")] = {TotemTexture(57722), 3, "Totem of Wrath IV"}
			--Water Totems
			totemsTable[TotemName(8170)] = {TotemTexture(8170), 4, "Cleansing Totem"}
			totemsTable[TotemName(8184, "I")] = {TotemTexture(8184), 4, "Fire Resistance Totem I"}
			totemsTable[TotemName(10537, "II")] = {TotemTexture(10537), 4, "Fire Resistance Totem II"}
			totemsTable[TotemName(10538, "III")] = {TotemTexture(10538), 4, "Fire Resistance Totem III"}
			totemsTable[TotemName(25563, "IV")] = {TotemTexture(25563), 4, "Fire Resistance Totem IV"}
			totemsTable[TotemName(58737, "V")] = {TotemTexture(58737), 4, "Fire Resistance Totem V"}
			totemsTable[TotemName(58739, "VI")] = {TotemTexture(58739), 4, "Fire Resistance Totem VI"}
			totemsTable[TotemName(5394, "I")] = {TotemTexture(5394), 4, "Healing Stream Totem I"}
			totemsTable[TotemName(6375, "II")] = {TotemTexture(6375), 4, "Healing Stream Totem II"}
			totemsTable[TotemName(6377, "III")] = {TotemTexture(6377), 4, "Healing Stream Totem III"}
			totemsTable[TotemName(10462, "IV")] = {TotemTexture(10462), 4, "Healing Stream Totem IV"}
			totemsTable[TotemName(10463, "V")] = {TotemTexture(10463), 4, "Healing Stream Totem V"}
			totemsTable[TotemName(25567, "VI")] = {TotemTexture(25567), 4, "Healing Stream Totem VI"}
			totemsTable[TotemName(58755, "VII")] = {TotemTexture(58755), 4, "Healing Stream Totem VII"}
			totemsTable[TotemName(58756, "VIII")] = {TotemTexture(58756), 4, "Healing Stream Totem VIII"}
			totemsTable[TotemName(58757, "IX")] = {TotemTexture(58757), 4, "Healing Stream Totem IX"}
			totemsTable[TotemName(5675, "I")] = {TotemTexture(5675), 4, "Mana Spring Totem I"}
			totemsTable[TotemName(10495, "II")] = {TotemTexture(10495), 4, "Mana Spring Totem II"}
			totemsTable[TotemName(10496, "III")] = {TotemTexture(10496), 4, "Mana Spring Totem III"}
			totemsTable[TotemName(10497, "IV")] = {TotemTexture(10497), 4, "Mana Spring Totem IV"}
			totemsTable[TotemName(25570, "V")] = {TotemTexture(25570), 4, "Mana Spring Totem V"}
			totemsTable[TotemName(58771, "VI")] = {TotemTexture(58771), 4, "Mana Spring Totem VI"}
			totemsTable[TotemName(58773, "VII")] = {TotemTexture(58773), 4, "Mana Spring Totem VII"}
			totemsTable[TotemName(58774, "VIII")] = {TotemTexture(58774), 4, "Mana Spring Totem VIII"}
			totemsTable[TotemName(16190)] = {TotemTexture(16190), 4, "Mana Tide Totem"}
		end

		function Nameplate_GetTotemTable(name)
			-- feature disabled?
			if not config.showTotemIcons then
				-- delete the table if still exists.
				if totemsTable ~= nil then
					totemsTable = nil
				end
				return false
			end

			-- build the table if not already built.
			if not totemsTable then
				TotemsTable_Build()
			end

			if totemsTable and not totemsTable[name] then
				for _, totemTable in pairs(totemsTable) do
					if totemTable[3] and totemTable[3] == name then
						return totemTable
					end
				end
			end
			return totemsTable and totemsTable[name] or false
		end
	end

	-- :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

	-- makes sure the frame is a valid one
	local function NameplateIsValid(frame)
		if frame:GetName() then return end
		local overlayRegion = select(2, frame:GetRegions())
		return (overlayRegion and overlayRegion:GetObjectType() == "Texture" and overlayRegion:GetTexture() == [[Interface\Tooltips\Nameplate-Border]])
	end

	-- returns the nameplate reaction
	local function NameplateReaction(r, g, b, a)
		if r < 0.01 and b < 0.01 and g > 0.99 then
			return "FRIENDLY", "NPC"
		elseif r < 0.01 and b > 0.99 and g < 0.01 then
			return "FRIENDLY", "PLAYER"
		elseif r > 0.99 and b < 0.01 and g > 0.99 then
			return "NEUTRAL", "NPC"
		elseif r > 0.99 and b < 0.01 and g < 0.01 then
			return "HOSTILE", "NPC"
		else
			return "HOSTILE", "PLAYER"
		end
	end

	-- format the text of the health
	local Nameplate_FormatHealthText
	do
		local function Nameplate_ShortenHealthText(num)
			local res
			if num > 1000000000 then
				res = format("%.3fB", num / 1000000000)
			elseif num > 1000000 then
				res = format("%.2fM", num / 1000000)
			elseif num > 1000 then
				res = format("%.1fK", num / 1000)
			else
				res = floor(num)
			end
			return res
		end

		function Nameplate_FormatHealthText(self)
			if not self or not self.healthBar then
				return
			end
			if config.showHealthText or config.showHealthPercent then
				local minval, maxval = self.healthBar:GetMinMaxValues()
				local curval = self.healthBar:GetValue()

				if config.hideHealthFull and curval == maxval then
					self.text:Hide()
					return
				end

				local text = ""

				if config.showHealthText then
					text = text .. (config.shortenNumbers and Nameplate_ShortenHealthText(curval) or curval)
				end

				if config.showHealthMax and text ~= "" then
					text = text .. " / " .. (config.shortenNumbers and Nameplate_ShortenHealthText(maxval) or maxval)
				end

				if config.showHealthPercent then
					if text == "" then
						text = format("%." .. (config.decimals or 1) .. "f%%", 100 * curval / max(1, maxval))
					else
						text = text .. "  -  " .. format("%." .. (config.decimals or 1) .. "f%%", 100 * curval / max(1, maxval))
					end
				end

				self.text:SetText(text)
				if text ~= "" then
					self.text:Show()
				else
					self.text:Hide()
				end
			else
				self.text:SetText("")
				self.text:Hide()
			end
		end
	end

	-- handles casting time update
	local function CastBar_UpdateTime(self, curval)
		local minval, maxval = self:GetMinMaxValues()
		if self.channeling then
			self.time:SetFormattedText("%.1f", curval)
		else
			self.time:SetFormattedText("%.1f", maxval - curval)
		end
	end

	-- simply fixes the casting bar
	local function CastBar_Fix(self)
		self.castbarOverlay:Hide()

		self:SetHeight(5)
		self:ClearAllPoints()
		self:SetPoint("TOP", self.healthBar, "BOTTOM", 0, -4)
	end

	-- colorize the casting bar
	local function CastBar_Colorize(self, shielded)
		if shielded then
			self:SetStatusBarColor(0.8, 0.05, 0)
		end
	end

	local function CastBar_OnSizeChanged(self)
		self.needFix = true
	end

	local function CastBar_OnValueChanged(self, curval)
		CastBar_UpdateTime(self, curval)
		if self.needFix then
			CastBar_Fix(self)
			self.needFix = nil
		end
	end

	local function CastBar_OnShow(self)
		self.channeling = UnitChannelInfo("target")
		CastBar_Fix(self)
		CastBar_Colorize(self, self.shieldedRegion:IsShown())
	end

	local function CastBar_OnHide(self)
		self.spell:SetText("")
	end

	-- handles colorizing the casting bar
	local function CastBar_OnEvent(self, event, unit, spellname)
		if unit and self:IsShown() then
			CastBar_Colorize(self, event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
			-- self.spell:SetText(spellname or "")
		end
	end

	local function Health_OnValueChanged(oldbar, val)
		local plate = oldbar:GetParent()
		local minval, maxval = oldbar:GetMinMaxValues()
		plate.healthBar:SetMinMaxValues(minval, maxval)
		plate.healthBar:SetValue((val and (val == 1 and val ~= maxval) and 0 or val) or oldbar:GetValue())
	end

	local function Nameplate_CheckForChange(self)
		if changed then
			if changed == "barWidth" then
				self.healthBar:SetWidth(config.barWidth)
			elseif changed == "barHeight" then
				self.healthBar:SetHeight(config.barHeight)
			elseif changed == "barTexture" then
				local barTexture = core:MediaFetch("statusbar", config.barTexture)
				self.healthBar:SetStatusBarTexture(barTexture)
				self.castBar:SetStatusBarTexture(barTexture)
			elseif changed == "font" or changed == "fontSize" or changed == "fontOutline" then
				local font = core:MediaFetch("font", config.font)
				self.name:SetFont(font, config.fontSize, config.fontOutline)
				self.level:SetFont(font, config.fontSize, config.fontOutline)
				self.castBar.time:SetFont(font, config.fontSize, config.fontOutline)
			elseif changed == "textFont" or changed == "textFontSize" or changed == "textFontOutline" then
				self.text:SetFont(core:MediaFetch("font", config.textFont), config.textFontSize, config.textFontOutline)
			elseif changed == "hideName" or changed == "hideLevel" then
				core:ShowIf(self.name, not config.hideName)
				core:ShowIf(self.level, not config.hideLevel)
			elseif changed == "abbrevName" then
				self.name:SetText(config.abbrevName and core:Abbrev(self.oldname:GetText()) or self.oldname:GetText())
			elseif changed == "showHealthText" or changed == "showHealthPercent" then
				core:ShowIf(self.text, config.showHealthText or config.showHealthPercent)
			elseif changed == "arrow" then
				if not config.arrow or config.arrow == "NONE" then
					self.leftIndicator:SetTexture(nil)
					self.rightIndicator:SetTexture(nil)
				else
					self.leftIndicator:SetTexture(path .. "Textures\\Arrows\\" .. config.arrow)
					self.rightIndicator:SetTexture(path .. "Textures\\Arrows\\" .. config.arrow)
				end
			elseif changed == "textOfsX" or changed == "textOfsY" then
				self.text:SetPoint("CENTER", config.textOfsX or 0, config.textOfsY or 0)
			elseif changed == "tankColor" or changed == "tankMode" or changed == "customColor" or changed == "FRIENDLY" or changed == "NEUTRAL" or changed == "HOSTILE" then
				self:SetHealthColor()
			elseif changed == "showTotemIcons" then
				Nameplate_OnShow(self)
			end

			core.After(0.1, function() changed = nil end)
		end
	end

	local function Nameplate_SetHealthColor(self)
		if self.hasThreat then
			self.healthBar.reset = true
			self.healthBar:SetStatusBarColor(unpack(config.tankColor))
			return
		end

		self.marked = (self.raidicon:IsShown() == 1)
		local r, g, b

		if self.marked then
			local x, y = self.raidicon:GetTexCoord()
			self.raidIcon = RaidIconCoordinate[x][y]
			if config.raidIconColor and RaidIconColors[self.raidIcon] then
				r, g, b = unpack(RaidIconColors[self.raidIcon])
			end
		end

		if not (r and g and b) then
			r, g, b = self.oldHealth:GetStatusBarColor()

			-- using custom colors
			if config.customColor then
				-- change reaction and type if required.
				local nreact, ntype = NameplateReaction(r, g, b)
				if nreact ~= self.reaction or ntype ~= self.type then
					self.reaction, self.type = nreact, ntype
				end
				nreact, ntype = nil, nil

				-- we use custom colors only for non-players.
				if self.reaction and config[self.reaction] and self.type ~= "PLAYER" then
					r, g, b = unpack(config[self.reaction])
				end
			end
		end

		if self.healthBar.reset or r ~= self.healthBar.r or g ~= self.healthBar.g or b ~= self.healthBar.b then
			self.healthBar.r, self.healthBar.g, self.healthBar.b = r, g, b
			self.healthBar.reset = nil
			self.healthBar:SetStatusBarColor(r, g, b)
		end
	end

	local function Nameplate_OnEnter(self)
		if self.highlight and not self.totem then
			self.highlight:Show()
		end
	end

	local function Nameplate_OnLeave(self)
		if self.highlight and not self.totem then
			self.highlight:Hide()
		end
	end

	local function Nameplate_UpdateCritical(self)
		if self.glow:IsVisible() then
			self.glow.wasVisible = true

			if config.tankMode then
				local r, g, b = self.glow:GetVertexColor()
				self.hasThreat = (g + b) < 0.1

				if self.hasThreat then
					self:SetHealthColor()
				end
			end
		elseif self.glow.wasVisible then
			self.glow.wasVisible = nil

			if self.hasThreat then
				self.hasThreat = nil
				self:SetHealthColor()
			end
		end

		if self.oldHighlight:IsShown() then
			if not self.highlighted then
				self.highlighted = true
				self:OnEnter()
			end
		elseif self.highlighted then
			self.highlighted = nil
			self:OnLeave()
		end
	end

	-- nameplate OnUpdate
	function Nameplate_OnUpdate(self, elapsed)
		self.elapsed = (self.elapsed or 0) + elapsed
		if self.elapsed >= 0.01 then
			self:CheckForChange()
			self:UpdateCritical()
			self:SetHealthColor()
			self:FormatHealthText()
			core:ShowIf(self.name, not config.hideName and not self.totem)
			core:ShowIf(self.level, not config.hideLevel and not self.totem)
			core:ShowIf(self.healthBar, not self.totem)
			core:ShowIf(self.bg, not self.totem)

			if targetExists and self:GetAlpha() == 1 then
				self.healthBar:SetWidth(config.barWidth * 1.15)
				self.castBar:SetWidth(config.barWidth * 1.15)
				core:ShowIf(self.leftIndicator, not self.totem)
				core:ShowIf(self.rightIndicator, not self.totem)
				if not config.arrow or config.arrow == "NONE" then
					self.healthBar.borderLeft:SetTexture(0.8, 0.8, 0.8)
					self.healthBar.borderRight:SetTexture(0.8, 0.8, 0.8)
					self.healthBar.borderTop:SetTexture(0.8, 0.8, 0.8)
					self.healthBar.borderBottom:SetTexture(0.8, 0.8, 0.8)
				else
					self.healthBar.borderLeft:SetTexture(0, 0, 0)
					self.healthBar.borderRight:SetTexture(0, 0, 0)
					self.healthBar.borderTop:SetTexture(0, 0, 0)
					self.healthBar.borderBottom:SetTexture(0, 0, 0)
				end
			else
				self.healthBar:SetWidth(config.barWidth)
				self.castBar:SetWidth(config.barWidth)
				self.leftIndicator:Hide()
				self.rightIndicator:Hide()
				self.healthBar.borderLeft:SetTexture(0, 0, 0)
				self.healthBar.borderRight:SetTexture(0, 0, 0)
				self.healthBar.borderTop:SetTexture(0, 0, 0)
				self.healthBar.borderBottom:SetTexture(0, 0, 0)
			end

			self.elapsed = 0
		end
	end

	-- handles frame's show
	function Nameplate_OnShow(self)
		self.healthBar:ClearAllPoints()
		self.healthBar:SetPoint("CENTER", self.healthBar:GetParent())
		self.healthBar:SetWidth(config.barWidth)
		self.healthBar:SetHeight(config.barHeight)

		self.castBar:ClearAllPoints()
		self.castBar:SetPoint("TOP", self.healthBar, "BOTTOM", 0, -4)
		self.castBar:SetWidth(config.barWidth)
		self.castBar:SetHeight(config.barHeight)

		self.highlight:ClearAllPoints()
		self.highlight:SetAllPoints(self.healthBar)

		self.name:SetJustifyH("LEFT")
		self.name:SetText(config.abbrevName and core:Abbrev(self.oldname:GetText()) or self.oldname:GetText())
		self.name:SetPoint("BOTTOMLEFT", self.healthBar, "TOPLEFT", 0, 3)
		self.name:SetPoint("RIGHT", self.healthBar, -15, 3)
		core:ShowIf(self.name, not config.hideName)

		local level = self.level:GetText() or ""
		self.level:SetJustifyH("RIGHT")
		self.level:ClearAllPoints()
		self.level:SetPoint("BOTTOMRIGHT", self.healthBar, "TOPRIGHT", 3, 3)
		if self.boss:IsShown() then
			self.level:SetText("B")
			self.level:SetTextColor(0.8, 0.05, 0)
		else
			self.level:SetText(level .. (self.elite:IsShown() and "+" or ""))
		end
		core:ShowIf(self.level, not config.hideLevel)

		if config.arenaUnitNumber then
			if IsActiveBattlefieldArena() then
				for i = 1, 5 do
					if UnitExists("arena" .. i) and (GetUnitName("arena" .. i) == self.oldname:GetText() or GetUnitName("arena" .. i) == self.oldname:GetText() .. " (*)") then
						self.name:SetText(i)
						break
					end
				end
			elseif self.name:GetText() ~= self.oldname:GetText() then
				self.name:SetText(config.abbrevName and core:Abbrev(self.oldname:GetText()) or self.oldname:GetText())
			end
		end

		self:UpdateCritical()
		Health_OnValueChanged(self.oldHealth, self.oldHealth:GetValue())

		local totemTable = Nameplate_GetTotemTable(self.oldname:GetText())
		if totemTable then
			if not self.totem then
				self.totem = self:CreateTexture(nil, "BACKGROUND")
				self.totem:SetPoint("BOTTOM", self, "TOP")
				self.totem:SetSize(24, 24)
				self.totem:SetAlpha(0.85)
				self.totem:SetTexture(totemTable[1])
				self.totem:SetTexCoord(0.15, 0.85, 0.15, 0.85)
			else
				self.totem:SetTexture(totemTable[1])
				self.totem:Show()
			end
		elseif self.totem then
			self.totem:Hide()
			self.totem = nil
		end
	end

	function Nameplate_OnHide(self)
		self.highlight:Hide()
	end

	local function Nameplate_CreateBorders(healthBar)
		if not healthBar.borderLeft then
			healthBar.borderLeft = healthBar:CreateTexture(nil, "BORDER")
			healthBar.borderLeft:SetPoint("TOPLEFT", healthBar, "TOPLEFT", -1, 1)
			healthBar.borderLeft:SetPoint("BOTTOMLEFT", healthBar, "BOTTOMLEFT", -1, -1)
			healthBar.borderLeft:SetTexture(0, 0, 0)
			healthBar.borderLeft:SetWidth(1)
		end
		if not healthBar.borderRight then
			healthBar.borderRight = healthBar:CreateTexture(nil, "BORDER")
			healthBar.borderRight:SetPoint("TOPRIGHT", healthBar, "TOPRIGHT", 1, 1)
			healthBar.borderRight:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", 1, -1)
			healthBar.borderRight:SetTexture(0, 0, 0)
			healthBar.borderRight:SetWidth(1)
		end
		if not healthBar.borderTop then
			healthBar.borderTop = healthBar:CreateTexture(nil, "BORDER")
			healthBar.borderTop:SetPoint("TOPLEFT", healthBar, "TOPLEFT", -1, 1)
			healthBar.borderTop:SetPoint("TOPRIGHT", healthBar, "TOPRIGHT", 1, 1)
			healthBar.borderTop:SetTexture(0, 0, 0)
			healthBar.borderTop:SetHeight(1)
		end
		if not healthBar.borderBottom then
			healthBar.borderBottom = healthBar:CreateTexture(nil, "BORDER")
			healthBar.borderBottom:SetPoint("BOTTOMLEFT", healthBar, "BOTTOMLEFT", -1, -1)
			healthBar.borderBottom:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", 1, -1)
			healthBar.borderBottom:SetTexture(0, 0, 0)
			healthBar.borderBottom:SetHeight(1)
		end
	end

	-- creates the frame
	function Nameplate_Create(frame)
		if frame.done then
			return
		end
		frame.done = true

		local oldHeath, castBar = frame:GetChildren()
		frame.castBar = castBar

		frame.oldHealth = oldHeath
		frame.oldHealth:Hide()

		local healthBar = CreateFrame("StatusBar", nil, frame)
		frame.healthBar = healthBar
		frame.oldHealth:SetScript("OnValueChanged", Health_OnValueChanged)

		local glowRegion, overlayRegion, castbarOverlay, shieldedRegion, spellIconRegion, highlightRegion, nameTextRegion, levelTextRegion, bossIconRegion, raidIconRegion, stateIconRegion = frame:GetRegions()
		frame.oldname = nameTextRegion
		nameTextRegion:Hide()

		local name = frame:CreateFontString()
		name:SetPoint("BOTTOM", healthBar, "TOP", 0, 1)
		name:SetFont(core:MediaFetch("font", config.font), config.fontSize, config.fontOutline)
		name:SetTextColor(0.84, 0.75, 0.65)
		name:SetShadowOffset(1.25, -1.25)
		name:SetJustifyH("LEFT")
		name:SetJustifyV("BOTTOM")
		frame.name = name
		core:ShowIf(frame.name, not config.hideName)

		levelTextRegion:SetFont(core:MediaFetch("font", config.font), config.fontSize, config.fontOutline)
		levelTextRegion:SetShadowOffset(1.25, -1.25)
		levelTextRegion:SetJustifyH("RIGHT")
		levelTextRegion:SetJustifyV("BOTTOM")
		frame.level = levelTextRegion
		core:ShowIf(frame.level, not config.hideLevel)

		healthBar:SetStatusBarTexture(core:MediaFetch("statusbar", config.barTexture))
		healthBar.hpBackground = healthBar:CreateTexture(nil, "BORDER")
		healthBar.hpBackground:SetAllPoints(healthBar)
		healthBar.hpBackground:SetTexture(config.barTexture)
		healthBar.hpBackground:SetVertexColor(0.15, 0.15, 0.15)

		Nameplate_CreateBorders(healthBar)

		frame.overlay = CreateFrame("Frame", nil, frame)
		frame.overlay:SetAllPoints(frame.healthBar)
		frame.overlay:SetFrameLevel(frame.healthBar:GetFrameLevel() + 1)

		frame.oldHighlight = highlightRegion
		frame.highlight = frame.overlay:CreateTexture(nil, "ARTWORK")
		frame.highlight:SetAllPoints(frame.healthBar)
		frame.highlight:SetTexture(core:MediaFetch("statusbar", config.barTexture))
		frame.highlight:SetBlendMode("ADD")
		frame.highlight:SetVertexColor(1, 1, 1, 0.35)
		frame.highlight:Hide()

		local text = frame.overlay:CreateFontString(nil, "OVERLAY")
		text:SetFont(core:MediaFetch("font", config.textFont), config.textFontSize, config.textFontOutline)
		text:SetPoint("CENTER", config.textOfsX or 0, config.textOfsY or 1)
		text:SetTextColor(0.84, 0.75, 0.65)
		text:SetJustifyH("CENTER")
		text:SetJustifyV("MIDDLE")
		text:SetShadowOffset(1.25, -1.25)
		text:Hide()
		frame.text = text

		frame.FormatHealthText = Nameplate_FormatHealthText
		frame:FormatHealthText()

		castBar.castbarOverlay = castbarOverlay
		castBar.healthBar = healthBar
		castBar.shieldedRegion = shieldedRegion
		castBar:SetStatusBarTexture(core:MediaFetch("statusbar", config.barTexture))

		castBar:HookScript("OnShow", CastBar_OnShow)
		-- castBar:HookScript("OnHide", CastBar_OnHide)
		castBar:HookScript("OnSizeChanged", CastBar_OnSizeChanged)
		castBar:HookScript("OnValueChanged", CastBar_OnValueChanged)
		castBar:HookScript("OnEvent", CastBar_OnEvent)
		-- castBar:RegisterEvent("UNIT_SPELLCAST_START")
		-- castBar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
		castBar:RegisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
		castBar:RegisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")

		castBar.time = castBar:CreateFontString(nil, "ARTWORK")
		castBar.time:SetPoint("RIGHT", castBar, "LEFT", -2, 1)
		castBar.time:SetFont(core:MediaFetch("font", config.font), config.fontSize, config.fontOutline)
		castBar.time:SetTextColor(0.84, 0.75, 0.65)
		castBar.time:SetShadowOffset(1.25, -1.25)

		-- castBar.spell = castBar:CreateFontString(nil, "ARTWORK")
		-- castBar.spell:SetPoint("TOP", castBar, "BOTTOM", 0, -2)
		-- castBar.spell:SetFont(core:MediaFetch("font", config.font), config.fontSize, config.fontOutline)
		-- castBar.spell:SetTextColor(0.84, 0.75, 0.65)
		-- castBar.spell:SetShadowOffset(1.25, -1.25)

		castBar.bg = castBar:CreateTexture(nil, "BORDER")
		castBar.bg:SetAllPoints(castBar)
		castBar.bg:SetTexture(config.barTexture)
		castBar.bg:SetVertexColor(0.15, 0.15, 0.15)

		castBar.glow = CreateFrame("Frame", nil, castBar)
		castBar.glow:SetPoint("TOPLEFT", castBar, "TOPLEFT", -4.5, 4)
		castBar.glow:SetPoint("BOTTOMRIGHT", castBar, "BOTTOMRIGHT", 4.5, -4.5)
		castBar.glow:SetBackdrop(backdrop)
		castBar.glow:SetBackdropColor(0, 0, 0)
		castBar.glow:SetBackdropBorderColor(0, 0, 0)

		spellIconRegion:SetHeight(0.01)
		spellIconRegion:SetWidth(0.01)

		raidIconRegion:ClearAllPoints()
		raidIconRegion:SetPoint("BOTTOM", healthBar, "TOP", 0, config.barHeight + 3)
		raidIconRegion:SetSize(15, 15)
		frame.raidicon = raidIconRegion

		frame.glow = glowRegion
		frame.elite = stateIconRegion
		frame.boss = bossIconRegion

		bossIconRegion:SetTexture(nil)
		castbarOverlay:SetTexture(nil)
		glowRegion:SetTexture(nil)
		highlightRegion:SetTexture(nil)
		overlayRegion:SetTexture(nil)
		shieldedRegion:SetTexture(nil)
		stateIconRegion:SetTexture(nil)

		frame.bg = frame:CreateTexture(nil, "BACKGROUND")
		frame.bg:SetTexture(config.solidTexture)
		frame.bg:SetVertexColor(0, 0, 0, 0.75)
		frame.bg:SetAllPoints(healthBar)

		local right = frame:CreateTexture(nil, "BACKGROUND")
		right:SetPoint("LEFT", frame.healthBar, "RIGHT")
		right:SetRotation(1.57)
		right:SetSize(32, 32)
		right:Hide()

		local left = frame:CreateTexture(nil, "BACKGROUND")
		left:SetPoint("RIGHT", frame.healthBar, "LEFT")
		left:SetRotation(-1.57)
		left:SetSize(32, 32)
		left:Hide()

		if config.arrow and config.arrow ~= "NONE" then
			right:SetTexture(path .. "Textures\\Arrows\\" .. config.arrow)
			left:SetTexture(path .. "Textures\\Arrows\\" .. config.arrow)
		end

		frame.rightIndicator = right
		frame.leftIndicator = left

		frame.OnEnter = Nameplate_OnEnter
		frame.OnLeave = Nameplate_OnLeave
		frame.CheckForChange = Nameplate_CheckForChange
		frame.SetHealthColor = Nameplate_SetHealthColor
		frame.UpdateCritical = Nameplate_UpdateCritical

		local r, g, b = oldHeath:GetStatusBarColor()
		frame.reaction, frame.type = NameplateReaction(r, g, b)
		frame.class = ClassReference[ColorToString(r, g, b)]

		frame:SetScript("OnShow", Nameplate_OnShow)
		frame:SetScript("OnHide", Nameplate_OnHide)
		Nameplate_OnShow(frame)

		frame:SetScript("OnUpdate", Nameplate_OnUpdate)
	end

	-- :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

	local SlashCommandHandler
	do
		local commands = {}
		local help = "|cffffd700%s|r: %s"

		commands.toggle = function()
			DB.enabled = not DB.enabled
		end

		commands.enable = function()
			DB.enabled = false
		end
		commands.on = commands.enable

		commands.disable = function()
			DB.enabled = false
		end
		commands.off = commands.disable

		commands.fontsize = function(num)
			num = tonumber(num)
			if num then
				DB.fontSize = num
				config.fontSize = num
			end
		end
		commands.size = commands.fontsize

		commands.hptext = function()
			DB.showHealthText = not DB.showHealthText
		end
		commands.health = commands.hptext

		commands.hpmax = function()
			DB.showHealthMax = not DB.showHealthMax
		end
		commands.max = commands.hpmax

		commands.hppercent = function()
			DB.showHealthPercent = not DB.showHealthPercent
		end
		commands.percent = commands.hppercent

		commands.shorten = function()
			DB.shortenNumbers = not DB.shortenNumbers
		end
		commands.short = commands.shorten

		commands.height = function(num)
			num = tonumber(num)
			if num then
				DB.barHeight = num
				config.barHeight = num
			end
		end
		commands.barHeight = commands.height

		commands.width = function(num)
			num = tonumber(num)
			if num then
				DB.barWidth = num
				config.barWidth = num
			end
		end
		commands.barWidth = commands.width

		commands.config = function()
			core:OpenConfig("Options", "Nameplates")
		end
		commands.options = commands.config

		function SlashCommandHandler(msg)
			local cmd, rest = strsplit(" ", msg, 2)
			cmd = cmd:lower()

			if type(commands[cmd]) == "function" then
				commands[cmd](rest)
				if cmd ~= "config" and cmd ~= "options" then
					ReloadUI()
				end
			else
				Print(L:F("Acceptable commands for: |caaf49141%s|r", "/np"))
				print(format(help, "enable", L["enable module"]))
				print(format(help, "disable", L["disable module"]))
				print(format(help, "fontsize|r |cff00ffffn|r", L["changes nameplates font size"]))
				print(format(help, "width|r |cff00ffffn|r", L["changes nameplates width"]))
				print(format(help, "height|r |cff00ffffn|r", L["changes nameplates height"]))
				print(format(help, "health", L["toggles health text"]))
				print(format(help, "max", L["toggles max health text"]))
				print(format(help, "shorten", L["shortens health text"]))
				print(format(help, "percent", L["toggles health percentage"]))
				print(format(help, "config", L["Access module settings."]))
			end
		end
	end

	local function SetupDatabase()
		if not DB then
			if type(core.db.Nameplates) ~= "table" or next(core.db.Nameplates) == nil then
				core.db.Nameplates = CopyTable(defaults)
			end

			-- just in case config were missing after update.
			for k, v in pairs(defaults) do
				if core.db.Nameplates[k] == nil then
					core.db.Nameplates[k] = v
				end
			end

			DB = core.db.Nameplates

			for k, v in pairs(DB) do
				config[k] = v
			end
		end
		if not CharDB then
			if type(core.char.Nameplates) ~= "table" or next(core.char.Nameplates) == nil then
				core.char.Nameplates = CopyTable(defaultsChar)
			end

			for k, v in pairs(defaultsChar) do
				if core.char.Nameplates[k] == nil then
					core.char.Nameplates[k] = v
				end
			end
			CharDB = core.char.Nameplates

			for k, v in pairs(CharDB) do
				config[k] = v
			end
		end
	end

	function GetOptions()
		if not options then
			local _disabled = function()
				return (not DB.enabled or disabled)
			end

			options = {
				type = "group",
				name = L["Nameplates"],
				get = function(i)
					return config[i[#i]]
				end,
				set = function(i, val)
					DB[i[#i]] = val
					config[i[#i]] = val
					changed = i[#i]
				end,
				args = {
					status = {
						type = "description",
						name = L:F("This module is disabled because you are using: |cffffd700%s|r", reason or UNKNOWN),
						fontSize = "medium",
						order = 0,
						hidden = not disabled
					},
					desc = {
						type = "description",
						name = L["Some settings require UI to be reloaded."],
						order = 0.1,
						width = "full"
					},
					enabled = {
						type = "toggle",
						name = L["Enable"],
						order = 1,
						disabled = disabled
					},
					reset = {
						type = "execute",
						name = RESET,
						order = 2,
						disabled = _disabled,
						confirm = function()
							return L:F("Are you sure you want to reset %s to default?", "Nameplates")
						end,
						func = function()
							wipe(core.db.Nameplates)
							wipe(core.char.Nameplates)
							DB, CharDB = nil, nil
							SetupDatabase()
							Print(L["module's settings reset to default."])
							ReloadUI()
						end
					},
					appearance = {
						type = "group",
						name = L["Appearance"],
						order = 3,
						inline = true,
						disabled = _disabled,
						args = {
							barWidth = {
								type = "range",
								name = L["Width"],
								order = 1,
								min = 80,
								max = 250,
								step = 0.01,
								bigStep = 1
							},
							barHeight = {
								type = "range",
								name = L["Height"],
								order = 2,
								min = 6,
								max = 30,
								step = 0.01,
								bigStep = 1
							},
							barTexture = {
								type = "select",
								name = L["Texture"],
								dialogControl = "LSM30_Statusbar",
								order = 3,
								values = AceGUIWidgetLSMlists.statusbar
							},
							font = {
								type = "select",
								name = L["Font"],
								dialogControl = "LSM30_Font",
								order = 4,
								values = AceGUIWidgetLSMlists.font
							},
							fontSize = {
								type = "range",
								name = L["Font Size"],
								order = 5,
								min = 6,
								max = 30,
								step = 1
							},
							fontOutline = {
								type = "select",
								name = L["Font Outline"],
								order = 6,
								values = {
									[""] = NONE,
									["OUTLINE"] = L["Outline"],
									["THINOUTLINE"] = L["Thin outline"],
									["THICKOUTLINE"] = L["Thick outline"],
									["MONOCHROME"] = L["Monochrome"],
									["OUTLINEMONOCHROME"] = L["Outlined monochrome"]
								}
							},
							hideName = {
								type = "toggle",
								name = L["Hide Name"],
								order = 8
							},
							abbrevName = {
								type = "toggle",
								name = L["Abbreviation"],
								order = 9
							},
							hideLevel = {
								type = "toggle",
								name = L["Hide Level"],
								order = 10
							},
							raidIconColor = {
								type = "toggle",
								name = L["Raid Icon Color"],
								order = 11
							},
							arenaUnitNumber = {
								type = "toggle",
								name = L["Arena Unit Number"],
								desc = L["In arena, names will be changed to arena unit numbers."],
								order = 12
							},
							showTotemIcons = {
								type = "toggle",
								name = L["Show Totems Icons"],
								desc = L["Shows totem icons instead of nameplates."],
								order = 13
							}
						}
					},
					healthtext = {
						type = "group",
						name = L["Health Text"],
						order = 4,
						inline = true,
						disabled = _disabled,
						args = {
							showHealthText = {
								type = "toggle",
								name = L["Show Health Text"],
								order = 1
							},
							showHealthMax = {
								type = "toggle",
								name = L["Show Max Health"],
								order = 2
							},
							shortenNumbers = {
								type = "toggle",
								name = L["Shorten Health Text"],
								order = 3
							},
							showHealthPercent = {
								type = "toggle",
								name = L["Show Health Percent"],
								order = 4
							},
							hideHealthFull = {
								type = "toggle",
								name = L["Hide text when health is full"],
								order = 5,
								width = "double"
							},
							textFont = {
								type = "select",
								name = L["Font"],
								dialogControl = "LSM30_Font",
								values = AceGUIWidgetLSMlists.font,
								order = 6
							},
							textFontSize = {
								type = "range",
								name = L["Font Size"],
								order = 7,
								min = 6,
								max = 30,
								step = 1
							},
							textFontOutline = {
								type = "select",
								name = L["Font Outline"],
								order = 8,
								values = {
									[""] = NONE,
									["OUTLINE"] = L["Outline"],
									["THINOUTLINE"] = L["Thin outline"],
									["THICKOUTLINE"] = L["Thick outline"],
									["MONOCHROME"] = L["Monochrome"],
									["OUTLINEMONOCHROME"] = L["Outlined monochrome"]
								}
							},
							decimals = {
								type = "range",
								name = L["Decimals"],
								order = 9,
								min = 0,
								max = 3,
								step = 1
							},
							textOfsX = {
								type = "range",
								name = L["X Offset"],
								order = 10,
								min = -125,
								max = 125,
								step = 0.01,
								bigStep = 1
							},
							textOfsY = {
								type = "range",
								name = L["Y Offset"],
								order = 11,
								min = -15,
								max = 15,
								step = 0.01,
								bigStep = 0.1
							}
						}
					},
					custom = {
						type = "group",
						name = L["Custom Colors"],
						order = 98,
						inline = true,
						disabled = _disabled,
						args = {
							customColor = {
								type = "toggle",
								name = L["Enable"],
								order = 1
							},
							FRIENDLY = {
								type = "color",
								name = FACTION_STANDING_LABEL5,
								get = function()
									return unpack(config.FRIENDLY)
								end,
								set = function(_, r, g, b)
									DB.FRIENDLY[1], config.FRIENDLY[1] = r, r
									DB.FRIENDLY[2], config.FRIENDLY[2] = g, g
									DB.FRIENDLY[3], config.FRIENDLY[3] = b, b
									changed = "FRIENDLY"
								end,
								disabled = function() return not config.customColor end,
								order = 2
							},
							NEUTRAL = {
								type = "color",
								name = FACTION_STANDING_LABEL4,
								get = function()
									return unpack(config.NEUTRAL)
								end,
								set = function(_, r, g, b)
									DB.NEUTRAL[1], config.NEUTRAL[1] = r, r
									DB.NEUTRAL[2], config.NEUTRAL[2] = g, g
									DB.NEUTRAL[3], config.NEUTRAL[3] = b, b
									changed = "NEUTRAL"
								end,
								disabled = function() return not config.customColor end,
								order = 3
							},
							HOSTILE = {
								type = "color",
								name = FACTION_STANDING_LABEL2,
								get = function()
									return unpack(config.HOSTILE)
								end,
								set = function(_, r, g, b)
									DB.HOSTILE[1], config.HOSTILE[1] = r, r
									DB.HOSTILE[2], config.HOSTILE[2] = g, g
									DB.HOSTILE[3], config.HOSTILE[3] = b, b
									changed = "HOSTILE"
								end,
								disabled = function() return not config.customColor end,
								order = 4
							}
						}
					},
					tank = {
						type = "group",
						name = L["Tank Mode"],
						order = 99,
						inline = true,
						disabled = _disabled,
						args = {
							tankMode = {
								type = "toggle",
								name = L["Enable"],
								order = 1,
								disabled = _disabled,
								get = function()
									return CharDB.tankMode
								end,
								set = function(_, val)
									CharDB.tankMode = val
								end
							},
							tankColor = {
								type = "color",
								name = L["Bar Color"],
								desc = L["Bar color when you have threat."],
								order = 2,
								disabled = _disabled,
								get = function()
									return unpack(CharDB.tankColor or config.tankColor)
								end,
								set = function(_, r, g, b, a)
									CharDB.tankColor = {r, g, b, a}
								end
							}
						}
					},
					arrow = {
						type = "multiselect",
						name = L["Target Highlight"],
						order = 100,
						width = "half",
						disabled = _disabled,
						get = function(_, key)
							return (config.arrow == key) or (key == "NONE" and config.arrow == "NONE")
						end,
						set = function(_, val)
							DB.arrow = val
							config.arrow = val
							changed = "arrow"
						end,
						values = {}
					}
				}
			}
		end

		options.args.arrow.values.NONE = NONE
		for i = 0, 73 do
			options.args.arrow.values["arrow" .. i] = "|T" .. path .. "Textures\\Arrows\\arrow" .. i .. ".tga:32:32|t"
		end

		return options
	end

	core:RegisterForEvent("PLAYER_LOGIN", function()
		disabled, reason = core:AddOnIsLoaded("TidyPlates", "Kui_Nameplates", "KuiNameplates", "Neatplates", "dNameplates", "Plater", "ThreatPlates", "caelNamePlates", "Aloft")
		SetupDatabase()
		core.options.args.Options.args.Nameplates = GetOptions()

		-- class references
		for class, ctable in pairs(core.classcolors) do
			ClassReference[ColorToString(ctable.r, ctable.g, ctable.b)] = class
		end
	end)

	do
		-- nameplates OnUpdate handler
		local lastUpdate = 0
		-- used to update only if needed.
		local lastChildCount, newChildCount = 0, 0

		local function Nameplates_OnUpdate(self, elapsed)
			lastUpdate = lastUpdate + elapsed

			if lastUpdate > 0.1 then
				lastUpdate = 0
				newChildCount = WorldFrame:GetNumChildren()
				if lastChildCount ~= newChildCount then
					lastChildCount = newChildCount
					for i = 1, select("#", WorldFrame:GetChildren()) do
						local f = select(i, WorldFrame:GetChildren())
						if NameplateIsValid(f) and not f.done then
							Nameplate_Create(f)
						end
					end
				end
			end
		end

		-- on mod loaded.
		core:RegisterForEvent("PLAYER_ENTERING_WORLD", function()
			if disabled then
				NP:UnregisterAllEvents()
				NP:SetScript("OnUpdate", nil)
				NP:Hide()
				return
			end

			SetupDatabase()
			if DB.enabled then
				NP:RegisterEvent("PLAYER_TARGET_CHANGED")
				NP:SetScript("OnUpdate", Nameplates_OnUpdate)
				NP:Show()
			else
				NP:UnregisterAllEvents()
				NP:SetScript("OnUpdate", nil)
				NP:Hide()
			end
		end)
	end

	SLASH_KPACKNAMEPLATES1 = "/np"
	SLASH_KPACKNAMEPLATES2 = "/nameplates"
	SlashCmdList["KPACKNAMEPLATES"] = SlashCommandHandler
end)