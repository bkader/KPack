--[[ Credits:  lynstats ]]
local core = KPack
if not core then return end
core:AddModule("LynStats", "Shows your latencty, fps, addons memory, mail and clock.", function(L)
	if core:IsDisabled("LynStats") or core.ElvUI then return end

	-- CONFIG
	---------------------------------------------
	local movable = true
	local addonList = 25
	local font = [[Interface\AddOns\KPack\Media\Fonts\HOOGE.TTF]]
	local fontSize = 12
	local fontFlag = "THINOUTLINE"
	if core.nonLatin then font = [[Fonts\FRIZQT__.ttf]] end

	local textAlign = "CENTER"
	local position = {"BOTTOMLEFT", UIParent, "BOTTOMLEFT", 3, 5}
	local tooltipAnchor = "ANCHOR_TOPRIGHT"

	local customColor = true
	local useShadow = true
	local showMail = true
	local showClock = false
	local use12 = false -- ignored if showClock is false.

	-- GLOBALS
	---------------------------------------------

	local CreateFrame, GetFramerate = CreateFrame, GetFramerate
	local HasNewMail = HasNewMail
	local UnitClass = UnitClass
	local select, format, lower = select, string.format, string.lower
	local floor, modf = math.floor, math.modf
	local tinsert, tsort = table.insert, table.sort
	local GetNumAddOns, GetAddOnInfo = GetNumAddOns, GetAddOnInfo
	local GetAddOnMemoryUsage, UpdateAddOnMemoryUsage = GetAddOnMemoryUsage, UpdateAddOnMemoryUsage
	local date, gcinfo, GetNetStats = date, gcinfo, GetNetStats
	local collectgarbage = collectgarbage

	-- CODE ITSELF
	---------------------------------------------

	local StatsFrame = CreateFrame("Frame", "KPackLynStats", UIParent)

	local gradientColor = {0, 1, 0, 1, 1, 0, 1, 0, 0}
	local color
	if customColor then
		color = {r = 0, g = 1, b = 0.7}
	else
		color = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[core.class]
	end

	local function memFormat(number)
		if number > 1024 then
			return format("%.2f mb", (number / 1024))
		else
			return format("%.1f kb", floor(number))
		end
	end

	local function numFormat(v)
		if v > 1E10 then
			return (floor(v / 1E9)) .. "b"
		elseif v > 1E9 then
			return (floor((v / 1E9) * 10) / 10) .. "b"
		elseif v > 1E7 then
			return (floor(v / 1E6)) .. "m"
		elseif v > 1E6 then
			return (floor((v / 1E6) * 10) / 10) .. "m"
		elseif v > 1E4 then
			return (floor(v / 1E3)) .. "k"
		elseif v > 1E3 then
			return (floor((v / 1E3) * 10) / 10) .. "k"
		else
			return v
		end
	end

	-- http://www.wowwiki.com/ColorGradient
	local function ColorGradient(perc, ...)
		if (perc > 1) then
			local r, g, b = select(select("#", ...) - 2, ...)
			return r, g, b
		elseif (perc < 0) then
			local r, g, b = ...
			return r, g, b
		end

		local num = select("#", ...) / 3

		local segment, relperc = modf(perc * (num - 1))
		local r1, g1, b1, r2, g2, b2 = select((segment * 3) + 1, ...)

		return r1 + (r2 - r1) * relperc, g1 + (g2 - g1) * relperc, b1 + (b2 - b1) * relperc
	end

	local function RGBGradient(num)
		local r, g, b = ColorGradient(num, unpack(gradientColor))
		return r, g, b
	end

	local function RGBToHex(r, g, b)
		r = r <= 1 and r >= 0 and r or 0
		g = g <= 1 and g >= 0 and g or 0
		b = b <= 1 and b >= 0 and b or 0
		return format("|cff%02x%02x%02x", r * 255, g * 255, b * 255)
	end

	local function addonCompare(a, b)
		return a.memory > b.memory
	end

	local function clearGarbage()
		if InCombatLockdown() then
			core:Print("|cffffe02e" .. ERR_NOT_IN_COMBAT .. "|r", "LynStats")
			return
		end

		UpdateAddOnMemoryUsage()
		local before = gcinfo()
		collectgarbage("collect")
		UpdateAddOnMemoryUsage()
		local after = gcinfo()
		print("|c0000ddffCleaned:|r " .. memFormat(before - after))
	end

	StatsFrame:EnableMouse(true)

	local function getFPS()
		return "|c00ffffff" .. floor(GetFramerate()) .. "|r fps"
	end

	local function getLatencyRaw()
		return select(3, GetNetStats())
	end

	local function getLatency()
		return "|c00ffffff" .. getLatencyRaw() .. "|r ms"
	end

	local function getMail()
		if HasNewMail() ~= nil then
			return "|c00ff00ffMail!|r"
		else
			return ""
		end
	end

	local function getTime()
		if use12 == true then
			local t = date("%I:%M")
			local ampm = date("%p")
			return "|c00ffffff" .. t .. "|r " .. lower(ampm)
		else
			local t = date("%H:%M")
			return "|c00ffffff" .. t .. "|r"
		end
	end

	local function addonTooltip(self)
		if InCombatLockdown() then return end

		GameTooltip:ClearLines()
		GameTooltip:SetOwner(self, tooltipAnchor)
		local blizz = collectgarbage("count")
		local addons = core.newTable()
		local entry, memory
		local total = 0
		local nr = 0
		UpdateAddOnMemoryUsage()
		GameTooltip:AddLine("AddOns", color.r, color.g, color.b)
		for i = 1, GetNumAddOns(), 1 do
			if (GetAddOnMemoryUsage(i) > 0) then
				memory = GetAddOnMemoryUsage(i)
				entry = {name = GetAddOnInfo(i), memory = memory}
				tinsert(addons, entry)
				total = total + memory
			end
		end
		tsort(addons, addonCompare)
		for _, e in pairs(addons) do
			if nr < addonList then
				GameTooltip:AddDoubleLine(e.name, memFormat(e.memory), 1, 1, 1, RGBGradient(e.memory / 800))
				nr = nr + 1
			end
		end
		core.delTable(addons)
		GameTooltip:AddLine("---------------------------------------", color.r, color.g, color.b)
		GameTooltip:AddDoubleLine(L["Total"], memFormat(total), 1, 1, 1, RGBGradient(total / (1024 * 10)))
		GameTooltip:AddDoubleLine(L["Total incl. Blizzard"], memFormat(blizz), 1, 1, 1, RGBGradient(blizz / (1024 * 10)))
		GameTooltip:Show()
	end

	StatsFrame:SetScript("OnEnter", function() addonTooltip(StatsFrame) end)
	StatsFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)

	if movable then
		StatsFrame:ClearAllPoints()
		StatsFrame:SetPoint(unpack(position))
		StatsFrame:SetMovable(true)
		StatsFrame:SetClampedToScreen(true)
		StatsFrame:SetUserPlaced(true)
		StatsFrame:SetScript("OnMouseDown", function(self)
			if IsAltKeyDown() then
				self.moving = true
				self:StartMoving()
				return
			end
		end)
		StatsFrame:SetScript("OnMouseUp", function(self)
			if self.moving then
				self.moving = nil
				self:StopMovingOrSizing()
				return
			end
			clearGarbage()
		end)
	else
		StatsFrame:SetPoint(unpack(position))
	end
	StatsFrame:SetWidth(50)
	StatsFrame:SetHeight(fontSize)

	StatsFrame.text = StatsFrame:CreateFontString(nil, "BACKGROUND")
	StatsFrame.text:SetPoint(textAlign, StatsFrame)
	StatsFrame.text:SetFont(font, fontSize, fontFlag)
	if useShadow then
		StatsFrame.text:SetShadowOffset(1, -1)
		StatsFrame.text:SetShadowColor(0, 0, 0)
	end
	StatsFrame.text:SetTextColor(color.r, color.g, color.b)

	local lastUpdate = 0

	local function update(self, elapsed)
		lastUpdate = lastUpdate + elapsed
		if lastUpdate > 1 then
			lastUpdate = 0
			local text = getFPS() .. "  " .. getLatency()
			if showMail then
				text = text .. "  " .. getMail()
			end
			if showClock then
				text = text .. "  " .. getTime()
			end
			StatsFrame.text:SetText(text)
			self:SetWidth(StatsFrame.text:GetStringWidth())
			self:SetHeight(StatsFrame.text:GetStringHeight())
		end
	end

	StatsFrame:SetScript("OnEvent", function(self, event)
		self:SetScript("OnUpdate", update)
	end)
	StatsFrame:RegisterEvent("PLAYER_LOGIN")
end)