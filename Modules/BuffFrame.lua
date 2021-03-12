local _, addon = ...
local hooksecurefunc = hooksecurefunc

do
    -- edit the configuration the way you want
    local config = {
        -- Buffs
        buffSize = 30,
        buffScale = 1,
        buffFontSize = 14,
        buffCountSize = 16,
        -- Debuffs
        debuffSize = 32,
        debuffScale = 1,
        debuffFontSize = 14,
        debuffCountSize = 16,
        durationFont = [[Interface\AddOns\KPack\Media\Fonts\yanone.ttf]], -- the font used for the duration
        countFont = [[Interface\AddOns\KPack\Media\Fonts\yanone.ttf]] -- the font used for stack counts
    }

    -- we makd sure to change the way duration looks.
    local ceil, mod = math.ceil, mod

    local origSecondsToTimeAbbrev = _G.SecondsToTimeAbbrev
    local function SecondsToTimeAbbrevHook(seconds)
        origSecondsToTimeAbbrev(seconds)
        if seconds >= 86400 then
            return "|cffffffff%dd|r", ceil(seconds / 86400)
        elseif seconds >= 3600 then
            return "|cffffffff%dh|r", ceil(seconds / 3600)
        elseif seconds >= 60 then
            return "|cffffffff%dm|r", ceil(seconds / 60)
        end
        return "|cffffffff%d|r", seconds
    end
    _G.SecondsToTimeAbbrev = SecondsToTimeAbbrevHook
    BuffFrame:SetScript("OnUpdate", nil)

    -- Style temporary enchants first:
    do
        local function UpdateFirstButton(buff)
            if buff and buff:IsShown() then
                buff:ClearAllPoints()
                if BuffFrame.numEnchants > 0 then
                    buff:SetPoint("TOPRIGHT", _G["TempEnchant" .. BuffFrame.numEnchants], "TOPLEFT", -5, 0)
                else
                    buff:SetPoint("TOPRIGHT", TempEnchant1)
                end
                return
            end
        end

        local function CheckFirstButton()
            if BuffButton1 then
                UpdateFirstButton(BuffButton1)
            end
        end

        for i = 1, 2 do
            local buff = _G["TempEnchant" .. i]
            if buff then
                buff:SetScale(config.buffScale)
                buff:SetSize(config.buffSize, config.buffSize)
                buff:SetScript("OnShow", function() CheckFirstButton() end)
                buff:SetScript("OnHide", function() CheckFirstButton() end)

                local icon = _G["TempEnchant" .. i .. "Icon"]
                icon:SetTexCoord(0.04, 0.96, 0.04, 0.96)

                local duration = _G["TempEnchant" .. i .. "Duration"]
                duration:ClearAllPoints()
                duration:SetPoint("BOTTOM", buff, "BOTTOM", 0, -2)
                duration:SetFont(config.durationFont, config.buffFontSize, "THINOUTLINE")
                duration:SetShadowOffset(0, 0)
                duration:SetDrawLayer("OVERLAY")
            end
        end
    end

    -- style everything else.
    hooksecurefunc("AuraButton_Update", function(buttonName, index, filter)
        local buffName = buttonName .. index
        local buff = _G[buffName]

        if not buff then
            return
        end

        -- position the duration
        buff.duration:ClearAllPoints()
        buff.duration:SetPoint("BOTTOM", buff, "BOTTOM", 0, -2)
        buff.duration:SetShadowOffset(0, 0)
        buff.duration:SetDrawLayer("OVERLAY")

        -- position the stack count
        buff.count:ClearAllPoints()
        buff.count:SetPoint("TOPRIGHT", buff)
        buff.count:SetShadowOffset(0, 0)
        buff.count:SetDrawLayer("OVERLAY")

        if filter == "HELPFUL" then
            buff:SetSize(config.buffSize, config.buffSize)
            buff:SetScale(config.buffScale)
            buff.duration:SetFont(config.durationFont, config.buffFontSize, "THINOUTLINE")
            buff.count:SetFont(config.countFont, config.buffCountSize, "THINOUTLINE")
        else
            buff:SetSize(config.debuffSize, config.debuffSize)
            buff:SetScale(config.debuffScale)
            buff.duration:SetFont(config.durationFont, config.debuffFontSize, "THINOUTLINE")
            buff.count:SetFont(config.countFont, config.debuffCountSize, "THINOUTLINE")
        end
    end)
end

-- ----------------------------------------------------------------------------

do
    local select, pairs, match, format = select, pairs, string.match, string.format
    local GetUnitName, UnitIsPlayer, UnitClass, UnitReaction = GetUnitName, UnitIsPlayer, UnitClass, UnitReaction
    local UnitAura, UnitBuff, UnitDebuff = UnitAura, UnitBuff, UnitDebuff

    local BETTER_FACTION_BAR_COLORS = {
        [1] = {r = 217 / 255, g = 69 / 255, b = 69 / 255},
        [2] = {r = 217 / 255, g = 69 / 255, b = 69 / 255},
        [3] = {r = 217 / 255, g = 69 / 255, b = 69 / 255},
        [4] = {r = 217 / 255, g = 196 / 255, b = 92 / 255},
        [5] = {r = 84 / 255, g = 150 / 255, b = 84 / 255},
        [6] = {r = 84 / 255, g = 150 / 255, b = 84 / 255},
        [7] = {r = 84 / 255, g = 150 / 255, b = 84 / 255},
        [8] = {r = 84 / 255, g = 150 / 255, b = 84 / 255}
    }

    local classColors = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS

    local function KPack_AddAuraSource(self, func, unit, index, filter)
        local srcUnit = select(8, func(unit, index, filter))
        if srcUnit then
            local src = GetUnitName(srcUnit, true)
            if srcUnit == "pet" or srcUnit == "vehicle" then
                local color = classColors[select(2, UnitClass("player"))]
                src = format("%s (|cff%02x%02x%02x%s|r)", src, color.r * 255, color.g * 255, color.b * 255, GetUnitName("player", true))
            else
                local partypet = match(srcUnit, "^partypet(%d+)$")
                local raidpet = match(srcUnit, "^raidpet(%d+)$")
                if partypet then
                    src = format("%s (%s)", src, GetUnitName("party" .. partypet, true))
                elseif raidpet then
                    src = format("%s (%s)", src, GetUnitName("raid" .. raidpet, true))
                end
            end
            if UnitIsPlayer(srcUnit) then
                local color = classColors[select(2, UnitClass(srcUnit))]
                if color then
                    src = format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, src)
                end
            else
                local color = BETTER_FACTION_BAR_COLORS[UnitReaction(srcUnit, "player")]
                if color then
                    src = format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, src)
                end
            end
            self:AddLine(DONE_BY .. " " .. src)
            self:Show()
        end
    end
    local funcs = {
        SetUnitAura = UnitAura,
        SetUnitBuff = UnitBuff,
        SetUnitDebuff = UnitDebuff
    }

    for k, v in pairs(funcs) do
        hooksecurefunc(GameTooltip, k, function(self, unit, index, filter)
            KPack_AddAuraSource(self, v, unit, index, filter)
        end)
    end
end