local core = KPack
if not core then return end
core:AddModule("IDs", "Adds IDs to the ingame tooltips.", function(L)
	if core:IsDisabled("IDs") or core.ElvUI then return end

	local IDs = {}
	core.IDs = IDs
	LibStub("AceHook-3.0"):Embed(IDs)

	local select, pairs, match, find, format, strsub = select, pairs, string.match, string.find, string.format, string.sub
	local GetUnitName, UnitIsPlayer, UnitClass, UnitReaction = GetUnitName, UnitIsPlayer, UnitClass, UnitReaction
	local UnitAura, UnitBuff, UnitDebuff = UnitAura, UnitBuff, UnitDebuff

	local function addLine(tooltip, left, right)
		tooltip:AddDoubleLine(left, right)
		tooltip:Show()
	end

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

	core:RegisterForEvent("PLAYER_ENTERING_WORLD", function()
		if not IDs:IsHooked(GameTooltip, "OnTooltipSetSpell") then
			IDs:HookScript(GameTooltip, "OnTooltipSetSpell", function(self)
				local id = select(3, self:GetSpell())
				if id then
					addLine(self, L["Spell ID"], id)
				end
			end)
		end

		if not IDs:IsHooked(GameTooltip, "OnTooltipSetItem") then
			IDs:HookScript(GameTooltip, "OnTooltipSetItem", function(self)
				local _, itemlink = self:GetItem()
				if itemlink then
					local _, itemid = strsplit(":", match(itemlink, "item[%-?%d:]+"))
					addLine(self, L["Item ID"], itemid)
				end
			end)
		end

		if not IDs:IsHooked(GameTooltip, "SetUnitBuff") then
			IDs:SecureHook(GameTooltip, "SetUnitBuff", function(self, ...)
				KPack_AddAuraSource(self, UnitBuff, ...)
				local id = select(11, UnitBuff(...))
				if id then
					addLine(self, L["Spell ID"], id)
				end
			end)
		end

		if not IDs:IsHooked(GameTooltip, "SetUnitDebuff") then
			IDs:SecureHook(GameTooltip, "SetUnitDebuff", function(self, ...)
				KPack_AddAuraSource(self, UnitDebuff, ...)
				local id = select(11, UnitDebuff(...))
				if id then
					addLine(self, L["Spell ID"], id)
				end
			end)
		end

		if not IDs:IsHooked(GameTooltip, "SetUnitAura") then
			IDs:SecureHook(GameTooltip, "SetUnitAura", function(self, ...)
				KPack_AddAuraSource(self, UnitAura, ...)
				local id = select(11, UnitAura(...))
				if id then
					addLine(self, L["Spell ID"], id)
				end
			end)
		end

		if not IDs:IsHooked("SetItemRef") then
			IDs:SecureHook("SetItemRef", function(link, text, button, chatFrame)
				if find(link, "^spell:") or find(link, "^enchant:") then
					local pos = find(link, ":") + 1
					local id = strsub(link, pos)
					if find(id, ":") then
						pos = find(id, ":") - 1
						id = id:sub(1, pos)
					end
					if id then
						addLine(ItemRefTooltip, L["Spell ID"], id)
					end
				elseif find(link, "^achievement:") then
					local pos = find(link, ":") + 1
					local endpos = find(link, ":", pos) - 1
					if pos and endpos then
						local id = strsub(link, pos, endpos)
						if id then
							addLine(ItemRefTooltip, L["Achievement ID"], id)
						end
					end
				elseif find(link, "^quest:") then
					local pos = find(link, ":") + 1
					local endpos = find(link, ":", pos) - 1
					if pos and endpos then
						local id = strsub(link, pos, endpos)
						if id then
							addLine(ItemRefTooltip, L["Quest ID"], id)
						end
					end
				elseif find(link, "^item:") then
					local pos = find(link, ":") + 1
					local endpos = find(link, ":", pos) - 1
					if pos and endpos then
						local id = strsub(link, pos, endpos)
						if id then
							addLine(ItemRefTooltip, L["Item ID"], id)
						end
					end
				end
			end)
		end
	end)
end)