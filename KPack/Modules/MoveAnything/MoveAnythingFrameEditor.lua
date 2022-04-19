local MovAny = MovAny
if not MovAny then return end

local KPack = KPack
if not KPack then return end

local L = KPack.L

local _G = _G
local MovAny_TooltipShow = _G.MovAny_TooltipShow or KPack.Noop
local MA_tdeepcopy = _G.MA_tdeepcopy or _G.CopyTable

function MovAny:ToggleFrameEditors(show)
	show = show ~= nil and show or MAOptionsToggleFrameEditors:GetChecked()
	for i, fe in pairs(MovAny.frameEditors) do
		if show then
			fe:Show()
		else
			fe:Hide()
		end
	end
end

function MovAny:FrameEditor(name)
	local f = _G[name]
	if f and name ~= f:GetName() then
		name = f:GetName()
	end
	if MovAny.frameEditors[name] then
		MovAny.frameEditors[name]:CloseDialog()
		return
	end
	if MovAny.NoFE[name] then
		MovAny_Print(string.format(L.FRAME_NO_FRAME_EDITOR, name))
		return
	end
	if self.lDelayedSync[name] then
		MovAny_Print(string.format(self.lDelayedSync[name], name))
		return
	end
	if f and not self:IsValidObject(f) then
		return
	end
	for id = 1, 1000, 1 do
		f = _G["MA_FE" .. id]
		if not f then
			f = MovAny:CreateFrameEditor(id, name)
			break
		end
		if not f.o then
			f:LoadFrame(name)
			f:Show()
			break
		end
		id = id + 1
	end
end

function MovAny:CreateFrameEditor(id, name)
	local funcClearFocus = function(self)
		self:ClearFocus()
	end

	local leftColumnWidth = 42
	local centerColumnWidth = 30
	local secondColumnOffset = leftColumnWidth + 10

	local tabList = {}
	local tabFunc = function(func)
		return function(self)
			local found = nil
			local prev = nil
			for i, v in pairs(tabList) do
				if found and not IsShiftKeyDown() then
					v:SetFocus()
					found = nil
					break
				end
				if v == self then
					self:ClearFocus()
					found = true
					if not prev and IsShiftKeyDown() then
						break
					end
				end
				if found and prev and IsShiftKeyDown() then
					prev:SetFocus()
					found = nil
					break
				end
				prev = v
			end
			if found then
				if IsShiftKeyDown() then
					for i, v in pairs(tabList) do
						prev = v
					end
					if prev then
						prev:SetFocus()
					end
				elseif tabList[1] then
					tabList[1]:SetFocus()
				end
			end
			if func then
				func(self)
			end
		end
	end

	local fn = "MA_FE" .. id
	local fe = CreateFrame("Frame", fn, UIParent)

	fe:SetSize(650, 495)
	fe:SetFrameStrata("DIALOG")
	fe:SetFrameLevel(1)
	fe:SetPoint("CENTER")
	fe:EnableMouse(true)
	fe:SetMovable(true)
	fe:RegisterForDrag("LeftButton")
	fe:SetScript("OnDragStart", fe.StartMoving)
	fe:SetScript("OnDragStop", fe.StopMovingOrSizing)
	fe:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		tile = "true",
		tileSize = 32
	})
	fe:SetBackdropColor(0, 0, 0)
	fe:SetBackdropBorderColor(0, 0, 0)

	local pointDropDownButton = CreateFrame("Button", fn .. "Point", fe, "UIDropDownMenuTemplate")
	local pointFunc = function(self)
		UIDropDownMenu_SetSelectedValue(pointDropDownButton, self.value)

		fe:VerifyOpt()
		local updateEditor
		if not fe.opt.pos then
			fe.opt.pos = fe:GeneratePoint()
			updateEditor = true
		end
		if fe.opt.pos and fe.opt.pos[1] ~= self.value then
			fe.opt.pos[1] = self.value
			fe:WritePoint(updateEditor)
		end
	end
	local pointDropDown_MenuInit = function()
		local point
		if fe.opt and fe.opt.pos and fe.opt.pos[1] then
			point = fe.opt.pos[1]
		elseif fe.editFrame then
			point = fe.editFrame:GetPoint()
		end

		local info
		for _, infoTab in pairs(MovAny.DDMPointList) do
			info = UIDropDownMenu_CreateInfo()
			info.text = infoTab.text
			info.value = infoTab.value
			info.func = pointFunc
			if point == infoTab.value then
				info.checked = true
			end
			UIDropDownMenu_AddButton(info)
		end
	end

	local relPointDropDownButton = CreateFrame("Button", fn .. "RelPoint", fe, "UIDropDownMenuTemplate")
	local relPointFunc = function(self)
		UIDropDownMenu_SetSelectedValue(relPointDropDownButton, self.value)

		fe:VerifyOpt()
		if not fe.opt.orgPos and fe.editFrame then
			MovAny:StoreOrgPoints(fe.editFrame, fe.opt)
		end
		local updateEditor
		if not fe.opt.pos then
			fe.opt.pos = fe:GeneratePoint()
			updateEditor = true
		end
		if fe.opt.pos[3] ~= self.value then
			fe.opt.pos[3] = self.value
			fe:WritePoint(updateEditor)
		end
	end
	local relPointDropDown_MenuInit = function()
		local info
		for _, infoTab in pairs(MovAny.DDMPointList) do
			info = UIDropDownMenu_CreateInfo()
			info.text = infoTab.text
			info.value = infoTab.value
			info.func = relPointFunc
			info.checked = nil
			UIDropDownMenu_AddButton(info)
		end
	end

	local closeButton = CreateFrame("Button", fn .. "Close", fe, "MAButtonTemplate")
	closeButton:SetText("X")
	closeButton:SetSize(20, 20)
	closeButton:SetPoint("TOPRIGHT", -1, 0)
	closeButton:SetScript("OnClick", function() fe:CloseDialog() end)

	local helpfulNameLabel = fe:CreateFontString()
	helpfulNameLabel:SetFontObject("GameFontNormalSmall")
	helpfulNameLabel:SetSize(leftColumnWidth, 20)
	helpfulNameLabel:SetJustifyH("LEFT")
	helpfulNameLabel:SetPoint("TOPLEFT", fe, "TOPLEFT", 12, -8)
	helpfulNameLabel:SetText("Frame:")

	local helpfulName = fe:CreateFontString(fn .. "HelpfulName")
	helpfulName:SetFontObject("GameFontHighlightSmall")
	helpfulName:SetSize(270, 20)
	helpfulName:SetJustifyH("LEFT")
	helpfulName:SetPoint("TOPLEFT", helpfulNameLabel, "TOPRIGHT", 6, 0)

	local realNameLabel = fe:CreateFontString()
	realNameLabel:SetFontObject("GameFontNormalSmall")
	realNameLabel:SetSize(leftColumnWidth, 20)
	realNameLabel:SetJustifyH("LEFT")
	realNameLabel:SetPoint("TOPLEFT", helpfulNameLabel, "BOTTOMLEFT", 0, -2)
	realNameLabel:SetText("Name:")

	local realName = fe:CreateFontString(fn .. "RealName")
	realName:SetFontObject("GameFontHighlightSmall")
	realName:SetSize(270, 20)
	realName:SetJustifyH("LEFT")
	realName:SetPoint("TOPLEFT", realNameLabel, "TOPRIGHT", 6, 0)

	local enabledCheck = CreateFrame("CheckButton", fn .. "Enabled", fe, "MACheckButtonTemplate")
	enabledCheck:SetPoint("TOPLEFT", realNameLabel, "BOTTOMLEFT", 2, -2)
	enabledCheck:SetScript("OnClick", function(self) MovAny:ToggleEnableFrame(fe.o.name, fe.opt) end)
	_G[enabledCheck:GetName() .. "Text"]:SetText("Enabled")

	local hideCheck = CreateFrame("CheckButton", fn .. "Hide", fe, "MACheckButtonTemplate")
	hideCheck:SetPoint("TOPLEFT", enabledCheck, "TOPRIGHT", 50, 0)
	hideCheck:SetScript("OnClick", function(self)
		if fe.opt and fe.opt.disabled then
			fe.opt.hidden = self:GetChecked() and true or nil
		else
			if not MovAny:ToggleHide(fe.editFrame:GetName()) then
				self:SetChecked(nil)
			end
		end
		MovAny:UpdateGUIIfShown(true)
	end)
	_G[hideCheck:GetName() .. "Text"]:SetText("Hidden")

	local clampToScreenCheck = CreateFrame("CheckButton", fn .. "ClampToScreenButton", fe, "MACheckButtonTemplate")
	clampToScreenCheck:SetPoint("TOPLEFT", hideCheck, "TOPRIGHT", 50, 0)
	clampToScreenCheck:SetScript("OnClick", function()
		local opt = fe:VerifyOpt()

		if opt.clampToScreen then
			opt.clampToScreen = nil
		else
			opt.clampToScreen = true
		end
		if fe.editFrame and not opt.disabled and fe.editFrame.SetClampedToScreen then
			fe.editFrame:SetClampedToScreen(opt.clampToScreen)
			local mover = MovAny:GetMoverByFrame(fe.editFrame)
			if mover then
				mover:SetClampedToScreen(opt.clampToScreen)
			end
		end
		MovAny:UpdateGUIIfShown(true)
	end)
	_G[clampToScreenCheck:GetName() .. "Text"]:SetText("Clamp to screen")

	local groupTooltipFunc = function(self)
		local names = {}
		local last = nil
		for fn, opt in pairs(MovAny.frameOptions) do
			if type(opt.groups) == "table" and opt.groups[self:GetID()] then
				tinsert(names, fn)
				last = fn
			end
		end

		table.sort(names, function(o1, o2) return o1:lower() < o2:lower() end)

		local s = ""
		if last ~= nil then
			for _, name in pairs(names) do
				s = s .. "  " .. name .. "\n"
			end
			self.tooltipText = string.format(L.FE_GROUPS_TOOLTIP, self:GetID()) .. "\n" .. s
			MovAny_TooltipShow(self)
		else
			self.tooltipText = nil
		end
	end
	local groupFunc = function(self)
		if IsShiftKeyDown() then
			if IsControlKeyDown() and IsAltKeyDown() then
				if type(self.confirm) == "number" and self.confirm + 5 >= time() then
					for fn, opt in pairs(MovAny.frameOptions) do
						if type(opt.groups) == "table" and opt.groups[self:GetID()] then
							opt.groups[self:GetID()] = nil
							if next(opt.groups) == nil then
								opt.groups = nil
							end
						end
					end
					self.confirm = nil
					MovAny:UpdateGUIIfShown(true)
				else
					self:SetChecked(not self:GetChecked())

					local match = nil
					for fn, opt in pairs(MovAny.frameOptions) do
						if type(opt.groups) == "table" and opt.groups[self:GetID()] then
							match = fn
							break
						end
					end
					if match then
						self.confirm = time()
						MovAny_Print(string.format(L.FE_GROUP_RESET_CONFIRM, self:GetID()))
					end
				end
			else
				local opt = fe:VerifyOpt(true)
				for i = 1, 13, 1 do
					_G[fn .. "Group" .. i]:SetChecked(nil)
				end
				if type(opt) == "table" then
					opt.groups = nil
				end
			end
			groupTooltipFunc(self)
			return
		end
		local opt = fe:VerifyOpt()
		if not opt.groups then
			opt.groups = {}
		end
		opt.groups[self:GetID()] = self:GetChecked()
		if next(opt.groups) == nil then
			opt.groups = nil
		end
		MovAny:UpdateGUIIfShown(true)
		groupTooltipFunc(self)
	end

	local groupLabel = fe:CreateFontString()
	groupLabel:SetFontObject("GameFontNormalSmall")
	groupLabel:SetSize(leftColumnWidth, 18)
	groupLabel:SetJustifyH("LEFT")
	groupLabel:SetPoint("TOPLEFT", enabledCheck, "BOTTOMLEFT", -3, -6)
	groupLabel:SetText("Groups")

	local groupCheck1 = CreateFrame("CheckButton", fn .. "Group1", fe, "MACheckButtonTemplate")
	groupCheck1:SetPoint("TOPLEFT", groupLabel, "TOPRIGHT", 8, 0)
	groupCheck1:SetScript("OnClick", groupFunc)
	groupCheck1:SetID(1)
	_G[groupCheck1:GetName() .. "Text"]:SetText("1")
	groupCheck1:SetScript("OnEnter", groupTooltipFunc)

	local groupCheck2 = CreateFrame("CheckButton", fn .. "Group2", fe, "MACheckButtonTemplate")
	groupCheck2:SetPoint("TOPLEFT", groupCheck1, "TOPRIGHT", 7, 0)
	groupCheck2:SetScript("OnClick", groupFunc)
	groupCheck2:SetID(2)
	_G[groupCheck2:GetName() .. "Text"]:SetText("2")
	groupCheck2:SetScript("OnEnter", groupTooltipFunc)

	local groupCheck3 = CreateFrame("CheckButton", fn .. "Group3", fe, "MACheckButtonTemplate")
	groupCheck3:SetPoint("TOPLEFT", groupCheck2, "TOPRIGHT", 7, 0)
	groupCheck3:SetScript("OnClick", groupFunc)
	groupCheck3:SetID(3)
	_G[groupCheck3:GetName() .. "Text"]:SetText("3")
	groupCheck3:SetScript("OnEnter", groupTooltipFunc)

	local groupCheck4 = CreateFrame("CheckButton", fn .. "Group4", fe, "MACheckButtonTemplate")
	groupCheck4:SetPoint("TOPLEFT", groupCheck3, "TOPRIGHT", 7, 0)
	groupCheck4:SetScript("OnClick", groupFunc)
	groupCheck4:SetID(4)
	_G[groupCheck4:GetName() .. "Text"]:SetText("4")
	groupCheck4:SetScript("OnEnter", groupTooltipFunc)

	local groupCheck5 = CreateFrame("CheckButton", fn .. "Group5", fe, "MACheckButtonTemplate")
	groupCheck5:SetPoint("TOPLEFT", groupCheck4, "TOPRIGHT", 7, 0)
	groupCheck5:SetScript("OnClick", groupFunc)
	groupCheck5:SetID(5)
	_G[groupCheck5:GetName() .. "Text"]:SetText("5")
	groupCheck5:SetScript("OnEnter", groupTooltipFunc)

	local groupCheck6 = CreateFrame("CheckButton", fn .. "Group6", fe, "MACheckButtonTemplate")
	groupCheck6:SetPoint("TOPLEFT", groupCheck5, "TOPRIGHT", 7, 0)
	groupCheck6:SetScript("OnClick", groupFunc)
	groupCheck6:SetID(6)
	_G[groupCheck6:GetName() .. "Text"]:SetText("6")
	groupCheck6:SetScript("OnEnter", groupTooltipFunc)

	local groupCheck7 = CreateFrame("CheckButton", fn .. "Group7", fe, "MACheckButtonTemplate")
	groupCheck7:SetPoint("TOPLEFT", groupCheck6, "TOPRIGHT", 7, 0)
	groupCheck7:SetScript("OnClick", groupFunc)
	groupCheck7:SetID(7)
	_G[groupCheck7:GetName() .. "Text"]:SetText("7")
	groupCheck7:SetScript("OnEnter", groupTooltipFunc)

	local groupCheck8 = CreateFrame("CheckButton", fn .. "Group8", fe, "MACheckButtonTemplate")
	groupCheck8:SetPoint("TOPLEFT", groupCheck7, "TOPRIGHT", 7, 0)
	groupCheck8:SetScript("OnClick", groupFunc)
	groupCheck8:SetID(8)
	_G[groupCheck8:GetName() .. "Text"]:SetText("8")
	groupCheck8:SetScript("OnEnter", groupTooltipFunc)

	local groupCheck9 = CreateFrame("CheckButton", fn .. "Group9", fe, "MACheckButtonTemplate")
	groupCheck9:SetPoint("TOPLEFT", groupCheck8, "TOPRIGHT", 7, 0)
	groupCheck9:SetScript("OnClick", groupFunc)
	groupCheck9:SetID(9)
	_G[groupCheck9:GetName() .. "Text"]:SetText("9")
	groupCheck9:SetScript("OnEnter", groupTooltipFunc)

	local groupCheck10 = CreateFrame("CheckButton", fn .. "Group10", fe, "MACheckButtonTemplate")
	groupCheck10:SetPoint("TOPLEFT", groupCheck9, "TOPRIGHT", 7, 0)
	groupCheck10:SetScript("OnClick", groupFunc)
	groupCheck10:SetID(10)
	_G[groupCheck10:GetName() .. "Text"]:SetText("10")
	groupCheck10:SetScript("OnEnter", groupTooltipFunc)

	local groupCheck11 = CreateFrame("CheckButton", fn .. "Group11", fe, "MACheckButtonTemplate")
	groupCheck11:SetPoint("TOPLEFT", groupCheck10, "TOPRIGHT", 11, 0)
	groupCheck11:SetScript("OnClick", groupFunc)
	groupCheck11:SetID(11)
	_G[groupCheck11:GetName() .. "Text"]:SetText("11")
	groupCheck11:SetScript("OnEnter", groupTooltipFunc)

	local groupCheck12 = CreateFrame("CheckButton", fn .. "Group12", fe, "MACheckButtonTemplate")
	groupCheck12:SetPoint("TOPLEFT", groupCheck11, "TOPRIGHT", 11, 0)
	groupCheck12:SetScript("OnClick", groupFunc)
	groupCheck12:SetID(12)
	_G[groupCheck12:GetName() .. "Text"]:SetText("12")
	groupCheck12:SetScript("OnEnter", groupTooltipFunc)

	local groupCheck13 = CreateFrame("CheckButton", fn .. "Group13", fe, "MACheckButtonTemplate")
	groupCheck13:SetPoint("TOPLEFT", groupCheck12, "TOPRIGHT", 11, 0)
	groupCheck13:SetScript("OnClick", groupFunc)
	groupCheck13:SetID(13)
	_G[groupCheck13:GetName() .. "Text"]:SetText("13")
	groupCheck13:SetScript("OnEnter", groupTooltipFunc)

	local positionHeading = fe:CreateFontString()
	positionHeading:SetFontObject("GameFontNormalSmall")
	positionHeading:SetSize(50, 20)
	positionHeading:SetJustifyH("LEFT")
	positionHeading:SetPoint("TOPLEFT", groupLabel, "BOTTOMLEFT", 0, 10)
	positionHeading:SetText("Position")

	local posResetButton = CreateFrame("Button", fn .. "PositionResetButton", fe, "MAButtonTemplate")
	posResetButton:SetSize(20, 20)
	posResetButton:SetPoint("LEFT", positionHeading, "RIGHT", 0, 0)
	posResetButton:SetText("R")

	local dropDownClickFunc = function(self)
		ToggleDropDownMenu(1, nil, self, self, 6, 7, nil, self)
	end

	local pointLabel = fe:CreateFontString()
	pointLabel:SetFontObject("GameFontNormalSmall")
	pointLabel:SetSize(leftColumnWidth, 18)
	pointLabel:SetJustifyH("LEFT")
	pointLabel:SetPoint("TOPLEFT", positionHeading, "BOTTOMLEFT", 0, -10)
	pointLabel:SetText("Attach")

	pointDropDownButton:SetID(1)
	pointDropDownButton:SetScript("OnClick", dropDownClickFunc)
	pointDropDownButton:SetPoint("TOPLEFT", pointLabel, "TOPRIGHT", -12, 3)
	UIDropDownMenu_Initialize(pointDropDownButton, pointDropDown_MenuInit)
	UIDropDownMenu_SetWidth(pointDropDownButton, 100)

	local pointResetButton = CreateFrame("Button", fn .. "PointResetButton", fe, "MAButtonTemplate")
	pointResetButton:SetSize(20, 20)
	pointResetButton:SetPoint("TOPLEFT", pointDropDownButton, "TOPRIGHT", 0, -2.5)
	pointResetButton:SetText("R")
	pointResetButton:SetScript("OnClick", function()
		local opt = fe:VerifyOpt()
		local p
		if fe.editFrame then
			p = self:GetRelativePoint(self:GetFirstOrgPoint(opt), fe.editFrame)
		else
			p = MovAny:GetFirstOrgPoint(opt)
		end
		if not p then
			return
		end
		p = p[1]
		if fe.opt and fe.opt.pos and fe.opt.pos[1] ~= p then
			UIDropDownMenu_Initialize(pointDropDownButton, pointDropDown_MenuInit)
			UIDropDownMenu_SetSelectedValue(pointDropDownButton, p)
			fe.opt.pos[1] = p
			fe:WritePoint()
		end
	end)

	local relPointLabel = fe:CreateFontString()
	relPointLabel:SetFontObject("GameFontNormalSmall")
	relPointLabel:SetSize(30, 18)
	relPointLabel:SetPoint("TOPLEFT", pointResetButton, "TOPRIGHT", 10, 0)
	relPointLabel:SetText("to")

	relPointDropDownButton:SetID(2)
	relPointDropDownButton:SetScript("OnClick", dropDownClickFunc)
	relPointDropDownButton:SetPoint("TOPLEFT", relPointLabel, "TOPRIGHT", -12, 3)
	UIDropDownMenu_Initialize(relPointDropDownButton, relPointDropDown_MenuInit)
	UIDropDownMenu_SetWidth(relPointDropDownButton, 100)

	local relPointResetButton = CreateFrame("Button", fn .. "RelPointResetButton", fe, "MAButtonTemplate")
	relPointResetButton:SetSize(20, 20)
	relPointResetButton:SetPoint("TOPLEFT", relPointDropDownButton, "TOPRIGHT", 0, -2.5)
	relPointResetButton:SetText("R")
	relPointResetButton:SetScript("OnClick", function()
		local opt = fe:VerifyOpt()
		local p
		if fe.editFrame then
			p = self:GetRelativePoint(self:GetFirstOrgPoint(opt), fe.editFrame)
		else
			p = MovAny:GetFirstOrgPoint(opt)
		end
		if not p then
			return
		end
		p = p[3]
		if fe.opt and fe.opt.pos and fe.opt.pos[3] ~= p then
			UIDropDownMenu_Initialize(relPointDropDownButton, relPointDropDown_MenuInit)
			UIDropDownMenu_SetSelectedValue(relPointDropDownButton, p)
			fe.opt.pos[3] = p
			fe:WritePoint()
		end
	end)

	local relToEdit = CreateFrame("EditBox", fn .. "RelToEdit", fe, "InputBoxTemplate")

	local relToLabel = fe:CreateFontString()
	relToLabel:SetFontObject("GameFontNormalSmall")
	relToLabel:SetSize(40, 18)
	relToLabel:SetPoint("TOPLEFT", pointLabel, "BOTTOMLEFT", 0, -14)
	relToLabel:SetText("of")

	local relToFunc = function(self)
		self = self or relToEdit
		local value = self:GetText()

		if value == "" then
			if fe.opt and fe.opt.pos then
				self:SetText(fe.opt.pos[2])
			else
				local p = MovAny:GetFirstOrgPoint(fe:VerifyOpt())
				p = p[2]
				self:SetText(p)
			end
		elseif _G[value] then
			fe:VerifyOpt()
			if not fe.opt.orgPos and fe.editFrame then
				MovAny:StoreOrgPoints(fe.editFrame, fe.opt)
			end
			local updateEditor
			if not fe.opt.pos then
				fe.opt.pos = fe:GeneratePoint()
				updateEditor = true
			end
			if fe.opt.pos[2] ~= value then
				fe.opt.pos[2] = value
				fe:WritePoint(updateEditor)
			end
		else
			MovAny_Print(string.format(L.ELEMENT_NOT_FOUND_NAMED, value))
		end

		self:ClearFocus()
	end

	local relToEscapeFunc = function(self)
		local value = self:GetText()
		if _G[value] then
			fe:VerifyOpt()
			if not fe.opt.orgPos and fe.editFrame then
				MovAny:StoreOrgPoints(fe.editFrame, fe.opt)
			end
			local updateEditor
			if not fe.opt.pos then
				fe.opt.pos = fe:GeneratePoint()
				updateEditor = true
			end
			if fe.opt.pos[2] ~= value then
				fe.opt.pos[2] = value
				fe:WritePoint(updateEditor)
			end
		else
			if fe.opt and fe.opt.pos then
				self:SetText(fe.opt.pos[2])
			else
				local p = MovAny:GetFirstOrgPoint(fe:VerifyOpt())
				p = p[2]
				self:SetText(p)
			end
		end
		self:ClearFocus()
	end

	relToEdit:SetFontObject("GameFontHighlightSmall")
	relToEdit:SetSize(311, 20)
	relToEdit:SetJustifyH("LEFT")
	relToEdit:SetAutoFocus(false)
	relToEdit:SetPoint("TOPLEFT", relToLabel, "TOPRIGHT", 13, 0)
	relToEdit:SetScript("OnTabPressed", tabFunc(relToFunc))
	relToEdit:SetScript("OnEnterPressed", relToFunc)
	relToEdit:SetScript("OnEscapePressed", relToEscapeFunc)

	local relToResetButton = CreateFrame("Button", fn .. "RelToResetButton", fe, "MAButtonTemplate")
	relToResetButton:SetSize(20, 20)
	relToResetButton:SetPoint("TOPLEFT", relToEdit, "TOPRIGHT", 15, 1)
	relToResetButton:SetText("R")
	relToResetButton:SetScript("OnClick", function()
		local opt = fe:VerifyOpt()
		local p
		if fe.editFrame then
			p = self:GetRelativePoint(self:GetFirstOrgPoint(opt), fe.editFrame)
		else
			p = MovAny:GetFirstOrgPoint(opt)
		end
		if not p then
			return
		end
		p = p[2]

		if relToEdit:GetText() ~= p then
			relToEdit:SetText(p)
			relToFunc()
		end
	end)

	local xLabel = fe:CreateFontString()
	xLabel:SetFontObject("GameFontNormalSmall")
	xLabel:SetSize(leftColumnWidth, 18)
	xLabel:SetJustifyH("LEFT")
	xLabel:SetPoint("TOPLEFT", relToLabel, "BOTTOMLEFT", 0, -13)
	xLabel:SetText("X offset")

	local xEdit = CreateFrame("EditBox", fn .. "XEdit", fe, "InputBoxTemplate")

	local xSlider = CreateFrame("Slider", fn .. "XSlider", fe, "OptionsSliderTemplate")

	xEdit:SetFontObject("GameFontHighlightSmall")
	xEdit:SetMaxLetters(10)
	xEdit:SetSize(59, 20)
	xEdit:SetJustifyH("CENTER")
	xEdit:SetAutoFocus(false)
	xEdit:SetPoint("TOPLEFT", xLabel, "TOPRIGHT", 12, 0)
	xEdit:SetText("0")

	local xSliderFunc
	local xEditFunc = function(self)
		self:ClearFocus()

		local v = tonumber(xEdit:GetText())
		if v == nil then
			return
		end

		xSlider:SetScript("OnValueChanged", nil)
		xSlider:SetMinMaxValues(v - 200, v + 200)
		xSlider:SetValue(v)

		v = numfor(v)
		_G[xSlider:GetName() .. "Low"]:SetText(v - 200)
		_G[xSlider:GetName() .. "High"]:SetText(v + 200)
		_G[xSlider:GetName() .. "Text"]:SetText(v)

		xSlider:SetScript("OnValueChanged", xSliderFunc)

		if fe.updating then
			return
		end
		fe:VerifyOpt()
		if not fe.opt.orgPos and fe.editFrame then
			MovAny:StoreOrgPoints(fe.editFrame, fe.opt)
		end
		local updateEditor
		if not fe.opt.pos then
			fe.opt.pos = fe:GeneratePoint()
			updateEditor = true
		end
		if fe.opt.pos[4] ~= tonumber(xEdit:GetText()) then
			fe.lastX = fe.opt.pos[4]
			fe.opt.pos[4] = tonumber(xEdit:GetText())
			fe:WritePoint(updateEditor)
		end
	end
	xEdit:SetScript("OnEnterPressed", xEditFunc)
	xEdit:SetScript("OnTabPressed", tabFunc(xEditFunc))
	xEdit:SetScript("OnEscapePressed", funcClearFocus)

	xSlider:SetScale(.75)
	xSlider:SetWidth(535)
	xSlider:SetMinMaxValues(-200, 200)
	xSlider:SetValue(0)
	xSlider:SetValueStep(1)
	xSlider:SetPoint("TOPLEFT", xEdit, "TOPRIGHT", 10, -2)
	xSlider:SetScript("OnMouseUp", function(self)
		local v = numfor(xSlider:GetValue())
		xSlider:SetScript("OnValueChanged", nil)
		xSlider:SetMinMaxValues(v - 200, v + 200)
		xSlider:SetScript("OnValueChanged", xSliderFunc)
		_G[xSlider:GetName() .. "Low"]:SetText(v - 200)
		_G[xSlider:GetName() .. "High"]:SetText(v + 200)
		_G[xSlider:GetName() .. "Text"]:SetText(v)
	end)
	xSliderFunc = function(self)
		local v = numfor(xSlider:GetValue())
		_G[xSlider:GetName() .. "Text"]:SetText(v)

		xEdit:SetText(numfor(xSlider:GetValue()))

		if fe.updating then
			return
		end
		fe:VerifyOpt()
		if not fe.opt.orgPos and fe.editFrame then
			MovAny:StoreOrgPoints(fe.editFrame, fe.opt)
		end
		local updateEditor
		if not fe.opt.pos then
			fe.opt.pos = fe:GeneratePoint()
			updateEditor = true
		end
		if fe.opt.pos[4] ~= xSlider:GetValue() then
			fe.lastX = fe.opt.pos[4]
			fe.opt.pos[4] = xSlider:GetValue()
			fe:WritePoint(updateEditor)
		end
	end
	xSlider:SetScript("OnValueChanged", xSliderFunc)

	local xMinusFunc = function()
		local v = xSlider:GetValue() - 1
		xSlider:SetScript("OnValueChanged", nil)
		xSlider:SetMinMaxValues(v - 200, v + 200)
		xSlider:SetScript("OnValueChanged", xSliderFunc)
		xSlider:SetValue(v)
	end
	local xPlusFunc = function()
		local v = xSlider:GetValue() + 1
		xSlider:SetScript("OnValueChanged", nil)
		xSlider:SetMinMaxValues(v - 200, v + 200)
		xSlider:SetScript("OnValueChanged", xSliderFunc)
		xSlider:SetValue(v)
	end
	xSlider:SetScript("OnMouseWheel", function(self, dir)
		if dir > 0 then
			xPlusFunc()
		else
			xMinusFunc()
		end
	end)

	local xMinusButton = CreateFrame("Button", fn .. "XMinusButton", fe, "MAButtonTemplate")
	xMinusButton:SetSize(20, 20)
	xMinusButton:SetPoint("TOPLEFT", xSlider, "TOPRIGHT", 12, 2)
	xMinusButton:SetText("-")
	xMinusButton:SetScript("OnClick", xMinusFunc)

	local xPlusButton = CreateFrame("Button", fn .. "XPlusButton", fe, "MAButtonTemplate")
	xPlusButton:SetSize(20, 20)
	xPlusButton:SetPoint("TOPLEFT", xMinusButton, "TOPRIGHT", 3, 0)
	xPlusButton:SetText("+")
	xPlusButton:SetScript("OnClick", xPlusFunc)

	local xResetButton = CreateFrame("Button", fn .. "XResetButton", fe, "MAButtonTemplate")
	xResetButton:SetSize(20, 20)
	xResetButton:SetPoint("TOPLEFT", xPlusButton, "TOPRIGHT", 3, 0)
	xResetButton:SetText("R")
	xResetButton:SetScript("OnClick", function()
		local opt = fe:VerifyOpt()
		local p
		if fe.editFrame then
			p = self:GetRelativePoint(self:GetFirstOrgPoint(opt), fe.editFrame)
		else
			p = MovAny:GetFirstOrgPoint(opt)
		end
		if not p then
			return
		end
		p = p[4]

		xSlider:SetScript("OnValueChanged", nil)
		xSlider:SetMinMaxValues(p - 200, p + 200)
		xSlider:SetScript("OnValueChanged", xSliderFunc)
		xSlider:SetValue(p)
	end)

	local xZeroButton = CreateFrame("Button", fn .. "XZeroButton", fe, "MAButtonTemplate")
	xZeroButton:SetSize(20, 20)
	xZeroButton:SetPoint("TOPLEFT", xResetButton, "TOPRIGHT", 3, 0)
	xZeroButton:SetText("0")
	xZeroButton:SetScript("OnClick", function()
		xSlider:SetScript("OnValueChanged", nil)
		xSlider:SetMinMaxValues(-200, 200)
		xSlider:SetScript("OnValueChanged", xSliderFunc)
		xSlider:SetValue(0)
	end)

	local yLabel = fe:CreateFontString()
	yLabel:SetFontObject("GameFontNormalSmall")
	yLabel:SetSize(leftColumnWidth, 18)
	yLabel:SetJustifyH("LEFT")
	yLabel:SetPoint("TOPLEFT", xLabel, "BOTTOMLEFT", 0, -13)
	yLabel:SetText("Y offset")

	local yEdit = CreateFrame("EditBox", fn .. "YEdit", fe, "InputBoxTemplate")

	local ySlider = CreateFrame("Slider", fn .. "YSlider", fe, "OptionsSliderTemplate")

	yEdit:SetFontObject("GameFontHighlightSmall")
	yEdit:SetMaxLetters(10)
	yEdit:SetSize(59, 20)
	yEdit:SetJustifyH("CENTER")
	yEdit:SetAutoFocus(false)
	yEdit:SetPoint("TOPLEFT", yLabel, "TOPRIGHT", 12, 0)
	yEdit:SetText("0")

	local ySliderFunc
	local yEditFunc = function(self)
		self:ClearFocus()

		local v = tonumber(yEdit:GetText())
		if not v then return end

		ySlider:SetScript("OnValueChanged", nil)
		ySlider:SetMinMaxValues(v - 200, v + 200)
		ySlider:SetValue(v)

		v = numfor(v)
		_G[ySlider:GetName() .. "Low"]:SetText(v - 200)
		_G[ySlider:GetName() .. "High"]:SetText(v + 200)
		_G[ySlider:GetName() .. "Text"]:SetText(v)

		ySlider:SetScript("OnValueChanged", ySliderFunc)

		if fe.updating then
			return
		end
		fe:VerifyOpt()
		if not fe.opt.orgPos and fe.editFrame then
			MovAny:StoreOrgPoints(fe.editFrame, fe.opt)
		end
		local updateEditor
		if not fe.opt.pos then
			fe.opt.pos = fe:GeneratePoint()
			updateEditor = true
		end
		if fe.opt.pos[5] ~= tonumber(yEdit:GetText()) then
			fe.lastY = fe.opt.pos[5]
			fe.opt.pos[5] = tonumber(yEdit:GetText())
			fe:WritePoint(updateEditor)
		end
	end
	yEdit:SetScript("OnEnterPressed", yEditFunc)
	yEdit:SetScript("OnTabPressed", tabFunc(yEditFunc))
	yEdit:SetScript("OnEscapePressed", funcClearFocus)

	ySlider:SetScale(.75)
	ySlider:SetWidth(535)
	ySlider:SetMinMaxValues(-200, 200)
	ySlider:SetValue(0)
	ySlider:SetValueStep(1)
	ySlider:SetPoint("TOPLEFT", yEdit, "TOPRIGHT", 10, -2)
	ySlider:SetScript("OnMouseUp", function(self)
		local v = numfor(ySlider:GetValue())
		ySlider:SetScript("OnValueChanged", nil)
		ySlider:SetMinMaxValues(v - 200, v + 200)
		ySlider:SetScript("OnValueChanged", ySliderFunc)
		_G[ySlider:GetName() .. "Low"]:SetText(v - 200)
		_G[ySlider:GetName() .. "High"]:SetText(v + 200)
		_G[ySlider:GetName() .. "Text"]:SetText(v)
	end)

	ySliderFunc = function(self)
		local v = numfor(ySlider:GetValue())
		_G[ySlider:GetName() .. "Text"]:SetText(v)

		yEdit:SetText(numfor(ySlider:GetValue()))

		if fe.updating then
			return
		end
		fe:VerifyOpt()
		if not fe.opt.orgPos and fe.editFrame then
			MovAny:StoreOrgPoints(fe.editFrame, fe.opt)
		end
		local updateEditor
		if not fe.opt.pos then
			fe.opt.pos = fe:GeneratePoint()
			updateEditor = true
		end
		if fe.opt.pos[5] ~= self:GetValue() then
			fe.lastY = fe.opt.pos[5]
			fe.opt.pos[5] = self:GetValue()
			fe:WritePoint(updateEditor)
		end
	end
	ySlider:SetScript("OnValueChanged", ySliderFunc)

	local yMinusFunc = function()
		local v = ySlider:GetValue() - 1
		ySlider:SetScript("OnValueChanged", nil)
		ySlider:SetMinMaxValues(v - 200, v + 200)
		ySlider:SetScript("OnValueChanged", ySliderFunc)
		ySlider:SetValue(v)
	end
	local yPlusFunc = function()
		local v = ySlider:GetValue() + 1
		ySlider:SetScript("OnValueChanged", nil)
		ySlider:SetMinMaxValues(v - 200, v + 200)
		ySlider:SetScript("OnValueChanged", ySliderFunc)
		ySlider:SetValue(v)
	end
	ySlider:SetScript("OnMouseWheel", function(self, dir)
		if dir > 0 then
			yPlusFunc()
		else
			yMinusFunc()
		end
	end)

	local yMinusButton = CreateFrame("Button", fn .. "YMinusButton", fe, "MAButtonTemplate")
	yMinusButton:SetSize(20, 20)
	yMinusButton:SetPoint("TOPLEFT", ySlider, "TOPRIGHT", 12, 2)
	yMinusButton:SetText("-")
	yMinusButton:SetScript("OnClick", yMinusFunc)

	local yPlusButton = CreateFrame("Button", fn .. "YPlusButton", fe, "MAButtonTemplate")
	yPlusButton:SetSize(20, 20)
	yPlusButton:SetPoint("TOPLEFT", yMinusButton, "TOPRIGHT", 3, 0)
	yPlusButton:SetText("+")
	yPlusButton:SetScript("OnClick", yPlusFunc)

	local yResetButton = CreateFrame("Button", fn .. "YResetButton", fe, "MAButtonTemplate")
	yResetButton:SetSize(20, 20)
	yResetButton:SetPoint("TOPLEFT", yPlusButton, "TOPRIGHT", 3, 0)
	yResetButton:SetText("R")
	yResetButton:SetScript("OnClick", function()
		local opt = fe:VerifyOpt()
		local p
		if fe.editFrame then
			p = self:GetRelativePoint(self:GetFirstOrgPoint(opt), fe.editFrame)
		else
			p = MovAny:GetFirstOrgPoint(opt)
		end
		if not p then
			return
		end
		p = p[5]

		ySlider:SetScript("OnValueChanged", nil)
		ySlider:SetMinMaxValues(p - 200, p + 200)
		ySlider:SetScript("OnValueChanged", ySliderFunc)
		ySlider:SetValue(p)
	end)

	local yZeroButton = CreateFrame("Button", fn .. "YZeroButton", fe, "MAButtonTemplate")
	yZeroButton:SetSize(20, 20)
	yZeroButton:SetPoint("TOPLEFT", yResetButton, "TOPRIGHT", 3, 0)
	yZeroButton:SetText("0")
	yZeroButton:SetScript("OnClick", function()
		ySlider:SetScript("OnValueChanged", nil)
		ySlider:SetMinMaxValues(-200, 200)
		ySlider:SetScript("OnValueChanged", ySliderFunc)
		ySlider:SetValue(0)
	end)

	local widthLabel = fe:CreateFontString()
	widthLabel:SetFontObject("GameFontNormalSmall")
	widthLabel:SetSize(leftColumnWidth, 18)
	widthLabel:SetJustifyH("LEFT")
	widthLabel:SetPoint("TOPLEFT", yLabel, "BOTTOMLEFT", 0, -13)
	widthLabel:SetText("Width")

	local widthEdit = CreateFrame("EditBox", fn .. "WidthEdit", fe, "InputBoxTemplate")

	local widthSlider = CreateFrame("Slider", fn .. "WidthSlider", fe, "OptionsSliderTemplate")

	widthEdit:SetFontObject("GameFontHighlightSmall")
	widthEdit:SetMaxLetters(10)
	widthEdit:SetSize(59, 20)
	widthEdit:SetJustifyH("CENTER")
	widthEdit:SetAutoFocus(false)
	widthEdit:SetPoint("TOPLEFT", widthLabel, "TOPRIGHT", 12, 0)
	widthEdit:SetText("0")

	local widthSliderFunc
	local widthEditFunc = function(self)
		self:ClearFocus()
		local v = tonumber(widthEdit:GetText())
		if v == nil or v < 1 then
			return
		end

		local lowV = v - 200
		if lowV < 1 then
			lowV = 1
		end
		widthSlider:SetScript("OnValueChanged", nil)
		widthSlider:SetMinMaxValues(lowV, lowV + 400)
		widthSlider:SetValue(v)
		widthSlider:SetScript("OnValueChanged", widthSliderFunc)
		v = numfor(v)
		_G[widthSlider:GetName() .. "Low"]:SetText(numfor(lowV))
		_G[widthSlider:GetName() .. "High"]:SetText(numfor(lowV + 400))
		_G[widthSlider:GetName() .. "Text"]:SetText(v)

		if fe.updating then
			return
		end
		fe:VerifyOpt()

		fe:WriteDimentions()
	end

	widthEdit:SetScript("OnEnterPressed", widthEditFunc)
	widthEdit:SetScript("OnTabPressed", tabFunc(widthEditFunc))
	widthEdit:SetScript("OnEscapePressed", funcClearFocus)

	widthSlider:SetScale(.75)
	widthSlider:SetWidth(535)
	widthSlider:SetMinMaxValues(-200, 200)
	widthSlider:SetValue(0)
	widthSlider:SetValueStep(1)
	widthSlider:SetPoint("TOPLEFT", widthEdit, "TOPRIGHT", 10, -2)
	widthSlider:SetScript("OnMouseUp", function(self)
		local v = widthSlider:GetValue()

		local lowV = v - 200
		if lowV < 1 then
			lowV = 1
		end
		v = numfor(v)
		widthSlider:SetMinMaxValues(lowV, lowV + 400)
		_G[widthSlider:GetName() .. "Low"]:SetText(numfor(lowV))
		_G[widthSlider:GetName() .. "High"]:SetText(numfor(lowV + 400))
		_G[widthSlider:GetName() .. "Text"]:SetText(v)
	end)
	widthSliderFunc = function(self)
		local v = numfor(widthSlider:GetValue())
		_G[widthSlider:GetName() .. "Text"]:SetText(v)

		widthEdit:SetText(numfor(widthSlider:GetValue()))

		if fe.updating then
			return
		end
		fe:VerifyOpt()

		fe:WriteDimentions()
	end
	widthSlider:SetScript("OnValueChanged", widthSliderFunc)

	local widthMinusFunc = function()
		local v = widthSlider:GetValue() - 1
		if v < 1 then
			v = 1
		end
		lowV = v - 200
		if lowV < 1 then
			lowV = 1
		end
		widthSlider:SetScript("OnValueChanged", nil)
		widthSlider:SetMinMaxValues(lowV, lowV + 400)
		widthSlider:SetScript("OnValueChanged", widthSliderFunc)
		widthSlider:SetValue(v)
	end
	local widthPlusFunc = function()
		local v = widthSlider:GetValue() + 1
		if v < 1 then
			v = 1
		end
		lowV = v - 200
		if lowV < 1 then
			lowV = 1
		end
		widthSlider:SetScript("OnValueChanged", nil)
		widthSlider:SetMinMaxValues(lowV, lowV + 400)
		widthSlider:SetScript("OnValueChanged", widthSliderFunc)
		widthSlider:SetValue(v)
	end
	widthSlider:SetScript("OnMouseWheel", function(self, dir)
		if dir > 0 then
			widthPlusFunc()
		else
			widthMinusFunc()
		end
	end)

	local widthMinusButton = CreateFrame("Button", fn .. "WidthMinusButton", fe, "MAButtonTemplate")
	widthMinusButton:SetSize(20, 20)
	widthMinusButton:SetPoint("TOPLEFT", widthSlider, "TOPRIGHT", 12, 2)
	widthMinusButton:SetText("-")
	widthMinusButton:SetScript("OnClick", widthMinusFunc)

	local widthPlusButton = CreateFrame("Button", fn .. "WidthPlusButton", fe, "MAButtonTemplate")
	widthPlusButton:SetSize(20, 20)
	widthPlusButton:SetPoint("TOPLEFT", widthMinusButton, "TOPRIGHT", 3, 0)
	widthPlusButton:SetText("+")
	widthPlusButton:SetScript("OnClick", widthPlusFunc)

	local heightSlider = CreateFrame("Slider", fn .. "HeightSlider", fe, "OptionsSliderTemplate")

	local widthResetButton = CreateFrame("Button", fn .. "WidthResetButton", fe, "MAButtonTemplate")
	widthResetButton:SetSize(20, 20)
	widthResetButton:SetPoint("TOPLEFT", widthPlusButton, "TOPRIGHT", 3, 0)
	widthResetButton:SetText("R")
	widthResetButton:SetScript("OnClick", function()
		local opt = fe:VerifyOpt()
		local p = opt.orgWidth
		if not p then
			return
		end

		local lowV = p - 200
		if lowV < 0 then
			lowV = 0
		end

		widthSlider:SetScript("OnValueChanged", nil)
		widthSlider:SetMinMaxValues(lowV, lowV + 400)
		widthSlider:SetScript("OnValueChanged", widthSliderFunc)
		widthSlider:SetValue(p)

		_G[heightSlider:GetName() .. "Low"]:SetText(numfor(lowV))
		_G[heightSlider:GetName() .. "High"]:SetText(numfor(lowV + 400))
	end)

	local heightLabel = fe:CreateFontString()
	heightLabel:SetFontObject("GameFontNormalSmall")
	heightLabel:SetSize(leftColumnWidth, 18)
	heightLabel:SetJustifyH("LEFT")
	heightLabel:SetPoint("TOPLEFT", widthLabel, "BOTTOMLEFT", 0, -13)
	heightLabel:SetText("Height")

	local heightEdit = CreateFrame("EditBox", fn .. "HeightEdit", fe, "InputBoxTemplate")
	heightEdit:SetFontObject("GameFontHighlightSmall")
	heightEdit:SetMaxLetters(10)
	heightEdit:SetSize(59, 20)
	heightEdit:SetJustifyH("CENTER")
	heightEdit:SetAutoFocus(false)
	heightEdit:SetPoint("TOPLEFT", heightLabel, "TOPRIGHT", 12, 0)
	heightEdit:SetText("0")

	local heightSliderFunc
	local heightEditFunc = function(self)
		self:ClearFocus()
		local v = tonumber(heightEdit:GetText())
		if v == nil or v < 1 then
			return
		end

		local lowV = v - 200
		if lowV < 1 then
			lowV = 1
		end
		heightSlider:SetScript("OnValueChanged", nil)
		heightSlider:SetMinMaxValues(lowV, lowV + 400)
		heightSlider:SetValue(v)

		v = numfor(v)
		_G[heightSlider:GetName() .. "Low"]:SetText(numfor(lowV))
		_G[heightSlider:GetName() .. "High"]:SetText(numfor(lowV + 400))
		_G[heightSlider:GetName() .. "Text"]:SetText(v)
		heightSlider:SetScript("OnValueChanged", heightSliderFunc)
		if fe.updating then
			return
		end
		fe:VerifyOpt()

		fe:WriteDimentions()
	end

	heightEdit:SetScript("OnEnterPressed", heightEditFunc)
	heightEdit:SetScript("OnTabPressed", tabFunc(heightEditFunc))
	heightEdit:SetScript("OnEscapePressed", funcClearFocus)

	heightSlider:SetScale(.75)
	heightSlider:SetWidth(535)
	heightSlider:SetMinMaxValues(-200, 200)
	heightSlider:SetValue(0)
	heightSlider:SetValueStep(1)
	heightSlider:SetPoint("TOPLEFT", heightEdit, "TOPRIGHT", 10, -2)
	heightSlider:SetScript("OnMouseUp", function(self)
		local v = heightSlider:GetValue()

		local lowV = v - 200
		if lowV < 1 then
			lowV = 1
		end
		v = numfor(v)
		heightSlider:SetMinMaxValues(lowV, lowV + 400)
		_G[heightSlider:GetName() .. "Low"]:SetText(numfor(lowV))
		_G[heightSlider:GetName() .. "High"]:SetText(numfor(lowV + 400))
	end)

	heightSliderFunc = function(self)
		local v = numfor(heightSlider:GetValue())
		_G[heightSlider:GetName() .. "Text"]:SetText(v)

		heightEdit:SetText(numfor(heightSlider:GetValue()))

		if fe.updating then
			return
		end
		fe:VerifyOpt()

		fe:WriteDimentions()
	end
	heightSlider:SetScript("OnValueChanged", heightSliderFunc)

	local heightMinusFunc = function()
		local v = heightSlider:GetValue() - 1
		if v < 1 then
			v = 1
		end
		lowV = v - 200
		if lowV < 1 then
			lowV = 1
		end
		heightSlider:SetScript("OnValueChanged", nil)
		heightSlider:SetMinMaxValues(lowV, lowV + 400)
		heightSlider:SetScript("OnValueChanged", heightSliderFunc)
		heightSlider:SetValue(v)
	end
	local heightPlusFunc = function()
		local v = heightSlider:GetValue() + 1
		if v < 1 then
			v = 1
		end
		lowV = v - 200
		if lowV < 1 then
			lowV = 1
		end
		heightSlider:SetScript("OnValueChanged", nil)
		heightSlider:SetMinMaxValues(lowV, lowV + 400)
		heightSlider:SetScript("OnValueChanged", heightSliderFunc)
		heightSlider:SetValue(v)
	end
	heightSlider:SetScript("OnMouseWheel", function(self, dir)
		if dir > 0 then
			heightPlusFunc()
		else
			heightMinusFunc()
		end
	end)

	local heightMinusButton = CreateFrame("Button", fn .. "HeightMinusButton", fe, "MAButtonTemplate")
	heightMinusButton:SetSize(20, 20)
	heightMinusButton:SetPoint("TOPLEFT", heightSlider, "TOPRIGHT", 12, 2)
	heightMinusButton:SetText("-")
	heightMinusButton:SetScript("OnClick", heightMinusFunc)

	local heightPlusButton = CreateFrame("Button", fn .. "HeightPlusButton", fe, "MAButtonTemplate")
	heightPlusButton:SetSize(20, 20)
	heightPlusButton:SetPoint("TOPLEFT", heightMinusButton, "TOPRIGHT", 3, 0)
	heightPlusButton:SetText("+")
	heightPlusButton:SetScript("OnClick", heightPlusFunc)

	local heightResetButton = CreateFrame("Button", fn .. "HeightResetButton", fe, "MAButtonTemplate")
	heightResetButton:SetSize(20, 20)
	heightResetButton:SetPoint("TOPLEFT", heightPlusButton, "TOPRIGHT", 3, 0)
	heightResetButton:SetText("R")
	heightResetButton:SetScript("OnClick", function()
		local opt = fe:VerifyOpt()
		local p = opt.orgHeight
		if not p then
			return
		end

		local lowV = p - 200
		if lowV < 1 then
			lowV = 1
		end

		heightSlider:SetScript("OnValueChanged", nil)
		heightSlider:SetMinMaxValues(lowV, lowV + 400)
		heightSlider:SetScript("OnValueChanged", heightSliderFunc)
		heightSlider:SetValue(p)
		local v = heightSlider:GetValue()

		_G[heightSlider:GetName() .. "Low"]:SetText(numfor(lowV))
		_G[heightSlider:GetName() .. "High"]:SetText(numfor(lowV + 400))
	end)

	local scaleLabel = fe:CreateFontString()
	scaleLabel:SetFontObject("GameFontNormalSmall")
	scaleLabel:SetSize(leftColumnWidth, 20)
	scaleLabel:SetJustifyH("LEFT")
	scaleLabel:SetPoint("TOPLEFT", heightLabel, "BOTTOMLEFT", 0, -20)
	scaleLabel:SetText("Scale:")

	local scaleEdit = CreateFrame("EditBox", fn .. "ScaleEdit", fe, "InputBoxTemplate")

	local scaleSlider = CreateFrame("Slider", fn .. "ScaleSlider", fe, "OptionsSliderTemplate")

	scaleEdit:SetFontObject("GameFontHighlightSmall")
	scaleEdit:SetMaxLetters(6)
	scaleEdit:SetSize(59, 20)
	scaleEdit:SetJustifyH("CENTER")
	scaleEdit:SetAutoFocus(false)
	scaleEdit:SetPoint("TOPLEFT", scaleLabel, "TOPRIGHT", 12, 0)
	scaleEdit:SetText("1")

	local scaleSliderFunc
	local scaleEditFunc = function(self)
		self:ClearFocus()
		local v = tonumber(self:GetText())
		if not v then
			return
		end
		_G[scaleSlider:GetName() .. "Text"]:SetText(v)

		scaleSlider:SetScript("OnValueChanged", nil)
		scaleSlider:SetValue(v)
		scaleSlider:SetScript("OnValueChanged", scaleSliderFunc)

		if fe.updating then
			return
		end
		fe:VerifyOpt()
		if fe.opt.scale ~= tonumber(self:GetText()) then
			scaleSlider:SetValue(tonumber(self:GetText()))
			fe:WriteScale()
		end
	end
	scaleEdit:SetScript("OnEnterPressed", scaleEditFunc)
	scaleEdit:SetScript("OnTabPressed", tabFunc(scaleEditFunc))
	scaleEdit:SetScript("OnEscapePressed", funcClearFocus)

	scaleSlider:SetScale(.75)
	scaleSlider:SetWidth(535)
	scaleSlider:SetMinMaxValues(0, 10)
	scaleSlider:SetValue(1)
	scaleSlider:SetValueStep(.01)
	scaleSlider:SetPoint("TOPLEFT", scaleEdit, "TOPRIGHT", 10, -2)
	scaleSlider:SetScript("OnMouseUp", function(self) _G[self:GetName() .. "Text"]:SetText(numfor(self:GetValue(), 2)) end)
	_G[scaleSlider:GetName() .. "Low"]:SetText("0")
	_G[scaleSlider:GetName() .. "High"]:SetText("10")

	scaleSliderFunc = function(self)
		if not self.GetValue then
			return
		end
		local v = numfor(self:GetValue(), 2)
		_G[self:GetName() .. "Text"]:SetText(v)

		scaleEdit:SetText(v)

		if fe.updating then
			return
		end
		fe:VerifyOpt()
		if fe.opt.scale ~= self:GetValue() then
			--fe.opt.scale = self:GetValue()
			fe:WriteScale()
		end
	end
	scaleSlider:SetScript("OnValueChanged", scaleSliderFunc)

	local scaleMinusFunc = function()
		local v = scaleSlider:GetValue() - .01
		if v < 0 then
			v = 0
		end
		scaleSlider:SetValue(v)
	end
	local scalePlusFunc = function()
		local v = scaleSlider:GetValue() + .01
		if v < 0 then
			v = 0
		end
		scaleSlider:SetValue(v)
	end
	scaleSlider:SetScript("OnMouseWheel", function(self, dir)
		if dir > 0 then
			scalePlusFunc()
		else
			scaleMinusFunc()
		end
	end)

	local scaleMinusButton = CreateFrame("Button", fn .. "ScaleMinusButton", fe, "MAButtonTemplate")
	scaleMinusButton:SetSize(20, 20)
	scaleMinusButton:SetPoint("TOPLEFT", scaleSlider, "TOPRIGHT", 12, 2)
	scaleMinusButton:SetText("-")
	scaleMinusButton:SetScript("OnClick", scaleMinusFunc)

	local scalePlusButton = CreateFrame("Button", fn .. "ScalePlusButton", fe, "MAButtonTemplate")
	scalePlusButton:SetSize(20, 20)
	scalePlusButton:SetPoint("TOPLEFT", scaleMinusButton, "TOPRIGHT", 3, 0)
	scalePlusButton:SetText("+")
	scalePlusButton:SetScript("OnClick", scalePlusFunc)

	local scaleResetButton = CreateFrame("Button", fn .. "ScaleResetButton", fe, "MAButtonTemplate")
	scaleResetButton:SetSize(20, 20)
	scaleResetButton:SetPoint("TOPLEFT", scalePlusButton, "TOPRIGHT", 3, 0)
	scaleResetButton:SetText("R")
	scaleResetButton:SetScript("OnClick", function()
		local opt = fe:VerifyOpt()
		local p = opt.orgScale
		if not p then
			return
		end
		scaleSlider:SetValue(p)
	end)

	local scaleOneButton = CreateFrame("Button", fn .. "ScaleOneButton", fe, "MAButtonTemplate")
	scaleOneButton:SetSize(20, 20)
	scaleOneButton:SetPoint("TOPLEFT", scaleResetButton, "TOPRIGHT", 3, 0)
	scaleOneButton:SetText("1")
	scaleOneButton:SetScript("OnClick", function() scaleSlider:SetValue(1) end)

	local alphaLabel = fe:CreateFontString()
	alphaLabel:SetFontObject("GameFontNormalSmall")
	alphaLabel:SetSize(leftColumnWidth, 20)
	alphaLabel:SetJustifyH("LEFT")
	alphaLabel:SetPoint("TOPLEFT", scaleLabel, "BOTTOMLEFT", 0, -2)
	alphaLabel:SetText("Alpha:")

	local alphaEdit = CreateFrame("EditBox", fn .. "AlphaEdit", fe, "InputBoxTemplate")

	local alphaSlider = CreateFrame("Slider", fn .. "AlphaSlider", fe, "OptionsSliderTemplate")

	alphaEdit:SetFontObject("GameFontHighlightSmall")
	alphaEdit:SetMaxLetters(5)
	alphaEdit:SetSize(59, 20)
	alphaEdit:SetJustifyH("CENTER")
	alphaEdit:SetAutoFocus(false)
	alphaEdit:SetPoint("TOPLEFT", alphaLabel, "TOPRIGHT", 12, 0)
	alphaEdit:SetText("100")

	local alphaSliderFunc
	local alphaEditFunc = function(self)
		self:ClearFocus()
		local v = tonumber(self:GetText())
		if v == nil then
			return
		end
		if v > 100 then
			v = 100
			self:SetText(v)
		elseif v < 0 then
			v = 0
			self:SetText(v)
		end
		_G[alphaSlider:GetName() .. "Text"]:SetText(v .. "%")

		alphaSlider:SetScript("OnValueChanged", nil)
		alphaSlider:SetValue(v / 100)
		alphaSlider:SetScript("OnValueChanged", alphaSliderFunc)

		if fe.updating then
			return
		end
		fe:WriteAlpha()
	end
	alphaEdit:SetScript("OnEnterPressed", alphaEditFunc)
	alphaEdit:SetScript("OnTabPressed", tabFunc(alphaEditFunc))
	alphaEdit:SetScript("OnEscapePressed", funcClearFocus)

	alphaSlider:SetScale(.75)
	alphaSlider:SetWidth(535)
	alphaSlider:SetMinMaxValues(0, 1)
	alphaSlider:SetValue(1)
	alphaSlider:SetValueStep(.01)
	alphaSlider:SetPoint("TOPLEFT", alphaEdit, "TOPRIGHT", 10, -2)
	alphaSlider:SetScript("OnMouseUp", function(self) _G[self:GetName() .. "Text"]:SetText(numfor(alphaSlider:GetValue() * 100, 0) .. "%") end)

	alphaSliderFunc = function(self)
		local v = numfor(alphaSlider:GetValue() * 100, 0)
		_G[self:GetName() .. "Text"]:SetText(v .. "%")
		alphaEdit:SetText(v)

		if fe.updating then
			return
		end
		fe:WriteAlpha()
	end
	alphaSlider:SetScript("OnValueChanged", alphaSliderFunc)
	_G[alphaSlider:GetName() .. "Low"]:SetText("0%")
	_G[alphaSlider:GetName() .. "High"]:SetText("100%")

	local alphaMinusFunc = function()
		local v = alphaSlider:GetValue() - .01
		if v < 0 then
			v = 0
		end
		alphaSlider:SetValue(v)
	end
	local alphaPlusFunc = function()
		local v = alphaSlider:GetValue() + .01
		if v < 0 then
			v = 0
		end
		alphaSlider:SetValue(v)
	end
	alphaSlider:SetScript("OnMouseWheel", function(self, dir)
		if dir > 0 then
			alphaPlusFunc()
		else
			alphaMinusFunc()
		end
	end)

	local alphaMinusButton = CreateFrame("Button", fn .. "AlphaMinusButton", fe, "MAButtonTemplate")
	alphaMinusButton:SetSize(20, 20)
	alphaMinusButton:SetPoint("TOPLEFT", alphaSlider, "TOPRIGHT", 12, 2)
	alphaMinusButton:SetText("-")
	alphaMinusButton:SetScript("OnClick", alphaMinusFunc)

	local alphaPlusButton = CreateFrame("Button", fn .. "AlphaPlusButton", fe, "MAButtonTemplate")
	alphaPlusButton:SetSize(20, 20)
	alphaPlusButton:SetPoint("TOPLEFT", alphaMinusButton, "TOPRIGHT", 3, 0)
	alphaPlusButton:SetText("+")
	alphaPlusButton:SetScript("OnClick", alphaPlusFunc)

	local alphaResetButton = CreateFrame("Button", fn .. "AlphaResetButton", fe, "MAButtonTemplate")
	alphaResetButton:SetSize(20, 20)
	alphaResetButton:SetPoint("TOPLEFT", alphaPlusButton, "TOPRIGHT", 3, 0)
	alphaResetButton:SetText("R")
	alphaResetButton:SetScript("OnClick", function()
		local opt = fe:VerifyOpt()
		local p = opt.orgAlpha
		if not p then
			return
		end
		alphaSlider:SetValue(p)
	end)

	local alphaFullButton = CreateFrame("Button", fn .. "AlphaFullButton", fe, "MAButtonTemplate")
	alphaFullButton:SetSize(20, 20)
	alphaFullButton:SetPoint("TOPLEFT", alphaResetButton, "TOPRIGHT", 3, 0)
	alphaFullButton:SetText("1")
	alphaFullButton:SetScript("OnClick", function() alphaSlider:SetValue(1) end)

	local hideArtworkCheck = CreateFrame("CheckButton", fn .. "HideLayerArtwork", fe, "MACheckButtonTemplate")
	local hideBackgroundCheck = CreateFrame("CheckButton", fn .. "HideLayerBackground", fe, "MACheckButtonTemplate")
	local hideBorderCheck = CreateFrame("CheckButton", fn .. "HideLayerBorder", fe, "MACheckButtonTemplate")
	local hideHighlightCheck = CreateFrame("CheckButton", fn .. "HideLayerHighlight", fe, "MACheckButtonTemplate")
	local hideOverlayCheck = CreateFrame("CheckButton", fn .. "HideLayerOverlay", fe, "MACheckButtonTemplate")

	local hideLayerFunc = function(self)
		local opt = fe:VerifyOpt()

		if fe.editFrame and not opt.disabled then
			MovAny:ResetLayers(fe.editFrame, opt, true)
		end

		if self == hideArtworkCheck then
			opt.disableLayerArtwork = self:GetChecked()
		elseif self == hideBackgroundCheck then
			opt.disableLayerBackground = self:GetChecked()
		elseif self == hideBorderCheck then
			opt.disableLayerBorder = self:GetChecked()
		elseif self == hideHighlightCheck then
			opt.disableLayerHighlight = self:GetChecked()
		elseif self == hideOverlayCheck then
			opt.disableLayerOverlay = self:GetChecked()
		end

		if fe.editFrame and not opt.disabled then
			MovAny:ApplyLayers(fe.editFrame, opt)
		end

		MovAny:UpdateGUIIfShown(true)
	end

	local hideLayersHeading = fe:CreateFontString()
	hideLayersHeading:SetFontObject("GameFontNormalSmall")
	hideLayersHeading:SetSize(85, 20)
	hideLayersHeading:SetJustifyH("LEFT")
	hideLayersHeading:SetPoint("TOPLEFT", alphaLabel, "BOTTOMLEFT", 0, -10)
	hideLayersHeading:SetText("Hide Layer")

	local layersResetButton = CreateFrame("Button", fn .. "PointResetButton", fe, "MAButtonTemplate")
	layersResetButton:SetSize(20, 20)
	layersResetButton:SetPoint("TOPLEFT", hideLayersHeading, "TOPRIGHT", 0, -1)
	layersResetButton:SetText("R")
	layersResetButton:SetScript("OnClick", function()
		local opt = fe:VerifyOpt()
		if fe.editFrame and opt then
			if opt.disabled then
				opt.disableLayerArtwork = nil
				opt.disableLayerBackground = nil
				opt.disableLayerBorder = nil
				opt.disableLayerHighlight = nil
				opt.disableLayerOverlay = nil
			else
				MovAny:ResetLayers(fe.editFrame, opt)
			end
		end
		hideArtworkCheck:SetChecked(nil)
		hideBackgroundCheck:SetChecked(nil)
		hideBorderCheck:SetChecked(nil)
		hideHighlightCheck:SetChecked(nil)
		hideOverlayCheck:SetChecked(nil)

		MovAny:UpdateGUIIfShown(true)
	end)

	hideArtworkCheck:SetPoint("TOPLEFT", hideLayersHeading, "BOTTOMLEFT", 4, -2)
	hideArtworkCheck:SetScript("OnClick", hideLayerFunc)
	_G[hideArtworkCheck:GetName() .. "Text"]:SetText("Artwork")

	hideBackgroundCheck:SetPoint("TOPLEFT", hideArtworkCheck, "BOTTOMLEFT", 0, -1)
	hideBackgroundCheck:SetScript("OnClick", hideLayerFunc)
	_G[hideBackgroundCheck:GetName() .. "Text"]:SetText("Background")

	hideBorderCheck:SetPoint("TOPLEFT", hideBackgroundCheck, "BOTTOMLEFT", 0, -1)
	hideBorderCheck:SetScript("OnClick", hideLayerFunc)
	_G[hideBorderCheck:GetName() .. "Text"]:SetText("Border")

	hideHighlightCheck:SetPoint("TOPLEFT", hideBorderCheck, "BOTTOMLEFT", 0, -1)
	hideHighlightCheck:SetScript("OnClick", hideLayerFunc)
	_G[hideHighlightCheck:GetName() .. "Text"]:SetText("Highlight")

	hideOverlayCheck:SetPoint("TOPLEFT", hideHighlightCheck, "BOTTOMLEFT", 0, -1)
	hideOverlayCheck:SetScript("OnClick", hideLayerFunc)
	_G[hideOverlayCheck:GetName() .. "Text"]:SetText("Overlay")

	local strataLabel = fe:CreateFontString()
	strataLabel:SetFontObject("GameFontNormalSmall")
	strataLabel:SetSize(35, 20)
	strataLabel:SetJustifyH("LEFT")
	strataLabel:SetPoint("TOPLEFT", layersResetButton, "TOPRIGHT", 30, 0)
	strataLabel:SetText("Strata:")

	local strataDropDownButton = CreateFrame("Button", fn .. "Strata", fe, "UIDropDownMenuTemplate")
	strataDropDownButton:SetID(3)
	strataDropDownButton:SetScript("OnClick", dropDownClickFunc)

	local strataFunc = function(self)
		UIDropDownMenu_SetSelectedValue(strataDropDownButton, self.value)

		local opt = fe:VerifyOpt()
		if opt.frameStrata ~= self.value then
			opt.frameStrata = self.value

			local editFrame = fe.editFrame
			if editFrame and not opt.disabled then
				if not opt.orgFrameStrata then
					opt.orgFrameStrata = editFrame:GetFrameStrata()
				end
				if not InCombatLockdown() or not MovAny:IsProtected(editFrame) then
					editFrame:SetFrameStrata(opt.frameStrata)
				else
					local closure = function(f, fs)
						return function()
							if MovAny:IsProtected(f) and InCombatLockdown() then
								return true
							end
							f:SetFrameStrata(fs)
						end
					end
					MovAny.pendingActions[fe.o.name .. ":SetFrameStrata"] = closure(editFrame, opt.frameStrata)
				end
			end

			MovAny:UpdateGUIIfShown(true)
		end
	end

	local strataDropDown_MenuInit = function()
		local frameStrata = (fe.opt and fe.opt.frameStrata) or (fe.editFrame and fe.editFrame:GetFrameStrata()) or nil

		local info
		for _, infoTab in pairs(MovAny.DDMStrataList) do
			info = UIDropDownMenu_CreateInfo()
			info.text = infoTab.text
			info.value = infoTab.value
			info.func = strataFunc

			if frameStrata == infoTab.value then
				info.checked = true
			end
			UIDropDownMenu_AddButton(info)
		end
	end

	strataDropDownButton:SetPoint("TOPLEFT", strataLabel, "TOPRIGHT", -12, 1)
	UIDropDownMenu_Initialize(strataDropDownButton, strataDropDown_MenuInit)
	UIDropDownMenu_SetWidth(strataDropDownButton, 130)

	local strataResetButton = CreateFrame("Button", fn .. "StrataResetButton", fe, "MAButtonTemplate")
	strataResetButton:SetSize(20, 20)
	strataResetButton:SetPoint("TOPLEFT", strataDropDownButton, "TOPRIGHT", 0, -2.5)
	strataResetButton:SetText("R")
	strataResetButton:SetScript("OnClick", function()
		local opt = fe:VerifyOpt()
		local fs = opt.orgFrameStrata
		local editFrame = fe.editFrame
		if not fs then
			return
		end

		if strataDropDownButton:GetText() ~= fs then
			if editFrame and not opt.disabled then
				if not InCombatLockdown() or not MovAny:IsProtected(editFrame) then
					editFrame:SetFrameStrata(fs)
				else
					local closure = function(f, fs)
						return function()
							if MovAny:IsProtected(f) and InCombatLockdown() then
								return true
							end
							f:SetFrameStrata(fs)
						end
					end
					MovAny.pendingActions[fe.o.name .. ":SetFrameStrata"] = closure(editFrame, fs)
				end
			end
			opt.frameStrata = fs

			UIDropDownMenu_Initialize(strataDropDownButton, strataDropDown_MenuInit)
			UIDropDownMenu_SetSelectedValue(strataDropDownButton, fs)

			opt.orgFrameStrata = nil
			opt.frameStrata = nil
		end

		MovAny:UpdateGUIIfShown(true)
	end)

	local unregisterAllEventsCheck = CreateFrame("CheckButton", fn .. "UnregAllEventsCheckButton", fe, "MACheckButtonTemplate")
	unregisterAllEventsCheck:SetPoint("TOPLEFT", strataLabel, "BOTTOMLEFT", 0, -20)
	unregisterAllEventsCheck:SetScript("OnClick", function(self)
		if not self:GetChecked() or (type(self.confirm) == "number" and self.confirm + 5 >= time()) then
			fe:VerifyOpt()
			local opt = fe.opt

			if opt.unregisterAllEvents then
				opt.unregisterAllEvents = nil
			else
				opt.unregisterAllEvents = true
				if fe.editFrame then
					fe.editFrame:UnregisterAllEvents()
				end
			end
			self.confirm = nil
			MovAny:UpdateGUIIfShown(true)
		else
			self.confirm = time()
			MovAny_Print(L.FE_UNREGISTER_ALL_EVENTS_CONFIRM)

			self:SetChecked(not self:GetChecked())
		end
	end)
	unregisterAllEventsCheck.tooltipText = L.FE_UNREGISTER_ALL_EVENTS_TOOLTIP
	_G[unregisterAllEventsCheck:GetName() .. "Text"]:SetText("Unregister all events")

	local forcedLockPointCheck = CreateFrame("CheckButton", fn .. "ForcedLockCheckButton", fe, "MACheckButtonTemplate")
	forcedLockPointCheck:SetPoint("TOPLEFT", unregisterAllEventsCheck, "BOTTOMLEFT", 0, -2)
	forcedLockPointCheck:SetScript("OnClick", function(self)
		if not self:GetChecked() or (type(self.confirm) == "number" and self.confirm + 5 >= time()) then
			fe:VerifyOpt()
			local opt = fe.opt

			if opt.forcedLock then
				opt.forcedLock = nil
			else
				opt.forcedLock = true
				if fe.editFrame then
					fe.editFrame.MASetPoint = fe.editFrame.SetPoint
					fe.editFrame.SetPoint = MovAny.fVoid
				end
			end
			self.confirm = nil
			MovAny:UpdateGUIIfShown(true)
		else
			self.confirm = time()
			MovAny_Print(L.FE_FORCED_LOCK_POSITION_CONFIRM)

			self:SetChecked(not self:GetChecked())
		end
	end)
	forcedLockPointCheck.tooltipText = L.FE_FORCED_LOCK_POSITION_TOOLTIP
	_G[forcedLockPointCheck:GetName() .. "Text"]:SetText("Force lock position")

	local revertButton = CreateFrame("Button", fn .. "RevertButton", fe, "MAButtonTemplate")
	revertButton:SetSize(75, 22)
	revertButton:SetPoint("TOPLEFT", fe, "BOTTOMRIGHT", -180, 140)
	revertButton:SetText("Revert")
	revertButton.tooltipText = "Revert to the modifications this element had when this editor was opened"
	revertButton:SetScript("OnClick", function()
		if fe.editFrame and (InCombatLockdown() and MovAny:IsProtected(fe.editFrame)) then
			MovAny_Print(string.format(L.FRAME_PROTECTED_DURING_COMBAT, fe.o.name))
		else
			if fe.editFrame then
				MovAny:UnhookFrame(fe.editFrame, MovAny:GetFrameOptions(fe.o.name), true)
			end
			local opt = MA_tdeepcopy(fe.initialOpt)
			MovAny.frameOptions[fe.o.name] = opt
			fe.opt = opt
			MovAny:SyncFrame(fe.o.name, opt, true)
			fe:UpdateEditor()
		end
	end)

	local resetButton = CreateFrame("Button", fn .. "ResetButton", fe, "MAButtonTemplate")
	resetButton:SetSize(75, 22)
	resetButton:SetPoint("TOPLEFT", revertButton, "BOTTOMLEFT", 0, -10)
	resetButton:SetText("Reset")
	resetButton.tooltipText = "Reset element"
	resetButton:SetScript("OnClick", function()
		if not fe.editFrame then return end
		MovAny:ResetFrameConfirm(fe.o.name)
	end)

	local exportButton = CreateFrame("Button", fn .. "ExportButton", fe, "MAButtonTemplate")
	exportButton:SetSize(75, 22)
	exportButton:SetPoint("TOPLEFT", resetButton, "BOTTOMLEFT", 0, -10)
	exportButton:SetText("Export")
	exportButton:SetScript("OnClick", function() MovAny:PortDialog(2, fe.fn) end)

	local syncButton = CreateFrame("Button", fn .. "SyncButton", fe, "MAButtonTemplate")
	syncButton:SetSize(75, 22)
	syncButton:SetPoint("TOPLEFT", exportButton, "BOTTOMLEFT", 0, -10)
	syncButton:SetText("Sync")
	syncButton:Disable()
	syncButton.tooltipText = "Synchronize all modifications"
	syncButton:SetScript("OnClick", function()
		if fe.editFrame then
			MovAny:SyncFrame(fe.o.name)
		end
	end)

	local moverButton = CreateFrame("Button", fn .. "MoverButton", fe, "MAButtonTemplate")
	moverButton:SetSize(75, 22)
	moverButton:SetPoint("TOPLEFT", revertButton, "TOPRIGHT", 10, 0)
	moverButton:SetText("Mover")
	moverButton.tooltipText = "Toggles a mover on/off for the frame"
	moverButton:SetScript("OnClick", function(self)
		MovAny:ToggleMove(fe.o.name)
		fe:UpdateButtons()
	end)

	local showButton = CreateFrame("Button", fn .. "ShowButton", fe, "MAButtonTemplate")
	showButton:SetSize(75, 22)
	showButton:SetPoint("TOPLEFT", moverButton, "BOTTOMLEFT", 0, -10)
	showButton:SetText("Show")
	showButton.tooltipText = 'Toggles visibility of the frame, any change is not permanent. For permanent hiding use the "Hidden" checkbox'
	showButton:SetScript("OnClick", function(self)
		local opt = fe.opt
		local f = fe.editFrame
		if not f then
			return
		end
		if not MovAny:IsProtected(f) or not InCombatLockdown() then
			if f:IsShown() then
				if (opt and opt.UIPanelWindows) or UIPanelWindows[f:GetName()] then
					HideUIPanel(f)
				else
					f:Hide()
				end
			else
				if (opt and opt.UIPanelWindows) or UIPanelWindows[f:GetName()] then
					ShowUIPanel(f)
				else
					f:Show()
				end
			end
			fe:UpdateButtons()
		else
			MovAny_Print(string.format(L.FRAME_PROTECTED_DURING_COMBAT, f:GetName()))
		end
	end)

	local importButton = CreateFrame("Button", fn .. "ImportButton", fe, "MAButtonTemplate")
	importButton:SetSize(75, 22)
	importButton:SetPoint("TOPLEFT", showButton, "BOTTOMLEFT", 0, -10)
	importButton:SetText("Import")
	importButton:SetScript("OnClick", function() MovAny:PortDialog(1, fe.fn) end)

	local actualsHeading = fe:CreateFontString()
	actualsHeading:SetFontObject("GameFontNormalSmall")
	actualsHeading:SetSize(140, 20)
	actualsHeading:SetJustifyH("LEFT")
	actualsHeading:SetPoint("TOPRIGHT", fe, "TOPRIGHT", -25, -4)
	actualsHeading:SetText("Absolute values")

	local infoTextWidthLabel = fe:CreateFontString()
	infoTextWidthLabel:SetFontObject("GameFontNormalSmall")
	infoTextWidthLabel:SetSize(leftColumnWidth, 16)
	infoTextWidthLabel:SetJustifyH("RIGHT")
	infoTextWidthLabel:SetPoint("TOPLEFT", actualsHeading, "BOTTOMLEFT", -55, -1)
	infoTextWidthLabel:SetText("Width:")

	local infoTextWidth = fe:CreateFontString()
	infoTextWidth:SetFontObject("GameFontNormalSmall")
	infoTextWidth:SetSize(60, 16)
	infoTextWidth:SetJustifyH("LEFT")
	infoTextWidth:SetPoint("TOPLEFT", infoTextWidthLabel, "TOPRIGHT", 3, 0)

	local infoTextXLabel = fe:CreateFontString()
	infoTextXLabel:SetFontObject("GameFontNormalSmall")
	infoTextXLabel:SetSize(leftColumnWidth, 16)
	infoTextXLabel:SetJustifyH("RIGHT")
	infoTextXLabel:SetPoint("TOPLEFT", infoTextWidthLabel, "BOTTOMLEFT", 0, -1)
	infoTextXLabel:SetText("X:")

	local infoTextX = fe:CreateFontString()
	infoTextX:SetFontObject("GameFontNormalSmall")
	infoTextX:SetSize(60, 16)
	infoTextX:SetJustifyH("LEFT")
	infoTextX:SetPoint("TOPLEFT", infoTextXLabel, "TOPRIGHT", 3, 0)

	local infoTextAlphaLabel = fe:CreateFontString()
	infoTextAlphaLabel:SetFontObject("GameFontNormalSmall")
	infoTextAlphaLabel:SetSize(leftColumnWidth, 16)
	infoTextAlphaLabel:SetJustifyH("RIGHT")
	infoTextAlphaLabel:SetPoint("TOPLEFT", infoTextXLabel, "BOTTOMLEFT", 0, -1)
	infoTextAlphaLabel:SetText("Alpha:")

	local infoTextAlpha = fe:CreateFontString()
	infoTextAlpha:SetFontObject("GameFontNormalSmall")
	infoTextAlpha:SetSize(60, 16)
	infoTextAlpha:SetJustifyH("LEFT")
	infoTextAlpha:SetPoint("TOPLEFT", infoTextAlphaLabel, "TOPRIGHT", 3, 0)

	local infoTextHeightLabel = fe:CreateFontString()
	infoTextHeightLabel:SetFontObject("GameFontNormalSmall")
	infoTextHeightLabel:SetSize(leftColumnWidth, 16)
	infoTextHeightLabel:SetJustifyH("RIGHT")
	infoTextHeightLabel:SetPoint("TOPLEFT", actualsHeading, "BOTTOMLEFT", 55, -1)
	infoTextHeightLabel:SetText("Height:")

	local infoTextHeight = fe:CreateFontString()
	infoTextHeight:SetFontObject("GameFontNormalSmall")
	infoTextHeight:SetSize(60, 16)
	infoTextHeight:SetJustifyH("LEFT")
	infoTextHeight:SetPoint("TOPLEFT", infoTextHeightLabel, "TOPRIGHT", 3, 0)

	local infoTextYLabel = fe:CreateFontString()
	infoTextYLabel:SetFontObject("GameFontNormalSmall")
	infoTextYLabel:SetSize(leftColumnWidth, 16)
	infoTextYLabel:SetJustifyH("RIGHT")
	infoTextYLabel:SetPoint("TOPLEFT", infoTextHeightLabel, "BOTTOMLEFT", 0, -1)
	infoTextYLabel:SetText("Y:")

	local infoTextY = fe:CreateFontString()
	infoTextY:SetFontObject("GameFontNormalSmall")
	infoTextY:SetSize(60, 16)
	infoTextY:SetJustifyH("LEFT")
	infoTextY:SetPoint("TOPLEFT", infoTextYLabel, "TOPRIGHT", 3, 0)

	local infoTextScaleLabel = fe:CreateFontString()
	infoTextScaleLabel:SetFontObject("GameFontNormalSmall")
	infoTextScaleLabel:SetSize(leftColumnWidth, 16)
	infoTextScaleLabel:SetJustifyH("RIGHT")
	infoTextScaleLabel:SetPoint("TOPLEFT", infoTextYLabel, "BOTTOMLEFT", 0, -1)
	infoTextScaleLabel:SetText("Scale:")

	local infoTextScale = fe:CreateFontString()
	infoTextScale:SetFontObject("GameFontNormalSmall")
	infoTextScale:SetSize(60, 16)
	infoTextScale:SetJustifyH("LEFT")
	infoTextScale:SetPoint("TOPLEFT", infoTextScaleLabel, "TOPRIGHT", 3, 0)

	posResetButton:SetScript("OnClick", function()
		local opt = fe:VerifyOpt()
		if not opt.pos then
			return
		end
		if fe.editFrame then
			MovAny:ResetPosition(fe.editFrame, opt)
		else
			opt.pos = nil
		end

		fe.updating = true

		if fe.editFrame then
			local mover = MovAny:GetMoverByFrame(fe.o.name)
			if mover then
				p = {mover:GetPoint()}
			else
				p = {fe.editFrame:GetPoint()}
			end
		else
			p = {"TOPLEFT", "UIParent", "TOPLEFT", 0, 0}
		end
		UIDropDownMenu_Initialize(pointDropDownButton, pointDropDown_MenuInit)
		UIDropDownMenu_SetSelectedValue(pointDropDownButton, p[1] or "TOPLEFT")

		local relPoint = p[3] or p[1] or "TOPLEFT"
		UIDropDownMenu_Initialize(relPointDropDownButton, relPointDropDown_MenuInit)
		UIDropDownMenu_SetSelectedValue(relPointDropDownButton, relPoint)

		local relativeTo = "UIParent"
		if p[2] then
			if type(p[2]) == "string" then
				relativeTo = p[2]
			elseif type(p[2]) == "table" and p[2]:GetName() then
				relativeTo = p[2]:GetName()
			end
		end
		relToEdit:SetText(relativeTo)

		local v = tonumber(numfor(p[4])) or 0
		xSlider:SetScript("OnValueChanged", nil)
		xSlider:SetMinMaxValues(v - 200, v + 200)
		_G[xSlider:GetName() .. "Low"]:SetText(v - 200)
		_G[xSlider:GetName() .. "High"]:SetText(v + 200)
		_G[xSlider:GetName() .. "Text"]:SetText(v)
		xSlider:SetValue(v)
		xSlider:SetScript("OnValueChanged", xSliderFunc)
		xEdit:SetText(v)

		v = tonumber(numfor(p[5])) or 0
		ySlider:SetMinMaxValues(v - 200, v + 200)
		ySlider:SetMinMaxValues(v - 200, v + 200)
		_G[ySlider:GetName() .. "Low"]:SetText(v - 200)
		_G[ySlider:GetName() .. "High"]:SetText(v + 200)
		_G[ySlider:GetName() .. "Text"]:SetText(v)
		ySlider:SetValue(v)
		ySlider:SetScript("OnValueChanged", ySliderFunc)
		yEdit:SetText(v)

		fe.updating = nil
	end)

	fe.LoadFrame = function(self, name)
		if self.o then
			MovAny.frameEditors[self.o.name] = nil
		end
		if MovAny.lRunOnceBeforeInteract[name] then
			if not MovAny.lRunOnceBeforeInteract[name]() then
				MovAny.lRunOnceBeforeInteract[name] = nil
			end
		end

		self.lastX = nil
		self.lastY = nil

		self.editFrame = _G[name]
		self.opt = MovAny:GetFrameOptions(name, nil, true)
		self.o = MovAny:GetFrame(name)

		if not self.o then
			if self.editFrame then
				MovAny:AddFrameToMovableList(name, name)
				self.o = MovAny:GetFrame(name)
				if not self.o then
					self:CloseDialog()
					return
				end
			else
				self:CloseDialog()
				return
			end
		end

		fe.fn = name

		self.initialOpt = MA_tdeepcopy(self.opt)

		MovAny.frameEditors[name] = self
		self:UpdateEditor()
	end

	fe.UpdateEditor = function()
		fe.updating = true

		local o = fe.o
		local fn = o.name
		local opt = MovAny:GetFrameOptions(fn)
		fe.opt = opt
		local editFrame = fe.editFrame

		wipe(tabList)

		fe.frameHeight = 490

		realName:SetText(fn)
		helpfulName:SetText(o.helpfulName)

		enabledCheck:SetChecked(not opt or not opt.disabled)

		if not MovAny.NoHide[fn] then
			hideCheck:Show()
			hideCheck:SetChecked(opt and opt.hidden)
		else
			hideCheck:Hide()
		end

		if not editFrame or editFrame.IsClampedToScreen then
			clampToScreenCheck:Show()
			clampToScreenCheck:SetChecked((opt and opt.clampToScreen) or (editFrame and editFrame:IsClampedToScreen()))
		else
			clampToScreenCheck:Hide()
		end

		for i = 1, 13, 1 do
			_G[fe:GetName() .. "Group" .. i]:SetChecked(type(opt) == "table" and type(opt.groups) == "table" and opt.groups[i] and true or nil)
		end

		local nextPoint = {"TOPLEFT", groupLabel, "BOTTOMLEFT", 0, -10}

		nextPoint = fe:UpdatePointControls(nextPoint)
		nextPoint = fe:UpdateScale(nextPoint)

		if not MovAny.NoAlpha[fn] then
			alphaLabel:SetPoint(unpack(nextPoint))
			nextPoint = {"TOPLEFT", alphaLabel, "BOTTOMLEFT", 0, -20}

			alphaLabel:Show()
			alphaEdit:Show()
			alphaSlider:Show()
			alphaMinusButton:Show()
			alphaPlusButton:Show()
			alphaResetButton:Show()
			alphaFullButton:Show()

			local alpha = opt and opt.alpha or 1
			alphaSlider:SetValue(alpha)
			_G[alphaSlider:GetName() .. "Text"]:SetText(numfor(alphaSlider:GetValue() * 100, 0) .. "%")

			tinsert(tabList, alphaEdit)
		else
			fe.frameHeight = fe.frameHeight - 40
			alphaLabel:Hide()
			alphaEdit:Hide()
			alphaSlider:Hide()
			alphaMinusButton:Hide()
			alphaPlusButton:Hide()
			alphaResetButton:Hide()
			alphaFullButton:Hide()
		end
		fe:SetHeight(fe.frameHeight)

		hideLayersHeading:SetPoint(unpack(nextPoint))

		if fe.editFrame and fe.editFrame.DisableDrawLayer and not MovAny.lVirtualMovers[fe.o.name] then
			hideLayersHeading:Show()

			hideArtworkCheck:Show()
			hideBackgroundCheck:Show()
			hideBorderCheck:Show()
			hideHighlightCheck:Show()
			hideOverlayCheck:Show()

			hideArtworkCheck:SetChecked(fe.opt and fe.opt.disableLayerArtwork)
			hideBackgroundCheck:SetChecked(fe.opt and fe.opt.disableLayerBackground)
			hideBorderCheck:SetChecked(fe.opt and fe.opt.disableLayerBorder)
			hideHighlightCheck:SetChecked(fe.opt and fe.opt.disableLayerHighlight)
			hideOverlayCheck:SetChecked(fe.opt and fe.opt.disableLayerOverlay)

			layersResetButton:Show()
		else
			hideLayersHeading:Hide()

			hideArtworkCheck:Hide()
			hideBackgroundCheck:Hide()
			hideBorderCheck:Hide()
			hideHighlightCheck:Hide()
			hideOverlayCheck:Hide()

			layersResetButton:Hide()
		end

		if (opt and opt.frameStrata) or (editFrame and editFrame.GetFrameStrata and editFrame:GetFrameStrata()) then
			strataLabel:Show()
			strataDropDownButton:Show()
			local frameStrata = (opt and opt.frameStrata) or (editFrame and editFrame:GetFrameStrata()) or nil
			UIDropDownMenu_Initialize(strataDropDownButton, strataDropDown_MenuInit)
			if frameStrata then
				UIDropDownMenu_SetSelectedValue(strataDropDownButton, frameStrata)
			else
				UIDropDownMenu_SetSelectedValue(strataDropDownButton, "BACKGROUND")
			end
			strataResetButton:Show()
		else
			strataLabel:Hide()
			strataDropDownButton:Hide()
			strataResetButton:Hide()
		end

		if not editFrame or not editFrame.UnregisterAllEvents then
			unregisterAllEventsCheck:Hide()
		else
			unregisterAllEventsCheck:Show()
			unregisterAllEventsCheck:SetChecked((opt and opt.unregisterAllEvents))
		end
		fe:UpdateButtons()
		fe:UpdateActuals()

		fe.updating = nil
	end

	fe.UpdateButtons = function()
		if MovAny:GetFrameOptions(fe.o.name) then
			resetButton:Enable()
		else
			resetButton:Disable()
		end

		if fe.editFrame then
			local mover = MovAny:GetMoverByFrame(fe.editFrame)
			moverButton:Enable()
			moverButton:SetText(mover and "Detach" or "Attach")
			if mover then
				syncButton:Disable()
			else
				syncButton:Enable()
			end
		else
			moverButton:Disable()
			syncButton:Disable()
		end

		if fe.editFrame then
			showButton:Enable()
			showButton:SetText(fe.editFrame:IsShown() and "Hide" or "Show")
		else
			showButton:Disable()
		end
	end

	fe.CloseDialog = function(self)
		if IsShiftKeyDown() and IsControlKeyDown() and IsAltKeyDown() then
			ReloadUI()
		else
			self:Hide()
			MovAny.frameEditors[self.o and self.o.name or name] = nil
			self.o = nil
			self.opt = nil
			self.editFrame = nil
			self.initialOpt = nil
		end
	end

	fe.VerifyOpt = function(self, dontCreate)
		local opt = MovAny:GetFrameOptions(fe.o.name)
		if not opt then
			if dontCreate then
				fe.opt = nil
			else
				fe.opt = MovAny:HookFrame(fe.o.name)
			end
		end
		return fe.opt
	end

	fe.WritePoint = function(self, updateEditor)
		if fe.updating then
			return
		end
		local fn = fe.o.name
		local editFrame = fe.editFrame
		local opt = fe:VerifyOpt()

		if fe.editFrame and not opt.orgPos then
			MovAny:StoreOrgPoints(editFrame, opt)
		end

		fe.updating = true

		if opt.groups and not IsShiftKeyDown() then
			local x = fe.lastX and opt.pos[4] - fe.lastX or 0
			x = x * (opt.scale or 1)
			local y = fe.lastY and opt.pos[5] - fe.lastY or 0
			y = y * (opt.scale or 1)
			MovAny:MoveGroups(fn, opt.groups, x, y)
		end
		fe.lastX = nil
		fe.lastY = nil

		if editFrame and not opt.disabled then
			local mover = MovAny:GetMoverByFrame(fn)
			if mover and (not InCombatLockdown() or not MovAny:IsProtected(editFrame)) then
				mover.dontUpdate = true
				MovAny:DetachMover(mover)
			end
			if not InCombatLockdown() or not MovAny:IsProtected(editFrame) then
				MovAny:ApplyPosition(editFrame, opt)
			else
				local closure = function(f, opt)
					return function()
						if MovAny:IsProtected(f) and InCombatLockdown() then
							return true
						end
						MovAny:ApplyPosition(f, opt)
					end
				end
				MovAny.pendingActions[fe.o.name .. ":SetPoint"] = closure(editFrame, opt)
			end
			if mover and (not InCombatLockdown() or not MovAny:IsProtected(editFrame)) then
				MovAny:AttachMover(fn)
			end
		end

		MovAny:UpdateGUIIfShown(true)
		if updateEditor then
			fe:UpdateEditor()
		else
			fe:UpdateButtons()
			fe:UpdateActuals()
		end
		fe.updating = nil
	end

	fe.WriteScale = function()
		if fe.updating then
			return
		end
		local fn = fe.o.name
		local editFrame = fe.editFrame
		local opt = fe:VerifyOpt()

		local scale = scaleSlider:GetValue()

		fe.updating = true

		local mover = MovAny:GetMoverByFrame(fn)
		if mover and (not InCombatLockdown() or not MovAny:IsProtected(editFrame)) then
			mover.dontUpdate = true
			MovAny:StopMoving(fn)
		end

		local updateGUI = nil

		if scale > 0 then
			if opt.pos and opt.scale then
				opt.pos[4] = opt.pos[4] * opt.scale
				opt.pos[5] = opt.pos[5] * opt.scale
			end
			if opt.pos and scale then
				opt.pos[4] = opt.pos[4] / scale
				opt.pos[5] = opt.pos[5] / scale
			end
			if opt.groups and IsShiftKeyDown() then
				MovAny:ScaleGroups(fn, opt.groups, scale - (opt.scale or (editFrame and editFrame:GetScale())), scale)
			end

			if scale ~= opt.scale then
				updateGUI = true
			end
			opt.scale = scale

			if editFrame and not opt.disabled then
				if not InCombatLockdown() or not MovAny:IsProtected(editFrame) then
					MovAny:ApplyScale(editFrame, opt)
					MovAny:ApplyPosition(editFrame, opt)
				else
					local closure = function(f, opt)
						return function()
							if MovAny:IsProtected(f) and InCombatLockdown() then
								return true
							end
							MovAny:ApplyScale(f, opt)
							MovAny:ApplyPosition(editFrame, opt)
						end
					end
					MovAny.pendingActions[fn .. ":SetScale"] = closure(editFrame, opt)
				end
			end
			if opt.scale == opt.orgScale then
				opt.scale = nil
				opt.orgScale = nil
			end
		end

		if mover and (not InCombatLockdown() or not MovAny:IsProtected(editFrame)) then
			MovAny:AttachMover(fn)
		end

		if updateGUI then
			MovAny:UpdateGUIIfShown(true)
		end
		fe:UpdateButtons()
		fe:UpdateActuals()
		fe.updating = nil
	end

	fe.WriteDimentions = function()
		if fe.updating then
			return
		end
		local fn = fe.o.name
		local editFrame = fe.editFrame
		local opt = fe:VerifyOpt()

		if editFrame then
			if type(opt.orgWidth) == "nil" then
				opt.orgWidth = editFrame:GetWidth()
			end

			if type(opt.orgHeight) == "nil" then
				opt.orgHeight = editFrame:GetHeight()
			end
		end

		local updateGUI = nil

		local width = widthSlider:GetValue()
		if width >= 0 then
			if width ~= opt.width then
				updateGUI = true
				if opt.groups and not IsShiftKeyDown() then
					local s = width / (opt.width or opt.orgWidth)
					MovAny:ScaleGroups(fn, opt.groups, s - 1, s, 0)
				end
			end
			opt.width = width
		end

		local height = heightSlider:GetValue()
		if height >= 0 then
			if height ~= opt.height then
				updateGUI = true
				if opt.groups and not IsShiftKeyDown() then
					local s = height / (opt.height or opt.orgHeight)
					MovAny:ScaleGroups(fn, opt.groups, s - 1, s, 1)
				end
			end
			opt.height = height
		end

		if opt.disabled then
			return
		end

		fe.updating = true
		local mover = MovAny:GetMoverByFrame(fn)
		if mover and (not InCombatLockdown() or not MovAny:IsProtected(editFrame)) then
			mover.dontUpdate = true
			MovAny:StopMoving(fn)
		end

		if editFrame then
			if not InCombatLockdown() or not MovAny:IsProtected(editFrame) then
				MovAny:ApplyScale(editFrame, opt)
			else
				local closure = function(f, opt)
					return function()
						if MovAny:IsProtected(f) and InCombatLockdown() then
							return true
						end
						MovAny:ApplyScale(f, opt)
					end
				end
				MovAny.pendingActions[fn .. ":Scale"] = closure(editFrame, opt)
			end
		end
		if mover and (not InCombatLockdown() or not MovAny:IsProtected(editFrame)) then
			MovAny:AttachMover(fn)
		end

		if updateGUI then
			MovAny:UpdateGUIIfShown(true)
		end
		fe:UpdateButtons()
		fe:UpdateActuals()
		fe.updating = nil
	end

	fe.WriteAlpha = function()
		if fe.updating then
			return
		end
		local fn = fe.o.name
		local opt = fe:VerifyOpt()

		fe.updating = true
		local alpha = tonumber(alphaSlider:GetValue())
		if opt.alpha ~= alpha then
			if opt.groups and not IsShiftKeyDown() then
				MovAny:AlphaGroups(fn, opt.groups, alpha - (opt.alpha or (fe.editFrame and fe.editFrame:GetAlpha()) or 1), alpha)
			end
			opt.alpha = alpha

			if fe.editFrame then
				MovAny:ApplyAlpha(fe.editFrame, opt)
			end
			if opt.alpha == opt.orgAlpha then
				opt.alpha = nil
				opt.orgAlpha = nil
			end

			MovAny:UpdateGUIIfShown(true)
		end

		fe:UpdateButtons()
		fe:UpdateActuals()
		fe.updating = nil
	end

	fe.UpdateActuals = function()
		local editFrame = fe.editFrame
		if not editFrame then
			actualsHeading:Hide()
			infoTextWidthLabel:Hide()
			infoTextWidth:Hide()
			infoTextHeightLabel:Hide()
			infoTextHeight:Hide()
			infoTextXLabel:Hide()
			infoTextX:Hide()
			infoTextYLabel:Hide()
			infoTextY:Hide()
			infoTextScaleLabel:Hide()
			infoTextScale:Hide()
			infoTextAlphaLabel:Hide()
			infoTextAlpha:Hide()
			return
		end

		actualsHeading:Show()
		infoTextWidthLabel:Show()
		infoTextWidth:Show()
		infoTextHeightLabel:Show()
		infoTextHeight:Show()
		infoTextXLabel:Show()
		infoTextX:Show()
		infoTextYLabel:Show()
		infoTextY:Show()

		if editFrame.GetEffectiveScale or editFrame.GetScale then
			local scale
			if editFrame.GetScale then
				scale = editFrame:GetScale()
			elseif editFrame.GetEffectiveScale then
				scale = editFrame:GetEffectiveScale() / UIParent:GetScale()
			end

			if editFrame:GetLeft() then
				infoTextX:SetText(numfor(editFrame:GetLeft() * scale))
			else
				infoTextX:SetText("?")
			end
			if editFrame:GetBottom() then
				infoTextY:SetText(numfor(editFrame:GetBottom() * scale))
			end

			if editFrame:GetWidth() then
				infoTextWidth:SetText(numfor(editFrame:GetWidth() * scale))
			end
			if editFrame:GetHeight() then
				infoTextHeight:SetText(numfor(editFrame:GetHeight() * scale))
			end

			infoTextScaleLabel:Show()
			infoTextScale:Show()
			infoTextScale:SetText(numfor(scale * 100) .. "%")
		else
			infoTextX:SetText(numfor(editFrame:GetLeft()))
			infoTextY:SetText(numfor(editFrame:GetBottom()))

			infoTextWidth:SetText(numfor(editFrame:GetWidth()))
			infoTextHeight:SetText(numfor(editFrame:GetHeight()))

			infoTextScaleLabel:Hide()
			infoTextScale:Hide()
		end
		if editFrame.GetEffectiveAlpha or editFrame.GetAlpha then
			infoTextAlphaLabel:Show()
			infoTextAlpha:Show()
			local alpha
			if editFrame.GetEffectiveAlpha then
				alpha = editFrame:GetEffectiveAlpha()
			elseif editFrame.GetAlpha then
				alpha = editFrame:GetAlpha()
			end
			infoTextAlpha:SetText(numfor(alpha * 100, 0) .. "%")
		else
			infoTextAlphaLabel:Hide()
			infoTextAlpha:Hide()
		end
	end

	fe.UpdatePointControls = function(self, nextPoint)
		local fe = self
		local opt = fe.opt
		local editFrame = fe.editFrame
		local fn = fe.fn

		if not MovAny.NoMove[fn] then
			if nextPoint then
				positionHeading:SetPoint(unpack(nextPoint))
				nextPoint = {"TOPLEFT", yLabel, "BOTTOMLEFT", 0, -20}
			end

			positionHeading:Show()
			posResetButton:Show()
			pointLabel:Show()
			pointDropDownButton:Show()
			pointResetButton:Show()
			relPointLabel:Show()
			relPointDropDownButton:Show()
			relPointResetButton:Show()
			relToLabel:Show()
			relToEdit:Show()
			relToResetButton:Show()
			xLabel:Show()
			xEdit:Show()
			xSlider:Show()
			xMinusButton:Show()
			xPlusButton:Show()
			xResetButton:Show()
			xZeroButton:Show()
			yLabel:Show()
			yEdit:Show()
			ySlider:Show()
			yMinusButton:Show()
			yPlusButton:Show()
			yResetButton:Show()
			yZeroButton:Show()

			tinsert(tabList, relToEdit)
			tinsert(tabList, xEdit)
			tinsert(tabList, yEdit)

			local p
			if opt and opt.pos then
				p = opt.pos
			elseif editFrame then
				local mover = MovAny:GetMoverByFrame(fn)
				if mover then
					p = {mover:GetPoint()}
				else
					p = {editFrame:GetPoint()}
				end
			else
				p = {"TOPLEFT", "UIParent", "TOPLEFT", 0, 0}
			end
			UIDropDownMenu_Initialize(pointDropDownButton, pointDropDown_MenuInit)
			UIDropDownMenu_SetSelectedValue(pointDropDownButton, p[1] or "TOPLEFT")

			local relPoint = p[3] or p[1] or "TOPLEFT"
			UIDropDownMenu_Initialize(relPointDropDownButton, relPointDropDown_MenuInit)
			UIDropDownMenu_SetSelectedValue(relPointDropDownButton, relPoint)

			local relativeTo = "UIParent"
			if p[2] then
				if type(p[2]) == "string" then
					relativeTo = p[2]
				elseif type(p[2]) == "table" and p[2]:GetName() then
					relativeTo = p[2]:GetName()
				end
			end
			relToEdit:SetText(relativeTo)

			local v = tonumber(numfor(p[4])) or 0
			xSlider:SetMinMaxValues(v - 200, v + 200)
			_G[xSlider:GetName() .. "Low"]:SetText(v - 200)
			_G[xSlider:GetName() .. "High"]:SetText(v + 200)
			xSlider:SetValue(v)

			v = tonumber(numfor(p[5])) or 0
			ySlider:SetMinMaxValues(v - 200, v + 200)
			_G[ySlider:GetName() .. "Low"]:SetText(v - 200)
			_G[ySlider:GetName() .. "High"]:SetText(v + 200)
			ySlider:SetValue(v)
		else
			fe.frameHeight = fe.frameHeight - 150

			positionHeading:Hide()
			posResetButton:Hide()
			pointLabel:Hide()
			pointDropDownButton:Hide()
			pointResetButton:Hide()
			relPointLabel:Hide()
			relPointDropDownButton:Hide()
			relPointResetButton:Hide()
			relToLabel:Hide()
			relToEdit:Hide()
			relToResetButton:Hide()
			xLabel:Hide()
			xEdit:Hide()
			xSlider:Hide()
			xResetButton:Hide()
			xZeroButton:Hide()
			yLabel:Hide()
			yEdit:Hide()
			ySlider:Hide()
			yResetButton:Hide()
			yZeroButton:Hide()
		end

		return nextPoint
	end

	fe.UpdateScale = function(self, nextPoint)
		local fe = self
		local opt = fe.opt
		local editFrame = fe.editFrame
		local fn = fe.o.name

		if MovAny.ScaleWH[fn] then
			fe.frameHeight = fe.frameHeight + 27

			if nextPoint then
				widthLabel:SetPoint(unpack(nextPoint))
				nextPoint = {"TOPLEFT", heightLabel, "BOTTOMLEFT", 0, -20}
			end

			scaleLabel:Hide()
			scaleEdit:Hide()
			scaleSlider:Hide()
			scaleMinusButton:Hide()
			scalePlusButton:Hide()
			scaleResetButton:Hide()
			scaleOneButton:Hide()

			widthLabel:Show()
			widthEdit:Show()
			widthSlider:Show()
			widthMinusButton:Show()
			widthPlusButton:Show()
			widthResetButton:Show()

			heightLabel:Show()
			heightEdit:Show()
			heightSlider:Show()
			heightMinusButton:Show()
			heightPlusButton:Show()
			heightResetButton:Show()

			local v = 1
			if opt and (opt.width or opt.orgWidth) then
				if opt.width then
					v = opt.width
				elseif opt.orgWidth then
					v = opt.orgWidth
				end
			elseif fe.editFrame then
				v = fe.editFrame:GetWidth()
			end
			local lowV = tonumber(numfor(v)) - 200
			if lowV < 1 then
				lowV = 1
			end
			widthSlider:SetMinMaxValues(lowV, lowV + 400)
			widthSlider:SetValue(v)
			_G[widthSlider:GetName() .. "Low"]:SetText(lowV)
			_G[widthSlider:GetName() .. "High"]:SetText(lowV + 400)

			v = 1
			if opt and (opt.height or opt.orgHeight) then
				if opt.height then
					v = opt.height
				elseif opt.orgHeight then
					v = opt.orgHeight
				end
			elseif fe.editFrame then
				v = fe.editFrame:GetHeight()
			end
			lowV = tonumber(numfor(v)) - 200
			if lowV < 1 then
				lowV = 1
			end
			heightSlider:SetMinMaxValues(lowV, lowV + 400)
			heightSlider:SetValue(v)
			_G[heightSlider:GetName() .. "Low"]:SetText(lowV)
			_G[heightSlider:GetName() .. "High"]:SetText(lowV + 400)

			tinsert(tabList, widthEdit)
			tinsert(tabList, heightEdit)
		elseif not MovAny.NoScale[fn] and (not editFrame or MovAny:CanBeScaled(editFrame, 1)) then
			scaleLabel:SetPoint(unpack(nextPoint))
			nextPoint = {"TOPLEFT", scaleLabel, "BOTTOMLEFT", 0, -20}

			scaleLabel:Show()
			scaleEdit:Show()
			scaleSlider:Show()
			scaleMinusButton:Show()
			scalePlusButton:Show()
			scaleResetButton:Show()
			scaleOneButton:Show()

			widthLabel:Hide()
			widthEdit:Hide()
			widthSlider:Hide()
			widthMinusButton:Hide()
			widthPlusButton:Hide()
			widthResetButton:Hide()

			heightLabel:Hide()
			heightEdit:Hide()
			heightSlider:Hide()
			heightMinusButton:Hide()
			heightPlusButton:Hide()
			heightResetButton:Hide()

			local scale = opt and opt.scale or 1
			scaleSlider:SetValue(scale)

			tinsert(tabList, scaleEdit)
		else
			fe.frameHeight = fe.frameHeight - 40

			scaleLabel:Hide()
			scaleEdit:Hide()
			scaleSlider:Hide()
			scaleMinusButton:Hide()
			scalePlusButton:Hide()
			scaleResetButton:Hide()
			scaleOneButton:Hide()

			widthLabel:Hide()
			widthEdit:Hide()
			widthSlider:Hide()
			widthMinusButton:Hide()
			widthPlusButton:Hide()
			widthResetButton:Hide()

			heightLabel:Hide()
			heightEdit:Hide()
			heightSlider:Hide()
			heightMinusButton:Hide()
			heightPlusButton:Hide()
			heightResetButton:Hide()
		end

		return nextPoint
	end

	fe.GeneratePoint = function(fe)
		local relTo = relToEdit:GetText()

		if not _G[relTo] then
			MovAny_Print(string.format(L.ELEMENT_NOT_FOUND_NAMED, name))
			return nil
		end

		return {
			pointDropDownButton.selectedValue,
			relTo,
			relPointDropDownButton.selectedValue,
			xSlider:GetValue(),
			ySlider:GetValue()
		}
	end

	fe:LoadFrame(name)
end