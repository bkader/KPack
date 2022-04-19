local core = KPack
if not core then return end
core:AddModule("IgnoreMore", "Let you ignore more than 49 players, a list shared between all characters of the same account.", function(L)
	if core:IsDisabled("IgnoreMore") then return end

	local mod = core.IgnoreMore or {}
	core.IgnoreMore = mod

	local DB
	local defaults = {
		enabled = true,
		list = {}
	}

	local frame = CreateFrame("Frame")
	local realm

	-- cache frequently used globlas
	local strmatch, strupper, strsub, gsub = string.match, string.upper, string.sub, string.gsub
	local pairs, ipairs, next, type = pairs, ipairs, next, type
	local tonumber, tostring = tonumber, tostring
	local format, print = string.format, print
	local GetTime, time, date = GetTime, time, date
	local tinsert, tremove, sort = table.insert, table.remove, table.sort
	local min, max = math.min, math.max
	local UnitName = UnitName

	-- needed locals
	local list
	local ignoredPlayers, systemIgnoreList = core.WeakTable(), core.WeakTable()
	local IgnoreMore_ChatFilter, IgnoreMore_SystemFilter

	-- function that returns nothing
	local function noFunc()
	end

	-- module's print function
	local function Print(msg)
		if msg then
			core:Print(msg, "IgnoreMore")
		end
	end

	-- ///////////////////////////////////////////////////////
	-- Utilities
	-- ///////////////////////////////////////////////////////

	-- shorten the date for better display
	local function IgnoreMore_ShortDate(when)
		return date((time() - when < 17280000) and "%d %b" or "%b %Y", when)
	end

	-- fixes the name
	local function IgnoreMore_FixName(name)
		if strmatch(name, "^[a-z]") then
			return strupper(strsub(name, 1, 1)) .. strsub(name, 2)
		end
		return name
	end

	-- used to split arguments
	local function IgnoreMore_SplitArgs(str)
		local n, r = strmatch(str, "^ *(..-) *: *(.*)")
		if not n then
			n = strmatch(str, "^ *(..-) *$")
		end
		if not n then
			Print(L:F("%s does not look like a valid player name.", str))
			return
		end
		if strmatch(n, " ") and not strmatch(n, "^.[^ ]-%-") then
			Print(L:F("%s does not look like a valid player name.", str))
			return
		end
		return n, r
	end

	local function IgnoreMore_GetRealm()
		local realm, faction = GetRealmName(), UnitFactionGroup("player")
		return faction and format("%s-%s", realm, faction) or realm
	end

	-- ///////////////////////////////////////////////////////
	-- Fake event generators
	-- ///////////////////////////////////////////////////////

	-- generates a fake event
	local function IgnoreMore_GenerateEvent(evtname, ...)
		local a1, a2, a3, a4, a5, a6, a7, a8, a9 = _G.arg1, _G.arg2, _G.arg3, _G.arg4, _G.arg5, _G.arg6, _G.arg7, _G.arg8, _G.arg9
		local e = _G.event
		local t = _G.this

		--DBG print("Generating event",evtname,...)
		for i, frame in ipairs({_G.GetFramesRegisteredForEvent(evtname)}) do
			local onevent = frame:GetScript("OnEvent")
			if onevent then
				_G.this = frame
				_G.event = evtname
				_G.arg1, _G.arg2, _G.arg3, _G.arg4, _G.arg5, _G.arg6, _G.arg7, _G.arg8, _G.arg9 = ...
				onevent(frame, evtname, ...)
			end
		end
		_G.this = t
		_G.event = e
		_G.arg1, _G.arg2, _G.arg3, _G.arg4, _G.arg5, _G.arg6, _G.arg7, _G.arg8, _G.arg9 = a1, a2, a3, a4, a5, a6, a7, a8, a9
	end

	-- generates a fake system message.
	local function IgnoreMore_GenerateSysMsg(msg)
		IgnoreMore_GenerateEvent("CHAT_MSG_SYSTEM", msg, "", "", "", "", "", "", "", "", "", "")
	end

	-- ///////////////////////////////////////////////////////
	-- Replacing some default functions.
	-- ///////////////////////////////////////////////////////

	-- replace the default AddIgnore function
	local Old_AddIgnore = _G.AddIgnore
	_G.AddIgnore = function(name, reason, quiet)
		if not list then
			return Old_AddIgnore(name)
		end

		if type(name) ~= "string" or #name < 2 then
			return
		end
		name = IgnoreMore_FixName(name)

		if name == UnitName("player") then
			if not quiet then
				IgnoreMore_GenerateSysMsg(_G.ERR_IGNORE_SELF)
			end
			return false
		end

		local entry = list[name]

		if not reason and type(entry) == "table" then
			if not quiet then
				IgnoreMore_GenerateSysMsg(format(_G.ERR_IGNORE_ALREADY_S, name))
			end
			return false
		end

		if type(entry) == "table" then
			-- just an update, no creation
		else
			entry = {}
			tinsert(ignoredPlayers, name)
			list[name] = entry
		end

		entry.time = time()
		entry.reason = reason

		if not quiet then
			if reason then
				IgnoreMore_GenerateSysMsg(format(_G.ERR_IGNORE_ADDED_S, name) .. ' "' .. reason .. '"')
			else
				IgnoreMore_GenerateSysMsg(format(_G.ERR_IGNORE_ADDED_S, name))
			end
		end

		IgnoreMore_GenerateEvent("IGNORELIST_UPDATE")
		return true
	end

	-- replace the default DelIgnore function
	local Old_DelIgnore = _G.DelIgnore
	_G.DelIgnore = function(name, quiet)
		if not list then
			return Old_DelIgnore(name)
		end

		name = IgnoreMore_FixName(name)

		if type(list[name]) ~= "table" then
			if not quiet then
				IgnoreMore_GenerateSysMsg(_G.ERR_IGNORE_NOT_FOUND)
			end
			return false
		end

		for k, v in pairs(ignoredPlayers) do
			if v == name then
				tremove(ignoredPlayers, k)
				break
			end
		end

		list[name] = nil

		if systemIgnoreList[name] then
			Old_DelIgnore(name)
			systemIgnoreList[name] = nil
		elseif not quiet then
			IgnoreMore_GenerateSysMsg(format(_G.ERR_IGNORE_REMOVED_S, name))
			IgnoreMore_GenerateEvent("IGNORELIST_UPDATE")
		end
		return true
	end

	-- replace the default AddOrDelIgnore function
	local Old_AddOrDelIgnore = _G.AddOrDelIgnore
	_G.AddOrDelIgnore = function(name, reason, quiet)
		if not list then
			return Old_AddOrDelIgnore(name)
		end

		name = IgnoreMore_FixName(name)
		if (reason or "") ~= "" or type(list[name]) ~= "table" then
			AddIgnore(name, reason, quiet)
		else
			DelIgnore(name, quiet)
		end
	end

	-- replace the default GetIgnoreName function
	local Old_GetIgnoreName = _G.GetIgnoreName
	_G.GetIgnoreName = function(i)
		if not list then
			return Old_GetIgnoreName(i)
		end
		return ignoredPlayers[i] or UNKNOWN
	end

	-- replace the default GetNumIgnores function
	local Old_GetNumIgnores = _G.GetNumIgnores
	_G.GetNumIgnores = function()
		return list and #ignoredPlayers or Old_GetNumIgnores()
	end

	-- ignore list selection
	do
		-- holds the index of the selected ignored player
		local selected

		-- replace default GetSelectedIgnore function
		local Old_GetSelectedIgnore = _G.GetSelectedIgnore
		_G.GetSelectedIgnore = function()
			if not list then
				return Old_GetSelectedIgnore()
			end
			selected = selected or 0
			if selected > #ignoredPlayers then
				selected = 0
			end
			return selected
		end

		-- replace default SetSelectedIgnore function
		local Old_SetSelectedIgnore = _G.SetSelectedIgnore
		_G.SetSelectedIgnore = function(i)
			if not list then
				Old_SetSelectedIgnore(i)
			end
			selected = i
		end
	end

	-- add our custom ignore reason
	local GetIgnoreReason = function(who)
		if not list then
			return nil
		end

		local i = tonumber(who)
		if i then
			who = ignoredPlayers[i]
		end
		if not who then
			return nil
		end

		local entry = list[who]
		if type(entry) ~= "table" then
			return nil
		end
		return entry.reason or ""
	end

	-- ///////////////////////////////////////////////////////

	do
		-- right column table
		local column2 = {}

		-- replace default IgnoreList_Update function
		local Old_IgnoreList_Update = _G.IgnoreList_Update
		_G.IgnoreList_Update = function(...)
			Old_IgnoreList_Update(...)

			if not list or not FriendsFrameIgnoreScrollFrame then
				return
			end

			local ignoreOffset = FauxScrollFrame_GetOffset(FriendsFrameIgnoreScrollFrame)
			local maxwid, buttonwid = 0, 0
			for i = 1, IGNORES_TO_DISPLAY, 1 do
				local ignoreIndex = i + ignoreOffset
				local nameText = _G["FriendsFrameIgnoreButton" .. i].name
				local ignoreButton = _G["FriendsFrameIgnoreButton" .. i]
				if nameText and ignoreButton then
					buttonwid = ignoreButton:GetWidth()
					if not column2[i] then
						column2[i] = ignoreButton:CreateFontString("FontString", "OVERLAY", "GameFontHighlightSmall")
						column2[i]:SetJustifyH("LEFT")
						column2[i]:SetPoint("BOTTOMRIGHT", ignoreButton)
						column2[i]:SetPoint("TOP", ignoreButton)
					end

					local txt = ""
					maxwid = max(maxwid, nameText:GetStringWidth())
					local entry = list[nameText:GetText()]
					if type(entry) == "table" then
						if entry.time then
							txt = txt .. IgnoreMore_ShortDate(entry.time)
						end
						if entry.reason then
							txt = txt .. ": " .. entry.reason
						end
					end
					column2[i]:SetText(txt)
				end
			end

			for i = 1, IGNORES_TO_DISPLAY, 1 do
				if column2[i] then
					column2[i]:SetWidth(buttonwid - maxwid - 30)
				end
			end
		end
	end

	-- ///////////////////////////////////////////////////////

	do
		local lastOnClick_time, lastOnClick_button = 0
		local Old_FriendsFrameIgnoreButton_OnClick = _G.FriendsFrameIgnoreButton_OnClick
		_G.FriendsFrameIgnoreButton_OnClick = function(self, ...)
			Old_FriendsFrameIgnoreButton_OnClick(self, ...)
			if not list then
				return
			end

			local now = GetTime()
			if lastOnClick_button == self and now - lastOnClick_time < 0.3 then
				StaticPopup_Show("EDIT_IGNORE_REASON")
			end
			lastOnClick_button = self
			lastOnClick_time = now
		end
	end

	-- ///////////////////////////////////////////////////////
	-- Make a popup dialog for editing ignore reasons
	-- ///////////////////////////////////////////////////////

	do
		local dialog = {}
		for k, v in pairs(StaticPopupDialogs["SET_FRIENDNOTE"]) do
			dialog[k] = v
		end
		dialog.maxLetters = 256
		dialog.text = L["Reason for ignoring this player:"]
		dialog.OnAccept = function(self)
			AddIgnore(GetIgnoreName(GetSelectedIgnore()), self.wideEditBox:GetText():trim())
		end
		dialog.EditBoxOnEnterPressed = function(self)
			local parent = self:GetParent()
			dialog.OnAccept(parent)
			parent:Hide()
		end
		dialog.OnShow = function(self)
			local reason = GetIgnoreReason(GetSelectedIgnore()) or ""
			self.wideEditBox:SetText(reason)
			self.wideEditBox:SetFocus()
		end
		StaticPopupDialogs["EDIT_IGNORE_REASON"] = dialog
	end

	-- ///////////////////////////////////////////////////////

	local SlashCommandHandler
	do
		local exec = {}
		local help = "|cffffd700%s|r: %s"

		exec.enable = function()
			if not DB.enabled then
				DB.enabled = true
				Print(L:F("module status: %s", L["|cff00ff00enabled|r"]) .. " " .. L["Please reload ui."])
			end
		end
		exec.on = exec.enable

		exec.disable = function()
			if DB.enabled then
				DB.enabled = false
				Print(L:F("module status: %s", L["|cffff0000disabled|r"]) .. " " .. L["Please reload ui."])
			end
		end
		exec.off = exec.disable

		exec.wipe = function()
			realm = realm or IgnoreMore_GetRealm()
			wipe(DB.list[realm])
			list = DB.list[realm]
			Print(L["ignore list wiped"])
		end

		function SlashCommandHandler(msg)
			local cmd, rest = strsplit(" ", msg, 2)
			if type(exec[cmd]) == "function" then
				exec[cmd](rest)
			else
				Print(L:F("Acceptable commands for: |caaf49141%s|r", "/im"))
				print(format(help, "enable", L["enable module"]))
				print(format(help, "disable", L["disable module"]))
				print(format(help, "wipe", L["wipe the ingore list"]))
			end
		end
	end

	-- ///////////////////////////////////////////////////////

	do
		local events = {
			"CHAT_MSG_ACHIEVEMENT",
			"CHAT_MSG_BATTLEGROUND",
			"CHAT_MSG_BATTLEGROUND_LEADER",
			"CHAT_MSG_CHANNEL",
			"CHAT_MSG_CHANNEL_JOIN",
			"CHAT_MSG_CHANNEL_LEAVE",
			"CHAT_MSG_EMOTE",
			"CHAT_MSG_GUILD",
			"CHAT_MSG_GUILD_ACHIEVEMENT",
			"CHAT_MSG_OFFICER",
			"CHAT_MSG_PARTY",
			"CHAT_MSG_RAID",
			"CHAT_MSG_RAID_LEADER",
			"CHAT_MSG_RAID_WARNING",
			"CHAT_MSG_SAY",
			"CHAT_MSG_TEXT_EMOTE",
			"CHAT_MSG_WHISPER",
			"CHAT_MSG_WHISPER_INFORM",
			"CHAT_MSG_YELL"
		}

		local function IgnoreMore_Pattern(str)
			str = gsub(str, "[%[%]%(%)%%%.%-%+%*]", function(ch) return "%" .. ch end)
			return gsub(str, "%%%%s", "(.-)")
		end

		local _ERR_INVITED_TO_GROUP_SS = "^" .. IgnoreMore_Pattern(ERR_INVITED_TO_GROUP_SS)
		local _ERR_INVITED_ALREADY_IN_GROUP_SS = "^" .. IgnoreMore_Pattern(ERR_INVITED_ALREADY_IN_GROUP_SS)

		local notified = {}

		function IgnoreMore_ChatFilter(self, event, msg, source, ...)
			if list and type(source) == "string" and source ~= "" and type(list[source]) == "table" then
				if event == "CHAT_MSG_WHISPER_INFORM" then
					return false, msg .. " (NOTE: You are ignoring this player!)", source, ...
				end
				return true
			end
		end

		function IgnoreMore_SystemFilter(self, event, msg, ...)
			local player = strmatch(msg, _ERR_INVITED_TO_GROUP_SS) or strmatch(msg, _ERR_INVITED_ALREADY_IN_GROUP_SS)
			if player and list and type(list[player]) == "table" then
				if notified[player] then
					return true
				else
					local entry = list[player]
					notified[player] = true
					msg = msg .. L:F("(Ignored: %s: %s. Further attempts will not be shown.)", IgnoreMore_ShortDate(entry.time), entry.reason or "")
					return false, msg, ...
				end
			end
		end

		local function IgnoreMore_OnUpdate(self, elapsed)
			frame:Hide()

			if not DB.enabled then
				list = nil
				return
			end

			list = DB.list[realm]

			local num = GetNumIgnores()
			for i = num, 1, -1 do
				local name = GetIgnoreName(i)
				if type(name) ~= "string" or name == "" or name == UNKNOWN then
					-- nothing
				elseif not list[name] then
					list[name] = {
						time = time(),
						reason = L:F("From %s's system ignore list.", UnitName("player"))
					}
					systemIgnoreList[name] = true
				elseif type(list[name]) ~= "table" then
					DelIgnore(name)
				else
					systemIgnoreList[name] = true
				end
			end

			for k, v in pairs(list) do
				if type(k) ~= "string" or k == "" then
					list[k] = nil
				end

				if type(v) == "table" then
					tinsert(ignoredPlayers, k)
				end
			end

			sort(ignoredPlayers)

			for _, event in pairs(events) do
				ChatFrame_AddMessageEventFilter(event, IgnoreMore_ChatFilter)
			end
			ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", IgnoreMore_SystemFilter)
		end

		core:RegisterForEvent("VARIABLES_LOADED", function()
			-- set our default variables
			if type(core.db.IgnoreMore) ~= "table" or not next(core.db.IgnoreMore) then
				core.db.IgnoreMore = CopyTable(defaults)
			end
			DB = core.db.IgnoreMore

			realm = realm or IgnoreMore_GetRealm()
			DB.list[realm] = DB.list[realm] or {}

			-- register our slash commands handler
			SlashCmdList["KPACKIGNOREMORE"] = SlashCommandHandler
			SLASH_KPACKIGNOREMORE1 = "/im"
			SLASH_KPACKIGNOREMORE2 = "/ignoremore"
			SLASH_KPACKIGNOREMORE3 = "/igmore"

			if DB.enabled then
				UIParent:UnregisterEvent("PARTY_INVITE_REQUEST")
				UIParent:UnregisterEvent("DUEL_REQUESTED")
				frame:SetScript("OnUpdate", IgnoreMore_OnUpdate)
				frame:Show()
			else
				UIParent:RegisterEvent("PARTY_INVITE_REQUEST")
				UIParent:RegisterEvent("DUEL_REQUESTED")
				frame:SetScript("OnUpdate", nil)
				frame:Hide()
			end
		end)
	end

	-- whether to accept or decline invites.
	core:RegisterForEvent("PARTY_INVITE_REQUEST", function(_, name)
		if not DB.enabled then
			return
		elseif list and type(list[name]) == "table" then
			DeclineGroup()
		else
			StaticPopup_Show("PARTY_INVITE", name)
		end
	end)

	-- cancel or accept duels.
	core:RegisterForEvent("DUEL_REQUESTED", function(_, name)
		if not DB.enabled then
			return
		elseif list and type(list[name]) == "table" then
			CancelDuel()
		else
			StaticPopup_Show("DUEL_REQUESTED", name)
		end
	end)

	-- handles trade window show
	core:RegisterForEvent("TRADE_SHOW", function(_, ...)
		if not DB.enabled then
			return
		end
		local name = UnitName("NPC")
		if list and name and type(list[name]) == "table" then
			CloseTrade()
		else
			TradeFrame:GetScript("OnEvent")(TradeFrame, ...)
		end
	end)

	-- the following function can be used by other modules/addons
	-- to check if the given name is on the ignore list.
	function mod:IsIgnored(name)
		for i = 1, GetNumIgnores() do
			local n = GetIgnoreName(i)
			if n == name then
				return true
			end
		end
		return false
	end
end)