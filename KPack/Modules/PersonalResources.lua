local core = KPack
if not core then return end
core:AddModule("Personal Resources", 'Mimics the retail feature named "Personal Resource Display".', function(L)
	if core:IsDisabled("Personal Resources") then return end

	-- cache frequently used glboals
	local UnitHealth, UnitHealthMax = UnitHealth, UnitHealthMax
	local UnitPowerType, UnitPower, UnitPowerMax = UnitPowerType, UnitPower, UnitPowerMax
	local floor, format = math.floor, string.format

	-- saved variables and default
	local DB
	local defaults = {
		enabled = true,
		combat = false,
		text = false,
		point = "CENTER",
		font = "Friz Quadrata TT",
		fontSize = 12,
		fontOutline = "OUTLINE",
		texture = "KPack Norm",
		color = {0, 0, 0, 0.5},
		width = 180,
		height = 32,
		scale = 1
	}
	local PLAYER_ENTERING_WORLD

	local frame, fname = nil, "KPersonalResources"

	-- module print function
	local function Print(msg)
		if msg then
			core:Print(msg, "Personal Resources")
		end
	end

	-- sets up the database
	local function SetupDatabase()
		if not DB then
			if type(core.char.PersonalResources) ~= "table" or next(core.char.PersonalResources) == nil then
				core.char.PersonalResources = CopyTable(defaults)
			end

			-- to make update easy
			for k, v in pairs(defaults) do
				if core.char.PersonalResources[k] == nil then
					core.char.PersonalResources[k] = v
				end
			end

			DB = core.char.PersonalResources
		end
	end

	-- ///////////////////////////////////////////////////////

	local PersonalResources_Initialize
	do
		-- creates bars

		local function PersonalResources_CreateBar(parent)
			if not parent then return end

			local bar = core:CreateStatusBar(nil, parent)
			bar:SetPoint("CENTER", 0, -120)
			bar:SetMinMaxValues(0, 100)

			local text = bar:CreateFontString(nil, "OVERLAY")
			text:SetFont(
				core:MediaFetch("font", DB.font or defaults.font, "Friz Quadrata TT"),
				DB.fontSize or defaults.fontSize,
				DB.fontOutline or defaults.fontOutline
			)

			if DB.point == "LEFT" then
				text:SetPoint("RIGHT", bar, "LEFT")
				text:SetJustifyH("RIGHT")
			elseif DB.point == "RIGHT" then
				text:SetPoint("LEFT", bar, "RIGHT")
				text:SetJustifyH("LEFT")
			else
				text:SetPoint("CENTER", 0, 0)
				text:SetJustifyH("CENTER")
			end

			text:SetJustifyV("MIDDLE")
			text:SetText("")
			text:Hide()
			bar.text = text
			return bar
		end

		-- handles OnDragStart event
		local function Frame_OnDragStart(self)
			if IsAltKeyDown() or IsShiftKeyDown() then
				self.moving = true
				self:StartMoving()
			end
		end

		-- handles OnDragStop event
		local function Frame_OnDragStop(self)
			if self.moving then
				self.moving = false
				self:StopMovingOrSizing()
				core:SavePosition(self, core.char.PersonalResources)
			end
		end

		-- frame event handler
		local function Frame_OnEvent(self, event, ...)
			if event == "PLAYER_REGEN_ENABLED" then
				core:ShowIf(self, DB.combat)
			elseif event == "PLAYER_REGEN_DISABLED" then
				self:Show()
			end
		end

		local nextUpdate, updateInterval = 0, 0.05
		local Frame_OnUpdate
		local PersonalResources_UpdateValues
		do
			local SPELL_POWER_MANA = SPELL_POWER_MANA or 0
			local SPELL_POWER_RAGE = SPELL_POWER_RAGE or 1
			local SPELL_POWER_ENERGY = SPELL_POWER_ENERGY or 3
			local SPELL_POWER_RUNIC_POWER = SPELL_POWER_RUNIC_POWER or 6

			-- simple calculate
			local function PersonalResources_Calculate(val, maxVal)
				local res = (val / maxVal) * 100
				local mult = 10 ^ 2
				return floor(res * mult + 0.5) / mult
			end

			-- power color
			local function PersonalResources_PowerColor(t)
				local r, g, b = 0, 0, 1

				if t == "RAGE" then
					r, g, b = 1, 0, 0
				elseif t == "ENERGY" then
					r, g, b = 1, 1, 0
				elseif t == "RUNIC_POWER" then
					r, g, b = 0, 0.82, 1
				elseif t == "FOCUS" then
					r, g, b = 1, .5, .25
				end

				return r, g, b
			end

			function PersonalResources_UpdateValues(self)
				if not (self.health and self.power) then
					return
				end

				-- health
				local hp, hpMax = UnitHealth("player"), UnitHealthMax("player")
				self.health:SetValue(PersonalResources_Calculate(hp, hpMax))

				local pw, pwMax, en, enMax, ra, raMax

				-- project ascension
				if core.Ascension and (DB.energy or DB.rage) then
					-- mana
					pw, pwMax = UnitPower("player", SPELL_POWER_MANA), UnitPowerMax("player", SPELL_POWER_MANA)
					self.power:SetValue(PersonalResources_Calculate(pw, pwMax))
					self.power:SetStatusBarColor(PersonalResources_PowerColor("MANA"))

					-- enery
					if DB.energy then
						en, enMax = UnitPower("player", SPELL_POWER_ENERGY), UnitPowerMax("player", SPELL_POWER_ENERGY)
						self.energy:SetValue(PersonalResources_Calculate(en, enMax))
						self.energy:SetStatusBarColor(PersonalResources_PowerColor("ENERGY"))
					end

					-- rage
					if DB.rage then
						ra, raMax = UnitPower("player", SPELL_POWER_RAGE), UnitPowerMax("player", SPELL_POWER_RAGE)
						self.rage:SetValue(PersonalResources_Calculate(ra, raMax))
						self.rage:SetStatusBarColor(PersonalResources_PowerColor("RAGE"))
					end
				else
					-- power
					local power = select(2, UnitPowerType("player"))
					pw, pwMax = UnitPower("player"), UnitPowerMax("player")
					self.power:SetValue(PersonalResources_Calculate(pw, pwMax))
					self.power:SetStatusBarColor(PersonalResources_PowerColor(power))
				end

				if DB.text then
					self.health.text:SetText(format("%02.f%%", 100 * hp / hpMax))
					self.health.text:Show()

					self.power.text:SetText(format("%02.f%%", 100 * pw / pwMax))
					self.power.text:Show()

					if core.Ascension and (DB.energy or DB.rage) then
						if DB.energy then
							self.energy.text:SetText(format("%02.f%%", 100 * en / enMax))
							self.energy.text:Show()
						end

						if DB.rage then
							self.rage.text:SetText(format("%02.f%%", 100 * ra / raMax))
							self.rage.text:Show()
						end
					end
				else
					if self.health.text:IsShown() then
						self.health.text:Hide()
					end
					if self.power.text:IsShown() then
						self.power.text:Hide()
					end
					if core.Ascension and self.energy and self.energy.text:IsShown() then
						self.energy.text:Hide()
					end
					if core.Ascension and self.rage and self.rage.text:IsShown() then
						self.rage.text:Hide()
					end
				end
			end

			-- handles OnUpdate event
			function Frame_OnUpdate(self, elapsed)
				if not DB.enabled then
					self:SetScript("OnUpdate", nil)
				end

				nextUpdate = nextUpdate + (elapsed or 0)
				while nextUpdate > updateInterval do
					PersonalResources_UpdateValues(self)
					nextUpdate = nextUpdate - updateInterval
				end
			end
		end

		-- initializes personal resources
		function PersonalResources_Initialize(cmd)
			frame = frame or _G[fname]
			local width = DB.width or 180
			local height = DB.height or 32
			local scale = DB.scale or 1

			if not frame then
				local anchor = DB.anchor or "CENTER"
				local xOfs = DB.xOfs or 0
				local yOfs = DB.yOfs or -120

				-- create main frame
				frame = CreateFrame("Frame", fname, UIParent)
				frame:SetWidth(width)
				frame:SetHeight(height)
				frame:SetPoint(anchor, xOfs, yOfs)
			elseif cmd then
				frame:SetWidth(width)
				frame:SetHeight(height)
			end

			-- background color
			local color = DB.color or defaults.color

			-- health bar
			if not frame.health then
				frame.health = PersonalResources_CreateBar(frame)
				frame.health:GetStatusBarTexture():SetHorizTile(false)
				frame.health:GetStatusBarTexture():SetVertTile(false)
				frame.health:SetPoint("TOPLEFT", 2, -2)
				frame.health:SetPoint("TOPRIGHT", -2, -2)
			end
			frame.health:SetStatusBarTexture(core:MediaFetch("statusbar", DB.texture))
			frame.health:SetStatusBarColor(0, 0.65, 0)
			frame.health:SetBackgroundColor(unpack(color))
			frame.health:SetHeight(height * 0.6)
			frame.health.bg:Show()

			-- power bar
			if not frame.power then
				frame.power = PersonalResources_CreateBar(frame)
				frame.power:GetStatusBarTexture():SetHorizTile(false)
				frame.power:GetStatusBarTexture():SetVertTile(false)
				frame.power:SetPoint("TOPLEFT", frame.health, "BOTTOMLEFT")
				frame.power:SetPoint("TOPRIGHT", frame.health, "BOTTOMRIGHT")
			end
			frame.power:SetStatusBarTexture(core:MediaFetch("statusbar", DB.texture))
			frame.power:SetStatusBarColor(nil)
			frame.power:SetBackgroundColor(unpack(color))
			frame.power:SetHeight(height * 0.4)
			frame.power.bg:Show()

			-- project ascension
			if core.Ascension and (DB.energy or DB.rage) then
				local num = (DB.energy and DB.rage) and 2 or 1

				frame.health:SetHeight(height * (num == 1 and 0.5 or 0.4))
				frame.power:SetHeight(height * (num == 1 and 0.25 or 0.2))

				-- energy bar
				if DB.energy then
					if not frame.energy then
						frame.energy = PersonalResources_CreateBar(frame)
						frame.energy:GetStatusBarTexture():SetHorizTile(false)
						frame.energy:GetStatusBarTexture():SetVertTile(false)
						frame.energy:SetPoint("TOPLEFT", frame.power, "BOTTOMLEFT")
						frame.energy:SetPoint("TOPRIGHT", frame.power, "BOTTOMRIGHT")
					end
					frame.energy:SetStatusBarTexture(core:MediaFetch("statusbar", DB.texture))
					frame.energy:SetStatusBarColor(nil)
					frame.energy:SetBackgroundColor(unpack(color))
					frame.energy:SetHeight(height * (num == 1 and 0.25 or 0.2))
					frame.energy.bg:Show()
				elseif frame.energy then
					frame.energy:Hide()
					frame.energy = nil
				end

				-- rage bar
				if DB.rage then
					if not frame.rage then
						frame.rage = PersonalResources_CreateBar(frame)
						frame.rage:GetStatusBarTexture():SetHorizTile(false)
						frame.rage:GetStatusBarTexture():SetVertTile(false)
						frame.rage:SetPoint("TOPLEFT", DB.energy and frame.energy or frame.power, "BOTTOMLEFT")
						frame.rage:SetPoint("TOPRIGHT", DB.energy and frame.energy or frame.power, "BOTTOMRIGHT")
					end
					frame.rage:SetStatusBarTexture(core:MediaFetch("statusbar", DB.texture))
					frame.rage:SetStatusBarColor(nil)
					frame.rage:SetBackgroundColor(unpack(color))
					frame.rage:SetHeight(height * (num == 1 and 0.25 or 0.2))
					frame.rage.bg:Show()
				elseif frame.rage then
					frame.rage:Hide()
					frame.rage = nil
				end
			else
				if frame.energy then
					frame.energy:Hide()
					frame.energy = nil
				end
				if frame.rage then
					frame.rage:Hide()
					frame.rage = nil
				end
			end

			-- make the frame movable
			frame:SetScale(scale)
			frame:EnableMouse(true)
			frame:SetMovable(true)
			frame:RegisterForDrag("LeftButton")

			if cmd then
				frame.health.text:ClearAllPoints()
				frame.power.text:ClearAllPoints()
				if core.Ascension then
					if frame.energy then
						frame.energy.text:ClearAllPoints()
					end
					if frame.rage then
						frame.rage.text:ClearAllPoints()
					end
				end

				if DB.point == "LEFT" then
					frame.health.text:SetPoint("RIGHT", frame.health, "LEFT", -3, 0)
					frame.health.text:SetJustifyH("RIGHT")
					frame.power.text:SetPoint("RIGHT", frame.power, "LEFT", -3, 0)
					frame.power.text:SetJustifyH("RIGHT")
					if core.Ascension then
						if frame.energy then
							frame.energy.text:SetPoint("RIGHT", frame.energy, "LEFT", -3, 0)
							frame.energy.text:SetJustifyH("RIGHT")
						end
						if frame.rage then
							frame.rage.text:SetPoint("RIGHT", frame.rage, "LEFT", -3, 0)
							frame.rage.text:SetJustifyH("RIGHT")
						end
					end
				elseif DB.point == "RIGHT" then
					frame.health.text:SetPoint("LEFT", frame.health, "RIGHT", 3, 0)
					frame.health.text:SetJustifyH("LEFT")
					frame.power.text:SetPoint("LEFT", frame.power, "RIGHT", 3, 0)
					frame.power.text:SetJustifyH("LEFT")
					if core.Ascension then
						if frame.energy then
							frame.energy.text:SetPoint("LEFT", frame.energy, "RIGHT", 3, 0)
							frame.energy.text:SetJustifyH("LEFT")
						end
						if frame.rage then
							frame.rage.text:SetPoint("LEFT", frame.rage, "RIGHT", 3, 0)
							frame.rage.text:SetJustifyH("LEFT")
						end
					end
				else
					frame.health.text:SetPoint("CENTER", 0, 0)
					frame.health.text:SetJustifyH("CENTER")
					frame.power.text:SetPoint("CENTER", 0, 0)
					frame.power.text:SetJustifyH("CENTER")
					if core.Ascension then
						if frame.energy then
							frame.energy.text:SetPoint("CENTER", 0, 0)
							frame.energy.text:SetJustifyH("CENTER")
						end
						if frame.rage then
							frame.rage.text:SetPoint("CENTER", 0, 0)
							frame.rage.text:SetJustifyH("CENTER")
						end
					end
				end

				frame.health.text:SetFont(
					core:MediaFetch("font", DB.font or defaults.font, "Friz Quadrata TT"),
					DB.fontSize or defaults.fontSize,
					DB.fontOutline or defaults.fontOutline
				)

				frame.power.text:SetFont(
					core:MediaFetch("font", DB.font or defaults.font, "Friz Quadrata TT"),
					DB.fontSize or defaults.fontSize,
					DB.fontOutline or defaults.fontOutline
				)

				if core.Ascension and (frame.energy or frame.rage) then
					if DB.energy and frame.energy then
						frame.energy.text:SetFont(
							core:MediaFetch("font", DB.font or defaults.font, "Friz Quadrata TT"),
							DB.fontSize or defaults.fontSize,
							DB.fontOutline or defaults.fontOutline
						)
					end

					if DB.rage and frame.rage then
						frame.rage.text:SetFont(
							core:MediaFetch("font", DB.font or defaults.font, "Friz Quadrata TT"),
							DB.fontSize or defaults.fontSize,
							DB.fontOutline or defaults.fontOutline
						)
					end
				end
			end

			core:RestorePosition(frame, DB)
			core:ShowIf(frame, DB.enabled and DB.combat)

			-- register our frame event
			if DB.enabled then
				frame:RegisterEvent("PLAYER_REGEN_ENABLED")
				frame:RegisterEvent("PLAYER_REGEN_DISABLED")

				frame:SetScript("OnEvent", Frame_OnEvent)
				frame:SetScript("OnDragStart", Frame_OnDragStart)
				frame:SetScript("OnDragStop", Frame_OnDragStop)
				frame:SetScript("OnUpdate", Frame_OnUpdate)
				PersonalResources_UpdateValues(frame)
			else
				frame:UnregisterAllEvents()
				frame:SetScript("OnEvent", nil)
				frame:SetScript("OnDragStart", nil)
				frame:SetScript("OnDragStop", nil)
				frame:SetScript("OnUpdate", nil)
			end
		end
	end

	function PLAYER_ENTERING_WORLD(cmd)
		if not cmd then
			SetupDatabase()
		end
		PersonalResources_Initialize(cmd)
	end
	core:RegisterForEvent("PLAYER_ENTERING_WORLD", PLAYER_ENTERING_WORLD)

	-- slash commands handler
	local SlashCommandHandler
	do
		local commands = {}
		local help = "|cffffd700%s|r: %s"

		-- enable the module
		commands.enable = function()
			DB.enabled = true
			Print(L:F("module status: %s", L["|cff00ff00enabled|r"]))
		end
		commands.on = commands.enable

		-- disable the module
		commands.disable = function()
			DB.enabled = false
			Print(L:F("module status: %s", L["|cffff0000disabled|r"]))
		end
		commands.off = commands.disable

		-- hide the bar
		commands.show = function()
			core:ShowIf(frame, DB.enabled)
		end

		-- hide bar
		commands.hide = function()
			frame:Hide()
		end

		-- change scale
		commands.scale = function(n)
			n = tonumber(n)
			if n then
				DB.scale = n
			end
		end

		-- change width
		commands.width = function(n)
			n = tonumber(n)
			if n then
				DB.width = n
			end
		end

		-- change height
		commands.height = function(n)
			n = tonumber(n)
			if n then
				DB.height = n
			end
		end

		-- reset module
		commands.reset = function()
			wipe(core.char.PersonalResources)
			DB = nil
			Print(L["module's settings reset to default."])
		end
		commands.default = commands.reset

		-- toggle combat
		commands.combat = function()
			DB.combat = not DB.combat
			if DB.combat then
				Print(L:F("show out on combat: %s", L["|cff00ff00ON|r"]))
				frame:Hide()
			else
				Print(L:F("show out on combat: %s", L["|cffff0000OFF|r"]))
				frame:Show()
			end
		end

		commands.text = function()
			DB.text = not DB.text
		end

		commands.config = function()
			core:OpenConfig("Options", "PersonalResources")
		end
		commands.options = commands.config

		function SlashCommandHandler(msg)
			if InCombatLockdown() then
				Print("|cffffe02e" .. ERR_NOT_IN_COMBAT .. "|r")
				return
			end

			local cmd, rest = strsplit(" ", msg, 2)
			if type(commands[cmd]) == "function" then
				commands[cmd](rest)
				PLAYER_ENTERING_WORLD(true)
			else
				Print(L:F("Acceptable commands for: |caaf49141%s|r", "/ps"))
				print(format(help, "enable", L["enable module"]))
				print(format(help, "disable", L["disable module"]))
				print(format(help, "show", L["show personal resources"]))
				print(format(help, "hide", L["hide personal resources"]))
				print(format(help, "scale|r |cff00ffffn|r", L["change personal resources scale"]))
				print(format(help, "width|r |cff00ffffn|r", L["change personal resources width"]))
				print(format(help, "height|r |cff00ffffn|r", L["change personal resources height"]))
				print(format(help, "text", L["toggle showing health and power text"]))
				print(format(help, "combat", L["toggle showing personal resources out of combat"]))
				print(format(help, "config", L["Access module settings."]))
				print(format(help, "reset", L["Resets module settings to default."]))
			end
		end
	end

	core:RegisterForEvent(
		"PLAYER_LOGIN",
		function()
			SetupDatabase()

			SlashCmdList["KPACKPLAYERRESOURCES"] = SlashCommandHandler
			SLASH_KPACKPLAYERRESOURCES1 = "/ps"
			SLASH_KPACKPLAYERRESOURCES2 = "/resources"

			local function disabled()
				return not DB.enabled
			end
			core.options.args.Options.args.PersonalResources = {
				type = "group",
				name = "Personal Resources",
				get = function(i)
					return DB[i[#i]]
				end,
				set = function(i, val)
					DB[i[#i]] = val
					PLAYER_ENTERING_WORLD(true)
				end,
				args = {
					enabled = {
						type = "toggle",
						name = L["Enable"],
						order = 1
					},
					combat = {
						type = "toggle",
						name = L["Show out of combat"],
						order = 2,
						disabled = disabled
					},
					energy = {
						type = "toggle",
						name = L["Show Energy"],
						order = 3,
						hidden = not core.Ascension,
						disabled = disabled
					},
					rage = {
						type = "toggle",
						name = L["Show Rage"],
						order = 4,
						hidden = not core.Ascension,
						disabled = disabled
					},
					text = {
						type = "toggle",
						name = L["Show Text"],
						order = 5,
						disabled = disabled
					},
					sep1 = {
						type = "description",
						name = " ",
						order = 6,
						width = "full"
					},
					width = {
						type = "range",
						name = L["Width"],
						order = 7,
						min = 50,
						max = 300,
						step = 0.1,
						bigStep = 1,
						disabled = disabled
					},
					height = {
						type = "range",
						name = L["Height"],
						order = 8,
						min = 30,
						max = 80,
						step = 0.1,
						bigStep = 1,
						disabled = disabled
					},
					scale = {
						type = "range",
						name = L["Scale"],
						order = 9,
						width = "double",
						min = 0.5,
						max = 3,
						step = 0.01,
						bigStep = 0.1,
						isPercent = true,
						disabled = disabled
					},
					sep2 = {
						type = "description",
						name = " ",
						order = 10,
						width = "full"
					},
					font = {
						type = "select",
						name = L["Font"],
						dialogControl = "LSM30_Font",
						order = 11,
						values = AceGUIWidgetLSMlists.font
					},
					fontSize = {
						type = "range",
						name = L["Font Size"],
						order = 12,
						min = 6,
						max = 30,
						step = 1
					},
					fontOutline = {
						type = "select",
						name = L["Font Outline"],
						order = 13,
						values = {
							[""] = NONE,
							["OUTLINE"] = L["Outline"],
							["THINOUTLINE"] = L["Thin outline"],
							["THICKOUTLINE"] = L["Thick outline"],
							["MONOCHROME"] = L["Monochrome"],
							["OUTLINEMONOCHROME"] = L["Outlined monochrome"]
						}
					},
					point = {
						type = "select",
						name = L["Text Position"],
						order = 14,
						values = {CENTER = L["Center"], LEFT = L["Left"], RIGHT = L["Right"]}
					},
					sep3 = {
						type = "description",
						name = " ",
						order = 15,
						width = "full"
					},
					texture = {
						type = "select",
						name = L["Texture"],
						desc = L:F("Select texture to use for the %s", L["Personal Resources"]),
						dialogControl = "LSM30_Statusbar",
						order = 16,
						values = AceGUIWidgetLSMlists.statusbar
					},
					color = {
						type = "color",
						name = L["Background Color"],
						desc = L:F("Select the background color to use for %s", L["Personal Resources"]),
						order = 17,
						hasAlpha = true,
						get = function()
							return unpack(DB.color or defaults.color)
						end,
						set = function(_, r, g, b, a)
							DB.color = {r, g, b, a}
							PLAYER_ENTERING_WORLD(true)
						end
					},
					sep4 = {
						type = "description",
						name = " ",
						order = 100
					},
					reset = {
						type = "execute",
						name = RESET,
						order = 101,
						width = "double",
						confirm = function()
							return L:F("Are you sure you want to reset %s to default?", "Personal Resources")
						end,
						func = function()
							wipe(core.char.PersonalResources)
							DB = nil
							Print(L["module's settings reset to default."])
							PLAYER_ENTERING_WORLD()
						end
					}
				}
			}

			PLAYER_ENTERING_WORLD()
		end
	)
end)