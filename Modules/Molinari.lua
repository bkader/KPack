local folder, core = ...

local mod = core.Molinari or {}
core.Molinari = mod

local E = core:Events()

local unpack = unpack
local select = select
local pairs = pairs

local IsSpellKnown = IsSpellKnown
local GetSpellInfo = GetSpellInfo
local GetMouseFocus = GetMouseFocus
local GetItemInfo = GetItemInfo
local AutoCastShine_AutoCastStart = AutoCastShine_AutoCastStart
local AutoCastShine_AutoCastStop = AutoCastShine_AutoCastStop

local _
local button
local enabled, auction
local macro = "/cast %s\n/use %s %s"
local spells = {}

-- the following table is used to validate
-- items that can be disenchanted
local itemTypes = {
    INVTYPE_HEAD = true,
    INVTYPE_NECK = true,
    INVTYPE_SHOULDER = true,
    INVTYPE_CLOAK = true,
    INVTYPE_CHEST = true,
    INVTYPE_WRIST = true,
    INVTYPE_HAND = true,
    INVTYPE_WAIST = true,
    INVTYPE_LEGS = true,
    INVTYPE_FEET = true,
    INVTYPE_FINGER = true,
    INVTYPE_TRINKET = true,
    INVTYPE_RANGED = true,
    INVTYPE_RANGEDRIGHT = true,
    INVTYPE_THROWN = true,
    INVTYPE_HOLDABLE = true,
    INVTYPE_SHIELD = true,
    INVTYPE_WEAPON = true,
    INVTYPE_2HWEAPON = true,
    INVTYPE_WEAPONMAINHAND = true,
    INVTYPE_WEAPONOFFHAND = true
}

local function ScanTooltip(text)
    for index = 1, GameTooltip:NumLines() do
        local info = spells[_G["GameTooltipTextLeft" .. index]:GetText()]
        if info then
            return unpack(info)
        end
    end
end

local function Clickable()
    return (not InCombatLockdown() and IsAltKeyDown() and not auction)
end

local function Disperse(self)
    if not InCombatLockdown() then
        self:Hide()
        self:ClearAllPoints()
        AutoCastShine_AutoCastStop(self)
    end
end

local function Molinari_OnTooltipSetItem(self)
    local iname, ilink = self:GetItem()
    if iname and Clickable() then
        local spell, r, g, b = ScanTooltip()
        local bag, slot
        if spell then
            slot = GetMouseFocus()
            bag = slot:GetParent()
        elseif spells.DE and itemTypes[select(9, GetItemInfo(ilink))] then
            spell, r, g, b = unpack(spells.DE)
            slot = GetMouseFocus()
            bag = slot:GetParent()
        end
        if spell and bag and slot then
            button:SetAttribute("type", "macro")
            button:SetAttribute("macrotext", macro:format(spell, bag:GetID(), slot:GetID()))
            button:SetAllPoints(slot)
            button:Show()
            AutoCastShine_AutoCastStart(button, r, g, b)
        end
    end
end

function E:PLAYER_LOGIN()
	self:UnregisterEvent("PLAYER_LOGIN")

    -- Lockpicking
    if IsSpellKnown(1804) then
        spells[LOCKED] = {select(1, GetSpellInfo(1804)), 0, 1, 1}
        enabled = true
    end

    -- Disenchanting
    if IsSpellKnown(13262) then
        spells.DE = {select(1, GetSpellInfo(13262)), 0.5, 0.5, 1}
        enabled = true
    end

    -- Prospecting
    if IsSpellKnown(31252) then
        spells[ITEM_PROSPECTABLE] = {select(1, GetSpellInfo(31252)), 1, 0.5, 0.5}
        enabled = true
    end

    -- Milling
    if IsSpellKnown(51005) then
        spells[ITEM_MILLABLE] = {select(1, GetSpellInfo(51005)), 0.5, 1, 0.5}
        enabled = true
    end

    if not enabled then return end

    button = CreateFrame("Button", "KPackMolinari", UIParent, "SecureActionButtonTemplate, AutoCastShineTemplate")
	button:SetPoint("TOPLEFT", -999, 0)
    button:RegisterForClicks("LeftButtonUp")
    button:SetFrameStrata("DIALOG")
    button:SetScript("OnLeave", Disperse)
    button:Hide()

    for _, sparkle in pairs(button.sparkles) do
        sparkle:SetHeight(sparkle:GetHeight() * 3)
        sparkle:SetWidth(sparkle:GetWidth() * 3)
    end

    GameTooltip:HookScript("OnTooltipSetItem", Molinari_OnTooltipSetItem)
end

function E:MODIFIER_STATE_CHANGED(key)
    if button and button:IsShown() and (key == "LALT" or key == "RALT") then
        Disperse(button)
    end
end

function E:PLAYER_REGEN_ENABLED()
    if button then Disperse(button) end
end

-- Auctionator check
function E:AUCTION_HOUSE_SHOW()
	if _G.AUCTIONATOR_ENABLE_ALT == 1 then
		auction = true
	end
end

function E:AUCTION_HOUSE_CLOSED()
    auction = nil
end