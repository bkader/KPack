local core = KPack
if not core then return end
core:AddModule("HalionHelper", "|cff00ff00/halionhelper|r", function(L)
	if core:IsDisabled("HalionHelper") then return end

	local HalionHelper = CreateFrame("Frame")
	core.HalionHelper = HalionHelper
	HalionHelper:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)

	-- globals
	local unpack = unpack
	local select = select
	local tonumber = tonumber
	local tostring = tostring
	local UnitGUID, UnitBuff = UnitGUID, UnitBuff
	local IsInInstance = IsInInstance
	local IsRaidLeader = IsRaidLeader
	local GetCurrentMapAreaID = GetCurrentMapAreaID
	local GetSpellInfo = GetSpellInfo
	local SendChatMessage = SendChatMessage
	local PlaySoundFile = PlaySoundFile

	local defaults, options, configmode = {
		enabled = true,
		scale = 1,
		voice = true,
		raid = true
	}

	local halion, cached = {[40142] = true, [39863] = true}, core.WeakTable()
	local combustion = GetSpellInfo(74562)
	local consumption = GetSpellInfo(74792)
	local texture = [[Interface\BUTTONS\WHITE8X8]]

	-- segments colors & alphas
	local colors = {
		[2] = {1, 0, 0},
		[3] = {1, 0, 0},
		[4] = {1, .5, 0},
		[5] = {1, 1, 0},
		[6] = {0, 1, 0},
		[7] = {0, 1, 0},
		[8] = {.8, .8, 0},
		[9] = {1, .5, 0},
		[10] = {1, 0, 0},
		[11] = {1, 0, 0}
	}

	local insideBuff = GetSpellInfo(74807)

	local corporeality = {
		[74836] = 1, --  70% less dealt, 100% less taken
		[74835] = 2, --  50% less dealt,  80% less taken
		[74834] = 3, --  30% less dealt,  50% less taken
		[74833] = 4, --  20% less dealt,  30% less taken
		[74832] = 5, --  10% less dealt,  15% less taken
		[74826] = 6, --  normal
		[74827] = 7, --  15% more dealt,  20% more taken
		[74828] = 8, --  30% more dealt,  50% more taken
		[74829] = 9, --  60% more dealt, 100% more taken
		[74830] = 10, -- 100% more dealt, 200% more taken
		[74831] = 11 -- 200% more dealt, 400% more taken
	}

	-- frame creation
	local HalionBar
	do
		local function OnDragStop(self)
			self:StopMovingOrSizing()
			self:SetUserPlaced(false)
			core:SavePosition(self, HalionHelper.db)
		end

		local function MoveIndicator(self, i)
			if self.position ~= i then
				self.position = i
				self.indicator:SetPoint("CENTER", self.segments[i], "RIGHT")

				-- change text for here & there
				if isInside then
					self.here:SetText(L["Inside"])
					self.there:SetText(L["Outside"])
				else
					self.here:SetText(L["Outside"])
					self.there:SetText(L["Inside"])
				end

				-- change message
				if i < 5 then
					self.message:SetText(L["Stop All Damage!"])
					self.message:SetTextColor(1, 0.5, 0)
					HalionHelper:AnnounceToRaid(isInside and L["Stop DPS Inside!"] or L["Stop DPS Outside!"])
					HalionHelper:AlertPlayer("dpsstop")
				elseif i == 5 then
					self.message:SetText(L["Slow Down!"])
					self.message:SetTextColor(1, 1, 0)
					HalionHelper:AnnounceToRaid(isInside and L["Slow DPS Inside!"] or L["Slow DPS Outside!"])
					HalionHelper:AlertPlayer("dpsslow")
				elseif i == 6 then
					self.message:SetText("")
					HalionHelper:AnnounceToRaid(L["DPS Both Sides!"])
				elseif i == 7 then
					self.message:SetText(L["Harder! Faster!"])
					self.message:SetTextColor(1, 1, 0)
					HalionHelper:AnnounceToRaid(isInside and L["Slow DPS Outside!"] or L["Slow DPS Inside!"])
					HalionHelper:AlertPlayer("dpsmore")
				elseif i > 7 then
					self.message:SetText(L["OMG MORE DAMAGE!"])
					self.message:SetTextColor(1, 0.5, 0)
					HalionHelper:AnnounceToRaid(isInside and L["Stop DPS Outside!"] or L["Stop DPS Inside!"])
					HalionHelper:AlertPlayer("dpshard")
				end
			end
		end

		function HalionHelper:CreateHalionBar()
			if not HalionBar then
				HalionBar = CreateFrame("Frame", "KPackHalionHelperFrame", UIParent)
				HalionBar:SetSize(210, 20)
				HalionBar:SetBackdrop({
					bgFile = texture,
					edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
					tile = false,
					tileSize = 16,
					edgeSize = 16,
					insets = {left = 4, right = 4, top = 4, bottom = 4}
				})
				HalionBar:SetBackdropColor(0, 0, 0, 1)
				HalionBar:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)

				HalionBar:EnableMouse(true)
				HalionBar:SetMovable(true)
				HalionBar:RegisterForDrag("LeftButton")
				HalionBar:SetUserPlaced(false)
				HalionBar:SetScript("OnDragStart", HalionBar.StartMoving)
				HalionBar:SetScript("OnDragStop", OnDragStop)

				-- create bar segments
				HalionBar.segments = core.WeakTable(HalionBar.segments)
				for i = 1, 11 do
					local t = HalionBar:CreateTexture(nil, "ARTWORK")
					t:SetTexture(texture)
					if i == 1 then
						t:SetPoint("RIGHT", HalionBar, "LEFT", 5, 0)
						t:SetSize(1, 10)
						t:SetAlpha(0)
					else
						t:SetPoint("LEFT", HalionBar.segments[i - 1], "RIGHT", 0, 0)
						t:SetSize(20, 10)
						t:SetVertexColor(unpack(colors[i]))
						if i <= 5 then
							t:SetAlpha(0.5)
						elseif i == 6 or i == 7 then
							t:SetAlpha(0.8)
						end
					end
					HalionBar.segments[i] = t
				end

				-- message
				HalionBar.message = HalionBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
				HalionBar.message:SetPoint("BOTTOM", HalionBar, "TOP", 0, 5)
				HalionBar.message:SetText("")

				-- here
				HalionBar.here = HalionBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
				HalionBar.here:SetPoint("TOPRIGHT", HalionBar, "BOTTOMRIGHT", -5, -5)
				HalionBar.here:SetText(L["Outside"])

				-- there
				HalionBar.there = HalionBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
				HalionBar.there:SetPoint("TOPLEFT", HalionBar, "BOTTOMLEFT", 5, -5)
				HalionBar.there:SetText(L["Inside"])

				-- corporeality indicator
				HalionBar.indicator = HalionBar:CreateTexture(nil, "OVERLAY")
				HalionBar.indicator:SetPoint("CENTER", HalionBar.segments[6], "RIGHT")
				HalionBar.indicator:SetWidth(10)
				HalionBar.indicator:SetHeight(30)
				HalionBar.indicator:SetTexture([[Interface\WorldStateFrame\WorldState-CaptureBar]])
				HalionBar.indicator:SetTexCoord(0.77734375, 0.796875, 0, 0.28125)
				HalionBar.indicator:SetDesaturated(true)

				HalionBar.MoveIndicator = MoveIndicator

				-- position
				HalionBar:SetScript("OnHide", function(self)
					self.position = nil
					self.message:SetText("")
					self.indicator:SetPoint("CENTER", HalionBar.segments[6], "RIGHT")
				end)
				HalionBar:SetPoint("CENTER")
				HalionBar:Hide()
			end
		end
	end

	-- play audio file
	function HalionHelper:AlertPlayer(file)
		if self.db.voice then
			PlaySoundFile("Interface\\AddOns\\KPack\\Media\\Sounds\\HalionHelper\\" .. file .. ".mp3", "Master")
		end
	end

	function HalionHelper:AnnounceToRaid(msg)
		if self.db.raid and IsRaidLeader() and msg and msg ~= "" then
			SendChatMessage(tostring(msg), "RAID_WARNING")
		end
	end

	function HalionHelper:GetOptions()
		if not options then
			local disabled = function()
				return not self.db.enabled
			end

			options = {
				type = "group",
				name = L["Halion Helper"],
				get = function(i)
					return HalionHelper.db[i[#i]]
				end,
				set = function(i, val)
					HalionHelper.db[i[#i]] = val
					HalionHelper:ApplySettings()
				end,
				args = {
					enabled = {
						type = "toggle",
						name = L["Enable"],
						order = 1
					},
					configmode = {
						type = "toggle",
						name = L["Configuration Mode"],
						order = 2,
						get = function()
							return configmode
						end,
						set = function()
							configmode = not configmode
							HalionHelper:ApplySettings()
						end,
						disabled = disabled
					},
					voice = {
						type = "toggle",
						name = VOICE,
						order = 3,
						disabled = disabled
					},
					raid = {
						type = "toggle",
						name = RAID_WARNING,
						order = 4,
						disabled = disabled
					},
					scale = {
						type = "range",
						name = L["Scale"],
						order = 5,
						min = 0.5,
						max = 3,
						step = 0.01,
						bigStep = 0.1,
						width = "double",
						disabled = disabled
					}
				}
			}
		end
		return options
	end

	function HalionHelper:SetupDatabase()
		if not self.db then
			if type(core.db.HalionHelper) ~= "table" then
				core.db.HalionHelper = CopyTable(defaults)
			end
			self.db = core.db.HalionHelper
		end

		core.options.args.Options.args.HalionHelper = self:GetOptions()
	end

	function HalionHelper:ApplySettings()
		if not self.db.enabled then
			self:UnregisterEvent("PLAYER_TARGET_CHANGED")
			self:UnregisterEvent("PLAYER_REGEN_ENABLED")
			self:UnregisterEvent("PLAYER_REGEN_DISABLED")
			self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

			configmode = nil

			if HalionBar then
				HalionBar:Hide()
				HalionBar = nil
			end

			return
		end

		self:CreateHalionBar()
		HalionBar:SetScale(self.db.scale or 1)
		core:RestorePosition(HalionBar, self.db)

		if configmode and not HalionBar:IsShown() then
			HalionBar:Show()
		elseif not configmode and HalionBar:IsShown() then
			HalionBar:Hide()
		end
	end

	function HalionHelper:PLAYER_ENTERING_WORLD()
		self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
		self:ZONE_CHANGED_NEW_AREA()
	end

	function HalionHelper:PLAYER_TARGET_CHANGED()
		if UnitExists("target") and self:IsHalion(UnitGUID("target")) then
			isInside = (cached[UnitGUID("target")] == 40142)
			if HalionBar and isInside then
				HalionBar.here:SetText(L["Inside"])
				HalionBar.there:SetText(L["Outside"])
			elseif HalionBar then
				HalionBar.here:SetText(L["Outside"])
				HalionBar.there:SetText(L["Inside"])
			end
		end
	end

	function HalionHelper:PLAYER_REGEN_DISABLED()
		cached = core.WeakTable(cached)
	end

	function HalionHelper:PLAYER_REGEN_ENABLED()
		cached = core.WeakTable(cached)
		if HalionBar and HalionBar:IsShown() then
			HalionBar:Hide()
		end
	end

	function HalionHelper:ZONE_CHANGED_NEW_AREA()
		if not self.db.enabled then
			self:UnregisterEvent("PLAYER_TARGET_CHANGED")
			self:UnregisterEvent("PLAYER_REGEN_ENABLED")
			self:UnregisterEvent("PLAYER_REGEN_DISABLED")
			self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
			return
		end

		local inInstance, instanceType = IsInInstance()
		if not inInstance or instanceType ~= "raid" then
			self:UnregisterEvent("PLAYER_TARGET_CHANGED")
			self:UnregisterEvent("PLAYER_REGEN_ENABLED")
			self:UnregisterEvent("PLAYER_REGEN_DISABLED")
			self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
			self.enabled = false
			return
		end

		local mapID = GetCurrentMapAreaID()
		self.enabled = (mapID == 610)

		if self.enabled then
			self:RegisterEvent("PLAYER_TARGET_CHANGED")
			self:RegisterEvent("PLAYER_REGEN_ENABLED")
			self:RegisterEvent("PLAYER_REGEN_DISABLED")
			self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		else
			self:UnregisterEvent("PLAYER_TARGET_CHANGED")
			self:UnregisterEvent("PLAYER_REGEN_ENABLED")
			self:UnregisterEvent("PLAYER_REGEN_DISABLED")
			self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		end

		self:ApplySettings()
	end

	function HalionHelper:UpdateCorporeality()
		if UnitExists("boss1") then
			for id, _ in pairs(corporeality) do
				local spellid = select(11, UnitBuff("boss1", GetSpellInfo(id)))
				if spellid and HalionBar then
					HalionBar:MoveIndicator(corporeality[spellid])
					break
				end
			end
		end
	end

	function HalionHelper:IsHalion(guid)
		if tonumber(guid) then
			if cached[guid] then
				return cached[guid]
			end

			local id = tonumber(guid:sub(9, 12), 16)
			if id and halion[id] then
				cached[guid] = id
				return id
			end
		end
	end

	function HalionHelper:COMBAT_LOG_EVENT_UNFILTERED(_, event, srcGUID, _, _, dstGUID, dstName, _, spellid, spellname)
		if not self.enabled or not core.InCombat then
			return
		end

		-- create the bar if not created
		self:CreateHalionBar()

		if self:IsHalion(srcGUID) == 40142 and not self.isInside then
			self.isInside = true
			if HalionBar then
				HalionBar.here:SetText(L["Inside"])
				HalionBar.there:SetText(L["Outside"])
				self:UpdateCorporeality()
			end
		elseif self:IsHalion(srcGUID) == 39863 and self.isInside then
			self.isInside = false
			if HalionBar then
				HalionBar.here:SetText(L["Outside"])
				HalionBar.there:SetText(L["Inside"])
				self:UpdateCorporeality()
			end
		end

		if event == "SPELL_AURA_APPLIED" then
			-- combustion/consumption
			if spellname == combustion then
				if dstGUID == core.guid then
					self:AlertPlayer("combustion")
				end

				if self.isInside then
					self.isInside = false
				end
			elseif spellname == consumption then
				if dstGUID == core.guid then
					self:AlertPlayer("consumption")
				end

				if not self.isInside then
					self.isInside = true
				end
			end

			-- corporeality
			if (self:IsHalion(dstGUID) or self:IsHalion(srcGUID)) and corporeality[spellid] then
				if not HalionBar:IsShown() then
					HalionBar:Show()
				end
				HalionBar:MoveIndicator(corporeality[spellid])
			end
		end
	end

	core:RegisterForEvent("PLAYER_LOGIN", function()
		-- ignore if the addon exists.
		if _G.HalionHelper then
			return
		end

		local self = HalionHelper
		self:SetupDatabase()

		SLASH_KPACKHALIONHELPER1 = "/halionhelper"
		SlashCmdList["KPACKHALIONHELPER"] = function()
			core:OpenConfig("Options", "HalionHelper")
		end

		self:RegisterEvent("PLAYER_ENTERING_WORLD")
		self:PLAYER_ENTERING_WORLD()
	end)
end)