local core = KPack
if not core then return end
core:AddModule("RaidTabs", "Adds tabs to raid brower, BG or RDF windows, allowing you to switch between them.", function()
	if core:IsDisabled("RaidTabs") then return end

	local libTab = _G.libTab
	local tabs = {
		-- looking for dungeon
		LFDParentFrame = {
			Frame = "LFDParentFrame",
			Texture = "Interface\\LFGFrame\\UI-LFG-PORTRAIT",
			ToolTip = LOOKING_FOR_DUNGEON,
			order = 1,
			group = 1,
			offsetX = 0,
			offsetY = 0
		},
		-- looking for raid
		LFRParentFrame = {
			Frame = "LFRParentFrame",
			Texture = "Interface\\LFGFrame\\UI-LFR-PORTRAIT",
			ToolTip = LOOKING_FOR_RAID,
			order = 2,
			group = 1,
			offsetX = 0,
			offsetY = 0
		},
		-- battleground
		PVPParentFrame = {
			Frame = "PVPParentFrame",
			Texture = "Interface\\BattlefieldFrame\\UI-Battlefield-Icon",
			ToolTip = BATTLEGROUNDS,
			order = 3,
			offsetX = -29,
			offsetY = 0,
			OnClickFunction = function()
				PVPFrame:Hide()
				PVPBattlegroundFrame:Show()
				PanelTemplates_Tab_OnClick(PVPParentFrameTab2, PVPParentFrame)
				PVPBattlegroundFrameGroupJoinButton:SetFrameLevel(PVPParentFrameTab2:GetFrameLevel() + 1)
			end,
			OnShowFunction = function(caller)
				caller.OnClickFunction = nil
				caller.OnShowFunction = nil
			end
		}
	}
	libTab:initialize("KPackRaidTabs", tabs)

	local oldRaidFrameButtonOnClick = RaidFrameNotInRaidRaidBrowserButton:GetScript("OnClick")
	RaidFrameNotInRaidRaidBrowserButton:SetScript("OnClick", function(...)
		libTab:tabSetGroupFrame("KPackRaidTabs", "LFRParentFrame")
		if (oldRaidFrameButtonOnClick) then
			oldRaidFrameButtonOnClick(...)
		end
	end)
end)