assert(KPack, "KPack not found!")
local folder, core = ...
local L = core.L

local tinsert = table.insert
local tremove = table.remove
local twipe = table.wipe
local tsort = table.sort
local tgetn = table.getn
local pairs, ipairs = pairs, ipairs
local next, select, type = next, select, type
local strfind = string.find
local strmatch = string.match
local strformat = string.format
local strsub = string.sub
local strlen = string.len
local GetScreenWidth = GetScreenWidth
local GetScreenHeight = GetScreenHeight

local MAGetScale
local MADebug
local MAPrint
local echo, decho, dechoSub

local DB
local function SetupDatabase()
	if not DB then
		if type(core.db.MoveAnything) ~= "table" or not next(core.db.MoveAnything) then
			core.db.MoveAnything = {
				CustomFrames = {},
				CharacterSettings = {},
				UseCharacterSettings = false
			}
		end
		DB = core.db.MoveAnything
	end
end
core:RegisterForEvent("PLAYER_LOGIN", function()
	SetupDatabase()
	local hasElvui = (core.ElvUI and core.ElvUI:GetModule("ElvUI_Enhanced", true) ~= nil)
	if core:IsDisabled(ADDONS) or hasElvui then
		GameMenuButtonMoveAnything:ClearAllPoints()
		if hasElvui then
			GameMenuButtonMoveAnything:SetPoint("TOP", GameMenuFrame, "BOTTOM", 0, -5)
		else
			GameMenuButtonMoveAnything:SetPoint("TOP", GameMenuButtonMacros, "BOTTOM", 0, -1)
			GameMenuButtonLogout:SetPoint("TOP", GameMenuButtonMoveAnything, "BOTTOM", 0, -16)
			GameMenuFrame:SetHeight(GameMenuFrame:GetHeight() + 26)
		end
	end
end)

local function void()
end

-- X: http://lua-users.org/wiki/CopyTable
local function tdeepcopy(object)
	local lookup_table = {}
	local function _copy(object)
		if type(object) ~= "table" then
			return object
		elseif lookup_table[object] then
			return lookup_table[object]
		end
		local new_table = {}
		lookup_table[object] = new_table
		for index, value in pairs(object) do
			new_table[_copy(index)] = _copy(value)
		end
		return setmetatable(new_table, getmetatable(object))
	end
	return _copy(object)
end

local function tcopy(object)
	if type(object) ~= "table" then
		return object
	end
	local new_table = {}
	for index, value in pairs(object) do
		new_table[index] = value
	end
	return setmetatable(new_table, getmetatable(object))
end

local function tlen(t)
	local i = 0
	if t ~= nil then
		for k in pairs(t) do
			i = i + 1
		end
	end
	return i
end

local function dbg(s)
	MAPrint(s)
end

local MovAny = {
		guiLines = -1,
		resetConfirm = "",
		bagFrames = {},
		cats = {},
		createBeforeInteract = {
			AchievementAlertFrame1 = "AchievementAlertFrameTemplate",
			AchievementAlertFrame2 = "AchievementAlertFrameTemplate",
			GroupLootFrame1 = "GroupLootFrameTemplate",
			GroupLootFrame2 = "GroupLootFrameTemplate",
			GroupLootFrame3 = "GroupLootFrameTemplate",
			GroupLootFrame4 = "GroupLootFrameTemplate"
		},
		customCat = nil,
		runOnceBeforeInteract = {
			AchievementAlertFrame1 = AchievementFrame_LoadUI,
			AchievementAlertFrame2 = AchievementFrame_LoadUI,
			QuestLogDetailFrame = function()
				if not QuestLogDetailFrame:IsShown() then
					ShowUIPanel(QuestLogDetailFrame)
					HideUIPanel(QuestLogDetailFrame)
				end
			end
		},
		runBeforeInteract = {
			MainMenuBar = function()
				if not core.MA.FrameOptions["VehicleMenuBar"] or not core.MA.FrameOptions["VehicleMenuBar"].pos then
					local v = _G["VehicleMenuBar"]
					v:ClearAllPoints()
					v:SetPoint("BOTTOMLEFT", "UIParent", "BOTTOMLEFT", UIParent:GetWidth() / 2 - v:GetWidth() / 2, 0)
				end
			end,
			MultiBarLeft = function()
				if core.MA:IsFrameHooked("MultiBarLeftHorizontalMover") then
					core.MA:ResetFrame("MultiBarLeftHorizontalMover")
				end
			end,
			MultiBarRight = function()
				if core.MA:IsFrameHooked("MultiBarRightHorizontalMover") then
					core.MA:ResetFrame("MultiBarRightHorizontalMover")
				end
			end,
			MinimapCluster = function()
				Minimap:SetFrameStrata("LOW")
				if TimeManagerClockButton then
					TimeManagerClockButton:SetFrameStrata("MEDIUM")
				end
			end,
			PlayerFrame = function()
				PlayerFrame:SetFrameStrata("LOW")
			end,
			TimeManagerClockButton = function()
				TimeManagerClockButton:SetFrameStrata("MEDIUM")
			end,
			VehicleMenuBarActionButtonFrame = function()
				VehicleMenuBarActionButtonFrame:SetHeight(VehicleMenuBarActionButton1:GetHeight() + 2)
				VehicleMenuBarActionButtonFrame:SetWidth((VehicleMenuBarActionButton1:GetWidth() + 2) * VEHICLE_MAX_ACTIONBUTTONS)
			end,
			LFDSearchStatus = function()
				LFDSearchStatus:SetFrameStrata("TOOLTIP")
			end
		},
		runAfterInteract = {},
		defFrames = {},
		frameListSize = 17,
		frames = {},
		framesCount = 0,
		framesIdx = {},
		framesUnsupported = {},
		initRun = nil,
		lastFrameName = nil,
		lEnableMouse = {
			WatchFrame,
			DurabilityFrame,
			CastingBarFrame,
			WorldStateScoreFrame,
			WorldStateAlwaysUpFrame,
			AlwaysUpFrame1,
			AlwaysUpFrame2,
			WorldStateCaptureBar1,
			VehicleMenuBar,
			TargetFrameSpellBar,
			FocusFrameSpellBar,
			MirrorTimer1,
			MiniMapInstanceDifficulty
			--UIErrorsFrame,
		},
		lSimpleHide = {},
		lTranslate = {
			minimap = "MinimapCluster",
			tooltip = "TooltipMover",
			player = "PlayerFrame",
			target = "TargetFrame",
			tot = "TargetFrameToT",
			targetoftarget = "TargetFrameToT",
			pet = "PetFrame",
			focus = "FocusFrame",
			bags = "BagButtonsMover",
			keyring = "KeyRingFrame",
			castbar = "CastingBarFrame",
			buffs = "ConsolidatedBuffs",
			GameTooltip = "TooltipMover",
			ShapeshiftBarFrame = "ShapeshiftButtonsMover"
		},
		lTranslateSec = {
			PVPFrame = "PVPParentFrame",
			ShapeshiftBarFrame = "ShapeshiftButtonsMover"
		},
		lHideOnScale = {
			MainMenuExpBar = {
				MainMenuXPBarTexture0,
				MainMenuXPBarTexture1,
				MainMenuXPBarTexture2,
				MainMenuXPBarTexture3,
				ExhaustionTick,
				ExhaustionTickNormal,
				ExhaustionTickHighlight,
				ExhaustionLevelFillBar
			},
			ReputationWatchBar = {
				ReputationWatchBarTexture0,
				ReputationWatchBarTexture1,
				ReputationWatchBarTexture2,
				ReputationWatchBarTexture3,
				ReputationXPBarTexture0,
				ReputationXPBarTexture1,
				ReputationXPBarTexture2,
				ReputationXPBarTexture3
			}
		},
		lLinkedScaling = {
			BasicActionButtonsMover = {
				ActionBarDownButton = "ActionBarDownButton",
				ActionBarUpButton = "ActionBarUpButton"
			},
			ReputationWatchBar = {
				ReputationWatchStatusBar = "ReputationWatchStatusBar"
			},
			PlayerFrame = {
				ComboFrame = "ComboFrame"
			}
		},
		rendered = nil,
		nextFrameIdx = 1,
		pendingActions = {},
		pendingFrames = {},
		MAXMOVERS = 20,
		SCROLL_HEIGHT = 20,
		currentMover = 1,
		moverPrefix = "MAMover",
		ScaleWH = {
			MainMenuExpBar = "MainMenuExpBar",
			ReputationWatchBar = "ReputationWatchBar",
			ReputationWatchStatusBar = "ReputationWatchStatusBar",
			WatchFrame = "WatchFrame",
			ChatFrameEditBox = "ChatFrameEditBox"
		},
		DetachFromParent = {
			MainMenuBarPerformanceBarFrame = "UIParent",
			TargetofFocusFrame = "UIParent",
			PetFrame = "UIParent",
			PartyMemberFrame1PetFrame = "UIParent",
			PartyMemberFrame2PetFrame = "UIParent",
			PartyMemberFrame3PetFrame = "UIParent",
			PartyMemberFrame4PetFrame = "UIParent",
			DebuffButton1 = "UIParent",
			ReputationWatchBar = "UIParent",
			MainMenuExpBar = "UIParent",
			TimeManagerClockButton = "UIParent",
			MultiCastActionBarFrame = "UIParent",
			MainMenuBarRightEndCap = "UIParent",
			MainMenuBarMaxLevelBar = "UIParent",
			TargetFrameSpellBar = "UIParent",
			FocusFrameSpellBar = "UIParent",
			MANudger = "UIParent",
			MultiBarBottomRight = "UIParent",
			MultiBarBottomLeft = "UIParent"
		},
		HideList = {
			VehicleMenuBar = {
				{"VehicleMenuBar", "ARTWORK", "BACKGROUND", "BORDER", "OVERLAY"},
				{"VehicleMenuBarArtFrame", "ARTWORK", "BACKGROUND", "BORDER", "OVERLAY"},
				{"VehicleMenuBarActionButtonFrame", "ARTWORK", "BACKGROUND", "BORDER", "OVERLAY"}
			},
			MAOptions = {
				{"MAOptions", "ARTWORK", "BORDER"}
			},
			GameMenuFrame = {
				{"GameMenuFrame", "BACKGROUND", "ARTWORK", "BORDER"}
			},
			MainMenuBar = {
				{"MainMenuBarArtFrame", "BACKGROUND", "ARTWORK"},
				{"PetActionBarFrame", "OVERLAY"},
				{"ShapeshiftBarFrame", "OVERLAY"},
				{"MainMenuBar", "DISABLEMOUSE"},
				{"BonusActionBarFrame", "OVERLAY", "DISABLEMOUSE"}
			},
			MinimapBackdrop = {
				{"MinimapBackdrop", "ARTWORK"}
			}
		},
		HideUsingWH = {},
		MoveOnlyWhenVisible = {
			WorldStateCaptureBar1 = "WorldStateCaptureBar1",
			AlwaysUpFrame1 = "AlwaysUpFrame1",
			AlwaysUpFrame2 = "AlwaysUpFrame2",
			VehicleMenuBarHealthBar = "VehicleMenuBarHealthBar",
			VehicleMenuBarPowerBar = "VehicleMenuBarPowerBar",
			ArenaEnemyFrame1 = "ArenaEnemyFrame1",
			ArenaEnemyFrame2 = "ArenaEnemyFrame2",
			ArenaEnemyFrame3 = "ArenaEnemyFrame3",
			ArenaEnemyFrame4 = "ArenaEnemyFrame4",
			ArenaEnemyFrame5 = "ArenaEnemyFrame5"
		},
		NoAlpha = {
			CastingBarFrame = "CastingBarFrame",
			TargetFrameSpellBar = "TargetFrameSpellBar",
			FocusFrameSpellBar = "FocusFrameSpellBar",
			MinimapBackdrop = "MinimapBackdrop",
			MinimapNorthTag = "MinimapNorthTag"
		},
		NoHide = {
			FramerateLabel = "FramerateLabel",
			UIPanelMover1 = "UIPanelMover1",
			UIPanelMover2 = "UIPanelMover2",
			WorldMapFrame = "WorldMapFrame"
		},
		NoMove = {
			PVPFrame = "PVPFrame",
			MinimapBackdrop = "MinimapBackdrop",
			BuffFrame = "BuffFrame",
			MinimapNorthTag = "MinimapNorthTag",
			WorldMapFrame = "WorldMapFrame"
		},
		NoScale = {
			WorldStateAlwaysUpFrame = "WorldStateAlwaysUpFrame",
			MainMenuBarArtFrame = "MainMenuBarArtFrame",
			MainMenuBarMaxLevelBar = "MainMenuBarMaxLevelBar",
			MinimapBorderTop = "MinimapBorderTop",
			TargetFrameBuff1 = "TargetFrameBuff1",
			MinimapBackdrop = "MinimapBackdrop",
			MinimapNorthTag = "MinimapNorthTag"
		},
		NoReparent = {
			TargetFrameSpellBar = "TargetFrameSpellBar",
			FocusFrameSpellBar = "FocusFrameSpellBar",
			VehicleMenuBarHealthBar = "VehicleMenuBarHealthBar",
			VehicleMenuBarLeaveButton = "VehicleMenuBarLeaveButton",
			VehicleMenuBarPowerBar = "VehicleMenuBarPowerBar"
		},
		NoUnanchorRelatives = {
			FramerateLabel = "FramerateLabel"
		},
		NoUnanchoring = {
			BuffFrame = "BuffFrame",
			RuneFrame = "RuneFrame",
			TotemFrame = "TotemFrame",
			ComboFrame = "ComboFrame",
			MANudger = "MANudger",
			TimeManagerClockButton = "TimeManagerClockButton",
			TemporaryEnchantFrame = "TemporaryEnchantFrame",
			PartyMember1DebuffsMover = "PartyMember1DebuffsMover",
			PartyMember2DebuffsMover = "PartyMember2DebuffsMover",
			PartyMember3DebuffsMover = "PartyMember3DebuffsMover",
			PartyMember4DebuffsMover = "PartyMember4DebuffsMover",
			PetDebuffsMover = "PetDebuffsMover",
			TargetBuffsMover = "TargetBuffsMover",
			TargetDebuffsMover = "TargetDebuffsMover",
			FocusDebuffsMover = "FocusDebuffsMover",
			TargetFrameToTDebuffsMover = "TargetFrameToTDebuffsMover"
		},
		DefaultFrameList = {

			{"", ACHIEVEMENTS},
			{"AchievementFrame", "Achievements"},
			{"AchievementAlertFrame1", "Achievement Alert 1"},
			{"AchievementAlertFrame2", "Achievement Alert 2"},

			{"", QUESTS_LABEL},
			{"WatchFrame", "Tracker"},
			{"QuestLogDetailFrame", "Quest Details"},
			{"QuestLogFrame", "Quest Log"},
			{"QuestTimerFrame", "Quest Timer"},

			{"", ACTIONBAR_LABEL},
			{"BasicActionButtonsMover", BINDING_HEADER_ACTIONBAR},
			{"BasicActionButtonsVerticalMover", "Action Bar - Vertical"},
			{"MultiBarBottomLeft", "Bottom Left Action Bar"},
			{"MultiBarBottomRight", "Bottom Right Action Bar"},
			{"MultiBarRight", "Right Action Bar"},
			{"MultiBarRightHorizontalMover", "Right Action Bar - Horizontal"},
			{"MultiBarLeft", "Right Action Bar 2"},
			{"MultiBarLeftHorizontalMover", "Right Action Bar 2 - Horizontal"},
			{"MainMenuBarPageNumber", "Action Bar Page Number"},
			{"ActionBarUpButton", "Action Bar Page Up"},
			{"ActionBarDownButton", "Action Bar Page Down"},
			{"PetActionButtonsMover", "Pet Action Bar"},
			{"PetActionButtonsVerticalMover", "Pet Action Bar - Vertical"},
			{"ShapeshiftButtonsMover", "Stance / Aura / Shapeshift Buttons"},
			{"ShapeshiftButtonsVerticalMover", "Stance / Aura / Shapeshift - Vertical"},
			{"MultiCastActionBarFrame", "Shaman Totem Bar"},

			{"", ARENA},
			{"ArenaEnemyFrame1", "Arena Enemy 1"},
			{"ArenaEnemyFrame2", "Arena Enemy 2"},
			{"ArenaEnemyFrame3", "Arena Enemy 3"},
			{"ArenaEnemyFrame4", "Arena Enemy 4"},
			{"ArenaEnemyFrame5", "Arena Enemy 5"},
			{"PVPTeamDetails", "Arena Team Details"},
			{"ArenaFrame", "Arena Queue List"},
			{"ArenaRegistrarFrame", "Arena Registrar"},
			{"PVPBannerFrame", "Arena Banner"},

			{"", "Bags"},
			{"BagButtonsMover", "Bag Buttons"},
			{"BagButtonsVerticalMover", "Bag Buttons - Vertical"},
			{"BagFrame1", "Backpack"},
			{"BagFrame2", "Bag 1"},
			{"BagFrame3", "Bag 2"},
			{"BagFrame4", "Bag 3"},
			{"BagFrame5", "Bag 4"},
			{"KeyRingFrame", "Key Ring"},
			{"CharacterBag0Slot", "Bag Button 1"},
			{"CharacterBag1Slot", "Bag Button 2"},
			{"CharacterBag2Slot", "Bag Button 3"},
			{"CharacterBag3Slot", "Bag Button 4"},
			{"KeyRingButton", "Key Ring Button"},

			{"", "Bank"},
			{"BankFrame", "Bank"},
			{"BankBagFrame1", "Bank Bag 1"},
			{"BankBagFrame2", "Bank Bag 2"},
			{"BankBagFrame3", "Bank Bag 3"},
			{"BankBagFrame4", "Bank Bag 4"},
			{"BankBagFrame5", "Bank Bag 5"},
			{"BankBagFrame6", "Bank Bag 6"},
			{"BankBagFrame7", "Bank Bag 7"},

			{"", "Battlegrounds & PvP"},
			{"PVPParentFrame", PLAYER_V_PLAYER},
			{"BattlefieldMinimap", BATTLEFIELD_MINIMAP},
			{"BattlefieldFrame", "Battleground Queue"},
			{"WorldStateScoreFrame", "Battleground Score"},
			{"WorldStateCaptureBar1", "Flag Capture Timer Bar"},

			{"", "Bottom Bar"},
			{"MainMenuBar", "Main Bar"},
			{"MainMenuBarLeftEndCap", "Left Gryphon"},
			{"MainMenuBarRightEndCap", "Right Gryphon"},
			{"MainMenuExpBar", "Experience Bar"},
			{"MainMenuBarMaxLevelBar", "Max Level Bar Filler"},
			{"ReputationWatchBar", "Reputation Tracker Bar"},
			{"MicroButtonsMover", "Micro Menu"},
			{"MicroButtonsVerticalMover", "Micro Menu - Vertical"},
			{"MainMenuBarVehicleLeaveButton", "Leave Vehicle Button"},

			{"", "Dungeons & Raids"},
			{"LFDParentFrame", LOOKING_FOR_DUNGEON},
			{"DungeonCompletionAlertFrame1", "Dungeon Completion Alert"},
			{"LFDSearchStatus", "Dungeon Search Status Tooltip"},
			{"LFDDungeonReadyDialog", "Dungeon Ready Dialog"},
			{"LFDDungeonReadyPopup", "Dungeon Ready Popup"},
			{"LFDDungeonReadyStatus", "Dungeon Ready Status"},
			{"LFDRoleCheckPopup", "Dungeon Role Check Popup"},
			{"RaidBossEmoteFrame", "Raid Boss Emotes"},
			{"Boss1TargetFrame", "Raid Boss Health Bar 1"},
			{"Boss2TargetFrame", "Raid Boss Health Bar 2"},
			{"Boss3TargetFrame", "Raid Boss Health Bar 3"},
			{"Boss4TargetFrame", "Raid Boss Health Bar 4"},
			{"LFRParentFrame", "Raid Browser"},
			{"RaidPullout1", "Raid Group Pullout 1"},
			{"RaidPullout2", "Raid Group Pullout 2"},
			{"RaidPullout3", "Raid Group Pullout 3"},
			{"RaidPullout4", "Raid Group Pullout 4"},
			{"RaidPullout5", "Raid Group Pullout 5"},
			{"RaidPullout6", "Raid Group Pullout 6"},
			{"RaidPullout7", "Raid Group Pullout 7"},
			{"RaidPullout8", "Raid Group Pullout 8"},
			{"RaidWarningFrame", "Raid Warnings"},

			{"", MAINMENU_BUTTON},
			{"GameMenuFrame", MAINMENU_BUTTON},
			{"VideoOptionsFrame", "Video Options"},
			{"AudioOptionsFrame", "Sound & Voice Options"},
			{"InterfaceOptionsFrame", INTERFACE_OPTIONS},
			{"KeyBindingFrame", "Keybinding Options"},

			{"", "Guild"},
			{"GuildBankFrame", GUILD_BANK},
			{"GuildInfoFrame", GUILD_INFORMATION},
			{"GuildMemberDetailFrame", "Guild Member Details"},
			{"GuildControlPopupFrame", GUILDCONTROL},
			{"GuildRegistrarFrame", "Guild Registrar"},

			{"", "Info Panels"},
			{"UIPanelMover1", "Generic Info Panel 1"},
			{"UIPanelMover2", "Generic Info Panel 2"},
			{"CharacterFrame", "Character / Pet / Reputation / Skills"},
			{"TaxiFrame", "Flight Paths"},
			{"FriendsFrame", "Friends / Who / Guild / Chat / Raid"},
			{"GossipFrame", "Gossip"},
			{"InspectFrame", INSPECT},
			{"LFDParentFrame", LOOKING_FOR_DUNGEON},
			{"LFRParentFrame", "Looking For Raid"},
			{"MacroFrame", MACROS},
			{"MailFrame", MINIMAP_TRACKING_MAILBOX},
			{"MerchantFrame", MERCHANT},
			{"OpenMailFrame", OPENMAIL},
			{"PetStableFrame", "Pet Stable"},
			{"SpellBookFrame", SPELLBOOK},
			{"TabardFrame", "Tabard Design"},
			{"PlayerTalentFrame", TALENTS},
			{"TradeFrame", "Trade"},
			{"TradeSkillFrame", "Trade Skills"},
			{"ClassTrainerFrame", "Trainer"},
			{"DressUpFrame", "Wardrobe"},

			{"", LOOT},
			{"LootFrame", LOOT},
			{"GroupLootFrame1", "Loot Roll 1"},
			{"GroupLootFrame2", "Loot Roll 2"},
			{"GroupLootFrame3", "Loot Roll 3"},
			{"GroupLootFrame4", "Loot Roll 4"},

			{"", MINIMAP_LABEL},
			{"MinimapCluster", MINIMAP_LABEL},
			{"MinimapZoneTextButton", "Zone Text"},
			{"MinimapBorderTop", "Top Border"},
			{"MinimapBackdrop", "Round Border"},
			{"MinimapNorthTag", "North Indicator"},
			{"MiniMapBattlefieldFrame", "Battleground  Button"},
			{"GameTimeFrame", "Calendar Button"},
			{"TimeManagerClockButton", "Clock Button"},
			{"MiniMapInstanceDifficulty", "Dungeon Difficulty"},
			{"MiniMapLFGFrame", "LFD/R Button"},
			{"LFDSearchStatus", "LFD/R Search Status"},
			{"MiniMapMailFrame", "Mail Notification"},
			{"MiniMapTracking", "Tracking Button"},
			{"MinimapZoomIn", "Zoom In Button"},
			{"MinimapZoomOut", "Zoom Out Button"},
			{"MiniMapWorldMapButton", "World Map Button"},

			{"", MISCELLANEOUS},
			{"TimeManagerFrame", "Alarm Clock"},
			{"AuctionFrame", BUTTON_LAG_AUCTIONHOUSE},
			{"BarberShopFrame", BARBERSHOP},
			{"MirrorTimer1", "Breath/Fatigue Bar"},
			{"CalendarFrame", "Calendar"},
			{"CalendarViewEventFrame", "Calendar Event"},
			{"CastingBarFrame", "Casting Bar"},
			{"ChatConfigFrame", "Chat Channel Configuration"},
			{"ColorPickerFrame", "Color Picker"},
			{"TokenFramePopup", "Currency Options"},
			{"ItemRefTooltip", "Chat Popup"},
			-- {"DebuffFrame", "Debuffs"},
			{"DurabilityFrame", "Durability Figure"},
			{"UIErrorsFrame", "Errors & Warnings"},
			{"FramerateLabel", "Framerate"},
			{"GearManagerDialog", "Equipment Manager"},
			{"ItemSocketingFrame", "Gem Socketing"},
			{"HelpFrame", "GM Help"},
			{"MacroPopupFrame", "Macro Name & Icon"},
			{"StaticPopup1", "Static Popup 1"},
			{"StaticPopup2", "Static Popup 2"},
			{"StaticPopup3", "Static Popup 3"},
			{"StaticPopup4", "Static Popup 4"},
			{"ItemTextFrame", "Reading Materials"},
			{"ReputationDetailFrame", "Reputation Details"},
			{"TemporaryEnchantFrame", "Temporary item buffs"},
			{"TicketStatusFrame", "Ticket Status"},
			{"TooltipMover", "Tooltip"},
			{"BagItemTooltipMover", "Tooltip - Bag Item"},
			{"WorldStateAlwaysUpFrame", "Top Center Status Display"},
			{"VoiceChatTalkers", "Voice Chat Talkers"},
			{"ZoneTextFrame", "Zoning Zone Text"},
			{"SubZoneTextFrame", "Zoning Subzone Text"},

			{"", PLAYER},
			{"PlayerFrame", PLAYER},
			-- {"BuffFrame", "Buffs - Alpha and Scale"},
			{"ConsolidatedBuffs", "Buffs - Position"},
			{"ConsolidatedBuffsTooltip", "Buffs - Consolidated Tooltip"},
			{"RuneFrame", "Deathknight Runes"},
			{"TotemFrame", "Shaman Totem Timers"},

			{"", TARGET},
			{"TargetFrame", TARGET},
			{"TargetFrameBuff1", "Target Buffs"},
			{"ComboFrame", "Target Combo Points Display"},
			{"TargetFrameDebuff1", "Target Debuffs"},
			{"TargetFrameSpellBar", "Target Casting Bar"},
			{"TargetFrameToT", "Target of Target"},
			{"TargetFrameToTDebuff1", "Target of Target Debuffs"},

			{"", FOCUS},
			{"FocusFrame", FOCUS},
			{"FocusFrameSpellBar", "Focus Casting Bar"},
			{"FocusFrameDebuff1", "Focus Debuffs"},
			{"FocusFrameToT", "Target of Focus"},
			{"FocusFrameToTDebuff1", "Target of Focus Debuffs"},

			{"", PETS},
			{"PetFrame", PET},
			{"PartyMemberFrame1PetFrame", "Party Pet 1"},
			{"PartyMemberFrame2PetFrame", "Party Pet 2"},
			{"PartyMemberFrame3PetFrame", "Party Pet 3"},
			{"PartyMemberFrame4PetFrame", "Party Pet 4"},

			{"", PARTY},
			{"PartyMemberFrame1", "Party Member 1"},
			{"PartyMemberFrame1Debuff1", "Party Member 1 Debuffs"},
			{"PartyMemberFrame2", "Party Member 2"},
			{"PartyMemberFrame2Debuff1", "Party Member 2 Debuffs"},
			{"PartyMemberFrame3", "Party Member 3"},
			{"PartyMemberFrame3Debuff1", "Party Member 3 Debuffs"},
			{"PartyMemberFrame4", "Party Member 4"},
			{"PartyMemberFrame4Debuff1", "Party Member 4 Debuffs"},

			{"", "Vehicle"},
			{"VehicleMenuBar", "Vehicle Bar"},
			{"VehicleMenuBarActionButtonFrame", "Vehicle Action Bar"},
			{"VehicleMenuBarHealthBar", "Vehicle Health Bar"},
			{"VehicleMenuBarLeaveButton", "Vehicle Leave Button"},
			{"VehicleMenuBarPowerBar", "Vehicle Power Bar"},
			{"VehicleSeatIndicator", "Vehicle Seat Indicator"},

			{"", "MoveAnything"},
			{"MAOptions", "MoveAnything Window"},
			{"MANudger", "MoveAnything Nudger"},

			{"", "Custom Frames"}
		},
		ContainerFrame_GenerateFrame = function(frame, size, id)
			core.MA:GrabContainerFrame(frame, core.MA:GetBag(id))
		end,
		CloseAllWindows = function(arg1)
			local opt, f
			for i, v in pairs(core.MA.frames) do
				if v and v.name and core.MA:IsFrameHooked(v.name) then
					opt = core.MA:GetFrameOptions(v.name)
					if opt and opt.UIPanelWindows then
						f = _G[v.name]
						if f ~= nil and f ~= GameMenuFrame then
							if f.IsShown and f:IsShown() then
								f:Hide()
							end
						end
					end
				end
			end
		end,
		ShowUIPanel = function(f)
			core.MA:SetLeftFrameLocation()
			core.MA:SetCenterFrameLocation()
		end,
		HideUIPanel = function(f)
			core.MA:SetLeftFrameLocation()
			core.MA:SetCenterFrameLocation()
		end,
		CaptureBar_Create = function(id)
			local f = core.MA.oCaptureBar_Create(id)
			local opts = core.MA:GetFrameOptions("WorldStateCaptureBar1")
			if opts then
				core.MA:ApplyAll(f, opts)
			end
			if not opts or not opts.pos then
				f:ClearAllPoints()
				f:SetPoint("TOPRIGHT", "UIParent", "BOTTOMRIGHT", -CONTAINER_OFFSET_X, 0)
			end
			return f
		end,
		AchievementAlertFrame_OnLoad = function(f)
			f.RegisterForClicks = void
			core.MA.oAchievementAlertFrame_OnLoad(f)
			local opts = core.MA:GetFrameOptions(f:GetName())
			if opts then
				core.MA:ApplyAll(f, opts)
			end
		end,
		AchievementAlertFrame_GetAlertFrame = function()
			local f = core.MA.oAchievementAlertFrame_GetAlertFrame()
			if not f then
				return
			end
			local opts = core.MA:GetFrameOptions(f:GetName())
			if opts then
				core.MA:ApplyAll(f, opts)
			end
			return f
		end
	}
core.MA = MovAny

BINDING_HEADER_KPACKMOVEANYTHING = "|cfff58cbaK|r|caaf49141Pack|r MoveAnything"

StaticPopupDialogs["MOVEANYTHING_RESET_CONFIRM"] = {
	text = L["MoveAnything: Reset all frames in the current profile?"],
	button1 = YES,
	button2 = NO,
	OnAccept = function() MovAny:ResetAll() end,
	timeout = 0,
	exclusive = 0,
	showAlert = 1,
	whileDead = 1,
	hideOnEscape = 1
}

function MovAny:Boot()
	if self.inited then
		return
	end

	SetupDatabase()
	self.db = DB
	_G["MAOptionsCaption"]:SetText(BINDING_HEADER_KPACKMOVEANYTHING)

	if not DB.noMMMW and Minimap:GetScript("OnMouseWheel") == nil then
		Minimap:SetScript("OnMouseWheel", function()
			if arg1 < 0 then
				Minimap_ZoomOut()
			else
				Minimap_ZoomIn()
			end
		end)
		Minimap:EnableMouseWheel(true)
	end

	local autoShowUI = nil
	if DB.CharacterSettings == nil then
		autoShowUI = true
	end

	self:VerifyData()

	local DB_Defaults = {
		autoShowNext = nil,
		optsPlaySound = nil,
		alwaysShowNudger = nil
	}

	for i, v in pairs(DB_Defaults) do
		if DB[i] ~= nil then
		else
			DB[i] = v
		end
	end

	DB["collapsed"] = true

	MAOptionsCharacterSpecific:SetScript("OnEnter", MovAny.TooltipShowMultiline)
	MAOptionsCharacterSpecific:SetScript("OnLeave", MovAny.TooltipHide)

	MAOptionsToggleCategories:SetScript("OnEnter", MovAny.TooltipShow)
	MAOptionsToggleCategories:SetScript("OnLeave", MovAny.TooltipHide)

	MAOptionsToggleModifiedFramesOnly:SetScript("OnEnter", MovAny.TooltipShow)
	MAOptionsToggleModifiedFramesOnly:SetScript("OnLeave", MovAny.TooltipHide)

	MAOptionsToggleTooltips:SetScript("OnEnter", MovAny.TooltipShow)
	MAOptionsToggleTooltips:SetScript("OnLeave", MovAny.TooltipHide)

	MAOptionsSync:SetScript("OnEnter", MovAny.TooltipShow)
	MAOptionsSync:SetScript("OnLeave", MovAny.TooltipHide)

	MAOptionsClose:SetScript("OnEnter", MovAny.TooltipShow)
	MAOptionsClose:SetScript("OnLeave", MovAny.TooltipHide)

	MAOptionsResetAll:SetScript("OnEnter", MovAny.TooltipShow)
	MAOptionsResetAll:SetScript("OnLeave", MovAny.TooltipHide)

	local label
	for i = 1, self.frameListSize do
		label = _G["MAMove" .. i .. "FrameName"]
		label:SetScript("OnEnter", MovAny.TooltipShowMultiline)
		label:SetScript("OnLeave", MovAny.TooltipHide)
	end

	self:ParseData()

	-- hook stuff
	if ContainerFrame_GenerateFrame then
		hooksecurefunc("ContainerFrame_GenerateFrame", self.ContainerFrame_GenerateFrame)
	end
	if CloseAllWindows then
		hooksecurefunc("CloseAllWindows", self.CloseAllWindows)
	end
	if ShowUIPanel then
		hooksecurefunc("ShowUIPanel", self.ShowUIPanel)
	end
	if HideUIPanel then
		hooksecurefunc("HideUIPanel", self.HideUIPanel)
	end
	if GameTooltip_SetDefaultAnchor then
		hooksecurefunc("GameTooltip_SetDefaultAnchor", self.hGameTooltip_SetDefaultAnchor)
	end
	if GameTooltip and GameTooltip.SetOwner then
		hooksecurefunc(GameTooltip, "SetOwner", self.hGameTooltip_SetOwner)
	end
	if updateContainerFrameAnchors and not DB.noBags then
		hooksecurefunc("updateContainerFrameAnchors", self.UpdateContainerFrameAnchors)
	end

	if ExtendedUI and ExtendedUI.CAPTUREPOINT then
		self.oCaptureBar_Create = ExtendedUI.CAPTUREPOINT.create
		ExtendedUI.CAPTUREPOINT.create = self.CaptureBar_Create
	end

	if AchievementAlertFrame_OnLoad then
		self.oAchievementAlertFrame_OnLoad = AchievementAlertFrame_OnLoad
		AchievementAlertFrame_OnLoad = self.AchievementAlertFrame_OnLoad
	end

	if AchievementAlertFrame_GetAlertFrame then
		self.oAchievementAlertFrame_GetAlertFrame = AchievementAlertFrame_GetAlertFrame
		AchievementAlertFrame_GetAlertFrame = self.AchievementAlertFrame_GetAlertFrame
	end

	self.inited = true
	if DB.autoShowNext == true then
		autoShowUI = true
		DB.autoShowNext = nil
	end
	if autoShowUI == true then
		MAOptions:Show()
	end
end

function MovAny:OnPlayerLogout()
	SetupDatabase()
	if MAOptions:IsShown() then
		DB.autoShowNext = true
	end

	if type(DB.CustomFrames) == "table" then
		for i, v in pairs(DB.CustomFrames) do
			v.idx = nil
			v.cat = nil
		end
	end
	MovAny:CleanProfile(MovAny:GetProfileName())
end

function MovAny:CleanProfile(pn)
	if pn and type(DB.CharacterSettings[pn]) == "table" then
		local f
		for i, v in pairs(DB.CharacterSettings[pn]) do
			f = _G[i]
			if f and f.SetUserPlaced and (f:IsMovable() or f:IsResizable()) then
				f:SetUserPlaced(nil)
				f:SetMovable(nil)
			end
			v.ignoreFramePositionManager = nil
			v.cat = nil
			v.originalScale = nil
			v.orgPos = nil
			v.MANAGED_FRAME = nil
			v.UIPanelWindows = nil
		end
	end
end

function MovAny:VerifyData()
	if DB.CharacterSettings[self:GetProfileName()] == nil then
		DB.CharacterSettings[self:GetProfileName()] = {}
	end

	local fRel
	local remList = {}
	for pi, profile in pairs(DB.CharacterSettings) do
		twipe(remList)
		for fn, opt in pairs(profile) do
			if not opt or opt == nil then
				break
			end

			opt.movable = nil
			opt.cat = nil

			opt.originalLeft = nil
			opt.originalBottom = nil

			opt.originalWidth = nil
			opt.originalHeight = nil

			opt.orgPos = nil

			opt.originalScale = nil

			opt.MANAGED_FRAME = nil
			opt.UIPanelWindows = nil

			if opt.scale and opt.scale > 0.991 and opt.scale < 1.009 then
				opt.scale = 1
			end

			if opt.x ~= nil and opt.y ~= nil then
				f = _G[fn]

				fRel = self:ForcedDetachFromParent(fn, opt)
				if not fRel then
					p = f and f.GetParent and f:GetParent() ~= nil and f:GetParent():GetName() or "UIParent"
				end

				opt.pos = {"BOTTOMLEFT", p, "BOTTOMLEFT", opt.x, opt.y}
				opt.x = nil
				opt.y = nil
			else
				opt.x = nil
				opt.y = nil
			end

			if
				not opt.hidden and opt.pos == nil and opt.scale == nil and opt.width == nil and opt.height == nil and
					opt.alpha == nil
			 then
				tinsert(remList, fn)
			end
		end
		for i, v in ipairs(remList) do
			DB.CharacterSettings[pi][v] = nil
		end
	end
end

function MovAny:ParseData()
	local sepLast, sep = nil

	if DB.noList then
		for i, v in pairs(self.DefaultFrameList) do
			if v[1] then
				if v[1] == "" then
					sep = {}
					sep.name = nil
					sep.helpfulName = v[2]
					sep.sep = true
					sep.collapsed = DB.collapsed
					sepLast = sep
				end
			end
		end
		sep.idx = self.nextFrameIdx
		self.nextFrameIdx = self.nextFrameIdx + 1
		tinsert(self.frames, sepLast)
		tinsert(self.cats, sepLast)
		self.framesCount = self.framesCount + 1
	else
		for i, v in pairs(self.DefaultFrameList) do
			if v[1] then
				if v[1] == "" then
					sep = {}
					sep.idx = self.nextFrameIdx
					self.nextFrameIdx = self.nextFrameIdx + 1
					sep.name = nil
					sep.helpfulName = v[2]
					sep.sep = true
					sep.collapsed = DB.collapsed
					tinsert(self.frames, sep)
					tinsert(self.cats, sep)
					self.framesCount = self.framesCount + 1
					sepLast = sep
				else
					self:AddFrameToMovableList(v[1], v[2], 2)
					if sepLast then
						self.frames[self.nextFrameIdx - 1].cat = sepLast
					end
					if not self.defFrames[v[1]] then
						self:AddCustomFrameIfNew(v[1])
					end
				end
			end
		end
	end

	self.DefaultFrameList = nil
	self.customCat = sepLast

	self.FrameOptions = DB.CharacterSettings[self:GetProfileName()]
	tsort(self.FrameOptions, function(o1, o2) return o1.name:lower() < o2.name:lower() end )

	for i, v in pairs(self.FrameOptions) do
		if not self:GetFrame(v.name) then
			self:AddFrameToMovableList(v.name, v.helpfulName, 1)
			self.frames[self.nextFrameIdx - 1].cat = self.customCat
		end
	end
end

function MovAny:VerifyFrameData(fn)
	local opt = self:GetFrameOptions(fn)
	if opt and (not opt.hidden and opt.pos == nil and opt.scale == nil and opt.width == nil and opt.height == nil and opt.alpha == nil) then
		MovAny.FrameOptions[fn] = nil
	end
end

function MovAny:AddCustomFrameIfNew(name)
	local found = nil
	for i in pairs(DB.CustomFrames) do
		if DB.CustomFrames[i].name == name then
			found = i
			break
		end
	end
	if found == nil then
		tinsert(DB.CustomFrames, {name = name, helpfulName = name})
		self.guiLines = -1
		self:UpdateGUIIfShown(true)
		return true
	end
end

function MovAny:ForcedDetachFromParent(fn, opt)
	if self.DetachFromParent[fn] then
		return self.DetachFromParent[fn]
	end
	if UIPanelWindows[fn] then
		return "UIParent"
	end
	if not opt then
		opt = self.FrameOptions[fn]
		if not opt then
			return "UIParent"
		end
	end
	if opt.UIPanelWindows then
		return "UIParent"
	end
end

function MovAny:ErrorNotInCombat(f, quiet)
	if f and self:IsProtected(f) and InCombatLockdown() then
		if not quiet then
			MAPrint(L:F("Can't interact with %s during combat.", f:GetName()))
		end
		return true
	end
end

function MovAny:IsScalableFrame(f)
	if not f.SetScale then
		return
	end
	if self.NoScale[f:GetName()] or self.ScaleWH[f:GetName()] then
		return
	end
	return true
end

function MovAny:CanBeScaled(f)
	if f.GetName and self.ScaleWH[f:GetName()] then
		return true
	end
	if not f or not f.GetScale or self.NoScale[f:GetName()] or f:GetObjectType() == "FontString" then
		return
	end
	return true
end

do
	local validObjects = {
		Frame = true,
		FontString = true,
		Texture = true,
		Button = true,
		CheckButton = true,
		StatusBar = true,
		GameTooltip = true,
		MessageFrame = true,
		PlayerModel = true,
		ColorSelect = true,
		EditBox = true
	}

	function MovAny:IsValidObject(f, silent)
		if type(f) == "string" then
			f = _G[f]
		end
		if not f then
			return
		end
		if type(f) ~= "table" then
			if not silent then
				MAPrint(L:F("Unsupported type: %s", type(f)))
			end
			return
		end
		if f == UIParent or f == WorldFrame or f == CinematicFrame then
			if not silent then
				MAPrint(L:F("Unsupported frame: %s", f:GetName()))
			end
			return
		end
		if not validObjects[f:GetObjectType()] then
			if not silent then
				MAPrint(L:F("Unsupported type: %s", f:GetObjectType()))
			end
			return
		end

		if MovAny:IsMAFrame(f:GetName()) then
			local fn = f:GetName()
			if fn == "MAOptions" or fn == "MANudger" then
				return true
			end
			return
		end
		return true
	end
end

function MovAny:IsDefaultFrame(f)
	if not f.GetName then
		return
	end
	local fn = f:GetName()
	for i, v in ipairs(MovAny.frames) do
		if v.name == fn then
			return v.default
		end
	end
	return
end

function MovAny:SyncAllFrames(dontReset)
	if not self.rendered then
		dontReset = true
	end
	self.pendingFrames = tcopy(self.FrameOptions)
	self:SyncFrames(dontReset)
end

function MovAny:SyncFrames(dontReset)
	if not self.inited or self.syncingFrames then
		return
	end

	local pending = (next(self.pendingFrames) ~= nil)

	if not pending then
		return
	end

	self.syncingFrames = true

	local handled
	local skippedFrames = {}

	if dontReset then
		for fn, opt in pairs(self.pendingFrames) do
			f = _G[fn]
			if f then
				self:UnanchorRelatives(f)
			end
		end
	end

	for fn, opt in pairs(self.pendingFrames) do
		if not opt.disabled and not self:GetMoverByFrameName(fn) then
			handled = nil

			if self.runOnceBeforeInteract[fn] then
				self.runOnceBeforeInteract[fn]()
				self.runOnceBeforeInteract[fn] = nil
			end

			if not self.runBeforeInteract[fn] or not self.runBeforeInteract[fn]() then
				f = _G[fn]
				if f and self:IsValidObject(f, true) then
					if not MovAny:IsProtected(f) or not InCombatLockdown() then
						if dontReset == nil or not dontReset then
							MovAny:ResetScale(f, opt, true)
							MovAny:ResetPosition(f, opt, true)
							MovAny:ResetAlpha(f, opt, true)
						end
						if self:IsFrameHooked(fn) then
							if self:HookFrame(fn, f, not dontReset) then
								self:ApplyAll(f, opt)
								handled = true
							end
						end
					end
				end
			end
			if self.runAfterInteract[fn] then
				self.runAfterInteract[fn](handled)
			end
			if not handled then
				skippedFrames[fn] = opt
			end
		end
	end
	self.pendingFrames = skippedFrames

	local postponed = {}
	for k, f in pairs(self.pendingActions) do
		if f() then
			tinsert(postponed, f)
		end
	end
	self.pendingActions = postponed

	self:SetLeftFrameLocation()
	self:SetCenterFrameLocation()

	self.rendered = true
	self.syncingFrames = nil
end

function MovAny:IsProtected(f)
	return f:IsProtected() or f.MAProtected
end

function MovAny:GetProfileName(override)
	local val = DB.UseCharacterSettings
	if override ~= nil then
		val = override
	end
	if val then
		return GetCVar("realmName") .. " " .. UnitName("player")
	else
		return "default"
	end
end

function MovAny:CopySettings(fromName, toName)
	if DB.CharacterSettings[toName] == nil then
		DB.CharacterSettings[toName] = {}
	end
	for i, val in pairs(DB.CharacterSettings[fromName]) do
		local l = tcopy(val)
		l.cat = nil
		DB.CharacterSettings[toName][i] = l
	end
end

function MovAny:UpdateProfile(profile)
	self:ResetAll(true)
	self.FrameOptions = DB.CharacterSettings[self:GetProfileName()]
	self:SyncAllFrames(true)
	self:UpdateGUIIfShown(true)
end

function MovAny:GetFrameCount()
	return self.framesCount
end

function MovAny:ClearFrameOptions(fn)
	self.FrameOptions[fn] = nil
	self:RemoveIfCustom(fn)
end

function MovAny:GetFrameOptions(fn, noSymLink, create)
	if MovAny.FrameOptions == nil then
		return nil
	end

	if not noSymLink and not MovAny.FrameOptions[fn] and MovAny.lTranslateSec[fn] then
		fn = MovAny.lTranslateSec[fn]
	end
	if create and MovAny.FrameOptions[fn] == nil then
		MovAny.FrameOptions[fn] = {name = fn}
	end
	return MovAny.FrameOptions[fn]
end

function MovAny:GetFrame(fn)
	for i, v in pairs(self.frames) do
		if v.name == fn then
			return v
		end
	end
end

function MovAny:RemoveIfCustom(fn)
	local removed = nil
	for i in pairs(DB.CustomFrames) do
		if DB.CustomFrames[i].name == fn then
			tremove(DB.CustomFrames, i)
			self.guiLines = -1
			removed = true
			break
		end
	end

	if removed then
		for i in pairs(self.frames) do
			if self.frames[i].name == fn then
				tremove(self.frames, i)
				self.framesCount = self.framesCount - 1
				break
			end
		end
	end
end

function MovAny.hShow(f, ...)
	if f.MAHidden then
		if MovAny:IsProtected(f) and InCombatLockdown() then
			local opt = MovAny:GetFrameOptions(f:GetName())
			if opt ~= nil then
				MovAny.pendingFrames[f:GetName()] = opt
			end
		else
			f.MAHidden = nil
			f:Hide()
			f.MAHidden = true
		end
	end
end

function MovAny:LockVisibility(f)
	f.MAHidden = true

	if not f.MAShowHook then
		hooksecurefunc(f, "Show", MovAny.hShow)
		f.MAShowHook = true
	end

	f.MAWasShown = f:IsShown()
	if f.MAWasShown then
		f:Hide()
	end

	if self.lSimpleHide[f] then
		return
	end

	if f.attachedChildren then
		for i, v in pairs(f.attachedChildren) do
			self:LockVisibility(v)
		end
	end
end

function MovAny:UnlockVisibility(f)
	if not f.MAHidden then
		return
	end
	f.MAHidden = nil
	if self.lSimpleHide[f] then
		f:Show()
		return
	end

	if f.MAWasShown then
		f.MAWasShown = nil
		f:Show()
	end
	if f.attachedChildren then
		for i, v in pairs(f.attachedChildren) do
			self:UnlockVisibility(v)
		end
	end
end

function MovAny.hSetPoint(f, ...)
	if f.MAPoint then
		local fn = f:GetName()
		if strmatch(fn, "^ContainerFrame[1-9][0-9]*$") then
			fn = MovAny:GetBagInContainerFrame(f):GetName()
		end

		if InCombatLockdown() and MovAny:IsProtected(f) then
			MovAny.pendingFrames[fn] = MovAny:GetFrameOptions(fn)
		else
			local p = f.MAPoint
			f.MAPoint = nil
			f:ClearAllPoints()
			f:SetPoint(unpack(p))
			f.MAPoint = p
			p = nil
		end
	end
end

function MovAny:LockPoint(f)
	if not f.MAPoint then
		if not f.MALockPointHook then
			hooksecurefunc(f, "SetPoint", MovAny.hSetPoint)
			f.MALockPointHook = true
		end
		f.MAPoint = {f:GetPoint(1)}
	end
end

function MovAny:UnlockPoint(f)
	f.MAPoint = nil
end

function MovAny:LockParent(f)
	if not f.MAParented and not f.MAParentHook then
		hooksecurefunc(f, "SetParent", MovAny.hSetParent)
		f.MAParentHook = true
	end
	f.MAParented = f:GetParent()
end

function MovAny:UnlockParent(f)
	f.MAParented = nil
end

function MovAny.hSetParent(f, ...)
	if f.MAParented then
		if InCombatLockdown() and MovAny:IsProtected(f) then
			MovAny.pendingFrames[f:GetName()] = MovAny:GetFrameOptions(f:GetName())
		else
			local p = f.MAParented
			MovAny:UnlockParent(f)
			f:SetParent(p)
			MovAny:LockParent(f)
		end
	end
end

function MovAny.hSetScale(f, ...)
	if f.MAScaled then
		local fn = f:GetName()

		if strmatch(fn, "^ContainerFrame[1-9][0-9]*$") then
			local bag = MovAny:GetBagInContainerFrame(f)
			fn = bag:GetName()
		end

		if MovAny:IsProtected(f) and InCombatLockdown() then
			MovAny.pendingFrames[fn] = MovAny:GetFrameOptions(fn)
			MovAny:SyncFrames()
		else
			MovAny:Rescale(f, f.MAScaled)
		end
	end
end

function MovAny:LockScale(f)
	if f.SetScale and not f.MAScaled then
		local meta = getmetatable(f).__index
		if not meta.MAScaleHook then
			if meta.SetScale then
				hooksecurefunc(meta, "SetScale", MovAny.hSetScale)
			end
			meta.MAScaleHook = true
		end
		f.MAScaled = f:GetScale()
	end
end

function MovAny:UnlockScale(f)
	f.MAScaled = nil
end

function MovAny:Rescale(f, scale)
	MovAny:UnlockScale(f)
	f:SetScale(scale)
	MovAny:LockScale(f)
end

function MovAny:HookFrame(fn, f, dontUnanchor)
	if not f then
		f = _G[fn]
	end
	if not f then
		return
	end

	if not self:IsValidObject(f) then
		return
	end

	local opt = self:GetFrameOptions(fn, true)
	if opt == nil then
		opt = {}
		self.FrameOptions[fn] = opt
		opt.cat = self.customCat
	end
	if opt.name == nil then
		opt.name = fn
	end

	if f.OnMAHook and f.OnMAHook(f) ~= nil then
		return
	end

	if not opt.orgPos then
		MovAny:StoreOrgPoints(f, opt)
	end

	if not dontUnanchor then
		self:UnanchorRelatives(f)
	end

	if self.DetachFromParent[fn] and not self.NoReparent[fn] and not f.MAOrgParent then
		f.MAOrgParent = f:GetParent()
		f:SetParent(_G[self.DetachFromParent[fn]])
	end

	if f.OnMAPostHook and f.OnMAPostHook(f) ~= nil then
		return
	end

	return true
end

-- XXX: verify that frame is properly hooked instead of just checking stored options?
function MovAny:IsFrameHooked(fn)
	if fn == nil then
		return
	end
	local opt = self:GetFrameOptions(fn)
	if opt and (opt.pos or opt.hidden or opt.scale ~= nil or opt.alpha ~= nil) then
		return true
	end
	return
end

function MovAny:IsFrameHidden(fn)
	if fn == nil then
		return
	end
	local opt = self:GetFrameOptions(fn)
	if opt and opt.hidden then
		return true
	end
	return
end

function MovAny:StoreOrgPoints(f, opt)
	local np = f:GetNumPoints()
	if np == 1 then
		opt.orgPos = self:GetSerializedPoint(f)
	elseif np > 1 then
		opt.orgPos = {}
		for i = 1, np, 1 do
			opt.orgPos[i] = self:GetSerializedPoint(f, i)
		end
	end
	if not opt.orgPos then
		if f == TargetFrameSpellBar then
			opt.orgPos = {"BOTTOM", "TargetFrame", "BOTTOM", -15, 10}
		elseif f == FocusFrameSpellBar then
			opt.orgPos = {"BOTTOM", "FocusFrame", "BOTTOM", 0, 0}
		elseif f == VehicleMenuBarHealthBar then
			opt.orgPos = {"BOTTOMLEFT", "VehicleMenuBarArtFrame", "BOTTOMLEFT", 119, 3}
		elseif f == VehicleMenuBarPowerBar then
			opt.orgPos = {"BOTTOMRIGHT", "VehicleMenuBarArtFrame", "BOTTOMRIGHT", -119, 3}
		elseif f == VehicleMenuBarLeaveButton then
			opt.orgPos = {"BOTTOMRIGHT", "VehicleMenuBar", "BOTTOMRIGHT", 177, 15}
		else
			opt.orgPos = {"TOP", "UIParent", "TOP", 0, -135}
		end
	end
end

function MovAny:RestoreOrgPoints(f, opt, readOnly)
	f:ClearAllPoints()

	if opt then
		if type(opt.orgPos) == "table" then
			if type(opt.orgPos[1]) == "table" then
				for i, v in pairs(opt.orgPos) do
					f:SetPoint(unpack(v))
				end
			else
				f:SetPoint(unpack(opt.orgPos))
			end
		end
		if not readOnly then
			opt.orgPos = nil
		end
	end
end

function MovAny:GetFirstOrgPoint(opt)
	if opt then
		if type(opt.orgPos) == "table" then
			if type(opt.orgPos[1]) == "table" then
				return opt.orgPos[1]
			else
				return opt.orgPos
			end
		end
	end
end

function MovAny:GetSerializedPoint(f, num)
	num = num or 1
	local point, rel, relPoint, x, y = f:GetPoint(num)
	if point then
		if rel and rel.GetName and rel:GetName() ~= "" then
			rel = rel:GetName()
		else
			rel = "UIParent"
		end
		return {point, rel, relPoint, x, y}
	end
	return nil
end

function MovAny:GetRelativePoint(o, f, lockRel)
	if not o then
		o = {"BOTTOMLEFT", UIParent, "BOTTOMLEFT"}
	end
	local rel = o[2]
	if rel == nil then
		rel = UIParent
	end
	if type(rel) == "string" then
		rel = _G[rel]
	end
	if not rel then
		return
	end

	local point = o[1]
	local relPoint = o[3]

	if not lockRel then
		local newRel = self:ForcedDetachFromParent(f:GetName())
		if newRel then
			rel = _G[newRel]
			point = "BOTTOMLEFT"
			relPoint = "BOTTOMLEFT"
		end
		if not rel then
			return
		end
	end

	local rX, rY, pX, pY

	if rel:GetLeft() ~= nil then
		if relPoint == "TOPRIGHT" then
			rY = rel:GetTop()
			rX = rel:GetRight()
		elseif relPoint == "TOPLEFT" then
			rY = rel:GetTop()
			rX = rel:GetLeft()
		elseif relPoint == "TOP" then
			rY = rel:GetTop()
			rX = (rel:GetRight() + rel:GetLeft()) / 2
		elseif relPoint == "BOTTOMRIGHT" then
			rY = rel:GetBottom()
			rX = rel:GetRight()
		elseif relPoint == "BOTTOMLEFT" then
			rY = rel:GetBottom()
			rX = rel:GetLeft()
		elseif relPoint == "BOTTOM" then
			rY = rel:GetBottom()
			rX = (rel:GetRight() + rel:GetLeft()) / 2
		elseif relPoint == "CENTER" then
			rY = (rel:GetTop() + rel:GetBottom()) / 2
			rX = (rel:GetRight() + rel:GetLeft()) / 2
		elseif relPoint == "LEFT" then
			rY = (rel:GetTop() + rel:GetBottom()) / 2
			rX = rel:GetLeft()
		elseif relPoint == "RIGHT" then
			rY = (rel:GetTop() + rel:GetBottom()) / 2
			rX = rel:GetRight()
		else
			return
		end

		if rel.GetEffectiveScale then
			rY = rY * rel:GetEffectiveScale()
			rX = rX * rel:GetEffectiveScale()
		else
			rY = rY * UIParent:GetEffectiveScale()
			rX = rX * UIParent:GetEffectiveScale()
		end
	end

	if f:GetLeft() ~= nil then
		if point == "TOPRIGHT" then
			pY = f:GetTop()
			pX = f:GetRight()
		elseif point == "TOPLEFT" then
			pY = f:GetTop()
			pX = f:GetLeft()
		elseif point == "TOP" then
			pY = f:GetTop()
			pX = (f:GetRight() + f:GetLeft()) / 2
		elseif point == "BOTTOMRIGHT" then
			pY = f:GetBottom()
			pX = f:GetRight()
		elseif point == "BOTTOMLEFT" then
			pY = f:GetBottom()
			pX = f:GetLeft()
		elseif point == "BOTTOM" then
			pY = f:GetBottom()
			pX = (f:GetRight() + f:GetLeft()) / 2
		elseif point == "CENTER" then
			pY = (f:GetTop() + f:GetBottom()) / 2
			pX = (f:GetRight() + f:GetLeft()) / 2
		elseif point == "LEFT" then
			pY = (f:GetTop() + f:GetBottom()) / 2
			pX = f:GetLeft()
		elseif point == "RIGHT" then
			pY = (f:GetTop() + f:GetBottom()) / 2
			pX = f:GetRight()
		else
			return
		end

		if f.GetEffectiveScale then
			pY = pY * f:GetEffectiveScale()
			pX = pX * f:GetEffectiveScale()
		else
			pY = pY * UIParent:GetEffectiveScale()
			pX = pX * UIParent:GetEffectiveScale()
		end
	end

	if rY ~= nil and rX ~= nil and pY ~= nil and pX ~= nil then
		rX = pX - rX
		rY = pY - rY

		if f.GetEffectiveScale then
			rY = rY / f:GetEffectiveScale()
			rX = rX / f:GetEffectiveScale()
		else
			rY = rY / UIParent:GetEffectiveScale()
			rX = rX / UIParent:GetEffectiveScale()
		end
	else
		rX = 0
		rY = 0
	end

	return {point, rel:GetName(), relPoint, rX, rY}
end

function MovAny:AddFrameToMovableList(fn, helpfulName, default)
	if not self:GetFrame(fn) then
		if helpfulName == nil then
			helpfulName = fn
		end

		local opts = {}
		opts.name = fn
		opts.helpfulName = helpfulName
		opts.cat = self.customCat

		opts.idx = self.nextFrameIdx
		self.nextFrameIdx = self.nextFrameIdx + 1

		tinsert(self.frames, opts)
		self.framesCount = self.framesCount + 1

		if default == 2 then
			opts.default = true
			self.defFrames[opts.name] = opts
		else
			if default ~= 1 then
				tinsert(DB.CustomFrames, opts)
				self.guiLines = -1
			end
		end
		if self.inited then
			self:UpdateGUIIfShown()
		end
	end
end

function MovAny:AttachMover(fn, helpfulName)
	if self.NoMove[fn] and self.NoScale[fn] and self.NoHide[fn] and self.NoAlpha[fn] then
		MAPrint(L:F("Unsupported frame: %s", fn))
		return
	end

	if self.NoMove[fn] and self.NoScale[fn] and self.NoAlpha[fn] then
		MAPrint(L:F("%s can only be hidden", fn))
		return
	end

	local f = _G[fn]

	if self.MoveOnlyWhenVisible[fn] and (f == nil or not f:IsShown()) then
		MAPrint(L:F("%s can only be modified while it's shown on the screen", fn))
		return
	end

	if self:ErrorNotInCombat(f) then
		return
	end

	if not self:GetMoverByFrameName(fn) then
		local mover = self:FindAvailableFrame()
		if mover == nil then
			MAPrint(L:F("You can only move %i frames at once", self.MAXMOVERS))
			return
		end
		if self.runOnceBeforeInteract[fn] then
			self.runOnceBeforeInteract[fn]()
			self.runOnceBeforeInteract[fn] = nil
		end
		if self.runBeforeInteract[fn] and self.runBeforeInteract[fn]() then
			return
		end
		local created = nil
		local handled = nil

		if self.createBeforeInteract[fn] and _G[fn] == nil then
			CreateFrame("Frame", fn, UIParent, self.createBeforeInteract[fn])
			created = true
		end
		f = _G[fn]

		self.lastFrameName = fn
		if self:IsValidObject(f) then
			if f.OnMAOnAttach then
				f.OnMAOnAttach(f, mover)
			end
			self:AddFrameToMovableList(fn, helpfulName)
			if self:HookFrame(fn) then
				if self:AttachMoverToFrame(mover, f) then
					handled = true
					mover.createdTagged = created
					if f.OnMAPostAttach then
						f.OnMAPostAttach(f, mover)
					end
					self:UpdateGUIIfShown()
				end
			end
		end

		if self.runAfterInteract[fn] then
			self.runAfterInteract[fn](handled)
		end
		return true
	end
end

function MovAny:GetDefaultFrameParent(f)
	local c = f
	while c and c ~= UIParent and c ~= nil do
		if c.MAParent then
			c = c.MAParent
		end
		if c.GetName and c:GetName() ~= nil and c:GetName() ~= "" then
			local m = strmatch(c:GetName(), "^ContainerFrame[1-9][0-9]*$")
			if m then
				local bag = self:GetBagInContainerFrame(_G[m])
				return _G[bag:GetName()]
			end

			local transName = self:Translate(c:GetName(), true, true)

			if self:GetFrameOptions(transName) ~= nil then
				return _G[transName]
			else
				local frame = self:GetFrame(transName)
				if frame then
					return _G[frame.name]
				end
			end
		end
		c = c:GetParent()
	end
	return nil
end

function MovAny:GetTopFrameParent(f)
	local c = f
	local l = nil
	local ln
	local n
	while c and c ~= UIParent do
		if c:IsToplevel() then
			n = c:GetName()
			if n ~= nil and n ~= "" then
				return c
			elseif ln ~= nil then
				return ln
			else
				MAPrint(L["No named elements found"])
				return nil
			end
		end
		l = c
		n = c:GetName()
		if n ~= nil and n ~= "" then
			ln = c
		end
		c = c:GetParent()
	end
	if c == UIParent then
		return l
	end
	return nil
end

function MovAny:ToggleMove(fn)
	local ret = nil
	if self:GetMoverByFrameName(fn) then
		ret = self:StopMoving(fn)
	else
		ret = self:AttachMover(fn)
	end

	self.lastFrameName = fn

	self:UpdateGUIIfShown(true)

	return ret
end

function MovAny:ToggleHide(fn)
	local ret = nil
	if self:IsFrameHidden(fn) then
		ret = self:ShowFrame(fn)
	else
		ret = self:HideFrame(fn)
	end

	self.lastFrameName = fn

	self:UpdateGUIIfShown(true)

	return ret
end

--X: binds
function MovAny:SafeMoveFrameAtCursor()
	local obj = GetMouseFocus()

	if obj then
		if self:IsMAFrame(obj:GetName()) then
			if self:IsMover(obj:GetName()) and obj.tagged then
				obj = obj.tagged
			elseif not self:IsValidObject(obj, true) then
				obj = obj:GetParent()
			end
		end
		local transName = self:Translate(obj:GetName(), 1)

		if transName ~= obj:GetName() then
			self:ToggleMove(transName)
		else
			local p = obj:GetParent()
			if (p == MinimapBackdrop or p == Minimap or p == MinimapCluster) and obj ~= Minimap then
				self:ToggleMove(obj:GetName())
			else
				local objTest = self:GetDefaultFrameParent(obj)

				if objTest then
					self:ToggleMove(objTest:GetName())
				else
					objTest = self:GetTopFrameParent(obj)
					if objTest then
						self:ToggleMove(objTest:GetName())
					elseif obj and obj ~= WorldFrame and obj ~= UIParent and obj.GetName then
						self:ToggleMove(obj:GetName())
					end
				end

			end

		end

	end

	self:UpdateGUIIfShown(true)
end

function MovAny:MoveFrameAtCursor()
	local obj = GetMouseFocus()
	if self:IsMAFrame(obj:GetName()) then
		if self:IsMover(obj:GetName()) and obj.tagged then
			obj = obj.tagged
		elseif not self:IsValidObject(obj) then
			return
		end
	end
	if obj and obj ~= WorldFrame and obj ~= UIParent and obj:GetName() then
		self:ToggleMove(obj:GetName())
	end

	self:UpdateGUIIfShown(true)
end

function MovAny:SafeHideFrameAtCursor()
	local obj = GetMouseFocus()

	if obj then
		if self:IsMAFrame(obj:GetName()) then
			if self:IsMover(obj:GetName()) and obj.tagged then
				obj = obj.tagged
			elseif not self:IsValidObject(obj, true) then
				obj = obj:GetParent()
			end
		end
		local transName = self:Translate(obj:GetName(), 1)
		if transName ~= obj:GetName() then
			self:ToggleHide(transName)
		else
			local objTest = self:GetDefaultFrameParent(obj)
			if objTest then
				self:ToggleHide(objTest:GetName())
			else
				objTest = self:GetTopFrameParent(obj)
				if objTest then
					self:AddFrameToMovableList(objTest:GetName(), nil)
					self:ToggleHide(objTest:GetName())
				elseif obj and obj ~= WorldFrame and obj ~= UIParent then
					self:AddFrameToMovableList(obj:GetName(), nil)
					self:ToggleHide(obj:GetName())
				end
			end
		end
	end

	self:UpdateGUIIfShown(true)
end

function MovAny:HideFrameAtCursor()
	local obj = GetMouseFocus()
	if self:IsMAFrame(obj:GetName()) then
		if self:IsMover(obj:GetName()) and obj.tagged then
			obj = obj.tagged
		else
			return
		end
	end
	if obj and obj ~= WorldFrame and obj ~= UIParent then
		self:ToggleHide(obj:GetName())
	end

	self:UpdateGUIIfShown(true)
end

function MovAny:SafeResetFrameAtCursor()
	local obj = GetMouseFocus()

	if obj then
		if self.FrameOptions[obj:GetName()] then
			self:ResetFrameConfirm(obj:GetName())
		else
			if self:IsMAFrame(obj:GetName()) then
				if self:IsMover(obj:GetName()) and obj.tagged then
					obj = obj.tagged
				elseif not self:IsValidObject(obj, true) then
					obj = obj:GetParent()
				end
			end
			local transName = self:Translate(obj:GetName(), 1)
			if transName ~= obj:GetName() and self.FrameOptions[obj:GetName()] then
				self:ResetFrameConfirm(obj:GetName())
			else
				local objTest = self:GetDefaultFrameParent(obj)
				if objTest and self.FrameOptions[objTest:GetName()] then
					self:ResetFrameConfirm(objTest:GetName())
				else
					objTest = self:GetTopFrameParent(obj)
					if objTest and self.FrameOptions[objTest:GetName()] then
						self:ResetFrameConfirm(objTest:GetName())
					elseif obj and obj ~= WorldFrame and obj ~= UIParent and self.FrameOptions[obj:GetName()] then
						self:ResetFrameConfirm(obj:GetName())
					end
				end
			end
		end
	end
end

function MovAny:ResetFrameAtCursor()
	local obj = GetMouseFocus()
	if self:IsMAFrame(obj:GetName()) then
		if self:IsMover(obj:GetName()) and obj.tagged then
			obj = obj.tagged
		else
			return
		end
	end

	if InCombatLockdown() and MovAny:IsProtected(obj) then
		self:ErrorNotInCombat(obj)
		return
	end

	local fn = obj:GetName()

	if self.FrameOptions[fn] then
		self:ResetFrameConfirm(fn)
	end
end

function MovAny:IsMover(fn)
	if fn ~= nil and strmatch(fn, "^" .. self.moverPrefix .. "[0-9]+$") ~= nil then
		return true
	end
end

function MovAny:IsMAFrame(fn)
	if fn ~= nil and (strmatch(fn, "^MoveAnything") ~= nil or strmatch(fn, "^MA") ~= nil) then
		return true
	end
end

function MovAny:IsContainer(fn)
	if type(fn) == "string" and strmatch(fn, "^ContainerFrame[1-9][0-9]*$") then
		return true
	end
end

function MovAny:Translate(f, secondary, nofirst)
	if not nofirst and self.lTranslate[f] then
		return self.lTranslate[f]
	end

	if secondary and self.lTranslateSec[f] then
		return self.lTranslateSec[f]
	end

	if f == "last" then
		return MovAny.lastFrameName
	else
		return f
	end
end

function MovAny:GetMoverByFrameName(moveFrameName)
	local frame
	for i = 1, self.MAXMOVERS, 1 do
		frame = _G[self.moverPrefix .. i]
		if type(frame) ~= "nil" and frame:IsShown() and frame.tagged == _G[moveFrameName] then
			return frame
		end
	end
	return nil
end

function MovAny:FindAvailableFrame()
	local frame
	for i = 1, self.MAXMOVERS, 1 do
		frame = _G[self.moverPrefix .. i]
		if not frame:IsShown() then
			return frame
		end
	end
	return nil
end

function MovAny:AttachMoverToFrame(mover, f)
	if mover.tagged then
		self:DetachMover(mover)
	end
	self:UnlockPoint(f)

	local listOptions = self:GetFrame(f:GetName())
	local frameOptions = self:GetFrameOptions(f:GetName())

	mover.helpfulName = listOptions.helpfulName

	if f.OnMAMoving then
		if not f:OnMAMoving() then
			self:DetachMover(mover)
			return
		end
	end

	local x, y
	x = 0
	y = 0
	if f:GetLeft() == nil and not f:IsShown() then
		f:Show()
		f:Hide()
	end

	mover.attaching = true

	local opt = self:GetFrameOptions(f:GetName())
	if not opt.pos then
		opt.pos = self:GetRelativePoint(self:GetFirstOrgPoint(opt), f)
	end

	mover:ClearAllPoints()
	mover:SetPoint("CENTER", f, "CENTER")

	mover:SetWidth(f:GetWidth() * MAGetScale(f, 1) / UIParent:GetScale())
	mover:SetHeight(f:GetHeight() * MAGetScale(f, 1) / UIParent:GetScale())

	local p = self:GetRelativePoint({"BOTTOMLEFT", UIParent, "BOTTOMLEFT"}, mover)
	mover:ClearAllPoints()
	mover:SetPoint(unpack(p))

	if f.GetFrameLevel then
		mover:SetFrameLevel(f:GetFrameLevel() + 1)
	end

	f:ClearAllPoints()
	f:SetPoint("BOTTOMLEFT", mover, "BOTTOMLEFT", 0, 0)

	if not self.NoMove[f:GetName()] then
		f.orgX = x
		f.orgY = y
	end

	mover.tagged = f

	local label = _G[mover:GetName() .. "BackdropInfoLabel"]
	label:Hide()
	label:ClearAllPoints()
	label:SetPoint("CENTER", label:GetParent(), "CENTER", 0, 0)

	mover:Show()

	mover.attaching = nil
end

function MovAny:DetachMover(mover)
	if mover.tagged and not mover.attaching then
		self:UpdatePosition(mover)

		local f = mover.tagged

		self:ApplyPosition(f, self:GetFrameOptions(f:GetName()))

		if mover.createdTagged then
			mover.tagged:Hide()
		end
		if f.OnMAOnDetach then
			f.OnMAOnDetach(f, mover)
		end
	end

	mover:Hide()
	mover.tagged = nil
	mover.attaching = nil
end

function MovAny:UpdatePosition(mover)
	if mover and mover.tagged then
		local f = mover.tagged
		if self.NoMove[f:GetName()] then
			return
		end
		local opt = self:GetFrameOptions(f:GetName())
		opt.pos = self:GetRelativePoint(opt.pos or self:GetFirstOrgPoint(opt) or {"BOTTOMLEFT", "UIParent", "BOTTOMLEFT"}, f)

		if f.OnMAPosition then
			f.OnMAPosition(f)
		end
	end
end

function MovAny:StopMoving(fn)
	local mover = self:GetMoverByFrameName(fn)
	if mover and not self:ErrorNotInCombat(_G[fn]) then
		self:DetachMover(mover)
		self:UpdateGUIIfShown()
	end
end

function MovAny:ResetFrameConfirm(fn)
	local f = _G[fn]
	if InCombatLockdown() and MovAny:IsProtected(f) then
		self:ErrorNotInCombat(f)
		return
	end
	if self.resetConfirm == fn then
		self.resetConfirm = nil
		MAPrint(L:F("Resetting %s", fn))
		self:ResetFrame(fn)
	else
		self.resetConfirm = fn
		MAPrint(L:F("Reset %s? Press again to confirm", fn))
	end
end

function MovAny:ResetFrame(f, dontUpdate, readOnly)
	if not f then
		return
	end
	local fn
	if type(f) == "string" then
		fn = f
		f = _G[fn]
	elseif f and f.GetName then
		fn = f:GetName()
	end
	if not fn then
		return
	end

	if self:ErrorNotInCombat(f) or (InCombatLockdown() and f.UMFP) then
		return
	end

	self:StopMoving(fn)

	self.lastFrameName = fn

	if not f then
		if not readOnly then
			self:ClearFrameOptions(fn)
		end
		if not dontUpdate then
			self:UpdateGUIIfShown(true)
		end
		return
	end

	local opt = self:GetFrameOptions(fn, true)
	if opt == nil then
		opt = {}
	end

	if f.OnMAPreReset then
		f.OnMAPreReset(f, opt)
	end

	local width = nil
	local height = nil
	if opt then
		width = opt.originalWidth
		height = opt.originalHeight
	end

	self:ResetScale(f, opt, readOnly)
	self:ResetPosition(f, opt, readOnly)
	self:ResetAlpha(f, opt, readOnly)
	self:ResetHide(f, opt, readOnly)

	if width then
		f:SetWidth(width)
	end
	if height then
		f:SetHeight(height)
	end

	f.attachedChildren = nil

	if not readOnly then
		self:ClearFrameOptions(fn)
	end

	if f.OnMAPostReset then
		f.OnMAPostReset(f)
	end

	if not dontUpdate then
		self:UpdateGUIIfShown(true)
	end
end

function MovAny:ToggleOptionsMenu()
	if MAOptions:IsShown() then
		MAOptions:Hide()
	else
		MAOptions:Show()
	end
end

function MovAny:OnMoveCheck(button)
	if not self:ToggleMove(self.frames[button:GetParent().idx].name) then
		button:SetChecked(nil)
		return
	end
end

function MovAny:OnHideCheck(button)
	if not self:ToggleHide(self.frames[button:GetParent().idx].name) then
		button:SetChecked(nil)
		return
	end
end

function MovAny:OnResetCheck(button)
	local f = _G[self.frames[button:GetParent().idx].name]
	if f then
		if self:ErrorNotInCombat(f) then
			return
		end
	else
		f = self.frames[button:GetParent().idx].name
	end
	self:ResetFrame(f)
end

function MovAny:HideFrame(f, readOnly)
	local fn
	if type(f) == "string" then
		fn = f
		f = _G[fn]
	end
	if not fn then
		fn = f:GetName()
	end

	local opt
	if readOnly then
		opt = {}
	else
		opt = self:GetFrameOptions(fn, nil, true)
		opt.hidden = true
	end
	if not f then
		return true
	end

	if not self:IsValidObject(f) or not self:HookFrame(fn) or self:ErrorNotInCombat(f) then
		return
	end

	f.MAWasShown = f:IsShown()

	if f.GetAttribute then
		opt.unit = f:GetAttribute("unit")
		if opt.unit then
			f:SetAttribute("unit", nil)
		end
	end

	if self.HideList[fn] then
		for hIndex, hideEntry in pairs(self.HideList[fn]) do
			local val = _G[hideEntry[1]]
			local hideType
			for i = 2, tgetn(hideEntry) do
				hideType = hideEntry[i]
				if type(hideType) == "function" then
					hideType(nil)
				elseif hideType == "DISABLEMOUSE" then
					val:EnableMouse(nil)
				elseif hideType == "FRAME" then
					self:LockVisibility(val)
				elseif hideType == "WH" then
					self:StopMoving(fn)
					val:SetWidth(1)
					val:SetHeight(1)
				else
					val:DisableDrawLayer(hideType)
				end
			end
		end
	elseif self.HideUsingWH[fn] then
		self:StopMoving(fn)
		f:SetWidth(1)
		f:SetHeight(1)
		self:LockVisibility(f)
	else
		self:LockVisibility(f)
	end
	if f.OnMAHide then
		f.OnMAHide(f, true)
	end

	return true
end

function MovAny:ShowFrame(f, readOnly)
	local fn
	if type(f) == "string" then
		fn = f
		f = _G[f]
	end
	if not fn then
		fn = f:GetName()
	end

	local opt = self:GetFrameOptions(fn)
	if readOnly == nil and opt then
		opt.hidden = nil
		opt.unit = nil
	end
	if not f then
		self:VerifyFrameData(fn)
		return true
	end
	if not self:IsValidObject(f) or not self:HookFrame(fn) or self:ErrorNotInCombat(f) then
		return
	end
	if opt.unit and f.SetAttribute then
		f:SetAttribute("unit", opt.unit)
	end
	if self.HideList[fn] then
		for hIndex, hideEntry in pairs(self.HideList[fn]) do
			local val = _G[hideEntry[1]]
			local hideType
			for i = 2, tgetn(hideEntry) do
				hideType = hideEntry[i]
				if type(hideType) == "function" then
					hideType(true)
				elseif hideType == "DISABLEMOUSE" then
					val:EnableMouse(true)
				elseif hideType == "FRAME" then
					self:UnlockVisibility(val)
				elseif hideType == "WH" then
					if type(opt.originalWidth) == "number" then
						val:SetWidth(opt.originalWidth)
					end
					if type(opt.originalHeight) == "number" then
						val:SetHeight(opt.originalHeight)
					end
				else
					val:EnableDrawLayer(hideType)
				end
			end
		end
	elseif self.HideUsingWH[fn] then
		if type(opt.originalWidth) == "number" then
			f:SetWidth(opt.originalWidth)
		end
		if type(opt.originalHeight) == "number" then
			f:SetHeight(opt.originalHeight)
		end
		self:UnlockVisibility(f)
	else
		self:UnlockVisibility(f)
	end
	if f.OnMAHide then
		f.OnMAHide(f, nil)
	end
	self:VerifyFrameData(fn)
	return true
end

function MovAny:OnCheckCharacterSpecific(button)
	if InCombatLockdown() then
		button:SetChecked(not button:GetChecked())
		MAPrint(L["Profiles can't be switched during combat"])
		return
	end
	local oldName = self:GetProfileName()
	if button:GetChecked() then
		DB.UseCharacterSettings = true
	else
		DB.UseCharacterSettings = nil
	end
	local newProfile = self:GetProfileName()

	local i = 0
	if DB.CharacterSettings[newProfile] == nil then
		DB.CharacterSettings[newProfile] = {}
	else
		for v in pairs(DB.CharacterSettings[newProfile]) do
			i = i + 1
		end
	end
	if i == 0 then
		self:CopySettings(oldName, newProfile)
	end
	self:UpdateProfile()
end

function MovAny:OnCheckToggleCategories(button)
	local state = button:GetChecked()
	if state then
		DB.collapsed = true
	else
		DB.collapsed = nil
	end
	for i, v in pairs(self.cats) do
		v.collapsed = state
	end

	self:UpdateGUIIfShown(true)
end

function MovAny:OnCheckToggleModifiedFramesOnly(button)
	local state = button:GetChecked()
	if state then
		DB.modifiedFramesOnly = true
	else
		DB.modifiedFramesOnly = nil
	end

	self:UpdateGUIIfShown(true)
end

function MovAny:OnCheckToggleTooltips(button)
	local state = button:GetChecked()
	if state then
		DB.tooltips = true
	else
		DB.tooltips = nil
	end
	self:UpdateGUIIfShown()
end

function MovAny:MoverOnSizeChanged(mover)
	if mover.tagged then
		if mover.attaching then
			return
		end
		local s, w, h, f, opt
		f = mover.tagged
		opt = self:GetFrameOptions(f:GetName())
		if self.ScaleWH[f:GetName()] then
			if opt.width ~= mover:GetWidth() or opt.height ~= mover:GetHeight() then
				opt.width = mover:GetWidth()
				opt.height = mover:GetHeight()
				self:ApplyScale(f, opt)
			end
		else
			if mover.MASizingAnchor == "LEFT" or mover.MASizingAnchor == "RIGHT" then
				w = mover:GetWidth()
				h = w * (f:GetHeight() / f:GetWidth())
				if h < 8 then
					h = 8
					w = h * (f:GetWidth() / f:GetHeight())
				end
			else
				h = mover:GetHeight()
				w = h * (f:GetWidth() / f:GetHeight())
				if w < 8 then
					w = 8
					h = w * (f:GetHeight() / f:GetWidth())
				end
			end
			s = mover:GetWidth() / f:GetWidth()
			s = s / MAGetScale(f:GetParent(), 1) * UIParent:GetScale()
			if s > 0.991 and s < 1 then
				s = 1
			end

			if mover.tagged.GetScale and s ~= mover.tagged:GetScale() then
				opt.scale = s

				self:ApplyScale(f, opt)
			end
			mover:SetWidth(w)
			mover:SetHeight(h)

			local label = _G[mover:GetName() .. "BackdropInfoLabel"]
			label:SetWidth(w + 100)
			label:SetHeight(h)
		end

		local label = _G[this:GetName() .. "BackdropInfoLabel"]
		label:ClearAllPoints()
		label:SetPoint("TOP", label:GetParent(), "TOP", 0, 0)

		local brief, long
		if this.tagged and MovAny:CanBeScaled(this.tagged) then
			if MovAny.ScaleWH[this.tagged:GetName()] then
				brief = "W: " .. numfor(this.tagged:GetWidth()) .. " H:" .. numfor(this.tagged:GetHeight())
				long = brief
			else
				brief = numfor(this.tagged:GetScale())
				long = "Scale: " .. brief
			end
			label:Show()
			label:SetText(brief)
			if this:GetName() == self.moverPrefix .. self.currentMover then
				_G["MANudgerInfoLabel"]:Show()
				_G["MANudgerInfoLabel"]:SetText(long)
			end
		end

		label = _G[this:GetName() .. "BackdropMovingFrameName"]
		label:ClearAllPoints()
		label:SetPoint("TOP", label:GetParent(), "TOP", 0, 20)

		self:UpdateGUIIfShown(true)
	end
end

function MovAny:MoverOnMouseWheel(this)
	if not this.tagged or MovAny.NoAlpha[this.tagged:GetName()] then
		return
	end
	local alpha = this.tagged:GetAlpha()
	if arg1 > 0 then
		alpha = alpha + 0.05
	else
		alpha = alpha - 0.05
	end
	if alpha < 0 then
		alpha = 0
		this.tagged.alphaAttempts = nil
	elseif alpha > 0.99 then
		alpha = 1
		this.tagged.alphaAttempts = nil
	elseif alpha > 0.92 then
		if not this.tagged.alphaAttempts then
			this.tagged.alphaAttempts = 1
		elseif this.tagged.alphaAttempts > 2 then
			alpha = 1
			this.tagged.alphaAttempts = nil
		else
			this.tagged.alphaAttempts = this.tagged.alphaAttempts + 1
		end
	else
		this.tagged.alphaAttempts = nil
	end

	local opt = self:GetFrameOptions(this.tagged:GetName())
	opt.alpha = alpha
	self:ApplyAlpha(this.tagged, opt)

	if opt.alpha == opt.originalAlpha then
		opt.alpha = nil
		opt.originalAlpha = nil
	end

	local label = _G[this:GetName() .. "BackdropInfoLabel"]
	label:Show()
	label:SetText(numfor(alpha))
	if this:GetName() == self.moverPrefix .. MovAny.currentMover then
		_G["MANudgerInfoLabel"]:Show()
		_G["MANudgerInfoLabel"]:SetText("Alpha:" .. numfor(alpha))
	end
end

function MovAny:ResetAll(readOnly)
	for i, v in pairs(self.FrameOptions) do
		self:ResetFrame(v.name, true, true)
	end
	self:ReanchorRelatives()
	if not readOnly then
		self.FrameOptions = {}
		DB.CharacterSettings[self:GetProfileName()] = self.FrameOptions
	end

	self:UpdateGUIIfShown(true)
end

function MovAny:OnShow()
	if DB.optsPlaySound == true then
		PlaySound("igMainMenuOpen")
	end

	MANudger:Show()
	self:NudgerFrameRefresh()
	self:UpdateGUI()

	for i, v in pairs(self.lEnableMouse) do
		if v and v.EnableMouse and (not MovAny:IsProtected(v) or not InCombatLockdown()) then
			v:EnableMouse(true)
		end
	end
end

function MovAny:OnHide()
	if DB.optsPlaySound == true then
		PlaySound("igMainMenuClose")
	end

	self:MoverOnHide()

	for i, v in pairs(self.lEnableMouse) do
		if v and v.EnableMouse and (not MovAny:IsProtected(v) or not InCombatLockdown()) then
			v:EnableMouse(nil)
		end
	end
end

function MovAny:RowTitleClicked(title)
	local o = self.frames[MAGetParent(title).idx]

	if o.sep then
		if o.collapsed then
			o.collapsed = nil
		else
			o.collapsed = true
		end

		self:UpdateGUI(1)
	end
end

function MovAny:CountGUIItems()
	local items = 0
	local nextSepItems = 0
	local curSep = nil

	for i, o in pairs(MovAny.frames) do
		if o.sep then
			if curSep then
				curSep.items = nextSepItems
				nextSepItems = 0
			end
			curSep = o
		else
			if DB.modifiedFramesOnly then
				if MovAny:IsFrameHooked(o.name) then
					nextSepItems = nextSepItems + 1
				end
			else
				nextSepItems = nextSepItems + 1
			end
		end
	end

	if curSep then
		curSep.items = nextSepItems
	end

	for i, o in pairs(MovAny.frames) do
		if o.sep then
			if not DB.modifiedFramesOnly then
				if o.collapsed then
					items = items + 1
				else
					items = items + o.items + 1
				end
			else
				if o.items > 0 then
					if o.collapsed then
						items = items + 1
					else
						items = items + o.items + 1
					end
				end
			end
		end
	end

	self.guiLines = items
end

function MovAny:UpdateGUI(recount)
	if recount or MovAny.guiLines == -1 then
		MovAny:CountGUIItems()
	end

	FauxScrollFrame_Update(MAScrollFrame, MovAny.guiLines, MovAny.frameListSize, MovAny.SCROLL_HEIGHT)
	local topOffset = FauxScrollFrame_GetOffset(MAScrollFrame)

	local startOffset = 0
	local hidden = 0
	local shown = 0
	local lastSep = nil
	for i, o in pairs(MovAny.frames) do
		if startOffset == 0 and shown >= topOffset then
			startOffset = topOffset + hidden
			break
		end

		if o.sep then
			lastSep = o
			if DB.modifiedFramesOnly then
				if o.items == 0 then
					hidden = hidden + 1
				else
					shown = shown + 1
				end
			else
				shown = shown + 1
			end
		else
			if lastSep and lastSep.collapsed then
			elseif DB.modifiedFramesOnly then
				if lastSep.items > 0 then
					shown = shown + 1
				else
					hidden = hidden + 1
				end
			else
				shown = shown + 1
			end
		end
	end

	if startOffset ~= 0 then
		-- X: fix off by one
		if startOffset > 0 then
			startOffset = startOffset + 1
		end
	end

	local prefix, move, backdrop, hide, sepOffset, wtfOffset
	prefix = "MAMove"
	move = "Move"
	hide = "Hide"
	sepOffset = 0
	wtfOffset = 0

	local skip = topOffset

	for i = 1, MovAny.frameListSize, 1 do
		local index = i + sepOffset + wtfOffset

		local o
		-- forward to next shown element
		while 1 do
			if index > MovAny.framesCount then
				break
			end
			o = MovAny.frames[index]

			if o.sep then
				if DB.modifiedFramesOnly then
					if o.items > 0 then
						if skip > 0 then
							index = index + 1
							wtfOffset = wtfOffset + 1
							skip = skip - 1
						else
							break
						end
					else
						index = index + 1
						wtfOffset = wtfOffset + 1
					end
				else
					if skip > 0 then
						index = index + 1
						wtfOffset = wtfOffset + 1
						skip = skip - 1
					else
						break
					end
				end
			elseif o.cat then
				local c = o.cat
				if c.collapsed then
					index = index + 1
					wtfOffset = wtfOffset + 1
				else
					if DB.modifiedFramesOnly then
						if MovAny:IsFrameHooked(o.name) then
							if skip > 0 then
								index = index + 1
								wtfOffset = wtfOffset + 1
								skip = skip - 1
							else
								break
							end
						else
							index = index + 1
							wtfOffset = wtfOffset + 1
						end
					else
						if skip > 0 then
							index = index + 1
							wtfOffset = wtfOffset + 1
							skip = skip - 1
						else
							break
						end
					end
				end
			else
				index = index + 1
				wtfOffset = wtfOffset + 1
			end
		end

		local row = _G[prefix .. i]
		local frameNameLabel = _G[prefix .. i .. "FrameName"]
		frameNameLabel.idx = index

		if index > MovAny:GetFrameCount() then
			row:Hide()
		else
			local fn = o.name
			local opts = MovAny:GetFrameOptions(fn)
			local moveCheck = _G[prefix .. i .. move]
			local hideCheck = _G[prefix .. i .. hide]

			row.idx = index
			row.name = o.name
			row:Show()

			local text, label, tooltipLines
			if o.sep then
				text = _G[prefix .. i .. "FrameNameText"]
				text:Hide()
				text = _G[prefix .. i .. "FrameNameHighlight"]
				text:Show()
				if o.collapsed and o.items > 0 then
					text:SetText("+ " .. o.helpfulName)
				else
					text:SetText("   " .. o.helpfulName)
				end
				label = _G[prefix .. i .. "FrameName"]
				label.tooltipLines = nil
			else
				text = _G[prefix .. i .. "FrameNameHighlight"]
				text:Hide()
				text = _G[prefix .. i .. "FrameNameText"]
				text:Show()
				text:SetText(o.helpfulName)
			end

			if fn then
				_G[prefix .. i .. "Backdrop"]:Show()

				if MovAny.NoMove[fn] and MovAny.NoScale[fn] and MovAny.NoAlpha[fn] then
					moveCheck:Hide()
				else
					moveCheck:SetChecked(MovAny:GetMoverByFrameName(fn) and 1 or nil)
					moveCheck:Show()
				end
				if MovAny.NoHide[fn] then
					hideCheck:Hide()
				else
					hideCheck:SetChecked(opts and opts.hidden or nil)
					hideCheck:Show()
				end

				if MovAny:IsFrameHooked(fn) then
					_G[prefix .. i .. "Reset"]:Show()
				else
					if o.default then
						_G[prefix .. i .. "Reset"]:Hide()
					else
						_G[prefix .. i .. "Reset"]:Show()
					end
				end
			else
				_G[prefix .. i .. "Backdrop"]:Hide()
				moveCheck:Hide()
				hideCheck:Hide()
				_G[prefix .. i .. "Reset"]:Hide()
			end

			if o.sep and o.collapsed then
				sepOffset = sepOffset + o.items
			end
		end
	end
	MAOptionsCharacterSpecific:SetChecked(DB.UseCharacterSettings)
	MAOptionsCharacterSpecific.tooltipLines = {
		L["Use character specific settings"],
		" ",
		L:F("Current profile: %s", MovAny:GetProfileName()),
		"Cmds: /movelist, /moveimport, /moveexport & /movedelete"
	}

	MAOptionsToggleCategories:SetChecked(DB.collapsed)
	MAOptionsToggleModifiedFramesOnly:SetChecked(DB.modifiedFramesOnly)
	MAOptionsToggleTooltips:SetChecked(DB.tooltips)
	MovAny:TooltipHide()
end

function MovAny:UpdateGUIIfShown(recount)
	if recount then
		self.guiLines = -1
	end
	if MAOptions and MAOptions:IsShown() then
		self:UpdateGUI()
	end
end

function MovAny:Mover(dir)
	if dir > 0 then
		if self.currentMover < 20 then
			self.currentMover = self.currentMover + 1
		else
			self.currentMover = 1
		end
	else
		if MovAny.currentMover > 1 then
			self.currentMover = self.currentMover - 1
		else
			self.currentMover = 20
		end
	end
	self:NudgerFrameRefresh()
end

function MovAny:GetFirstMover()
	for i = 1, MovAny.MAXMOVERS do
		if _G[self.moverPrefix .. i]:IsShown() then
			return i
		end
	end
	return nil
end

function MovAny:MoverOnShow(mover)
	local mn = mover:GetName()

	MANudger:Show()
	self.currentMover = tonumber(mover:GetID())
	self:NudgerFrameRefresh()
	mover.startAlpha = mover.tagged:GetAlpha()
	_G[mn .. "Backdrop"]:Show()
	_G[mn .. "BackdropMovingFrameName"]:SetText(this.helpfulName)
	if not this.tagged or not MovAny:CanBeScaled(this.tagged) then
		_G[mn .. "Resize_TOP"]:Hide()
		_G[mn .. "Resize_LEFT"]:Hide()
		_G[mn .. "Resize_BOTTOM"]:Hide()
		_G[mn .. "Resize_RIGHT"]:Hide()
	else
		_G[mn .. "Resize_TOP"]:Show()
		_G[mn .. "Resize_LEFT"]:Show()
		_G[mn .. "Resize_BOTTOM"]:Show()
		_G[mn .. "Resize_RIGHT"]:Show()
	end

	_G[mn .. "BackdropInfoLabel"]:SetText("")
	if self.moverPrefix .. self.currentMover == mn then
		_G["MANudgerInfoLabel"]:SetText("")
	end
end

function MovAny:MoverOnHide()
	local firstMover = self:GetFirstMover()
	if firstMover == nil then
		MANudger:Hide()
	else
		self.currentMover = firstMover
		self:NudgerFrameRefresh()
	end
end

function MovAny:NudgerOnShow()
	if not DB.alwaysShowNudger then
		local firstMover = self:GetFirstMover()
		if firstMover == nil then
			MANudger:Hide()
			return
		end
	end
	self:NudgerFrameRefresh()
end

function MovAny:NudgerFrameRefresh()
	local labelText = "" .. self.currentMover .. "/" .. self.MAXMOVERS
	local f = _G[self.moverPrefix .. self.currentMover].tagged
	if f then
		local fn = f:GetName()
		labelText = labelText .. "\n" .. fn
		MANudger.idx = MovAny:GetFrame(fn).idx
		if self.NoHide[fn] then
			MANudger_Hide:Hide()
		else
			MANudger_Hide:Show()
		end
	end
	MANudgerTitle:SetText(labelText)
end

function MovAny:NudgerOnUpdate()
	-- This code was originally ripped from DiscordART :)
	local obj = GetMouseFocus()
	local text = ""
	local text2 = ""
	local label = MANudgerMouseOver
	local labelSafe = MANudgerMouseOver

	if obj and obj ~= WorldFrame and obj:GetName() then
		local objTest = self:GetDefaultFrameParent(obj)
		if objTest then
			text = text .. "Safe: " .. objTest:GetName()
		else
			objTest = self:GetTopFrameParent(obj)
			if objTest then
				text = text .. "Safe: " .. objTest:GetName()
			end
		end
	end

	if obj and obj ~= WorldFrame and obj:GetName() then
		text2 = "Mouseover: " .. text2 .. obj:GetName()
		if obj:GetParent() and obj:GetParent() ~= WorldFrame and obj:GetParent():GetName() then
			text2 = text2 .. "\nParent: " .. obj:GetParent():GetName()
			if
				obj:GetParent():GetParent() and obj:GetParent():GetParent() ~= WorldFrame and
					obj:GetParent():GetParent():GetName()
			 then
				text2 = text2 .. "\nParent's Parent: " .. obj:GetParent():GetParent():GetName()
			end
		end
	end

	if not strfind(text2, "MANudger") then
		label:SetText(text2 .. "\n" .. text)
	else
		label:SetText(text)
	end
end

function MovAny:Center(lock)
	local mover = _G[self.moverPrefix .. self.currentMover]
	if lock == 0 then
		-- Both
		mover:ClearAllPoints()
		mover:SetPoint("CENTER", 0, 0)
	else
		local x, y
		x = mover:GetLeft()
		y = mover:GetBottom()

		mover:ClearAllPoints()
		if lock == 1 then
			--Horizontal
			mover:SetPoint("CENTER", 0, 0)
			x = mover:GetLeft()
			mover:ClearAllPoints()
			mover:SetPoint("BOTTOMLEFT", x, y)
		elseif lock == 2 then
			-- Vertical
			mover:SetPoint("CENTER", 0, 0)
			y = mover:GetBottom()
			mover:ClearAllPoints()
			mover:SetPoint("BOTTOMLEFT", x, y)
		end
	end

	self:UpdatePosition(mover)
end

function MovAny:Nudge(dir, button)
	local x, y, offsetX, offsetY, parent, mover, offsetAmount
	mover = _G[self.moverPrefix .. self.currentMover]

	if not mover:IsShown() then
		return
	end

	x = mover:GetLeft()
	y = mover:GetBottom()

	if button == "RightButton" then
		if IsShiftKeyDown() then
			offsetAmount = 250
		else
			offsetAmount = 50
		end
	else
		if IsShiftKeyDown() then
			offsetAmount = 10
		elseif IsAltKeyDown() then
			offsetAmount = 0.1
		else
			offsetAmount = 1
		end
	end

	if dir == 1 then
		offsetX = 0
		offsetY = offsetAmount
	elseif dir == 2 then
		offsetX = 0
		offsetY = -offsetAmount
	elseif dir == 3 then
		offsetX = -offsetAmount
		offsetY = 0
	elseif dir == 4 then
		offsetX = offsetAmount
		offsetY = 0
	end

	mover:ClearAllPoints()
	mover:SetPoint("BOTTOMLEFT", "UIParent", "BOTTOMLEFT", x + offsetX, y + offsetY)
	self:UpdatePosition(mover)
end

function MovAny:SizingAnchor(button)
	local s, e = strfind(button:GetName(), "Resize_")
	local anchorto = strsub(button:GetName(), e + 1)
	local anchor

	if anchorto == "LEFT" then
		anchor = "RIGHT"
	elseif anchorto == "RIGHT" then
		anchor = "LEFT"
	elseif anchorto == "TOP" then
		anchor = "BOTTOM"
	elseif anchorto == "BOTTOM" then
		anchor = "TOP"
	end
	return anchorto, anchor
end

function MovAny:SetLeftFrameLocation()
	local f = GetUIPanel("left")
	if
		f and (f ~= LootFrame or GetCVar("lootUnderMouse") ~= "1") and not self:IsFrameHooked(f:GetName()) and
			not self:GetMoverByFrameName(f:GetName())
	 then
		if self:IsFrameHooked("UIPanelMover1") then
			local func = function()
				MovAny:UnlockPoint(f)
				f:ClearAllPoints()
				f:SetPoint("TOPLEFT", "UIPanelMover1", "TOPLEFT")

				if not f.MAOrgScale then
					f.MAOrgScale = f:GetScale()
				end
				f:SetScale(MAGetScale(UIPanelMover1), 1)

				if not f.MAOrgAlpha then
					f.MAOrgAlpha = f:GetAlpha()
				end
				f:SetAlpha(UIPanelMover1:GetAlpha())
			end
			if self:IsProtected(f) and InCombatLockdown() then
				MovAny.pendingActions[f:GetName() .. ":UIPanel"] = func
			else
				func()
			end
		else
			local func = function()
				if f.MAOrgScale then
					f:SetScale(f.MAOrgScale)
					f.MAOrgScale = nil
				end
				if f.MAOrgAlpha then
					f:SetAlpha(f.MAOrgAlpha)
					f.MAOrgAlpha = nil
				end
			end
			if self:IsProtected(f) and InCombatLockdown() then
				MovAny.pendingActions[f:GetName() .. ":UIPanel"] = func
			else
				func()
			end
		end
	end
end

function MovAny:SetCenterFrameLocation()
	if GetUIPanel("left") then
		local f = GetUIPanel("center")
		if
			f and (f ~= LootFrame or GetCVar("lootUnderMouse") ~= "1") and not self:IsFrameHooked(f:GetName()) and
				not self:GetMoverByFrameName(f:GetName())
		 then
			if self:IsFrameHooked("UIPanelMover2") then
				local func = function()
					MovAny:UnlockPoint(f)
					f:ClearAllPoints()
					f:SetPoint("TOPLEFT", "UIPanelMover2", "TOPLEFT")

					if not f.OrgScale then
						f.OrgScale = f:GetScale()
					end
					f:SetScale(MAGetScale(UIPanelMover2), 1)

					if not f.OrgAlpha then
						f.OrgAlpha = f:GetAlpha()
					end
					f:SetAlpha(UIPanelMover2:GetAlpha())
				end
				if self:IsProtected(f) and InCombatLockdown() then
					MovAny.pendingActions[f:GetName() .. ":UIPanel"] = func
				else
					func()
				end
			else
				local func = function()
					if f.OrgScale then
						f:SetScale(f.OrgScale)
						f.OrgScale = nil
					end
					if f.OrgAlpha then
						f:SetAlpha(f.OrgAlpha)
						f.OrgAlpha = nil
					end
				end
				if self:IsProtected(f) and InCombatLockdown() then
					MovAny.pendingActions[f:GetName() .. ":UIPanel"] = func
				else
					func()
				end
			end
		end
	end
end

function MovAny:GetContainerFrame(id)
	local i = 1
	local container
	while 1 do
		container = _G["ContainerFrame" .. i]
		if not container then
			break
		end
		if container:IsShown() and container:GetID() == id then
			return container
		end
		i = i + 1
	end
	return nil
end

function MovAny:GetBagInContainerFrame(f)
	return self:GetBag(f:GetID())
end

function MovAny:GetBag(id)
	return self.bagFrames[id]
end

function MovAny:SetBag(id, bag)
	self.bagFrames[id] = bag
end

function MovAny:GrabContainerFrame(container, movableBag)
	if movableBag and MovAny:IsFrameHooked(movableBag:GetName()) then
		movableBag:Show()

		MovAny:UnlockScale(container)
		container:SetScale(MAGetScale(movableBag))
		MovAny:LockScale(container)

		MovAny:UnlockPoint(container)
		container:ClearAllPoints()
		container:SetPoint("CENTER", movableBag, "CENTER", 0, 0)
		MovAny:LockPoint(container)

		movableBag.attachedChildren = {}
		tinsert(movableBag.attachedChildren, container)

		container:SetAlpha(movableBag:GetAlpha())
	else
		local opts = {alpha = 1.0, scale = 1.0}
		MovAny:ApplyAlpha(container, opts)
		MovAny:ApplyScale(container, opts)
	end
end

function MovAny:ApplyAll(f, opts)
	if not opts then
		opts = MovAny:GetFrameOptions(f:GetName())
	end
	MovAny:ApplyScale(f, opts)
	MovAny:ApplyPosition(f, opts)
	MovAny:ApplyAlpha(f, opts)
	MovAny:ApplyHide(f, opts)
end

function MovAny:UnanchorRelatives(f)
	if f.GetName and MovAny.NoUnanchorRelatives[f:GetName()] then
		return
	end
	local p = f:GetParent()
	if not p then
		return
	end


	local named = {}

	self:_AddNamedChildren(named, f)

	local relatives = tcopy(named)
	relatives[f] = f

	if p.GetRegions then
		local children = {p:GetRegions()}
		if children ~= nil then
			for i, v in ipairs(children) do
				self:_AddDependents(relatives, v)
			end
		end
	end

	if p.GetChildren then
		local children = {p:GetChildren()}
		if children ~= nil then
			for i, v in ipairs(children) do
				self:_AddDependents(relatives, v)
			end
		end
	end

	relatives[f] = nil
	relatives[GameTooltip] = nil

	for i, v in pairs(named) do
		relatives[v] = nil
	end

	local fRel = self:ForcedDetachFromParent(f:GetName())
	if fRel == nil then
		fRel = select(2, f:GetPoint(1))
	end
	local size = tlen(relatives)
	if size > 0 then
		local unanchored = {}
		local x, y, z
		for i, v in pairs(relatives) do
			z = i
			if not self:IsContainer(v:GetName()) and
					not strmatch(v:GetName(), "BagFrame[1-9][0-9]*") and
					not self.NoUnanchoring[v:GetName()] and
					not v.MAPoint
			 then
				if v:GetRight() ~= nil and v:GetTop() ~= nil then

					local pt = {v:GetPoint(1)}
					pt[2] = fRel
					pt = MovAny:GetRelativePoint(pt, v)
					if MovAny:IsProtected(v) and InCombatLockdown() then
						MovAny:AddPendingPoint(v, pt)
					else
						v.MAOrgPoint = {v:GetPoint(1)}
						MovAny:UnlockPoint(v)
						v:ClearAllPoints()
						v:SetPoint(unpack(pt))
						MovAny:LockPoint(v)
					end
					unanchored[i] = v
				end
			end
		end
		if z ~= nil then
			f.MAUnanchoredRelatives = unanchored
		end
	end
end

function MovAny:_AddDependents(l, f)
	local p = select(2, f:GetPoint(1))
	if p and l[p] then
		l[f] = f
	end
end

function MovAny:_AddNamedChildren(l, f)
	local n

	if f.GetChildren then
		local children = {f:GetChildren()}
		if children ~= nil then
			for i, v in pairs(children) do
				self:_AddNamedChildren(l, v)
				if v.GetName then
					n = v:GetName()
					if n then
						l[v] = v
					end
				end
			end
		end
	end

	if f.attachedChildren then
		local children = f.attachedChildren
		if children ~= nil then
			for i, v in pairs(children) do
				self:_AddNamedChildren(l, v)
				if v.GetName then
					n = v:GetName()
					if n then
						l[v] = v
					end
				end
			end
		end
	end
end

function MovAny:ReanchorRelatives()
	local f
	for i, v in pairs(self.FrameOptions) do
		f = _G[v.name]
		if f and f.MAUnanchoredRelatives then
			for k, r in pairs(f.MAUnanchoredRelatives) do
				if not MovAny:IsFrameHooked(r) then
					MovAny:UnlockPoint(r)
					if r.MAOrgPoint then
						r:SetPoint(unpack(r.MAOrgPoint))
						r.MAOrgPoint = nil
					end
				end
			end
			f.MAUnanchoredRelatives = nil
		end
	end
end

function MovAny:AddPendingPoint(f, p)
	MovAny.pendingActions[f:GetName() .. ":Point"] = function()
		if MovAny:IsProtected(f) and InCombatLockdown() then
			return true
		end
		if not f.MAOrgPoint then
			f.MAOrgPoint = {f:GetPoint(1)}
		end
		MovAny:UnlockPoint(f)
		f:ClearAllPoints()
		f:SetPoint(unpack(p))
		MovAny:LockPoint(f)
	end
end

function MovAny:ApplyPosition(f, opt)
	if not opt or self.NoMove[f:GetName()] then
		return
	end

	if opt.pos then
		local fn = f:GetName()
		if opt.orgPos == nil and not self:IsContainer(f:GetName()) and strmatch("BagFrame", f:GetName()) ~= nil then
			MovAny:StoreOrgPoints(f, opt)
		end

		if UIPARENT_MANAGED_FRAME_POSITIONS[fn] then
			f.ignoreFramePositionManager = true
		end

		self:UnlockPoint(f)
		f:ClearAllPoints()
		f:SetPoint(unpack(opt.pos))
		self:LockPoint(f)

		if f.OnMAPosition then
			f.OnMAPosition(f)
		end

		if f.attachedChildren then
			for i, v in pairs(f.attachedChildren) do
				if
					not v.ignoreFramePositionManager and v.GetName and UIPARENT_MANAGED_FRAME_POSITIONS[v:GetName()] and
						not v.ignoreFramePositionManager and
						not MovAny:IsFrameHooked(v) and
						v.GetName and
						UIPARENT_MANAGED_FRAME_POSITIONS[v:GetName()]
				 then
					v.UMFP = true
					v.ignoreFramePositionManager = true
				end
			end
		end

		if UIPanelWindows[fn] and f ~= GameMenuFrame then
			local left = GetUIPanel("left")
			local center = GetUIPanel("center")

			if f == left then
				UIParent.left = nil
				if center then
					UIParent.center = nil
					UIParent.left = center
				end
			elseif f == center then
				UIParent.center = nil
			end

			local wasShown = f:IsShown()
			if wasShown and (not MovAny:IsProtected(f) or not InCombatLockdown()) then
				HideUIPanel(f)
			end
			local optt = self:GetFrameOptions(fn)
			if optt then
				optt.UIPanelWindows = UIPanelWindows[fn]
			end
			UIPanelWindows[fn] = nil
			f:SetAttribute("UIPanelLayout-enabled", false)

			if wasShown and f ~= MerchantFrame and (not MovAny:IsProtected(f) or not InCombatLockdown()) then
				f:Show()
			end
		end
	end
end

function MovAny:ResetPosition(f, opt, readOnly)
	if not opt or (f.GetName and MovAny.NoMove[f:GetName()]) then
		return
	end
	MovAny:UnlockPoint(f)

	local umfp = nil
	if f.ignoreFramePositionManager then
		umfp = true
		f.ignoreFramePositionManager = nil
	end

	if opt.orgPos then
		self:RestoreOrgPoints(f, opt, readOnly)
	else
		return
	end

	if f.OnMAPositionReset then
		f.OnMAPositionReset(f, opt, readOnly)
	end
	if not readOnly then
		opt.pos = nil
	end

	if f.attachedChildren then
		for i, v in pairs(f.attachedChildren) do
			if v and not MovAny:IsFrameHooked(v) and v.GetName and v.UMFP then
				v.UMFP = nil
				v.ignoreFramePositionManager = nil
				umfp = true
			end
		end
	end

	if opt.UIPanelWindows then
		UIPanelWindows[f:GetName()] = opt.UIPanelWindows
		if not readOnly then
			opt.UIPanelWindows = nil
		end
		f:SetAttribute("UIPanelLayout-enabled", true)
		if f:IsShown() and (not MovAny:IsProtected(f) or not InCombatLockdown()) then
			f:Hide()
			ShowUIPanel(f)
		end
	end

	if umfp and not InCombatLockdown() then
		UIParent_ManageFramePositions()
	end

	f.MAOrgParent = nil
end

function MovAny:ApplyAlpha(f, opt)
	if not opt or MovAny.NoAlpha[f:GetName()] then
		return
	end
	local alpha = opt.alpha

	if alpha and alpha >= 0 and alpha <= 1 then
		if opt.originalAlpha == nil then
			opt.originalAlpha = f:GetAlpha()
		end
		f:SetAlpha(alpha)

		if f.attachedChildren then
			for i, v in pairs(f.attachedChildren) do
				if v:GetAlpha() ~= 1 then
					v.MAOrgAlpha = v:GetAlpha()
				end
				v:SetAlpha(alpha)
			end
		end
		if f.OnMAAlpha then
			f.OnMAAlpha(f, alpha)
		end
	end
end

function MovAny:ResetAlpha(f, opt, readOnly)
	if not opt or MovAny.NoAlpha[f:GetName()] then
		return
	end

	local alpha = opt.originalAlpha
	if alpha == nil or alpha > 1 then
		alpha = 1
	elseif alpha < 0 then
		alpha = 0
	end

	f:SetAlpha(alpha)

	if f.attachedChildren then
		for i, v in pairs(f.attachedChildren) do
			v:SetAlpha(alpha)
		end
	end

	if f.OnMAAlpha then
		f.OnMAAlpha(f, alpha)
	end
end

function MovAny:ApplyHide(f, opt, readOnly)
	if not opt or MovAny.NoHide[f:GetName()] then
		return
	end

	-- HideFrame fires OnMAHide event now
	if opt.hidden then
		self:HideFrame(f, readOnly)
	end
end

function MovAny:ResetHide(f, opt, readOnly)
	if not opt or MovAny.NoHide[f:GetName()] then
		return
	end

	local wasHidden = opt.hidden
	if not readOnly then
		opt.hidden = nil
	end

	if wasHidden then
		self:ShowFrame(f, readOnly)
	end

	if f.OnMAHide then
		f.OnMAHide(f, nil)
	end
end

function MovAny:ApplyScale(f, opt, readOnly)
	if not opt or not self:CanBeScaled(f) then
		return
	end

	self:UnlockScale(f)
	if f.GetName and self.ScaleWH[f:GetName()] then
		if opt.width or opt.height then

			if opt.width and opt.originalWidth == nil then
				opt.originalWidth = f:GetWidth()
			end
			if opt.height and opt.originalHeight == nil then
				opt.originalHeight = f:GetHeight()
			end
			if self.lHideOnScale[f:GetName()] then
				for i, v in pairs(self.lHideOnScale[f:GetName()]) do
					self:LockVisibility(v)
				end
			end
			if opt.width ~= nil and opt.width > 0 then
				f:SetWidth(opt.width)
			end
			if opt.height ~= nil and opt.height > 0 then
				f:SetHeight(opt.height)
			end
			self:LockScale(f)
			if self.lLinkedScaling[f:GetName()] then
				for i, v in pairs(self.lLinkedScaling[f:GetName()]) do
					if not self:IsFrameHooked(v) then
						self:ApplyScale(_G[v], opt)
					end
				end
			end
			if f.OnMAScale then
				f.OnMAScale(f, opt.width, opt.height)
			end
		end
	elseif opt.scale ~= nil and opt.scale >= 0 then
		if readOnly == nil and not opt.originalScale then
			opt.originalScale = f:GetScale()
		end

		f:SetScale(opt.scale)
		self:LockScale(f)

		if self.lHideOnScale[f:GetName()] then
			for i, v in pairs(self.lHideOnScale[f:GetName()]) do
				self:LockVisibility(v)
			end
		end

		if f.attachedChildren and not f.MANoScaleChildren then
			for i, v in pairs(f.attachedChildren) do
				self:ApplyScale(v, opt)
			end
		end

		if self.lLinkedScaling[f:GetName()] then
			for i, v in pairs(self.lLinkedScaling[f:GetName()]) do
				if not self:IsFrameHooked(v) then
					self:ApplyScale(_G[v], opt)
				end
			end
		end
		if f.OnMAScale then
			f.OnMAScale(f, opt.scale)
		end
	end
end

function MovAny:ResetScale(f, opt, readonly)
	if not opt or (f.GetName and MovAny.NoScale[f:GetName()]) then
		return
	end

	self:UnlockScale(f)
	if self.ScaleWH[f:GetName()] then
		if
			(opt.originalWidth and f:GetWidth() ~= opt.originalWidth) or
				(opt.originalHeight and f:GetHeight() ~= opt.originalHeight)
		 then
			if opt.originalWidth ~= nil and opt.originalWidth > 0 then
				f:SetWidth(opt.originalWidth)
			end
			if opt.originalHeight ~= nil and opt.originalHeight > 0 then
				f:SetHeight(opt.originalHeight)
			end
			if self.lHideOnScale[f:GetName()] then
				for i, v in pairs(self.lHideOnScale[f:GetName()]) do
					self:UnlockVisibility(v)
				end
			end
			if self.lLinkedScaling[f:GetName()] then
				local lf
				for i, v in pairs(self.lLinkedScaling[f:GetName()]) do
					if not self:IsFrameHooked(v) then
						lf = _G[v]
						if self:CanBeScaled(lf) then
							if self:IsProtected(lf) and InCombatLockdown() then
								self.pendingFrames[v] = opt
							else
								self:ResetScale(lf, opt)
							end
						end
					end
				end
			end
			if f.OnMAScale then
				f.OnMAScale(f, {opt.width, opt.height})
			end
		end
	elseif self:IsScalableFrame(f) then
		local scale = opt.originalScale or 1
		if scale == nil then
			return
		end
		if scale ~= f:GetScale() then
			f:SetScale(scale)
		end

		if self.lHideOnScale[f:GetName()] then
			for i, v in pairs(self.lHideOnScale[f:GetName()]) do
				self:UnlockVisibility(v)
			end
		end
		if f.attachedChildren and not f.MANoScaleChildren then
			for i, v in pairs(f.attachedChildren) do
				if not self:IsFrameHooked(v) then
					if self:CanBeScaled(v) then
						if self:IsProtected(v) and InCombatLockdown() then
							self.pendingFrames[i] = opt
						else
							self:ResetScale(v, opt)
						end
					end
				end
			end
		end
		if self.lLinkedScaling[f:GetName()] then
			for i, v in pairs(self.lLinkedScaling[f:GetName()]) do
				self:ResetScale(_G[v], opt)
			end
		end
		if f.OnMAScale then
			f.OnMAScale(f, scale)
		end
	end
end

-- modfied version of blizzards updateContainerFrameAnchors
-- to prevent this from hooking the original updateContainerFrameAnchors do a "/run DB.noBags = true" followed by "/reload"
function MovAny:UpdateContainerFrameAnchors()
	local frame, xOffset, yOffset, screenHeight, freeScreenHeight, leftMostPoint, column
	local screenWidth = GetScreenWidth()
	local containerScale = 1
	local leftLimit = 0

	while (containerScale > CONTAINER_SCALE) do
		screenHeight = GetScreenHeight() / containerScale
		-- Adjust the start anchor for bags depending on the multibars
		xOffset = CONTAINER_OFFSET_X / containerScale
		yOffset = CONTAINER_OFFSET_Y / containerScale
		-- freeScreenHeight determines when to start a new column of bags
		freeScreenHeight = screenHeight - yOffset
		leftMostPoint = screenWidth - xOffset
		column = 1
		local frameHeight
		for index, frameName in ipairs(ContainerFrame1.bags) do
			frameHeight = _G[frameName]:GetHeight()
			if freeScreenHeight < frameHeight then
				-- Start a new column
				column = column + 1
				leftMostPoint = screenWidth - (column * CONTAINER_WIDTH * containerScale) - xOffset
				freeScreenHeight = screenHeight - yOffset
			end
			freeScreenHeight = freeScreenHeight - frameHeight - VISIBLE_CONTAINER_SPACING
		end
		if leftMostPoint < leftLimit then
			containerScale = containerScale - 0.01
		else
			break
		end
	end

	if containerScale < CONTAINER_SCALE then
		containerScale = CONTAINER_SCALE
	end

	screenHeight = GetScreenHeight() / containerScale
	-- Adjust the start anchor for bags depending on the multibars
	xOffset = CONTAINER_OFFSET_X / containerScale
	yOffset = CONTAINER_OFFSET_Y / containerScale
	-- freeScreenHeight determines when to start a new column of bags
	freeScreenHeight = screenHeight - yOffset
	column = 0

	local bag = nil
	local lastBag = nil
	for index, frameName in ipairs(ContainerFrame1.bags) do
		frame = _G[frameName]
		bag = MovAny:GetBagInContainerFrame(frame)
		if
			not bag or
				(bag and not MovAny:IsFrameHooked(bag:GetName()) and not MovAny:GetMoverByFrameName(bag:GetName()))
		 then

			MovAny:UnlockScale(frame)
			frame:SetScale(containerScale)

			MovAny:UnlockPoint(frame)
			frame:ClearAllPoints()
			if lastBag == nil then -- First bag
				frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", GetScreenWidth() - xOffset - CONTAINER_WIDTH, yOffset)
			elseif freeScreenHeight < frame:GetHeight() then -- Start a new column
				column = column + 1
				freeScreenHeight = screenHeight - yOffset
				frame:SetPoint("BOTTOMLEFT", frame:GetParent(), "BOTTOMLEFT", GetScreenWidth() - xOffset - (column * CONTAINER_WIDTH) - CONTAINER_WIDTH, yOffset)
			else -- Anchor to the previous bag
				frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", select(4, lastBag:GetPoint(1)), lastBag:GetTop() + CONTAINER_SPACING)
			end
			freeScreenHeight = freeScreenHeight - frame:GetHeight() - VISIBLE_CONTAINER_SPACING

			lastBag = frame
		end
	end
end

----------------------------------------------------------------
-- X: slash commands

SLASH_KPACKMAMOVE1 = "/move"
SlashCmdList["KPACKMAMOVE"] = function(msg)
	if msg == nil or strlen(msg) == 0 then
		MovAny:ToggleOptionsMenu()
	else
		MovAny:ToggleMove(MovAny:Translate(msg))
	end
end

SLASH_KPACKMAUNMOVE1 = "/unmove"
SlashCmdList["KPACKMAUNMOVE"] = function(msg)
	if msg then
		if MovAny.FrameOptions[msg] then
			MovAny:ResetFrame(msg)
		elseif MovAny.FrameOptions[MovAny:Translate(msg)] then
			MovAny:ResetFrame(MovAny:Translate(msg))
		end
	else
		MAPrint(L["Syntax: /unmove framename"])
	end
end

SLASH_KPACKMAHIDE1 = "/hide"
SlashCmdList["KPACKMAHIDE"] = function(msg)
	if msg == nil or strlen(msg) == 0 then
		MAPrint(L["Syntax: /hide ProfileName"])
		return
	end
	MovAny:ToggleHide(MovAny:Translate(msg))
end

SLASH_KPACKMAIMPORT1 = "/moveimport"
SlashCmdList["KPACKMAIMPORT"] = function(msg)
	if msg == nil or strlen(msg) == 0 then
		MAPrint(L["Syntax: /moveimport ProfileName"])
		return
	end

	if InCombatLockdown() then
		MAPrint(L["Disabled during combat."])
		return
	end

	if DB.CharacterSettings[msg] == nil then
		MAPrint(L:F("Unknown profile: %s", msg))
		return
	end

	MovAny:CopySettings(msg, MovAny:GetProfileName())
	MovAny:UpdateProfile()
	MAPrint(L:F("Profile imported: %s", msg))
end

SLASH_KPACKMAEXPORT1 = "/moveexport"
SlashCmdList["KPACKMAEXPORT"] = function(msg)
	if msg == nil or strlen(msg) == 0 then
		MAPrint(L["Syntax: /moveexport ProfileName"])
		return
	end

	MovAny:CopySettings(MovAny:GetProfileName(), msg)
	MAPrint(L:F("Profile exported: %s", msg))
end

SLASH_KPACKMALIST1 = "/movelist"
SlashCmdList["KPACKMALIST"] = function(msg)
	MAPrint(L["Profiles"] .. ":")
	for i, val in pairs(DB.CharacterSettings) do
		local str = ' "' .. i .. '"'
		if val == MovAny.FrameOptions then
			str = str .. " <- " .. L["Current"]
		end
		MAPrint(str)
	end
end

SLASH_KPACKMADELETE1 = "/movedelete"
SLASH_KPACKMADELETE2 = "/movedel"
SlashCmdList["KPACKMADELETE"] = function(msg)
	if msg == nil or strlen(msg) == 0 then
		MAPrint(L["Syntax: /movedelete ProfileName"])
		return
	end

	if DB.CharacterSettings[msg] == nil then
		MAPrint(L:F("Unknown profile: %s", msg))
		return
	end

	if msg == MovAny:GetProfileName() then
		if InCombatLockdown() then
			MAPrint(L["Can't delete current profile during combat"])
			return
		end
		MovAny:ResetAll()
	else
		DB.CharacterSettings[msg] = nil
	end
	MAPrint(L:F("Profile deleted: %s", msg))
end

----------------------------------------------------------------
-- X: global functions

function numfor(n)
	if n == nil then
		return "nil"
	end
	return strformat("%.2f", n)
end

function MAGetParent(f)
	if not f or not f.GetParent then
		return
	end
	local p = f:GetParent()
	if p == nil then
		return UIParent
	end

	return p
end

function MAGetScale(f, effective)
	if not f or not f.GetScale then
		return 1
	elseif MovAny.NoScale[f:GetName()] then
		return f:GetScale()
	else
		if not f.GetScale or f:GetScale() == nil then
			return 1
		end

		if effective then
			return f:GetEffectiveScale()
		else
			return f:GetScale()
		end
	end
end

function MAPrint(msgKey, msgHighlight, msgAdditional, r, g, b, frame)
	local msgOutput
	if frame then
		msgOutput = frame
	else
		msgOutput = DEFAULT_CHAT_FRAME
	end

	if msgKey == "" then
		return
	end
	if msgKey == nil then
		msgKey = "<nomsg>"
	end
	if msgHighlight == nil or msgHighlight == "" then
		msgHighlight = " "
	end
	if msgAdditional == nil or msgAdditional == "" then
		msgAdditional = " "
	end
	if msgOutput then
		msgOutput:AddMessage("|caaff0000MoveAnything|r|caaffff00>|r " .. msgKey .. " |caaaaddff" .. msgHighlight .. "|r" .. msgAdditional, r, g, b)
	end
end

----------------------------------------------------------------

function MovAny:EnableFrame(fn)
	if fn == nil then
		return
	end

	local opts = self:GetFrameOptions(fn)
	if not opts then
		return
	end
	opts.disabled = nil

	local f = _G[fn]
	if not f then
		return
	end
	if not self:HookFrame(fn, f) then
		return
	end
	self:ApplyScale(f, opts)
	self:ApplyPosition(f, opts)
	self:ApplyAlpha(f, opts)
	self:ApplyHide(f, opts)
end

function MovAny:DisableFrame(fn)
	if fn == nil then
		return
	end
	self:StopMoving(fn)

	local opt = self:GetFrameOptions(fn)
	if not opt then
		return
	end
	opt.disabled = true

	local f = _G[fn]
	if not f then
		return
	end

	if f.OnMAPreReset then
		f.OnMAPreReset(f)
	end

	self:ResetScale(f, opt, true)
	self:ResetPosition(f, opt, true)
	self:ResetAlpha(f, opt, true)
	self:ResetHide(f, opt, true)
end

function MovAny:HookTooltip(mover)
	local l, r, t, b, anchor
	local tooltip = GameTooltip
	l = mover:GetLeft() * mover:GetEffectiveScale()
	r = mover:GetRight() * mover:GetEffectiveScale()
	t = mover:GetTop() * mover:GetEffectiveScale()
	b = mover:GetBottom() * mover:GetEffectiveScale()

	anchor = "CENTER"
	if ((b + t) / 2) < ((UIParent:GetTop() * UIParent:GetScale()) / 2) - 25 then
		anchor = "BOTTOM"
	elseif ((b + t) / 2) > ((UIParent:GetTop() * UIParent:GetScale()) / 2) + 25 then
		anchor = "TOP"
	end
	if anchor ~= "CENTER" then
		if ((l + r) / 2) > ((UIParent:GetRight() * UIParent:GetScale()) / 2) + 25 then
			anchor = anchor .. "RIGHT"
		elseif ((l + r) / 2) < ((UIParent:GetRight() * UIParent:GetScale()) / 2) - 25 then
			anchor = anchor .. "LEFT"
		end
	end
	MovAny:UnlockPoint(tooltip)
	tooltip:ClearAllPoints()

	if tooltip:GetOwner() then
		tooltip.MASkip = true
		tooltip:SetOwner(tooltip:GetOwner(), "ANCHOR_NONE")
		tooltip.MASkip = nil
	end

	tooltip:SetPoint(anchor, mover, anchor, 0, 0)
	tooltip:SetParent(mover)

	MovAny:LockPoint(tooltip)

	local opt = MovAny:GetFrameOptions(mover:GetName())
	MovAny:ApplyHide(tooltip, opt, true)
	mover.attachedChildren = {tooltip}
end

function MovAny:hGameTooltip_SetDefaultAnchor(relative)
	local tooltip = GameTooltip
	if tooltip.MASkip then
		return
	end
	if MovAny:IsFrameHooked("TooltipMover") then
		MovAny:HookTooltip(_G["TooltipMover"])
	elseif MovAny:IsFrameHooked("BagItemTooltipMover") then
		local opt = {alpha = 1.0, scale = 1.0}
		MovAny:UnlockPoint(tooltip)
		MovAny:ApplyScale(tooltip, opt, true)
		MovAny:ApplyAlpha(tooltip, opt, true)
		MovAny:ResetHide(tooltip, opt, true)
		if not tooltip:IsProtected() then
			tooltip.MASkip = true
			GameTooltip_SetDefaultAnchor(tooltip, relative)
			tooltip.MASkip = nil
		end
	end
end

function MovAny:hGameTooltip_SetOwner(owner, anchor)
	if GameTooltip.MASkip then
		return
	end
	if owner:GetName() ~= nil and strmatch(owner:GetName(), "ContainerFrame[1-9][0-9]*") then
		if MovAny:IsFrameHooked("BagItemTooltipMover") then
			MovAny:HookTooltip(_G["BagItemTooltipMover"])
		end
	end
end

-- X: MA tooltip funcs
function MovAny:TooltipShow()
	if not this.tooltipText then
		return
	end
	if (DB.tooltips and not IsShiftKeyDown()) or (not DB.tooltips and IsShiftKeyDown()) then
		GameTooltip:SetOwner(this, "ANCHOR_CURSOR")
		GameTooltip:ClearLines()
		GameTooltip:AddLine(this.tooltipText, nil, nil, nil, true)
		GameTooltip:Show()
	end
end

function MovAny:TooltipHide()
	GameTooltip:Hide()
end

function MovAny:TooltipShowMultiline(reserved, parent, tooltipLines)
	if this and parent == nil then
		parent = this
	end
	if this and this.tooltipLines then
		tooltipLines = this.tooltipLines
	end
	if tooltipLines == nil then
		tooltipLines = parent.tooltipLines
	end
	if tooltipLines == nil then
		tooltipLines = MovAny:GetFrameTooltipLines(MovAny.frames[parent.idx].name)
	end
	if tooltipLines == nil then
		return
	end
	local g = (next(tooltipLines) ~= nil)
	if not g then
		return
	end
	if (DB.tooltips and not IsShiftKeyDown()) or (not DB.tooltips and IsShiftKeyDown()) then
		GameTooltip:SetOwner(parent, "ANCHOR_CURSOR")
		GameTooltip:ClearLines()
		for i, v in ipairs(tooltipLines) do
			GameTooltip:AddLine(v, nil, nil, nil, true)
		end
		GameTooltip:Show()
	end
end

function MovAny:GetFrameTooltipLines(fn)
	if not fn then
		return
	end

	local opts = MovAny:GetFrameOptions(fn)
	local o = MovAny:GetFrame(fn)
	local msgs = {}
	local added = nil

	tinsert(msgs, o.helpfulName or fn)
	if opts then
		if opts.hidden then
			if MovAny.HideList[fn] then
				tinsert(msgs, "Specially hidden")
			else
				tinsert(msgs, "Hidden")
			end
		end
	end
	if o and o.helpfulName and o.helpfulName ~= fn and fn ~= nil then
		tinsert(msgs, " ")
		tinsert(msgs, "Frame: " .. fn)
	end
	if opts then
		if opts.pos then
			if not added then
				tinsert(msgs, " ")
			end
			tinsert(msgs, "Position: " .. numfor(opts.pos[4]) .. ", " .. numfor(opts.pos[5]))
			added = true
		end
		if opts.scale then
			if not added then
				tinsert(msgs, " ")
			end
			tinsert(msgs, "Scale: " .. numfor(opts.scale))
			added = true
		end
		if opts.alpha then
			if not added then
				tinsert(msgs, " ")
			end
			tinsert(msgs, "Alpha: " .. numfor(opts.alpha))
			added = true
		end

		added = nil
		if opts.scale then
			if not added then
				tinsert(msgs, " ")
			end
			tinsert(msgs, "Original Scale: " .. numfor(opts.originalScale or 1))
			added = true
		end
		if opts.alpha and opts.originalAlpha and opts.alpha ~= opts.originalAlpha then
			if not added then
				tinsert(msgs, " ")
			end
			tinsert(msgs, "Original Alpha: " .. numfor(opts.originalAlpha))
			added = true
		end
	end
	return msgs
end

----------------------------------------------------------------
-- X: debugging code

function echo(...)
	local msg = ""
	for k, v in pairs({...}) do
		msg = msg .. k .. "=[" .. tostring(v) .. "] "
	end
	DEFAULT_CHAT_FRAME:AddMessage(msg)
end

function decho(...)
	local msg = ""
	for k, v in pairs({...}) do
		if type(v) == "table" then
			msg = msg .. k .. "=[" .. dechoSub(v, 1) .. "] \n"
		else
			msg = msg .. k .. "=[" .. tostring(v) .. "] \n"
		end
	end
	DEFAULT_CHAT_FRAME:AddMessage(msg)
end

function dechoSub(t, d)
	local msg = ""
	if d > 10 then
		return msg
	end
	for k, v in pairs(t) do
		if type(v) == "table" then
			msg = msg .. k .. "=[" .. dechoSub(v, d + 1) .. "] \n"
		else
			msg = msg .. k .. "=[" .. tostring(v) .. "] \n"
		end
	end
	return msg
end

function MovAny:DebugFrameAtCursor()
	local o = GetMouseFocus()
	if o then
		if self:IsMAFrame(o:GetName()) then
			if self:IsMover(o:GetName()) and o.tagged then
				o = o.tagged
			end
		end

		if o ~= WorldFrame and o ~= UIParent then
			MovAny:Dump(o)
		end
	end
end

function MovAny:Dump(o)
	if type(o) ~= "table" then
		MAPrint(L:F("Unsupported type: %s", type(o)))
		return
	end

	MAPrint("Name: " .. o:GetName())

	if o.GetObjectType then
		MAPrint("Type: " .. o:GetObjectType())
	end

	local p = o:GetParent()
	if p == nil then
		p = UIParent
	end
	if o ~= p then
		MAPrint("Parent: " .. (p:GetName() or "unnamed"))
	end

	if o.MAParent then
		MAPrint("MA Parent: " .. (o.MAParent:GetName() or "unnamed"))
	end

	local point = {o:GetPoint()}
	if point and point[1] and point[2] and point[3] and point[4] and point[5] then
		if not point[2] then
			point[2] = UIParent
		end
		MAPrint("Point: " .. point[1] .. ", " .. point[2]:GetName() .. ", " .. point[3] .. ", " .. point[4] .. ", " .. point[5])
	end

	if o:GetTop() then
		MAPrint("Top: " .. o:GetTop())
	end
	if o:GetRight() then
		MAPrint("Right: " .. o:GetRight())
	end
	if o:GetBottom() then
		MAPrint("Bottom: " .. o:GetBottom())
	end
	if o:GetLeft() then
		MAPrint("Left: " .. o:GetLeft())
	end
	if o:GetHeight() then
		MAPrint("Height: " .. o:GetHeight())
	end
	if o:GetWidth() then
		MAPrint("Width: " .. o:GetWidth())
	end
	if o.GetScale then
		MAPrint("Scale: " .. o:GetScale())
	end
	if o.GetEffectiveScale then
		MAPrint("Scale Effective: " .. o:GetEffectiveScale())
	end
	if o.GetAlpha then
		MAPrint("Alpha: " .. o:GetAlpha())
	end
	if o.GetEffectiveAlpha then
		MAPrint("Alpha Effective: " .. o:GetEffectiveAlpha())
	end
	if o.GetFrameLevel then
		MAPrint("Level: " .. o:GetFrameLevel())
	end
	if o.GetFrameStrata then
		MAPrint("Strata: " .. o:GetFrameStrata())
	end
	if o.IsUserPlaced then
		if o:IsUserPlaced() then
			MAPrint("UserPlaced: true")
		else
			MAPrint("UserPlaced: false")
		end
	end
	if o.IsMovable then
		if o:IsMovable() then
			MAPrint("Movable: true")
		else
			MAPrint("Movable: false")
		end
	end
	if o.IsResizable then
		if o:IsResizable() then
			MAPrint("Resizable: true")
		else
			MAPrint("Resizable: false")
		end
	end
	if o.IsTopLevel and o:IsToplevel() then
		MAPrint("Top Level: true")
	end
	if o.IsProtected and o:IsProtected() then
		MAPrint("Protected: true")
	elseif o.MAProtected then
		MAPrint("Virtually protected: true")
	end
	if o.IsKeyboardEnabled then
		if o:IsKeyboardEnabled() then
			MAPrint("KeyboardEnabled: true")
		else
			MAPrint("KeyboardEnabled: false")
		end
	end
	if o.IsMouseEnabled then
		if o:IsMouseEnabled() then
			MAPrint("MouseEnabled: true")
		else
			MAPrint("MouseEnabled: false")
		end
	end
	if o.IsMouseWheelEnabled then
		if o:IsMouseWheelEnabled() then
			MAPrint("MouseWheelEnabled: true")
		else
			MAPrint("MouseWheelEnabled: false")
		end
	end

	local opts = self:GetFrameOptions(o:GetName())
	if opts ~= nil then
		MAPrint("MA stored variables:")
		for i, v in pairs(opts) do
			if i ~= "cat" and i ~= "name" then
				if v == nil then
					MAPrint("  " .. i .. ": nil")
				elseif v == true then
					MAPrint("  " .. i .. ": true")
				elseif v == false then
					MAPrint("  " .. i .. ": false")
				elseif type(v) == "number" then
					MAPrint("  " .. i .. ": " .. numfor(v))
				elseif type(v) == "table" then
					MAPrint(" " .. i .. ": table")
					decho(v)
				else
					MAPrint(" " .. i .. " is a " .. type(v) .. "")
				end
			end
		end
	end
end

SLASH_KPACKMADBG1 = "/madbg"
SlashCmdList["KPACKMADBG"] = function(msg)
	if msg == nil or msg == "" then
		MADebug()
		return
	end
	local f = _G[msg]
	if f == nil then
		local tr = MovAny:Translate(msg)
		if tr then
			f = _G[tr]
		end
	end
	if f == nil then
		MAPrint(L:F("UI element not found: %s", msg))
	else
		MovAny:Dump(f)
	end
end

function MADebug()
	local ct = 0
	MAPrint("Custom frames: " .. tlen(DB.CustomFrames))
	for i, v in pairs(DB.CustomFrames) do
		ct = ct + 1
		MAPrint(ct .. ": " .. v.name)
	end

	ct = 0
	MAPrint("Frame options: " .. tlen(MovAny.FrameOptions))
	for i, v in pairs(MovAny.FrameOptions) do
		ct = ct + 1
		MAPrint(ct .. ": " .. v.name)
	end
end

MovAny.dbg = dbg