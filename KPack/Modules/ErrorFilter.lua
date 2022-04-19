local core = KPack
if not core then return end
core:AddModule("Error Filter", "Manages the errors that are displayed in the blizzard UIErrorsFrame.", function(L)
	if core:IsDisabled("Error Filter") then return end

	local mod = core.ErrorFilter or {}
	core.ErrorFilter = mod

	local strfind = string.find
	local strlower = string.lower

	local DB, SetupDatabase
	local function Print(msg)
		core:Print(msg, L["Error Filter"])
	end

	local defaults = {enabled = true, shown = true}

	local filters = {
		[ERR_ABILITY_COOLDOWN] = true,
		[ERR_BADATTACKPOS] = true,
		[ERR_GENERIC_NO_TARGET] = true,
		[ERR_INVALID_ATTACK_TARGET] = true,
		[ERR_ITEM_COOLDOWN] = true,
		[ERR_NO_ATTACK_TARGET] = true,
		[ERR_OUT_OF_ENERGY] = true,
		[ERR_OUT_OF_FOCUS] = true,
		[ERR_OUT_OF_MANA] = true,
		[ERR_OUT_OF_RAGE] = true,
		[ERR_OUT_OF_RANGE] = true,
		[ERR_OUT_OF_RUNES] = true,
		[ERR_OUT_OF_RUNIC_POWER] = true,
		[ERR_SPELL_COOLDOWN] = true,
		[ERR_TOO_FAR_TO_ATTACK] = true,
		[ERR_TOO_FAR_TO_INTERACT] = true,
		[SPELL_FAILED_AURA_BOUNCED] = true,
		[SPELL_FAILED_BAD_TARGETS] = true,
		[SPELL_FAILED_CASTER_AURASTATE] = true,
		[SPELL_FAILED_ITEM_NOT_READY] = true,
		[SPELL_FAILED_NO_COMBO_POINTS] = true,
		[SPELL_FAILED_SPELL_IN_PROGRESS] = true,
		[SPELL_FAILED_TARGETS_DEAD] = true
	}

	local SlashCommandHandler
	do
		local exec = {}

		exec.status = function()
			Print(L:F("Filter Enabled: %s - Frame Shown: %s", tostring(DB.options.enabled), tostring(DB.options.shown)))
		end

		exec.enable = function()
			if not DB.options.enabled then
				DB.options.enabled = true
				Print(L["module enabled."])
			end
		end

		exec.disable = function()
			if DB.options.enabled then
				DB.options.enabled = false
				Print(L["module disabled."])
			end
		end

		exec.hide = function()
			if DB.options.shown then
				DB.options.shown = false
				UIErrorsFrame:Hide()
				Print(L["Error frame is now hidden."])
			end
		end

		exec.show = function()
			if not DB.options.shown then
				DB.options.shown = true
				UIErrorsFrame:Show()
				Print(L["Error frame is now visible."])
			end
		end

		exec.reset = function()
			wipe(core.db.ErrorFilter)
			DB = nil
			SetupDatabase()
			Print(L["module's settings reset to default."])
		end
		exec.default = exec.reset

		exec.config = function()
			core:OpenConfig("Options", "ErrorFilter")
		end
		exec.options = exec.config

		function SlashCommandHandler(msg)
			local cmd, rest = strsplit(" ", msg, 2)
			if type(exec[cmd]) == "function" then
				exec[cmd](rest)
			else
				Print(L:F("Acceptable commands for: |caaf49141%s|r", "/erf"))
				print("|cffffd700status|r", L["show module status."])
				print("|cffffd700enable|r", L["enable the module."])
				print("|cffffd700disable|r", L["disable the module."])
				print("|cffffd700hide|r", L["hide error frame."])
				print("|cffffd700show|r", L["show error frame."])
				print("|cffffd700config|r", L["Access module settings."])
				print("|cffffd700reset|r", L["Resets module settings to default."])
			end
		end
	end

	function SetupDatabase()
		if not DB then
			if type(core.db.ErrorFilter) ~= "table" or next(core.db.ErrorFilter) == nil then
				core.db.ErrorFilter = {
					options = CopyTable(defaults),
					filters = CopyTable(filters)
				}
			end
			DB = core.db.ErrorFilter
		end
	end

	local options
	local function GetOptions()
		if not options then
			local disabled = function()
				return not DB.options.enabled
			end

			options = {
				type = "group",
				name = L["Error Filter"],
				get = function(i)
					return DB.options[i[#i]]
				end,
				set = function(i, val)
					DB.options[i[#i]] = val
				end,
				args = {
					enabled = {
						type = "toggle",
						name = L["Enable"],
						order = 1
					},
					shown = {
						type = "toggle",
						name = L["Show Frame"],
						desc = L["Enable this if you want to keep the errors frame visible for other errors."],
						order = 2,
						disabled = disabled
					},
					messages = {
						type = "group",
						name = L["Tick the messages you want to disable."],
						get = function(i)
							return DB.filters[i[#i]]
						end,
						set = function(i, val)
							DB.filters[i[#i]] = val
						end,
						order = 3,
						width = "double",
						inline = true,
						disabled = disabled,
						args = {}
					},
					reset = {
						type = "execute",
						name = RESET,
						order = 9,
						disabled = disabled,
						width = "double",
						confirm = function()
							return L:F("Are you sure you want to reset %s to default?", L["Error Filter"])
						end,
						func = function()
							wipe(core.db.ErrorFilter)
							DB = nil
							SetupDatabase()
							Print(L["module's settings reset to default."])
						end
					}
				}
			}

			local numorder = 1
			for k, v in pairs(DB.filters) do
				options.args.messages.args[k] = {
					type = "toggle",
					name = k,
					order = numorder
				}
				numorder = numorder + 1
			end
		end
		return options
	end

	core:RegisterForEvent("PLAYER_LOGIN", function()
		SetupDatabase()
		if DB.options.shown then
			UIErrorsFrame:Show()
		else
			UIErrorsFrame:Hide()
		end

		core.options.args.Options.args.ErrorFilter = GetOptions()
	end)

	local UIErrorsFrame_OldOnEvent = UIErrorsFrame:GetScript("OnEvent")
	core:RegisterForEvent("PLAYER_ENTERING_WORLD", function()
		SetupDatabase()
		UIErrorsFrame:SetScript("OnEvent", function(self, event, arg1, ...)
			if event == "UI_ERROR_MESSAGE" and DB.options.enabled and DB.filters[arg1] then
				return
			end

			return UIErrorsFrame_OldOnEvent(self, event, arg1, ...)
		end)
	end)

	SlashCmdList["KPACKERRORFILTER"] = SlashCommandHandler
	SLASH_KPACKERRORFILTER1 = "/erf"
	SLASH_KPACKERRORFILTER2 = "/errorfilter"
end)