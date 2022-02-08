assert(KPack, "KPack not found!")
KPack:AddModule("Minimapicon", "Shows minimap icon",function(_, core, L)
	if core:IsDisabled("Minimapicon") then return end
	
	local mod = core.Minimapicon or {}
	core.Minimapicon = mod

	local MMB_Config
	defaultsDB = {
		Enabled = true,
	}	
	
	local PLAYER_ENTERING_WORLD
	
	local menuIcon = CreateFrame("Button", "MyMenuIconButton", Minimap)
	menuIcon:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight");
	menuIcon:SetWidth(32)
	menuIcon:SetHeight(32)
	menuIcon:SetFrameStrata("LOW")
	menuIcon:SetMovable(true)
	menuIcon:RegisterForDrag("LeftButton")
	menuIcon:RegisterForClicks("AnyUp");
	menuIcon:SetPoint("CENTER", -12, -80)

	menuIcon.icon = menuIcon:CreateTexture(nil, "BACKGROUND")
	menuIcon.icon:SetTexture("Interface\\Icons\\Achievement_Reputation_KirinTor") 
	menuIcon.icon:SetWidth(22);
	menuIcon.icon:SetHeight(22);
	menuIcon.icon:SetPoint("CENTER", 0, 0)

	menuIcon.border = menuIcon:CreateTexture(nil, "ARTWORK")
	menuIcon.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
	menuIcon.border:SetTexCoord(0,0.6,0,0.6);
	menuIcon.border:SetAllPoints(menuIcon);

	local minimapShapes = {
		["ROUND"] = {true, true, true, true},
		["SQUARE"] = {false, false, false, false},
		["CORNER-TOPLEFT"] = {true, false, false, false},
		["CORNER-TOPRIGHT"] = {false, false, true, false},
		["CORNER-BOTTOMLEFT"] = {false, true, false, false},
		["CORNER-BOTTOMRIGHT"] = {false, false, false, true},
		["SIDE-LEFT"] = {true, true, false, false},
		["SIDE-RIGHT"] = {false, false, true, true},
		["SIDE-TOP"] = {true, false, true, false},
		["SIDE-BOTTOM"] = {false, true, false, true},
		["TRICORNER-TOPLEFT"] = {true, true, true, false},
		["TRICORNER-TOPRIGHT"] = {true, false, true, true},
		["TRICORNER-BOTTOMLEFT"] = {true, true, false, true},
		["TRICORNER-BOTTOMRIGHT"] = {false, true, true, true},
	}

	
	local function onupdate(self)
		if self.isMoving then
			
			local mx, my = Minimap:GetCenter()
			local px, py = GetCursorPosition()
			local scale = Minimap:GetEffectiveScale()
			px, py = px / scale, py / scale
		
			local angle = math.rad(math.deg(math.atan2(py - my, px - mx)) % 360)
			
			local x, y, q = math.cos(angle), math.sin(angle), 1
			if x < 0 then q = q + 1 end
			if y > 0 then q = q + 2 end
			
			local minimapShape = GetMinimapShape and GetMinimapShape() or "ROUND"
			local quadTable = minimapShapes[minimapShape]
			if quadTable[q] then
				x, y = x*80, y*80
			else
				local diagRadius = 103.13708498985 --math.sqrt(2*(80)^2)-10
				x = math.max(-80, math.min(x*diagRadius, 80));
				y = math.max(-80, math.min(y*diagRadius, 80));
			end
			self:ClearAllPoints();
			self:SetPoint("CENTER", Minimap, "CENTER", x, y);
		end
	end
	
	menuIcon:SetScript("OnMouseDown", function(self, button)
		self.icon:SetPoint("CENTER", 1, -1);
	end);
	
	menuIcon:SetScript("OnMouseUp", function(self, button)
		self.icon:SetPoint("CENTER", 0, 0);
	end);
	
	menuIcon:SetScript("OnClick", function(self, button)
		core:OpenConfig()
	end)
	
	menuIcon:SetScript("OnDragStart",
		function(self)
			if IsShiftKeyDown() then
				self.isMoving = true
				self:SetScript("OnUpdate", function(self) onupdate(self) end)
			end
		end)
	
	menuIcon:SetScript("OnDragStop",
		function(self)
			self.isMoving = nil
			self:SetScript("OnUpdate", nil)
			self:SetUserPlaced(true)
		end)
	
	menuIcon:SetScript("OnEnter",
		function(self)
			GameTooltip:SetOwner(self, "ANCHOR_LEFT")
			
			GameTooltip:ClearLines()
			GameTooltip:AddLine("|cfff58cbaKader|r|caaf49141Pack|r " .. core.version)
			GameTooltip:AddLine(L["|cfff58cbaClick|r to toggle the settings window"],1,1,1)
			GameTooltip:Show()
		end)
	
	menuIcon:SetScript("OnLeave", function(self) 
		GameTooltip:Hide();
		self.icon:SetPoint("CENTER", 0, 0);
	end) 
	
	local function SetupDatabase()
		if not MMB_Config then
			if type(core.db.Minimapicon) ~= "table" or not next(core.db.Minimapicon) then
				core.db.Minimapicon = CopyTable(defaultsDB)
			end
			MMB_Config = core.db.Minimapicon
		end
	end
	
	function PLAYER_ENTERING_WORLD()
		SetupDatabase()	
		if not MMB_Config.Enabled then
			menuIcon:Hide()
		end
	end
	
	local options = {
			type = "group",
			name = L["Minimap Icon"],
			get = function(i)
				return MMB_Config[i[#i]]
			end,
			set = function(i, val)
				MMB_Config[i[#i]] = val
			end,
				args = {
					Enabled = {
						type = "toggle",
						name = L["Enable"],
						order = 1,
						width = "full",
						get = function(i) return MMB_Config[i[#i]] end,
						set = function(info,v) MMB_Config[info[#info]] = v; if v then menuIcon:Show() else menuIcon:Hide() end; end,
							},							
				},
			}
	core:RegisterForEvent("PLAYER_LOGIN", function()
			core.options.args.Options.args.Minimapicon = options

			SLASH_KPACKMINIMAP1 = "/minimapicon"
			SlashCmdList["KPACKMINIMAP"] = function()
				core:OpenConfig("Options", "Minimapicon")
			end
		end)
	core:RegisterForEvent("PLAYER_ENTERING_WORLD", PLAYER_ENTERING_WORLD)
end)