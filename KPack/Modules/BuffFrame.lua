assert(KPack, "KPack not found!")
KPack:AddModule("BuffFrame", "Lightweight, it modifies your buff and debuff frames.", function(_, core, L)
	if core:IsDisabled("BuffFrame") or core.ElvUI then return end

	local LSM = core.LSM or LibStub("LibSharedMedia-3.0")
	local hooksecurefunc = hooksecurefunc
	local LBF = LibStub("LibButtonFacade", true)

	do
		local disabled, reason
		if core:AddOnHasModule("Dominos", "Buffs") then
			disabled = true
			reason = "Dominos Buffs"
		end

		local DB, SetupDatabase
		local defaults = {
			enabled = true,
			buffSize = 30,
			buffScale = 1,
			buffFontSize = 14,
			buffCountSize = 16,
			debuffSize = 32,
			debuffScale = 1,
			debuffFontSize = 14,
			debuffCountSize = 16,
			durationFont = "Yanone",
			countFont = "Yanone",
			iconPerRow = 8,
			durationAnchor = "BOTTOM",
			durationOffsetX = 0,
			durationOffsetY = -2,
			stackAnchor = "TOPRIGHT",
			stackOffsetX = 0,
			stackOffsetY = 0
		}
		local anchors = {
			TOP = L["Top"],
			BOTTOM = L["Bottom"],
			LEFT = L["Left"],
			RIGHT = L["Right"],
			CENTER = L["Center"],
			TOPLEFT = L["Top Left"],
			TOPRIGHT = L["Top Right"],
			BOTTOMLEFT = L["Bottom Left"],
			BOTTOMRIGHT = L["Bottom Right"]
		}

		-- flag used so we don't hook again
		local hooked

		-- we makd sure to change the way duration looks.
		local ceil, mod = math.ceil, mod

		local origSecondsToTimeAbbrev = _G.SecondsToTimeAbbrev
		local function SecondsToTimeAbbrevHook(seconds)
			origSecondsToTimeAbbrev(seconds)
			if seconds >= 86400 then
				return "|cffffffff%dd|r", ceil(seconds / 86400)
			elseif seconds >= 3600 then
				return "|cffffffff%dh|r", ceil(seconds / 3600)
			elseif seconds >= 60 then
				return "|cffffffff%dm|r", ceil(seconds / 60)
			end
			return "|cffffffff%d|r", seconds
		end
		_G.SecondsToTimeAbbrev = SecondsToTimeAbbrevHook
		BuffFrame:SetScript("OnUpdate", nil)

		-- Style temporary enchants first:
		local function UpdateFirstButton(buff)
			if buff and buff:IsShown() then
				buff:ClearAllPoints()
				if BuffFrame.numEnchants > 0 then
					buff:SetPoint("TOPRIGHT", _G["TempEnchant" .. BuffFrame.numEnchants], "TOPLEFT", -5, 0)
				else
					buff:SetPoint("TOPRIGHT", TempEnchant1)
				end
				return
			end
		end

		local function CheckFirstButton()
			if BuffButton1 then
				UpdateFirstButton(BuffButton1)
			end
		end

		local function Our_AuraButton_Update(buttonName, index, filter)
			local buffName = buttonName .. index
			local buff = _G[buffName]

			if not buff then
				return
			end

			_G[buffName .. "Icon"]:SetTexCoord(0.1, 0.9, 0.1, 0.9)

			-- position the duration
			buff.duration:ClearAllPoints()
			buff.duration:SetShadowOffset(0, 0)
			buff.duration:SetDrawLayer("OVERLAY")
			buff.duration:SetPoint(
				DB.durationAnchor or "BOTTOM",
				buff,
				DB.durationAnchor or "BOTTOM",
				DB.durationOffsetX or 0,
				DB.durationOffsetY or -2
			)
			if DB.durationAnchor and DB.durationAnchor:find("LEFT") then
				buff.duration:SetJustifyH("LEFT")
			elseif DB.durationAnchor and DB.durationAnchor:find("RIGHT") then
				buff.duration:SetJustifyH("RIGHT")
			else
				buff.duration:SetJustifyH("CENTER")
			end

			-- position the stack count
			buff.count:ClearAllPoints()
			buff.count:SetJustifyV("TOP")
			buff.count:SetPoint(
				DB.stackAnchor or "TOPRIGHT",
				buff,
				DB.stackAnchor or "TOPRIGHT",
				DB.stackOffsetX or 0,
				DB.stackOffsetY or 0
			)
			if DB.stackAnchor and DB.stackAnchor:find("RIGHT") then
				buff.count:SetJustifyH("RIGHT")
			elseif DB.stackAnchor and DB.stackAnchor:find("LEFT") then
				buff.count:SetJustifyH("LEFT")
			else
				buff.count:SetJustifyH("CENTER")
			end
			buff.count:SetShadowOffset(0, 0)
			buff.count:SetDrawLayer("OVERLAY")

			if filter == "HELPFUL" then
				buff:SetSize(DB.buffSize, DB.buffSize)
				buff:SetScale(DB.buffScale)
				buff.duration:SetFont(LSM:Fetch("font", DB.durationFont), DB.buffFontSize, "THINOUTLINE")
				buff.count:SetFont(LSM:Fetch("font", DB.countFont), DB.buffCountSize, "THINOUTLINE")
			else
				buff:SetSize(DB.debuffSize, DB.debuffSize)
				buff:SetScale(DB.debuffScale)
				buff.duration:SetFont(LSM:Fetch("font", DB.durationFont), DB.debuffFontSize, "THINOUTLINE")
				buff.count:SetFont(LSM:Fetch("font", DB.countFont), DB.debuffCountSize, "THINOUTLINE")
			end

			if LBF then
				LBF:Group("KPack", L["Buff Frame"]):AddButton(buff)
			end
		end

		local Old_BuffFrame_UpdateAllBuffAnchors = BuffFrame_UpdateAllBuffAnchors
		function BuffFrame_UpdateAllBuffAnchors()
			_G.BUFF_ROW_SPACING = 5
			_G.BUFFS_PER_ROW = DB.iconPerRow or 8
			Old_BuffFrame_UpdateAllBuffAnchors()
		end

		local function Our_TempEnchantButton_OnUpdate(self, elapsed)
			if BuffFrame.numEnchants > 0 then
				TemporaryEnchantFrame:SetWidth((DB.buffSize * BuffFrame.numEnchants) + (BUFF_ROW_SPACING * (BuffFrame.numEnchants - 1)))
			end
		end

		function SetupDatabase()
			if not DB then
				if type(core.db.BuffFrame) ~= "table" or not next(core.db.BuffFrame) then
					core.db.BuffFrame = CopyTable(defaults)
				end
				DB = core.db.BuffFrame
			end
		end

		local function PLAYER_ENTERING_WORLD()
			if not DB.enabled then
				return
			end

			-- change its size for better position
			ConsolidatedBuffs:SetSize(DB.buffSize, DB.buffSize)

			for i = 1, 2 do
				local buff = _G["TempEnchant" .. i]
				if buff then
					buff:SetScale(DB.buffScale)
					buff:SetSize(DB.buffSize, DB.buffSize)
					buff:SetScript("OnShow", function() CheckFirstButton() end)
					buff:SetScript("OnHide", function() CheckFirstButton() end)

					local icon = _G["TempEnchant" .. i .. "Icon"]
					icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)

					local duration = _G["TempEnchant" .. i .. "Duration"]
					duration:ClearAllPoints()
					duration:SetPoint(
						DB.durationAnchor or "BOTTOM",
						buff,
						DB.durationAnchor or "BOTTOM",
						DB.durationOffsetX or 0,
						DB.durationOffsetY or -2
					)
					duration:SetFont(LSM:Fetch("font", DB.durationFont), DB.buffFontSize, "THINOUTLINE")
					duration:SetShadowOffset(0, 0)
					duration:SetDrawLayer("OVERLAY")
					_G["TempEnchant" .. i .. "Border"]:SetTexture(nil)
					if LBF then
						LBF:Group("KPack", L["Buff Frame"]):AddButton(buff)
					end
				end
			end
			if not hooked then
				hooksecurefunc("AuraButton_Update", Our_AuraButton_Update)
				hooksecurefunc("TempEnchantButton_OnUpdate", Our_TempEnchantButton_OnUpdate)
				hooked = true
			end

			if LBF and DB.style then
				LBF:Group("KPack", L["Buff Frame"]):Skin(unpack(DB.style))
			end
		end

		core:RegisterForEvent("PLAYER_LOGIN", function()
			SetupDatabase()

			SLASH_KPACKBUFFFRAME1 = "/buff"
			SLASH_KPACKBUFFFRAME2 = "/buffframe"
			SlashCmdList["KPACKBUFFFRAME"] = function()
				core:OpenConfig("Options", "BuffFrame")
			end
			local _disabled = function()
				return not DB.enabled or core.InCombat or disabled
			end

			core.options.args.Options.args.BuffFrame = {
				type = "group",
				name = L["Buff Frame"],
				get = function(i)
					return (DB[i[#i]] == nil) and defaults[i[#i]] or DB[i[#i]]
				end,
				set = function(i, val)
					DB[i[#i]] = val
					PLAYER_ENTERING_WORLD(i[#i])
					if i[#i] == "iconPerRow" then
						BuffFrame_UpdateAllBuffAnchors()
					end
				end,
				args = {
					status = {
						type = "description",
						name = L:F("This module is disabled because you are using: |cffffd700%s|r", reason or UNKNOWN),
						fontSize = "medium",
						order = 0,
						hidden = not disabled
					},
					notice = {
						type = "description",
						name = L["Some settings require UI to be reloaded."],
						fontSize = "medium",
						order = 0.1,
						width = "double"
					},
					enabled = {
						type = "toggle",
						name = L["Enable"],
						order = 0.2,
						disabled = function() return core.InCombat or disabled end
					},
					reset = {
						type = "execute",
						name = RESET,
						order = 1,
						disabled = _disabled,
						confirm = function()
							return L:F("Are you sure you want to reset %s to default?", L["Buff Frame"])
						end,
						func = function()
							core.db.BuffFrame = nil
							DB = nil
							SetupDatabase()
							core:Print(L["module's settings reset to default."], "BuffFrame")
						end
					},
					common = {
						type = "group",
						name = L["Common"],
						inline = true,
						order = 2,
						disabled = _disabled,
						args = {
							iconPerRow = {
								type = "range",
								name = L["Icon Per Row"],
								order = 0,
								min = 6, max = 12, step = 1,
								width = "double"
							},
							durationAnchor = {
								type = "select",
								name = L["Duration Anchor"],
								order = 1,
								width = "double",
								values = anchors
							},
							durationOffsetX = {
								type = "range",
								name = L["X Offset"],
								order = 2,
								min = -50,
								max = 50,
								step = 1
							},
							durationOffsetY = {
								type = "range",
								name = L["Y Offset"],
								order = 3,
								min = -50,
								max = 50,
								step = 1
							},
							stackAnchor = {
								type = "select",
								name = L["Stack Anchor"],
								order = 5,
								width = "double",
								values = anchors
							},
							stackOffsetX = {
								type = "range",
								name = L["X Offset"],
								order = 6,
								min = -50,
								max = 50,
								step = 1
							},
							stackOffsetY = {
								type = "range",
								name = L["Y Offset"],
								order = 7,
								min = -50,
								max = 50,
								step = 1
							}
						}
					},
					buffs = {
						type = "group",
						name = L["Buffs"],
						inline = true,
						order = 3,
						disabled = _disabled,
						args = {
							buffSize = {
								type = "range",
								name = L["Buff Size"],
								order = 1,
								min = 16,
								max = 64,
								step = 1
							},
							buffScale = {
								type = "range",
								name = L["Scale"],
								order = 2,
								min = 0.5,
								max = 3,
								step = 0.01,
								bigStep = 0.1
							},
							buffFontSize = {
								type = "range",
								name = L["Duration Font Size"],
								order = 3,
								min = 6,
								max = 30,
								step = 1
							},
							buffCountSize = {
								type = "range",
								name = L["Stack Font Size"],
								order = 4,
								min = 6,
								max = 30,
								step = 1
							}
						}
					},
					debuffs = {
						type = "group",
						name = L["Debuffs"],
						inline = true,
						order = 4,
						disabled = _disabled,
						args = {
							debuffSize = {
								type = "range",
								name = L["Debuff Size"],
								order = 1,
								min = 16,
								max = 64,
								step = 1
							},
							debuffScale = {
								type = "range",
								name = L["Scale"],
								order = 2,
								min = 0.5,
								max = 3,
								step = 0.01,
								bigStep = 0.1
							},
							debuffFontSize = {
								type = "range",
								name = L["Duration Font Size"],
								order = 3,
								min = 6,
								max = 30,
								step = 1
							},
							debuffCountSize = {
								type = "range",
								name = L["Stack Font Size"],
								order = 4,
								min = 6,
								max = 30,
								step = 1
							}
						}
					},
					fonts = {
						type = "group",
						name = L["Font"],
						order = 5,
						inline = true,
						disabled = _disabled,
						args = {
							durationFont = {
								type = "select",
								name = L["Duration Font"],
								order = 1,
								dialogControl = "LSM30_Font",
								values = AceGUIWidgetLSMlists.font
							},
							countFont = {
								type = "select",
								name = L["Stack Font"],
								order = 2,
								dialogControl = "LSM30_Font",
								values = AceGUIWidgetLSMlists.font
							}
						}
					}
				}
			}

			PLAYER_ENTERING_WORLD()
		end)

		core:RegisterForEvent("PLAYER_ENTERING_WORLD", PLAYER_ENTERING_WORLD)
	end

	-- ----------------------------------------------------------------------------

	do
		local select, pairs, match, format = select, pairs, string.match, string.format
		local GetUnitName, UnitIsPlayer, UnitClass, UnitReaction = GetUnitName, UnitIsPlayer, UnitClass, UnitReaction
		local UnitAura, UnitBuff, UnitDebuff = UnitAura, UnitBuff, UnitDebuff
		local hooked

		local BETTER_FACTION_BAR_COLORS = {
			[1] = {r = 217 / 255, g = 69 / 255, b = 69 / 255},
			[2] = {r = 217 / 255, g = 69 / 255, b = 69 / 255},
			[3] = {r = 217 / 255, g = 69 / 255, b = 69 / 255},
			[4] = {r = 217 / 255, g = 196 / 255, b = 92 / 255},
			[5] = {r = 84 / 255, g = 150 / 255, b = 84 / 255},
			[6] = {r = 84 / 255, g = 150 / 255, b = 84 / 255},
			[7] = {r = 84 / 255, g = 150 / 255, b = 84 / 255},
			[8] = {r = 84 / 255, g = 150 / 255, b = 84 / 255}
		}

		local classColors = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS

		local function KPack_AddAuraSource(self, func, unit, index, filter)
			local srcUnit = select(8, func(unit, index, filter))
			if srcUnit then
				local src = GetUnitName(srcUnit, true)
				if srcUnit == "pet" or srcUnit == "vehicle" then
					local color = classColors[select(2, UnitClass("player"))]
					src = format("%s (|cff%02x%02x%02x%s|r)", src, color.r * 255, color.g * 255, color.b * 255, GetUnitName("player", true))
				else
					local partypet = match(srcUnit, "^partypet(%d+)$")
					local raidpet = match(srcUnit, "^raidpet(%d+)$")
					if partypet then
						src = format("%s (%s)", src, GetUnitName("party" .. partypet, true))
					elseif raidpet then
						src = format("%s (%s)", src, GetUnitName("raid" .. raidpet, true))
					end
				end
				if UnitIsPlayer(srcUnit) then
					local color = classColors[select(2, UnitClass(srcUnit))]
					if color then
						src = format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, src)
					end
				else
					local color = BETTER_FACTION_BAR_COLORS[UnitReaction(srcUnit, "player")]
					if color then
						src = format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, src)
					end
				end
				self:AddLine(DONE_BY .. " " .. src)
				self:Show()
			end
		end
		local funcs = {SetUnitAura = UnitAura, SetUnitBuff = UnitBuff, SetUnitDebuff = UnitDebuff}

		if not hooked then
			for k, v in pairs(funcs) do
				hooksecurefunc(GameTooltip, k, function(self, unit, index, filter)
					KPack_AddAuraSource(self, v, unit, index, filter)
				end)
			end
			hooked = true
		end
	end
end)