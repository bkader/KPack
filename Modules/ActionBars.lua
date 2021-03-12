local addonName, addon = ...
local L = addon.L
local mod = addon.ActionBars
if not mod then
  mod = CreateFrame("Frame")
  addon.ActionBars = mod
end

local _LoadAddOn = LoadAddOn
local _IsActionInRange = IsActionInRange
local _InCombatLockdown = InCombatLockdown
local _UnitAffectingCombat = UnitAffectingCombat
local _hooksecurefunc = hooksecurefunc
local _UnitInVehicle = UnitInVehicle

local _UnitLevel = UnitLevel
local _IsXPUserDisabled = IsXPUserDisabled
local _GetWatchedFactionInfo = GetWatchedFactionInfo
local _TextStatusBar_UpdateTextString = TextStatusBar_UpdateTextString
local _MainMenuExpBar_Update = MainMenuExpBar_Update
local _UIParent_ManageFramePositions = UIParent_ManageFramePositions

local _pairs, _ipairs, _type, _next = pairs, ipairs, type, next
local _format, _match, _tostring, _tonumber = string.format, string.match, tostring, tonumber
local math_min, math__max, _select = math.min, math.max, select
local _SetCVar, _GetCVar = SetCVar, GetCVar

ActionBarsDB = {}
local defaults = {
  scale = 1,
  dark = false,
  perfect = false,
  range = true,
  art = true,
  hotkeys = 1,
  moved = false,
  hover = false,
}
local disabled

mod:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
mod:RegisterEvent("ADDON_LOADED")
mod:RegisterEvent("PLAYER_LOGIN")

-- module's print function
local function Print(msg)
  if msg then
    addon:Print(msg, "ActionBars")
  end
end

-- used to kill functions
local function noFunc() return end

-- utility functions used to show/hide a frame only if it exists
local function Show(frame)
  if frame and frame.Show then
    frame:Show()
  end
end
local function Hide(frame)
  if frame and frame.Hide then
    frame:Hide()
  end
end
local function ShowHide(frame, cond)
  if not frame or not frame.Show then
    return
  elseif cond and not frame:IsShown() then
    frame:Show()
  elseif not cond and frame:IsShown() then
    frame:Hide()
  end
end

--
-- scales action bar elements
--
local function ActionBars_ScaleBars(scale)
  scale = scale or ActionBarsDB.scale or 1
  _G.MainMenuBar:SetScale(scale)
  _G.MultiBarBottomLeft:SetScale(scale)
  _G.MultiBarBottomRight:SetScale(scale)
  _G.MultiBarRight:SetScale(scale)
  _G.MultiBarLeft:SetScale(scale)
  _G.VehicleMenuBar:SetScale(scale)
end

--
-- Dark mode
--
local function ActionBars_DarkMode()
  local vertex = ActionBarsDB.dark and 0.32 or 1.00
  for i, v in pairs({
    -- UnitFrames
    PlayerFrameTexture,
    TargetFrameTextureFrameTexture,
    PetFrameTexture,
    PartyMemberFrame1Texture,
    PartyMemberFrame2Texture,
    PartyMemberFrame3Texture,
    PartyMemberFrame4Texture,
    PartyMemberFrame1PetFrameTexture,
    PartyMemberFrame2PetFrameTexture,
    PartyMemberFrame3PetFrameTexture,
    PartyMemberFrame4PetFrameTexture,
    FocusFrameTextureFrameTexture,
    TargetFrameToTTextureFrameTexture,
    FocusFrameToTTextureFrameTexture,
    Boss1TargetFrameTextureFrameTexture,
    Boss2TargetFrameTextureFrameTexture,
    Boss3TargetFrameTextureFrameTexture,
    Boss4TargetFrameTextureFrameTexture,
    Boss5TargetFrameTextureFrameTexture,
    Boss1TargetFrameSpellBarBorder,
    Boss2TargetFrameSpellBarBorder,
    Boss3TargetFrameSpellBarBorder,
    Boss4TargetFrameSpellBarBorder,
    Boss5TargetFrameSpellBarBorder,
    RuneButtonIndividual1BorderTexture,
    RuneButtonIndividual2BorderTexture,
    RuneButtonIndividual3BorderTexture,
    RuneButtonIndividual4BorderTexture,
    RuneButtonIndividual5BorderTexture,
    RuneButtonIndividual6BorderTexture,
    CastingBarFrameBorder,
    FocusFrameSpellBarBorder,
    TargetFrameSpellBarBorder,
    -- MainMenuBar
    SlidingActionBarTexture0,
    SlidingActionBarTexture1,
    BonusActionBarTexture0,
    BonusActionBarTexture1,
    BonusActionBarTexture,
    MainMenuBarTexture0,
    MainMenuBarTexture1,
    MainMenuBarTexture2,
    MainMenuBarTexture3,
    MainMenuMaxLevelBar0,
    MainMenuMaxLevelBar1,
    MainMenuMaxLevelBar2,
    MainMenuMaxLevelBar3,
    MainMenuXPBarTextureLeftCap,
    MainMenuXPBarTextureRightCap,
    MainMenuXPBarTextureMid,
    ReputationWatchBarTexture0,
    ReputationWatchBarTexture1,
    ReputationWatchBarTexture2,
    ReputationWatchBarTexture3,
    ReputationXPBarTexture0,
    ReputationXPBarTexture1,
    ReputationXPBarTexture2,
    ReputationXPBarTexture3,
    MainMenuBarLeftEndCap,
    MainMenuBarRightEndCap,
    StanceBarLeft,
    StanceBarMiddle,
    StanceBarRight,
    -- ArenaFrames
    -- ActionBarUpButton:GetNormalTexture(),
    -- ActionBarUpButton:GetPushedTexture(),
    -- ActionBarUpButton:GetHighlightTexture(),
    -- ActionBarDownButton:GetNormalTexture(),
    -- ActionBarDownButton:GetPushedTexture(),
    -- ActionBarDownButton:GetHighlightTexture(),
    ShapeshiftBarLeft,
    ShapeshiftBarMiddle,
    ShapeshiftBarRight,
    ArenaEnemyFrame1Texture,
    ArenaEnemyFrame2Texture,
    ArenaEnemyFrame3Texture,
    ArenaEnemyFrame4Texture,
    ArenaEnemyFrame5Texture,
    ArenaEnemyFrame1SpecBorder,
    ArenaEnemyFrame2SpecBorder,
    ArenaEnemyFrame3SpecBorder,
    ArenaEnemyFrame4SpecBorder,
    ArenaEnemyFrame5SpecBorder,
    ArenaEnemyFrame1PetFrameTexture,
    ArenaEnemyFrame2PetFrameTexture,
    ArenaEnemyFrame3PetFrameTexture,
    ArenaEnemyFrame4PetFrameTexture,
    ArenaEnemyFrame5PetFrameTexture,
    ArenaPrepFrame1Texture,
    ArenaPrepFrame2Texture,
    ArenaPrepFrame3Texture,
    ArenaPrepFrame4Texture,
    ArenaPrepFrame5Texture,
    ArenaPrepFrame1SpecBorder,
    ArenaPrepFrame2SpecBorder,
    ArenaPrepFrame3SpecBorder,
    ArenaPrepFrame4SpecBorder,
    ArenaPrepFrame5SpecBorder,
    -- PANES
    CharacterFrameTitleBg,
    CharacterFrameBg,
    -- MINIMAP
    MinimapBorder,
    MinimapBorderTop,
    MiniMapTrackingButtonBorder
  }) do
    v:SetVertexColor(vertex, vertex, vertex)
  end
end

--
-- pixel perfect mode
--
local _GetScreenResolutions, _GetCurrentResolution = GetScreenResolutions, GetCurrentResolution
local function ActionBars_PixelPerfect()
  if ActionBarsDB.perfect and not _InCombatLockdown() and not _UnitAffectingCombat("player") then
    local scale = math_min(2, math__max(0.20, 768/_match(({_GetScreenResolutions()})[_GetCurrentResolution()], "%d+x(%d+)")))
    if scale < 0.64 then
      UIParent:SetScale(scale)
    else
      _SetCVar("uiScale", scale)
    end
  end
end

--
-- turns button red if target out of range
--
local ActionBars_Range
do
  local function KPackActionButton_OnEvent(self, event, ...)
    if event == "PLAYER_TARGET_CHANGED" then
      self.newTimer = self.rangeTimer
    end
  end

  local function KPackActionButton_UpdateUsable(self)
    local icon = _G[self:GetName() .. "Icon"]
    local valid = _IsActionInRange(self.action)
    if valid == 0 then icon:SetVertexColor(1.0, 0.1, 0.1) end
  end

  local function KPackActionButton_OnUpdate(self, elapsed)
    local rangeTimer = self.newTimer
    if rangeTimer then
      rangeTimer = rangeTimer - elapsed
      if rangeTimer <= 0 then
        ActionButton_UpdateUsable(self)
        rangeTimer = _G.TOOLTIP_UPDATE_TIME
      end
      self.newTimer = rangeTimer
    end
  end

  function ActionBars_Range()
    if ActionBarsDB.range == true then
      _hooksecurefunc("ActionButton_OnEvent", KPackActionButton_OnEvent)
      _hooksecurefunc("ActionButton_UpdateUsable", KPackActionButton_UpdateUsable)
      _hooksecurefunc("ActionButton_OnUpdate", KPackActionButton_OnUpdate)
    end
  end
end

--
-- handle hiding/showing action bar gryphons
--
local function ActionBars_Gryphons()
  if ActionBarsDB.art then
    _G.MainMenuBarLeftEndCap:Hide()
    _G.MainMenuBarRightEndCap:Hide()
  else
    _G.MainMenuBarLeftEndCap:Show()
    _G.MainMenuBarRightEndCap:Show()
  end
end

local function ActionBars_Hotkeys(opacity)
  opacity = opacity or ActionBarsDB.hotkeys or 1
  local mopacity = opacity/1.2 -- macro name opacity
  for i = 1, 12 do
    _G["ActionButton" .. i .. "HotKey"]:SetAlpha(opacity)
    _G["MultiBarBottomRightButton" .. i .. "HotKey"]:SetAlpha(opacity)
    _G["MultiBarBottomLeftButton" .. i .. "HotKey"]:SetAlpha(opacity)
    _G["MultiBarRightButton" .. i .. "HotKey"]:SetAlpha(opacity)
    _G["MultiBarLeftButton" .. i .. "HotKey"]:SetAlpha(opacity)

    _G["ActionButton" .. i .. "Name"]:SetAlpha(mopacity)
    _G["MultiBarBottomRightButton" .. i .. "Name"]:SetAlpha(mopacity)
    _G["MultiBarBottomLeftButton" .. i .. "Name"]:SetAlpha(mopacity)
    _G["MultiBarRightButton" .. i .. "Name"]:SetAlpha(mopacity)
    _G["MultiBarLeftButton" .. i .. "Name"]:SetAlpha(mopacity)
  end
end

--
-- moves bars around, the way we want it.
--
local function ActionBars_MoveBars()
  if not ActionBarsDB.moved then return end

  -- we move right side bar
  _G.MultiBarRight:ClearAllPoints()
  _G.MultiBarRight:SetPoint("CENTER", _G.MultiBarBottomRight, -233, -186)
  _G.MultiBarRight.SetPoint = noFunc

  -- we move left side bar
  _G.MultiBarLeft:ClearAllPoints()
  _G.MultiBarLeft:SetPoint("CENTER", _G.MultiBarBottomLeft, -233, -186)
  _G.MultiBarLeft.SetPoint = noFunc

  -- now we make sure to move buttons around to have
  -- horizontal bars instead of old vertical one.
  for _, s in _ipairs({"Left", "Right"}) do
    -- the following prefix is used later to position buttons.
    local pref = "MultiBar".._tostring(s).."Button"

    for i = 2, 12 do -- we start from 2nd button
      local btn = _G[pref.._tostring(i)]
      if btn then
        btn:ClearAllPoints()
        btn:SetPoint("LEFT", pref.._tostring(i-1), "RIGHT", 6, 0)
      end
    end
  end

  -- we move the cast bar as well.
  _G.MultiCastActionBarFrame:ClearAllPoints()
  _G.MultiCastActionBarFrame:SetPoint("BOTTOMLEFT", _G.MultiBarLeft, "TOPLEFT", 0, 5)
  _G.MultiCastActionBarFrame.SetPoint = noFunc

  -- we move the class/shapeshift bar
  _G.ShapeshiftBarFrame:ClearAllPoints()
  _G.ShapeshiftBarFrame:SetPoint("BOTTOMLEFT", _G.MultiBarLeft, "TOPLEFT", 0, 5)
  _G.ShapeshiftBarFrame.SetPoint = noFunc

  -- we move the pet bar
  _G.PetActionBarFrame:ClearAllPoints()
  _G.PetActionBarFrame:SetPoint("BOTTOMLEFT", _G.MultiBarRight, "TOPLEFT", -32, 8)
  _G.PetActionBarFrame.SetPoint = noFunc
end

--
-- mouseover right action bars
--
local ActionBars_MouseOver
do
  local function MouseOver_OnUpdate(self, elapsed)
    self.lastUpdate = self.lastUpdate + elapsed
    if self.lastUpdate > 0.5 then
      self:SetAlpha(MouseIsOver(self) and 1 or 0)
    end
  end

  function ActionBars_MouseOver()
    if ActionBarsDB.hover == true then
      for _, frame in _ipairs({MultiBarLeft, MultiBarRight}) do
        if frame:IsShown() then
          frame.lastUpdate = 0
          frame:SetScript("OnUpdate", MouseOver_OnUpdate)
        else
          frame:SetScript("OnUpdate", nil)
        end
      end
    else
      for _, frame in _ipairs({MultiBarLeft, MultiBarRight}) do
        if frame:IsShown() and frame.lastUpdate then
          frame.lastUpdate = nil
          frame:SetScript("OnUpdate", nil)
          frame:SetAlpha(1)
        end
      end
    end
  end
end

-- ========================================================== --

-- ===================== --
-- Slash command handler
-- ===================== --

local SlashCommandHandler
do
  local exec, help = {}, "|cffffd700%s|r: %s"

  exec.scale = function(num)
    num = _tonumber(num)
    if num and num >= 0.5 then
      ActionBarsDB.scale = num
      Print(L:F("action bars scale set to: |cff00ffff%s|r", num))
      ActionBars_ScaleBars(num)
    end
  end

  exec.dark = function()
    if ActionBarsDB.dark == true then
      ActionBarsDB.dark = false
      Print(L:F("dark mode: %s", L["|cffff0000OFF|r"]))
    else
      ActionBarsDB.dark = true
      Print(L:F("dark mode: %s", L["|cff00ff00ON|r"]))
    end
  end

  exec.perfect = function()
    if ActionBarsDB.perfect == true then
      ActionBarsDB.perfect = false
      Print(L:F("pixel perfect mode: %s", L["|cffff0000OFF|r"]))
    else
      ActionBarsDB.perfect = true
      Print(L:F("pixel perfect mode: %s", L["|cff00ff00ON|r"]))
    end
  end
  exec.pixel = exec.perfect

  exec.range = function()
    if ActionBarsDB.range == true then
      ActionBarsDB.range = false
      Print(L:F("range detection: %s", L["|cffff0000OFF|r"]))
    else
      ActionBarsDB.range = true
      Print(L:F("range detection: %s", L["|cff00ff00ON|r"]))
    end
  end

  exec.art = function()
    if ActionBarsDB.art == true then
      ActionBarsDB.art = false
      Print(L:F("gryphons: %s", L["|cff00ff00ON|r"]))
    else
      ActionBarsDB.art = true
      Print(L:F("gryphons: %s", L["|cffff0000OFF|r"]))
    end
  end

  exec.hotkeys = function (num)
    local onum = ActionBarsDB.hotkeys
    num = _tonumber(num)
    ActionBarsDB.hotkeys = num and num or onum
    ActionBars_Hotkeys(num)
    Print(L:F("hotkeys opacity set to: |cff00ffff%s|r", ActionBarsDB.hotkeys))
  end
  exec.opacity = exec.hotkeys

  exec.on = function()
    ActionBarsDB.moved = true
    ReloadUI()
  end

  exec.off = function()
    ActionBarsDB.moved = false
    ReloadUI()
  end

  exec.move = function()
    if ActionBarsDB.moved == true then
      exec.off()
    else
      exec.on()
    end
  end

  exec.hover = function()
    if ActionBarsDB.hover == true then
      ActionBarsDB.hover = false
      Print(L:F("mouseover right bars: %s", L["|cffff0000OFF|r"]))
    else
      ActionBarsDB.hover = true
      Print(L:F("mouseover right bars: %s", L["|cff00ff00ON|r"]))
    end
  end
  exec.mouseover = exec.hover

  exec.reset = function()
    wipe(ActionBarsDB)
    ActionBarsDB = defaults
    Print(L["addon settings reset to default."])
    if ActionBarsDB.moved then ReloadUI() end
  end
  exec.defaults = exec.reset

  exec.about = function()
    Print([[This small addon was made with big passion by |cfff58cbaKader|r from |cffffd700Novus Ordo|r, an alliance pve guild on |cff996019Warmane|r-Icecrown.
If you have suggestions or you are facing issues with my addons, feel free to message me on the forums, CurseForge or discord (|cffffd700bkader#6361|r).
]])
  end
  exec.info = exec.about

  function SlashCommandHandler(msg)
    local cmd, rest = strsplit(" ", msg, 2)
    cmd = cmd:trim()
    if rest then rest = rest:trim() end

    if _type(exec[cmd]) == "function" then
      exec[cmd](rest)
      mod:PLAYER_ENTERING_WORLD()
    else
      Print(L:F("Acceptable commands for: |caaf49141%s|r", "/abm"))
      print(_format(help, "on", L["move right action bars on top of middle ones."]))
      print(_format(help, "off", L["move right action bars to their default location."]))
      print(_format(help, "scale|r |cff00ffffn", L["scales the action bars. n between 0 and 1."]))
      print(_format(help, "dark", L["toggle dark textures mode."]))
      print(_format(help, "perfect", L["toggles pixel perfect mode."]))
      print(_format(help, "range", L["toggles bars range dectection."]))
      print(_format(help, "art", L["toggles gryphons."]))
      print(_format(help, "hotkeys|r |cff00ffffn", L["changes opacity of keybindings and macros names. n between 0 and 1."]))
      print(_format(help, "hover", L["shows right action bars on mouseover."]))
      print(_format(help, "reset", L["Resets module settings to default."]))
      print(_format(help, "info", L["Some info you might need."]))
    end
  end
end

-- ========================================================== --

function mod:ADDON_LOADED(name)
  if name ~= addonName then return end
  if _next(ActionBarsDB) == nil then
    ActionBarsDB = CopyTable(defaults)
  end

  -- register slash commands
  SlashCmdList["KPACKACTIONBATS"] = SlashCommandHandler
  _G.SLASH_KPACKACTIONBATS1 = "/abm"

end

function mod:PLAYER_LOGIN()
  -- -- if we are using an action bars addon, better skip.
  for _, n in _ipairs({"Dominos", "Bartender4", "MiniMainBar", "ElvUI", "KActionBars"}) do
    if _G[n] then
      disabled = true
      break
    end
  end
  self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function mod:PLAYER_ENTERING_WORLD()
  if not disabled then
    ActionBars_ScaleBars()
    ActionBars_PixelPerfect()
    ActionBars_Range()
    ActionBars_Gryphons()
    ActionBars_Hotkeys()
    ActionBars_MoveBars()
    ActionBars_MouseOver()
  end
  ActionBars_DarkMode()
end
