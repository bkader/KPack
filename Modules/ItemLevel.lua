local slots = {
    "HeadSlot",
    "NeckSlot",
    "ShoulderSlot",
    "BackSlot",
    "ChestSlot",
    "ShirtSlot",
    "TabardSlot",
    "WristSlot",
    "MainHandSlot",
    "SecondaryHandSlot",
    "RangedSlot",
    "HandsSlot",
    "WaistSlot",
    "LegsSlot",
    "FeetSlot",
    "Finger0Slot",
    "Finger1Slot",
    "Trinket0Slot",
    "Trinket1Slot"
}

-----------------------------------------------------------------------
-- Equipment slots item level

do
    local eventFrame = CreateFrame("Frame", nil, UIParent)
    local loadFrame = CreateFrame("Frame", nil, UIParent)

    local function CreateButtonsText(frame)
        for _, slot in pairs(slots) do
            local button = _G[frame .. slot]
            button.t = button:CreateFontString(nil, "OVERLAY")
            button.t:SetFont(NumberFontNormal:GetFont())
            button.t:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 2, 2)
            button.t:SetText("")
        end
    end

    local function UpdateButtonsText(frame)
        if frame == "Inspect" and not InspectFrame:IsShown() then
            return
        end

        for _, slot in pairs(slots) do
            local id = GetInventorySlotInfo(slot)
            local item
            local text = _G[frame .. slot].t

            if frame == "Inspect" then
                item = GetInventoryItemLink("target", id)
            else
                item = GetInventoryItemLink("player", id)
            end

            if slot == "ShirtSlot" or slot == "TabardSlot" then
                text:SetText("")
            elseif item then
                local oldilevel = text:GetText()
                local ilevel = select(4, GetItemInfo(item))

                if ilevel then
                    if ilevel ~= oldilevel then
                        text:SetText("|cFFFFFF00" .. ilevel)
                    end
                else
                    text:SetText("")
                end
            else
                text:SetText("")
            end
        end
    end

    eventFrame:RegisterEvent("PLAYER_LOGIN")
    eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    eventFrame:SetScript(
        "OnEvent",
        function(self, event)
            if event == "PLAYER_LOGIN" then
                CreateButtonsText("Character")
                UpdateButtonsText("Character")
                self:UnregisterEvent("PLAYER_LOGIN")
            elseif event == "PLAYER_TARGET_CHANGED" then
                UpdateButtonsText("Inspect")
            else
                UpdateButtonsText("Character")
            end
        end
    )

    loadFrame:RegisterEvent("ADDON_LOADED")
    loadFrame:SetScript(
        "OnEvent",
        function(self, event, addon)
            if addon == "Blizzard_InspectUI" then
                CreateButtonsText("Inspect")
                InspectFrame:HookScript(
                    "OnShow",
                    function(self)
                        UpdateButtonsText("Inspect")
                    end
                )
                eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
                self:UnregisterEvent("ADDON_LOADED")
            end
        end
    )
end

-----------------------------------------------------------------------
-- average item level in tooltips and PaperDoll
do
    local floor = math.floor
    local UnitIsPlayer = UnitIsPlayer
    local GetInventoryItemID = GetInventoryItemID
    local GetInventorySlotInfo = GetInventorySlotInfo

    local function CalculateItemLevel(unit)
        if unit and UnitIsPlayer(unit) then
            local total, itn = 0, 0

            for i in ipairs(slots) do
                local slot = GetInventoryItemID(unit, GetInventorySlotInfo(slots[i]))
                if slot then
                    local sName, sLink, iRarity, iLevel, iMinLevel, sType, sSubType, iStackCount = GetItemInfo(slot)
                    if iLevel and iLevel > 0 then
                        itn = itn + 1
                        total = total + iLevel
                    end
                end
            end
            return (total < 1 or itn < 1) and 0 or floor(total / itn)
        end
    end

    GameTooltip:HookScript("OnTooltipSetUnit", function(self, ...)
        local ilevel
        local name, unit = GameTooltip:GetUnit()
        if unit and CanInspect(unit) then
            local isInspectOpen = (InspectFrame and InspectFrame:IsShown()) or (_G.Examiner and _G.Examiner:IsShown())
            if unit and CanInspect(unit) and not isInspectOpen then
                NotifyInspect(unit)
                ilevel = CalculateItemLevel(unit)
                ClearInspectPlayer(unit)
                GameTooltip:AddDoubleLine("Item Level", ilevel, 1, 1, 0)
            end
        end
    end)
end