local core = KPack
if not core then return end
core:AddModule("Align", "A very simple alignment grid with no options.", function()
	if core:IsDisabled("Align") then return end

	-- cache some globals
	local _CreateFrame = CreateFrame
	local _GetScreenWidth, _GetScreenHeight = GetScreenWidth, GetScreenHeight
	local _floor, _ceil = math.floor, math.ceil

	-- default box size and grid frame
	local boxSize, frame = 32
	local aligning = false

	-- draws the grid
	local function Align_DrawGrid()
		grid = _CreateFrame("Frame", nil, UIParent)
		grid.boxSize = boxSize
		grid:SetAllPoints(UIParent)

		local size = 2
		local width = _GetScreenWidth()
		local ratio = width / _GetScreenHeight()
		local height = _GetScreenHeight() * ratio

		local wStep = width / boxSize
		local hStep = height / boxSize

		for i = 0, boxSize do
			local tx = grid:CreateTexture(nil, "BACKGROUND")
			if i == boxSize / 2 then
				tx:SetTexture(1, 0, 0, 0.5)
			else
				tx:SetTexture(0, 0, 0, 0.5)
			end
			tx:SetPoint("TOPLEFT", grid, "TOPLEFT", i * wStep - (size / 2), 0)
			tx:SetPoint("BOTTOMRIGHT", grid, "BOTTOMLEFT", i * wStep + (size / 2), 0)
		end

		height = _GetScreenHeight()

		do
			local tx = grid:CreateTexture(nil, "BACKGROUND")
			tx:SetTexture(1, 0, 0, 0.5)
			tx:SetPoint("TOPLEFT", grid, "TOPLEFT", 0, -(height / 2) + (size / 2))
			tx:SetPoint("BOTTOMRIGHT", grid, "TOPRIGHT", 0, -(height / 2 + size / 2))
		end

		for i = 1, _floor((height / 2) / hStep) do
			local tx = grid:CreateTexture(nil, "BACKGROUND")
			tx:SetTexture(0, 0, 0, 0.5)
			tx:SetPoint("TOPLEFT", grid, "TOPLEFT", 0, -(height / 2 + i * hStep) + (size / 2))
			tx:SetPoint("BOTTOMRIGHT", grid, "TOPRIGHT", 0, -(height / 2 + i * hStep + size / 2))
			tx = grid:CreateTexture(nil, "BACKGROUND")
			tx:SetTexture(0, 0, 0, 0.5)
			tx:SetPoint("TOPLEFT", grid, "TOPLEFT", 0, -(height / 2 - i * hStep) + (size / 2))
			tx:SetPoint("BOTTOMRIGHT", grid, "TOPRIGHT", 0, -(height / 2 - i * hStep + size / 2))
		end
	end

	-- shows the grid
	local function Align_ShowGrid()
		if not grid then
			Align_DrawGrid()
		elseif grid.boxSize ~= boxSize then
			grid:Hide()
			Align_DrawGrid()
		else
			grid:Show()
		end
	end

	-- hides the grid
	local function Align_HideGrid()
		if grid then
			grid:Hide()
		end
	end

	-- module slash commands handler
	local function SlashCommandHandler(str)
		if aligning then
			Align_HideGrid()
			aligning = false
		else
			boxSize = (_ceil((tonumber(str) or boxSize) / 32) * 32)
			if boxSize > 256 then
				boxSize = 256
			end
			Align_DrawGrid()
			aligning = true
		end
	end

	core:RegisterForEvent("PLAYER_LOGIN", function()
		SlashCmdList["KPACKALIGN"] = SlashCommandHandler
		SLASH_KPACKALIGN1 = "/drawgrid"
		SLASH_KPACKALIGN2 = "/dg"
		if not _G.Align then
			SLASH_KPACKALIGN3 = "/align"
		end
	end)
end)