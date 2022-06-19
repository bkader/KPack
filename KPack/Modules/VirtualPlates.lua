local core = KPack
if not core then return end
core:AddModule("Virtual Plates", "Scales nameplates relative to the location of units on the screen.", function(L)
	if core:IsDisabled("Virtual Plates") then return end
	local CreateFrame = CreateFrame

	local mod = {}
	mod.frame = CreateFrame("Frame", nil, WorldFrame)

	local plates, visiblePlates = {}, {}
	local cameraClip, plateLevels, updateRate = 4, 3, 0
	local plateOverrde, nextUpdate = {}, 0

	local defaults = {minScale = 0.5, maxScale = 3, scaleFactor = 15}

	local DB
	local function SetupDatabase()
		if not DB then
			if type(core.db.VirtualPlates) ~= "table" then
				core.db.VirtualPlates = CopyTable(defaults)
			end
			DB = core.db.VirtualPlates
		end
	end

	do
		local function VP_ResetPoint(frame, region, point, relFrame, ...)
			if relFrame == frame then
				region:SetPoint(point, plates[frame], ...)
			end
		end

		function mod:PlateOnShow()
			nextUpdate = 0
			local visual = plates[self]
			visiblePlates[self] = visual
			visual:Show()

			for i, r in ipairs(self) do
				for p = 1, r:GetNumPoints() do
					VP_ResetPoint(self, r, r:GetPoint(p))
				end
			end
		end
	end

	function mod:PlateOnHide()
		visiblePlates[self] = nil
		plates[self]:Hide()
	end

	do
		local WorldFrame_GetChildren = WorldFrame.GetChildren
		do
			local VP_PlatesUpdate
			do
				local sortOrder, depths = {}, {}
				local function SortFunc(a, b)
					return depths[a] > depths[b]
				end

				-- original stuff
				local SetAlpha = mod.frame.SetAlpha
				local SetFrameLevel = mod.frame.SetFrameLevel
				local SetScale = mod.frame.SetScale

				function VP_PlatesUpdate()
					for plate, visual in pairs(visiblePlates) do
						local depth = visual:GetEffectiveDepth()
						if depth <= 0 then
							SetAlpha(visual, 0)
						else
							sortOrder[#sortOrder + 1] = plate
							depths[plate] = depth
						end
					end

					if #sortOrder > 0 then
						local minScale = DB and DB.minScale or defaults.minScale
						local maxScale = DB and (DB.maxScale > 0 and DB.maxScale or nil) or defaults.maxScale
						local scaleFactor = DB and DB.scaleFactor or defaults.scaleFactor

						sort(sortOrder, SortFunc)
						for i, plate in ipairs(sortOrder) do
							local depth, visual = depths[plate], plates[plate]

							if depth < cameraClip then
								SetAlpha(visual, depth / cameraClip)
							else
								SetAlpha(visual, 1)
							end

							SetFrameLevel(visual, i * plateLevels)

							local scale = scaleFactor / depth
							if scale < minScale then
								scale = minScale
							elseif maxScale and scale > maxScale then
								scale = maxScale
							end
							SetScale(visual, scale)
							if not core.InCombat then
								local width, height = visual:GetSize()
								plate:SetSize(width * scale, height * scale)
							end
						end
						wipe(sortOrder)
					end
				end
			end

			local function VP_ReparentChildren(frame, ...)
				local visual = plates[frame]
				for i = 1, select("#", ...) do
					local child = select(i, ...)
					if child ~= visual then
						local leveloffset = child:GetFrameLevel() - frame:GetFrameLevel()
						child:SetParent(visual)
						child:SetFrameLevel(visual:GetFrameLevel() + leveloffset)
						frame[#frame + 1] = child
					end
				end
			end

			local function VP_ReparentRegions(frame, ...)
				local visual = plates[frame]
				for i = 1, select("#", ...) do
					local region = select(i, ...)
					region:SetParent(visual)
					frame[#frame + 1] = region
				end
			end

			local function VP_AddPlate(frame)
				local visual = CreateFrame("Frame", nil, frame)
				plates[frame] = visual

				visual:Hide()
				visual:SetPoint("TOP")
				visual:SetSize(frame:GetSize())

				VP_ReparentChildren(frame, frame:GetChildren())
				VP_ReparentRegions(frame, frame:GetRegions())
				visual:EnableDrawLayer("HIGHLIGHT")

				frame:SetScript("OnShow", mod.PlateOnShow)
				frame:SetScript("OnHide", mod.PlateOnHide)
				if frame:IsVisible() then
					mod.PlateOnShow(frame)
				end

				-- Hook methods
				for k, v in pairs(plateOverrde) do
					visual[k] = v
				end

				local depth = WorldFrame:GetDepth()
				WorldFrame:SetDepth(depth + 1)
				WorldFrame:SetDepth(depth)
			end

			local function VS_ScanePlates(...)
				for i = 1, select("#", ...) do
					local frame = select(i, ...)
					if not plates[frame] then
						local region = frame:GetRegions()
						if region and region:GetObjectType() == "Texture" and region:GetTexture() == [[Interface\TargetingFrame\UI-TargetingFrame-Flash]] then
							VP_AddPlate(frame)
						end
					end
				end
			end

			local ChildCount, NewChildCount = 0
			function mod:WorldFrameOnUpdate(elapsed)
				NewChildCount = self:GetNumChildren()
				if ChildCount ~= NewChildCount then
					ChildCount = NewChildCount
					VS_ScanePlates(WorldFrame_GetChildren(self))
				end

				nextUpdate = nextUpdate - elapsed
				if nextUpdate <= 0 then
					nextUpdate = updateRate
					return VP_PlatesUpdate()
				end
			end
		end

		local children = {}
		local function VP_ReplaceChildren(...)
			local count = select("#", ...)
			for i = 1, count do
				local frame = select(i, ...)
				children[i] = plates[frame] or frame
			end
			for i = count + 1, #children do
				children[i] = nil
			end
			return unpack(children)
		end

		function WorldFrame:GetChildren(...)
			return VP_ReplaceChildren(WorldFrame_GetChildren(self, ...))
		end
	end

	function mod.frame:OnEvent(event, ...)
		if self[event] then
			self[event](self, event, ...)
		end
	end

	local GetParent = mod.frame.GetParent
	do
		local function VP_PlateOverride(func)
			plateOverrde[func] = function(self, ...)
				local frame = GetParent(self)
				return frame[func](frame, ...)
			end
		end
		VP_PlateOverride("GetParent")
		VP_PlateOverride("SetAlpha")
		VP_PlateOverride("GetAlpha")
		VP_PlateOverride("GetEffectiveAlpha")
	end

	do
		local function OnUpdateOverride(self, ...)
			self.OnUpdate(plates[self], ...)
		end

		local SetScript = mod.frame.SetScript
		function plateOverrde:SetScript(script, handler, ...)
			if (type(script) == "string" and script:lower() == "onupdate") then
				local frame = GetParent(self)
				frame.OnUpdate = handler
				return frame:SetScript(script, handler and OnUpdateOverride or nil, ...)
			else
				return SetScript(self, script, handler, ...)
			end
		end

		local GetScript = mod.frame.GetScript
		function plateOverrde:GetScript(script, ...)
			if type(script) == "string" and script:lower() == "onupdate" then
				return GetParent(self).OnUpdate
			else
				return GetScript(self, script, ...)
			end
		end

		local HookScript = mod.frame.HookScript
		function plateOverrde:HookScript(script, handler, ...)
			if (type(script) == "string" and script:lower() == "onupdate") then
				local frame = GetParent(self)
				if frame.OnUpdate then
					local backup = frame.OnUpdate
					frame.OnUpdate = function(self, ...)
						backup(self, ...)
						return handler(self, ...)
					end
				else
					frame.OnUpdate = handler
				end
				return frame:SetScript(script, OnUpdateOverride, ...)
			else
				return HookScript(self, script, handler, ...)
			end
		end
	end

	local options
	local function GetOptions()
		if not options then
			options = {
				type = "group",
				name = L["Virtual Plates"],
				get = function(i)
					return DB[i[#i]] or defaults[i[#i]]
				end,
				set = function(i, val)
					DB[i[#i]] = val
				end,
				args = {
					scaleFactor = {
						type = "range",
						name = L["Scale Factor"],
						desc = L["Nameplates this far from the camera will be normal sized."],
						min = 5,
						max = 40,
						step = 1,
						width = "double",
						order = 10
					},
					scale = {
						type = "group",
						name = L["Nameplate Scale Limits"],
						inline = true,
						order = 20,
						args = {
							minScale = {
								type = "range",
								name = L["Minimum Scale"],
								desc = L["Limits how small nameplates can shrink, from 0 meaning no limit, to 1 meaning they won't shrink smaller than their default size."],
								min = 0,
								max = 1,
								step = 0.01,
								isPercent = true,
								width = "double",
								order = 10
							},
							maxScale = {
								type = "range",
								name = L["Maximum Scale"],
								desc = L["Prevents nameplates from growing too large when they're near the screen.\nSet to -1 to disable."],
								min = -0.01,
								max = 10,
								step = 0.01,
								isPercent = true,
								width = "double",
								order = 20
							}
						}
					}
				}
			}
		end
		return options
	end

	core:RegisterForEvent("PLAYER_LOGIN", function()
		SetupDatabase()
		core.options.args.Options.args.VirtualPlates = GetOptions()

		WorldFrame:HookScript("OnUpdate", mod.WorldFrameOnUpdate)
		mod.frame:SetScript("OnEvent", mod.frame.OnEvent)
	end)
end)