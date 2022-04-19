local core = KPack
if not core then return end
core:AddModule("Binder", "Allows you to save your current keybinds as a profile that you can load whenever you want.", function(L)
	if core:IsDisabled("Binder") then return end

	local Binder = {}
	core.Binder = Binder

	local tinsert, tremove, ipairs = table.insert, table.remove, ipairs
	local LoadBindings, SaveBindings = LoadBindings, SaveBindings
	local GetNumBindings, SetBinding = GetNumBindings, SetBinding

	local DB
	local defaults = {{name = DEFAULT, binds = {}}}

	local selectedprofile, characterspecific

	local function Binder_SaveBindings()
		local total = GetNumBindings()
		local list = {}
		for i = 1, total do
			local action, bindOne, bindTwo = GetBinding(i)
			if bindOne ~= nil or bindTwo ~= nil then
				list[#list + 1] = {action = action, bindOne = bindOne, bindTwo = bindTwo}
			end
		end
		return list
	end

	local function Binder_LoadBindings(id)
		local profile = DB and DB[id]
		if profile then
			LoadBindings(0)
			SetBinding("1")
			SetBinding("2")
			SetBinding("3")
			SetBinding("4")
			SetBinding("5")
			SetBinding("6")
			SetBinding("7")
			SetBinding("8")
			SetBinding("9")
			SetBinding("0")
			SetBinding("-")
			SetBinding("=")

			for i = 1, #profile.binds do -- GetNumBindings()
				local action = profile.binds[i].action
				local bindOne = profile.binds[i].bindOne
				local bindTwo = profile.binds[i].bindTwo

				if bindOne ~= nil or bindTwo ~= nil then
					if bindOne ~= nil then
						SetBinding(bindOne, action)
					end
					if bindTwo ~= nil then
						SetBinding(bindTwo, action)
					end
				else
					tremove(profile.binds, i) -- clean it
				end

			end

			SaveBindings(characterspecific and 2 or 1)

			return true
		end
	end

	local function SetupDatabase()
		if not DB then
			if type(core.db.Binder) ~= "table" or next(core.db.Binder) == nil then
				core.db.Binder = CopyTable(defaults)
				core.db.Binder[1].binds = Binder_SaveBindings()
			end
			DB = core.db.Binder
		end
	end

	core:RegisterForEvent("PLAYER_LOGIN", function()
		SetupDatabase()

		core.options.args.Options.args.Binder = {
			type = "group",
			name = "Binder",
			args = {
				header1 = {
					type = "header",
					name = L["Create Profile"],
					order = 1
				},
				desc1 = {
					type = "description",
					name = L["Enter the name of the new profile then press Enter or click OK.\nThe new created profile will store the keybinds you are currently using."],
					fontSize = "medium",
					order = 2,
					width = "full"
				},
				name = {
					type = "input",
					name = NAME,
					order = 3,
					width = "full",
					set = function(_, val)
						val = val:trim()
						if val == "" then return end
						local binds = Binder_SaveBindings()

						-- replace existing one.
						local saved = false
						for i, profile in ipairs(DB) do
							if profile.name:lower() == val:lower() then
								DB[i].binds = binds
								saved = true
								break
							end
						end
						-- create new profile
						if not saved then
							DB[#DB + 1] = {name = val, binds = binds}
						end
						core:Print(L:F('Profile "%s" successfully created.', val), "Binder")
						selectedprofile, characterspecific = nil, nil
					end
				},
				sep1 = {
					type = "description",
					name = " ",
					order = 4,
					width = "full"
				},
				restore = {
					type = "header",
					name = L["Restore Profile"],
					order = 5
				},
				profiles = {
					type = "select",
					name = L["Profiles"],
					desc = L["Select the profile you want to restore or delete."],
					order = 6,
					values = function()
						local list = {}
						for k, v in ipairs(DB) do
							list[k] = v.name
						end
						return list
					end,
					get = function()
						return selectedprofile
					end,
					set = function(i, val)
						selectedprofile = val
					end
				},
				character = {
					type = "toggle",
					name = CHARACTER_SPECIFIC_KEYBINDINGS,
					order = 7,
					get = function()
						return characterspecific
					end,
					set = function(_, val)
						characterspecific = val
					end
				},
				apply = {
					type = "execute",
					name = APPLY,
					order = 8,
					disabled = function()
						return not selectedprofile
					end,
					confirm = function()
						return L:F("Are you sure you want to restore the profile: %s?", DB[selectedprofile].name)
					end,
					func = function()
						local succes = Binder_LoadBindings(selectedprofile)
						if succes then
							core:Print(L:F('Profile "%s" successfully restored.', DB[selectedprofile].name), "Binder")
						end
						selectedprofile, characterspecific = nil, nil
					end
				},
				delete = {
					type = "execute",
					name = DELETE,
					order = 9,
					disabled = function()
						return (not selectedprofile or #DB <= 1)
					end,
					confirm = function()
						return L:F("Are you sure you want to delete the profile: %s?", DB[selectedprofile].name)
					end,
					func = function()
						local name = DB[selectedprofile].name
						tremove(DB, selectedprofile)
						core:Print(L:F('Profile "%s" successfully deleted.', name), "Binder")
						selectedprofile, characterspecific = nil, nil
						if #DB == 0 then
							wipe(core.db.Binder)
							DB = nil
							SetupDatabase()
						end
					end
				},
				sep2 = {
					type = "description",
					name = " ",
					order = 10,
					width = "full"
				},
				reset = {
					type = "execute",
					name = RESET,
					order = 11,
					width = "full",
					confirm = function()
						return L:F("Are you sure you want to reset %s to default?", "Binder")
					end,
					func = function()
						core.db.Binder, DB = nil, nil
						selectedprofile, characterspecific = nil, nil
						SetupDatabase()
						core:Print(L["module's settings reset to default."], "Binder")
					end
				}
			}
		}

		SLASH_KPACKBINDER1 = "/binder"
		SlashCmdList.KPACKBINDER = function()
			return core:OpenConfig("Options", "Binder")
		end
	end)
end)