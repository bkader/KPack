local addonName, addon = ...

-- main event frame
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")

local strsub = string.sub
local strfind = string.find
local strmatch = string.match

-- frame event handler
local function EventHandler(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name:lower() == addonName:lower() then
            f:UnregisterEvent("ADDON_LOADED")
            f:RegisterEvent("PLAYER_ENTERING_WORLD")
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        f:UnregisterEvent("PLAYER_ENTERING_WORLD")
        hooksecurefunc(GameTooltip, "SetUnitBuff", function(self, ...)
            local id = select(11, UnitBuff(...))
            if id then
                self:AddDoubleLine("Spell ID", id)
                self:Show()
            end
        end)

        hooksecurefunc(GameTooltip, "SetUnitDebuff", function(self, ...)
            local id = select(11, UnitDebuff(...))
            if id then
                self:AddDoubleLine("Spell ID", id)
                self:Show()
            end
        end)

        hooksecurefunc(GameTooltip, "SetUnitAura", function(self, ...)
            local id = select(11, UnitAura(...))
            if id then
                self:AddDoubleLine("Spell ID", id)
                self:Show()
            end
        end)

        hooksecurefunc("SetItemRef", function(link, text, button, chatFrame)
            if strfind(link, "^spell:") then
                local id = strsub(link, 7)
                ItemRefTooltip:AddDoubleLine("Spell ID", id)
                ItemRefTooltip:Show()
            elseif strfind(link, "^item:") then
                local id = select(3, strfind(link, "^|%x+|Hitem:(%-?%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%-?%d+):(%-?%d+)"))
                if id then
                    ItemRefTooltip:AddDoubleLine("Item ID", id)
                    ItemRefTooltip:Show()
                end
            end
        end)

        GameTooltip:HookScript("OnTooltipSetSpell", function(self)
            local id = select(3, self:GetSpell())
            if id then
                self:AddDoubleLine("Spell ID", id)
                self:Show()
            end
        end)

        GameTooltip:HookScript("OnTooltipSetItem", function(self)
            local _, itemlink = self:GetItem()
            if itemlink then
                local str, itemid = strsplit(":", strmatch(itemlink, "item[%-?%d:]+"))
                self:AddDoubleLine("ItemID:", itemid)
                self:Show()
            end
        end)
    end
end
f:SetScript("OnEvent", EventHandler)