local core = KPack
if not core then return end
core:AddModule("FriendsInfo", "Adds info to the friends list.", function(L)
	if core:IsDisabled("FriendsInfo") then return end

	local DB

	-- cache frequently used globals
	local BNGetFriendInfo, GetFriendInfo = BNGetFriendInfo, GetFriendInfo
	local FriendsFrame_GetLastOnline = FriendsFrame_GetLastOnline
	local GetRealmName = GetRealmName
	local format, time, type = string.format, time, type

	-- needed locals
	local realm

	-- module default print function.
	local function Print(msg)
		if msg then
			core:Print(msg, "FriendsInfo")
		end
	end

	-- this function is hooked to default FriendsFrame scroll frame
	local function FriendsInfo_SetButton(button, index, firstButton)
		local noteColor = "|cfffde05c"

		if button.buttonType == FRIENDS_BUTTON_TYPE_BNET then
			local _, _, _, _, _, _, _, _, _, _, _, noteText, _, _ = BNGetFriendInfo(button.id)
			if noteText then
				button.info:SetText(button.info:GetText() .. " " .. noteColor .. "(" .. noteText .. ")")
			end
		end

		if button.buttonType ~= FRIENDS_BUTTON_TYPE_WOW then
			return
		end

		local name, level, class, area, connected, _, note = GetFriendInfo(button.id)
		if not name then
			return
		end

		local n
		if note then
			n = noteColor .. "(" .. note .. ")"
		end

		-- add the friend to database
		DB[realm] = DB[realm] or {}
		DB[realm][name] = DB[realm][name] or {}

		-- is the player online?
		if connected then
			-- offline? display old details.
			DB[realm][name].level = level
			DB[realm][name].class = class
			DB[realm][name].area = area
			DB[realm][name].lastSeen = format("%i", time())

			if n then
				button.info:SetText(button.info:GetText() .. " " .. n)
			end
		else
			level = DB[realm][name].level
			class = DB[realm][name].class
			if class and level then
				local nameText = name .. ", " .. format(FRIENDS_LEVEL_TEMPLATE, level, class)
				button.name:SetText(nameText)
			end

			local lastSeen = DB[realm][name].lastSeen
			if lastSeen then
				local infoText = L:F("Last seen %s ago", FriendsFrame_GetLastOnline(lastSeen))
				if n then
					button.info:SetText(infoText .. " " .. n)
				else
					button.info:SetText(infoText)
				end
			elseif n then
				button.info:SetText(n)
			end
		end
	end

	-- initializes the module.
	local function FriendsInfo_Initialize()
		realm = GetRealmName()
		hooksecurefunc(FriendsFrameFriendsScrollFrame, "buttonFunc", FriendsInfo_SetButton)
	end

	core:RegisterForEvent("PLAYER_LOGIN", function(_, name)
		core.db.FriendsInfo = core.db.FriendsInfo or {}
		DB = core.db.FriendsInfo
	end)

	core:RegisterForEvent("PLAYER_ENTERING_WORLD", function()
		FriendsInfo_Initialize()
	end)
end)