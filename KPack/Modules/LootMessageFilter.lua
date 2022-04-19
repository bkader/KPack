local core = KPack
if not core then return end
core:AddModule("LootMessageFilter", "Filters loot messages from other players in your group, based on item quality.", function(L)
	if core:IsDisabled("LootMessageFilter") then return end

	local find, match, lower = string.find, string.match, string.lower
	local select, ipairs = select, ipairs
	local GetItemInfo = GetItemInfo

	-- items quality string holders.
	local colors = {
		"|cff9d9d9d%s|r",
		"|cffffffff%s|r",
		"|cff1eff00%s|r",
		"|cff0070dd%s|r",
		"|cffa335ee%s|r",
		"|cffff8000%s|r",
		"|cffe6cc80%s|r"
	}

	-- module's print function
	local function Print(msg)
		if msg then
			core:Print(msg, "LootMessageFilter")
		end
	end

	-- slash commands handler
	local function SlashCommandHandler(cmd)
		local color, quality
		if cmd == "poor" or cmd == "0" then
			core.db.LMF = 0
			quality = ITEM_QUALITY0_DESC
			color = colors[1]
		elseif cmd == "common" or cmd == "1" then
			core.db.LMF = 1
			quality = ITEM_QUALITY1_DESC
			color = colors[2]
		elseif cmd == "uncommon" or cmd == "2" then
			core.db.LMF = 2
			quality = ITEM_QUALITY2_DESC
			color = colors[3]
		elseif cmd == "rare" or cmd == "3" then
			core.db.LMF = 3
			quality = ITEM_QUALITY3_DESC
			color = colors[4]
		elseif cmd == "epic" or cmd == "4" then
			core.db.LMF = 4
			quality = ITEM_QUALITY4_DESC
			color = colors[5]
		elseif cmd == "legendary" or cmd == "5" then
			core.db.LMF = 5
			quality = ITEM_QUALITY5_DESC
			color = colors[6]
		elseif cmd == "heirloom" or cmd == "6" then
			core.db.LMF = 6
			quality = ITEM_QUALITY7_DESC
			color = colors[7]
		elseif cmd == "status" then
			local i = core.db.LMF
			quality = _G["ITEM_QUALITY" .. i .. "_DESC"]
			color = colors[i + 1]
		end

		if quality and color then
			Print(L:F("Minimum item rarity for loot filter set to %s", color:format(quality)))
		else
			Print(L:F("Acceptable commands for: |caaf49141%s|r", "/lmf"))
			for i, c in ipairs(colors) do
				print("|caaf49141" .. (i - 1) .. "|r -", c:format(_G["ITEM_QUALITY" .. (i - 1) .. "_DESC"]))
			end
			print("|caaf49141status|r", L["Check the filter status."])
		end
	end

	-- function hooked to chat frame.
	local function LMF_Initialize(self, event, msg)
		if not match(msg, "Hbattlepet") then
			local itemId = select(3, find(msg, "item:(%d+):"))
			local rarity = select(3, GetItemInfo(itemId))
			if (rarity < core.db.LMF) and (find(msg, "receives") or find(msg, "gets") or find(msg, "creates")) then
				return true
			else
				return false
			end
		end
		return false
	end

	local function SetupDatabase()
		if not core.db.LMF or type(core.db.LMF) ~= "number" then
			core.db.LMF = 2
		end
	end
	core:RegisterForEvent("PLAYER_LOGIN", SetupDatabase)

	core:RegisterForEvent("PLAYER_ENTERING_WORLD", function()
		SetupDatabase()
		ChatFrame_AddMessageEventFilter("CHAT_MSG_LOOT", LMF_Initialize)
	end)

	SlashCmdList["KPACKLMF"] = SlashCommandHandler
	SLASH_KPACKLMF1 = "/lmf"
end)