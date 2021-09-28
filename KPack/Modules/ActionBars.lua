assert(KPack, "KPack not found!")
KPack:AddModule("ActionBars", "Allows you to tweak your action bars in the limit of the allowed.", function(_, core, L)
	if core:IsDisabled("ActionBars") or core.ElvUI then return end
	local disabled, reason = core:AddOnIsLoaded("Dominos", "Bartender4", "MiniMainBar", "ElvUI", "KActionBars")

	local mod = core.ActionBars or CreateFrame("Frame")
	mod:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)

	core.ActionBars = mod
	LibStub("AceHook-3.0"):Embed(mod)

	local _LoadAddOn = LoadAddOn
	local _IsActionInRange = IsActionInRange
	local _IsUsableAction = IsUsableAction
	local _InCombatLockdown = InCombatLockdown
	local _UnitAffectingCombat = UnitAffectingCombat
	local _UnitInVehicle = UnitInVehicle

	local _UnitLevel = UnitLevel
	local _IsXPUserDisabled = IsXPUserDisabled
	local _GetWatchedFactionInfo = GetWatchedFactionInfo
	local _TextStatusBar_UpdateTextString = TextStatusBar_UpdateTextString
	local _MainMenuExpBar_Update = MainMenuExpBar_Update
	local _UIParent_ManageFramePositions = UIParent_ManageFramePositions

	local _pairs, _ipairs, _type, _next = pairs, ipairs, type, next
	local _format, _match, _tostring, _tonumber = string.format, string.match, tostring, tonumber
	local math_min, math__max, _select = math.min, math.max, select
	local _SetCVar, _GetCVar = SetCVar, GetCVar

	local DB
	local defaults = {
		scale = 1,
		dark = true,
		range = true,
		art = true,
		hotkeys = 1,
		hover = false
	}

	-- module's print function
	local function Print(msg)
		if msg then
			core:Print(msg, "ActionBars")
		end
	end

	-- used to kill functions
	local function noFunc()
		return
	end

	-- utility functions used to show/hide a frame only if it exists
	local function Show(frame)
		if frame and frame.Show then
			frame:Show()
		end
	end
	local function Hide(frame)
		if frame and frame.Hide then
			frame:Hide()
		end
	end

	--
	-- scales action bar elements
	--
	local function ActionBars_ScaleBars(scale)
		DB = DB or core.db.ActionBars or {}
		scale = scale or DB.scale or 1
		_G.MainMenuBar:SetScale(scale)
		_G.MultiBarBottomLeft:SetScale(scale)
		_G.MultiBarBottomRight:SetScale(scale)
		_G.MultiBarRight:SetScale(scale)
		_G.MultiBarLeft:SetScale(scale)
		_G.VehicleMenuBar:SetScale(scale)
	end

	--
	-- Dark mode
	--
	local ActionBars_DarkMode
	do
		mod.textures = {
			normal = "Interface\\Addons\\KPack\\Media\\Textures\\AB_Normal",
			flash = "Interface\\Addons\\KPack\\Media\\Textures\\AB_Flash",
			hightlight = "Interface\\Addons\\KPack\\Media\\Textures\\AB_Hightlight",
			pushed = "Interface\\Addons\\KPack\\Media\\Textures\\AB_Pushed",
			checked = "Interface\\Addons\\KPack\\Media\\Textures\\AB_Checked",
			equipped = "Interface\\Addons\\KPack\\Media\\Textures\\AB_Equipped"
		}
		mod.colors = {
			normal = {r = 0.37, g = 0.3, b = 0.3},
			equipped = {r = 0.1, g = 0.5, b = 0.1}
		}

		local function Darken_Button(name)
			if not name or not _G[name] or _G[name].kpacked then return end
			_G[name].kpacked = true
			local btn = _G[name]

			-- crop icon
			local t = _G[name .. "Icon"]
			if t then
				t:SetTexCoord(0.1, 0.9, 0.1, 0.9)
				t:SetPoint("TOPLEFT", btn, "TOPLEFT", 2, -2)
				t:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 2)
			end

			-- remove border
			t = _G[name .. "Border"]
			if t then
				t:SetTexture(nil)
			end

			-- position cooldown
			t = _G[name .. "Cooldown"]
			if t then
				t:SetAllPoints(btn)
			end

			-- flash texture
			t = _G[name .. "Flash"]
			if t then
				t:SetTexture(mod.textures.flash)
			end

			-- normal texture
			t = _G[name .. "NormalTexture2"] or _G[name .. "NormalTexture"] or btn.GetNormalTexture and btn:GetNormalTexture()
			if t then
				if btn.action and IsEquippedAction(btn.action) then
					t:SetVertexColor(mod.colors.equipped.r, mod.colors.equipped.g, mod.colors.equipped.b, 1)
				else
					t:SetVertexColor(mod.colors.normal.r, mod.colors.normal.g, mod.colors.normal.b, 1)
				end
				t:SetAllPoints(btn)
				hooksecurefunc(t, "SetVertexColor", function(self, r, g, b, a)
					local bn = self:GetParent()
					if r == 1 and g == 1 and b == 1 and bn.action and (IsEquippedAction(btn.action)) then
						if mod.colors.equipped.r == 1 and mod.colors.equipped.g == 1 and mod.colors.equipped.b == 1 then
							self:SetVertexColor(0.99, 0.99, 0.99, 1)
						else
							self:SetVertexColor(mod.colors.equipped.r, mod.colors.equipped.g, mod.colors.equipped.b, 1)
						end
					elseif r == 0.5 and g == 0.5 and b == 1 then
						if mod.colors.normal.r == 0.5 and mod.colors.normal.g == 0.5 and mod.colors.normal.b == 1 then
							self:SetVertexColor(0.49, 0.49, 0.99, 1)
						else
							self:SetVertexColor(mod.colors.normal.r, mod.colors.normal.g, mod.colors.normal.b, 1)
						end
					elseif r == 1 and g == 1 and b == 1 then
						if mod.colors.normal.r == 1 and mod.colors.normal.g == 1 and mod.colors.normal.b == 1 then
							self:SetVertexColor(0.99, 0.99, 0.99, 1)
						else
							self:SetVertexColor(mod.colors.normal.r, mod.colors.normal.g, mod.colors.normal.b, 1)
						end
					end
				end)
			end

			-- normal texture
			if btn.SetNormalTexture then
				btn:SetNormalTexture(mod.textures.normal)
				hooksecurefunc(btn, "SetNormalTexture", function(self, texture)
					if texture and texture ~= mod.textures.normal then
						self:SetNormalTexture(mod.textures.normal)
					end
				end)
			end

			-- hightlight texture
			if btn.SetHighlightTexture then
				btn:SetHighlightTexture(mod.textures.hover)
				hooksecurefunc(btn, "SetHighlightTexture", function(self, texture)
					if texture and texture ~= mod.textures.hover then
						self:SetHighlightTexture(mod.textures.hover)
					end
				end)
			end

			-- pushed texture
			if btn.SetPushedtTexture then
				btn:SetPushedtTexture(mod.textures.pushed)
				hooksecurefunc(btn, "SetPushedtTexture", function(self, texture)
					if texture and texture ~= mod.textures.pushed then
						self:SetPushedtTexture(mod.textures.pushed)
					end
				end)
			end

			-- checked texture
			if btn.SetCheckedTexture then
				btn:SetCheckedTexture(mod.textures.checked)
				hooksecurefunc(btn, "SetCheckedTexture", function(self, texture)
					if texture and texture ~= mod.textures.checked then
						self:SetCheckedTexture(mod.textures.checked)
					end
				end)
			end
		end

		local function Darken_BagButton(name, vertex)
			if not name or not _G[name] or _G[name].kpacked then return end
			_G[name].kpacked = true
			local btn = _G[name]

			-- icon
			local t = _G[name .. "IconTexture"]
			if t then
				t:SetTexCoord(0.1, 0.9, 0.1, 0.9)
				t:SetPoint("TOPLEFT", btn, "TOPLEFT", 2, -2)
				t:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 2)
			end

			-- normal texture
			t = _G[name .. "NormalTexture"] or btn:GetNormalTexture()
			if t then
				t:SetTexCoord(0, 1, 0, 1)
				t:SetDrawLayer("BACKGROUND", -7)
				t:SetVertexColor(vertex, vertex, vertex)
				t:SetAllPoints(btn)
			end
			if btn.SetNormalTexture then
				btn:SetNormalTexture(mod.textures.normal)
				hooksecurefunc(btn, "SetNormalTexture", function(self, texture)
					if texture and texture ~= mod.textures.normal then
						self:SetNormalTexture(mod.textures.normal)
					end
				end)
			end

			-- hightlight texture
			if btn.SetHighlightTexture then
				btn:SetHighlightTexture(mod.textures.hover)
				hooksecurefunc(btn, "SetHighlightTexture", function(self, texture)
					if texture and texture ~= mod.textures.hover then
						self:SetHighlightTexture(mod.textures.hover)
					end
				end)
			end

			-- pushed texture
			if btn.SetPushedtTexture then
				btn:SetPushedtTexture(mod.textures.pushed)
				hooksecurefunc(btn, "SetPushedtTexture", function(self, texture)
					if texture and texture ~= mod.textures.pushed then
						self:SetPushedtTexture(mod.textures.pushed)
					end
				end)
			end

			-- checked texture
			if btn.SetCheckedTexture then
				btn:SetCheckedTexture(mod.textures.checked)
				hooksecurefunc(btn, "SetCheckedTexture", function(self, texture)
					if texture and texture ~= mod.textures.checked then
						self:SetCheckedTexture(mod.textures.checked)
					end
				end)
			end
		end

		function ActionBars_DarkMode()
			if not DB.dark then return end
			for i, v in pairs({
				-- UnitFrames
				"PlayerFrameTexture",
				"TargetFrameTextureFrameTexture",
				"PetFrameTexture",
				"PartyMemberFrame1Texture",
				"PartyMemberFrame2Texture",
				"PartyMemberFrame3Texture",
				"PartyMemberFrame4Texture",
				"PartyMemberFrame1PetFrameTexture",
				"PartyMemberFrame2PetFrameTexture",
				"PartyMemberFrame3PetFrameTexture",
				"PartyMemberFrame4PetFrameTexture",
				"FocusFrameTextureFrameTexture",
				"TargetFrameToTTextureFrameTexture",
				"FocusFrameToTTextureFrameTexture",
				"Boss1TargetFrameTextureFrameTexture",
				"Boss2TargetFrameTextureFrameTexture",
				"Boss3TargetFrameTextureFrameTexture",
				"Boss4TargetFrameTextureFrameTexture",
				"Boss5TargetFrameTextureFrameTexture",
				"Boss1TargetFrameSpellBarBorder",
				"Boss2TargetFrameSpellBarBorder",
				"Boss3TargetFrameSpellBarBorder",
				"Boss4TargetFrameSpellBarBorder",
				"Boss5TargetFrameSpellBarBorder",
				"RuneButtonIndividual1BorderTexture",
				"RuneButtonIndividual2BorderTexture",
				"RuneButtonIndividual3BorderTexture",
				"RuneButtonIndividual4BorderTexture",
				"RuneButtonIndividual5BorderTexture",
				"RuneButtonIndividual6BorderTexture",
				"CastingBarFrameBorder",
				"FocusFrameSpellBarBorder",
				"TargetFrameSpellBarBorder",
				-- MainMenuBar
				"SlidingActionBarTexture0",
				"SlidingActionBarTexture1",
				"BonusActionBarTexture0",
				"BonusActionBarTexture1",
				"BonusActionBarTexture",
				"MainMenuBarTexture0",
				"MainMenuBarTexture1",
				"MainMenuBarTexture2",
				"MainMenuBarTexture3",
				"MainMenuMaxLevelBar0",
				"MainMenuMaxLevelBar1",
				"MainMenuMaxLevelBar2",
				"MainMenuMaxLevelBar3",
				"MainMenuXPBarTextureLeftCap",
				"MainMenuXPBarTextureRightCap",
				"MainMenuXPBarTextureMid",
				"ReputationWatchBarTexture0",
				"ReputationWatchBarTexture1",
				"ReputationWatchBarTexture2",
				"ReputationWatchBarTexture3",
				"ReputationXPBarTexture0",
				"ReputationXPBarTexture1",
				"ReputationXPBarTexture2",
				"ReputationXPBarTexture3",
				"MainMenuBarLeftEndCap",
				"MainMenuBarRightEndCap",
				"StanceBarLeft",
				"StanceBarMiddle",
				"StanceBarRight",
				"ShapeshiftBarLeft",
				"ShapeshiftBarMiddle",
				"ShapeshiftBarRight",
				-- ArenaFrames
				"ArenaEnemyFrame1Texture",
				"ArenaEnemyFrame2Texture",
				"ArenaEnemyFrame3Texture",
				"ArenaEnemyFrame4Texture",
				"ArenaEnemyFrame5Texture",
				"ArenaEnemyFrame1SpecBorder",
				"ArenaEnemyFrame2SpecBorder",
				"ArenaEnemyFrame3SpecBorder",
				"ArenaEnemyFrame4SpecBorder",
				"ArenaEnemyFrame5SpecBorder",
				"ArenaEnemyFrame1PetFrameTexture",
				"ArenaEnemyFrame2PetFrameTexture",
				"ArenaEnemyFrame3PetFrameTexture",
				"ArenaEnemyFrame4PetFrameTexture",
				"ArenaEnemyFrame5PetFrameTexture",
				"ArenaPrepFrame1Texture",
				"ArenaPrepFrame2Texture",
				"ArenaPrepFrame3Texture",
				"ArenaPrepFrame4Texture",
				"ArenaPrepFrame5Texture",
				"ArenaPrepFrame1SpecBorder",
				"ArenaPrepFrame2SpecBorder",
				"ArenaPrepFrame3SpecBorder",
				"ArenaPrepFrame4SpecBorder",
				"ArenaPrepFrame5SpecBorder",
				-- PANES
				"CharacterFrameTitleBg",
				"CharacterFrameBg",
				-- MINIMAP
				"MinimapBorder",
				"MinimapBorderTop",
				"MiniMapTrackingButtonBorder",
				"TargetFrameSpellBarBorderShield",
				"FocusFrameSpellBarBorderShield",
				-- CompactRaidFrame
				"CompactRaidFrameManagerBorderTop",
				"CompactRaidFrameManagerBorderTopLeft",
				"CompactRaidFrameManagerBorderTopRight",
				"CompactRaidFrameManagerBorderBottom",
				"CompactRaidFrameManagerBorderBottomLeft",
				"CompactRaidFrameManagerBorderBottomRight",
				"CompactRaidFrameManagerBorderLeft",
				"CompactRaidFrameManagerBorderRight",
				"CompactRaidFrameManagerBg",
				"CompactRaidFrameContainerBorderFrameBorderTop",
				"CompactRaidFrameContainerBorderFrameBorderTopLeft",
				"CompactRaidFrameContainerBorderFrameBorderTopRight",
				"CompactRaidFrameContainerBorderFrameBorderBottom",
				"CompactRaidFrameContainerBorderFrameBorderBottomLeft",
				"CompactRaidFrameContainerBorderFrameBorderBottomRight",
				"CompactRaidFrameContainerBorderFrameBorderLeft",
				"CompactRaidFrameContainerBorderFrameBorderRight"}) do
				if _G[v] then
					_G[v]:SetVertexColor(mod.colors.normal.r, mod.colors.normal.g, mod.colors.normal.b, 1)
				end
			end

			for i = 0, NUM_ACTIONBAR_BUTTONS do
				Darken_Button("ActionButton" .. i)
				Darken_Button("BonusActionButton" .. i)
				Darken_Button("MultiBarBottomLeftButton" .. i)
				Darken_Button("MultiBarBottomRightButton" .. i)
				Darken_Button("MultiBarRightButton" .. i)
				Darken_Button("MultiBarLeftButton" .. i)
				Darken_Button("ShapeshiftButton" .. i)
				Darken_Button("PetActionButton" .. i)

				if i <= 3 then
					Darken_BagButton("CharacterBag" .. i .. "Slot")
				end
			end
			Darken_BagButton("MainMenuBarBackpackButton")
		end
	end

	--
	-- turns button red if target out of range
	--
	local ActionBars_Range
	do
		function mod:ActionButton_OnEvent(btn, event, ...)
			if event == "PLAYER_TARGET_CHANGED" then
				btn.newTimer = btn.rangeTimer
			end
		end

		function mod:ActionButton_UpdateUsable(btn)
			local icon = _G[btn:GetName() .. "Icon"]
			local valid = _IsActionInRange(btn.action)
			if valid == 0 then
				icon:SetVertexColor(1.0, 0.1, 0.1)
			elseif not _IsUsableAction(btn.action) then
				icon:SetVertexColor(0.5, 0.5, 1.0)
			else
				icon:SetVertexColor(1.0, 1.0, 1.0)
			end
		end

		function mod:ActionButton_OnUpdate(btn, elapsed)
			local rangeTimer = btn.newTimer
			if rangeTimer then
				rangeTimer = rangeTimer - elapsed
				if rangeTimer <= 0 then
					mod:ActionButton_UpdateUsable(btn)
					rangeTimer = _G.TOOLTIP_UPDATE_TIME
				end
				btn.newTimer = rangeTimer
			end
		end

		function ActionBars_Range()
			if DB.range == true and not mod:IsHooked("ActionButton_OnEvent") then
				mod:SecureHook("ActionButton_OnEvent")
				mod:SecureHook("ActionButton_UpdateUsable")
				mod:SecureHook("ActionButton_OnUpdate")
			elseif not DB.range and mod:IsHooked("ActionButton_OnEvent") then
				mod:UnhookAll()
			end
		end
	end

	--
	-- handle hiding/showing action bar gryphons
	--
	local function ActionBars_Gryphons()
		if DB.art then
			_G.MainMenuBarLeftEndCap:Hide()
			_G.MainMenuBarRightEndCap:Hide()
		else
			_G.MainMenuBarLeftEndCap:Show()
			_G.MainMenuBarRightEndCap:Show()
		end
	end

	local function ActionBars_Hotkeys(opacity)
		opacity = opacity or DB.hotkeys or 1
		local mopacity = opacity / 1.2 -- macro name opacity
		for i = 1, 12 do
			_G["ActionButton" .. i .. "HotKey"]:SetAlpha(opacity)
			_G["BonusActionButton" .. i .. "HotKey"]:SetAlpha(opacity)
			_G["MultiBarBottomRightButton" .. i .. "HotKey"]:SetAlpha(opacity)
			_G["MultiBarBottomLeftButton" .. i .. "HotKey"]:SetAlpha(opacity)
			_G["MultiBarRightButton" .. i .. "HotKey"]:SetAlpha(opacity)
			_G["MultiBarLeftButton" .. i .. "HotKey"]:SetAlpha(opacity)

			_G["ActionButton" .. i .. "Name"]:SetAlpha(mopacity)
			_G["BonusActionButton" .. i .. "Name"]:SetAlpha(mopacity)
			_G["MultiBarBottomRightButton" .. i .. "Name"]:SetAlpha(mopacity)
			_G["MultiBarBottomLeftButton" .. i .. "Name"]:SetAlpha(mopacity)
			_G["MultiBarRightButton" .. i .. "Name"]:SetAlpha(mopacity)
			_G["MultiBarLeftButton" .. i .. "Name"]:SetAlpha(mopacity)
		end
	end

	--
	-- mouseover right action bars
	--
	local ActionBars_MouseOver
	do
		local function MouseOver_OnUpdate(self, elapsed)
			self.lastUpdate = self.lastUpdate + elapsed
			if self.lastUpdate > 0.5 then
				self:SetAlpha(MouseIsOver(self) and 1 or 0)
			end
		end

		function ActionBars_MouseOver()
			if DB.hover == true then
				for _, frame in _ipairs({MultiBarLeft, MultiBarRight}) do
					if frame:IsShown() then
						frame.lastUpdate = 0
						frame:SetScript("OnUpdate", MouseOver_OnUpdate)
					else
						frame:SetScript("OnUpdate", nil)
					end
				end
			else
				for _, frame in _ipairs({MultiBarLeft, MultiBarRight}) do
					if frame:IsShown() and frame.lastUpdate then
						frame.lastUpdate = nil
						frame:SetScript("OnUpdate", nil)
						frame:SetAlpha(1)
					end
				end
			end
		end
	end

	-- ========================================================== --

	local options = {
		type = "group",
		name = "ActionBars",
		get = function(i)
			return DB[i[#i]]
		end,
		set = function(i, val)
			DB[i[#i]] = val
			mod:ApplySettings()
		end,
		args = {
			status = {
				type = "description",
				name = L:F("This module is disabled because you are using: |cffffd700%s|r", reason or UNKNOWN),
				fontSize = "medium",
				order = 0,
				hidden = not disabled
			},
			art = {
				type = "toggle",
				name = L["Hide Gryphons"],
				order = 1,
				disabled = function() return disabled end,
				set = function(_, val)
					DB.art = val
					ActionBars_Gryphons()
				end
			},
			range = {
				type = "toggle",
				name = L["Range Detection"],
				desc = L["Turns your buttons red if your target is out of range."],
				disabled = function() return disabled end,
				order = 2
			},
			dark = {
				type = "toggle",
				name = L["Dark Mode"],
				disabled = function() return disabled end,
				order = 3
			},
			hover = {
				type = "toggle",
				name = L["Hover Mode"],
				desc = L["Shows your right action bars on hover."],
				disabled = function() return disabled end,
				order = 4
			},
			scale = {
				type = "range",
				name = L["Scale"],
				desc = L["Changes action bars scale"],
				order = 7,
				disabled = function() return disabled end,
				min = 0.5,
				max = 3,
				step = 0.01,
				bigStep = 0.1
			},
			hotkeys = {
				type = "range",
				name = L["Hotkeys"],
				desc = L["Changes the opacity of action bar hotkeys."],
				order = 8,
				disabled = function() return disabled end,
				min = 0,
				max = 1,
				step = 0.01,
				bigStep = 0.1
			},
			reset = {
				type = "execute",
				name = RESET,
				order = 9,
				disabled = function() return disabled end,
				width = "full",
				confirm = function()
					return L:F("Are you sure you want to reset %s to default?", "Automate")
				end,
				func = function()
					core.db.ActionBars = nil
					DB = nil
					mod:SetupDatabase()
					Print(L["module's settings reset to default."])
					mod:ApplySettings()
				end
			}
		}
	}

	function mod:SetupDatabase()
		if not DB then
			if type(core.db.ActionBars) ~= "table" or not next(core.db.ActionBars) then
				core.db.ActionBars = CopyTable(defaults)
			end
			DB = core.db.ActionBars
		end
	end

	function mod:ApplySettings()
		mod:SetupDatabase()
		if not disabled then
			ActionBars_Gryphons()
			ActionBars_Range()
			ActionBars_MouseOver()
			ActionBars_ScaleBars()
			ActionBars_Hotkeys()
			ActionBars_DarkMode()
		end
	end

	function mod:PLAYER_ENTERING_WORLD()
		mod:ApplySettings()
	end

	core:RegisterForEvent("PLAYER_LOGIN", function()
		mod:SetupDatabase()

		SLASH_KPACKABM1 = "/abm"
		SlashCmdList.KPACKABM = function()
			return core:OpenConfig("Options", "ActionBars")
		end
		core.options.args.Options.args.ActionBars = options
		mod:RegisterEvent("PLAYER_ENTERING_WORLD")
	end)
end)