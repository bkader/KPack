local core = KPack
if not core then return end
core:AddModule("EnhancedStackSplit", "Enhances the StackSplitFrame with numbered Buttons.", function(L)
	if core:IsDisabled("EnhancedStackSplit") then return end

	local mod = core.EnhStackSplit or {}
	core.EnhStackSplit = mod

	local DB
	local defaults = {mode = 1, xlmode = false}

	local _G = _G
	local ContainerIDToInventoryID = ContainerIDToInventoryID
	local GetContainerItemLink = GetContainerItemLink
	local GetContainerNumSlots = GetContainerNumSlots
	local GetContainerNumFreeSlots = GetContainerNumFreeSlots
	local GetContainerItemInfo = GetContainerItemInfo
	local GetInventoryItemLink = GetInventoryItemLink
	local GetItemFamily = GetItemFamily

	local autoSplitMode = false
	local splititembag
	local splititemslot
	local maxstacksize = 0
	local slotlocks = nil
	local autosplitstackcount
	local autosplitnumstacks
	local autosplitnumber
	local autosplitleftover
	local autosplititemlink

	local positionanchor
	local positionparent
	local positionanchorto

	local splitMode = {
		[1] = L["Original WoW Mode"],
		[2] = L["1-Click Mode"],
		[3] = L["Auto Split Mode"]
	}
	local blockedFrames = {
		[1] = "MerchantItem",
		[2] = "GuildBank"
	}
	local mainBankFrames = {
		[1] = "BankFrame", -- default Blizzard Bank Frame
		[2] = "TBnkFrame" -- TBag
	}

	-- ================================================================== --

	local function Print(msg)
		if msg then
			core:Print(msg, "EnhancedStackSplit")
		end
	end

	local function reclaim(tbl)
		if type(tbl) ~= "table" then
			return
		end
		for k, v in pairs(tbl) do
			if type(v) == "table" then
				tbl[k] = reclaim(v)
			elseif type(tbl) == "table" then
				tbl[k] = nil
			end
			tbl = nil
		end
		return tbl
	end

	local function lockSlot(bag, slot)
		slotlocks = slotlocks or {}
		slotlocks[bag] = slotlocks[bag] or {}
		slotlocks[bag][slot] = true
	end

	local function isLockedSlot(bag, slot)
		return (slotlocks and slotlocks[bag] and slotlocks[bag][slot])
	end

	local function clearLockedSlots()
		slotlocks = reclaim(slotlocks)
	end

	local function isBag(bag)
		local iID = ContainerIDToInventoryID(bag)
		local baglink = GetInventoryItemLink("player", iID)
		return baglink or false
	end

	local function getFreeBagSlots()
		local freeslots = GetContainerNumFreeSlots(1)
		local containerbagtype = 0
		local itembagtype = GetItemFamily(autosplititemlink)

		for bag = 1, NUM_BAG_SLOTS do
			local baglink = isBag(bag)
			if baglink then
				containerbagtype = GetItemFamily(baglink)
				if containerbagtype == 0 or containerbagtype == itembagtype then
					freeslots = freeslots + GetContainerNumFreeSlots(bag)
				end
			end
		end
		return freeslots
	end

	local function getFreeSlot()
		local containerbagtype = 0
		local itembagtype = GetItemFamily(autosplititemlink)
		local goodbag = true
		for bag = 0, NUM_BAG_SLOTS do
			if bag > 0 then
				local baglink = isBag(bag)
				if baglink then
					containerbagtype = GetItemFamily(baglink)
					if containerbagtype == 0 or containerbagtype == itembagtype then
						goodbag = true
					else
						goodbag = false
					end
				end
			end
			if goodbag then
				for slot = 1, GetContainerNumSlots(bag) do
					if not isLockedSlot(bag, slot) then
						if not GetContainerItemLink(bag, slot) then
							return bag, slot
						end
					end
				end
			end
		end
		return nil
	end

	local function autoSplitCalc(num)
		local freeslots = getFreeBagSlots()
		local numstacks = math.floor(maxstacksize / num)
		if numstacks > freeslots then
			numstacks = freeslots
		end
		local leftover = maxstacksize - (numstacks * num)
		return freeslots or 0, numstacks or 0, leftover or 0
	end

	local function createButton(name, parent, template, anchorparent, width, anchorp, anchorrp, adimx, adimy, text, func1, func2)
		local b = CreateFrame("Button", name, _G[parent], template)
		b:SetWidth(width)
		b:SetHeight(24)
		b:SetPoint(anchorp, anchorparent, anchorrp, adimx, adimy)
		b:SetText(text)
		b:SetScript("OnClick", func1)
		if func2 then
			b:SetScript("OnEnter", func2)
			b:SetScript("OnLeave", function() _G.EnhancedStackSplitTextAutoText2:SetText("") end)
		end
	end

	-- ================================================================== --

	function mod:CreateFrames()
		local topframe = CreateFrame("Frame", "EnhancedStackSplitTopTextureFrame", StackSplitFrame)
		topframe:SetPoint("TOPLEFT", "StackSplitFrame", "TOPLEFT", 0, 2)
		topframe:SetWidth(172)
		topframe:SetHeight(20)
		local texture = topframe:CreateTexture(nil, "BACKGROUND")
		texture:SetTexture("Interface\\MoneyFrame\\UI-MoneyFrame2")
		texture:SetAllPoints(topframe)
		texture:SetBlendMode("ALPHAKEY")
		texture:SetTexCoord(0, 172 / 256, 0, 20 / 128)
		local text1 = topframe:CreateFontString("EnhancedStackSplitTextFrameTXT", "BACKGROUND", "GameFontNormalSmall")
		text1:SetPoint("TOP", "EnhancedStackSplitTopTextureFrame", "TOP", 1, -8)
		text1:SetJustifyH("CENTER")
		local text2 = topframe:CreateFontString("EnhancedStackSplitTextAutoText1", "BACKGROUND", "GameFontNormalSmall")
		text2:SetPoint("TOP", "EnhancedStackSplitTextFrameTXT", "BOTTOM", 0, -2)
		text2:SetJustifyH("CENTER")
		local text3 = topframe:CreateFontString("EnhancedStackSplitTextAutoText2", "BACKGROUND", "GameFontNormalSmall")
		text3:SetPoint("TOP", "EnhancedStackSplitTextAutoText1", "BOTTOM", 0, -2)
		text3:SetJustifyH("CENTER")

		local framebot = CreateFrame("Frame", "EnhancedStackSplitBottomTextureFrame", StackSplitFrame)
		framebot:EnableMouse(true)
		framebot:SetPoint("TOPLEFT", "StackSplitFrame", "BOTTOMLEFT", 0, 27)
		framebot:SetWidth(172)
		framebot:SetHeight(30)
		local texturebot = framebot:CreateTexture(nil, "BACKGROUND")
		texturebot:SetTexture("Interface\\MoneyFrame\\UI-MoneyFrame")
		texturebot:SetAllPoints(framebot)
		texturebot:SetTexCoord(0, 172 / 256, 46 / 128, 76 / 128)

		local framebot2 = CreateFrame("Frame", "EnhancedStackSplitBottom2TextureFrame", StackSplitFrame)
		framebot2:EnableMouse(true)
		framebot2:SetPoint("TOPLEFT", "EnhancedStackSplitBottomTextureFrame", "BOTTOMLEFT", 0, 0)
		framebot2:SetWidth(172)
		framebot2:SetHeight(50)
		local texturebot2 = framebot2:CreateTexture(nil, "BACKGROUND")
		texturebot2:SetTexture("Interface\\MoneyFrame\\UI-MoneyFrame")
		texturebot2:SetAllPoints(framebot2)
		texturebot2:SetTexCoord(0, 172 / 256, 46 / 128, 96 / 128)

		local autoframe = CreateFrame("Frame", "EnhancedStackSplitAutoTextureFrame", StackSplitFrame)
		autoframe:SetPoint("TOPLEFT", "StackSplitFrame", "TOPLEFT", 16, -13)
		autoframe:SetWidth(142)
		autoframe:SetHeight(37)
		autoframe:Hide()
		local textureauto1 = autoframe:CreateTexture(nil, "BACKGROUND")
		textureauto1:SetTexture("Interface\\MoneyFrame\\UI-MoneyFrame2")
		textureauto1:SetAllPoints(autoframe)
		textureauto1:SetTexCoord(16 / 256, 158 / 256, 13 / 128, 50 / 128)
		local textureauto2 = autoframe:CreateTexture(nil, "HIGH")
		textureauto2:SetTexture("Interface\\DialogFrame\\DialogAlertIcon")
		textureauto2:SetPoint("BOTTOM", "EnhancedStackSplitAutoTextureFrame", "TOPRIGHT", 6, 0)
		textureauto2:SetWidth(41)
		textureauto2:SetHeight(32)
		textureauto2:SetTexCoord(11 / 64, 52 / 64, 16 / 64, 48 / 64)
		local textureauto3 = autoframe:CreateTexture(nil, "HIGH")
		textureauto3:SetTexture("Interface\\DialogFrame\\DialogAlertIcon")
		textureauto3:SetPoint("BOTTOM", "EnhancedStackSplitAutoTextureFrame", "TOPLEFT", -6, 0)
		textureauto3:SetWidth(41)
		textureauto3:SetHeight(32)
		textureauto3:SetTexCoord(11 / 64, 52 / 64, 16 / 64, 48 / 64)

		createButton(
			"EnhancedStackSplitAuto1Button",
			"StackSplitFrame",
			"KPackButtonTemplate",
			"StackSplitFrame",
			64,
			"RIGHT",
			"BOTTOM",
			-1,
			40,
			"1",
			function() mod:Split(1) end,
			function() mod:AutoSplitInfo(1) end
		)
		_G.EnhancedStackSplitAuto1Button:Hide()

		createButton(
			"EnhancedStackSplitButton1",
			"EnhancedStackSplitBottomTextureFrame",
			"KPackButtonTemplate",
			"EnhancedStackSplitBottomTextureFrame",
			22,
			"TOPLEFT",
			"TOPLEFT",
			10,
			2,
			"2",
			function() mod:Split(2) end,
			function() mod:AutoSplitInfo(2) end
		)
		createButton(
			"EnhancedStackSplitButton2",
			"EnhancedStackSplitBottomTextureFrame",
			"KPackButtonTemplate",
			"EnhancedStackSplitButton1",
			22,
			"TOPLEFT",
			"TOPRIGHT",
			-1,
			0,
			"3",
			function() mod:Split(3) end,
			function() mod:AutoSplitInfo(3) end
		)
		createButton(
			"EnhancedStackSplitButton3",
			"EnhancedStackSplitBottomTextureFrame",
			"KPackButtonTemplate",
			"EnhancedStackSplitButton2",
			22,
			"TOPLEFT",
			"TOPRIGHT",
			-1,
			0,
			"4",
			function() mod:Split(4) end,
			function() mod:AutoSplitInfo(4) end
		)
		createButton(
			"EnhancedStackSplitButton4",
			"EnhancedStackSplitBottomTextureFrame",
			"KPackButtonTemplate",
			"EnhancedStackSplitButton3",
			22,
			"TOPLEFT",
			"TOPRIGHT",
			-1,
			0,
			"5",
			function() mod:Split(5) end,
			function() mod:AutoSplitInfo(5) end
		)
		createButton(
			"EnhancedStackSplitButton5",
			"EnhancedStackSplitBottomTextureFrame",
			"KPackButtonTemplate",
			"EnhancedStackSplitButton4",
			22,
			"TOPLEFT",
			"TOPRIGHT",
			-1,
			0,
			"6",
			function() mod:Split(6) end,
			function() mod:AutoSplitInfo(6) end
		)
		createButton(
			"EnhancedStackSplitButton6",
			"EnhancedStackSplitBottomTextureFrame",
			"KPackButtonTemplate",
			"EnhancedStackSplitButton5",
			22,
			"TOPLEFT",
			"TOPRIGHT",
			-1,
			0,
			"7",
			function() mod:Split(7) end,
			function() mod:AutoSplitInfo(7) end
		)
		createButton(
			"EnhancedStackSplitButton7",
			"EnhancedStackSplitBottomTextureFrame",
			"KPackButtonTemplate",
			"EnhancedStackSplitButton6",
			22,
			"TOPLEFT",
			"TOPRIGHT",
			-1,
			0,
			"8",
			function() mod:Split(8) end,
			function() mod:AutoSplitInfo(8) end
		)
		createButton(
			"EnhancedStackSplitButton8",
			"EnhancedStackSplitBottomTextureFrame",
			"KPackButtonTemplate",
			"EnhancedStackSplitButton7",
			22,
			"TOPLEFT",
			"TOPRIGHT",
			-1,
			0,
			"9",
			function() mod:Split(9) end,
			function() mod:AutoSplitInfo(9) end
		)
		createButton(
			"EnhancedStackSplitButton9",
			"EnhancedStackSplitBottomTextureFrame",
			"KPackButtonTemplate",
			"EnhancedStackSplitButton1",
			26,
			"TOPLEFT",
			"BOTTOMLEFT",
			0,
			2,
			"10",
			function() mod:Split(10) end,
			function() mod:AutoSplitInfo(10) end
		)
		createButton(
			"EnhancedStackSplitButton10",
			"EnhancedStackSplitBottomTextureFrame",
			"KPackButtonTemplate",
			"EnhancedStackSplitButton9",
			26,
			"TOPLEFT",
			"TOPRIGHT",
			-1,
			0,
			"20",
			function() mod:Split(20) end,
			function() mod:AutoSplitInfo(20) end
		)

		createButton(
			"EnhancedStackSplitButton11",
			"EnhancedStackSplitBottomTextureFrame",
			"KPackButtonTemplate",
			"EnhancedStackSplitButton1",
			26,
			"TOPLEFT",
			"BOTTOMLEFT",
			7,
			2.5,
			"10",
			function() mod:Split(10) end,
			function() mod:AutoSplitInfo(10) end
		)
		createButton(
			"EnhancedStackSplitButton12",
			"EnhancedStackSplitBottomTextureFrame",
			"KPackButtonTemplate",
			"EnhancedStackSplitButton11",
			26,
			"TOPLEFT",
			"TOPRIGHT",
			-1,
			0,
			"12",
			function() mod:Split(12) end,
			function() mod:AutoSplitInfo(12) end
		)
		createButton(
			"EnhancedStackSplitButton13",
			"EnhancedStackSplitBottomTextureFrame",
			"KPackButtonTemplate",
			"EnhancedStackSplitButton12",
			26,
			"TOPLEFT",
			"TOPRIGHT",
			-1,
			0,
			"14",
			function() mod:Split(14) end,
			function() mod:AutoSplitInfo(14) end
		)
		createButton(
			"EnhancedStackSplitButton14",
			"EnhancedStackSplitBottomTextureFrame",
			"KPackButtonTemplate",
			"EnhancedStackSplitButton13",
			26,
			"TOPLEFT",
			"TOPRIGHT",
			-1,
			0,
			"15",
			function() mod:Split(15) end,
			function() mod:AutoSplitInfo(15) end
		)
		createButton(
			"EnhancedStackSplitButton15",
			"EnhancedStackSplitBottomTextureFrame",
			"KPackButtonTemplate",
			"EnhancedStackSplitButton14",
			26,
			"TOPLEFT",
			"TOPRIGHT",
			-1,
			0,
			"16",
			function() mod:Split(16) end,
			function() mod:AutoSplitInfo(16) end
		)
		createButton(
			"EnhancedStackSplitButton16",
			"EnhancedStackSplitBottomTextureFrame",
			"KPackButtonTemplate",
			"EnhancedStackSplitButton15",
			26,
			"TOPLEFT",
			"TOPRIGHT",
			-1,
			0,
			"20",
			function() mod:Split(20) end,
			function() mod:AutoSplitInfo(20) end
		)

		createButton(
			"EnhancedStackSplitAutoSplitButton",
			"EnhancedStackSplitBottomTextureFrame",
			"KPackButtonTemplate",
			"EnhancedStackSplitButton8",
			1,
			"TOPRIGHT",
			"BOTTOMRIGHT",
			0,
			2,
			L["Auto"],
			function() mod:ModeToggle(3) end
		)
		createButton(
			"EnhancedStackSplitModeTXTButton",
			"EnhancedStackSplitBottomTextureFrame",
			"KPackButtonTemplate",
			"EnhancedStackSplitAutoSplitButton",
			1,
			"TOPRIGHT",
			"TOPLEFT",
			3,
			0,
			L["M"],
			function() mod:ModeToggle(1) end
		)
		_G.EnhancedStackSplitAutoSplitButton:SetWidth(
			ceil(_G.EnhancedStackSplitAutoSplitButton:GetTextWidth()) + 10
		)
		_G.EnhancedStackSplitModeTXTButton:SetWidth(ceil(_G.EnhancedStackSplitModeTXTButton:GetTextWidth()) + 10)

		local XLButton = CreateFrame("Button", "EnhancedStackSplitXLModeButton", _G.EnhancedStackSplitBottomTextureFrame)
		XLButton:SetWidth(20)
		XLButton:SetHeight(12)
		XLButton:SetPoint("CENTER", "EnhancedStackSplitBottomTextureFrame", "CENTER", 0, -30)

		local textureNormal = XLButton:CreateTexture("EnhancedStackSplitXLModeButtonNormalTexture", "ARTWORK")
		textureNormal:SetAllPoints(XLButton)
		textureNormal:SetTexture("Interface\\Buttons\\UI-TotemBar")
		textureNormal:SetTexCoord(100 / 128, 126 / 128, 104 / 256, 119 / 256)
		XLButton:SetNormalTexture(textureNormal)
		local textureHighlight = XLButton:CreateTexture("EnhancedStackSplitXLModeButtonHighlightTexture", "ARTWORK")
		textureHighlight:SetPoint("TOPLEFT", 3, -3)
		textureHighlight:SetPoint("BOTTOMRIGHT", -3, 3)
		textureHighlight:SetTexture("Interface\\Buttons\\UI-TotemBar")
		textureHighlight:SetTexCoord(72 / 128, 92 / 128, 69 / 256, 79 / 256)
		XLButton:SetHighlightTexture(textureHighlight)
		local texturePushed = XLButton:CreateTexture("EnhancedStackSplitXLModeButtonPushedTexture", "ARTWORK")
		texturePushed:SetPoint("TOPLEFT", 1, -1)
		texturePushed:SetPoint("BOTTOMRIGHT", -1, 1)
		texturePushed:SetTexture("Interface\\Buttons\\UI-TotemBar")
		texturePushed:SetTexCoord(100 / 128, 126 / 128, 104 / 256, 119 / 256)
		XLButton:SetPushedTexture(texturePushed)
		local textureDisabled = XLButton:CreateTexture("EnhancedStackSplitXLModeButtonDisabledTexture", "ARTWORK")
		textureDisabled:SetAllPoints(XLButton)
		textureDisabled:SetTexture("Interface\\Buttons\\UI-TotemBar")
		textureDisabled:SetTexCoord(100 / 128, 126 / 128, 104 / 256, 119 / 256)
		XLButton:SetDisabledTexture(textureDisabled)

		local shaderSupported = textureDisabled:SetDesaturated(true)
		if not shaderSupported then
			textureDisabled:SetVertexColor(0.5, 0.5, 0.5)
		end

		XLButton:SetScript("OnClick", function() mod:XLModeToggle() end)

		mod:ModeSettings(DB.mode)
		mod:RepositionButtons()
	end

	function mod:PositionSplitFrame()
		if DB.xlmode then
			StackSplitFrame:SetPoint(positionanchor, positionparent, positionanchorto, 0, 35)
		else
			StackSplitFrame:SetPoint(positionanchor, positionparent, positionanchorto, 0, 14)
		end
	end

	function mod:RepositionButtons()
		if DB.xlmode then
			_G.EnhancedStackSplitBottomTextureFrame:SetHeight(30)
			_G.EnhancedStackSplitAutoSplitButton:SetPoint("TOPRIGHT", "EnhancedStackSplitButton8", "BOTTOMRIGHT", 0, -19)

			_G.EnhancedStackSplitButton9:SetText("100")
			_G.EnhancedStackSplitButton9:SetWidth(34)
			_G.EnhancedStackSplitButton9:SetScript("OnClick", function() mod:Split(100) end)
			_G.EnhancedStackSplitButton9:SetScript("OnEnter", function() mod:AutoSplitInfo(100) end)
			_G.EnhancedStackSplitButton9:SetPoint("TOPLEFT", "EnhancedStackSplitButton1", "BOTTOMLEFT", 0, -19)
			_G.EnhancedStackSplitButton10:Hide()

			_G.EnhancedStackSplitButton11:Show()
			_G.EnhancedStackSplitButton12:Show()
			_G.EnhancedStackSplitButton13:Show()
			_G.EnhancedStackSplitButton14:Show()
			_G.EnhancedStackSplitButton15:Show()
			_G.EnhancedStackSplitButton16:Show()

			_G.EnhancedStackSplitXLModeButton:SetPoint("CENTER", "EnhancedStackSplitBottomTextureFrame", "CENTER", 0, -45)
			_G.EnhancedStackSplitXLModeButtonNormalTexture:SetTexCoord(100 / 128, 126 / 128, 123 / 256, 138 / 256)
			_G.EnhancedStackSplitXLModeButtonPushedTexture:SetTexCoord(100 / 128, 126 / 128, 123 / 256, 138 / 256)
			_G.EnhancedStackSplitXLModeButtonDisabledTexture:SetTexCoord(100 / 128, 126 / 128, 123 / 256, 138 / 256)
			_G.EnhancedStackSplitXLModeButtonHighlightTexture:SetTexCoord(72 / 128, 92 / 128, 88 / 256, 98 / 256)
		else
			_G.EnhancedStackSplitBottomTextureFrame:SetHeight(9)
			_G.EnhancedStackSplitAutoSplitButton:SetPoint("TOPRIGHT", "EnhancedStackSplitButton8", "BOTTOMRIGHT", 0, 2)

			_G.EnhancedStackSplitButton9:SetText("10")
			_G.EnhancedStackSplitButton9:SetWidth(26)
			_G.EnhancedStackSplitButton9:SetScript("OnClick", function() mod:Split(10) end)
			_G.EnhancedStackSplitButton9:SetScript("OnEnter", function() mod:AutoSplitInfo(10) end)
			_G.EnhancedStackSplitButton9:SetPoint("TOPLEFT", "EnhancedStackSplitButton1", "BOTTOMLEFT", 0, 2)
			_G.EnhancedStackSplitButton10:Show()

			_G.EnhancedStackSplitButton11:Hide()
			_G.EnhancedStackSplitButton12:Hide()
			_G.EnhancedStackSplitButton13:Hide()
			_G.EnhancedStackSplitButton14:Hide()
			_G.EnhancedStackSplitButton15:Hide()
			_G.EnhancedStackSplitButton16:Hide()

			_G.EnhancedStackSplitXLModeButton:SetPoint("CENTER", "EnhancedStackSplitBottomTextureFrame", "CENTER", 0, -34)
			_G.EnhancedStackSplitXLModeButtonNormalTexture:SetTexCoord(100 / 128, 126 / 128, 104 / 256, 119 / 256)
			_G.EnhancedStackSplitXLModeButtonPushedTexture:SetTexCoord(100 / 128, 126 / 128, 104 / 256, 119 / 256)
			_G.EnhancedStackSplitXLModeButtonDisabledTexture:SetTexCoord(100 / 128, 126 / 128, 104 / 256, 119 / 256)
			_G.EnhancedStackSplitXLModeButtonHighlightTexture:SetTexCoord(72 / 128, 92 / 128, 69 / 256, 79 / 256)
		end
	end

	function mod:XLModeToggle()
		DB.xlmode = not DB.xlmode
		mod:PositionSplitFrame()
		mod:RepositionButtons()
		if autoSplitMode then
			mod:ModeSettings(3)
		else
			mod:ModeSettings(DB.mode)
		end
	end

	function mod:ModeToggle(mode)
		if mode == 3 then
			autoSplitMode = true
			mod:ModeSettings(3)
		else
			if not autoSplitMode then
				if DB.mode == 2 then
					DB.mode = 1
				else
					DB.mode = 2
				end
			end
			autoSplitMode = false
			mod:ModeSettings(DB.mode)
		end
	end

	function mod:AutoSplitButtonToggle(toggle)
		if toggle then
			for i = 1, 16 do
				mod:ButtonTweak("EnhancedStackSplitButton" .. i, 1)
			end
			_G.EnhancedStackSplitXLModeButton:Enable()
			_G.EnhancedStackSplitAuto1Button:Enable()
			_G.EnhancedStackSplitModeTXTButton:Enable()
			_G.StackSplitCancelButton:Enable()
		else
			for i = 1, 16 do
				mod:ButtonTweak("EnhancedStackSplitButton" .. i, 0)
			end
			_G.EnhancedStackSplitXLModeButton:Disable()
			_G.EnhancedStackSplitAuto1Button:Disable()
			_G.EnhancedStackSplitModeTXTButton:Disable()
			_G.StackSplitCancelButton:Disable()
		end
	end

	function mod:ButtonTweak(button, state)
		-- button: string
		-- state : 0=disable | 1=enable
		if state == 0 then
			_G[button]:Disable()
			_G[button]:SetDisabledTexture(nil)
			_G[button .. "Left"]:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled")
			_G[button .. "Middle"]:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled")
			_G[button .. "Right"]:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled")
			_G[button]:SetScript("OnMouseDown", nil)
			_G[button]:SetScript("OnMouseUp", nil)
		else
			_G[button]:Enable()
			_G[button .. "Left"]:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up")
			_G[button .. "Middle"]:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up")
			_G[button .. "Right"]:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up")
		end
	end

	function mod:ModeSettings(mode)
		for i = 1, 16 do
			mod:ButtonTweak("EnhancedStackSplitButton" .. i, 1)
		end
		if mode == 3 then
			if DB.xlmode then
				if maxstacksize > 1 and maxstacksize < 10 then
					for i = maxstacksize - 1, 9 do
						mod:ButtonTweak("EnhancedStackSplitButton" .. i, 0)
					end
				end
				if maxstacksize < 11 then
					mod:ButtonTweak("EnhancedStackSplitButton11", 0)
				end
				if maxstacksize < 13 then
					mod:ButtonTweak("EnhancedStackSplitButton12", 0)
				end
				if maxstacksize < 15 then
					mod:ButtonTweak("EnhancedStackSplitButton13", 0)
				end
				if maxstacksize < 16 then
					mod:ButtonTweak("EnhancedStackSplitButton14", 0)
				end
				if maxstacksize < 17 then
					mod:ButtonTweak("EnhancedStackSplitButton15", 0)
				end
				if maxstacksize < 21 then
					mod:ButtonTweak("EnhancedStackSplitButton16", 0)
				end
				if maxstacksize < 101 then
					mod:ButtonTweak("EnhancedStackSplitButton9", 0)
				end
			else
				if maxstacksize > 1 and maxstacksize < 11 then
					for i = maxstacksize - 1, 10 do
						mod:ButtonTweak("EnhancedStackSplitButton" .. i, 0)
					end
				end
				if maxstacksize < 21 then
					mod:ButtonTweak("EnhancedStackSplitButton10", 0)
				end
			end
			mod:ButtonTweak("EnhancedStackSplitAutoSplitButton", 0)
			_G.StackSplitOkayButton:Hide()
			_G.StackSplitLeftButton:Hide()
			_G.StackSplitRightButton:Hide()
			_G.EnhancedStackSplitAutoTextureFrame:Show()
			_G.EnhancedStackSplitAuto1Button:Show()
			_G.EnhancedStackSplitTextAutoText1:Show()
			_G.EnhancedStackSplitTextAutoText2:Show()
			_G.EnhancedStackSplitTextAutoText1:SetText("|cffffffff" .. L["Free Bag Slots"] .. ":|r |cffff8000" .. getFreeBagSlots() .. "|r")
			_G.EnhancedStackSplitTextAutoText2:SetText("")
		else
			if DB.xlmode then
				if maxstacksize > 1 and maxstacksize < 10 then
					for i = maxstacksize, 9 do
						mod:ButtonTweak("EnhancedStackSplitButton" .. i, 0)
					end
				end
				if maxstacksize < 10 then
					mod:ButtonTweak("EnhancedStackSplitButton11", 0)
				end
				if maxstacksize < 12 then
					mod:ButtonTweak("EnhancedStackSplitButton12", 0)
				end
				if maxstacksize < 14 then
					mod:ButtonTweak("EnhancedStackSplitButton13", 0)
				end
				if maxstacksize < 15 then
					mod:ButtonTweak("EnhancedStackSplitButton14", 0)
				end
				if maxstacksize < 16 then
					mod:ButtonTweak("EnhancedStackSplitButton15", 0)
				end
				if maxstacksize < 20 then
					mod:ButtonTweak("EnhancedStackSplitButton16", 0)
				end
				if maxstacksize < 100 then
					mod:ButtonTweak("EnhancedStackSplitButton9", 0)
				end
			else
				if maxstacksize > 1 and maxstacksize < 11 then
					for i = maxstacksize, 10 do
						mod:ButtonTweak("EnhancedStackSplitButton" .. i, 0)
					end
				end
				if maxstacksize < 20 then
					mod:ButtonTweak("EnhancedStackSplitButton10", 0)
				end
			end
			if not autosplititemlink then
				mod:ButtonTweak("EnhancedStackSplitAutoSplitButton", 0)
			else
				mod:ButtonTweak("EnhancedStackSplitAutoSplitButton", 1)
			end
			_G.EnhancedStackSplitAutoTextureFrame:Hide()
			_G.EnhancedStackSplitAuto1Button:Hide()
			_G.EnhancedStackSplitTextAutoText1:Hide()
			_G.EnhancedStackSplitTextAutoText2:Hide()
			_G.StackSplitOkayButton:Show()
			_G.StackSplitLeftButton:Show()
			_G.StackSplitRightButton:Show()
		end
		_G.EnhancedStackSplitTextFrameTXT:SetText(splitMode[mode])
	end

	function mod:AutoSplitInfo(num)
		local freeslots, numstacks, leftover = autoSplitCalc(num)
		_G.EnhancedStackSplitTextAutoText2:SetText("|cffffffff" .. maxstacksize .. " | |cffff8000" .. numstacks .. "|cffffffffx " .. num .. " | " .. L["leftover"] .. "=" .. leftover .. "|r")
	end

	function mod.OpenStackSplitFrame(maxStack, parent, anchor, anchorTo)
		if not maxStack or not parent or not anchor or not anchorTo then
			return
		end

		if maxStack < 2 then
			return
		end

		positionanchor = anchor
		positionparent = parent
		positionanchorto = anchorTo

		splititembag = StackSplitFrame.owner:GetParent():GetID()
		splititemslot = StackSplitFrame.owner:GetID()

		local splitItemName = StackSplitFrame.owner:GetParent():GetName()
		if splitItemName then
			for i = 1, #mainBankFrames do -- this needs some better solution
				if string.find(splitItemName, mainBankFrames[i]) then
					splititembag = -1
				end
			end
			for i = 1, #blockedFrames do -- this needs some better solution
				if string.find(splitItemName, blockedFrames[i]) then
					splititembag = nil
				end
			end
		end

		autosplititemlink = nil
		if splititembag then
			autosplititemlink = GetContainerItemLink(splititembag, splititemslot)
		end

		maxstacksize = maxStack
		mod:PositionSplitFrame()
		_G.StackSplitOkayButton:SetPoint("RIGHT", "StackSplitFrame", "BOTTOM", -3, 40)
		_G.StackSplitCancelButton:SetPoint("LEFT", "StackSplitFrame", "BOTTOM", 5, 40)
		autoSplitMode = false
		mod:AutoSplitButtonToggle(true)
		_G.EnhancedStackSplitTextFrameTXT:SetText(splitMode[DB.mode])
		mod:ModeSettings(DB.mode)
	end

	function mod:Split(num)
		if autoSplitMode then
			local freeslots, numstacks, leftover = autoSplitCalc(num)
			autosplitstackcount = 0
			autosplitnumstacks = numstacks
			autosplitleftover = leftover
			autosplitnumber = num
			clearLockedSlots()
			mod:AutoSplitButtonToggle(false)
			mod:AutoSplit(autosplitnumstacks, autosplitnumber, autosplitleftover)
		else
			mod:SingleSplit(num)
		end
	end

	function mod:CheckItemLock(arg1, arg2)
		if StackSplitFrame:IsShown() and StackSplitFrame.owner and splititembag and splititemslot then
			if arg1 and arg2 then
				if arg1 == splititembag and arg2 == splititemslot then
					local locked = select(3, GetContainerItemInfo(splititembag, splititemslot))
					if not locked then
						mod:AutoSplit(autosplitnumstacks, autosplitnumber, autosplitleftover)
					end
				end
			end
		end
	end

	function mod:AutoSplit(numstacks, num, leftover)
		if leftover == 0 then
			if autosplitstackcount == numstacks - 1 then
				StackSplitFrame:Hide()
				return
			end
		else
			if autosplitstackcount == numstacks then
				StackSplitFrame:Hide()
				return
			end
		end
		local bag, slot = getFreeSlot()
		SplitContainerItem(splititembag, splititemslot, num)
		if bag ~= nil then
			lockSlot(bag, slot)
			PickupContainerItem(bag, slot)
		end
		autosplitstackcount = autosplitstackcount + 1
	end

	function mod:SingleSplit(num)
		if num >= StackSplitFrame.maxStack then
			num = StackSplitFrame.maxStack
			_G.StackSplitRightButton:Disable()
		end
		if num < StackSplitFrame.maxStack then
			_G.StackSplitRightButton:Enable()
		end
		_G.StackSplitLeftButton:Enable()
		StackSplitFrame.split = num
		StackSplitText:SetText(num)
		if DB.mode == 2 then
			StackSplitFrameOkay_Click()
		end
	end

	-- ================================================================== --

	local function SetupDatabase()
		if not DB then
			if type(core.db.StackSplit) ~= "table" or not next(core.db.StackSplit) then
				core.db.StackSplit = CopyTable(defaults)
			end
			DB = core.db.StackSplit
		end
	end
	core:RegisterForEvent("PLAYER_LOGIN", function()
		SetupDatabase()
		mod:CreateFrames()
		hooksecurefunc("OpenStackSplitFrame", mod.OpenStackSplitFrame)
	end)

	core:RegisterForEvent("ITEM_LOCK_CHANGED", function(_, ...)
		SetupDatabase()
		mod:CheckItemLock(...)
	end)
end)