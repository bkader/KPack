local folder, core = ...
local E = core:Events()

-- main event frame
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")

local strsub = string.sub
local strfind = string.find
local strmatch = string.match

local function addLine(tooltip, left, right)
    tooltip:AddDoubleLine(left, right)
    tooltip:Show()
end

function E:PLAYER_ENTERING_WORLD()
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    hooksecurefunc(GameTooltip, "SetUnitBuff", function(self, ...)
        local id = select(11, UnitBuff(...))
        if id then addLine("Spell ID", id) end
    end)

    hooksecurefunc(GameTooltip, "SetUnitDebuff", function(self, ...)
        local id = select(11, UnitDebuff(...))
        if id then addLine(self, "Spell ID", id) end
    end)

    hooksecurefunc(GameTooltip, "SetUnitAura", function(self, ...)
        local id = select(11, UnitAura(...))
        if id then addLine(self, "Spell ID", id) end
    end)

    hooksecurefunc("SetItemRef", function(link, text, button, chatFrame)
        if strfind(link, "^spell:") or strfind(link, "^enchant:") then
            local pos = strfind(link, ":") + 1
            local id = strsub(link, pos)
            if strfind(id, ":") then
                pos = strfind(id, ":") - 1
                id = id:sub(1, pos)
            end
            if id then
                addLine(ItemRefTooltip, "Spell ID", id)
            end
        elseif strfind(link, "^achievement:") then
            local pos = strfind(link, ":") + 1
            local endpos = strfind(link, ":", pos) - 1
            if pos and endpos then
                local id = strsub(link, pos, endpos)
                if id then
                    addLine(ItemRefTooltip, "Achievement ID", id)
                end
            end
        elseif strfind(link, "^quest:") then
            local pos = strfind(link, ":") + 1
            local endpos = strfind(link, ":", pos) - 1
            if pos and endpos then
                local id = strsub(link, pos, endpos)
                if id then
                    addLine(ItemRefTooltip, "Quest ID", id)
                end
            end
        elseif strfind(link, "^item:") then
            local pos = strfind(link, ":") + 1
            local endpos = strfind(link, ":", pos) - 1
            if pos and endpos then
                local id = strsub(link, pos, endpos)
                if id then
                    addLine(ItemRefTooltip, "Item ID", id)
                end
            end
        end
    end)

    GameTooltip:HookScript("OnTooltipSetSpell", function(self)
        local id = select(3, self:GetSpell())
        if id then addLine(self, "Spell ID", id) end
    end)

    GameTooltip:HookScript("OnTooltipSetItem", function(self)
        local _, itemlink = self:GetItem()
        if itemlink then
            local _, itemid = strsplit(":", strmatch(itemlink, "item[%-?%d:]+"))
            addLine(self, "Item ID:", itemid)
        end
    end)
end