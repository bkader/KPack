local core = KPack
if not core then return end
core:AddModule("ActionBars", "Allows you to tweak your action bars in the limit of the allowed.", function(L)
	if core:IsDisabled("ActionBars") or core.ElvUI then return end
	local disabled, reason = core:AddOnIsLoaded("Dominos", "Bartender4", "MiniMainBar", "ElvUI", "KActionBars", "KkthnxUI")

	local mod = core.ActionBars or CreateFrame("Frame")
	mod:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)

	core.ActionBars = mod
	LibStub("AceHook-3.0"):Embed(mod)

	local _LoadAddOn = LoadAddOn
	local _IsActionInRange = IsActionInRange
	local _IsUsableAction = IsUsableAction
	local _InCombatLockdown = InCombatLockdown
	local _UnitAffectingCombat = UnitAffectingCombat
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

	local DB
	local defaults = {scale = 1, range = true, art = true, hotkeys = 1, hover = false}

	-- module's print function
	local function Print(msg)
		if msg then
			core:Print(msg, "ActionBars")
		end
	end

	-- used to kill functions
	local function noFunc()
		return
	end

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

	--
	-- scales action bar elements
	--
	local function ActionBars_ScaleBars(scale)
		DB = DB or core.db.ActionBars or {}
		scale = scale or DB.scale or 1
		_G.MainMenuBar:SetScale(scale)
		_G.MultiBarBottomLeft:SetScale(scale)
		_G.MultiBarBottomRight:SetScale(scale)
		_G.MultiBarRight:SetScale(scale)
		_G.MultiBarLeft:SetScale(scale)
		_G.VehicleMenuBar:SetScale(scale)
	end

	--
	-- turns button red if target out of range
	--
	local ActionBars_Range
	do
		function mod:ActionButton_OnEvent(btn, event, ...)
			if event == "PLAYER_TARGET_CHANGED" then
				btn.newTimer = btn.rangeTimer
			end
		end

		function mod:ActionButton_UpdateUsable(btn)
			local name = btn:GetName()
			local icon = _G[name.."Icon"]
			local normalTexture = _G[name.."NormalTexture"]

			local inRange = IsActionInRange(btn.action)
			local isUsable, notEnoughMana = IsUsableAction(btn.action);

			if inRange == 0 then
				icon:SetVertexColor(1.0, 0.1, 0.1)
				normalTexture:SetVertexColor(1.0, 0.1, 0.1)
			elseif isUsable then
				icon:SetVertexColor(1.0, 1.0, 1.0)
				normalTexture:SetVertexColor(1.0, 1.0, 1.0)
			elseif notEnoughMana then
				icon:SetVertexColor(0.5, 0.5, 1.0)
				normalTexture:SetVertexColor(0.5, 0.5, 1.0)
			else
				icon:SetVertexColor(0.4, 0.4, 0.4)
				normalTexture:SetVertexColor(1.0, 1.0, 1.0)
			end
		end

		function mod:ActionButton_OnUpdate(btn, elapsed)
			local rangeTimer = btn.newTimer
			if rangeTimer then
				rangeTimer = rangeTimer - elapsed
				if rangeTimer <= 0 then
					mod:ActionButton_UpdateUsable(btn)
					rangeTimer = _G.TOOLTIP_UPDATE_TIME
				end
				btn.newTimer = rangeTimer
			end
		end

		function ActionBars_Range()
			if DB.range == true and not mod:IsHooked("ActionButton_OnEvent") then
				mod:SecureHook("ActionButton_OnEvent")
				mod:SecureHook("ActionButton_UpdateUsable")
				mod:SecureHook("ActionButton_OnUpdate")
			elseif not DB.range and mod:IsHooked("ActionButton_OnEvent") then
				mod:UnhookAll()
			end
		end
	end

	--
	-- handle hiding/showing action bar gryphons
	--
	local function ActionBars_Gryphons()
		if DB.art then
			_G.MainMenuBarLeftEndCap:Hide()
			_G.MainMenuBarRightEndCap:Hide()
		else
			_G.MainMenuBarLeftEndCap:Show()
			_G.MainMenuBarRightEndCap:Show()
		end
	end

	local function ActionBars_Hotkeys(opacity)
		opacity = opacity or DB.hotkeys or 1
		local mopacity = opacity / 1.2 -- macro name opacity
		for i = 1, 12 do
			_G["ActionButton" .. i .. "HotKey"]:SetAlpha(opacity)
			_G["BonusActionButton" .. i .. "HotKey"]:SetAlpha(opacity)
			_G["MultiBarBottomRightButton" .. i .. "HotKey"]:SetAlpha(opacity)
			_G["MultiBarBottomLeftButton" .. i .. "HotKey"]:SetAlpha(opacity)
			_G["MultiBarRightButton" .. i .. "HotKey"]:SetAlpha(opacity)
			_G["MultiBarLeftButton" .. i .. "HotKey"]:SetAlpha(opacity)

			_G["ActionButton" .. i .. "Name"]:SetAlpha(mopacity)
			_G["BonusActionButton" .. i .. "Name"]:SetAlpha(mopacity)
			_G["MultiBarBottomRightButton" .. i .. "Name"]:SetAlpha(mopacity)
			_G["MultiBarBottomLeftButton" .. i .. "Name"]:SetAlpha(mopacity)
			_G["MultiBarRightButton" .. i .. "Name"]:SetAlpha(mopacity)
			_G["MultiBarLeftButton" .. i .. "Name"]:SetAlpha(mopacity)
		end
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
			if DB.hover == true then
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

	local options = {
		type = "group",
		name = "ActionBars",
		get = function(i)
			return DB[i[#i]]
		end,
		set = function(i, val)
			DB[i[#i]] = val
			mod:ApplySettings()
		end,
		args = {
			status = {
				type = "description",
				name = L:F("This module is disabled because you are using: |cffffd700%s|r", reason or UNKNOWN),
				fontSize = "medium",
				order = 0,
				hidden = not disabled
			},
			art = {
				type = "toggle",
				name = L["Hide Gryphons"],
				order = 1,
				disabled = function() return disabled end,
				set = function(_, val)
					DB.art = val
					ActionBars_Gryphons()
				end
			},
			range = {
				type = "toggle",
				name = L["Range Detection"],
				desc = L["Turns your buttons red if your target is out of range."],
				disabled = function() return disabled end,
				order = 2
			},
			hover = {
				type = "toggle",
				name = L["Hover Mode"],
				desc = L["Shows your right action bars on hover."],
				disabled = function() return disabled end,
				order = 3
			},
			sep1 = {
				type = "description",
				name = " ",
				order = 4,
				width = "full"
			},
			scale = {
				type = "range",
				name = L["Scale"],
				desc = L["Changes action bars scale"],
				order = 7,
				disabled = function() return disabled end,
				min = 0.5,
				max = 3,
				step = 0.01,
				bigStep = 0.05
			},
			hotkeys = {
				type = "range",
				name = L["Hotkeys"],
				desc = L["Changes the opacity of action bar hotkeys."],
				order = 8,
				disabled = function() return disabled end,
				min = 0,
				max = 1,
				step = 0.01,
				bigStep = 0.1
			},
			reset = {
				type = "execute",
				name = RESET,
				order = 9,
				disabled = function() return disabled end,
				width = "full",
				confirm = function()
					return L:F("Are you sure you want to reset %s to default?", "ActionBars")
				end,
				func = function()
					wipe(core.db.ActionBars)
					DB = nil
					mod:SetupDatabase()
					Print(L["module's settings reset to default."])
					mod:ApplySettings()
				end
			}
		}
	}

	function mod:SetupDatabase()
		if not DB then
			if type(core.db.ActionBars) ~= "table" or next(core.db.ActionBars) == nil then
				core.db.ActionBars = CopyTable(defaults)
			end
			DB = core.db.ActionBars
		end
	end

	function mod:ApplySettings()
		mod:SetupDatabase()
		if not disabled then
			ActionBars_Gryphons()
			ActionBars_Range()
			ActionBars_MouseOver()
			ActionBars_ScaleBars()
			ActionBars_Hotkeys()
		end
	end

	function mod:PLAYER_ENTERING_WORLD()
		mod:ApplySettings()
	end

	core:RegisterForEvent("PLAYER_LOGIN", function()
		mod:SetupDatabase()

		SLASH_KPACKABM1 = "/abm"
		SlashCmdList.KPACKABM = function()
			return core:OpenConfig("Options", "ActionBars")
		end
		core.options.args.Options.args.ActionBars = options
		mod:RegisterEvent("PLAYER_ENTERING_WORLD")
	end)
end)