local core = KPack
if not core then return end
core:AddModule("Borders Colors", "This module adds colorized border items.", function(L)
	if core:IsDisabled("Borders Colors") or core.ElvUI then return end

	local mod = CreateFrame("Frame")
	mod:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
	mod:RegisterEvent("ADDON_LOADED")

	local ipairs, type = ipairs, type
	local hooksecurefunc = hooksecurefunc
	local GetBuybackItemLink = GetBuybackItemLink
	local GetContainerItemID = GetContainerItemID
	local GetInventoryItemID = GetInventoryItemID
	local GetContainerNumSlots = GetContainerNumSlots
	local GetInventorySlotInfo = GetInventorySlotInfo
	local GetItemInfo = GetItemInfo
	local GetTradeSkillItemLink = GetTradeSkillItemLink
	local GetTradeSkillReagentItemLink = GetTradeSkillReagentItemLink
	local IsBagOpen = IsBagOpen

	-- Add quest color:
	ITEM_QUALITY_COLORS[7] = {r = 1, g = 1, b = 0, hex = "ffff00"}

	-- character slots
	local slotWidth, slotHeight = 68, 68
	local slotsTable = {
		"Head", "Neck", "Shoulder", "Back", "Chest", "Shirt", "Tabard", "Wrist", "Hands", "Waist", "Legs",
		"Feet", "Finger0", "Finger1", "Trinket0", "Trinket1", "MainHand", "SecondaryHand", "Ranged", "Ammo"
	}

	local defaults = {
		bags = true,
		bank = true,
		char = true,
		inspect = true,
		merchant = true,
		tradeskill = true,
		intensity = 0.5
	}

	local options, DB
	local function GetOptions()
		if not options then
			options = {
				type = "group",
				name = L["Borders Colors"],
				get = function(i)
					return DB[i[#i]]
				end,
				set = function(i, val)
					DB[i[#i]] = val
				end,
				args = {
					bags = {
						type = "toggle",
						name = INVENTORY_TOOLTIP,
						order = 10
					},
					bank = {
						type = "toggle",
						name = L["Bank"],
						order = 20
					},
					char = {
						type = "toggle",
						name = STATUS_TEXT_PLAYER,
						order = 30
					},
					inspect = {
						type = "toggle",
						name = INSPECT,
						order = 40
					},
					merchant = {
						type = "toggle",
						name = MERCHANT,
						order = 50
					},
					tradeskill = {
						type = "toggle",
						name = TRADE_SKILLS,
						order = 60
					},
					intensity = {
						type = "range",
						name = L["Intensity"],
						min = 0,
						max = 1,
						step = 0.01,
						isPercent = true,
						width = "double",
						order = 70
					}
				}
			}
		end
		return options
	end

	local function SetupDatabase()
		if not DB then
			if type(core.db.BordersColors) ~= "table" then
				core.db.BordersColors = CopyTable(defaults)
			end
			DB = core.db.BordersColors
		end
	end

	local function GetItemQuality(itemId)
		if itemId then
			local quality, _, _, itemType = select(3, GetItemInfo(itemId))
			return itemType == L.Quest and 7 or quality
		end
	end

	local function FindLastBuybackItem()
		for i = 1, 12 do
			local link = GetBuybackItemLink(i)
			if link then
				return link
			end
		end
	end

	local function MOD_CreateBorder(name, parent, width, height, xOfs, yOfs)
		xOfs, yOfs = xOfs or 0, yOfs or 1

		local border = parent:CreateTexture(name .. "Quality", "OVERLAY")
		border:SetTexture([[Interface\Buttons\UI-ActionButton-Border]])
		border:SetBlendMode("ADD")
		border:SetAlpha(DB.intensity or 0.5)
		border:SetHeight(height)
		border:SetWidth(width)
		border:SetPoint("CENTER", parent, "CENTER", xOfs, yOfs)
		border:Hide()
		return border
	end

	local function MOD_CharFrame_UpdateBorders(unit, frame)
		if DB and ((unit == "target" and DB.inspect) or (unit == "player" and DB.char)) then
			for _, charSlot in ipairs(slotsTable) do
				local id, _ = GetInventorySlotInfo(charSlot .. "Slot")
				local quality = GetItemQuality(GetInventoryItemID(unit, id))

				local slotName = frame .. charSlot .. "Slot"

				if _G[slotName] then
					local slot = _G[slotName]

					-- create border if not done yet
					if not slot.qborder then
						local height = slotHeight
						local width = slotWidth

						if charSlot == "Ammo" then
							height = 58
							width = 58
						end

						slot.qborder = MOD_CreateBorder(slotName, _G[slotName], width, height)
					end

					-- update border color
					if quality and ITEM_QUALITY_COLORS[quality] then
						local color = ITEM_QUALITY_COLORS[quality]
						slot.qborder:SetVertexColor(color.r, color.g, color.b)
						slot.qborder:SetAlpha(DB.intensity or 0.5)
						slot.qborder:Show()
					else
						slot.qborder:Hide()
					end
				end
			end
		end
	end

	function mod:ToggleCharacter()
		if CharacterFrame:IsShown() then
			mod:RegisterEvent("UNIT_INVENTORY_CHANGED")
			MOD_CharFrame_UpdateBorders("player", "Character")
		else
			mod:UnregisterEvent("UNIT_INVENTORY_CHANGED")
		end
	end

	local function MOD_UpdateContainerSlot(bagId, slotId, slotName)
		local item = _G[slotName]
		if not item.qborder then
			item.qborder = MOD_CreateBorder(slotName, item, slotHeight, slotHeight)
		end

		local itemId = GetContainerItemID(bagId, slotId)

		if itemId then
			local quality = GetItemQuality(itemId)
			if quality and quality > 1 then
				local color = ITEM_QUALITY_COLORS[quality]
				item.qborder:SetVertexColor(color.r, color.g, color.b)
				item.qborder:SetAlpha(DB.intensity or 0.5)
				item.qborder:Show()
			else
				item.qborder:Hide()
			end
		else
			item.qborder:Hide()
		end
	end

	local function MOD_ToggleBag(id)
		if not (DB and DB.bags) then return end
		local frameId = IsBagOpen(id)
		if frameId then
			local slots = GetContainerNumSlots(id)
			for i = 1, slots do
				local slotName = "ContainerFrame" .. frameId .. "Item" .. (slots + 1 - i)
				MOD_UpdateContainerSlot(id, i, slotName)
			end
		end
	end

	local function MOD_UpdateSlotBorderColor(item, itemId, minquality)
		minquality = minquality or 0
		local quality = GetItemQuality(itemId)

		if (quality and quality > minquality) then
			local color = ITEM_QUALITY_COLORS[quality]
			item.qborder:SetVertexColor(color.r, color.g, color.b)
			item.qborder:SetAlpha(DB.intensity or 0.5)
			item.qborder:Show()
		else
			item.qborder:Hide()
		end
	end

	local function MOD_MerchantItems_Update(itemLinkFunc)
		for i = 1, 12 do
			local slotName = "MerchantItem" .. i .. "ItemButton"
			local itemFrame = _G[slotName]

			if (not itemFrame.qborder) then
				itemFrame.qborder = MOD_CreateBorder(slotName, itemFrame, slotWidth, slotHeight)
			end

			local link = itemLinkFunc(i)

			if (link) then
				MOD_UpdateSlotBorderColor(itemFrame, link, 1)
			else
				itemFrame.qborder:Hide()
			end
		end
	end

	local function MOD_MerchantMainBuyBack_Update()
		local buybackSlotName = "MerchantBuyBackItemItemButton"
		local item = _G[buybackSlotName]

		if (not item.qborder) then
			item.qborder = MOD_CreateBorder(buybackSlotName, item, slotWidth, slotHeight)
		end

		local lastLink = FindLastBuybackItem()

		if (lastLink) then
			MOD_UpdateSlotBorderColor(item, lastLink, 1)
		else
			item.qborder:Hide()
		end
	end

	function mod:MerchantFrame_UpdateMerchantInfo()
		if not (DB and DB.merchant) then return end
		MOD_MerchantItems_Update(GetMerchantItemLink)
		MOD_MerchantMainBuyBack_Update()
	end

	function mod:MerchantFrame_UpdateBuybackInfo()
		if not (DB and DB.merchant) then return end
		MOD_MerchantItems_Update(GetMerchantItemLink)
	end

	local function MOD_UpdateTradeSkillItem(id)
		local slotName = "TradeSkillSkillIcon"
		local item = _G[slotName]

		if (not item.qborder) then
			item.qborder = MOD_CreateBorder(slotName, item, slotWidth, slotHeight)
		end

		local link = GetTradeSkillItemLink(id)

		if (link) then
			MOD_UpdateSlotBorderColor(item, link, LE_ITEM_QUALITY_COMMON)
		else
			item.qborder:Hide()
		end
	end

	local function MOD_UpdateTradeSkillReageant(id)
		local nb = GetTradeSkillNumReagents(id)
		for index = 1, nb do
			local slotName = "TradeSkillReagent" .. index
			local item = _G[slotName]

			if (not item.qborder) then
				item.qborder = MOD_CreateBorder(slotName, item, slotWidth, slotHeight, -54)
			end

			local link = GetTradeSkillReagentItemLink(id, index)

			if (link) then
				MOD_UpdateSlotBorderColor(item, link, LE_ITEM_QUALITY_COMMON)
			else
				item.qborder:Hide()
			end
		end
	end

	function mod:TradeSkillFrame_SetSelection(id)
		if not (DB and DB.tradeskill) then return end
		MOD_UpdateTradeSkillItem(id)
		MOD_UpdateTradeSkillReageant(id)
	end

	function mod:Initialize()
		SetupDatabase()
		if not core.options.args.Options.args.BordersColors then
			core.options.args.Options.args.BordersColors = GetOptions()
		end

		hooksecurefunc("ToggleCharacter", mod.ToggleCharacter)
		hooksecurefunc("ToggleBag", function(id) MOD_ToggleBag(id) end)
		hooksecurefunc("MerchantFrame_UpdateMerchantInfo", mod.MerchantFrame_UpdateMerchantInfo)
		hooksecurefunc("MerchantFrame_UpdateBuybackInfo", mod.MerchantFrame_UpdateBuybackInfo)
		mod:RegisterEvent("BAG_UPDATE")
		mod:RegisterEvent("BANKFRAME_OPENED")
		mod:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
	end

	function mod:ADDON_LOADED(name)
		if name == "Blizzard_TradeSkillUI" then
			hooksecurefunc("TradeSkillFrame_SetSelection", function(id)
				mod:TradeSkillFrame_SetSelection(id, DB.tradeskill)
			end)
		elseif name == "Blizzard_InspectUI" then
			InspectFrame:HookScript("OnShow", function()
				MOD_CharFrame_UpdateBorders("target", "Inspect")
			end)
		end
	end

	function mod:UNIT_INVENTORY_CHANGED()
		MOD_CharFrame_UpdateBorders("player", "Character")
	end

	function mod:BAG_UPDATE(id)
		MOD_ToggleBag(id)
	end

	function mod:BANKFRAME_OPENED()
		if DB and DB.bank then
			local container = BANK_CONTAINER
			for i = 1, GetContainerNumSlots(container) do
				MOD_UpdateContainerSlot(container, i, "BankFrameItem" .. i)
			end
		end
	end

	function mod:PLAYERBANKSLOTS_CHANGED()
		mod:BANKFRAME_OPENED()
	end

	core:RegisterForEvent("PLAYER_LOGIN", mod.Initialize)
end)