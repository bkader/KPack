local core = KPack
if not core then return end
core:AddModule("Postal", function(L)
	if core:IsDisabled("Postal") then return end

	local Postal = {}
	Postal.modules = {}
	core.Postal = Postal

	LibStub("AceEvent-3.0"):Embed(Postal)
	LibStub("AceHook-3.0"):Embed(Postal)

	local strmatch = string.match
	local strgsub = string.gsub
	local format = string.format
	local strtrim = string.trim
	local tonumber = tonumber
	local pairs, ipairs = pairs, ipairs
	local type, select = type, select
	local tinsert, tremove, tsort = table.insert, table.remove, table.sort
	local CreateFrame = CreateFrame

	local defaults = {
		EnabledModules = {
			BlackBook = true,
			DoNotWant = true,
			Express = true,
			OpenAll = true,
			Rake = true,
			Select = true,
			TradeBlock = true
		},
		OpenSpeed = 0.50,
		Select = {
			SpamChat = true,
			KeepFreeSpace = 1
		},
		OpenAll = {
			AHCancelled = true,
			AHExpired = true,
			AHOutbid = true,
			AHSuccess = true,
			AHWon = true,
			NeutralAHCancelled = true,
			NeutralAHExpired = true,
			NeutralAHOutbid = true,
			NeutralAHSuccess = true,
			NeutralAHWon = true,
			Attachments = true,
			SpamChat = true,
			KeepFreeSpace = 1
		},
		Express = {
			EnableAltClick = true,
			AutoSend = true,
			MouseWheel = true,
			MultiItemTooltip = true
		}
	}

	local defaultsChar = {
		BlackBook = {
			AutoFill = true,
			contacts = {},
			recent = {},
			alts = {},
			AutoCompleteAlts = true,
			AutoCompleteRecent = true,
			AutoCompleteContacts = true,
			AutoCompleteFriends = true,
			AutoCompleteGuild = true,
			ExcludeRandoms = true,
			DisableBlizzardAutoComplete = false,
			UseAutoComplete = true
		}
	}

	---------------------------------------------------------------------------
	-- Core

	do
		local t = {}
		Postal.keepFreeOptions = {0, 1, 2, 3, 5, 10, 15, 20, 25, 30}

		local KPostal_DropDownMenu = CreateFrame("Frame", "KPostal_DropDownMenu")
		_G.KPostal_DropDownMenu.displayMode = "MENU"
		_G.KPostal_DropDownMenu.info = {}
		_G.KPostal_DropDownMenu.levelAdjust = 0
		_G.KPostal_DropDownMenu.UncheckHack = function(dropdownbutton)
			_G[dropdownbutton:GetName() .. "Check"]:Hide()
		end
		_G.KPostal_DropDownMenu.HideMenu = function()
			if UIDROPDOWNMENU_OPEN_MENU == KPostal_DropDownMenu then
				CloseDropDownMenus()
			end
		end

		local function subjectHoverIn(self)
			local s = _G["MailItem" .. self:GetID() .. "Subject"]
			if s:GetStringWidth() + 25 > s:GetWidth() then
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetText(s:GetText())
				GameTooltip:Show()
			end
		end

		local function subjectHoverOut(self)
			GameTooltip:Hide()
		end

		function Postal:IterateModules()
			return pairs(self.modules)
		end

		function Postal:MAIL_SHOW()
			for name, mod in Postal:IterateModules() do
				if self.db.EnabledModules[name] and mod.MAIL_SHOW then
					mod:MAIL_SHOW()
				end
			end
		end

		function Postal:MAIL_CLOSED()
			for i = 1, GetInboxNumItems() do
				if not select(9, GetInboxHeaderInfo(i)) then
					return
				end
			end
			MiniMapMailFrame:Hide()
			for name, mod in Postal:IterateModules() do
				if self.db.EnabledModules[name] and mod.MAIL_CLOSED then
					mod:MAIL_CLOSED()
				end
			end
		end

		function Postal:PLAYER_LEAVING_WORLD()
			for name, mod in Postal:IterateModules() do
				if self.db.EnabledModules[name] and mod.PLAYER_LEAVING_WORLD then
					mod:PLAYER_LEAVING_WORLD()
				end
			end
		end

		function Postal.Menu(self, level)
			if not level then return end
			local info = self.info
			if level == 1 then
				wipe(info)
				info.isTitle = 1
				info.text = "Postal"
				info.notCheckable = 1
				UIDropDownMenu_AddButton(info, level)

				info.keepShownOnClick = 1
				for name, mod in Postal:IterateModules() do
					wipe(info)
					info.text = L[name]
					info.func = Postal.ToggleModule
					info.arg1 = name
					info.arg2 = mod
					info.checked = (Postal.db.EnabledModules[name] == true)
					info.hasArrow = mod.ModuleMenu ~= nil
					info.value = mod
					UIDropDownMenu_AddButton(info, level)
				end

				wipe(info)
				info.disabled = 1
				UIDropDownMenu_AddButton(info, level)

				wipe(info)
				info.text = L["Opening Speed"]
				info.func = self.UncheckHack
				info.notCheckable = 1
				info.keepShownOnClick = 1
				info.hasArrow = 1
				info.value = "OpenSpeed"
				UIDropDownMenu_AddButton(info, level)

				wipe(info)
				info.disabled = 1
				UIDropDownMenu_AddButton(info, level)

				wipe(info)
				info.text = CLOSE
				info.func = self.HideMenu
				info.tooltipTitle = CLOSE
				info.notCheckable = 1
				UIDropDownMenu_AddButton(info, level)
			elseif level == 2 then
				if UIDROPDOWNMENU_MENU_VALUE == "OpenSpeed" then
					local speed = Postal.db.OpenSpeed
					for i = 0, 13 do
						wipe(info)
						local s = 0.3 + i * 0.05
						info.text = format("%0.2f", s)
						info.func = Postal.SetOpenSpeed
						info.checked = s == speed
						info.arg1 = s
						UIDropDownMenu_AddButton(info, level)
					end
					for i = 0, 8 do
						wipe(info)
						local s = 1 + i * 0.5
						info.text = format("%0.2f", s)
						info.func = Postal.SetOpenSpeed
						info.checked = s == speed
						info.arg1 = s
						UIDropDownMenu_AddButton(info, level)
					end
				elseif type(UIDROPDOWNMENU_MENU_VALUE) == "table" and UIDROPDOWNMENU_MENU_VALUE.ModuleMenu then
					self.levelAdjust = 1
					UIDROPDOWNMENU_MENU_VALUE.ModuleMenu(self, level)
					self.levelAdjust = 0
					self.module = UIDROPDOWNMENU_MENU_VALUE
				end
			elseif level == 3 then
				if self.module and self.module.ModuleMenu then
					self.levelAdjust = 1
					self.module.ModuleMenu(self, level)
					self.levelAdjust = 0
				end
			elseif level > 3 then
				if self.module and self.module.ModuleMenu then
					self.levelAdjust = 1
					self.module.ModuleMenu(self, level)
					self.levelAdjust = 0
				end
			end
		end

		---------------------------
		-- Common Mail Functions --
		---------------------------

		-- Disable Inbox Clicks
		function Postal:DisableInbox(disable)
			if disable then
				if not self:IsHooked("InboxFrame_OnClick") then
					self:RawHook("InboxFrame_OnClick", core.Noop, true)
					for i = 1, 7 do
						_G["MailItem" .. i .. "ButtonIcon"]:SetDesaturated(1)
					end
				end
			else
				if self:IsHooked("InboxFrame_OnClick") then
					self:Unhook("InboxFrame_OnClick")
					for i = 1, 7 do
						_G["MailItem" .. i .. "ButtonIcon"]:SetDesaturated(nil)
					end
				end
			end
		end

		-- Return the type of mail a message subject is
		local SubjectPatterns = {
			AHCancelled = gsub(AUCTION_REMOVED_MAIL_SUBJECT, "%%s", ".*"),
			AHExpired = gsub(AUCTION_EXPIRED_MAIL_SUBJECT, "%%s", ".*"),
			AHOutbid = gsub(AUCTION_OUTBID_MAIL_SUBJECT, "%%s", ".*"),
			AHSuccess = gsub(AUCTION_SOLD_MAIL_SUBJECT, "%%s", ".*"),
			AHWon = gsub(AUCTION_WON_MAIL_SUBJECT, "%%s", ".*")
		}
		function Postal:GetMailType(msgSubject)
			if msgSubject then
				for k, v in pairs(SubjectPatterns) do
					if msgSubject:find(v) then
						return k
					end
				end
			end
			return "NonAHMail"
		end

		function Postal:GetMoneyString(money)
			local gold = floor(money / 10000)
			local silver = floor((money - gold * 10000) / 100)
			local copper = mod(money, 100)
			if gold > 0 then
				return format(GOLD_AMOUNT_TEXTURE .. " " .. SILVER_AMOUNT_TEXTURE .. " " .. COPPER_AMOUNT_TEXTURE, gold, 0, 0, silver, 0, 0, copper, 0, 0)
			elseif silver > 0 then
				return format(SILVER_AMOUNT_TEXTURE .. " " .. COPPER_AMOUNT_TEXTURE, silver, 0, 0, copper, 0, 0)
			else
				return format(COPPER_AMOUNT_TEXTURE, copper, 0, 0)
			end
		end

		function Postal:CountItemsAndMoney()
			local numAttach = 0
			local numGold = 0
			for i = 1, GetInboxNumItems() do
				local msgMoney, _, _, msgItem = select(5, GetInboxHeaderInfo(i))
				numAttach = numAttach + (msgItem or 0)
				numGold = numGold + msgMoney
			end
			return numAttach, numGold
		end

		function Postal:Print(msg)
			if msg then
				core:Print(msg, "Postal")
			end
		end

		function Postal.SaveOption(_, arg1, arg2, checked)
			if arg1 == "BlackBook" then
				Postal.char.BlackBook[arg2] = checked
			else
				Postal.db[arg1][arg2] = checked
			end
		end

		function Postal.ToggleModule(_, arg1, arg2, checked)
			if Postal.db.EnabledModules[arg1] then
				Postal.db.EnabledModules[arg1] = false
				if arg2 and arg2.OnDisable then
					arg2:OnDisable()
				end
			else
				Postal.db.EnabledModules[arg1] = true
				if arg2 and arg2.OnEnable then
					arg2:OnEnable()
				end
			end
		end

		function Postal.SetOpenSpeed(_, arg1, arg2, checked)
			Postal.db.OpenSpeed = arg1
		end

		function Postal:SetupDatabase()
			if not self.db then
				if type(core.db.Postal) ~= "table" then
					core.db.Postal = CopyTable(defaults)
				end
				if type(core.char.Postal) ~= "table" then
					core.char.Postal = CopyTable(defaultsChar)
				end

				self.db = core.db.Postal
				self.char = core.char.Postal

				-- restore old data
				if self.db.BlackBook then
					self.char.BlackBook = CopyTable(self.db.BlackBook)
					self.db.BlackBook = nil
				end
			end
		end

		core:RegisterForEvent("PLAYER_LOGIN", function()
			if _G.Postal then return end
			Postal:SetupDatabase()

			-- in case someone updated from an older version
			if Postal.db.EnabledModules == nil then
				Postal.db.EnabledModules = defaults.EnabledModules
			end

			for name, mod in Postal:IterateModules() do
				if Postal.db.EnabledModules[name] and mod.OnEnable then
					mod:OnEnable()
				end
			end
			Postal:RegisterEvent("MAIL_SHOW")
			Postal:RegisterEvent("MAIL_CLOSED")
			Postal:RegisterEvent("PLAYER_LEAVING_WORLD")

			-- Create the Menu Button
			local KPostal_ModuleMenuButton = CreateFrame("Button", "KPostal_ModuleMenuButton", MailFrame)
			KPostal_ModuleMenuButton:SetWidth(25)
			KPostal_ModuleMenuButton:SetHeight(25)
			KPostal_ModuleMenuButton:SetPoint("TOPRIGHT", -58, -12)
			KPostal_ModuleMenuButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
			KPostal_ModuleMenuButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Round")
			KPostal_ModuleMenuButton:SetDisabledTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Disabled")
			KPostal_ModuleMenuButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
			KPostal_ModuleMenuButton:SetScript("OnClick", function(self, button, down)
				if _G.KPostal_DropDownMenu.initialize ~= Postal.Menu then
					CloseDropDownMenus()
					_G.KPostal_DropDownMenu.initialize = Postal.Menu
				end
				ToggleDropDownMenu(1, nil, KPostal_DropDownMenu, self:GetName(), 0, 0)
			end)
			KPostal_ModuleMenuButton:SetScript("OnHide", _G.KPostal_DropDownMenu.HideMenu)
		end)
	end

	---------------------------------------------------------------------------
	-- Express Module

	do
		local Postal_Express = {}
		LibStub("AceHook-3.0"):Embed(Postal_Express)

		function Postal_Express:MAIL_SHOW()
			if Postal.db.Express.EnableAltClick and not self:IsHooked(GameTooltip, "OnTooltipSetItem") then
				self:HookScript(GameTooltip, "OnTooltipSetItem")
				self:RawHook("ContainerFrameItemButton_OnModifiedClick", true)
			end
		end

		function Postal_Express:MAIL_CLOSED(event)
			if self:IsHooked(GameTooltip, "OnTooltipSetItem") then
				self:Unhook(GameTooltip, "OnTooltipSetItem")
				self:Unhook("ContainerFrameItemButton_OnModifiedClick")
			end
		end
		Postal_Express.PLAYER_LEAVING_WORLD = Postal_Express.MAIL_CLOSED

		function Postal_Express:OnEnable()
			if not self:IsHooked("InboxFrame_OnClick") then
				self:RawHook("InboxFrame_OnClick", true)
				self:RawHook("InboxFrame_OnModifiedClick", "InboxFrame_OnClick", true)
				self:RawHook("InboxFrameItem_OnEnter", true)
			end

			if Postal.db.Express.MouseWheel then
				MailFrame:EnableMouseWheel(true)
				if not self:IsHooked(MailFrame, "OnMouseWheel") then
					self:HookScript(MailFrame, "OnMouseWheel")
				end
			end
		end

		function Postal_Express:OnDisable()
			if self:IsHooked("InboxFrame_OnClick") then
				self:Unhook("InboxFrame_OnClick")
				self:Unhook("InboxFrame_OnModifiedClick", "InboxFrame_OnClick")
				self:Unhook("InboxFrameItem_OnEnter")
			end
			MailFrame:EnableMouseWheel(false)
			if self:IsHooked(MailFrame, "OnMouseWheel") then
				self:Unhook(MailFrame, "OnMouseWheel")
			end
		end

		function Postal_Express:InboxFrameItem_OnEnter(this, motion)
			self.hooks["InboxFrameItem_OnEnter"](this, motion)
			local tooltip = GameTooltip

			local money, COD, _, hasItem, _, wasReturned, _, canReply = select(5, GetInboxHeaderInfo(this.index))
			if Postal.db.Express.MultiItemTooltip and hasItem and hasItem > 1 then
				for i = 1, ATTACHMENTS_MAX_RECEIVE do
					local name, itemTexture, count, quality, canUse = GetInboxItem(this.index, i)
					if name then
						local itemLink = GetInboxItemLink(this.index, i)
						if count > 1 then
							tooltip:AddLine(("%sx%d"):format(itemLink, count))
						else
							tooltip:AddLine(itemLink)
						end
						tooltip:AddTexture(itemTexture)
					end
				end
			end
			if (money > 0 or hasItem) and (not COD or COD == 0) then
				tooltip:AddLine(L["|cffeda55fShift-Click|r to take the contents."])
			end
			if not wasReturned and canReply then
				tooltip:AddLine(L["|cffeda55fCtrl-Click|r to return it to sender."])
			end
			tooltip:Show()
		end

		function Postal_Express:InboxFrame_OnClick(button, index)
			if IsShiftKeyDown() then
				local cod = select(6, GetInboxHeaderInfo(index))
				if cod <= 0 then
					AutoLootMailItem(index)
				end
			elseif IsControlKeyDown() then
				local wasReturned, _, canReply = select(10, GetInboxHeaderInfo(index))
				if not wasReturned and canReply then
					ReturnInboxItem(index)
				end
			else
				return self.hooks["InboxFrame_OnClick"](button, index)
			end
		end

		function Postal_Express:OnTooltipSetItem(tooltip, ...)
			local recipient = SendMailNameEditBox:GetText()
			if Postal.db.Express.AutoSend and recipient ~= "" and SendMailFrame:IsVisible() and not CursorHasItem() then
				tooltip:AddLine(L:F("|cffeda55fAlt-Click|r to send this item to %s.", recipient))
			end
		end

		function Postal_Express:ContainerFrameItemButton_OnModifiedClick(this, button, ...)
			if button == "LeftButton" and IsAltKeyDown() and SendMailFrame:IsVisible() and not CursorHasItem() then
				local bag, slot = this:GetParent():GetID(), this:GetID()
				local texture, count = GetContainerItemInfo(bag, slot)
				PickupContainerItem(bag, slot)
				ClickSendMailItemButton()
				if Postal.db.Express.AutoSend then
					for i = 1, ATTACHMENTS_MAX_SEND do
						-- get info about the attachment
						local itemName, itemTexture, stackCount, quality = GetSendMailItem(i)
						if SendMailNameEditBox:GetText() ~= "" and texture == itemTexture and count == stackCount then
							SendMailFrame_SendMail()
						end
					end
				end
			else
				return self.hooks["ContainerFrameItemButton_OnModifiedClick"](this, button, ...)
			end
		end

		function Postal_Express:OnMouseWheel(frame, direction)
			if direction == -1 then
				if math.ceil(GetInboxNumItems() / 7) > InboxFrame.pageNum then
					InboxNextPage()
				end
			elseif InboxFrame.pageNum ~= 1 then
				InboxPrevPage()
			end
		end

		function Postal_Express.SetEnableAltClick(dropdownbutton, arg1, arg2, checked)
			local self = Postal_Express
			Postal.db.Express.EnableAltClick = checked
			if checked then
				if MailFrame:IsVisible() and not self:IsHooked(GameTooltip, "OnTooltipSetItem") then
					self:HookScript(GameTooltip, "OnTooltipSetItem")
					self:RawHook("ContainerFrameItemButton_OnModifiedClick", true)
				end
			else
				if self:IsHooked(GameTooltip, "OnTooltipSetItem") then
					self:Unhook(GameTooltip, "OnTooltipSetItem")
					self:Unhook("ContainerFrameItemButton_OnModifiedClick")
				end
			end
			-- A hack to get the next button to disable/enable
			local i, j = strmatch(dropdownbutton:GetName(), "DropDownList(%d+)Button(%d+)")
			j = tonumber(j) + 1
			if checked then
				_G["DropDownList" .. i .. "Button" .. j]:Enable()
				_G["DropDownList" .. i .. "Button" .. j .. "InvisibleButton"]:Hide()
			else
				_G["DropDownList" .. i .. "Button" .. j]:Disable()
				_G["DropDownList" .. i .. "Button" .. j .. "InvisibleButton"]:Show()
			end
		end

		function Postal_Express.SetAutoSend(dropdownbutton, arg1, arg2, checked)
			Postal.db.Express.AutoSend = checked
		end

		function Postal_Express.SetMouseWheel(dropdownbutton, arg1, arg2, checked)
			local self = Postal_Express
			Postal.db.Express.MouseWheel = checked
			if checked then
				if not self:IsHooked(MailFrame, "OnMouseWheel") then
					MailFrame:EnableMouseWheel(true)
					self:HookScript(MailFrame, "OnMouseWheel")
				end
			else
				if self:IsHooked(MailFrame, "OnMouseWheel") then
					self:Unhook(MailFrame, "OnMouseWheel")
				end
			end
		end

		function Postal_Express.ModuleMenu(self, level)
			if not level then return end
			local info = self.info
			wipe(info)
			if level == 1 + self.levelAdjust then
				local db = Postal.db.Express
				info.keepShownOnClick = 1

				info.text = L["Enable Alt-Click to send mail"]
				info.func = Postal_Express.SetEnableAltClick
				info.checked = db.EnableAltClick
				UIDropDownMenu_AddButton(info, level)

				info.text = L["Auto-Send on Alt-Click"]
				info.func = Postal_Express.SetAutoSend
				info.checked = db.AutoSend
				info.disabled = not Postal.db.Express.EnableAltClick
				UIDropDownMenu_AddButton(info, level)

				info.text = L["Mousewheel to scroll Inbox"]
				info.func = Postal_Express.SetMouseWheel
				info.checked = db.MouseWheel
				info.disabled = nil
				UIDropDownMenu_AddButton(info, level)

				info.text = L["Add multiple item mail tooltips"]
				info.func = Postal.SaveOption
				info.checked = db.MultiItemTooltip
				info.arg1 = "Express"
				info.arg2 = "MultiItemTooltip"
				info.disabled = nil
				UIDropDownMenu_AddButton(info, level)
			end
		end

		Postal.modules.Express = Postal_Express
	end

	---------------------------------------------------------------------------
	-- OpenAll

	do
		local Postal_OpenAll = {}
		LibStub("AceHook-3.0"):Embed(Postal_OpenAll)

		local mailIndex, attachIndex
		local lastItem, lastNumAttach, lastNumGold
		local wait
		local button
		local KPostal_OpenAllMenuButton
		local skipFlag
		local invFull
		local openAllOverride

		local updateFrame = CreateFrame("Frame")
		updateFrame:Hide()
		updateFrame:SetScript("OnShow", function(self) self.time = Postal.db.OpenSpeed end)
		updateFrame:SetScript("OnUpdate", function(self, elapsed)
			self.time = self.time - elapsed
			if self.time <= 0 then
				self:Hide()
				Postal_OpenAll:ProcessNext()
			end
		end)

		function Postal_OpenAll:MAIL_CLOSED()
			Postal_OpenAll:Reset()
		end

		function Postal_OpenAll:PLAYER_LEAVING_WORLD()
			Postal_OpenAll:Reset()
		end

		function Postal_OpenAll:UI_ERROR_MESSAGE(_, error_message)
			if not Postal.db.EnabledModules.OpenAll then
				return
			elseif error_message == ERR_INV_FULL then
				invFull = true
				wait = false
			elseif error_message == ERR_ITEM_MAX_COUNT then
				attachIndex = (attachIndex or 1) - 1
				wait = false
			end
		end

		function Postal_OpenAll:OnEnable()
			if not button then
				button = CreateFrame("Button", "KPostalOpenAllButton", InboxFrame, "UIPanelButtonTemplate")
				button:SetWidth(120)
				button:SetHeight(25)
				if core.locale == "frFR" then
					button:SetPoint("CENTER", InboxFrame, "TOP", -32, -410)
				else
					button:SetPoint("CENTER", InboxFrame, "TOP", -22, -410)
				end
				button:SetText(L["Open All"])
				button:SetScript("OnClick", function() Postal_OpenAll:OpenAll() end)
				button:SetFrameLevel(button:GetFrameLevel() + 1)
			end
			if not KPostal_OpenAllMenuButton then
				-- Create the Menu Button
				KPostal_OpenAllMenuButton = CreateFrame("Button", "KPostal_OpenAllMenuButton", InboxFrame)
				KPostal_OpenAllMenuButton:SetWidth(30)
				KPostal_OpenAllMenuButton:SetHeight(30)
				KPostal_OpenAllMenuButton:SetPoint("LEFT", button, "RIGHT", -2, 0)
				KPostal_OpenAllMenuButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
				KPostal_OpenAllMenuButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Round")
				KPostal_OpenAllMenuButton:SetDisabledTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Disabled")
				KPostal_OpenAllMenuButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
				KPostal_OpenAllMenuButton:SetScript("OnClick", function(self, button, down)
					if _G.KPostal_DropDownMenu.initialize ~= Postal_OpenAll.ModuleMenu then
						CloseDropDownMenus()
						_G.KPostal_DropDownMenu.initialize = Postal_OpenAll.ModuleMenu
					end
					ToggleDropDownMenu(1, nil, _G.KPostal_DropDownMenu, self:GetName(), 0, 0)
				end)
				KPostal_OpenAllMenuButton:SetFrameLevel(KPostal_OpenAllMenuButton:GetFrameLevel() + 1)
			end

			button:Show()
			KPostal_OpenAllMenuButton:SetScript("OnHide", _G.KPostal_DropDownMenu.HideMenu)
			KPostal_OpenAllMenuButton:Show()
			Postal.RegisterEvent(Postal_OpenAll, "UI_ERROR_MESSAGE")
		end

		function Postal_OpenAll:OnDisable()
			self:Reset()
			KPostal_OpenAllMenuButton:SetScript("OnHide", nil)
			KPostal_OpenAllMenuButton:Hide()
			if button then
				button:Hide()
			end
			Postal.UnregisterAllEvents(Postal_OpenAll)
		end

		function Postal_OpenAll:OpenAll()
			mailIndex = GetInboxNumItems() or 0
			attachIndex = ATTACHMENTS_MAX_RECEIVE
			invFull = nil
			skipFlag = false
			lastItem = false
			lastNumAttach = nil
			lastNumGold = nil
			wait = false
			openAllOverride = IsShiftKeyDown()
			if mailIndex == 0 then return end

			Postal:DisableInbox(1)
			button:SetText(L["Processing Message"])

			self:ProcessNext()
		end

		function Postal_OpenAll:ProcessNext()
			if mailIndex > 0 then
				if wait then
					local attachCount, goldCount = Postal:CountItemsAndMoney()
					if lastNumGold ~= goldCount then
						wait = false
						mailIndex = mailIndex - 1
						attachIndex = ATTACHMENTS_MAX_RECEIVE
						return self:ProcessNext() -- tail call
					elseif lastNumAttach ~= attachCount then
						wait = false
						attachIndex = (attachIndex or 1) - 1
						if lastItem then
							lastItem = false
							mailIndex = mailIndex - 1
							attachIndex = ATTACHMENTS_MAX_RECEIVE
							return self:ProcessNext() -- tail call
						end
					else
						updateFrame:Show()
						return
					end
				end

				local sender, msgSubject, msgMoney, msgCOD, _, msgItem, _, _, msgText, _, isGM = select(3, GetInboxHeaderInfo(mailIndex))

				if (msgCOD and msgCOD > 0) or (isGM) then
					skipFlag = true
					mailIndex = mailIndex - 1
					attachIndex = ATTACHMENTS_MAX_RECEIVE
					return self:ProcessNext() -- tail call
				end

				local mailType = Postal:GetMailType(msgSubject)
				if mailType == "NonAHMail" then
					if not (openAllOverride or Postal.db.OpenAll.Attachments) and msgItem then
						mailIndex = mailIndex - 1
						attachIndex = ATTACHMENTS_MAX_RECEIVE
						return self:ProcessNext() -- tail call
					end
				else
					local factionEnglish, factionLocale = UnitFactionGroup("player")
					if not strfind(sender, factionLocale) then
						mailType = "Neutral" .. mailType
					end
					if not (openAllOverride or Postal.db.OpenAll[mailType]) then
						mailIndex = mailIndex - 1
						attachIndex = ATTACHMENTS_MAX_RECEIVE
						return self:ProcessNext() -- tail call
					end
				end

				if Postal.db.OpenAll.SpamChat and attachIndex == ATTACHMENTS_MAX_RECEIVE then
					local moneyString = msgMoney > 0 and " [" .. Postal:GetMoneyString(msgMoney) .. "]" or ""
					Postal:Print(format("%s %d: %s%s", L["Processing Message"], mailIndex, msgSubject or "", moneyString))
				end

				while not GetInboxItemLink(mailIndex, attachIndex) and attachIndex > 0 do
					attachIndex = (attachIndex or 1) - 1
				end

				if attachIndex > 0 and not invFull and Postal.db.OpenAll.KeepFreeSpace > 0 then
					local free = 0
					for bag = 0, NUM_BAG_SLOTS do
						local bagFree, bagFam = GetContainerNumFreeSlots(bag)
						if bagFam == 0 then
							free = free + bagFree
						end
					end
					if free <= Postal.db.OpenAll.KeepFreeSpace then
						invFull = true
						Postal:Print(L:F("Not taking more items as there are now only %d regular bagslots free.", free))
					end
				end

				if attachIndex > 0 and not invFull then
					TakeInboxItem(mailIndex, attachIndex)

					lastNumAttach, lastNumGold = Postal:CountItemsAndMoney()
					wait = true
					local attachIndex2 = attachIndex - 1
					while not GetInboxItemLink(mailIndex, attachIndex2) and attachIndex2 > 0 do
						attachIndex2 = attachIndex2 - 1
					end
					if attachIndex2 == 0 and msgMoney == 0 then
						lastItem = true
					end

					updateFrame:Show()
				elseif msgMoney > 0 then
					TakeInboxMoney(mailIndex)

					lastNumAttach, lastNumGold = Postal:CountItemsAndMoney()
					wait = true

					updateFrame:Show()
				else
					mailIndex = mailIndex - 1
					attachIndex = ATTACHMENTS_MAX_RECEIVE
					return self:ProcessNext()
				end
			else
				if IsAddOnLoaded("MrPlow") then
					if _G.MrPlow.DoStuff then
						_G.MrPlow:DoStuff("stack")
					elseif _G.MrPlow.ParseInventory then
						_G.MrPlow:ParseInventory()
					end
				end
				if skipFlag then
					Postal:Print(L["Some Messages May Have Been Skipped."])
				end
				self:Reset()
			end
		end

		function Postal_OpenAll:Reset()
			updateFrame:Hide()
			Postal:DisableInbox()
			InboxFrame_Update()
			if button then
				button:SetText(L["Open All"])
			end
		end

		function Postal_OpenAll.SetKeepFreeSpace(dropdownbutton, arg1)
			Postal.db.OpenAll.KeepFreeSpace = arg1
		end

		function Postal_OpenAll.ModuleMenu(self, level)
			if not level then return end
			local info = self.info
			wipe(info)
			local db = Postal.db.OpenAll

			if level == 1 + self.levelAdjust then
				info.hasArrow = 1
				info.keepShownOnClick = 1
				info.func = self.UncheckHack
				info.notCheckable = 1

				info.text = FACTION .. " " .. L["AH-related mail"]
				info.value = "AHMail"
				UIDropDownMenu_AddButton(info, level)

				info.text = FACTION_STANDING_LABEL4 .. " " .. L["AH-related mail"]
				info.value = "NeutralAHMail"
				UIDropDownMenu_AddButton(info, level)

				info.text = L["Non-AH related mail"]
				info.value = "NonAHMail"
				UIDropDownMenu_AddButton(info, level)

				info.text = L["Other options"]
				info.value = "OtherOptions"
				UIDropDownMenu_AddButton(info, level)
			elseif level == 2 + self.levelAdjust then
				info.keepShownOnClick = 1
				info.func = Postal.SaveOption
				info.arg1 = "OpenAll"

				if UIDROPDOWNMENU_MENU_VALUE == "AHMail" then
					info.text = L["Open all Auction cancelled mail"]
					info.arg2 = "AHCancelled"
					info.checked = db.AHCancelled
					UIDropDownMenu_AddButton(info, level)

					info.text = L["Open all Auction expired mail"]
					info.arg2 = "AHExpired"
					info.checked = db.AHExpired
					UIDropDownMenu_AddButton(info, level)

					info.text = L["Open all Outbid on mail"]
					info.arg2 = "AHOutbid"
					info.checked = db.AHOutbid
					UIDropDownMenu_AddButton(info, level)

					info.text = L["Open all Auction successful mail"]
					info.arg2 = "AHSuccess"
					info.checked = db.AHSuccess
					UIDropDownMenu_AddButton(info, level)

					info.text = L["Open all Auction won mail"]
					info.arg2 = "AHWon"
					info.checked = db.AHWon
					UIDropDownMenu_AddButton(info, level)
				elseif UIDROPDOWNMENU_MENU_VALUE == "NeutralAHMail" then
					info.text = L["Open all Auction cancelled mail"]
					info.arg2 = "NeutralAHCancelled"
					info.checked = db.NeutralAHCancelled
					UIDropDownMenu_AddButton(info, level)

					info.text = L["Open all Auction expired mail"]
					info.arg2 = "NeutralAHExpired"
					info.checked = db.NeutralAHExpired
					UIDropDownMenu_AddButton(info, level)

					info.text = L["Open all Outbid on mail"]
					info.arg2 = "NeutralAHOutbid"
					info.checked = db.NeutralAHOutbid
					UIDropDownMenu_AddButton(info, level)

					info.text = L["Open all Auction successful mail"]
					info.arg2 = "NeutralAHSuccess"
					info.checked = db.NeutralAHSuccess
					UIDropDownMenu_AddButton(info, level)

					info.text = L["Open all Auction won mail"]
					info.arg2 = "NeutralAHWon"
					info.checked = db.NeutralAHWon
					UIDropDownMenu_AddButton(info, level)
				elseif UIDROPDOWNMENU_MENU_VALUE == "NonAHMail" then
					info.text = L["Open all mail with attachments"]
					info.arg2 = "Attachments"
					info.checked = db.Attachments
					UIDropDownMenu_AddButton(info, level)
				elseif UIDROPDOWNMENU_MENU_VALUE == "OtherOptions" then
					info.text = L["Keep free space"]
					info.hasArrow = 1
					info.value = "KeepFreeSpace"
					info.func = self.UncheckHack
					UIDropDownMenu_AddButton(info, level)

					info.text = L["Verbose mode"]
					info.hasArrow = nil
					info.value = nil
					info.func = Postal.SaveOption
					info.arg2 = "SpamChat"
					info.checked = db.SpamChat
					UIDropDownMenu_AddButton(info, level)
				end
			elseif level == 3 + self.levelAdjust then
				if UIDROPDOWNMENU_MENU_VALUE == "KeepFreeSpace" then
					local keepFree = db.KeepFreeSpace
					info.func = Postal_OpenAll.SetKeepFreeSpace
					for _, v in ipairs(Postal.keepFreeOptions) do
						info.text = v
						info.checked = v == keepFree
						info.arg1 = v
						UIDropDownMenu_AddButton(info, level)
					end
				end
			end
		end

		Postal.modules.OpenAll = Postal_OpenAll
	end

	---------------------------------------------------------------------------
	-- Wire
	-- Set subject field to value of coins sent if subject is blank.

	do
		local Postal_Wire = {}
		LibStub("AceHook-3.0"):Embed(Postal_Wire)

		local g, s, c
		g = "^%[" .. GOLD_AMOUNT .. " " .. SILVER_AMOUNT .. " " .. COPPER_AMOUNT .. "%]$"
		s = "^%[" .. SILVER_AMOUNT .. " " .. COPPER_AMOUNT .. "%]$"
		c = "^%[" .. COPPER_AMOUNT .. "%]$"
		if core.locale == "ruRU" then
			--Because ruRU has these escaped strings which can't be in mail subjects.
			--COPPER_AMOUNT = "%d |4медная монета:медные монеты:медных монет;"; -- Lowest value coin denomination
			--SILVER_AMOUNT = "%d |4серебряная:серебряные:серебряных;"; -- Mid value coin denomination
			--GOLD_AMOUNT = "%d |4золотая:золотые:золотых;"; -- Highest value coin denomination
			g = "^%[%d+з %d+с %d+м%]$"
			s = "^%[%d+с %d+м%]$"
			c = "^%[%d+м%]$"
		end
		g = strgsub(g, "%%d", "%%d+")
		s = strgsub(s, "%%d", "%%d+")
		c = strgsub(c, "%%d", "%%d+")

		function Postal_Wire:OnEnable()
			if not self:IsHooked(SendMailMoney, "onValueChangedFunc") then
				self:SecureHook(SendMailMoney, "onValueChangedFunc")
			end
		end

		function Postal_Wire:OnDisable()
			if self:IsHooked(SendMailMoney, "onValueChangedFunc") then
				self:Unhook(SendMailMoney, "onValueChangedFunc")
			end
		end

		function Postal_Wire:onValueChangedFunc()
			local subject = SendMailSubjectEditBox:GetText()
			if subject == "" or subject:find(g) or subject:find(s) or subject:find(c) then
				local money = MoneyInputFrame_GetCopper(SendMailMoney)
				if money and money > 0 then
					local gold = floor(money / 10000)
					local silver = floor((money - gold * 10000) / 100)
					local copper = mod(money, 100)
					if core.locale == "ruRU" then
						if gold > 0 then
							SendMailSubjectEditBox:SetText(format("[%d+з %d+с %d+м]", gold, silver, copper))
						elseif silver > 0 then
							SendMailSubjectEditBox:SetText(format("[%d+с %d+м]", silver, copper))
						else
							SendMailSubjectEditBox:SetText(format("[%d+м]", copper))
						end
					else
						if gold > 0 then
							SendMailSubjectEditBox:SetText(format("[" .. GOLD_AMOUNT .. " " .. SILVER_AMOUNT .. " " .. COPPER_AMOUNT .. "]", gold, silver, copper))
						elseif silver > 0 then
							SendMailSubjectEditBox:SetText(format("[" .. SILVER_AMOUNT .. " " .. COPPER_AMOUNT .. "]", silver, copper))
						else
							SendMailSubjectEditBox:SetText(format("[" .. COPPER_AMOUNT .. "]", copper))
						end
					end
				else
					SendMailSubjectEditBox:SetText("")
				end
			end
		end

		Postal.modules.Wire = Postal_Wire
	end

	---------------------------------------------------------------------------
	-- Select

	do
		local Postal_Select = {}
		LibStub("AceHook-3.0"):Embed(Postal_Select)

		local currentMode = nil
		local selectedMail = {}
		local openButton = nil
		local returnButton = nil
		local checkboxFunc = function(self)
			Postal_Select:ToggleMail(self)
		end
		local mailIndex, attachIndex
		local lastItem, lastNumAttach, lastNumGold
		local wait
		local skipFlag
		local invFull
		local lastCheck

		local updateFrame = CreateFrame("Frame")
		updateFrame:Hide()
		updateFrame:SetScript("OnShow", function(self) self.time = Postal.db.OpenSpeed end)
		updateFrame:SetScript("OnUpdate", function(self, elapsed)
			self.time = self.time - elapsed
			if self.time <= 0 then
				self:Hide()
				Postal_Select:ProcessNext()
			end
		end)

		local lastUnseen, lastTime = 0, 0
		local function printTooMuchMail()
			local cur, tot = GetInboxNumItems()
			if tot - cur ~= lastUnseen or GetTime() - lastTime >= 61 then
				lastUnseen = tot - cur
				lastTime = GetTime()
			end
			if cur >= 50 then
				Postal:Print(L:F("There are %i more messages not currently shown.", lastUnseen))
			else
				Postal:Print(L:F("There are %i more messages not currently shown. More should become available in %i seconds.", lastUnseen, lastTime + 61 - GetTime()))
			end

			InboxTooMuchMail.Show = core.Noop
		end

		function Postal_Select:OnEnable()
			if not openButton then
				openButton = CreateFrame("Button", "PostalSelectOpenButton", InboxFrame, "UIPanelButtonTemplate")
				openButton:SetWidth(120)
				openButton:SetHeight(25)
				openButton:SetPoint("RIGHT", InboxFrame, "TOP", 5, -53)
				openButton:SetText(L["Open"])
				openButton:SetScript("OnClick", function() Postal_Select:HandleSelect(1) end)
				openButton:SetFrameLevel(openButton:GetFrameLevel() + 1)
			end

			if not returnButton then
				returnButton = CreateFrame("Button", "PostalSelectReturnButton", InboxFrame, "UIPanelButtonTemplate")
				returnButton:SetWidth(120)
				returnButton:SetHeight(25)
				returnButton:SetPoint("LEFT", InboxFrame, "TOP", 10, -53)
				returnButton:SetText(MAIL_RETURN)
				returnButton:SetScript("OnClick", function() Postal_Select:HandleSelect() end)
				returnButton:SetFrameLevel(returnButton:GetFrameLevel() + 1)
			end

			MailItem1:SetPoint("TOPLEFT", "InboxFrame", "TOPLEFT", 48, -80)
			for i = 1, 7 do
				_G["MailItem" .. i .. "ExpireTime"]:SetPoint("TOPRIGHT", "MailItem" .. i, "TOPRIGHT", 10, -4)
				_G["MailItem" .. i]:SetWidth(280)
			end

			for i = 1, 7 do
				if not _G["PostalInboxCB" .. i] then
					local CB = CreateFrame("CheckButton", "PostalInboxCB" .. i, _G["MailItem" .. i], "OptionsCheckButtonTemplate")
					CB:SetID(i)
					CB:SetPoint("RIGHT", "MailItem" .. i, "LEFT", 1, -5)
					CB:SetWidth(24)
					CB:SetHeight(24)
					CB:SetHitRectInsets(0, 0, 0, 0)
					CB:SetScript("OnClick", checkboxFunc)
					local text = CB:CreateFontString("PostalInboxCB" .. i .. "Text", "BACKGROUND", "GameFontHighlightSmall")
					text:SetPoint("BOTTOM", CB, "TOP")
					text:SetText(i)
					CB.text = text
				end
			end

			self:RawHook("InboxFrame_Update", true)

			InboxTooMuchMail.Show = printTooMuchMail
			InboxTooMuchMail:Hide()

			openButton:Show()
			returnButton:Show()
			for i = 1, 7 do
				_G["PostalInboxCB" .. i]:Show()
			end

			Postal.RegisterEvent(Postal_Select, "MAIL_INBOX_UPDATE")
			Postal.RegisterEvent(Postal_Select, "UI_ERROR_MESSAGE")
		end

		function Postal_Select:OnDisable()
			self:Reset()
			if self:IsHooked("InboxFrame_Update") then
				self:Unhook("InboxFrame_Update")
			end
			openButton:Hide()
			returnButton:Hide()
			MailItem1:SetPoint("TOPLEFT", "InboxFrame", "TOPLEFT", 28, -80)
			for i = 1, 7 do
				_G["PostalInboxCB" .. i]:Hide()
				_G["MailItem" .. i .. "ExpireTime"]:SetPoint("TOPRIGHT", "MailItem" .. i, "TOPRIGHT", -4, -4)
				_G["MailItem" .. i]:SetWidth(305)
			end
			InboxTooMuchMail.Show = nil
			Postal.UnregisterAllEvents(Postal_Select)
		end

		function Postal_Select:MAIL_CLOSED()
			Postal_Select:Reset()
		end

		function Postal_Select:MAIL_INBOX_UPDATE()
			if Postal.db.EnabledModules.Select then
				updateFrame:Show()
			end
		end

		function Postal_Select:PLAYER_LEAVING_WORLD()
			Postal_Select:Reset()
		end

		function Postal_Select:UI_ERROR_MESSAGE(_, error_message)
			if not Postal.db.EnabledModules.Select then
				return
			elseif error_message == ERR_INV_FULL then
				invFull = true
				wait = false
			elseif error_message == ERR_ITEM_MAX_COUNT then
				attachIndex = (attachIndex or 1) - 1
				wait = false
			end
		end

		function Postal_Select:ToggleMail(frame)
			local index = frame:GetID() + (InboxFrame.pageNum - 1) * 7
			if lastCheck and IsShiftKeyDown() then
				for i = lastCheck, index, lastCheck <= index and 1 or -1 do
					selectedMail[i] = true
				end
				self:InboxFrame_Update()
				return
			end
			if IsControlKeyDown() then
				local status = frame:GetChecked()
				local indexSender = select(3, GetInboxHeaderInfo(index))
				for i = 1, GetInboxNumItems() do
					if select(3, GetInboxHeaderInfo(i)) == indexSender then
						selectedMail[i] = status
					end
				end
				self:InboxFrame_Update()
				return
			end
			if frame:GetChecked() then
				selectedMail[index] = true
				lastCheck = index
			else
				selectedMail[index] = nil
				lastCheck = nil
			end
		end

		function Postal_Select:HandleSelect(mode)
			mailIndex = GetInboxNumItems() or 0
			attachIndex = ATTACHMENTS_MAX_RECEIVE
			invFull = nil
			skipFlag = false
			lastItem = false
			lastNumAttach = nil
			lastNumGold = nil
			wait = false
			if mailIndex == 0 then return end

			currentMode = mode
			if currentMode then
				openButton:SetText(L["Processing Message"])
				returnButton:Hide()
			else
				returnButton:SetText(L["Processing Message"])
				openButton:Hide()
			end

			Postal:DisableInbox(1)
			if self:IsHooked("InboxFrame_Update") then
				self:Unhook("InboxFrame_Update")
			end

			for i = 1, 7 do
				local index = i + (InboxFrame.pageNum - 1) * 7
				local CB = _G["PostalInboxCB" .. i]
				CB:Hide()
			end

			self:ProcessNext()
		end

		function Postal_Select:ProcessNext()
			mailIndex = mailIndex or 0
			while not selectedMail[mailIndex] and mailIndex > 0 do
				mailIndex = mailIndex - 1
				attachIndex = ATTACHMENTS_MAX_RECEIVE
			end

			if mailIndex > 0 then
				local msgSubject, msgMoney, msgCOD, _, msgItem, _, wasReturned, msgText, canReply, isGM = select(4, GetInboxHeaderInfo(mailIndex))

				if currentMode then
					if wait then
						local attachCount, goldCount = Postal:CountItemsAndMoney()
						if lastNumGold ~= goldCount then
							wait = false
							selectedMail[mailIndex] = nil
							mailIndex = mailIndex - 1
							attachIndex = ATTACHMENTS_MAX_RECEIVE
							return self:ProcessNext() -- tail call
						elseif lastNumAttach ~= attachCount then
							wait = false
							attachIndex = (attachIndex or 1) - 1
							if lastItem then
								lastItem = false
								selectedMail[mailIndex] = nil
								mailIndex = mailIndex - 1
								attachIndex = ATTACHMENTS_MAX_RECEIVE
								return self:ProcessNext() -- tail call
							end
						else
							updateFrame:Show()
							return
						end
					end

					if Postal.db.Select.SpamChat and attachIndex == ATTACHMENTS_MAX_RECEIVE then
						local moneyString = msgMoney > 0 and " [" .. Postal:GetMoneyString(msgMoney) .. "]" or ""
						Postal:Print(format("%s %d: %s%s", L["Open"], mailIndex, msgSubject or "", moneyString))
					end

					if (msgCOD and msgCOD > 0) or (isGM) then
						skipFlag = true
						selectedMail[mailIndex] = nil
						mailIndex = mailIndex - 1
						attachIndex = ATTACHMENTS_MAX_RECEIVE
						return self:ProcessNext() -- tail call
					end

					while not GetInboxItemLink(mailIndex, attachIndex) and attachIndex > 0 do
						attachIndex = (attachIndex or 1) - 1
					end

					if attachIndex > 0 and not invFull and Postal.db.Select.KeepFreeSpace > 0 then
						local free = 0
						for bag = 0, NUM_BAG_SLOTS do
							local bagFree, bagFam = GetContainerNumFreeSlots(bag)
							if bagFam == 0 then
								free = free + bagFree
							end
						end
						if free <= Postal.db.Select.KeepFreeSpace then
							invFull = true
							Postal:Print(L:F("Not taking more items as there are now only %d regular bagslots free.", free))
						end
					end

					if attachIndex > 0 and not invFull then
						TakeInboxItem(mailIndex, attachIndex)

						lastNumAttach, lastNumGold = Postal:CountItemsAndMoney()
						wait = true
						local attachIndex2 = attachIndex - 1
						while not GetInboxItemLink(mailIndex, attachIndex2) and attachIndex2 > 0 do
							attachIndex2 = attachIndex2 - 1
						end
						if attachIndex2 == 0 and msgMoney == 0 then
							lastItem = true
						end

						updateFrame:Show()
					elseif msgMoney > 0 then
						TakeInboxMoney(mailIndex)

						lastNumAttach, lastNumGold = Postal:CountItemsAndMoney()
						wait = true

						updateFrame:Show()
					else
						selectedMail[mailIndex] = nil
						mailIndex = mailIndex - 1
						attachIndex = ATTACHMENTS_MAX_RECEIVE
						return self:ProcessNext() -- tail call
					end
				else
					if Postal.db.Select.SpamChat and attachIndex == ATTACHMENTS_MAX_RECEIVE then
						Postal:Print(MAIL_RETURN .. " " .. mailIndex .. ": " .. msgSubject)
					end
					if not wasReturned and canReply then
						ReturnInboxItem(mailIndex)
						selectedMail[mailIndex] = nil
						mailIndex = mailIndex - 1
					else
						Postal:Print(L["Skipping"] .. " " .. mailIndex .. ": " .. msgSubject)
						mailIndex = mailIndex - 1
						return self:ProcessNext() -- tail call
					end
				end
			else
				if IsAddOnLoaded("MrPlow") then
					if _G.MrPlow.DoStuff then
						_G.MrPlow:DoStuff("stack")
					elseif _G.MrPlow.ParseInventory then -- Backwards compat
						_G.MrPlow:ParseInventory()
					end
				end
				if skipFlag then
					Postal:Print(L["Some Messages May Have Been Skipped."])
				end
				self:Reset()
			end
		end

		function Postal_Select:InboxFrame_Update()
			self.hooks["InboxFrame_Update"]()
			for i = 1, 7 do
				local index = i + (InboxFrame.pageNum - 1) * 7
				local CB = _G["PostalInboxCB" .. i]
				if index > GetInboxNumItems() then
					CB:Hide()
				else
					CB:Show()
					CB:SetChecked(selectedMail[index])
					CB.text:SetText(index)
				end
			end
		end

		function Postal_Select:Reset()
			if not self:IsHooked("InboxFrame_Update") then
				self:RawHook("InboxFrame_Update", true)
			end

			updateFrame:Hide()

			wipe(selectedMail)

			Postal:DisableInbox()
			self:InboxFrame_Update()
			openButton:SetText(L["Open"])
			openButton:Show()
			returnButton:SetText(MAIL_RETURN)
			returnButton:Show()
			lastCheck = nil
			InboxTooMuchMail.Show = printTooMuchMail
		end

		function Postal_Select.SetKeepFreeSpace(dropdownbutton, arg1, arg2, checked)
			Postal.db.Select.KeepFreeSpace = arg1
		end

		function Postal_Select.ModuleMenu(self, level)
			if not level then return end
			local info = self.info
			wipe(info)
			if level == 1 + self.levelAdjust then
				info.keepShownOnClick = 1

				info.text = L["Keep free space"]
				info.hasArrow = 1
				info.value = "KeepFreeSpace"
				info.func = self.UncheckHack
				UIDropDownMenu_AddButton(info, level)

				info.text = L["Verbose mode"]
				info.hasArrow = nil
				info.value = nil
				info.func = Postal.SaveOption
				info.arg1 = "Select"
				info.arg2 = "SpamChat"
				info.checked = Postal.db.Select.SpamChat
				UIDropDownMenu_AddButton(info, level)
			elseif level == 2 + self.levelAdjust then
				if UIDROPDOWNMENU_MENU_VALUE == "KeepFreeSpace" then
					local keepFree = Postal.db.Select.KeepFreeSpace
					info.func = Postal_Select.SetKeepFreeSpace
					for _, v in ipairs(Postal.keepFreeOptions) do
						info.text = v
						info.checked = v == keepFree
						info.arg1 = v
						UIDropDownMenu_AddButton(info, level)
					end
				end
			end
		end

		Postal.modules.Select = Postal_Select
	end

	---------------------------------------------------------------------------
	-- Rake
	-- Prints the amount of money collected during a mail session.

	do
		local Postal_Rake = {}
		local money

		function Postal_Rake:OnEnable()
			Postal.RegisterEvent(Postal_Rake, "MAIL_SHOW", "MailShow")
		end

		function Postal_Rake:OnDisable()
			Postal.UnregisterAllEvents(Postal_Rake)
		end

		function Postal_Rake:MailShow()
			money = GetMoney()
			Postal.RegisterEvent(Postal_Rake, "MAIL_CLOSED", "MailClosed")
		end

		function Postal_Rake:MailClosed()
			Postal.UnregisterEvent(Postal_Rake, "MAIL_CLOSED")
			money = GetMoney() - money
			if money > 0 then
				Postal:Print(L["Collected"] .. " " .. Postal:GetMoneyString(money))
			end
		end

		Postal.modules.Rake = Postal_Rake
	end

	---------------------------------------------------------------------------
	-- DoNotWant
	-- Shows a clickable visual icon as to whether a mail will be returned or deleted on expiry.

	do
		local Postal_DoNotWant = {}
		LibStub("AceHook-3.0"):Embed(Postal_DoNotWant)

		StaticPopupDialogs["KPOSTAL_DELETE_MAIL"] = {
			text = DELETE_MAIL_CONFIRMATION,
			button1 = ACCEPT,
			button2 = CANCEL,
			OnAccept = function(self)
				DeleteInboxItem(selectedID)
				selectedID = nil
			end,
			showAlert = 1,
			timeout = 0,
			hideOnEscape = 1
		}

		StaticPopupDialogs["KPOSTAL_DELETE_MONEY"] = {
			text = DELETE_MONEY_CONFIRMATION,
			button1 = ACCEPT,
			button2 = CANCEL,
			OnAccept = function(self)
				DeleteInboxItem(selectedID)
				selectedID = nil
			end,
			OnShow = function(self)
				MoneyFrame_Update(self.moneyFrame, selectedIDmoney)
			end,
			hasMoneyFrame = 1,
			showAlert = 1,
			timeout = 0,
			hideOnEscape = 1
		}

		function Postal_DoNotWant.Click(self, button, down)
			selectedID = self.id + (InboxFrame.pageNum - 1) * 7
			local packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft, itemCount, wasRead, wasReturned, textCreated, canReply = GetInboxHeaderInfo(selectedID)
			selectedIDmoney = money
			local firstAttachName
			for i = 1, ATTACHMENTS_MAX_RECEIVE do
				firstAttachName = GetInboxItem(selectedID, i)
				if firstAttachName then
					break
				end
			end
			if InboxItemCanDelete(selectedID) then
				if firstAttachName then
					StaticPopup_Show("KPOSTAL_DELETE_MAIL", firstAttachName)
					return
				elseif money and money > 0 then
					StaticPopup_Show("KPOSTAL_DELETE_MONEY")
					return
				else
					DeleteInboxItem(selectedID)
				end
			else
				ReturnInboxItem(selectedID)
				StaticPopup_Hide("COD_CONFIRMATION")
			end
			selectedID = nil
		end

		function Postal_DoNotWant:OnEnable()
			for i = 1, 7 do
				local b = _G["MailItem" .. i .. "ExpireTime"]
				if not b.returnicon then
					b.returnicon = CreateFrame("BUTTON", nil, b)
					b.returnicon:SetPoint("TOPRIGHT", b, "BOTTOMRIGHT", -5, -1)
					b.returnicon:SetWidth(16)
					b.returnicon:SetHeight(16)
					b.returnicon.texture = b.returnicon:CreateTexture(nil, "BACKGROUND")
					b.returnicon.texture:SetAllPoints()
					b.returnicon.texture:SetTexCoord(1, 0, 0, 1) -- flips image left/right
					b.returnicon.id = i
					b.returnicon:SetScript("OnClick", Postal_DoNotWant.Click)
					b.returnicon:SetScript("OnEnter", b:GetScript("OnEnter"))
					b.returnicon:SetScript("OnLeave", b:GetScript("OnLeave"))
				end

				b.returnicon:Show()
			end

			if not self:IsHooked("InboxFrame_Update") then
				self:RawHook("InboxFrame_Update", true)
			end
		end

		function Postal_DoNotWant:OnDisable()
			if self:IsHooked("InboxFrame_Update") then
				self:Unhook("InboxFrame_Update")
			end
			for i = 1, 7 do
				_G["MailItem" .. i .. "ExpireTime"].returnicon:Hide()
			end
		end

		function Postal_DoNotWant:InboxFrame_Update()
			self.hooks["InboxFrame_Update"]()
			for i = 1, 7 do
				local index = i + (InboxFrame.pageNum - 1) * 7
				local b = _G["MailItem" .. i .. "ExpireTime"].returnicon
				if index > GetInboxNumItems() then
					b:Hide()
				else
					local f = InboxItemCanDelete(index)
					b.texture:SetTexture( f and "Interface\\RaidFrame\\ReadyCheck-NotReady" or "Interface\\ChatFrame\\ChatFrameExpandArrow")
					b.tooltip = f and DELETE or MAIL_RETURN
					b:Show()
				end
			end
		end

		Postal.modules.DoNotWant = Postal_DoNotWant
	end

	---------------------------------------------------------------------------
	-- BlackBook
	-- Lists your contacts, friends, guild mates, alts and track the last 10 people you mailed.

	do
		local Postal_BlackBook = {}
		LibStub("AceHook-3.0"):Embed(Postal_BlackBook)

		local Postal_BlackBookButton
		local numFriendsOnList = 0
		local sorttable = {}
		local ignoresortlocale = {koKR = true, zhCN = true, zhTW = true}
		local enableAltsMenu
		local Postal_BlackBook_Autocomplete_Flags = {include = AUTOCOMPLETE_FLAG_ALL, exclude = AUTOCOMPLETE_FLAG_NONE}

		function Postal_BlackBook:OnEnable()
			Postal.char.BlackBook.alts = Postal.char.BlackBook.alts or {}
			if not Postal_BlackBookButton then
				Postal_BlackBookButton = CreateFrame("Button", "Postal_BlackBookButton", SendMailFrame)
				Postal_BlackBookButton:SetWidth(25)
				Postal_BlackBookButton:SetHeight(25)
				Postal_BlackBookButton:SetPoint("LEFT", SendMailNameEditBox, "RIGHT", -2, 0)
				Postal_BlackBookButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
				Postal_BlackBookButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Round")
				Postal_BlackBookButton:SetDisabledTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Disabled")
				Postal_BlackBookButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
				Postal_BlackBookButton:SetScript("OnClick", function(self, button, down)
					if _G.KPostal_DropDownMenu.initialize ~= Postal_BlackBook.BlackBookMenu then
						CloseDropDownMenus()
						_G.KPostal_DropDownMenu.initialize = Postal_BlackBook.BlackBookMenu
					end
					ToggleDropDownMenu(1, nil, _G.KPostal_DropDownMenu, self:GetName(), 0, 0)
				end)
				Postal_BlackBookButton:SetScript("OnHide", _G.KPostal_DropDownMenu.HideMenu)
			end

			SendMailNameEditBox:SetHistoryLines(15)
			self:RawHook("SendMailFrame_Reset", true)
			self:RawHook("MailFrameTab_OnClick", true)
			if Postal.char.BlackBook.UseAutoComplete then
				self:RawHookScript(SendMailNameEditBox, "OnChar")
			end
			self:HookScript(SendMailNameEditBox, "OnEditFocusGained")
			self:RawHook("AutoComplete_Update", true)

			local db = Postal.char.BlackBook
			local exclude = bit.bor(db.AutoCompleteFriends and AUTOCOMPLETE_FLAG_NONE or AUTOCOMPLETE_FLAG_FRIEND, db.AutoCompleteGuild and AUTOCOMPLETE_FLAG_NONE or AUTOCOMPLETE_FLAG_IN_GUILD)
			Postal_BlackBook_Autocomplete_Flags.include = bit.bxor(db.ExcludeRandoms and (bit.bor(AUTOCOMPLETE_FLAG_FRIEND, AUTOCOMPLETE_FLAG_IN_GUILD)) or AUTOCOMPLETE_FLAG_ALL, exclude)
			SendMailNameEditBox.autoCompleteParams = Postal_BlackBook_Autocomplete_Flags

			Postal_BlackBookButton:Show()
		end

		function Postal_BlackBook:OnDisable()
			SendMailNameEditBox:SetHistoryLines(1)
			Postal_BlackBookButton:Hide()
			SendMailNameEditBox.autoCompleteParams = AUTOCOMPLETE_LIST.MAIL
		end

		function Postal_BlackBook:MAIL_SHOW()
			if self.AddAlt then
				self:AddAlt()
			end
		end

		function Postal_BlackBook:AddAlt()
			local realm = GetRealmName()
			local faction = UnitFactionGroup("player")
			local player = UnitName("player")
			local namestring = UnitName("player") .. "|" .. GetRealmName() .. "|" .. UnitFactionGroup("player")
			local flag = true
			local db = Postal.char.BlackBook.alts
			for i = 1, #db do
				if namestring == db[i] then
					flag = false
				else
					local p, r, f = strsplit("|", db[i])
					if r == realm and f == faction and p ~= player then
						enableAltsMenu = true
					end
				end
			end
			if flag then
				tinsert(db, namestring)
				tsort(db)
			end
			self.AddAlt = nil -- Kill ourselves so we only run it once
		end

		function Postal_BlackBook.DeleteAlt(dropdownbutton, arg1, arg2, checked)
			local realm = GetRealmName()
			local faction = UnitFactionGroup("player")
			local player = UnitName("player")
			local db = Postal.char.BlackBook.alts
			enableAltsMenu = false
			for i = #db, 1, -1 do
				if arg1 == db[i] then
					tremove(db, i)
				else
					local p, r, f = strsplit("|", db[i])
					if r == realm and f == faction and p ~= player then
						enableAltsMenu = true
					end
				end
			end
			CloseDropDownMenus()
		end

		-- Only called on a mail that is sent successfully
		function Postal_BlackBook:SendMailFrame_Reset()
			local name = strtrim(SendMailNameEditBox:GetText())
			if name == "" then
				return self.hooks["SendMailFrame_Reset"]()
			end
			SendMailNameEditBox:AddHistoryLine(name)
			local db = Postal.char.BlackBook.recent
			for k = 1, #db do
				if name == db[k] then
					tremove(db, k)
					break
				end
			end
			tinsert(db, 1, name)
			for k = #db, 11, -1 do
				tremove(db, k)
			end
			self.hooks["SendMailFrame_Reset"]()
			if Postal.char.BlackBook.AutoFill then
				SendMailNameEditBox:SetText(name)
				SendMailNameEditBox:HighlightText()
			end
		end

		function Postal_BlackBook.ClearRecent(dropdownbutton, arg1, arg2, checked)
			wipe(Postal.char.BlackBook.recent)
			CloseDropDownMenus()
		end

		function Postal_BlackBook:MailFrameTab_OnClick(button, tab)
			self.hooks["MailFrameTab_OnClick"](button, tab)
			if Postal.char.BlackBook.AutoFill and tab == 2 then
				local name = Postal.char.BlackBook.recent[1]
				if name and SendMailNameEditBox:GetText() == "" then
					SendMailNameEditBox:SetText(name)
					SendMailNameEditBox:HighlightText()
				end
			end
		end

		function Postal_BlackBook:OnEditFocusGained(editbox, ...)
			SendMailNameEditBox:HighlightText()
		end

		function Postal_BlackBook:AutoComplete_Update(editBox, editBoxText, utf8Position, ...)
			if editBox ~= SendMailNameEditBox or not Postal.char.BlackBook.DisableBlizzardAutoComplete then
				self.hooks["AutoComplete_Update"](editBox, editBoxText, utf8Position, ...)
			end
		end

		function Postal_BlackBook:OnChar(editbox, ...)
			if editbox:GetUTF8CursorPosition() ~= strlenutf8(editbox:GetText()) then return end

			local db = Postal.char.BlackBook
			local text = strupper(editbox:GetText())
			local textlen = strlen(text)
			local newname

			if db.AutoCompleteAlts then
				local alts = Postal.char.BlackBook.alts
				local realm = GetRealmName()
				local faction = UnitFactionGroup("player")
				local player = UnitName("player")
				for i = 1, #alts do
					local p, r, f = strsplit("|", alts[i])
					if r == realm and f == faction and p ~= player then
						if strfind(strupper(p), text, 1, 1) == 1 then
							newname = p
							break
						end
					end
				end
			end

			if not newname and db.AutoCompleteRecent then
				local db2 = db.recent
				for j = 1, #db2 do
					local name = db2[j]
					if strfind(strupper(name), text, 1, 1) == 1 then
						newname = name
						break
					end
				end
			end

			if not newname and db.AutoCompleteContacts then
				local db2 = db.contacts
				for j = 1, #db2 do
					local name = db2[j]
					if strfind(strupper(name), text, 1, 1) == 1 then
						newname = name
						break
					end
				end
			end

			self.hooks[SendMailNameEditBox].OnChar(editbox, ...)

			if newname then
				editbox:SetText(newname)
				editbox:HighlightText(textlen, -1)
				editbox:SetCursorPosition(textlen)
			end
		end

		function Postal_BlackBook.SetSendMailName(dropdownbutton, arg1, arg2, checked)
			SendMailNameEditBox:SetText(arg1)
			if SendMailNameEditBox:HasFocus() then
				SendMailSubjectEditBox:SetFocus()
			end
			CloseDropDownMenus()
		end

		function Postal_BlackBook.AddContact(dropdownbutton, arg1, arg2, checked)
			local name = strtrim(SendMailNameEditBox:GetText())
			if name == "" then return end
			local db = Postal.char.BlackBook.contacts
			for k = 1, #db do
				if name == db[k] then
					return
				end
			end
			tinsert(db, name)
			tsort(db)
		end

		function Postal_BlackBook.RemoveContact(dropdownbutton, arg1, arg2, checked)
			local name = strtrim(SendMailNameEditBox:GetText())
			if name == "" then return end
			local db = Postal.char.BlackBook.contacts
			for k = 1, #db do
				if name == db[k] then
					tremove(db, k)
					return
				end
			end
		end

		function Postal_BlackBook.BlackBookMenu(self, level)
			if not level then return end
			Postal.char.BlackBook.contacts = Postal.char.BlackBook.contacts or {}
			local info = self.info
			wipe(info)
			if level == 1 then
				info.isTitle = 1
				info.text = FRIENDS
				info.notCheckable = 1
				UIDropDownMenu_AddButton(info, level)

				info.disabled = nil
				info.isTitle = nil

				local db = Postal.char.BlackBook.contacts
				for i = 1, #db do
					info.text = db[i]
					info.func = Postal_BlackBook.SetSendMailName
					info.arg1 = db[i]
					UIDropDownMenu_AddButton(info, level)
				end

				info.arg1 = nil
				if #db > 0 then
					info.disabled = 1
					info.text = nil
					info.func = nil
					UIDropDownMenu_AddButton(info, level)
					info.disabled = nil
				end

				info.text = L["Add Contact"]
				info.func = Postal_BlackBook.AddContact
				UIDropDownMenu_AddButton(info, level)

				info.text = L["Remove Contact"]
				info.func = Postal_BlackBook.RemoveContact
				UIDropDownMenu_AddButton(info, level)

				info.disabled = 1
				info.text = nil
				info.func = nil
				UIDropDownMenu_AddButton(info, level)

				info.hasArrow = 1
				info.keepShownOnClick = 1
				info.func = self.UncheckHack

				info.disabled = #Postal.char.BlackBook.recent == 0
				info.text = L["Recently Mailed"]
				info.value = "recent"
				UIDropDownMenu_AddButton(info, level)

				info.disabled = not enableAltsMenu
				info.text = L["Alts"]
				info.value = "alt"
				UIDropDownMenu_AddButton(info, level)

				info.disabled = GetNumFriends() == 0
				info.text = FRIEND
				info.value = "friend"
				UIDropDownMenu_AddButton(info, level)

				info.disabled = not IsInGuild()
				info.text = GUILD
				info.value = "guild"
				UIDropDownMenu_AddButton(info, level)

				wipe(info)
				info.disabled = 1
				info.notCheckable = 1
				UIDropDownMenu_AddButton(info, level)
				info.disabled = nil

				info.text = CLOSE
				info.func = self.HideMenu
				UIDropDownMenu_AddButton(info, level)
			elseif level == 2 then
				info.notCheckable = 1
				if UIDROPDOWNMENU_MENU_VALUE == "recent" then
					local db = Postal.char.BlackBook.recent
					if #db == 0 then return end

					for i = 1, #db do
						info.text = db[i]
						info.func = Postal_BlackBook.SetSendMailName
						info.arg1 = db[i]
						UIDropDownMenu_AddButton(info, level)
					end

					info.disabled = 1
					info.text = nil
					info.func = nil
					info.arg1 = nil
					UIDropDownMenu_AddButton(info, level)
					info.disabled = nil

					info.text = L["Clear list"]
					info.func = Postal_BlackBook.ClearRecent
					info.arg1 = nil
					UIDropDownMenu_AddButton(info, level)
				elseif UIDROPDOWNMENU_MENU_VALUE == "alt" then
					if not enableAltsMenu then return end

					local db = Postal.char.BlackBook.alts
					local realm = GetRealmName()
					local faction = UnitFactionGroup("player")
					local player = UnitName("player")
					info.notCheckable = 1
					for i = 1, #db do
						local p, r, f = strsplit("|", db[i])
						if r == realm and f == faction and p ~= player then
							info.text = p
							info.func = Postal_BlackBook.SetSendMailName
							info.arg1 = p
							UIDropDownMenu_AddButton(info, level)
						end
					end

					info.disabled = 1
					info.text = nil
					info.func = nil
					info.arg1 = nil
					UIDropDownMenu_AddButton(info, level)
					info.disabled = nil

					info.text = DELETE
					info.hasArrow = 1
					info.keepShownOnClick = 1
					info.func = self.UncheckHack
					info.value = "deletealt"
					UIDropDownMenu_AddButton(info, level)
				elseif UIDROPDOWNMENU_MENU_VALUE == "friend" then
					local numFriends = GetNumFriends()
					for i = 1, numFriends do
						sorttable[i] = GetFriendInfo(i)
					end

					if BNGetNumFriends then -- For pre 3.3.5 backwards compat
						local numBNetTotal, numBNetOnline = BNGetNumFriends()
						for i = 1, numBNetOnline do
							local presenceID, givenName, surname, toonName, toonID, client = BNGetFriendInfo(i)
							if (toonName and client == BNET_CLIENT_WOW and CanCooperateWithToon(toonID)) then
								local alreadyOnList = false
								for j = 1, numFriends do
									if sorttable[j] == toonName then
										alreadyOnList = true
										break
									end
								end
								if not alreadyOnList then
									numFriends = numFriends + 1
									sorttable[numFriends] = toonName
								end
							end
						end
					end

					if numFriends == 0 then return end

					for i = #sorttable, numFriends + 1, -1 do
						sorttable[i] = nil
					end
					if not ignoresortlocale[GetLocale()] then
						tsort(sorttable)
					end

					numFriendsOnList = numFriends

					if numFriends > 0 and numFriends <= 25 then
						for i = 1, numFriends do
							local name = sorttable[i]
							info.text = name
							info.func = Postal_BlackBook.SetSendMailName
							info.arg1 = name
							UIDropDownMenu_AddButton(info, level)
						end
					elseif numFriends > 25 then
						info.hasArrow = 1
						info.keepShownOnClick = 1
						info.func = self.UncheckHack
						for i = 1, math.ceil(numFriends / 25) do
							info.text = L["Part %d"]:format(i)
							info.value = "fpart" .. i
							UIDropDownMenu_AddButton(info, level)
						end
					end
				elseif UIDROPDOWNMENU_MENU_VALUE == "guild" then
					if not IsInGuild() then return end

					local numFriends = GetNumGuildMembers(true)
					for i = 1, numFriends do
						local name, rank = GetGuildRosterInfo(i)
						sorttable[i] = name .. " |cffffd200(" .. rank .. ")|r"
					end
					for i = #sorttable, numFriends + 1, -1 do
						sorttable[i] = nil
					end
					if not ignoresortlocale[GetLocale()] then
						tsort(sorttable)
					end
					if numFriends > 0 and numFriends <= 25 then
						for i = 1, numFriends do
							info.text = sorttable[i]
							info.func = Postal_BlackBook.SetSendMailName
							info.arg1 = strmatch(sorttable[i], "(.*) |cffffd200")
							UIDropDownMenu_AddButton(info, level)
						end
					elseif numFriends > 25 then
						info.hasArrow = 1
						info.keepShownOnClick = 1
						info.func = self.UncheckHack
						for i = 1, math.ceil(numFriends / 25) do
							info.text = L["Part %d"]:format(i)
							info.value = "gpart" .. i
							UIDropDownMenu_AddButton(info, level)
						end
					end
				end
			elseif level == 3 then
				info.notCheckable = 1
				if UIDROPDOWNMENU_MENU_VALUE == "deletealt" then
					local db = Postal.char.BlackBook.alts
					local realm = GetRealmName()
					local faction = UnitFactionGroup("player")
					local player = UnitName("player")
					for i = 1, #db do
						local p, r, f = strsplit("|", db[i])
						if r == realm and f == faction and p ~= player then
							info.text = p
							info.func = Postal_BlackBook.DeleteAlt
							info.arg1 = db[i]
							UIDropDownMenu_AddButton(info, level)
						end
					end
				elseif strfind(UIDROPDOWNMENU_MENU_VALUE, "fpart") then
					local startIndex = tonumber(strmatch(UIDROPDOWNMENU_MENU_VALUE, "fpart(%d+)")) * 25 - 24
					local endIndex = math.min(startIndex + 24, numFriendsOnList)
					for i = startIndex, endIndex do
						local name = sorttable[i]
						info.text = name
						info.func = Postal_BlackBook.SetSendMailName
						info.arg1 = name
						UIDropDownMenu_AddButton(info, level)
					end
				elseif strfind(UIDROPDOWNMENU_MENU_VALUE, "gpart") then
					local startIndex = tonumber(strmatch(UIDROPDOWNMENU_MENU_VALUE, "gpart(%d+)")) * 25 - 24
					local endIndex = math.min(startIndex + 24, GetNumGuildMembers(true))
					for i = startIndex, endIndex do
						local name = sorttable[i]
						info.text = sorttable[i]
						info.func = Postal_BlackBook.SetSendMailName
						info.arg1 = strmatch(sorttable[i], "(.*) |cffffd200")
						UIDropDownMenu_AddButton(info, level)
					end
				end
			end
		end

		function Postal_BlackBook.SaveFriendGuildOption(dropdownbutton, arg1, arg2, checked)
			Postal.SaveOption(dropdownbutton, arg1, arg2, checked)
			local db = Postal.char.BlackBook
			local exclude = bit.bor(db.AutoCompleteFriends and AUTOCOMPLETE_FLAG_NONE or AUTOCOMPLETE_FLAG_FRIEND, db.AutoCompleteGuild and AUTOCOMPLETE_FLAG_NONE or AUTOCOMPLETE_FLAG_IN_GUILD)
			Postal_BlackBook_Autocomplete_Flags.include = bit.bxor(db.ExcludeRandoms and (bit.bor(AUTOCOMPLETE_FLAG_FRIEND, AUTOCOMPLETE_FLAG_IN_GUILD)) or AUTOCOMPLETE_FLAG_ALL, exclude)
		end

		function Postal_BlackBook.SetAutoComplete(dropdownbutton, arg1, arg2, checked)
			local self = Postal_BlackBook
			Postal.char.BlackBook.UseAutoComplete = not checked
			if checked then
				if self:IsHooked(SendMailNameEditBox, "OnChar") then
					self:Unhook(SendMailNameEditBox, "OnChar")
				end
			else
				if not self:IsHooked(SendMailNameEditBox, "OnChar") then
					self:RawHookScript(SendMailNameEditBox, "OnChar")
				end
			end
		end

		function Postal_BlackBook.ModuleMenu(self, level)
			if not level then return end
			local info = self.info
			wipe(info)
			if level == 1 + self.levelAdjust then
				info.keepShownOnClick = 1
				info.text = L["Autofill last person mailed"]
				info.func = Postal.SaveOption
				info.arg1 = "BlackBook"
				info.arg2 = "AutoFill"
				info.checked = Postal.char.BlackBook.AutoFill
				UIDropDownMenu_AddButton(info, level)

				info.hasArrow = 1
				info.keepShownOnClick = 1
				info.func = self.UncheckHack
				info.checked = nil
				info.arg1 = nil
				info.arg2 = nil
				info.text = L["Name auto-completion options"]
				info.value = "AutoComplete"
				UIDropDownMenu_AddButton(info, level)
			elseif level == 2 + self.levelAdjust then
				local db = Postal.char.BlackBook
				info.arg1 = "BlackBook"

				if UIDROPDOWNMENU_MENU_VALUE == "AutoComplete" then
					info.text = L["Use Postal's auto-complete"]
					info.arg2 = "UseAutoComplete"
					info.checked = db.UseAutoComplete
					info.func = Postal_BlackBook.SetAutoComplete
					UIDropDownMenu_AddButton(info, level)

					info.func = Postal.SaveOption
					info.disabled = not db.UseAutoComplete
					info.keepShownOnClick = 1

					info.text = L["Alts"]
					info.arg2 = "AutoCompleteAlts"
					info.checked = db.AutoCompleteAlts
					UIDropDownMenu_AddButton(info, level)

					info.text = L["Recently Mailed"]
					info.arg2 = "AutoCompleteRecent"
					info.checked = db.AutoCompleteRecent
					UIDropDownMenu_AddButton(info, level)

					info.text = FRIENDS
					info.arg2 = "AutoCompleteContacts"
					info.checked = db.AutoCompleteContacts
					UIDropDownMenu_AddButton(info, level)

					info.disabled = nil

					info.text = FRIEND
					info.arg2 = "AutoCompleteFriends"
					info.checked = db.AutoCompleteFriends
					info.func = Postal_BlackBook.SaveFriendGuildOption
					UIDropDownMenu_AddButton(info, level)

					info.text = GUILD
					info.arg2 = "AutoCompleteGuild"
					info.checked = db.AutoCompleteGuild
					UIDropDownMenu_AddButton(info, level)

					info.text = L["Exclude randoms you interacted with"]
					info.arg2 = "ExcludeRandoms"
					info.checked = db.ExcludeRandoms
					UIDropDownMenu_AddButton(info, level)

					info.text = L["Disable Blizzard's auto-completion popup menu"]
					info.arg2 = "DisableBlizzardAutoComplete"
					info.checked = db.DisableBlizzardAutoComplete
					info.func = Postal.SaveOption
					UIDropDownMenu_AddButton(info, level)
				end
			end
		end

		Postal.modules.BlackBook = Postal_BlackBook
	end

	---------------------------------------------------------------------------
	-- TradeBlock
	-- Block incoming trade requests while in a mail session.

	do
		local Postal_TradeBlock = {}

		function Postal_TradeBlock:OnEnable()
			Postal.RegisterEvent(Postal_TradeBlock, "MAIL_SHOW", "MailShow")
		end

		function Postal_TradeBlock:OnDisable()
			SetCVar("BlockTrades", 0)
			ClosePetition()
			PetitionFrame:RegisterEvent("PETITION_SHOW")
		end

		function Postal_TradeBlock:MailShow()
			PetitionFrame:UnregisterEvent("PETITION_SHOW")
			if IsAddOnLoaded("Lexan") then
				return
			end
			if GetCVar("BlockTrades") == "0" then
				Postal.RegisterEvent(Postal_TradeBlock, "MAIL_CLOSED", "Reset")
				Postal.RegisterEvent(Postal_TradeBlock, "PLAYER_LEAVING_WORLD", "Reset")
				SetCVar("BlockTrades", 1)
			end
		end

		function Postal_TradeBlock:Reset()
			Postal.UnregisterEvent(Postal_TradeBlock, "MAIL_CLOSED")
			Postal.UnregisterEvent(Postal_TradeBlock, "PLAYER_LEAVING_WORLD")
			SetCVar("BlockTrades", 0)
			ClosePetition()
			CloseTrade()
			PetitionFrame:RegisterEvent("PETITION_SHOW")
		end

		Postal.modules.TradeBlock = Postal_TradeBlock
	end
end)