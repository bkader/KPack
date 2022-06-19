local core = KPack
if not core then return end
core:AddModule("Tooltip", "Enhanced tooltip.", function(L)
	if core:IsDisabled("Tooltip") or core.ElvUI then return end

	-- saved variables & defaults
	local DB
	local defaults = {
		unit = false,
		spell = false,
		petspell = false,
		class = false,
		enhance = true,
		scale = 1,
		moved = false,
		point = "TOP",
		xOfs = 0,
		yOfs = -25
	}
	local disabled

	-- cache frequently used globals
	local next, type, select, pairs = next, type, select, pairs
	local format, match = string.format, string.match
	local UnitPlayerControlled = UnitPlayerControlled
	local GetQuestDifficultyColor = GetQuestDifficultyColor
	local UnitClassification, UnitCreatureType = UnitClassification, UnitCreatureType
	local UnitIsPlayer, UnitExists = UnitIsPlayer, UnitExists
	local UnitName, UnitLevel, UnitRace, UnitClass = UnitName, UnitLevel, UnitRace, UnitClass
	local UnitReaction, UnitCanAttack, UnitIsPVP = UnitReaction, UnitCanAttack, UnitIsPVP
	local UnitHealth, UnitHealthMax = UnitHealth, UnitHealthMax
	local IsInGuild, GetGuildInfo = IsInGuild, GetGuildInfo

	-- needed locals
	local iconFrame, PLAYER_ENTERING_WORLD

	-- module's print function
	local function Print(msg)
		if msg then
			core:Print(msg, "Tooltip")
		end
	end

	local function SetupDatabase()
		if not DB then
			if type(core.char.Tooltip) ~= "table" or next(core.char.Tooltip) == nil then
				core.char.Tooltip = CopyTable(defaults)
			end
			DB = core.char.Tooltip
		end
	end

	do
		local function Tooltip_SetUnit()
			if DB.unit and core.InCombat then
				GameTooltip:Hide()
			end
		end

		local function Tooltip_SetAction()
			if DB.spell and core.InCombat then
				GameTooltip:Hide()
			end
		end

		local function Tooltip_SetPetAction()
			if DB.petspell and core.InCombat then
				GameTooltip:Hide()
			end
		end

		local function Tooltip_SetShapeshift()
			if DB.class and core.InCombat then
				GameTooltip:Hide()
			end
		end

		-- change game tooltip position
		local Tooltip_AnchorToMouse
		local function Tooltip_ChangePosition(tooltip, parent)
			if DB.moved then
				if DB.point == "CURSOR" then
					tooltip:SetOwner(parent, "ANCHOR_CURSOR")

					if not Tooltip_AnchorToMouse then
						Tooltip_AnchorToMouse = function(self)
							local x, y = GetCursorPosition()
							local s = self:GetEffectiveScale()
							self:ClearAllPoints()
							self:SetPoint("BOTTOM", UIParent, "BOTTOMLEFT", (x / s), (y / s))
						end
					end

					Tooltip_AnchorToMouse(tooltip)
				else
					tooltip:SetOwner(parent, "ANCHOR_NONE")
					tooltip:SetPoint(DB.point or "TOP", UIParent, DB.point or "TOP", DB.xOfs or 0, DB.yOfs or -25)
				end
				tooltip.default = 1
			end
		end

		core:RegisterForEvent("PLAYER_LOGIN", function()
			SetupDatabase()

			if _G.Aurora or _G.KkthnxUI then
				disabled = true
				return
			end

			SLASH_KPACK_TOOLTIP1 = "/tip"
			SLASH_KPACK_TOOLTIP2 = "/tooltip"
			SlashCmdList["KPACK_TOOLTIP"] = function()
				core:OpenConfig("Options", "Tooltip")
			end

			hooksecurefunc(GameTooltip, "SetUnit", Tooltip_SetUnit)
			hooksecurefunc(GameTooltip, "SetAction", Tooltip_SetAction)
			hooksecurefunc(GameTooltip, "SetPetAction", Tooltip_SetPetAction)
			hooksecurefunc(GameTooltip, "SetShapeshift", Tooltip_SetShapeshift)
			hooksecurefunc("GameTooltip_SetDefaultAnchor", Tooltip_ChangePosition)

			core.options.args.Options.args.Tooltip = {
				type = "group",
				name = L["Tooltips"],
				get = function(i) return DB[i[#i]] end,
				set = function(i, val)
					DB[i[#i]] = val
					PLAYER_ENTERING_WORLD()
				end,
				args = {
					enhance = {
						type = "toggle",
						name = L["Enhanced Tooltips"],
						desc = L["Enable this if you want the change the style of tooltips."],
						order = 1
					},
					scale = {
						type = "range",
						name = L["Scale"],
						order = 2,
						min = 0.5,
						max = 3,
						step = 0.01,
						bigStep = 0.1
					},
					movetip = {
						type = "header",
						name = L["Move Tooltips"],
						order = 3
					},
					moved = {
						type = "toggle",
						name = L["Enable"],
						desc = L["Enable this if you want to change default tooltip position."],
						order = 4
					},
					point = {
						type = "select",
						name = L["Position"],
						order = 5,
						values = {
							TOPLEFT = L["Top Left"],
							TOPRIGHT = L["Top Right"],
							TOP = L["Top"],
							BOTTOMLEFT = L["Bottom Left"],
							BOTTOMRIGHT = L["Bottom Right"],
							BOTTOM = L["Bottom"],
							LEFT = L["Left"],
							RIGHT = L["Right"],
							CENTER = L["Center"],
							CURSOR = L["At Cursor"],
						}
					},
					xOfs = {
						type = "range",
						name = L["X Offset"],
						order = 6,
						min = -350,
						max = 350,
						step = 0.1,
						bigStep = 1
					},
					yOfs = {
						type = "range",
						name = L["Y Offset"],
						order = 7,
						min = -350,
						max = 350,
						step = 0.1,
						bigStep = 1
					},
					hideincombat = {
						type = "header",
						name = L["Hide in combat"],
						order = 8
					},
					unit = {
						type = "toggle",
						name = L["Unit"],
						desc = L["Hides unit tooltips in combat."],
						order = 9
					},
					spell = {
						type = "toggle",
						name = L["Action Bar"],
						desc = L["Hides your action bar spell tooltips in combat."],
						order = 10
					},
					petspell = {
						type = "toggle",
						name = L["Pet Bar"],
						desc = L["Hides your pet action bar spell tooltips in combat."],
						order = 12
					},
					class = {
						type = "toggle",
						name = L["Class Bar"],
						desc = L["Hides stance/shape bar tooltips in combat."],
						order = 13
					},
					sep = {
						type = "description",
						name = " ",
						order = 14,
						width = "full"
					},
					reset = {
						type = "execute",
						name = RESET,
						order = 99,
						width = "full",
						confirm = function()
							return L:F("Are you sure you want to reset %s to default?", L["Tooltips"])
						end,
						func = function()
							wipe(core.char.Tooltip)
							DB = nil
							PLAYER_ENTERING_WORLD()
						end
					}
				}
			}
		end)
	end

	-- ///////////////////////////////////////////////////////
	do
		local backdrop = {
			bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
			edgeFile = [[Interface\ChatFrame\ChatFrameBackground]],
			edgeSize = 1,
			insets = {top = 0, left = 0, bottom = 0, right = 0}
		}

		local types = {
			rare = " |cffAF5050" .. ITEM_QUALITY3_DESC .. "|r ",
			elite = " |cffAF5050" .. ELITE .. "|r ",
			worldboss = " |cffAF5050" .. BOSS .. "|r ",
			rareelite = " |cffAF5050+" .. ITEM_QUALITY3_DESC .. "|r "
		}

		local classColors = {
			DEATHKNIGHT = "c41f3b",
			DRUID = "ff7d0a",
			HUNTER = "a9d271",
			MAGE = "40c7eb",
			PALADIN = "f58cba",
			PRIEST = "ffffff",
			ROGUE = "fff569",
			SHAMAN = "0070de",
			WARLOCK = "8787ed",
			WARRIOR = "c79c6e"
		}

		-- hooked to tooltips OnShow event
		local function Tooltip_OnShow(self)
			self:SetBackdropColor(0, 0, 0, 0.6)
			local item = self.GetItem and select(2, self:GetItem()) or nil
			if item then
				local quality = select(3, GetItemInfo(item))
				if quality and quality > 1 then
					local r, g, b = GetItemQualityColor(quality)
					self:SetBackdropBorderColor(r, g, b)
				end
			else
				self:SetBackdropBorderColor(0, 0, 0)
			end
		end

		-- hooked to tooltips OnHide event
		local function Tooltip_OnHide(self)
			self:SetBackdropBorderColor(0, 0, 0, 1)
		end

		local Tooltip_OnTooltipSetUnit
		local Tooltip_StatusBarOnValueChanged
		do
			-- converts RGB to HEX
			local Tooltip_Hex = function(r, g, b)
				return ("|cff%02x%02x%02x"):format(r * 255, g * 255, b * 255)
			end

			-- format health for better display
			local Tooltip_Truncate = function(value)
				if value >= 1e6 then
					return format("%.2fm", value / 1e6)
				elseif value >= 1e4 then
					return format("%.1fk", value / 1e3)
				else
					return format("%.0f", value)
				end
			end

			-- returns the proper unit color
			local function Tooltip_UnitColor(unit)
				local r, g, b = 1, 1, 1
				if UnitPlayerControlled(unit) then
					if UnitCanAttack(unit, "player") then
						if UnitCanAttack("player", unit) then
							r = FACTION_BAR_COLORS[2].r
							g = FACTION_BAR_COLORS[2].g
							b = FACTION_BAR_COLORS[2].b
						end
					elseif UnitCanAttack("player", unit) then
						r = FACTION_BAR_COLORS[4].r
						g = FACTION_BAR_COLORS[4].g
						b = FACTION_BAR_COLORS[4].b
					elseif UnitIsPVP(unit) then
						r = FACTION_BAR_COLORS[6].r
						g = FACTION_BAR_COLORS[6].g
						b = FACTION_BAR_COLORS[6].b
					end
				else
					local reaction = UnitReaction(unit, "player")
					if reaction then
						r = FACTION_BAR_COLORS[reaction].r
						g = FACTION_BAR_COLORS[reaction].g
						b = FACTION_BAR_COLORS[reaction].b
					end
				end

				if UnitIsPlayer(unit) then
					local class = select(2, UnitClass(unit))
					if class then
						r = RAID_CLASS_COLORS[class].r
						g = RAID_CLASS_COLORS[class].g
						b = RAID_CLASS_COLORS[class].b
					end
				end

				return r, g, b
			end

			-- hooked to OnTooltipSetUnit to add our enhancement
			function Tooltip_OnTooltipSetUnit(self)
				local lines = self:NumLines()
				local unit = select(2, self:GetUnit())
				if not unit then
					local mfocus = GetMouseFocus()
					if mfocus and mfocus.unit then
						unit = mfocus:GetAttribute("unit")
					end
				end
				if not unit then
					if UnitExists("mouseover") then
						unit = "mouseover"
					end
					if not unit then
						self:Hide()
						return
					end
				end
				if UnitIsUnit(unit, "mouseover") then
					unit = "mouseover"
				end

				local classif = UnitClassification(unit)
				local diffColor = GetQuestDifficultyColor(UnitLevel(unit))
				local creatureType = UnitCreatureType(unit) or ""
				local unitName = UnitName(unit)
				local level = UnitLevel(unit)
				if level < 0 then level = "??" end

				if UnitIsPlayer(unit) then
					if UnitIsAFK(unit) then
						self:AppendText((" %s"):format(CHAT_FLAG_AFK))
					elseif UnitIsDND(unit) then
						self:AppendText((" %s"):format(CHAT_FLAG_DND))
					end

					local unitRace = UnitRace(unit)
					local unitClass, classFile = UnitClass(unit)
					local guild, rank = GetGuildInfo(unit)
					local playerGuild = GetGuildInfo("player")
					local offset = 2

					if guild then
						_G["GameTooltipTextLeft2"]:SetFormattedText("%s |cffffffff(%s)|r", guild, rank)
						if IsInGuild() and guild == playerGuild then
							_G["GameTooltipTextLeft2"]:SetTextColor(0.7, 0.5, 0.8)
						else
							_G["GameTooltipTextLeft2"]:SetTextColor(0.35, 1, 0.6)
						end
						offset = offset + 1
					end

					for i = offset, lines do
						if (_G["GameTooltipTextLeft" .. i] and type(_G["GameTooltipTextLeft" .. i]) == "table" and _G["GameTooltipTextLeft" .. i]:GetText():find(PLAYER)) then
							_G["GameTooltipTextLeft" .. i]:SetFormattedText(
								LEVEL .. " %s%s|r %s |cff%s%s|r",
								Tooltip_Hex(diffColor.r, diffColor.g, diffColor.b),
								level,
								unitRace,
								classColors[classFile],
								unitClass
							)
							break
						end
					end
				else
					for i = 2, lines do
						if _G["GameTooltipTextLeft" .. i] and ((_G["GameTooltipTextLeft" .. i]:GetText():find(LEVEL)) or (creatureType and _G["GameTooltipTextLeft" .. i]:GetText():find(creatureType))) then
							if level == -1 and classif == "elite" then classif = "worldboss" end
							_G["GameTooltipTextLeft" .. i]:SetText(format(Tooltip_Hex(diffColor.r, diffColor.g, diffColor.b) .. "%s|r", level) .. (types[classif] or " ") .. creatureType)
							break
						end
					end
				end

				local pvpLine
				for i = 1, lines do
					local text = _G["GameTooltipTextLeft" .. i]:GetText()
					if text and text == PVP_ENABLED then
						pvpLine = _G["GameTooltipTextLeft" .. i]
						pvpLine:SetText()
						break
					end
				end

				if UnitExists(unit .. "target") then
					local r, g, b = Tooltip_UnitColor(unit .. "target")
					local text
					if UnitName(unit .. "target") == UnitName("player") then
						text = Tooltip_Hex(1, 0, 0) .. "<" .. UNIT_YOU .. ">|r"
					else
						text = Tooltip_Hex(r, g, b) .. UnitName(unit .. "target") .. "|r"
					end
					if text then
						self:AddLine(STATUS_TEXT_TARGET .. ": " .. text)
					end
				end
			end

			function Tooltip_StatusBarOnValueChanged(self, value)
				if not value then
					return
				end

				local min, max = self:GetMinMaxValues()
				if value < min or value > max then
					return
				end

				local unit = select(2, GameTooltip:GetUnit())
				if unit then
					min, max = UnitHealth(unit), UnitHealthMax(unit)
					if not self.text then
						self.text = self:CreateFontString(nil, "OVERLAY")
						self.text:SetPoint("CENTER", GameTooltipStatusBar)
						self.text:SetFont(GameFontNormal:GetFont(), 11, "THINOUTLINE")
					end
					self.text:Show()
					local hp = Tooltip_Truncate(min) .. " / " .. Tooltip_Truncate(max)
					self.text:SetText(hp)
				else
					if self.text then
						self.text:Hide()
					end
				end
			end
		end

		-- hooked to SetItemRef
		local function Tooltip_SetItemRef(link, text, button)
			if not iconFrame then
				return
			end

			if iconFrame:IsShown() then
				iconFrame:Hide()
			end

			local t, id = match(link, "(%l+):(%d+)")
			if t == "item" then
				iconFrame.icon:SetTexture(select(10, GetItemInfo(id)))
				iconFrame:Show()
			elseif t == "spell" then
				iconFrame.icon:SetTexture(select(3, GetSpellInfo(id)))
				iconFrame:Show()
			elseif t == "achievement" then
				iconFrame.icon:SetTexture(select(10, GetAchievementInfo(id)))
				iconFrame:Show()
			end
		end

		function PLAYER_ENTERING_WORLD()
			SetupDatabase()

			if disabled or not DB.enhance then
				return
			end

			for _, t in pairs({
				GameTooltip,
				ItemRefTooltip,
				ShoppingTooltip2,
				ShoppingTooltip3,
				WorldMapTooltip,
				DropDownList1MenuBackdrop,
				DropDownList2MenuBackdrop,
				_G.L_DropDownList1MenuBackdrop,
				_G.L_DropDownList2MenuBackdrop
			}) do
				if t then
					t:SetBackdrop(backdrop)
					t:SetBackdropColor(0, 0, 0, 0.6)
					t:SetBackdropBorderColor(0, 0, 0, 1)
					t:SetScale(DB.scale or 1)
					t:SetScript("OnShow", Tooltip_OnShow)
					t:HookScript("OnHide", Tooltip_OnHide)
				end
			end

			-- hook our custom function to change the look
			-- GameTooltip:HookScript("OnTooltipSetUnit", Tooltip_OnTooltipSetUnit)

			-- add target health and max health
			GameTooltipStatusBar.bg = CreateFrame("Frame", nil, GameTooltipStatusBar)
			GameTooltipStatusBar.bg:SetPoint("TOPLEFT", GameTooltipStatusBar, "TOPLEFT", -1, 1)
			GameTooltipStatusBar.bg:SetPoint("BOTTOMRIGHT", GameTooltipStatusBar, "BOTTOMRIGHT", 1, -1)
			GameTooltipStatusBar.bg:SetFrameStrata("LOW")
			GameTooltipStatusBar.bg:SetBackdrop(backdrop)
			GameTooltipStatusBar.bg:SetBackdropColor(0, 0, 0, 0.5)
			GameTooltipStatusBar.bg:SetBackdropBorderColor(0, 0, 0, 1)
			GameTooltipStatusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
			GameTooltipStatusBar:ClearAllPoints()
			GameTooltipStatusBar:SetPoint("TOPLEFT", GameTooltip, "BOTTOMLEFT", 1, 0)
			GameTooltipStatusBar:SetPoint("TOPRIGHT", GameTooltip, "BOTTOMRIGHT", -1, 0)
			GameTooltipStatusBar:HookScript("OnValueChanged", Tooltip_StatusBarOnValueChanged)

			-- add item icon to tooltip
			iconFrame = iconFrame or CreateFrame("Frame", nil, ItemRefTooltip)
			iconFrame:SetWidth(30)
			iconFrame:SetHeight(30)
			iconFrame:SetPoint("TOPRIGHT", ItemRefTooltip, "TOPLEFT", -3, 0)
			iconFrame:SetBackdrop(backdrop)
			iconFrame:SetBackdropColor(0, 0, 0, 0.5)
			iconFrame:SetBackdropBorderColor(0, 0, 0, 1)
			iconFrame.icon = iconFrame:CreateTexture(nil, "BACKGROUND")
			iconFrame.icon:SetPoint("TOPLEFT", 1, -1)
			iconFrame.icon:SetPoint("BOTTOMRIGHT", -1, 1)
			iconFrame.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

			hooksecurefunc("SetItemRef", Tooltip_SetItemRef)
		end
		core:RegisterForEvent("PLAYER_ENTERING_WORLD", PLAYER_ENTERING_WORLD)
	end

	core:RegisterForEvent("UPDATE_MOUSEOVER_UNIT", function()
		if not disabled and DB and DB.unit and core.InCombat then
			GameTooltip:Hide()
		end
	end)
end)