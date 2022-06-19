local core = KPack
if not core then return end
core:AddModule("SimpleComboPoints", "Highly customizable combo point module for rogues and druids.", function(L)
	if core:IsDisabled("SimpleComboPoints") then return end

	local mod = core.SCP or {}
	core.SCP = mod

	-- cache frequently used globals
	local pairs = pairs
	local CreateFrame = CreateFrame
	local GetComboPoints = GetComboPoints
	local IsAltKeyDown = IsAltKeyDown
	local InCombatLockdown = InCombatLockdown
	local ColorPickerFrame = ColorPickerFrame

	-- some locales we need
	local maxPoints, xPos, yPos = 5, 0, 0
	local druidForm, shown = false, true
	local pointsFrame

	-- saved variables and default options
	local DB, _
	local defaults = {
		enabled = true,
		width = 22,
		height = 22,
		scale = 1,
		spacing = 1,
		combat = false,
		anchor = "CENTER",
		opacity = 0.1,
		color = {r = 0.969, g = 0.675, b = 0.145},
		borderSize = 2,
		border = {r = 0, g = 0, b = 0, a = 0.5},
		color2on = false,
		color2 = {r = 0.969, g = 0.675, b = 0.145},
		xPos = xPos,
		yPos = yPos
	}
	local disabled

	-- local functions
	local SCP_InitializeFrames, SCP_RefreshDisplay
	local SCP_UpdatePoints, SCP_UpdateFrames
	local SCP_DestroyFrames
	local SCP_ColorPickCallback
	local UPDATE_SHAPESHIFT_FORM

	-- module's print function
	local function Print(msg)
		if msg then
			core:Print(msg, "ComboPoints")
		end
	end

	local function SetupDatabase()
		if not DB then
			if type(core.char.SCP) ~= "table" or next(core.char.SCP) == nil then
				core.char.SCP = CopyTable(defaults)
			end
			DB = core.char.SCP
		end
	end

	-- //////////////////////////////////////////////////////////////

	local backdrop = {
		bgFile = [[Interface\Buttons\WHITE8X8]],
		edgeFile = [[Interface\Buttons\WHITE8X8]],
		tileSize = 2,
		edgeSize = 2,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	}
	local borderColor = {r = 0, g = 0, b = 0, a = 1}

	-- initializes the frame
	function SCP_InitializeFrames()
		pointsFrame = wipe(pointsFrame or {})
		for i = 1, maxPoints do
			pointsFrame[i] = CreateFrame("Frame", "KPackSCPFrame" .. i, i == 1 and UIParent or pointsFrame[i - 1])
			backdrop.edgeSize = DB.borderSize or defaults.borderSize
			pointsFrame[i]:SetBackdrop(backdrop)
		end
		SCP_UpdateFrames()
	end

	-- updates the combo points frames
	function SCP_UpdatePoints()
		if disabled then
			return
		end
		local power, i = GetComboPoints("player"), 1
		local r, g, b = DB.color.r, DB.color.g, DB.color.b
		while i <= power do
			if pointsFrame[i] then
				pointsFrame[i]:SetBackdropColor(r, g, b, 1)
			end
			i = i + 1
		end
		if DB.color2on and DB.color2 then
			r, g, b = DB.color2.r, DB.color2.g, DB.color2.b
		end
		while i <= maxPoints do
			if pointsFrame[i] then
				pointsFrame[i]:SetBackdropColor(r, g, b, DB.opacity or defaults.opacity)
			end
			i = i + 1
		end
		if DB.combat then
			SCP_RefreshDisplay()
		end
	end

	-- updates the whole frame
	function SCP_UpdateFrames()
		local width = DB.width or 22
		local height = DB.height or 22

		local fcolor = (DB.color2on and DB.color2) and DB.color2 or DB.color
		local bcolor = DB.border or borderColor

		for i = 1, maxPoints do
			if pointsFrame[i] then
				pointsFrame[i]:SetSize(width, height)
				pointsFrame[i]:SetBackdropColor(fcolor.r, fcolor.g, fcolor.b, DB.opacity or defaults.opacity)
				pointsFrame[i]:SetBackdropBorderColor(bcolor.r, bcolor.g, bcolor.b, bcolor.a or 1)

				if i == 1 then
					pointsFrame[i]:SetPoint(DB.anchor, UIParent, DB.anchor, DB.xPos, DB.yPos)
					pointsFrame[i]:SetScale(DB.scale)

					pointsFrame[i]:SetMovable(true)
					pointsFrame[i]:EnableMouse(true)
					pointsFrame[i]:RegisterForDrag("LeftButton")

					pointsFrame[i]:SetScript("OnDragStart", function(self)
						if IsAltKeyDown() then
							self:StartMoving()
						end
					end)
					pointsFrame[i]:SetScript("OnDragStop", function(self)
						self:StopMovingOrSizing()
						DB.anchor, _, _, DB.xPos, DB.yPos = self:GetPoint(1)
					end)
				else
					pointsFrame[i]:SetPoint("RIGHT", width + 1 + (DB.spacing or 0), 0)
				end
				pointsFrame[i]:Show()
			end
		end
		SCP_UpdatePoints()
	end

	-- simply refreshes the display of the frame
	function SCP_RefreshDisplay()
		if druidForm then
			return
		end

		if not InCombatLockdown() and GetComboPoints("player") == 0 and DB.combat then
			if next(pointsFrame) then
				for i = 1, maxPoints do
					pointsFrame[i]:Hide()
				end
			end
			shown = false
		elseif not shown then
			for i = 1, maxPoints do
				pointsFrame[i]:Show()
			end
			shown = true
		end
	end

	-- destroys the frames.
	function SCP_DestroyFrames()
		for i = 1, maxPoints do
			if pointsFrame[i] then
				pointsFrame[i]:Hide()
				pointsFrame[i] = nil
			end
		end
		pointsFrame = wipe(pointsFrame or {})
	end

	-- hooked to the ColorPickerFrame
	function SCP_ColorPickCallback(restore)
		local r, g, b
		if restore then
			r, g, b = unpack(restore)
		else
			r, g, b = ColorPickerFrame:GetColorRGB()
		end

		if r and g and b then
			DB.color.r = r
			DB.color.g = g
			DB.color.b = b
			SCP_UpdateFrames()
		end
	end

	-- //////////////////////////////////////////////////////////////

	-- after the player enters the world
	core:RegisterForEvent("PLAYER_ENTERING_WORLD", function()
		if disabled then return end
		SetupDatabase()
		SCP_InitializeFrames()
		SCP_UpdatePoints()
		-- only for druids.
		if core.class == "DRUID" then
			core.After(1, UPDATE_SHAPESHIFT_FORM)
		end
	end)

	-- used to update combo points
	core:RegisterForEvent("UNIT_COMBO_POINTS", SCP_UpdatePoints)
	core:RegisterForEvent("PLAYER_REGEN_ENABLED", SCP_UpdatePoints)
	core:RegisterForEvent("PLAYER_TARGET_CHANGED", SCP_UpdatePoints)

	-- used only for druids
	function UPDATE_SHAPESHIFT_FORM()
		if disabled or core.class ~= "DRUID" then
			return
		end
		SetupDatabase()

		if not pointsFrame then
			SCP_InitializeFrames()
		end

		if GetShapeshiftForm() == 3 then
			for i = 1, maxPoints do
				pointsFrame[i]:Show()
			end
			druidForm = false
		elseif next(pointsFrame) then
			for i = 1, maxPoints do
				pointsFrame[i]:Hide()
			end
			druidForm = true
		end
		SCP_UpdatePoints()
	end
	core:RegisterForEvent("UPDATE_SHAPESHIFT_FORM", UPDATE_SHAPESHIFT_FORM)

	-- //////////////////////////////////////////////////////////////

	-- slash commands handler
	local function SlashCommandHandler(txt)
		local cmd, msg = txt:match("^(%S*)%s*(.-)$")
		cmd, msg = cmd:lower(), msg:lower()

		-- enable or disable the module
		if cmd == "toggle" then
			-- reset settings
			DB.enabled = not DB.enabled
			SCP_DestroyFrames()
			if not DB.enabled then
				SCP_UpdateFrames()
			else
				SCP_InitializeFrames()
			end
		elseif cmd == "reset" then
			wipe(core.char.SCP)
			DB = nil
			SetupDatabase()

			SCP_DestroyFrames()
			SCP_InitializeFrames()

			Print(L["module's settings reset to default."])
		elseif cmd == "width" or cmd == "height" and DB[cmd] ~= nil then
			-- scaling
			local num = tonumber(msg)
			if num then
				DB[cmd] = num
				SCP_UpdateFrames()
			else
				Print(L["The " .. cmd .. " must be a valid number"])
			end
		elseif cmd == "scale" then
			local scale = tonumber(msg)
			if scale then
				DB.scale = scale
				SCP_UpdateFrames()
			else
				Print(L["Scale has to be a number, recommended to be between 0.5 and 3"])
			end
		elseif cmd == "spacing" then
			-- changing color
			local spacing = tonumber(msg)
			if spacing then
				DB.spacing = spacing
				SCP_UpdateFrames()
			else
				Print(L["The spacing must be a valid number"])
			end
		elseif cmd == "color" or cmd == "colour" then
			-- toggle in and out of combat
			local r, g, b = DB.color.r, DB.color.g, DB.color.b
			ColorPickerFrame:SetColorRGB(r, g, b)
			ColorPickerFrame.previousValues = {r, g, b}
			ColorPickerFrame.func = SCP_ColorPickCallback
			ColorPickerFrame.opacityFunc = SCP_ColorPickCallback
			ColorPickerFrame.cancelFunc = SCP_ColorPickCallback
			ColorPickerFrame:Hide()
			ColorPickerFrame:Show()
		elseif cmd == "combat" or cmd == "nocombat" then
			-- otherwise, show commands help
			DB.combat = not DB.combat

			local status = (DB.combat == false)
			Print(L:F("Show out of combat: %s", (status and "|cff00ff00ON|r" or "|cffff0000OFF|r")))

			SCP_RefreshDisplay()
		elseif cmd == "config" or cmd == "options" then
			core:OpenConfig("Options", "SCP")
		else
			Print(L:F("Acceptable commands for: |caaf49141%s|r", "/scp"))
			print("|cffffd700toggle|r", L["Enables or disables the module."])
			print("|cffffd700width or height |cff00ffffn|r|r", L["Changes the points width or height."])
			print("|cffffd700scale |cff00ffffn|r|r", L["Changes frame scale."])
			print("|cffffd700spacing |cff00ffffn|r|r", L["Changes spacing between points."])
			print("|cffffd700color|r", L["Changes points color."])
			print("|cffffd700combat|r", L["Toggles showing combo points out of combat."])
			print("|cffffd700config|r", L["Access module settings."])
			print("|cffffd700reset|r", L["Resets module settings to default."])
		end
	end

	core:RegisterForEvent("PLAYER_LOGIN", function()
		if core.class ~= "ROGUE" and core.class ~= "DRUID" then
			disabled = true
			return
		end

		SetupDatabase()

		SlashCmdList["KPACKSCP"] = SlashCommandHandler
		SLASH_KPACKSCP1, SLASH_KPACKSCP2 = "/scp", "/simplecombopoints"

		local function _disabled()
			return not DB.enabled
		end

		core.options.args.Options.args.SCP = {
			type = "group",
			name = "Simple Combo Points",
			get = function(i)
				return DB[i[#i]]
			end,
			set = function(i, val)
				DB[i[#i]] = val
				SCP_DestroyFrames()
				SCP_InitializeFrames()
			end,
			args = {
				enabled = {
					type = "toggle",
					name = L["Enable"],
					order = 1
				},
				combat = {
					type = "toggle",
					name = L["Hide out of combat"],
					desc = L["Toggles showing combo points out of combat."],
					order = 2
				},
				width = {
					type = "range",
					name = L["Width"],
					order = 3,
					min = 10,
					max = 50,
					step = 0.1,
					bigStep = 1
				},
				height = {
					type = "range",
					name = L["Height"],
					order = 4,
					min = 10,
					max = 50,
					step = 0.1,
					bigStep = 1
				},
				scale = {
					type = "range",
					name = L["Scale"],
					desc = L["Changes frame scale."],
					order = 5,
					min = 0.5,
					max = 3,
					step = 0.001,
					bigStep = 0.01,
					isPercent = true
				},
				spacing = {
					type = "range",
					name = L["Spacing"],
					desc = L["Changes spacing between points."],
					order = 6,
					min = 0,
					max = 50,
					step = 0.1,
					bigStep = 1
				},
				opacity = {
					type = "range",
					name = L["Opacity"],
					desc = L["Changes points opacity."],
					order = 7,
					get = function()
						return DB.opacity
					end,
					set = function(_, val)
						DB.opacity = val
						SCP_DestroyFrames()
						SCP_InitializeFrames()
					end,
					min = 0.1,
					max = 0.9,
					step = 0.001,
					bigStep = 0.01,
					isPercent = true
				},
				color = {
					type = "color",
					name = L["Color"],
					desc = L["Changes points color."],
					hasAlpha = false,
					order = 8,
					get = function()
						return DB.color.r, DB.color.g, DB.color.b
					end,
					set = function(i, r, g, b)
						DB.color.r, DB.color.g, DB.color.b = r, g, b
						SCP_DestroyFrames()
						SCP_InitializeFrames()
					end
				},
				borders = {
					type = "header",
					name = L["Borders"],
					order = 9
				},
				borderSize = {
					type = "range",
					name = L["Size"],
					order = 10,
					min = 1,
					max = 5,
					step = 0.1,
					bigStep = 1
				},
				border = {
					type = "color",
					name = L["Border Color"],
					hasAlpha = true,
					order = 11,
					get = function()
						local c = DB.border or borderColor
						return c.r, c.g, c.b, c.a or 1
					end,
					set = function(i, r, g, b, a)
						DB.border = DB.border or {}
						DB.border.r, DB.border.g, DB.border.b, DB.border.a = r, g, b, a or 1
						SCP_DestroyFrames()
						SCP_InitializeFrames()
					end
				},
				sep_02 = {
					type = "description",
					name = " ",
					width = "full",
					order = 12
				},
				color2head = {
					type = "header",
					name = L["Empty Color"],
					order = 13
				},
				color2on = {
					type = "toggle",
					name = L["Enable"],
					order = 14
				},
				color2 = {
					type = "color",
					name = L["Color"],
					desc = L["Empty points color."],
					hasAlpha = false,
					order = 15,
					disabled = function() return not DB.color2on end,
					get = function()
						local c = DB.color2 or DB.color
						return c.r, c.g, c.b
					end,
					set = function(i, r, g, b)
						DB.color2 = DB.color2 or {}
						DB.color2.r, DB.color2.g, DB.color2.b = r, g, b
						SCP_DestroyFrames()
						SCP_InitializeFrames()
					end
				},
				sep_03 = {
					type = "description",
					name = " ",
					width = "full",
					order = 98
				},
				reset = {
					type = "execute",
					name = RESET,
					order = 99,
					width = "full",
					confirm = function()
						return L:F("Are you sure you want to reset %s to default?", "SimpleComboPoints")
					end,
					func = function()
						wipe(core.char.SCP)
						DB = nil
						SetupDatabase()
						SCP_DestroyFrames()
						SCP_InitializeFrames()
						Print(L["module's settings reset to default."])
					end
				}
			}
		}
	end)
end)