local core = KPack
if not core then return end
core:AddModule("BlizzBugsSuck", "Fixes some Blizzard bugs, adds a timer bar for RDF or BGs popup.", function()
	if core:IsDisabled("BlizzBugsSuck") then return end

	-- Fixes are:
	--
	-- Fix_UIDropDownMenu:
	-- UIDropDownMenu FrameLevels do not properly follow their parent
	-- and need to be fixed to prevent the button being under the background.
	--
	-- Fix_GermanLocale
	-- Fix incorrect translations in the German Locale.  For whatever reason
	-- Blizzard changed the oneletter time abbreviations to be 3 letter in
	-- the German Locale.
	--
	-- Fix_MinimapPing
	-- Fix for minimap ping points not updating as your character moves.
	-- Original code taken from AntiRadarJam by Lombra with permission.
	--
	-- Fix_InterfaceOptionsCategory
	-- fixes the issue with InterfaceOptionsFrame_OpenToCategory not actually
	-- opening the Category (and not even scrolling to it)
	--

	local Fix_UIDropDownMenu
	local Fix_GermanLocale
	local Fix_MinimapPing
	local Fix_InterfaceOptionsCategory

	-- ///////////////////////////////////////////////////////

	do
		local function CreateFrames_Hook()
			for l = 1, UIDROPDOWNMENU_MAXLEVELS do
				for b = 1, UIDROPDOWNMENU_MAXBUTTONS do
					local button = _G["DropDownList" .. l .. "Button" .. b]
					if button then
						local button_parent = button:GetParent()
						if button_parent then
							local button_level = button:GetFrameLevel()
							local parent_level = button_parent:GetFrameLevel()
							if button_level <= parent_level then
								button:SetFrameLevel(parent_level + 2)
							end
						end
					end
				end
			end
		end

		function Fix_UIDropDownMenu()
			hooksecurefunc("UIDropDownMenu_CreateFrames", CreateFrames_Hook)
		end
	end

	-- ///////////////////////////////////////////////////////

	do
		local GetLocale = GetLocale
		function Fix_GermanLocale()
			if GetLocale() == "deDE" then
				_G.MINUTE_ONELETTER_ABBR = "%d m"
				_G.DAY_ONELETTER_ABBR = "%d d"
			end
		end
	end

	-- ///////////////////////////////////////////////////////

	do
		function Fix_MinimapPing()
			MinimapPing:HookScript("OnUpdate", function(self, elapsed)
				if self.fadeOut or (self.timer or 0) > MINIMAPPING_FADE_TIMER then
					Minimap_SetPing(Minimap:GetPingPosition())
				end
			end)
		end
	end

	-- ///////////////////////////////////////////////////////

	do
		local doNotRun = false

		local function GetPanelName(panel)
			local cat = INTERFACEOPTIONS_ADDONCATEGORIES
			if type(panel) == "string" then
				for i, p in pairs(cat) do
					if p.name == panel then
						return p.parent and GetPanelName(p.parent) or panel
					end
				end
			elseif (type(panel) == "table") then
				for i, p in pairs(cat) do
					if p == panel then
						if p.parent then
							return p.parent and GetPanelName(p.parent) or panel.name
						end
					end
				end
			end
		end

		local function OpenToCategory_Hook(pan)
			if InCombatLockdown() then return end

			if doNotRun then
				doNotRun = false
				return
			end

			local panelName = GetPanelName(pan)
			-- if its not part of our list return early
			if not panelName then return end

			local noncollapsedHeaders = {}
			local shownpanels, t, mypanel = 0, {}

			for i, panel in ipairs(INTERFACEOPTIONS_ADDONCATEGORIES) do
				if not panel.parent or noncollapsedHeaders[panel.parent] then
					if panel.name == panelName then
						panel.collapsed = true
						t.element = panel
						InterfaceOptionsListButton_ToggleSubCategories(t)
						noncollapsedHeaders[panel.name] = true
						mypanel = shownpanels + 1
					end
					if not panel.collapsed then
						noncollapsedHeaders[panel.name] = true
					end
					shownpanels = shownpanels + 1
				end
			end

			local Smin, Smax = InterfaceOptionsFrameAddOnsListScrollBar:GetMinMaxValues()
			InterfaceOptionsFrameAddOnsListScrollBar:SetValue((Smax / (shownpanels - 15)) * (mypanel - 2))
			doNotRun = true
			InterfaceOptionsFrame_OpenToCategory(pan)
		end

		function Fix_InterfaceOptionsCategory()
			hooksecurefunc("InterfaceOptionsFrame_OpenToCategory", OpenToCategory_Hook)
		end
	end

	-- ///////////////////////////////////////////////////////

	-- fixe "You are not in party" error.
	do
		local _SendAddonMessage = SendAddonMessage
		local _GetRealNumRaidMembers = GetRealNumRaidMembers
		local _GetRealNumPartyMembers = GetRealNumPartyMembers
		local _IsInGuild = IsInGuild
		local function Fix_SendAddonMessage(prefix, msg, channel, ...)
			local chann = strlower(channel)
			if
				(chann == "raid" and _GetRealNumRaidMembers() == 0) or
					(chann == "party" and _GetRealNumPartyMembers() == 0) or
					(chann == "guild" and not _IsInGuild())
			 then
				return
			end
			_SendAddonMessage(prefix, msg, channel, ...)
		end
		SendAddonMessage = Fix_SendAddonMessage
	end

	-- ///////////////////////////////////////////////////////

	-- -- Reposition achievement ui
	-- do
	--     local AchievementAnchor = CreateFrame("Frame", "AchievementAnchor", UIParent)
	--     AchievementAnchor:SetSize(
	--         DungeonCompletionAlertFrame1:GetWidth() - 36,
	--         DungeonCompletionAlertFrame1:GetHeight() - 4
	--     )
	--     AchievementAnchor:SetPoint("TOP", UIParent, "TOP", 0, -42)

	--     local function KPack_AlertFrame_FixAnchors()
	--         local one, two, lfg = AchievementAlertFrame1, AchievementAlertFrame2, DungeonCompletionAlertFrame1
	--         if one then
	--             one:ClearAllPoints()
	--             one:SetPoint("TOP", AchievementAnchor, "TOP", 0, -20)
	--         end

	--         if two then
	--             two:ClearAllPoints()
	--             two:SetPoint("TOP", one, "BOTTOM", 0, -10)
	--         end

	--         if lfg:IsShown() then
	--             lfg:ClearAllPoints()
	--             if one then
	--                 if two then
	--                     lfg:SetPoint("TOP", two, "BOTTOM", 0, -10)
	--                 else
	--                     lfg:SetPoint("TOP", one, "BOTTOM", 0, -10)
	--                 end
	--             else
	--                 lfg:SetPoint("TOP", UIParent, "TOP", 0, -20)
	--             end
	--         end
	--     end

	--     core:RegisterForEvent("VARIABLES_LOADED", function()
	--         AlertFrame_FixAnchors = KPack_AlertFrame_FixAnchors
	--     end)
	-- end

	-- ///////////////////////////////////////////////////////

	do
		_G.INTERFACE_ACTION_BLOCKED = ""

		-- Fix RemoveTalent() taint
		local TaintFix = CreateFrame("Frame")
		TaintFix:SetScript("OnUpdate", function(self, elapsed)
			if LFRBrowseFrame.timeToClear then
				LFRBrowseFrame.timeToClear = nil
			end
		end)

		LFRBrowseFrameListScrollFrame:ClearAllPoints()
		LFRBrowseFrameListScrollFrame:SetPoint("TOPLEFT", LFRBrowseFrameListButton1, "TOPLEFT", 0, 0)
		LFRBrowseFrameListScrollFrame:SetPoint("BOTTOMRIGHT", LFRBrowseFrameListButton19, "BOTTOMRIGHT", 5, -2)
		LFRQueueFrameSpecificListScrollFrame:ClearAllPoints()
		LFRQueueFrameSpecificListScrollFrame:SetPoint("TOPLEFT", LFRQueueFrameSpecificListButton1, "TOPLEFT", 0, 0)
		LFRQueueFrameSpecificListScrollFrame:SetPoint("BOTTOMRIGHT", LFRQueueFrameSpecificListButton14, "BOTTOMRIGHT", 0, -2)

		-- Misclicks for some popups
		StaticPopupDialogs.RESURRECT.hideOnEscape = nil
		StaticPopupDialogs.AREA_SPIRIT_HEAL.hideOnEscape = nil
		StaticPopupDialogs.PARTY_INVITE.hideOnEscape = nil
		StaticPopupDialogs.CONFIRM_SUMMON.hideOnEscape = nil
		-- StaticPopupDialogs.ADDON_ACTION_FORBIDDEN.button1 = nil
		-- StaticPopupDialogs.TOO_MANY_LUA_ERRORS.button1 = nil
		-- StaticPopupDialogs.CONFIRM_BATTLEFIELD_ENTRY.button2 = nil
	end

	-- ///////////////////////////////////////////////////////

	_G.GetTexCoordsForRole = function(role)
		local textureHeight, textureWidth = 256, 256
		local roleHeight, roleWidth = 67, 67

		if role == "GUIDE" then
			return GetTexCoordsByGrid(1, 1, textureWidth, textureHeight, roleWidth, roleHeight)
		elseif role == "TANK" then
			return GetTexCoordsByGrid(1, 2, textureWidth, textureHeight, roleWidth, roleHeight)
		elseif role == "HEALER" then
			return GetTexCoordsByGrid(2, 1, textureWidth, textureHeight, roleWidth, roleHeight)
		elseif role == "DAMAGER" then
			return GetTexCoordsByGrid(2, 2, textureWidth, textureHeight, roleWidth, roleHeight)
		else
			return GetTexCoordsByGrid(2, 2, textureWidth, textureHeight, roleWidth, roleHeight)
		end
	end

	_G.GetBackgroundTexCoordsForRole = function(role)
		local textureHeight, textureWidth = 128, 256
		local roleHeight, roleWidth = 75, 75

		if role == "TANK" then
			return GetTexCoordsByGrid(2, 1, textureWidth, textureHeight, roleWidth, roleHeight)
		elseif role == "HEALER" then
			return GetTexCoordsByGrid(1, 1, textureWidth, textureHeight, roleWidth, roleHeight)
		elseif role == "DAMAGER" then
			return GetTexCoordsByGrid(3, 1, textureWidth, textureHeight, roleWidth, roleHeight)
		else
			return GetTexCoordsByGrid(3, 1, textureWidth, textureHeight, roleWidth, roleHeight)
		end
	end

	-- ///////////////////////////////////////////////////////

	-- LFG bar
	do
		local frame

		local function LFGBar_Create()
			if not frame then
				frame = CreateFrame("Frame", nil, LFDDungeonReadyDialog)
				frame:SetPoint("TOP", LFDDungeonReadyDialog, "BOTTOM", 0, -5)
				frame:SetSize(280, 10)
				frame.t = frame:CreateTexture(nil, "OVERLAY")
				frame.t:SetTexture("Interface\\CastingBar\\UI-CastingBar-Border")
				frame.t:SetSize(375, 64)
				frame.t:SetPoint("TOP", 0, 28)

				frame.bar = CreateFrame("StatusBar", nil, frame)
				frame.bar:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
				frame.bar:SetAllPoints()
				frame.bar:SetFrameLevel(LFDDungeonReadyDialog:GetFrameLevel() + 1)
				frame.bar:SetStatusBarColor(0, 1, 0)
			end
		end

		local function LFGBar_Update()
			LFGBar_Create()
			local obj = LFDDungeonReadyDialog
			local oldTime = GetTime()
			local flag = 0
			local duration = 40
			local interval = 0.1
			obj:SetScript("OnUpdate", function(self, elapsed)
				obj.nextUpdate = (obj.nextUpdate or 0) + elapsed
				if obj.nextUpdate > interval then
					local newTime = GetTime()
					local timeleft = newTime - oldTime
					if timeleft < duration then
						local width = frame:GetWidth() * timeleft / duration
						frame.bar:SetPoint("BOTTOMRIGHT", frame, 0 - width, 0)
						flag = flag + 1
						if flag >= 10 then
							flag = 0
						end

						if timeleft <= 15 then
							frame.bar:SetStatusBarColor(0, 1, 0)
						elseif timeleft <= 30 then
							frame.bar:SetStatusBarColor(1, 0.7, 0)
						elseif timeleft <= duration then
							frame.bar:SetStatusBarColor(1, 0, 0)
						end
					else
						obj:SetScript("OnUpdate", nil)
					end
					obj.nextUpdate = 0
				end
			end)
		end

		core:RegisterForEvent("LFG_PROPOSAL_SHOW", function()
			if LFDDungeonReadyDialog:IsShown() then
				LFGBar_Update()
			end
		end)
	end

	-- ///////////////////////////////////////////////////////
	-- WorldMap Fix
	-- UIPanelWindows["WorldMapFrame"] = {area = "center", pushable = 9}
	-- hooksecurefunc(WorldMapFrame, "Show", function(self)
	--     self:SetScale(0.75)
	--     self:EnableKeyboard(false)
	--     BlackoutWorld:Hide()
	--     WorldMapFrame:EnableMouse(false)
	-- end)

	-- ///////////////////////////////////////////////////////

	core:RegisterForEvent("PLAYER_LOGIN", function()
		Fix_UIDropDownMenu()
		Fix_GermanLocale()
		Fix_MinimapPing()
		Fix_InterfaceOptionsCategory()
	end)
end)