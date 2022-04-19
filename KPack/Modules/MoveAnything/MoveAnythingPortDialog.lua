local MovAny = MovAny
if not MovAny then return end

local _G = _G
local MA_tdeepcopy = _G.MA_tdeepcopy or _G.CopyTable

function MovAny:PortDialog(mode, fn)
	if not self.portDlg then
		self.portDlg = self:CreatePortDialog()
	end
	self.portDlg:PrepareDialog(mode, fn)
	self.portDlg:Show()
	self.CreatePortDialog = nil
end

function MovAny:CreatePortDialog()
	local fn = "MAPortDialog"

	local pd = CreateFrame("Frame", fn, _G.UIParent)

	tinsert(_G.UISpecialFrames, fn)

	pd:SetSize(370, 130)
	pd:SetFrameStrata("FULLSCREEN_DIALOG")
	pd:SetFrameLevel(1)
	pd:SetPoint("CENTER")
	pd:EnableMouse(true)
	pd:SetMovable(true)
	pd:RegisterForDrag("LeftButton")
	pd:SetScript("OnDragStart", pd.StartMoving)
	pd:SetScript("OnDragStop", pd.StopMovingOrSizing)
	pd:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		tile = "true",
		tileSize = 32
	})
	pd:SetBackdropColor(0, 0, 0)
	pd:SetBackdropBorderColor(0, 0, 0)

	local closeButton = CreateFrame("Button", fn .. "Close", pd, "MAButtonTemplate")
	closeButton:SetText("X")
	closeButton:SetSize(20, 20)
	closeButton:SetPoint("TOPRIGHT", -1, 0)
	closeButton:SetScript("OnClick", function() pd:CloseDialog() end)

	local actionLabel = pd:CreateFontString()
	actionLabel:SetFontObject("GameFontNormalSmall")
	actionLabel:SetSize(100, 20)
	actionLabel:SetJustifyH("LEFT")
	actionLabel:SetPoint("TOPLEFT", pd, "TOPLEFT", 12, -8)

	local frameNameLabel = pd:CreateFontString()
	frameNameLabel:SetFontObject("GameFontNormalSmall")
	frameNameLabel:SetSize(150, 20)
	frameNameLabel:SetJustifyH("LEFT")
	frameNameLabel:SetPoint("TOPLEFT", pd, "TOPLEFT", 62, -8)

	local dirLabel = pd:CreateFontString()
	dirLabel:SetFontObject("GameFontNormalSmall")
	dirLabel:SetSize(40, 20)
	dirLabel:SetJustifyH("LEFT")
	dirLabel:SetPoint("TOPLEFT", actionLabel, "BOTTOMLEFT", 0, 0)

	local profileCheck = CreateFrame("CheckButton", fn .. "Enabled", pd, "MACheckButtonTemplate")
	local profileDropDownButton = CreateFrame("Button", fn .. "Profile", pd, "UIDropDownMenuTemplate")
	local profileNoneLabel = pd:CreateFontString()

	local textCheck = CreateFrame("CheckButton", fn .. "Enabled", pd, "MACheckButtonTemplate")
	local textEditBox = CreateFrame("EditBox", fn .. "TextEdit", pd, "InputBoxTemplate")

	local actionButton = CreateFrame("Button", fn .. "ExportButton", pd, "MAButtonTemplate")

	local profileFunc = function(self)
		UIDropDownMenu_SetSelectedValue(profileDropDownButton, self.value)
	end

	profileCheck:SetPoint("TOPLEFT", dirLabel, "TOPRIGHT", 9, -2)
	profileCheck:SetScript("OnClick", function(self)
		if not self:GetChecked() then
			self:SetChecked(true)
			return
		end
		textEditBox:Hide()
		textCheck:SetChecked(nil)
		if pd.profileFound then
			profileDropDownButton:Show()
			actionButton:Enable()
		else
			profileNoneLabel:Show()
			actionButton:Disable()
		end
	end)

	local profileLabel = pd:CreateFontString()
	profileLabel:SetFontObject("GameFontNormalSmall")
	profileLabel:SetHeight(20)
	profileLabel:SetJustifyH("LEFT")
	profileLabel:SetPoint("TOPLEFT", profileCheck, "TOPRIGHT", 1, 2)
	profileLabel:SetText("Profile")

	textCheck:SetPoint("TOPLEFT", profileLabel, "TOPRIGHT", 9, -2)
	textCheck:SetScript("OnClick", function(self)
		if not self:GetChecked() then
			self:SetChecked(true)
			return
		end
		profileCheck:SetChecked(nil)
		if pd.profileFound then
			profileDropDownButton:Hide()
		else
			profileNoneLabel:Hide()
		end
		textEditBox:Show()
		if pd.mode == 1 then
			actionButton:Disable()
			textEditBox:SetText("")
		elseif pd.mode == 2 then
			actionButton:Disable()
			if pd.fn then
				textEditBox:SetText(MovAny:SerializeFrame(pd.fn))
			else
				textEditBox:SetText(MovAny:SerializeProfile(MovAny:GetProfileName()))
			end
		end
		textEditBox:SetFocus()
	end)

	local textLabel = pd:CreateFontString()
	textLabel:SetFontObject("GameFontNormalSmall")
	textLabel:SetHeight(20)
	textLabel:SetJustifyH("LEFT")
	textLabel:SetPoint("TOPLEFT", textCheck, "TOPRIGHT", 1, 2)
	textLabel:SetText("Text String")

	profileDropDownButton:SetID(1)
	profileDropDownButton:SetScript("OnClick", function(self) ToggleDropDownMenu(1, nil, self, self, 6, 7, nil, self) end)
	profileDropDownButton:SetPoint("TOPLEFT", dirLabel, "BOTTOMLEFT", 0, -10)
	UIDropDownMenu_SetWidth(profileDropDownButton, 200)

	profileNoneLabel:SetFontObject("GameFontNormalSmall")
	profileNoneLabel:SetHeight(20)
	profileNoneLabel:SetJustifyH("LEFT")
	profileNoneLabel:SetPoint("TOPLEFT", dirLabel, "BOTTOMLEFT", 0, -10)
	profileNoneLabel:SetText("No profile has modified this frame")

	textEditBox:SetFontObject("GameFontHighlightSmall")
	textEditBox:SetSize(311, 20)
	textEditBox:SetJustifyH("LEFT")
	textEditBox:SetAutoFocus(false)
	textEditBox:SetPoint("TOPLEFT", dirLabel, "BOTTOMLEFT", 0, -10)
	textEditBox:SetScript("OnTextChanged", function(self)
		if pd.mode == 2 then return end
		local text = self:GetText()
		if text ~= nil and text ~= "" then
			actionButton:Enable()
		else
			actionButton:Disable()
		end
	end)

	actionButton:SetSize(75, 22)
	actionButton:SetPoint("BOTTOMRIGHT", pd, "BOTTOMRIGHT", -8, 10)
	actionButton:SetScript("OnClick", function()
		if pd.mode == 1 then
			if pd.fn then
				if textEditBox:IsShown() then
					local opt = MovAny:UnserializeFrame(textEditBox:GetText(), pd.fn)
					if opt then
						kMADB.profiles[MovAny:GetProfileName()].frames[pd.fn] = opt
						MovAny:SyncFrame(pd.fn, opt)
						pd:CloseDialog()
						MovAny:UpdateGUIIfShown(true)
					end
				else
					-- import pd.fn from selected profile
					local pn = UIDropDownMenu_GetSelectedValue(profileDropDownButton)
					local p = kMADB.profiles[pn]
					local oldOpt = kMADB.profiles[MovAny:GetProfileName()].frames[pd.fn]
					if type(p) == "table" then
						if oldOpt then
							MovAny:ResetFrame(pd.fn, nil, true)
						end
						local opt = MA_tdeepcopy(p.frames[pd.fn])
						kMADB.profiles[MovAny:GetProfileName()].frames[pd.fn] = opt
						MovAny.pendingFrames[pd.fn] = opt
						MovAny:SyncFrames()
						pd:CloseDialog()
						MovAny:UpdateGUIIfShown(true)
					end
				end
			else
				if textEditBox:IsShown() then
					if MovAny:UnserializeProfile(textEditBox:GetText()) then
						MovAny:UpdateGUIIfShown(true)
						pd:CloseDialog()
					end
				else
					-- import selected profile
					local pn = UIDropDownMenu_GetSelectedValue(profileDropDownButton)
					MovAny:ResetProfile(true)
					MovAny:CopyProfile(pn, MovAny:GetProfileName())
					MovAny:SyncAllFrames()
					pd:CloseDialog()
					MovAny:UpdateGUIIfShown(true)
				end
			end
		elseif pd.mode == 2 then
			if pd.fn then
				if not textEditBox:IsShown() then
					--export pd.fn to selected profile
					local pn = UIDropDownMenu_GetSelectedValue(profileDropDownButton)
					local p = kMADB.profiles[MovAny:GetProfileName()]
					if type(p) == "table" then
						kMADB.profiles[pn].frames[pd.fn] = MA_tdeepcopy(p.frames[pd.fn])
					end
					pd:CloseDialog()
				end
			else
				if not textEditBox:IsShown() then
					-- export profile to selected profile
					MovAny:CopyProfile(MovAny:GetProfileName(), UIDropDownMenu_GetSelectedValue(profileDropDownButton))
					pd:CloseDialog()
				end
			end
		end
	end)

	pd.PrepareDialog = function(self, mode, fn)
		self.mode = mode
		self.fn = fn

		local s = ""
		local dir = ""
		if mode == 1 then
			s = "Import"
			dir = "From"
		else
			s = "Export"
			dir = "To"
		end
		actionButton:SetText(s)
		if fn then
			s = s .. ":"
		else
			s = s .. " profile"
		end
		actionLabel:SetText(s)
		if fn then
			frameNameLabel:SetText(fn)
			frameNameLabel:Show()
		else
			frameNameLabel:Hide()
		end

		dirLabel:SetText(dir .. ":")

		profileCheck:SetChecked(true)
		textCheck:SetChecked(nil)
		profileDropDownButton:Show()
		textEditBox:Hide()

		actionButton:Enable()

		local profileDropDown_MenuInit = function()
			local info
			local names = {}
			for name, profile in pairs(kMADB.profiles) do
				if name ~= "default" and name ~= MovAny:GetProfileName() then
					if not pd.fn or (pd.mode == 1 and pd.fn and profile.frames[pd.fn]) or (pd.mode == 2) then
						tinsert(names, name)
					end
				end
			end
			table.sort(
				names,
				function(o1, o2)
					return o1:lower() < o2:lower()
				end
			)
			if
				MovAny:GetProfileName() ~= "default" and
					((pd.mode == 1 and pd.fn and kMADB.profiles["default"].frames[pd.fn]) or (pd.mode == 1 and not pd.fn) or
						pd.mode == 2)
			 then
				info = UIDropDownMenu_CreateInfo()
				info.text = "default"
				info.value = "default"
				info.func = profileFunc
				UIDropDownMenu_AddButton(info)
			end
			for _, name in pairs(names) do
				info = UIDropDownMenu_CreateInfo()
				info.text = name
				info.value = name
				info.func = profileFunc
				UIDropDownMenu_AddButton(info)
			end
		end

		UIDropDownMenu_Initialize(profileDropDownButton, profileDropDown_MenuInit)

		local selProfile
		if MovAny:GetProfileName() ~= "default" and ((pd.mode == 1 and pd.fn and kMADB.profiles["default"].frames[pd.fn]) or (pd.mode == 1 and not pd.fn) or pd.mode == 2) then
			selProfile = "default"
		else
			local names = {}
			for name, profile in pairs(kMADB.profiles) do
				if name ~= "default" and name ~= MovAny:GetProfileName() then
					if not pd.fn or (pd.mode == 1 and pd.fn and profile.frames[pd.fn]) or (pd.mode == 2) then
						tinsert(names, name)
					end
				end
			end
			table.sort(names, function(o1, o2) return o1:lower() < o2:lower() end)
			selProfile = next(names)
		end
		if selProfile == nil then
			pd.profileFound = nil
			profileDropDownButton:Hide()
			profileNoneLabel:Show()
			actionButton:Disable()
		else
			pd.profileFound = true
			profileDropDownButton:Show()
			profileNoneLabel:Hide()
			actionButton:Enable()
			UIDropDownMenu_SetSelectedValue(profileDropDownButton, selProfile)
		end
	end

	pd.CloseDialog = function(self)
		if IsShiftKeyDown() and IsControlKeyDown() and IsAltKeyDown() then
			ReloadUI()
		else
			self:Hide()
		end
	end

	pd.Reload = function(self)
		self:PrepareDialog(self.mode, self.fn)
	end

	return pd
end