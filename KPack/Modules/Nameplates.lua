assert(KPack, "KPack not found!")
KPack:AddModule("Nameplates", function(_, core, L)
	if core:IsDisabled("Nameplates") or core.ElvUI then return end

	local LSM = core.LSM or LibStub("LibSharedMedia-3.0")

	-- SavedVariables
	local DB, CharDB, changed, disabled
	local defaults = {
		enabled = true,
		barTexture = "KPack",
		barWidth = 120,
		barHeight = 12,
		font = "Yanone",
		fontSize = 11,
		fontOutline = "THINOUTLINE",
		hideName = false,
		hideLevel = false,
		showHealthText = false,
		showHealthMax = false,
		shortenNumbers = true,
		showHealthPercent = false,
		textFont = "Yanone",
		textFontSize = 11,
		textFontOutline = "THINOUTLINE"
	}
	local defaultsChar = {
		tankMode = false,
		tankColor = {0.2, 0.9, 0.1, 1}
	}

	-- ::::::::::::::::::::::::: START of Configuration ::::::::::::::::::::::::: --

	local config = {
		glowTexture = [[Interface\AddOns\KPack\Media\Textures\glowTex]],
		solidTexture = [[Interface\Buttons\WHITE8X8]],
		tankMode = false,
		tankColor = {0.2, 0.9, 0.1, 1}
	}

	-- Non-Latin Font Bypass
	if core.nonLatin then
		config.font = NAMEPLATE_FONT -- here goes the path
	end

	-- :::::::::::::::::::::::::: END of Configuration ::::::::::::::::::::::::: --

	local backdrop = {
		edgeFile = config.glowTexture,
		edgeSize = 5,
		insets = {left = 3, right = 2, top = 3, bottom = 2}
	}

	local _type, _select = type, select
	local _format = string.format
	local math_max = math.max
	local math_floor = math.floor
	local unpack = unpack
	local UnitExists = UnitExists
	local targetExists
	local ShowHide

	-- events frame
	local frame = CreateFrame("Frame")
	core.NP = config

	-- module's print function
	local function Print(msg)
		if msg then
			core:Print(msg, "Nameplates")
		end
	end

	-- :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

	-- makes sure the frame is a valid one
	local function NameplateIsValid(frame)
		if frame:GetName() then return end
		local overlayRegion = _select(2, frame:GetRegions())
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
		local function Nameplate_Shorten(num)
			local res
			if num > 1000000000 then
				res = format("%02.3fB", num / 1000000000)
			elseif num > 1000000 then
				res = format("%02.2fM", num / 1000000)
			elseif num > 1000 then
				res = format("%02.1fK", num / 1000)
			else
				res = math_floor(num)
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
				local text = ""

				if config.showHealthText then
					text = text .. (config.shortenNumbers and Nameplate_Shorten(curval) or curval)
				end

				if config.showHealthMax and text ~= "" then
					text = text .. " / " .. (config.shortenNumbers and Nameplate_Shorten(maxval) or maxval)
				end

				if config.showHealthPercent then
					if text == "" then
						text = _format("%02.1f%%", 100 * curval / math_max(1, maxval))
					else
						text = text .. "  -  " .. _format("%02.1f%%", 100 * curval / math_max(1, maxval))
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

	-- handles colorizing the casting bar
	local function CastBar_OnEvent(self, event, unit)
		if unit == "target" then
			if self:IsShown() then
				CastBar_Colorize(self, event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
			end
		end
	end

	local function Health_OnValueChanged(oldbar, val)
		local plate = oldbar:GetParent()
		local minval, maxval = oldbar:GetMinMaxValues()
		plate.healthBar:SetMinMaxValues(minval, maxval)
		plate.healthBar:SetValue(val or oldbar:GetValue())
	end

	local Nameplate_CheckForChange
	do
		function ShowHide(f, cond)
			if not f or not f.Show then
				return
			elseif cond and not f:IsShown() then
				f:Show()
			elseif not cond and f:IsShown() then
				f:Hide()
			end
		end

		function Nameplate_CheckForChange(self)
			if changed then
				if changed == "barWidth" then
					self.healthBar:SetWidth(config.barWidth)
				elseif changed == "barHeight" then
					self.healthBar:SetHeight(config.barHeight)
				elseif changed == "barTexture" then
					local barTexture = LSM:Fetch("statusbar", config.barTexture)
					self.healthBar:SetStatusBarTexture(barTexture)
					self.castBar:SetStatusBarTexture(barTexture)
				elseif changed == "font" or changed == "fontSize" or changed == "fontOutline" then
					local font = LSM:Fetch("font", config.font)
					self.name:SetFont(font, config.fontSize, config.fontOutline)
					self.level:SetFont(font, config.fontSize, config.fontOutline)
					self.castBar.time:SetFont(font, config.fontSize, config.fontOutline)
				elseif changed == "textFont" or changed == "textFontSize" or changed == "textFontOutline" then
					self.text:SetFont(LSM:Fetch("font", config.textFont), config.textFontSize, config.textFontOutline)
				elseif changed == "hideName" or changed == "hideLevel" then
					ShowHide(self.name, not config.hideName)
					ShowHide(self.level, not config.hideLevel)
				elseif changed == "showHealthText" or changed == "showHealthPercent" then
					ShowHide(self.text, config.showHealthText or config.showHealthPercent)
				end

				changed = nil
			end
		end
	end

	local function Nameplate_SetHealthColor(self)
		if self.hasThreat then
			self.healthBar.reset = true
			self.healthBar:SetStatusBarColor(unpack(config.tankColor))
			return
		end

		local r, g, b = self.oldHealth:GetStatusBarColor()
		if self.healthBar.reset or r ~= self.healthBar.r or g ~= self.healthBar.g or b ~= self.healthBar.b then
			self.healthBar.r, self.healthBar.g, self.healthBar.b = r, g, b
			self.healthBar.reset = nil

			self.healthBar:SetStatusBarColor(r, g, b)
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
	end

	-- nameplate OnUpdate
	local function Nameplate_OnUpdate(self, elapsed)
		self.elapsed = (self.elapsed or 0) + elapsed
		if self.elapsed >= 0.01 then
			self:CheckForChange()
			self:UpdateCritical()
			self:SetHealthColor()
			self:FormatHealthText()
			ShowHide(self.name, not config.hideName)
			ShowHide(self.level, not config.hideLevel)

			if targetExists and self:GetAlpha() == 1 then
				self.healthBar:SetWidth(config.barWidth * 1.15)
				self.castBar:SetWidth(config.barWidth * 1.15)
				self.leftIndicator:Show()
				self.rightIndicator:Show()
			else
				self.healthBar:SetWidth(config.barWidth)
				self.castBar:SetWidth(config.barWidth)
				self.leftIndicator:Hide()
				self.rightIndicator:Hide()
			end

			self.elapsed = 0
		end
	end

	-- handles frame's show
	local function Nameplate_OnShow(self)
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
		self.name:SetText(self.oldname:GetText())
		self.name:SetPoint("BOTTOMLEFT", self.healthBar, "TOPLEFT", 0, 3)
		self.name:SetPoint("RIGHT", self.healthBar, -15, 3)
		ShowHide(self.name, not config.hideName)

		local level, elite = tonumber(self.level:GetText()), self.elite:IsShown()
		self.level:SetJustifyH("RIGHT")
		self.level:ClearAllPoints()
		self.level:SetPoint("BOTTOMRIGHT", self.healthBar, "TOPRIGHT", 3, 3)
		if self.boss:IsShown() then
			self.level:SetText("B")
			self.level:SetTextColor(0.8, 0.05, 0)
		elseif elite then
			self.level:SetText(level .. (elite and "+" or ""))
		end
		ShowHide(self.level, not config.hideLevel)

		self:UpdateCritical()
		Health_OnValueChanged(self.oldHealth, self.oldHealth:GetValue())
	end

	local function Nameplate_OnHide(self)
		self.highlight:Hide()
	end

	-- creates the frame
	local function Nameplate_Create(frame)
		if frame.done then
			return
		end
		frame.done = true

		local health, castBar = frame:GetChildren()
		frame.castBar = castBar

		frame.oldHealth = health
		frame.oldHealth:Hide()

		local healthBar = CreateFrame("StatusBar", nil, frame)
		frame.healthBar = healthBar
		frame.oldHealth:SetScript("OnValueChanged", Health_OnValueChanged)

		local glowRegion, overlayRegion, castbarOverlay, shieldedRegion, spellIconRegion, highlightRegion, nameTextRegion, levelTextRegion, bossIconRegion, raidIconRegion, stateIconRegion = frame:GetRegions()
		frame.oldname = nameTextRegion
		nameTextRegion:Hide()

		local name = frame:CreateFontString()
		name:SetPoint("BOTTOM", healthBar, "TOP", 0, 1)
		name:SetFont(LSM:Fetch("font", config.font), config.fontSize, config.fontOutline)
		name:SetTextColor(0.84, 0.75, 0.65)
		name:SetShadowOffset(1.25, -1.25)
		name:SetJustifyH("LEFT")
		name:SetJustifyV("BOTTOM")
		frame.name = name
		ShowHide(frame.name, not config.hideName)

		levelTextRegion:SetFont(LSM:Fetch("font", config.font), config.fontSize, config.fontOutline)
		levelTextRegion:SetShadowOffset(1.25, -1.25)
		levelTextRegion:SetJustifyH("RIGHT")
		levelTextRegion:SetJustifyV("BOTTOM")
		frame.level = levelTextRegion
		ShowHide(frame.level, not config.hideLevel)

		healthBar:SetStatusBarTexture(LSM:Fetch("statusbar", config.barTexture))
		healthBar.hpBackground = healthBar:CreateTexture(nil, "BORDER")
		healthBar.hpBackground:SetAllPoints(healthBar)
		healthBar.hpBackground:SetTexture(config.barTexture)
		healthBar.hpBackground:SetVertexColor(0.15, 0.15, 0.15)

		healthBar.hpGlow = CreateFrame("Frame", nil, healthBar)
		healthBar.hpGlow:SetPoint("TOPLEFT", healthBar, "TOPLEFT", -4.5, 4)
		healthBar.hpGlow:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", 4.5, -4.5)
		healthBar.hpGlow:SetBackdrop(backdrop)
		healthBar.hpGlow:SetBackdropColor(0, 0, 0)
		healthBar.hpGlow:SetBackdropBorderColor(0, 0, 0, 1)

		local text = healthBar:CreateFontString(nil, "OVERLAY")
		text:SetFont(LSM:Fetch("font", config.textFont), config.textFontSize, config.textFontOutline)
		text:SetPoint("CENTER", 0, 1)
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
		castBar:SetStatusBarTexture(LSM:Fetch("statusbar", config.barTexture))

		castBar:HookScript("OnShow", CastBar_OnShow)
		castBar:HookScript("OnSizeChanged", CastBar_OnSizeChanged)
		castBar:HookScript("OnValueChanged", CastBar_OnValueChanged)
		castBar:HookScript("OnEvent", CastBar_OnEvent)
		castBar:RegisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
		castBar:RegisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")

		castBar.time = castBar:CreateFontString(nil, "ARTWORK")
		castBar.time:SetPoint("RIGHT", castBar, "LEFT", -2, 1)
		castBar.time:SetFont(LSM:Fetch("font", config.font), config.fontSize, config.fontOutline)
		castBar.time:SetTextColor(0.84, 0.75, 0.65)
		castBar.time:SetShadowOffset(1.25, -1.25)

		castBar.cbBackground = castBar:CreateTexture(nil, "BORDER")
		castBar.cbBackground:SetAllPoints(castBar)
		castBar.cbBackground:SetTexture(config.barTexture)
		castBar.cbBackground:SetVertexColor(0.15, 0.15, 0.15)

		castBar.cbGlow = CreateFrame("Frame", nil, castBar)
		castBar.cbGlow:SetPoint("TOPLEFT", castBar, "TOPLEFT", -4.5, 4)
		castBar.cbGlow:SetPoint("BOTTOMRIGHT", castBar, "BOTTOMRIGHT", 4.5, -4.5)
		castBar.cbGlow:SetBackdrop(backdrop)
		castBar.cbGlow:SetBackdropColor(0, 0, 0)
		castBar.cbGlow:SetBackdropBorderColor(0, 0, 0)

		spellIconRegion:SetHeight(0.01)
		spellIconRegion:SetWidth(0.01)

		highlightRegion:SetTexture(config.barTexture)
		highlightRegion:SetVertexColor(0.25, 0.25, 0.25)
		frame.highlight = highlightRegion

		raidIconRegion:ClearAllPoints()
		raidIconRegion:SetPoint("BOTTOM", healthBar, "TOP", 0, config.barHeight + 3)
		raidIconRegion:SetSize(15, 15)

		frame.glow = glowRegion
		frame.elite = stateIconRegion
		frame.boss = bossIconRegion

		bossIconRegion:SetTexture(nil)
		castbarOverlay:SetTexture(nil)
		glowRegion:SetTexture(nil)
		overlayRegion:SetTexture(nil)
		shieldedRegion:SetTexture(nil)
		stateIconRegion:SetTexture(nil)

		frame.bg = frame:CreateTexture(nil, "BACKGROUND")
		frame.bg:SetTexture(config.solidTexture)
		frame.bg:SetVertexColor(0, 0, 0, 0.85)
		frame.bg:SetAllPoints(healthBar)

		local right = frame:CreateTexture(nil, "BACKGROUND")
		right:SetTexture([[Interface\Addons\Nameplates\arrow]])
		right:SetPoint("LEFT", frame.healthBar, "RIGHT", -3, 0)
		right:SetRotation(1.57)
		right:Hide()
		frame.rightIndicator = right

		local left = frame:CreateTexture(nil, "BACKGROUND")
		left:SetTexture([[Interface\Addons\Nameplates\arrow]])
		left:SetPoint("RIGHT", frame.healthBar, "LEFT", 3, 0)
		left:SetRotation(-1.57)
		left:Hide()
		frame.leftIndicator = left

		frame.CheckForChange = Nameplate_CheckForChange
		frame.SetHealthColor = Nameplate_SetHealthColor
		frame.UpdateCritical = Nameplate_UpdateCritical

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

			if _type(commands[cmd]) == "function" then
				commands[cmd](rest)
				if cmd ~= "config" and cmd ~= "options" then
					ReloadUI()
				end
			else
				Print(L:F("Acceptable commands for: |caaf49141%s|r", "/np"))
				print(_format(help, "enable", L["enable module"]))
				print(_format(help, "disable", L["disable module"]))
				print(_format(help, "fontsize|r |cff00ffffn|r", L["changes nameplates font size"]))
				print(_format(help, "width|r |cff00ffffn|r", L["changes nameplates width"]))
				print(_format(help, "height|r |cff00ffffn|r", L["changes nameplates height"]))
				print(_format(help, "health", L["toggles health text"]))
				print(_format(help, "max", L["toggles max health text"]))
				print(_format(help, "shorten", L["shortens health text"]))
				print(_format(help, "percent", L["toggles health percentage"]))
				print(_format(help, "config", L["Access module settings."]))
			end
		end
	end

	local function SetupDatabase()
		if not DB then
			if type(core.db.Nameplates) ~= "table" or not next(core.db.Nameplates) then
				core.db.Nameplates = CopyTable(defaults)
			end
			DB = core.db.Nameplates

			for k, v in pairs(DB) do
				config[k] = v
			end

			for k, v in pairs(defaults) do
				if config[k] == nil then
					config[k] = v
				end
			end
		end
		if not CharDB then
			if type(core.char.Nameplates) ~= "table" or not next(core.char.Nameplates) then
				core.char.Nameplates = CopyTable(defaultsChar)
			end
			CharDB = core.char.Nameplates

			for k, v in pairs(CharDB) do
				config[k] = v
			end
		end
	end

	core:RegisterForEvent("PLAYER_LOGIN", function()
		SetupDatabase()
		for _, name in ipairs({"TidyPlates", "KuiNameplates"}) do
			if _G[name] then
				disabled = true
				return
			end
		end

		local function _disabled() return not DB.enabled end
		core.options.args.Options.args.Nameplates = {
			type = "group",
			name = L["Nameplates"],
			get = function(i)
				return DB[i[#i]] or config[i[#i]]
			end,
			set = function(i, val)
				DB[i[#i]] = val
				config[i[#i]] = val
				changed = i[#i]
			end,
			args = {
				desc = {
					type = "description",
					name = L["Some settings require UI to be reloaded."],
					order = 0,
					width = "full"
				},
				enabled = {
					type = "toggle",
					name = L["Enable"],
					order = 1
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
						wipe(DB)
						DB = defaults
						for k, v in pairs(DB) do
							config[k] = v
						end
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
							step = 1
						},
						barHeight = {
							type = "range",
							name = L["Height"],
							order = 2,
							min = 6,
							max = 30,
							step = 1
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
							order = 7
						},
						hideLevel = {
							type = "toggle",
							name = L["Hide Level"],
							order = 9
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
						textFont = {
							type = "select",
							name = L["Font"],
							dialogControl = "LSM30_Font",
							values = AceGUIWidgetLSMlists.font,
							order = 5
						},
						textFontSize = {
							type = "range",
							name = L["Font Size"],
							order = 6,
							min = 6,
							max = 30,
							step = 1
						},
						textFontOutline = {
							type = "select",
							name = L["Font Outline"],
							order = 7,
							values = {
								[""] = NONE,
								["OUTLINE"] = L["Outline"],
								["THINOUTLINE"] = L["Thin outline"],
								["THICKOUTLINE"] = L["Thick outline"],
								["MONOCHROME"] = L["Monochrome"],
								["OUTLINEMONOCHROME"] = L["Outlined monochrome"]
							}
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
				}
			}
		}
	end)

	do
		-- nameplates OnUpdate handler
		local lastUpdate = 0
		local function Nameplates_OnUpdate(self, elapsed)
			lastUpdate = lastUpdate + elapsed

			if lastUpdate > 0.1 then
				lastUpdate = 0
				for i = 1, _select("#", WorldFrame:GetChildren()) do
					local frame = _select(i, WorldFrame:GetChildren())
					if NameplateIsValid(frame) and not frame.done then
						Nameplate_Create(frame)
					end
				end
			end
		end

		-- on mod loaded.
		core:RegisterForEvent("PLAYER_ENTERING_WORLD", function()
			if disabled then return end

			SetupDatabase()
			if DB.enabled and not disabled then
				frame:SetScript("OnUpdate", Nameplates_OnUpdate)
				frame:Show()
			else
				frame:SetScript("OnUpdate", nil)
				frame:Hide()
			end
		end)
	end

	core:RegisterForEvent("PLAYER_TARGET_CHANGED", function()
		if not disabled and DB.enabled then
			targetExists = UnitExists("target")
		end
	end)

	SLASH_KPACKNAMEPLATES1 = "/np"
	SLASH_KPACKNAMEPLATES2 = "/nameplates"
	SlashCmdList["KPACKNAMEPLATES"] = SlashCommandHandler
end)