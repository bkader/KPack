local core = KPack
if not core then return end
core:AddModule("ChatMods", "Adds several tweaks to chat windows, such us removing buttons, mousewheel scroll, copy chat and clickable links.", function(L)
	if core:IsDisabled("ChatMods") or core.ElvUI then return end

	local mod = core.ChatMods or CreateFrame("Frame")
	mod:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)

	core.ChatMods = mod

	local defaults = {
		enabled = true,
		editbox = "top"
	}

	local DB, SetupDatabase, disabled
	local gsub, format = string.gsub, string.format

	local function Print(msg)
		if msg then
			core:Print(msg, "ChatMods")
		end
	end

	local ChatMods_Initialize
	local SlashCommandHandler
	do
		local exec = {}
		local help = "|cffffd700%s|r: %s"

		-- toggle module
		exec.toggle = function()
			DB.enabled = not DB.enabled
			Print(DB.enabled and L["|cff00ff00enabled|r"] or L["|cffff0000disabled|r"])
		end

		-- center editBox
		exec.editbox = function(rest)
			rest = rest and rest:lower():trim() or ""
			if rest == "top" or rest == "bottom" or rest == "middle" then
				DB.editbox = rest
				Print(L:F("editbox position set to: |cff00ffff%s|r", rest))
			else
				Print(L:F("Acceptable commands for: |caaf49141%s|r", "/cm editbox"))
				print("|cffffd700middle|r : ", L["put the editbox in the middle of the screen."])
				print("|cffffd700top|r : ", L["put the editbox on top of the chat frame."])
				print("|cffffd700bottom|r : ", L["put the editbox at the bottom of the chat frame."])
			end
		end

		-- reset to default
		exec.reset = function()
			wipe(DB)
			DB = defaults
			Print(L["module's settings reset to default."])
		end
		exec.default = exec.reset

		function SlashCommandHandler(msg)
			local cmd, rest = strsplit(" ", msg, 2)
			if type(exec[cmd]) == "function" then
				exec[cmd](rest)
				ChatMods_Initialize()
			else
				Print(L:F("Acceptable commands for: |caaf49141%s|r", "/cm"))
				print("|cffffd700toggle|r : ", L["Turns module |cff00ff00ON|r or |cffff0000OFF|r."])
				print("|cffffd700editbox|r : ", L["toggles chat editbox position."])
				print("|cffffd700reset|r : ", L["Resets module settings to default."])
			end
		end
	end

	-- :::::::::::::::::::::::::::::::::::::::::::::
	-- Button Hiding/Moving
	-- :::::::::::::::::::::::::::::::::::::::::::::

	local ChatMods_ChatFrame

	do
		local noFunc = function(f)
			if f then
				f:Hide()
			end
		end

		--Scroll to the bottom button
		local function ChatMods_ScrollToBottom(self)
			self:GetParent():ScrollToBottom()
		end

		function ChatMods_ChatFrame()
			ChatFrameMenuButton:Hide()
			ChatFrameMenuButton:SetScript("OnShow", noFunc)
			FriendsMicroButton:Hide()
			FriendsMicroButton:SetScript("OnShow", noFunc)

			for i = 1, 10 do
				local cf = _G[format("%s%d", "ChatFrame", i)]

				if i == 2 then
					cf:SetJustifyH("RIGHT")
				end

				--fix fading
				local tab = _G["ChatFrame" .. i .. "Tab"]
				tab:SetAlpha(1)
				tab.noMouseAlpha = .25
				cf:SetFading(true)

				--Unlimited chatframes resizing
				cf:SetMinResize(0, 0)
				cf:SetMaxResize(0, 0)

				--Allow the chat frame to move to the end of the screen
				cf:SetClampedToScreen(true)
				cf:SetClampRectInsets(0, 0, 0, 0)

				--EditBox Module
				local ebParts = {"Left", "Mid", "Right"}
				for _, ebPart in ipairs(ebParts) do
					_G["ChatFrame" .. i .. "EditBox" .. ebPart]:SetTexture(0, 0, 0, 0)
					local ebed = _G["ChatFrame" .. i .. "EditBoxFocus" .. ebPart]
					ebed:SetTexture(0, 0, 0, 0.8)
					ebed:SetHeight(18)
				end

				--Remove scroll buttons
				local bf = _G["ChatFrame" .. i .. "ButtonFrame"]
				bf:Hide()
				bf:SetScript("OnShow", noFunc)

				local bb = _G["ChatFrame" .. i .. "ButtonFrameBottomButton"]
				bb:SetParent(_G["ChatFrame" .. i])
				bb:SetHeight(18)
				bb:SetWidth(18)
				bb:ClearAllPoints()
				bb:SetPoint("TOPRIGHT", cf, "TOPRIGHT", 0, -6)
				bb:SetAlpha(0.4)
				bb.SetPoint = function()
				end
				bb:SetScript("OnClick", ChatMods_ScrollToBottom)
			end
			BNToastFrame:SetClampedToScreen(true)
		end
	end

	local function ChatMods_EditBox()
		for i = 1, 10 do
			local cf = _G["ChatFrame" .. i]
			local eb = _G["ChatFrame" .. i .. "EditBox"]

			eb:SetAltArrowKeyMode(false)
			eb:ClearAllPoints()
			eb:EnableMouse(false)

			if DB.editbox == "middle" then
				eb:SetPoint("BOTTOMLEFT", UIParent, "BOTTOM", -200, 180)
				eb:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOM", 200, 180)
			elseif DB.editbox == "top" then
				eb:SetPoint("BOTTOMLEFT", cf, "TOPLEFT", 2, 20)
				eb:SetPoint("BOTTOMRIGHT", cf, "TOPRIGHT", -2, 20)
			else
				eb:SetPoint("TOPLEFT", cf, "BOTTOMLEFT")
				eb:SetPoint("TOPRIGHT", cf, "BOTTOMRIGHT")
			end
		end
	end

	-- :::::::::::::::::::::::::::::::::::::::::::::
	-- Tell Target
	-- :::::::::::::::::::::::::::::::::::::::::::::

	local ChatMods_TellTarget
	do
		local UnitExists, UnitIsFriend = UnitExists, UnitIsFriend
		local UnitName, UnitIsSameServer = UnitName, UnitIsSameServer

		function ChatMods_TellTarget(msg)
			if not UnitExists("target") then
				return
			end
			if not (msg and msg:len() > 0) then
				return
			end
			if not UnitIsFriend("player", "target") then
				return
			end
			local name, realm = UnitName("target")
			if realm and not UnitIsSameServer("player", "target") then
				name = ("%s-%s"):format(name, realm)
			end
			SendChatMessage(msg, "WHISPER", nil, name)
		end
	end

	-- :::::::::::::::::::::::::::::::::::::::::::::
	-- Scroll module
	-- :::::::::::::::::::::::::::::::::::::::::::::

	local function ChatMods_FloatingChatFrame_OnMouseScroll(self, dir)
		if dir > 0 then
			if IsShiftKeyDown() then
				self:ScrollToTop()
			elseif IsControlKeyDown() then
				self:ScrollUp()
				self:ScrollUp()
			end
		elseif dir < 0 then
			if IsShiftKeyDown() then
				self:ScrollToBottom()
			elseif IsControlKeyDown() then
				self:ScrollDown()
				self:ScrollDown()
			end
		end
	end

	-- :::::::::::::::::::::::::::::::::::::::::::::
	-- Enable/Disable mouse for editbox
	-- :::::::::::::::::::::::::::::::::::::::::::::

	local function ChatMods_ChatFrame_OpenChat()
		for i = 1, 10 do
			local box = _G["ChatFrame" .. i .. "EditBox"]
			box:EnableMouse(true)
		end
	end

	local function ChatMods_ChatEdit_SendText()
		for i = 1, 10 do
			local box = _G["ChatFrame" .. i .. "EditBox"]
			box:EnableMouse(false)
		end
	end

	-- :::::::::::::::::::::::::::::::::::::::::::::
	-- Show link tooltips on hover
	-- :::::::::::::::::::::::::::::::::::::::::::::

	local LinkHover = {
		show = {
			achievement = true,
			enchant = true,
			glyph = true,
			item = true,
			quest = true,
			spell = true,
			talent = true,
			unit = true
		}
	}

	LinkHover.OnHyperlinkEnter = function(self, data, link)
		local t = data:match("^(.-):")
		if LinkHover.show[t] and IsAltKeyDown() then
			ShowUIPanel(GameTooltip)
			GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
			GameTooltip:SetHyperlink(link)
			GameTooltip:Show()
		end
	end

	LinkHover.OnHyperlinkLeave = function(self, data, link)
		local t = data:match("^(.-):")
		if LinkHover.show[t] then
			HideUIPanel(GameTooltip)
		end
	end

	local function ChatMods_LinkHover()
		for i = 1, NUM_CHAT_WINDOWS do
			local frame = _G["ChatFrame" .. i]
			if frame then
				frame:SetScript("OnHyperlinkEnter", LinkHover.OnHyperlinkEnter)
				frame:SetScript("OnHyperlinkLeave", LinkHover.OnHyperlinkLeave)
			end
		end
	end

	-- :::::::::::::::::::::::::::::::::::::::::::::
	-- Filter message when DND or AFK
	-- :::::::::::::::::::::::::::::::::::::::::::::

	local ChatMods_CHAT_MSG_AFK
	do
		local data = {}
		function ChatMods_ChatEvent(arg1, arg2)
			if data[arg2] and data[arg2] == arg1 then
				return true
			end
			data[arg2] = arg1
		end
	end

	-- :::::::::::::::::::::::::::::::::::::::::::::
	-- URL detection and copy
	-- :::::::::::::::::::::::::::::::::::::::::::::

	local ChatMobs_AddMessageEventFilters
	do
		local tlds = {
			"[Cc][Oo][Mm]",
			"[Uu][Kk]",
			"[Nn][Ee][Tt]",
			"[Dd][Ee]",
			"[Ff][Rr]",
			"[Ee][Ss]",
			"[Bb][Ee]",
			"[Cc][Cc]",
			"[Uu][Ss]",
			"[Kk][Oo]",
			"[Cc][Hh]",
			"[Tt][Ww]",
			"[Cc][Nn]",
			"[Rr][Uu]",
			"[Gg][Rr]",
			"[Gg][Gg]",
			"[Ii][Tt]",
			"[Ee][Uu]",
			"[Tt][Vv]",
			"[Nn][Ll]",
			"[Hh][Uu]",
			"[Oo][Rr][Gg]"
		}

		local function FilterFunction(self, event, msg, ...)
			for i = 1, 21 do --Number of TLD's in tlds table
				local newmsg, found = gsub(msg, "(%S-%." .. tlds[i] .. "/?%S*)", "|cffffffff|Hurl:%1|h[%1]|h|r")
				if found > 0 then
					return false, newmsg, ...
				end
			end

			local newmsg, found = gsub(msg, "(%d+%.%d+%.%d+%.%d+:?%d*/?%S*)", "|cffffffff|Hurl:%1|h[%1]|h|r")
			if found > 0 then
				return false, newmsg, ...
			end
		end

		function ChatMobs_AddMessageEventFilters()
			ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", FilterFunction)
			ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", FilterFunction)
			ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", FilterFunction)
			ChatFrame_AddMessageEventFilter("CHAT_MSG_OFFICER", FilterFunction)
			ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", FilterFunction)
			ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY_LEADER", FilterFunction)
			ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", FilterFunction)
			ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_LEADER", FilterFunction)
			ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", FilterFunction)
			ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", FilterFunction)
			ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_WHISPER", FilterFunction)
			ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_CONVERSATION", FilterFunction)

			local currentLink

			_G.ChatFrame_OnHyperlinkShow = function(self, link, text, button)
				if not StaticPopupDialogs["CHATMODS_URLCOPY_DIALOG"] then
					StaticPopupDialogs["CHATMODS_URLCOPY_DIALOG"] = {
						text = "URL",
						button2 = TEXT(CLOSE),
						hasEditBox = 1,
						hasWideEditBox = 1,
						showAlert = 1,
						OnShow = function(frame)
							local editBox = _G[frame:GetName() .. "WideEditBox"]
							editBox:SetText(currentLink)
							currentLink = nil
							editBox:SetFocus()
							editBox:HighlightText(0)
							local button = _G[frame:GetName() .. "Button2"]
							button:ClearAllPoints()
							button:SetWidth(200)
							button:SetPoint("CENTER", editBox, "CENTER", 0, -30)
							_G[frame:GetName() .. "AlertIcon"]:Hide()
						end,
						EditBoxOnEscapePressed = function(frame)
							frame:GetParent():Hide()
						end,
						timeout = 0,
						whileDead = 1,
						hideOnEscape = 1
					}
				end

				if (link):sub(1, 3) == "url" then
					currentLink = (link):sub(5)
					StaticPopup_Show("CHATMODS_URLCOPY_DIALOG")
					return
				end

				SetItemRef(link, text, button, self)
			end
		end
	end

	-- :::::::::::::::::::::::::::::::::::::::::::::
	-- Channels Names
	-- :::::::::::::::::::::::::::::::::::::::::::::

	local ChatMods_ChatCopy

	do
		local lines, frame

		local function ChatMods_CreateCopyFrame()
			frame = CreateFrame("Frame", "KPack_ChatModsCopyFrame", UIParent)
			frame:SetBackdrop({
				bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
				edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
				tile = true,
				tileSize = 16,
				edgeSize = 16,
				insets = {left = 3, right = 3, top = 5, bottom = 3}
			})
			frame:SetBackdropColor(0, 0, 0, 1)
			frame:SetWidth(500)
			frame:SetHeight(400)
			frame:SetPoint("CENTER", UIParent, "CENTER")
			frame:Hide()
			frame:SetFrameStrata("DIALOG")

			local scrollArea = CreateFrame("ScrollFrame", "ChatModsCopyScroll", frame, "UIPanelScrollFrameTemplate")
			scrollArea:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -30)
			scrollArea:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 8)

			local editBox = CreateFrame("EditBox", "ChatModsCopyBox", frame)
			editBox:SetMultiLine(true)
			editBox:SetMaxLetters(99999)
			editBox:EnableMouse(true)
			editBox:SetAutoFocus(false)
			editBox:SetFontObject(ChatFontNormal)
			editBox:SetWidth(400)
			editBox:SetHeight(270)
			editBox:SetScript("OnEscapePressed", function(self)
				self:GetParent():GetParent():Hide()
				self:SetText("")
			end)
			scrollArea:SetScrollChild(editBox)

			local close = CreateFrame("Button", "ChatModsCloseButton", frame, "UIPanelCloseButton")
			close:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
			tinsert(UISpecialFrames, "KPack_ChatModsCopyFrame")
		end

		local ChatMods_CopyFunc = function(frame, button)
			local cf = _G[format("%s%d", "ChatFrame", frame:GetID())]
			local _, size = cf:GetFont()
			FCF_SetChatWindowFontSize(cf, cf, 0.01)

			lines = core.newTable()
			local ct = 1
			for i = select("#", cf:GetRegions()), 1, -1 do
				local region = select(i, cf:GetRegions())
				if region:GetObjectType() == "FontString" then
					lines[ct] = tostring(region:GetText())
					ct = ct + 1
				end
			end

			local lineCt = ct - 1
			local text = table.concat(lines, "\n", 1, lineCt)
			FCF_SetChatWindowFontSize(cf, cf, size)
			_G.KPack_ChatModsCopyFrame:Show()
			_G.ChatModsCopyBox:SetText(text)
			_G.ChatModsCopyBox:HighlightText(0)
			core.delTable(lines)
		end

		local ChatMods_HintFunc = function(frame, button)
			GameTooltip:SetOwner(frame, "ANCHOR_TOP")
			if SHOW_NEWBIE_TIPS == "1" then
				GameTooltip:AddLine(CHAT_OPTIONS_LABEL, 1, 1, 1)
				GameTooltip:AddLine(NEWBIE_TOOLTIP_CHATOPTIONS, nil, nil, nil, 1)
			end
			GameTooltip:AddLine((SHOW_NEWBIE_TIPS == "1" and "\n" or "") .. "Double-Click to Copy")
			GameTooltip:Show()
		end

		function ChatMods_ChatCopy()
			if not frame then
				ChatMods_CreateCopyFrame()
			end

			for i = 1, 10 do
				local tab = _G[format("%s%d%s", "ChatFrame", i, "Tab")]
				if tab then
					tab:SetScript("OnDoubleClick", ChatMods_CopyFunc)
					tab:SetScript("OnEnter", ChatMods_HintFunc)
				end
			end
		end
	end

	-- :::::::::::::::::::::::::::::::::::::::::::::
	-- Event Handler
	-- :::::::::::::::::::::::::::::::::::::::::::::

	function SetupDatabase()
		if DB then return end
		if type(core.db.ChatMods) ~= "table" or not next(core.db.ChatMods) then
			core.db.ChatMods = CopyTable(defaults)
		end
		DB = core.db.ChatMods
	end

	core:RegisterForEvent("PLAYER_LOGIN", function()
		SetupDatabase()
		disabled = (_G.Chatter or _G.Prat or _G.ElvUI)

		if not disabled then
			SlashCmdList["KPACKCHATMODS"] = SlashCommandHandler
			SLASH_KPACKCHATMODS1 = "/cm"
			SLASH_KPACKCHATMODS2 = "/chatmods"

			if not DB.enabled then return end

			-- :::::::::::::::::::::::::::::::::::::::::::::
			-- Sticky Channels & Fading Alpha
			-- :::::::::::::::::::::::::::::::::::::::::::::

			ChatTypeInfo.BN_WHISPER.sticky = 0
			ChatTypeInfo.EMOTE.sticky = 0
			ChatTypeInfo.OFFICER.sticky = 1
			ChatTypeInfo.RAID_WARNING.sticky = 0
			ChatTypeInfo.WHISPER.sticky = 1
			ChatTypeInfo.YELL.sticky = 0

			_G.CHAT_FRAME_TAB_NORMAL_NOMOUSE_ALPHA = 0
			_G.CHAT_FRAME_TAB_SELECTED_NOMOUSE_ALPHA = 0

			-- -- :::::::::::::::::::::::::::::::::::::::::::::
			-- -- Timestamp Customize
			-- -- :::::::::::::::::::::::::::::::::::::::::::::

			-- _G.TIMESTAMP_FORMAT_HHMM="|r|cff999999[%I:%M]|r "
			-- _G.TIMESTAMP_FORMAT_HHMM_24HR="|r|cff999999[%H:%M]|r "
			-- _G.TIMESTAMP_FORMAT_HHMM_AMPM="|r|cff999999[%I:%M %p]|r "

			-- _G.TIMESTAMP_FORMAT_HHMMSS="|r|cff999999[%I:%M:%S]|r "
			-- _G.TIMESTAMP_FORMAT_HHMMSS_24HR="|r|cff999999[%H:%M:%S]|r "
			-- _G.TIMESTAMP_FORMAT_HHMMSS_AMPM="|r|cff999999[%I:%M:%S %p]|r "

			-- Tell Target Command!
			SlashCmdList["KPACKTELLTARGET"] = ChatMods_TellTarget
			SLASH_KPACKTELLTARGET1 = "/tt"
			SLASH_KPACKTELLTARGET2 = "/ее"	-- only for ruRU locale
			SLASH_KPACKTELLTARGET3 = "/wt"

			hooksecurefunc("FloatingChatFrame_OnMouseScroll", ChatMods_FloatingChatFrame_OnMouseScroll)
			mod:RegisterEvent("PLAYER_ENTERING_WORLD")
		end
	end)

	-- :::::::::::::::::::::::::::::::::::::::::::::

	ChatMods_Initialize = function()
		hooksecurefunc("ChatFrame_OpenChat", ChatMods_ChatFrame_OpenChat)
		hooksecurefunc("ChatEdit_SendText", ChatMods_ChatEdit_SendText)

		ChatMods_LinkHover()

		ChatFrame_AddMessageEventFilter("CHAT_MSG_AFK", ChatMods_ChatEvent)
		ChatFrame_AddMessageEventFilter("CHAT_MSG_DND", ChatMods_ChatEvent)
		ChatMobs_AddMessageEventFilters()
		ChatMods_ChatCopy()
		ChatMods_ChatFrame()
		ChatMods_EditBox()
	end

	function mod:PLAYER_ENTERING_WORLD()
		SetupDatabase()
		if not disabled and DB.enabled then
			ChatMods_Initialize()
		end
	end
end)