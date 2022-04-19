local core = KPack
if not core then return end
core:AddModule("ClassColor", "Class color guild list, friends list and who list.", function()
	if core:IsDisabled("ClassColor") then return end

	local type = type
	local pairs = pairs
	local select = select
	local unpack = unpack
	local setmetatable = setmetatable
	local format = string.format
	local gsub = string.gsub
	local wipe = table.wipe
	local hooksecurefunc = hooksecurefunc
	local RAID_CLASS_COLORS = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS

	--  Class color guild/friends/etc list(yClassColor by yleaf)

	local GUILD_INDEX_MAX = 12
	local SMOOTH = {1, 0, 0, 1, 1, 0, 0, 1, 0}

	local BC = {}
	for k, v in pairs(LOCALIZED_CLASS_NAMES_MALE) do
		BC[v] = k
	end
	for k, v in pairs(LOCALIZED_CLASS_NAMES_FEMALE) do
		BC[v] = k
	end

	local function Hex(r, g, b)
		if type(r) == "table" then
			if r.r then
				r, g, b = r.r, r.g, r.b
			else
				r, g, b = unpack(r)
			end
		end

		if not r or not g or not b then
			r, g, b = 1, 1, 1
		end

		return format("|cff%02x%02x%02x", r * 255, g * 255, b * 255)
	end

	-- http://www.wowwiki.com/ColorGradient
	local function ColorGradient(perc, ...)
		if perc >= 1 then
			local r, g, b = select(select("#", ...) - 2, ...)
			return r, g, b
		elseif perc <= 0 then
			local r, g, b = ...
			return r, g, b
		end

		local num = select("#", ...) / 3

		local segment, relperc = math.modf(perc * (num - 1))
		local r1, g1, b1, r2, g2, b2 = select((segment * 3) + 1, ...)

		return r1 + (r2 - r1) * relperc, g1 + (g2 - g1) * relperc, b1 + (b2 - b1) * relperc
	end

	local guildRankColor = setmetatable({}, {__index = function(t, i)
		if i then
			t[i] = {ColorGradient(i / GUILD_INDEX_MAX, unpack(SMOOTH))}
		end
		return i and t[i] or {1, 1, 1}
	end})

	local diffColor = setmetatable({}, { __index = function(t, i)
		local c = i and GetQuestDifficultyColor(i)
		if not c then
			return "|cffffffff"
		end
		t[i] = Hex(c)
		return t[i]
	end})

	local classColorHex = setmetatable({}, {__index = function(t, i)
		local c = i and RAID_CLASS_COLORS[BC[i] or i]
		if not c then
			return "|cffffffff"
		end
		t[i] = Hex(c)
		return t[i]
	end})

	local classColors = setmetatable({}, {__index = function(t, i)
		local c = i and RAID_CLASS_COLORS[BC[i] or i]
		if not c then
			return {1, 1, 1}
		end
		t[i] = {c.r, c.g, c.b}
		return t[i]
	end})

	if CUSTOM_CLASS_COLORS then
		local function callBack()
			wipe(classColorHex)
			wipe(classColors)
		end
		CUSTOM_CLASS_COLORS:RegisterCallback(callBack)
	end

	local WHITE = {r = 1, g = 1, b = 1}
	local FRIENDS_LEVEL_TEMPLATE = FRIENDS_LEVEL_TEMPLATE:gsub("%%d", "%%s")
	FRIENDS_LEVEL_TEMPLATE = FRIENDS_LEVEL_TEMPLATE:gsub("%$d", "%$s") -- "%2$s %1$d-?? ??????"

	core:RegisterForEvent("PLAYER_LOGIN", function()
		hooksecurefunc(FriendsFrameFriendsScrollFrame, "buttonFunc", function(button, index, fristButton)
			local height, nameText, infoText, nameColor
			local playerArea = GetRealZoneText()

			if (button.buttonType == FRIENDS_BUTTON_TYPE_WOW) then
				local name, level, class, area, connected, status, note = GetFriendInfo(button.id)
				if connected then
					nameText = classColorHex[class] .. name .. "|r, " .. format(FRIENDS_LEVEL_TEMPLATE, diffColor[level] .. level .. "|r", class)
					nameColor = WHITE
					if area == playerArea then
						infoText = format("|cff00ff00%s|r", area)
					end
				end
			elseif button.buttonType == FRIENDS_BUTTON_TYPE_BNET then
				local presenceID, givenName, surname, toonName, toonID, client, isOnline, lastOnline, isAFK, isDND, messageText, noteText = BNGetFriendInfo(button.id)
				if isOnline and client == BNET_CLIENT_WOW then
					local hasFocus, name, _, _, _, _, _, _, _, _, _, _, _ = BNGetToonInfo(toonID)
					if (givenName and surname and name) then
					end
				end
			end
			if nameText then
				button.name:SetText(nameText)
			end
			if nameColor then
				button.name:SetTextColor(nameColor.r, nameColor.g, nameColor.b)
			end
			if infoText then
				button.info:SetText(infoText)
			end
		end)

		hooksecurefunc("GuildStatus_Update", function()
			local playerArea = GetRealZoneText()

			if FriendsFrame.playerStatusFrame then
				local guildOffset = FauxScrollFrame_GetOffset(GuildListScrollFrame)
				local guildIndex

				for i = 1, GUILDMEMBERS_TO_DISPLAY, 1 do
					guildIndex = guildOffset + i
					local name, rank, rankIndex, level, class, zone, note, officernote, online, status, classFileName = GetGuildRosterInfo(guildIndex)
					if not name then return end
					if online then
						local nameText = _G["GuildFrameButton" .. i .. "Name"]
						local zoneText = _G["GuildFrameButton" .. i .. "Zone"]
						local levelText = _G["GuildFrameButton" .. i .. "Level"]
						local classText = _G["GuildFrameButton" .. i .. "Class"]

						nameText:SetVertexColor(unpack(classColors[class]))
						if playerArea == zone then
							zoneText:SetFormattedText("|cff00ff00%s|r", zone)
						end
						levelText:SetText(diffColor[level] .. level)
					end
				end
			else
				local guildOffset = FauxScrollFrame_GetOffset(GuildListScrollFrame)
				local guildIndex

				for i = 1, GUILDMEMBERS_TO_DISPLAY, 1 do
					guildIndex = guildOffset + i
					local name, rank, rankIndex, level, class, zone, note, officernote, online, status, classFileName = GetGuildRosterInfo(guildIndex)
					if not name then
						return
					end
					if online then
						local nameText = _G["GuildFrameGuildStatusButton" .. i .. "Name"]
						nameText:SetVertexColor(unpack(classColors[class]))

						local rankText = _G["GuildFrameGuildStatusButton" .. i .. "Rank"]
						rankText:SetVertexColor(unpack(guildRankColor[rankIndex]))
					end
				end
			end
		end)

		hooksecurefunc("WhoList_Update", function()
			local whoIndex
			local whoOffset = FauxScrollFrame_GetOffset(WhoListScrollFrame)

			local playerZone = GetRealZoneText()
			local playerGuild = GetGuildInfo "player"
			local playerRace = UnitRace "player"

			for i = 1, WHOS_TO_DISPLAY, 1 do
				whoIndex = whoOffset + i
				local nameText = _G["WhoFrameButton" .. i .. "Name"]
				local levelText = _G["WhoFrameButton" .. i .. "Level"]
				local classText = _G["WhoFrameButton" .. i .. "Class"]
				local variableText = _G["WhoFrameButton" .. i .. "Variable"]

				local name, guild, level, race, class, zone, classFileName = GetWhoInfo(whoIndex)
				if not name then
					return
				end
				if zone == playerZone then
					zone = "|cff00ff00" .. zone
				end
				if guild == playerGuild then
					guild = "|cff00ff00" .. guild
				end
				if race == playerRace then
					race = "|cff00ff00" .. race
				end
				local columnTable = {zone, guild, race}

				nameText:SetVertexColor(unpack(classColors[class]))
				levelText:SetText(diffColor[level] .. level)
				variableText:SetText(columnTable[UIDropDownMenu_GetSelectedID(WhoFrameDropDown)])
			end
		end)

		hooksecurefunc("LFRBrowseFrameListButton_SetData", function(button, index)
			local name, level, areaName, className, comment, partyMembers, status, class, encountersTotal, encountersComplete, isLeader, isTank, isHealer, isDamage = SearchLFGGetResults(index)
			local c = class and classColors[class]
			if c then
				button.name:SetTextColor(unpack(c))
				button.class:SetTextColor(unpack(c))
			end
			if level then
				button.level:SetText(diffColor[level] .. level)
			end
		end)

		hooksecurefunc("WorldStateScoreFrame_Update", function()
			local inArena = IsActiveBattlefieldArena()
			for i = 1, MAX_WORLDSTATE_SCORE_BUTTONS do
				local index = FauxScrollFrame_GetOffset(WorldStateScoreScrollFrame) + i
				local name, killingBlows, honorableKills, deaths, honorGained, faction, rank, race, class, classToken, damageDone, healingDone = GetBattlefieldScore(index)
				if name then
					local n, r = strsplit("-", name, 2)
					n = classColorHex[classToken] .. n .. "|r"
					if n == core.name then
						n = "> " .. n .. " <"
					end

					if r then
						local color
						if inArena then
							if faction == 1 then
								color = "|cffffd100"
							else
								color = "|cff19ff19"
							end
						else
							if faction == 1 then
								color = "|cff00adf0"
							else
								color = "|cffff1919"
							end
						end
						r = color .. r .. "|r"
						n = n .. "|cffffffff-|r" .. r
					end

					local buttonNameText = _G["WorldStateScoreButton" .. i .. "NameText"]
					buttonNameText:SetText(n)
				end
			end
		end)
	end)
end)