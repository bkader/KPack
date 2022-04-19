local core = KPack
if not core then return end
core:AddModule("CombatTime", "Tracks how long you spend in combat.", function(L)
	if core:IsDisabled("CombatTime") then return end

	local mod = CreateFrame("Frame")
	mod:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
	core.CombatTime = mod

	local defaults = {
		enabled = false,
		stopwatch = false,
		locked = false,
		scale = 1,
		font = "Friz Quadrata TT",
		fontFlags = "OUTLINE",
		color = {1, 1, 0}
	}

	local floor, GetTime, format = math.floor, GetTime, string.format

	local options = {
		type = "group",
		name = L["Combat Time"],
		get = function(i)
			return mod.db[i[#i]]
		end,
		set = function(i, val)
			mod.db[i[#i]] = val
			mod:ApplySettings()
		end,
		args = {
			enabled = {
				type = "toggle",
				name = L["Enable"],
				order = 1
			},
			locked = {
				type = "toggle",
				name = L["Lock"],
				order = 2,
				disabled = function()
					return not mod.db.enabled
				end
			},
			stopwatch = {
				type = "toggle",
				name = STOPWATCH_TITLE,
				desc = L["Trigger the in-game stopwatch on combat."],
				order = 3,
				disabled = function()
					return not mod.db.enabled
				end
			},
			scale = {
				type = "range",
				name = L["Scale"],
				order = 4,
				min = 0.5,
				max = 3,
				step = 0.01,
				bigStep = 0.1,
				disabled = function()
					return not mod.db.enabled
				end
			},
			font = {
				type = "select",
				name = L["Font"],
				order = 5,
				dialogControl = "LSM30_Font",
				values = AceGUIWidgetLSMlists.font,
				disabled = function()
					return not mod.db.enabled
				end
			},
			fontFlags = {
				type = "select",
				name = L["Font Outline"],
				order = 6,
				values = {
					[""] = NONE,
					["OUTLINE"] = L["Outline"],
					["THINOUTLINE"] = L["Thin outline"],
					["THICKOUTLINE"] = L["Thick outline"],
					["MONOCHROME"] = L["Monochrome"],
					["OUTLINEMONOCHROME"] = L["Outlined monochrome"]
				},
				disabled = function()
					return not mod.db.enabled
				end
			},
			color = {
				type = "color",
				name = L["Color"],
				order = 7,
				get = function()
					return unpack(mod.db.color)
				end,
				set = function(_, r, g, b)
					mod.db.color = {r, g, b, 1}
					mod:ApplySettings()
				end
			}
		}
	}

	local function Print(msg)
		if msg then
			core:Print(msg, "CombatTime")
		end
	end

	local function SetupDatabase()
		if not mod.db then
			-- disabled by default
			if type(core.db.CombatTime) ~= "table" or core.db.CombatTime.scale == nil then
				core.db.CombatTime = CopyTable(defaults)
			end
			mod.db = core.db.CombatTime
		end
	end

	local function CombatTime_OnUpdate(self, elapsed)
		self.updated = (self.updated or 0) + elapsed

		if self.updated > 1 then
			local total = GetTime() - self.starttime
			local _hor = floor(total / 3600)
			local _min = floor(total / 60 - (_hor * 60))
			local _sec = floor(total - _hor * 3600 - _min * 60)

			if _hor > 0 then
				self.timer:SetText(format("%02d:%02d:%02d", _hor, _min, _sec))
			else
				self.timer:SetText(format("%02d:%02d", _min, _sec))
			end
			self.updated = 0
		end
	end

	local function CombatTime_CreateFrame()
		local frame = CreateFrame("Frame", "KPackCombatTimer", nil, UIParent)
		frame:SetSize(85, 25)
		frame:SetFrameStrata("LOW")
		frame:SetPoint("TOPLEFT", Minimap, "BOTTOMLEFT", 0, -10)

		-- make the frame movable
		frame:SetMovable(true)
		frame:EnableMouse(true)
		frame:SetClampedToScreen(true)
		frame:RegisterForDrag("RightButton")
		frame:SetScript("OnDragStart", function(self)
			self:StartMoving()
		end)
		frame:SetScript("OnDragStop", function(self)
			self:StopMovingOrSizing()
			core:SavePosition(self, mod.db)
		end)
		frame:SetScript("OnMouseUp", function(self, button)
			if button == "RightButton" then
				core:OpenConfig("Options", "CombatTime")
			end
		end)

		-- timer text
		local timer = frame:CreateFontString(nil, "OVERLAY")
		timer:SetFont(core:MediaFetch("font", mod.db.font), 14, mod.db.fontFlags)
		timer:SetTextColor(unpack(mod.db.color))
		timer:SetJustifyH("CENTER")
		timer:SetAllPoints(frame)
		timer:SetText("00:00")
		frame.timer = timer

		if mod.db.stopwatch then
			frame:Hide()
		else
			frame:Show()
		end

		frame.elapsed = 0
		core:RestorePosition(frame, mod.db)
		return frame
	end

	local SlashCommandHandler
	do
		local exec, help = {}, "|cffffd700%s|r: %s"

		exec.on = function()
			if mod.db.enabled ~= true then
				mod.db.enabled = true
				Print(L["|cff00ff00enabled|r"])
				mod.frame = mod.frame or CombatTime_CreateFrame()
			end
		end
		exec.enable = exec.on

		exec.off = function()
			if mod.db.enabled == true then
				mod.db.enabled = false
				Print(L["|cffff0000disabled|r"])
				if mod.frame then
					mod.frame:Hide()
					mod.frame:UnregisterAllEvents()
				end
			end
		end
		exec.disable = exec.off

		exec.stopwatch = function()
			if mod.db.stopwatch == true then
				mod.db.stopwatch = false
				Print(L:F("using stopwatch: %s", L["|cffff0000disabled|r"]))
			else
				Print(L:F("using stopwatch: %s", L["|cff00ff00enabled|r"]))
				mod.db.stopwatch = true
			end
		end

		exec.reset = function()
			wipe(core.db.CombatTime)
			core.db.CombatTime = CopyTable(defaults)
			mod.db = core.db.CombatTime
			Print(L["module's settings reset to default."])
			if mod.frame then
				mod.frame:Hide()
				mod.frame:UnregisterAllEvents()
				mod.frame = nil
				mod:ApplySettings()
			end
		end
		exec.defaults = exec.reset

		function SlashCommandHandler(msg)
			local cmd = msg:trim():lower()
			if type(exec[cmd]) == "function" then
				exec[cmd]()
			elseif cmd == "config" or cmd == "options" then
				core:OpenConfig("Options", "CombatTime")
			else
				Print(L:F("Acceptable commands for: |caaf49141%s|r", "/ct"))
				print(format(help, "on", L["enable the module."]))
				print(format(help, "off", L["disable the module."]))
				print(format(help, "stopwatch", L["Trigger the in-game stopwatch on combat."]))
				print(format(help, "config", L["Access module settings."]))
				print(format(help, "reset", L["Resets module settings to default."]))
			end
		end
	end

	function mod:ApplySettings()
		SetupDatabase()
		self.frame = self.frame or CombatTime_CreateFrame()

		if not self.db.enabled then
			self:UnregisterAllEvents()
			if self.frame and self.frame:IsShown() then
				self.frame:Hide()
				self.frame.elapsed = 0
				self.frame:SetScript("OnUpdate", nil)
			end
			return
		end

		core:RestorePosition(self.frame, self.db)
		self.frame:SetScale(self.db.scale or 1)
		self.frame.timer:SetFont(core:MediaFetch("font", self.db.font), 14, self.db.fontFlags)
		self.frame.timer:SetTextColor(unpack(self.db.color))

		if self.db.locked then
			self.frame:SetBackdrop(nil)
			self.frame:EnableMouse(false)
		else
			self.frame:SetBackdrop({
				bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
				insets = {left = 1, right = 2, top = 2, bottom = 1}
			})
			self.frame:EnableMouse(true)
		end

		if self.db.stopwatch then
			self.frame:Hide()
		else
			self.frame:Show()
		end

		self:RegisterEvent("PLAYER_REGEN_ENABLED")
		self:RegisterEvent("PLAYER_REGEN_DISABLED")
	end

	function mod:PLAYER_REGEN_DISABLED()
		if self.db.enabled then
			self.frame = self.frame or CombatTime_CreateFrame()

			if self.db.stopwatch then
				if not StopwatchFrame:IsShown() then
					Stopwatch_Toggle()
				end
				Stopwatch_Clear()
				Stopwatch_Play()
				self.frame:Hide()
				self.frame:SetScript("OnUpdate", nil)
			else
				self.frame.timer:SetTextColor(unpack(self.db.color))
				self.frame.starttime = GetTime() - 1
				self.frame:SetScript("OnUpdate", CombatTime_OnUpdate)
				self.frame:Show()
			end
		end
	end

	function mod:PLAYER_REGEN_ENABLED()
		if self.db.enabled then
			self.frame = self.frame or CombatTime_CreateFrame()
			self.frame.elapsed = 0
			self.frame:SetScript("OnUpdate", nil)

			if self.db.stopwatch and StopwatchFrame and StopwatchFrame:IsShown() then
				Stopwatch_Pause()
				if self.frame then
					self.frame:Hide()
				end
			elseif self.frame and not self.frame:IsShown() then
				self.frame:Show()
			end
		end
	end

	core:RegisterForEvent("PLAYER_LOGIN", function()
		SetupDatabase()
		core.options.args.Options.args.CombatTime = options
		-- register our slash commands
		SLASH_KPACKCOMBATTIME1 = "/ctm"
		SlashCmdList["KPACKCOMBATTIME"] = SlashCommandHandler

		mod:ApplySettings()
	end)
end)