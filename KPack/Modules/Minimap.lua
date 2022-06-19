local core = KPack
if not core then return end
core:AddModule("Minimap", "|cff00ff00/mm, /minimap|r", function(L)
	if core:IsDisabled("Minimap") or core.ElvUI then return end

	-- list of addons for which the module is disabled
	-- add as many addons as you want, i just added few.
	local disabled, reason = core:AddOnIsLoaded("SexyMap", "MinimapBar", "KkthnxUI")

	if not disabled and core:AddOnHasModule("Dominos", "minimap") then
		disabled, reason = true, "Dominos"
	end

	local pairs, ipairs, select = pairs, ipairs, select
	local UnitName, UnitClass = UnitName, UnitClass
	local UIFrameFlash = UIFrameFlash

	local DB, SetupDatabase
	local defaults = {
		enabled = true,
		grabber = true,
		locked = true,
		hide = false,
		zone = false,
		scale = 1,
		combat = false,
		moved = false,
		point = "TOPRIGHT",
		x = 0,
		y = 0
	}

	-- cache frequently used globals
	local ToggleCharacter = ToggleCharacter
	local ToggleSpellBook = ToggleSpellBook
	local ToggleTalentFrame = ToggleTalentFrame
	local ToggleAchievementFrame = ToggleAchievementFrame
	local ToggleFriendsFrame = ToggleFriendsFrame
	local ToggleHelpFrame = ToggleHelpFrame
	local ToggleFrame = ToggleFrame

	local PLAYER_ENTERING_WORLD, Minimap_GrabButtons

	local function Print(msg)
		core:Print(msg, "Minimap")
	end

	function SetupDatabase()
		if not DB then
			if type(core.db.Minimap) ~= "table" or next(core.db.Minimap) == nil then
				core.db.Minimap = CopyTable(defaults)
			end
			DB = core.db.Minimap
		end
	end

	--------------------------------------------------------------------------------

	local SlashCommandHandler
	do
		local exec = {}
		local help = "|cffffd700%s|r: %s"

		exec.enable = function()
			if not DB.enabled then
				DB.enabled = true
				Print(L:F("module status: %s", L["|cff00ff00enabled|r"]))
				Print(L["Please reload ui."])
				PLAYER_ENTERING_WORLD()
			end
		end
		exec.on = exec.enable

		exec.disable = function()
			if DB.enabled then
				DB.enabled = false
				Print(L:F("module status: %s", L["|cff00ff00enabled|r"]))
				Print(L["Please reload ui."])
				PLAYER_ENTERING_WORLD()
			end
		end
		exec.off = exec.disable

		exec.lock = function()
			if not DB.locked then
				DB.locked = true
				Print(L["minimap locked."])
				PLAYER_ENTERING_WORLD()
			end
		end

		exec.unlock = function()
			if DB.locked then
				DB.locked = false
				Print(L["minimap unlocked. Hold SHIFT+ALT to move it."])
				PLAYER_ENTERING_WORLD()
			end
		end

		exec.show = function()
			if DB.hide then
				DB.hide = false
				Print(L["minimap shown."])
				PLAYER_ENTERING_WORLD()
			end
		end

		exec.hide = function()
			if not DB.hide then
				DB.hide = true
				Print(L["minimap hidden."])
				PLAYER_ENTERING_WORLD()
			end
		end

		exec.hidezone = function()
			if not DB.zone then
				DB.zone = true
			else
				DB.zone = false
			end
			PLAYER_ENTERING_WORLD()
		end
		exec.zone = exec.hidezone

		exec.combat = function()
			DB.combat = not DB.combat
			if DB.combat then
				Print(L:F("hide in combat: %s", L["|cff00ff00ON|r"]))
			else
				Print(L:F("hide in combat: %s", L["|cffff0000OFF|r"]))
				if not DB.hide and not MinimapCluster:IsShown() then
					MinimapCluster:Show()
				end
			end
			PLAYER_ENTERING_WORLD()
		end

		exec.scale = function(n)
			n = tonumber(n)
			if n then
				DB.scale = n
				PLAYER_ENTERING_WORLD()
			end
		end

		exec.reset = function()
			-- moved? Put it back to its position
			if DB.moved then
				MinimapCluster:ClearAllPoints()
				MinimapCluster:SetPoint(defaults.point, defaults.x, defaults.y)
			end
			wipe(DB)
			DB = defaults
			Print(L["module's settings reset to default."])
			PLAYER_ENTERING_WORLD()
		end
		exec.defaults = exec.reset

		function SlashCommandHandler(msg)
			local cmd, rest = strsplit(" ", msg, 2)
			if type(exec[cmd]) == "function" then
				exec[cmd](rest)
			elseif cmd == "config" or cmd == "options" then
				core:OpenConfig("Options", "Minimap")
			else
				Print(L:F("Acceptable commands for: |caaf49141%s|r", "/mm"))
				print(format(help, "enable", L["enable module"]))
				print(format(help, "disable", L["disable module"]))
				print(format(help, "show", L["show minimap"]))
				print(format(help, "hide", L["hide minimap"]))
				print(format(help, "zone", L["hide zone text"]))
				print(format(help, "combat", L["toggle hiding minimap in combat"]))
				print(format(help, "scale|r |cff00ffffn|r", L["change minimap scale"]))
				print(format(help, "lock", L["lock the minimap"]))
				print(format(help, "unlock", L["unlocks the minimap"]))
				print(format(help, "config", L["Access module settings."]))
				print(format(help, "reset", L["Resets module settings to default."]))
				print(L["Once unlocked, the minimap can be moved by holding both SHIFT and ALT buttons."])
			end
		end
	end

	--------------------------------------------------------------------------------

	core:RegisterForEvent("PLAYER_LOGIN", function()
		SetupDatabase()

		local function _disabled()
			return not DB.enabled or disabled
		end
		core.options.args.Options.args.Minimap = {
			type = "group",
			name = MINIMAP_LABEL,
			get = function(i)
				return DB[i[#i]]
			end,
			set = function(i, val)
				DB[i[#i]] = val
				PLAYER_ENTERING_WORLD()
			end,
			args = {
				status = {
					type = "description",
					name = L:F("This module is disabled because you are using: |cffffd700%s|r", reason or UNKNOWN),
					fontSize = "medium",
					order = 0,
					hidden = not disabled
				},
				enabled = {
					type = "toggle",
					name = L["Enable"],
					order = 1,
					disabled = disabled
				},
				grabber = {
					type = "toggle",
					name = L["Button Grabber"],
					order = 2,
					disabled = _disabled
				},
				locked = {
					type = "toggle",
					name = L["Lock Minimap"],
					order = 3,
					disabled = _disabled
				},
				hide = {
					type = "toggle",
					name = L["Hide Minimap"],
					order = 4,
					disabled = _disabled
				},
				zone = {
					type = "toggle",
					name = L["Hide Zone Text"],
					order = 5,
					disabled = _disabled
				},
				combat = {
					type = "toggle",
					name = L["Hide in combat"],
					order = 6,
					disabled = _disabled
				},
				scale = {
					type = "range",
					name = L["Scale"],
					order = 7,
					disabled = _disabled,
					width = "double",
					min = 0.5,
					max = 3,
					step = 0.01,
					bigStep = 0.1
				},
				reset = {
					type = "execute",
					name = RESET,
					order = 99,
					disabled = _disabled,
					width = "double",
					confirm = function()
						return L:F("Are you sure you want to reset %s to default?", MINIMAP_LABEL)
					end,
					func = function()
						wipe(core.db.Minimap)
						DB = nil
						SetupDatabase()
						Print(L["module's settings reset to default."])
						PLAYER_ENTERING_WORLD()
					end
				}
			}
		}

		if not DB.enabled then
			disabled = true
			return
		end
	end)

	--------------------------------------------------------------------------------

	do
		local find, len, sub = string.find, string.len, string.sub
		local ceil, unpack, tinsert = math.ceil, unpack, table.insert

		local LockButton, UnlockButton
		local CheckVisibility, GetVisibleList
		local GrabMinimapButtons, SkinMinimapButton, UpdateLayout

		local ignoreButtons = {
			"BattlefieldMinimap",
			"ButtonCollectFrame",
			"GameTimeFrame",
			"MiniMapBattlefieldFrame",
			"MiniMapLFGFrame",
			"MiniMapMailFrame",
			"MiniMapPing",
			"MiniMapRecordingButton",
			"MiniMapTracking",
			"MiniMapTrackingButton",
			"MiniMapVoiceChatFrame",
			"MiniMapWorldMapButton",
			"Minimap",
			"MinimapBackdrop",
			"MinimapToggleButton",
			"MinimapZoneTextButton",
			"MinimapZoomIn",
			"MinimapZoomOut",
			"TimeManagerClockButton"
		}

		local genericIgnores = {
			"GuildInstance",
			"GatherMatePin",
			"GatherNote",
			"GuildMap3Mini",
			"HandyNotesPin",
			"LibRockConfig-1.0_MinimapButton",
			"NauticusMiniIcon",
			"WestPointer",
			"poiMinimap",
			"Spy_MapNoteList_mini"
		}

		local partialIgnores = {"Node", "Note", "Pin"}
		local whiteList = {"LibDBIcon"}
		local buttonFunctions = {
			"SetParent",
			"SetFrameStrata",
			"SetFrameLevel",
			"ClearAllPoints",
			"SetPoint",
			"SetScale",
			"SetSize",
			"SetWidth",
			"SetHeight"
		}

		local grabberFrame, needUpdate
		local minimapFrames, skinnedButtons

		function LockButton(btn)
			for _, func in ipairs(buttonFunctions) do
				btn[func] = core.Noop
			end
		end

		function UnlockButton(btn)
			for _, func in ipairs(buttonFunctions) do
				btn[func] = nil
			end
		end

		function CheckVisibility()
			local updateLayout

			for _, button in ipairs(skinnedButtons) do
				if button:IsVisible() and button.__hidden then
					button.__hidden = false
					updateLayout = true
				elseif not button:IsVisible() and not button.__hidden then
					button.__hidden = true
					updateLayout = true
				end
			end

			return updateLayout
		end

		function GetVisibleList()
			local t = {}

			for _, button in ipairs(skinnedButtons) do
				if button:IsVisible() then
					tinsert(t, button)
				end
			end

			return t
		end

		function GrabMinimapButtons()
			for _, frame in ipairs(minimapFrames) do
				for i = 1, frame:GetNumChildren() do
					local object = select(i, frame:GetChildren())

					if object and object:IsObjectType("Button") then
						SkinMinimapButton(object)
					end
				end
			end

			if _G.MiniMapMailFrame then
				SkinMinimapButton(_G.MiniMapMailFrame)
			end

			if _G.AtlasButtonFrame then
				SkinMinimapButton(_G.AtlasButton)
			end
			if _G.FishingBuddyMinimapFrame then
				SkinMinimapButton(_G.FishingBuddyMinimapButton)
			end
			if _G.HealBot_MMButton then
				SkinMinimapButton(_G.HealBot_MMButton)
			end

			if needUpdate or CheckVisibility() then
				UpdateLayout()
			end
		end

		function SkinMinimapButton(button)
			if not button or button.__skinned then return end

			local name = button:GetName()
			if not name then return end

			if button:IsObjectType("Button") then
				local validIcon

				for i = 1, #whiteList do
					if sub(name, 1, len(whiteList[i])) == whiteList[i] then
						validIcon = true
						break
					end
				end

				if not validIcon then
					if tContains(ignoreButtons, name) then
						return
					end

					for i = 1, #genericIgnores do
						if sub(name, 1, len(genericIgnores[i])) == genericIgnores[i] then
							return
						end
					end

					for i = 1, #partialIgnores do
						if find(name, partialIgnores[i]) then
							return
						end
					end
				end

				button:SetPushedTexture(nil)
				button:SetHighlightTexture(nil)
				button:SetDisabledTexture(nil)
			end

			for i = 1, button:GetNumRegions() do
				local region = select(i, button:GetRegions())

				if region:GetObjectType() == "Texture" then
					local texture = region:GetTexture()

					if texture and (find(texture, "Border") or find(texture, "Background") or find(texture, "AlphaMask")) then
						region:SetTexture(nil)
					else
						if name == "BagSync_MinimapButton" then
							region:SetTexture("Interface\\AddOns\\BagSync\\media\\icon")
						elseif name == "DBMMinimapButton" then
							region:SetTexture("Interface\\Icons\\INV_Helmet_87")
						elseif name == "OutfitterMinimapButton" then
							if region:GetTexture() == "Interface\\Addons\\Outfitter\\Textures\\MinimapButton" then
								region:SetTexture(nil)
							end
						elseif name == "SmartBuff_MiniMapButton" then
							region:SetTexture("Interface\\Icons\\Spell_Nature_Purge")
						elseif name == "VendomaticButtonFrame" then
							region:SetTexture("Interface\\Icons\\INV_Misc_Rabbit_2")
						end

						region:ClearAllPoints()
						region:SetPoint("TOPLEFT", 2, -2)
						region:SetPoint("BOTTOMRIGHT", -2, 2)
						region:SetDrawLayer("ARTWORK")
						region.SetPoint = core.Noop
					end
				end
			end

			button:SetParent(grabberFrame)
			button:SetFrameLevel(grabberFrame:GetFrameLevel() + 5)
			button:SetBackdrop({
				bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				insets = {left = 0, right = 0, top = 0, bottom = 0}
			})

			LockButton(button)

			button:SetScript("OnDragStart", nil)
			button:SetScript("OnDragStop", nil)

			button.__hidden = button:IsVisible() and true or false
			button.__skinned = true
			tinsert(skinnedButtons, button)

			needUpdate = true
		end

		function UpdateLayout()
			if #skinnedButtons == 0 then return end

			local spacing = 2
			local visibleButtons = GetVisibleList()

			if #visibleButtons == 0 then
				grabberFrame:SetSize(21 + (spacing * 2), 21 + (spacing * 2))
				return
			end

			local numButtons = #visibleButtons
			local buttonsPerRow = 6
			local numColumns = ceil(numButtons / buttonsPerRow)

			if buttonsPerRow > numButtons then
				buttonsPerRow = numButtons
			end

			local barWidth = (21 * numColumns) + (1 * (numColumns - 1)) + spacing * 2
			local barHeight = (21 * buttonsPerRow) + (1 * (buttonsPerRow - 1)) + spacing * 2

			grabberFrame:SetSize(barWidth, barHeight)

			for i, button in ipairs(visibleButtons) do
				UnlockButton(button)

				button:SetSize(21, 21)
				button:ClearAllPoints()

				if i == 1 then
					button:SetPoint("TOPRIGHT", grabberFrame, "TOPRIGHT")
				elseif (i - 1) % buttonsPerRow == 0 then
					button:SetPoint("RIGHT", visibleButtons[i - buttonsPerRow], "LEFT", -spacing, 0)
				else
					button:SetPoint("TOP", visibleButtons[i - 1], "BOTTOM", 0, -spacing)
				end

				LockButton(button)
			end

			needUpdate = nil
		end

		function Minimap_GrabButtons()
			if not DB.grabber then return end
			skinnedButtons = core.WeakTable(skinnedButtons)
			minimapFrames = {Minimap, MinimapBackdrop}

			grabberFrame = CreateFrame("Frame", "KPack_MinimapButtonGrabber", Minimap)
			grabberFrame:SetSize(21, 21)
			grabberFrame:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", -2, -2)
			grabberFrame:SetFrameStrata("LOW")
			grabberFrame:SetClampedToScreen(true)

			GrabMinimapButtons()
			core.NewTicker(5, GrabMinimapButtons)
		end
	end

	--------------------------------------------------------------------------------

	do
		local backdrop = {
			bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
			edgeFile = [[Interface\ChatFrame\ChatFrameBackground]],
			edgeSize = 1,
			insets = {top = 0, left = 0, bottom = 0, right = 0}
		}

		-- the dopdown menu frame
		local menuFrame

		-- menu list
		local menuList = {
			{
				text = CHARACTER_BUTTON,
				notCheckable = 1,
				func = function()
					ToggleCharacter("PaperDollFrame")
				end
			},
			{
				text = SPELLBOOK_ABILITIES_BUTTON,
				notCheckable = 1,
				func = function()
					ToggleFrame(SpellBookFrame)
				end
			},
			{
				text = TALENTS_BUTTON,
				notCheckable = 1,
				func = ToggleTalentFrame
			},
			{
				text = ACHIEVEMENT_BUTTON,
				notCheckable = 1,
				func = ToggleAchievementFrame
			},
			{
				text = QUESTLOG_BUTTON,
				notCheckable = 1,
				func = function()
					ToggleFrame(QuestLogFrame)
				end
			},
			{
				text = SOCIAL_BUTTON,
				notCheckable = 1,
				func = function()
					ToggleFriendsFrame(1)
				end
			},
			{
				text = L["Calendar"],
				notCheckable = 1,
				func = function()
					GameTimeFrame:Click()
				end
			},
			{
				text = BATTLEFIELD_MINIMAP,
				notCheckable = 1,
				func = ToggleBattlefieldMinimap
			},
			{
				text = TIMEMANAGER_TITLE,
				notCheckable = 1,
				func = ToggleTimeManager
			},
			{
				text = PLAYER_V_PLAYER,
				notCheckable = 1,
				func = function()
					ToggleFrame(PVPParentFrame)
				end
			},
			{
				text = LFG_TITLE,
				notCheckable = 1,
				func = function()
					ToggleFrame(LFDParentFrame)
				end
			},
			{
				text = LOOKING_FOR_RAID,
				notCheckable = 1,
				func = function()
					ToggleFrame(LFRParentFrame)
				end
			},
			{
				text = MAINMENU_BUTTON,
				notCheckable = 1,
				func = function()
					if GameMenuFrame:IsShown() then
						PlaySound("igMainMenuQuit")
						HideUIPanel(GameMenuFrame)
					else
						PlaySound("igMainMenuOpen")
						ShowUIPanel(GameMenuFrame)
					end
				end
			},
			{
				text = HELP_BUTTON,
				notCheckable = 1,
				func = ToggleHelpFrame
			}
		}

		-- handles mouse wheel action on minimap
		local function Minimap_OnMouseWheel(self, z)
			local c = Minimap:GetZoom()
			if z > 0 and c < 5 then
				Minimap:SetZoom(c + 1)
			elseif (z < 0 and c > 0) then
				Minimap:SetZoom(c - 1)
			end
		end

		local function Cluster_OnMouseDown(self, button)
			if DB.lock then return end
			if button == "LeftButton" and not MinimapCluster.isMoving then
				MinimapCluster:SetMovable(true)
				MinimapCluster.isMoving = true
				MinimapCluster:StartMoving()
			end
		end

		local function Cluster_OnMouseUp(self, button)
			if DB.lock then return end
			if button == "LeftButton" and MinimapCluster.isMoving then
				MinimapCluster.isMoving = nil
				MinimapCluster:StopMovingOrSizing()
				local point, _, _, xOfs, yOfs = MinimapCluster:GetPoint(1)
				DB.moved = true
				DB.point = point
				DB.x = xOfs
				DB.y = yOfs
			end
		end

		-- handle mouse clicks on minimap
		local function Minimap_OnMouseUp(self, button)
			-- create the menu frame
			menuFrame = menuFrame or CreateFrame("Frame", "KPack_MinimapRightClickMenu", UIParent, "UIDropDownMenuTemplate")

			if button == "RightButton" then
				EasyMenu(menuList, menuFrame, "cursor", 0, 0, "MENU", 2)
			elseif button == "MiddleButton" then
				ToggleDropDownMenu(1, nil, MiniMapTrackingDropDown, self)
			else
				Minimap_OnClick(self)
			end
		end

		-- called once the user enter the world
		function PLAYER_ENTERING_WORLD()
			if disabled then return end

			-- fix the stupid buff with MoveAnything Condolidate buffs
			if not (_G.MOVANY or _G.MovAny or core.MA) then
				ConsolidatedBuffs:SetParent(UIParent)
				ConsolidatedBuffs:ClearAllPoints()
				ConsolidatedBuffs:SetPoint("TOPRIGHT", -205, -13)
				ConsolidatedBuffs.SetPoint = core.Noop
			end

			for i, v in pairs({
				MinimapBorder,
				MiniMapMailBorder,
				_G.QueueStatusMinimapButtonBorder,
				-- select(1, TimeManagerClockButton:GetRegions()),
				select(1, GameTimeFrame:GetRegions())
			}) do
				v:SetVertexColor(.3, .3, .3)
			end

			MinimapBorderTop:Hide()
			MinimapZoomIn:Hide()
			MinimapZoomOut:Hide()
			MiniMapWorldMapButton:Hide()
			core:Kill(GameTimeFrame)
			core:Kill(MiniMapTracking)
			MinimapZoneText:SetPoint("TOPLEFT", "MinimapZoneTextButton", "TOPLEFT", 5, 5)
			if DB.zone then
				MinimapZoneTextButton:Hide()
			else
				MinimapZoneTextButton:Show()
			end
			Minimap:EnableMouseWheel(true)

			Minimap:SetScript("OnMouseWheel", Minimap_OnMouseWheel)
			Minimap:SetScript("OnMouseUp", Minimap_OnMouseUp)

			-- Make is square
			MinimapBorder:SetTexture(nil)
			Minimap:SetFrameLevel(2)
			Minimap:SetFrameStrata("BACKGROUND")
			Minimap:SetMaskTexture([[Interface\ChatFrame\ChatFrameBackground]])
			Minimap:SetBackdrop({
				bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
				insets = {top = -2, bottom = -1, left = -2, right = -1}
			})
			Minimap:SetBackdropColor(0, 0, 0, 1)
			MinimapCluster:SetScale(DB.scale or 1)

			if DB.hide then
				MinimapCluster:Hide()
			elseif not DB.combat and not core.InCombat then
				MinimapCluster:Show()
			end

			if DB.locked then
				if MinimapCluster.handle then
					MinimapCluster.handle:EnableMouse(false)
					MinimapCluster.handle:SetMovable(false)
					MinimapCluster.handle:RegisterForDrag(nil)
					MinimapCluster.handle:SetScript("OnMouseDown", nil)
					MinimapCluster.handle:SetScript("OnMouseUp", nil)
					MinimapCluster.handle:Hide()
				end
			else
				if not MinimapCluster.handle then
					MinimapCluster.handle = CreateFrame("Frame", nil, Minimap)
					MinimapCluster.handle:SetAllPoints(MinimapCluster)
					MinimapCluster.handle:SetBackdrop(backdrop)
					MinimapCluster.handle:SetBackdropColor(1, 0, 0, 0.5)
					MinimapCluster.handle:SetBackdropBorderColor(0, 0, 0, 1)
					MinimapCluster.handle:SetClampedToScreen(true)
				end

				MinimapCluster.handle:EnableMouse(true)
				MinimapCluster.handle:SetMovable(true)
				MinimapCluster.handle:RegisterForDrag("LeftButton")
				MinimapCluster.handle:SetScript("OnMouseDown", Cluster_OnMouseDown)
				MinimapCluster.handle:SetScript("OnMouseUp", Cluster_OnMouseUp)
				MinimapCluster.handle:Show()
			end

			-- move to position
			if DB.moved then
				MinimapCluster:ClearAllPoints()
				MinimapCluster:SetPoint(DB.point, DB.x, DB.y)
			end

			Minimap_GrabButtons()
		end
		core:RegisterForEvent("PLAYER_ENTERING_WORLD", PLAYER_ENTERING_WORLD)
	end

	core:RegisterForEvent("PLAYER_REGEN_ENABLED", function()
		if not disabled and DB.enabled and DB.combat and not MinimapCluster:IsShown() and not DB.hide then
			MinimapCluster:Show()
		end
	end)

	core:RegisterForEvent("PLAYER_REGEN_DISABLED", function()
		if not disabled and DB.enabled and DB.combat and MinimapCluster:IsShown() then
			MinimapCluster:Hide()
		end
	end)

	SlashCmdList["KPACKMINIMAP"] = SlashCommandHandler
	SLASH_KPACKMINIMAP1, SLASH_KPACKMINIMAP2 = "/minimap", "/mm"

	local pinger, timer
	local frame = CreateFrame("Frame")
	core:RegisterForEvent("MINIMAP_PING", function(_, unit, coordx, coordy)
		if UnitName(unit) ~= core.name then
			-- create the pinger
			if not pinger then
				pinger = frame:CreateFontString(nil, "OVERLAY")
				pinger:SetFont("Fonts\\FRIZQT__.ttf", 13, "OUTLINE")
				pinger:SetPoint("CENTER", Minimap, "CENTER", 0, 0)
				pinger:SetJustifyH("CENTER")
			end

			if timer and time() - timer > 1 or not timer then
				local Class = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS[select(2, UnitClass(unit))]
				pinger:SetText(format("|cffff0000*|r %s |cffff0000*|r", UnitName(unit)))
				pinger:SetTextColor(Class.r, Class.g, Class.b)
				UIFrameFlash(frame, 0.2, 2.8, 5, false, 0, 5)
				timer = time()
			end
		end
	end)

	local taint = CreateFrame("Frame")
	taint:RegisterEvent("PLAYER_ENTERING_WORLD")
	taint:SetScript("OnEvent", function(self)
		ToggleFrame(SpellBookFrame)
		ToggleFrame(SpellBookFrame)
	end)
end)