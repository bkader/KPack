local core = KPack
if not core then return end
core:AddModule("ChatFilter", "Filters out words or completely removes sentences from the chat when a blacklisted word has been found in the sentence.", function(L)
	if core:IsDisabled("ChatFilter") then return end

	local mod = core.ChatFilter or {}
	core.ChatFilter = mod

	-- defaults
	local DB
	local defaults = {
		enabled = true,
		verbose = false,
		words = {"wts", "wtb", "recruiting"}
	}
	local logs, last = {}, 0

	-- cache frequently used globals
	local strfind, strlower, strformat = string.find, string.lower, string.format
	local tinsert, tremove, tmaxn = table.insert, table.remove, table.maxn
	local UnitIsInMyGuild, UnitInRaid, UnitInParty = UnitIsInMyGuild, UnitInRaid, UnitInParty

	-- replace default UnitIsFriend
	local GetNumFriends = GetNumFriends
	local function UnitIsFriend(name)
		for i = 1, GetNumFriends() do
			if name == GetFriendInfo(i) then
				return true
			end
		end
		return false
	end

	-- print function
	local function Print(msg)
		if msg then
			core:Print(msg, "ChatFilter")
		end
	end

	-- dumb function to return ON or OFF
	local function ChatFilter_StatusMessage(on)
		return on and "|cff00ff00ON|r" or "|cffff0000OFF|r"
	end

	-- builds the final logs then prints it
	local function ChatFilter_PrintLog(num)
		if #logs == 0 then
			Print(L["The message log is empty."])
		else
			local count = (num > #logs) and #logs or num
			Print(L:F("Displaying the last %d messages:", count))
			for i = 1, count do
				print("|cffd3d3d3" .. i .. "|r." .. logs[i])
			end
		end
	end

	-- slash command handler
	local function SlashCommandHandler(msg)
		local cmd, rest = strsplit(" ", msg, 2)

		-- toggle the chat filter.
		if cmd == "toggle" then
			-- toggle verbose mode
			DB.enabled = not DB.enabled
			Print(L:F("filter is now %s", ChatFilter_StatusMessage(DB.enabled)))
		elseif cmd == "config" or cmd == "options" then
			core:OpenConfig("Options", "ChatFilter")
		elseif cmd == "verbose" then
			-- list words
			DB.verbose = not DB.verbose
			Print(L:F("notifications are now %s", ChatFilter_StatusMessage(DB.verbose)))
		elseif cmd == "words" or cmd == "list" then
			-- logs of messages that were hidden
			Print(L["filter keywords are:"])
			local words = core.newTable()
			for i, word in ipairs(DB.words) do
				words[i] = i .. ".|cff00ffff" .. word .. "|r"
			end
			print(table.concat(words, ", "))
			core.delTable(words)
		elseif cmd == "log" or cmd == "logs" then
			-- add a new word to the list
			if rest then
				if not strmatch(rest, "%d") then
					Print(L["Input is not a number"])
				end
				ChatFilter_PrintLog(tonumber(rest))
			else
				ChatFilter_PrintLog(10)
			end
		elseif cmd == "add" and rest then
			-- remove a word from the list
			tinsert(DB.words, rest:trim())
			Print(L:F("the word |cff00ffff%s|r was added successfully.", rest:trim()))
		elseif (cmd == "remove" or cmd == "delete" or cmd == "del") and rest then
			-- reset or default values
			if not strmatch(rest, "%d") then
				Print(L["Input is not a number"])
				return
			end

			local count = #DB.words
			local index = tonumber(rest)
			if index > count then
				Print(L:F("Index is out of range. Max value is |cff00ffff%d|r.", count))
				return
			end

			local word = DB.words[index]
			tremove(DB.words, index)
			Print(L:F("the word |cff00ffff%s|r was removed successfully.", word))
		elseif cmd == "default" or cmd == "reset" then
			-- anything else will display the help menu
			DB = CopyTable(defaults)
			Print(L["module's settings reset to default."])

			-- clear logs
			wipe(logs)
			last = 0
		else
			Print(L:F("Acceptable commands for: |caaf49141%s|r", "/cf"))
			print("|cffffd700toggle|r : ", L["Turn filter |cff00ff00ON|r / |cffff0000OFF|r"])
			print("|cffffd700words|r : ", L["View filter keywords (case-insensitive)"])
			print("|cffffd700add|r |cff00ffffword|r : ", L["Adds a |cff00ffffkeyword|r"])
			print("|cffffd700del|r |cff00ffffpos|r : ", L["Remove keyword by |cff00ffffposition|r"])
			print("|cffffd700verbose|r : ", L["Show or hide filter notifications"])
			print("|cffffd700log|r |cff00ffffn|r : ", L["View the last |cff00ffffn|r filtered messages (up to 20)"])
			print("|cffffd700config|r : ", L["Access module settings."])
			print("|cffffd700reset|r : ", L["Resets module settings to default."])
		end
	end

	-- the main filter function
	local ChatFilter_Filter
	do
		-- adds a filtered message to the logs table.
		local function ChatFilter_AddLog(name, msg)
			if DB.verbose and last + 2 <= GetTime() then
				Print(L:F("filtered a message from |cff00ffff%s|r", name))
				last = GetTime()
			end

			local message = strformat("|cffd3d3d3[%s]|r: %s", name, msg)
			if not tContains(logs, message) then
				tinsert(logs, 0, message)
			end

			-- remove the last element if we exceed 20
			while tmaxn(logs) > 20 do
				tremove(logs)
			end
		end

		function ChatFilter_Filter(self, event, msg, player, ...)
			-- we don't filter messages if the filter is disabled
			-- or the player is from the guild
			-- or the player is a friend
			-- or the player is in a raid or party group
			if not DB.enabled or UnitIsInMyGuild(player) or UnitIsFriend(player) or UnitInRaid(player) or UnitInParty(player) then
				return false
			end

			local temp, count = strlower(msg), #DB.words
			for i = 1, count do
				if strfind(temp, strlower(DB.words[i])) then
					ChatFilter_AddLog(player, msg)
					return true
				end
			end
		end
	end

	local function disabled()
		return not DB.enabled
	end
	local options = {
		type = "group",
		name = L["Chat Filter"],
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
			verbose = {
				type = "toggle",
				name = L["Verbose Mode"],
				desc = L["Notifies you whenever a message is filtered."],
				order = 2,
				disabled = disabled
			},
			header = {
				type = "header",
				name = L["Keywords"],
				order = 3
			},
			words = {
				type = "description",
				name = function()
					return table.concat(DB.words, ", ")
				end,
				order = 4,
				width = "full"
			},
			sep1 = {
				type = "description",
				name = " ",
				order = 5,
				width = "full"
			},
			cmd = {
				type = "description",
				name = L:F("Type |cffffd700/%s|r in chat for more.", "cf"),
				order = 6,
				width = "full"
			}
		}
	}

	local function SetupDatabase()
		if type(core.db.ChatFilter) ~= "table" or not next(core.db.ChatFilter) then
			core.db.ChatFilter = CopyTable(defaults)
		end
		DB = core.db.ChatFilter
	end

	core:RegisterForEvent("PLAYER_LOGIN", function(_, name)
		SetupDatabase()

		-- register our slash commands handler
		SlashCmdList["KPACKCHATFILTER"] = SlashCommandHandler
		SLASH_KPACKCHATFILTER1, SLASH_KPACKCHATFILTER2 = "/chatfilter", "/cf"

		core.options.args.Options.args.ChatFilter = options
	end)

	core:RegisterForEvent("PLAYER_ENTERING_WORLD", function()
		if not DB then
			SetupDatabase()
		end
		ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", ChatFilter_Filter)
		ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", ChatFilter_Filter)
		ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", ChatFilter_Filter)
	end)
end)