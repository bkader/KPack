local core = KPack
if not core then return end
core:AddModule("Dark Mode", function(L)
	if core:IsDisabled("Dark Mode") then return end

	local DB
	local defaults = {
		normal = {r = 0.37, g = 0.37, b = 0.37, a = 1},
		equipped = {r = 0.1, g = 0.5, b = 0.1, a = 1}
	}

	local config = {
		textures = {
			normal = [[Interface\Addons\KPack\Media\Textures\AB_Normal]],
			flash = [[Interface\Addons\KPack\Media\Textures\AB_Flash]],
			hightlight = [[Interface\Addons\KPack\Media\Textures\AB_Hightlight]],
			pushed = [[Interface\Addons\KPack\Media\Textures\AB_Pushed]],
			checked = [[Interface\Addons\KPack\Media\Textures\AB_Checked]],
			equipped = [[Interface\Addons\KPack\Media\Textures\AB_Equipped]]
		},
		colors = {
			normal = {r = 0.37, g = 0.37, b = 0.37, a = 1},
			equipped = {r = 0.1, g = 0.5, b = 0.1, a = 1}
		}
	}

	local framesList = {
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
		"MainMenuXPBarTexture0",
		"MainMenuXPBarTexture1",
		"MainMenuXPBarTexture2",
		"MainMenuXPBarTexture3",
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
		"CompactRaidFrameContainerBorderFrameBorderRight",
		-- Fake Dominos Textures
		"DominosMicroMenuArtTexture",
		"DominosActionBarArtTexture"
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
			t:ClearAllPoints()
			t:SetAllPoints(btn)
			t:SetTexture(config.textures.equipped)
			if btn.action and IsEquippedAction(btn.action) then
				t:SetVertexColor(config.colors.equipped.r or 0, config.colors.equipped.g or 1, config.colors.equipped.b or 0, config.colors.equipped.a or 0.65)
				t:Show()
			elseif btn.action then
				t:Hide()
			end
			local _SetVertexColor = t.SetVertexColor
			t.SetVertexColor = function(self, r, g, b, a)
				if btn.action and IsEquippedAction(btn.action) then
					_SetVertexColor(self, config.colors.equipped.r or 0, config.colors.equipped.g or 1, config.colors.equipped.b or 0, config.colors.equipped.a or 0.65)
				else
					_SetVertexColor(self, r, g, b, a)
				end
			end
		end

		-- position cooldown
		t = _G[name .. "Cooldown"]
		if t then
			t:SetAllPoints(btn)
		end

		-- flash texture
		t = _G[name .. "Flash"]
		if t then
			t:SetTexture(config.textures.flash)
		end

		-- normal texture
		t = _G[name .. "NormalTexture2"] or _G[name .. "NormalTexture"] or btn.GetNormalTexture and btn:GetNormalTexture()
		if t then
			if btn.action and IsEquippedAction(btn.action) then
				t:SetVertexColor(config.colors.equipped.r, config.colors.equipped.g, config.colors.equipped.b, config.colors.equipped.a or 1)
			else
				t:SetVertexColor(config.colors.normal.r, config.colors.normal.g, config.colors.normal.b, config.colors.normal.a or 1)
			end
			t:SetAllPoints(btn)
			hooksecurefunc(t, "SetVertexColor", function(self, r, g, b, a)
				local bn = self:GetParent()
				if r == 1 and g == 1 and b == 1 and bn.action and (IsEquippedAction(btn.action)) then
					if config.colors.equipped.r == 1 and config.colors.equipped.g == 1 and config.colors.equipped.b == 1 then
						self:SetVertexColor(0.99, 0.99, 0.99, 1)
					else
						self:SetVertexColor(config.colors.equipped.r, config.colors.equipped.g, config.colors.equipped.b, config.colors.equipped.a or 1)
					end
				elseif r == 0.5 and g == 0.5 and b == 1 then
					if config.colors.normal.r == 0.5 and config.colors.normal.g == 0.5 and config.colors.normal.b == 1 then
						self:SetVertexColor(0.49, 0.49, 0.99, 1)
					else
						self:SetVertexColor(config.colors.normal.r, config.colors.normal.g, config.colors.normal.b, config.colors.normal.a or 1)
					end
				elseif r == 1 and g == 1 and b == 1 then
					if
						config.colors.normal.r == 1 and config.colors.normal.g == 1 and
							config.colors.normal.b == 1
					 then
						self:SetVertexColor(0.99, 0.99, 0.99, 1)
					else
						self:SetVertexColor(config.colors.normal.r, config.colors.normal.g, config.colors.normal.b, config.colors.normal.a or 1)
					end
				end
			end)
		end

		-- normal texture
		if btn.SetNormalTexture then
			btn:SetNormalTexture(config.textures.normal)
			hooksecurefunc(btn, "SetNormalTexture", function(self, texture)
				if texture and texture ~= config.textures.normal then
					self:SetNormalTexture(config.textures.normal)
				end
			end)
		end

		-- hightlight texture
		if btn.SetHighlightTexture then
			btn:SetHighlightTexture(config.textures.hightlight)
			hooksecurefunc(btn, "SetHighlightTexture", function(self, texture)
				if texture and texture ~= config.textures.hightlight then
					self:SetHighlightTexture(config.textures.hightlight)
				end
			end)
		end

		-- pushed texture
		if btn.SetPushedtTexture then
			btn:SetPushedtTexture(config.textures.pushed)
			hooksecurefunc(btn, "SetPushedtTexture", function(self, texture)
				if texture and texture ~= config.textures.pushed then
					self:SetPushedtTexture(config.textures.pushed)
				end
			end)
		end

		-- checked texture
		if btn.SetCheckedTexture then
			btn:SetCheckedTexture(config.textures.checked)
			hooksecurefunc(btn, "SetCheckedTexture", function(self, texture)
				if texture and texture ~= config.textures.checked then
					self:SetCheckedTexture(config.textures.checked)
				end
			end)
		end
	end

	local function Darken_BagButton(name, vertex)
		if not name or not _G[name] or _G[name].kpacked then
			return
		end
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
			btn:SetNormalTexture(config.textures.normal)
			hooksecurefunc(btn, "SetNormalTexture", function(self, texture)
				if texture and texture ~= config.textures.normal then
					self:SetNormalTexture(config.textures.normal)
				end
			end)
		end

		-- hightlight texture
		if btn.SetHighlightTexture then
			btn:SetHighlightTexture(config.textures.hightlight)
			hooksecurefunc(btn, "SetHighlightTexture", function(self, texture)
				if texture and texture ~= config.textures.hightlight then
					self:SetHighlightTexture(config.textures.hightlight)
				end
			end)
		end

		-- pushed texture
		if btn.SetPushedtTexture then
			btn:SetPushedtTexture(config.textures.pushed)
			hooksecurefunc(btn, "SetPushedtTexture", function(self, texture)
				if texture and texture ~= config.textures.pushed then
					self:SetPushedtTexture(config.textures.pushed)
				end
			end)
		end

		-- checked texture
		if btn.SetCheckedTexture then
			btn:SetCheckedTexture(config.textures.checked)
			hooksecurefunc(btn, "SetCheckedTexture", function(self, texture)
				if texture and texture ~= config.textures.checked then
					self:SetCheckedTexture(config.textures.checked)
				end
			end)
		end
	end
	local function DarkMode()
		for _, f in pairs(framesList) do
			if _G[f] then
				_G[f]:SetVertexColor(config.colors.normal.r, config.colors.normal.g, config.colors.normal.b, config.colors.normal.a or 1)
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

	local function SetupDatabase()
		if not DB then
			if type(core.db.DarkMode) ~= "table" or next(core.db.DarkMode) == nil then
				core.db.DarkMode = CopyTable(defaults)
			end

			DB = core.db.DarkMode
		end

		if core.db.DarkMode.charspecific then
			if type(core.char.DarkMode) ~= "table" or next(core.char.DarkMode) == nil then
				core.char.DarkMode = CopyTable(core.db.DarkMode)
			end
			DB = core.char.DarkMode
			DB.charspecific = nil
		elseif core.char.DarkMode then
			core.char.DarkMode = nil
		end

		if DB.classcolor and core.mycolor then
			config.colors.normal.r = core.mycolor.r
			config.colors.normal.g = core.mycolor.g
			config.colors.normal.b = core.mycolor.b
			config.colors.normal.a = 1

			-- equipped;
			if DB.equipped then
				config.colors.equipped.r = DB.equipped.r or defaults.equipped.r
				config.colors.equipped.g = DB.equipped.g or defaults.equipped.g
				config.colors.equipped.b = DB.equipped.b or defaults.equipped.b
				config.colors.equipped.a = DB.equipped.a or defaults.equipped.a
			end
		else
			for k, _ in pairs(defaults) do
				if DB[k] then
					config.colors[k].r = DB[k].r or defaults[k].r
					config.colors[k].g = DB[k].g or defaults[k].g
					config.colors[k].b = DB[k].b or defaults[k].b
					config.colors[k].a = DB[k].a or defaults[k].a
				end
			end
		end
	end

	local function SetupOptions()
		SetupDatabase()

		if not core.options.args.Options.args.DarkMode then
			core.options.args.Options.args.DarkMode = {
				type = "group",
				name = L["Dark Mode"],
				get = function(i)
					local c = config.colors[i[#i]]
					return c.r or 1, c.g or 1, c.b or 1, c.a or 1
				end,
				set = function(i, r, g, b, a)
					DB[i[#i]].r = r or 1
					DB[i[#i]].g = g or 1
					DB[i[#i]].b = b or 1
					DB[i[#i]].a = a or 1
					SetupDatabase()
					DarkMode()
				end,
				args = {
					charspecific = {
						type = "toggle",
						name = L["Character Specific"],
						desc = L["Enable this if you want settings to be stored per character rather than per account."],
						get = function()
							return core.db.DarkMode.charspecific
						end,
						set = function()
							core.db.DarkMode.charspecific = not core.db.DarkMode.charspecific
							if not core.db.DarkMode.charspecific then
								core.db.DarkMode.charspecific = nil
								core.char.DarkMode = nil
								DB = nil
							end
							SetupDatabase()
							DarkMode()
						end,
						order = 1
					},
					classcolor = {
						type = "toggle",
						name = L["Use class color"],
						get = function()
							return DB.classcolor
						end,
						set = function()
							DB.classcolor = not DB.classcolor
							SetupDatabase()
							DarkMode()
						end,
						order = 2
					},
					sep_1 = {
						type = "description",
						name = " ",
						order = 3,
						width = "full"
					},
					normal = {
						type = "color",
						name = L["Color"],
						hasAlpha = true,
						order = 4,
						disabled = function()
							return DB.classcolor
						end
					},
					equipped = {
						type = "color",
						name = CURRENTLY_EQUIPPED,
						hasAlpha = true,
						order = 5
					},
					sep_2 = {
						type = "description",
						name = " ",
						order = 6,
						width = "full"
					},
					reset = {
						type = "execute",
						name = RESET,
						order = 99,
						width = "double",
						confirm = function()
							return L:F("Are you sure you want to reset %s to default?", L["Dark Mode"])
						end,
						func = function()
							DB.classcolor = nil
							for k, v in pairs(defaults) do
								DB[k].r, DB[k].g, DB[k].b, DB[k].a = v.r, v.g, v.b, v.a
								config.colors.r, config.colors.g, config.colors.b, config.colors.a = v.r, v.g, v.b, v.a
							end

							SetupDatabase()
							DarkMode()
							collectgarbage("collect")
							core:Print(L["module's settings reset to default."], L["Dark Mode"])
						end
					}
				}
			}
		end
	end

	core:RegisterForEvent("PLAYER_LOGIN", SetupOptions)
	core:RegisterForEvent("PLAYER_ENTERING_WORLD", DarkMode)
end)