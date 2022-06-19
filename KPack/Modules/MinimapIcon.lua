local core = KPack
if not core then return end
core:AddModule("Minimap Button", "Shows the kPack minimap icon button.", function(L, folder)
	if core:IsDisabled("Minimap Button") then return end

	-- required LibDataBroker
	local LDB = LibStub("LibDataBroker-1.1")
	if not LDB then return end

	-- required LibDBIcon
	local DBI = LibStub("LibDBIcon-1.0")
	if not DBI then return end

	local dataobj

	local function CreateMinimapButton()
		if dataobj then return end

		dataobj = LDB:NewDataObject(folder, {
			label = GetAddOnMetadata(folder, "Title"),
			type = "data source",
			icon = [[Interface\AddOns\KPack\Media\KPack]],
			text = "n/a"
		})

		dataobj.OnEnter = function(self)
			GameTooltip:SetOwner(self, "ANCHOR_NONE")
			GameTooltip:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT")
			GameTooltip:ClearLines()

			GameTooltip:AddDoubleLine(core.title, core.version)
			GameTooltip:AddLine(L["|cff00ff00Click|r to toggle the settings window."], 1, 1, 1)

			GameTooltip:Show()
		end

		dataobj.OnLeave = function(self)
			GameTooltip:Hide()
		end

		dataobj.OnClick = function(self)
			core:OpenConfig()
		end

		if not DBI:IsRegistered(folder) then
			DBI:Register(folder, dataobj)
		end
	end

	core:RegisterForEvent("PLAYER_LOGIN", CreateMinimapButton)
end)