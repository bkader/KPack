local core = KPack
if not core then return end
core:AddModule("GarbageProtector", "Intercepts irresponsible collectgarbage calls to prevent chunky lockups and freezes.", function(L)
	if core:IsDisabled("GarbageProtector") then return end
	if _G.GarbageProtector then return end

	local GP = CreateFrame("Frame")
	core.GarbageProtector = GP

	local DB, options
	local defaults = {enabled = true, garbage = true, memory = true}

	-- garbage collector
	do
		local orig_collectgarbage = collectgarbage
		orig_collectgarbage("setpause", 110)
		orig_collectgarbage("setstepmul", 200)

		local function GP_collectgarbage(opt, arg)
			GP:SetupDatabase()

			if not (DB and DB.enabled and DB.garbage) then
				return orig_collectgarbage(opt, arg)
			end

			if opt == nil or opt == "collect" or opt == "stop" or opt == "restart" or opt == "step" then
				-- no! no! why? bad idea!
			elseif opt == "count" then
				-- probably used for GC current count
				return orig_collectgarbage(opt, arg)
			elseif opt == "setpause" then
				-- prevent addons from changing GC pause from default 110.
				return orig_collectgarbage("setpause", 110)
			elseif opt == "setstepmul" then
				-- prevent addons from changing GC step multiplier from default 200.
				return orig_collectgarbage("setstepmul", 200)
			else
				-- just in case something new is added.
				return orig_collectgarbage(opt, arg)
			end
		end
		_G.collectgarbage = GP_collectgarbage
	end

	-- update addon memory usage
	do
		local orig_UpdateAddOnMemoryUsage = UpdateAddOnMemoryUsage

		local function GP_UpdateAddOnMemoryUsage(...)
			GP:SetupDatabase()

			if not (DB and DB.enabled and DB.memory) then
				return orig_UpdateAddOnMemoryUsage(...)
			end
		end
		_G.UpdateAddOnMemoryUsage = GP_UpdateAddOnMemoryUsage
	end

	function GP:Print(msg)
		core:Print(msg, L["Garbage Protector"])
	end

	function GP:SetupDatabase()
		if not DB then
			if type(core.db.GarbageProtector) ~= "table" or next(core.db.GarbageProtector) == nil then
				core.db.GarbageProtector = CopyTable(defaults)
			end
			DB = core.db.GarbageProtector
		end
	end

	function GP:GetOptions()
		if not options then
			options = {
				type = "group",
				name = L["Garbage Protector"],
				get = function(i)
					return DB[i[#i]]
				end,
				set = function(i, val)
					DB[i[#i]] = val
				end,
				args = {
					desc = {
						type = "description",
						name = L["Intercepts irresponsible collectgarbage calls to prevent chunky lockups and freezes."],
						order = 0,
						width = "full",
						fontSize = "medium"
					},
					sep = {
						type = "description",
						name = " ",
						order = 0.1,
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
						disabled = function() return not DB.enabled end,
						confirm = function()
							return L:F("Are you sure you want to reset %s to default?", L["Garbage Protector"])
						end,
						func = function()
							wipe(core.db.GarbageProtector)
							DB = nil
							GP:SetupDatabase()
							GP:Print(L["module's settings reset to default."])
						end
					},
					garbage = {
						type = "toggle",
						name = "collectgarbage",
						desc = L["Screw those irresponsible collectgarbage calls!"],
						order = 3,
						disabled = function() return not DB.enabled end
					},
					memory = {
						type = "toggle",
						name = "UpdateAddOnMemoryUsage",
						desc = L["UpdateAddOnMemoryUsage is a waste of CPU time and some addons call it periodically when they shouldn't.\n\n|cffffd700WARNING|r: All in-game memory usage reports obtained with GetAddOnMemoryUsage will be reported as 0 or the last returned value if this is enabled."],
						order = 4,
						disabled = function() return not DB.enabled end
					}
				}
			}
		end

		return options
	end

	local function SlashCommandHandler(cmd)
		if cmd == "toggle" then
			DB.enabled = not DB.enabled
			GP:Print(DB.enabled and L["|cff00ff00enabled|r"] or L["|cffff0000disabled|r"])
		elseif cmd == "collectgarbage" then
			DB.garbage = not DB.garbage
			GP:Print("collectgarbage - " .. (DB.garbage and L["|cff00ff00enabled|r"] or L["|cffff0000disabled|r"]))
		elseif cmd == "UpdateAddOnMemoryUsage" then
			GP:Print("UpdateAddOnMemoryUsage - " .. (DB.memory and L["|cff00ff00enabled|r"] or L["|cffff0000disabled|r"]))
		else
			core:OpenConfig("Options", "GarbageProtector")
		end
	end

	core:RegisterForEvent("PLAYER_LOGIN", function()
		GP:SetupDatabase()

		SlashCmdList["KPACKGARBAGEPROTECTOR"] = SlashCommandHandler
		SLASH_KPACKGARBAGEPROTECTOR1 = "/gp"
		SLASH_KPACKGARBAGEPROTECTOR2 = "/garbageprotector"
		core.options.args.Options.args.GarbageProtector = GP:GetOptions()
	end)
end)