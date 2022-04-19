local core = KPack
if not core then return end
core:AddModule("AddOns", function(L, addonName)
	if core:IsDisabled(L["AddOns"]) or _G.KkthnxUI then return end
	if core.ElvUI and core.ElvUI:GetModule("ElvUI_Enhanced", true) then return end

	local _G = _G
	local unpack = unpack
	local select = select
	local sort = table.sort
	local GetAddOnInfo = GetAddOnInfo
	local CreateFrame = CreateFrame
	local UIParent = UIParent
	local GetNumAddOns = GetNumAddOns
	local GetAddOnDependencies = GetAddOnDependencies

	local AddonList
	local menuWasShown

	-- buttons & frames
	local CloseButton
	local EnableAllButton
	local ReloadButton
	local DisableAllButton
	local ScrollFrame, ScrollBar

	local function CreateAddonsList()
		if AddonList then return end
		AddonList = CreateFrame("Frame", "AddonList", UIParent)
		tinsert(UISpecialFrames, "AddonList")
		AddonList:SetSize(385, 512)
		AddonList:SetPoint("CENTER", UIParent, 0, 24)
		AddonList:EnableMouse(true)
		AddonList:SetMovable(true)
		AddonList:SetUserPlaced(false)
		AddonList:SetClampedToScreen(true)
		AddonList:SetScript("OnMouseDown", function(self) self:StartMoving() end)
		AddonList:SetScript("OnMouseUp", function(self) self:StopMovingOrSizing() end)
		AddonList:SetFrameStrata("DIALOG")
		tinsert(UISpecialFrames, "Addons")

		CloseButton = CloseButton or CreateFrame("Button", "AddonListCloseButton", AddonList, "UIPanelCloseButton")
		CloseButton:SetSize(30, 30)
		CloseButton:SetPoint("TOPRIGHT", AddonList, "TOPRIGHT", 5, -4)
		CloseButton:SetScript("OnClick", function() AddonList:Hide() end)

		-- add some cool textures
		local t = AddonList:CreateTexture(nil, "BACKGROUND")
		t:SetTexture([[Interface\HelpFrame\HelpFrame-TopLeft]])
		t:SetSize(128, 256)
		t:SetPoint("TOPLEFT")

		t = AddonList:CreateTexture(nil, "BACKGROUND")
		t:SetTexture([[Interface\HelpFrame\HelpFrame-Top]])
		t:SetSize(177, 256)
		t:SetPoint("TOPLEFT", 128, 0)

		t = AddonList:CreateTexture(nil, "BACKGROUND")
		t:SetTexture([[Interface\HelpFrame\HelpFrame-TopRight]])
		t:SetSize(128, 256)
		t:SetPoint("TOPRIGHT", 48, 0)
		t:SetPoint("TOPRIGHT", 48, 0)

		t = AddonList:CreateTexture(nil, "BACKGROUND")
		t:SetTexture([[Interface\HelpFrame\HelpFrame-Bottom]])
		t:SetSize(177, 256)
		t:SetPoint("BOTTOMLEFT", 128, 0)

		t = AddonList:CreateTexture(nil, "BACKGROUND")
		t:SetTexture([[Interface\HelpFrame\HelpFrame-BotLeft]])
		t:SetSize(128, 256)
		t:SetPoint("BOTTOMLEFT")

		t = AddonList:CreateTexture(nil, "BACKGROUND")
		t:SetTexture([[Interface\HelpFrame\HelpFrame-BotRight]])
		t:SetSize(128, 256)
		t:SetPoint("BOTTOMRIGHT", 48, 0)

		t = AddonList:CreateTexture(nil, "ARTWORK")
		t:SetTexture([[Interface\DialogFrame\UI-DialogBox-Header]])
		t:SetSize(328, 64)
		t:SetPoint("TOP", 0, 12)

		local title = AddonList:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		title:SetPoint("TOP", t, 0, -14)
		title:SetText(L["AddOns"])

		local info = AddonList:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		info:SetPoint("TOPLEFT", 26, -30)
		info:SetPoint("RIGHT", -22, -30)

		ScrollFrame = ScrollFrame or CreateFrame("ScrollFrame", "AddonListScrollFrame", AddonList, "UIPanelScrollFrameTemplate")
		ScrollBar = _G["AddonListScrollFrameScrollBar"]
		local MainAddonFrame = CreateFrame("Frame", "AddonListFrame", ScrollFrame)

		ScrollFrame:SetPoint("TOPLEFT", AddonList, "TOPLEFT", 5, -58)
		ScrollFrame:SetPoint("BOTTOMRIGHT", AddonList, "BOTTOMRIGHT", -32, 52)
		ScrollFrame:SetScrollChild(MainAddonFrame)

		local UpdateAddonList = function()
			local self = MainAddonFrame
			self:SetPoint("TOPLEFT")
			self:SetWidth(ScrollFrame:GetWidth())
			self:SetHeight(ScrollFrame:GetHeight())
			self.addons = self.addons or {}
			for i = 1, GetNumAddOns() do
				self.addons[i] = select(1, GetAddOnInfo(i))
			end
			sort(self.addons)

			local oldb
			local countAll, countOn, countOff = 0, 0, 0

			for i, v in pairs(self.addons) do
				local name, title, notes, enabled, loadable, reason = GetAddOnInfo(v)

				if name then
					local CheckButtonName = "AddonListEntry" .. i
					local CheckButton = _G[CheckButtonName]
					if not CheckButton then
						CheckButton = CreateFrame("CheckButton", CheckButtonName, self, "OptionsCheckButtonTemplate")
					end
					CheckButton:SetChecked(enabled)

					if name == addonName then
						CheckButton:EnableMouse(false)
						CheckButton:Disable()
					else
						CheckButton:EnableMouse(true)
						CheckButton:Enable()
					end
					CheckButton.title = title .. "|n"
					if notes then
						CheckButton.tooltip = (CheckButton.tooltip or "") .. "|cffffffff" .. notes .. "|r|n"
					end
					if (GetAddOnDependencies(v)) then
						CheckButton.tooltip = (CheckButton.tooltip or "") .. "|n|cffff4400Dependencies: |r"
						for j = 1, select("#", GetAddOnDependencies(v)) do
							CheckButton.tooltip = CheckButton.tooltip .. select(j, GetAddOnDependencies(v))
							if (j > 1) then
								CheckButton.tooltip = CheckButton.tooltip .. ", "
							end
						end
						CheckButton.tooltip = CheckButton.tooltip .. "|r"
					end

					if i == 1 then
						CheckButton:SetPoint("TOPLEFT", self, "TOPLEFT", 10, -10)
					else
						CheckButton:SetPoint("TOP", oldb, "BOTTOM", 0, 6)
					end

					CheckButton:SetScript("OnEnter", function(self)
						GameTooltip:ClearLines()
						GameTooltip:SetOwner(self, ANCHOR_TOPRIGHT)
						GameTooltip:AddLine(self.title, nil, nil, nil, true)
						if self.tooltip then
							GameTooltip:AddLine(self.tooltip, nil, nil, nil, true)
						end
						GameTooltip:Show()
					end)
					CheckButton:SetScript("OnLeave", function(self) GameTooltip:Hide() end)

					CheckButton:SetScript("OnClick", function()
						local _, _, _, enabled = GetAddOnInfo(name)
						if enabled then
							DisableAddOn(name)
						else
							EnableAddOn(name)
						end
					end)

					if loadable and (enabled and (reason == "DEP_DEMAND_LOADED" or reason == "DEMAND_LOADED")) then
						_G[CheckButtonName .. "Text"]:SetTextColor(1.0, 0.78, 0.0)
						countOff = countOff + 1
					elseif enabled and reason == "DEP_DISABLED" then
						_G[CheckButtonName .. "Text"]:SetTextColor(1.0, 0.1, 0.1)
						countOff = countOff + 1
					elseif enabled then
						countOn = countOn + 1
					else
						countOff = countOff + 1
						_G[CheckButtonName .. "Text"]:SetTextColor(0.5, 0.5, 0.5)
					end

					countAll = countAll + 1
					_G[CheckButtonName .. "Text"]:SetText(title)
					oldb = CheckButton
				end
			end

			info:SetText(L:F("|cffffffff%d|r AddOns: |cffffffff%d|r |cff00ff00Enabled|r, |cffffffff%d|r |cffff0000Disabled|r", countAll, countOn, countOff))
		end

		AddonList:SetScript("OnShow", function(self)
			PlaySound("igMainMenuOption")
			UpdateAddonList()
		end)
		AddonList:SetScript("OnHide", function(self)
			PlaySound("igMainMenuOptionCheckBoxOn")
			self:ClearAllPoints()
			self:SetPoint("CENTER", UIParent, 0, 24)
			if menuWasShown then
				ShowUIPanel(GameMenuFrame)
				menuWasShown = nil
			end
		end)
		AddonList:Hide()

		ReloadButton = ReloadButton or CreateFrame("Button", "AddonListReloadButton", AddonList, "KPackButtonTemplate")
		ReloadButton:SetSize(105, 21)
		ReloadButton:SetPoint("BOTTOM", AddonList, "BOTTOM", 0, 21)
		ReloadButton:SetText(L["Reload UI"])
		ReloadButton:SetScript("OnClick", function() ReloadUI() end)

		EnableAllButton = EnableAllButton or CreateFrame("Button", "AddonListEnableAllButton", AddonList, "KPackButtonTemplate")
		EnableAllButton:SetSize(105, 21)
		EnableAllButton:SetPoint("BOTTOMLEFT", AddonList, "BOTTOMLEFT", 7, 21)
		EnableAllButton:SetText(L["Enable All"])
		EnableAllButton:SetScript("OnClick", function()
			EnableAllAddOns()
			UpdateAddonList()
		end)

		DisableAllButton = DisableAllButton or CreateFrame("Button", "AddonListDisableAllButton", AddonList, "KPackButtonTemplate")
		DisableAllButton:SetSize(105, 21)
		DisableAllButton:SetPoint("BOTTOMRIGHT", AddonList, "BOTTOMRIGHT", -6, 21)
		DisableAllButton:SetText(L["Disable All"])
		DisableAllButton:SetScript("OnClick", function()
			for k, v in pairs(MainAddonFrame.addons) do
				local name, title, notes, enabled, loadable, reason = GetAddOnInfo(v)
				if name and name ~= addonName then
					DisableAddOn(name)
				end
			end
			UpdateAddonList()
		end)
	end

	-- Slash command
	SLASH_KPACKADDONLIST1 = "/addons"
	SLASH_KPACKADDONLIST2 = "/acp"
	local function OpenAddonList()
		if InCombatLockdown() then
			core:Print("|cffffe02e" .. ERR_NOT_IN_COMBAT .. "|r")
			return
		end
		CreateAddonsList()
		PlaySound("igMainMenuOption")
		if GameMenuFrame:IsShown() then
			menuWasShown = true
			HideUIPanel(GameMenuFrame)
		end
		AddonList:Show()
	end
	SlashCmdList.KPACKADDONLIST = function(msg)
		OpenAddonList()
	end

	local AddonListButton = CreateFrame("Button", "GameMenuButtonAddOns", GameMenuFrame, "GameMenuButtonTemplate")
	AddonListButton:SetText(L["AddOns"])
	AddonListButton:SetPoint("TOP", GameMenuButtonMacros, "BOTTOM", 0, -1)
	AddonListButton:SetScript("OnClick", OpenAddonList)

	core:RegisterForEvent("PLAYER_LOGIN", function()
		local offset = 26
		if _G.GameMenuButtonMoveAnything then
			offset = offset + 26
			_G.GameMenuButtonMoveAnything:ClearAllPoints()
			_G.GameMenuButtonMoveAnything:SetPoint("TOP", AddonListButton, "BOTTOM", 0, -1)
			GameMenuButtonLogout:SetPoint("TOP", _G.GameMenuButtonMoveAnything, "BOTTOM", 0, -16)
		else
			GameMenuButtonLogout:SetPoint("TOP", AddonListButton, "BOTTOM", 0, -16)
		end
		GameMenuFrame:SetHeight(GameMenuFrame:GetHeight() + offset)

		if core.ElvUI then
			local S = core.ElvUI:GetModule("Skins", true)
			if not S then
				return
			end
			if not AddonListButton.isSkinned then
				S:HandleButton(AddonListButton)
				AddonListButton.isSkinned = true
			end

			local old_OnClick = AddonListButton:GetScript("OnClick")
			AddonListButton:SetScript("OnClick", function(self, button)
				old_OnClick(self, button)
				if not AddonList.isSkinned then
					AddonList:SetParent(UIParent)
					AddonList:SetFrameStrata("HIGH")
					AddonList:SetHitRectInsets(0, 0, 0, 0)
					AddonList:StripTextures()
					AddonList:SetTemplate("Transparent")

					S:HandleCloseButton(CloseButton, AddonList)
					S:HandleButton(EnableAllButton)
					S:HandleButton(ReloadButton)
					S:HandleButton(DisableAllButton)

					ScrollFrame:StripTextures()
					ScrollFrame:SetTemplate("Transparent")

					S:HandleScrollBar(ScrollBar)
					ScrollBar:Point("TOPLEFT", ScrollFrame, "TOPRIGHT", 3, -19)
					ScrollBar:Point("BOTTOMLEFT", ScrollFrame, "BOTTOMRIGHT", 3, 19)

					AddonList.isSkinned = true
				end
			end)
		end
	end)
end)