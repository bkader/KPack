local core = KPack
if not core then return end
core:AddModule("SnowfallKeyPress", "Allows you to cast your spells on key down instead of on key up.", function(L)
	if core:IsDisabled("SnowfallKeyPress") then return end

	-------------------------------------------------------------------------------
	-- Module declaration
	--
	local SnowfallKeyPress = {}

	-------------------------------------------------------------------------------
	-- Module settings
	--

	local DB, SetupDatabase
	SnowfallKeyPress.settings = {
		keys = {
			"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
			"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "`", "-", "=", "[", "]", "\\", ";", "'", ".", ",", "/",
			"F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12",
			"BACKSPACE", "DELETE", "END", "ENTER", "ESCAPE", "HOME", "INSERT",
			"UP", "DOWN", "LEFT", "RIGHT",
			"NUMLOCK", "NUMPAD0", "NUMPAD1", "NUMPAD2", "NUMPAD3", "NUMPAD4", "NUMPAD5", "NUMPAD6", "NUMPAD7", "NUMPAD8", "NUMPAD9",
			"NUMPADDECIMAL", "NUMPADDIVIDE", "NUMPADMINUS", "NUMPADMULTIPLY", "NUMPADPLUS",
			"PAGEDOWN", "PAGEUP", "PAUSE", "SCROLLLOCK", "SPACE", "TAB", "BUTTON3", "BUTTON4", "BUTTON5"
		},
		modifiers = {"ALT", "CTRL", "SHIFT"}
	}

	-------------------------------------------------------------------------------
	-- KeyPress Animations
	--

	local animate
	do
		local animationsCount, animations = 5, {}
		local frame, texture, animationGroup, alpha1, scale1, scale2, rotation2
		for i = 1, animationsCount do
			frame = CreateFrame("Frame")

			-- Create an animation texture
			texture = frame:CreateTexture()
			texture:SetTexture([[Interface\Cooldown\star4]])
			texture:SetAlpha(0)
			texture:SetAllPoints(frame)
			texture:SetBlendMode("ADD")

			-- Create an animation group for that texture
			animationGroup = texture:CreateAnimationGroup()

			-- Start by making the animation texture visible
			alpha1 = animationGroup:CreateAnimation("Alpha")
			alpha1:SetChange(1)
			alpha1:SetDuration(0)
			alpha1:SetOrder(1)

			-- Start by making the animation texture 1.5x the size of the button
			scale1 = animationGroup:CreateAnimation("Scale")
			scale1:SetScale(1.5, 1.5)
			scale1:SetDuration(0)
			scale1:SetOrder(1)

			-- Over 0.2 seconds, scale the animation texture down to zero size
			scale2 = animationGroup:CreateAnimation("Scale")
			scale2:SetScale(0, 0)
			scale2:SetDuration(0.3)
			scale2:SetOrder(2)

			-- Over 0.3 seconds, rotate the animation texture counter-clockwise by 90 degrees
			rotation2 = animationGroup:CreateAnimation("Rotation")
			rotation2:SetDegrees(90)
			rotation2:SetDuration(0.3)
			rotation2:SetOrder(2)

			animations[i] = {frame = frame, animationGroup = animationGroup}
		end

		local animationNum = 1
		function animate(button)
			-- Don't animate invisible buttons
			if (not button:IsVisible()) then
				return true
			end

			local animation = animations[animationNum]
			local frame = animation.frame
			local animationGroup = animation.animationGroup

			-- Place the animation on top of the button
			frame:SetFrameStrata(button:GetFrameStrata())
			frame:SetFrameLevel(button:GetFrameLevel() + 10)
			frame:SetPoint("TOPLEFT", button, "TOPLEFT", -3, 3)
			frame:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 3, -3)

			-- Play the animation from the beginning
			animationGroup:Stop()
			animationGroup:Play()

			-- Cycle to the next animation on the next call
			animationNum = (animationNum % animationsCount) + 1

			return true
		end
	end

	SnowfallKeyPress.animation = SnowfallKeyPress.animation or {}
	SnowfallKeyPress.animation.handlers = SnowfallKeyPress.animation.handlers or {}
	SnowfallKeyPress.animation.savedDefaultHandler = animate

	-------------------------------------------------------------------------------
	-- Globals
	--

	local _G = _G
	local strmatch, strgsub = string.match, string.gsub
	local pairs, ipairs = pairs, ipairs
	local tinsert, tremove = table.insert, table.remove
	local select, type = select, type
	local IsShiftKeyDown = IsShiftKeyDown
	local IsControlKeyDown = IsControlKeyDown
	local IsAltKeyDown = IsAltKeyDown

	local keysConfig = {}
	local updateBindings

	--------------------------------------------------------------------------------
	-- Initialization

	local templates = {
		{command = "^ACTIONBUTTON(%d+)$", attributes = {{"type", "macro"}, {"actionbutton", "%1"}}}, -- Action Buttons
		{command = "^MULTIACTIONBAR1BUTTON(%d+)$", attributes = {{"type", "click"}, {"clickbutton", "MultiBarBottomLeftButton%1"}}}, -- BottomLeft Action Buttons
		{command = "^MULTIACTIONBAR2BUTTON(%d+)$", attributes = {{"type", "click"}, {"clickbutton", "MultiBarBottomRightButton%1"}}}, -- BottomRight Action Buttons
		{command = "^MULTIACTIONBAR3BUTTON(%d+)$", attributes = {{"type", "click"}, {"clickbutton", "MultiBarRightButton%1"}}}, -- Right Action Buttons (rightmost)
		{command = "^MULTIACTIONBAR4BUTTON(%d+)$", attributes = {{"type", "click"}, {"clickbutton", "MultiBarLeftButton%1"}}}, -- Right ActionBar 2 Buttons (2nd from right)
		{command = "^SHAPESHIFTBUTTON(%d+)$", attributes = {{"type", "click"}, {"clickbutton", "ShapeshiftButton%1"}}}, -- Special Action Buttons (shapeshift/stance)
		{command = "^BONUSACTIONBUTTON(%d+)$", attributes = {{"type", "click"}, {"clickbutton", "PetActionButton%1"}}}, -- Secondary Action Buttons (pet/bonus)
		{command = "^MULTICASTSUMMONBUTTON(%d+)$", attributes = {{"type", "click"}, {"multicastsummon", "%1"}}}, -- Call of the Elements/Ancestors/Spirits
		{command = "^MULTICASTRECALLBUTTON1$", attributes = {{"type", "click"}, {"clickbutton", "MultiCastRecallSpellButton"}}}, -- Totemic Recall
		{command = "^CLICK (.+):([^:]+)$", attributes = {{"type", "click"}, {"clickbutton", "%1"}}}, -- Clicks
		{command = "^MACRO (.+)$", attributes = {{"type", "macro"}, {"macro", "%1"}}}, -- Macros
		{command = "^SPELL (.+)$", attributes = {{"type", "spell"}, {"spell", "%1"}}}, -- Spells
		{command = "^ITEM (.+)$", attributes = {{"type", "item"}, {"item", "%1"}}} -- Items
	}

	local hook = true

	local overrideFrame = CreateFrame("Frame")

	local allowedTypeAttributes = {
		actionbar = true,
		action = true,
		pet = true,
		multispell = true,
		spell = true,
		item = true,
		macro = true,
		cancelaura = true,
		stop = true,
		target = true,
		focus = true,
		assist = true,
		maintank = true,
		mainassist = true
	}

	--------------------------------------------------------------------------------
	-- Keys and modifiers

	local keys = SnowfallKeyPress.settings.keys
	local modifiers = SnowfallKeyPress.settings.modifiers

	-- Create a table of all possible combinations of modifiers
	local modifierCombos = {}
	local function createModifierCombos(base, modifierNum, modifiers, modifierCombos)
		local modifier = modifiers[modifierNum]
		if not modifier then
			tinsert(modifierCombos, base)
			return
		end

		local nextModifierNum = modifierNum + 1
		createModifierCombos(base, nextModifierNum, modifiers, modifierCombos)
		createModifierCombos(base .. modifier .. "-", nextModifierNum, modifiers, modifierCombos)
	end
	createModifierCombos("", 1, modifiers, modifierCombos)

	local function keyLess(key1, key2)
		local comp1, comp2

		comp1 = strgsub(key1, "^.*%-(.+)", "%1", 1)
		comp2 = strgsub(key2, "^.*%-(.+)", "%1", 1)
		if comp1 < comp2 then
			return true
		elseif comp1 > comp2 then
			return false
		end

		comp1 = strmatch(key1, "ALT%-")
		comp2 = strmatch(key2, "ALT%-")
		if not comp1 and comp2 then
			return true
		elseif comp1 and not comp2 then
			return false
		end

		comp1 = strmatch(key1, "CTRL%-")
		comp2 = strmatch(key2, "CTRL%-")
		if not comp1 and comp2 then
			return true
		elseif comp1 and not comp2 then
			return false
		end

		comp1 = strmatch(key1, "SHIFT%-")
		comp2 = strmatch(key2, "SHIFT%-")
		if not comp1 and comp2 then
			return true
		elseif comp1 and not comp2 then
			return false
		end

		return nil
	end

	function insertKey(key)
		local less, position
		position = 0
		for k, v in ipairs(keysConfig) do
			less = keyLess(key, v)
			if less == nil then
				return nil
			elseif less == true then
				break
			end
			position = k
		end
		position = position + 1
		tinsert(keysConfig, position, key)
		return position
	end

	local function removeKey(key)
		for k, v in ipairs(keysConfig) do
			if key == v then
				tremove(keysConfig, k)
				return k
			end
		end
		return false
	end

	--------------------------------------------------------------------------------
	-- Configuration

	local scrollBarUpdate

	local function populateKeysConfig()
		wipe(keysConfig)
		for _, key in ipairs(keys) do
			if strmatch(key, "-.") then
				insertKey(strmatch(key, "^-?(.*)$"))
			else
				for _, modifierCombo in ipairs(modifierCombos) do
					insertKey(modifierCombo .. key)
				end
			end
		end
	end

	local configFrame = CreateFrame("Frame", nil, UIParent)
	configFrame:SetWidth(420)
	configFrame:SetHeight(310)
	configFrame:SetPoint("TOPLEFT", 200, -200)
	configFrame:SetBackdrop({
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 16,
		insets = {left = 4, right = 4, top = 4, bottom = 4}
	})
	configFrame:Hide()

	configFrame.name = "SnowfallKeyPress"

	local title = configFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetPoint("RIGHT")
	title:SetText("|cfff58cbaK|r|caaf49141Pack|r - SnowfallKeyPress")
	title:SetJustifyH("LEFT")

	local modifierCombosConfig = {}
	createModifierCombos("", 1, modifiers, modifierCombosConfig)

	local function addAll(_, key)
		if
			key == "UNKNOWN" or
			key == "LSHIFT" or
			key == "RSHIFT" or
			key == "LCTRL" or
			key == "RCTRL" or
			key == "LALT" or
			key == "RALT"
		then
			return
		end

		if key == "LeftButton" then
			key = "BUTTON1"
		elseif key == "RightButton" then
			key = "BUTTON2"
		elseif key == "MiddleButton" then
			key = "BUTTON3"
		else
			key = strgsub(key, "^Button(%d+)$", "BUTTON%1")
		end

		local offset
		for k, modifierCombo in ipairs(modifierCombosConfig) do
			insertKey(modifierCombo .. key)
		end
		scrollBarUpdate()
		updateBindings()
	end

	local function addOne(_, key)
		if
			key == "UNKNOWN" or
			key == "LSHIFT" or
			key == "RSHIFT" or
			key == "LCTRL" or
			key == "RCTRL" or
			key == "LALT" or
			key == "RALT"
		then
			return
		end

		if key == "LeftButton" then
			key = "BUTTON1"
		elseif key == "RightButton" then
			key = "BUTTON2"
		elseif key == "MiddleButton" then
			key = "BUTTON3"
		else
			key = strgsub(key, "^Button(%d+)$", "BUTTON%1")
		end
		if IsShiftKeyDown() then
			key = "SHIFT-" .. key
		end
		if IsControlKeyDown() then
			key = "CTRL-" .. key
		end
		if IsAltKeyDown() then
			key = "ALT-" .. key
		end

		insertKey(key)
		scrollBarUpdate()
		updateBindings()
	end

	local function subAll(_, key)
		if
			key == "UNKNOWN" or
			key == "LSHIFT" or
			key == "RSHIFT" or
			key == "LCTRL" or
			key == "RCTRL" or
			key == "LALT" or
			key == "RALT"
		then
			return
		end

		if key == "LeftButton" then
			key = "BUTTON1"
		elseif key == "RightButton" then
			key = "BUTTON2"
		elseif key == "MiddleButton" then
			key = "BUTTON3"
		else
			key = strgsub(key, "^Button(%d+)$", "BUTTON%1")
		end

		local offset
		for k, modifierCombo in ipairs(modifierCombosConfig) do
			removeKey(modifierCombo .. key)
		end
		scrollBarUpdate()
		updateBindings()
	end

	local function subOne(_, key)
		if
			key == "UNKNOWN" or
			key == "LSHIFT" or
			key == "RSHIFT" or
			key == "LCTRL" or
			key == "RCTRL" or
			key == "LALT" or
			key == "RALT"
		then
			return
		end

		if key == "LeftButton" then
			key = "BUTTON1"
		elseif key == "RightButton" then
			key = "BUTTON2"
		elseif key == "MiddleButton" then
			key = "BUTTON3"
		else
			key = strgsub(key, "^Button(%d+)$", "BUTTON%1")
		end
		if IsShiftKeyDown() then
			key = "SHIFT-" .. key
		end
		if IsControlKeyDown() then
			key = "CTRL-" .. key
		end
		if IsAltKeyDown() then
			key = "ALT-" .. key
		end

		removeKey(key)
		scrollBarUpdate()
		updateBindings()
	end

	local addAllButton = CreateFrame("Button", nil, configFrame, "KPackButtonTemplate")
	addAllButton:SetWidth(130)
	addAllButton:SetHeight(44)
	addAllButton:SetPoint("TOPLEFT", 16, -42)
	addAllButton:SetText("+\n(" .. MODIFIERS_COLON .. " " .. ALL .. ")")
	addAllButton:SetFrameStrata("DIALOG")
	addAllButton:SetScript("OnEnter", function(self) self:EnableKeyboard(true) end)
	addAllButton:SetScript("OnLeave", function(self) self:EnableKeyboard(false) end)
	addAllButton:SetScript("OnKeyDown", addAll)
	addAllButton:SetScript("OnClick", addAll)
	addAllButton:RegisterForClicks("AnyUp")

	local addButton = CreateFrame("Button", nil, configFrame, "KPackButtonTemplate")
	addButton:SetWidth(65)
	addButton:SetHeight(22)
	addButton:SetPoint("TOPLEFT", addAllButton, "BOTTOMLEFT", 0, 0)
	addButton:SetText("+")
	addButton:SetFrameStrata("DIALOG")
	addButton:SetScript("OnEnter", function(self) self:EnableKeyboard(true) end)
	addButton:SetScript("OnLeave", function(self) self:EnableKeyboard(false) end)
	addButton:SetScript("OnKeyDown", addOne)
	addButton:SetScript("OnClick", addOne)
	addButton:RegisterForClicks("AnyUp")

	local subButton = CreateFrame("Button", nil, configFrame, "KPackButtonTemplate")
	subButton:SetWidth(65)
	subButton:SetHeight(22)
	subButton:SetPoint("TOPLEFT", addButton, "TOPRIGHT", 0, 0)
	subButton:SetText("-")
	subButton:SetFrameStrata("DIALOG")
	subButton:SetScript("OnEnter", function(self) self:EnableKeyboard(true) end)
	subButton:SetScript("OnLeave", function(self) self:EnableKeyboard(false) end)
	subButton:SetScript("OnKeyDown", subOne)
	subButton:SetScript("OnClick", subOne)
	subButton:RegisterForClicks("AnyUp")

	local subAllButton = CreateFrame("Button", nil, configFrame, "KPackButtonTemplate")
	subAllButton:SetWidth(130)
	subAllButton:SetHeight(44)
	subAllButton:SetPoint("TOPRIGHT", subButton, "BOTTOMRIGHT", 0, 0)
	subAllButton:SetText("-\n(" .. MODIFIERS_COLON .. " " .. ALL .. ")")
	subAllButton:SetFrameStrata("DIALOG")
	subAllButton:SetScript("OnEnter", function(self) self:EnableKeyboard(true) end)
	subAllButton:SetScript("OnLeave", function(self) self:EnableKeyboard(false) end)
	subAllButton:SetScript("OnKeyDown", subAll)
	subAllButton:SetScript("OnClick", subAll)
	subAllButton:RegisterForClicks("AnyUp")

	local clearAllButton = CreateFrame("Button", nil, configFrame, "KPackButtonTemplate")
	clearAllButton:SetWidth(130)
	clearAllButton:SetHeight(22)
	clearAllButton:SetPoint("TOPLEFT", addAllButton, "TOPRIGHT", 40, 0)
	clearAllButton:SetText(CLEAR_ALL)
	clearAllButton:SetScript("OnClick", function()
		wipe(keysConfig)
		scrollBarUpdate()
		updateBindings()
	end)

	local resetDefaultButton = CreateFrame("Button", nil, configFrame, "KPackButtonTemplate")
	resetDefaultButton:SetWidth(130)
	resetDefaultButton:SetHeight(22)
	resetDefaultButton:SetPoint("TOPRIGHT", clearAllButton, "BOTTOMRIGHT", 0, 0)
	resetDefaultButton:SetText(RESET_TO_DEFAULT)
	resetDefaultButton:SetScript("OnClick", function()
		populateKeysConfig()
		scrollBarUpdate()
		updateBindings()
	end)

	local animationButton = CreateFrame("CheckButton", "SnowfallKeyPress_configFrameAnimationButton", configFrame, "UICheckButtonTemplate")
	animationButton:SetWidth(22)
	animationButton:SetHeight(22)
	animationButton:SetPoint("TOPLEFT", resetDefaultButton, "BOTTOMLEFT", 0, -10)
	_G["SnowfallKeyPress_configFrameAnimationButtonText"]:SetText(ANIMATION)
	animationButton:SetScript("OnClick", function(self) DB.animation = (self:GetChecked() == 1) end)

	local enableButton = CreateFrame("CheckButton", "SnowfallKeyPress_configFrameEnableButton", configFrame, "UICheckButtonTemplate")
	enableButton:SetWidth(22)
	enableButton:SetHeight(22)
	enableButton:SetPoint("TOPLEFT", resetDefaultButton, "BOTTOMLEFT", 0, -40)
	_G["SnowfallKeyPress_configFrameEnableButtonText"]:SetText(ENABLE)
	enableButton:SetScript("OnClick", function(self)
		if self:GetChecked() then
			DB.enable = true
			hook = true
			overrideFrame:RegisterEvent("UPDATE_BINDINGS")
			updateBindings()
		else
			DB.enable = false
			updateBindings()
		end
	end)

	local keyFrame = CreateFrame("Frame", nil, configFrame)
	keyFrame:SetWidth(322)
	keyFrame:SetHeight(16 * 16 + 12)
	keyFrame:SetPoint("TOPLEFT", 16, -155)
	keyFrame:SetBackdrop({
		bgFile = "Interface\\BUTTONS\\WHITE8X8.BLP",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		edgeSize = 16,
		insets = {left = 4, right = 4, top = 4, bottom = 4}
	})
	keyFrame:SetBackdropColor(0, 0, 0, 0)

	local numRows = 16
	configFrame.keyRows = {}
	for i = 1, 16 do
		configFrame.keyRows[i] = configFrame:CreateFontString(nil, "ARTWORK", "NumberFontNormalSmall")
		configFrame.keyRows[i]:SetWidth(314)
		configFrame.keyRows[i]:SetHeight(16)
		configFrame.keyRows[i]:SetPoint("TOPLEFT", 16, -146 - 16 * i)
		configFrame.keyRows[i]:SetJustifyH("RIGHT")
		configFrame.keyRows[i]:SetText(i)
	end
	local scrollBar = CreateFrame("ScrollFrame", "SnowfallKeyPress_configFrameScrollBar", configFrame, "FauxScrollFrameTemplate")
	scrollBar:SetWidth(316)
	scrollBar:SetHeight(16 * 16)
	scrollBar:SetPoint("TOPLEFT", 16, -162)
	scrollBar:SetScript("OnVerticalScroll", function(self, offset) FauxScrollFrame_OnVerticalScroll(self, offset, 16, scrollBarUpdate) end)
	local scrollBarTextureTop = scrollBar:CreateTexture()
	scrollBarTextureTop:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar")
	scrollBarTextureTop:SetWidth(31)
	scrollBarTextureTop:SetHeight(256)
	scrollBarTextureTop:SetPoint("TOPLEFT", scrollBar, "TOPRIGHT", -2, 5)
	scrollBarTextureTop:SetTexCoord(0, 0.484375, 0, 1)

	local scrollBarTextureBottom = scrollBar:CreateTexture()
	scrollBarTextureBottom:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar")
	scrollBarTextureBottom:SetWidth(31)
	scrollBarTextureBottom:SetHeight(106)
	scrollBarTextureBottom:SetPoint("BOTTOMLEFT", scrollBar, "BOTTOMRIGHT", -2, -2)
	scrollBarTextureBottom:SetTexCoord(0.515625, 1, 0, 0.4140625)

	function scrollBarUpdate()
		FauxScrollFrame_Update(scrollBar, #keysConfig, numRows, 16)
		local offset = FauxScrollFrame_GetOffset(scrollBar)
		for i = 1, 16 do
			configFrame.keyRows[i]:SetText(keysConfig[offset + i])
		end
	end

	--------------------------------------------------------------------------------
	-- Clear key binding mode so that the Blizzard key binding UI doesn't look for
	-- overrides and generate bogus messages like:
	-- "CLICK SnowfallKeyPress_Button_1:LeftButton Function is Now Unbound!"

	hooksecurefunc("ShowUIPanel", function()
		if KeyBindingFrame then
			KeyBindingFrame.mode = nil
		end
	end)

	--------------------------------------------------------------------------------
	-- Helper functions

	local function isSecureButton(x)
		return not (not (type(x) == "table" and type(x.IsObjectType) == "function" and issecurevariable(x, "IsObjectType") and x:IsObjectType("Button") and select(2, x:IsProtected())))
	end

	local function animateKey(f)
		if not DB.animation then return end

		local key = f.clickButtonName
		if not key then return end

		local e = _G[key]
		if not e then return end

		local t = false
		for o, n in ipairs(SnowfallKeyPress.animation.handlers) do
			t = ipairs(f) or t
		end
		if not t and SnowfallKeyPress.animation.savedDefaultHandler then
			SnowfallKeyPress.animation.savedDefaultHandler(e)
		end
	end

	-- Accelerate a key, which we must not currently be overriding
	local function accelerateKey(key, command)
		local bindButtonName, bindButton
		local attributeName, attributeValue
		local mouseButton, harmButton, helpButton
		local mouseType, harmType, helpType
		local clickButtonName, clickButton

		for _, template in ipairs(templates) do
			if strmatch(command, template.command) then
				-- make sure there are attributes. Otherwise, this key is blacklisted
				if template.attributes then
					clickButtonName, mouseButton = strmatch(command, "^CLICK (.+):([^:]+)$")
					if clickButtonName then
						-- For clicks, check that the target is a SecureActionButton that isn't doing anything that could possibly rely on differentiating down/up clicks
						clickButton = _G[clickButtonName]
						if not isSecureButton(clickButton) or clickButton:GetAttribute("", "downbutton", mouseButton) then
							return
						end
						harmButton = SecureButton_GetModifiedAttribute(clickButton, "harmbutton", mouseButton)
						helpButton = SecureButton_GetModifiedAttribute(clickButton, "helpbutton", mouseButton)
						mouseType = SecureButton_GetModifiedAttribute(clickButton, "type", mouseButton)
						harmType = SecureButton_GetModifiedAttribute(clickButton, "type", harmButton)
						helpType = SecureButton_GetModifiedAttribute(clickButton, "type", helpButton)
						if
							(mouseType and not allowedTypeAttributes[mouseType]) or
							(harmType and not allowedTypeAttributes[harmType]) or
							(helpType and not allowedTypeAttributes[helpType])
						then
							return
						end
					else
						-- For non-clicks, the default mouse button is LeftButton
						mouseButton = "LeftButton"
					end

					-- make the bind button if it doesn't already exist
					bindButtonName = "SnowfallKeyPress_Button_" .. key
					bindButton = _G[bindButtonName]
					if (not bindButton) then
						bindButton = CreateFrame("Button", "SnowfallKeyPress_Button_" .. key, nil, "SecureActionButtonTemplate")
						bindButton:RegisterForClicks("AnyDown")
						SecureHandlerSetFrameRef(bindButton, "VehicleMenuBar", VehicleMenuBar)
						SecureHandlerSetFrameRef(bindButton, "BonusActionBarFrame", BonusActionBarFrame)
						SecureHandlerSetFrameRef(bindButton, "MultiCastSummonSpellButton", MultiCastSummonSpellButton)
						SecureHandlerExecute(bindButton, [[
							VehicleMenuBar = self:GetFrameRef("VehicleMenuBar");
							BonusActionBarFrame = self:GetFrameRef("BonusActionBarFrame");
							MultiCastSummonSpellButton = self:GetFrameRef("MultiCastSummonSpellButton");
						]])
					end

					-- Clear out any old wrap script that may exist
					SecureHandlerUnwrapScript(bindButton, "OnClick")

					-- apply specified attributes
					for _, attribute in ipairs(template.attributes) do
						attributeName = attribute[1]
						attributeValue = strgsub(command, template.command, attribute[2], 1)

						if attributeName == "clickbutton" then
							-- For "clickbutton" attributes, convert the button name into a button reference
							bindButton:SetAttribute(attributeName, _G[attributeValue])
							bindButton.clickButtonName = attributeValue
							bindButton:SetScript("PostClick", animateKey)
						elseif attributeName == "actionbutton" then
							-- For our custom "actionbutton" attribute, we'll make the decision which button (vehicle/bonus/action) to click similar to how Blizzard does it in ActionButton.lua:ActionButtonUp()
							SecureHandlerWrapScript(bindButton, "OnClick", bindButton, [[
								local clickMacro = "/click ActionButton]] .. attributeValue .. [[";
								if (VehicleMenuBar:IsProtected() and VehicleMenuBar:IsShown() and ]] .. tostring(tonumber(attributeValue) <= VEHICLE_MAX_ACTIONBUTTONS) .. [[) then
									clickMacro = "/click VehicleMenuBarActionButton]] .. attributeValue .. [[";
								elseif (BonusActionBarFrame:IsProtected() and BonusActionBarFrame:IsShown()) then
									clickMacro = "/click BonusActionButton]] .. attributeValue .. [[";
								end
								self:SetAttribute("macrotext", clickMacro);
							]])
							bindButton:SetScript("PostClick", function(self)
								bindButton.clickButtonName = strsub(bindButton:GetAttribute("macrotext"), 8)
								animateKey(bindButton)
							end)
						elseif attributeName == "multicastsummon" then
							-- For our custom "multicastsummon" attribute, before the click, we'll set the button ID based upon the binding
							SecureHandlerWrapScript(bindButton, "OnClick", bindButton, [[
								lastID = MultiCastSummonSpellButton:GetID();
								MultiCastSummonSpellButton:SetID(]] .. attributeValue .. [[);
							]], [[MultiCastSummonSpellButton:SetID(lastID);]])
							bindButton:SetAttribute("clickbutton", MultiCastSummonSpellButton)
						else
							bindButton:SetAttribute(attributeName, attributeValue)
						end
					end

					-- create a priority override
					hook = false
					SetOverrideBindingClick(overrideFrame, true, key, bindButtonName, mouseButton)
					hook = true
				end

				-- stop since we found a matching template
				return
			end
		end
	end

	--------------------------------------------------------------------------------
	-- UPDATE_BINDINGS
	-- Find all keys. Accelerate them.

	function updateBindings()
		if InCombatLockdown() then return end
		SetupDatabase()

		-- Remove all of our overrides so we can see other overrides
		hook = false
		ClearOverrideBindings(overrideFrame)
		hook = true

		if not DB.enable then
			overrideFrame:UnregisterEvent("UPDATE_BINDINGS")
			hook = false
			return
		end

		-- Find all bound keys and accelerate them
		local command
		for _, key in ipairs(keysConfig) do
			command = GetBindingAction(key, true)
			if command then
				accelerateKey(key, command)
			end
		end
	end

	--------------------------------------------------------------------------------
	-- SetOverrideBinding*
	-- Make sure this key is one we are supposed to accelerate. Remove our override. See what the key is bound to, now. Apply a new override.

	local function setOverrideBindingHook(_, _, overrideKey)
		if not hook or InCombatLockdown() then return end

		local command
		for _, key in ipairs(keysConfig) do
			if overrideKey == key then
				hook = false
				SetOverrideBinding(overrideFrame, false, overrideKey, nil)
				hook = true
				command = GetBindingAction(overrideKey, true)
				if command then
					accelerateKey(overrideKey, command)
				end
				break
			end
		end
	end
	hooksecurefunc("SetOverrideBinding", setOverrideBindingHook)
	hooksecurefunc("SetOverrideBindingSpell", setOverrideBindingHook)
	hooksecurefunc("SetOverrideBindingClick", setOverrideBindingHook)
	hooksecurefunc("SetOverrideBindingItem", setOverrideBindingHook)
	hooksecurefunc("SetOverrideBindingMacro", setOverrideBindingHook)

	--------------------------------------------------------------------------------
	-- ClearOverrideBindings
	-- Remove all our overrides. Re-apply overrides for all key bindings (to potentially new commands).

	local function clearOverrideBindingsHook()
		if not hook then return end
		updateBindings()
	end
	hooksecurefunc("ClearOverrideBindings", clearOverrideBindingsHook)

	--------------------------------------------------------------------------------
	-- ADDON_LOADED

	function SetupDatabase()
		if not DB then
			if type(core.db.SnowfallKeyPress) ~= "table" or not next(core.db.SnowfallKeyPress) then
				core.db.SnowfallKeyPress = {keys = {}, enable = true, animation = true}
			end
			-- fix animation
			if core.db.SnowfallKeyPress.animation == nil then
				core.db.SnowfallKeyPress.animation = true
			end
			DB = core.db.SnowfallKeyPress
			keysConfig = DB.keys
		end
	end

	core:RegisterForEvent("PLAYER_LOGIN", function()
		SetupDatabase()
		animationButton:SetChecked(DB.animation)
		enableButton:SetChecked(DB.enable)

		if #keysConfig == 0 then
			populateKeysConfig()
		end

		scrollBarUpdate()

		InterfaceOptions_AddCategory(configFrame)

		overrideFrame:UnregisterAllEvents()
		overrideFrame:SetScript("OnEvent", updateBindings)
		overrideFrame:RegisterEvent("UPDATE_BINDINGS")
		updateBindings()
	end)
end)