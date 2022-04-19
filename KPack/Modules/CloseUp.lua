local core = KPack
if not core or core.Ascension then return end
core:AddModule("CloseUp", "Allows you to zoom, reposition, and rotate the UI's builtin models so that you may get a better view.", function(L, folder)
	if core:IsDisabled("CloseUp") or core.ElvUI then return end

	local mod = core.CloseUp or {}
	core.CloseUp = mod

	local DB

	-- cache frequetly used globals
	local GetCursorPosition = GetCursorPosition
	local UnitExists, UnitIsVisible, UnitIsPlayer = UnitExists, UnitIsVisible, UnitIsPlayer

	-- plays a dummy function that does nothing.
	local function noFunc()
	end

	-- module's print function.
	function mod:Print(msg)
		if msg then
			core:Print(msg, "CloseUp")
		end
	end

	local function SetupDatabase()
		if not DB then
			if core.db.CloseUp == nil then
				core.db.CloseUp = true
			end
			DB = core.db.CloseUp
		end
	end

	-- allow player to remove the dressing room background
	-- by holdinh down ctrl button and click.
	local function CloseUp_ToggleBG(noSave)
		if not noSave then
			DB = not DB
		end
		local f = (DB and DressUpBackgroundTopLeft.Hide) or DressUpBackgroundTopLeft.Show
		f(DressUpBackgroundTopLeft)
		f(DressUpBackgroundTopRight)
		f(DressUpBackgroundBotLeft)
		f(DressUpBackgroundBotRight)
		if AuctionDressUpBackgroundTop then
			f(AuctionDressUpBackgroundTop)
			f(AuctionDressUpBackgroundBot)
		end
	end

	do
		-- handles the frame's OnUpdate event.
		local function Model_OnUpdate(self, elapsed)
			if not self then return end
			local currX, currY = GetCursorPosition()
			if self.rotating then
				self:SetFacing(self:GetFacing() + ((currX - self.prevX) / 50))
			elseif self.posing then
				local cz, cx, cy = self:GetPosition()
				self:SetPosition(cz, cx + ((currX - self.prevX) / 50), cy + ((currY - self.prevY) / 50))
			end
			self.prevX, self.prevY = currX, currY
		end

		-- handles the frame's OnMouseDown event
		local function Model_OnMouseDown(self, button)
			if not self then return end
			if self.pMouseDown then self.pMouseDown(button) end
			self:SetScript("OnUpdate", Model_OnUpdate)
			if button == "LeftButton" then
				self.rotating = 1
				if IsControlKeyDown() then
					CloseUp_ToggleBG()
				end
			elseif button == "RightButton" then
				self.posing = 1
			end
			self.prevX, self.prevY = GetCursorPosition()
		end

		-- handles the frame's OnMouseUp event
		local function Model_OnMouseUp(self, button)
			if not self then return end
			if self.pMouseUp then self.pMouseUp(button) end
			self:SetScript("OnUpdate", nil)
			if button == "LeftButton" then
				self.rotating = nil
			elseif button == "RightButton" then
				self.posing = nil
			end
		end

		-- handles the frame's OnMouseWheel event
		local function Model_OnMouseWheel(self, arg)
			if not self then return end
			local cz, cx, cy = this:GetPosition()
			self:SetPosition(cz + ((arg > 0 and 0.6) or -0.6), cx, cy)
		end

		-- the main function that applies all modifications to frames.
		-- we added it to the module namespace so that the player can
		-- use it to apply it to his/her model.
		function mod:Apply(model, w, h, x, y, sigh, noRotate)
			local gmodel = _G[model]
			if not gmodel then return end

			if not noRotate then
				model = sigh or model
				_G[model .. "RotateRightButton"]:Hide()
				_G[model .. "RotateLeftButton"]:Hide()
			end

			if w then
				gmodel:SetWidth(w)
			end
			if h then
				gmodel:SetHeight(h)
			end

			if x or y then
				local p, rt, rp, px, py = gmodel:GetPoint()
				gmodel:SetPoint(p, rt, rp, x or px, y or py)
			end

			gmodel:SetModelScale(2)
			gmodel:EnableMouse(true)
			gmodel:EnableMouseWheel(true)

			gmodel.pMouseDown = gmodel:GetScript("OnMouseDown") or noFunc
			gmodel.pMouseUp = gmodel:GetScript("OnMouseUp") or noFunc

			gmodel:SetScript("OnMouseDown", Model_OnMouseDown)
			gmodel:SetScript("OnMouseUp", Model_OnMouseUp)
			gmodel:SetScript("OnMouseWheel", Model_OnMouseWheel)
		end
	end

	local CloseUp_NewButton
	do
		local tooltip = GameTooltip

		-- shows the help tooltip for buttons.
		local function CloseUp_ShowTooltip(self)
			tooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
			tooltip:SetText(self.tt)
			if _G.CloseUpNPCModel and _G.CloseUpNPCModel:IsVisible() and self.tt == L["Undress"] then
				tooltip:AddLine(L["Cannot dress NPC models."], 1, 1, 1, 1)
			end
			tooltip:Show()
		end

		-- simply hides the tooltip.
		local function CloseUp_HideTooltip()
			tooltip:Hide()
		end

		-- this function allows us to create buttons.
		function CloseUp_NewButton(name, parent, text, w, h, button, tt, func)
			local b = button or CreateFrame("Button", name, parent, "KPackButtonTemplate")
			b:SetText(text or b:GetText())
			b:SetWidth(w or b:GetWidth())
			b:SetHeight(h or b:GetHeight())
			b:SetScript("OnClick", func)
			if tt then
				b.tt = tt
				b:SetScript("OnEnter", CloseUp_ShowTooltip)
				b:SetScript("OnLeave", CloseUp_HideTooltip)
			end
			return b
		end
	end

	-- applies our CloseUp modifications to the auction
	-- house dressing room.
	local function CloseUp_AuctionUI()
		mod:Apply("AuctionDressUpModel", nil, 370, 0, 10)
		local tb, du = AuctionDressUpFrameResetButton, AuctionDressUpModel
		local w, h = 20, tb:GetHeight()

		CloseUp_NewButton(nil, nil, "T", w, h, tb, TARGET, function()
			if UnitExists("target") and UnitIsVisible("target") then
				du:SetUnit("target")
			end
		end)

		local a, b, c, d, e = tb:GetPoint()
		tb:SetPoint(a, b, c, d, e - 30)

		CloseUp_NewButton("CloseUpAHResetButton", du, "R", 20, 22, nil, RESET, function() du:Dress() end):SetPoint("RIGHT", tb, "LEFT", 0, 0)
		CloseUp_NewButton("CloseUpAHUndressButton", du, "U", 20, 22, nil, L["Undress"], function() du:Undress() end):SetPoint("LEFT", tb, "RIGHT", 0, 0)
		CloseUp_ToggleBG(true)
	end

	-- applies our modifications to the inspect frame.
	local function CloseUp_InspectUI()
		mod:Apply("InspectModelFrame", nil, nil, nil, nil, "InspectModel")
	end

	-- changes the default dressing room and applies our modifications.
	local function CloseUp_DressingRoom()
		mod:Apply("DressUpModel", nil, 332, nil, 104)

		local tb = DressUpFrameCancelButton
		local w, h = 40, tb:GetHeight()
		local m = DressUpModel

		local tm = CreateFrame("PlayerModel", "CloseUpNPCModel", DressUpFrame)
		tm:SetAllPoints(DressUpModel)
		tm:Hide()
		mod:Apply("CloseUpNPCModel", nil, nil, nil, nil, nil, true)
		DressUpFrame:HookScript("OnShow", function()
			tm:Hide()
			m:Show()
			CloseUp_ToggleBG(true)
		end)

		-- convert default close button into set target button
		CloseUp_NewButton(nil, nil, "T", w, h, tb, STATUS_TEXT_TARGET, function()
			if UnitExists("target") and UnitIsVisible("target") then
				if UnitIsPlayer("target") then
					tm:Hide()
					m:Show()
					m:SetUnit("target")
				else
					tm:Show()
					m:Hide()
					tm:SetUnit("target")
				end
				SetPortraitTexture(DressUpFramePortrait, "target")
			end
		end)

		local a, b, c, d, e = tb:GetPoint()
		tb:SetPoint(a, b, c, d - (w / 2), e)
		CloseUp_NewButton("CloseUpUndressButton", DressUpFrame, "U", w, h, nil, L["Undress"], function() m:Undress() end):SetPoint("LEFT", tb, "RIGHT", -2, 0)
	end

	-- adds buttons to quickly show/hide helm and cloak
	local function CloseUp_Quickie()
		if not PaperDollFrame then return end
		local btn

		-- helm
		if not PaperDollFrame.helm then
			btn = CreateFrame("Button", nil, PaperDollFrame)
			btn:SetToplevel(true)
			btn:SetSize(32, 32)
			btn:SetPoint("LEFT", CharacterHeadSlot, "RIGHT", 9, 0)
			btn:SetScript("OnClick", function() ShowHelm(not ShowingHelm()) end)
			btn:SetNormalTexture("Interface\\AddOns\\KPack\\Media\\Textures\\textureHead")
			btn:SetPushedTexture("Interface\\AddOns\\KPack\\Media\\Textures\\textureHead")
			btn:SetHighlightTexture("Interface\\AddOns\\KPack\\Media\\Textures\\textureHighlight")
			PaperDollFrame.helm = btn
		end

		-- cloak
		if not PaperDollFrame.cloak then
			btn = CreateFrame("Button", nil, PaperDollFrame)
			btn:SetToplevel(true)
			btn:SetSize(32, 32)
			btn:SetPoint("LEFT", CharacterBackSlot, "RIGHT", 9, 0)
			btn:SetScript("OnClick", function() ShowCloak(not ShowingCloak()) end)
			btn:SetNormalTexture("Interface\\AddOns\\KPack\\Media\\Textures\\textureCloak")
			btn:SetPushedTexture("Interface\\AddOns\\KPack\\Media\\Textures\\textureCloak")
			btn:SetHighlightTexture("Interface\\AddOns\\KPack\\Media\\Textures\\textureHighlight")
			PaperDollFrame.cloak = btn
		end
	end

	core:RegisterForEvent("ADDON_LOADED", function(_, name)
		if name == folder then
			SetupDatabase()
		elseif name == "Blizzard_AuctionUI" then
			CloseUp_AuctionUI()
		elseif name == "Blizzard_InspectUI" then
			CloseUp_InspectUI()
		end
	end)

	core:RegisterForEvent("PLAYER_LOGIN", function()
		SetupDatabase()
		mod:Apply("CharacterModelFrame")
		mod:Apply("TabardModel", nil, nil, nil, nil, "TabardCharacterModel")
		mod:Apply("PetModelFrame")
		mod:Apply("PetStableModel")
		PetPaperDollPetInfo:SetFrameStrata("HIGH")
		if CompanionModelFrame then
			mod:Apply("CompanionModelFrame")
		end

		if AuctionDressUpModel then
			CloseUp_AuctionUI()
		end
		if InspectModelFrame then
			CloseUp_InspectUI()
		end
		CloseUp_DressingRoom()
		CloseUp_Quickie()
	end)
end)