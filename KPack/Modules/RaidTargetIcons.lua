local core = KPack
if not core then return end
core:AddModule("Target Icons", "Allows you to quickly mark raid targets using a radial menu.", function(L)
	if core:IsDisabled(L["Target Icons"]) then return end

	local RTI = {}

	local DB, SetupDatabase
	local defaults = {
		ctrl = true,
		alt = false,
		shift = false,
		singlehover = false,
		speed = 0.25,
		double = true,
		doublehover = false,
		bindinghover = false,
		hovertime = 0.2
	}

	local math_atan2 = math.atan2
	local math_ceil = math.ceil
	local math_deg = math.deg
	local math_floor = math.floor
	local math_sqrt = math.sqrt

	local GetTime = GetTime
	local GetCursorPosition = GetCursorPosition
	local GetNumRaidMembers = GetNumRaidMembers
	local GetRaidTargetIndex = GetRaidTargetIndex
	local IsRaidLeader = IsRaidLeader
	local IsRaidOfficer = IsRaidOfficer
	local PlaySound = PlaySound
	local SetPortraitTexture = SetPortraitTexture
	local UnitExists = UnitExists
	local UnitIsDeadOrGhost = UnitIsDeadOrGhost
	local UnitIsUnit = UnitIsUnit
	local UnitPlayerOrPetInRaid = UnitPlayerOrPetInRaid

	RTI.button = CreateFrame("Button", "KPackRaidTargetIconsMenu", UIParent)
	RTI.button:SetPoint("CENTER", UIParent, "BOTTOMLEFT", 0, 0)
	RTI.button:SetClampedToScreen(true)
	RTI.button:SetSize(100, 100)
	RTI.button:SetFrameStrata("DIALOG")
	RTI.button:Hide()
	RTI.button.origShow = RTI.button.Show

	RTI.button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	RTI.button:RegisterEvent("PLAYER_TARGET_CHANGED")

	function RTI.button:Show()
		RTI.button.p = RTI.button:CreateTexture("KPackRaidTargetIconsMenuPortrait", "BORDER")
		RTI.button.p:SetWidth(40)
		RTI.button.p:SetHeight(40)
		RTI.button.p:SetPoint("CENTER", RTI.button, "CENTER", 0, 0)
		RTI.button.b = RTI.button:CreateTexture("KPackRaidTargetIconsMenuBorder", "BACKGROUND")
		RTI.button.b:SetTexture("Interface\\Minimap\\UI-TOD-Indicator")
		RTI.button.b:SetWidth(80)
		RTI.button.b:SetHeight(80)
		RTI.button.b:SetTexCoord(0.5, 1, 0, 1)
		RTI.button.b:SetPoint("CENTER", RTI.button, "CENTER", 10, -10)
		for i = 1, 8 do
			RTI.button[i] = RTI.button:CreateTexture("KPackRaidTargetIconsMenu" .. i, "OVERLAY")
		end

		RTI.button:origShow()
		RTI.button.Show = RTI.button.origShow
		RTI.button.origShow = nil

		RTI.button:SetScript("OnUpdate", function(self, arg1)
			local portrait = RTI.button.portrait
			RTI.button.portrait = nil
			local saved, index = self.index, GetRaidTargetIndex("target")
			self.index = nil
			local curtime = GetTime()
			if not self.hiding then
				if not UnitExists("target") or (not UnitPlayerOrPetInRaid("target") and UnitIsDeadOrGhost("target")) then
					if portrait then
						self:Hide()
						return
					else
						self.hiding = curtime
					end
				elseif portrait then
					if portrait == 0 and not (UnitIsUnit("target", "mouseover") or RTI.nameplate) then
						self:Hide()
						return
					end
					PlaySound("igMainMenuOptionCheckBoxOn")
					SetPortraitTexture(RTI.button.p, "target")
				end

				local x, y = GetCursorPosition()
				local s = RTI.button:GetEffectiveScale()
				local mx, my = RTI.button:GetCenter()
				x = x / s
				y = y / s

				local a, b = y - my, x - mx

				local dist = math_floor(math_sqrt(a * a + b * b))

				if dist > 60 then
					if dist > 200 then
						self.lingering = nil
						self.hiding = curtime
						self.showinghowing = nil
						PlaySound("igMainMenuOptionCheckBoxOff")
					elseif not self.lingering then
						self.lingering = curtime
					end
				else
					self.lingering = nil

					if dist > 20 and dist < 50 then
						local pos = math_deg(math_atan2(a, b)) + 27.5
						self.index = mod(11 - math_ceil(pos / 45), 8) + 1
					end
				end

				for i = 1, 8 do
					local t = self[i]
					if index == i then
						t:SetTexCoord(0, 1, 0, 1)
						t:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
					else
						t:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
						SetRaidTargetIconTexture(t, i)
					end
				end

				if self.hovering then
					if self.index and (not saved or saved == self.index) then
						self.hovering = self.hovering + arg1
						if self.hovering > (DB.hovertime or 0.2) then
							self:Click()
						end
					else
						self.hovering = 0
					end
				end
			end

			if self.showing then
				local status = curtime - self.showing
				if status > 0.1 then
					RTI.button.p:SetAlpha(1)
					RTI.button.b:SetAlpha(1)
					for i = 1, 8 do
						local t, radians = self[i], (0.375 - i / 8) * 360
						t:SetPoint("CENTER", self, "CENTER", 36 * cos(radians), 36 * sin(radians))
						t:SetAlpha(0.5)
						t:SetWidth(18)
						t:SetHeight(18)
					end
					self.showing = nil
				else
					status = status / 0.1
					RTI.button.p:SetAlpha(status)
					RTI.button.b:SetAlpha(status)
					for i = 1, 8 do
						local t, radians = self[i], (0.375 - i / 8) * 360
						t:SetPoint(
							"CENTER",
							self,
							"CENTER",
							(20 * status + 16) * cos(radians),
							(20 * status + 16) * sin(radians)
						)
						if i == index then
							t:SetAlpha(status)
						else
							t:SetAlpha(0.5 * status)
						end
						t:SetWidth(9 * status + 9)
						t:SetHeight(9 * status + 9)
					end
				end
			elseif self.hiding then
				local status = curtime - self.hiding
				if status > 0.1 then
					self.hiding = nil
					self:Hide()
				else
					status = 1 - status / 0.1
					RTI.button.p:SetAlpha(status)
					RTI.button.b:SetAlpha(status)
					for i = 1, 8 do
						local t, radians = self[i], (0.375 - i / 8) * 360
						if self.index == i then
							t:SetWidth(36 - 18 * status)
							t:SetHeight(36 - 18 * status)
							t:SetAlpha(min(4 * status, 1))
						else
							t:SetPoint(
								"CENTER",
								self,
								"CENTER",
								(20 * status + 16) * cos(radians),
								(20 * status + 16) * sin(radians)
							)
							t:SetAlpha(0.75 * status)
							t:SetWidth(18 * status)
							t:SetHeight(18 * status)
						end
					end
				end
			else
				for i = 1, 8 do
					local t = self[i]
					if i == index then
						t:SetAlpha(1)
					else
						t:SetAlpha(0.75)
					end
					t:SetWidth(18)
					t:SetHeight(18)
				end
			end

			if (self.index) then
				local t = self[self.index]
				local alpha, width = t:GetAlpha(), t:GetWidth()

				if not self.time or saved ~= self.index then
					self.time = curtime
				end
				local s = 1 + min((curtime - self.time) / 0.05, 1)

				t:SetAlpha(min(alpha + 0.125 * s, 1))
				t:SetWidth(width * s)
				t:SetHeight(width * s)
			end

			if self.lingering then
				local status = curtime - self.lingering
				if status > 0.75 then
					self.hiding = curtime
					self.lingering = nil
					self.showing = nil
					self.index = nil
					PlaySound("igMainMenuOptionCheckBoxOff")
				end
			end
		end)

		RTI.button:SetScript("OnClick", function(self, arg1)
			if not self.hiding then
				local index = GetRaidTargetIndex("target")
				if (arg1 == "RightButton" and index and index > 0) or (self.index and self.index > 0 and self.index == index) then
					self.index = index
					PlaySound("igMiniMapZoomOut")
					RTI.SetRaidTarget(0)
				elseif (self.index) then
					PlaySound("igMiniMapZoomIn")
					RTI.SetRaidTarget(self.index)
				else
					PlaySound("igMainMenuOptionCheckBoxOff")
				end
				self.showing = nil
				self.hiding = GetTime()
			end
		end)
	end

	RTI.button:SetScript("OnEvent", function(self, event, ...)
		if self:IsVisible() and not self.exists and not self.hiding then
			self.index = nil
			self.showing = nil
			self.hiding = GetTime()
			PlaySound("igMainMenuOptionCheckBoxOff")
			self.exists = nil
		elseif self.exists then
			self.exists = nil
		end
	end)

	function RTI.Show(frombinding)
		if DB.debug == nil then
			local num = GetNumRaidMembers()
			if num > 0 then
				if not (IsRaidLeader() or IsRaidOfficer()) then
					return
				end
			end
		end

		RTI.button.showing = GetTime()
		RTI.button.hiding = nil
		RTI.button.index = nil
		RTI.button.lingering = nil
		if UnitExists("target") and frombinding or UnitIsUnit("target", "mouseover") then
			RTI.button.exists = nil
		else
			RTI.button.exists = 1
		end
		RTI.button.portrait = frombinding or 0

		local x, y = GetCursorPosition()
		local s = RTI.button:GetEffectiveScale()
		RTI.button:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / s, y / s)
		RTI.button:Show()
	end

	function RTI.IsNameplateUnderMouse()
		local numch = WorldFrame:GetNumChildren()
		if numch > 0 then
			for i = 1, numch do
				local f = select(i, WorldFrame:GetChildren())
				if f:IsShown() and f:IsMouseOver() then
					-- 3rd party nameplate addons
					if f.aloftData or f.extended or f.done then
						return true
					end

					-- default nameplates
					local r = select(2, f:GetRegions())
					if not f:GetName() and r and r:GetObjectType("Texture") and (r.GetTexture and r:GetTexture() == "Interface\\Tooltips\\Nameplate-Border") then
						return true
					end
				end
			end
		end
		return false
	end

	function RTI.AreModifiersDown()
		SetupDatabase()
		if not DB.ctrl and not DB.alt and not DB.shift then
			return false
		elseif DB.ctrl ~= (IsControlKeyDown() == 1) then
			return false
		elseif DB.alt ~= (IsAltKeyDown() == 1) then
			return false
		elseif DB.shift ~= (IsShiftKeyDown() == 1) then
			return false
		end
		return true
	end

	local origSetRaidTarget = SetRaidTarget
	function RTI.SetRaidTarget(index, unit, fromBinding)
		index = index or 0
		if RTI.button:IsVisible() then
			RTI.button.i = index
			RTI.button:Click()
		end
		if not fromBinding then
			origSetRaidTarget("target", index)
		end
	end
	hooksecurefunc("SetRaidTarget", function(unit, index)
		RTI.SetRaidTarget(index, unit, 1)
	end)

	local clickFrameScripts = {}
	local clickFrames = {
		"WorldFrame",
		"TargetFrame",
		"FocusFrame",
		"Boss1TargetFrame",
		"Boss2TargetFrame",
		"Boss3TargetFrame",
		"Boss4TargetFrame"
	}
	do
		for _, frameName in pairs(clickFrames) do
			clickFrameScripts[frameName] = _G[frameName]:GetScript("OnMouseUp")
			if not clickFrameScripts[frameName] and _G[frameName]:IsObjectType("Button") then
				_G[frameName]:RegisterForClicks("AnyUp")
			end
			_G[frameName]:SetScript("OnMouseUp", function(self, arg1) RTI.OnMouseUp(self, arg1) end)
		end
	end

	function RTI.OnMouseUp(frame, btn)
		if btn == "LeftButton" then
			local curtime = GetTime()
			local x, y = GetCursorPosition()
			local modifiers = RTI.AreModifiersDown()
			RTI.nameplate = RTI.IsNameplateUnderMouse()
			local double =
				(DB.double and RTI.click and curtime - RTI.click < (DB.speed or 0.25) and abs(x - RTI.clickX) < 20 and
				abs(y - RTI.clickY) < 20)
			if modifiers or double then
				if (modifiers and DB.singlehover) or (double and DB.doublehover) then
					RTI.button.hovering = 0
				else
					RTI.button.hovering = nil
				end
				RTI.click = nil
				RTI.Show()
			else
				RTI.click = curtime
			end
			RTI.clickX, RTI.clickY = x, y
		end
		if clickFrameScripts[frame:GetName()] then
			clickFrameScripts[frame:GetName()](frame, btn)
		end
	end

	function SetupDatabase()
		if not DB then
			if type(core.db.RTI) ~= "table" or next(core.db.RTI) == nil then
				core.db.RTI = CopyTable(defaults)
			end
			DB = core.db.RTI
		end
	end

	core:RegisterForEvent("PLAYER_LOGIN", function()
		SetupDatabase()

		core.options.args.Options.args.RTI = {
			type = "group",
			name = L["Target Icons"],
			get = function(i)
				return DB[i[#i]]
			end,
			set = function(i, val)
				DB[i[#i]] = val
			end,
			args = {
				singleclick = {
					type = "group",
					name = L["Left Click"],
					order = 1,
					inline = true,
					args = {
						modifiers = {
							type = "description",
							name = L["Modifiers"],
							order = 1,
							width = "half"
						},
						ctrl = {
							type = "toggle",
							name = L["CTRL"],
							order = 2,
							width = "half"
						},
						alt = {
							type = "toggle",
							name = L["ALT"],
							order = 3,
							width = "half"
						},
						shift = {
							type = "toggle",
							name = L["SHIFT"],
							order = 4,
							width = "half"
						},
						singlehover = {
							type = "toggle",
							name = L["Select Icon on Hover"],
							order = 5,
							width = "full"
						}
					}
				},
				doubleclick = {
					type = "group",
					name = L["Double Left Click"],
					order = 2,
					inline = true,
					args = {
						double = {
							type = "toggle",
							name = L["Enable"],
							order = 1
						},
						doublehover = {
							type = "toggle",
							name = L["Select Icon on Hover"],
							order = 2
						},
						speed = {
							type = "range",
							name = L["Double Click Speed"],
							order = 3,
							width = "full",
							min = 0.15,
							max = 0.5,
							step = 0.01
						}
					}
				},
				hovertime = {
					type = "range",
					name = L["Hover Wait Time"],
					order = 3,
					width = "full",
					min = 0,
					max = 0.5,
					step = 0.05
				},
				sep = {
					type = "description",
					name = " ",
					order = 4,
					width = "full"
				},
				reset = {
					type = "execute",
					name = RESET,
					order = 99,
					width = "full",
					confirm = function()
						return L:F("Are you sure you want to reset %s to default?", L["Target Icons"])
					end,
					func = function()
						wipe(core.db.RTI)
						DB = nil
						SetupDatabase()
						core:Print(L["module's settings reset to default."], L["Target Icons"])
					end
				}
			}
		}
	end)
end)