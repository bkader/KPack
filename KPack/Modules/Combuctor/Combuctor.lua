local core = KPack
if not core then return end
core:AddModule("Combuctor", "Bag replacement addon.", function(L)
	if core:IsDisabled("Combuctor") or _G.Combuctor then return end

	local modname = "Combuctor"
	local mod = core.Combuctor or {}
	core.Combuctor = mod

	local _G = _G
	local BagnonDB = _G.BagnonDB
	local BagSync = _G.BagSync
	local BagSyncDB = _G.BagSyncDB

	local DB, SetupDatabase, _
	local defaults = {
		inventory = {
			bags = {0, 1, 2, 3, 4},
			position = {"BOTTOMRIGHT", nil, "BOTTOMRIGHT", -64, 64},
			showBags = false,
			leftSideFilter = true,
			w = 384,
			h = 512
		},
		bank = {
			bags = {-1, 5, 6, 7, 8, 9, 10, 11},
			showBags = false,
			w = 512,
			h = 512
		}
	}

	-- add some line to localization
	L.Weapon, L.Armor, L.Container, L.Consumable, L.Glyph, L.TradeGood, _, _, L.Recipe, L.Gem, L.Misc, L.Quest = GetAuctionItemClasses()
	L.Devices, L.Explosives = select(10, GetAuctionItemSubClasses(6))
	L.SimpleGem = select(8, GetAuctionItemSubClasses(7))
	local currentRealm = GetRealmName()

	local AutoShowInventory, AutoHideInventory

	local function Print(msg)
		if msg then
			core:Print(msg, "Combuctor")
		end
	end

	local function SlashCommandHandler(msg)
		msg = msg and msg:lower()
		if msg == "bank" then
			mod:Toggle(BANK_CONTAINER)
		elseif msg == "bags" or msg == "inventory" then
			mod:Toggle(BACKPACK_CONTAINER)
		elseif msg == "" or msg == "options" or msg == "config" then
			InterfaceOptionsFrame_OpenToCategory(modname)
		else
			Print(L:F("Acceptable commands for: |caaf49141%s|r", "/cbt"))
			print(L:F("%s: toggle inventory", "|cffFF0000/cbt bags|r"))
			print(L:F("%s: toggle bank", "|cffFF0000/cbt bank|r"))
			print(L:F("%s: access options panel", "|cffFF0000/cbt config|r"))
		end
	end
	SLASH_KPACKCOMBUCTOR1 = "/cbt"
	SLASH_KPACKCOMBUCTOR2 = "/combuctor"
	SlashCmdList.KPACKCOMBUCTOR = SlashCommandHandler

	function mod:GetProfile()
		return DB
	end

	function mod:SetMaxItemScale(scale)
		DB.maxScale = scale or 1
	end

	function mod:GetMaxItemScale()
		return DB.maxScale or 1
	end

	---------------------------------------------------------------------------
	-- Bag Toggle:

	function mod:Show(bag, auto)
		for _, frame in pairs(self.frames) do
			for _, bagID in pairs(frame.sets.bags) do
				if bagID == bag then
					frame:ShowFrame(auto)
					return
				end
			end
		end
	end

	function mod:Hide(bag, auto)
		for _, frame in pairs(self.frames) do
			for _, bagID in pairs(frame.sets.bags) do
				if bagID == bag then
					frame:HideFrame(auto)
					return
				end
			end
		end
	end

	function mod:Toggle(bag, auto)
		for _, frame in pairs(self.frames) do
			for _, bagID in pairs(frame.sets.bags) do
				if bagID == bag then
					frame:ToggleFrame(auto)
					return
				end
			end
		end
	end

	---------------------------------------------------------------------------
	-- Events:

	do
		local function addSet(sets, exclude, name, ...)
			if sets then
				tinsert(sets, name)
			else
				sets = {name}
			end

			if select("#", ...) > 0 then
				if exclude then
					tinsert(exclude, {[name] = {...}})
				else
					exclude = {[name] = {...}}
				end
			end

			return sets, exclude
		end

		local function DefaultInventorySets(class)
			return addSet(nil, nil, ALL, ALL, L.Keys)
		end

		local function DefaultBankSets(class)
			local sets, exclude = addSet(nil, nil, ALL, ALL, L.Keys)
			sets, exclude = addSet(sets, exclude, L.Equipment)
			sets, exclude = addSet(sets, exclude, L.TradeGood)
			sets, exclude = addSet(sets, exclude, L.Misc)

			return sets, exclude
		end

		function SetupDatabase()
			if not DB then
				if type(core.char.Combuctor) ~= "table" or not next(core.char.Combuctor) then
					core.char.Combuctor = CopyTable(defaults)
				end
				DB = core.char.Combuctor

				if not DB.inventory.sets or not DB.inventory.exclude then
					DB.inventory.sets, DB.inventory.exclude = DefaultInventorySets(core.class)
				end
				if not DB.bank.sets or not DB.bank.exclude then
					DB.bank.sets, DB.bank.exclude = DefaultBankSets(core.class)
				end
			end
		end

		core:RegisterForEvent("VARIABLES_LOADED", SetupDatabase)
	end

	core:RegisterForEvent("PLAYER_ENTERING_WORLD", function()
		SetupDatabase()
		mod.frames = {
			mod.Frame:New(L.InventoryTitle, DB.inventory, false, "inventory"),
			mod.Frame:New(L.BankTitle, DB.bank, true, "bank")
		}

		AutoShowInventory = function()
			mod:Show(BACKPACK_CONTAINER, true)
		end
		AutoHideInventory = function()
			mod:Hide(BACKPACK_CONTAINER, true)
		end

		_G.OpenBackpack = AutoShowInventory
		hooksecurefunc("CloseBackpack", AutoHideInventory)

		_G.ToggleBank = function(bag)
			mod:Toggle(bag)
		end
		_G.ToggleBackpack = function()
			mod:Toggle(BACKPACK_CONTAINER)
		end
		_G.OpenAllBags = function()
			mod:Show(BACKPACK_CONTAINER)
		end
		if _G.ToggleAllBags then
			_G.ToggleAllBags = function()
				mod:Toggle(BACKPACK_CONTAINER)
			end
		end

		hooksecurefunc("CloseAllBags", function() mod:Hide(BACKPACK_CONTAINER) end)
		BankFrame:UnregisterAllEvents()

		mod("InventoryEvents"):Register(mod, "BANK_OPENED", function()
			mod:Show(BANK_CONTAINER, true)
			mod:Show(BACKPACK_CONTAINER, true)
		end)
		mod("InventoryEvents"):Register(mod, "BANK_CLOSED",
		function()
			mod:Hide(BANK_CONTAINER, true)
			mod:Hide(BACKPACK_CONTAINER, true)
		end)

		core:RegisterForEvent("MAIL_CLOSED", AutoHideInventory)
		core:RegisterForEvent("TRADE_CLOSED", AutoHideInventory)
		core:RegisterForEvent("TRADE_SKILL_CLOSE", AutoHideInventory)
		core:RegisterForEvent("AUCTION_HOUSE_CLOSED", AutoHideInventory)
		core:RegisterForEvent("AUCTION_HOUSE_CLOSED", AutoHideInventory)

		core:RegisterForEvent("TRADE_SHOW", AutoShowInventory)
		core:RegisterForEvent("TRADE_SKILL_SHOW", AutoShowInventory)
		core:RegisterForEvent("AUCTION_HOUSE_SHOW", AutoShowInventory)
		core:RegisterForEvent("AUCTION_HOUSE_SHOW", AutoShowInventory)
	end)

	---------------------------------------------------------------------------
	-- DB:

	do
		local tinsert, tremove, tsort = table.insert, table.remove, table.sort
		local pairs, ipairs = pairs, ipairs
		local select, tonumber, strsplit = select, tonumber, strsplit
		local GetItemInfo, GetItemIcon = GetItemInfo, GetItemIcon

		local function SetupBagnonDB()
			if not BagnonDB and BagSync then
				BagnonDB = {}
			else
				return
			end

			do
				local CURRENT_REALM = GetRealmName()

				local function getBagTag(bagId)
					if bagId == KEYRING_CONTAINER then
						return "key"
					end
					if bagId == BANK_CONTAINER then
						return "bank"
					end
					if (bagId >= NUM_BAG_SLOTS + 1) and (bagId <= NUM_BAG_SLOTS + NUM_BANKBAGSLOTS) then
						return "bank"
					end
					if (bagId >= BACKPACK_CONTAINER) and (bagId <= BACKPACK_CONTAINER + NUM_BAG_SLOTS) then
						return "bag"
					end
				end

				local function getItemIndex(bagId, slotId)
					return getBagTag(bagId) .. ":" .. bagId .. ":" .. slotId
				end

				local function getBagIndex(bagId)
					return "bd:" .. getBagTag(bagId) .. ":" .. bagId
				end

				local function playerData(player)
					return BagSyncDB[CURRENT_REALM][player]
				end

				local function bagData(player, bagId)
					local pd = playerData(player)
					return pd and pd[getBagIndex(bagId)]
				end

				local function itemData(player, bagId, slotId)
					local pd = playerData(player)
					return pd and pd[getItemIndex(bagId, slotId)]
				end

				do
					local playerList
					function BagnonDB:GetPlayerList()
						if not playerList then
							playerList = {}

							for player in self:GetPlayers() do
								tinsert(playerList, player)
							end

							tsort(playerList, function(a, b)
								if a == core.name then
									return true
								elseif b == core.name then
									return false
								end
								return a < b
							end)
						end
						return playerList
					end

					function BagnonDB:RemovePlayer(player, realm)
						local rdb = BagSyncDB[realm or CURRENT_REALM]
						if rdb then
							rdb[player] = nil
						end

						if realm == currentRealm and playerList then
							for i, character in pairs(playerList) do
								if character == player then
									tremove(playerList, i)
									break
								end
							end
						end
					end
				end

				function BagnonDB:GetPlayers()
					return pairs(BagSyncDB[CURRENT_REALM])
				end

				function BagnonDB:GetMoney(player)
					local pd = playerData(player)
					local c = pd and pd["gold:0:0"]
					return c or 0
				end

				function BagnonDB:GetNumBankSlots(player)
					return NUM_BANKBAGSLOTS
				end

				function BagnonDB:GetBagData(bagId, player)
					local info = bagData(player, bagId)
					if info then
						local size, link, count = strsplit(",", info)
						local hyperLink = (link and select(2, GetItemInfo(link))) or nil
						return tonumber(size), hyperLink, tonumber(count) or 1, GetItemIcon(link)
					end
				end

				function BagnonDB:GetItemData(bagId, slotId, player)
					local info = itemData(player, bagId, slotId)
					if info then
						local link, count = strsplit(",", info)
						if link then
							local hyperLink, quality = select(2, GetItemInfo(link))
							return hyperLink, tonumber(count) or 1, GetItemIcon(link), tonumber(quality)
						end
					end
				end
			end

			if BagnonDB then
				local currentFrame
				local dropdown
				local info = {}

				local function AddCheckItem(text, value, func, checked, hasArrow, level, arg1, arg2)
					info.text = text
					info.func = func
					info.value = value
					info.hasArrow = (hasArrow and true) or nil
					info.notCheckable = false
					info.checked = checked
					info.arg1 = arg1
					info.arg2 = arg2
					UIDropDownMenu_AddButton(info, level)
				end

				--adds an uncheckable item to a dropdown menu
				local function AddItem(text, value, func, level, arg1, arg2)
					info.text = text
					info.func = func
					info.value = value
					info.hasArrow = false
					info.notCheckable = true
					info.checked = false
					info.arg1 = arg1
					info.arg2 = arg2
					UIDropDownMenu_AddButton(info, level)
				end

				local function CharSelect_OnClick(self, player, delete)
					local newPlayer
					if delete then
						BagnonDB:RemovePlayer(player)
						newPlayer = core.name
					else
						newPlayer = player
					end

					currentFrame:SetPlayer(newPlayer)
					for i = 1, UIDROPDOWNMENU_MENU_LEVEL - 1 do
						_G["DropDownList" .. i]:Hide()
					end
				end

				local function CharSelect_Initialize(self, level)
					local playerList = BagnonDB:GetPlayerList()
					level = level or 1

					if level == 1 then
						local selected = currentFrame:GetPlayer()
						local current = core.name

						for i, player in ipairs(playerList) do
							AddCheckItem(player, i, CharSelect_OnClick, player == selected, player ~= current, level, player)
						end
					elseif level == 2 then
						AddItem(REMOVE, nil, CharSelect_OnClick, level, playerList[UIDROPDOWNMENU_MENU_VALUE], true)
					end
				end

				local function CharSelect_Create()
					dropdown = CreateFrame("Frame", "BagnonDBCharSelect", UIParent, "UIDropDownMenuTemplate")
					dropdown:SetID(1)
					UIDropDownMenu_Initialize(dropdown, CharSelect_Initialize, "MENU")

					return dropdown
				end

				function BagnonDB:SetDropdownFrame(frame)
					currentFrame = frame
				end

				function BagnonDB:ToggleDropdown(anchor, offX, offY)
					ToggleDropDownMenu(1, nil, dropdown or CharSelect_Create(), anchor, offX, offY)
				end
			end
		end
		SetupBagnonDB()
	end

	---------------------------------------------------------------------------
	-- Core:

	do
		local modules = {}

		mod.GetModule = function(self, name, silent)
			local module = modules[name]
			if not (module or silent) then
				error(L:F("Could not find module \"%s\"", name), 2)
			end

			return module
		end

		mod.NewModule = function(self, name, obj)
			if modules[name] then
				error(L:F("Module \"%s\" already exists", name), 2)
			end

			local module = obj or {}
			modules[name] = module
			return module
		end

		mod.IterateModules = function()
			return pairs(modules)
		end

		setmetatable(mod, {__call = mod.GetModule})
	end

	-----------------------------------------

	do
		local Envoy = mod:NewModule("Envoy")

		local assert = function(condition, msg)
			if not condition then
				return error(msg, 3)
			end
		end

		local Envoy_MT = {__index = Envoy}

		function Envoy:New(obj)
			local o = setmetatable(obj or {}, Envoy_MT)
			o.listeners = {}
			return o
		end

		function Envoy:Send(msg, ...)
			assert(msg, "Usage: Envoy:Send(msg[, args])")
			assert(type(msg) == "string", "String expected for <msg>, got: '" .. type(msg) .. "'")

			local listeners = self.listeners[msg]
			if listeners then
				for obj, action in pairs(listeners) do
					action(obj, msg, ...)
				end
			end
		end

		function Envoy:Register(obj, msg, method)
			assert(obj and msg, "Usage: Envoy:Register(obj, msg[, method])")
			assert(type(msg) == "string", "String expected for <msg>, got: '" .. type(msg) .. "'")

			method = method or msg
			local action

			if type(method) == "string" then
				assert(obj[method] and type(obj[method]) == "function", "Object does not have an instance of " .. method)
				action = obj[method]
			else
				assert(type(method) == "function", "String or function expected for <method>, got: '" .. type(method) .. "'")
				action = method
			end

			local listeners = self.listeners[msg] or {}
			listeners[obj] = action
			self.listeners[msg] = listeners
		end

		function Envoy:RegisterMany(obj, ...)
			assert(obj and select("#", ...) > 0, "Usage: Envoy:RegisterMany(obj, msg, [...])")
			for i = 1, select("#", ...) do
				self:Register(obj, (select(i, ...)))
			end
		end

		--tells obj to do nothing when msg happens
		function Envoy:Unregister(obj, msg)
			assert(obj and msg, "Usage: Envoy:Unregister(obj, msg)")
			assert(type(msg) == "string", "String expected for <msg>, got: '" .. type(msg) .. "'")

			local listeners = self.listeners[msg]
			if listeners then
				listeners[obj] = nil
				if not next(listeners) then
					self.listeners[msg] = nil
				end
			end
		end

		function Envoy:UnregisterAll(obj)
			assert(obj, "Usage: Envoy:UnregisterAll(obj)")
			for msg in pairs(self.listeners) do
				self:Ignore(obj, msg)
			end
		end
	end

	-----------------------------------------

	do
		local InventoryEvents = mod:NewModule("InventoryEvents", mod("Envoy"):New())
		local AtBank = false

		local GetContainerItemInfo = GetContainerItemInfo
		local GetContainerItemCooldown = GetContainerItemCooldown
		local GetKeyRingSize = GetKeyRingSize
		local GetContainerNumSlots = GetContainerNumSlots
		local GetContainerNumFreeSlots = GetContainerNumFreeSlots
		local GetNumBankSlots = GetNumBankSlots

		function InventoryEvents:AtBank()
			return AtBank
		end
		local function sendMessage(msg, ...)
			InventoryEvents:Send(msg, ...)
		end

		local Slots
		do
			local function getIndex(bagId, slotId)
				return (bagId < 0 and bagId * 100 - slotId) or bagId * 100 + slotId
			end

			Slots = {
				Set = function(self, bagId, slotId, itemLink, count, isLocked, onCooldown)
					local index = getIndex(bagId, slotId)
					local item = self[index] or {}
					item[1] = itemLink
					item[2] = count
					item[4] = onCooldown
					self[index] = item
				end,
				Remove = function(self, bagId, slotId)
					local index = getIndex(bagId, slotId)
					local item = self[index]
					if item then
						self[index] = nil
						return true
					end
				end,
				Get = function(self, bagId, slotId)
					return self[getIndex(bagId, slotId)]
				end
			}

			setmetatable(Slots, {__call = Slots.Get})
		end

		local BagTypes = {}
		local BagSizes = {}

		local function addItem(bagId, slotId)
			local texture, count, locked, quality, readable, lootable, itemLink =
				GetContainerItemInfo(bagId, slotId)
			local start, duration, enable = GetContainerItemCooldown(bagId, slotId)
			local onCooldown = (start > 0 and duration > 0 and enable > 0)

			Slots:Set(bagId, slotId, itemLink, count, locked, onCooldown)
			sendMessage("ITEM_SLOT_ADD", bagId, slotId, itemLink, count, onCooldown)
		end

		local function removeItem(bagId, slotId)
			if Slots:Remove(bagId, slotId) then
				sendMessage("ITEM_SLOT_REMOVE", bagId, slotId)
			end
		end

		local function updateItem(bagId, slotId)
			local item = Slots(bagId, slotId)
			if item then
				local prevLink = item[1]
				local prevCount = item[2]

				local texture, count, locked, quality, readable, lootable, itemLink =
					GetContainerItemInfo(bagId, slotId)
				if not (prevLink == itemLink and prevCount == count) then
					item[1] = itemLink
					item[2] = count

					sendMessage("ITEM_SLOT_UPDATE", bagId, slotId, itemLink, count)
				end
			end
		end

		local function updateItemCooldown(bagId, slotId)
			local item = Slots(bagId, slotId)

			if item and item[1] then
				local start, duration, enable = GetContainerItemCooldown(bagId, slotId)
				local onCooldown = (start > 0 and duration > 0 and enable > 0)

				if item[4] ~= onCooldown then
					item[4] = onCooldown
					sendMessage("ITEM_SLOT_UPDATE_COOLDOWN", bagId, slotId, onCooldown)
				end
			end
		end

		local function getBagSize(bagId)
			if bagId == KEYRING_CONTAINER then
				return GetKeyRingSize()
			end
			if bagId == BANK_CONTAINER then
				return NUM_BANKGENERIC_SLOTS
			end
			return GetContainerNumSlots(bagId)
		end

		local function updateBagSize(bagId)
			local prevSize = BagSizes[bagId] or 0
			local newSize = getBagSize(bagId)
			BagSizes[bagId] = newSize

			if prevSize > newSize then
				for slotId = newSize + 1, prevSize do
					removeItem(bagId, slotId)
				end
			elseif prevSize < newSize then
				for slotId = prevSize + 1, newSize do
					addItem(bagId, slotId)
				end
			end
		end

		local function updateBagType(bagId)
			local _, newType = GetContainerNumFreeSlots(bagId)
			local prevType = BagTypes[bagId]

			if newType ~= prevType then
				BagTypes[bagId] = newType
				sendMessage("BAG_UPDATE_TYPE", bagId, newType)
			end
		end

		local function forEachItem(bagId, f, ...)
			if not bagId and f then
				error("Usage: forEachItem(bagId, function, ...)", 2)
			end

			for slotId = 1, getBagSize(bagId) do
				f(bagId, slotId, ...)
			end
		end

		local function forEachBag(f, ...)
			if not f then
				error("Usage: forEachBag(function, ...)", 2)
			end

			if AtBank then
				for bagId = 1, NUM_BAG_SLOTS + GetNumBankSlots() do
					f(bagId, ...)
				end
			else
				for bagId = 1, NUM_BAG_SLOTS do
					f(bagId, ...)
				end
			end
			f(KEYRING_CONTAINER, ...)
		end

		do
			local eventFrame = CreateFrame("Frame")
			eventFrame:Hide()

			eventFrame:SetScript("OnEvent", function(self, event, ...)
				local a = self[event]
				if a then
					a(self, event, ...)
				end
			end)
			eventFrame:RegisterEvent("PLAYER_LOGIN")

			function eventFrame:PLAYER_LOGIN(event, ...)
				self:RegisterEvent("BAG_UPDATE")
				self:RegisterEvent("BAG_UPDATE_COOLDOWN")
				self:RegisterEvent("PLAYERBANKSLOTS_CHANGED")

				updateBagSize(KEYRING_CONTAINER)
				forEachItem(KEYRING_CONTAINER, updateItem)

				updateBagSize(BACKPACK_CONTAINER)
				forEachItem(BACKPACK_CONTAINER, updateItem)
			end

			function eventFrame:BAG_UPDATE(event, bagId, ...)
				forEachBag(updateBagType)
				forEachBag(updateBagSize)
				forEachItem(bagId, updateItem)
			end

			function eventFrame:PLAYERBANKSLOTS_CHANGED(event, slotId, ...)
				if slotId > GetContainerNumSlots(BANK_CONTAINER) then
					local bagId = (slotId - getBagSize(BANK_CONTAINER)) + ITEM_INVENTORY_BANK_BAG_OFFSET
					updateBagType(bagId)
					updateBagSize(bagId)
				else
					updateItem(BANK_CONTAINER, slotId)
				end
			end

			function eventFrame:BAG_UPDATE_COOLDOWN(event, ...)
				forEachBag(forEachItem, updateItemCooldown)
			end
		end

		do
			local bankWatcher = CreateFrame("Frame")
			bankWatcher:Hide()

			bankWatcher:SetScript("OnShow", function(self)
				AtBank = true

				updateBagSize(BANK_CONTAINER)
				forEachItem(BANK_CONTAINER, updateItem)

				forEachBag(updateBagType)
				forEachBag(updateBagSize)

				sendMessage("BANK_OPENED")

				self:SetScript("OnShow", function(self)
					AtBank = true
					sendMessage("BANK_OPENED")
				end)
			end)

			bankWatcher:SetScript("OnHide", function(self)
				AtBank = false
				sendMessage("BANK_CLOSED")
			end)

			bankWatcher:SetScript("OnEvent", function(self, event, ...)
				if event == "BANKFRAME_OPENED" then
					self:Show()
				else
					self:Hide()
				end
			end)

			bankWatcher:RegisterEvent("BANKFRAME_OPENED")
			bankWatcher:RegisterEvent("BANKFRAME_CLOSED")
		end
	end

	-----------------------------------------

	do
		local PlayerInfo = mod:NewModule("PlayerInfo")

		function PlayerInfo:IsCached(player)
			if type(player) ~= "string" then
				error("Usage: PlayerInfo:IsCached('player'", 2)
			end
			return player ~= core.name
		end

		function PlayerInfo:GetMoney(player)
			if type(player) ~= "string" then
				error("Usage: PlayerInfo:GetMoney('player'", 2)
			end

			local money = 0
			if self:IsCached(player) then
				if BagnonDB then
					money = BagnonDB:GetMoney(player)
				end
			else
				money = GetMoney()
			end

			return money
		end

		function PlayerInfo:AtBank()
			return mod("InventoryEvents"):AtBank()
		end
	end

	-----------------------------------------

	do
		local BagSlotInfo = mod:NewModule("BagSlotInfo")

		local IsInventoryItemLocked = IsInventoryItemLocked
		local GetInventoryItemLink = GetInventoryItemLink
		local GetInventoryItemTexture = GetInventoryItemTexture
		local GetInventoryItemCount = GetInventoryItemCount
		local GetItemFamily = GetItemFamily
		local ContainerIDToInventoryID = ContainerIDToInventoryID
		local BankButtonIDToInvSlotID = BankButtonIDToInvSlotID

		function BagSlotInfo:IsBankBag(bagSlot)
			if not tonumber(bagSlot) then
				error("Usage: BagSlotInfo:IsBankBag(bagSlot)", 2)
			end

			return bagSlot > NUM_BAG_SLOTS and bagSlot < (NUM_BAG_SLOTS + NUM_BANKBAGSLOTS + 1)
		end

		function BagSlotInfo:IsBank(bagSlot)
			if not tonumber(bagSlot) then
				error("Usage: BagSlotInfo:IsBank(bagSlot)", 2)
			end

			return bagSlot == BANK_CONTAINER
		end

		function BagSlotInfo:IsBackpack(bagSlot)
			if not tonumber(bagSlot) then
				error("Usage: BagSlotInfo:IsBackpack(bagSlot)", 2)
			end

			return bagSlot == BACKPACK_CONTAINER
		end

		function BagSlotInfo:IsBackpackBag(bagSlot)
			if not tonumber(bagSlot) then
				error("Usage: BagSlotInfo:IsBackpackBag(bagSlot)", 2)
			end

			return bagSlot > 0 and bagSlot < (NUM_BAG_SLOTS + 1)
		end

		function BagSlotInfo:IsCached(player, bagSlot)
			if not (type(player) == "string" and tonumber(bagSlot)) then
				error("Usage: BagSlotInfo:IsCached('player', bagSlot)", 2)
			end

			if mod("PlayerInfo"):IsCached(player) then
				return true
			end

			if self:IsBank(bagSlot) or self:IsBankBag(bagSlot) then
				return not mod("PlayerInfo"):AtBank()
			end

			return false
		end

		function BagSlotInfo:IsPurchasable(player, bagSlot)
			if not (type(player) == "string" and tonumber(bagSlot)) then
				error("Usage: BagSlotInfo:IsPurchasable('player', bagSlot)", 2)
			end

			local purchasedSlots
			if self:IsCached(player, bagSlot) then
				if BagnonDB then
					purchasedSlots = BagnonDB:GetNumBankSlots(player) or 0
				else
					purchasedSlots = 0
				end
			else
				purchasedSlots = GetNumBankSlots()
			end
			return bagSlot > (purchasedSlots + NUM_BAG_SLOTS)
		end

		function BagSlotInfo:IsLocked(player, bagSlot)
			if not (type(player) == "string" and tonumber(bagSlot)) then
				error("Usage: BagSlotInfo:IsLocked('player', bagSlot)", 2)
			end

			if self:IsBackpack(bagSlot) or self:IsBank(bagSlot) or self:IsCached(player, bagSlot) then
				return false
			end
			return IsInventoryItemLocked(self:ToInventorySlot(bagSlot))
		end

		function BagSlotInfo:GetSize(player, bagSlot)
			if not (type(player) == "string" and tonumber(bagSlot)) then
				error("Usage: BagSlotInfo:GetSize('player', bagSlot)", 2)
			end

			local size = 0
			if self:IsCached(player, bagSlot) then
				if BagnonDB then
					size = (BagnonDB:GetBagData(bagSlot, player))
				end
			elseif self:IsBank(bagSlot) then
				size = NUM_BANKGENERIC_SLOTS
			else
				size = GetContainerNumSlots(bagSlot)
			end
			return size or 0
		end

		function BagSlotInfo:GetItemInfo(player, bagSlot)
			if not (type(player) == "string" and tonumber(bagSlot)) then
				error("Usage: size = BagSlotInfo:GetItemInfo('player', bagSlot)", 2)
			end

			local link, texture, count, _
			if self:IsCached(player, bagSlot) then
				if BagnonDB then
					_, link, count, texture = BagnonDB:GetBagData(bagSlot, player)
				end
			else
				local invSlot = self:ToInventorySlot(bagSlot)
				link = GetInventoryItemLink("player", invSlot)
				texture = GetInventoryItemTexture("player", invSlot)
				count = GetInventoryItemCount("player", invSlot)
			end
			return link, count, texture
		end

		local BAGTYPE_PROFESSION = 0x0008 + 0x0010 + 0x0020 + 0x0040 + 0x0080 + 0x0200 + 0x0400 + 0x8000

		function BagSlotInfo:GetBagType(player, bagSlot)
			if not (type(player) == "string" and tonumber(bagSlot)) then
				error("Usage: size = BagSlotInfo:GetBagType('player', bagSlot)", 2)
			end

			if self:IsBank(bagSlot) or self:IsBackpack(bagSlot) then
				return 0
			end

			local itemLink = (self:GetItemInfo(player, bagSlot))
			if itemLink then
				return GetItemFamily(itemLink)
			end

			return 0
		end

		function BagSlotInfo:IsTradeBag(player, bagSlot)
			if not (type(player) == "string" and tonumber(bagSlot)) then
				error("Usage: size = BagSlotInfo:IsTradeBag('player', bagSlot)", 2)
			end

			return bit.band(self:GetBagType(player, bagSlot) or 0, BAGTYPE_PROFESSION) > 0
		end

		function BagSlotInfo:ToInventorySlot(bagSlot)
			if not tonumber(bagSlot) then
				error("Usage: BagSlotInfo:ToInventorySlot(bagSlot)", 2)
			end

			if self:IsBackpackBag(bagSlot) then
				return ContainerIDToInventoryID(bagSlot)
			end

			if self:IsBankBag(bagSlot) then
				return BankButtonIDToInvSlotID(bagSlot, 1)
			end

			return nil
		end
	end

	-----------------------------------------

	do
		local ItemSlotInfo = mod:NewModule("ItemSlotInfo")
		local GetItemInfo = GetItemInfo
		local GetContainerItemInfo = GetContainerItemInfo

		function ItemSlotInfo:GetItemInfo(player, bag, slot)
			local link, count, texture, quality, readable, locked, lootable
			if self:IsCached(player, bag, slot) then
				if BagnonDB then
					link, count, texture, quality = BagnonDB:GetItemData(bag, slot, player)
				end
			else
				texture, count, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)
				if link and quality < 0 then
					quality = select(3, GetItemInfo(link))
				end
			end
			return texture, count, locked, quality, readable, lootable, link
		end

		function ItemSlotInfo:IsLocked(player, bag, slot)
			if self:IsCached(player, bag, slot) then
				return false
			end
			return select(3, GetContainerItemInfo(bag, slot))
		end

		function ItemSlotInfo:IsCached(player, bag, slot)
			return mod("BagSlotInfo"):IsCached(player, bag)
		end
	end

	-----------------------------------------------------------------------
	-- Sets

	do
		local CombuctorSet = mod:NewModule("Sets", mod("Envoy"):New())
		mod.Set = CombuctorSet

		local assert = assert
		local format = string.format
		local BAGTYPE_PROFESSION = 0x0008 + 0x0010 + 0x0020 + 0x0040 + 0x0080 + 0x0200 + 0x0400 + 0x8000

		-------------------------------------
		-- sets.lua
		--

		do
			local sets = {}

			local sendMessage = function(msg, ...)
				CombuctorSet:Send(msg, ...)
			end
			CombuctorSet.RegisterMessage = CombuctorSet.Register
			CombuctorSet.UnregisterMessage = CombuctorSet.Unregister

			function CombuctorSet:Register(name, icon, rule)
				assert(name, "Set must include a name")
				assert(icon, format("No icon specified for set '%s'", icon))

				local set = self:Get(name)
				if set then
					if not (set.icon == icon and set.rule == rule) then
						set.icon = icon
						set.rule = rule
						sendMessage("COMBUCTOR_SET_UPDATE", name, icon, rule)
					end
				else
					table.insert(sets, {["name"] = name, ["icon"] = icon, ["rule"] = rule})
					sendMessage("COMBUCTOR_SET_ADD", name, icon, rule)
				end
			end

			function CombuctorSet:RegisterSubSet(name, parent, icon, rule)
				assert(name, "Subset must include a name")
				assert(self:Get(parent), format("Cannot find a parent set named '%s'", parent))

				local set = self:Get(name, parent)
				if set then
					if not (set.icon == icon and set.rule == rule) then
						set.icon = icon
						set.rule = rule
						sendMessage("COMBUCTOR_SUBSET_UPDATE", name, parent, icon, rule)
					end
				else
					table.insert(sets, {["parent"] = parent, ["name"] = name, ["icon"] = icon, ["rule"] = rule})
					sendMessage("COMBUCTOR_SUBSET_ADD", name, parent, icon, rule)
				end
			end

			do
				local function removeSetAndChildren(parent)
					local i = 1
					local found = false

					while i <= #sets do
						local set = sets[i]

						if set.parent == parent or (set.parent == nil and set.name == parent) then
							table.remove(sets, i)
							found = true
						else
							i = i + 1
						end
					end

					if found then
						sendMessage("COMBUCTOR_SET_REMOVE", parent)
					end
				end

				function CombuctorSet:Unregister(name, parent)
					if parent then
						for i, set in pairs(sets) do
							if set.name == name and set.parent == parent then
								table.remove(sets, i)
								sendMessage("COMBUCTOR_SUBSET_REMOVE", name, parent)
								break
							end
						end
					else
						removeSetAndChildren(name)
					end
				end
			end

			function CombuctorSet:Get(name, parent)
				for _, set in pairs(sets) do
					if set.name == name and set.parent == parent then
						return set
					end
				end
			end

			do
				local function parentSetIterator(_, i)
					for j = i + 1, #sets do
						local set = sets[j]
						if set and not set.parent then
							return j, set
						end
					end
				end

				function CombuctorSet:GetParentSets()
					return parentSetIterator, nil, 0
				end
			end

			do
				local function getChildSetIterator(parent, i)
					for j = i + 1, #sets do
						local set = sets[j]
						if set and set.parent == parent then
							return j, set
						end
					end
				end

				function CombuctorSet:GetChildSets(parent)
					return getChildSetIterator, parent, 0
				end
			end
		end

		-------------------------------------
		-- filters
		--

		CombuctorSet:Register(ALL, "Interface\\Icons\\INV_Misc_EngGizmos_17", function() return true end)
		CombuctorSet:RegisterSubSet(ALL, ALL)
		CombuctorSet:RegisterSubSet(L.Normal, ALL, nil, function(player, bagType) return bagType and bagType == 0 end)
		CombuctorSet:RegisterSubSet(L.Trade, ALL, nil, function(player, bagType) return bagType and bit.band(bagType, BAGTYPE_PROFESSION) > 0 end)

		-- equipment
		do
			local function isEquipment(_, _, _, _, _, _, _, itype, _, _, _)
				return (itype == L.Armor or itype == L.Weapon)
			end
			CombuctorSet:Register(L.Equipment, "Interface/Icons/INV_Chest_Chain_04", isEquipment)
			CombuctorSet:RegisterSubSet(ALL, L.Equipment)
		end

		-- armor
		do
			local function isArmor(_, _, _, _, _, _, _, itype, _, _, equipLoc)
				return itype == L.Armor and equipLoc ~= "INVTYPE_TRINKET"
			end
			CombuctorSet:RegisterSubSet(L.Armor, L.Equipment, nil, isArmor)
		end

		-- weapon
		do
			local function isWeapon(_, _, _, _, _, _, _, itype, _, _, _)
				return itype == L.Weapon
			end
			CombuctorSet:RegisterSubSet(L.Weapon, L.Equipment, nil, isWeapon)
		end

		-- trinket
		do
			local function isTrinket(_, _, _, _, _, _, _, _, _, _, equipLoc)
				return equipLoc == "INVTYPE_TRINKET"
			end
			CombuctorSet:RegisterSubSet(INVTYPE_TRINKET, L.Equipment, nil, isTrinket)
		end

		-- usable items
		do
			local function isUsable(_, _, _, _, _, _, _, itype, subType, _, _)
				if itype == L.Consumable then
					return true
				elseif itype == L.TradeGood then
					if subType == L.Devices or subType == L.Explosives then
						return true
					end
				end
			end
			CombuctorSet:Register(L.Usable, "Interface/Icons/INV_Potion_93", isUsable)
			CombuctorSet:RegisterSubSet(ALL, L.Usable)
		end

		-- consumable
		do
			local function isConsumable(_, _, _, _, _, _, _, itype, _, _, _)
				return itype == L.Consumable
			end
			CombuctorSet:RegisterSubSet(L.Consumable, L.Usable, nil, isConsumable)
		end

		-- devices
		do
			local function isDevice(_, _, _, _, _, _, _, itype, _, _, _)
				return itype == L.TradeGood
			end
			CombuctorSet:RegisterSubSet(L.Devices, L.Usable, nil, isDevice)
		end

		-- quest items
		do
			local function isQuestItem(_, _, _, _, _, _, _, itype, _, _, _)
				return itype == L.Quest
			end
			CombuctorSet:Register(L.Quest, "Interface/QuestFrame/UI-QuestLog-BookIcon", isQuestItem)
			CombuctorSet:RegisterSubSet(ALL, L.Quest)
		end

		-- trade goods + gems
		do
			local function isTradeGood(_, _, _, _, _, _, _, itype, subType, _, _)
				if itype == L.TradeGood then
					return not (subType == L.Devices or subType == L.Explosives)
				end
				return itype == L.Recipe or itype == L.Gem
			end
			CombuctorSet:Register(L.TradeGood, "Interface/Icons/INV_Fabric_Silk_02", isTradeGood)
			CombuctorSet:RegisterSubSet(ALL, L.TradeGood)
		end

		-- trade good
		do
			local function isTradeGood(_, _, _, _, _, _, _, itype, _, _, _)
				return itype == L.TradeGood
			end
			CombuctorSet:RegisterSubSet(L.TradeGood, L.TradeGood, nil, isTradeGood)
		end

		-- gems
		do
			local function isGem(_, _, _, _, _, _, _, itype, _, _, _)
				return itype == L.Gem
			end
			CombuctorSet:RegisterSubSet(L.Gem, L.TradeGood, nil, isGem)
		end

		-- recipe
		do
			local function isRecipe(_, _, _, _, _, _, _, itype, _, _, _)
				return itype == L.Recipe
			end
			CombuctorSet:RegisterSubSet(L.Recipe, L.TradeGood, nil, isRecipe)
		end

		-- misc
		do
			local function isMiscItem(_, _, _, link, _, _, _, itype, _, _, _)
				return itype == L.Misc and (link:match("%d+") ~= "6265")
			end
			CombuctorSet:Register(L.Misc, "Interface/Icons/INV_Misc_Rune_01", isMiscItem)
			CombuctorSet:RegisterSubSet(ALL, L.Misc)
		end
	end

	-----------------------------------------------------------------------
	-- Item

	do
		local ItemSearch = LibStub("LibItemSearch-1.0")
		local BagSlotInfo = mod("BagSlotInfo")
		local ItemSlotInfo = mod("ItemSlotInfo")

		local pairs, ipairs = pairs, ipairs
		local select = select
		local format = string.format

		local CreateFrame = CreateFrame
		local GetItemInfo = GetItemInfo
		local ClearCursor = ClearCursor
		local ResetCursor = ResetCursor
		local CursorHasItem = CursorHasItem
		local HandleModifiedItemClick = HandleModifiedItemClick
		local SetItemButtonCount = SetItemButtonCount
		local SetItemButtonDesaturated = SetItemButtonDesaturated
		local SetItemButtonTexture = SetItemButtonTexture
		local SetItemButtonTextureVertexColor = SetItemButtonTextureVertexColor

		-- item.lua

		do
			local ItemSlot = core:NewClass("Button")
			mod.ItemSlot = ItemSlot

			local PlayerInfo = mod("PlayerInfo")

			function ItemSlot:New()
				return self:Restore() or self:Create()
			end

			function ItemSlot:Set(parent, bag, slot)
				self:SetParent(self:GetDummyBag(parent, bag))
				self:SetID(slot)

				if self:IsVisible() then
					self:Update()
				else
					self:Show()
				end
			end

			function ItemSlot:Create()
				local id = self:GetNextItemSlotID()
				-- local item = self:Bind(self:GetBlizzardItemSlot(id) or self:ConstructNewItemSlot(id)) -- TODO: FIXME
				local item = self:Bind(self:ConstructNewItemSlot(id))

				local border = item:CreateTexture(nil, "OVERLAY")
				border:SetWidth(67)
				border:SetHeight(67)
				border:SetPoint("CENTER", item)
				border:SetTexture([[Interface\Buttons\UI-ActionButton-Border]])
				border:SetBlendMode("ADD")
				border:Hide()
				item.border = border

				item.questBorder = _G[item:GetName() .. "IconQuestTexture"]

				item.cooldown = _G[item:GetName() .. "Cooldown"]

				item:SetScript("OnEvent", nil)
				item:SetScript("OnEnter", item.OnEnter)
				item:SetScript("OnLeave", item.OnLeave)
				item:SetScript("OnShow", item.OnShow)
				item:SetScript("OnHide", item.OnHide)
				item:SetScript("PostClick", item.PostClick)
				item.UpdateTooltip = nil

				return item
			end

			function ItemSlot:ConstructNewItemSlot(id)
				return CreateFrame("Button", ("%sItem%d"):format(modname, id), nil, "ContainerFrameItemButtonTemplate")
			end

			function ItemSlot:GetBlizzardItemSlot(id)
				return
				-- if not self:CanReuseBlizzardBagSlots() then
				-- 	return nil
				-- end

				-- local bag = math.ceil(id / MAX_CONTAINER_ITEMS)
				-- local slot = (id - 1) % MAX_CONTAINER_ITEMS + 1
				-- local item = _G[format("ContainerFrame%dItem%d", bag, slot)]

				-- if item then
				-- 	item:SetID(0)
				-- 	item:ClearAllPoints()
				-- 	return item
				-- end
			end

			function ItemSlot:CanReuseBlizzardBagSlots()
				return true
			end

			function ItemSlot:Restore()
				local item = ItemSlot.unused and next(ItemSlot.unused)
				if item then
					ItemSlot.unused[item] = nil
					return item
				end
			end

			do
				local id = 1
				function ItemSlot:GetNextItemSlotID()
					local nextID = id
					id = id + 1
					return nextID
				end
			end

			function ItemSlot:Free()
				self:Hide()
				self:SetParent(nil)
				self:UnlockHighlight()

				ItemSlot.unused = ItemSlot.unused or {}
				ItemSlot.unused[self] = true
			end

			function ItemSlot:OnShow()
				self:Update()
			end

			function ItemSlot:OnHide()
				self:HideStackSplitFrame()
			end

			function ItemSlot:OnDragStart()
				if self:IsCached() and CursorHasItem() then
					ClearCursor()
				end
			end

			function ItemSlot:OnModifiedClick(button)
				local link = self:IsCached() and self:GetItem()
				if link then
					HandleModifiedItemClick(link)
				end
			end

			function ItemSlot:OnEnter()
				local dummySlot = self:GetDummyItemSlot()

				if self:IsCached() then
					dummySlot:SetParent(self)
					dummySlot:SetAllPoints(self)
					dummySlot:Show()
				else
					dummySlot:Hide()

					if self:IsBank() then
						if self:GetItem() then
							self:AnchorTooltip()
							GameTooltip:SetInventoryItem("player", BankButtonIDToInvSlotID(self:GetID()))
							GameTooltip:Show()
							CursorUpdate(self)
						end
					else
						ContainerFrameItemButton_OnEnter(self)
					end
				end
			end

			function ItemSlot:OnLeave()
				GameTooltip:Hide()
				ResetCursor()
			end

			function ItemSlot:Update()
				if not self:IsVisible() then
					return
				end

				local texture, count, locked, quality, readable, lootable, link = self:GetItemSlotInfo()
				self:SetItem(link)
				self:SetTexture(texture)
				self:SetCount(count)
				self:SetLocked(locked)
				self:SetReadable(readable)
				self:SetBorderQuality(quality)
				self:UpdateCooldown()
				self:UpdateSlotColor()
				if GameTooltip:IsOwned(self) then
					self:UpdateTooltip()
				end
			end

			function ItemSlot:SetItem(itemLink)
				self.hasItem = itemLink or nil
			end

			function ItemSlot:GetItem()
				return self.hasItem
			end

			function ItemSlot:SetTexture(texture)
				SetItemButtonTexture(self, texture or self:GetEmptyItemTexture())
			end

			function ItemSlot:GetEmptyItemTexture()
				if self:ShowingEmptyItemSlotTexture() then
					return [[Interface\PaperDoll\UI-Backpack-EmptySlot]]
				end
				return nil
			end

			function ItemSlot:UpdateSlotColor()
				if (not self:GetItem()) and self:ColoringBagSlots() then
					if self:IsTradeBagSlot() then
						local r, g, b = self:GetTradeSlotColor()
						SetItemButtonTextureVertexColor(self, r, g, b)
						local normText = self.normText or self:GetNormalTexture()
						if normText and normText.SetVertexColor then
							normText:SetVertexColor(r, g, b)
						end
						return
					end
				end

				SetItemButtonTextureVertexColor(self, 1, 1, 1)
				local normText = self.normText or self:GetNormalTexture()
				if normText and normText.SetVertexColor then
					normText:SetVertexColor(1, 1, 1)
				end
			end

			function ItemSlot:SetCount(count)
				SetItemButtonCount(self, count)
			end

			function ItemSlot:SetReadable(readable)
				self.readable = readable
			end

			function ItemSlot:SetLocked(locked)
				SetItemButtonDesaturated(self, locked)
			end

			function ItemSlot:UpdateLocked()
				self:SetLocked(self:IsLocked())
			end

			function ItemSlot:IsLocked()
				return ItemSlotInfo:IsLocked(self:GetPlayer(), self:GetBag(), self:GetID())
			end

			function ItemSlot:SetBorderQuality(quality)
				local border = self.border
				local qBorder = self.questBorder

				if self:HighlightingQuestItems() then
					local isQuestItem, isQuestStarter = self:IsQuestItem()
					if isQuestItem then
						qBorder:SetTexture(TEXTURE_ITEM_QUEST_BORDER)
						qBorder:SetAlpha(self:GetHighlightAlpha())
						qBorder:Show()
						border:Hide()
						return
					end

					if isQuestStarter then
						qBorder:SetTexture(TEXTURE_ITEM_QUEST_BANG)
						qBorder:SetAlpha(self:GetHighlightAlpha())
						qBorder:Show()
						border:Hide()
						return
					end
				end

				if self:HighlightingItemsByQuality() then
					if self:GetItem() and quality and quality > 1 then
						local r, g, b = GetItemQualityColor(quality)
						border:SetVertexColor(r, g, b, self:GetHighlightAlpha())
						border:Show()
						qBorder:Hide()
						return
					end
				end

				qBorder:Hide()
				border:Hide()
			end

			function ItemSlot:UpdateBorder()
				local texture, count, locked, quality = self:GetItemSlotInfo()
				self:SetBorderQuality(quality)
			end

			function ItemSlot:UpdateCooldown()
				if self:GetItem() and (not self:IsCached()) then
					ContainerFrame_UpdateCooldown(self:GetBag(), self)
				else
					CooldownFrame_SetTimer(self.cooldown, 0, 0, 0)
					SetItemButtonTextureVertexColor(self, 1, 1, 1)
				end
			end

			function ItemSlot:HideStackSplitFrame()
				if self.hasStackSplit and self.hasStackSplit == 1 then
					StackSplitFrame:Hide()
				end
			end

			ItemSlot.UpdateTooltip = ItemSlot.OnEnter

			function ItemSlot:AnchorTooltip()
				if self:GetRight() >= (GetScreenWidth() / 2) then
					GameTooltip:SetOwner(self, "ANCHOR_LEFT")
				else
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				end
			end

			function ItemSlot:Highlight(enable)
				if enable then
					self:LockHighlight()
				else
					self:UnlockHighlight()
				end
			end

			function ItemSlot:GetPlayer()
				local player
				if self:GetParent() then
					local p = self:GetParent():GetParent()
					player = p and p:GetPlayer()
				end
				return player or core.name
			end

			function ItemSlot:GetBag()
				return self:GetParent() and self:GetParent():GetID() or -1
			end

			function ItemSlot:IsSlot(bag, slot)
				return self:GetBag() == bag and self:GetID() == slot
			end

			function ItemSlot:IsCached()
				return BagSlotInfo:IsCached(self:GetPlayer(), self:GetBag())
			end

			function ItemSlot:IsBank()
				return BagSlotInfo:IsBank(self:GetBag())
			end

			function ItemSlot:IsBankSlot()
				local bag = self:GetBag()
				return BagSlotInfo:IsBank(bag) or BagSlotInfo:IsBankBag(bag)
			end

			function ItemSlot:AtBank()
				return PlayerInfo:AtBank()
			end

			function ItemSlot:GetItemSlotInfo()
				local texture, count, locked, quality, readable, lootable, link =
					ItemSlotInfo:GetItemInfo(self:GetPlayer(), self:GetBag(), self:GetID())
				return texture, count, locked, quality, readable, lootable, link
			end

			function ItemSlot:HighlightingItemsByQuality()
				return true
			end
			function ItemSlot:HighlightingQuestItems()
				return true
			end
			function ItemSlot:GetHighlightAlpha()
				return 0.5
			end

			local QUEST_ITEM_SEARCH = format("t:%s|%s", select(10, GetAuctionItemClasses()), "quest")
			function ItemSlot:IsQuestItem()
				local itemLink = self:GetItem()
				if not itemLink then
					return false, false
				end

				if self:IsCached() then
					return ItemSearch:Find(itemLink, QUEST_ITEM_SEARCH), false
				else
					local isQuestItem, questID, isActive = GetContainerItemQuestInfo(self:GetBag(), self:GetID())
					return isQuestItem, (questID and not isActive)
				end
			end

			function ItemSlot:IsTradeBagSlot()
				return BagSlotInfo:IsTradeBag(self:GetPlayer(), self:GetBag())
			end

			function ItemSlot:GetTradeSlotColor()
				return 0.5, 1, 0.5
			end
			function ItemSlot:ColoringBagSlots()
				return true
			end
			function ItemSlot:ShowingEmptyItemSlotTexture()
				return true
			end

			function ItemSlot:GetDummyItemSlot()
				ItemSlot.dummySlot = ItemSlot.dummySlot or ItemSlot:CreateDummyItemSlot()
				return ItemSlot.dummySlot
			end

			function ItemSlot:CreateDummyItemSlot()
				local slot = CreateFrame("Button")
				slot:RegisterForClicks("anyUp")
				slot:SetToplevel(true)
				slot:Hide()

				local function Slot_OnEnter(self)
					local parent = self:GetParent()
					parent:LockHighlight()

					if parent:IsCached() and parent:GetItem() then
						ItemSlot.AnchorTooltip(self)
						GameTooltip:SetHyperlink(parent:GetItem())
						GameTooltip:Show()
					end
				end

				local function Slot_OnLeave(self)
					GameTooltip:Hide()
					self:Hide()
				end

				local function Slot_OnHide(self)
					local parent = self:GetParent()
					if parent then
						parent:UnlockHighlight()
					end
				end

				local function Slot_OnClick(self, button)
					self:GetParent():OnModifiedClick(button)
				end

				slot.UpdateTooltip = Slot_OnEnter
				slot:SetScript("OnClick", Slot_OnClick)
				slot:SetScript("OnEnter", Slot_OnEnter)
				slot:SetScript("OnLeave", Slot_OnLeave)
				slot:SetScript("OnShow", Slot_OnEnter)
				slot:SetScript("OnHide", Slot_OnHide)

				return slot
			end

			function ItemSlot:GetDummyBag(parent, bag)
				local dummyBags = parent.dummyBags
				if not dummyBags then
					dummyBags = setmetatable({}, {__index = function(t, k)
						local f = CreateFrame("Frame", nil, parent)
						f:SetID(k)
						t[k] = f
						return f
					end})
					parent.dummyBags = dummyBags
				end

				return dummyBags[bag]
			end
		end

		-- itemFrameEvents.lua

		do
			local FrameEvents = mod:NewModule("ItemFrameEvents")
			local frames = {}

			function FrameEvents:ITEM_LOCK_CHANGED(msg, ...)
				self:UpdateSlotLock(...)
			end
			function FrameEvents:UNIT_QUEST_LOG_CHANGED(msg, ...)
				self:UpdateBorder(...)
			end
			function FrameEvents:QUEST_ACCEPTED(msg, ...)
				self:UpdateBorder(...)
			end
			function FrameEvents:ITEM_SLOT_ADD(msg, ...)
				self:UpdateSlot(...)
			end
			function FrameEvents:ITEM_SLOT_REMOVE(msg, ...)
				self:RemoveItem(...)
			end
			function FrameEvents:ITEM_SLOT_UPDATE(msg, ...)
				self:UpdateSlot(...)
			end
			function FrameEvents:ITEM_SLOT_UPDATE_COOLDOWN(msg, ...)
				self:UpdateSlotCooldown(...)
			end
			function FrameEvents:BANK_OPENED(msg, ...)
				self:UpdateBankFrames(...)
			end
			function FrameEvents:BANK_CLOSED(msg, ...)
				self:UpdateBankFrames(...)
			end
			function FrameEvents:BAG_UPDATE_TYPE(msg, ...)
				self:UpdateSlotColor(...)
			end

			function FrameEvents:UpdateBorder(...)
				for f in self:GetFrames() do
					if f:GetPlayer() == core.name then
						f:UpdateBorder(...)
					end
				end
			end

			function FrameEvents:UpdateSlotColor(...)
				for f in self:GetFrames() do
					if f:GetPlayer() == core.name then
						f:UpdateSlotColor(...)
					end
				end
			end

			function FrameEvents:UpdateSlot(...)
				for f in self:GetFrames() do
					if f:GetPlayer() == core.name then
						if f:UpdateSlot(...) then
							f:RequestLayout()
						end
					end
				end
			end

			function FrameEvents:RemoveItem(...)
				for f in self:GetFrames() do
					if f:GetPlayer() == core.name then
						if f:RemoveItem(...) then
							f:RequestLayout()
						end
					end
				end
			end

			function FrameEvents:UpdateSlotLock(...)
				for f in self:GetFrames() do
					if f:GetPlayer() == core.name then
						f:UpdateSlotLock(...)
					end
				end
			end

			function FrameEvents:UpdateSlotCooldown(...)
				for f in self:GetFrames() do
					if f:GetPlayer() == core.name then
						f:UpdateSlotCooldown(...)
					end
				end
			end

			function FrameEvents:UpdateBankFrames()
				for f in self:GetFrames() do
					f:Regenerate()
				end
			end

			function FrameEvents:LayoutFrames()
				for f in self:GetFrames() do
					if f.needsLayout then
						f.needsLayout = nil
						f:Layout()
					end
				end
			end

			function FrameEvents:RequestLayout()
				self.Updater:Show()
			end

			function FrameEvents:GetFrames()
				return pairs(frames)
			end

			function FrameEvents:Register(f)
				frames[f] = true
			end

			function FrameEvents:Unregister(f)
				frames[f] = nil
			end

			-- Initialization
			do
				local f = CreateFrame("Frame")
				f:Hide()
				f:SetScript("OnEvent", function(self, event, ...)
					local method = FrameEvents[event]
					if method then
						method(FrameEvents, event, ...)
					end
				end)
				f:SetScript("OnUpdate", function(self, elapsed)
					FrameEvents:LayoutFrames()
					self:Hide()
				end)

				f:RegisterEvent("ITEM_LOCK_CHANGED")
				f:RegisterEvent("UNIT_QUEST_LOG_CHANGED")
				f:RegisterEvent("QUEST_ACCEPTED")

				FrameEvents.Updater = f

				mod("InventoryEvents"):RegisterMany(
					FrameEvents,
					"ITEM_SLOT_ADD",
					"ITEM_SLOT_REMOVE",
					"ITEM_SLOT_UPDATE",
					"ITEM_SLOT_UPDATE_COOLDOWN",
					"BANK_OPENED",
					"BANK_CLOSED",
					"BAG_UPDATE_TYPE"
				)
			end
		end

		-- itemFrame.lua

		do
			local ItemFrame = core:NewClass("Button")
			mod.ItemFrame = ItemFrame

			local FrameEvents = mod("ItemFrameEvents")

			local function ToIndex(bag, slot)
				return (bag < 0 and bag * 100 - slot) or (bag * 100 + slot)
			end

			local function ToBag(index)
				return (index > 0 and floor(index / 100)) or ceil(index / 100)
			end

			function ItemFrame:New(parent)
				local f = self:Bind(CreateFrame("Button", nil, parent))
				f.items = {}
				f.bags = parent.sets.bags
				f.filter = parent.filter
				f.count = 0

				f:RegisterForClicks("anyUp")
				f:SetScript("OnShow", self.OnShow)
				f:SetScript("OnHide", self.OnHide)
				f:SetScript("OnClick", self.PlaceItem)

				return f
			end

			function ItemFrame:OnShow()
				self:UpdateUpdatable()
				self:Regenerate()
			end

			function ItemFrame:OnHide()
				self:UpdateUpdatable()
			end

			function ItemFrame:UpdateUpdatable()
				if self:IsVisible() then
					FrameEvents:Register(self)
				else
					FrameEvents:Unregister(self)
				end
			end

			function ItemFrame:SetPlayer(player)
				self.player = player
				self:ReloadAllItems()
			end

			function ItemFrame:GetPlayer()
				return self.player or core.name
			end

			function ItemFrame:HasItem(bag, slot, link)
				local hasBag = false
				for _, bagID in pairs(self.bags) do
					if bag == bagID then
						hasBag = true
						break
					end
				end
				if not hasBag then
					return false
				end

				local f = self.filter
				if next(f) then
					local player = self:GetPlayer()
					local bagType = self:GetBagType(bag)
					link = link or self:GetItemLink(bag, slot)

					local name, quality, level, ilvl, itemType, subType, stackCount, equipLoc
					if link then
						name, link, quality, level, ilvl, itemType, subType, stackCount, equipLoc =
							GetItemInfo(link)
					end

					if f.quality > 0 and not (quality and bit.band(f.quality, mod.QualityFlags[quality]) > 0) then
						return false
					elseif
						f.rule and
							not f.rule(player, bagType, name, link, quality, level, ilvl, itemType, subType, stackCount, equipLoc)
					 then
						return false
					elseif
						f.subRule and
							not f.subRule(player, bagType, name, link, quality, level, ilvl, itemType, subType, stackCount, equipLoc)
					 then
						return false
					elseif f.name then
						return ItemSearch:Find(link, f.name)
					end
				end
				return true
			end

			function ItemFrame:AddItem(bag, slot)
				local index = ToIndex(bag, slot)
				local item = self.items[index]

				if item then
					item:Update()
					item:Highlight(self.highlightBag == bag)
				else
					item = mod.ItemSlot:New()
					item:Set(self, bag, slot)
					item:Highlight(self.highlightBag == bag)

					self.items[index] = item
					self.count = self.count + 1
					return true
				end
			end

			function ItemFrame:RemoveItem(bag, slot)
				local index = ToIndex(bag, slot)
				local item = self.items[index]

				if item then
					item:Free()
					self.items[index] = nil
					self.count = self.count - 1
					return true
				end
			end

			function ItemFrame:UpdateSlot(bag, slot, link)
				if self:HasItem(bag, slot, link) then
					return self:AddItem(bag, slot)
				end
				return self:RemoveItem(bag, slot)
			end

			function ItemFrame:UpdateSlotLock(bag, slot)
				if not slot then
					return
				end

				local item = self.items[ToIndex(bag, slot)]
				if item then
					item:UpdateLocked()
				end
			end

			function ItemFrame:UpdateSlotCooldown(bag, slot)
				local item = self.items[ToIndex(bag, slot)]
				if item then
					item:UpdateCooldown()
				end
			end

			function ItemFrame:UpdateSlotCooldowns()
				for _, item in pairs(self.items) do
					item:UpdateCooldown()
				end
			end

			function ItemFrame:UpdateBorder()
				for _, item in pairs(self.items) do
					item:UpdateBorder()
				end
			end

			function ItemFrame:UpdateSlotColor(bagId)
				for _, item in pairs(self.items) do
					if item:GetBag() == bagId then
						item:UpdateSlotColor()
					end
				end
			end

			function ItemFrame:Regenerate()
				if not self:IsVisible() then
					return
				end

				local changed = false
				for _, bag in pairs(self.bags) do
					for slot = 1, self:GetBagSize(bag) do
						if self:UpdateSlot(bag, slot) then
							changed = true
						end
					end
				end

				if changed then
					self:RequestLayout()
				end
			end

			function ItemFrame:RemoveAllItems()
				local items = self.items
				local changed = true

				for i, item in pairs(items) do
					changed = true
					item:Free()
					items[i] = nil
				end
				self.count = 0

				return changed
			end

			function ItemFrame:ReloadAllItems()
				if self:RemoveAllItems() and self:IsVisible() then
					self:Regenerate()
				end
			end

			function ItemFrame:RequestLayout()
				self.needsLayout = true
				self:TriggerLayout()
			end

			function ItemFrame:TriggerLayout()
				if self:IsVisible() and self.needsLayout then
					FrameEvents:RequestLayout(self)
				end
			end

			function ItemFrame:Layout(spacing)
				local width, height = self:GetWidth(), self:GetHeight()
				spacing = spacing or 2
				local count = self.count
				local size = 36 + spacing * 2
				local cols = 0
				local scale, rows
				local maxScale = mod:GetMaxItemScale()

				repeat
					cols = cols + 1
					scale = width / (size * cols)
					rows = floor(height / (size * scale))
				until (scale <= maxScale and cols * rows >= count)

				local player = self:GetPlayer()
				local items = self.items
				local i = 0

				for _, bag in ipairs(self.bags) do
					for slot = 1, self:GetBagSize(bag) do
						local item = items[ToIndex(bag, slot)]
						if item then
							i = i + 1
							local row = _G.mod(i - 1, cols)
							local col = ceil(i / cols) - 1
							item:ClearAllPoints()
							item:SetScale(scale)
							item:SetPoint("TOPLEFT", self, "TOPLEFT", size * row + spacing, -(size * col + spacing))
							item:Show()
						end
					end
				end
			end

			function ItemFrame:HighlightBag(bag)
				self.highlightBag = bag
				for _, item in pairs(self.items) do
					item:Highlight(item:GetBag() == bag)
				end
			end

			function ItemFrame:GetBagSize(bag)
				return BagSlotInfo:GetSize(self:GetPlayer(), bag)
			end

			function ItemFrame:GetBagType(bag)
				return BagSlotInfo:GetBagType(self:GetPlayer(), bag)
			end

			function ItemFrame:IsBagCached(bag)
				return BagSlotInfo:IsCached(self:GetPlayer(), bag)
			end

			function ItemFrame:GetItemLink(bag, slot)
				local link = select(7, ItemSlotInfo:GetItemInfo(self:GetPlayer(), bag, slot))
				return link
			end

			function ItemFrame:PlaceItem()
				if CursorHasItem() then
					for _, bag in ipairs(self.bags) do
						if not self:IsBagCached(bag) then
							for slot = 1, self:GetBagSize(bag) do
								if not GetContainerItemLink(bag, slot) then
									PickupContainerItem(bag, slot)
								end
							end
						end
					end
				end
			end
		end

		-- bag.lua

		do
			local Bag = core:NewClass("Button")
			mod.Bag = Bag
			local SIZE = 30
			local NORMAL_TEXTURE_SIZE = 64 * (SIZE / 36)

			local unused = {}
			local id = 1

			function Bag:New()
				local bag = self:Bind(CreateFrame("Button", ("%sBag%d"):format(modname, id)))
				local name = bag:GetName()
				bag:SetSize(SIZE, SIZE)

				local icon = bag:CreateTexture(name .. "IconTexture", "BORDER")
				icon:SetAllPoints(bag)

				local count = bag:CreateFontString(name .. "Count", "OVERLAY")
				count:SetFontObject("NumberFontNormalSmall")
				count:SetJustifyH("RIGHT")
				count:SetPoint("BOTTOMRIGHT", -2, 2)

				local nt = bag:CreateTexture(name .. "NormalTexture")
				nt:SetTexture([[Interface\\Buttons\\UI-Quickslot2]])
				nt:SetWidth(NORMAL_TEXTURE_SIZE)
				nt:SetHeight(NORMAL_TEXTURE_SIZE)
				nt:SetPoint("CENTER", 0, -1)
				bag:SetNormalTexture(nt)

				local pt = bag:CreateTexture()
				pt:SetTexture([[Interface\Buttons\UI-Quickslot-Depress]])
				pt:SetAllPoints(bag)
				bag:SetPushedTexture(pt)

				local ht = bag:CreateTexture()
				ht:SetTexture([[Interface\Buttons\ButtonHilight-Square]])
				ht:SetAllPoints(bag)
				bag:SetHighlightTexture(ht)

				bag:RegisterForClicks("anyUp")
				bag:RegisterForDrag("LeftButton")

				bag:SetScript("OnEnter", self.OnEnter)
				bag:SetScript("OnShow", self.OnShow)
				bag:SetScript("OnLeave", self.OnLeave)
				bag:SetScript("OnClick", self.OnClick)
				bag:SetScript("OnDragStart", self.OnDrag)
				bag:SetScript("OnReceiveDrag", self.OnClick)
				bag:SetScript("OnEvent", self.OnEvent)

				id = id + 1
				return bag
			end

			function Bag:Get()
				local f = next(unused)
				if f then
					unused[f] = nil
					return f
				end
				return self:New()
			end

			function Bag:Set(parent, id)
				self:SetID(id)
				self:SetParent(parent)

				if self:IsBank() or self:IsBackpack() then
					SetItemButtonTexture(self, [[Interface\Buttons\Button-Backpack-Up]])
					SetItemButtonTextureVertexColor(self, 1, 1, 1)
				else
					self:Update()

					self:RegisterEvent("ITEM_LOCK_CHANGED")
					self:RegisterEvent("CURSOR_UPDATE")
					self:RegisterEvent("BAG_UPDATE")
					self:RegisterEvent("PLAYERBANKSLOTS_CHANGED")

					if self:IsBankBagSlot() then
						self:RegisterEvent("BANKFRAME_OPENED")
						self:RegisterEvent("BANKFRAME_CLOSED")
						self:RegisterEvent("PLAYERBANKBAGSLOTS_CHANGED")
					end
				end
			end

			function Bag:Release()
				unused[self] = true

				self:SetParent(nil)
				self:Hide()
				self:UnregisterAllEvents()
				_G[self:GetName() .. "Count"]:Hide()
			end

			function Bag:OnEvent(event, ...)
				if event == "BANKFRAME_OPENED" or event == "BANKFRAME_CLOSED" then
					self:Update()
				elseif not self:IsCached() then
					if event == "ITEM_LOCK_CHANGED" then
						self:UpdateLock()
					elseif event == "CURSOR_UPDATE" then
						self:UpdateCursor()
					elseif event == "BAG_UPDATE" or event == "PLAYERBANKSLOTS_CHANGED" then
						self:Update()
					elseif event == "PLAYERBANKBAGSLOTS_CHANGED" then
						self:Update()
					end
				end
			end

			function Bag:OnClick(button)
				local link = self:GetItemInfo()
				if link and HandleModifiedItemClick(link) then
					return
				end
				if self:IsCached() then
					return
				end

				if self:IsPurchasable() then
					self:PurchaseSlot()
				elseif CursorHasItem() then
					if self:IsBackpack() then
						PutItemInBackpack()
					else
						PutItemInBag(self:GetInventorySlot())
					end
				elseif not (self:IsBackpack() or self:IsBank()) then
					self:Pickup()
				end
			end

			function Bag:OnDrag()
				if not self:IsCached() then
					self:Pickup()
				end
			end

			function Bag:OnEnter()
				if self:GetRight() > (GetScreenWidth() / 2) then
					GameTooltip:SetOwner(self, "ANCHOR_LEFT")
				else
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				end

				self:UpdateTooltip()
				self:HighlightItems()
				self:GetParent().itemFrame:HighlightBag(self:GetID())
			end

			function Bag:OnLeave()
				if GameTooltip:IsOwned(self) then
					GameTooltip:Hide()
				end
				self:ClearHighlightItems()
			end

			function Bag:OnShow()
				self:Update()
			end

			function Bag:Update()
				if not self:IsVisible() then
					return
				end

				self:UpdateLock()
				self:UpdateSlotInfo()
				self:UpdateCursor()
			end

			function Bag:UpdateLock()
				if not self:IsBagSlot() then
					return
				end
				SetItemButtonDesaturated(self, self:IsLocked())
			end

			function Bag:UpdateCursor()
				if not self:IsBagSlot() then
					return
				end

				if CursorCanGoInSlot(self:GetInventorySlot()) then
					self:LockHighlight()
				else
					self:UnlockHighlight()
				end
			end

			function Bag:UpdateSlotInfo()
				if not self:IsBagSlot() then
					return
				end

				local link, count, texture = self:GetItemInfo()
				if link then
					self.hasItem = link
					SetItemButtonTexture(self, texture or GetItemIcon(link))
					SetItemButtonTextureVertexColor(self, 1, 1, 1)
				else
					self.hasItem = nil
					SetItemButtonTexture(self, [[Interface\PaperDoll\UI-PaperDoll-Slot-Bag]])
					if self:IsPurchasable() then
						SetItemButtonTextureVertexColor(self, 1, 0.1, 0.1)
					else
						SetItemButtonTextureVertexColor(self, 1, 1, 1)
					end
				end
				self:SetCount(count)
			end

			function Bag:SetCount(count)
				local text = _G[self:GetName() .. "Count"]
				count = count or 0

				if count > 1 then
					if count > 999 then
						text:SetFormattedText("%.1fk", count / 1000)
					else
						text:SetText(count)
					end
					text:Show()
				else
					text:Hide()
				end
			end

			function Bag:Pickup()
				PlaySound("BAGMENUBUTTONPRESS")
				PickupBagFromSlot(self:GetInventorySlot())
			end

			function Bag:HighlightItems()
				self:GetParent().itemFrame:HighlightBag(self:GetID())
			end

			function Bag:ClearHighlightItems()
				self:GetParent().itemFrame:HighlightBag(nil)
			end

			--show the purchase slot dialog
			function Bag:PurchaseSlot()
				if not StaticPopupDialogs["CONFIRM_BUY_BANK_SLOT_COMBUCTOR"] then
					StaticPopupDialogs["CONFIRM_BUY_BANK_SLOT_COMBUCTOR"] = {
						text = TEXT(CONFIRM_BUY_BANK_SLOT),
						button1 = TEXT(YES),
						button2 = TEXT(NO),
						OnAccept = function(self)
							PurchaseSlot()
						end,
						OnShow = function(self)
							MoneyFrame_Update(self:GetName() .. "MoneyFrame", GetBankSlotCost(GetNumBankSlots()))
						end,
						hasMoneyFrame = 1,
						timeout = 0,
						hideOnEscape = 1
					}
				end

				PlaySound("igMainMenuOption")
				StaticPopup_Show("CONFIRM_BUY_BANK_SLOT_COMBUCTOR")
			end

			function Bag:UpdateTooltip()
				GameTooltip:ClearLines()

				if self:IsBackpack() then
					GameTooltip:SetText(BACKPACK_TOOLTIP, 1, 1, 1)
				elseif self:IsBank() then
					GameTooltip:SetText(L.Bank, 1, 1, 1)
				elseif self:IsCached() then
					self:UpdateCachedBagTooltip()
				else
					self:UpdateBagTooltip()
				end

				GameTooltip:Show()
			end

			function Bag:UpdateCachedBagTooltip()
				local link = self:GetItemInfo()
				if link then
					GameTooltip:SetHyperlink(link)
				elseif self:IsPurchasable() then
					GameTooltip:SetText(BANK_BAG_PURCHASE, 1, 1, 1)
				elseif self:IsBankBagSlot() then
					GameTooltip:SetText(BANK_BAG, 1, 1, 1)
				else
					GameTooltip:SetText(EQUIP_CONTAINER, 1, 1, 1)
				end
			end

			function Bag:UpdateBagTooltip()
				if not GameTooltip:SetInventoryItem("player", self:GetInventorySlot()) then
					if self:IsPurchasable() then
						GameTooltip:SetText(BANK_BAG_PURCHASE, 1, 1, 1)
						GameTooltip:AddLine(L.ClickToPurchase)
						SetTooltipMoney(GameTooltip, GetBankSlotCost(GetNumBankSlots()))
					else
						GameTooltip:SetText(EQUIP_CONTAINER, 1, 1, 1)
					end
				end
			end

			function Bag:GetPlayer()
				local p = self:GetParent()
				return p and p:GetPlayer() or core.name
			end

			function Bag:IsCached()
				return BagSlotInfo:IsCached(self:GetPlayer(), self:GetID())
			end
			function Bag:IsBackpack()
				return BagSlotInfo:IsBackpack(self:GetID())
			end
			function Bag:IsBank()
				return BagSlotInfo:IsBank(self:GetID())
			end
			function Bag:IsInventoryBagSlot()
				return BagSlotInfo:IsBackpackBag(self:GetID())
			end
			function Bag:IsBankBagSlot()
				return BagSlotInfo:IsBankBag(self:GetID())
			end
			function Bag:IsBagSlot()
				return self:IsInventoryBagSlot() or self:IsBankBagSlot()
			end
			function Bag:IsPurchasable()
				return BagSlotInfo:IsPurchasable(self:GetPlayer(), self:GetID())
			end
			function Bag:GetInventorySlot()
				return BagSlotInfo:ToInventorySlot(self:GetID())
			end
			function Bag:IsLocked()
				return BagSlotInfo:IsLocked(self:GetPlayer(), self:GetID())
			end

			function Bag:GetItemInfo()
				local link, count, texture = BagSlotInfo:GetItemInfo(self:GetPlayer(), self:GetID())
				return link, count, texture
			end
		end

		-- money.lua

		do
			local MoneyFrame = core:NewClass("Frame")
			mod.MoneyFrame = MoneyFrame

			local GetBackpackCurrencyInfo = GetBackpackCurrencyInfo
			local GetNumWatchedTokens = GetNumWatchedTokens
			local GetRealmName = GetRealmName
			local MoneyFrame_Update = MoneyFrame_Update
			local MouseIsOver = MouseIsOver
			local OpenCoinPickupFrame = OpenCoinPickupFrame

			function MoneyFrame:New(parent)
				local f = self:Bind(CreateFrame("Frame", parent:GetName() .. "MoneyFrame", parent, "SmallMoneyFrameTemplate"))
				f:SetScript("OnShow", self.Update)
				f:Update()

				local click = CreateFrame("Button", f:GetName() .. "Click", f)
				click:SetFrameLevel(f:GetFrameLevel() + 3)
				click:SetAllPoints(f)

				click:SetScript("OnClick", self.OnClick)
				click:SetScript("OnEnter", self.OnEnter)
				click:SetScript("OnLeave", self.OnLeave)

				return f
			end

			function MoneyFrame:Update()
				local player = self:GetParent():GetPlayer()
				if player == core.name or not BagnonDB then
					MoneyFrame_Update(self:GetName(), GetMoney())
				else
					MoneyFrame_Update(self:GetName(), BagnonDB:GetMoney(player))
				end
			end

			function MoneyFrame:OnClick()
				local parent = self:GetParent()
				local name = parent:GetName()

				if MouseIsOver(getglobal(name .. "GoldButton")) then
					OpenCoinPickupFrame(COPPER_PER_GOLD, MoneyTypeInfo[parent.moneyType].UpdateFunc(), parent)
					parent.hasPickup = 1
				elseif MouseIsOver(getglobal(name .. "SilverButton")) then
					OpenCoinPickupFrame(COPPER_PER_SILVER, MoneyTypeInfo[parent.moneyType].UpdateFunc(), parent)
					parent.hasPickup = 1
				elseif MouseIsOver(getglobal(name .. "CopperButton")) then
					OpenCoinPickupFrame(1, MoneyTypeInfo[parent.moneyType].UpdateFunc(), parent)
					parent.hasPickup = 1
				end
			end

			function MoneyFrame:OnEnter()
				GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")

				if (GetNumWatchedTokens() > 0) then
					local Num_Currs = GetNumWatchedTokens()
					if (Num_Currs > 3) then
						Num_Currs = 3
					end

					GameTooltip:AddLine(format("%s's Currencies", core.name))
					for CountVar = 1, Num_Currs, 1 do
						local Curr_Name, Curr_Amt = GetBackpackCurrencyInfo(CountVar)
						if (Curr_Name == nil) then
						else
							GameTooltip:AddDoubleLine(Curr_Name, Curr_Amt, 0, 170, 255, 255, 255, 255)
						end
					end

					GameTooltip:AddLine("\r")
				end

				local money = 0
				if BagnonDB then
					for player in BagnonDB:GetPlayers() do
						money = money + BagnonDB:GetMoney(player)
					end
				end

				GameTooltip:AddLine(format(L.TotalOnRealm, GetRealmName()))
				SetTooltipMoney(GameTooltip, money)
				GameTooltip:Show()
			end

			function MoneyFrame:OnLeave()
				GameTooltip:Hide()
			end
		end
	end

	-----------------------------------------------------------------------
	-- Filters

	do
		-- qualityFilter.lua
		do
			do
				local QualityFlags = {}
				for quality = 0, 7 do
					QualityFlags[quality] = bit.lshift(1, quality)
				end
				mod.QualityFlags = QualityFlags
			end

			local FilterButton = core:NewClass("Checkbutton")
			local SIZE = 20

			local IsModifierKeyDown = IsModifierKeyDown

			function FilterButton:Create(parent, quality, qualityFlag)
				local button = self:Bind(CreateFrame("Checkbutton", nil, parent, "UIRadioButtonTemplate"))
				button:SetWidth(SIZE)
				button:SetHeight(SIZE)
				button:SetScript("OnClick", self.OnClick)
				button:SetScript("OnEnter", self.OnEnter)
				button:SetScript("OnLeave", self.OnLeave)

				local bg = button:CreateTexture(nil, "BACKGROUND")
				bg:SetSize(SIZE / 3, SIZE / 3)
				bg:SetPoint("CENTER")

				local r, g, b = GetItemQualityColor(quality)
				bg:SetTexture(r * 1.25, g * 1.25, b * 1.25, 0.75)

				button:SetCheckedTexture(bg)
				button:GetNormalTexture():SetVertexColor(r, g, b)

				button.quality = quality
				button.qualityFlag = qualityFlag
				return button
			end

			function FilterButton:OnClick()
				local frame = self:GetParent():GetParent()
				if bit.band(frame:GetQuality(), self.qualityFlag) > 0 then
					if IsModifierKeyDown() or frame:GetQuality() == self.qualityFlag then
						frame:RemoveQuality(self.qualityFlag)
					else
						frame:SetQuality(self.qualityFlag)
					end
				elseif IsModifierKeyDown() then
					frame:AddQuality(self.qualityFlag)
				else
					frame:SetQuality(self.qualityFlag)
				end
			end

			function FilterButton:OnEnter()
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

				local quality = self.quality
				if quality then
					local r, g, b = GetItemQualityColor(quality)
					GameTooltip:SetText(_G[format("ITEM_QUALITY%d_DESC", quality)], r, g, b)
				else
					GameTooltip:SetText(ALL)
				end

				GameTooltip:Show()
			end

			function FilterButton:OnLeave()
				GameTooltip:Hide()
			end

			function FilterButton:UpdateHighlight(quality)
				self:SetChecked(bit.band(quality, self.qualityFlag) > 0)
			end

			--  QualityFilter, A group of filter buttons
			local QualityFilter = core:NewClass("Frame")
			mod.QualityFilter = QualityFilter

			function QualityFilter:New(parent)
				local f = self:Bind(CreateFrame("Frame", nil, parent))

				f:AddQualityButton(0)
				f:AddQualityButton(1)
				f:AddQualityButton(2)
				f:AddQualityButton(3)
				f:AddQualityButton(4)
				f:AddQualityButton(5, mod.QualityFlags[5] + mod.QualityFlags[6])
				f:AddQualityButton(7)

				f:SetWidth(SIZE * 6)
				f:SetHeight(SIZE)
				f:UpdateHighlight()

				return f
			end

			function QualityFilter:AddQualityButton(quality, qualityFlags)
				local button = FilterButton:Create(self, quality, qualityFlags or mod.QualityFlags[quality])
				if self.prev then
					button:SetPoint("LEFT", self.prev, "RIGHT", 1, 0)
				else
					button:SetPoint("LEFT")
				end
				self.prev = button
			end

			function QualityFilter:UpdateHighlight()
				local quality = self:GetParent():GetQuality()
				for i = 1, select("#", self:GetChildren()) do
					select(i, self:GetChildren()):UpdateHighlight(quality)
				end
			end
		end

		-- sideFilter.lua
		do
			local SideFilterButton = core:NewClass("CheckButton")
			do
				local id = 1
				function SideFilterButton:New(parent, reversed)
					local b = self:Bind(CreateFrame("CheckButton", "CombuctorSideButton" .. id, parent, "CombuctorSideTabButtonTemplate"))
					b:GetNormalTexture():SetTexCoord(0.06, 0.94, 0.06, 0.94)
					b:SetScript("OnClick", b.OnClick)
					b:SetScript("OnEnter", b.OnEnter)
					b:SetScript("OnLeave", b.OnLeave)
					b:SetReversed(reversed)

					id = id + 1
					return b
				end
			end

			function SideFilterButton:OnClick()
				self:GetParent():GetParent():SetCategory(self.set.name)
			end

			function SideFilterButton:OnEnter()
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetText(self.set.name)
				GameTooltip:Show()
			end

			function SideFilterButton:OnLeave()
				GameTooltip:Hide()
			end

			function SideFilterButton:Set(set)
				self.set = set
				self:SetNormalTexture(set.icon)
			end

			function SideFilterButton:UpdateHighlight(setName)
				self:SetChecked(self.set.name == setName)
			end

			function SideFilterButton:SetReversed(enable)
				self.reversed = enable and true or nil

				local border = _G[self:GetName() .. "Border"]

				border:ClearAllPoints()
				if self:Reversed() then
					border:SetTexCoord(1, 0, 0, 1)
					border:SetPoint("TOPRIGHT", 3, 11)
				else
					border:SetTexCoord(0, 1, 0, 1)
					border:ClearAllPoints()
					border:SetPoint("TOPLEFT", -3, 11)
				end
			end

			function SideFilterButton:Reversed()
				return self.reversed
			end

			-- Side Filter Object
			local SideFilter = core:NewClass("Frame")
			mod.SideFilter = SideFilter

			function SideFilter:New(parent, reversed)
				local f = self:Bind(CreateFrame("Frame", nil, parent))
				f.buttons = setmetatable({}, {__index = function(t, k)
					local b = SideFilterButton:New(f, f:Reversed())
					if k > 1 then
						b:SetPoint("TOPLEFT", t[k - 1], "BOTTOMLEFT", 0, -17)
					else
						if f:Reversed() then
							b:SetPoint("TOPRIGHT", parent, "TOPLEFT", 10, -80)
						else
							b:SetPoint("TOPLEFT", parent, "TOPRIGHT", -32, -65)
						end
					end

					t[k] = b
					return b
				end})

				f:SetReversed(reversed)
				return f
			end

			function SideFilter:UpdateFilters()
				local numFilters = 0
				local parent = self:GetParent()

				for _, set in mod.Set:GetParentSets() do
					if parent:HasSet(set.name) then
						numFilters = numFilters + 1
						self.buttons[numFilters]:Set(set)
					end
				end

				if numFilters > 1 then
					for i = 1, numFilters do
						self.buttons[i]:Show()
					end

					for i = numFilters + 1, #self.buttons do
						self.buttons[i]:Hide()
					end

					self:UpdateHighlight()
					self:Show()
				else
					self:Hide()
				end
			end

			function SideFilter:UpdateHighlight()
				local category = self:GetParent():GetCategory()
				for _, button in pairs(self.buttons) do
					if button:IsShown() then
						button:UpdateHighlight(category)
					end
				end
			end

			function SideFilter:Layout()
				if #self.buttons > 0 then
					local first = self.buttons[1]
					first:ClearAllPoints()

					if self:Reversed() then
						first:SetPoint("TOPRIGHT", self:GetParent(), "TOPLEFT", 10, -80)
					else
						first:SetPoint("TOPLEFT", self:GetParent(), "TOPRIGHT", -32, -65)
					end

					for i = 2, #self.buttons do
						self.buttons[i]:SetPoint("TOPLEFT", self.buttons[i - 1], "BOTTOMLEFT", 0, -17)
					end
				end
			end

			function SideFilter:SetReversed(enable)
				self.reversed = enable and true or nil
				for i, button in pairs(self.buttons) do
					button:SetReversed(enable)
				end
				self:Layout()
			end

			function SideFilter:Reversed()
				return self.reversed
			end
		end

		-- bottomFilter.lua
		do
			local BottomTab = core:NewClass("Button")

			function BottomTab:New(parent, id)
				local tab = self:Bind(CreateFrame("Button", parent:GetName() .. "Tab" .. id, parent, "CombuctorFrameTabButtonTemplate"))
				tab:SetScript("OnClick", self.OnClick)
				tab:SetID(id)
				return tab
			end

			function BottomTab:OnClick()
				local frame = self:GetParent():GetParent()
				if frame.selectedTab ~= self:GetID() then
					PlaySound("igCharacterInfoTab")
				end

				frame:SetSubCategory(self.set.name)
			end

			function BottomTab:Set(set)
				self.set = set
				if set.icon then
					self:SetFormattedText("|T%s:%d|t %s", set.icon, 16, set.name)
				else
					self:SetText(set.name)
				end

				PanelTemplates_TabResize(self, 0)
				self:GetHighlightTexture():SetWidth(self:GetTextWidth() + 30)
			end

			function BottomTab:UpdateHighlight(setName)
				if self.set.name == setName then
					PanelTemplates_SetTab(self:GetParent(), self:GetID())
				end
			end

			-- Side Filter Object
			local BottomFilter = core:NewClass("Frame")
			mod.BottomFilter = BottomFilter

			function BottomFilter:New(parent)
				local f = self:Bind(CreateFrame("Frame", parent:GetName() .. "BottomFilter", parent))
				f.buttons = setmetatable({}, {__index = function(t, k)
					local tab = BottomTab:New(f, k)
					if k > 1 then
						tab:SetPoint("LEFT", f.buttons[k - 1], "RIGHT", -16, 0)
					else
						tab:SetPoint("CENTER", parent, "BOTTOMLEFT", 60, 46)
					end

					t[k] = tab
					return tab
				end})

				return f
			end

			function BottomFilter:UpdateFilters()
				local numFilters = 0
				local parent = self:GetParent()

				for _, set in mod("Sets"):GetChildSets(parent:GetCategory()) do
					if parent:HasSubSet(set.name, set.parent) then
						numFilters = numFilters + 1
						self.buttons[numFilters]:Set(set)
					end
				end

				if numFilters > 1 then
					for i = 1, numFilters do
						self.buttons[i]:Show()
					end

					for i = numFilters + 1, #self.buttons do
						self.buttons[i]:Hide()
					end

					PanelTemplates_SetNumTabs(self, numFilters)
					self:UpdateHighlight()
					self:Show()
				else
					PanelTemplates_SetNumTabs(self, 0)
					self:Hide()
				end
				self:GetParent():UpdateClampInsets()
			end

			function BottomFilter:UpdateHighlight()
				local category = self:GetParent():GetSubCategory()

				for _, button in pairs(self.buttons) do
					if button:IsShown() then
						button:UpdateHighlight(category)
					end
				end
			end
		end
	end

	-----------------------------------------------------------------------
	-- Frame

	do
		local FrameEvents = mod:NewModule("FrameEvents")
		do
			local frames = {}

			function FrameEvents:Load()
				local CSet = mod("Sets")

				CSet:RegisterMessage(self, "COMBUCTOR_SET_ADD", "UpdateSets")
				CSet:RegisterMessage(self, "COMBUCTOR_SET_UPDATE", "UpdateSets")
				CSet:RegisterMessage(self, "COMBUCTOR_SET_REMOVE", "UpdateSets")

				CSet:RegisterMessage(self, "COMBUCTOR_CONFIG_SET_ADD", "UpdateSetConfig")
				CSet:RegisterMessage(self, "COMBUCTOR_CONFIG_SET_REMOVE", "UpdateSetConfig")

				CSet:RegisterMessage(self, "COMBUCTOR_SUBSET_ADD", "UpdateSubSets")
				CSet:RegisterMessage(self, "COMBUCTOR_SUBSET_UPDATE", "UpdateSubSets")
				CSet:RegisterMessage(self, "COMBUCTOR_SUBSET_REMOVE", "UpdateSubSets")

				CSet:RegisterMessage(self, "COMBUCTOR_CONFIG_SUBSET_ADD", "UpdateSubSetConfig")
				CSet:RegisterMessage(self, "COMBUCTOR_CONFIG_SUBSET_REMOVE", "UpdateSubSetConfig")
			end

			function FrameEvents:UpdateSets(msg, name)
				for f in self:GetFrames() do
					if f:HasSet(name) then
						f:UpdateSets()
					end
				end
			end

			function FrameEvents:UpdateSetConfig(msg, key, name)
				for f in self:GetFrames() do
					if f.key == key then
						f:UpdateSets()
					end
				end
			end

			function FrameEvents:UpdateSubSetConfig(msg, key, name, parent)
				for f in self:GetFrames() do
					if f.key == key and f:GetCategory() == parent then
						f:UpdateSubSets()
					end
				end
			end

			function FrameEvents:UpdateSubSets(msg, name, parent)
				for f in self:GetFrames() do
					if f:GetCategory() == parent then
						f:UpdateSubSets()
					end
				end
			end

			function FrameEvents:Register(f)
				frames[f] = true
			end

			function FrameEvents:Unregister(f)
				frames[f] = nil
			end

			function FrameEvents:GetFrames()
				return pairs(frames)
			end

			FrameEvents:Load()
		end

		local InventoryFrame = core:NewClass("Frame")
		mod.Frame = InventoryFrame

		local CombuctorSet = mod("Sets")

		local BASE_WIDTH = 384
		local ITEM_FRAME_WIDTH_OFFSET = 312 - BASE_WIDTH
		local BASE_HEIGHT = 512
		local ITEM_FRAME_HEIGHT_OFFSET = 346 - BASE_HEIGHT

		local lastID = 1
		function InventoryFrame:New(titleText, settings, isBank, key)
			local f = self:Bind(CreateFrame("Frame", format("CombuctorFrame%d", lastID), UIParent, "CombuctorInventoryTemplate"))
			f:SetScript("OnShow", self.OnShow)
			f:SetScript("OnHide", self.OnHide)

			f.sets = settings
			f.isBank = isBank
			f.key = key
			f.titleText = titleText

			f.bagButtons = {}
			f.filter = {quality = 0}

			f:SetWidth(settings.w or BASE_WIDTH)
			f:SetHeight(settings.h or BASE_HEIGHT)

			f.title = _G[f:GetName() .. "Title"]

			f.sideFilter = mod.SideFilter:New(f, f:IsSideFilterOnLeft())

			f.bottomFilter = mod.BottomFilter:New(f)

			f.nameFilter = _G[f:GetName() .. "Search"]

			f.qualityFilter = mod.QualityFilter:New(f)
			f.qualityFilter:SetPoint("BOTTOMLEFT", 24, 65)

			f.itemFrame = mod.ItemFrame:New(f)
			f.itemFrame:SetPoint("TOPLEFT", 24, -78)

			f.moneyFrame = mod.MoneyFrame:New(f)
			f.moneyFrame:SetPoint("BOTTOMRIGHT", -40, 67)

			f:UpdateTitleText()
			f:UpdateBagToggleHighlight()
			f:UpdateBagFrame()

			f.sideFilter:UpdateFilters()
			f:LoadPosition()
			f:UpdateClampInsets()

			lastID = lastID + 1
			tinsert(UISpecialFrames, f:GetName())
			return f
		end

		function InventoryFrame:UpdateTitleText()
			self.title:SetFormattedText(self.titleText, self:GetPlayer())
		end

		function InventoryFrame:OnTitleEnter(title)
			GameTooltip:SetOwner(title, "ANCHOR_LEFT")
			GameTooltip:SetText(title:GetText(), 1, 1, 1)
			GameTooltip:AddLine(L.MoveTip)
			GameTooltip:AddLine(L.ResetPositionTip)
			GameTooltip:Show()
		end

		function InventoryFrame:OnBagToggleClick(toggle, button)
			if button == "LeftButton" then
				_G[toggle:GetName() .. "Icon"]:SetTexCoord(0.075, 0.925, 0.075, 0.925)
				self:ToggleBagFrame()
			else
				if self.isBank then
					mod:Toggle(BACKPACK_CONTAINER)
				else
					mod:Toggle(BANK_CONTAINER)
				end
			end
		end

		function InventoryFrame:OnBagToggleEnter(toggle)
			GameTooltip:SetOwner(toggle, "ANCHOR_LEFT")
			GameTooltip:SetText(L.Bags, 1, 1, 1)
			GameTooltip:AddLine(L.BagToggle)

			if self.isBank then
				GameTooltip:AddLine(L.InventoryToggle)
			else
				GameTooltip:AddLine(L.BankToggle)
			end
			GameTooltip:Show()
		end

		function InventoryFrame:OnPortraitEnter(portrait)
			GameTooltip:SetOwner(portrait, "ANCHOR_RIGHT")
			GameTooltip:SetText(self:GetPlayer(), 1, 1, 1)
			GameTooltip:AddLine("<Left Click> to switch characters")
			GameTooltip:Show()
		end

		function InventoryFrame:ToggleBagFrame()
			self.sets.showBags = not self.sets.showBags
			self:UpdateBagToggleHighlight()
			self:UpdateBagFrame()
		end

		function InventoryFrame:UpdateBagFrame()
			for i, bag in pairs(self.bagButtons) do
				self.bagButtons[i] = nil
				bag:Release()
			end

			if self.sets.showBags then
				for _, bagID in ipairs(self.sets.bags) do
					if bagID ~= KEYRING_CONTAINER then
						local bag = mod.Bag:Get()
						bag:Set(self, bagID)
						tinsert(self.bagButtons, bag)
					end
				end

				for i, bag in ipairs(self.bagButtons) do
					bag:ClearAllPoints()
					if i > 1 then
						bag:SetPoint("TOP", self.bagButtons[i - 1], "BOTTOM", 0, -6)
					else
						bag:SetPoint("TOPRIGHT", -48, -82)
					end
					bag:Show()
				end
			end

			self:UpdateItemFrameSize()
		end

		function InventoryFrame:UpdateBagToggleHighlight()
			if self.sets.showBags then
				_G[self:GetName() .. "BagToggle"]:LockHighlight()
			else
				_G[self:GetName() .. "BagToggle"]:UnlockHighlight()
			end
		end

		function InventoryFrame:SetFilter(key, value)
			if self.filter[key] ~= value then
				self.filter[key] = value

				self.itemFrame:Regenerate()
				return true
			end
		end

		function InventoryFrame:GetFilter(key)
			return self.filter[key]
		end

		function InventoryFrame:SetPlayer(player)
			if self:GetPlayer() ~= player then
				self.player = player

				self:UpdateTitleText()
				self:UpdateBagFrame()
				self:UpdateSets()

				self.itemFrame:SetPlayer(player)
				self.moneyFrame:Update()
			end
		end

		function InventoryFrame:GetPlayer()
			return self.player or core.name
		end

		function InventoryFrame:UpdateSets(category)
			self.sideFilter:UpdateFilters()
			self:SetCategory(category or self:GetCategory())
			self:UpdateSubSets()
		end

		function InventoryFrame:UpdateSubSets(subCategory)
			self.bottomFilter:UpdateFilters()
			self:SetSubCategory(subCategory or self:GetSubCategory())
		end

		function InventoryFrame:HasSet(name)
			for i, setName in self:GetSets() do
				if setName == name then
					return true
				end
			end
			return false
		end

		function InventoryFrame:HasSubSet(name, parent)
			if self:HasSet(parent) then
				local excludeSets = self:GetExcludedSubsets(parent)
				if excludeSets then
					for _, childSet in pairs(excludeSets) do
						if childSet == name then
							return false
						end
					end
				end
				return true
			end
			return false
		end

		function InventoryFrame:GetSets()
			local profile = mod:GetProfile(self:GetPlayer()) or mod:GetProfile(core.name)
			return ipairs(profile[self.key].sets)
		end

		function InventoryFrame:GetExcludedSubsets(parent)
			local profile = mod:GetProfile(self:GetPlayer()) or mod:GetProfile(core.name)
			return profile[self.key].exclude[parent]
		end

		function InventoryFrame:SetCategory(name)
			if not (self:HasSet(name) and CombuctorSet:Get(name)) then
				name = self:GetDefaultCategory()
			end

			local set = name and CombuctorSet:Get(name)
			if self:SetFilter("rule", (set and set.rule) or nil) then
				self.category = name
				self.sideFilter:UpdateHighlight()
				self:UpdateSubSets()
			end
		end

		function InventoryFrame:GetCategory()
			return self.category or self:GetDefaultCategory()
		end

		function InventoryFrame:GetDefaultCategory()
			for _, set in CombuctorSet:GetParentSets() do
				if self:HasSet(set.name) then
					return set.name
				end
			end
		end

		function InventoryFrame:SetSubCategory(name)
			local parent = self:GetCategory()
			if not (parent and self:HasSubSet(name, parent) and CombuctorSet:Get(name, parent)) then
				name = self:GetDefaultSubCategory()
			end

			local set = name and CombuctorSet:Get(name, parent)
			if self:SetFilter("subRule", (set and set.rule) or nil) then
				self.subCategory = name
				self.bottomFilter:UpdateHighlight()
			end
		end

		function InventoryFrame:GetSubCategory()
			return self.subCategory or self:GetDefaultSubCategory()
		end

		function InventoryFrame:GetDefaultSubCategory()
			local parent = self:GetCategory()
			if parent then
				for _, set in CombuctorSet:GetChildSets(parent) do
					if self:HasSubSet(set.name, parent) then
						return set.name
					end
				end
			end
		end

		function InventoryFrame:AddQuality(quality)
			self:SetFilter("quality", self:GetFilter("quality") + quality)
			self.qualityFilter:UpdateHighlight()
		end

		function InventoryFrame:RemoveQuality(quality)
			self:SetFilter("quality", self:GetFilter("quality") - quality)
			self.qualityFilter:UpdateHighlight()
		end

		function InventoryFrame:SetQuality(quality)
			self:SetFilter("quality", quality)
			self.qualityFilter:UpdateHighlight()
		end

		function InventoryFrame:GetQuality()
			return self:GetFilter("quality") or 0
		end

		function InventoryFrame:OnSizeChanged()
			local w, h = self:GetWidth(), self:GetHeight()
			self.sets.w = w
			self.sets.h = h

			self:SizeTLTextures(w, h)
			self:SizeBLTextures(w, h)
			self:SizeTRTextures(w, h)
			self:SizeBRTextures(w, h)
			self:UpdateItemFrameSize()
		end

		function InventoryFrame:SizeTLTextures(w, h)
			local t = _G[self:GetName() .. "TLRight"]
			t:SetWidth(128 + (w - BASE_WIDTH) / 2)

			t = _G[self:GetName() .. "TLBottom"]
			t:SetHeight(128 + (h - BASE_HEIGHT) / 2)

			t = _G[self:GetName() .. "TLBottomRight"]
			t:SetWidth(128 + (w - BASE_WIDTH) / 2)
			t:SetHeight(128 + (h - BASE_HEIGHT) / 2)
		end

		function InventoryFrame:SizeBLTextures(w, h)
			local t = _G[self:GetName() .. "BLRight"]
			t:SetWidth(128 + (w - BASE_WIDTH) / 2)

			t = _G[self:GetName() .. "BLTop"]
			t:SetHeight(128 + (h - BASE_HEIGHT) / 2)

			t = _G[self:GetName() .. "BLTopRight"]
			t:SetWidth(128 + (w - BASE_WIDTH) / 2)
			t:SetHeight(128 + (h - BASE_HEIGHT) / 2)
		end

		function InventoryFrame:SizeTRTextures(w, h)
			local t = _G[self:GetName() .. "TRLeft"]
			t:SetWidth(64 + (w - BASE_WIDTH) / 2)

			t = _G[self:GetName() .. "TRBottom"]
			t:SetHeight(128 + (h - BASE_HEIGHT) / 2)

			t = _G[self:GetName() .. "TRBottomLeft"]
			t:SetWidth(64 + (w - BASE_WIDTH) / 2)
			t:SetHeight(128 + (h - BASE_HEIGHT) / 2)
		end

		function InventoryFrame:SizeBRTextures(w, h)
			local t = _G[self:GetName() .. "BRLeft"]
			t:SetWidth(64 + (w - BASE_WIDTH) / 2)

			t = _G[self:GetName() .. "BRTop"]
			t:SetHeight(128 + (h - BASE_HEIGHT) / 2)

			t = _G[self:GetName() .. "BRTopLeft"]
			t:SetWidth(64 + (w - BASE_WIDTH) / 2)
			t:SetHeight(128 + (h - BASE_HEIGHT) / 2)
		end

		function InventoryFrame:UpdateItemFrameSize()
			local prevW, prevH = self.itemFrame:GetWidth(), self.itemFrame:GetHeight()
			local newW = self:GetWidth() + ITEM_FRAME_WIDTH_OFFSET
			if next(self.bagButtons) then
				newW = newW - 36
			end

			local newH = self:GetHeight() + ITEM_FRAME_HEIGHT_OFFSET

			if not ((prevW == newW) and (prevH == newH)) then
				self.itemFrame:SetWidth(newW)
				self.itemFrame:SetHeight(newH)
				self.itemFrame:RequestLayout()
			end
		end

		function InventoryFrame:UpdateClampInsets()
			local l, r, t, b

			if self.bottomFilter:IsShown() then
				t, b = -15, 35
			else
				t, b = -15, 65
			end

			if self.sideFilter:IsShown() then
				if self.sideFilter:Reversed() then
					l, r = -20, -35
				else
					l, r = 15, 0
				end
			else
				l, r = 15, -35
			end

			self:SetClampRectInsets(l, r, t, b)
		end

		function InventoryFrame:SavePosition(point, parent, relPoint, x, y)
			if point then
				if self.sets.position then
					self.sets.position[1] = point
					self.sets.position[2] = nil
					self.sets.position[3] = relPoint
					self.sets.position[4] = x
					self.sets.position[5] = y
				else
					self.sets.position = {point, nil, relPoint, x, y}
				end
			else
				self.sets.position = nil
			end
			self:LoadPosition()
		end

		function InventoryFrame:LoadPosition()
			if self.sets.position then
				local point, parent, relPoint, x, y = unpack(self.sets.position)
				self:SetPoint(point, self:GetParent(), relPoint, x, y)
				self:SetUserPlaced(true)
			else
				self:SetUserPlaced(nil)
			end
			self:UpdateManagedPosition()
		end

		function InventoryFrame:UpdateManagedPosition()
			if self.sets.position then
				if self:GetAttribute("UIPanelLayout-enabled") then
					if self:IsShown() then
						HideUIPanel(self)
						self:SetAttribute("UIPanelLayout-defined", false)
						self:SetAttribute("UIPanelLayout-enabled", false)
						self:SetAttribute("UIPanelLayout-whileDead", false)
						self:SetAttribute("UIPanelLayout-area", nil)
						self:SetAttribute("UIPanelLayout-pushable", nil)
						ShowUIPanel(self)
					end
				end
			elseif not self:GetAttribute("UIPanelLayout-enabled") then
				self:SetAttribute("UIPanelLayout-defined", true)
				self:SetAttribute("UIPanelLayout-enabled", true)
				self:SetAttribute("UIPanelLayout-whileDead", true)
				self:SetAttribute("UIPanelLayout-area", "left")
				self:SetAttribute("UIPanelLayout-pushable", 1)

				if self:IsShown() then
					HideUIPanel(self)
					ShowUIPanel(self)
				end
			end
		end

		function InventoryFrame:OnShow()
			PlaySound("igBackPackOpen")

			FrameEvents:Register(self)
			self:UpdateSets(self:GetDefaultCategory())
		end

		function InventoryFrame:OnHide()
			PlaySound("igBackPackClose")
			FrameEvents:Unregister(self)

			if self:IsBank() and self:AtBank() then
				CloseBankFrame()
			end

			self:SetPlayer(core.name)
		end

		function InventoryFrame:ToggleFrame(auto)
			if self:IsShown() then
				self:HideFrame(auto)
			else
				self:ShowFrame(auto)
			end
		end

		function InventoryFrame:ShowFrame(auto)
			if not self:IsShown() then
				ShowUIPanel(self)
				self.autoShown = auto or nil
			end
		end

		function InventoryFrame:HideFrame(auto)
			if self:IsShown() then
				if not auto or self.autoShown then
					HideUIPanel(self)
					self.autoShown = nil
				end
			end
		end

		function InventoryFrame:SetLeftSideFilter(enable)
			self.sets.leftSideFilter = enable and true or nil
			self.sideFilter:SetReversed(enable)
		end

		function InventoryFrame:IsSideFilterOnLeft()
			return self.sets.leftSideFilter
		end

		function InventoryFrame:IsBank()
			return self.isBank
		end

		function InventoryFrame:AtBank()
			return mod("PlayerInfo"):AtBank()
		end
	end

	-----------------------------------------------------------------------
	-- Options

	do
		-- panel.lua
		do
			local Panel = core:NewClass("Frame")
			local min = math.min
			local max = math.max

			function Panel:New(name, title, subtitle, icon, parent)
				local f = self:Bind(CreateFrame("Frame", name, UIParent))
				f.name = title
				f.parent = parent

				local text = f:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
				text:SetPoint("TOPLEFT", 16, -16)
				if icon then
					text:SetFormattedText("|T%s:%d|t %s", icon, 32, title)
				else
					text:SetText(title)
				end

				local subtext = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
				subtext:SetHeight(32)
				subtext:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -8)
				subtext:SetPoint("RIGHT", f, -32, 0)
				subtext:SetNonSpaceWrap(true)
				subtext:SetJustifyH("LEFT")
				subtext:SetJustifyV("TOP")
				subtext:SetText(subtitle)

				InterfaceOptions_AddCategory(f)

				return f
			end

			function Panel:NewCheckButton(name)
				local b = CreateFrame("CheckButton", self:GetName() .. name, self, "InterfaceOptionsCheckButtonTemplate")
				_G[b:GetName() .. "Text"]:SetText(name)

				return b
			end

			function Panel:NewDropdown(name)
				local f = CreateFrame("Frame", self:GetName() .. name, self, "UIDropDownMenuTemplate")

				local text = f:CreateFontString(nil, "BACKGROUND", "GameFontNormalSmall")
				text:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 21, 0)
				text:SetText(name)

				return f
			end

			function Panel:NewButton(name, width, height)
				local b = CreateFrame("Button", self:GetName() .. name, self, "UIPanelButtonTemplate")
				b:SetText(name)
				b:SetWidth(width)
				b:SetHeight(height or width)

				return b
			end

			mod.Options = Panel:New("CombuctorOptions", "Combuctor")
		end

		-------------------------------------------------------------------------------
		-- general.lua
		--

		do
			local CombuctorSet = mod("Sets")
			local MAX_ITEMS = 13
			local height, offset = 26, 0
			local selected = {}
			local items = {}
			local profile = mod:GetProfile()
			local key = "inventory"

			local pairs = pairs
			local tinsert = table.insert
			local tremove = table.remove

			local sendMessage = function(msg, ...)
				CombuctorSet:Send(msg, ...)
			end

			local function AddSet(name)
				for _, set in pairs(DB[key].sets) do
					if set.name == name then
						return
					end
				end
				tinsert(DB[key].sets, name)
				sendMessage("COMBUCTOR_CONFIG_SET_ADD", key, name)
			end

			local function RemoveSet(name)
				for i, set in pairs(DB[key].sets) do
					if set == name then
						tremove(DB[key].sets, i)
						sendMessage("COMBUCTOR_CONFIG_SET_REMOVE", key, name)
						break
					end
				end
			end

			local function AddSubSet(name, parent)
				local info = DB[key]
				local exclude = info.exclude[parent]

				if exclude then
					for i, set in pairs(exclude) do
						if set == name then
							tremove(exclude, i)
							if #exclude < 1 then
								info.exclude[parent] = nil
							end

							sendMessage("COMBUCTOR_CONFIG_SUBSET_ADD", key, name, parent)
							break
						end
					end
				end
			end

			local function RemoveSubSet(name, parent)
				local info = DB[key]
				local exclude = info.exclude[parent]

				if exclude then
					for i, set in pairs(exclude) do
						if set == name then
							return
						end
					end
					tinsert(exclude, name)
				else
					info.exclude[parent] = {name}
				end
				sendMessage("COMBUCTOR_CONFIG_SUBSET_REMOVE", key, name, parent)
			end

			local function HasSet(name)
				local info = DB[key]

				for i, setName in pairs(info.sets) do
					if setName == name then
						return true
					end
				end
				return false
			end

			local function HasSubSet(name, parent)
				local info = DB[key]
				local exclude = info.exclude[parent]

				if exclude then
					for j, child in pairs(exclude) do
						if child == name then
							return false
						end
					end
				end
				return true
			end

			local function ListButtonCheck_OnClick(self)
				local set = self:GetParent().set
				if set.parent then
					if self:GetChecked() then
						AddSubSet(set.name, set.parent)
					else
						RemoveSubSet(set.name, set.parent)
					end
				else
					if self:GetChecked() then
						AddSet(set.name)
					else
						RemoveSet(set.name)
					end
				end
			end

			local function ListButtonToggle_OnClick(self)
				local set = self:GetParent().set

				selected[set.name] = not selected[set.name]
				self:GetParent():GetParent():UpdateList()
			end

			local function ListButton_Set(self, set)
				self.set = set

				if set.icon then
					_G[self.check:GetName() .. "Text"]:SetFormattedText("|T%s:%d|t %s", set.icon, 28, set.name)
				else
					_G[self.check:GetName() .. "Text"]:SetText(set.name)
				end

				if set.parent then
					self.toggle:Hide()
				else
					self.toggle:Show()

					if selected[set.name] then
						self.toggle:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-UP")
						self.toggle:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-DOWN")
					else
						self.toggle:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-UP")
						self.toggle:SetPushedTexture("Interface\\Buttons\\UI-PlusButton-DOWN")
					end
				end

				if set.parent then
					self.check:SetChecked(HasSubSet(set.name, set.parent))
				else
					self.check:SetChecked(HasSet(set.name))
				end
			end

			local function ListButton_Create(id, parent)
				local name = format("%sButton%d", parent:GetName(), id)
				local b = CreateFrame("Frame", name, parent)
				b:SetWidth(200)
				b:SetHeight(24)
				b.Set = ListButton_Set

				local toggle = CreateFrame("Button", nil, b)
				toggle:SetPoint("LEFT", b)
				toggle:SetWidth(14)
				toggle:SetHeight(14)
				toggle:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-UP")
				toggle:SetPushedTexture("Interface\\Buttons\\UI-PlusButton-DOWN")
				toggle:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
				toggle:SetScript("OnClick", ListButtonToggle_OnClick)
				b.toggle = toggle

				local check = CreateFrame("CheckButton", name .. "Check", b, "InterfaceOptionsCheckButtonTemplate")
				check:SetScript("OnClick", ListButtonCheck_OnClick)
				check:SetPoint("LEFT", toggle, "RIGHT", 4, 0)
				b.check = check

				return b
			end

			local function Panel_UpdateList(self)
				local items = {}

				for _, parentSet in CombuctorSet:GetParentSets() do
					tinsert(items, parentSet)
					if selected[parentSet.name] then
						for _, childSet in CombuctorSet:GetChildSets(parentSet.name) do
							tinsert(items, childSet)
						end
					end
				end

				local scrollFrame = self.scrollFrame
				local offset = FauxScrollFrame_GetOffset(scrollFrame)
				local i = 1

				while i <= MAX_ITEMS and items[i + offset] do
					local button = self.buttons[i]
					button:Set(items[i + offset])

					local offLeft = button.set.parent and 24 or 0
					button:SetPoint("TOPLEFT", 14 + offLeft, -(86 + button:GetHeight() * i))
					button:Show()

					i = i + 1
				end

				for j = i, #self.buttons do
					self.buttons[j]:Hide()
				end

				FauxScrollFrame_Update(scrollFrame, #items, MAX_ITEMS, self.buttons[1]:GetHeight())
			end

			local info = {}
			local function AddItem(text, value, func, checked, arg1)
				info.text = text
				info.func = func
				info.value = value
				info.checked = checked
				info.arg1 = arg1
				UIDropDownMenu_AddButton(info)
			end

			local function AddFrameSelector(self)
				local dd = self:NewDropdown("Frame")

				dd:SetScript("OnShow", function(self)
					UIDropDownMenu_SetWidth(self, 110)
					UIDropDownMenu_Initialize(self, self.Initialize)
					UIDropDownMenu_SetSelectedValue(self, key)
				end)

				local function Key_OnClick(self)
					key = self.value
					UIDropDownMenu_SetSelectedValue(dd, self.value)
					dd:GetParent():UpdateList()
				end

				function dd:Initialize()
					AddItem(L.Inventory, "inventory", Key_OnClick, "inventory" == key)
					AddItem(L.Bank, "bank", Key_OnClick, "bank" == key)
				end
				return dd
			end

			do
				local panel = mod.Options
				panel.UpdateList = Panel_UpdateList
				panel:SetScript("OnShow", function(self) self:UpdateList() end)
				panel:SetScript("OnHide", function(self) selected = {} end)

				local name = panel:GetName()
				local dropdown = AddFrameSelector(panel)
				dropdown:SetPoint("TOPLEFT", 6, -72)

				local scroll = CreateFrame("ScrollFrame", name .. "ScrollFrame", panel, "FauxScrollFrameTemplate")
				scroll:SetScript("OnVerticalScroll", function(self, arg1)
					FauxScrollFrame_OnVerticalScroll(self, arg1, height + offset, function() panel:UpdateList() end)
				end)
				scroll:SetPoint("TOPLEFT", 6, -92)
				scroll:SetPoint("BOTTOMRIGHT", -32, 8)
				panel.scrollFrame = scroll

				panel.buttons = setmetatable({}, {__index = function(t, k)
					t[k] = ListButton_Create(k, panel)
					return t[k]
				end
				})
			end
		end
	end
end)
BINDING_HEADER_COMBUCTOR = "|cfff58cbaK|r|caaf49141Pack|r Combuctor"
BINDING_NAME_COMBUCTOR_TOGGLE_INVENTORY = KPack.L.ToggleInventory
BINDING_NAME_COMBUCTOR_TOGGLE_BANK = KPack.L.ToggleBank