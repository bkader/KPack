local core = KPack
if not core then return end
core:AddModule("Action Bar Saver", "Allows you to setup different profiles for your action bars.", function(L)
	if core:IsDisabled("Action Bar Saver") then return end

	local ABS = core.ActionBarSaver or {}
	core.ActionBarSaver = ABS
	local command = core.locale == "frFR" and "abr" or "abs"

	-- frequently used globals
	local strtrim = string.trim
	local strsplit = string.split
	local strlower = string.lower
	local strformat = string.format
	local strmatch = string.match
	local strgsub = string.gsub
	local pairs, select, tostring = pairs, select, tostring
	local tsort = table.sort
	local tremove = table.remove
	local tinsert = table.insert
	local tconcat = table.concat

	local GetSpellName = GetSpellName
	local GetSpellTabInfo = GetSpellTabInfo
	local GetActionInfo = GetActionInfo
	local GetItemInfo = GetItemInfo
	local GetMacroInfo = GetMacroInfo
	local GetMacroIconInfo = GetMacroIconInfo
	local GetNumMacros = GetNumMacros
	local GetNumMacroIcons = GetNumMacroIcons
	local GetCursorInfo = GetCursorInfo
	local ClearCursor = ClearCursor
	local PickupSpell = PickupSpell
	local PickupAction = PickupAction
	local PickupItem = PickupItem
	local PickupMacro = PickupMacro
	local PickupCompanion = PickupCompanion

	-- module locals
	local errorsCache = core.WeakTable()
	local spellCache = core.WeakTable()
	local macroCache = core.WeakTable()
	local iconCache, myclass

	local MAX_MACROS = 54
	local MAX_CHAR_MACROS = 18
	local MAX_GLOBAL_MACROS = 36

	local CompressText
	local UncompressText
	local FindMacro
	local RestoreMacros
	local RestoreAction

	local DB
	local function LoadDatabase()
		if DB then return end

		if type(core.db.ABS) ~= "table" then
			core.db.ABS = {macro = false, count = false, rank = true, spellSubs = {}, sets = {}}
			for class in pairs(RAID_CLASS_COLORS) do
				core.db.ABS.sets[class] = core.db.ABS.sets[class] or {}
			end
		end

		DB = core.db.ABS
	end

	local function Print(msg)
		if msg then
			core:Print(msg, "ActionBarSaver")
		end
	end

	---------------------------------------------------------------------------

	function CompressText(text)
		text = strgsub(text, "\n", "/n")
		text = strgsub(text, "/n$", "")
		text = strgsub(text, "||", "/124")

		return strtrim(text)
	end

	function UncompressText(text)
		text = strgsub(text, "/n", "\n")
		text = strgsub(text, "/124", "|")
		return strtrim(text)
	end

	function FindMacro(id, data)
		if macroCache[id] == data then
			return id
		end

		for i, currentMacro in pairs(macroCache) do
			if currentMacro == data then
				return i
			end
		end

		return nil
	end

	function RestoreMacros(set)
		local perCharacter = true
		for _, data in pairs(set) do
			local mtype, id, binding, macroName, macroIcon, macroData = strsplit("|", data)
			if mtype == "macro" then
				local macroID = FindMacro(id, macroData)
				if not macroID then
					local globalNum, charNum = GetNumMacros()
					if globalNum == MAX_GLOBAL_MACROS and charNum == MAX_CHAR_MACROS then
						tinsert(errorsCache, L["Unable to restore macros, you already have 36 global and 18 per character ones created."])
						break
					elseif charNum == MAX_CHAR_MACROS then
						perCharacter = false
					end

					if not iconCache then
						iconCache = core.newTable()
						for i = 1, GetNumMacroIcons() do
							iconCache[(GetMacroIconInfo(i))] = i
						end
					end

					macroName = UncompressText(macroName)
					CreateMacro(
						macroName == "" and " " or macroName,
						iconCache[macroIcon] or 1,
						UncompressText(macroData),
						nil,
						perCharacter
					)
					core.delTable(iconCache)
				end
			end
		end

		for i = 1, MAX_MACROS do
			local macro = select(3, GetMacroInfo(i))
			macroCache[i] = macro and CompressText(macro) or nil
		end
	end

	function RestoreAction(i, atype, actionID, binding, ...)
		if atype == "spell" then
			local spellName, spellRank = ...
			if (DB.rank or spellRank == "") and spellCache[spellName] then
				PickupSpell(spellCache[spellName], BOOKTYPE_SPELL)
			elseif spellRank ~= "" and spellCache[spellName .. spellRank] then
				PickupSpell(spellCache[spellName .. spellRank], BOOKTYPE_SPELL)
			end

			if GetCursorInfo() ~= atype then
				local lowerSpell = strlower(spellName)
				for spell, linked in pairs(DB.spellSubs) do
					if lowerSpell == spell and spellCache[linked] then
						RestoreAction(i, atype, actionID, binding, linked, nil, _G.arg3)
						return
					elseif lowerSpell == linked and spellCache[spell] then
						RestoreAction(i, atype, actionID, binding, spell, nil, _G.arg3)
						return
					end
				end

				tinsert(errorsCache, L:F('Unable to restore spell "%s" to slot #%d, it does not appear to have been learned yet.', spellName, i))
				ClearCursor()
				return
			end

			PlaceAction(i)
		elseif atype == "companion" then
			local critterName, critterType, critterID = ...
			PickupCompanion(critterType, actionID)
			if GetCursorInfo() ~= "companion" then
				tinsert(errorsCache, L:F('Unable to restore companion "%s" to slot #%d, it does not appear to exist yet.', critterName, i))
				ClearCursor()
				return
			end

			PlaceAction(i)
		elseif atype == "item" then
			PickupItem(actionID)

			if GetCursorInfo() ~= atype then
				local itemName = select(i, ...)
				tinsert(errorsCache, L:F('Unable to restore item "%s" to slot #%d, cannot be found in inventory.', itemName and itemName ~= "" and itemName or actionID, i))
				ClearCursor()
				return
			end

			PlaceAction(i)
		elseif atype == "macro" then
			PickupMacro(FindMacro(actionID, select(3, ...)) or -1)
			if GetCursorInfo() ~= atype then
				tinsert(errorsCache, L:F("Unable to restore macro id #%d to slot #%d, it appears to have been deleted.", actionID, i))
				ClearCursor()
				return
			end

			PlaceAction(i)
		elseif atype == "equipmentset" then
			for n = 1, GetNumEquipmentSets() do
				local name, icon = GetEquipmentSetInfo(n)
				if name == ... then
					PickupEquipmentSet(n)

					if GetCursorInfo() ~= atype then
						local itemName = ...
						itemName = ((itemName and itemName ~= "") and itemName or actionID) .. " (equipmentset)"
						tinsert(errorsCache, L:F('Unable to restore item "%s" to slot #%d, cannot be found in inventory.', itemName, i))
						ClearCursor()
						return
					end

					PlaceAction(i)
					return
				end
			end

			local name, icon = ...
			local iconIndex
			for n = 1, GetNumMacroIcons() do
				if GetMacroIconInfo(n):gsub("(.+)\\(.+)\\", ""):lower() == icon then
					iconIndex = n
					break
				end
			end
			if iconIndex then
				SaveEquipmentSet(name, iconIndex)
				RestoreAction(i, "equipmentset", actionID, binding, ...)
			end
		end
	end


	function ABS:SaveProfile(name)
		DB.sets[myclass][name] = DB.sets[myclass][name] or {}
		local set = DB.sets[myclass][name]

		for i = 1, 120 do
			set[i] = nil

			local atype, id, subtype, extraid = GetActionInfo(i)
			if atype and id then
				if atype == "companion" then
					set[i] = strformat("%s|%s|%s|%s|%s|%s", atype, id, "", name, subtype, extraid)
				elseif atype == "item" then
					set[i] = strformat("%s|%d|%s|%s", atype, id, "", GetItemInfo(id) or "")
				elseif atype == "equipmentset" then
					local icon = GetEquipmentSetInfoByName(id)
					if icon then
						set[i] = strformat("%s|%d|%s|%s|%s", atype, i, "", id, icon)
					end
				elseif atype == "spell" and id > 0 then
					local spell, rank = GetSpellName(id, BOOKTYPE_SPELL)
					if spell then
						set[i] = strformat("%s|%d|%s|%s|%s|%s", atype, id, "", spell, rank or "", extraid or "")
					end
				elseif atype == "macro" then
					local mname, icon, macro = GetMacroInfo(id)
					if mname and icon and macro then
						set[i] = strformat("%s|%d|%s|%s|%s|%s", atype, i, "", CompressText(mname), icon, CompressText(macro))
					end
				end
			end
		end

		Print(L:F("Saved profile %s!", name))
	end

	function ABS:RestoreProfile(name, overrideClass)
		local set = DB.sets[overrideClass or myclass][name]
		if not set then
			Print(L:F('No profile with the name "%s" exists.', set or "NaN"))
			return
		elseif InCombatLockdown() then
			Print(ERR_NOT_IN_COMBAT)
			return
		end

		for k in pairs(spellCache) do
			spellCache[k] = nil
		end

		for book = 1, MAX_SKILLLINE_TABS do
			local _, _, offset, numSpells = GetSpellTabInfo(book)

			for i = 1, numSpells do
				local index = offset + i
				local spell, rank = GetSpellName(index, BOOKTYPE_SPELL)

				spellCache[spell] = index
				spellCache[strlower(spell)] = index

				if rank and rank ~= "" then
					spellCache[spell .. rank] = index
				end
			end
		end

		for i = 1, MAX_MACROS do
			local macro = select(3, GetMacroInfo(i))
			macroCache[i] = macro and CompressText(macro) or nil
		end

		if DB.macro then
			RestoreMacros(set)
		end

		-- Start fresh with nothing on the cursor
		ClearCursor()

		for i = 1, 120 do
			local atype, id = GetActionInfo(i)

			if id or atype then
				PickupAction(i)
				ClearCursor()
			end

			if set[i] then
				RestoreAction(i, strsplit("|", set[i]))
			end
		end

		if #(errorsCache) == 0 then
			Print(L:F("Restored profile %s!", name))
		else
			Print(L:F("Restored profile %s, failed to restore %d buttons type /abs errors for more information.", name, #errorsCache))
		end
	end

	---------------------------------------------------------------------------

	core:RegisterForEvent("VARIABLES_LOADED", function()
		LoadDatabase()
		myclass = core.class
	end)

	do
		local exec = {}

		exec.save = function(name)
			if name ~= "" then
				ABS:SaveProfile(name)
			end
		end

		exec.restore = function(name)
			if name ~= "" then
				for i = #errorsCache, 1, -1 do
					tremove(errorsCache, i)
				end

				if not DB.sets[myclass][name] then
					Print(L:F('Cannot restore profile "%s", you can only restore profiles saved to your class.', name))
					return
				end

				ABS:RestoreProfile(name, myclass)
			end
		end

		exec.load = function(name)
			if name ~= "" then
				for i = #errorsCache, 1, -1 do
					tremove(errorsCache, i)
				end

				if not DB.sets[myclass][name] then
					Print(L:F('Cannot restore profile "%s", you can only restore profiles saved to your class.', name))
					return
				end

				ABS:RestoreProfile(name, myclass)
			end
		end

		exec.rename = function(arg)
			local old, new = strsplit(" ", arg, 2)
			new = strtrim(new or "")
			old = strtrim(old or "")

			if old == new then
				Print(L:F('You cannot rename "%s" to "%s" they are the same profile names.', old, new))
				return
			elseif new == "" then
				Print(L:F('No name specified to rename "%s" to.', old))
				return
			elseif DB.sets[myclass][new] then
				Print(L:F('Cannot rename "%s" to "%s" a profile already exists for %s.', old, new, myclass))
				return
			elseif DB.sets[myclass][old] then
				Print(L:F('No profile with the name "%s" exists.', old))
				return
			end

			DB.sets[myclass][new] = CopyTable(DB.sets[myclass][old])
			DB.sets[myclass][old] = nil
			Print(L:F('Renamed "%s" to "%s".', old, new))
		end

		exec.delete = function(name)
			if name ~= "" then
				DB.sets[myclass][name] = nil
				Print(L:F('Deleted saved profile "%s".', name))
			end
		end
		exec.remove = exec.delete

		exec.link = function(arg)
			local first, second = strmatch(arg, '"(.+)" "(.+)"')
			first = strtrim(first or "")
			second = strtrim(second or "")
			if first == "" or second == "" then
				Print(L["Invalid spells passed, remember you must put quotes around both of them."])
				return
			end
			DB.spellSubs[first] = second
			Print(L:F('Spells "%s" and "%s" are now linked.', first, second))
		end

		exec.errors = function()
			if #errorsCache == 0 then
				Print("No errors found!")
				return
			end

			Print(L:F("Errors found: %d", #errorsCache))
			for _, text in pairs(errorsCache) do
				print(tostring(text))
			end
		end

		exec.list = function()
			local classes, sets = {}, {}
			for class, _ in pairs(DB.sets) do
				tinsert(classes, class)
			end
			tsort(classes, function(a, b) return a < b end)
			local first

			for _, class in pairs(classes) do
				for i = #sets, 1, -1 do
					tremove(sets, i)
				end
				for name in pairs(DB.sets[class]) do
					tinsert(sets, name)
				end

				if #sets > 0 then
					if not first then
						Print(L["Available profiles are:"])
						first = true
					end
					print(strformat("|caaf49141%s|r: %s", class or "???", tconcat(sets, ", ")))
				end
			end
			first = nil
		end

		exec.macro = function()
			if DB.macro then
				DB.macro = false
				Print(L["Auto macro restoration is now disabled!"])
			else
				DB.macro = true
				Print(L["Auto macro restoration is now enabled!"])
			end
		end

		exec.count = function()
			if DB.count then
				DB.count = false
				Print(L["Checking item count is now disabled!"])
			else
				DB.count = true
				Print(L["Checking item count is now enabled!"])
			end
		end

		exec.rank = function()
			if DB.rank then
				DB.rank = false
				Print(L["Auto restoring highest spell rank is now disabled!"])
			else
				DB.rank = true
				Print(L["Auto restoring highest spell rank is now enabled!"])
			end
		end

		local function SlashCommandHandler(msg)
			msg = msg or ""
			local cmd, arg = strsplit(" ", msg, 2)
			cmd = strlower(cmd or "")
			arg = strlower(arg or "")

			if exec[cmd] then
				exec[cmd](arg)
			else
				Print(L:F("Acceptable commands for: |caaf49141%s|r", "/"..command))
				print(L["/abs save <profile> - Saves your current action bar setup under the given profile."])
				print(L["/abs restore <profile> - Changes your action bars to the passed profile."])
				print(L["/abs load <profile> - Same as /abs restore <profile>."])
				print(L["/abs delete <profile> - Deletes the saved profile."])
				print(L["/abs rename <oldProfile> <newProfile> - Renames a saved profile from oldProfile to newProfile."])
				print(L['/abs link "<spell 1>" "<spell 2>" - Links a spell with another, INCLUDE QUOTES for example you can use "Shadowmeld" "War Stomp" so if War Stomp can\'t be found, it\'ll use Shadowmeld and vica versa.'])
				print(L["/abs count - Toggles checking if you have the item in your inventory before restoring it, use if you have disconnect issues when restoring."])
				print(L["/abs macro - Attempts to restore macros that have been deleted for a profile."])
				print(L["/abs rank - Toggles if ABS should restore the highest rank of the spell, or the one saved originally."])
				print(L["/abs list - Lists all saved profiles."])
			end
		end

		local options = {
			type = "group",
			name = "ActionBarSaver",
			get = function(i)
				return DB[i[#i]]
			end,
			set = function(i, val)
				DB[i[#i]] = val
			end,
			args = {
				count = {
					type = "toggle",
					name = L["Count"],
					desc = L["Toggles checking if you have the item in your inventory before restoring it, use if you have disconnect issues when restoring."],
					order = 1
				},
				macro = {
					type = "toggle",
					name = MACROS,
					desc = L["Attempts to restore macros that have been deleted for a profile."],
					order = 2
				},
				rank = {
					type = "toggle",
					name = L["Rank"],
					desc = L["Toggles if ABS should restore the highest rank of the spell, or the one saved originally."],
					order = 3
				}
			}
		}

		core:RegisterForEvent("PLAYER_LOGIN", function()
			if _G.ABS then return end
			LoadDatabase()
			SLASH_KPACKABS1 = "/"..command
			SLASH_KPACKABS2 = "/actionbarsaver"
			SlashCmdList.KPACKABS = SlashCommandHandler
			core.options.args.Options.args.ActionBarSaver = options
		end)
	end
end)