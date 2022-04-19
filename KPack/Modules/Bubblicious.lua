local core = KPack
if not core then return end
core:AddModule("Bubblicious", "Chat bubble related customizations.", function(L)
	if core:IsDisabled("Bubblicious") then return end

	local Bubblicious = CreateFrame("Frame")
	Bubblicious:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
	core.Bubblicious = Bubblicious

	local gmatch, gsub, lower = string.gmatch, string.gsub, string.lower
	local min, max, select = math.min, math.max, select

	local disabled, reason, options
	local defaults = {
		enabled = true,
		shorten = false,
		color = true,
		icons = true,
		font = true,
		fontsize = 14
	}

	local MAX_CHATBUBBLE_WIDTH = 300
	local ICON_LIST = ICON_LIST
	local ICON_TAG_LIST = ICON_TAG_LIST
	local ICON_LIST_LOCALIZED = {
		-- deDE
		["stern"] = "rt1",
		["kreis"] = "rt2",
		["diamant"] = "rt3",
		["dreieck"] = "rt4",
		["mond"] = "rt5",
		["quadrat"] = "rt6",
		["kreuz"] = "rt7",
		["totenschädel"] = "rt8",
		-- enUS
		["star"] = "rt1",
		["circle"] = "rt2",
		["diamond"] = "rt3",
		["triangle"] = "rt4",
		["moon"] = "rt5",
		["square"] = "rt6",
		["cross"] = "rt7",
		["skull"] = "rt8",
		-- esES/esMX
		["estrella"] = "rt1",
		["círculo"] = "rt2",
		["circulo"] = "rt2",
		["diamante"] = "rt3",
		["triángulo"] = "rt4",
		["triangulo"] = "rt4",
		["luna"] = "rt5",
		["cuadrado"] = "rt6",
		["cruz"] = "rt7",
		["calavera"] = "rt8",
		-- frFR
		["étoile"] = "rt1",
		["etoile"] = "rt1",
		["cercle"] = "rt2",
		["losange"] = "rt3",
		["lune"] = "rt5",
		["carré"] = "rt6",
		["carre"] = "rt6",
		["croix"] = "rt7",
		["crâne"] = "rt8",
		["crane"] = "rt8",
		-- koKR
		["별"] = "rt1",
		["동그라미"] = "rt2",
		["다이아몬드"] = "rt3",
		["세모"] = "rt4",
		["달"] = "rt5",
		["네모"] = "rt6",
		["가위표"] = "rt7",
		["해골"] = "rt8",
		-- ruRU
		["звезда"] = "rt1",
		["круг"] = "rt2",
		["ромб"] = "rt3",
		["треугольник"] = "rt4",
		["полумесяц"] = "rt5",
		["квадрат"] = "rt6",
		["крест"] = "rt7",
		["череп"] = "rt8",
		-- zhCN
		["星形"] = "rt1",
		["圆形"] = "rt2",
		["菱形"] = "rt3",
		["三角"] = "rt4",
		["月亮"] = "rt5",
		["方块"] = "rt6",
		["十字"] = "rt7",
		["骷髅"] = "rt8",
		-- zhTW
		["星星"] = "rt1",
		["圈圈"] = "rt2",
		["鑽石"] = "rt3",
		["方形"] = "rt6",
		["頭顱"] = "rt8",
		-- Just in case locales
		-- itIT
		["stella"] = "rt1",
		["cerchio"] = "rt2",
		["rombo"] = "rt3",
		["triangolo"] = "rt4",
		["quadrato"] = "rt6",
		["croce"] = "rt7",
		["teschio"] = "rt8",
		-- petBR
		["estrela"] = "rt1",
		["triângulo"] = "rt4",
		["lua"] = "rt5",
		["quadrado"] = "rt6",
		["xis"] = "rt7",
		["caveira"] = "rt8"
	}

	function Bubblicious:SetupDatabase()
		if not self.db then
			if type(core.db.Bubblicious) ~= "table" or next(core.db.Bubblicious) == nil then
				core.db.Bubblicious = CopyTable(defaults)
			end
			self.db = core.db.Bubblicious
		end
	end

	function Bubblicious:GetValue(info)
		return self.db[info[#info]]
	end

	function Bubblicious:SetValue(info, value)
		self.db[info[#info]] = value
		self:PLAYER_ENTERING_WORLD()
	end

	function Bubblicious:GetOptions()
		if not options then
			options = {
				handler = self,
				type = "group",
				name = "Bubblicious",
				get = "GetValue",
				set = "SetValue",
				args = {
					status = {
						type = "description",
						name = L:F("This module is disabled because you are using: |cffffd700%s|r", reason or UNKNOWN),
						fontSize = "medium",
						order = 0,
						hidden = not disabled
					},
					enabled = {
						type = "toggle",
						name = L["Enabled"],
						order = 1,
						disabled = disabled
					},
					reset = {
						type = "execute",
						name = RESET,
						order = 2,
						disabled = function()
							return not Bubblicious.db.enabled or disabled
						end,
						confirm = function()
							return L:F("Are you sure you want to reset %s to default?", "Bubblicious")
						end,
						func = function()
							wipe(core.db.Bubblicious)
							Bubblicious.db = nil
							Bubblicious:SetupDatabase()
							core:Print(L["module's settings reset to default."], "Bubblicious")
						end
					},
					params = {
						type = "group",
						name = L["Appearance"],
						inline = true,
						order = 3,
						disabled = function()
							return not Bubblicious.db.enabled or disabled
						end,
						args = {
							shorten = {
								type = "toggle",
								name = L["Shorten Bubbles"],
								desc = L["Shorten the chat bubbles down to a single line each. Mouse over the bubble to expand the text."],
								order = 1
							},
							color = {
								type = "toggle",
								name = L["Color Bubbles"],
								desc = L["Color the chat bubble border the same as the chat type."],
								order = 2
							},
							icons = {
								type = "toggle",
								name = L["Show Raid Icons"],
								desc = L["Show raid icons in the chat bubbles."],
								order = 3
							},
							font = {
								type = "toggle",
								name = L["Use Chat Font"],
								desc = L["Use the same font you are using on the chatframe."],
								order = 4
							},
							fontsize = {
								type = "range",
								name = L["Font Size"],
								desc = L["Set the chat bubble font size."],
								order = 5,
								width = "double",
								min = 8,
								max = 32,
								step = 1
							}
						}
					}
				}
			}
		end
		return options
	end

	core:RegisterForEvent("PLAYER_LOGIN", function()
		Bubblicious:SetupDatabase()
		disabled, reason = core:AddOnIsLoaded("Prat", "Bubblicious")

		core.options.args.Options.args.Bubblicious = Bubblicious:GetOptions()

		if not disabled then
			SlashCmdList.KPACKBUBBLICIOUS = function()
				core:OpenConfig("Options", "Bubblicious")
			end
			SLASH_KPACKBUBBLICIOUS1 = "/bubble"
			SLASH_KPACKBUBBLICIOUS2 = "/bubbles"

			Bubblicious:RegisterEvent("PLAYER_ENTERING_WORLD")
		else
			Bubblicious:RestoreDefaults()
			Bubblicious:UnregisterAllEvents()
			Bubblicious:Hide()
		end
	end)

	function Bubblicious:PLAYER_ENTERING_WORLD()
		self:SetupDatabase()

		if not disabled and self.db and self.db.enabled then
			self.throttle = 0.1

			if self.db.shorten or self.db.color or self.db.icons or self.db.font then
				self:Show()
			else
				self:Hide()
			end

			self:SetScript("OnUpdate", function(self, elapsed)
				self.throttle = self.throttle - elapsed
				if self:IsShown() and self.throttle < 0 then
					self.throttle = 0.1
					self:FormatBubbles()
				end
			end)
		else
			self:RestoreDefaults()
			self:UnregisterAllEvents()
			self:SetScript("OnUpdate", nil)
			self:Hide()
		end
	end

	function Bubblicious:IterateChatBubbles(callback)
		for i = 1, WorldFrame:GetNumChildren() do
			local v = select(i, WorldFrame:GetChildren())
			local b = v:GetBackdrop()
			if b and b.bgFile == [[Interface\Tooltips\ChatBubble-Background]] then
				for j = 1, v:GetNumRegions() do
					local frame = v
					local w = select(j, v:GetRegions())
					if w:GetObjectType() == "FontString" then
						if type(callback) == "function" then
							callback(frame, w)
						else
							self[callback](self, frame, w)
						end
					end
				end
			end
		end
	end

	function Bubblicious:FormatBubbles()
		self:IterateChatBubbles("FormatCallback")
	end

	function Bubblicious:RestoreDefaults()
		self:Hide()
		self:IterateChatBubbles("RestoreDefaultsCallback")
	end

	function Bubblicious:FormatCallback(frame, fs)
		if not frame:IsShown() then
			fs.lastText = nil
			return
		end

		if self.db.shorten then
			local wrap = fs:CanWordWrap() or 0

			if frame:IsMouseOver() then
				fs:SetWordWrap(1)
			elseif wrap == 1 then
				fs:SetWordWrap(0)
			end
		end

		MAX_CHATBUBBLE_WIDTH = max(frame:GetWidth(), MAX_CHATBUBBLE_WIDTH)
		local text = fs:GetText() or ""

		if text == fs.lastText then
			if self.db.shorten then
				fs:SetWidth(fs:GetWidth())
			end
			return
		end

		if self.db.color then
			frame:SetBackdropBorderColor(fs:GetTextColor())
		end

		if self.db.font then
			fs:SetFont(ChatFrame1:GetFont(), self.db.fontsize, select(3, fs:GetFont()))
		end

		if self.db.icons then
			local term
			for tag in gmatch(text, "%b{}") do
				term = lower(gsub(tag, "[{}]", ""))
				term = ICON_LIST_LOCALIZED[term] or term
				if ICON_TAG_LIST[term] and ICON_LIST[ICON_TAG_LIST[term]] then
					text = gsub(text, tag, ICON_LIST[ICON_TAG_LIST[term]] .. "0|t")
				end
			end
		end

		fs:SetText(text)
		fs.lastText = text
		fs:SetWidth(min(fs:GetStringWidth(), MAX_CHATBUBBLE_WIDTH - 14))
	end

	function Bubblicious:RestoreDefaultsCallback(frame, fs)
		frame:SetBackdropBorderColor(1, 1, 1, 1)
		fs:SetWordWrap(1)
		fs:SetWidth(fs:GetWidth())
	end
end)