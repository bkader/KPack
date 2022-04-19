local core = KPack
if not core then return end
core:AddModule("GearScoreLite", "GearScoreLite is a trimmed down version of GearScore.", function(L)
	if core:IsDisabled("GearScoreLite") then return end

	local mod = core.GearScore or {}
	core.GearScore = mod

	local _
	local pairs, ipairs = pairs, ipairs
	local unpack = unpack
	local UnitName, UnitClass = UnitName, UnitClass
	local UnitIsPlayer, UnitIsUnit = UnitIsPlayer, UnitIsUnit
	local CanInspect, NotifyInspect = CanInspect, NotifyInspect
	local GetInventoryItemLink = GetInventoryItemLink

	local GearScore_GetScore
	local GearScore_GetEnchantInfo
	local GearScore_GetItemScore
	local GearScore_GetQuality
	local GearScore_HookSetUnit
	local GearScore_HookSetItem
	local GearScore_HookRefItem
	local GearScore_HookCompareItem
	local GearScore_HookCompareItem2
	local GearScore_HookItem
	local GearScore_OnEnter
	local MyPaperDoll
	local GS_MANSET
	local unitName

	local DB
	local PersonalGearScore

	local itemTypes = {
		["INVTYPE_RELIC"] = {["SlotMOD"] = 0.3164, ["ItemSlot"] = 18, ["Enchantable"] = false},
		["INVTYPE_TRINKET"] = {["SlotMOD"] = 0.5625, ["ItemSlot"] = 33, ["Enchantable"] = false},
		["INVTYPE_2HWEAPON"] = {["SlotMOD"] = 2.000, ["ItemSlot"] = 16, ["Enchantable"] = true},
		["INVTYPE_WEAPONMAINHAND"] = {["SlotMOD"] = 1.0000, ["ItemSlot"] = 16, ["Enchantable"] = true},
		["INVTYPE_WEAPONOFFHAND"] = {["SlotMOD"] = 1.0000, ["ItemSlot"] = 17, ["Enchantable"] = true},
		["INVTYPE_RANGED"] = {["SlotMOD"] = 0.3164, ["ItemSlot"] = 18, ["Enchantable"] = true},
		["INVTYPE_THROWN"] = {["SlotMOD"] = 0.3164, ["ItemSlot"] = 18, ["Enchantable"] = false},
		["INVTYPE_RANGEDRIGHT"] = {["SlotMOD"] = 0.3164, ["ItemSlot"] = 18, ["Enchantable"] = false},
		["INVTYPE_SHIELD"] = {["SlotMOD"] = 1.0000, ["ItemSlot"] = 17, ["Enchantable"] = true},
		["INVTYPE_WEAPON"] = {["SlotMOD"] = 1.0000, ["ItemSlot"] = 36, ["Enchantable"] = true},
		["INVTYPE_HOLDABLE"] = {["SlotMOD"] = 1.0000, ["ItemSlot"] = 17, ["Enchantable"] = false},
		["INVTYPE_HEAD"] = {["SlotMOD"] = 1.0000, ["ItemSlot"] = 1, ["Enchantable"] = true},
		["INVTYPE_NECK"] = {["SlotMOD"] = 0.5625, ["ItemSlot"] = 2, ["Enchantable"] = false},
		["INVTYPE_SHOULDER"] = {["SlotMOD"] = 0.7500, ["ItemSlot"] = 3, ["Enchantable"] = true},
		["INVTYPE_CHEST"] = {["SlotMOD"] = 1.0000, ["ItemSlot"] = 5, ["Enchantable"] = true},
		["INVTYPE_ROBE"] = {["SlotMOD"] = 1.0000, ["ItemSlot"] = 5, ["Enchantable"] = true},
		["INVTYPE_WAIST"] = {["SlotMOD"] = 0.7500, ["ItemSlot"] = 6, ["Enchantable"] = false},
		["INVTYPE_LEGS"] = {["SlotMOD"] = 1.0000, ["ItemSlot"] = 7, ["Enchantable"] = true},
		["INVTYPE_FEET"] = {["SlotMOD"] = 0.75, ["ItemSlot"] = 8, ["Enchantable"] = true},
		["INVTYPE_WRIST"] = {["SlotMOD"] = 0.5625, ["ItemSlot"] = 9, ["Enchantable"] = true},
		["INVTYPE_HAND"] = {["SlotMOD"] = 0.7500, ["ItemSlot"] = 10, ["Enchantable"] = true},
		["INVTYPE_FINGER"] = {["SlotMOD"] = 0.5625, ["ItemSlot"] = 31, ["Enchantable"] = false},
		["INVTYPE_CLOAK"] = {["SlotMOD"] = 0.5625, ["ItemSlot"] = 15, ["Enchantable"] = true},
		--Lol Shirt
		["INVTYPE_BODY"] = {["SlotMOD"] = 0, ["ItemSlot"] = 4, ["Enchantable"] = false}
	}

	local defaults = {
		["Player"] = true,
		["Item"] = true,
		["Compare"] = true,
		["Level"] = false,
	}

	local itemRarity = {
		[0] = {Red = 0.55, Green = 0.55, Blue = 0.55},
		[1] = {Red = 1.00, Green = 1.00, Blue = 1.00},
		[2] = {Red = 0.12, Green = 1.00, Blue = 0.00},
		[3] = {Red = 0.00, Green = 0.50, Blue = 1.00},
		[4] = {Red = 0.69, Green = 0.28, Blue = 0.97},
		[5] = {Red = 0.94, Green = 0.09, Blue = 0.00},
		[6] = {Red = 1.00, Green = 0.00, Blue = 0.00},
		[7] = {Red = 0.90, Green = 0.80, Blue = 0.50}
	}

	local formula = {
		["A"] = {
			[4] = {["A"] = 91.4500, ["B"] = 0.6500},
			[3] = {["A"] = 81.3750, ["B"] = 0.8125},
			[2] = {["A"] = 73.0000, ["B"] = 1.0000}
		},
		["B"] = {
			[4] = {["A"] = 26.0000, ["B"] = 1.2000},
			[3] = {["A"] = 0.7500, ["B"] = 1.8000},
			[2] = {["A"] = 8.0000, ["B"] = 2.0000},
			[1] = {["A"] = 0.0000, ["B"] = 2.2500}
		}
	}

	local itemQuality = {
		[6000] = {
			["Red"] = {["A"] = 0.94, ["B"] = 5000, ["C"] = 0.00006, ["D"] = 1},
			["Green"] = {["A"] = 0.47, ["B"] = 5000, ["C"] = 0.00047, ["D"] = -1},
			["Blue"] = {["A"] = 0, ["B"] = 0, ["C"] = 0, ["D"] = 0},
			["Description"] = "Legendary"
		},
		[5000] = {
			["Red"] = {["A"] = 0.69, ["B"] = 4000, ["C"] = 0.00025, ["D"] = 1},
			["Green"] = {["A"] = 0.28, ["B"] = 4000, ["C"] = 0.00019, ["D"] = 1},
			["Blue"] = {["A"] = 0.97, ["B"] = 4000, ["C"] = 0.00096, ["D"] = -1},
			["Description"] = "Epic"
		},
		[4000] = {
			["Red"] = {["A"] = 0.0, ["B"] = 3000, ["C"] = 0.00069, ["D"] = 1},
			["Green"] = {["A"] = 0.5, ["B"] = 3000, ["C"] = 0.00022, ["D"] = -1},
			["Blue"] = {["A"] = 1, ["B"] = 3000, ["C"] = 0.00003, ["D"] = -1},
			["Description"] = "Superior"
		},
		[3000] = {
			["Red"] = {["A"] = 0.12, ["B"] = 2000, ["C"] = 0.00012, ["D"] = -1},
			["Green"] = {["A"] = 1, ["B"] = 2000, ["C"] = 0.00050, ["D"] = -1},
			["Blue"] = {["A"] = 0, ["B"] = 2000, ["C"] = 0.001, ["D"] = 1},
			["Description"] = "Uncommon"
		},
		[2000] = {
			["Red"] = {["A"] = 1, ["B"] = 1000, ["C"] = 0.00088, ["D"] = -1},
			["Green"] = {["A"] = 1, ["B"] = 000, ["C"] = 0.00000, ["D"] = 0},
			["Blue"] = {["A"] = 1, ["B"] = 1000, ["C"] = 0.001, ["D"] = -1},
			["Description"] = "Common"
		},
		[1000] = {
			["Red"] = {["A"] = 0.55, ["B"] = 0, ["C"] = 0.00045, ["D"] = 1},
			["Green"] = {["A"] = 0.55, ["B"] = 0, ["C"] = 0.00045, ["D"] = 1},
			["Blue"] = {["A"] = 0.55, ["B"] = 0, ["C"] = 0.00045, ["D"] = 1},
			["Description"] = "Trash"
		}
	}

	local commandList = {
		[1] = {"/gs player", "Toggles display of scores on players."},
		[2] = {"/gs item", "Toggles display of scores for items."},
		[3] = {"/gs level", "Toggles iLevel information."},
		[4] = {"/gs reset", "Resets GearScore's Options back to Default."},
		[5] = {"/gs compare", "Toggles display of comparative info between you and your target's GearScore."}
	}

	local function Print(msg)
		if msg then
			core:Print(msg, "GearScore")
		end
	end

	-------------------------- Get Mouseover Score -----------------------------------
	function GearScore_GetScore(Name, Target)
		if (UnitIsPlayer(Target)) then
			local PlayerClass, PlayerEnglishClass = UnitClass(Target)
			local GearScore = 0
			local PVPScore = 0
			local ItemCount = 0
			local LevelTotal = 0
			local TitanGrip = 1
			local TempPVPScore = 0

			if (GetInventoryItemLink(Target, 16)) and (GetInventoryItemLink(Target, 17)) then
				local ItemName, ItemLink, ItemRarity, ItemLevel, ItemMinLevel, ItemType, ItemSubType, ItemStackCount, ItemEquipLoc, ItemTexture = GetItemInfo(GetInventoryItemLink(Target, 16))
				if (ItemEquipLoc == "INVTYPE_2HWEAPON") then
					TitanGrip = 0.5
				end
			end

			if (GetInventoryItemLink(Target, 17)) then
				local ItemName, ItemLink, ItemRarity, ItemLevel, ItemMinLevel, ItemType, ItemSubType, ItemStackCount, ItemEquipLoc, ItemTexture = GetItemInfo(GetInventoryItemLink(Target, 17))
				if (ItemEquipLoc == "INVTYPE_2HWEAPON") then
					TitanGrip = 0.5
				end
				local TempScore, ItmLevel = GearScore_GetItemScore(GetInventoryItemLink(Target, 17))
				if (PlayerEnglishClass == "HUNTER") then
					TempScore = TempScore * 0.3164
				end
				GearScore = GearScore + TempScore * TitanGrip
				ItemCount = ItemCount + 1
				LevelTotal = LevelTotal + ItmLevel
			end

			for i = 1, 18 do
				if (i ~= 4) and (i ~= 17) then
					local link = GetInventoryItemLink(Target, i)
					if (link) then
						local ItemName, ItmLink, ItemRarity, ItemLevel, ItemMinLevel, ItemType, ItemSubType, ItemStackCount, ItemEquipLoc, ItemTexture = GetItemInfo(link)
						local TempScore = GearScore_GetItemScore(ItmLink)
						if (i == 16) and (PlayerEnglishClass == "HUNTER") then
							TempScore = TempScore * 0.3164
						end
						if (i == 18) and (PlayerEnglishClass == "HUNTER") then
							TempScore = TempScore * 5.3224
						end
						if (i == 16) then
							TempScore = TempScore * TitanGrip
						end
						GearScore = GearScore + TempScore
						ItemCount = ItemCount + 1
						LevelTotal = LevelTotal + (ItemLevel or 0)
					end
				end
			end
			if (GearScore <= 0) and (Name ~= UnitName("player")) then
				GearScore = 0
				return 0, 0
			elseif (Name == UnitName("player")) and (GearScore <= 0) then
				GearScore = 0
			end
			if (ItemCount == 0) then
				LevelTotal = 0
			end
			return floor(GearScore), floor(LevelTotal / ItemCount)
		end
	end
	core.GetGearScore = GearScore_GetScore

	-------------------------------------------------------------------------------

	function GearScore_GetEnchantInfo(ItemLink, ItemEquipLoc)
		local found, _, ItemSubString = string.find(ItemLink, "^|c%x+|H(.+)|h%[.*%]")
		local ItemSubStringTable = core.newTable()

		for v in string.gmatch(ItemSubString, "[^:]+") do
			tinsert(ItemSubStringTable, v)
		end
		ItemSubString, _ = ItemSubStringTable[2] .. ":" .. ItemSubStringTable[3], ItemSubStringTable[2]
		core.delTable(ItemSubStringTable)

		local StringStart, StringEnd = string.find(ItemSubString, ":")
		ItemSubString = string.sub(ItemSubString, StringStart + 1)
		if (ItemSubString == "0") and (itemTypes[ItemEquipLoc]["Enchantable"]) then
			local percent = (floor((-2 * (itemTypes[ItemEquipLoc]["SlotMOD"])) * 100) / 100)
			return (1 + (percent / 100))
		else
			return 1
		end
	end

	------------------------------ Get Item Score ---------------------------------
	function GearScore_GetItemScore(itemLink)
		local QualityScale = 1
		local PVPScale = 1
		local PVPScore = 0
		local GearScore = 0
		if not (itemLink) then
			return 0, 0
		end
		local ItemName, ItemLink, ItemRarity, ItemLevel, ItemMinLevel, ItemType, ItemSubType, ItemStackCount, ItemEquipLoc, ItemTexture = GetItemInfo(itemLink)
		local Table = core.WeakTable()
		local Scale = 1.8618
		if (ItemRarity == 5) then
			QualityScale = 1.3
			ItemRarity = 4
		elseif (ItemRarity == 1) then
			QualityScale = 0.005
			ItemRarity = 2
		elseif (ItemRarity == 0) then
			QualityScale = 0.005
			ItemRarity = 2
		end
		if (ItemRarity == 7) then
			ItemRarity = 3
			ItemLevel = 187.05
		end
		if (itemTypes[ItemEquipLoc]) then
			if (ItemLevel > 120) then
				Table = formula["A"]
			else
				Table = formula["B"]
			end
			if (ItemRarity >= 2) and (ItemRarity <= 4) then
				local Red, Green, Blue = GearScore_GetQuality((floor(((ItemLevel - Table[ItemRarity].A) / Table[ItemRarity].B) * 1 * Scale)) * 11.25)
				GearScore = floor(((ItemLevel - Table[ItemRarity].A) / Table[ItemRarity].B) * itemTypes[ItemEquipLoc].SlotMOD * Scale * QualityScale)
				if (ItemLevel == 187.05) then
					ItemLevel = 0
				end
				if (GearScore < 0) then
					GearScore = 0
					Red, Green, Blue = GearScore_GetQuality(1)
				end
				if (PVPScale == 0.75) then
					PVPScore = 1
					GearScore = GearScore * 1
				else
					PVPScore = GearScore * 0
				end
				local percent = (GearScore_GetEnchantInfo(ItemLink, ItemEquipLoc) or 1)
				GearScore = floor(GearScore * percent)
				PVPScore = floor(PVPScore)
				return GearScore, ItemLevel, itemTypes[ItemEquipLoc].ItemSlot, Red, Green, Blue, PVPScore, ItemEquipLoc, percent
			end
		end
		return -1, ItemLevel, 50, 1, 1, 1, PVPScore, ItemEquipLoc, 1
	end
	-------------------------------------------------------------------------------

	-------------------------------- Get Quality ----------------------------------

	function GearScore_GetQuality(ItemScore)
		if (ItemScore > 5999) then
			ItemScore = 5999
		elseif not (ItemScore) then
			return 0, 0, 0, "Trash"
		end

		local Red = 0.1
		local Blue = 0.1
		local Green = 0.1
		local Description

		for i = 0, 6 do
			if (ItemScore > i * 1000) and (ItemScore <= ((i + 1) * 1000)) then
				Red = itemQuality[(i + 1) * 1000].Red["A"] + (((ItemScore - itemQuality[(i + 1) * 1000].Red["B"]) * itemQuality[(i + 1) * 1000].Red["C"]) * itemQuality[(i + 1) * 1000].Red["D"])
				Blue = itemQuality[(i + 1) * 1000].Green["A"] + (((ItemScore - itemQuality[(i + 1) * 1000].Green["B"]) * itemQuality[(i + 1) * 1000].Green["C"]) * itemQuality[(i + 1) * 1000].Green["D"])
				Green = itemQuality[(i + 1) * 1000].Blue["A"] + (((ItemScore - itemQuality[(i + 1) * 1000].Blue["B"]) * itemQuality[(i + 1) * 1000].Blue["C"]) * itemQuality[(i + 1) * 1000].Blue["D"])
				Description = itemQuality[(i + 1) * 1000].Description
				break
			end
		end

		return Red, Green, Blue, Description
	end
	-------------------------------------------------------------------------------

	----------------------------- Hook Set Unit -----------------------------------
	function GearScore_HookSetUnit(arg1, arg2)
		if core.InCombat then
			return
		end
		local Name = GameTooltip:GetUnit()
		local MouseOverGearScore, MouseOverAverage = 0, 0
		if CanInspect("mouseover") and UnitName("mouseover") == Name and not core.InCombat and UnitIsUnit("target", "mouseover") then
			NotifyInspect("mouseover")
			MouseOverGearScore, MouseOverAverage = GearScore_GetScore(Name, "mouseover")
		end
		if MouseOverGearScore and MouseOverGearScore > 0 and DB.Player then
			local Red, Blue, Green = GearScore_GetQuality(MouseOverGearScore)
			if DB.Level then
				GameTooltip:AddDoubleLine("GearScore: " .. MouseOverGearScore, "iLvl: " .. MouseOverAverage .. "", Red, Green, Blue, Red, Green, Blue)
			else
				GameTooltip:AddLine("GearScore: " .. MouseOverGearScore, Red, Green, Blue)
			end
			if DB.Compare then
				local MyGearScore = GearScore_GetScore(UnitName("player"), "player")
				local TheirGearScore = MouseOverGearScore
				if MyGearScore > TheirGearScore then
					GameTooltip:AddDoubleLine("YourScore: " .. MyGearScore, "(+" .. (MyGearScore - TheirGearScore) .. ")", 0, 1, 0, 0, 1, 0)
				elseif MyGearScore < TheirGearScore then
					GameTooltip:AddDoubleLine("YourScore: " .. MyGearScore, "(-" .. (TheirGearScore - MyGearScore) .. ")", 1, 0, 0, 1, 0, 0)
				elseif MyGearScore == TheirGearScore then
					GameTooltip:AddDoubleLine("YourScore: " .. MyGearScore, "(+0)", 0, 1, 1, 0, 1, 1)
				end
			end
		end
	end

	-------------------------------------------------------------------------------
	function GearScore_HookSetItem()
		ItemName, ItemLink = GameTooltip:GetItem()
		GearScore_HookItem(ItemName, ItemLink, GameTooltip)
	end
	function GearScore_HookRefItem()
		ItemName, ItemLink = ItemRefTooltip:GetItem()
		GearScore_HookItem(ItemName, ItemLink, ItemRefTooltip)
	end
	function GearScore_HookCompareItem()
		ItemName, ItemLink = ShoppingTooltip1:GetItem()
		GearScore_HookItem(ItemName, ItemLink, ShoppingTooltip1)
	end
	function GearScore_HookCompareItem2()
		ItemName, ItemLink = ShoppingTooltip2:GetItem()
		GearScore_HookItem(ItemName, ItemLink, ShoppingTooltip2)
	end
	function GearScore_HookItem(ItemName, ItemLink, Tooltip)
		if core.InCombat then
			return
		end
		local PlayerClass, PlayerEnglishClass = UnitClass("player")
		if not (IsEquippableItem(ItemLink)) then
			return
		end
		local ItemScore, ItemLevel, EquipLoc, Red, Green, Blue, PVPScore, ItemEquipLoc, enchantPercent = GearScore_GetItemScore(ItemLink)
		if (ItemScore >= 0) then
			if DB.Item then
				if (ItemLevel) and DB.Level then
					Tooltip:AddDoubleLine("GearScore: " .. ItemScore, "iLvl: " .. ItemLevel, Red, Blue, Green, Red, Blue, Green)
					if (PlayerEnglishClass == "HUNTER") then
						if (ItemEquipLoc == "INVTYPE_RANGEDRIGHT") or (ItemEquipLoc == "INVTYPE_RANGED") then
							Tooltip:AddLine("HunterScore: " .. floor(ItemScore * 5.3224), Red, Blue, Green)
						end
						if
							(ItemEquipLoc == "INVTYPE_2HWEAPON") or (ItemEquipLoc == "INVTYPE_WEAPONMAINHAND") or
								(ItemEquipLoc == "INVTYPE_WEAPONOFFHAND") or
								(ItemEquipLoc == "INVTYPE_WEAPON") or
								(ItemEquipLoc == "INVTYPE_HOLDABLE")
						 then
							Tooltip:AddLine("HunterScore: " .. floor(ItemScore * 0.3164), Red, Blue, Green)
						end
					end
				else
					Tooltip:AddLine("GearScore: " .. ItemScore, Red, Blue, Green)
					if (PlayerEnglishClass == "HUNTER") then
						if (ItemEquipLoc == "INVTYPE_RANGEDRIGHT") or (ItemEquipLoc == "INVTYPE_RANGED") then
							Tooltip:AddLine("HunterScore: " .. floor(ItemScore * 5.3224), Red, Blue, Green)
						end
						if
							(ItemEquipLoc == "INVTYPE_2HWEAPON") or (ItemEquipLoc == "INVTYPE_WEAPONMAINHAND") or
								(ItemEquipLoc == "INVTYPE_WEAPONOFFHAND") or
								(ItemEquipLoc == "INVTYPE_WEAPON") or
								(ItemEquipLoc == "INVTYPE_HOLDABLE")
						 then
							Tooltip:AddLine("HunterScore: " .. floor(ItemScore * 0.3164), Red, Blue, Green)
						end
					end
				end
			end
		else
			if DB.Level and (ItemLevel) then
				Tooltip:AddLine("iLevel " .. ItemLevel)
			end
		end
	end
	function GearScore_OnEnter(Name, ItemSlot, Argument)
		if (UnitName("target")) then
			NotifyInspect("target")
			DB.LastNotified = UnitName("target")
		end
		local OriginalOnEnter = GearScore_Original_SetInventoryItem(Name, ItemSlot, Argument)
		return OriginalOnEnter
	end
	function MyPaperDoll()
		if core.InCombat then return end
		local MyGearScore = GearScore_GetScore(UnitName("player"), "player")
		local Red, Blue, Green = GearScore_GetQuality(MyGearScore)
		PersonalGearScore:SetText(MyGearScore)
		PersonalGearScore:SetTextColor(Red, Green, Blue, 1)
	end

	----------------------------- Reports -----------------------------------------

	---------------GS-SPAM Slasch Command--------------------------------------

	function GS_MANSET(cmd)
		cmd = cmd:trim():lower()
		if cmd == "" or cmd == "options" or cmd == "option" or cmd == "help" then
			Print(L:F("Acceptable commands for: |caaf49141%s|r", "/gs"))
			for _, tbl in ipairs(commandList) do
				print(unpack(tbl))
			end
		elseif cmd == "show" or cmd == "player" then
			DB.Player = not DB.Player
			if DB.Player then
				Print(L:F("Player Scores: %s", L["|cff00ff00ON|r"]))
			else
				Print(L:F("Player Scores: %s", L["|cffff0000OFF|r"]))
			end
		elseif cmd == "item" then
			DB.Item = not DB.Item
			if DB.Item then
				Print(L:F("Item Scores: %s", L["|cff00ff00ON|r"]))
			else
				Print(L:F("Item Scores: %s", L["|cffff0000OFF|r"]))
			end
		elseif cmd == "level" then
			DB.Level = not DB.Level
			if DB.Level then
				Print(L:F("Item Levels: %s", L["|cff00ff00ON|r"]))
			else
				Print(L:F("Item Levels: %s", L["|cffff0000OFF|r"]))
				if core.ItemLevel and core.ItemLevel.HookTooltip then
					core.ItemLevel:HookTooltip()
				end
			end
			return
		elseif cmd == "compare" then
			DB.Compare = not DB.Compare
			if DB.Compare then
				Print(L:F("Comparisons: %s", L["|cff00ff00ON|r"]))
			else
				Print(L:F("Comparisons: %s", L["|cffff0000OFF|r"]))
			end
		else
			Print(L:F('Unknown Command. Type "|caaf49141%s|r" for a list of commands.', "/gs"))
		end
	end

	------------------------ GUI PROGRAMS -------------------------------------------------------

	local function SetupDatabase()
		if not DB then
			if type(core.db.GearScore) ~= "table" or not next(core.db.GearScore) then
				core.db.GearScore = CopyTable(defaults)
			end
			DB = core.db.GearScore
			core.GearScore = DB
		end
	end

	local options = {
		type = "group",
		name = "GearScoreLite",
		get = function(i)
			return DB[i[#i]]
		end,
		set = function(i, val)
			DB[i[#i]] = val
		end,
		args = {
			Player = {
				type = "toggle",
				name = PLAYER,
				desc = L["Toggles display of scores on players."],
				order = 1
			},
			Item = {
				type = "toggle",
				name = ITEMS,
				desc = L["Toggles display of scores for items."],
				order = 2
			},
			Compare = {
				type = "toggle",
				name = L["Compare"],
				desc = L["Toggles display of comparative info between you and your target's GearScore."],
				order = 4
			},
			Level = {
				type = "toggle",
				name = L["Item Level"],
				desc = L["Toggles iLevel information."],
				order = 5
			}
		}
	}

	core:RegisterForEvent("PLAYER_LOGIN", function()
		SetupDatabase()
		core.options.args.Options.args.GearScore = options

		GameTooltip:HookScript("OnTooltipSetUnit", GearScore_HookSetUnit)
		GameTooltip:HookScript("OnTooltipSetItem", GearScore_HookSetItem)
		ShoppingTooltip1:HookScript("OnTooltipSetItem", GearScore_HookCompareItem)
		ShoppingTooltip2:HookScript("OnTooltipSetItem", GearScore_HookCompareItem2)
		ItemRefTooltip:HookScript("OnTooltipSetItem", GearScore_HookRefItem)
		CharacterModelFrame:HookScript("OnShow", MyPaperDoll)

		PersonalGearScore = CharacterModelFrame:CreateFontString("PersonalGearScore")
		PersonalGearScore:SetFont("Fonts\\FRIZQT__.TTF", 10)
		PersonalGearScore:SetText("GS: 0")
		PersonalGearScore:SetPoint("BOTTOMLEFT", CharacterModelFrame, "BOTTOMLEFT", 6, 35)
		PersonalGearScore:Show()

		local gs2 = CharacterModelFrame:CreateFontString("GearScore2")
		gs2:SetFont("Fonts\\FRIZQT__.TTF", 10)
		gs2:SetText("GearScore")
		gs2:SetPoint("BOTTOMLEFT", CharacterModelFrame, "BOTTOMLEFT", 6, 25)
		gs2:Show()
		GearScore_Original_SetInventoryItem = GameTooltip.SetInventoryItem
		GameTooltip.SetInventoryItem = GearScore_OnEnter
	end)

	core:RegisterForEvent("PLAYER_EQUIPMENT_CHANGED", function()
		SetupDatabase()
		local MyGearScore = GearScore_GetScore(UnitName("player"), "player")
		local Red, Blue, Green = GearScore_GetQuality(MyGearScore)
		PersonalGearScore:SetText(MyGearScore)
		PersonalGearScore:SetTextColor(Red, Green, Blue, 1)
	end)

	SlashCmdList["KPACKGEARSCORE"] = GS_MANSET
	SLASH_KPACKGEARSCORE1 = "/gset"
	SLASH_KPACKGEARSCORE2 = "/gs"
	SLASH_KPACKGEARSCORE3 = "/gearscore"
end)