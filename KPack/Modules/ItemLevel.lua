local core = KPack
if not core then return end
core:AddModule("ItemLevel", "Adds item levels to character and inspect frames.", function(L)
	if core:IsDisabled("ItemLevel") then return end

	local mod = core.ItemLevel or {}
	core.ItemLevel = mod

	local slots = {
		"HeadSlot",
		"NeckSlot",
		"ShoulderSlot",
		"BackSlot",
		"ChestSlot",
		"ShirtSlot",
		"TabardSlot",
		"WristSlot",
		"MainHandSlot",
		"SecondaryHandSlot",
		"RangedSlot",
		"HandsSlot",
		"WaistSlot",
		"LegsSlot",
		"FeetSlot",
		"Finger0Slot",
		"Finger1Slot",
		"Trinket0Slot",
		"Trinket1Slot"
	}

	-----------------------------------------------------------------------
	-- Equipment slots item level

	do
		local function CreateButtonsText(frame)
			for _, slot in pairs(slots) do
				local button = _G[frame .. slot]
				button.t = button:CreateFontString(nil, "OVERLAY")
				button.t:SetFont(NumberFontNormal:GetFont())
				button.t:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 2, 2)
				button.t:SetText("")
			end
		end

		local function UpdateButtonsText(frame)
			if frame == "Inspect" and not (InspectFrame and InspectFrame:IsShown()) then
				return
			end

			for _, slot in pairs(slots) do
				local id = GetInventorySlotInfo(slot)
				local item
				local text = _G[frame .. slot].t

				if frame == "Inspect" then
					item = GetInventoryItemLink("target", id)
				else
					item = GetInventoryItemLink("player", id)
				end

				if slot == "ShirtSlot" or slot == "TabardSlot" then
					text:SetText("")
				elseif item then
					local oldilevel = text:GetText()
					local ilevel = select(4, GetItemInfo(item))

					if ilevel then
						if ilevel ~= oldilevel then
							text:SetText("|cFFFFFF00" .. ilevel)
						end
					else
						text:SetText("")
					end
				else
					text:SetText("")
				end
			end
		end

		core:RegisterForEvent("PLAYER_LOGIN", function()
			CreateButtonsText("Character")
			UpdateButtonsText("Character")
		end)

		core:RegisterForEvent("PLAYER_EQUIPMENT_CHANGED", function()
			UpdateButtonsText("Character")
		end)

		core:RegisterForEvent("PLAYER_TARGET_CHANGED", function()
			UpdateButtonsText("Inspect")
		end)

		core:RegisterForEvent("ADDON_LOADED", function(_, name)
			if name == "Blizzard_InspectUI" then
				CreateButtonsText("Inspect")
				InspectFrame:HookScript("OnShow", function(self)
					UpdateButtonsText("Inspect")
				end)
				if not core.GearScore or not core.GearScore.Level then
					mod:HookTooltip()
				end
			end
		end)
	end

	-----------------------------------------------------------------------
	-- average item level in tooltips and PaperDoll

	do
		local ceil = math.ceil
		local UnitIsPlayer = UnitIsPlayer
		local GetInventoryItemID = GetInventoryItemID
		local GetInventorySlotInfo = GetInventorySlotInfo

		local function CalculateItemLevel(unit)
			if unit and UnitIsPlayer(unit) then
				local total, itn = 0, 0

				for i = 1, 18 do
					if i ~= 4 and i ~= 17 then
						local sLink = GetInventoryItemLink(unit, i)
						if sLink then
							local _, _, _, iLevel, _, _, _, _ = GetItemInfo(sLink)
							if iLevel and iLevel > 0 then
								itn = itn + 1
								total = total + iLevel
							end
						end
					end
				end
				return (total < 1 or itn < 1) and 0 or ceil(total / itn)
			end
		end

		function mod:HookTooltip()
			GameTooltip:HookScript("OnTooltipSetUnit", function(self, ...)
				local ilevel
				local name, unit = self:GetUnit()
				if unit and CanInspect(unit) then
					local isInspectOpen =
						(InspectFrame and InspectFrame:IsShown()) or (_G.Examiner and _G.Examiner:IsShown())
					if unit and CanInspect(unit) and not isInspectOpen then
						NotifyInspect(unit)
						ilevel = CalculateItemLevel(unit)
						ClearInspectPlayer(unit)
						self:AddDoubleLine(L["Item Level"], ilevel, 1, 1, 0)
					end
				end
			end)
		end
	end
end)