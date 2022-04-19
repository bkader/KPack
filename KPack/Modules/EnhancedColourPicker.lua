local core = KPack
if not core then return end
core:AddModule("EnhancedColourPicker", "Adds Copy and Paste Functions to the ColorPicker.", function()
	if core:IsDisabled("EnhancedColourPicker") or core.ElvUI then return end

	local mod = core.ECP or {}
	core.ECP = mod

	local format = string.format

	local function Print(msg)
		if msg then
			core:Print(msg, "EnhancedColorPicker")
		end
	end

	function mod:UpdateColour_Alpha(obj)
		if not obj:GetText() or obj:GetText() == "" then
			return
		end

		local r, g, b = ColorPickerFrame:GetColorRGB()
		local a = OpacitySliderFrame:GetValue()

		local id = obj:GetID()

		if id == 1 then
			r = format("%.2f", obj:GetNumber())
			r = r or 0
		elseif id == 2 then
			g = format("%.2f", obj:GetNumber())
			g = g or 0
		elseif id == 3 then
			b = format("%.2f", obj:GetNumber())
			b = b or 0
		else
			a = format("%.2f", obj:GetNumber())
			a = a or 0
		end

		if id ~= 4 then
			ColorPickerFrame:SetColorRGB(r, g, b)
			ColorSwatch:SetTexture(r, g, b)
		else
			OpacitySliderFrame:SetValue(a)
		end
	end

	function mod:UpdateEB(r, g, b, a)
		if mod.editBoxFocus then
			return
		end

		if not r then
			r, g, b = ColorPickerFrame:GetColorRGB()
		end
		if not a then
			a = OpacitySliderFrame:GetValue()
		end

		_G.ECPRedBoxText:SetText(format("%.2f", r))
		_G.ECPGreenBoxText:SetText(format("%.2f", g))
		_G.ECPBlueBoxText:SetText(format("%.2f", b))
		_G.ECPAlphaBoxText:SetText(format("%.2f", a))

		_G.ECPRedBox:SetText("")
		_G.ECPGreenBox:SetText("")
		_G.ECPBlueBox:SetText("")
		_G.ECPAlphaBox:SetText("")
	end

	local function ECP_OnShow(self)
		if self.hasOpacity then
			_G.ECPAlphaBox:Show()
			_G.ECPAlphaBoxLabel:Show()
			_G.ECPAlphaBoxText:Show()
		else
			_G.ECPAlphaBox:Hide()
			_G.ECPAlphaBoxLabel:Hide()
			_G.ECPAlphaBoxText:Hide()
		end
	end

	local function ECP_OnColorSelect(self, ...)
		local arg1, arg2, arg3 = ...
		mod:UpdateEB(arg1, arg2, arg3, self.opacity)
	end

	local function ECP_Opacity_OnValueChanged(self, ...)
		mod:UpdateEB(nil, nil, nil, self.opacity)
	end

	core:RegisterForEvent("PLAYER_LOGIN", function()
		ColorPickerFrame:HookScript("OnShow", ECP_OnShow)
		ColorPickerFrame:HookScript("OnColorSelect", ECP_OnColorSelect)
		OpacitySliderFrame:HookScript("OnValueChanged", ECP_Opacity_OnValueChanged)

		-- Add Buttons and EditBoxes to the original ColorPicker Frame
		local cb = CreateFrame("Button", "ECPCopy", ColorPickerFrame, "KPackButtonTemplate")
		cb:SetText("Copy")
		cb:SetWidth(75)
		cb:SetHeight(22)
		cb:SetPoint("BOTTOMLEFT", "ColorPickerFrame", "TOPLEFT", 10, -32)
		cb:SetScript("OnClick", function(self)
			local r, g, b = ColorPickerFrame:GetColorRGB()
			local a = ColorPickerFrame.hasOpacity and OpacitySliderFrame:GetValue() or 1
			local CurrentlyCopiedColor = _G.CurrentlyCopiedColor or {}
			_G.CurrentlyCopiedColor = CurrentlyCopiedColor

			CurrentlyCopiedColor.r = r
			CurrentlyCopiedColor.g = g
			CurrentlyCopiedColor.b = b
			CurrentlyCopiedColor.a = a
		end)

		local pb = CreateFrame("Button", "ECPPaste", ColorPickerFrame, "KPackButtonTemplate")
		pb:SetText("Paste")
		pb:SetWidth(75)
		pb:SetHeight(22)
		pb:SetPoint("BOTTOMRIGHT", "ColorPickerFrame", "TOPRIGHT", -10, -32)
		pb:SetScript("OnClick", function(self)
			local CurrentlyCopiedColor = _G.CurrentlyCopiedColor
			if CurrentlyCopiedColor then
				ColorPickerFrame:SetColorRGB(
					CurrentlyCopiedColor.r,
					CurrentlyCopiedColor.g,
					CurrentlyCopiedColor.b
				)
				if ColorPickerFrame.hasOpacity then
					OpacitySliderFrame:SetValue(CurrentlyCopiedColor.a)
				end
				ColorSwatch:SetTexture(
					CurrentlyCopiedColor.r,
					CurrentlyCopiedColor.g,
					CurrentlyCopiedColor.b
				)
			end
		end)

		-- move the Color Picker Wheel
		ColorPickerWheel:ClearAllPoints()
		ColorPickerWheel:SetPoint("TOPLEFT", 16, -34)

		-- move the Opacity Slider Frame
		OpacitySliderFrame:ClearAllPoints()
		OpacitySliderFrame:SetPoint("TOPLEFT", "ColorSwatch", "TOPRIGHT", 52, -4)

		local editBoxes = {"Red", "Green", "Blue", "Alpha"}
		for i = 1, table.getn(editBoxes) do
			local ebn = editBoxes[i]
			local obj = CreateFrame("EditBox", "ECP" .. ebn .. "Box", ColorPickerFrame, "InputBoxTemplate")
			obj:SetFrameStrata("DIALOG")
			obj:SetMaxLetters(4)
			obj:SetAutoFocus(false)
			obj:SetWidth(35)
			obj:SetHeight(25)
			obj:SetID(i)
			if i == 1 then
				obj:SetPoint("TOPLEFT", 265, -68)
			else
				obj:SetPoint("TOP", "ECP" .. editBoxes[i - 1] .. "Box", "BOTTOM", 0, 3)
			end

			obj:SetScript("OnEscapePressed", function(self)
				self:ClearFocus()
				mod:UpdateEB()
			end)
			obj:SetScript("OnEnterPressed", function(self)
				self:ClearFocus()
				mod:UpdateEB()
			end)
			obj:SetScript("OnTextChanged", function(self) mod:UpdateColour_Alpha(self) end)
			obj:SetScript("OnEditFocusGained", function() mod.editBoxFocus = true end)
			obj:SetScript("OnEditFocusLost", function() mod.editBoxFocus = nil end)

			local objl = obj:CreateFontString("ECP" .. ebn .. "BoxLabel", "ARTWORK", "GameFontNormal")
			objl:SetPoint("RIGHT", "ECP" .. ebn .. "Box", "LEFT", -38, 0)
			objl:SetText(string.sub(ebn, 1, 1) .. ":")
			objl:SetTextColor(1, 1, 1)

			local objt = obj:CreateFontString("ECP" .. ebn .. "BoxText", "ARTWORK", "GameFontNormal")
			objt:SetPoint("LEFT", "ECP" .. ebn .. "Box", "LEFT", -38, 0)
			objt:SetTextColor(1, 1, 1)
			obj:Show()
		end

		-- define the Tab Pressed Scripts
		_G.ECPRedBox:SetScript("OnTabPressed", function(self) _G.ECPGreenBox:SetFocus() end)
		_G.ECPGreenBox:SetScript("OnTabPressed", function(self) _G.ECPBlueBox:SetFocus() end)
		_G.ECPBlueBox:SetScript("OnTabPressed", function(self) _G.ECPAlphaBox:SetFocus() end)
		_G.ECPAlphaBox:SetScript("OnTabPressed", function(self) _G.ECPRedBox:SetFocus() end)
	end)
end)