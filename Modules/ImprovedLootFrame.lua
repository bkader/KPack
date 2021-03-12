local addonName, addon = ...

local mod = addon.ILF or CreateFrame("Frame")
addon.ILF = mod
mod:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
mod:RegisterEvent("ADDON_LOADED")

-- flag whether the player is using a loot addon
local hasAddon

-- cache frequently used globals
local CreateFrame = CreateFrame
local GetNumLootItems = GetNumLootItems
local select, pairs = select, pairs

-- module print function
local function Print(msg)
    if msg then
        addon:Print(msg, "ImprovedLootFrame")
    end
end

-- initializes the module
local function ILF_Initialize()
    local i, t = 1, "Interface\\LootFrame\\UI-LootPanel"

    while true do
        local r = select(i, LootFrame:GetRegions())
        if not r then
            break
        end

        if r.GetText and r:GetText() == ITEMS then
            r:ClearAllPoints()
            r:SetPoint("TOP", -12, -19.5)
        elseif r.GetTexture and r:GetTexture() == t then
            r:Hide()
        end
        i = i + 1
    end

    -- frame top
    local top = LootFrame:CreateTexture("LootFrameBackdropTop")
    top:SetTexture(t)
    top:SetTexCoord(0, 1, 0, 0.3046875)
    top:SetPoint("TOP")
    top:SetHeight(78)

    -- frame bottom
    local bottom = LootFrame:CreateTexture("LootFrameBackdropBottom")
    bottom:SetTexture(t)
    bottom:SetTexCoord(0, 1, 0.9296875, 1)
    bottom:SetPoint("BOTTOM")
    bottom:SetHeight(18)

    -- frame middle
    local mid = LootFrame:CreateTexture("LootFrameBackdropMiddle")
    mid:SetTexture(t)
    mid:SetTexCoord(0, 1, 0.3046875, 0.9296875)
    mid:SetPoint("TOP", top, "BOTTOM")
    mid:SetPoint("BOTTOM", bottom, "TOP")
end

function mod:ADDON_LOADED(name)
	if name ~= addonName then return end
	self:UnregisterEvent("ADDON_LOADED")
	hasAddon = IsAddOnLoaded("LovelyLoot")
	if hasAddon then return end
	ILF_Initialize()
end

-- ///////////////////////////////////////////////////////
-- replace default functions
-- ///////////////////////////////////////////////////////

-- replacing LootFrame_Show
do
    local p, r, x, y = "TOP", "BOTTOM", 0, -4
    local buttonHeight = LootButton1:GetHeight() + abs(y)
    local baseHeight = LootFrame:GetHeight() - (buttonHeight * LOOTFRAME_NUMBUTTONS)

    local Old_LootFrame_Show = LootFrame_Show
    _G.LootFrame_Show = function(self, ...)
        LootFrame:SetHeight(baseHeight + (GetNumLootItems() * buttonHeight))
        local num = GetNumLootItems()
        for i = 1, GetNumLootItems() do
            if i > LOOTFRAME_NUMBUTTONS then
                local button = _G["LootButton" .. i]
                if not button then
                    button = CreateFrame("Button", "LootButton" .. i, LootFrame, "LootButtonTemplate", i)
                end
                LOOTFRAME_NUMBUTTONS = i
            end

            if i > 1 then
                local button = _G["LootButton" .. i]
                button:ClearAllPoints()
                button:SetPoint(p, "LootButton" .. (i - 1), r, x, y)
            end
        end
        return Old_LootFrame_Show(self, ...)
    end
end

-- replacing LootButton_OnClick
do
    -- list of registered frames.
    local frames = {}

    -- populates the frames table.
    local function PopulateFrames(...)
        wipe(frames)
        for i = 1, select("#", ...) do
            frames[i] = select(i, ...)
        end
    end

    local Old_LootButton_OnClick = LootButton_OnClick
    _G.LootButton_OnClick = function(self, ...)
        PopulateFrames(GetFramesRegisteredForEvent("ADDON_ACTION_BLOCKED"))

        for i, frame in pairs(frames) do
            frame:UnregisterEvent("ADDON_ACTION_BLOCKED")
        end

        Old_LootButton_OnClick(self, ...)
        for i, frame in pairs(frames) do
            frame:RegisterEvent("ADDON_ACTION_BLOCKED")
        end
    end
end