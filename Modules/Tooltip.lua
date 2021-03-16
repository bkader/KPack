local addonName, addon = ...

local mod = addon.Tooltip or {}
addon.Tooltip = mod

local E = addon:Events()
local L = addon.L

-- saved variables & defaults
TooltipDB = {}
local defaults = {
    unit = false,
    spell = false,
    petspell = false,
    class = false,
    enhance = true,
    scale = 1,
    moved = false
}

-- cache frequently used globals
local next, type, select, pairs = next, type, select, pairs
local format, match = string.format, string.match
local UnitPlayerControlled = UnitPlayerControlled
local GetQuestDifficultyColor = GetQuestDifficultyColor
local UnitClassification, UnitCreatureType = UnitClassification, UnitCreatureType
local UnitIsPlayer, UnitExists = UnitIsPlayer, UnitExists
local UnitName, UnitLevel, UnitRace, UnitClass = UnitName, UnitLevel, UnitRace, UnitClass
local UnitReaction, UnitCanAttack, UnitIsPVP = UnitReaction, UnitCanAttack, UnitIsPVP
local UnitHealth, UnitHealthMax = UnitHealth, UnitHealthMax
local IsInGuild, GetGuildInfo = IsInGuild, GetGuildInfo

-- needed locals
local iconFrame, inCombat

-- module's print function
local function Print(msg)
    if msg then
        addon:Print(msg, "Tooltip")
    end
end

do
    -- slash commands handler
    local SlashCommandHandler
    do
        local exec = {}
        local helpStr = "|cffffd700%s|r: %s"

        -- toggles unit tooltips
        exec.unit = function()
            TooltipDB.unit = not TooltipDB.unit
            Print(L:F("unit tooltip in combat: %s", TooltipDB.unit and L["|cffff0000disabled|r"] or L["|cff00ff00enabled|r"]))
        end

        -- toggles spells tooltips
        exec.action = function()
            TooltipDB.spell = not TooltipDB.spell
            Print(L:F("bar spells tooltip in combat: %s", TooltipDB.spell and L["|cffff0000disabled|r"] or L["|cff00ff00enabled|r"]))
        end

        -- toggles pet spells tooltips
        exec.pet = function()
            TooltipDB.petspell = not TooltipDB.petspell
            Print(L:F("pet bar spells tooltip in combat: %s", TooltipDB.petspell and L["|cffff0000disabled|r"] or L["|cff00ff00enabled|r"]))
        end

        -- toggles class spells tooltips
        exec.class = function()
            TooltipDB.class = not TooltipDB.class
            Print(L:F("class bar spells tooltip in combat: %s", TooltipDB.class and L["|cffff0000disabled|r"] or L["|cff00ff00enabled|r"]))
        end

        -- change tooltip scale
        exec.scale = function(scale)
            scale = tonumber(scale)
            if scale and scale ~= TooltipDB.scale then
                TooltipDB.scale = scale
                Print(L:F("tooltip scale set to: |cff00ffff%s|r", scale))
            end
        end

        -- move tooltip to top middle of the screen, or not
        exec.move = function()
            TooltipDB.move = not TooltipDB.move
            if TooltipDB.move then
                Print(L["tooltip moved to top middle of the screen."])
            else
                Print(L["tooltip moved to default position."] .. " " .. L["Please reload ui."])
            end
        end

        -- toggle tooltip enhancement
        exec.enhance = function()
            TooltipDB.enhance = not TooltipDB.enhance
            Print(L:F("enhanced tooltips: %s", TooltipDB.enhance and L["|cff00ff00enabled|r"] or L["|cffff0000disabled|r"]))
        end

        -- main slash commands function
        function SlashCommandHandler(msg)
            local cmd, rest = strsplit(" ", msg, 2)
            cmd = cmd:lower()
            if type(exec[cmd]) == "function" then
                exec[cmd](rest)
                E:PLAYER_ENTERING_WORLD()
            else
                Print(L:F("Acceptable commands for: |caaf49141%s|r", "/tip"))
                print(helpStr:format("unit", L["toggles unit tooltip in combat"]))
                print(helpStr:format("spell", L["toggles bar spells tooltip in combat"]))
                print(helpStr:format("pet", L["toggles pet bar spells tooltip in combat"]))
                print(helpStr:format("class", L["toggles class bar spells tooltip in combat"]))
                print(helpStr:format("scale |cff00ffffn|r", L["change tooltips scale"]))
                print(helpStr:format("move", L["moves tooltip to top middle of the screen"]))
                print(helpStr:format("enhance", L["toggles enhanced tooltips (requires reload)"]))
            end
        end
    end

    local function Tooltip_SetUnit()
        if TooltipDB.unit and inCombat then
            GameTooltip:Hide()
        end
    end

    local function Tooltip_SetAction()
        if TooltipDB.spell and inCombat then
            GameTooltip:Hide()
        end
    end

    local function Tooltip_SetPetAction()
        if TooltipDB.petspell and inCombat then
            GameTooltip:Hide()
        end
    end

    local function Tooltip_SetShapeshift()
        if TooltipDB.class and inCombat then
            GameTooltip:Hide()
        end
    end

    -- change game tooltip position
    local function Tooltip_ChangePosition(tooltip, parent)
        if TooltipDB.move then
            tooltip:SetOwner(parent, "ANCHOR_NONE")
            tooltip:SetPoint("TOP", UIParent, "TOP", 0, -25)
            tooltip.default = 1
        end
    end

    function E:ADDON_LOADED(name)
        self:UnregisterEvent("ADDON_LOADED")
        if name ~= addonName then return end

        if next(TooltipDB) == nil then
            TooltipDB = defaults
        end

        SlashCmdList["KPACK_TOOLTIP"] = SlashCommandHandler
        SLASH_KPACK_TOOLTIP1 = "/tip"
        SLASH_KPACK_TOOLTIP2 = "/tooltip"

        hooksecurefunc(GameTooltip, "SetUnit", Tooltip_SetUnit)
        hooksecurefunc(GameTooltip, "SetAction", Tooltip_SetAction)
        hooksecurefunc(GameTooltip, "SetPetAction", Tooltip_SetPetAction)
        hooksecurefunc(GameTooltip, "SetShapeshift", Tooltip_SetShapeshift)
        hooksecurefunc("GameTooltip_SetDefaultAnchor", Tooltip_ChangePosition)
    end
end

-- ///////////////////////////////////////////////////////
do
    local backdrop = {
        bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
        edgeFile = [[Interface\ChatFrame\ChatFrameBackground]],
        edgeSize = 1,
        insets = {top = 0, left = 0, bottom = 0, right = 0}
    }

    local types = {
        rare = " R ",
        elite = " + ",
        worldboss = " B ",
        rareelite = " R+ "
    }

    local classColors = {
        DEATHKNIGHT = "c41f3b",
        DRUID = "ff7d0a",
        HUNTER = "a9d271",
        MAGE = "40c7eb",
        PALADIN = "f58cba",
        PRIEST = "ffffff",
        ROGUE = "fff569",
        SHAMAN = "0070de",
        WARLOCK = "8787ed",
        WARRIOR = "c79c6e"
    }

    -- hooked to tooltips OnShow event
    local function Tooltip_OnShow(self)
        self:SetBackdropColor(0, 0, 0, 0.6)
        local item = self.GetItem and select(2, self:GetItem()) or nil
        if item then
            local quality = select(3, GetItemInfo(item))
            if quality and quality > 1 then
                local r, g, b = GetItemQualityColor(quality)
                self:SetBackdropBorderColor(r, g, b)
            end
        else
            self:SetBackdropBorderColor(0, 0, 0)
        end
    end

    -- hooked to tooltips OnHide event
    local function Tooltip_OnHide(self)
        self:SetBackdropBorderColor(0, 0, 0, 1)
    end

    local Tooltip_OnTooltipSetUnit
    local Tooltip_StatusBarOnValueChanged
    do
        -- converts RGB to HEX
        local Tooltip_Hex = function(r, g, b)
            return ("|cff%02x%02x%02x"):format(r * 255, g * 255, b * 255)
        end

        -- format health for better display
        local Tooltip_Truncate = function(value)
            if value >= 1e6 then
                return format("%.2fm", value / 1e6)
            elseif value >= 1e4 then
                return format("%.1fk", value / 1e3)
            else
                return format("%.0f", value)
            end
        end

        -- returns the proper unit color
        local function Tooltip_UnitColor(unit)
            local r, g, b = 1, 1, 1
            if UnitPlayerControlled(unit) then
                if UnitCanAttack(unit, "player") then
                    if UnitCanAttack("player", unit) then
                        r = FACTION_BAR_COLORS[2].r
                        g = FACTION_BAR_COLORS[2].g
                        b = FACTION_BAR_COLORS[2].b
                    end
                elseif UnitCanAttack("player", unit) then
                    r = FACTION_BAR_COLORS[4].r
                    g = FACTION_BAR_COLORS[4].g
                    b = FACTION_BAR_COLORS[4].b
                elseif UnitIsPVP(unit) then
                    r = FACTION_BAR_COLORS[6].r
                    g = FACTION_BAR_COLORS[6].g
                    b = FACTION_BAR_COLORS[6].b
                end
            else
                local reaction = UnitReaction(unit, "player")
                if reaction then
                    r = FACTION_BAR_COLORS[reaction].r
                    g = FACTION_BAR_COLORS[reaction].g
                    b = FACTION_BAR_COLORS[reaction].b
                end
            end

            if UnitIsPlayer(unit) then
                local class = select(2, UnitClass(unit))
                if class then
                    r = RAID_CLASS_COLORS[class].r
                    g = RAID_CLASS_COLORS[class].g
                    b = RAID_CLASS_COLORS[class].b
                end
            end

            return r, g, b
        end

        -- hooked to OnTooltipSetUnit to add our enhancement
        function Tooltip_OnTooltipSetUnit(self)
            local unit = select(2, self:GetUnit())
            if unit then
                local unitClassification = types[UnitClassification(unit)] or " "
                local diffColor = GetQuestDifficultyColor(UnitLevel(unit))
                local creatureType = UnitCreatureType(unit) or ""
                local unitName = UnitName(unit)
                local unitLevel = UnitLevel(unit)
                if unitLevel < 0 then
                    unitLevel = "??"
                end

                if UnitIsPlayer(unit) then
                    local unitRace = UnitRace(unit)
                    local unitClass, classFile = UnitClass(unit)
                    local guild, rank = GetGuildInfo(unit)
                    local playerGuild = GetGuildInfo("player")
                    if guild then
                        GameTooltipTextLeft2:SetFormattedText("%s |cffffffff(%s)|r", guild, rank)
                        if IsInGuild() and guild == playerGuild then
                            GameTooltipTextLeft2:SetTextColor(0.7, 0.5, 0.8)
                        else
                            GameTooltipTextLeft2:SetTextColor(0.35, 1, 0.6)
                        end
                    end

                    for i = 2, GameTooltip:NumLines() do
                        if _G["GameTooltipTextLeft" .. i] and _G["GameTooltipTextLeft" .. i].GetText and _G["GameTooltipTextLeft" .. i]:GetText():find(PLAYER) then
                            local str = LEVEL .. " %s%s|r %s |cff%s%s|r"
                            _G["GameTooltipTextLeft" .. i]:SetText(str:format(Tooltip_Hex(diffColor.r, diffColor.g, diffColor.b), unitLevel, unitRace, classColors[classFile], unitClass))
                            break
                        end
                    end
                else
                    for i = 2, GameTooltip:NumLines() do
                        if _G["GameTooltipTextLeft" .. i]:GetText():find(LEVEL) or _G["GameTooltipTextLeft" .. i]:GetText():find(creatureType) then
                            _G["GameTooltipTextLeft" .. i]:SetText(format(Tooltip_Hex(diffColor.r, diffColor.g, diffColor.b) .. "%s|r", unitLevel) .. unitClassification .. creatureType)
                            break
                        end
                    end
                end

                if UnitIsPVP(unit) then
                    for i = 2, GameTooltip:NumLines() do
                        if _G["GameTooltipTextLeft" .. i] and _G["GameTooltipTextLeft" .. i]:GetText():find(PVP) then
                            _G["GameTooltipTextLeft" .. i]:SetText(nil)
                            break
                        end
                    end
                end

                if UnitExists(unit .. "target") then
                    local r, g, b = Tooltip_UnitColor(unit .. "target")
                    if UnitName(unit .. "target") == UnitName("player") then
                        text = Tooltip_Hex(1, 0, 0) .. "<" .. UNIT_YOU .. ">|r"
                    else
                        text = Tooltip_Hex(r, g, b) .. UnitName(unit .. "target") .. "|r"
                    end
                    self:AddLine(TARGET .. ": " .. text)
                end
            end
        end

        function Tooltip_StatusBarOnValueChanged(self, value)
            if not value then
                return
            end

            local min, max = self:GetMinMaxValues()
            if value < min or value > max then
                return
            end

            local unit = select(2, GameTooltip:GetUnit())
            if unit then
                min, max = UnitHealth(unit), UnitHealthMax(unit)
                if not self.text then
                    self.text = self:CreateFontString(nil, "OVERLAY")
                    self.text:SetPoint("CENTER", GameTooltipStatusBar)
                    self.text:SetFont(GameFontNormal:GetFont(), 11, "THINOUTLINE")
                end
                self.text:Show()
                local hp = Tooltip_Truncate(min) .. " / " .. Tooltip_Truncate(max)
                self.text:SetText(hp)
            else
                if self.text then
                    self.text:Hide()
                end
            end
        end
    end

    -- hooked to SetItemRef
    local function Tooltip_SetItemRef(link, text, button)
        if not iconFrame then
            return
        end

        if iconFrame:IsShown() then
            iconFrame:Hide()
        end

        local t, id = match(link, "(%l+):(%d+)")
        if t == "item" then
            iconFrame.icon:SetTexture(select(10, GetItemInfo(id)))
            iconFrame:Show()
        elseif t == "spell" then
            iconFrame.icon:SetTexture(select(3, GetSpellInfo(id)))
            iconFrame:Show()
        elseif t == "achievement" then
            iconFrame.icon:SetTexture(select(10, GetAchievementInfo(id)))
            iconFrame:Show()
        end
    end

    function E:PLAYER_ENTERING_WORLD()
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        if _G.Aurora then
            return
        end

        if not TooltipDB.enhance then
            return
        end

        local tooltips = {
            GameTooltip,
            ItemRefTooltip,
            ShoppingTooltip2,
            ShoppingTooltip3,
            WorldMapTooltip,
            DropDownList1MenuBackdrop,
            DropDownList2MenuBackdrop,
            _G.L_DropDownList1MenuBackdrop,
            _G.L_DropDownList2MenuBackdrop
        }

        for _, t in pairs(tooltips) do
            if t then
                t:SetBackdrop(backdrop)
                t:SetBackdropColor(0, 0, 0, 0.6)
                t:SetBackdropBorderColor(0, 0, 0, 1)
                t:SetScale(TooltipDB.scale or 1)
                t:SetScript("OnShow", Tooltip_OnShow)
                t:HookScript("OnHide", Tooltip_OnHide)
            end
        end

        -- hook our custom function to change the look
        GameTooltip:HookScript("OnTooltipSetUnit", Tooltip_OnTooltipSetUnit)

        -- add target health and max health
        GameTooltipStatusBar.bg = CreateFrame("Frame", nil, GameTooltipStatusBar)
        GameTooltipStatusBar.bg:SetPoint("TOPLEFT", GameTooltipStatusBar, "TOPLEFT", -1, 1)
        GameTooltipStatusBar.bg:SetPoint("BOTTOMRIGHT", GameTooltipStatusBar, "BOTTOMRIGHT", 1, -1)
        GameTooltipStatusBar.bg:SetFrameStrata("LOW")
        GameTooltipStatusBar.bg:SetBackdrop(backdrop)
        GameTooltipStatusBar.bg:SetBackdropColor(0, 0, 0, 0.5)
        GameTooltipStatusBar.bg:SetBackdropBorderColor(0, 0, 0, 1)
        GameTooltipStatusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        GameTooltipStatusBar:ClearAllPoints()
        GameTooltipStatusBar:SetPoint("TOPLEFT", GameTooltip, "BOTTOMLEFT", 1, 0)
        GameTooltipStatusBar:SetPoint("TOPRIGHT", GameTooltip, "BOTTOMRIGHT", -1, 0)
        GameTooltipStatusBar:HookScript("OnValueChanged", Tooltip_StatusBarOnValueChanged)

        -- add item icon to tooltip
        iconFrame = iconFrame or CreateFrame("Frame", nil, ItemRefTooltip)
        iconFrame:SetWidth(30)
        iconFrame:SetHeight(30)
        iconFrame:SetPoint("TOPRIGHT", ItemRefTooltip, "TOPLEFT", -3, 0)
        iconFrame:SetBackdrop(backdrop)
        iconFrame:SetBackdropColor(0, 0, 0, 0.5)
        iconFrame:SetBackdropBorderColor(0, 0, 0, 1)
        iconFrame.icon = iconFrame:CreateTexture(nil, "BACKGROUND")
        iconFrame.icon:SetPoint("TOPLEFT", 1, -1)
        iconFrame.icon:SetPoint("BOTTOMRIGHT", -1, 1)
        iconFrame.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

        hooksecurefunc("SetItemRef", Tooltip_SetItemRef)
    end
end

function E:UPDATE_MOUSEOVER_UNIT()
    if TooltipDB.unit and inCombat then
        GameTooltip:Hide()
    end
end

function E:PLAYER_REGEN_ENABLED()
    inCombat = false
end

function E:PLAYER_REGEN_DISABLED()
    inCombat = true
end