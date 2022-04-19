local core = KPack
if not core then return end
core:AddModule("Automate", "Automates some of the more tedious tasks in WoW.", function(L, folder)
	if core:IsDisabled("Automate") then return end

	local mod = core.Automate or {}
	core.Automate = mod

	local DB, CharDB
	local defaultsDB = {
		enabled = true,
		duels = false,
		gossip = false,
		junk = true,
		nameplate = false,
		repair = true,
		uiscale = false,
		camera = true,
		screenshot = false
	}
	local defaultsChar = {
		flyingmount = "",
		groundmount = "",
		sets = {}
	}

	local PLAYER_ENTERING_WORLD
	local PLAYER_REGEN_ENABLED
	local PLAYER_REGEN_DISABLED

	local chatFrame = DEFAULT_CHAT_FRAME

	local GetSpellInfo = GetSpellInfo
	local GetNumEquipmentSets = GetNumEquipmentSets
	local GetEquipmentSetInfo = GetEquipmentSetInfo
	local EquipmentManager_EquipSet = EquipmentManager_EquipSet

	-- module's print function
	local function Print(msg)
		if msg then
			core:Print(msg, "Automate")
		end
	end

	local function SetupDatabase()
		if not DB then
			if type(core.db.Automate) ~= "table" or next(core.db.Automate) == nil then
				core.db.Automate = CopyTable(defaultsDB)
			end
			DB = core.db.Automate
		end

		if not CharDB then
			if type(core.char.Automate) ~= "table" or next(core.char.Automate) == nil then
				core.char.Automate = CopyTable(defaultsChar)
			end
			CharDB = core.char.Automate
		end
	end

	do
		-- automatic ui scale
		local function Automate_UIScale()
			if DB.uiscale then
				local scalefix = CreateFrame("Frame")
				scalefix:RegisterEvent("PLAYER_LOGIN")
				scalefix:SetScript("OnEvent", function()
					SetCVar("useUiScale", 1)
					SetCVar("uiScale", 768 / string.match(({GetScreenResolutions()})[GetCurrentResolution()], "%d+x(%d+)"))
				end)
				SetCVar("screenshotQuality", SCREENSHOT_QUALITY)
			end
		end

		local function Automate_ListEquipments()
			local list = {None = NONE}
			local num = GetNumEquipmentSets()
			if num > 0 then
				for i = 1, num do
					local name, Icon, _ = GetEquipmentSetInfo(i)
					list[name] = name
				end
			end
			return list
		end

		function PLAYER_ENTERING_WORLD()
			SetupDatabase()
			if DB.enabled then
				Automate_UIScale()
				mod:AdjustCamera()
			end
		end

		local function disabled()
			return not DB.enabled
		end
		local options = {
			type = "group",
			name = "Automate",
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
				reset = {
					type = "execute",
					name = RESET,
					order = 1.1,
					confirm = function()
						return L:F("Are you sure you want to reset %s to default?", "Automate")
					end,
					func = function()
						wipe(core.db.Automate)
						wipe(core.char.Automate)
						DB = nil
						CharDB = nil
						SetupDatabase()
					end
				},
				automatic = {
					type = "group",
					name = L["Automatic Tasks"],
					order = 2,
					disabled = disabled,
					inline = true,
					args = {
						repair = {
							type = "toggle",
							name = L["Repair equipment"],
							order = 1
						},
						junk = {
							type = "toggle",
							name = L["Sell Junk"],
							order = 2
						},
						nameplate = {
							type = "toggle",
							name = L["Nameplates"],
							desc = L["Shows nameplates only in combat."],
							order = 3
						},
						duels = {
							type = "toggle",
							name = L["Cancel Duels"],
							order = 4
						},
						gossip = {
							type = "toggle",
							name = L["Skip Quest Gossip"],
							order = 5
						},
						camera = {
							type = "toggle",
							name = L["Max Camera Distance"],
							order = 6
						},
						screenshot = {
							type = "toggle",
							name = L["Achievement Screenshot"],
							order = 7
						},
						uiscale = {
							type = "toggle",
							name = L["Automatic UI Scale"],
							order = 8
						}
					}
				},
				equipment = {
					type = "group",
					name = L["Auto Equipment"],
					order = 3,
					disabled = disabled,
					inline = true,
					get = function(i)
						CharDB.sets = CharDB.sets or {}
						local index = (i[#i] == "secondaryset") and 2 or 1
						return CharDB.sets[index]
					end,
					set = function(i, val)
						local index = (i[#i] == "secondaryset") and 2 or 1
						CharDB.sets[index] = val
					end,
					args = {
						equipmenttip = {
							type = "description",
							name = L["Allows you to automatocally swap gear to the selected equipment sets when you change your spec."],
							order = 1
						},
						primaryset = {
							type = "select",
							name = L["Primary Spec"],
							order = 2,
							disabled = function()
								return GetNumEquipmentSets() == 0
							end,
							values = function()
								return Automate_ListEquipments()
							end
						},
						secondaryset = {
							type = "select",
							name = L["Secondary Spec"],
							order = 3,
							disabled = function()
								return (GetNumEquipmentSets() == 0 or GetNumTalentGroups() == 1)
							end,
							values = function()
								return Automate_ListEquipments()
							end
						}
					}
				},
				mounts = {
					type = "group",
					name = MOUNTS,
					order = 4,
					disabled = disabled,
					inline = true,
					get = function(i)
						return CharDB[i[#i]]
					end,
					set = function(i, val)
						local name = tostring(val)
						if name:find("spell:") then
							local spellid = name:match("spell:(%d+)")
							if spellid then
								name = GetSpellInfo(spellid)
							end
						end
						CharDB[i[#i]] = name or ""
					end,
					args = {
						mountstip = {
							type = "description",
							name = L["Enter the name or link the ground and flying mounts to be used using the provided keybinding."],
							order = 1,
							width = "full"
						},
						groundmount = {
							type = "input",
							name = L["Ground Mount"],
							order = 2
						},
						flyingmount = {
							type = "input",
							name = L["Flying Mount"],
							order = 3
						}
					}
				},
				more = {
					type = "header",
					name = OTHER,
					order = 13
				},
				tip1 = {
					type = "description",
					name = L["|cffffd700Alt-Click|r to buy a stack of item from merchant."],
					order = 14,
					width = "full"
				},
				tip2 = {
					type = "description",
					name = L["You can keybind raid icons on MouseOver. Check keybindings."],
					order = 15,
					width = "full"
				}
			}
		}

		core:RegisterForEvent("PLAYER_LOGIN", function()
			core.options.args.Options.args.Automate = options

			SLASH_KPACKAUTOMATE1 = "/auto"
			SLASH_KPACKAUTOMATE2 = "/automate"
			SlashCmdList["KPACKAUTOMATE"] = function()
				core:OpenConfig("Options", "Automate")
			end
		end)
		core:RegisterForEvent("PLAYER_ENTERING_WORLD", PLAYER_ENTERING_WORLD)
	end

	-- ///////////////////////////////////////////////////////
	-- Ignore Duels
	-- ///////////////////////////////////////////////////////

	core:RegisterForEvent("DUEL_REQUESTED", function()
		if DB.enabled and DB.duels then
			CancelDuel()
			StaticPopup_Hide("DUEL_REQUESTED")
		end
	end)

	-- ///////////////////////////////////////////////////////
	-- Skip Gossip
	-- ///////////////////////////////////////////////////////

	do
		local function Automate_SkipGossip()
			if not DB.enabled or not DB.gossip then
				return
			end
			if (GetNumGossipActiveQuests() + GetNumGossipAvailableQuests()) == 0 and GetNumGossipOptions() == 1 then
				SelectGossipOption(1)
			end
			for i = 1, GetNumGossipActiveQuests() do
				if select(i * 4, GetGossipActiveQuests(i)) == 1 then
					SelectGossipActiveQuest(i)
				end
			end
		end
		core:RegisterForEvent("GOSSIP_SHOW", Automate_SkipGossip)
		core:RegisterForEvent("QUEST_GREETING", Automate_SkipGossip)
	end

	-- ///////////////////////////////////////////////////////
	-- Auto Nameplates
	-- ///////////////////////////////////////////////////////

	function PLAYER_REGEN_ENABLED()
		if DB.enabled then
			if DB.nameplate then
				SetCVar("nameplateShowEnemies", 0)
				_G.NAMEPLATES_ON = false
			end
			if DB.camera then
				mod:AdjustCamera()
			end
		end
	end
	core:RegisterForEvent("PLAYER_REGEN_ENABLED", PLAYER_REGEN_ENABLED)

	function PLAYER_REGEN_DISABLED()
		if DB.enabled and DB.nameplate then
			SetCVar("nameplateShowEnemies", 1)
			_G.NAMEPLATES_ON = true
		end
	end
	core:RegisterForEvent("PLAYER_REGEN_DISABLED", PLAYER_REGEN_DISABLED)

	-- ///////////////////////////////////////////////////////
	-- Auto Repair, Auto Sell Junk and Stack Buying
	-- ///////////////////////////////////////////////////////

	do
		-- handles auto selling junk
		local function Automate_SellJunk()
			if DB.junk then
				local i = 0

				for bag = 0, 4 do
					for slot = 0, GetContainerNumSlots(bag) do
						local link = GetContainerItemLink(bag, slot)
						if link and select(3, GetItemInfo(link)) == 0 then
							ShowMerchantSellCursor(1)
							UseContainerItem(bag, slot)
							i = i + 1
						end
					end
				end

				if i > 0 then
					core:PrintSys(L:F("You have successfully sold %d grey items.", i))
				end
			end
		end

		-- handles auto repair
		local function Automate_Repair()
			if DB.repair and CanMerchantRepair() == 1 then
				local cost, needed = GetRepairAllCost()
				if needed then
					local guildWithdraw = GetGuildBankWithdrawMoney()
					local useGuild = CanGuildBankRepair() and (guildWithdraw > cost or guildWithdraw == -1)
					if useGuild then
						RepairAllItems(1)
						local vCopper = cost % 100
						local vSilver = floor((cost % 10000) / 100)
						local vGold = floor(cost / 100000)
						core:PrintSys(L:F("Repair cost covered by Guild Bank: %dg %ds %dc.", tostring(vGold), tostring(vSilver), tostring(vCopper)))
					elseif cost < GetMoney() then
						RepairAllItems()
						local vCopper = cost % 100
						local vSilver = floor((cost % 10000) / 100)
						local vGold = floor(cost / 100000)
						core:PrintSys(L:F("Your items have been repaired for %dg %ds %dc.", tostring(vGold), tostring(vSilver), tostring(vCopper)))
					else
						core:PrintSys(L["You don't have enough money to repair items!"])
					end
				end
			end
		end

		core:RegisterForEvent("MERCHANT_SHOW", function()
			if DB.enabled then
				Automate_Repair()
				Automate_SellJunk()
			end
		end)

		-- replace default action so we can buy stack
		local Old_MerchantItemButton_OnModifiedClick = _G.MerchantItemButton_OnModifiedClick
		_G.MerchantItemButton_OnModifiedClick = function(self, ...)
			if IsAltKeyDown() then
				local maxStack = select(8, GetItemInfo(GetMerchantItemLink(this:GetID())))
				local _, _, _, quantity, _, _, _ = GetMerchantItemInfo(this:GetID())
				if maxStack and maxStack > 1 then
					BuyMerchantItem(this:GetID(), floor(maxStack / quantity))
				end
			end
			Old_MerchantItemButton_OnModifiedClick(self, ...)
		end
	end

	-- ///////////////////////////////////////////////////////
	-- Automatic Screenshot
	-- ///////////////////////////////////////////////////////

	function mod:AdjustCamera()
		if DB.camera and not InCombatLockdown() then
			SetCVar("cameraDistanceMaxFactor", "2.6")
			SetCVar("cameraDistanceMax", 50)
			MoveViewOutStart(50000)
		end
	end

	-- ///////////////////////////////////////////////////////
	-- Trainer Button
	-- ///////////////////////////////////////////////////////

	do
		local button, locked
		local skillsToLearn, skillsLearned
		local process

		local function Automate_TrainReset()
			button:SetScript("OnUpdate", nil)
			locked = nil
			skillsLearned = nil
			skillsToLearn = nil
			process = nil
			button.delay = nil
		end

		local function Automate_TrainAll_OnUpdate(self, elapsed)
			self.delay = self.delay - elapsed
			if self.delay <= 0 then
				Automate_TrainReset()
			end
		end

		local function Automate_TrainAll()
			locked = true
			button:Disable()

			local j, cost = 0
			local money = GetMoney()

			for i = 1, GetNumTrainerServices() do
				if select(3, GetTrainerServiceInfo(i)) == "available" then
					j = j + 1
					cost = GetTrainerServiceCost(i)
					if money >= cost then
						money = money - cost
						BuyTrainerService(i)
					else
						Automate_TrainReset()
						return
					end
				end
			end

			if j > 0 then
				skillsToLearn = j
				skillsLearned = 0

				process = true
				button.delay = 1
				button:SetScript("OnUpdate", Automate_TrainAll_OnUpdate)
			else
				Automate_TrainReset()
			end
		end

		core:RegisterForEvent("TRAINER_UPDATE", function()
			if not DB.enabled or not process then return end

			skillsLearned = skillsLearned + 1

			if skillsLearned >= skillsToLearn then
				Automate_TrainReset()
				Automate_TrainAll()
			else
				button.delay = 1
			end
		end)

		function mod:TrainButtonCreate()
			if button then return end
			button = CreateFrame("Button", "KPackTrainAllButton", ClassTrainerFrame, "KPackButtonTemplate")
			button:SetSize(80, 18)
			button:SetFormattedText("%s %s", TRAIN, ALL)
			button:SetPoint("RIGHT", ClassTrainerFrameCloseButton, "LEFT", 1, 0)
			button:SetScript("OnClick", function() Automate_TrainAll() end)
		end

		function mod:TrainButtonUpdate()
			if locked then return end

			for i = 1, GetNumTrainerServices() do
				if select(3, GetTrainerServiceInfo(i)) == "available" then
					button:Enable()
					return
				end
			end

			button:Disable()
		end
	end

	-- ///////////////////////////////////////////////////////
	-- Auto Equipment Set
	-- ///////////////////////////////////////////////////////

	core:RegisterForEvent("ACTIVE_TALENT_GROUP_CHANGED", function(_, index)
		SetupDatabase()
		if not DB.enabled or not index or GetNumEquipmentSets() == 0 then
			return
		end
		CharDB.sets = CharDB.sets or {}
		local setname = CharDB.sets[index]

		if setname and setname ~= "None" then
			EquipmentManager_EquipSet(setname)
			core:Notify(L:F("Changed equipment set to |cffffd700%s|r", setname))
		end
	end)

	-- ///////////////////////////////////////////////////////
	-- Auto Mount Up
	-- ///////////////////////////////////////////////////////

	do
		local IsMounted = IsMounted
		local CanExitVehicle = CanExitVehicle
		local VehicleExit = VehicleExit
		local IsFlyableArea = IsFlyableArea
		local IsControlKeyDown = IsControlKeyDown
		local GetNumCompanions = GetNumCompanions
		local GetCompanionInfo = GetCompanionInfo
		local CallCompanion = CallCompanion

		local function Automate_MountUp(ground, flying)
			if not DB.enabled then
				return
			end
			ground = ground or CharDB.groundmount
			flying = flying or CharDB.flyingmount
			if not flying or flying == "" then
				flying = ground
			end
			if (not ground or ground == "") and (not flying or flying == "") then
				return
			end

			local num = GetNumCompanions("MOUNT")
			if not num or IsMounted() then
				Dismount()
				return
			end

			if CanExitVehicle() then
				VehicleExit()
				return
			end

			local flyable, nofly

			if IsUsableSpell(59569) ~= true then
				nofly = true
			end

			flyable = IsFlyableArea()
			if not nofly and IsFlyableArea() then
				flyable = true
			end

			if IsControlKeyDown() then
				flyable = not flyable
			end

			for i = 1, num, 1 do
				local _, info = GetCompanionInfo("MOUNT", i)
				if flying and info == flying and flyable then
					CallCompanion("MOUNT", i)
					return
				elseif ground and info == ground and not flyable then
					CallCompanion("MOUNT", i)
					return
				end
			end
		end
		core.Mount = Automate_MountUp
	end

	-- ///////////////////////////////////////////////////////
	-- Automatic Screenshot
	-- ///////////////////////////////////////////////////////

	core:RegisterForEvent("ACHIEVEMENT_EARNED", function()
		if DB.enabled and DB.screenshot then
			core.After(1, function() Screenshot() end)
		end
	end)

	-- ///////////////////////////////////////////////////////

	core:RegisterForEvent("ADDON_LOADED", function(_, name)
		if name == folder then
			SetupDatabase()
		elseif name == "Blizzard_TrainerUI" then
			SetupDatabase()
			if DB.enabled then
				mod:TrainButtonCreate()
				hooksecurefunc("ClassTrainerFrame_Update", mod.TrainButtonUpdate)
			end
		end
	end)
end)
BINDING_HEADER_KPACKAUTOMATE = "|cfff58cbaK|r|caaf49141Pack|r Automate"
BINDING_NAME_KPACKAUTOMATE_1 = "MouseOver: " .. RAID_TARGET_1
BINDING_NAME_KPACKAUTOMATE_2 = "MouseOver: " .. RAID_TARGET_2
BINDING_NAME_KPACKAUTOMATE_3 = "MouseOver: " .. RAID_TARGET_3
BINDING_NAME_KPACKAUTOMATE_4 = "MouseOver: " .. RAID_TARGET_4
BINDING_NAME_KPACKAUTOMATE_5 = "MouseOver: " .. RAID_TARGET_5
BINDING_NAME_KPACKAUTOMATE_6 = "MouseOver: " .. RAID_TARGET_6
BINDING_NAME_KPACKAUTOMATE_7 = "MouseOver: " .. RAID_TARGET_7
BINDING_NAME_KPACKAUTOMATE_8 = "MouseOver: " .. RAID_TARGET_8
BINDING_NAME_KPACKAUTOMATE_0 = KPack.L["Remove Icon"]
BINDING_NAME_KPACKAUTOMATEMOUNT = KPack.L["Auto Mount/Dismount"]