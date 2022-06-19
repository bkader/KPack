local core = KPack
if not core then return end
core:AddModule("Viewporter", "Adds black bars at top/bottom/left/right side of the screen.", function(L)
	if core:IsDisabled("Viewporter") then return end

	local frame = CreateFrame("Frame")

	-- saved variables and defaults
	local DB, SetupDatabase
	local defaults = {
		enabled = false,
		left = 0,
		right = 0,
		top = 0,
		bottom = 0,
		firstTime = true
	}

	-- needed locales
	local initialized
	local sides = {
		left = "left",
		right = "right",
		top = "top",
		bottom = "bottom",
		bot = "bottom"
	}

	-- module's print function
	local function Print(msg)
		if msg then
			core:Print(msg, "Viewporter")
		end
	end

	-- called everytime we need to make changes to the viewport
	local function Viewporter_Initialize()
		if initialized then return end
		local left, right, top, bottom = 0, 0, 0, 0
		if DB.enabled then
			left, right, top, bottom = DB.left, DB.right, DB.top, DB.bottom
		end

		local scale = 768 / UIParent:GetHeight()
		WorldFrame:SetPoint("TOPLEFT", (left * scale), -(top * scale))
		WorldFrame:SetPoint("BOTTOMRIGHT", -(right * scale), (bottom * scale))

		initialized = true
	end

	-- slash commands handler
	local function SlashCommandHandler(msg)
		local cmd, rest = strsplit(" ", msg, 2)
		cmd = cmd:lower()
		rest = rest and rest:trim() or ""

		if cmd == "toggle" then
			DB.enabled = not DB.enabled
			Print(DB.enabled and L["|cff00ff00enabled|r"] or L["|cffff0000disabled|r"])
			initialized = nil
			frame:Show()
		elseif cmd == "enable" or cmd == "on" then
			DB.enabled = true
			initialized = nil
			frame:Show()
			Print(L["|cff00ff00enabled|r"])
		elseif cmd == "disable" or cmd == "off" then
			DB.enabled = false
			initialized = nil
			frame:Show()
			Print(L["|cffff0000disabled|r"])
		elseif cmd == "reset" or cmd == "default" then
			wipe(core.char.Viewporter)
			DB = nil
			SetupDatabase()
			initialized = nil
			Print(L["module's settings reset to default."])
			frame:Show()
		elseif cmd == "config" or cmd == "options" then
			core:OpenConfig("Options", "Viewporter")
		elseif sides[cmd] then
			local size = tonumber(rest)
			size = size or 0
			DB[sides[cmd]] = size
			initialized = nil
			frame:Show()
		else
			Print(L:F("Acceptable commands for: |caaf49141%s|r", "/vp"))
			print("|cffffd700toggle|r", L["toggles viewporter status"])
			print("|cffffd700enable|r", L["enable module"])
			print("|cffffd700disable|r", L["disable module"])
			print("|cffffd700config|r", L["Access module settings."])
			print("|cffffd700reset|r", L["Resets module settings to default."])
			print(L:F("|cffffd700Example|r: %s", "/vp bottom 120"))
			return
		end

		Viewporter_Initialize()
	end

	do
		local function Viewporter_OnUpdate(self, elapsed)
			SetupDatabase()
			if not (DB and DB.enabled) then
				Viewporter_Initialize()
				self:Hide()
				return
			end

			if DB.firstTime then
				DB.firstTime = false
			end
			Viewporter_Initialize()
			self:Hide()
		end

		core:RegisterForEvent("PLAYER_ENTERING_WORLD", function()
			frame:SetScript("OnUpdate", Viewporter_OnUpdate)
		end)
	end

	function SetupDatabase()
		if not DB then
			if type(core.char.Viewporter) ~= "table" or next(core.char.Viewporter) == nil then
				core.char.Viewporter = CopyTable(defaults)
			end
			DB = core.char.Viewporter
		end
	end

	-- frame event handler
	core:RegisterForEvent("PLAYER_LOGIN", function()
		SetupDatabase()

		SlashCmdList["KPACKVIEWPORTER"] = SlashCommandHandler
		SLASH_KPACKVIEWPORTER1 = "/vp"
		SLASH_KPACKVIEWPORTER2 = "/viewport"
		SLASH_KPACKVIEWPORTER3 = "/viewporter"

		local disabled = function()
			return not DB.enabled
		end
		core.options.args.Options.args.Viewporter = {
			type = "group",
			name = L["Viewporter"],
			get = function(i)
				return DB[i[#i]]
			end,
			set = function(i, val)
				DB[i[#i]] = val
				initialized = nil
				frame:Show()
			end,
			args = {
				enabled = {
					type = "toggle",
					name = L["Enable"],
					order = 1
				},
				reset = {
					type = "execute",
					name = RESET,
					order = 2,
					disabled = disabled,
					confirm = function()
						return L:F("Are you sure you want to reset %s to default?", L["Viewporter"])
					end,
					func = function()
						wipe(core.char.Viewporter)
						DB = nil
						SetupDatabase()
						Print(L["module's settings reset to default."])
						initialized = nil
						frame:Show()
					end
				},
				sep = {
					type = "description",
					name = " ",
					order = 3,
					width = "full"
				},
				left = {
					type = "range",
					name = L["Left"],
					order = 4,
					disabled = disabled,
					min = 0,
					max = 350,
					step = 0.1,
					bigStep = 1
				},
				right = {
					type = "range",
					name = L["Right"],
					order = 5,
					disabled = disabled,
					min = 0,
					max = 350,
					step = 0.1,
					bigStep = 1
				},
				top = {
					type = "range",
					name = L["Top"],
					order = 6,
					disabled = disabled,
					min = 0,
					max = 350,
					step = 0.1,
					bigStep = 1
				},
				bottom = {
					type = "range",
					name = L["Bottom"],
					order = 7,
					disabled = disabled,
					min = 0,
					max = 350,
					step = 0.1,
					bigStep = 1
				}
			}
		}
	end)
end)