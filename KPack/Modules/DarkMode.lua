assert(KPack, "KPack not found!")
KPack:AddModule("Dark Mode", function(_, core)
	if core:IsDisabled("Dark Mode") then return end

	local config = {
		textures = {
			normal = [[Interface\Addons\KPack\Media\Textures\AB_Normal]],
			flash = [[Interface\Addons\KPack\Media\Textures\AB_Flash]],
			hightlight = [[Interface\Addons\KPack\Media\Textures\AB_Hightlight]],
			pushed = [[Interface\Addons\KPack\Media\Textures\AB_Pushed]],
			checked = [[Interface\Addons\KPack\Media\Textures\AB_Checked]],
			equipped = [[Interface\Addons\KPack\Media\Textures\AB_Equipped]],
		},
		colors = {
			normal = {r = 0.37, g = 0.37, b = 0.37},
			equipped = {r = 0.1, g = 0.5, b = 0.1}
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
		"CompactRaidFrameContainerBorderFrameBorderRight"
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
				t:SetVertexColor(0, 1, 0, 0.65)
				t:Show()
			elseif btn.action then
				t:Hide()
			end
			local _SetVertexColor = t.SetVertexColor
			t.SetVertexColor = function(self, r, g, b, a)
				if btn.action and IsEquippedAction(btn.action) then
					_SetVertexColor(self, 0, 1, 0, 0.65)
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
				t:SetVertexColor(config.colors.equipped.r, config.colors.equipped.g, config.colors.equipped.b, 1)
			else
				t:SetVertexColor(config.colors.normal.r, config.colors.normal.g, config.colors.normal.b, 1)
			end
			t:SetAllPoints(btn)
			hooksecurefunc(t, "SetVertexColor", function(self, r, g, b, a)
					local bn = self:GetParent()
					if r == 1 and g == 1 and b == 1 and bn.action and (IsEquippedAction(btn.action)) then
					if
						config.colors.equipped.r == 1 and config.colors.equipped.g == 1 and
							config.colors.equipped.b == 1
					 then
						self:SetVertexColor(0.99, 0.99, 0.99, 1)
					else
						self:SetVertexColor(config.colors.equipped.r, config.colors.equipped.g, config.colors.equipped.b, 1)
					end
				elseif r == 0.5 and g == 0.5 and b == 1 then
					if
						config.colors.normal.r == 0.5 and
						config.colors.normal.g == 0.5 and
						config.colors.normal.b == 1
					then
						self:SetVertexColor(0.49, 0.49, 0.99, 1)
					else
						self:SetVertexColor(config.colors.normal.r, config.colors.normal.g, config.colors.normal.b, 1)
					end
				elseif r == 1 and g == 1 and b == 1 then
					if
						config.colors.normal.r == 1 and
						config.colors.normal.g == 1 and
						config.colors.normal.b == 1
					then
						self:SetVertexColor(0.99, 0.99, 0.99, 1)
					else
						self:SetVertexColor(config.colors.normal.r, config.colors.normal.g, config.colors.normal.b, 1)
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
				_G[f]:SetVertexColor(config.colors.normal.r, config.colors.normal.g, config.colors.normal.b, 1)
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

	core:RegisterForEvent("PLAYER_ENTERING_WORLD", DarkMode)
end)