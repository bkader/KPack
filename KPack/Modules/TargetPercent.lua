local core = KPack
if not core then return end
core:AddModule("Target Percent", "Adds a health percentage to the Blizzard target and focus target frames.", function()
	if core:IsDisabled("Target Percent") or core.ElvUI then return end

	local CreateFrame = CreateFrame
	local UnitHealth = UnitHealth
	local UnitHealthMax = UnitHealthMax

	local targetPercent, focusPercent

	-- handles creating the percentage frame
	local function TargetPercent_CreateFrame(name, parent, width, height)
		local frame
		if name and parent then
			-- Create Frame:
			frame = CreateFrame("Frame", name, parent)
			if core.ufi then
				frame:SetPoint("BOTTOMRIGHT", parent, "TOPRIGHT", 15, 0)
			else
				frame:SetPoint("BOTTOMRIGHT", parent, "TOPRIGHT", 14, 16)
			end
			frame:SetWidth(width or 56)
			frame:SetHeight(height or 24)

			-- Create text
			frame.text = frame:CreateFontString(name .. "Text", "OVERLAY")
			frame.text:SetAllPoints(frame)
			frame.text:SetFontObject(TextStatusBarText)
			frame.text:SetJustifyH("CENTER")

			-- Add frame backdrop:
			frame:SetBackdrop({
				bgFile = "Interface/Tooltips/UI-Tooltip-Background",
				edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
				tile = true,
				tileSize = 16,
				edgeSize = 16,
				insets = {left = 4, right = 4, top = 4, bottom = 4}
			})
			frame:SetBackdropColor(0, 0, 0, 1)
		end
		return frame
	end

	-- called when the player enters the world
	core:RegisterForEvent("PLAYER_ENTERING_WORLD", function()
		-- create target percentage
		targetPercent = targetPercent or TargetPercent_CreateFrame("TargetPercent", TargetFrameHealthBar)
		targetPercent:RegisterEvent("PLAYER_TARGET_CHANGED")
		targetPercent:RegisterEvent("UNIT_HEALTH")
		targetPercent:SetScript("OnEvent", function(frame, _, unit)
			if unit and not UnitIsUnit(unit, "target") then
				return
			end
			local hp = UnitHealth("target")
			core:ShowIf(frame, (hp >= 1))
			frame.text:SetFormattedText("%.2f", (hp / UnitHealthMax("target") * 100))
		end)

		-- create focus percentage
		focusPercent = focusPercent or TargetPercent_CreateFrame("FocusPercent", FocusFrameHealthBar)
		focusPercent:RegisterEvent("PLAYER_FOCUS_CHANGED")
		focusPercent:SetScript("OnShow", function()
			focusPercent:RegisterEvent("UNIT_HEALTH")
		end)
		focusPercent:SetScript("OnHide", function()
			focusPercent:UnregisterEvent("UNIT_HEALTH")
		end)
		focusPercent:SetScript("OnEvent", function(frame, _, unit)
			if unit and not UnitIsUnit(unit, "focus") then
				return
			end
			local hp = UnitHealth("focus")
			core:ShowIf(frame, (hp >= 1))
			frame.text:SetFormattedText("%.2f", (hp / UnitHealthMax("focus") * 100))
		end)
	end)
end)