assert(KPack, "KPack not found!")
KPack:AddModule("Personal Resources", 'Mimics the retail feature named "Personal Resource Display".', function(folder, core, L)
	if core:IsDisabled("Personal Resources") then return end

	-- cache frequently used glboals
	local CreateFrame = CreateFrame
	local UnitHealth, UnitHealthMax = UnitHealth, UnitHealthMax
	local UnitPowerType, UnitPower, UnitPowerMax = UnitPowerType, UnitPower, UnitPowerMax
	local floor, format = math.floor, string.format
	local LSM = core.LSM or LibStub("LibSharedMedia-3.0")

	-- saved variables and default
	local DB
	local defaults = {
		enabled = true,
		combat = false,
		percent = false,
		borderless = false,
		texture = "Blizzard",
		width = 180,
		height = 32,
		scale = 1
	}
	local PLAYER_ENTERING_WORLD

	local fname = "KPersonalResources"

	-- module print function
	local function Print(msg)
		if msg then
			core:Print(msg, "Personal Resources")
		end
	end

	-- utility to show/hide frame
	local function ShowHide(f, cond)
		if not f then
			return
		elseif cond and not f:IsShown() then
			f:Show()
		elseif not cond and f:IsShown() then
			f:Hide()
		end
	end

	-- sets up the database
	local function SetupDatabase()
		if not DB then
			if type(core.char.PersonalResources) ~= "table" or not next(core.char.PersonalResources) then
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
			if not parent then
				return
			end

			local bar = CreateFrame("StatusBar", nil, parent)
			bar:SetPoint("CENTER", 0, -120)
			bar:SetHitRectInsets(2, 2, 2, 2)
			bar:SetMinMaxValues(0, 100)

			local percent = bar:CreateFontString(nil, "OVERLAY")
			percent:SetFont(PlayerFrameHealthBarText:GetFont())
			percent:SetPoint("TOPLEFT")
			percent:SetPoint("BOTTOMRIGHT")
			percent:SetJustifyH("CENTER")
			percent:SetJustifyV("MIDDLE")
			percent:SetText("")
			percent:Hide()
			bar.percent = percent
			return bar
		end

		local function PersonalResources_CreateBorder(bar)
			if DB.borderless then
				if bar.border then
					bar.border:Hide()
					bar.border = nil
				end
				return
			end
			local border = bar.border or CreateFrame("Frame", nil, bar)
			border:SetBackdrop({
				bgFile = "Interface\\Tooltips\\UI-StatusBar-Border",
				tile = false,
				tileSize = bar:GetWidth(),
				edgeSize = bar:GetHeight(),
				insets = {left = 0, right = 0, top = 0, bottom = 0}
			})
			border:SetPoint("TOPLEFT", -5, 5)
			border:SetPoint("BOTTOMRIGHT", 5, -5)
			return border
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
				ShowHide(self, DB.combat)
			elseif event == "PLAYER_REGEN_DISABLED" then
				self:Show()
			end
		end

		local nextUpdate, updateInterval = 0, 0.05
		local Frame_OnUpdate
		local PersonalResources_UpdateValues
		do
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
				local hp, hpMax = UnitHealth("player"), UnitHealthMax("player")
				self.health:SetValue(PersonalResources_Calculate(hp, hpMax))

				local _, power = UnitPowerType("player")
				local pw, pwMax = UnitPower("player"), UnitPowerMax("player")
				self.power:SetValue(PersonalResources_Calculate(pw, pwMax))
				self.power:SetStatusBarColor(PersonalResources_PowerColor(power))

				if DB.percent then
					self.health.percent:SetText(format("%02.f%%", 100 * hp / hpMax))
					self.power.percent:SetText(format("%02.f%%", 100 * pw / pwMax))
					self.health.percent:Show()
					self.power.percent:Show()
				else
					if self.health.percent:IsShown() then
						self.health.percent:Hide()
					end
					if self.power.percent:IsShown() then
						self.power.percent:Hide()
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
		function PersonalResources_Initialize()
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
				frame:SetSize(width, height)
				frame:SetPoint(anchor, xOfs, yOfs)
				frame:SetBackdrop({
					bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
					insets = {left = 2, right = 2, top = 2, bottom = 2}
				})
				frame:SetBackdropColor(0, 0, 0, 0.8)

				-- health bar
				frame.health = PersonalResources_CreateBar(frame)
				frame.health:SetStatusBarTexture(LSM:Fetch("statusbar", DB.texture))
				frame.health:GetStatusBarTexture():SetHorizTile(false)
				frame.health:GetStatusBarTexture():SetVertTile(false)
				frame.health:SetPoint("TOPLEFT", 2, -2)
				frame.health:SetPoint("BOTTOMRIGHT", -2, height * 0.4)
				frame.health:SetStatusBarColor(0, 0.65, 0)
				frame.health.border = PersonalResources_CreateBorder(frame.health)

				-- power bar
				frame.power = PersonalResources_CreateBar(frame)
				frame.power:SetStatusBarTexture(LSM:Fetch("statusbar", DB.texture))
				frame.power:GetStatusBarTexture():SetHorizTile(false)
				frame.power:GetStatusBarTexture():SetVertTile(false)
				frame.power:SetPoint("TOPLEFT", 2, -height * 0.6)
				frame.power:SetPoint("BOTTOMRIGHT", -2, 2)
				frame.power:SetStatusBarColor(nil)
				frame.power.border = PersonalResources_CreateBorder(frame.power)
				frame:SetScale(scale)

				-- make the frame movable
				frame:EnableMouse(true)
				frame:SetMovable(true)
				frame:RegisterForDrag("LeftButton")
			elseif frame then
				frame:SetSize(width, height)
				frame.health:SetStatusBarTexture(LSM:Fetch("statusbar", DB.texture))
				frame.health:SetPoint("TOPLEFT", 2, -2)
				frame.health:SetPoint("BOTTOMRIGHT", -2, height * 0.4)
				frame.health.border = PersonalResources_CreateBorder(frame.health)

				frame.power:SetStatusBarTexture(LSM:Fetch("statusbar", DB.texture))
				frame.power:SetPoint("TOPLEFT", 2, -height * 0.6)
				frame.power:SetPoint("BOTTOMRIGHT", -2, 2)
				frame.power.border = PersonalResources_CreateBorder(frame.power)

				frame:SetScale(scale)
			end

			core:RestorePosition(frame, DB)
			ShowHide(frame, DB.enabled and DB.combat)

			-- register our frame event
			if DB.enabled then
				frame:RegisterEvent("PLAYER_REGEN_ENABLED")
				frame:RegisterEvent("PLAYER_REGEN_DISABLED")
			else
				frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
				frame:UnregisterEvent("PLAYER_REGEN_DISABLED")
			end

			-- register events and set our scripts
			frame:SetScript("OnEvent", Frame_OnEvent)
			frame:SetScript("OnDragStart", Frame_OnDragStart)
			frame:SetScript("OnDragStop", Frame_OnDragStop)
			frame:SetScript("OnUpdate", Frame_OnUpdate)
			PersonalResources_UpdateValues(frame)
		end
	end

	function PLAYER_ENTERING_WORLD(cmd)
		if not cmd then
			SetupDatabase()
		end
		PersonalResources_Initialize()
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
			ShowHide(frame, DB.enabled)
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
			wipe(DB)
			DB = defaults
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

		commands.percent = function()
			DB.percent = not DB.percent
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
				print(format(help, "percent", L["toggle showing percentage of health and power"]))
				print(format(help, "combat", L["toggle showing personal resources out of combat"]))
				print(format(help, "config", L["Access module settings."]))
				print(format(help, "reset", L["Resets module settings to default."]))
			end
		end
	end

	core:RegisterForEvent("PLAYER_LOGIN", function()
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
				percent = {
					type = "toggle",
					name = L["Show percentage"],
					order = 3,
					disabled = disabled
				},
				borderless = {
					type = "toggle",
					name = L["Hide border"],
					order = 4,
					disabled = disabled
				},
				width = {
					type = "range",
					name = L["Width"],
					order = 5,
					min = 50,
					max = 300,
					step = 0.1,
					bigStep = 1,
					disabled = disabled
				},
				height = {
					type = "range",
					name = L["Height"],
					order = 6,
					min = 30,
					max = 80,
					step = 0.1,
					bigStep = 1,
					disabled = disabled
				},
				scale = {
					type = "range",
					name = L["Scale"],
					order = 7,
					min = 0.5,
					max = 3,
					step = 0.01,
					bigStep = 0.1,
					disabled = disabled
				},
				texture = {
					type = "select",
					name = L["Texture"],
					dialogControl = "LSM30_Statusbar",
					order = 8,
					values = AceGUIWidgetLSMlists.statusbar
				},
				sep = {
					type = "description",
					name = " ",
					order = 9
				},
				reset = {
					type = "execute",
					name = RESET,
					order = 99,
					width = "full",
					confirm = function()
						return L:F("Are you sure you want to reset %s to default?", "Automate")
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

		PLAYER_ENTERING_WORLD()
	end)
end)