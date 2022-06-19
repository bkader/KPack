local core = KPack
if not core then return end
core:AddModule("RaidUtility", "|cff00ff00/mana, /healersmana\n/invites\n/sunder\n/auras\n/rcd|r", function(L)
	if core:IsDisabled("RaidUtility") or _G.KRU then return end

	local mod = core.RaidUtility or {}
	core.RaidUtility = mod
	mod.options = {
		type = "group",
		name = L["Raid Utility"],
		args = {}
	}

	local pairs, ipairs, select = pairs, ipairs, select
	local tinsert, tremove, tsort = table.insert, table.remove, table.sort
	local strformat, strfind, strlower, strlen = string.format, string.find, string.lower, string.len
	local CreateFrame = CreateFrame
	local GetNumRaidMembers = GetNumRaidMembers
	local GetNumPartyMembers = GetNumPartyMembers
	local GetSpellInfo = GetSpellInfo
	local UnitExists, UnitIsPlayer, UnitIsFriend = UnitExists, UnitIsPlayer, UnitIsFriend
	local UnitName, UnitGUID, UnitClass = UnitName, UnitGUID, UnitClass
	local UnitIsDeadOrGhost, UnitIsConnected = UnitIsDeadOrGhost, UnitIsConnected
	local UnitInParty, UnitIsPartyLeader, IsPartyLeader = UnitInParty, UnitIsPartyLeader, IsPartyLeader
	local UnitInRaid, UnitIsRaidOfficer, IsRaidOfficer, IsRaidLeader = UnitInRaid, UnitIsRaidOfficer, IsRaidOfficer, IsRaidLeader
	local UnitPower, UnitPowerMax, UnitBuff = UnitPower, UnitPowerMax, UnitBuff

	local DB, SetupDatabase, _
	local defaults, order = {}, 1
	local CreateRaidUtilityPanel = core.Noop

	-- common functions

	local function Print(msg)
		if msg then
			core:Print(msg, "RaidUtility")
		end
	end

	local function CheckUnit(unit)
		return (unit and (UnitInParty(unit) or UnitInRaid(unit)) and UnitIsPlayer(unit) and
			UnitIsFriend("player", unit))
	end

	local function ResetDatabase(dst, src)
		if type(dst) ~= "table" then return end
		for k, v in pairs(src) do
			if type(v) == "table" then
				ResetDatabase(dst[k], v)
			else
				dst[k] = v
			end
		end
	end

	function mod:InGroup()
		return (GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0)
	end

	function mod:IsPromoted(name)
		name = name or "player"
		if (name == "player" or name == core.name) and UnitInRaid("player") then
			return IsRaidLeader() or UnitIsRaidOfficer("player")
		elseif UnitInRaid(name) then
			return UnitIsRaidOfficer(name), "raid"
		elseif UnitInParty(name) then
			return UnitIsPartyLeader(name), "party"
		end
	end

	---------------------------------------------------------------------------
	-- Raid Menu

	if not core.ElvUI then
		local InCombatLockdown = InCombatLockdown
		local DoReadyCheck = DoReadyCheck
		local ToggleFriendsFrame = ToggleFriendsFrame

		local GetRaidRosterInfo = GetRaidRosterInfo
		local UninviteUnit = UninviteUnit

		local RaidUtilityPanel
		local showButton

		-- defaults
		defaults.Menu = {
			enabled = true,
			locked = false,
			point = "TOP",
			xOfs = -400,
			yOfs = 1
		}

		local function CheckRaidStatus()
			local inInstance, instanceType = IsInInstance()
			if (((IsRaidLeader() or IsRaidOfficer()) and GetNumRaidMembers() > 0) or (IsPartyLeader() and GetNumPartyMembers() > 0)) and not (inInstance and (instanceType == "pvp" or instanceType == "arena")) then
				return true
			else
				return false
			end
		end

		function CreateRaidUtilityPanel()
			SetupDatabase()
			if not DB.Menu.enabled or RaidUtilityPanel then
				return
			end
			RaidUtilityPanel = CreateFrame("Frame", "KPackRaidControlPanel", UIParent, "SecureHandlerClickTemplate")
			RaidUtilityPanel:SetBackdrop({
				bgFile = [[Interface\DialogFrame\UI-DialogBox-Background-Dark]],
				edgeFile = [[Interface\DialogFrame\UI-DialogBox-Border]],
				edgeSize = 8,
				insets = {left = 1, right = 1, top = 1, bottom = 1}
			})
			RaidUtilityPanel:SetBackdropColor(0, 0, 1, 0.85)
			RaidUtilityPanel:SetSize(230, 112)
			RaidUtilityPanel:SetPoint("TOP", UIParent, "TOP", -400, 1)
			RaidUtilityPanel:SetFrameLevel(3)
			RaidUtilityPanel:SetFrameStrata("HIGH")

			showButton = CreateFrame("Button", "KPackRaidControl_ShowButton", UIParent, "KPackButtonTemplate, SecureHandlerClickTemplate")
			showButton:SetSize(136, 20)
			showButton:SetPoint(DB.Menu.point or "TOP", UIParent, DB.Menu.point or "TOP", DB.Menu.xOfs or -400, DB.Menu.yOfs or 0)
			showButton:SetText(RAID_CONTROL)
			showButton:SetFrameRef("KPackRaidControlPanel", RaidUtilityPanel)
			showButton:SetAttribute("_onclick", [=[
				local raidUtil = self:GetFrameRef("KPackRaidControlPanel")
				local closeBtn = raidUtil:GetFrameRef("KPackRaidControl_CloseButton")
				self:Hide()
				raidUtil:Show()

				local point = self:GetPoint()
				local raidUtilPoint, closeBtnPoint, yOffset
				if string.find(point, "BOTTOM") then
					raidUtilPoint, closeBtnPoint, yOffset = "BOTTOM", "TOP", 2
				else
					raidUtilPoint, closeBtnPoint, yOffset = "TOP", "BOTTOM", -2
				end

				raidUtil:ClearAllPoints()
				raidUtil:SetPoint(raidUtilPoint, self, raidUtilPoint)

				closeBtn:ClearAllPoints()
				closeBtn:SetPoint(raidUtilPoint, raidUtil, closeBtnPoint, 0, yOffset)
			]=])
			showButton:SetScript("OnMouseUp", function(self) RaidUtilityPanel.toggled = true end)
			showButton:SetMovable(true)
			showButton:SetClampedToScreen(true)
			showButton:SetClampRectInsets(0, 0, -1, 1)
			showButton:RegisterForDrag("RightButton")
			showButton:SetFrameStrata("HIGH")
			showButton:SetScript("OnDragStart", function(self)
				if InCombatLockdown() then
					Print(ERR_NOT_IN_COMBAT)
					return
				elseif DB.Menu.locked then
					return
				end
				self.moving = true
				self:StartMoving()
			end)

			showButton:SetScript("OnDragStop", function(self)
				if self.moving then
					self.moving = nil
					self:StopMovingOrSizing()
					local point = self:GetPoint()
					local xOffset = self:GetCenter()
					local screenWidth = UIParent:GetWidth() / 2
					xOffset = xOffset - screenWidth
					self:ClearAllPoints()
					if strfind(point, "BOTTOM") then
						self:SetPoint("BOTTOM", UIParent, "BOTTOM", xOffset, -1)
					else
						self:SetPoint("TOP", UIParent, "TOP", xOffset, 1)
					end
					DB.Menu.point, _, _, DB.Menu.xOfs, DB.Menu.yOfs = self:GetPoint(1)
				end
			end)

			local close = CreateFrame("Button", "KPackRaidControl_CloseButton", RaidUtilityPanel, "KPackButtonTemplate, SecureHandlerClickTemplate")
			close:SetSize(136, 20)
			close:SetPoint("TOP", RaidUtilityPanel, "BOTTOM", 0, -1)
			close:SetText(CLOSE)
			close:SetFrameRef("KPackRaidControl_ShowButton", showButton)
			close:SetAttribute("_onclick", [=[self:GetParent():Hide(); self:GetFrameRef("KPackRaidControl_ShowButton"):Show();]=])
			close:SetScript("OnMouseUp", function(self) RaidUtilityPanel.toggled = nil end)
			RaidUtilityPanel:SetFrameRef("KPackRaidControl_CloseButton", close)

			local disband = CreateFrame("Button", nil, RaidUtilityPanel, "KPackButtonTemplate, SecureActionButtonTemplate")
			disband:SetSize(200, 20)
			disband:SetPoint("TOP", RaidUtilityPanel, "TOP", 0, -8)
			disband:SetText(L["Disband Group"])
			disband:SetScript("OnMouseUp", function()
				if CheckRaidStatus() then
					StaticPopup_Show("DISBAND_RAID")
				end
			end)

			local maintank = CreateFrame("Button", nil, RaidUtilityPanel, "KPackButtonTemplate, SecureActionButtonTemplate")
			maintank:SetSize(95, 20)
			maintank:SetPoint("TOPLEFT", disband, "BOTTOMLEFT", 0, -5)
			maintank:SetText(MAINTANK)
			maintank:SetAttribute("type", "maintank")
			maintank:SetAttribute("unit", "target")
			maintank:SetAttribute("action", "toggle")

			local offtank = CreateFrame("Button", nil, RaidUtilityPanel, "KPackButtonTemplate, SecureActionButtonTemplate")
			offtank:SetSize(95, 20)
			offtank:SetPoint("TOPRIGHT", disband, "BOTTOMRIGHT", 0, -5)
			offtank:SetText(MAINASSIST)
			offtank:SetAttribute("type", "mainassist")
			offtank:SetAttribute("unit", "target")
			offtank:SetAttribute("action", "toggle")

			local ready = CreateFrame("Button", nil, RaidUtilityPanel, "KPackButtonTemplate, SecureActionButtonTemplate")
			ready:SetSize(200, 20)
			ready:SetPoint("TOPLEFT", maintank, "BOTTOMLEFT", 0, -5)
			ready:SetText(READY_CHECK)
			ready:SetScript("OnMouseUp", function()
				if CheckRaidStatus() then
					DoReadyCheck()
				end
			end)

			local control = CreateFrame("Button", nil, RaidUtilityPanel, "KPackButtonTemplate, SecureActionButtonTemplate")
			control:SetSize(95, 20)
			control:SetPoint("TOPLEFT", ready, "BOTTOMLEFT", 0, -5)
			control:SetText(L["Raid Menu"])
			control:SetScript("OnMouseUp", function()
				if InCombatLockdown() then
					Print(ERR_NOT_IN_COMBAT)
					return
				end
				ToggleFriendsFrame(5)
			end)
			RaidUtilityPanel.control = control

			local convert = CreateFrame("Button", nil, RaidUtilityPanel, "SecureHandlerClickTemplate, KPackButtonTemplate")
			convert:SetSize(95, 20)
			convert:SetPoint("TOPRIGHT", ready, "BOTTOMRIGHT", 0, -5)
			convert:SetText(CONVERT_TO_RAID)
			convert:SetScript("OnMouseUp", function()
				if CheckRaidStatus() then
					ConvertToRaid()
					SetLootMethod("master", "player")
				end
			end)
			RaidUtilityPanel.convert = convert
		end

		function mod:RaidUtilityToggle()
			if not DB.Menu.enabled then
				if KPackRaidControlPanel then
					KPackRaidControlPanel:Hide()
					if KPackRaidControl_ShowButton then
						KPackRaidControl_ShowButton:Hide()
					end
				end
				return
			end

			CreateRaidUtilityPanel()

			if GetNumRaidMembers() == 0 and GetNumPartyMembers() > 0 and IsPartyLeader() then
				RaidUtilityPanel.control:SetWidth(95)
				RaidUtilityPanel.convert:Show()
			else
				RaidUtilityPanel.control:SetWidth(200)
				RaidUtilityPanel.convert:Hide()
			end

			if InCombatLockdown() then
				return
			end

			if CheckRaidStatus() then
				if RaidUtilityPanel.toggled == true then
					RaidUtilityPanel:Show()
					showButton:Hide()
				else
					RaidUtilityPanel:Hide()
					showButton:Show()
				end
			else
				RaidUtilityPanel:Hide()
				showButton:Hide()
			end
		end
		core:RegisterForEvent("PLAYER_ENTERING_WORLD", mod.RaidUtilityToggle)
		core:RegisterForEvent("RAID_ROSTER_UPDATE", mod.RaidUtilityToggle)
		core:RegisterForEvent("PARTY_MEMBERS_CHANGED", mod.RaidUtilityToggle)
		core:RegisterForEvent("PLAYER_REGEN_ENABLED", mod.RaidUtilityToggle)

		StaticPopupDialogs.DISBAND_RAID = {
			text = L["Are you sure you want to disband the group?"],
			button1 = ACCEPT,
			button2 = CANCEL,
			OnAccept = function()
				if InCombatLockdown() then
					return
				end
				local numRaid = GetNumRaidMembers()
				if numRaid > 0 then
					for i = 1, numRaid do
						local name, _, _, _, _, _, _, online = GetRaidRosterInfo(i)
						if online and name ~= core.name then
							UninviteUnit(name)
						end
					end
				else
					for i = MAX_PARTY_MEMBERS, 1, -1 do
						if GetPartyMember(i) then
							UninviteUnit(UnitName("party" .. i))
						end
					end
				end
			end,
			timeout = 0,
			whileDead = 1,
			hideOnEscape = 1,
			preferredIndex = 3
		}

		mod.options.args.Control = {
			type = "group",
			name = RAID_CONTROL,
			order = order,
			get = function(i)
				return DB.Menu[i[#i]]
			end,
			set = function(i, val)
				DB.Menu[i[#i]] = val
				mod:RaidUtilityToggle()
			end,
			args = {
				enabled = {
					type = "toggle",
					name = L["Enable"],
					order = 1
				},
				locked = {
					type = "toggle",
					name = L["Lock"],
					order = 2
				}
			}
		}
		order = order + 1
	end

	---------------------------------------------------------------------------
	-- Loot Method

	do
		local HandleLootMethod
		defaults.Loot = {
			enabled = false,
			party = {
				enabled = true,
				method = "group",
				threshold = 2,
				master = ""
			},
			raid = {
				enabled = true,
				method = "master",
				threshold = 2,
				master = ""
			}
		}

		mod.options.args.Loot = {
			type = "group",
			name = LOOT_METHOD,
			order = order,
			args = {
				enabled = {
					type = "toggle",
					name = L["Enable"],
					order = 1,
					get = function()
						return DB.Loot.enabled
					end,
					set = function(_, val)
						DB.Loot.enabled = val
						HandleLootMethod()
					end
				},
				party = {
					type = "group",
					name = PARTY,
					order = 2,
					inline = true,
					disabled = function()
						return not DB.Loot.enabled
					end,
					get = function(i)
						return DB.Loot.party[i[#i]]
					end,
					set = function(i, val)
						DB.Loot.party[i[#i]] = val
					end,
					args = {
						enabled = {
							type = "toggle",
							name = L["Enable"],
							order = 1,
							width = "double"
						},
						method = {
							type = "select",
							name = LOOT_METHOD,
							order = 2,
							disabled = function()
								return not (DB.Loot.enabled and DB.Loot.party.enabled)
							end,
							values = {
								needbeforegreed = LOOT_NEED_BEFORE_GREED,
								freeforall = LOOT_FREE_FOR_ALL,
								roundrobin = LOOT_ROUND_ROBIN,
								master = LOOT_MASTER_LOOTER,
								group = LOOT_GROUP_LOOT
							}
						},
						threshold = {
							type = "select",
							name = LOOT_THRESHOLD,
							order = 3,
							disabled = function()
								return not (DB.Loot.enabled and DB.Loot.party.enabled)
							end,
							values = {
								[2] = "|cff1eff00" .. ITEM_QUALITY2_DESC .. "|r",
								[3] = "|cff0070dd" .. ITEM_QUALITY3_DESC .. "|r",
								[4] = "|cffa335ee" .. ITEM_QUALITY4_DESC .. "|r",
								[5] = "|cffff8000" .. ITEM_QUALITY5_DESC .. "|r",
								[6] = "|cffe6cc80" .. ITEM_QUALITY6_DESC .. "|r"
							}
						}
					}
				},
				raid = {
					type = "group",
					name = RAID,
					order = 3,
					inline = true,
					disabled = function()
						return not DB.Loot.enabled
					end,
					get = function(i)
						return DB.Loot.raid[i[#i]]
					end,
					set = function(i, val)
						DB.Loot.raid[i[#i]] = val
					end,
					args = {
						enabled = {
							type = "toggle",
							name = L["Enable"],
							order = 1,
							width = "double"
						},
						method = {
							type = "select",
							name = LOOT_METHOD,
							order = 2,
							disabled = function()
								return not (DB.Loot.enabled and DB.Loot.raid.enabled)
							end,
							values = {
								needbeforegreed = LOOT_NEED_BEFORE_GREED,
								freeforall = LOOT_FREE_FOR_ALL,
								roundrobin = LOOT_ROUND_ROBIN,
								master = LOOT_MASTER_LOOTER,
								group = LOOT_GROUP_LOOT
							}
						},
						threshold = {
							type = "select",
							name = LOOT_THRESHOLD,
							order = 3,
							disabled = function()
								return not (DB.Loot.enabled and DB.Loot.raid.enabled)
							end,
							values = {
								[2] = "|cff1eff00" .. ITEM_QUALITY2_DESC .. "|r",
								[3] = "|cff0070dd" .. ITEM_QUALITY3_DESC .. "|r",
								[4] = "|cffa335ee" .. ITEM_QUALITY4_DESC .. "|r",
								[5] = "|cffff8000" .. ITEM_QUALITY5_DESC .. "|r",
								[6] = "|cffe6cc80" .. ITEM_QUALITY6_DESC .. "|r"
							}
						}
					}
				},
				reset = {
					type = "execute",
					name = RESET,
					order = 99,
					width = "double",
					confirm = function()
						return L:F("Are you sure you want to reset %s to default?", LOOT_METHOD)
					end,
					func = function()
						ResetDatabase(DB.Loot, defaults.Loot)
					end
				}
			}
		}
		order = order + 1

		local frame = CreateFrame("Frame")
		frame:Hide()
		frame:SetScript("OnUpdate", function(self, elapsed)
			self.elapsed = (self.elapsed or 0) + elapsed
			if self.elapsed >= 3 then
				SetLootThreshold(self.threshold)
				self:Hide()
			end
		end)

		function HandleLootMethod()
			if not DB.Loot.enabled then
				return
			end
			local ranked, key = mod:IsPromoted()
			if not ranked or not key then
				return
			end
			if not DB.Loot[key].enabled then
				return
			end

			if IsRaidLeader() or IsPartyLeader() then
				local method = DB.Loot[key].method
				local threshold = DB.Loot[key].threshold

				local current = GetLootMethod()
				if current and current == method then
					-- the threshold was changed, so we make sure to change it.
					if threshold ~= GetLootThreshold() then
						frame.threshold = threshold
						frame.elapsed = 0
						frame:Show()
					end
					return
				end
				SetLootMethod(method, core.name, threshold)

				if method == "master" or method == "group" then
					frame.threshold = threshold
					frame.elapsed = 0
					frame:Show()
				end
			end
		end

		core:RegisterForEvent("PLAYER_ENTERING_WORLD", HandleLootMethod)
		core:RegisterForEvent("PARTY_CONVERTED_TO_RAID", HandleLootMethod)
	end

	---------------------------------------------------------------------------
	-- Paladin Auras

	do
		-- paladin auras
		local aurasOrder, spellIcons
		local testAuras, testMode
		local auraMastery = GetSpellInfo(31821)
		do
			local auraDevotion = GetSpellInfo(48942)
			local auraRetribution = GetSpellInfo(54043)
			local auraConcentration = GetSpellInfo(19746)
			local auraShadow = GetSpellInfo(48943)
			local auraFrost = GetSpellInfo(48945)
			local auraFire = GetSpellInfo(48947)
			local auraCrusader = GetSpellInfo(32223)

			aurasOrder = {
				[auraDevotion] = 1,
				[auraRetribution] = 2,
				[auraConcentration] = 3,
				[auraShadow] = 4,
				[auraFrost] = 5,
				[auraFire] = 6,
				[auraCrusader] = 7
			}

			spellIcons = {
				[auraDevotion] = "Interface\\Icons\\Spell_Holy_DevotionAura",
				[auraRetribution] = "Interface\\Icons\\Spell_Holy_AuraOfLight",
				[auraConcentration] = "Interface\\Icons\\Spell_Holy_MindSooth",
				[auraShadow] = "Interface\\Icons\\Spell_Shadow_SealOfKings",
				[auraFrost] = "Interface\\Icons\\Spell_Frost_WizardMark",
				[auraFire] = "Interface\\Icons\\Spell_Fire_SealOfFire",
				[auraCrusader] = "Interface\\Icons\\Spell_Holy_CrusaderAura"
			}

			testAuras = {
				[auraDevotion] = auraDevotion,
				[auraRetribution] = auraRetribution,
				[auraConcentration] = auraConcentration,
				[auraShadow] = auraShadow,
				[auraFrost] = auraFrost,
				[auraFire] = auraFire,
				[auraCrusader] = auraCrusader
			}
		end

		-- defaults
		defaults.Auras = {
			enabled = false,
			locked = false,
			updateInterval = 0.25,
			hideTitle = false,
			scale = 1,
			font = "Yanone",
			fontSize = 14,
			fontFlags = "OUTLINE",
			iconSize = 24,
			width = 140,
			align = "LEFT",
			spacing = 2
		}

		local display, CreateDisplay
		local ShowDisplay, HideDisplay
		local LockDisplay, UnlockDisplay
		local UpdateDisplay

		local auras, auraFrames = {}, {}
		local AddAura, RemoveAura
		local FetchDisplay, fetched
		local RenderDisplay, rendered
		local ResetFrames

		function AddAura(auraname, playername)
			auras[auraname] = playername
			rendered = nil
		end

		function RemoveAura(auraname, playername)
			auras[auraname] = nil
			local f = _G["KPackPaladinAuras" .. playername]
			if f then
				f.cooldown:Hide()
				f:Hide()
				f = nil
			end
			rendered = nil
		end

		function FetchDisplay()
			if not fetched then
				auras = {}
				for name in pairs(aurasOrder) do
					local unit = select(8, UnitBuff("player", name))
					if unit then
						AddAura(name, UnitName(unit) or UNKNOWN)
					end
				end
				fetched = true
			end
		end

		do
			local function SortAuras(a, b)
				if not aurasOrder[a[1]] then
					return true
				end
				if not aurasOrder[b[1]] then
					return false
				end
				return aurasOrder[a[1]] < aurasOrder[b[1]]
			end

			function ResetFrames()
				for k, v in pairs(auraFrames) do
					if _G[k] then
						_G[k]:Hide()
					end
				end
			end

			function RenderDisplay()
				if not DB.Auras.enabled then
					rendered = true
				end
				if rendered then
					return
				end
				ResetFrames()

				local list = {}
				for auraname, playername in pairs(auras) do
					tinsert(list, {auraname, playername})
				end
				tsort(list, SortAuras)

				local size = DB.Auras.iconSize or 24

				for i = 1, #list do
					local aura = list[i]
					local fname = "KPackPaladinAuras" .. aura[2]

					local f = _G[fname]
					if not f then
						f = CreateFrame("Frame", fname, display)

						local t = f:CreateTexture(nil, "BACKGROUND")
						t:SetSize(size, size)
						t:SetTexCoord(0.1, 0.9, 0.1, 0.9)
						f.icon = t

						t = f:CreateTexture(nil, "BACKGROUND")
						t:SetSize(size, size)
						t:SetTexture([[Interface\Icons\Spell_Holy_AuraMastery]])
						t:SetTexCoord(0.1, 0.9, 0.1, 0.9)
						core:ShowIf(t, testMode)
						f.am = t

						t = CreateFrame("Cooldown", nil, display, "CooldownFrameTemplate")
						t:SetAllPoints(f.am)
						f.cooldown = t

						t = f:CreateFontString(nil, "ARTWORK")
						t:SetFont(core:MediaFetch("font", DB.Auras.font), DB.Auras.fontSize, DB.Auras.fontFlags)
						t:SetSize(110, size)
						t:SetJustifyV("MIDDLE")
						f.name = t
					end

					f:SetSize(DB.Auras.width or 140, size)
					f:SetPoint("TOPLEFT", display, "TOPLEFT", 0, -((size + (DB.Auras.spacing or 0)) * (i - 1)))
					f.icon:SetTexture(spellIcons[aura[1]])
					f.name:SetText(aura[2])
					f:Show()

					if display.align == "RIGHT" then
						f.icon:SetPoint("RIGHT", f, "RIGHT", 0, 0)
						f.am:SetPoint("LEFT", f.icon, "RIGHT", 3, 0)
						f.name:SetPoint("RIGHT", f.icon, "LEFT", -3, 0)
						f.name:SetPoint("LEFT", f, "LEFT", 0, 0)
						f.name:SetJustifyH("RIGHT")
					else
						f.icon:SetPoint("LEFT", f, "LEFT", 0, 0)
						f.am:SetPoint("RIGHT", f.icon, "LEFT", -3, 0)
						f.name:SetPoint("LEFT", f.icon, "RIGHT", 3, 0)
						f.name:SetPoint("RIGHT", f, "RIGHT", 0, 0)
						f.name:SetJustifyH("LEFT")
					end
					auraFrames[fname] = true
				end

				rendered = true
			end
		end

		function UpdateDisplay()
			if not display then
				return
			end

			if DB.Auras.enabled then
				ShowDisplay()
			else
				HideDisplay()
			end

			if DB.Auras.locked then
				LockDisplay()
			else
				UnlockDisplay()
			end

			core:RestorePosition(display, DB.Auras)

			display:SetWidth(DB.Auras.width or 140)
			display:SetScale(DB.Auras.scale or 1)

			local iconSize = DB.Auras.iconSize or 24
			display:SetHeight(iconSize * 7 + (DB.Auras.spacing or 0) * 6)
			core:ShowIf(display.header, not (DB.Auras.hideTitle and display.locked))

			display.header:SetFont(core:MediaFetch("font", DB.Auras.font), DB.Auras.fontSize, DB.Auras.fontFlags)

			local changeside
			if display.align ~= DB.Auras.align then
				display.align = DB.Auras.align
				changeside = display.align
			end

			if changeside then
				display.header:SetJustifyH(changeside)
				if changeside == "RIGHT" then
					display.header:ClearAllPoints()
					display.header:SetPoint("BOTTOMRIGHT", display, "TOPRIGHT", 0, 5)
					display.header:SetJustifyH("RIGHT")
				else
					display.header:ClearAllPoints()
					display.header:SetPoint("BOTTOMLEFT", display, "TOPLEFT", 0, 5)
					display.header:SetJustifyH("LEFT")
				end
			end

			if testMode then
				auras = testAuras
			else
				auras, fetched = {}, nil
				FetchDisplay()
			end

			for _, name in pairs(auras) do
				local f = _G["KPackPaladinAuras" .. name]
				if f then
					f:SetHeight(iconSize + 2)
					f.name:SetFont(core:MediaFetch("font", DB.Auras.font), DB.Auras.fontSize, DB.Auras.fontFlags)
					f.icon:SetSize(iconSize, iconSize)

					if changeside == "RIGHT" then
						f.icon:ClearAllPoints()
						f.icon:SetPoint("RIGHT", f, "RIGHT", 0, 0)
						f.am:ClearAllPoints()
						f.am:SetPoint("LEFT", f.icon, "RIGHT", 3, 0)
						f.name:ClearAllPoints()
						f.name:SetPoint("RIGHT", f.icon, "LEFT", -3, 0)
						f.name:SetPoint("LEFT", f, "LEFT", 0, 0)
						f.name:SetJustifyH("RIGHT")
					elseif changeside == "LEFT" then
						f.icon:ClearAllPoints()
						f.icon:SetPoint("LEFT", f, "LEFT", 0, 0)
						f.am:ClearAllPoints()
						f.am:SetPoint("RIGHT", f.icon, "LEFT", -3, 0)
						f.name:ClearAllPoints()
						f.name:SetPoint("LEFT", f.icon, "RIGHT", 3, 0)
						f.name:SetPoint("RIGHT", f, "RIGHT", 0, 0)
						f.name:SetJustifyH("LEFT")
					end
				end
			end

			rendered = nil
		end

		do
			local function StartMoving(self)
				self.moving = true
				self:StartMoving()
			end

			local function StopMoving(self)
				if self.moving then
					self:StopMovingOrSizing()
					self.moving = nil
					core:SavePosition(self, DB.Auras)
				end
			end

			local function OnMouseDown(self, button)
				if button == "RightButton" then
					core:OpenConfig("RaidUtility", "Auras")
				end
			end

			function CreateDisplay()
				if display then
					return
				end
				display = CreateFrame("Frame", "KPackPaladinAuras", UIParent)
				display:SetSize(DB.Auras.width or 140, (DB.Auras.iconSize or 24) * 7 + (DB.Auras.spacing or 0) * 6)
				display:SetClampedToScreen(true)
				display:SetScale(DB.Auras.scale or 1)
				display.align = DB.Auras.align or "LEFT"
				core:RestorePosition(display, DB.Auras)

				local t = display:CreateTexture(nil, "BACKGROUND")
				t:SetPoint("TOPLEFT", -2, 2)
				t:SetPoint("BOTTOMRIGHT", 2, -2)
				t:SetTexture(0, 0, 0, 0.5)
				display.bg = t

				t = display:CreateFontString(nil, "OVERLAY")
				t:SetFont(core:MediaFetch("font", DB.Auras.font), DB.Auras.fontSize, DB.Auras.fontFlags)
				t:SetText(L["Paladin Auras"])
				t:SetTextColor(0.96, 0.55, 0.73)
				if display.align == "RIGHT" then
					t:SetPoint("BOTTOMRIGHT", display, "TOPRIGHT", 0, 5)
					t:SetJustifyH("RIGHT")
				else
					t:SetPoint("BOTTOMLEFT", display, "TOPLEFT", 0, 5)
					t:SetJustifyH("LEFT")
				end
				display.header = t
			end

			function LockDisplay()
				if not display then
					CreateDisplay()
				end
				display:EnableMouse(false)
				display:SetMovable(false)
				display:RegisterForDrag(nil)
				display:SetScript("OnDragStart", nil)
				display:SetScript("OnDragStop", nil)
				display:SetScript("OnMouseDown", nil)
				display.bg:SetTexture(0, 0, 0, 0)
				if DB.Auras.hideTitle then
					display.header:Hide()
				end
				display.locked = true
			end

			function UnlockDisplay()
				if not display then
					CreateDisplay()
				end
				display:EnableMouse(true)
				display:SetMovable(true)
				display:RegisterForDrag("LeftButton")
				display:SetScript("OnDragStart", StartMoving)
				display:SetScript("OnDragStop", StopMoving)
				display:SetScript("OnMouseDown", OnMouseDown)
				display.bg:SetTexture(0, 0, 0, 0.5)
				display.header:Show()
				display.locked = nil
			end
		end

		do
			local function OnUpdate(self, elapsed)
				self.lastUpdate = (self.lastUpdate or 0) + elapsed
				if self.lastUpdate > (DB.Auras.updateInterval or 0.25) then
					FetchDisplay()
					RenderDisplay()
					self.lastUpdate = 0
				end
			end

			local cacheEvents = {
				PARTY_MEMBERS_CHANGED = true,
				RAID_ROSTER_UPDATE = true
			}

			local function OnEvent(self, event, _, arg2, _, arg4, _, _, arg7, _, _, arg10)
				if not self or self ~= display or not (event == "COMBAT_LOG_EVENT_UNFILTERED" or cacheEvents[event]) then
					return
				elseif cacheEvents[event] then
					ResetFrames()
					fetched, rendered = nil, nil
				elseif arg2 == "SPELL_AURA_APPLIED" and arg4 and CheckUnit(arg4) then
					if spellIcons[arg10] and arg7 and arg7 == core.name then
						AddAura(arg10, arg4)
					elseif arg10 == auraMastery then
						local f = _G["KPackPaladinAuras" .. arg4]
						if f then
							f.am:Show()
							CooldownFrame_SetTimer(f.cooldown, GetTime(), 6, 1)
						end
					end
				elseif arg2 == "SPELL_AURA_REMOVED" and arg4 and CheckUnit(arg4) then
					if spellIcons[arg10] and arg7 and arg7 == core.name then
						RemoveAura(arg10, arg4)
					elseif arg10 == auraMastery then
						local f = _G["KPackPaladinAuras" .. arg4]
						if f then
							rendered = nil
							f.am:Hide()
							f.cooldown:Hide()
						end
					end
				end
			end

			function ShowDisplay()
				if not display then
					CreateDisplay()
				end
				display:Show()
				display:SetScript("OnUpdate", OnUpdate)
				display:SetScript("OnEvent", OnEvent)
				display:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
				display:RegisterEvent("PARTY_MEMBERS_CHANGED")
				display:RegisterEvent("RAID_ROSTER_UPDATE")
			end

			function HideDisplay()
				if display then
					display:Hide()
					display:SetScript("OnUpdate", nil)
					display:SetScript("OnEvent", nil)
					display:UnregisterAllEvents()
				end
			end
		end

		mod.options.args.Auras = {
			type = "group",
			name = L["Paladin Auras"],
			order = order,
			get = function(i)
				return DB.Auras[i[#i]]
			end,
			set = function(i, val)
				DB.Auras[i[#i]] = val
				UpdateDisplay()
			end,
			args = {
				enabled = {
					type = "toggle",
					name = L["Enable"],
					order = 1
				},
				testMode = {
					type = "toggle",
					name = L["Configuration Mode"],
					desc = L["Toggle configuration mode to allow moving frames and setting appearance options."],
					order = 2,
					get = function()
						return testMode
					end,
					set = function(_, val)
						testMode = val
						if testMode then
							display:UnregisterAllEvents()
						else
							display:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
							display:RegisterEvent("PARTY_MEMBERS_CHANGED")
							display:RegisterEvent("RAID_ROSTER_UPDATE")
						end
						ResetFrames()
						UpdateDisplay()
					end
				},
				locked = {
					type = "toggle",
					name = L["Lock"],
					order = 3,
					disabled = function()
						return not DB.Auras.enabled
					end
				},
				updateInterval = {
					type = "range",
					name = L["Update Frequency"],
					order = 4,
					disabled = function()
						return not DB.Auras.enabled
					end,
					min = 0.1,
					max = 1,
					step = 0.05,
					bigStep = 0.1
				},
				appearance = {
					type = "group",
					name = L["Appearance"],
					order = 5,
					inline = true,
					disabled = function()
						return not DB.Auras.enabled
					end,
					args = {
						font = {
							type = "select",
							name = L["Font"],
							order = 1,
							dialogControl = "LSM30_Font",
							values = AceGUIWidgetLSMlists.font
						},
						fontFlags = {
							type = "select",
							name = L["Font Outline"],
							order = 2,
							values = {
								[""] = NONE,
								["OUTLINE"] = L["Outline"],
								["THINOUTLINE"] = L["Thin outline"],
								["THICKOUTLINE"] = L["Thick outline"],
								["MONOCHROME"] = L["Monochrome"],
								["OUTLINEMONOCHROME"] = L["Outlined monochrome"]
							}
						},
						fontSize = {
							type = "range",
							name = L["Font Size"],
							order = 3,
							min = 8,
							max = 30,
							step = 1
						},
						align = {
							type = "select",
							name = L["Orientation"],
							order = 4,
							values = {LEFT = L["Left to right"], RIGHT = L["Right to left"]}
						},
						iconSize = {
							type = "range",
							name = L["Icon Size"],
							order = 5,
							min = 8,
							max = 30,
							step = 1
						},
						spacing = {
							type = "range",
							name = L["Spacing"],
							order = 6,
							min = 0,
							max = 30,
							step = 1
						},
						width = {
							type = "range",
							name = L["Width"],
							order = 7,
							min = 120,
							max = 240,
							step = 1
						},
						scale = {
							type = "range",
							name = L["Scale"],
							order = 8,
							min = 0.5,
							max = 3,
							step = 0.01,
							bigStep = 0.1
						},
						hideTitle = {
							type = "toggle",
							name = L["Hide Title"],
							desc = L["Enable this if you want to hide the title text when locked."],
							order = 9
						}
					}
				},
				reset = {
					type = "execute",
					name = RESET,
					order = 99,
					width = "double",
					confirm = function()
						return L:F("Are you sure you want to reset %s to default?", L["Paladin Auras"])
					end,
					func = function()
						ResetDatabase(DB.Auras, defaults.Auras)
						UpdateDisplay()
					end
				}
			}
		}
		order = order + 1

		core:RegisterForEvent("PLAYER_ENTERING_WORLD", function()
			SetupDatabase()

			if DB.Auras.locked then
				LockDisplay()
			else
				UnlockDisplay()
			end

			if DB.Auras.enabled then
				ShowDisplay()
			else
				HideDisplay()
			end

			SLASH_KPACKAURAS1 = "/auras"
			SlashCmdList.KPACKAURAS = function()
				core:OpenConfig("RaidUtility", "Auras")
			end
		end)
	end

	---------------------------------------------------------------------------
	-- Sunder counter

	do
		local display, CreateDisplay
		local ShowDisplay, HideDisplay
		local LockDisplay, UnlockDisplay
		local UpdateDisplay
		local RenderDisplay, rendered
		local ResetFrames

		local AddSunder, ResetSunders, ReportSunders

		local sunder = GetSpellInfo(11597)
		local sunders, sunderFrames = {}, {}
		local testSunders, testMode = {Name1 = 20, Name2 = 32, Name3 = 6, Name4 = 12}

		-- defaults
		defaults.Sunders = {
			enabled = false,
			locked = false,
			updateInterval = 0.25,
			hideTitle = false,
			font = "Yanone",
			fontSize = 14,
			fontFlags = "OUTLINE",
			align = "RIGHT",
			spacing = 2,
			width = 140,
			scale = 1,
			sunders = {}
		}

		function UpdateDisplay()
			if not display then
				return
			end

			if DB.Sunders.enabled then
				ShowDisplay()
			else
				HideDisplay()
			end

			if DB.Sunders.locked then
				LockDisplay()
			else
				UnlockDisplay()
			end

			core:RestorePosition(display, DB.Sunders)

			display:SetWidth(DB.Sunders.width or 140)
			display:SetScale(DB.Sunders.scale or 1)

			display.header.text:SetFont(
				core:MediaFetch("font", DB.Sunders.font),
				DB.Sunders.fontSize,
				DB.Sunders.fontFlags
			)
			display.header.text:SetJustifyH(DB.Sunders.align or "LEFT")
			core:ShowIf(display.header, not (DB.Sunders.hideTitle and display.locked))

			sunders = testMode and testSunders or DB.Sunders.sunders

			for name, _ in pairs(sunders) do
				local f = _G["KPackSunderCounter" .. name]
				if f then
					f.text:SetFont(core:MediaFetch("font", DB.Sunders.font), DB.Sunders.fontSize, DB.Sunders.fontFlags)
					f.text:SetJustifyH(DB.Sunders.align or "RIGHT")
				end
			end

			rendered = nil
		end

		do
			local menuFrame
			local menu = {
				{
					text = L["Report"],
					func = function()
						ReportSunders()
					end,
					notCheckable = 1
				},
				{
					text = RESET,
					func = function()
						ResetSunders()
					end,
					notCheckable = 1
				}
			}

			local function StartMoving(self)
				self.moving = true
				self:StartMoving()
			end

			local function StopMoving(self)
				if self.moving then
					self:StopMovingOrSizing()
					self.moving = nil
					core:SavePosition(self, DB.Sunders)
				end
			end

			local function OnMouseDown(self, button)
				if button == "RightButton" then
					core:OpenConfig("RaidUtility", "Sunders")
				end
			end

			function CreateDisplay()
				if display then
					return
				end
				display = CreateFrame("Frame", "KPackSunderCounter", UIParent)
				display:SetSize(DB.Sunders.width or 140, 20)
				display:SetClampedToScreen(true)
				display:SetScale(DB.Sunders.scale or 1)
				core:RestorePosition(display, DB.Sunders)

				local t = display:CreateTexture(nil, "BACKGROUND")
				t:SetPoint("TOPLEFT", -2, 2)
				t:SetPoint("BOTTOMRIGHT", 2, -2)
				t:SetTexture(0, 0, 0, 0.5)
				display.bg = t

				t = CreateFrame("Button", nil, display)
				t:SetHeight(DB.Sunders.fontSize + 4)

				t.text = t:CreateFontString(nil, "OVERLAY")
				t.text:SetFont(core:MediaFetch("font", DB.Sunders.font), DB.Sunders.fontSize, DB.Sunders.fontFlags)
				t.text:SetText(sunder)
				t.text:SetAllPoints(t)
				t.text:SetJustifyH(DB.Sunders.align or "LEFT")
				t.text:SetJustifyV("BOTTOM")
				t.text:SetTextColor(0.78, 0.61, 0.43)
				t:SetPoint("BOTTOMLEFT", display, "TOPLEFT", 0, 5)
				t:SetPoint("BOTTOMRIGHT", display, "TOPRIGHT", 0, 5)
				t:RegisterForClicks("RightButtonUp")
				t:SetScript("OnMouseUp", function(self, button)
					if not testMode and next(sunders) and button == "RightButton" then
						menuFrame = menuFrame or CreateFrame("Frame", "KPackSunderCounterMenu", display, "UIDropDownMenuTemplate")
						EasyMenu(menu, menuFrame, "cursor", 0, 0, "MENU")
					end
				end)
				display.header = t
			end

			function LockDisplay()
				if not display then
					CreateDisplay()
				end
				display:EnableMouse(false)
				display:SetMovable(false)
				display:RegisterForDrag(nil)
				display:SetScript("OnDragStart", nil)
				display:SetScript("OnDragStop", nil)
				display:SetScript("OnMouseDown", nil)
				display.bg:SetTexture(0, 0, 0, 0)
				if DB.Sunders.hideTitle then
					display.header:Hide()
				end
				display.locked = true
			end

			function UnlockDisplay()
				if not display then
					CreateDisplay()
				end
				display:EnableMouse(true)
				display:SetMovable(true)
				display:RegisterForDrag("LeftButton")
				display:SetScript("OnDragStart", StartMoving)
				display:SetScript("OnDragStop", StopMoving)
				display:SetScript("OnMouseDown", OnMouseDown)
				display.bg:SetTexture(0, 0, 0, 0.5)
				display.header:Show()
				display.locked = nil
			end
		end

		function AddSunder(name)
			sunders[name] = (sunders[name] or 0) + 1
			rendered = nil
		end

		function ResetSunders()
			ResetFrames()
			DB.Sunders.sunders = {}
			rendered = nil
			UpdateDisplay()
		end

		function ReportSunders()
			if testMode then
				return
			end

			local list = {}
			for name, count in pairs(sunders) do
				tinsert(list, {name, count})
			end
			if #list == 0 then
				return
			end
			tsort(list, function(a, b) return (a[2] or 0) > (b[2] or 0) end)

			local channel = "SAY"
			if GetNumRaidMembers() > 0 then
				channel = "RAID"
			elseif GetNumPartyMembers() > 0 then
				channel = "PARTY"
			end

			SendChatMessage(sunder, channel)
			for i, sun in ipairs(list) do
				SendChatMessage(strformat("%2u. %s   %s", i, sun[1], sun[2]), channel)
			end
		end

		do
			local function OnUpdate(self, elapsed)
				self.lastUpdate = (self.lastUpdate or 0) + elapsed
				if self.lastUpdate > (DB.Sunders.updateInterval or 0.25) then
					if not rendered then
						RenderDisplay()
					end
					self.lastUpdate = 0
				end
			end

			local function OnEvent(self, event, _, arg2, _, arg4, _, _, _, _, _, arg10)
				if not self or self ~= display or event ~= "COMBAT_LOG_EVENT_UNFILTERED" then
					return
				elseif arg4 and CheckUnit(arg4) and arg2 == "SPELL_CAST_SUCCESS" and arg10 and arg10 == sunder then
					AddSunder(arg4)
				end
			end

			function ShowDisplay()
				if not display then
					CreateDisplay()
				end
				display:Show()
				display:SetScript("OnUpdate", OnUpdate)
				display:SetScript("OnEvent", OnEvent)
				display:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
			end

			function HideDisplay()
				if display then
					display:Hide()
					display:SetScript("OnUpdate", nil)
					display:SetScript("OnEvent", nil)
					display:UnregisterAllEvents()
				end
			end
		end

		function ResetFrames()
			for k, v in pairs(sunderFrames) do
				if _G[k] then
					_G[k]:Hide()
				end
			end
		end

		function RenderDisplay()
			if rendered then
				return
			end
			ResetFrames()

			local list = {}
			for name, count in pairs(sunders or {}) do
				tinsert(list, {name, count})
			end
			tsort(list, function(a, b) return (a[2] or 0) > (b[2] or 0) end)

			local height = 20

			for i = 1, #list do
				local entry = list[i]
				if entry then
					local fname = "KPackSunderCounter" .. entry[1]

					local f = _G[fname]
					if not f then
						f = CreateFrame("Frame", fname, display)

						local t = f:CreateFontString(nil, "OVERLAY")
						t:SetFont(core:MediaFetch("font", DB.Sunders.font), DB.Sunders.fontSize, DB.Sunders.fontFlags)
						t:SetPoint("TOPLEFT", f, "TOPLEFT")
						t:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT")
						t:SetJustifyH(DB.Sunders.align or "RIGHT")
						t:SetJustifyV("MIDDLE")
						f.text = t
					end

					f:SetHeight(20)
					f.text:SetText(strformat("%s: %d", entry[1], entry[2]))
					f:SetPoint("TOPLEFT", display, "TOPLEFT", 0, -((21 + (DB.Sunders.spacing or 0)) * (i - 1)))
					f:SetPoint("RIGHT", display)
					f:Show()
					if i > 1 then
						height = height + 21 + (DB.Sunders.spacing or 0)
					end
					sunderFrames[fname] = true
				end
			end

			display:SetHeight(height)
			rendered = true
		end

		mod.options.args.Sunders = {
			type = "group",
			name = sunder,
			order = order,
			get = function(i)
				return DB.Sunders[i[#i]]
			end,
			set = function(i, val)
				DB.Sunders[i[#i]] = val
				UpdateDisplay()
			end,
			args = {
				enabled = {
					type = "toggle",
					name = L["Enable"],
					order = 1
				},
				testMode = {
					type = "toggle",
					name = L["Configuration Mode"],
					desc = L["Toggle configuration mode to allow moving frames and setting appearance options."],
					order = 2,
					get = function()
						return testMode
					end,
					set = function(_, val)
						testMode = val
						if testMode then
							display:UnregisterAllEvents()
						else
							display:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
						end
						ResetFrames()
						UpdateDisplay()
					end
				},
				locked = {
					type = "toggle",
					name = L["Lock"],
					order = 3,
					disabled = function()
						return not DB.Sunders.enabled
					end
				},
				updateInterval = {
					type = "range",
					name = L["Update Frequency"],
					order = 4,
					disabled = function()
						return not DB.Sunders.enabled
					end,
					min = 0.1,
					max = 1,
					step = 0.05,
					bigStep = 0.1
				},
				appearance = {
					type = "group",
					name = L["Appearance"],
					order = 5,
					inline = true,
					disabled = function()
						return not DB.Sunders.enabled
					end,
					args = {
						font = {
							type = "select",
							name = L["Font"],
							order = 1,
							dialogControl = "LSM30_Font",
							values = AceGUIWidgetLSMlists.font
						},
						fontFlags = {
							type = "select",
							name = L["Font Outline"],
							order = 2,
							values = {
								[""] = NONE,
								["OUTLINE"] = L["Outline"],
								["THINOUTLINE"] = L["Thin outline"],
								["THICKOUTLINE"] = L["Thick outline"],
								["MONOCHROME"] = L["Monochrome"],
								["OUTLINEMONOCHROME"] = L["Outlined monochrome"]
							}
						},
						fontSize = {
							type = "range",
							name = L["Font Size"],
							order = 3,
							min = 8,
							max = 30,
							step = 1
						},
						align = {
							type = "select",
							name = L["Text Alignment"],
							order = 4,
							values = {LEFT = L["Left"], RIGHT = L["Right"]}
						},
						spacing = {
							type = "range",
							name = L["Spacing"],
							order = 5,
							min = 0,
							max = 30,
							step = 1
						},
						width = {
							type = "range",
							name = L["Width"],
							order = 6,
							min = 120,
							max = 240,
							step = 1
						},
						scale = {
							type = "range",
							name = L["Scale"],
							order = 7,
							min = 0.5,
							max = 3,
							step = 0.01,
							bigStep = 0.1
						},
						hideTitle = {
							type = "toggle",
							name = L["Hide Title"],
							desc = L["Enable this if you want to hide the title text when locked."],
							order = 8
						}
					}
				},
				reset = {
					type = "execute",
					name = RESET,
					order = 99,
					width = "double",
					confirm = function()
						return L:F("Are you sure you want to reset %s to default?", sunder)
					end,
					func = function()
						ResetDatabase(DB.Sunders, defaults.Sunders)
						UpdateDisplay()
					end
				}
			}
		}
		order = order + 1

		core:RegisterForEvent("PLAYER_ENTERING_WORLD", function()
			SetupDatabase()

			if DB.Sunders.locked then
				LockDisplay()
			else
				UnlockDisplay()
			end

			if DB.Sunders.enabled then
				sunders = DB.Sunders.sunders
				ShowDisplay()
			else
				HideDisplay()
			end

			SLASH_KPACKSUNDER1 = "/sunder"
			SlashCmdList.KPACKSUNDER = function(cmd)
				cmd = strlower(cmd:trim())
				if cmd == "reset" then
					ResetSunders()
				elseif cmd == "report" then
					ReportSunders()
				elseif cmd == "lock" then
					LockDisplay()
				elseif cmd == "unlock" then
					UnlockDisplay()
				else
					core:OpenConfig("RaidUtility", "Sunders")
				end
			end
		end)
	end

	---------------------------------------------------------------------------
	-- Healers Mana

	do
		defaults.Mana = {
			enabled = false,
			locked = false,
			updateInterval = 0.25,
			hideTitle = false,
			scale = 1,
			font = "Yanone",
			fontSize = 14,
			fontFlags = "OUTLINE",
			showIcon = true,
			iconSize = 24,
			align = "LEFT",
			width = 180,
			spacing = 2
		}

		local LGT = LibStub("LibGroupTalents-1.0", true)
		local display, CreateDisplay
		local ShowDisplay, HideDisplay
		local LockDisplay, UnlockDisplay
		local UpdateDisplay
		local RenderDisplay, rendered
		local UpdateMana
		local healers, healerFrames = {}, {}
		local testHealers = {
			raid1 = {
				name = "RestoDruid",
				class = "DRUID",
				curmana = 25000,
				maxmana = 44000,
				icon = "Interface\\Icons\\spell_nature_healingtouch",
				offline = true
			},
			raid2 = {
				name = "RestoShaman",
				class = "SHAMAN",
				curmana = 18000,
				maxmana = 36000,
				icon = "Interface\\Icons\\spell_nature_magicimmunity"
			},
			raid3 = {
				name = "HolyPriest",
				class = "PRIEST",
				curmana = 24000,
				maxmana = 32000,
				icon = "Interface\\Icons\\spell_holy_guardianspirit"
			},
			raid4 = {
				name = "DiscPriest",
				class = "PRIEST",
				curmana = 17000,
				maxmana = 32000,
				icon = "Interface\\Icons\\spell_holy_powerwordshield"
			},
			raid5 = {
				name = "HolyPaladin",
				class = "PALADIN",
				curmana = 17000,
				maxmana = 45000,
				icon = "Interface\\Icons\\spell_holy_holybolt",
				dead = true
			}
		}

		local colorsTable = {
			DRUID = {1, 0.49, 0.04},
			PALADIN = {0.96, 0.55, 0.73},
			PRIEST = {1, 1, 1},
			SHAMAN = {0, 0.44, 0.87}
		}

		local function GetHealerIcon(unit, class)
			class = class or select(2, UnitClass(unit))
			if class == "SHAMAN" then
				return "Interface\\Icons\\spell_nature_magicimmunity"
			elseif class == "PALADIN" then
				return "Interface\\Icons\\spell_holy_holybolt"
			elseif class == "DRUID" then
				return "Interface\\Icons\\spell_nature_healingtouch"
			elseif class == "PRIEST" then
				local tree = LGT.roster[UnitGUID(unit)].talents[LGT:GetActiveTalentGroup(unit)]
				if strlen(tree[1]) > strlen(tree[2]) then
					return "Interface\\Icons\\spell_holy_powerwordshield"
				else
					return "Interface\\Icons\\spell_holy_guardianspirit"
				end
			end
			return "Interface\\Icons\\INV_Misc_QuestionMark"
		end

		local function ResetFrames()
			for k, v in pairs(healerFrames) do
				if _G[k] then
					_G[k]:Hide()
				end
			end
		end

		local function CacheHealers()
			if testMode then
				return
			end

			local prefix, start, stop = "raid", 1, GetNumRaidMembers()
			if stop == 0 then
				prefix, start, stop = "party", 0, GetNumPartyMembers()
			end

			healers = {}

			if prefix then
				for i = start, stop do
					local unit = (i == 0) and "player" or prefix .. tostring(i)
					if UnitExists(unit) and LGT:GetUnitRole(unit) == "healer" then
						local class = select(2, UnitClass(unit))
						healers[unit] = {
							name = UnitName(unit),
							class = class,
							icon = GetHealerIcon(unit, class),
							curmana = UnitPower(unit, 0),
							maxmana = UnitPowerMax(unit, 0)
						}
					elseif healers[unit] then
						healers[unit] = nil
					end
				end
			elseif LGT:GetUnitRole("player") == "healer" then
				local class = select(2, UnitClass("player"))
				healers["player"] = {
					name = UnitName("player"),
					class = select(2, UnitClass("player")),
					icon = GetHealerIcon("player", class),
					curmana = UnitPower("player", 0),
					maxmana = UnitPowerMax("player", 0)
				}
			elseif healers["player"] then
				healers["player"] = nil
			end

			rendered = nil
		end

		function UpdateMana(unit, curmana, maxmana)
			if unit and healers[unit] then
				healers[unit].curmana = curmana
				healers[unit].maxmana = maxmana
				healers[unit].dead = UnitIsDeadOrGhost(unit)
				healers[unit].offline = not UnitIsConnected(unit)
			end
		end

		function UpdateDisplay()
			if not display then
				return
			end

			if DB.Mana.enabled then
				ShowDisplay()
			else
				HideDisplay()
			end

			if DB.Mana.locked then
				LockDisplay()
			else
				UnlockDisplay()
			end

			core:RestorePosition(display, DB.Mana)

			display:SetWidth(DB.Mana.width or 180)
			display:SetScale(DB.Mana.scale or 1)

			display.header:SetFont(core:MediaFetch("font", DB.Mana.font), DB.Mana.fontSize, DB.Mana.fontFlags)
			display.header:SetJustifyH(DB.Mana.align or "LEFT")
			core:ShowIf(display.header, not (DB.Mana.hideTitle and display.locked))

			if testMode then
				healers = testHealers
			else
				CacheHealers()
			end

			local changeside
			if display.align ~= DB.Mana.align then
				display.align = DB.Mana.align
				changeside = display.align
			end

			for unit, data in pairs(healers) do
				local f = _G["KPackHealersMana" .. data.name]
				if f then
					f.icon:SetSize(DB.Mana.iconSize, DB.Mana.iconSize)
					f.name:SetFont(core:MediaFetch("font", DB.Mana.font), DB.Mana.fontSize, DB.Mana.fontFlags)
					f.mana:SetFont(core:MediaFetch("font", DB.Mana.font), DB.Mana.fontSize, DB.Mana.fontFlags)

					if changeside == "RIGHT" then
						f.icon:ClearAllPoints()
						f.icon:SetPoint("RIGHT", f, "RIGHT", 0, 0)
						f.mana:ClearAllPoints()
						f.mana:SetPoint("LEFT", f, "LEFT", 0, 0)
						f.mana:SetJustifyH("LEFT")
						f.name:ClearAllPoints()
						f.name:SetPoint("LEFT", f.mana, "RIGHT", 1, 0)
						f.name:SetPoint("RIGHT", f.icon, "LEFT", -3, 0)
						f.name:SetJustifyH("RIGHT")
					elseif changeside == "LEFT" then
						f.icon:ClearAllPoints()
						f.icon:SetPoint("LEFT", f, "LEFT", 0, 0)
						f.mana:ClearAllPoints()
						f.mana:SetPoint("RIGHT", f, "RIGHT", 0, 0)
						f.mana:SetJustifyH("RIGHT")
						f.name:ClearAllPoints()
						f.name:SetPoint("LEFT", f.icon, "RIGHT", 3, 0)
						f.name:SetPoint("RIGHT", f.mana, "LEFT", 1, 0)
						f.name:SetJustifyH("LEFT")
					end
				end
			end

			rendered = nil
		end

		do
			local function StartMoving(self)
				self.moving = true
				self:StartMoving()
			end

			local function StopMoving(self)
				if self.moving then
					self:StopMovingOrSizing()
					self.moving = nil
					core:SavePosition(self, DB.Mana)
				end
			end

			local function OnMouseDown(self, button)
				if button == "RightButton" then
					core:OpenConfig("RaidUtility", "Mana")
				end
			end

			function CreateDisplay()
				if display then
					return
				end
				display = CreateFrame("Frame", "KPackHealersMana", UIParent)
				display:SetSize(DB.Mana.width or 180, DB.Mana.iconSize or 24)
				display:SetClampedToScreen(true)
				display:SetScale(DB.Mana.scale or 1)
				core:RestorePosition(display, DB.Mana)

				local t = display:CreateTexture(nil, "BACKGROUND")
				t:SetPoint("TOPLEFT", -2, 2)
				t:SetPoint("BOTTOMRIGHT", 2, -2)
				t:SetTexture(0, 0, 0, 0.5)
				display.bg = t

				t = display:CreateFontString(nil, "OVERLAY")
				t:SetFont(core:MediaFetch("font", DB.Mana.font), DB.Mana.fontSize, DB.Mana.fontFlags)
				t:SetText(L["Healers Mana"])
				t:SetJustifyH(DB.Mana.align or "LEFT")
				t:SetPoint("BOTTOMLEFT", display, "TOPLEFT", 0, 5)
				t:SetPoint("BOTTOMRIGHT", display, "TOPRIGHT", 0, 5)
				display.header = t
				display.align = DB.Mana.align or "LEFT"
			end

			function LockDisplay()
				if not display then
					CreateDisplay()
				end
				display:EnableMouse(false)
				display:SetMovable(false)
				display:RegisterForDrag(nil)
				display:SetScript("OnDragStart", nil)
				display:SetScript("OnDragStop", nil)
				display:SetScript("OnMouseDown", nil)
				display.bg:SetTexture(0, 0, 0, 0)
				if DB.Mana.hideTitle then
					display.header:Hide()
				end
				display.locked = true
			end

			function UnlockDisplay()
				if not display then
					CreateDisplay()
				end
				display:EnableMouse(true)
				display:SetMovable(true)
				display:RegisterForDrag("LeftButton")
				display:SetScript("OnDragStart", StartMoving)
				display:SetScript("OnDragStop", StopMoving)
				display:SetScript("OnMouseDown", OnMouseDown)
				display.bg:SetTexture(0, 0, 0, 0.5)
				display.header:Show()
				display.locked = nil
			end
		end

		do
			local function OnUpdate(self, elapsed)
				self.lastUpdate = (self.lastUpdate or 0) + elapsed
				if self.lastUpdate > (DB.Mana.updateInterval or 0.25) then
					if not rendered then
						RenderDisplay()
					end
					for _, data in pairs(healers) do
						local f = _G["KPackHealersMana" .. data.name]
						if f then
							if data.dead then
								f.mana:SetText(DEAD)
								f:SetAlpha(0.35)
							elseif data.offline then
								f.mana:SetText(FRIENDS_LIST_OFFLINE)
								f:SetAlpha(0.35)
							else
								f.mana:SetText(strformat("%02.f%%", 100 * data.curmana / data.maxmana))
								f:SetAlpha(1)
							end
						end
					end
					self.lastUpdate = 0
				end
			end

			local cacheEvents = {
				ACTIVE_TALENT_GROUP_CHANGED = true,
				PARTY_MEMBERS_CHANGED = true,
				RAID_ROSTER_UPDATE = true,
				PLAYER_REGEN_DISABLED = true
			}

			local function OnEvent(self, event, arg1)
				if not self or self ~= display or not DB.Mana.enabled then
					return
				elseif cacheEvents[event] then
					CacheHealers()
				elseif arg1 and CheckUnit(arg1) and healers[arg1] then
					if event == "UNIT_MANA" then
						UpdateMana(arg1, UnitPower(arg1, 0), UnitPowerMax(arg1, 0))
					elseif event == "UNIT_AURA" then
						local f = _G["KPackHealersMana" .. UnitName(arg1)]
						if not f then
							return
						end

						local _, _, icon, _, _, duration, _, _, _, _, _ = UnitBuff(arg1, TUTORIAL_TITLE12)
						if icon then
							f._icon = f._icon or f.icon:GetTexture()
							f.icon:SetTexture(icon)
							if not f.drinking then
								f.drinking = true
								CooldownFrame_SetTimer(f.cooldown, GetTime(), duration, 1)
							end
						else
							if f._icon then
								f.icon:SetTexture(f._icon)
								f._icon = nil
							end
							if f.drinking then
								f.drinking = nil
								f.cooldown:Hide()
							end
						end
					end
				end
			end

			function ShowDisplay()
				if not display then
					CreateDisplay()
				end
				display:Show()
				display:SetScript("OnUpdate", OnUpdate)
				display:SetScript("OnEvent", OnEvent)
				display:RegisterEvent("PARTY_MEMBERS_CHANGED")
				display:RegisterEvent("RAID_ROSTER_UPDATE")
				display:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
				display:RegisterEvent("UNIT_MANA")
				display:RegisterEvent("UNIT_AURA")
			end

			function HideDisplay()
				if display then
					display:Hide()
					display:SetScript("OnUpdate", nil)
					display:SetScript("OnEvent", nil)
					display:UnregisterAllEvents()
				end
			end
		end

		function RenderDisplay()
			if rendered then
				return
			end
			ResetFrames()
			local size = DB.Mana.iconSize or 24
			local height = size
			local i = 1
			for unit, data in pairs(healers) do
				local fname = "KPackHealersMana" .. data.name
				local f = _G[fname]
				if not f then
					f = CreateFrame("Frame", fname, display)

					local t = f:CreateTexture(nil, "BACKGROUND")
					t:SetSize(size, size)
					t:SetTexCoord(0.1, 0.9, 0.1, 0.9)
					f.icon = t

					t = CreateFrame("Cooldown", nil, display, "CooldownFrameTemplate")
					t:SetAllPoints(f.icon)
					f.cooldown = t

					t = f:CreateFontString(nil, "ARTWORK")
					t:SetFont(core:MediaFetch("font", DB.Mana.font), DB.Mana.fontSize, DB.Mana.fontFlags)
					t:SetJustifyV("MIDDLE")
					t:SetText(data.name)
					t:SetTextColor(unpack(colorsTable[data.class]))
					f.name = t

					t = f:CreateFontString(nil, "ARTWORK")
					t:SetFont(core:MediaFetch("font", DB.Mana.font), DB.Mana.fontSize, DB.Mana.fontFlags)
					t:SetJustifyV("MIDDLE")
					f.mana = t
				end

				f:SetHeight(size)
				f:SetPoint("TOPLEFT", display, "TOPLEFT", 0, -((size + (DB.Mana.spacing or 0)) * (i - 1)))
				f:SetPoint("RIGHT", display, "RIGHT", 0, 0)
				f.icon:SetTexture(data.icon)
				f.mana:SetText(strformat("%02.f%%", 100 * data.curmana / data.maxmana))
				f:Show()

				if display.align == "RIGHT" then
					f.icon:SetPoint("RIGHT", f, "RIGHT", 0, 0)
					f.mana:SetPoint("LEFT", f, "LEFT", 0, 0)
					f.mana:SetJustifyH("LEFT")
					f.name:SetPoint("LEFT", f.mana, "RIGHT", 1, 0)
					f.name:SetPoint("RIGHT", f.icon, "LEFT", -3, 0)
					f.name:SetJustifyH("RIGHT")
				else
					f.icon:SetPoint("LEFT", f, "LEFT", 0, 0)
					f.mana:SetPoint("RIGHT", f, "RIGHT", 0, 0)
					f.mana:SetJustifyH("RIGHT")
					f.name:SetPoint("LEFT", f.icon, "RIGHT", 3, 0)
					f.name:SetPoint("RIGHT", f.mana, "LEFT", 1, 0)
					f.name:SetJustifyH("LEFT")
				end
				if i > 1 then
					height = height + size + (DB.Mana.spacing or 0)
				end
				i = i + 1
				healerFrames[fname] = true
			end

			display:SetHeight(height)
			rendered = true
		end

		mod.options.args.Mana = {
			type = "group",
			name = L["Healers Mana"],
			order = order,
			get = function(i)
				return DB.Mana[i[#i]]
			end,
			set = function(i, val)
				DB.Mana[i[#i]] = val
				UpdateDisplay()
			end,
			args = {
				enabled = {
					type = "toggle",
					name = L["Enable"],
					order = 1
				},
				testMode = {
					type = "toggle",
					name = L["Configuration Mode"],
					desc = L["Toggle configuration mode to allow moving frames and setting appearance options."],
					order = 2,
					get = function()
						return testMode
					end,
					set = function(_, val)
						testMode = val
						if testMode then
							display:UnregisterAllEvents()
						else
							display:RegisterEvent("PARTY_MEMBERS_CHANGED")
							display:RegisterEvent("RAID_ROSTER_UPDATE")
							display:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
							display:RegisterEvent("UNIT_MANA")
							display:RegisterEvent("UNIT_AURA")
						end
						ResetFrames()
						UpdateDisplay()
					end
				},
				locked = {
					type = "toggle",
					name = L["Lock"],
					order = 3,
					disabled = function()
						return not DB.Mana.enabled
					end
				},
				updateInterval = {
					type = "range",
					name = L["Update Frequency"],
					order = 4,
					disabled = function()
						return not DB.Mana.enabled
					end,
					min = 0.1,
					max = 1,
					step = 0.05,
					bigStep = 0.1
				},
				appearance = {
					type = "group",
					name = L["Appearance"],
					order = 5,
					inline = true,
					disabled = function()
						return not DB.Mana.enabled
					end,
					args = {
						font = {
							type = "select",
							name = L["Font"],
							order = 1,
							dialogControl = "LSM30_Font",
							values = AceGUIWidgetLSMlists.font
						},
						fontFlags = {
							type = "select",
							name = L["Font Outline"],
							order = 2,
							values = {
								[""] = NONE,
								["OUTLINE"] = L["Outline"],
								["THINOUTLINE"] = L["Thin outline"],
								["THICKOUTLINE"] = L["Thick outline"],
								["MONOCHROME"] = L["Monochrome"],
								["OUTLINEMONOCHROME"] = L["Outlined monochrome"]
							}
						},
						fontSize = {
							type = "range",
							name = L["Font Size"],
							order = 3,
							min = 8,
							max = 30,
							step = 1
						},
						align = {
							type = "select",
							name = L["Orientation"],
							order = 4,
							values = {LEFT = L["Left to right"], RIGHT = L["Right to left"]}
						},
						iconSize = {
							type = "range",
							name = L["Icon Size"],
							order = 5,
							min = 8,
							max = 30,
							step = 1
						},
						spacing = {
							type = "range",
							name = L["Spacing"],
							order = 6,
							min = 0,
							max = 30,
							step = 1
						},
						width = {
							type = "range",
							name = L["Width"],
							order = 7,
							min = 120,
							max = 240,
							step = 1
						},
						scale = {
							type = "range",
							name = L["Scale"],
							order = 8,
							min = 0.5,
							max = 3,
							step = 0.01,
							bigStep = 0.1
						},
						hideTitle = {
							type = "toggle",
							name = L["Hide Title"],
							desc = L["Enable this if you want to hide the title text when locked."],
							order = 9
						}
					}
				},
				reset = {
					type = "execute",
					name = RESET,
					order = 99,
					width = "double",
					confirm = function()
						return L:F("Are you sure you want to reset %s to default?", L["Healers Mana"])
					end,
					func = function()
						ResetDatabase(DB.Mana, defaults.Mana)
						UpdateDisplay()
					end
				}
			}
		}
		order = order + 1
		core:RegisterForEvent("PLAYER_ENTERING_WORLD", function()
			SetupDatabase()
			if not LGT then
				return
			end

			if DB.Mana.locked then
				LockDisplay()
			else
				UnlockDisplay()
			end

			if DB.Mana.enabled then
				core.After(3, CacheHealers)
				ShowDisplay()
			else
				HideDisplay()
			end

			SLASH_KPACKHEALERSMANA1 = "/mana"
			SLASH_KPACKHEALERSMANA2 = "/healersmana"
			SlashCmdList.KPACKHEALERSMANA = function()
				core:OpenConfig("RaidUtility", "Mana")
			end
		end)
	end

	---------------------------------------------------------------------------
	-- Raid Cooldowns

	do
		local RaidCooldowns = CreateFrame("Frame")
		mod.RaidCooldowns = RaidCooldowns
		LibStub("LibBars-1.0"):Embed(RaidCooldowns)
		RaidCooldowns:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)

		local classcolors = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
		local heroism = core.faction == "Alliance" and 32182 or 2825
		local cooldowns = {
			DEATHKNIGHT = {
				[42650] = 600, -- Army of the Dead
				[45529] = 60, -- Blood Tap
				[47476] = 120, -- Strangulate
				[47528] = 10, -- Mind Freeze
				[47568] = 300, -- ERW
				[48707] = 45, -- Anti-Magic Shell
				[48792] = 120, -- Icebound Fortitude
				[48982] = 30, -- Rune Tap
				[49005] = 180, -- Mark of Blood
				[49016] = 180, -- Hysteria
				[49028] = 90, -- Dancing Rune Weapon
				[49039] = 120, -- Lichborne
				[49206] = 180, -- Summon Gargoyle
				[49222] = 60, -- Bone Shield
				[49576] = 35, -- Death Grip
				[51052] = 120, -- Anti-magic Zone
				[51271] = 60, -- Unbreakable Armor
				[55233] = 60, -- Vampiric Blood
				[56222] = 8, -- Dark Command
				[61999] = 600, -- Raise Ally
				[70654] = 60, -- Blood Armor (Tank 4 Set)
				[48743] = 120 -- Death Pact
			},
			DRUID = {
				[16857] = 6, -- Faerie Fire (Feral)
				[17116] = 180, -- Nature's Swiftness
				[18562] = 15, -- Swiftmend
				[22812] = 60, -- Barkskin
				[22842] = 180, -- Frenzied Regeneration
				[29166] = 180, -- Innervate
				[33357] = 180, -- Dash
				[33831] = 180, -- Force of Nature
				[48447] = 480, -- Tranquility
				[48477] = 600, -- Rebirth
				[50334] = 180, -- Berserk
				[5209] = 180, -- Challenging Roar
				[5229] = 60, -- Enrage
				[53201] = 60, -- Starfall
				[53227] = 20, -- Typhoon
				[61336] = 180, -- Survival Instincts
				[6795] = 8, -- Growl
				[8983] = 30 -- Bash
			},
			HUNTER = {
				[13809] = 30, -- Frost Trap
				[19263] = 90, -- Deterrence
				[19574] = 120, -- Bestial Wrath
				[19801] = 8, -- Tranquilizing Shot
				[23989] = 180, -- Readiness
				[3045] = 180, -- Rapid Fire
				[34477] = 30, -- Misdirection
				[34490] = 30, -- Silencing Shot
				[34600] = 30, -- Snake Trap
				[49067] = 30, -- Explosive Trap
				[60192] = 30, -- Freezing Arrow
				[781] = 25, -- Disengage
				[5384] = 30 -- Feign Death
			},
			MAGE = {
				[11958] = 480, -- Cold Snap
				[12051] = 240, -- Evocation
				[1953] = 15, -- Blink
				[2139] = 24, -- Counterspell
				[31687] = 180, -- Summon Water Elemental
				[45438] = 300, -- Ice Block
				[55342] = 180, -- Mirror Image
				[66] = 180 -- Invisibility
			},
			PALADIN = {
				[10278] = 300, -- Hand of Protection
				[10308] = 60, -- Hammer of Justice
				[1038] = 120, -- Hand of Salvation
				[1044] = 25, -- Hand of Freedom
				[19752] = 600, -- Divine Intervention
				[20066] = 60, -- Repentance
				[20216] = 120, -- Divine Favor
				[31789] = 8, -- Righteous Defense
				[31821] = 120, -- Aura Mastery
				[31842] = 180, -- Divine Illumination
				[31850] = 180, -- Ardent Defender
				[31884] = 120, -- Avenging Wrath
				[48788] = 1200, -- Lay on Hands
				[48817] = 30, -- Holy Wrath
				[498] = 60, -- Divine Protection
				[53601] = 60, -- Sacred Shield
				[54428] = 60, -- Divine Plea
				[62124] = 8, -- Hand of Reckoning
				[64205] = 120, -- Divine Sacrifice
				[642] = 300, -- Divine Shield
				[66233] = 120, -- Ardent Defender
				[6940] = 120, -- Hand of Sacrifice
				[70940] = 120 -- Divine Guardian
			},
			PRIEST = {
				[10060] = 96, -- Powers Infusion
				[10890] = 30, -- Psychic Scream
				[15487] = 45, -- Silence
				[33206] = 180, -- Pain Suppression
				[34433] = 300, -- Shadowfiend
				[47585] = 120, -- Dispersion
				[47788] = 180, -- Guardian Spirit
				[48113] = 10, -- Prayer of Mending
				[586] = 30, -- Fade
				[6346] = 180, -- Fear Ward
				[64044] = 120, -- Psychic Horror
				[64843] = 480, -- Divine Hymn
				[64901] = 360, -- Hymn of Hope
				[724] = 180, -- Lightwell
				[8122] = 30 -- Psychic Scream
			},
			ROGUE = {
				[11305] = 40, -- Sprint
				[13750] = 80, -- Adrenaline Rush
				[13877] = 20, -- Blade Flurry
				[14185] = 300, -- Preparation
				[1725] = 30, -- Distract
				[1766] = 10, -- Kick
				[1856] = 180, -- Vanish
				[2094] = 180, -- Blind
				[26669] = 50, -- Evasion
				[26889] = 20, -- Vanish
				[31224] = 90, -- Cloak of Shadows
				[48659] = 10, -- Feint
				[51690] = 20, -- Killing Spree
				[51722] = 60, -- Dismantle
				[5277] = 180, -- Evasion
				[57934] = 30, -- Tricks of the Trade
				[8643] = 20 -- Kidney Shot
			},
			SHAMAN = {
				[16166] = 180, -- Elemental Mastery
				[16188] = 120, -- Nature's Swiftness
				[16190] = 300, -- Mana Tide Totem
				[20608] = 1800, -- Reincarnation
				[2062] = 600, -- Earth Elemental Totem
				[21169] = 1800, -- Reincarnation
				[2894] = 600, -- Fire Elemental Totem
				[51514] = 45, -- Hex
				[51533] = 180, -- Feral Spirit
				[57994] = 6, -- Wind Shear
				[59159] = 35, -- Thunderstorm
				[30823] = 60, -- Shamanistic Rage
				[heroism] = 300 -- Bloodlust/Heroism
			},
			WARLOCK = {
				[1122] = 600, -- Summon Infernal
				[18540] = 600, -- Summon Doomguard
				[29858] = 180, -- Soulshatter
				[29893] = 300, -- Ritual of Souls
				[47241] = 126, -- Metamorphosis
				[47883] = 900, -- Soulstone Resurrection
				[48020] = 30, -- Demonic Circle: Teleport
				[59672] = 180, -- Metamorphosis
				[6203] = 1800, -- Soulstone, XXX needs testing
				[698] = 120, -- Ritual of Summoning
				[47891] = 30 -- Shadow Ward
			},
			WARRIOR = {
				[1161] = 180, -- Challenging Shout
				[12292] = 121, -- Death Wish
				[12323] = 5, -- Piercing Howl
				[12809] = 30, -- Concussion Blow
				[12975] = 180, -- Last Stand
				[1680] = 8, -- Whirlwind
				[1719] = 200, -- Recklessness
				[23881] = 4, -- Bloodthirst
				[2565] = 60, -- Shield Block
				[3411] = 30, -- Intervene
				[355] = 8, -- Taunt
				[46924] = 75, -- Bladestorm
				[5246] = 120, -- Intimidating Shout
				[55694] = 180, -- Enraged Regeneration
				[60970] = 45, -- Heroic Fury
				[64382] = 300, -- Shattering Throw
				[6552] = 10, -- Pummel
				[676] = 60, -- Disarm
				[70845] = 60, -- Stoicism (Tank 4 Set)
				[72] = 12, -- Shield Bash
				[871] = 300 -- Shield Wall
			}
		}

		local allSpells, classLookup = {}, {}
		for class, spells in pairs(cooldowns) do
			for id, cd in pairs(spells) do
				allSpells[id] = cd
				classLookup[id] = class
			end
		end

		local classes = {}
		do
			local hexColors = {}
			for k, v in pairs(classcolors) do
				hexColors[k] = "|cff" .. strformat("%02x%02x%02x", v.r * 255, v.g * 255, v.b * 255)
			end
			for class in pairs(cooldowns) do
				classes[class] = hexColors[class] .. LOCALIZED_CLASS_NAMES_MALE[class] .. "|r"
			end
			wipe(hexColors)
			hexColors = nil
		end

		local barGroups, inGroup

		local GetOptions

		defaults.Cooldowns = {
			enabled = false,
			locked = false,
			width = 180,
			height = 18,
			scale = 1.0,
			growUp = false,
			showIcon = true,
			showDuration = true,
			classColor = true,
			color = {0.25, 0.33, 0.68, 1},
			texture = "KPack",
			font = "Friz Quadrata TT",
			fontSize = 11,
			fontFlags = "",
			maxbars = 30,
			orientation = 1,
			spells = {
				[6203] = true,
				[6940] = true,
				[10278] = true,
				[12323] = true,
				[20608] = true,
				[29166] = true,
				[31821] = true,
				[33206] = true,
				[34477] = true,
				[47788] = true,
				[47883] = true,
				[48477] = true,
				[48788] = true,
				[57934] = true,
				[64205] = true,
				[64843] = true,
				[64901] = true,
				[heroism] = true
			}
		}

		local CreateDisplay, UpdateDisplay, display
		local ShowDisplay, HideDisplay
		local LockDisplay, UnlockDisplay
		local options

		function GetOptions()
			if not options then
				local disabled = function()
					return not (DB.Cooldowns and DB.Cooldowns.enabled)
				end
				options = {
					type = "group",
					name = L["Raid Cooldowns"],
					childGroups = "tab",
					order = order,
					get = function(i)
						return DB.Cooldowns[i[#i]]
					end,
					set = function(i, val)
						DB.Cooldowns[i[#i]] = val
						UpdateDisplay()
					end,
					args = {
						general = {
							type = "group",
							name = L["Options"],
							order = 1,
							args = {
								enabled = {
									type = "toggle",
									name = L["Enable"],
									order = 1,
									get = function()
										return DB.Cooldowns.enabled
									end,
									set = function()
										if DB.Cooldowns.enabled then
											DB.Cooldowns.enabled = false
											HideDisplay()
										else
											DB.Cooldowns.enabled = true
											ShowDisplay()
											UpdateDisplay()
										end
									end
								},
								locked = {
									type = "toggle",
									name = L["Lock"],
									order = 2,
									disabled = disabled
								},
								sep1 = {
									type = "description",
									name = " ",
									order = 3,
									width = "double"
								},
								showTest = {
									type = "execute",
									name = L["Spawn Test bars"],
									order = 4,
									disabled = disabled,
									func = function()
										RaidCooldowns:SpawnTestBar()
									end
								},
								reset = {
									type = "execute",
									name = RESET,
									order = 5,
									confirm = function()
										return L:F(
											"Are you sure you want to reset %s to default?",
											L["Raid Cooldowns"]
										)
									end,
									func = function()
										DB.Cooldowns = CopyTable(defaults.Cooldowns)
										UpdateDisplay()
									end
								},
								sep2 = {
									type = "description",
									name = " ",
									order = 6,
									width = "double"
								},
								appearance = {
									type = "group",
									name = L["Appearance"],
									order = 7,
									inline = true,
									disabled = disabled,
									args = {
										classColor = {
											type = "toggle",
											name = L["Class color"],
											order = 1
										},
										color = {
											type = "color",
											name = L["Custom color"],
											order = 2,
											get = function()
												return unpack(DB.Cooldowns.color)
											end,
											set = function(_, r, g, b)
												DB.Cooldowns.color = {r, g, b, 1}
												UpdateDisplay()
											end
										},
										width = {
											type = "range",
											name = L["Width"],
											order = 3,
											min = 50,
											max = 500,
											step = 5,
											bigStep = 10
										},
										height = {
											type = "range",
											name = L["Height"],
											order = 4,
											min = 6,
											max = 30,
											step = 1,
											bigStep = 1
										},
										spacing = {
											type = "range",
											name = L["Spacing"],
											order = 5,
											min = 0,
											max = 30,
											step = 0.01,
											bigStep = 1
										},
										scale = {
											type = "range",
											name = L["Scale"],
											order = 6,
											min = 1,
											max = 2,
											step = 0.01,
											bigStep = 0.1
										},
										orientation = {
											type = "select",
											name = L["Orientation"],
											order = 7,
											values = {L["Right to left"], L["Left to right"]},
											get = function()
												return (DB.Cooldowns.orientation == 3) and 2 or 1
											end,
											set = function(_, val)
												DB.Cooldowns.orientation = (val == 2) and 3 or 1
												UpdateDisplay()
											end
										},
										texture = {
											type = "select",
											name = L["Texture"],
											order = 8,
											dialogControl = "LSM30_Statusbar",
											values = AceGUIWidgetLSMlists.statusbar
										},
										font = {
											type = "select",
											name = L["Font"],
											dialogControl = "LSM30_Font",
											order = 9,
											values = AceGUIWidgetLSMlists.font
										},
										fontSize = {
											type = "range",
											name = L["Font Size"],
											order = 10,
											min = 5,
											max = 30,
											step = 1
										},
										fontFlags = {
											type = "select",
											name = L["Font Outline"],
											order = 11,
											values = {
												[""] = NONE,
												["OUTLINE"] = L["Outline"],
												["THINOUTLINE"] = L["Thin outline"],
												["THICKOUTLINE"] = L["Thick outline"],
												["MONOCHROME"] = L["Monochrome"],
												["OUTLINEMONOCHROME"] = L["Outlined monochrome"]
											}
										},
										sep1 = {
											type = "description",
											name = " ",
											order = 12,
											width = "double"
										},
										maxbars = {
											type = "range",
											name = L["Max Bars"],
											order = 13,
											min = 1,
											max = 60,
											step = 1,
											bigStep = 1
										},
										growUp = {
											type = "toggle",
											name = L["Grow Upwards"],
											order = 15
										}
									}
								},
								show = {
									type = "group",
									name = L["Show"],
									order = 8,
									inline = true,
									disabled = disabled,
									args = {
										onlySelf = {
											type = "toggle",
											name = L["Only show my spells"],
											order = 1
										},
										neverSelf = {
											type = "toggle",
											name = L["Never show my spells"],
											order = 2
										},
										showIcon = {
											type = "toggle",
											name = L["Icon"],
											order = 3
										},
										showDuration = {
											type = "toggle",
											name = L["Duration"],
											order = 4
										}
									}
								}
							}
						},
						spells = {
							type = "group",
							name = SPELLS,
							order = 2,
							disabled = disabled,
							get = function(i)
								return DB.Cooldowns.spells[i.arg]
							end,
							set = function(i, val)
								if val then
									DB.Cooldowns.spells[i.arg] = true
								else
									DB.Cooldowns.spells[i.arg] = nil
								end
								UpdateDisplay()
							end,
							args = {}
						}
					}
				}

				local _order = 1
				for class, spells in pairs(cooldowns) do
					local opt = {
						type = "group",
						name = classes[class],
						order = _order,
						args = {}
					}
					for spellid in pairs(spells) do
						local spellname, _, spellicon = GetSpellInfo(spellid)
						if spellname then
							opt.args[spellname] = {
								type = "toggle",
								name = spellname,
								image = spellicon,
								imageCoords = {0.1, 0.9, 0.1, 0.9},
								arg = spellid
							}
						end
					end
					options.args.spells.args[class] = opt
					_order = _order + 1
				end
			end

			return options
		end

		function CreateDisplay()
			if display then
				if DB.Cooldowns.enabled then
					ShowDisplay()
				end
				return
			end
			SetupDatabase()
			display = RaidCooldowns:GetBarGroup(L["Raid Cooldowns"]) or RaidCooldowns:NewBarGroup(L["Raid Cooldowns"], nil, DB.Cooldowns.width, DB.Cooldowns.height, "KPackRaidCooldownsFrame")
			display:SetFlashPeriod(0)
			display:RegisterCallback("AnchorClicked", RaidCooldowns.AnchorClicked)
			display:RegisterCallback("AnchorMoved", RaidCooldowns.AnchorMoved)
			display:SetClampedToScreen(true)
			display:SetFont(core:MediaFetch("font", DB.Cooldowns.font), DB.Cooldowns.fontSize, DB.Cooldowns.fontFlags)
			display:SetTexture(core:MediaFetch("statusbar", DB.Cooldowns.texture))
			display:SetScale(DB.Cooldowns.scale)
			display:SetOrientation(DB.Cooldowns.orientation)
			display:ReverseGrowth(DB.Cooldowns.growUp)
			display:SetWidth(DB.Cooldowns.width or 150)
			display:SetHeight(DB.Cooldowns.height or 14)
			display:SetSpacing(DB.Cooldowns.spacing or 0)
			display:SetMaxBars(DB.Cooldowns.maxbars)
			core:RestorePosition(display, DB.Cooldowns)

			if DB.Cooldowns.locked then
				display:HideAnchor()
			else
				display:ShowAnchor()
			end

			if DB.Cooldowns.showIcon then
				display:ShowIcon()
			else
				display:HideIcon()
			end
		end

		function RaidCooldowns:AnchorClicked(_, btn)
			if btn == "RightButton" then
				core:OpenConfig("RaidUtility", "Cooldowns")
			end
		end

		function RaidCooldowns:AnchorMoved()
			core:SavePosition(display, DB.Cooldowns)
		end

		function ShowDisplay()
			if not display then
				CreateDisplay()
			end
			display:Show()
			RaidCooldowns:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		end

		function HideDisplay()
			if display then
				RaidCooldowns:UnregisterAllEvents()
				display:Hide()
				display = nil
			end
		end

		function LockDisplay()
			if not display then
				CreateDisplay()
			end
			display:HideAnchor()
			display:Lock()
		end

		function UnlockDisplay()
			if not display then
				CreateDisplay()
			end
			display:ShowAnchor()
			display:Unlock()
		end

		function UpdateDisplay()
			if not display then
				CreateDisplay()
			end
			display:SetFont(core:MediaFetch("font", DB.Cooldowns.font), DB.Cooldowns.fontSize, DB.Cooldowns.fontFlags)
			display:SetTexture(core:MediaFetch("statusbar", DB.Cooldowns.texture))
			display:SetScale(DB.Cooldowns.scale)
			display:ReverseGrowth(DB.Cooldowns.growUp)
			display:SetOrientation(DB.Cooldowns.orientation)
			display:SetWidth(DB.Cooldowns.width or 150)
			display:SetHeight(DB.Cooldowns.height)
			display:SetHeight(DB.Cooldowns.height)
			display:SetSpacing(DB.Cooldowns.spacing or 0)
			display:SetMaxBars(DB.Cooldowns.maxbars)
			core:RestorePosition(display, DB.Cooldowns)

			if DB.Cooldowns.locked then
				display:HideAnchor()
			else
				display:ShowAnchor()
			end

			if DB.Cooldowns.showIcon then
				display:ShowIcon()
			else
				display:HideIcon()
			end

			if DB.Cooldowns.enabled and not display:IsShown() then
				ShowDisplay()
			elseif not DB.Cooldowns.enabled and display:IsShown() then
				HideDisplay()
			end
		end

		do
			local spellList, reverseClass
			local _testUnits = {
				Priest1 = "PRIEST",
				Mage1 = "MAGE",
				Warrior1 = "WARRIOR",
				Priest2 = "PRIEST",
				Priest3 = "PRIEST",
				DeathKnight1 = "DEATHKNIGHT",
				Hunter1 = "HUNTER",
				Rogue1 = "ROGUE",
				DeathKnight2 = "DEATHKNIGHT",
				Druid1 = "DRUID",
				Paladin1 = "PALADIN",
				Warlock1 = "WARLOCK",
				Shaman1 = "SHAMAN",
				Rogue2 = "ROGUE",
				Warrior2 = "WARRIOR",
				Paladin2 = "PALADIN",
				Druid2 = "DRUID"
			}

			function RaidCooldowns:SpawnTestBar()
				if not spellList then
					spellList, reverseClass = {}, {}
					for k in pairs(allSpells) do
						spellList[#spellList + 1] = k
					end
					for name, class in pairs(_testUnits) do
						reverseClass[class] = name
					end
				end
				local spell = spellList[math.random(1, #spellList)]
				local name = GetSpellInfo(spell)
				if name then
					local unit = reverseClass[classLookup[spell]]
					local duration = (allSpells[spell] / 30) + math.random(1, 120)
					RaidCooldowns:StartCooldown(unit, spell, duration, nil)
				end
			end
		end

		function RaidCooldowns:StartCooldown(unit, spell, duration, target, class)
			if DB.Cooldowns.neverSelf and unit == core.name then
				return
			end
			if DB.Cooldowns.onlySelf and unit ~= core.name then
				return
			end

			local bar = display:GetBar(unit .. "_" .. spell)
			if not bar then
				if target and target ~= unit then
					bar = display:NewTimerBar(unit .. "_" .. spell, unit .. " > " .. target, duration, duration, spell)
				else
					bar = display:NewTimerBar(unit .. "_" .. spell, unit, duration, duration, spell)
				end
			end

			if not DB.Cooldowns.showDuration then
				bar:HideTimerLabel()
			end

			bar.caster = unit
			bar.spellId = spell
			bar.target = target

			if DB.Cooldowns.classColor then
				class = class or select(2, UnitClass(unit))
				if not class then
					for k, v in pairs(classLookup) do
						if k == spell then
							class = v
							break
						end
					end
				end

				if class then
					local color = classcolors[class]
					if type(color) == "table" then
						bar:SetColorAt(1.00, color.r, color.g, color.b, 1)
						bar:SetColorAt(0.00, color.r, color.g, color.b, 1)
					end
				end
			else
				local r, g, b, a = unpack(DB.Cooldowns.color)
				bar:SetColorAt(1.00, r, g, b, a)
				bar:SetColorAt(0.00, r, g, b, a)
			end

			display:SortBars()
		end

		do
			local events = {
				SPELL_AURA_APPLIED = true,
				SPELL_CAST_SUCCESS = true,
				SPELL_CREATE = true,
				SPELL_RESURRECT = true
			}

			local band = bit.band
			local group = 0x7
			if COMBATLOG_OBJECT_AFFILIATION_MINE then
				group = COMBATLOG_OBJECT_AFFILIATION_MINE + COMBATLOG_OBJECT_AFFILIATION_PARTY + COMBATLOG_OBJECT_AFFILIATION_RAID
			end

			function inGroup(flags)
				return flags and (band(flags, group) ~= 0) or nil
			end

			function RaidCooldowns:COMBAT_LOG_EVENT_UNFILTERED(_, arg2, _, arg4, arg5, _, arg7, _, arg9)
				if arg2 and events[arg2] and inGroup(arg5) and arg9 then
					if (arg9 == 35079 or arg9 == 34477) and DB.Cooldowns.spells[34477] then
						self:StartCooldown(arg4, 34477, allSpells[34477], arg7)
					elseif (arg9 == 59628 or arg9 == 57934) and DB.Cooldowns.spells[57934] then
						self:StartCooldown(arg4, 57934, allSpells[57934], arg7)
					elseif DB.Cooldowns.spells[arg9] then
						self:StartCooldown(arg4, arg9, allSpells[arg9], arg7)
					end
				end
			end
		end

		mod.options.args.Cooldowns = GetOptions()
		order = order + 1
		core:RegisterForEvent("PLAYER_ENTERING_WORLD", function()
			SetupDatabase()

			if DB.Cooldowns.locked then
				LockDisplay()
			else
				UnlockDisplay()
			end

			if DB.Cooldowns.enabled then
				ShowDisplay()
			else
				HideDisplay()
			end

			SLASH_KPACKCOOLDOWNS1 = "/rcd"
			SlashCmdList.KPACKCOOLDOWNS = function()
				core:OpenConfig("RaidUtility", "Cooldowns")
			end
		end)
	end

	---------------------------------------------------------------------------
	-- Auto Invites

	do
		defaults.Invites = {keyword = "", guidkeyword = ""}

		local inGuild
		local guildRanks, GetGuildRanks = {}
		local options, GetOptions
		local keyword, guidkeyword

		local DoActualInvites, DoGuildInvites, ListGuildRanks
		local inviteFrame, inviteQueue = CreateFrame("Frame"), {}

		local function CanInvite()
			return (mod:InGroup() and mod:IsPromoted()) or not mod:InGroup()
		end

		local function InviteGuild()
			if CanInvite() then
				GuildRoster()
				SendChatMessage(L["All max level characters will be invited to raid in 10 seconds. Please leave your groups."], "GUILD")
				core.After(10, function() DoGuildInvites(MAX_PLAYER_LEVEL) end)
			end
		end

		local function InviteZone()
			if CanInvite() then
				GuildRoster()
				local zone = GetRealZoneText()
				SendChatMessage(L:F("All characters in %s will be invited to raid in 10 seconds. Please leave your groups.", zone), "GUILD")
				core.After(10, function() DoGuildInvites(nil, zone) end)
			end
		end

		local function InviteRank(rank, name)
			if CanInvite() then
				GuildRoster()
				GuildControlSetRank(rank)

				local ochat = select(3, GuildControlGetRankFlags())
				local channel = ochat and "OFFICER" or "GUILD"
				SendChatMessage(L:F("All characters of rank %s or higher will be invited to raid in 10 seconds. Please leave your groups.", name), "GUILD")
				core.After(10, function() DoGuildInvites(nil, nil, rank) end)
			end
		end

		local function _convertToRaid(self, elapsed)
			self.elapsed = (self.elapsed or 0) + elapsed
			if self.elapsed > 1 then
				self.elapsed = 0
				if UnitInRaid("player") then
					DoActualInvites()
					self:SetScript("OnUpdate", nil)
				end
			end
		end

		local function _waitForParty(self, elapsed)
			self.elapsed = (self.elapsed or 0) + elapsed
			if self.elapsed > 1 then
				self.elapsed = 0
				if GetNumPartyMembers() > 0 then
					ConvertToRaid()
					self:SetScript("OnUpdate", _convertToRaid)
				end
			end
		end

		function DoActualInvites()
			if not UnitInRaid("player") then
				local num = GetNumPartyMembers() + 1
				if num == 5 then
					if #inviteQueue > 0 then
						ConvertToRaid()
						inviteFrame:SetScript("OnUpdate", _convertToRaid)
					end
				else
					local tmp = {}
					for i = 1, (5 - num) do
						local u = tremove(inviteQueue)
						if u then
							tmp[u] = true
						end
					end
					if #inviteQueue > 0 then
						inviteFrame:SetScript("OnUpdate", _waitForParty)
					end
					for k in pairs(tmp) do
						InviteUnit(k)
					end
				end
				return
			end
			for _, v in next, inviteQueue do
				InviteUnit(v)
			end
			inviteQueue = {}
		end

		function DoGuildInvites(level, zone, rank)
			for i = 1, GetNumGuildMembers() do
				local name, _, rankindex, unitlevel, _, unitzone, _, _, online = GetGuildRosterInfo(i)
				if name and online and not UnitInParty(name) and not UnitInRaid(name) then
					if
						(level and level <= unitlevel) or (zone and zone == unitzone) or
							(rank and (rankindex + 1) <= rank)
					 then
						inviteQueue[#inviteQueue + 1] = name
					end
				end
			end
			DoActualInvites()
		end

		function ListGuildRanks()
			if inGuild and not next(guildRanks) then
				for i = 1, GuildControlGetNumRanks() do
					local rankname = GuildControlGetRankName(i)
					tinsert(guildRanks, i, rankname)
				end
				return guildRanks
			end
			return guildRanks
		end

		function GetOptions()
			if not options then
				inGuild = inGuild or IsInGuild()

				options = {
					type = "group",
					name = L["Auto Invites"],
					order = order,
					args = {
						quickinvite = {
							type = "group",
							inline = true,
							name = L["Quick Invites"],
							order = 1,
							disabled = function()
								return not inGuild
							end,
							hidden = function()
								return not inGuild
							end,
							args = {
								guild = {
									type = "execute",
									name = L["Invite guild"],
									desc = L["Invite everyone in your guild at the maximum level."],
									order = 2,
									disabled = function()
										return not CanInvite()
									end,
									func = InviteGuild
								},
								zone = {
									type = "execute",
									name = L["Invite zone"],
									desc = L["Invite everyone in your guild who are in the same zone as you."],
									order = 3,
									disabled = function()
										return not CanInvite()
									end,
									func = InviteZone
								}
							}
						},
						keywordinvite = {
							type = "group",
							inline = true,
							name = L["Keyword Invites"],
							order = 2,
							args = {
								keyword = {
									type = "input",
									name = L["Keyword"],
									desc = L["Anyone who whispers you this keyword will automatically and immediately be invited to your group."],
									order = 1,
									get = function()
										return DB.Invites.keyword
									end,
									set = function(_, val)
										DB.Invites.keyword = val:trim()
										keyword = (DB.Invites.keyword ~= "") and DB.Invites.keyword or nil
									end
								},
								guidkeyword = {
									type = "input",
									name = L["Guild Keyword"],
									desc = L["Any guild member who whispers you this keyword will automatically and immediately be invited to your group."],
									order = 2,
									disabled = function()
										return not inGuild
									end,
									get = function()
										return DB.Invites.guidkeyword
									end,
									set = function(_, val)
										DB.Invites.guidkeyword = val:trim()
										guidkeyword =
											(DB.Invites.guidkeyword ~= "") and DB.Invites.guidkeyword or nil
									end
								}
							}
						},
						rankinvite = {
							type = "group",
							inline = true,
							name = L["Rank Invites"],
							descStyle = "inline",
							order = 3,
							disabled = function()
								return not inGuild
							end,
							hidden = function()
								return not inGuild
							end,
							args = {
								desc = {
									type = "description",
									name = L["Clicking any of the buttons below will invite anyone of the selected rank AND HIGHER to your group. So clicking the 3rd button will invite anyone of rank 1, 2 or 3, for example. It will first post a message in either guild or officer chat and give your guild members 10 seconds to leave their groups before doing the actual invites."],
									width = "double",
									order = 0
								}
							}
						}
					}
				}
			end
			return options
		end

		local function IsGuildMember(name)
			inGuild = inGuild or IsInGuild()
			if inGuild then
				for i = 1, GetNumGuildMembers() do
					local n = GetGuildRosterInfo(i)
					if n == name then
						return true
					end
				end
			end
			return false
		end

		inviteFrame:SetScript("OnEvent", function(self, event, msg, sender)
			if (keyword and msg == keyword) or (guidkeyword and msg == guidkeyword and IsGuildMember(sender) and CanInvite()) then
				if mod:InGroup() and (UnitInParty(sender) or UnitInRaid(sender)) then return end -- ignore trolls.

				local inInstance, instanceType = IsInInstance()
				local numparty, numraid = GetNumPartyMembers(), GetNumRaidMembers()
				if inInstance and instanceType == "party" and numparty == 4 then
					SendChatMessage(L["Sorry, the group is full."], "WHISPER", nil, sender)
				elseif numparty == 4 and numraid == 0 then
					inviteQueue[#inviteQueue + 1] = sender
					DoActualInvites()
				elseif numraid == 40 then
					SendChatMessage(L["Sorry, the group is full."], "WHISPER", nil, sender)
				else
					InviteUnit(sender)
				end
			end
		end)

		core:RegisterForEvent("PLAYER_LOGIN", function()
			SetupDatabase()
			if _G.KRU then return end

			core.After(2, function()
				inGuild = IsInGuild()
				if inGuild then GuildRoster() end

				options = options or GetOptions()
				if inGuild then
					local ranks, numorder = ListGuildRanks(), 1
					for i, name in ipairs(ranks) do
						options.args.rankinvite.args[name .. i] = {
							type = "execute",
							name = name,
							desc = L:F("Invite all guild members of rank %s or higher.", name),
							order = numorder,
							func = function()
								InviteRank(i, name)
							end,
							disabled = function()
								return not CanInvite()
							end
						}
						numorder = numorder + 1
					end
				end
				mod.options.args.Invites = options
				order = order + 1

				if DB.Invites.keyword and DB.Invites.keyword:trim() ~= "" then
					keyword = DB.Invites.keyword
				end
				if DB.Invites.guidkeyword and DB.Invites.guidkeyword:trim() ~= "" then
					guidkeyword = DB.Invites.guidkeyword
				end

				if keyword or guidkeyword then
					inviteFrame:RegisterEvent("CHAT_MSG_BN_WHISPER")
					inviteFrame:RegisterEvent("CHAT_MSG_WHISPER")
				else
					inviteFrame:UnregisterAllEvents()
				end
			end)

			SLASH_KPACKAUTOINVITES1 = "/invites"
			SlashCmdList.KPACKAUTOINVITES = function(cmd)
				cmd = cmd and cmd:lower():trim()
				if cmd == "guild" then
					InviteGuild()
				elseif cmd == "zone" then
					InviteZone()
				else
					core:OpenConfig("RaidUtility", "Invites")
				end
			end
		end)
		core:RegisterForEvent("GUILD_ROSTER_UPDATE", function()
			inGuild = IsInGuild()
			wipe(guildRanks)
			guildRanks = inGuild and ListGuildRanks() or guildRanks
		end)
	end

	---------------------------------------------------------------------------
	-- Go Go!

	function SetupDatabase()
		if not DB then
			if type(core.db.RaidUtility) ~= "table" or next(core.db.RaidUtility) == nil then
				core.db.RaidUtility = CopyTable(defaults)
			end
			DB = core.db.RaidUtility

			-- database check to fix in case of updates.
			for k, v in pairs(defaults) do
				if DB[k] == nil then
					DB[k] = CopyTable(v)
				end
			end
			-- delete old entries
			for k, v in pairs(DB) do
				if defaults[k] == nil then
					DB[k] = nil
				end
			end
		end
	end

	core:RegisterForEvent("PLAYER_LOGIN", function()
		SetupDatabase()
		if _G.KRU then return end
		CreateRaidUtilityPanel()
		core.options.args.RaidUtility = mod.options
	end)
end)