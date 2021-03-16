local folder, core = ...

local mod = core.RaidUtility or {}
core.RaidUtility = mod

local E = core:Events()
local L = core.L

local strfind = string.find
local CreateFrame = CreateFrame
local GetNumRaidMembers = GetNumRaidMembers
local GetNumPartyMembers = GetNumPartyMembers
local IsPartyLeader = IsPartyLeader
local IsRaidLeader = IsRaidLeader
local IsRaidOfficer = IsRaidOfficer
local InCombatLockdown = InCombatLockdown
local DoReadyCheck = DoReadyCheck
local ToggleFriendsFrame = ToggleFriendsFrame

local GetRaidRosterInfo = GetRaidRosterInfo
local UninviteUnit = UninviteUnit

local RaidUtilityPanel
local showButton

local function Print(msg)
    if msg then
        core:Print(msg, "RaidUtility")
    end
end

local function CheckRaidStatus()
    local inInstance, instanceType = IsInInstance()
    if
        (((IsRaidLeader() or IsRaidOfficer()) and GetNumRaidMembers() > 0) or
            (IsPartyLeader() and GetNumPartyMembers() > 0)) and
            not (inInstance and (instanceType == "pvp" or instanceType == "arena"))
     then
        return true
    else
        return false
    end
end

local function CreateRaidUtilityPanel()
    if RaidUtilityPanel then return end
    RaidUtilityPanel = CreateFrame("Frame", "KPackRaidUtilityPanel", UIParent, "SecureHandlerClickTemplate")
    RaidUtilityPanel:SetBackdrop({
        bgFile = [[Interface\DialogFrame\UI-DialogBox-Background-Dark]],
        edgeFile = [[Interface\DialogFrame\UI-DialogBox-Border]],
        edgeSize = 8,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    RaidUtilityPanel:SetBackdropColor(0, 0, 1, 0.85)
    RaidUtilityPanel:SetSize(230, 112)
    RaidUtilityPanel:SetPoint("TOP", UIParent, "TOP", -400, 1)
    RaidUtilityPanel:SetFrameLevel(3)
    RaidUtilityPanel:SetFrameStrata("HIGH")

    showButton = CreateFrame("Button", "KPackRaidUtility_ShowButton", UIParent, "KPackButtonTemplate, SecureHandlerClickTemplate")
    showButton:SetSize(136, 20)
    showButton:SetPoint("TOP", -400, 0)
    showButton:SetText(RAID_CONTROL)
    showButton:SetFrameRef("KPackRaidUtilityPanel", RaidUtilityPanel)
    showButton:SetAttribute("_onclick", [=[
		local raidUtil = self:GetFrameRef("KPackRaidUtilityPanel")
		local closeBtn = raidUtil:GetFrameRef("KPackRaidUtility_CloseButton")
		self:Hide()
		raidUtil:Show()

		local point = self:GetPoint()
		local raidUtilPoint, closeBtnPoint, yOffset
		if string.find(point, "BOTTOM") then
			raidUtilPoint, closeBtnPoint, yOffset = "BOTTOM", "TOP", 5
		else
			raidUtilPoint, closeBtnPoint, yOffset = "TOP", "BOTTOM", -5
		end

		raidUtil:ClearAllPoints()
		raidUtil:SetPoint(raidUtilPoint, self, raidUtilPoint)

		closeBtn:ClearAllPoints()
		closeBtn:SetPoint(raidUtilPoint, raidUtil, closeBtnPoint, 0, yOffset)
	]=])
    showButton:SetScript("OnMouseUp", function(self) RaidUtilityPanel.toggled = true end)
    showButton:SetMovable(true)
    showButton:SetClampedToScreen(true)
    showButton:SetClampRectInsets(0, 0, -1, 1)
    showButton:RegisterForDrag("RightButton")
    showButton:SetFrameStrata("HIGH")
    showButton:SetScript("OnDragStart", function(self)
        if InCombatLockdown() then
            Print(ERR_NOT_IN_COMBAT)
            return
        end
        self:StartMoving()
    end)

    showButton:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point = self:GetPoint()
        local xOffset = self:GetCenter()
        local screenWidth = UIParent:GetWidth() / 2
        xOffset = xOffset - screenWidth
        self:ClearAllPoints()
        if strfind(point, "BOTTOM") then
            self:SetPoint("BOTTOM", UIParent, "BOTTOM", xOffset, -1)
        else
            self:SetPoint("TOP", UIParent, "TOP", xOffset, 1)
        end
    end)

    local close = CreateFrame("Button", "KPackRaidUtility_CloseButton", RaidUtilityPanel, "KPackButtonTemplate, SecureHandlerClickTemplate")
    close:SetSize(136, 20)
    close:SetPoint("TOP", RaidUtilityPanel, "BOTTOM", 0, -1)
    close:SetText(CLOSE)
    close:SetFrameRef("KPackRaidUtility_ShowButton", showButton)
    close:SetAttribute("_onclick", [=[self:GetParent():Hide(); self:GetFrameRef("KPackRaidUtility_ShowButton"):Show();]=])
    close:SetScript("OnMouseUp", function(self) RaidUtilityPanel.toggled = nil end)
    RaidUtilityPanel:SetFrameRef("KPackRaidUtility_CloseButton", close)

    local disband = CreateFrame("Button", nil, RaidUtilityPanel, "KPackButtonTemplate, SecureActionButtonTemplate")
    disband:SetSize(200, 20)
    disband:SetPoint("TOP", RaidUtilityPanel, "TOP", 0, -8)
    disband:SetText(L["Disband Group"])
    disband:SetScript("OnMouseUp", function()
        if CheckRaidStatus() then
            StaticPopup_Show("DISBAND_RAID")
        end
    end)

    local maintank = CreateFrame("Button", nil, RaidUtilityPanel, "KPackButtonTemplate, SecureActionButtonTemplate")
    maintank:SetSize(95, 20)
    maintank:SetPoint("TOPLEFT", disband, "BOTTOMLEFT", 0, -5)
    maintank:SetText(MAINTANK)
    maintank:SetAttribute("type", "maintank")
    maintank:SetAttribute("unit", "target")
    maintank:SetAttribute("action", "toggle")

    local offtank = CreateFrame("Button", nil, RaidUtilityPanel, "KPackButtonTemplate, SecureActionButtonTemplate")
    offtank:SetSize(95, 20)
    offtank:SetPoint("TOPRIGHT", disband, "BOTTOMRIGHT", 0, -5)
    offtank:SetText(MAINASSIST)
    offtank:SetAttribute("type", "mainassist")
    offtank:SetAttribute("unit", "target")
    offtank:SetAttribute("action", "toggle")

    local ready = CreateFrame("Button", nil, RaidUtilityPanel, "KPackButtonTemplate, SecureActionButtonTemplate")
    ready:SetSize(200, 20)
    ready:SetPoint("TOPLEFT", maintank, "BOTTOMLEFT", 0, -5)
    ready:SetText(READY_CHECK)
    ready:SetScript("OnMouseUp", function()
        if CheckRaidStatus() then
            DoReadyCheck()
        end
    end)

    local control = CreateFrame("Button", nil, RaidUtilityPanel, "KPackButtonTemplate, SecureActionButtonTemplate")
    control:SetSize(95, 20)
    control:SetPoint("TOPLEFT", ready, "BOTTOMLEFT", 0, -5)
    control:SetText(L["Raid Menu"])
    control:SetScript("OnMouseUp", function()
        if InCombatLockdown() then
            Print(ERR_NOT_IN_COMBAT)
            return
        end
        ToggleFriendsFrame(5)
    end)
    RaidUtilityPanel.control = control

    local convert = CreateFrame("Button", nil, RaidUtilityPanel, "SecureHandlerClickTemplate, KPackButtonTemplate")
    convert:SetSize(95, 20)
    convert:SetPoint("TOPRIGHT", ready, "BOTTOMRIGHT", 0, -5)
    convert:SetText(CONVERT_TO_RAID)
    convert:SetScript("OnMouseUp", function()
        if CheckRaidStatus() then
            ConvertToRaid()
            SetLootMethod("master", "player")
        end
    end)
    RaidUtilityPanel.convert = convert
end

function E:ADDON_LOADED(name)
    self:UnregisterEvent("ADDON_LOADED")
    if name ~= folder then
        return
    end
    CreateRaidUtilityPanel()
end

function mod:RaidUtilityToggle(event)
    if GetNumRaidMembers() == 0 and GetNumPartyMembers() > 0 and IsPartyLeader() then
        RaidUtilityPanel.control:SetWidth(95)
        RaidUtilityPanel.convert:Show()
    else
        RaidUtilityPanel.control:SetWidth(200)
        RaidUtilityPanel.convert:Hide()
    end

    if InCombatLockdown() then
        return
    end

    if CheckRaidStatus() then
        if RaidUtilityPanel.toggled == true then
            RaidUtilityPanel:Show()
            showButton:Hide()
        else
            RaidUtilityPanel:Hide()
            showButton:Show()
        end
    else
        RaidUtilityPanel:Hide()
        showButton:Hide()
    end

    if event == "PLAYER_REGEN_ENABLED" then
        E:UnregisterEvent("PLAYER_REGEN_ENABLED")
    end
end

function E:PLAYER_ENTERING_WORLD()
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    mod:RaidUtilityToggle("PLAYER_ENTERING_WORLD")
end

function E:RAID_ROSTER_UPDATE()
    mod:RaidUtilityToggle("RAID_ROSTER_UPDATE")
end

function E:PARTY_MEMBERS_CHANGED()
    mod:RaidUtilityToggle("PARTY_MEMBERS_CHANGED")
end

function E:PLAYER_REGEN_ENABLED()
    mod:RaidUtilityToggle("PLAYER_REGEN_ENABLED")
end

StaticPopupDialogs.DISBAND_RAID = {
    text = L["Are you sure you want to disband the group?"],
    button1 = ACCEPT,
    button2 = CANCEL,
    OnAccept = function()
        if InCombatLockdown() then
            return
        end
        local numRaid = GetNumRaidMembers()
        if numRaid > 0 then
            for i = 1, numRaid do
                local name, _, _, _, _, _, _, online = GetRaidRosterInfo(i)
                if online and name ~= core.name then
                    UninviteUnit(name)
                end
            end
        else
            for i = MAX_PARTY_MEMBERS, 1, -1 do
                if GetPartyMember(i) then
                    UninviteUnit(UnitName("party" .. i))
                end
            end
        end
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    preferredIndex = 3
}