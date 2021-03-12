local addonName, addon = ...
local L = addon.L

-- SavedVariables
NameplatesDB = true

-- ::::::::::::::::::::::::: START of Configuration ::::::::::::::::::::::::: --

local config = {
    -- bar config
    barWidth = 120, -- nameplate width
    barHeight = 12, -- health and cast bars height
    barTexture = [[Interface\Addons\KPack\Media\Textures\statusbar]],
    glowTexture = [[Interface\AddOns\KPack\Media\Textures\glowTex]],

    -- font config
    font = [[Interface\Addons\KPack\Media\Fonts\yanone.ttf]], -- path to the font used for all texts
    fontSize = 11, -- obviously, the font size
    fontOutline = "THINOUTLINE", -- the font outline

    -- Health text config:
    showHealthText = false, -- whether to show the hp left text
    showHealthPercent = false, -- show percentage or not
    shortenNumbers = false, -- whether to shorten numbers

    -- positions of health text and percent
    hpTextPos = {"LEFT", -3, 1},
    hpPercentPos = {"CENTER", 0, 1}
}

-- Non-Latin Font Bypass
-- if you are using a non-latin client, except russian,
-- you can here set your custom font to be used.
-- Just make sure to use a proper path to that file.
local nonLatinLocales = {koKR = true, zhCN = true, zhTW = true}
if nonLatinLocales[GetLocale()] then
    config.font = NAMEPLATE_FONT -- here goes the path
end

-- here you can change the fonts of health text and percet
-- Options are: {fontpath, fontsize, fontflags}
config.hpTextFont = {config.font, config.fontSize, config.fontOutline}
config.hpPercentFont = {config.font, config.fontSize, config.fontOutline}

-- :::::::::::::::::::::::::: END of Configuration ::::::::::::::::::::::::: --

local backdrop = {
    edgeFile = config.glowTexture,
    edgeSize = 5,
    insets = {left = 3, right = 2, top = 3, bottom = 2}
}

local _type, _select = type, select
local _format = string.format
local math_max = math.max
local math_floor = math.floor
local unpack = unpack
local UnitExists = UnitExists
local targetExists

-- events frame
local mod = CreateFrame("Frame")
mod:RegisterEvent("ADDON_LOADED")
mod:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
addon.NP = config

-- module's print function
local function Print(msg)
    if msg then
        addon:Print(msg, "Nameplates")
    end
end

-- :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

-- makes sure the frame is a valid one
local function NameplateIsValid(frame)
    if frame:GetName() then
        return
    end
    local overlayRegion = _select(2, frame:GetRegions())
    return (overlayRegion and overlayRegion:GetObjectType() == "Texture" and overlayRegion:GetTexture() == [[Interface\Tooltips\Nameplate-Border]])
end

-- format the text of the health
local Nameplate_FormatHealthText
do
    local function Nameplate_Shorten(num)
        local res
        if num > 1000000000 then
            res = format("%02.3fB", num / 1000000000)
        elseif num > 1000000 then
            res = format("%02.2fM", num / 1000000)
        elseif num > 1000 then
            res = format("%02.1fK", num / 1000)
        else
            res = math_floor(num)
        end
        return res
    end

    function Nameplate_FormatHealthText(self)
        if not self or not self.healthBar then
            return
        end
        if config.showHealthText or config.showHealthPercent then
            local minval, maxval = self.healthBar:GetMinMaxValues()
            local curval = self.healthBar:GetValue()

            if config.showHealthText then
                self.hpText:SetText(config.shortenNumbers and Nameplate_Shorten(curval) or curval)
                self.hpText:Show()
            else
                self.hpText:Hide()
            end

            if config.showHealthPercent then
                self.hpPercent:SetText(_format("%02.1f%%", 100 * curval / math_max(1, maxval)))
                self.hpPercent:Show()
            else
                self.hpPercent:Hide()
            end
        end
    end
end

-- nameplate OnUpdate
local function Nameplate_OnUpdate(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed >= 0.01 then
        self:FormatHealthText()

        if targetExists and self:GetAlpha() == 1 then
            self.healthBar:SetWidth(config.barWidth * 1.15)
            self.castBar:SetWidth(config.barWidth * 1.15)
            self.leftIndicator:Show()
            self.rightIndicator:Show()
        else
            self.healthBar:SetWidth(config.barWidth)
            self.castBar:SetWidth(config.barWidth)
            self.leftIndicator:Hide()
            self.rightIndicator:Hide()
        end

        self.elapsed = 0
    end
end

-- handles frame's show
local function Nameplate_OnShow(self)
    self.healthBar:ClearAllPoints()
    self.healthBar:SetPoint("CENTER", self.healthBar:GetParent())
    self.healthBar:SetWidth(config.barWidth)
    self.healthBar:SetHeight(config.barHeight)

    self.castBar:ClearAllPoints()
    self.castBar:SetPoint("TOP", self.healthBar, "BOTTOM", 0, -4)
    self.castBar:SetWidth(config.barWidth)
    self.castBar:SetHeight(config.barHeight)

    self.highlight:ClearAllPoints()
    self.highlight:SetAllPoints(self.healthBar)

    self.name:SetJustifyH("LEFT")
    self.name:SetText(self.oldname:GetText())
    self.name:SetPoint("BOTTOMLEFT", self.healthBar, "TOPLEFT", 0, 3)
    self.name:SetPoint("RIGHT", self.healthBar, -15, 3)

    local level, elite = tonumber(self.level:GetText()), self.elite:IsShown()
    self.level:SetJustifyH("RIGHT")
    self.level:ClearAllPoints()
    self.level:SetPoint("BOTTOMRIGHT", self.healthBar, "TOPRIGHT", 3, 3)
    if self.boss:IsShown() then
        self.level:SetText("B")
        self.level:SetTextColor(0.8, 0.05, 0)
    elseif elite then
        self.level:SetText(level .. (elite and "+" or ""))
    end
    self.level:Show()
end

-- handles casting time update
local function CastBar_UpdateTime(self, curval)
    local minval, maxval = self:GetMinMaxValues()
    if self.channeling then
        self.time:SetFormattedText("%.1f", curval)
    else
        self.time:SetFormattedText("%.1f", maxval - curval)
    end
end

-- simply fixes the casting bar
local function CastBar_Fix(self)
    self.castbarOverlay:Hide()

    self:SetHeight(5)
    self:ClearAllPoints()
    self:SetPoint("TOP", self.healthBar, "BOTTOM", 0, -4)
end

-- colorize the casting bar
local function CastBar_Colorize(self, shielded)
    if shielded then
        self:SetStatusBarColor(0.8, 0.05, 0)
    end
end

local function CastBar_OnSizeChanged(self)
    self.needFix = true
end

local function CastBar_OnValueChanged(self, curval)
    CastBar_UpdateTime(self, curval)
    if self.needFix then
        CastBar_Fix(self)
        self.needFix = nil
    end
end

local function CastBar_OnShow(self)
    self.channeling = UnitChannelInfo("target")
    CastBar_Fix(self)
    CastBar_Colorize(self, self.shieldedRegion:IsShown())
end

-- handles colorizing the casting bar
local function CastBar_OnEvent(self, event, unit)
    if unit == "target" then
        if self:IsShown() then
            CastBar_Colorize(self, event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
        end
    end
end

local function Nameplate_OnHide(self)
    self.highlight:Hide()
end

-- creates the frame
local function Nameplate_Create(frame)
    if frame.done then
        return
    end
    frame.done = true

    local healthBar, castBar = frame:GetChildren()
    frame.healthBar, frame.castBar = healthBar, castBar

    local glowRegion, overlayRegion, castbarOverlay, shieldedRegion, spellIconRegion, highlightRegion, nameTextRegion, levelTextRegion, bossIconRegion, raidIconRegion, stateIconRegion = frame:GetRegions()
    frame.oldname = nameTextRegion
    nameTextRegion:Hide()

    local name = frame:CreateFontString()
    name:SetPoint("BOTTOM", healthBar, "TOP", 0, 1)
    name:SetFont(config.font, config.fontSize, config.fontOutline)
    name:SetTextColor(0.84, 0.75, 0.65)
    name:SetShadowOffset(1.25, -1.25)
    name:SetJustifyH("LEFT")
    name:SetJustifyV("BOTTOM")
    frame.name = name

    levelTextRegion:SetFont(config.font, config.fontSize, config.fontOutline)
    levelTextRegion:SetShadowOffset(1.25, -1.25)
    levelTextRegion:SetJustifyH("RIGHT")
    levelTextRegion:SetJustifyV("BOTTOM")
    frame.level = levelTextRegion

    healthBar:SetStatusBarTexture(config.barTexture)
    healthBar.hpBackground = healthBar:CreateTexture(nil, "BORDER")
    healthBar.hpBackground:SetAllPoints(healthBar)
    healthBar.hpBackground:SetTexture(config.barTexture)
    healthBar.hpBackground:SetVertexColor(0.15, 0.15, 0.15)

    healthBar.hpGlow = CreateFrame("Frame", nil, healthBar)
    healthBar.hpGlow:SetPoint("TOPLEFT", healthBar, "TOPLEFT", -4.5, 4)
    healthBar.hpGlow:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", 4.5, -4.5)
    healthBar.hpGlow:SetBackdrop(backdrop)
    healthBar.hpGlow:SetBackdropColor(0, 0, 0)
    healthBar.hpGlow:SetBackdropBorderColor(0, 0, 0, 1)

    local hp = CreateFrame("Frame", nil, frame.healthBar)
    hp:SetHeight(config.barHeight)
    hp:SetPoint(unpack(config.hpTextPos))
    hp:SetFrameLevel(healthBar.hpGlow:GetFrameLevel() + 1)
    hp.text = hp:CreateFontString(nil, "OVERLAY")
    hp.text:SetPoint("CENTER")
    hp.text:SetFont(unpack(config.hpTextFont))
    hp.text:SetTextColor(0.84, 0.75, 0.65)
    hp.text:SetShadowOffset(1.25, -1.25)
    hp.text:SetJustifyH("CENTER")
    hp.text:SetJustifyV("MIDDLE")
    hp.text:Hide()
    frame.hpText = hp.text

    local percent = CreateFrame("Frame", nil, frame.healthBar)
    percent:SetHeight(config.barHeight)
    percent:SetPoint(unpack(config.hpPercentPos))
    percent:SetFrameLevel(healthBar.hpGlow:GetFrameLevel() + 1)
    percent.text = percent:CreateFontString(nil, "OVERLAY")
    percent.text:SetPoint("CENTER")
    percent.text:SetFont(unpack(config.hpPercentFont))
    percent.text:SetTextColor(0.84, 0.75, 0.65)
    percent.text:SetShadowOffset(1.25, -1.25)
    percent.text:SetJustifyH("CENTER")
    percent.text:SetJustifyV("MIDDLE")
    percent.text:Hide()
    frame.hpPercent = percent.text

    frame.FormatHealthText = Nameplate_FormatHealthText
    frame:FormatHealthText()
    hp:SetWidth(hp.text:GetWidth())
    percent:SetWidth(percent.text:GetWidth())

    castBar.castbarOverlay = castbarOverlay
    castBar.healthBar = healthBar
    castBar.shieldedRegion = shieldedRegion
    castBar:SetStatusBarTexture(config.barTexture)

    castBar:HookScript("OnShow", CastBar_OnShow)
    castBar:HookScript("OnSizeChanged", CastBar_OnSizeChanged)
    castBar:HookScript("OnValueChanged", CastBar_OnValueChanged)
    castBar:HookScript("OnEvent", CastBar_OnEvent)
    castBar:RegisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
    castBar:RegisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")

    castBar.time = castBar:CreateFontString(nil, "ARTWORK")
    castBar.time:SetPoint("RIGHT", castBar, "LEFT", -2, 1)
    castBar.time:SetFont(config.font, config.fontSize, config.fontOutline)
    castBar.time:SetTextColor(0.84, 0.75, 0.65)
    castBar.time:SetShadowOffset(1.25, -1.25)

    castBar.cbBackground = castBar:CreateTexture(nil, "BORDER")
    castBar.cbBackground:SetAllPoints(castBar)
    castBar.cbBackground:SetTexture(config.barTexture)
    castBar.cbBackground:SetVertexColor(0.15, 0.15, 0.15)

    castBar.cbGlow = CreateFrame("Frame", nil, castBar)
    castBar.cbGlow:SetPoint("TOPLEFT", castBar, "TOPLEFT", -4.5, 4)
    castBar.cbGlow:SetPoint("BOTTOMRIGHT", castBar, "BOTTOMRIGHT", 4.5, -4.5)
    castBar.cbGlow:SetBackdrop(backdrop)
    castBar.cbGlow:SetBackdropColor(0, 0, 0)
    castBar.cbGlow:SetBackdropBorderColor(0, 0, 0)

    spellIconRegion:SetHeight(0.01)
    spellIconRegion:SetWidth(0.01)

    highlightRegion:SetTexture(config.barTexture)
    highlightRegion:SetVertexColor(0.25, 0.25, 0.25)
    frame.highlight = highlightRegion

    raidIconRegion:ClearAllPoints()
    raidIconRegion:SetPoint("LEFT", healthBar, "RIGHT", 2, 0)
    raidIconRegion:SetHeight(15)
    raidIconRegion:SetWidth(15)

    frame.oldglow = glowRegion
    frame.elite = stateIconRegion
    frame.boss = bossIconRegion

    glowRegion:SetTexture(nil)
    overlayRegion:SetTexture(nil)
    shieldedRegion:SetTexture(nil)
    castbarOverlay:SetTexture(nil)
    stateIconRegion:SetTexture(nil)
    bossIconRegion:SetTexture(nil)

    local right = frame:CreateTexture(nil, "BACKGROUND")
    right:SetTexture([[Interface\Addons\Nameplates\arrow]])
    right:SetPoint("LEFT", frame.healthBar, "RIGHT", -3, 0)
    right:SetRotation(1.57)
    right:Hide()
    frame.rightIndicator = right

    local left = frame:CreateTexture(nil, "BACKGROUND")
    left:SetTexture([[Interface\Addons\Nameplates\arrow]])
    left:SetPoint("RIGHT", frame.healthBar, "LEFT", 3, 0)
    left:SetRotation(-1.57)
    left:Hide()
    frame.leftIndicator = left

    frame:SetScript("OnShow", Nameplate_OnShow)
    frame:SetScript("OnHide", Nameplate_OnHide)
    Nameplate_OnShow(frame)

    frame:SetScript("OnUpdate", Nameplate_OnUpdate)
end

-- :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

local SlashCommandHandler
do
    local commands = {}
    local help = "|cffffd700%s|r: %s"

    commands.enable = function()
        NameplatesDB = true
        Print(L:F("module status: %s", L["|cff00ff00enabled|r"]))
    end
    commands.on = commands.enable

    commands.disable = function()
        NameplatesDB = false
        Print(L:F("module status: %s", L["|cffff0000disabled|r"]))
    end
    commands.off = commands.disable

    function SlashCommandHandler(cmd)
        cmd = cmd and cmd:lower() or ""

        if _type(commands[cmd]) == "function" then
            commands[cmd]()
            ReloadUI()
        else
            Print(L:F("Acceptable commands for: |caaf49141%s|r", "/np"))
            print(_format(help, "enable", L["enable module"]))
            print(_format(help, "disable", L["disable module"]))
        end
    end
end

function mod:ADDON_LOADED(name)
    if name ~= addonName then
        return
    end
    self:UnregisterEvent("ADDON_LOADED")
    if NameplatesDB == nil then
        NameplatesDB = false
    end

    SlashCmdList["KPACKNAMEPLATES"] = SlashCommandHandler
    _G.SLASH_KPACKNAMEPLATES1 = "/np"
    _G.SLASH_KPACKNAMEPLATES2 = "/nameplates"

    self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

do
    -- nameplates OnUpdate handler
    local lastUpdate = 0
    local function Nameplates_OnUpdate(self, elapsed)
        lastUpdate = lastUpdate + elapsed

        if lastUpdate > 0.1 then
            lastUpdate = 0
            for i = 1, _select("#", WorldFrame:GetChildren()) do
                local frame = _select(i, WorldFrame:GetChildren())
                if NameplateIsValid(frame) and not frame.done then
                    Nameplate_Create(frame)
                end
            end
        end
    end

    -- on mod loaded.
    function mod:PLAYER_ENTERING_WORLD()
        for _, name in ipairs({"TidyPlates", "KuiNameplates"}) do
            if _G[name] then
                return
            end
        end

        if NameplatesDB then
            self:RegisterEvent("PLAYER_TARGET_CHANGED")
            self:SetScript("OnUpdate", Nameplates_OnUpdate)
        else
            self:UnregisterEvent("PLAYER_TARGET_CHANGED")
            self:SetScript("OnUpdate", nil)
        end
    end
end

function mod:PLAYER_TARGET_CHANGED()
    targetExists = UnitExists("target")
end