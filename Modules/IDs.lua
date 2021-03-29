assert(KPack, "KPack not found!")
KPack:AddModule("IDs", "Adds IDs to the ingame tooltips.", function(_, core, L)
    if core:IsDisabled("IDs") then return end

    local IDs = {}
    core.IDs = IDs
    LibStub("AceHook-3.0"):Embed(IDs)

    local strsub = string.sub
    local strfind = string.find
    local strmatch = string.match

    local function addLine(tooltip, left, right)
        tooltip:AddDoubleLine(left, right)
        tooltip:Show()
    end

    core:RegisterForEvent("PLAYER_ENTERING_WORLD", function()
        IDs:HookScript(GameTooltip, "OnTooltipSetSpell", function(self)
            local id = select(3, self:GetSpell())
            if id then addLine(self, L["Spell ID"], id) end
        end)

        IDs:HookScript(GameTooltip, "OnTooltipSetItem", function(self)
            local _, itemlink = self:GetItem()
            if itemlink then
                local _, itemid = strsplit(":", strmatch(itemlink, "item[%-?%d:]+"))
                addLine(self, L["Item ID"], itemid)
            end
        end)

        IDs:SecureHook(GameTooltip, "SetUnitBuff", function(self, ...)
            local id = select(11, UnitBuff(...))
            if id then addLine(self, L["Spell ID"], id) end
        end)

        IDs:SecureHook(GameTooltip, "SetUnitDebuff", function(self, ...)
            local id = select(11, UnitDebuff(...))
            if id then addLine(self, L["Spell ID"], id) end
        end)

        IDs:SecureHook(GameTooltip, "SetUnitAura", function(self, ...)
            local id = select(11, UnitAura(...))
            if id then addLine(self, L["Spell ID"], id) end
        end)

        IDs:SecureHook("SetItemRef", function(link, text, button, chatFrame)
            if strfind(link, "^spell:") or strfind(link, "^enchant:") then
                local pos = strfind(link, ":") + 1
                local id = strsub(link, pos)
                if strfind(id, ":") then
                    pos = strfind(id, ":") - 1
                    id = id:sub(1, pos)
                end
                if id then addLine(ItemRefTooltip, L["Spell ID"], id) end
            elseif strfind(link, "^achievement:") then
                local pos = strfind(link, ":") + 1
                local endpos = strfind(link, ":", pos) - 1
                if pos and endpos then
                    local id = strsub(link, pos, endpos)
                    if id then addLine(ItemRefTooltip, L["Achievement ID"], id) end
                end
            elseif strfind(link, "^quest:") then
                local pos = strfind(link, ":") + 1
                local endpos = strfind(link, ":", pos) - 1
                if pos and endpos then
                    local id = strsub(link, pos, endpos)
                    if id then addLine(ItemRefTooltip, L["Quest ID"], id) end
                end
            elseif strfind(link, "^item:") then
                local pos = strfind(link, ":") + 1
                local endpos = strfind(link, ":", pos) - 1
                if pos and endpos then
                    local id = strsub(link, pos, endpos)
                    if id then addLine(ItemRefTooltip, L["Item ID"], id) end
                end
            end
        end)
    end)
end)