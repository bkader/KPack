local core = KPack
if not core then return end
core:AddModule("CombatLogFix", "Fixes the combat log break bugs that have existed since 2.4.", function(L)
	if core:IsDisabled("CombatLogFix") then return end

	local mod = core.CLF or {}
	core.CLF = mod
	local frame = CreateFrame("Frame")

	-- saved variables and default settings
	local DB
	local defaults = {
		enabled = true,
		zone = true,
		auto = true,
		report = false,
		wait = false
	}

	-- main locals.
	local instanceType, lastEvent, throttleBreak
	local SlashCommandHandler

	-- cache frequently used globals
	local CombatLogGetNumEntries = CombatLogGetNumEntries
	local IsInInstance = IsInInstance
	local GetTime = GetTime
	local lower, trim, print = string.lower, string.trim, print
	local next, select = next, select

	-- main print function
	local function Print(msg)
		if msg then
			core:Print(msg, "CombatLogFix")
		end
	end

	local function SetupDatabase()
		if not DB then
			if type(core.db.CLF) ~= "table" or not next(core.db.CLF) then
				core.db.CLF = CopyTable(defaults)
			end
			DB = core.db.CLF
		end
	end

	local function CombatLogReportEntries()
		SetupDatabase()
		if DB.enabled and DB.report and (not throttleBreak or throttleBreak < GetTime()) then
			Print(L:F("%d filtered/%d events found. Cleared combat log, as it broke.", CombatLogGetNumEntries(), CombatLogGetNumEntries(true) ))
			throttleBreak = GetTime() + 60 -- every 60sec so we don't spam.
		end
	end

	local OldCombatLogClearEntries = CombatLogClearEntries
	_G.CombatLogClearEntries = function()
		CombatLogReportEntries()
		OldCombatLogClearEntries()
	end

	-- handles frame's OnUpdate event
	local function UpdateUIFrame(self, elapsed)
		if not DB.enabled then
			self:SetScript("OnUpdate", nil)
			self:Hide()
			return
		end

		self.lastUpdated = (self.lastUpdated or 0) + elapsed
		if self.lastUpdated > 0.5 then
			if lastEvent and ((GetTime() - lastEvent) <= 1) then
				return
			end

			-- we queue the clear for later if the plauyer is in combat.
			if not (DB.wait and InCombatLockdown()) then
				CombatLogClearEntries()
			end
			self.lastUpdated = 0
		end
	end
	do
		-- set of options and their texts
		local options = {
			enabled = L["Module Status"],
			zone = L["Zone Clearing"],
			auto = L["Auto Clearing"],
			wait = L["Queued Clearing"],
			report = L["Message Report"]
		}

		-- main slash commands handler.
		function SlashCommandHandler(msg)
			msg = lower(trim(msg or ""))
			if msg == "status" then
				-- reset to default
				Print(L["Show set options"])
				for k, v in pairs(options) do
					if DB[k] then
						print(v, ": |cff00ff00ON|r")
					else
						print(v, ": |cffff0000OFF|r")
					end
				end
			elseif msg == "reset" then
				-- existing command
				wipe(DB)
				DB = defaults
				Print(L["module's settings reset to default."])
			elseif msg == "toggle" then
				DB.enabled = not DB.enabled
				if DB.enabled then
					frame:SetScript("OnUpdate", UpdateUIFrame)
					frame:Show()
					Print(L:F("module status: %s", "|cff00ff00ON|r"))
				else
					frame:SetScript("OnUpdate", nil)
					frame:Hide()
					Print(L:F("module status: %s", "|cffff0000OFF|r"))
				end
			elseif msg ~= "enabled" and options[msg] then
				-- non-existing command
				DB[msg] = not DB[msg]
				local status = (DB[msg] == true)
				Print(options[msg] .. " - " .. (status and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
			elseif msg ~= "config" or msg == "options" then
				core:OpenConfig("Options", "CLFix")
			else
				Print(L:F("Acceptable commands for: |caaf49141%s|r", "/logfix"))
				print("|cffffd700toggle|r", L["Enables or disables the module."])
				print("|cffffd700status|r", L["List of set options."])
				print("|cffffd700zone|r", L["Toggles clearing on zone type change."])
				print("|cffffd700auto|r", L["Toggles clearing combat log when it breaks."])
				print("|cffffd700wait|r", L["Toggles not clearing until you drop combat."])
				print("|cffffd700report|r", L["Toggles reporting how many messages were found when it broke."])
				print("|cffffd700config|r", L["Access module settings."])
				print("|cffffd700reset|r", L["Resets module settings to default."])
			end
		end
	end

	-- register our slash commands
	SlashCmdList["KPACKLOGFIXER"] = SlashCommandHandler
	SLASH_KPACKLOGFIXER1 = "/clf"
	SLASH_KPACKLOGFIXER2 = "/fixer"
	SLASH_KPACKLOGFIXER3 = "/logfix"

	local function disabled()
		return not DB.enabled
	end
	local options = {
		type = "group",
		name = "CombatLogFix",
		get = function(i)
			return DB[i[#i]]
		end,
		set = function(i, val)
			DB[i[#i]] = val
		end,
		args = {
			enabled = {
				type = "toggle",
				name = L["Enable"],
				order = 1
			},
			auto = {
				type = "toggle",
				name = L["Auto Clearing"],
				order = 2,
				disabled = disabled
			},
			zone = {
				type = "toggle",
				name = L["Zone Clearing"],
				order = 3,
				disabled = disabled
			},
			wait = {
				type = "toggle",
				name = L["Queued Clearing"],
				order = 4,
				disabled = disabled
			},
			report = {
				type = "toggle",
				name = L["Message Report"],
				order = 5,
				disabled = disabled
			}
		}
	}

	core:RegisterForEvent("PLAYER_LOGIN", function()
		SetupDatabase()
		frame:SetScript("OnUpdate", DB.enabled and UpdateUIFrame or nil)
		core.options.args.Options.args.CLFix = options
	end)

	local function CLF_ZoneCheck()
		SetupDatabase()
		if DB.enabled and DB.zone then
			local t = select(2, IsInInstance())
			if instanceType and t ~= instanceType then
				CombatLogClearEntries()
			end
			instanceType = t
		end
	end

	-- clear combat log on zone change.
	core:RegisterForEvent("PLAYER_ENTERING_WORLD", CLF_ZoneCheck)
	core:RegisterForEvent("ZONE_CHANGED_NEW_AREA", CLF_ZoneCheck)

	-- queued clear after combat ends
	core:RegisterForEvent("PLAYER_REGEN_ENABLED", function()
		SetupDatabase()
		if DB.enabled and DB.wait then
			CombatLogClearEntries()
		end
	end)

	core:RegisterForEvent("COMBAT_LOG_EVENT_UNFILTERED", function()
		if DB.enabled then
			lastEvent = GetTime()
		end
	end)
end)