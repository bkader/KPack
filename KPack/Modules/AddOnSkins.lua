local core = KPack
if not core then return end
core:AddModule("AddOnSkins", function(L)
	if core:IsDisabled("AddOnSkins") or not core.ElvUI then return end

	local _G = _G
	local E = core.ElvUI
	local S = E:GetModule("Skins", true)
	local AS = E:GetModule("Skins", true)

	-- AllStats
	local function AddOnSkins_AllStats()
		if core:IsDisabled("AllStats") then return end
		if KPackAllStats and not KPackAllStats.isSkinned then
			KPackAllStats:StripTextures()
			KPackAllStats:SetTemplate("Transparent")
			KPackAllStats:Height(424)
			KPackAllStats:Point("TOPLEFT", PaperDollFrame, "TOPLEFT", 351, -12)
			KPackAllStats.button:Height(21)
			KPackAllStats.button:Point("BOTTOMRIGHT", -40, 84)
			S:HandleButton(KPackAllStats.button)
			KPackAllStats.isSkinned = true
		end
	end

	-- Automate
	local function AddOnSkins_Automate()
		if core:IsDisabled("Automate") or not core.Automate then return end
		if not core.Automate.isSkinned then
			hooksecurefunc(core.Automate, "TrainButtonCreate", function()
				S:HandleButton(KPackTrainAllButton)
			end)
			core.Automate.isSkinned = true
		end
	end

	-- combat time
	local function AddOnSkins_CombatTime()
		if core.CombatTime and KPackCombatTime and not KPackCombatTime.isSkinned then
			KPackCombatTime:SetTemplate("Transparent")
			KPackCombatTime:SetSize(100, 40)
			KPackCombatTime.isSkinned = true
		end
	end

	-- Death Recap
	local function AddOnSkins_DeathRecap()
		if core:IsDisabled("Death Recap") then return end
		KPackDeathRecapFrame:SetTemplate("Transparent")
		S:HandleButton(KPackDeathRecapFrameCloseButton)
	end

	-- EnhancedStackSpit
	local function AddOnSkins_EnhancedStackSplit()
		if core:IsDisabled("EnhancedStackSplit") then return end
		if core.EnhStackSplit and not core.EnhStackSplit.isSkinned then
			_G["EnhancedStackSplitTopTextureFrame"]:StripTextures()
			_G["EnhancedStackSplitTopTextureFrame"]:SetTemplate("Transparent")

			_G["EnhancedStackSplitBottomTextureFrame"]:StripTextures()
			_G["EnhancedStackSplitBottomTextureFrame"]:SetTemplate("Transparent")

			_G["EnhancedStackSplitBottom2TextureFrame"]:StripTextures()
			_G["EnhancedStackSplitBottom2TextureFrame"]:SetTemplate("Transparent")

			_G["EnhancedStackSplitAutoTextureFrame"]:StripTextures()
			_G["EnhancedStackSplitAutoTextureFrame"]:SetTemplate("Transparent")

			S:HandleButton(_G["EnhancedStackSplitAuto1Button"])
			for i = 1, 16 do
				local btn = _G["EnhancedStackSplitButton" .. i]
				S:HandleButton(btn)
				if i == 1 then
					btn:ClearAllPoints()
					btn:SetPoint("TOPLEFT", _G["EnhancedStackSplitBottomTextureFrame"], "TOPLEFT", 3, 3)
					btn.ClearAllPoints = core.Noop
					btn.SetPoint = core.Noop
				end
			end
			S:HandleButton(_G["EnhancedStackSplitAutoSplitButton"])
			S:HandleButton(_G["EnhancedStackSplitModeTXTButton"])

			core.EnhStackSplit.isSkinned = true
		end
	end

	local function AddOnSkins_MoveAnything()
		if core:IsDisabled("MoveAnything") or not core.MA then
			return
		end
		if not core.MA.isSkinned then
			local SPACING = 1 + (E.Spacing * 2)
			for i = 1, 20 do
				_G["MAMover" .. i .. "Backdrop"]:SetTemplate("Transparent")
				_G["MAMover" .. i]:HookScript("OnShow", function(self)
					_G[self:GetName() .. "Backdrop"]:SetBackdropBorderColor(unpack(E["media"].rgbvaluecolor))
				end)
				_G["MAMover" .. i]:SetScript("OnEnter", function(self)
					_G[self:GetName() .. "BackdropMovingFrameName"]:SetTextColor(1, 1, 1)
				end)
				_G["MAMover" .. i]:SetScript("OnLeave", function(self)
					_G[self:GetName() .. "BackdropMovingFrameName"]:SetTextColor(unpack(E["media"].rgbvaluecolor))
				end)
			end

			MAOptions:StripTextures()
			MAOptions:SetTemplate("Transparent")
			MAOptions:Size(420, 500 + (16 * SPACING))

			S:HandleCheckBox(MAOptionsCharacterSpecific)
			S:HandleCheckBox(MAOptionsToggleTooltips)
			S:HandleCheckBox(MAOptionsToggleModifiedFramesOnly)
			S:HandleCheckBox(MAOptionsToggleCategories)

			S:HandleButton(MAOptionsResetAll)
			S:HandleButton(MAOptionsClose)
			S:HandleButton(MAOptionsSync)

			for i = 1, 17 do
				_G["MAMove" .. i .. "Backdrop"]:SetTemplate("Default")
				S:HandleCheckBox(_G["MAMove" .. i .. "Move"])
				S:HandleCheckBox(_G["MAMove" .. i .. "Hide"])
				S:HandleButton(_G["MAMove" .. i .. "Reset"])

				if i ~= 1 then
					_G["MAMove" .. i]:SetPoint("TOPLEFT", "MAMove" .. (i - 1), "BOTTOMLEFT", 0, -SPACING)
				end
			end

			MAScrollFrame:Size(380, 442 + (16 * SPACING))
			S:HandleScrollBar(_G["MAScrollFrameScrollBar"])
			MAScrollBorder:StripTextures()

			MANudger:SetTemplate("Transparent")
			S:HandleButton(MANudger_NudgeUp)
			MANudger_NudgeUp:Point("CENTER", 0, 24 + SPACING)
			S:HandleButton(MANudger_CenterMe)
			MANudger_CenterMe:Point("TOP", MANudger_NudgeUp, "BOTTOM", 0, -SPACING)
			S:HandleButton(MANudger_NudgeDown)
			MANudger_NudgeDown:Point("TOP", MANudger_CenterMe, "BOTTOM", 0, -SPACING)
			S:HandleButton(MANudger_NudgeLeft)
			MANudger_NudgeLeft:Point("RIGHT", MANudger_CenterMe, "LEFT", -SPACING, 0)
			S:HandleButton(MANudger_NudgeRight)
			MANudger_NudgeRight:Point("LEFT", MANudger_CenterMe, "RIGHT", SPACING, 0)
			S:HandleButton(MANudger_CenterH)
			S:HandleButton(MANudger_CenterV)
			S:HandleButton(MANudger_Detach)
			S:HandleButton(MANudger_Hide)
			S:HandleButton(MANudger_MoverPlus)
			S:HandleButton(MANudger_MoverMinus)

			S:HandleButton(_G["GameMenuButtonMoveAnything"])

			core.MA.isSkinned = true
		end
	end

	local function AddOnSkins_RaidBrowser()
		if core:IsDisabled("RaidBrowser") or not core.RaidBrowser then
			return
		end
		if core.RaidBrowser and not core.RaidBrowser.isSkinned then
			S:HandleButton(_G["RaidBrowserRaidSetSaveButton"])
			_G["RaidBrowserRaidSetSaveButton"]:ClearAllPoints()
			_G["RaidBrowserRaidSetSaveButton"]:SetPoint("BOTTOMLEFT", _G["LFRBrowseFrameColumnHeader1"], "TOPLEFT", 0, 5)

			S:HandleDropDownBox(_G["RaidBrowserRaidSetMenu"])
			_G["RaidBrowserRaidSetMenu"]:ClearAllPoints()
			_G["RaidBrowserRaidSetMenu"]:SetPoint("BOTTOMRIGHT", _G["LFRBrowseFrameColumnHeader7"], "TOPRIGHT", 0, -5)

			core.RaidBrowser.isSkinned = true
		end
	end

	local function AddOnSkins_RaidTabs()
		if core:IsDisabled("RaidTabs") then
			return
		end
		for i = 1, 3 do
			local tab = _G["libTabKPackRaidTabs" .. i]
			if tab and not tab.isSkinned then
				tab:SetTemplate("Default")
				tab:StyleButton()
				tab:DisableDrawLayer("BACKGROUND")
				tab:GetNormalTexture():SetInside(tab.backdrop)
				tab:GetNormalTexture():SetTexCoord(unpack(E.TexCoords))
				tab.isSkinned = true
			end
		end
	end

	local function AddOnSkins_TellMeWhen()
		if core:IsDisabled("TellMeWhen") then
			return
		end
		if core.TellMeWhen and not core.TellMeWhen.isSkinned then
			local DB = core.char.TMW

			for i = 1, core.TellMeWhen.maxGroups do
				core.options.args.TellMeWhen.args["group" .. i].args.Width = nil
				core.options.args.TellMeWhen.args["group" .. i].args.Height = nil
				core.options.args.TellMeWhen.args["group" .. i].args.Spacing = nil
				if DB.Groups[i].Width ~= 30 then
					DB.Groups[i].Width = 30
				end
				if DB.Groups[i].Height ~= 30 then
					DB.Groups[i].Height = 30
				end
			end

			core.TellMeWhen.iconSpacing = E.Border

			hooksecurefunc(core.TellMeWhen, "Group_Update", function(self, groupID)
				local currentSpec = self:GetActiveTalentGroup()
				local groupName = "KTellMeWhen_Group" .. groupID
				local genabled = DB.Groups[groupID].Enabled
				local rows = DB.Groups[groupID].Rows
				local columns = DB.Groups[groupID].Columns
				local activePriSpec = DB.Groups[groupID].PrimarySpec
				local activeSecSpec = DB.Groups[groupID].SecondarySpec
				local iconSpacing = E.Border

				if (currentSpec == 1 and not activePriSpec) or (currentSpec == 2 and not activeSecSpec) then
					genabled = false
				end

				if genabled then
					for row = 1, rows do
						for column = 1, columns do
							local iconID = (row - 1) * columns + column
							local iconName = groupName .. "_Icon" .. iconID
							local icon = _G[iconName]
							if icon then
								if not icon.isSkinned then
									icon:SetTemplate("NoBackdrop")
									icon:GetRegions():SetTexture(nil)
									icon.texture:SetTexCoord(unpack(E.TexCoords))
									icon.texture:SetInside()
									icon.countText:FontTemplate()
									icon.highlight:SetTexture(1, 1, 1, .3)
									icon.highlight:SetInside()
									E:RegisterCooldown(icon.Cooldown)
									icon.isSkinned = true
								end
								icon:ClearAllPoints()
								if column > 1 then
									icon:SetPoint("TOPLEFT", _G[groupName .. "_Icon" .. (iconID - 1)], "TOPRIGHT", iconSpacing, 0)
								elseif row > 1 and column == 1 then
									icon:SetPoint("TOPLEFT", _G[groupName .. "_Icon" .. (iconID - columns)], "BOTTOMLEFT", 0, -iconSpacing)
								elseif iconID == 1 then
									icon:SetPoint("TOPLEFT", _G[groupName], "TOPLEFT")
								end
							end
						end
					end
				end
			end)
			core.TellMeWhen.isSkinned = true
		end
	end

	core:RegisterForEvent("PLAYER_ENTERING_WORLD", function()
		AddOnSkins_AllStats()
		AddOnSkins_Automate()
		AddOnSkins_CombatTime()
		AddOnSkins_DeathRecap()
		AddOnSkins_EnhancedStackSplit()
		AddOnSkins_MoveAnything()
		AddOnSkins_RaidBrowser()
		AddOnSkins_RaidTabs()
		AddOnSkins_TellMeWhen()
	end)
end)