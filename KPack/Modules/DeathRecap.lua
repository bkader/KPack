local core = KPack
if not core then return end
core:AddModule("Death Recap", function(L)
	if core:IsDisabled("Death Recap") then return end

	local mod = core.DeathRecap or {}
	core.DeathRecap = mod

	local _G = _G
	local select = select
	local tonumber = tonumber
	local band = bit.band
	local math_ceil, math_floor = math.ceil, math.floor
	local format, strupper, strsub = string.format, string.upper, string.sub
	local tsort, twipe = table.sort, table.wipe

	local CannotBeResurrected = CannotBeResurrected
	local CopyTable = CopyTable
	local CreateFrame = CreateFrame
	local GetReleaseTimeRemaining = GetReleaseTimeRemaining
	local GetSpellInfo = GetSpellInfo
	local GetSpellLink = GetSpellLink
	local HasSoulstone = HasSoulstone
	local IsActiveBattlefieldArena = IsActiveBattlefieldArena
	local IsFalling = IsFalling
	local IsOutOfBounds = IsOutOfBounds
	local RepopMe = RepopMe
	local UnitHealth = UnitHealth
	local UnitHealthMax = UnitHealthMax
	local UnitIsDeadOrGhost = UnitIsDeadOrGhost
	local UseSoulstone = UseSoulstone

	local ACTION_SWING = ACTION_SWING
	local ARENA_SPECTATOR = ARENA_SPECTATOR
	local COMBATLOG_FILTER_ME = COMBATLOG_FILTER_ME
	local COMBATLOG_UNKNOWN_UNIT = COMBATLOG_UNKNOWN_UNIT
	local DEATH_RELEASE_NOTIMER = DEATH_RELEASE_NOTIMER
	local DEATH_RELEASE_SPECTATOR = DEATH_RELEASE_SPECTATOR
	local DEATH_RELEASE_TIMER = DEATH_RELEASE_TIMER
	local MINUTES = MINUTES
	local SECONDS = SECONDS
	local TEXT_MODE_A_STRING_VALUE_SCHOOL = TEXT_MODE_A_STRING_VALUE_SCHOOL

	local lastDeathEvents
	local index = 0
	local deathList = {}
	local eventList = {}

	-- local functions
	local AddEvent
	local HasEvents
	local EraseEvents
	local AddDeath
	local GetDeathEvents
	local GetTableInfo
	local OpenRecap
	local Spell_OnEnter
	local Amount_OnEnter
	local CreateDeathRecapFrame
	local KPackDeathRecapFrame

	function AddEvent(timestamp, event, srcName, spellId, spellName, environmentalType, amount, overkill, school, resisted, blocked, absorbed)
		if index > 0 and eventList[index].timestamp + 10 <= timestamp then
			index = 0
			twipe(eventList)
		end

		if index < 5 then
			index = index + 1
		else
			index = 1
		end

		if not eventList[index] then
			eventList[index] = {}
		else
			twipe(eventList[index])
		end

		eventList[index].timestamp = timestamp
		eventList[index].event = event
		eventList[index].srcName = srcName
		eventList[index].spellId = spellId
		eventList[index].spellName = spellName
		eventList[index].environmentalType = environmentalType
		eventList[index].amount = amount
		eventList[index].overkill = overkill
		eventList[index].school = school
		eventList[index].resisted = resisted
		eventList[index].blocked = blocked
		eventList[index].absorbed = absorbed
		eventList[index].currentHP = UnitHealth("player")
		eventList[index].maxHP = UnitHealthMax("player")
	end

	function HasEvents()
		if lastDeathEvents then
			return #deathList > 0, #deathList
		else
			return false, #deathList
		end
	end

	function EraseEvents()
		if index > 0 then
			index = 0
			twipe(eventList)
		end
	end

	function AddDeath()
		if #eventList > 0 then
			local _, deathEvents = HasEvents()
			local deathIndex = deathEvents + 1
			deathList[deathIndex] = CopyTable(eventList)
			EraseEvents()
			return true
		end
		return false
	end

	function GetDeathEvents(recapID)
		if recapID and deathList[recapID] then
			local deathEvents = deathList[recapID]
			tsort(deathEvents, function(a, b) return a.timestamp > b.timestamp end)
			return deathEvents
		end
	end

	function GetTableInfo(data)
		local texture
		local nameIsNotSpell = false

		local event = data.event
		local spellId = data.spellId
		local spellName = data.spellName

		if event == "SWING_DAMAGE" then
			spellId = 6603
			spellName = ACTION_SWING

			nameIsNotSpell = true
		elseif event == "RANGE_DAMAGE" then
			nameIsNotSpell = true
		elseif event == "ENVIRONMENTAL_DAMAGE" then
			local environmentalType = data.environmentalType
			environmentalType = strupper(environmentalType)
			spellName = _G["ACTION_ENVIRONMENTAL_DAMAGE_" .. environmentalType]
			nameIsNotSpell = true

			if environmentalType == "DROWNING" then
				texture = "spell_shadow_demonbreath"
			elseif environmentalType == "FALLING" then
				texture = "ability_rogue_quickrecovery"
			elseif environmentalType == "FIRE" or environmentalType == "LAVA" then
				texture = "spell_fire_fire"
			elseif environmentalType == "SLIME" then
				texture = "inv_misc_slime_01"
			elseif environmentalType == "FATIGUE" then
				texture = "ability_creature_cursed_05"
			else
				texture = "ability_creature_cursed_05"
			end

			texture = "Interface\\Icons\\" .. texture
		end

		if spellName and nameIsNotSpell then
			spellName = format("|Haction:%s|h%s|h", event, spellName)
		end

		if spellId and not texture then
			texture = select(3, GetSpellInfo(spellId))
		end

		return spellId, spellName, texture
	end

	function OpenRecap(recapID)
		local self = KPackDeathRecapFrame

		if self:IsShown() and self.recapID == recapID then
			self:Hide()
			return
		end

		local deathEvents = GetDeathEvents(recapID)
		if not deathEvents then
			return
		end

		self.recapID = recapID

		if not deathEvents or #deathEvents <= 0 then
			for i = 1, 5 do
				self.DeathRecapEntry[i]:Hide()
			end

			self.Unavailable:Show()
			return
		end

		self.Unavailable:Hide()

		local highestDmgIdx, highestDmgAmount = 1, 0
		self.DeathTimeStamp = nil

		for i = 1, #deathEvents do
			local entry = self.DeathRecapEntry[i]
			local dmgInfo = entry.DamageInfo
			local evtData = deathEvents[i]
			local spellId, spellName, texture = GetTableInfo(evtData)

			entry:Show()
			self.DeathTimeStamp = self.DeathTimeStamp or evtData.timestamp

			if evtData.amount then
				local amountStr = -evtData.amount
				dmgInfo.Amount:SetText(amountStr)
				dmgInfo.AmountLarge:SetText(amountStr)
				dmgInfo.amount = evtData.amount

				dmgInfo.dmgExtraStr = ""
				if evtData.overkill and evtData.overkill > 0 then
					dmgInfo.dmgExtraStr = L:F("(%d Overkill)", evtData.overkill)
					dmgInfo.amount = evtData.amount - evtData.overkill
				end
				if evtData.absorbed and evtData.absorbed > 0 then
					dmgInfo.dmgExtraStr = dmgInfo.dmgExtraStr .. " " .. L:F("(%d Absorbed)", evtData.absorbed)
					dmgInfo.amount = evtData.amount - evtData.absorbed
				end
				if evtData.resisted and evtData.resisted > 0 then
					dmgInfo.dmgExtraStr = dmgInfo.dmgExtraStr .. " " .. L:F("(%d Resisted)", evtData.resisted)
					dmgInfo.amount = evtData.amount - evtData.resisted
				end
				if evtData.blocked and evtData.blocked > 0 then
					dmgInfo.dmgExtraStr = dmgInfo.dmgExtraStr .. " " .. L:F("(%d Blocked)", evtData.blocked)
					dmgInfo.amount = evtData.amount - evtData.blocked
				end

				if evtData.amount > highestDmgAmount then
					highestDmgIdx = i
					highestDmgAmount = evtData.amount
				end

				dmgInfo.Amount:Show()
				dmgInfo.AmountLarge:Hide()
			else
				dmgInfo.Amount:SetText("")
				dmgInfo.AmountLarge:SetText("")
				dmgInfo.amount = nil
				dmgInfo.dmgExtraStr = nil
			end

			dmgInfo.timestamp = evtData.timestamp
			dmgInfo.hpPercent = math_floor(evtData.currentHP / evtData.maxHP * 100)

			dmgInfo.spellName = spellName

			dmgInfo.caster = evtData.srcName or COMBATLOG_UNKNOWN_UNIT

			if evtData.school and evtData.school > 1 then
				local colorArray = CombatLog_Color_ColorArrayBySchool(evtData.school)
				entry.SpellInfo.FrameIcon:SetBackdropBorderColor(colorArray.r, colorArray.g, colorArray.b)
			else
				entry.SpellInfo.FrameIcon:SetBackdropBorderColor(0, 0, 0)
			end

			dmgInfo.school = evtData.school

			entry.SpellInfo.Caster:SetText(dmgInfo.caster)

			entry.SpellInfo.Name:SetText(spellName)
			entry.SpellInfo.Icon:SetTexture(texture)

			entry.SpellInfo.spellId = spellId
		end

		for i = #deathEvents + 1, #self.DeathRecapEntry do
			self.DeathRecapEntry[i]:Hide()
		end

		local entry = self.DeathRecapEntry[highestDmgIdx]
		if entry.DamageInfo.amount then
			entry.DamageInfo.Amount:Hide()
			entry.DamageInfo.AmountLarge:Show()
		end

		local deathEntry = self.DeathRecapEntry[1]
		local tombstoneIcon = deathEntry.tombstone
		if entry == deathEntry then
			tombstoneIcon:SetPoint("RIGHT", deathEntry.DamageInfo.AmountLarge, "LEFT", -10, 0)
		end

		self:Show()
	end

	function Spell_OnEnter(self)
		if self.spellId then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetHyperlink(GetSpellLink(self.spellId))
			GameTooltip:Show()
		end
	end

	function Amount_OnEnter(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:ClearLines()

		if self.amount then
			local valueStr = self.school and format(TEXT_MODE_A_STRING_VALUE_SCHOOL, self.amount, CombatLog_String_SchoolString(self.school)) or self.amount
			GameTooltip:AddLine(L:F("%s %s", valueStr, self.dmgExtraStr), 1, 0, 0, false)
		end

		if self.spellName then
			if self.caster then
				GameTooltip:AddLine(L:F("%s by %s", self.spellName, self.caster), 1, 1, 1, true)
			else
				GameTooltip:AddLine(self.spellName, 1, 1, 1, true)
			end
		end

		local seconds = (KPackDeathRecapFrame.DeathTimeStamp or 0) - self.timestamp
		if seconds > 0 then
			GameTooltip:AddLine(L:F("%s sec before death at %s%% health.", format("%.1F", seconds), self.hpPercent), 1, 0.824, 0, 1)
		else
			GameTooltip:AddLine(L:F("Killing blow at %s%% health.", self.hpPercent), 1, 0.824, 0, true)
		end

		GameTooltip:Show()
	end

	function CreateDeathRecapFrame()
		if KPackDeathRecapFrame then
			return
		end

		KPackDeathRecapFrame = CreateFrame("Frame", "KPackDeathRecapFrame", UIParent)
		KPackDeathRecapFrame:SetBackdrop({
			bgFile = [[Interface\DialogFrame\UI-DialogBox-Background-Dark]],
			edgeFile = [[Interface\DialogFrame\UI-DialogBox-Border]],
			edgeSize = 8,
			insets = {left = 1, right = 1, top = 1, bottom = 1}
		})
		KPackDeathRecapFrame:SetBackdropColor(0, 0, 1, 0.85)
		KPackDeathRecapFrame:SetFrameStrata("HIGH")
		KPackDeathRecapFrame:SetSize(340, 326)
		KPackDeathRecapFrame:SetPoint("CENTER")
		KPackDeathRecapFrame:SetMovable(true)
		KPackDeathRecapFrame:Hide()
		KPackDeathRecapFrame:SetScript("OnHide", function(self) self.recapID = nil end)
		tinsert(UISpecialFrames, KPackDeathRecapFrame:GetName())

		KPackDeathRecapFrame.Title = KPackDeathRecapFrame:CreateFontString("ARTWORK", nil, "GameFontNormalLarge")
		KPackDeathRecapFrame.Title:SetPoint("TOP", 0, -9)
		KPackDeathRecapFrame.Title:SetText(L["Death Recap"])

		KPackDeathRecapFrame.Unavailable = KPackDeathRecapFrame:CreateFontString("ARTWORK", nil, "GameFontNormal")
		KPackDeathRecapFrame.Unavailable:SetPoint("CENTER")
		KPackDeathRecapFrame.Unavailable:SetText(L["Death Recap unavailable."])

		KPackDeathRecapFrame.CloseXButton = CreateFrame("Button", "$parentCloseXButton", KPackDeathRecapFrame)
		KPackDeathRecapFrame.CloseXButton:SetSize(32, 32)
		KPackDeathRecapFrame.CloseXButton:SetPoint("TOPRIGHT", 2, 1)
		KPackDeathRecapFrame.CloseXButton:SetScript("OnClick", function(self) self:GetParent():Hide() end)

		KPackDeathRecapFrame.DragButton = CreateFrame("Button", "$parentDragButton", KPackDeathRecapFrame)
		KPackDeathRecapFrame.DragButton:SetPoint("TOPLEFT", 0, 0)
		KPackDeathRecapFrame.DragButton:SetPoint("BOTTOMRIGHT", KPackDeathRecapFrame, "TOPRIGHT", 0, -32)
		KPackDeathRecapFrame.DragButton:RegisterForDrag("LeftButton")
		KPackDeathRecapFrame.DragButton:SetScript("OnDragStart", function(self) self:GetParent():StartMoving() end)
		KPackDeathRecapFrame.DragButton:SetScript("OnDragStop", function(self) self:GetParent():StopMovingOrSizing() end)

		KPackDeathRecapFrame.DeathRecapEntry = {}

		for i = 1, 5 do
			local button = CreateFrame("Frame", nil, KPackDeathRecapFrame)
			button:SetSize(308, 32)
			KPackDeathRecapFrame.DeathRecapEntry[i] = button

			button.DamageInfo = CreateFrame("Button", nil, button)
			button.DamageInfo:SetPoint("TOPLEFT", 0, 0)
			button.DamageInfo:SetPoint("BOTTOMRIGHT", button, "BOTTOMLEFT", 80, 0)
			button.DamageInfo:SetScript("OnEnter", Amount_OnEnter)
			button.DamageInfo:SetScript("OnLeave", GameTooltip_Hide)

			button.DamageInfo.Amount = button.DamageInfo:CreateFontString("ARTWORK", nil, "GameFontNormalRight")
			button.DamageInfo.Amount:SetJustifyH("RIGHT")
			button.DamageInfo.Amount:SetJustifyV("CENTER")
			button.DamageInfo.Amount:SetSize(0, 32)
			button.DamageInfo.Amount:SetPoint("TOPRIGHT", 0, 0)
			button.DamageInfo.Amount:SetTextColor(0.75, 0.05, 0.05, 1)

			button.DamageInfo.AmountLarge = button.DamageInfo:CreateFontString("ARTWORK", nil, "NumberFont_Outline_Large")
			button.DamageInfo.AmountLarge:SetJustifyH("RIGHT")
			button.DamageInfo.AmountLarge:SetJustifyV("CENTER")
			button.DamageInfo.AmountLarge:SetSize(0, 32)
			button.DamageInfo.AmountLarge:SetPoint("TOPRIGHT", 0, 0)
			button.DamageInfo.AmountLarge:SetTextColor(1, 0.07, 0.07, 1)

			button.SpellInfo = CreateFrame("Button", nil, button)
			button.SpellInfo:SetPoint("TOPLEFT", button.DamageInfo, "TOPRIGHT", 16, 0)
			button.SpellInfo:SetPoint("BOTTOMRIGHT", 0, 0)
			button.SpellInfo:SetScript("OnEnter", Spell_OnEnter)
			button.SpellInfo:SetScript("OnLeave", GameTooltip_Hide)

			button.SpellInfo.FrameIcon = CreateFrame("Button", nil, button.SpellInfo)
			button.SpellInfo.FrameIcon:SetSize(34, 34)
			button.SpellInfo.FrameIcon:SetPoint("LEFT", 0, 0)

			button.SpellInfo.Icon = button.SpellInfo:CreateTexture(nil, "ARTWORK")
			button.SpellInfo.Icon:SetParent(button.SpellInfo.FrameIcon)
			button.SpellInfo.Icon:SetAllPoints(true)

			button.SpellInfo.Name = button.SpellInfo:CreateFontString("ARTWORK", nil, "GameFontNormal")
			button.SpellInfo.Name:SetJustifyH("LEFT")
			button.SpellInfo.Name:SetJustifyV("BOTTOM")
			button.SpellInfo.Name:SetPoint("BOTTOMLEFT", button.SpellInfo.Icon, "RIGHT", 8, 1)
			button.SpellInfo.Name:SetPoint("TOPRIGHT", 0, 0)

			button.SpellInfo.Caster = button.SpellInfo:CreateFontString("ARTWORK", nil, "SystemFont_Shadow_Small")
			button.SpellInfo.Caster:SetJustifyH("LEFT")
			button.SpellInfo.Caster:SetJustifyV("TOP")
			button.SpellInfo.Caster:SetPoint("TOPLEFT", button.SpellInfo.Icon, "RIGHT", 8, -2)
			button.SpellInfo.Caster:SetPoint("BOTTOMRIGHT", 0, 0)
			button.SpellInfo.Caster:SetTextColor(0.5, 0.5, 0.5, 1)

			if i == 1 then
				button:SetPoint("BOTTOMLEFT", 16, 64)
				button.tombstone = button:CreateTexture(nil, "ARTWORK")
				button.tombstone:SetSize(20, 20)
				button.tombstone:SetPoint("RIGHT", button.DamageInfo.Amount, "LEFT", -10, 0)
				button.tombstone:SetTexture("Interface\\Icons\\Ability_Rogue_FeignDeath")
			else
				button:SetPoint("BOTTOM", KPackDeathRecapFrame.DeathRecapEntry[i - 1], "TOP", 0, 14)
			end
		end

		local closebutton = CreateFrame("Button", "KPackDeathRecapFrameCloseButton", KPackDeathRecapFrame, "KPackButtonTemplate")
		closebutton:SetSize(144, 21)
		closebutton:SetPoint("BOTTOM", 0, 15)
		closebutton:SetText(CLOSE)
		closebutton:SetScript("OnClick", function(self) KPackDeathRecapFrame:Hide() end)

		-- replace blizzard default
		StaticPopupDialogs["KDEATH"] = {
			text = DEATH_RELEASE_TIMER,
			button1 = DEATH_RELEASE,
			button2 = USE_SOULSTONE,
			button3 = L["Death Recap"],
			OnShow = function(self)
				self.timeleft = GetReleaseTimeRemaining()
				local text = HasSoulstone()
				if text then
					self.button2:SetText(text)
				elseif core.class ~= "SHAMAN" then
					self.fixme = true
				end

				if IsActiveBattlefieldArena() then
					self.text:SetText(DEATH_RELEASE_SPECTATOR)
				elseif (self.timeleft == -1) then
					self.text:SetText(DEATH_RELEASE_NOTIMER)
				end
				if HasEvents() then
					self.button3:Enable()
					self.button3:SetScript("OnEnter", nil)
					self.button3:SetScript("OnLeave", nil)
				else
					self.button3:Disable()
					self.button3:SetScript("OnEnter", function(self)
						GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
						GameTooltip:SetText(L["Death Recap unavailable."])
						GameTooltip:Show()
					end)
					self.button3:SetScript("OnLeave", GameTooltip_Hide)
				end
			end,
			OnHide = function(self)
				self.button3:SetScript("OnEnter", nil)
				self.button3:SetScript("OnLeave", nil)
			end,
			OnAccept = function(self)
				if IsActiveBattlefieldArena() then
					local info = ChatTypeInfo["SYSTEM"]
					DEFAULT_CHAT_FRAME:AddMessage(ARENA_SPECTATOR, info.r, info.g, info.b, info.id)
				end
				RepopMe()
				if CannotBeResurrected() then
					return 1
				end
			end,
			OnCancel = function(self, data, reason)
				if reason == "override" then
					return
				end
				if reason == "timeout" then
					return
				end
				if reason == "clicked" then
					if HasSoulstone() then
						UseSoulstone()
					else
						RepopMe()
					end
					if CannotBeResurrected() then
						return 1
					end
				end
			end,
			OnAlt = function(self)
				core.After(0.01, function()
					if not StaticPopup_FindVisible("KDEATH") then
						StaticPopup_Show("KDEATH", GetReleaseTimeRemaining(), SECONDS)
					end
				end)
				OpenRecap(select(2, HasEvents()))
			end,
			OnUpdate = function(self, elapsed)
				if self.timeleft > 0 then
					local text = _G[self:GetName() .. "Text"]
					local timeleft = self.timeleft
					if timeleft < 60 then
						text:SetFormattedText(DEATH_RELEASE_TIMER, timeleft, SECONDS)
					else
						text:SetFormattedText(DEATH_RELEASE_TIMER, math_ceil(timeleft / 60), MINUTES)
					end
				end
				if IsFalling() and (not IsOutOfBounds()) then
					self.button1:Disable()
					self.button2:Disable()
				elseif HasSoulstone() then
					self.button1:Enable()
					self.button2:Enable()
				else
					self.button1:Enable()
					self.button2:Disable()
				end

				if self.fixme then
					self:SetWidth(320)

					self.button2:Hide()
					self.button1:ClearAllPoints()
					if self.button3:IsShown() then
						self.button1:SetPoint("BOTTOMRIGHT", self, "BOTTOM", -6, 16)
						self.button3:ClearAllPoints()
						self.button3:SetPoint("LEFT", self.button1, "RIGHT", 13, 0)
					else
						self.button1:SetPoint("BOTTOM", self, "BOTTOM", 0, 16)
					end

					self.fixme = nil
				end
			end,
			DisplayButton2 = function(self)
				return HasSoulstone()
			end,
			DisplayButton3 = function(self)
				return HasEvents()
			end,
			timeout = 0,
			whileDead = 1,
			interruptCinematic = 1,
			notClosableByLogout = 1,
			cancels = "RECOVER_CORPSE"
		}
	end

	core:RegisterForEvent("PLAYER_LOGIN", CreateDeathRecapFrame)

	function mod:HideDeathPopup()
		StaticPopup_Hide("KDEATH")
	end

	core:RegisterForEvent("PLAYER_ENTERING_WORLD", mod.HideDeathPopup)
	core:RegisterForEvent("RESURRECT_REQUEST", mod.HideDeathPopup)
	core:RegisterForEvent("PLAYER_ALIVE", mod.HideDeathPopup)
	core:RegisterForEvent("RAISED_AS_GHOUL", mod.HideDeathPopup)

	core:RegisterForEvent("PLAYER_DEAD", function()
		if StaticPopup_FindVisible("DEATH") then
			lastDeathEvents = (AddDeath() == true)
			StaticPopup_Hide("DEATH")
			StaticPopup_Show("KDEATH", GetReleaseTimeRemaining(), SECONDS)
		end
	end)

	local validEvents = {
		ENVIRONMENTAL_DAMAGE = true,
		RANGE_DAMAGE = true,
		SPELL_DAMAGE = true,
		SPELL_EXTRA_ATTACKS = true,
		SPELL_INSTAKILL = true,
		SPELL_PERIODIC_DAMAGE = true,
		SWING_DAMAGE = true
	}

	core:RegisterForEvent("COMBAT_LOG_EVENT_UNFILTERED", function(_, timestamp, event, _, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
			if (band(dstFlags, COMBATLOG_FILTER_ME) ~= COMBATLOG_FILTER_ME) or (band(srcFlags, COMBATLOG_FILTER_ME) == COMBATLOG_FILTER_ME) or (not validEvents[event]) then
				return
			end

			local subVal = strsub(event, 1, 5)
			local environmentalType, spellId, spellName, amount, overkill, school, resisted, blocked, absorbed

			if event == "SWING_DAMAGE" then
				amount, overkill, school, resisted, blocked, absorbed = ...
			elseif subVal == "SPELL" then
				spellId, spellName, _, amount, overkill, school, resisted, blocked, absorbed = ...
			elseif event == "ENVIRONMENTAL_DAMAGE" then
				environmentalType, amount, overkill, school, resisted, blocked, absorbed = ...
			end

			if not tonumber(amount) then
				return
			end

			AddEvent(timestamp, event, srcName, spellId, spellName, environmentalType, amount, overkill, school, resisted, blocked, absorbed)
		end
	)
end)