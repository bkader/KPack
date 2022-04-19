local core = KPack
if not core then return end
core:AddModule("Castbars", "Castbars is a lightweight, efficient and easy to use enhancement of the Blizzard castbars.", function(L)
	if core:IsDisabled("Castbars") or core.ElvUI then return end

	local Castbars = core.Castbars or {}
	core.Castbars = Castbars

	Castbars.DoNothing = function() end

	local GetSpellInfo = GetSpellInfo

	Castbars.BaseTickDuration = {
		-- Warlock
		[GetSpellInfo(689)] = 1, -- Drain Life
		[GetSpellInfo(1120)] = 3, -- Drain Soul
		[GetSpellInfo(5138)] = 1, -- Drain Mana
		[GetSpellInfo(755)] = 1, -- Health Funnel
		[GetSpellInfo(5740)] = 2, -- Rain of Fire
		[GetSpellInfo(1949)] = 1, -- Hellfire
		-- Druid
		[GetSpellInfo(740)] = 2, -- Tranquility
		[GetSpellInfo(16914)] = 1, -- Hurricane
		-- Priest
		[GetSpellInfo(47540)] = 1, -- Penance
		[GetSpellInfo(15407)] = 0.75, -- Mind Flay
		[GetSpellInfo(48045)] = 1, -- Mind Sear
		[GetSpellInfo(64843)] = 2, -- Divine Hymn
		[GetSpellInfo(64901)] = 2, -- Hymn of Hope
		-- Mage
		[GetSpellInfo(10)] = 1, -- Blizzard
		[GetSpellInfo(5143)] = 0.75, -- Arcane Missiles
		[GetSpellInfo(12051)] = 2, -- Evocation
		-- Hunter
		[GetSpellInfo(1510)] = 1 -- Volley
	}

	Castbars.Barticks = setmetatable({}, { __index = function(tick, i)
		local spark = CastingBarFrame:CreateTexture(nil, "ARTWORK")
		tick[i] = spark
		spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
		spark:SetVertexColor(1, 1, 1, 0.5)
		spark:SetBlendMode("ADD")
		spark:SetWidth(10)
		return spark
	end})

	local autoshotname, shootname, slamname = GetSpellInfo(75), GetSpellInfo(5019), GetSpellInfo(1464)
	local swingResetSpells = {
		[GetSpellInfo(845)] = true, -- Cleave
		[GetSpellInfo(78)] = true, -- Heroic Strike
		[GetSpellInfo(6807)] = true, -- Maul
		[GetSpellInfo(2973)] = true, -- Raptor Strike
		[GetSpellInfo(56815)] = true, -- Rune Strike
	}

	local function Castbars_SpellToTicks(spellName, actualDuration)
		local baseTickDuration = Castbars.BaseTickDuration[spellName]
		if baseTickDuration then
			local castTime = select(7, GetSpellInfo(2060))
			local haste = 3000 / (castTime or 3000)
			return floor(haste * actualDuration / baseTickDuration + 0.5)
		end
		return 0
	end

	local function Castbars_CastingBarFrameTicksSet(ticks)
		for _, tick in ipairs(Castbars.Barticks) do
			tick:Hide()
		end
		if ticks and ticks > 0 then
			local delta = (Castbars.db["CastingBarFrame"]["Width"] / ticks)
			for i = 1, ticks - 1 do
				local tick = Castbars.Barticks[i]
				tick:SetHeight(Castbars.db["CastingBarFrame"]["Height"] * 1.5)
				tick:SetPoint("CENTER", CastingBarFrame, "LEFT", delta * i, 0)
				tick:Show()
			end
		end
	end

	local function Castbars_IsDualWielding()
		local ohlow, ohhigh = select(3, UnitDamage("player"))
		return (core.class ~= "DRUID" and ohlow ~= ohhigh)
	end

	local function Castbars_FrameMediaRestore(frame)
		local barTexture = core:MediaFetch("statusbar", Castbars.db[frame.configName]["Texture"])
		local borderTexture = core:MediaFetch("border", Castbars.db[frame.configName]["Border"])
		local font = core:MediaFetch("font", Castbars.db[frame.configName]["Font"])
		if barTexture then
			frame.statusBar:SetStatusBarTexture(barTexture)
			if frame.latency then
				frame.latency:SetTexture(barTexture)
			end
		end
		if borderTexture then
			local edgeSize = ((Castbars.db[frame.configName]["Height"]) - 2) / 1.5
			frame.borderWidth = (edgeSize + 2 / 1.5) / 2
			if edgeSize > 16 then
				edgeSize = 16
				frame.borderWidth = edgeSize / 2
			end
			frame.backdrop:SetBackdrop({edgeFile = borderTexture, edgeSize = edgeSize})
			frame.backdrop:SetBackdropBorderColor(unpack(Castbars.db[frame.configName]["BorderColor"]))
		end
		if font then
			local textSize = Castbars.db[frame.configName]["FontSize"]
			local outline = Castbars.db[frame.configName]["FontOutline"] and "OUTLINE" or nil
			frame.text:SetFont(font, textSize, outline)
			if frame.timer then
				frame.timer:SetFont(font, textSize, outline)
			end
		end
	end

	function Castbars:FrameMediaRestoreAll()
		for i, frame in pairs(self.frames) do
			Castbars_FrameMediaRestore(frame)
		end
	end

	local function Castbars_FrameTimerRestore(frame, adjustTextWidth)
		if frame.timer then
			if frame.mergingTradeSkill then
				if frame.casting and frame.maxValue == frame.maxValueMerge then
					local secLeft = max(frame.maxValue - frame.value, 0)
					local minLeft = floor(secLeft / 60)
					frame.timer:SetFormattedText("%d/%d - %d:%02d", frame.countCurrent, frame.countTotal, minLeft, secLeft - minLeft * 60)
				end
			elseif frame.casting then
				if frame.delayTime and Castbars.db[frame.configName]["ShowPushback"] then
					frame.timer:SetFormattedText("|cFFFF0000+%.1f |cFFFFFFFF" .. frame.castTimeFormat, frame.delayTime, max(frame.maxValue - frame.value, 0), frame.maxValue)
				else
					frame.timer:SetFormattedText(frame.castTimeFormat, max(frame.maxValue - frame.value, 0), frame.maxValue + (frame.delayTime or 0))
				end
			elseif frame.channeling then
				frame.timer:SetFormattedText(frame.castTimeFormat, max(frame.value, 0), frame.maxValue)
			elseif Castbars.ConfigMode then
				if Castbars.db[frame.configName]["ShowPushback"] then
					frame.timer:SetFormattedText("|cFFFF0000+%.1f |cFFFFFFFF" .. frame.castTimeFormat, 0, 0, 0)
				else
					frame.timer:SetFormattedText(frame.castTimeFormat, 0, 0)
				end
			else
				frame.timer:SetText()
			end
			if frame.text and adjustTextWidth then
				frame.text:SetWidthReal(frame:GetWidth() - 10 - frame.timer:GetWidth())
			end
		end
	end

	local function Castbars_FrameColorRestore(frame)
		if frame.shield and frame.shield:IsShown() or frame.outOfRange then
			frame.statusBar:SetStatusBarColor(0.6, 0.6, 0.6)
			return
		end
		local r, g, b = unpack(Castbars.db[frame.configName]["BarColor"])
		if Castbars.db[frame.configName]["ClassColor"] and core.mycolor then
			r, g, b = core.mycolor.r, core.mycolor.g, core.mycolor.b
		end
		frame.statusBar:SetStatusBarColor(r, g, b)
		frame.shade:SetTexture(r * 0.1, g * 0.1, b * 0.1, 0.5)
	end

	local function Castbars_FrameIconRestore(frame)
		if frame.icon then
			if frame.shield and frame.shield:IsShown() and (Castbars.db[frame.configName]["ShowShield"]) then
				local hb, wb = frame.shield:GetHeight(), frame.shield:GetWidth()
				frame.icon:ClearAllPoints()
				frame.icon:SetPoint("TOPRIGHT", frame, "TOPLEFT", -0.03515625 * wb, 0.09375 * hb)
				frame.icon:SetHeight(0.328125 * hb)
				frame.icon:SetWidth(0.08203125 * wb)
				frame.icon:Show()
			elseif Castbars.db[frame.configName]["ShowIcon"] then
				frame.icon:ClearAllPoints()
				if Castbars.db[frame.configName]["Border"] == "None" then
					frame.icon:SetPoint("RIGHT", frame, "LEFT", 0, 0)
					frame.icon:SetHeight(Castbars.db[frame.configName]["Height"])
					frame.icon:SetWidth(Castbars.db[frame.configName]["Height"])
				else
					frame.icon:SetPoint("RIGHT", frame, "LEFT", -3, 0)
					frame.icon:SetHeight(Castbars.db[frame.configName]["Height"])
					frame.icon:SetWidth(Castbars.db[frame.configName]["Height"])
				end
				frame.icon:Show()
			else
				frame.icon:Hide()
			end
		end
	end

	local function Castbars_FrameRestoreOnCast(frame, unit, adjustTextWidth)
		Castbars_FrameColorRestore(frame)
		Castbars_FrameIconRestore(frame)
		Castbars_FrameTimerRestore(frame, adjustTextWidth)
		if unit == "player" and frame.unit == "player" then
			if frame.latency and Castbars.db[frame.configName]["ShowLatency"] and frame.sentTime and not frame.mergingTradeSkill then
				local min, max = frame:GetMinMaxValues()
				local latency = (GetTime() - frame.sentTime) / (max - min)
				frame.sentTime = nil
				if latency < 0 then
					latency = 0
				elseif latency > 1 then
					latency = 1
				end
				frame.latency:SetWidth(frame:GetWidth() * latency)
				frame.latency:ClearAllPoints()
				if frame.channeling then
					frame.latency:SetTexCoord(0, latency, 0, 1)
					frame.latency:SetPoint("LEFT", frame, "LEFT", 0, 0)
				else
					frame.latency:SetTexCoord(1 - latency, 1, 0, 1)
					frame.latency:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
				end
				frame.latency:Show()
			end
			local barText = frame.text:GetText()
			if frame.channeling then
				barText = frame.spellName
			elseif barText ~= frame.spellName and frame.spellTargetName then
				barText = frame.spellTargetName
			end
			if Castbars.db[frame.configName]["ShowSpellRank"] and frame.spellRank and frame.spellRank ~= "" and frame.spellRank ~= barText then
				barText = ("%s (%s)"):format(barText, frame.spellRank)
			end
			if Castbars.db[frame.configName]["ShowSpellTarget"] and frame.spellTargetName and frame.spellTargetName ~= "" and frame.spellTargetName ~= barText then
				frame.text:SetFormattedText("%s -> %s", barText, frame.spellTargetName)
			else
				frame.text:SetText(barText)
			end
		end
	end

	local function Castbars_FrameLayoutRestore(frame)
		local position = Castbars.db[frame.configName]["Position"]
		if frame.dragable and position then
			frame:clearAllPoints()
			frame:setPoint(position.point, position.parent, position.relpoint, position.x, position.y)
		end
		Castbars_FrameMediaRestore(frame)
		if Castbars.db[frame.configName]["Show"] then
			if frame == PetCastingBarFrame then
				frame.showCastbar = Castbars.db[frame.configName]["Show"] or UnitIsPossessed("pet")
			else
				frame.showCastbar = true
			end
		else
			frame.showCastbar = false
		end

		if frame.shield then
			if Castbars.db[frame.configName]["ShowShield"] then
				frame.shield:SetTexture("Interface\\CastingBar\\UI-CastingBar-Small-Shield")
				frame.shield:SetGradientAlpha("HORIZONTAL", 1, 1, 1, 0.5, 1, 1, 1, 0.5)
			else
				frame.shield:SetTexture()
			end
		end

		if frame.timer then
			frame.castTimeFormat = "%.1f"
			if Castbars.db[frame.configName]["ShowTotalCastTime"] then
				frame.castTimeFormat = frame.castTimeFormat .. "/%." .. (Castbars.db[frame.configName]["TotalCastTimeDecimals"] or "1") .. "f"
			end
			if Castbars.db[frame.configName]["ShowPushback"] then
				frame.timer:SetFormattedText("|cFFFF0000+%.1f |cFFFFFFFF" .. frame.castTimeFormat, 0, 0, 0)
			else
				frame.timer:SetFormattedText(frame.castTimeFormat, 0, 0)
			end
		end

		if frame.swing then
			frame.swing:UnregisterAllEvents()
			if Castbars.db[frame.configName]["ShowSwingTimer"] then
				frame.swing:RegisterEvent("PLAYER_REGEN_ENABLED")
				frame.swing:RegisterEvent("STOP_AUTOREPEAT_SPELL")
				frame.swing:RegisterEvent("UNIT_ATTACK_SPEED")
				frame.swing:RegisterEvent("UNIT_RANGEDDAMAGE")
				frame.swing:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
				frame.swing:RegisterEvent("UNIT_SPELLCAST_START")
				frame.swing:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
				frame.swing:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
				local r, g, b = unpack(Castbars.db[frame.configName]["BarColor"])
				frame.swing.texture:SetTexture(r, g, b)
			end
		end

		frame.text:SetJustifyH(Castbars.db[frame.configName]["TextAlignment"])

		frame:SetWidth(Castbars.db[frame.configName]["Width"])
		frame:SetHeight(Castbars.db[frame.configName]["Height"])

		Castbars_FrameRestoreOnCast(frame)
	end

	local function Castbars_FrameLayoutRestoreAll()
		for _, frame in pairs(Castbars.frames) do
			Castbars_FrameLayoutRestore(frame)
		end
	end

	local function Castbars_FrameCustomize(frame)
		local frameName = frame:GetName()
		local frameType

		if frameName:sub(1, 11) == "MirrorTimer" then
			local index = tonumber(frameName:sub(12, 12))
			frameType = "Mirror"
			frame.statusBar = _G[frameName .. "StatusBar"]
			frame.configName = "MirrorTimer"
			frame.friendlyName = L:F("Mirror Timer %d", index)
			if index == 1 then
				frame.dragable = true
			end
		elseif frameName == "CastingBarFrame" then
			frameType = "Castbar"
			frame.statusBar = frame
			frame.configName = frameName
			frame.friendlyName = L["Player/Vehicle Castbar"]
			frame.dragable = true
			frame.icon = _G[frameName .. "Icon"]
			frame.shield = _G[frameName .. "BorderShield"]
		elseif frameName == "PetCastingBarFrame" then
			frameType = "Castbar"
			frame.statusBar = frame
			frame.configName = UnitIsPossessed("pet") and "CastingBarFrame" or "PetCastingBarFrame"
			frame.friendlyName = L["Pet Castbar"]
			frame.dragable = true
			frame.icon = _G[frameName .. "Icon"]
			frame.shield = _G[frameName .. "BorderShield"]
		elseif frameName == "TargetCastingBarFrame" then
			frameType = "Castbar"
			frame.statusBar = frame
			frame.configName = frameName
			frame.friendlyName = L["Target Castbar"]
			frame.dragable = true
			frame.icon = _G[frameName .. "Icon"]
			frame.shield = _G[frameName .. "BorderShield"]
		elseif frameName == "FocusCastingBarFrame" then
			frameType = "Castbar"
			frame.statusBar = frame
			frame.configName = frameName
			frame.friendlyName = "Focus Castbar"
			frame.dragable = true
			frame.icon = _G[frameName .. "Icon"]
			frame.shield = _G[frameName .. "BorderShield"]
		end

		for _, region in pairs({frame:GetRegions()}) do
			if region.GetDrawLayer and region:GetDrawLayer() == "BACKGROUND" then
				frame.shade = region
			end
		end

		if frame.dragable then
			frame:SetMovable(true)
			frame:RegisterForDrag("LeftButton")
			Castbars.OnDragStart = Castbars.OnDragStart or function(frame)
				if Castbars.ConfigMode then
					GameTooltip:Hide()
					frame:EnableKeyboard(true)
					frame:StartMoving()
				end
			end
			frame:SetScript("OnDragStart", Castbars.OnDragStart)

			Castbars.OnDragStop = Castbars.OnDragStop or function(frame)
				frame:EnableKeyboard(false)
				frame:StopMovingOrSizing()
				if not Castbars.db[frame.configName]["Position"] then
					Castbars.db[frame.configName]["Position"] = {}
				end
				local position = Castbars.db[frame.configName]["Position"]
				position.point, position.parent, position.relpoint, position.x, position.y = frame:GetPoint()
			end
			frame:SetScript("OnDragStop", Castbars.OnDragStop)

			Castbars.OnKeyUp = Castbars.OnKeyUp or function(frame, key)
				local point, parent, relpoint, x, y = frame:GetPoint()
				if key == "UP" then
					y = y + 1
				elseif key == "DOWN" then
					y = y - 1
				elseif key == "RIGHT" then
					x = x + 1
				elseif key == "LEFT" then
					x = x - 1
				end
				frame:setPoint(point, parent, relpoint, x, y)
			end
			frame:SetScript("OnKeyUp", Castbars.OnKeyUp)

			Castbars.OnEnter = Castbars.OnEnter or function(frame)
				if Castbars.ConfigMode and not frame:IsDragging() then
					GameTooltip:SetOwner(frame, "ANCHOR_TOPLEFT")
					GameTooltip:SetText(L["|cFFFFFFFFDrag with mouse.\n|cFFCCCCCCUse arrow keys while dragging to fine tune position."])
				end
			end
			frame:SetScript("OnEnter", Castbars.OnEnter)

			Castbars.OnLeave = Castbars.OnLeave or function(frame) GameTooltip:Hide() end
			frame:SetScript("OnLeave", Castbars.OnLeave)
			frame:EnableKeyboard(false)
		end

		frame.spark = _G[frameName .. "Spark"]
		if frame.spark then
			local setPoint = frame.spark.SetPoint
			frame.spark.SetPoint = function(self, point, relativeFrame, relativePoint, x, y)
				setPoint(self, point, relativeFrame, relativePoint, x, 0)
			end
			frame.spark:SetWidth(10)
		end

		frame.text = _G[frameName .. "Text"]
		frame.text:ClearAllPoints()
		if frameType == "Castbar" then
			frame.text:SetPoint("LEFT", frame.statusBar, "LEFT", 5, 0.25)
		elseif frameType == "Mirror" then
			frame.text:SetPoint("CENTER", frame.statusBar, "CENTER", 0, 0.25)
		end

		if frame.icon then
			frame.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
		end

		frame.text.SetWidthReal = frame.text.SetWidth
		frame.text.SetWidth = Castbars.DoNothing
		frame.text.ClearAllPoints = Castbars.DoNothing
		frame.text.SetPoint = Castbars.DoNothing

		frame.clearAllPoints = frame.ClearAllPoints
		frame.ClearAllPoints = Castbars.DoNothing
		frame.setPoint = frame.SetPoint
		frame.SetPoint = Castbars.DoNothing

		frame.UnregisterEvent = Castbars.DoNothing
		frame.UnregisterAllEvents = Castbars.DoNothing
		frame.RegisterEvent = Castbars.DoNothing

		local frameBorder = _G[frameName .. "Border"]
		frameBorder:SetTexture()

		local frameFlash = _G[frameName .. "Flash"]
		if frameFlash then
			frameFlash:SetTexture()
		end

		frame.backdrop = CreateFrame("Frame", nil, frame)
		frame.backdrop:SetPoint("CENTER", frame.statusBar, "CENTER", 0, 0)

		if frameName == "CastingBarFrame" then
			frame.gcd = CreateFrame("Frame", nil, UIParent)
			frame.gcd:SetPoint("BOTTOM", frame.statusBar, "TOP", 0, 0)
			frame.gcd:SetHeight(3)
			frame.gcd:Hide()
			frame.gcd.border = frame.gcd:CreateTexture(nil, "BACKGROUND")
			frame.gcd.border:SetAllPoints(frame.gcd)
			local texture = frame.gcd:CreateTexture(nil, "OVERLAY")
			texture:SetTexture("Spells\\AURA_01")
			texture:SetVertexColor(1, 1, 1, 1)
			texture:SetBlendMode("ADD")
			texture:SetWidth(35)
			texture:SetHeight(35)
			frame.gcd:SetScript("OnUpdate", function(self, elapsed)
				self.elapsed = (self.elapsed or 0) + elapsed
				if self.elapsed > 0.1 then
					self.elapsed = 0
					if frame:IsVisible() then
						frame.gcd.border:SetTexture(0, 0, 0, 0)
					else
						frame.gcd.border:SetTexture(0, 0, 0, 0.5)
					end
				end
				local x = GetTime() * self.a - self.b
				if x > self:GetWidth() then
					self:Hide()
				else
					texture:SetPoint("CENTER", self, "LEFT", x, 0)
				end
			end)

			frame.swing = CreateFrame("Frame", nil, UIParent)
			frame.swing:Hide()
			frame.swing:SetPoint("TOP", frame.statusBar, "BOTTOM", 0, 0)
			frame.swing:SetHeight(3)
			local b = frame.swing:CreateTexture(nil, "BACKGROUND")
			b:SetAllPoints(frame.swing)
			b:SetTexture(0, 0, 0, 0.5)
			frame.swing.texture = frame.swing:CreateTexture(nil, "ARTWORK")
			frame.swing.texture:SetSize(5, frame.swing:GetHeight())
			frame.swing.texture:SetPoint("LEFT", frame.swing, "LEFT", 0, 0)
			frame.swing:SetScript("OnUpdate", function(self, elapsed)
				if self.slamStart then return end
				if self.startTime then
					local spent = GetTime() - self.startTime
					local perc = spent / self.duration
					if perc > 1 then
						return self:Hide()
					else
						self.texture:SetWidth(self:GetWidth() * perc)
					end
				end
			end)
			frame.swing:SetScript("OnEvent", function(self, event, ...)
				if event == "COMBAT_LOG_EVENT_UNFILTERED" then
					local _, combatevent, srcGUID, _, _, dstGUID = ...
					if srcGUID == core.guid then
						if combatevent == "SPELL_EXTRA_ATTACKS" then
							self.extraAttacks = select(12, ...)
							self.extraInhibit = true
						elseif combatevent == "SWING_DAMAGE" or combatevent == "SWING_MISSED" then
							if (self.extraAttacks or 0) > 0 and not self.extraInhibit then
								self.extraAttacks = (self.extraAttacks or 0) - 1
							elseif not Castbars_IsDualWielding() then
								self.extraInhibit = false
								self.duration = UnitAttackSpeed("player")
								self.startTime = GetTime()
								self:Show()
							end
						end
					elseif dstGUID == core.guid and combatevent == "SWING_MISSED" then
						if select(9, ...) == "PARRY" and self.duration then
							self.duration = self.duration * 0.6
						end
					end
				elseif event == "UNIT_ATTACK_SPEED" and ... == "player" then
					self.duration = UnitAttackSpeed("player")
				elseif event == "UNIT_RANGEDDAMAGE" and ... == "player" then
					self.duration = UnitRangedDamage("player")
				elseif event == "PLAYER_REGEN_ENABLED" or event == "STOP_AUTOREPEAT_SPELL" then
					self:Hide()
				elseif event == "UNIT_SPELLCAST_SUCCEEDED" and ... == "player" then
					local spell = select(2, ...)
					if Castbars_IsDualWielding() then
						if swingResetSpells[spell] then
							self.duration = UnitAttackSpeed("player")
							self.startTime = GetTime()
							self:Show()
						elseif spell == slamname then
							self.startTime = (self.startTime or 0) + GetTime() - (self.slamStart or 0)
							self.slamStart = nil
						end
					elseif spell == autoshotname or spell == shootname then
						self.duration = UnitRangedDamage("player")
						self.startTime = GetTime()
						self:Show()
					end
				elseif event == "UNIT_SPELLCAST_START" and ... == "player" and select(2, ...) == slamname then
					self.slamStart = GetTime()
				elseif event == "UNIT_SPELLCAST_INTERRUPTED" and ... == "player" and select(2, ...) == slamname and self.slamStart then
					self.slamStart = nil
				end
			end)
		end

		if frameType == "Castbar" then
			frame.timer = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
			frame.timer:SetPoint("RIGHT", frame, "RIGHT", -5, 0.25)
			frame.nextupdate = 0.1

			if frameName == "CastingBarFrame" then
				frame.latency = frame:CreateTexture(nil, "ARTWORK")
				frame.latency:Hide()
				frame.latency:SetHeight(frame:GetHeight())
				frame.latency:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
				frame.latency:SetVertexColor(1, 0, 0, 0.65)
			end

			frame.shield:SetDrawLayer("OVERLAY")
		end

		local setHeight = frame.SetHeight
		if frameType == "Castbar" then
			frame.SetHeight = function(self, height)
				height = height or frame:GetHeight()
				frame.backdrop:SetHeight(height + (frame.borderWidth or 0) - 2)
				frame.spark:SetHeight(1.8 * height)
				if frame.latency then
					frame.latency:SetHeight(height)
				end
				frame.shield:SetHeight(5.82 * height)
				setHeight(self, height)
			end
		elseif frameType == "Mirror" then
			frame.SetHeight = function(self, height)
				height = height or frame:GetHeight()
				frame.backdrop:SetHeight(height + (frame.borderWidth or 0) - 2)
				frame.statusBar:SetHeight(height)
				frame.shade:SetHeight(height)
				setHeight(self, height + 10)
			end
		end

		local setWidth = frame.SetWidth
		if frameType == "Castbar" then
			frame.SetWidth = function(self, width)
				width = width or frame:GetWidth()
				frame.backdrop:SetWidth(width + (frame.borderWidth or 0) - 2)
				frame.text:SetWidthReal(width - 10 - frame.timer:GetWidth())
				frame.shield:SetWidth(1.36 * width)
				frame.shield:ClearAllPoints()
				frame.shield:SetPoint("CENTER", frame.statusBar, "CENTER", -0.031875 * width, 0)
				if frame.gcd then
					frame.gcd:SetWidth(width)
				end
				if frame.swing then
					frame.swing:SetWidth(width)
				end
				setWidth(self, width)
			end
		elseif frameType == "Mirror" then
			frame.SetWidth = function(self, width)
				width = width or frame:GetWidth()
				frame.backdrop:SetWidth(width + (frame.borderWidth or 0) - 2)
				frame.statusBar:SetWidth(width)
				frame.shade:SetWidth(width)
				setWidth(self, width)
			end
		end

		frame:Hide()
	end

	local function Castbars_FrameCustomizeAll()
		for _, frame in pairs(Castbars.frames) do
			Castbars_FrameCustomize(frame)
		end
	end

	local function Castbars_GetOptionsTableForBar(frameConfigName, friendlyName, order, textAlign, showHideShield, enableDisable, showHideIcon, showHideLatency, showHideSpellTarget, showHideTotalCastTime, totalCastTimeDecimals, showHidePushback, showHideCooldownSpark)
		local options = {
			type = "group",
			name = friendlyName,
			order = order,
			args = {
				width = {
					type = "range",
					name = L["Width"],
					desc = L:F("Set the width of the %s", friendlyName),
					order = 10,
					min = 100, max = 600, step = 1,
					get = function()
						return Castbars.db[frameConfigName]["Width"]
					end,
					set = function(info, value)
						Castbars.db[frameConfigName]["Width"] = value
						Castbars_FrameLayoutRestoreAll()
					end
				},
				height = {
					type = "range",
					name = L["Height"],
					desc = L:F("Set the height of the %s", friendlyName),
					order = 11,
					min = 10, max = 100, step = 1,
					get = function()
						return Castbars.db[frameConfigName]["Height"]
					end,
					set = function(info, value)
						Castbars.db[frameConfigName]["Height"] = value
						Castbars_FrameLayoutRestoreAll()
					end
				},
				texture = {
					type = "select",
					name = L["Texture"],
					desc = L:F("Select texture to use for the %s", friendlyName),
					dialogControl = "LSM30_Statusbar",
					order = 12,
					values = AceGUIWidgetLSMlists.statusbar,
					get = function()
						return Castbars.db[frameConfigName]["Texture"]
					end,
					set = function(info, value)
						Castbars.db[frameConfigName]["Texture"] = value
						Castbars_FrameLayoutRestoreAll()
					end
				},
				color = {
					type = "color",
					name = L["Bar Color"],
					desc = L:F("Set color of the %s", friendlyName),
					order = 13,
					get = function(info)
						return unpack(Castbars.db[frameConfigName]["BarColor"])
					end,
					set = function(info, r, g, b)
						Castbars.db[frameConfigName]["BarColor"] = {r, g, b}
					end
				},
				font = {
					type = "select",
					name = L["Font"],
					desc = L:F("Select font to use for the %s", friendlyName),
					dialogControl = "LSM30_Font",
					order = 15,
					values = AceGUIWidgetLSMlists.font,
					get = function()
						return Castbars.db[frameConfigName]["Font"]
					end,
					set = function(info, value)
						Castbars.db[frameConfigName]["Font"] = value
						Castbars_FrameLayoutRestoreAll()
					end
				},
				fontsize = {
					type = "range",
					name = L["Font Size"],
					desc = L:F("Set the font size of the %s", friendlyName),
					order = 17,
					min = 6, max = 30, step = 1,
					get = function()
						return Castbars.db[frameConfigName]["FontSize"]
					end,
					set = function(info, value)
						Castbars.db[frameConfigName]["FontSize"] = value
						Castbars_FrameLayoutRestoreAll()
					end
				},
				fontoutline = {
					type = "toggle",
					name = L["Font Outline"],
					desc = L:F("Toggles outline on the font of the %s", friendlyName),
					order = 18,
					get = function()
						return Castbars.db[frameConfigName]["FontOutline"]
					end,
					set = function()
						Castbars.db[frameConfigName]["FontOutline"] = not Castbars.db[frameConfigName]["FontOutline"]
						Castbars_FrameLayoutRestoreAll()
					end
				},
				border = {
					type = "select",
					name = L["Border"],
					desc = L:F("Select border to use for the %s", friendlyName),
					dialogControl = "LSM30_Border",
					order = 19,
					values = AceGUIWidgetLSMlists.border,
					get = function()
						return Castbars.db[frameConfigName]["Border"]
					end,
					set = function(info, value)
						Castbars.db[frameConfigName]["Border"] = value
						Castbars_FrameLayoutRestoreAll()
					end
				},
				bordercolor = {
					type = "color",
					name = L["Border Color"],
					desc = L:F("Set color of the border of the %s", friendlyName),
					hasAlpha = true,
					order = 20,
					get = function(info)
						return unpack(Castbars.db[frameConfigName]["BorderColor"])
					end,
					set = function(info, r, g, b, a)
						Castbars.db[frameConfigName]["BorderColor"] = {r, g, b, a}
						Castbars_FrameLayoutRestoreAll()
					end
				}
			}
		}
		if enableDisable then
			options.args.enable = {
				type = "toggle",
				name = L["Enable"],
				desc = L:F("Toggles display of the %s", friendlyName),
				order = 1,
				get = function()
					return Castbars.db[frameConfigName]["Show"]
				end,
				set = function()
					Castbars.db[frameConfigName]["Show"] = not Castbars.db[frameConfigName]["Show"]
					Castbars_FrameLayoutRestoreAll()
				end
			}
		end
		if showHideIcon then
			options.args.showicon = {
				type = "toggle",
				name = L["Show Icon"],
				desc = L["Toggles display of the icon at the left side of the bar"],
				order = 2,
				get = function()
					return Castbars.db[frameConfigName]["ShowIcon"]
				end,
				set = function()
					Castbars.db[frameConfigName]["ShowIcon"] = not Castbars.db[frameConfigName]["ShowIcon"]
					Castbars_FrameLayoutRestoreAll()
				end
			}
		end
		if showHideShield then
			options.args.showshield = {
				type = "toggle",
				name = L["Show Shield"],
				desc = L["Toggles display of the shield around the bar when the spell cannot be interrupted."],
				order = 3,
				get = function()
					return Castbars.db[frameConfigName]["ShowShield"]
				end,
				set = function()
					Castbars.db[frameConfigName]["ShowShield"] = not Castbars.db[frameConfigName]["ShowShield"]
					Castbars_FrameLayoutRestoreAll()
				end
			}
		end
		if showHideLatency then
			options.args.showlatency = {
				type = "toggle",
				name = L["Show Latency"],
				desc = L["Toggles the latency indicator, which shows the latency at the time of spell cast as a red bar at the end of the Castbar."],
				order = 4,
				get = function()
					return Castbars.db[frameConfigName]["ShowLatency"]
				end,
				set = function()
					Castbars.db[frameConfigName]["ShowLatency"] = not Castbars.db[frameConfigName]["ShowLatency"]
					Castbars_FrameLayoutRestoreAll()
				end
			}
			options.args.showspellrank = {
				type = "toggle",
				name = L["Show Spell Rank"],
				desc = L["Toggles display of the rank of the spell being cast."],
				order = 4.1,
				get = function()
					return Castbars.db[frameConfigName]["ShowSpellRank"]
				end,
				set = function()
					Castbars.db[frameConfigName]["ShowSpellRank"] = not Castbars.db[frameConfigName]["ShowSpellRank"]
					Castbars_FrameLayoutRestoreAll()
				end
			}
			options.args.texture.width = "double"
			options.args.classcolor = {
				type = "toggle",
				name = L["Use class color"],
				order = 14,
				get = function()
					return Castbars.db[frameConfigName]["ClassColor"]
				end,
				set = function()
					Castbars.db[frameConfigName]["ClassColor"] = not Castbars.db[frameConfigName]["ClassColor"]
					Castbars_FrameLayoutRestoreAll()
				end
			}
		end
		if showHideSpellTarget then
			options.args.showspelltarget = {
				type = "toggle",
				name = L["Show Spell Target"],
				desc = L["Toggles display of the target of the spell being cast."],
				order = 5,
				get = function()
					return Castbars.db[frameConfigName]["ShowSpellTarget"]
				end,
				set = function()
					Castbars.db[frameConfigName]["ShowSpellTarget"] = not Castbars.db[frameConfigName]["ShowSpellTarget"]
					Castbars_FrameLayoutRestoreAll()
				end
			}
		end
		if showHideTotalCastTime then
			options.args.showtotalcasttime = {
				type = "toggle",
				name = L["Show Total Cast Time"],
				desc = L["Toggles display of the total cast time."],
				order = 6,
				get = function()
					return Castbars.db[frameConfigName]["ShowTotalCastTime"]
				end,
				set = function()
					Castbars.db[frameConfigName]["ShowTotalCastTime"] =
						not Castbars.db[frameConfigName]["ShowTotalCastTime"]
					Castbars_FrameLayoutRestoreAll()
				end
			}
		end
		if totalCastTimeDecimals then
			options.args.totalcasttimedecimals = {
				type = "range",
				name = L["Total Cast Time Decimals"],
				desc = L["Set the number of decimal places for the total cast time."],
				order = 7,
				min = 0, max = 3, step = 1,
				get = function()
					return Castbars.db[frameConfigName]["TotalCastTimeDecimals"]
				end,
				set = function(info, value)
					Castbars.db[frameConfigName]["TotalCastTimeDecimals"] = value
					Castbars_FrameLayoutRestoreAll()
				end
			}
		end
		if showHidePushback then
			options.args.showpushback = {
				type = "toggle",
				name = L["Show Pushback"],
				desc = L["Toggles display of the pushback time when spell casting is delayed."],
				order = 8,
				get = function()
					return Castbars.db[frameConfigName]["ShowPushback"]
				end,
				set = function()
					Castbars.db[frameConfigName]["ShowPushback"] = not Castbars.db[frameConfigName]["ShowPushback"]
					Castbars_FrameLayoutRestoreAll()
				end
			}
		end
		if showHideCooldownSpark then
			options.args.showspark = {
				type = "toggle",
				name = L["Show Global Cooldown Spark"],
				desc = L["Toggles display of the global cooldown spark."],
				order = 9,
				get = function()
					return Castbars.db[frameConfigName]["ShowCooldownSpark"]
				end,
				set = function()
					Castbars.db[frameConfigName]["ShowCooldownSpark"] = not Castbars.db[frameConfigName]["ShowCooldownSpark"]
				end
			}
		end

		if frameConfigName == "CastingBarFrame" then
			options.args.showswing = {
				type = "toggle",
				name = L["Show Swing Timer"],
				desc = L["Toggles display of the swing timer."],
				order = 9.1,
				width = "double",
				get = function()
					return Castbars.db[frameConfigName]["ShowSwingTimer"]
				end,
				set = function()
					Castbars.db[frameConfigName]["ShowSwingTimer"] = not Castbars.db[frameConfigName]["ShowSwingTimer"]
					Castbars_FrameLayoutRestoreAll()
				end
			}
		end

		if textAlign then
			options.args.textalign = {
				type = "select",
				name = L["Text Alignment"],
				desc = L["Set the alignment of the Castbar text"],
				order = 16,
				values = {LEFT = L["Left"], CENTER = L["Center"]},
				get = function()
					return Castbars.db[frameConfigName]["TextAlignment"]
				end,
				set = function(info, value)
					Castbars.db[frameConfigName]["TextAlignment"] = value
					Castbars_FrameLayoutRestoreAll()
				end
			}
		end
		return options
	end

	local defaults = {
		CastingBarFrame = {
			Show = true,
			ShowIcon = true,
			ShowLatency = true,
			ShowSpellRank = false,
			ShowSpellTarget = true,
			ShowTotalCastTime = true,
			TotalCastTimeDecimals = 1,
			ShowPushback = true,
			ShowCooldownSpark = true,
			ShowSwingTimer = true,
			Width = 250,
			Height = 24,
			Texture = "Castbars",
			BarColor = {1.0, 0.49, 0},
			Font = "Friz Quadrata TT",
			FontSize = 10,
			TextAlignment = "CENTER",
			FontOutline = true,
			BorderColor = {0.0, 0.0, 0.0, 0.8},
			Border = "Blizzard Tooltip",
			Position = {point = "CENTER", relpoint = "CENTER", x = 0, y = -145}
		},
		PetCastingBarFrame = {
			Show = true,
			ShowIcon = true,
			ShowTotalCastTime = true,
			Width = 150,
			Height = 12,
			Texture = "Castbars",
			BarColor = {1.0, 0.49, 0},
			Font = "Friz Quadrata TT",
			FontSize = 9,
			TextAlignment = "CENTER",
			FontOutline = true,
			BorderColor = {0.0, 0.0, 0.0, 0.8},
			Border = "None",
			Position = {point = "CENTER", relpoint = "CENTER", x = 0, y = -175}
		},
		TargetCastingBarFrame = {
			Show = true,
			ShowIcon = true,
			ShowShield = true,
			ShowTotalCastTime = true,
			Width = 205,
			Height = 12,
			Texture = "Castbars",
			BarColor = {1.0, 0.49, 0},
			Font = "Friz Quadrata TT",
			FontSize = 10,
			TextAlignment = "CENTER",
			FontOutline = true,
			BorderColor = {0.0, 0.0, 0.0, 0.8},
			Border = "None",
			Position = {point = "CENTER", relpoint = "CENTER", x = 0, y = 180}
		},
		FocusCastingBarFrame = {
			Show = false,
			ShowIcon = true,
			ShowShield = true,
			ShowTotalCastTime = true,
			Width = 205,
			Height = 12,
			Texture = "Castbars",
			BarColor = {1.0, 0.49, 0},
			Font = "Friz Quadrata TT",
			FontSize = 10,
			TextAlignment = "CENTER",
			FontOutline = true,
			BorderColor = {0.0, 0.0, 0.0, 0.8},
			Border = "None",
			Position = {point = "CENTER", relpoint = "CENTER", x = 0, y = 200}
		},
		MirrorTimer = {
			Width = 205,
			Height = 13,
			Texture = "Castbars",
			BarColor = {1.0, 0.49, 0},
			Font = "Friz Quadrata TT",
			FontSize = 10,
			TextAlignment = "CENTER",
			FontOutline = true,
			Border = "Blizzard Tooltip",
			BorderColor = {0.0, 0.0, 0.0, 0.8},
			Position = {point = "TOP", relpoint = "TOP", x = 0, y = -130}
		}
	}

	local function Castbars_SetupDatabase()
		if type(core.db.Castbars) ~= "table" or next(core.db.Castbars) == nil then
			core.db.Castbars = CopyTable(defaults)
		end
		Castbars.db = core.db.Castbars

		-- character specific settings
		if Castbars.db.UseCharacter then
			if type(core.char.Castbars) ~= "table" or next(core.char.Castbars) == nil then
				core.char.Castbars = CopyTable(core.db.Castbars)
			end
			Castbars.db = core.char.Castbars
		elseif core.char.Castbars then
			core.char.Castbars = nil
		end
	end

	local function Castbars_GetOptionsTable()
		local options = {
			type = "group",
			name = L["Castbars"],
			args = {
				toggleconfigmode = {
					name = L["Configuration Mode"],
					type = "toggle",
					order = 1,
					desc = L["Toggle configuration mode to allow moving frames and setting appearance options."],
					get = function()
						return Castbars.ConfigMode
					end,
					set = function()
						Castbars:Toggle()
					end
				},
				characterspecific = {
					name = L["Character Specific"],
					type = "toggle",
					order = 2,
					desc = L["Enable this if you want settings to be stored per character rather than per account."],
					get = function()
						return core.db.Castbars.UseCharacter
					end,
					set = function()
						core.db.Castbars.UseCharacter = not core.db.Castbars.UseCharacter
						Castbars_SetupDatabase()
						Castbars_FrameLayoutRestoreAll()
					end
				},
				reset = {
					type = "execute",
					name = RESET,
					order = 3,
					confirm = function()
						return L:F("Are you sure you want to reset %s to default?", "Castbars")
					end,
					func = function()
						wipe(core.char.Castbars)
						if not core.db.Castbars.UseCharacter then
							wipe(core.db.Castbars)
						end
						Castbars.db = nil
						Castbars_SetupDatabase()
						Castbars_FrameLayoutRestoreAll()
						core:Print(L["module's settings reset to default."], L["Castbars"])
					end
				},
				player = Castbars_GetOptionsTableForBar("CastingBarFrame", L["Player/Vehicle Castbar"], 4, true, false, true, true, true, true, true, true, true, true),
				pet = Castbars_GetOptionsTableForBar("PetCastingBarFrame", L["Pet Castbar"], 5, true, false, true, true, false, false, true, false, false, false),
				target = Castbars_GetOptionsTableForBar("TargetCastingBarFrame", L["Target Castbar"], 6, true, true, true, true, false, false, true, false, false, false),
				focus = Castbars_GetOptionsTableForBar("FocusCastingBarFrame", L["Focus Castbar"], 7, true, true, true, true, false, false, true, false, false, false),
				mirror = Castbars_GetOptionsTableForBar("MirrorTimer", L["Mirror Timers"], 8)
			}
		}
		return options
	end

	local function UnitFullName(unit)
		local name, realm = UnitName(unit)
		if realm and realm ~= "" then
			return name .. "-" .. realm
		else
			return name
		end
	end

	local function Castbars_NameToUnitID(targetName)
		return UnitExists(targetName) and targetName or (targetName == UnitFullName("target") and "target") or
			(targetName == UnitFullName("focus") and "focus") or
			(targetName == UnitFullName("targettarget") and "targettarget") or
			(targetName == UnitFullName("focustarget") and "focustarget") or
			nil
	end

	core:RegisterForEvent("PLAYER_LOGIN", function()
		Castbars_SetupDatabase()
		core.options.args.Castbars = Castbars_GetOptionsTable()

		UIPARENT_MANAGED_FRAME_POSITIONS["CastingBarFrame"] = nil

		-- Create target casting bar
		CreateFrame("StatusBar", "TargetCastingBarFrame", UIParent, "CastingBarFrameTemplate")
		_G.TargetCastingBarFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
		CastingBarFrame_OnLoad(_G.TargetCastingBarFrame, "target", false, true)

		-- Create focus casting bar
		CreateFrame("StatusBar", "FocusCastingBarFrame", UIParent, "CastingBarFrameTemplate")
		_G.FocusCastingBarFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
		CastingBarFrame_OnLoad(_G.FocusCastingBarFrame, "focus", false, true)

		-- Register additional events on CastingBarFrame
		CastingBarFrame:RegisterEvent("UNIT_SPELLCAST_SENT")
		CastingBarFrame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
		CastingBarFrame:RegisterEvent("UPDATE_TRADESKILL_RECAST")

		-- Setup table with all frames
		Castbars.frames = {CastingBarFrame, PetCastingBarFrame, _G.TargetCastingBarFrame, _G.FocusCastingBarFrame, MirrorTimer1, MirrorTimer2, MirrorTimer3}

		-- Customize the bars
		Castbars_FrameCustomizeAll()

		-- Restore layout of all frames
		local loginRestoreOnce
		if IsLoggedIn() then
			Castbars_FrameLayoutRestoreAll()
			loginRestoreOnce = true
		end

		-- Register Texture and Listen to LibSharedMedia-3.0 callbacks
		core:MediaRegister("statusbar", "Castbars", [[Interface\AddOns\KPack\Media\Statusbar\castbars]])
		core:RegisterLSMCallback(Castbars, "LibSharedMedia_Registered", "FrameMediaRestoreAll")
		core:RegisterLSMCallback(Castbars, "LibSharedMedia_SetGlobal", "FrameMediaRestoreAll")

		Castbars.CastingBarFrame_OnUpdate = function(frame, elapsed, ...)
			CastingBarFrame_OnUpdate(frame, elapsed, ...)
			if frame:IsVisible() then
				if frame.outOfRange ~= nil then
					local outOfRange = frame.outOfRange
					frame.outOfRange =
						frame.spellName and frame.spellTarget and
						(IsSpellInRange(frame.spellName, frame.spellTarget) == 0) and
						true or
						false
					if outOfRange ~= frame.outOfRange then
						Castbars_FrameColorRestore(frame)
					end
				end
				if frame.timer then
					if frame.nextupdate < elapsed then
						Castbars_FrameTimerRestore(frame)
						frame.nextupdate = 0.1
					else
						frame.nextupdate = frame.nextupdate - elapsed
					end
				end
			end
		end

		local orgDoTradeSkill = DoTradeSkill
		DoTradeSkill = function(index, num, ...)
			orgDoTradeSkill(index, num, ...)
			CastingBarFrame.mergingTradeSkill = true
			CastingBarFrame.countCurrent = 0
			CastingBarFrame.countTotal = tonumber(num) or 1
		end

		Castbars.CastingBarFrame_OnEvent = function(frame, event, ...)
			if Castbars.ConfigMode then
				return
			end
			frame.Show = nil
			if event == "UNIT_SPELLCAST_SENT" then
				local unit, spellName, spellRank, targetName = ...
				if unit == "player" then
					frame.sentTime = GetTime()
					frame.outOfRange = false
					frame.spellName = spellName
					frame.spellRank = spellRank
					frame.spellTargetName = targetName
					frame.spellTarget = Castbars_NameToUnitID(targetName)
				end
				return
			elseif event == "ACTIONBAR_UPDATE_COOLDOWN" and Castbars.db[frame.configName]["ShowCooldownSpark"] then
				frame.gcd:SetFrameLevel(frame.backdrop:GetFrameLevel() + 1)
				local startTime, duration = GetSpellCooldown(7302)
				if duration and duration > 0 then
					frame.gcd.a = frame.gcd:GetWidth() / duration
					frame.gcd.b = (startTime * frame.gcd:GetWidth()) / duration
					frame.gcd:Show()
				else
					frame.gcd:Hide()
				end
				return
			elseif event == "PLAYER_ENTERING_WORLD" then
				if not loginRestoreOnce then
					Castbars_FrameLayoutRestoreAll()
					loginRestoreOnce = true
				end
			elseif event == "PLAYER_TARGET_CHANGED" then
				CastingBarFrame_OnEvent(frame, "PLAYER_ENTERING_WORLD", ...)
				if frame.unit == "target" then
					Castbars_FrameRestoreOnCast(frame, frame.unit)
				end
				return
			elseif event == "PLAYER_FOCUS_CHANGED" then
				CastingBarFrame_OnEvent(frame, "PLAYER_ENTERING_WORLD", ...)
				if frame.unit == "focus" then
					Castbars_FrameRestoreOnCast(frame, frame.unit)
				end
				return
			elseif event == "UNIT_PET" and (... == "player") then
				frame.configName = UnitIsPossessed("pet") and "CastingBarFrame" or "PetCastingBarFrame"
				Castbars_FrameLayoutRestore(frame)
				return
			elseif event == "UPDATE_TRADESKILL_RECAST" then
				if frame.casting then
					frame.mergingTradeSkill = nil
				end
				return
			end
			CastingBarFrame_OnEvent(frame, event, ...)
			if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
				local unit = ...
				if unit == frame.unit then
					if unit == "player" then
						frame.gcd.border:SetTexture(0, 0, 0, 0)
						if frame.channeling then
							Castbars_CastingBarFrameTicksSet(Castbars_SpellToTicks(frame.spellName, frame.maxValue))
						end
						if frame.casting then
							frame.startTime = GetTime() - (frame.value or 0)
							frame.delayTime = nil
							if frame.mergingTradeSkill then
								frame.value = frame.value + frame.maxValue * frame.countCurrent
								frame.maxValue = frame.maxValue * frame.countTotal
								frame.maxValueMerge = frame.maxValue
								frame:SetMinMaxValues(0, frame.maxValue)
								frame:SetValue(frame.value)
								frame.countCurrent = frame.countCurrent + 1
							end
						end
					end
					Castbars_FrameRestoreOnCast(frame, unit, true)
				end
			elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
				if (... == "player") and frame.unit == "player" then
					if not (frame.casting or frame.channeling) then
						frame.latency:Hide()
						Castbars_CastingBarFrameTicksSet(0)
					end
					if frame.mergingTradeSkill then
						if frame.countCurrent == frame.countTotal then
							frame.mergingTradeSkill = nil
						else
							frame.value = frame.maxValue * frame.countCurrent / frame.countTotal
							frame:SetValue(frame.value)
							frame:SetStatusBarColor(unpack(Castbars.db[frame.configName]["BarColor"]))
							frame.holdTime = GetTime() + 1
							local sparkPosition = (frame.value / frame.maxValue) * frame:GetWidth()
							frame.spark:SetPoint("CENTER", frame, "LEFT", sparkPosition, 2)
							frame.spark:Show()
						end
					end
				end
			elseif event == "UNIT_SPELLCAST_DELAYED" then
				if (... == "player") and frame.unit == "player" and frame.casting then
					frame.delayTime = (GetTime() - (frame.value or 0)) - (frame.startTime or 0)
					Castbars_FrameTimerRestore(frame, true)
				end
			elseif event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
				if (... == "player") and frame.unit == "player" then
					frame.mergingTradeSkill = nil
				end
			elseif event == "UNIT_SPELLCAST_INTERRUPTIBLE" or event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" then
				if (... == frame.unit) then
					Castbars_FrameIconRestore(frame)
				end
			end
		end

		-- Replace the OnEvent handler
		CastingBarFrame:SetScript("OnEvent", Castbars.CastingBarFrame_OnEvent)
		PetCastingBarFrame:SetScript("OnEvent", Castbars.CastingBarFrame_OnEvent)
		_G.TargetCastingBarFrame:SetScript("OnEvent", Castbars.CastingBarFrame_OnEvent)
		_G.FocusCastingBarFrame:SetScript("OnEvent", Castbars.CastingBarFrame_OnEvent)

		-- Replace the OnUpdate handler
		CastingBarFrame:SetScript("OnUpdate", Castbars.CastingBarFrame_OnUpdate)
		PetCastingBarFrame:SetScript("OnUpdate", Castbars.CastingBarFrame_OnUpdate)
		_G.TargetCastingBarFrame:SetScript("OnUpdate", Castbars.CastingBarFrame_OnUpdate)
		_G.FocusCastingBarFrame:SetScript("OnUpdate", Castbars.CastingBarFrame_OnUpdate)

		Castbars.GetOptionsTableForBar = nil
		Castbars.GetOptionsTable = nil
		Castbars.FrameCustomize = nil
		Castbars.FrameCustomizeAll = nil

		SLASH_KPACKCASTBARS1 = "/cb"
		SLASH_KPACKCASTBARS2 = "/castbars"
		SlashCmdList.KPACKCASTBARS = Castbars.OpenConfig
	end)

	function Castbars:OpenConfig()
		core:OpenConfig("Castbars")
	end

	Castbars.MirrorTimerFrame_OnEvent = MirrorTimerFrame_OnEvent
	Castbars.MirrorTimer_Show = MirrorTimer_Show

	function Castbars:Show()
		if not self.ConfigMode then
			self.ConfigMode = true

			MirrorTimerFrame_OnEvent = self.DoNothing
			MirrorTimer_Show = self.DoNothing

			PetCastingBarFrame.configName = "PetCastingBarFrame"
			Castbars_FrameLayoutRestore(PetCastingBarFrame)

			for i, frame in pairs(self.frames) do
				frame:EnableMouse(true)
				frame.text:SetText(frame.friendlyName)
				frame.statusBar:SetStatusBarColor(unpack(self.db[frame.configName]["BarColor"]))
				frame.statusBar:SetAlpha(1)
				frame.statusBar:SetValue(select(2, frame.statusBar:GetMinMaxValues()))
				if frame.spark then
					frame.spark:Hide()
				end
				if frame.shield then
					frame.shield:Hide()
				end
				frame.fadeOut = nil
				frame.paused = 1
				if frame.icon then
					frame.icon:SetTexture("Interface\\Icons\\Spell_Arcane_MassDispel")
				end
				Castbars_FrameTimerRestore(frame, true)
				Castbars_FrameIconRestore(frame)
				frame:Show()
			end
		end
	end

	function Castbars:Hide()
		if self.ConfigMode then
			for i, frame in pairs(self.frames) do
				frame:EnableMouse(false)
				frame:Hide()
			end

			PetCastingBarFrame.configName = UnitIsPossessed("pet") and "CastingBarFrame" or "PetCastingBarFrame"
			Castbars_FrameLayoutRestore(PetCastingBarFrame)

			MirrorTimerFrame_OnEvent = self.MirrorTimerFrame_OnEvent
			MirrorTimer_Show = self.MirrorTimer_Show
			self.ConfigMode = false
		end
	end

	function Castbars:Toggle()
		if self.ConfigMode then
			self:Hide()
		else
			self:Show()
		end
	end
end)