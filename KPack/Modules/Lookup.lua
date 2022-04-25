local core = KPack
if not core then return end
core:AddModule("LookUp", "A slash command that allows you to search items and spells.", function(L)
	if core:IsDisabled("LookUp") then return end

	-- cache frequently use globals
	local GetSpellInfo, GetSpellLink = GetSpellInfo, GetSpellLink
	local GetItemInfo = GetItemInfo
	local lower, trim, find = string.lower, string.trim, string.find
	local tonumber = tonumber

	-- module's print function
	local function Print(msg)
		if msg then
			core:Print(msg, "LookUp")
		end
	end

	-- ///////////////////////////////////////////////////////
	-- Item Search
	-- ///////////////////////////////////////////////////////

	local function RequestItemLink(itemId)
		local itemName, itemLink = GetItemInfo(itemId)
		if not itemLink then
			return 0
		end
		return itemLink, itemName
	end

	local function SearchItem(query)
		local i, found = 1, 0
		query = lower(query)
		Print(L:F("Searching for items containing |cffffd700%s|r", query))

		while i < 90000 do
			local link, name = RequestItemLink(i)
			if link and link ~= 0 and find(lower(name), query) then
				print(L:F("|cffffd700Item|r: %s", link))
				found = found + 1
			end
			i = i + 1
		end
		print(L:F("Search completed, |cffffd700%d|r items matched.", found))
	end

	-- ///////////////////////////////////////////////////////
	-- Spell Search
	-- ///////////////////////////////////////////////////////

	local function RequestSpellLink(spellId)
		local name, _, _, _, _, _, id = GetSpellInfo(spellId)
		if not name then
			return 0
		end
		return GetSpellLink(spellId), name, spellId
	end

	local function SearchSpell(query)
		local i, found = 1, 0
		query = lower(query)
		Print(L:F("Searching for spells containing |cffffd700%s|r", query))

		while i < 90000 do
			local link, name, spellId = RequestSpellLink(i)
			if link and link ~= 0 and find(lower(name), query) then
				print(L:F("|cffffd700Spell|r : %s [%d]", link, spellId))
				found = found + 1
			end
			i = i + 1
		end
		print(L:F("Search completed, |cffffd700%d|r spells matched.", found))
	end

	local SlashCommandHandler
	do
		-- slash commands handler
		function SlashCommandHandler(msg)
			local cmd, rest = strsplit(" ", msg, 2)
			cmd = lower(trim(cmd))
			rest = rest and trim(rest) or ""

			-- searching for an item:
			if cmd == "item" and rest ~= "" then
				-- searching for a spell
				if tonumber(rest) ~= nil then
					local link = RequestItemLink(tonumber(rest))
					if link == 0 then
						Print(L["Item ID not found in local cache."])
					else
						print(L:F("|cffffd700Item|r: %s", link))
					end
				else
					SearchItem(rest)
				end
			elseif cmd == "spell" and rest ~= "" then
				-- otherwise tell the player
				if tonumber(rest) ~= nil then
					local link, _, spellId = RequestSpellLink(tonumber(rest))
					if link == 0 then
						Print(L["Spell ID not found in local cache."])
					else
						print(L:F("|cffffd700Spell|r : %s [%d]", link, spellId))
					end
				else
					SearchSpell(rest)
				end
			else
				Print(L:F("Acceptable commands for: |caaf49141%s|r", "/lookup"))
				print("|cffffd700item|r |cff00ffffname|r | |cff00ffffID|r : ", L["Searches for item link in local cache."])
				print("|cffffd700spell|r |cff00ffffname|r | |cff00ffffID|r : ", L["Searches for spell link."])
			end
		end
	end

	SlashCmdList["KPACKLOOKUP"] = SlashCommandHandler
	SLASH_KPACKLOOKUP1, SLASH_KPACKLOOKUP2 = "/lookup", "/lu"
end)