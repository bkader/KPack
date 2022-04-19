local KPack = KPack
if not KPack then return end

local L = KPack.L
local MAOptions
local MovAny_SetupDatabase
local MovAny_TooltipShow
local MovAny_TooltipHide
local MovAny_TooltipShowMultiline

local void = KPack.Noop
local new, del = KPack.newTable, KPack.delTable

-- X: http://lua-users.org/wiki/CopyTable
local function MA_tdeepcopy(object)
	local lookup_table = new()
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
	del(lookup_table)
	return _copy(object)
end
_G.MA_tdeepcopy = MA_tdeepcopy

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
	MovAny_Print(s)
end

local defaults = {
	tooltips = true,
	characters = {},
	profiles = {}
}

kMADB = {
	tooltips = true,
	characters = {},
	profiles = {},
}

MovAny = {
	fVoid = function() end,
	guiLines = -1,
	resetConfirm = "",
	bagFrames = {},
	cats = {},
	customCat = nil,
	defFrames = {},
	frames = {},
	framesCount = 0,
	framesIdx = {},
	framesUnsupported = {},
	initRun = nil,
	lastFrameName = nil,
	lSafeRelatives = {},
	lAllowedTypes = {
		Frame = "Frame",
		FontString = "FontString",
		Texture = "Texture",
		Button = "Button",
		CheckButton = "CheckButton",
		StatusBar = "StatusBar",
		GameTooltip = "GameTooltip",
		MessageFrame = "MessageFrame",
		PlayerModel = "PlayerModel",
		ColorSelect = "ColorSelect",
		EditBox = "EbitBox",
		ScrollingMessageFrame = "ScrollingMessageFrame"
	},
	lDisallowedFrames = {
		UIParent = "UIParent",
		WorldFrame = "WorldFrame",
		CinematicFrame = "CinematicFrame"
	},
	lDelayedSync = {
		PlayerTalentFrame = L.FRAME_ONLY_ONCE_OPENED,
		BankBagFrame1 = L.FRAME_ONLY_WHEN_BANK_IS_OPEN,
		BankBagFrame2 = L.FRAME_ONLY_WHEN_BANK_IS_OPEN,
		BankBagFrame3 = L.FRAME_ONLY_WHEN_BANK_IS_OPEN,
		BankBagFrame4 = L.FRAME_ONLY_WHEN_BANK_IS_OPEN,
		BankBagFrame5 = L.FRAME_ONLY_WHEN_BANK_IS_OPEN,
		BankBagFrame6 = L.FRAME_ONLY_WHEN_BANK_IS_OPEN,
		BankBagFrame7 = L.FRAME_ONLY_WHEN_BANK_IS_OPEN
	},
	lCreateBeforeInteract = {
		AchievementAlertFrame1 = "AchievementAlertFrameTemplate",
		AchievementAlertFrame2 = "AchievementAlertFrameTemplate",
		GroupLootFrame1 = "GroupLootFrameTemplate",
		GroupLootFrame2 = "GroupLootFrameTemplate",
		GroupLootFrame3 = "GroupLootFrameTemplate",
		GroupLootFrame4 = "GroupLootFrameTemplate"
	},
	lRunOnceBeforeInteract = {
		AchievementAlertFrame1 = AchievementFrame_LoadUI,
		AchievementAlertFrame2 = AchievementFrame_LoadUI,
		--[[ -- enable the following to auto load standard ui sub addons, will initially use more memory but will avoid the small hickups when they eventually do load. also makes more standard frames available for interaction
		AuctionFrame = AuctionFrame_LoadUI,
		BattlefieldMinimap = BattlefieldMinimap_LoadUI,
		BarberShopFrame = function() BarberShopFrame_LoadUI() ShowUIPanel(BarberShopFrame) HideUIPanel(BarberShopFrame) end,
		CalendarFrame = Calendar_LoadUI,
		ClassTrainerFrame = ClassTrainerFrame_LoadUI,
		GMSurveyFrame = GMSurveyFrame_LoadUI,
		GuildBankFrame = GuildBankFrame_LoadUI,
		InspectFrame = InspectFrame_LoadUI,
		PlayerTalentFrame = TalentFrame_LoadUI,
		MacroFrame = MacroFrame_LoadUI,
		TradeSkillFrame = TradeSkillFrame_LoadUI,
		TimeManagerClockButton = TimeManager_LoadUI,
		--]]
		ReputationWatchBar = function()
			if ReputationWatchBar_Update then
				hooksecurefunc("ReputationWatchBar_Update", MovAny.hReputationWatchBar_Update)
			end
		end,
		QuestLogDetailFrame = function()
			if not QuestLogDetailFrame:IsShown() then
				ShowUIPanel(QuestLogDetailFrame)
				HideUIPanel(QuestLogDetailFrame)
			end
		end,
		QuestFrame = function()
			hooksecurefunc(QuestFrame, "Show", function()
				if MovAny:IsModified("QuestFrame") then
					_G.GossipFrame:Hide()
				end
			end)
		end,
		AuctionFrame = function()
			local f = _G.AuctionDressUpFrame
			if not f then
				return true
			end
			f:SetScript("OnShow", function() PlaySound("igCharacterInfoOpen") end)
			f:SetScript("OnHide", function() PlaySound("igCharacterInfoClose") end)
			if not MovAny:IsModified(f) then
				f:SetPoint("TOPLEFT", "AuctionFrame", "TOPRIGHT", -2, -28)
			end
		end
	},
	lRunBeforeInteract = {
		MainMenuBar = function()
			if not MovAny.frameOptions["VehicleMenuBar"] or not MovAny.frameOptions["VehicleMenuBar"].pos then
				local v = _G["VehicleMenuBar"]
				v:ClearAllPoints()
				v:SetPoint("BOTTOMLEFT", "UIParent", "BOTTOMLEFT", UIParent:GetWidth() / 2 - v:GetWidth() / 2, 0)
			end
		end,
		MultiBarLeft = function()
			if MovAny:IsModified("MultiBarLeftHorizontalMover") then
				MovAny:ResetFrame("MultiBarLeftHorizontalMover")
			end
		end,
		MultiBarRight = function()
			if MovAny:IsModified("MultiBarRightHorizontalMover") then
				MovAny:ResetFrame("MultiBarRightHorizontalMover")
			end
		end,
		VehicleMenuBarActionButtonFrame = function()
			VehicleMenuBarActionButtonFrame:SetHeight(VehicleMenuBarActionButton1:GetHeight() + 2)
			VehicleMenuBarActionButtonFrame:SetWidth((VehicleMenuBarActionButton1:GetWidth() + 2) * VEHICLE_MAX_ACTIONBUTTONS)
		end,
		LFDSearchStatus = function()
			local opt = MovAny:GetFrameOptions("LFDSearchStatus")
			if not opt or not opt.frameStrata then
				LFDSearchStatus:SetFrameStrata("TOOLTIP")
			end
		end
	},
	lRunAfterInteract = {},
	lCreateVMs = {
		"BagFrame1",
		"BagFrame2",
		"BagFrame3",
		"BagFrame4",
		"BagFrame5",
		"KeyRingFrame"
	},
	lForcedLock = {
		-- Boss1TargetFrame = "Boss1TargetFrame",
		-- Boss2TargetFrame = "Boss2TargetFrame",
		-- Boss3TargetFrame = "Boss3TargetFrame",
		-- Boss4TargetFrame = "Boss4TargetFrame",
		ActionButton1 = "ActionButton1",
		BonusActionButton1 = "BonusActionButton1"
	},
	lEnableMouse = {
		WatchFrame,
		DurabilityFrame,
		CastingBarFrame,
		WorldStateScoreFrame,
		WorldStateAlwaysUpFrame,
		AlwaysUpFrame1,
		AlwaysUpFrame2,
		VehicleMenuBar,
		TargetFrameSpellBar,
		FocusFrameSpellBar,
		MirrorTimer1,
		MiniMapInstanceDifficulty,
		EclipseBarFrame
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
		buffs = "PlayerBuffsMover",
		debuffs = "PlayerDebuffsMover",
		GameTooltip = "TooltipMover",
		ShapeshiftBarFrame = "ShapeshiftButtonsMover",
		TemporaryEnchantFrame = "PlayerBuffsMover",
		TempEnchant1 = "PlayerBuffsMover",
		ConsolidatedBuffs = "PlayerBuffsMover",
		BuffFrame = "PlayerBuffsMover"
	},
	lTranslateSec = {
		ShapeshiftBarFrame = "ShapeshiftButtonsMover",
		BuffFrame = "PlayerBuffsMover",
		ConsolidatedBuffFrame = "PlayerBuffsMover"
	},
	lFrameNameRewrites = {
		TargetOfFocusDebuffsMover = "FocusFrameToTDebuffsMover",
		PVPParentFrame = "PVPFrame"
	},
	lDeleteFrameNames = {
		BuffFrame = "BuffFrame",
		ConsolidatedBuffFrame = "ConsolidatedBuffFrame",
		TemporaryEnchantFrame = "TemporaryEnchantFrame"
	},
	lHideOnScale = {
		["MainMenuExpBar"] = {
			MainMenuXPBarTexture0,
			MainMenuXPBarTexture1,
			MainMenuXPBarTexture2,
			MainMenuXPBarTexture3,
			ExhaustionTick,
			ExhaustionTickNormal,
			ExhaustionTickHighlight,
			ExhaustionLevelFillBar,
			MainMenuXPBarTextureLeftCap,
			MainMenuXPBarTextureRightCap,
			MainMenuXPBarTextureMid,
			MainMenuXPBarDiv1,
			MainMenuXPBarDiv2,
			MainMenuXPBarDiv3,
			MainMenuXPBarDiv4,
			MainMenuXPBarDiv5,
			MainMenuXPBarDiv6,
			MainMenuXPBarDiv7,
			MainMenuXPBarDiv8,
			MainMenuXPBarDiv9,
			MainMenuXPBarDiv10,
			MainMenuXPBarDiv11,
			MainMenuXPBarDiv12,
			MainMenuXPBarDiv13,
			MainMenuXPBarDiv14,
			MainMenuXPBarDiv15,
			MainMenuXPBarDiv16,
			MainMenuXPBarDiv17,
			MainMenuXPBarDiv18,
			MainMenuXPBarDiv19
		},
		["ReputationWatchBar"] = {
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
		["BasicActionButtonsMover"] = {
			ActionBarDownButton = "ActionBarDownButton",
			ActionBarUpButton = "ActionBarUpButton"
		},
		["ReputationWatchBar"] = {
			ReputationWatchStatusBar = "ReputationWatchStatusBar"
		},
		["PlayerFrame"] = {
			ComboFrame = "ComboFrame"
		}
	},
	rendered = nil,
	nextFrameIdx = 1,
	pendingActions = {},
	pendingFrames = {},
	pendingMovers = {},
	minimizedMovers = {},
	SCROLL_HEIGHT = 24,
	currentMover = nil,
	moverPrefix = "MAMover",
	moverNextId = 1,
	movers = {},
	frameEditors = {},
	DDMPointList = {
		{text = "Top Left", value = "TOPLEFT"},
		{text = "Top", value = "TOP"},
		{text = "Top Right", value = "TOPRIGHT"},
		{text = "Left", value = "LEFT"},
		{text = "Center", value = "CENTER"},
		{text = "Right", value = "RIGHT"},
		{text = "Bottom Left", value = "BOTTOMLEFT"},
		{text = "Bottom", value = "BOTTOM"},
		{text = "Bottom Right", value = "BOTTOMRIGHT"}
	},
	DDMStrataList = {
		{text = "Background", value = "BACKGROUND"},
		{text = "Low", value = "LOW"},
		{text = "Medium", value = "MEDIUM"},
		{text = "High", value = "HIGH"},
		{text = "Dialog", value = "DIALOG"},
		{text = "Fullscreen", value = "FULLSCREEN"},
		{text = "Fullscreen Dialog", value = "FULLSCREEN_DIALOG"},
		{text = "Tooltip", value = "TOOLTIP"}
	},
	ScaleWH = {
		MainMenuExpBar = "MainMenuExpBar",
		ReputationWatchBar = "ReputationWatchBar",
		ReputationWatchStatusBar = "ReputationWatchStatusBar",
		WatchFrame = "WatchFrame"
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
		--[[VehicleMenuBarHealthBar = "UIParent",
		VehicleMenuBarLeaveButton = "UIParent",
		VehicleMenuBarPowerBar = "UIParent",]]
		MultiCastActionBarFrame = "UIParent",
		MainMenuBarRightEndCap = "UIParent",
		MainMenuBarMaxLevelBar = "UIParent",
		TargetFrameSpellBar = "UIParent",
		FocusFrameSpellBar = "UIParent",
		--LFDSearchStatus = "UIParent",
		MANudger = "UIParent",
		MultiBarBottomRight = "UIParent",
		MultiBarBottomLeft = "UIParent",
		PlayerDebuffsMover = "UIParent",
		EclipseBarFrame = "UIParent",
		PaladinPowerBar = "UIParent",
		TotemFrame = "UIParent",
		ShardBarFrame = "UIParent"
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
		MinimapNorthTag = "MinimapNorthTag",
		FramerateLabel = "FramerateLabel"
	},
	NoHide = {
		FramerateLabel = "FramerateLabel",
		UIPanelMover1 = "UIPanelMover1",
		UIPanelMover2 = "UIPanelMover2",
		UIPanelMover3 = "UIPanelMover3",
		WorldMapFrame = "WorldMapFrame"
	},
	NoFE = {
		MainMenuBarMaxLevelBar = "MainMenuBarMaxLevelBar"
	},
	NoMove = {
		MinimapBackdrop = "MinimapBackdrop",
		MinimapNorthTag = "MinimapNorthTag",
		WorldMapFrame = "WorldMapFrame"
	},
	NoScale = {
		WorldStateAlwaysUpFrame = "WorldStateAlwaysUpFrame",
		MainMenuBarArtFrame = "MainMenuBarArtFrame",
		MainMenuBarMaxLevelBar = "MainMenuBarMaxLevelBar",
		MinimapBorderTop = "MinimapBorderTop",
		MinimapBackdrop = "MinimapBackdrop",
		MinimapNorthTag = "MinimapNorthTag",
		--WorldMapFrame = "WorldMapFrame",
		FramerateLabel = "FramerateLabel"
	},
	NoReparent = {
		TargetFrameSpellBar = "TargetFrameSpellBar",
		FocusFrameSpellBar = "FocusFrameSpellBar",
		VehicleMenuBarHealthBar = "VehicleMenuBarHealthBar",
		VehicleMenuBarLeaveButton = "VehicleMenuBarLeaveButton",
		VehicleMenuBarPowerBar = "VehicleMenuBarPowerBar",
		EclipseBarFrame = "EclipseBarFrame"
	},
	NoUnanchorRelatives = {
		FramerateLabel = "FramerateLabel",
		WorldStateAlwaysUpFrame = "WorldStateAlwaysUpFrame"
	},
	NoUnanchoring = {
		BuffFrame = "BuffFrame",
		RuneFrame = "RuneFrame",
		TotemFrame = "TotemFrame",
		ComboFrame = "ComboFrame",
		MANudger = "MANudger",
		TimeManagerClockButton = "TimeManagerClockButton",
		PartyMember1DebuffsMover = "PartyMember1DebuffsMover",
		PartyMember2DebuffsMover = "PartyMember2DebuffsMover",
		PartyMember3DebuffsMover = "PartyMember3DebuffsMover",
		PartyMember4DebuffsMover = "PartyMember4DebuffsMover",
		PetDebuffsMover = "PetDebuffsMover",
		TargetBuffsMover = "TargetBuffsMover",
		TargetDebuffsMover = "TargetDebuffsMover",
		FocusDebuffsMover = "FocusDebuffsMover",
		TargetFrameToTDebuffsMover = "TargetFrameToTDebuffsMover",
		TemporaryEnchantFrame = "TemporaryEnchantFrame",
		AuctionDressUpFrame = "AuctionDressUpFrame"
	},
	lAllowedMAFrames = {
		MAOptions = "MAOptions",
		MANudger = "MANudger",
		MAPortDialog = "MAPortDialog",
		GameMenuButtonMoveAnything = "GameMenuButtonMoveAnything"
	},
	CONTAINER_FRAME_TABLE = {
		[0] = {"Interface\\ContainerFrame\\UI-BackpackBackground", 256, 256, 239},
		[1] = {"Interface\\ContainerFrame\\UI-Bag-1x4", 256, 128, 96},
		[2] = {"Interface\\ContainerFrame\\UI-Bag-1x4", 256, 128, 96},
		[3] = {"Interface\\ContainerFrame\\UI-Bag-1x4", 256, 128, 96},
		[4] = {"Interface\\ContainerFrame\\UI-Bag-1x4", 256, 128, 96},
		[5] = {"Interface\\ContainerFrame\\UI-Bag-1x4+2", 256, 128, 116},
		[6] = {"Interface\\ContainerFrame\\UI-Bag-1x4+2", 256, 128, 116},
		[7] = {"Interface\\ContainerFrame\\UI-Bag-1x4+2", 256, 128, 116},
		[8] = {"Interface\\ContainerFrame\\UI-Bag-2x4", 256, 256, 137},
		[9] = {"Interface\\ContainerFrame\\UI-Bag-2x4+2", 256, 256, 157},
		[10] = {"Interface\\ContainerFrame\\UI-Bag-2x4+2", 256, 256, 157},
		[11] = {"Interface\\ContainerFrame\\UI-Bag-2x4+2", 256, 256, 157},
		[12] = {"Interface\\ContainerFrame\\UI-Bag-3x4", 256, 256, 178},
		[13] = {"Interface\\ContainerFrame\\UI-Bag-3x4+2", 256, 256, 198},
		[14] = {"Interface\\ContainerFrame\\UI-Bag-3x4+2", 256, 256, 198},
		[15] = {"Interface\\ContainerFrame\\UI-Bag-3x4+2", 256, 256, 198},
		[16] = {"Interface\\ContainerFrame\\UI-Bag-4x4", 256, 256, 219},
		[18] = {"Interface\\ContainerFrame\\UI-Bag-4x4+2", 256, 256, 239},
		[20] = {"Interface\\ContainerFrame\\UI-Bag-5x4", 256, 256, 259},
		[22] = {"Interface\\ContainerFrame\\UI-Bag-5x4", 256, 256, 279},
		[24] = {"Interface\\ContainerFrame\\UI-Bag-5x4", 256, 256, 299},
		[26] = {"Interface\\ContainerFrame\\UI-Bag-5x4", 256, 256, 319},
		[28] = {"Interface\\ContainerFrame\\UI-Bag-5x4", 256, 256, 339},
		[30] = {"Interface\\ContainerFrame\\UI-Bag-5x4", 256, 256, 359},
		[32] = {"Interface\\ContainerFrame\\UI-Bag-5x4", 256, 256, 379},
		[34] = {"Interface\\ContainerFrame\\UI-Bag-5x4", 256, 256, 399},
		[36] = {"Interface\\ContainerFrame\\UI-Bag-5x4", 256, 256, 419},
		[38] = {"Interface\\ContainerFrame\\UI-Bag-5x4", 256, 256, 439},
		[40] = {"Interface\\ContainerFrame\\UI-Bag-5x4", 256, 256, 459}
	},
	DefaultFrameList = {
		{"", ACHIEVEMENTS},
		{"AchievementFrame", ACHIEVEMENTS},
		{"AchievementAlertFrame1", "Achievement Alert 1"},
		{"AchievementAlertFrame2", "Achievement Alert 2"},

		{"", QUESTS_LABEL},
		{"WatchFrame", "Tracker"},
		{"QuestLogDetailFrame", "Quest Details"},
		{"QuestLogFrame", "Quest Log"},
		{"QuestFrame", "Quest Offer/Return"},
		{"QuestTimerFrame", "Quest Timer"},

		{"", ACTIONBAR_LABEL},
		{"BasicActionButtonsMover", "Action Bar"},
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
		{"PVPFrame", "PVP Window"},
		{"BattlefieldMinimap", "Battlefield Mini Map"},
		{"MiniMapBattlefieldFrame", "Battleground Minimap Button"},
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
		{"LFDParentFrame", "Dungeon Finder"},
		{"DungeonCompletionAlertFrame1", "Dungeon Completion Alert"},
		{"LFDSearchStatus", "Dungeon Search Status Tooltip"},
		{"LFDDungeonReadyDialog", "Dungeon Ready Dialog"},
		{"LFDDungeonReadyPopup", "Dungeon Ready Popup"},
		{"LFDDungeonReadyStatus", "Dungeon Ready Status"},
		{"LFDRoleCheckPopup", "Dungeon Role Check Popup"},
		{"RaidBossEmoteFrame", "Raid Boss Emote Display"},
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

		{"", GUILD},
		{"GuildFrame", GUILD},
		{"GuildBankFrame", GUILD_BANK},
		{"GuildControlPopupFrame", GUILDCONTROL},
		{"GuildInfoFrame", GUILD_INFORMATION},
		{"GuildInviteFrame", "Guild Invite"},
		{"GuildLogFrame", "Guild Log"},
		{"GuildMemberDetailFrame", "Guild Member Details"},
		{"GuildRegistrarFrame", "Guild Registrar"},

		{"", "Info Panels"},
		{"UIPanelMover1", "Generic Info Panel 1: Left"},
		{"UIPanelMover2", "Generic Info Panel 2: Center"},
		{"UIPanelMover3", "Generic Info Panel 3: Right"},
		{"CharacterFrame", "Character / Reputation / Currency"},
		{"DressUpFrame", "Dressing Room"},
		{"LFDParentFrame", LOOKING_FOR_DUNGEON},
		{"TaxiFrame", "Flight Paths"},
		{"FriendsFrame", "Social - Friends / Who / Guild / Chat / Raid"},
		{"GossipFrame", "Gossip"},
		{"InspectFrame", INSPECT},
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
		{"AuctionDressUpFrame", "Auction House Dressing Room"},
		{"BarberShopFrame", BARBERSHOP},
		{"MirrorTimer1", "Breath/Fatigue Bar"},
		{"CalendarFrame", "Calendar"},
		{"CalendarViewEventFrame", "Calendar Event"},
		{"ChannelPullout", "Channel Pullout"},
		{"ChatConfigFrame", "Chat Channel Configuration"},
		{"ColorPickerFrame", "Color Picker"},
		{"TokenFramePopup", "Currency Options"},
		{"ItemRefTooltip", "Chat Popup Tooltip"},
		{"DurabilityFrame", "Durability Figure"},
		{"UIErrorsFrame", "Errors & Warning Display"},
		{"FramerateLabel", "Framerate"},
		{"GearManagerDialog", "Equipment Manager"},
		{"ItemSocketingFrame", "Gem Socketing"},
		{"HelpFrame", "GM Help"},
		{"LevelUpDisplay", "Level Up Display"},
		{"MacroPopupFrame", "Macro Name & Icon"},
		{"StaticPopup1", "Static Popup 1"},
		{"StaticPopup2", "Static Popup 2"},
		{"StaticPopup3", "Static Popup 3"},
		{"StaticPopup4", "Static Popup 4"},
		{"ItemTextFrame", "Reading Materials"},
		{"ReputationDetailFrame", "Reputation Details"},
		{"TicketStatusFrame", "Ticket Status"},
		{"TooltipMover", "Tooltip"},
		{"BagItemTooltipMover", "Tooltip - Bag Item"},
		{"WorldStateAlwaysUpFrame", "Top Center Status Display"},
		--{"TutorialFrame", "Tutorials"},
		{"TutorialFrameAlertButton", "Tutorials Alert Button"},
		{"VoiceChatTalkers", "Voice Chat Talkers"},
		{"ZoneTextFrame", "Zoning Zone Text"},
		{"SubZoneTextFrame", "Zoning Subzone Text"},

		{"", PLAYER},
		{"PlayerFrame", PLAYER},
		{"PlayerBuffsMover", "Player Buffs"},
		{"ConsolidatedBuffsTooltip", "Player Buffs - Consolidated Buffs Tooltip"},
		{"PlayerDebuffsMover", "Player Debuffs"},
		{"CastingBarFrame", "Casting Bar"},
		{"RuneFrame", "Deathknight Runes"},
		{"EclipseBarFrame", "Druid Eclipse Bar"},
		{"MultiCastActionBarFrame", "Shaman Totem bar"},
		{"TotemFrame", "Shaman Totem Timers"},

		{"", STATUS_TEXT_TARGET},
		{"TargetFrame", STATUS_TEXT_TARGET},
		{"TargetBuffsMover", "Target Buffs"},
		{"ComboFrame", "Target Combo Points Display"},
		{"TargetDebuffsMover", "Target Debuffs"},
		{"TargetFrameSpellBar", "Target Casting Bar"},
		{"TargetFrameToT", "Target of Target"},
		{"TargetFrameToTDebuffsMover", "Target of Target Debuffs"},

		{"", FOCUS},
		{"FocusFrame", FOCUS},
		{"FocusBuffsMover", "Focus Buffs"},
		{"FocusDebuffsMover", "Focus Debuffs"},
		{"FocusFrameSpellBar", "Focus Casting Bar"},
		{"FocusFrameToT", "Target of Focus"},
		{"FocusFrameToTDebuffsMover", "Target of Focus Debuffs"},

		{"", PETS},
		{"PetFrame", PET},
		{"PetDebuffsMover", "Pet Debuffs"},
		{"PartyMemberFrame1PetFrame", "Party Pet 1"},
		{"PartyMemberFrame2PetFrame", "Party Pet 2"},
		{"PartyMemberFrame3PetFrame", "Party Pet 3"},
		{"PartyMemberFrame4PetFrame", "Party Pet 4"},

		{"", PARTY},
		{"PartyMemberFrame1", "Party Member 1"},
		{"PartyMember1DebuffsMover", "Party Member 1 Debuffs"},
		{"PartyMemberFrame2", "Party Member 2"},
		{"PartyMember2DebuffsMover", "Party Member 2 Debuffs"},
		{"PartyMemberFrame3", "Party Member 3"},
		{"PartyMember3DebuffsMover", "Party Member 3 Debuffs"},
		{"PartyMemberFrame4", "Party Member 4"},
		{"PartyMember4DebuffsMover", "Party Member 4 Debuffs"},

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
		{"GameMenuButtonMoveAnything", "MoveAnything Game Menu Button"},

		{"", "Custom Frames"}
	},
	----------------------------------------------------------------
	--X: hook replacements

	ContainerFrame_GenerateFrame = function(frame, size, id)
		MovAny:GrabContainerFrame(frame, MovAny:GetBag(id))
	end,
	hCreateFrame = function(frameType, name, parent, inherit, dontHook)
		if name then
			if dontHook == "MADontHook" then
				return
			end
			if MovAny:IsModified(name) then
				if MovAny:HookFrame(name) then
					local f = _G[name]
					if f and MovAny:IsValidObject(f) then
						if not MovAny:IsProtected(f) or not InCombatLockdown() then
							MovAny:ApplyAll(f)
						else
							MovAny.pendingFrames[name] = MovAny:GetFrameOptions(name)
						end
					end
				end
			end
		end
	end,
	hBlizzard_TalentUI = function()
		if PlayerTalentFrame_Toggle and not MovAny.hPlayerTalentFrame_Toggle_Hooked then
			hooksecurefunc("PlayerTalentFrame_Toggle", function()
				MovAny.lDelayedSync["PlayerTalentFrame"] = nil
				if MovAny:IsModified("PlayerTalentFrame") then
					MovAny:SyncFrame("PlayerTalentFrame")
				end
			end)
			MovAny.hPlayerTalentFrame_Toggle_Hooked = true
		end
	end,
	hReputationWatchBar_Update = function()
		if MovAny:IsModified("ReputationWatchBar") then
			MovAny:SyncFrame("ReputationWatchBar")
		end
	end,
	CaptureBar_Create = function(id)
		local f = MovAny.oCaptureBar_Create(id)
		local opts = MovAny:GetFrameOptions("WorldStateCaptureBar1")
		if opts then
			MovAny:ApplyAll(f, opts)
		end
		if not opts or not opts.pos then
			f:ClearAllPoints()
			f:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, -175)
		end
		return f
	end,
	AchievementAlertFrame_OnLoad = function(f)
		f.RegisterForClicks = void
		MovAny.oAchievementAlertFrame_OnLoad(f)
		local opts = MovAny:GetFrameOptions(f:GetName())
		if opts then
			MovAny:ApplyAll(f, opts)
		end
	end,
	AchievementAlertFrame_GetAlertFrame = function()
		local f = MovAny.oAchievementAlertFrame_GetAlertFrame()
		if not f then
			return
		end
		local opts = MovAny:GetFrameOptions(f:GetName())
		if opts then
			MovAny:ApplyAll(f, opts)
		end
		return f
	end
}

BINDING_HEADER_MOVEANYTHING = "MoveAnything"

StaticPopupDialogs["MOVEANYTHING_RESET_PROFILE_CONFIRM"] = {
	text = L.PROFILE_RESET_CONFIRM,
	button1 = TEXT(YES),
	button2 = TEXT(NO),
	OnAccept = function() MovAny:ResetProfile() end,
	timeout = 0,
	exclusive = 0,
	showAlert = 1,
	whileDead = 1,
	hideOnEscape = 1
}

StaticPopupDialogs["MOVEANYTHING_RESET_ALL_CONFIRM"] = {
	text = L.RESET_ALL_CONFIRM,
	button1 = TEXT(YES),
	button2 = TEXT(NO),
	OnAccept = function() MovAny:CompleteReset() end,
	timeout = 0,
	exclusive = 0,
	showAlert = 1,
	whileDead = 1,
	hideOnEscape = 1
}

StaticPopupDialogs["MOVEANYTHING_PROFILE_ADD"] = {
	text = L.PROFILE_ADD_TEXT,
	button1 = TEXT(L.ADD),
	button2 = TEXT(CANCEL),
	OnShow = function(self)
		self.editBox:SetScript("OnEnterPressed", function()
			if MovAny:AddProfile(self.editBox:GetText()) then
				StaticPopup_Hide("MOVEANYTHING_PROFILE_ADD")
			end
		end)
		self.editBox:SetScript("OnEscapePressed", function()
			StaticPopup_Hide("MOVEANYTHING_PROFILE_ADD")
		end)
	end,
	OnAccept = function(self)
		if not MovAny:AddProfile(self.editBox:GetText()) then
			StaticPopup_Show("MOVEANYTHING_PROFILE_ADD")
		end
	end,
	hasEditBox = true,
	timeout = 0,
	exclusive = 0,
	showAlert = 1,
	whileDead = 1,
	hideOnEscape = 1
}

StaticPopupDialogs["MOVEANYTHING_PROFILE_RENAME"] = {
	text = L.PROFILE_RENAME_TEXT,
	button1 = TEXT(L.RENAME),
	button2 = TEXT(CANCEL),
	OnShow = function(self)
		self.pn = MovAny:GetProfileName()
		self.editBox:SetScript("OnEnterPressed", function()
			if self.pn == self.editBox:GetText() or MovAny:RenameProfile(self.pn, self.editBox:GetText()) then
				StaticPopup_Hide("MOVEANYTHING_PROFILE_RENAME")
			end
		end)
		self.editBox:SetScript("OnEscapePressed", function()
			StaticPopup_Hide("MOVEANYTHING_PROFILE_RENAME")
		end)
	end,
	OnAccept = function(self)
		if self.pn ~= self.editBox:GetText() and not MovAny:RenameProfile(self.pn, self.editBox:GetText()) then
			StaticPopup_Show("MOVEANYTHING_PROFILE_RENAME")
		end
	end,
	hasEditBox = true,
	timeout = 0,
	exclusive = 0,
	showAlert = 1,
	whileDead = 1,
	hideOnEscape = 1
}

StaticPopupDialogs["MOVEANYTHING_PROFILE_SAVE_AS"] = {
	text = L.PROFILE_SAVE_AS_TEXT,
	button1 = TEXT(L.SAVE),
	button2 = TEXT(CANCEL),
	OnShow = function(self)
		self.pn = MovAny:GetProfileName()
		self.editBox:SetScript("OnEnterPressed", function()
			if MovAny:CopyProfile(self.pn, self.editBox:GetText()) then
				StaticPopup_Hide("MOVEANYTHING_PROFILE_SAVE_AS")
			end
		end)
		self.editBox:SetScript("OnEscapePressed", function()
			StaticPopup_Hide("MOVEANYTHING_PROFILE_SAVE_AS")
		end)
	end,
	OnAccept = function(self)
		if not MovAny:CopyProfile(self.pn, self.editBox:GetText()) then
			StaticPopup_Show("MOVEANYTHING_PROFILE_SAVE_AS")
		end
	end,
	hasEditBox = true,
	timeout = 0,
	exclusive = 0,
	showAlert = 1,
	whileDead = 1,
	hideOnEscape = 1
}

StaticPopupDialogs["MOVEANYTHING_PROFILE_DELETE"] = {
	text = L.PROFILE_DELETE_TEXT,
	button1 = TEXT(L.DELETE),
	button2 = TEXT(CANCEL),
	OnAccept = function(self) MovAny:DeleteProfile(MovAny:GetProfileName()) end,
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
	MovAny_SetupDatabase()
	MAOptions = _G["MAOptions"]

	if not kMADB.noMMMW and Minimap:GetScript("OnMouseWheel") == nil then
		Minimap:SetScript("OnMouseWheel", function(self, dir)
			if dir < 0 then
				Minimap_ZoomOut()
			else
				Minimap_ZoomIn()
			end
		end)
		Minimap:EnableMouseWheel(true)
	end

	local kMADB_Defaults = {frameListRows = 18}

	for i, v in pairs(kMADB_Defaults) do
		if kMADB[i] ~= nil then
		else
			kMADB[i] = v
		end
	end

	if tlen(kMADB.profiles) == 0 then
		kMADB.autoShowNext = true
	end

	self:VerifyData()

	kMADB.collapsed = true

	if kMADB.squareMM then
		MinimapBorder:SetTexture(nil)
		Minimap:SetMaskTexture("Interface\\AddOns\\KPack\\Modules\\MoveAnything\\MinimapMaskSquare")
	end

	self:SetNumRows(kMADB.frameListRows, false)

	if kMADB.closeGUIOnEscape then
		tinsert(UISpecialFrames, "MAOptions")
	end

	MAOptionsMoveHeader:SetText(L.LIST_HEADING_MOVER)
	MAOptionsHideHeader:SetText(L.LIST_HEADING_HIDE)

	MAOptionsToggleFrameEditors:SetChecked(true)

	self:ParseData()

	if self.lVirtualMovers then
		if type(self.lCreateVMs) == "table" then
			for _, name in pairs(self.lCreateVMs) do
				if not _G[name] then
					self:CreateVM(name)
				end
			end
			self.lCreateVMs = nil
		end
		local vmClosure = function(name)
			return function()
				if not _G[name] then
					MovAny:CreateVM(name)
				end
			end
		end
		for name, data in pairs(self.lVirtualMovers) do
			local vm = _G[name]
			if not vm then
				self.lRunOnceBeforeInteract[name] = vmClosure(name)
			end
			if not data.notMAParent then
				if type(data.count) == "number" then
					for i = 1, data.count, 1 do
						local child = _G[data.prefix .. i]
						if child and not MovAny:IsModified(child:GetName()) then
							child.MAParent = vm or name
						end
					end
				end
				if type(data.children) == "table" then
					for i, v in pairs(data.children) do
						local child = type(v) == "string" and _G[v] or v
						if type(child) == "table" and not MovAny:IsModified(child:GetName()) then
							child.MAParent = name
						end
					end
				end
			end
		end
	end

	if not kMADB.noBags then
		MAOptions:RegisterEvent("BANKFRAME_OPENED")
		MAOptions:RegisterEvent("BANKFRAME_CLOSED")
	end

	if not kMADB.dontHookCreateFrame and CreateFrame then
		hooksecurefunc("CreateFrame", self.hCreateFrame)
	end
	if ContainerFrame_GenerateFrame then
		hooksecurefunc("ContainerFrame_GenerateFrame", self.ContainerFrame_GenerateFrame)
	end
	if ShowUIPanel then
		hooksecurefunc("ShowUIPanel", self.SyncUIPanels)
	end
	if HideUIPanel then
		hooksecurefunc("HideUIPanel", self.SyncUIPanels)
	end
	if GameTooltip_SetDefaultAnchor then
		hooksecurefunc("GameTooltip_SetDefaultAnchor", self.hGameTooltip_SetDefaultAnchor)
	end
	if GameTooltip and GameTooltip.SetBagItem then
		hooksecurefunc(GameTooltip, "SetBagItem", self.hGameTooltip_SetBagItem)
	end
	if updateContainerFrameAnchors then
		hooksecurefunc("updateContainerFrameAnchors", self.hUpdateContainerFrameAnchors)
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
	if IsAddOnLoaded("Blizzard_TalentUI") then
		MovAny.hBlizzard_TalentUI()
	end

	self.inited = true
end

function MovAny:OnPlayerLogout()
	if MAOptions:IsShown() then
		kMADB.autoShowNext = true
	end

	if type(self.movers) == "table" then
		for i, v in ipairs(tcopy(self.movers)) do
			self:StopMoving(v.tagged:GetName())
		end
	end
	if type(kMADB.profiles) == "table" then
		for i, v in pairs(kMADB.profiles) do
			MovAny:CleanProfile(i)
		end
	end
end

function MovAny:CleanProfile(pn)
	local p = kMADB.profiles[pn]
	if type(p) == "table" and type(p.frames) == "table" then
		local f
		for i, v in pairs(p.frames) do
			f = _G[i]
			if f and f.IsUserPlaced and f:IsUserPlaced() and (f:IsMovable() or f:IsResizable()) then
				if f:IsUserPlaced() then
					if not f.MAWasUserPlaced then
						f:SetUserPlaced(nil)
					else
						f.MAWasUserPlaced = nil
					end
				end
				if f:IsMovable() then
					if not f.MAWasMovable then
						f:SetMovable(nil)
					else
						f.MAWasMovable = nil
					end
				end
				if f:IsResizable() then
					if not f.MAWasResizable then
						f:SetResizable(nil)
					else
						f.MAWasResizable = nil
					end
				end
			end
			v.ignoreFramePositionManager = nil
			v.cat = nil
			v.orgScale = nil
			v.orgAlpha = nil
			v.orgPos = nil
			v.MANAGED_FRAME = nil
			v.UIPanelWindows = nil
		end
	end
end

function MovAny:VerifyData()
	if kMADB.CharacterSettings then
		kMADB.profiles = {}
		for i, v in pairs(kMADB.CharacterSettings) do
			if type(v) == "table" then
				kMADB.profiles[i] = {name = i, frames = v}
			end
		end
		kMADB.CharacterSettings = nil

		kMADB.characters = {}
		if kMADB.UseCharacterSettings then
			for i, _ in pairs(kMADB.profiles) do
				kMADB.characters[i] = {profile = i}
			end
		end
	end

	if type(kMADB) ~= "table" then
		kMADB = {}
	end
	if type(kMADB.profiles) ~= "table" then
		kMADB.profiles = {}
	end
	if type(kMADB.characters) ~= "table" then
		kMADB.characters = {}
	end
	if kMADB.profiles["default"] == nil then
		self:AddProfile("default", true, true)
	end
	if kMADB.profiles[self:GetProfileName()] == nil then
		local char = kMADB.characters[self:GetCharacterIndex()]
		if char then
			char.profile = nil
		end
	end

	local fRel
	local remList = {}
	local addList = {}
	local rewriteName

	for pi, profile in pairs(kMADB.profiles) do
		table.wipe(remList)
		table.wipe(addList)
		if type(profile.frames) ~= "table" then
			profile.frames = {}
		end
		for fn, opt in pairs(profile.frames) do
			if type(fn) ~= "string" or type(opt) ~= "table" or self.lDeleteFrameNames[fn] then
				tinsert(remList, fn)
			else
				rewriteName = nil
				if self.lFrameNameRewrites[fn] then
					rewriteName = fn
					fn = self.lFrameNameRewrites[fn]
				end
				opt.cat = nil

				if opt.name ~= fn then
					opt.name = fn
				end

				opt.originalLeft = nil
				opt.originalBottom = nil

				opt.originalWidth = nil
				opt.orgWidth = nil

				opt.originalHeight = nil
				opt.orgHeight = nil

				opt.orgPos = nil

				opt.originalScale = nil
				opt.orgScale = nil

				opt.originalAlpha = nil
				opt.origAlpha = nil

				opt.MANAGED_FRAME = nil
				opt.UIPanelWindows = nil

				if type(opt.scale) == "number" then
					if opt.scale > 0.991 and opt.scale < 1.009 then
						opt.scale = 1
					end
				else
					opt.scale = nil
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

				if type(opt.pos) == "table" then
					local relTo = opt.pos[2]
					if type(relTo) == "table" and relTo.GetName and relTo:GetName() then
						opt.pos[2] = relTo:GetName()
					end
				end

				if rewriteName then
					if not self:IsModified(fn, nil, opt) then
						tinsert(remList, rewriteName)
					else
						tinsert(remList, rewriteName)
						addList[fn] = opt
					end
				elseif not self:IsModified(fn, nil, opt) then
					tinsert(remList, fn)
				end
			end
		end
		for i, v in ipairs(remList) do
			kMADB.profiles[pi].frames[v] = nil
		end
		for i, opt in pairs(addList) do
			kMADB.profiles[pi].frames[i] = opt
		end
	end

	self.lFrameNameRewrites = nil
	self.lDeleteFrameNames = nil
end

function MovAny:ParseData()
	if self.DefaultFrameList then
		local sepLast, sep

		if kMADB.noList then
			for i, v in pairs(self.DefaultFrameList) do
				if v[1] then
					if v[1] == "" then
						sep = {}
						sep.name = nil
						sep.helpfulName = v[2]
						sep.sep = true
						sep.collapsed = kMADB.collapsed
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
						sep.collapsed = kMADB.collapsed
						tinsert(self.frames, sep)
						tinsert(self.cats, sep)
						self.framesCount = self.framesCount + 1
						sepLast = sep
					else
						self:AddFrameToMovableList(v[1], v[2], 2, sepLast)
						if not self.defFrames[v[1]] then
							self:AddCustomFrameIfNew(v[1])
						end
					end
				end
			end
		end

		self.DefaultFrameList = nil
		self.customCat = sepLast
	end
	self.frameOptions = kMADB.profiles[self:GetProfileName()].frames
	for i, v in pairs(self.frameOptions) do
		if not self:GetFrame(v.name) then
			self:AddFrameToMovableList(v.name, v.helpfulName, 1)
		end
	end
end

function MovAny:VerifyFrameData(fn)
	local opt = self:GetFrameOptions(fn)
	if opt and (not opt.hidden and opt.pos == nil and opt.scale == nil and opt.width == nil and opt.height == nil and opt.alpha == nil) then
		MovAny.frameOptions[fn] = nil
	end
end

function MovAny:AddCustomFrameIfNew(name)
	if not self:GetFrame(name) then
		self:AddFrameToMovableList(name, name, 1)
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
		opt = self.frameOptions[fn]
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
			MovAny_Print(string.format(L.FRAME_PROTECTED_DURING_COMBAT, f:GetName()))
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

function MovAny:CanBeScaled(f, mode)
	if f.GetName and self.ScaleWH[f:GetName()] and not mode then
		return true
	end
	if not f or not f.GetScale or self.NoScale[f:GetName()] or f:GetObjectType() == "FontString" then
		return
	end
	return true
end

function MovAny:IsValidObject(f, silent)
	if type(f) == "string" then
		f = _G[f]
	end
	if not f then
		return
	end
	if type(f) ~= "table" then
		if not silent then
			MovAny_Print(string.format(L.UNSUPPORTED_TYPE, type(f)))
		end
		return
	end
	if self.lDisallowedFrames[f:GetName()] then
		if not silent then
			MovAny_Print(string.format(L.UNSUPPORTED_FRAME, f:GetName()))
		end
		return
	end

	local type = f:GetObjectType()
	if not self.lAllowedTypes[type] then
		if not silent then
			MovAny_Print(string.format(L.UNSUPPORTED_TYPE, f:GetObjectType()))
		end
		return
	end

	if MovAny:IsMAFrame(f:GetName()) then
		if MovAny.lAllowedMAFrames[f:GetName()] or string.sub(f:GetName(), 1, 5) == "MA_FE" then
			return true
		end
		return
	end
	return true
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
end

function MovAny:SyncAllFrames(dontReset)
	if not self.rendered then
		dontReset = true
	end
	self.pendingFrames = tcopy(self.frameOptions)
	self:SyncFrames(dontReset)
end

function MovAny:SyncFrames(dontReset)
	if not self.inited or self.syncingFrames or next(self.pendingFrames) == nil then
		return
	end

	self.syncingFrames = true

	local f, parent
	local skippedFrames = {}

	if dontReset then
		for fn, opt in pairs(self.pendingFrames) do
			f = _G[fn]
			if f and not self.NoMove[f:GetName()] then
				self:UnanchorRelatives(f, opt)
			end
		end
	end

	local success, handled
	for fn, opt in pairs(self.pendingFrames) do
		if not self:GetMoverByFrame(fn) then
			handled = nil
			self.curSyncFrame = fn

			success, handled = xpcall(function() MovAny:_IntSyncFrame(fn, opt, dontReset) end, self.SyncErrorHandler, self, fn, opt)
			if success == false then
				handled = true
			end
			self.curSyncFrame = nil
			if not handled then
				skippedFrames[fn] = opt
			end
		end
	end
	self.pendingFrames = skippedFrames

	local postponed = {}
	for k, func in pairs(self.pendingActions) do
		if func() then
			tinsert(postponed, func)
		end
	end
	self.pendingActions = postponed

	self:SyncUIPanels()

	self.rendered = true
	self.syncingFrames = nil

	if kMADB.autoShowNext then
		MAOptions:Show()
	end
end

function MovAny:_IntSyncFrame(fn, opt, dontReset)
	local handled = nil
	if self.lRunOnceBeforeInteract[fn] then
		if not self.lRunOnceBeforeInteract[fn]() then
			self.lRunOnceBeforeInteract[fn] = nil
		end
	end
	if not opt.disabled and not self.lDelayedSync[fn] then
		if not self.lRunBeforeInteract[fn] or not self.lRunBeforeInteract[fn]() then
			f = _G[fn]
			if f and self:IsValidObject(f, true) then
				if not self:IsProtected(f) or not InCombatLockdown() then
					if dontReset == nil or not dontReset then
						self:UnhookFrame(f, opt, true, true)
					end
					if self:IsModified(fn) then
						if self:HookFrame(fn, f, nil, true) then
							if not self:ApplyAll(f, opt) then
								handled = true
							end
						end
					end
				end
			end
		end
		if self.lRunAfterInteract[fn] then
			self.lRunAfterInteract[fn](handled)
		end
	end
	return handled
end

function MovAny.SyncErrorHandler(msg, frame, stack, ...)
	local fn = MovAny.curSyncFrame
	if fn then
		stack = stack or debugstack(2, 20, 20)
		if string.find(stack, "\\MoveAnything\\") then
			local funcs = ""
			for m in string.gmatch(stack, "function (%b`')") do
				if m ~= "xpcall" then
					if funcs == "" then
						funcs = m
					else
						funcs = funcs .. ", " .. m
					end
				end
			end
			MovAny_Print("An error occured while updating " .. fn .. ". Try resetting the frame and /reload before modifying it again. If the problem persists please report the following to the author: " .. fn .. " 11.4.5 " .. msg .. " " .. funcs)
		end
		local errorHandler = geterrorhandler()
		if type(errorHandler) == "function" and errorHandler ~= _ERRORMESSAGE then
			errorHandler(msg, frame, stack, ...)
		end
	end
end

function MovAny:SyncFrame(fn, opt, dontReset)
	opt = opt or self:GetFrameOptions(fn)
	if not opt then return end
	if opt.disabled then return end

	local handled = nil

	if self.lRunOnceBeforeInteract[fn] then
		self.lRunOnceBeforeInteract[fn]()
		self.lRunOnceBeforeInteract[fn] = nil
	end

	if not self.lRunBeforeInteract[fn] or not self.lRunBeforeInteract[fn]() then
		f = _G[fn]
		if f and self:IsValidObject(f, true) then
			if not self:IsProtected(f) or not InCombatLockdown() then
				local mover = self:GetMoverByFrame(f)
				if mover then
					MovAny:DetachMover(mover)
				end
				if not dontReset then
					self:UnhookFrame(f, opt, true, true)
				end
				if self:IsModified(fn) and self:HookFrame(fn, f, nil, true) then
					self:ApplyAll(f, opt)
					handled = true
				end
				if mover then
					self:AttachMover(fn)
				end
			else
				self.pendingFrames[fn] = opt
			end
		end
	end
	if self.lRunAfterInteract[fn] then
		self.lRunAfterInteract[fn](handled)
	end
	if not handled then
		self.pendingFrames[fn] = opt
	end
end

function MovAny:IsProtected(f)
	return f:IsProtected() or f.MAProtected
end

function MovAny:GetCharacterIndex()
	return GetCVar("realmName") .. " " .. UnitName("player")
end

function MovAny:GetProfileName(override)
	local char = kMADB.characters[MovAny:GetCharacterIndex()]
	if char and char.profile then
		return char.profile
	else
		return "default"
	end
end

function MovAny:CopyProfile(fromName, toName)
	if fromName == toName then
		return
	end
	if kMADB.profiles[toName] == nil then
		self:AddProfile(toName, true)
	end
	local l, vm
	for i, val in pairs(kMADB.profiles[fromName].frames) do
		l = tcopy(val)
		l.cat = nil
		data = self.lVirtualMovers[i]
		if data and data.excludes then
			kMADB.profiles[toName].frames[data.excludes] = nil
		end
		kMADB.profiles[toName].frames[i] = l
	end
	return true
end

function MovAny:AddProfile(pn, silent, dontUpdate)
	if kMADB.profiles[pn] then
		if not silent then
			MovAny_Print(string.format(L.PROFILE_ALREADY_EXISTS, pn))
		end
		return
	end
	kMADB.profiles[pn] = {name = pn, frames = {}}

	return true
end

function MovAny:DeleteProfile(pn)
	if pn == "default" then
		MovAny_Print(string.format(L.PROFILE_CANT_DELETE, pn))
		return
	end
	if self:GetProfileName() == pn then
		self:ResetProfile()
	end

	kMADB.profiles[pn] = nil
	for name, char in pairs(kMADB.characters) do
		if char and char.profile == pn then
			char.profile = nil
		end
	end
	if true then
		self.frameOptions = kMADB.profiles[self:GetProfileName()].frames
		self:SyncAllFrames(true)
		self:UpdateGUIIfShown(true)
	end
	return true
end

function MovAny:RenameProfile(pn, nn)
	if pn == nn or nn == "default" or nn == "" then
		return
	end
	local p = kMADB.profiles[pn]
	if type(p) ~= "table" then
		return
	end
	p.name = nn
	kMADB.profiles[nn] = p
	kMADB.profiles[pn] = nil
	for i, v in pairs(kMADB.characters) do
		if v.profile == pn then
			v.profile = nn
		end
	end
	return true
end

function MovAny:UpdateProfile()
	if self.frameOptions then
		self:ResetProfile(true)
	end
	self.frameOptions = kMADB.profiles[self:GetProfileName()].frames
	self:SyncAllFrames(true)
	self:UpdateGUIIfShown(true)
end

function MovAny:ChangeProfile(profile)
	MovAny:ResetProfile(true)
	local char = kMADB.characters[MovAny:GetCharacterIndex()]
	if not char then
		char = {}
		kMADB.characters[MovAny:GetCharacterIndex()] = char
	end
	char.profile = profile
	MovAny.frameOptions = kMADB.profiles[MovAny:GetProfileName()].frames

	for i, v in pairs(MovAny.frameOptions) do
		if not MovAny:GetFrame(v.name) then
			MovAny:AddFrameToMovableList(v.name, v.helpfulName, 1)
		end
	end

	MovAny:SyncAllFrames(true)
	MovAny:UpdateGUIIfShown(true)
end

function MovAny:GetFrameCount()
	return self.framesCount
end

function MovAny:ClearFrameOptions(fn)
	self.frameOptions[fn] = nil
	self:RemoveIfCustom(fn)
end

function MovAny:GetFrameOptions(fn, noSymLink, create)
	if MovAny.frameOptions == nil then
		return nil
	end

	if not noSymLink and not MovAny.frameOptions[fn] and MovAny.lTranslateSec[fn] then
		fn = MovAny.lTranslateSec[fn]
	end

	if create and MovAny.frameOptions[fn] == nil then
		MovAny.frameOptions[fn] = {name = fn, cat = MovAny.customCat}
	end
	return MovAny.frameOptions[fn]
end

function MovAny:GetFrame(fn)
	for i, v in pairs(self.frames) do
		if v.name == fn then
			return v
		end
	end
end

function MovAny:GetFrameIDX(o)
	for i, v in pairs(self.frames) do
		if v == o then
			return i
		end
	end
end

function MovAny:RemoveIfCustom(fn)
	for i, v in pairs(self.frames) do
		if v.name == fn then
			if not v.default then
				table.remove(self.frames, i)
				self.framesCount = self.framesCount - 1
			end
			break
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

function MovAny:LockVisibility(f, dontHide)
	if f.MAHidden then
		return
	end
	f.MAHidden = true

	if not f.MAShowHook then
		hooksecurefunc(f, "Show", MovAny.hShow)
		f.MAShowHook = true
	end

	f.MAWasShown = f:IsShown()
	if not dontHide and f.MAWasShown then
		f:Hide()
	end

	if self.lSimpleHide[f] then
		return
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
end

function MovAny.hSetPoint(f, ...)
	if f.MAPoint then
		local fn = f:GetName()

		if fn and string.match(fn, "^ContainerFrame[1-9][0-9]*$") then
			local bag = MovAny:GetBagInContainerFrame(f)
			if not bag then
				return
			end
			fn = bag:GetName()
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

function MovAny:LockPoint(f, opt)
	if not f.MAPoint then
		if f:GetName() and (MovAny.lForcedLock[f:GetName()] or (opt and opt.forcedLock)) then
			if not f.MASetPoint then
				f.MASetPoint = f.SetPoint
				f.SetPoint = MovAny.fVoid
			end
		else
			if not f.MALockPointHook then
				hooksecurefunc(f, "SetPoint", MovAny.hSetPoint)
				f.MALockPointHook = true
			end
			f.MAPoint = {f:GetPoint(1)}
		end
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

function MovAny.hSetScale(f)
	if f.MAScaled then
		local fn = f:GetName()

		if string.match(fn, "^ContainerFrame[1-9][0-9]*$") then
			local bag = MovAny:GetBagInContainerFrame(f)
			if not bag then
				return
			end
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

function MovAny:HookFrame(fn, f, dontUnanchor, runBeforeInteract)
	if not runBeforeInteract and (self.lRunBeforeInteract[fn] and self.lRunBeforeInteract[fn]()) then
		return
	end
	if not f then
		f = _G[fn]
	end
	if not f then return end
	if not self:IsValidObject(f) then return end

	local opt = self:GetFrameOptions(fn, true, true)
	if opt.name == nil then
		opt.name = fn
	end
	f.opt = opt
	if opt.disabled then return end

	if fn == "FocusFrame" then
		f.orgScale = f:GetScale()
		f.scale = f:GetScale()
	end
	if f.SetMovable and not self.NoMove[fn] then
		if f:IsUserPlaced() then
			f.MAWasUserPlaced = true
		end
		if f:IsMovable() then
			f.MAWasMovable = true
		end
		if f:IsResizable() then
			f.MAWasResizable = true
		end
		f:SetMovable(true)
		f:SetUserPlaced(true)
	end

	if not opt.orgPos then
		MovAny:StoreOrgPoints(f, opt)
	end

	if not f.MAHooked then
		if f.OnMAHook and f:OnMAHook() ~= nil then
			return
		end
		f.MAHooked = true
	end

	if not dontUnanchor and not self.NoUnanchorRelatives[fn] and not self.NoMove[fn] then
		self:UnanchorRelatives(f, opt)
	end

	if self.DetachFromParent[fn] and not self.NoReparent[fn] and not f.MAOrgParent then
		f.MAOrgParent = f:GetParent()
		f:SetParent(_G[self.DetachFromParent[fn]])
	end

	if f.OnMAPostHook and f.OnMAPostHook(f) ~= nil then
		return
	end

	return opt
end

function MovAny:UnhookFrame(f, opt, readOnly, dontResetHide)
	if f and f.MAHooked and f.SetUserPlaced and f:IsUserPlaced() and (f:IsMovable() or f:IsResizable()) then
		if f:IsUserPlaced() then
			if f.MAWasUserPlaced then
				f.MAWasUserPlaced = nil
			else
				f:SetUserPlaced(nil)
			end
		end
		if f:IsMovable() then
			if f.MAWasMovable then
				f.MAWasMovable = nil
			else
				f:SetMovable(nil)
			end
		end
		if f:IsResizable() then
			if f.MAWasResizable then
				f.MAWasResizable = nil
			else
				f:SetResizable(nil)
			end
		end
	end
	f.MAHooked = nil
	self:ResetAll(f, opt, readOnly, dontResetHide)
end

function MovAny:IsModified(fn, var, opt)
	if fn == nil then
		return
	end
	if type(fn) == "table" then
		fn = fn:GetName()
	end
	opt = opt or self:GetFrameOptions(fn)
	if opt then
		if var then
			if opt[var] then
				return true
			end
		elseif
			opt.pos or opt.hidden or opt.scale ~= nil or opt.alpha ~= nil or opt.frameStrata ~= nil or
				opt.disableLayerArtwork ~= nil or
				opt.disableLayerBackground ~= nil or
				opt.disableLayerBorder ~= nil or
				opt.disableLayerHighlight ~= nil or
				opt.disableLayerOverlay ~= nil or
				opt.unregisterAllEvents ~= nil or
				opt.groups ~= nil or
				opt.forcedLock ~= nil
		 then
			return true
		end
	end
	return false
end

function MovAny:IsFrameHidden(fn, opt)
	if fn == nil then
		return
	end
	opt = opt or self:GetFrameOptions(fn)
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
					if f.MASetPoint then
						f:MASetPoint(unpack(v))
					else
						f:SetPoint(unpack(v))
					end
				end
			else
				if f.MASetPoint then
					f:MASetPoint(unpack(opt.orgPos))
				else
					f:SetPoint(unpack(opt.orgPos))
				end
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

function MovAny:AddFrameToMovableList(fn, helpfulName, default, cat)
	if not self:GetFrame(fn) then
		if helpfulName == nil then
			helpfulName = fn
		end

		local opts = {}
		opts.name = fn
		opts.helpfulName = helpfulName

		opts.idx = self.nextFrameIdx
		self.nextFrameIdx = self.nextFrameIdx + 1

		tinsert(self.frames, opts)
		self.framesCount = self.framesCount + 1

		if default == 2 then
			opts.default = true
			self.defFrames[opts.name] = opts
			opts.cat = cat
		else
			opts.cat = self.customCat
		end
		self.guiLines = -1
		if self.inited then
			self:UpdateGUIIfShown()
		end
	end
end

function MovAny:AttachMover(fn, helpfulName)
	if self.NoMove[fn] and self.NoScale[fn] and self.NoHide[fn] and self.NoAlpha[fn] then
		string.format(L.UNSUPPORTED_FRAME, fn)
		return
	end

	if self.NoMove[fn] and self.NoScale[fn] and self.NoAlpha[fn] then
		MovAny_Print(string.format(L.FRAME_VISIBILITY_ONLY, fn))
		return
	end

	local f = _G[fn]

	if self.MoveOnlyWhenVisible[fn] and (f == nil or not f:IsShown()) then
		MovAny_Print(string.format(L.ONLY_WHEN_VISIBLE, fn))
		return
	end

	if self.lDelayedSync[fn] then
		MovAny_Print(string.format(self.lDelayedSync[fn], fn))
		return
	end

	if self:ErrorNotInCombat(f) then
		return
	end

	if not self:GetMoverByFrame(f) then
		if self.lRunOnceBeforeInteract[fn] then
			self.lRunOnceBeforeInteract[fn]()
			self.lRunOnceBeforeInteract[fn] = nil
		end
		if self.lRunBeforeInteract[fn] and self.lRunBeforeInteract[fn]() then
			return
		end
		local created = nil
		local handled = nil

		if self.lCreateBeforeInteract[fn] and _G[fn] == nil then
			f = CreateFrame("Frame", fn, UIParent, self.lCreateBeforeInteract[fn])
			created = true
		else
			f = _G[fn]
		end

		if f and fn ~= f:GetName() then
			fn = f:GetName()
			f = _G[fn]
		end
		self.lastFrameName = fn
		if self:IsValidObject(f) then
			local mover = self:GetAvailableMover()
			if f.OnMAAttach then
				f.OnMAAttach(f, mover)
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

		if self.lRunAfterInteract[fn] then
			self.lRunAfterInteract[fn](handled)
		end
		return true
	end
end

function MovAny:GetAvailableMover()
	local f
	for id = 1, 1000000, 1 do
		f = _G[self.moverPrefix .. id]
		if not f then
			f = CreateFrame("Frame", self.moverPrefix .. id, UIParent, "MAMoverTemplate")
			f:SetID(id)
			break
		end
		if not f.tagged then
			break
		end
	end

	if f then
		tinsert(self.movers, f)
		return f
	end
end

function MovAny:GetDefaultFrameParent(f)
	local c = f
	while c and c ~= UIParent and c ~= nil do
		local maParent = c.MAParent
		if maParent then
			if type(maParent) == "string" then
				maParent = self:CreateVM(maParent)
			end
			return maParent
		end
		if c.GetName and c:GetName() ~= nil and c:GetName() ~= "" then
			local m = string.match(c:GetName(), "^ContainerFrame[1-9][0-9]*$")
			if m then
				local bag = self:GetBagInContainerFrame(_G[m])
				if bag then
					return _G[bag:GetName()]
				end
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
				MovAny_Print(L.NO_NAMED_FRAMES_FOUND)
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
	if self:GetMoverByFrame(fn) then
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
	f = _G[fn]
	if f and fn ~= f:GetName() then
		fn = f:GetName()
	end
	if self:IsFrameHidden(fn) then
		ret = self:ShowFrame(fn)
	else
		ret = self:HideFrame(fn)
	end
	self.lastFrameName = fn
	self:UpdateGUIIfShown(true)
	return ret
end

--X: bindings
function MovAny:SafeMoveFrameAtCursor()
	local obj = GetMouseFocus()
	if obj then
		while 1 == 1 and obj do
			if self:IsMAFrame(obj:GetName()) then
				if self:IsMover(obj:GetName()) then
					if obj.tagged then
						obj = obj.tagged
					else
						return
					end
				elseif not self:IsValidObject(obj, true) then
					obj = obj:GetParent()
					if not obj or obj == UIParent then
						return
					end
				else
					break
				end
			else
				break
			end
		end
		local transName = self:Translate(obj:GetName(), 1)

		if transName ~= obj:GetName() then
			self:ToggleMove(transName)
			self:UpdateGUIIfShown(true)
			return
		end

		local p = obj:GetParent()
		-- check for minimap button
		if (p == MinimapBackdrop or p == Minimap or p == MinimapCluster) and obj ~= Minimap then
			self:ToggleMove(obj:GetName())
			self:UpdateGUIIfShown(true)
			return
		end

		local objTest = self:GetDefaultFrameParent(obj)
		if objTest then
			self:ToggleMove(objTest:GetName())
			self:UpdateGUIIfShown(true)
			return
		end

		objTest = self:GetTopFrameParent(obj)
		if objTest then
			self:ToggleMove(objTest:GetName())
			self:UpdateGUIIfShown(true)
			return
		end

		if obj and obj ~= WorldFrame and obj ~= UIParent and obj.GetName then
			self:ToggleMove(obj:GetName())
		end
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
			return
		end
		local objTest = self:GetDefaultFrameParent(obj)
		if objTest then
			self:ToggleHide(objTest:GetName())
			return
		end
		objTest = self:GetTopFrameParent(obj)
		if objTest then
			self:AddFrameToMovableList(objTest:GetName(), nil)
			self:ToggleHide(objTest:GetName())
			return
		end
		if obj and obj ~= WorldFrame and obj ~= UIParent then
			self:AddFrameToMovableList(obj:GetName(), nil)
			self:ToggleHide(obj:GetName())
			return
		end
		return
	end

	self:UpdateGUIIfShown(true)
end

function MovAny:SafeResetFrameAtCursor()
	local obj = GetMouseFocus()
	local fn = obj:GetName()

	if obj then
		if fn and self.frameOptions[fn] then
			self:ResetFrameConfirm(fn)
			return
		end
		if self:IsMAFrame(fn) then
			if self:IsMover(fn) and obj.tagged then
				obj = obj.tagged
				self:ResetFrameConfirm(obj:GetName())
				return
			elseif not self:IsValidObject(obj, true) then
				obj = obj:GetParent()
			end
			fn = obj:GetName()
		end

		local transName = self:Translate(fn, 1)
		if transName ~= fn and self.frameOptions[fn] then
			self:ResetFrameConfirm(fn)
			return
		end
		local objTest = self:GetDefaultFrameParent(obj)
		if objTest and self.frameOptions[objTest:GetName()] then
			self:ResetFrameConfirm(objTest:GetName())
			return
		end
		objTest = self:GetTopFrameParent(obj)
		if objTest and self.frameOptions[objTest:GetName()] then
			self:ResetFrameConfirm(objTest:GetName())
			return
		end
		if obj and obj ~= WorldFrame and obj ~= UIParent and self.frameOptions[fn] then
			self:ResetFrameConfirm(fn)
			return
		end
		return
	end
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

	if self.frameOptions[fn] then
		self:ResetFrameConfirm(fn)
	end
end

function MovAny:MAFEFrameAtCursor()
	local obj = GetMouseFocus()
	if self:IsMAFrame(obj:GetName()) then
		if self:IsMover(obj:GetName()) and obj.tagged then
			obj = obj.tagged
		elseif not self:IsValidObject(obj) then
			return
		end
	end
	if obj and obj ~= WorldFrame and obj ~= UIParent and obj:GetName() then
		self:FrameEditor(obj:GetName())
	end

	self:UpdateGUIIfShown(true)
end

function MovAny:IsMover(fn)
	if fn ~= nil and string.match(fn, "^" .. self.moverPrefix .. "[0-9]+$") ~= nil then
		return true
	end
end

function MovAny:IsMAFrame(fn)
	if fn ~= nil and (string.match(fn, "^MoveAnything") ~= nil or string.match(fn, "^MA") ~= nil) then
		return true
	end
end

function MovAny:IsContainer(fn)
	if type(fn) == "string" and string.match(fn, "^ContainerFrame[1-9][0-9]*$") then
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

function MovAny:ToggleMovers()
	if _G.MAOptionsToggleMovers:GetChecked() then
		local protected = {}
		for i, v in ipairs(self.minimizedMovers) do
			if InCombatLockdown() and self:IsProtected(v) then
				tinsert(protected, v)
			else
				self:AttachMover(v:GetName())
			end
		end
		table.wipe(self.minimizedMovers)
		self.minimizedMovers = protected
	else
		for i, v in ipairs(tcopy(self.movers)) do
			tinsert(self.minimizedMovers, v.tagged)
			self:StopMoving(v.tagged:GetName())
		end
	end
end

function MovAny:GetMoverByFrame(f)
	if not f then
		return
	end
	if type(f) == "string" then
		f = _G[f]
	end
	for i, m in ipairs(self.movers) do
		if type(m) == "table" and m:IsShown() and m.tagged == f then
			return m
		end
	end
	return nil
end

function MovAny:AttachMoverToFrame(mover, f)
	self:UnlockPoint(f)

	local fn = f:GetName()

	local listOptions = self:GetFrame(fn)
	if not listOptions then
		self:DetachMover(mover)
		return
	end
	local opt = self:GetFrameOptions(fn)

	mover.helpfulName = listOptions.helpfulName or fn
	f.MAMover = mover

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
	mover.dontUpdate = nil

	if f.IsClampedToScreen then
		mover:SetClampedToScreen(f:IsClampedToScreen())
	end
	opt.disabled = nil

	mover:ClearAllPoints()
	mover:SetPoint("CENTER", f, "CENTER")

	mover:SetWidth(f:GetWidth() * MAGetScale(f, 1) / UIParent:GetScale())
	mover:SetHeight(f:GetHeight() * MAGetScale(f, 1) / UIParent:GetScale())

	if f.GetFrameLevel then
		mover:SetFrameLevel(f:GetFrameLevel() + 1)
	end

	if not self.NoMove[fn] then
		if not opt.pos then
			opt.pos = self:GetRelativePoint(self:GetFirstOrgPoint(opt), f)
		end
		local p = self:GetRelativePoint({"BOTTOMLEFT", UIParent, "BOTTOMLEFT"}, mover)
		mover:ClearAllPoints()
		mover:SetPoint(unpack(p))

		f:ClearAllPoints()
		if f.MASetPoint then
			f:MASetPoint("BOTTOMLEFT", mover, "BOTTOMLEFT", 0, 0)
		else
			f:SetPoint("BOTTOMLEFT", mover, "BOTTOMLEFT", 0, 0)
		end

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
	mover.detaching = true
	if mover.tagged and not mover.attaching then
		local f = mover.tagged

		self:ApplyPosition(f, self:GetFrameOptions(f:GetName()))

		if mover.createdTagged then
			mover.tagged:Hide()
		end
		if f.OnMADetach then
			f.OnMADetach(f, mover)
		end
	end

	mover:Hide()
	mover.tagged = nil
	mover.attaching = nil
	mover.infoShown = nil

	if mover.tagged then
		mover.tagged.MAMover = nil
	end

	local found

	for i, m in ipairs(self.movers) do
		if m == mover then
			tremove(self.movers, i)
		end
	end

	if self.currentMover == mover then
		self:NudgerChangeMover(1)
	else
		self:NudgerFrameRefresh()
	end

	mover.detaching = nil
end

function MovAny:StopMoving(fn)
	local mover = self:GetMoverByFrame(fn)
	if mover and not self:ErrorNotInCombat(_G[fn]) then
		self:DetachMover(mover)
		self:UpdateGUIIfShown()
	end
end

function MovAny:ResetFrameConfirm(fn)
	local f = _G[fn]
	if InCombatLockdown() and self:IsProtected(f) then
		self:ErrorNotInCombat(f)
		return
	end
	if self.resetConfirm == fn and self.resetConfirmTime + 5 >= time() then
		self.resetConfirm = nil
		MovAny_Print(string.format(L.RESETTING_FRAME, fn))
		self:ResetFrame(fn)
		return true
	else
		self.resetConfirm = fn
		self.resetConfirmTime = time()
		MovAny_Print(string.format(L.RESET_FRAME_CONFIRM, fn))
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
		width = opt.orgWidth
		height = opt.orgHeight
	end

	if f.MAHooked then
		self:UnhookFrame(f, opt, readOnly)
	end

	if width then
		f:SetWidth(width)
	end
	if height then
		f:SetHeight(height)
	end

	if not readOnly then
		self:ClearFrameOptions(fn)
	end

	if f.OnMAPostReset then
		f.OnMAPostReset(f, readOnly)
	end

	f.attachedChildren = nil

	if not dontUpdate then
		self:UpdateGUIIfShown(true)
	end
end

function MovAny:ToggleGUI()
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
	local fn = self.frames[button:GetParent().idx].name
	local f = _G[fn]
	if f then
		if fn ~= f:GetName() then
			fn = f:GetName()
			f = _G[fn]
		end
		if self:ErrorNotInCombat(f) then
			return
		end
	end
	self:ResetFrame(f or fn)
end

function MovAny:HideFrame(f, readOnly)
	local fn
	if type(f) == "string" then
		fn = f
		f = _G[fn]
	end
	if not f then
		if self.lVirtualMovers[fn] then
			f = self:CreateVM(fn)
		else
			return
		end
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
			for i = 2, table.getn(hideEntry) do
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

function MovAny:ShowFrame(f, readOnly, dontHook)
	local fn
	if type(f) == "string" then
		fn = f
		f = _G[f]
	end
	if not f then
		if self.lVirtualMovers[fn] then
			f = self:CreateVM(fn)
		else
			return
		end
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
	if not self:IsValidObject(f) or (not dontHook and not self:HookFrame(fn)) or self:ErrorNotInCombat(f) then
		return
	end
	if opt.unit and f.SetAttribute then
		f:SetAttribute("unit", opt.unit)
	end
	if self.HideList[fn] then
		for hIndex, hideEntry in pairs(self.HideList[fn]) do
			local val = _G[hideEntry[1]]
			local hideType
			for i = 2, table.getn(hideEntry) do
				hideType = hideEntry[i]
				if type(hideType) == "function" then
					hideType(true)
				elseif hideType == "DISABLEMOUSE" then
					val:EnableMouse(true)
				elseif hideType == "FRAME" then
					self:UnlockVisibility(val)
				elseif hideType == "WH" then
					if type(opt.orgWidth) == "number" then
						val:SetWidth(opt.orgWidth)
					end
					if type(opt.orgHeight) == "number" then
						val:SetHeight(opt.orgHeight)
					end
				else
					val:EnableDrawLayer(hideType)
				end
			end
		end
		self:ApplyLayers(f, opt)
	elseif self.HideUsingWH[fn] then
		if type(opt.orgWidth) == "number" then
			f:SetWidth(opt.orgWidth)
		end
		if type(opt.orgHeight) == "number" then
			f:SetHeight(opt.orgHeight)
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

function MovAny:OnCheckToggleCategories(button)
	local state = button:GetChecked()
	if state then
		kMADB.collapsed = true
	else
		kMADB.collapsed = nil
	end
	for i, v in pairs(self.cats) do
		v.collapsed = state
	end

	self:UpdateGUIIfShown(true)
end

function MovAny:OnCheckToggleModifiedFramesOnly(button)
	local state = button:GetChecked()
	if state then
		kMADB.modifiedFramesOnly = true
	else
		kMADB.modifiedFramesOnly = nil
	end

	self:UpdateGUIIfShown(true)
end

function MovAny:MoveGroups(sender, groups, x, y)
	for g in pairs(groups) do
		for fn, opt in pairs(self.frameOptions) do
			if fn ~= sender and type(opt.groups) == "table" and opt.groups[g] and type(opt.pos) == "table" then
				local f = _G[fn]
				if f then
					local mover = self:GetMoverByFrame(f)
					if mover then
						self:DetachMover(mover)
					end

					-- XXX if not opt.pos
					opt.pos[4] = opt.pos[4] + (x / f:GetScale())
					opt.pos[5] = opt.pos[5] + (y / f:GetScale())
					self:ApplyPosition(f, opt)
					if mover then
						self:AttachMover(fn)
					end
				end
			end
		end
	end
end

function MovAny:ScaleGroups(sender, groups, scaleMod, scale, dir)
	for g in pairs(groups) do
		for fn, opt in pairs(self.frameOptions) do
			if fn ~= sender and type(opt.groups) == "table" and opt.groups[g] then
				local f = _G[fn]
				local mover
				if f then
					mover = self:GetMoverByFrame(f)
					if mover then
						self:DetachMover(mover)
					end
				end
				local scaleWH = self.ScaleWH[fn]

				local orgScale = opt.scale or (f and f:GetScale() or 1)

				if not scaleWH then
					if opt.pos then
						opt.pos[4] = opt.pos[4] * orgScale
						opt.pos[5] = opt.pos[5] * orgScale
					end
					opt.scale = orgScale + scaleMod
					if opt.pos then
						opt.pos[4] = opt.pos[4] / opt.scale
						opt.pos[5] = opt.pos[5] / opt.scale
					end
				else
					if f then
						if type(opt.orgWidth) ~= "number" then
							opt.orgWidth = f:GetWidth()
						end
						if type(opt.orgHeight) ~= "number" then
							opt.orgHeight = f:GetHeight()
						end
					end

					if dir == 0 then
						if type(opt.width) ~= "number" then
							opt.width = opt.orgWidth
						end
						if type(opt.width) == "number" then
							opt.width = opt.width * (1 + scaleMod)
						end
					elseif dir == 1 then
						if type(opt.height) ~= "number" then
							opt.height = opt.orgHeight
						end
						if type(opt.height) == "number" then
							opt.height = opt.height * (1 + scaleMod)
						end
					end
				end

				if f then
					self:ApplyScale(f, opt)
					if opt.pos then
						self:ApplyPosition(f, opt)
					end
					if mover then
						self:AttachMover(fn)
					end
				end
			end
		end
	end
end

function MovAny:AlphaGroups(sender, groups, alphaMod, alpha)
	for g in pairs(groups) do
		for fn, opt in pairs(self.frameOptions) do
			if fn ~= sender and type(opt.groups) == "table" and opt.groups[g] then
				local f = _G[fn]
				local mover
				if f then
					mover = self:GetMoverByFrame(f)
					if mover then
						self:DetachMover(mover)
					end
				end
				local fAlpha
				if not opt.alpha then
					fAlpha = f and (f:GetAlpha() + alphaMod) or alpha
				else
					fAlpha = opt.alpha + alphaMod
				end
				if fAlpha < 0 then
					fAlpha = 0
				elseif fAlpha > 1 then
					fAlpha = 1
				end
				opt.alpha = fAlpha
				self:ApplyAlpha(f, opt)
				if mover then
					self:AttachMover(fn)
				end
			end
		end
	end
end

function MovAny:MoverUpdatePosition(mover)
	if mover.attaching or mover.detaching then
		return
	end

	local x, y, parent
	if mover.tagged then
		local f = mover.tagged
		if self.NoMove[f:GetName()] then
			return
		end
		local opt = self:GetFrameOptions(f:GetName())
		if not mover.skipGroups and opt.groups and not IsShiftKeyDown() then
			local _, _, _, mx, my = unpack(self:GetRelativePoint(opt.pos, f, true))
			mx = mx -- * mover:GetScale()
			my = my -- * mover:GetScale()
			local fx = opt.pos[4]
			local fy = opt.pos[5]

			x = mx - fx
			y = my - fy

			if not self.ScaleWH[f:GetName()] then
				x = x * (opt.scale or (f.GetScale and f:GetScale()) or 1)
				y = y * (opt.scale or (f.GetScale and f:GetScale()) or 1)
			end

			MovAny:MoveGroups(f:GetName(), opt.groups, x, y)
		end
		if f:GetName() == "FramerateLabel" then
			opt.pos = self:GetRelativePoint({"BOTTOMLEFT", "UIParent", "BOTTOMLEFT"}, f)
		else
			opt.pos = self:GetRelativePoint(opt.pos or self:GetFirstOrgPoint(opt) or {"BOTTOMLEFT", "UIParent", "BOTTOMLEFT"}, f)
		end
		if f.OnMAPosition then
			f.OnMAPosition(f)
		end

		self:UpdateGUIIfShown()
	end
end

function MovAny:MoverOnSizeChanged(mover)
	if mover.attaching or mover.detaching then
		return
	end
	if mover.tagged then
		local s, w, h, f, opt
		f = mover.tagged
		opt = self:GetFrameOptions(f:GetName())
		if self.ScaleWH[f:GetName()] then
			if opt.width ~= mover:GetWidth() or opt.height ~= mover:GetHeight() then
				if not mover.skipGroups and opt.groups and not IsShiftKeyDown() then
					local dir = mover:GetHeight() ~= opt.height and 1 or 0
					if dir == 0 then
						s = mover:GetWidth() / f:GetWidth()
						s = s / MAGetScale(f:GetParent(), 1) * UIParent:GetScale()
					else
						s = mover:GetHeight() / f:GetHeight()
						s = s / MAGetScale(f:GetParent(), 1) * UIParent:GetScale()
					end

					self:ScaleGroups(f:GetName(), opt.groups, s - 1, s, dir)
				end

				opt.width = mover:GetWidth()
				opt.height = mover:GetHeight()
				self:ApplyScale(f, opt)

				mover.skipGroups = true
				self:MoverUpdatePosition(mover)
				mover.skipGroups = nil
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

			if f.GetScale and s ~= f:GetScale() then
				if not mover.skipGroups and opt.groups and not IsShiftKeyDown() then
					self:ScaleGroups(f:GetName(), opt.groups, s - (opt.scale or f:GetScale()), s)
				end

				opt.scale = s

				self:ApplyScale(f, opt)

				mover.skipGroups = true
				self:MoverUpdatePosition(mover)
				mover.skipGroups = nil
			end
			mover:SetWidth(w)
			mover:SetHeight(h)

			local label = _G[mover:GetName() .. "BackdropInfoLabel"]
			label:SetWidth(w + 100)
			label:SetHeight(h)
		end

		local label = _G[mover:GetName() .. "BackdropInfoLabel"]
		label:ClearAllPoints()
		label:SetPoint("TOP", label:GetParent(), "TOP", 0, 0)

		local brief, long
		if MovAny:CanBeScaled(f) then
			if MovAny.ScaleWH[f:GetName()] then
				brief = "W: " .. numfor(f:GetWidth()) .. " H:" .. numfor(f:GetHeight())
				long = brief
			else
				brief = numfor(f:GetScale())
				long = "Scale: " .. brief
			end
			label:Show()
			label:SetText(brief)
			if mover == self.currentMover then
				_G["MANudgerInfoLabel"]:Show()
				_G["MANudgerInfoLabel"]:SetText(long)
			end
		end

		label = _G[mover:GetName() .. "BackdropMovingFrameName"]
		label:ClearAllPoints()
		label:SetPoint("TOP", label:GetParent(), "TOP", 0, 20)

		self:UpdateGUIIfShown(true)
	end
end

function MovAny:MoverOnMouseWheel(mover, arg1)
	if not mover.tagged or MovAny.NoAlpha[mover.tagged:GetName()] then
		return
	end
	local alpha = mover.tagged:GetAlpha()
	if arg1 > 0 then
		alphaMod = .05
	else
		alphaMod = -.05
	end
	alpha = alpha + alphaMod
	if alpha < 0 then
		alpha = 0
		mover.tagged.alphaAttempts = nil
	elseif alpha > 0.99 then
		alpha = 1
		mover.tagged.alphaAttempts = nil
	elseif alpha > 0.92 then
		if not mover.tagged.alphaAttempts then
			mover.tagged.alphaAttempts = 1
		elseif mover.tagged.alphaAttempts > 2 then
			alpha = 1
			mover.tagged.alphaAttempts = nil
		else
			mover.tagged.alphaAttempts = mover.tagged.alphaAttempts + 1
		end
	else
		mover.tagged.alphaAttempts = nil
	end

	alpha = tonumber(numfor(alpha))

	local opt = self:GetFrameOptions(mover.tagged:GetName())

	if not mover.skipGroups and opt.groups and not IsShiftKeyDown() then
		self:AlphaGroups(f:GetName(), opt.groups, alphaMod, alpha)
	end

	opt.alpha = alpha
	self:ApplyAlpha(mover.tagged, opt)

	if opt.alpha == opt.orgAlpha then
		opt.alpha = nil
		opt.orgAlpha = nil
	end

	local label = _G[mover:GetName() .. "BackdropInfoLabel"]
	label:Show()
	label:SetText(numfor(alpha * 100) .. "%")
	if mover == self.currentMover then
		_G["MANudgerInfoLabel"]:Show()
		_G["MANudgerInfoLabel"]:SetText("Alpha:" .. numfor(alpha * 100) .. "%")
	end

	self:UpdateGUIIfShown(true)
end

function MovAny:ResetProfile(readOnly)
	for i, v in pairs(self.frameOptions) do
		self:ResetFrame(v.name, true, true)
	end
	self:ReanchorRelatives()
	if not readOnly then
		self.frameOptions = {}
		kMADB.profiles[self:GetProfileName()].frames = self.frameOptions
	end
	self:UpdateGUIIfShown(true)
end

function MovAny:CompleteReset()
	for i, v in pairs(self.frameOptions) do
		self:ResetFrame(v.name, true, true)
	end
	self:ReanchorRelatives()

	if kMADB.squareMM then
		MinimapBorder:SetTexture("Interface\\Minimap\\UI-Minimap-Border")
		Minimap:SetMaskTexture("Textures\\MinimapMask")
	end

	kMADB = {
		collapsed = true,
		frameListRows = 18,
		tooltips = true
	}
	kMADB.profiles = {}
	kMADB.characters = {}
	self.frameOptions = {}

	local name = self:GetProfileName()
	if kMADB.profiles[name] then
		kMADB.profiles[name].frames = self.frameOptions
	end

	MAOptionsToggleCategories:SetChecked(true)
	MovAny:OnCheckToggleCategories(MAOptionsToggleCategories)

	self:UpdateGUIIfShown(true)
end

function MovAny:OnShow()
	if kMADB.playSound then
		PlaySound("igMainMenuOpen")
	end

	kMADB.autoShowNext = true

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
	if kMADB.playSound then
		PlaySound("igMainMenuClose")
	end

	kMADB.autoShowNext = nil

	if not self.currentMover then
		MANudger:Hide()
	end

	for i, v in pairs(self.lEnableMouse) do
		if v and v.EnableMouse and (not MovAny:IsProtected(v) or not InCombatLockdown()) then
			v:EnableMouse(nil)
		end
	end

	CloseDropDownMenus()
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
	else
		if self.FrameEditor then
			self:FrameEditor(o.name)
		end
	end
end

function MovAny:CountGUIItems()
	local items = 0
	local nextSepItems = 0
	local curSep = nil

	if self.searchWord and self.searchWord ~= "" then
		for i, o in pairs(MovAny.frames) do
			if not o.sep and o.cat then
				if
					(not kMADB.dontSearchFrameNames and string.match(string.lower(o.name), self.searchWord)) or
						(o.helpfulName and string.match(string.lower(o.helpfulName), self.searchWord))
				 then
					if kMADB.modifiedFramesOnly then
						if MovAny:IsModified(o.name) then
							items = items + 1
						end
					else
						items = items + 1
					end
				end
			end
		end
	else
		for i, o in pairs(MovAny.frames) do
			if o.sep then
				if curSep then
					curSep.items = nextSepItems
					nextSepItems = 0
				end
				curSep = o
			else
				if kMADB.modifiedFramesOnly then
					if MovAny:IsModified(o.name) then
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
				if not kMADB.modifiedFramesOnly then
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
	end
	self.guiLines = items
end

function MovAny:UpdateGUI(recount)
	if recount or MovAny.guiLines == -1 then
		MovAny:CountGUIItems()
	end

	FauxScrollFrame_Update(MAScrollFrame, MovAny.guiLines, kMADB.frameListRows, MovAny.SCROLL_HEIGHT)
	local topOffset = FauxScrollFrame_GetOffset(MAScrollFrame)

	local displayList = {}

	if MovAny.searchWord and MovAny.searchWord ~= "" then
		local results = {}
		local skip = topOffset
		for i, o in pairs(MovAny.frames) do
			if not o.sep then
				if
					(not kMADB.dontSearchFrameNames and string.match(string.lower(o.name), MovAny.searchWord)) or
						(o.helpfulName and string.match(string.lower(o.helpfulName), MovAny.searchWord))
				 then
					if kMADB.modifiedFramesOnly then
						if MovAny:IsModified(o.name) then
							tinsert(results, o)
						end
					else
						tinsert(results, o)
					end
				end
			end
		end
		table.sort(results, function(o1, o2) return o1.helpfulName:lower() < o2.helpfulName:lower() end)
		for i, o in pairs(results) do
			if skip > 0 then
				skip = skip - 1
			else
				tinsert(displayList, o)
			end
		end
		results = nil
	else
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
				if kMADB.modifiedFramesOnly then
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
				elseif kMADB.modifiedFramesOnly then
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

		local sepOffset, wtfOffset
		sepOffset = 0
		wtfOffset = 0
		local skip = topOffset

		for i = 1, kMADB.frameListRows, 1 do
			local index = i + sepOffset + wtfOffset

			local o
			-- forward to next shown element
			while 1 do
				if index > MovAny.framesCount then
					o = nil
					break
				end
				o = MovAny.frames[index]
				if o.sep then
					if kMADB.modifiedFramesOnly then
						if o.items > 0 then
							if skip > 0 then
								index = index + 1
								wtfOffset = wtfOffset + 1
								skip = skip - 1
							else
								if o.sep and o.collapsed then
									sepOffset = sepOffset + o.items
								end
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
							if o.sep and o.collapsed then
								sepOffset = sepOffset + o.items
							end
							break
						end
					end
				elseif o.cat then
					local c = o.cat
					if c.collapsed then
						index = index + 1
						wtfOffset = wtfOffset + 1
					else
						if kMADB.modifiedFramesOnly then
							if MovAny:IsModified(o.name) then
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
			if o then
				tinsert(displayList, o)
			else
				break
			end
		end
	end

	local prefix, move, hide, backdrop = "MAMove", "Move", "Hide"
	local skip = topOffset

	for i = 1, kMADB.frameListRows, 1 do
		local o = displayList[i]
		local row = _G[prefix .. i]

		if not o then
			row:Hide()
		else
			local fn = o.name
			local opts = MovAny:GetFrameOptions(fn)
			local moveCheck = _G[prefix .. i .. move]
			local hideCheck = _G[prefix .. i .. hide]
			local text, frameNameLabel
			local idx = MovAny:GetFrameIDX(o)

			frameNameLabel = _G[prefix .. i .. "FrameName"]
			frameNameLabel.idx = idx
			row.idx = idx
			row.name = o.name
			row:Show()

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
				frameNameLabel.tooltipLines = nil
			else
				text = _G[prefix .. i .. "FrameNameHighlight"]
				text:Hide()
				text = _G[prefix .. i .. "FrameNameText"]
				text:Show()
				text:SetText((opts and opts.disabled and "*" or "") .. o.helpfulName)
			end

			if fn then
				_G[prefix .. i .. "Backdrop"]:Show()

				if MovAny.NoMove[fn] and MovAny.NoScale[fn] and MovAny.NoAlpha[fn] then
					moveCheck:Hide()
				else
					moveCheck:SetChecked(MovAny:GetMoverByFrame(fn) and 1 or nil)
					moveCheck:Show()
				end
				if MovAny.NoHide[fn] then
					hideCheck:Hide()
				else
					hideCheck:SetChecked(opts and opts.hidden or nil)
					hideCheck:Show()
				end

				if MovAny:IsModified(fn) then
					_G[prefix .. i .. "Reset"]:Show()
				else
					_G[prefix .. i .. "Reset"]:Hide()
				end
			else
				_G[prefix .. i .. "Backdrop"]:Hide()
				moveCheck:Hide()
				hideCheck:Hide()
				_G[prefix .. i .. "Reset"]:Hide()
			end
		end
	end

	MAOptionsToggleCategories:SetChecked(kMADB.collapsed)
	MAOptionsToggleModifiedFramesOnly:SetChecked(kMADB.modifiedFramesOnly)

	if MovAny.searchWord and MovAny.searchWord ~= "" then
		MAOptionsFrameNameHeader:SetText(string.format(L.LIST_HEADING_SEARCH_RESULTS, MovAny.guiLines))
	else
		MAOptionsFrameNameHeader:SetText(L.LIST_HEADING_CATEGORY_AND_FRAMES)
	end
	MovAny:TooltipHide()
end

function MovAny:UpdateGUIIfShown(recount, dontUpdateEditors)
	if recount then
		self.guiLines = -1
	end
	if MAOptions and MAOptions:IsShown() then
		self:UpdateGUI()
	end

	if not dontUpdateEditors then
		for fn, fe in pairs(self.frameEditors) do
			if fe:IsShown() and not fe.updating then
				fe:UpdateEditor()
			end
		end
	end

	if self.portDlg and self.portDlg:IsShown() then
		self.portDlg:Reload()
	end
end

function MovAny:NudgerChangeMover(dir)
	local p
	local first, sel
	local cur = self.currentMover
	local matchNext = false

	for i, m in ipairs(self.movers) do
		if not first then
			first = m
		end
		if matchNext then
			self.currentMover = m
			matchNext = nil
			break
		end
		if m == cur then
			if dir < 0 then
				if first == m then
					for i2, m2 in ipairs(self.movers) do
						sel = m2
					end
					self.currentMover = sel
				else
					self.currentMover = p
				end
				break
			else
				matchNext = true
			end
		end
		p = m
	end
	if matchNext then
		self.currentMover = first
	end

	self:NudgerFrameRefresh()
end

function MovAny:GetFirstMover()
	for i, m in ipairs(self.movers) do
		if m and m.IsShown and m:IsShown() then
			return m
		end
	end
	return nil
end

function MovAny:MoverOnShow(mover)
	local mn = mover:GetName()

	MANudger:Show()
	self.currentMover = mover
	self:NudgerFrameRefresh()

	mover.startAlpha = mover.tagged:GetAlpha()
	_G[mn .. "Backdrop"]:Show()
	_G[mn .. "BackdropMovingFrameName"]:SetText(mover.helpfulName)
	if not mover.tagged or not MovAny:CanBeScaled(mover.tagged) then
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
	if mover == self.currentMover then
		_G["MANudgerInfoLabel"]:SetText("")
	end
end

function MovAny:MoverOnHide()
	local firstMover = self:GetFirstMover()
	if not kMADB.alwaysShowNudger and firstMover == nil then
		MANudger:Hide()
	else
		self.currentMover = firstMover
		self:NudgerFrameRefresh()
	end
end

function MovAny:NudgerOnShow()
	if not kMADB.alwaysShowNudger then
		local firstMover = self:GetFirstMover()
		if firstMover == nil then
			MANudger:Hide()
			return
		end
	end
	self:NudgerFrameRefresh()
end

function MovAny:NudgerFrameRefresh()
	local labelText = ""

	if self.currentMover ~= nil then
		local cur = 0
		for i, m in ipairs(self.movers) do
			cur = cur + 1
			if m == self.currentMover then
				break
			end
		end
		labelText = cur .. " / " .. #self.movers

		local f = self.currentMover.tagged
		if f then
			local fn = f:GetName()
			if fn then
				labelText = labelText .. "\n" .. fn
				MANudger.idx = MovAny:GetFrame(fn).idx
				if self.NoHide[fn] then
					MANudger_Hide:Hide()
				else
					MANudger_Hide:Show()
				end
			end
		end
	end
	local moverCount = #self.movers
	if moverCount > 0 then
		MANudger_CenterH:Show()
		MANudger_CenterV:Show()
		MANudger_NudgeLeft:Show()
		MANudger_NudgeUp:Show()
		MANudger_NudgeDown:Show()
		MANudger_NudgeRight:Show()
		MANudger_CenterMe:Show()
		MANudger_Detach:Show()
		MANudger_Hide:Show()
		MANudgerMouseOver:ClearAllPoints()
		MANudgerMouseOver:SetPoint("BOTTOM", MANudger, "BOTTOM", 0, 6)

		if #self.movers > 1 then
			MANudger_MoverMinus:Show()
			MANudger_MoverPlus:Show()
		else
			MANudger_MoverMinus:Hide()
			MANudger_MoverPlus:Hide()
		end
	else
		MANudger_CenterH:Hide()
		MANudger_CenterV:Hide()
		MANudger_NudgeLeft:Hide()
		MANudger_NudgeUp:Hide()
		MANudger_NudgeDown:Hide()
		MANudger_NudgeRight:Hide()
		MANudger_CenterMe:Hide()
		MANudger_Detach:Hide()
		MANudger_Hide:Hide()
		MANudgerMouseOver:ClearAllPoints()
		MANudgerMouseOver:SetPoint("CENTER", MANudger, "CENTER", 0, 0)

		MANudger_MoverMinus:Hide()
		MANudger_MoverPlus:Hide()
	end
	MANudgerTitle:SetText(labelText)
end

function MovAny:NudgerOnUpdate()
	local obj = GetMouseFocus()
	local text = ""
	local text2 = ""
	local label = MANudgerMouseOver
	local labelSafe = MANudgerMouseOver
	local name

	if obj and obj ~= WorldFrame and obj:GetName() then
		local objTest = self:GetDefaultFrameParent(obj)
		if objTest then
			name = objTest:GetName()
			if name then
				text = text .. "Safe: " .. name
			end
		else
			objTest = self:GetTopFrameParent(obj)
			if objTest then
				name = objTest:GetName()
				if name then
					text = text .. "Safe: " .. objTest:GetName()
				end
			end
		end
	end

	if obj and obj ~= WorldFrame and obj:GetName() then
		name = obj:GetName()
		if name then
			text2 = "Mouseover: " .. text2 .. name
		end
		if obj:GetParent() and obj:GetParent() ~= WorldFrame and obj:GetParent():GetName() then
			name = obj:GetParent():GetName()
			if name then
				text2 = text2 .. "\nParent: " .. name
			end
			if
				obj:GetParent():GetParent() and
				obj:GetParent():GetParent() ~= WorldFrame and
				obj:GetParent():GetParent():GetName()
			then
				name = obj:GetParent():GetParent():GetName()
				if name then
					text2 = text2 .. "\nParent's Parent: " .. name
				end
			end
		end
	end

	if not string.find(text2, "MANudger") then
		label:SetText(text2 .. "\n" .. text)
	else
		label:SetText(text)
	end
end

function MovAny:Center(lock)
	local mover = self.currentMover
	local x, y
	if lock == 0 then
		-- Both
		mover:ClearAllPoints()
		mover:SetPoint("CENTER", 0, 0)
		x = mover:GetLeft()
		y = mover:GetBottom()
		mover:ClearAllPoints()
		mover:SetPoint("BOTTOMLEFT", x, y)
	else
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
	mover.skipGroups = true
	self:MoverUpdatePosition(mover)
	mover.skipGroups = nil
end

function MovAny:Nudge(dir, button)
	local x, y, offsetX, offsetY, parent, mover, offsetAmount
	mover = self.currentMover

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
	self:MoverUpdatePosition(mover)
end

function MovAny:SizingAnchor(button)
	local s, e = string.find(button:GetName(), "Resize_")
	local anchorto = string.sub(button:GetName(), e + 1)
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

function MovAny:SyncUIPanel(mn, f)
	local mover = _G[mn]

	if
		f and
		(f ~= LootFrame or GetCVar("lootUnderMouse") ~= "1") and
		not MovAny:IsModified(f) and
		not MovAny:GetMoverByFrame(f)
	then
		if self:IsModified(mn) then
			local closure = function(f)
				return function()
					if MovAny:IsProtected(f) and InCombatLockdown() then
						return true
					end

					MovAny:UnlockPoint(f)
					f:ClearAllPoints()

					local UIPOpt = UIPanelWindows[f:GetName()]
					local x = 0
					local y = 0
					if not UIPOpt or not UIPOpt.xoffset then
						x = 16
						y = -12
					end
					f:SetPoint("TOPLEFT", mn, "TOPLEFT", x, y)

					f.MAOrgScale = f:GetScale()
					f:SetScale(mover:GetScale())

					f.MAOrgAlpha = f:GetAlpha()
					f:SetAlpha(mover:GetAlpha())
				end
			end
			if MovAny:IsProtected(f) and InCombatLockdown() then
				MovAny.pendingActions[f:GetName() .. ":UIPanel"] = closure(f)
			else
				closure(f)()
			end
		elseif f.MAOrgScale or f.MAOrgAlpha then
			local closure = function(f)
				return function()
					if MovAny:IsProtected(f) and InCombatLockdown() then
						return true
					end
					if f.MAOrgScale then
						f:SetScale(f.MAOrgScale)
						f.MAOrgScale = nil
					end
					if f.MAOrgAlpha then
						f:SetAlpha(f.MAOrgAlpha)
						f.MAOrgAlpha = nil
					end
				end
			end
			if MovAny:IsProtected(f) and InCombatLockdown() then
				MovAny.pendingActions[f:GetName() .. ":UIPanel"] = closure(f)
			else
				closure(f)()
			end
		end
	end
end

function MovAny:SyncUIPanels()
	local this = MovAny

	local f = GetUIPanel("left")
	if f then
		this:SyncUIPanel("UIPanelMover1", f)
		f = GetUIPanel("center")
		if f then
			this:SyncUIPanel("UIPanelMover2", f)
			f = GetUIPanel("right")
			if f then
				this:SyncUIPanel("UIPanelMover3", f)
			end
		end
	else
		f = GetUIPanel("doublewide")
		if f then
			this:SyncUIPanel("UIPanelMover1", f)
			f = GetUIPanel("right")
			if f then
				this:SyncUIPanel("UIPanelMover3", f)
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
	if movableBag and MovAny:IsModified(movableBag) then
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

function MovAny:ApplyAll(f, opt)
	opt = opt or MovAny:GetFrameOptions(f:GetName())
	if opt.disabled then
		return
	end
	MovAny:ApplyScale(f, opt)
	if MovAny:ApplyPosition(f, opt) then
		MovAny:ResetScale(f, opt, true)
		return true
	end
	MovAny:ApplyAlpha(f, opt)
	MovAny:ApplyHide(f, opt)
	MovAny:ApplyLayers(f, opt)
	MovAny:ApplyMisc(f, opt)
end

function MovAny:ResetAll(f, opt, readOnly, dontResetHide)
	opt = opt or MovAny:GetFrameOptions(f:GetName())

	MovAny:ResetScale(f, opt, readOnly)
	MovAny:ResetPosition(f, opt, readOnly)
	MovAny:ResetAlpha(f, opt, readOnly)
	if not dontResetHide then
		MovAny:ResetHide(f, opt, readOnly)
	end
	MovAny:ResetLayers(f, opt, readOnly)
	MovAny:ResetMisc(f, opt, readOnly)
end

function MovAny:UnanchorRelatives(f, opt)
	if f.GetName and f:GetName() ~= nil and (MovAny.NoUnanchorRelatives[f:GetName()]) then
		return
	end
	if not f.GetParent then
		return
	end
	local p = f:GetParent()
	if not p then
		return
	end

	opt = opt or self:GetFrameOptions(f:GetName())

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

	--local fRel = self:ForcedDetachFromParent(f:GetName())
	local fRel = select(2, opt.orgPos)
	if fRel == nil then
		fRel = select(2, f:GetPoint(1))
	end
	local size = tlen(relatives)
	if size > 0 then
		local unanchored = {}
		local x, y, i
		for k, v in pairs(relatives) do
			if
				v:GetName() ~= nil and
				not self:IsContainer(v:GetName()) and
				not string.match(v:GetName(), "BagFrame[1-9][0-9]*") and
				not self.NoUnanchoring[v:GetName()] and
				not v.MAPoint
			then -- alternatively use not self:GetFrameOptions(v:GetName()) instead of v.MAPoint
				if v:GetRight() ~= nil and v:GetTop() ~= nil then
					local pts = {v:GetPoint(1)}
					pts[2] = fRel
					pts = MovAny:GetRelativePoint(pts, v, true)
					if MovAny:IsProtected(v) and InCombatLockdown() then
						MovAny:AddPendingPoint(v, pts)
					else
						v.MAOrgPoint = {v:GetPoint(1)}
						MovAny:UnlockPoint(v)
						v:ClearAllPoints()
						v:SetPoint(unpack(pts))
						MovAny:LockPoint(v)
					end
					unanchored[k] = v
					i = k
				end
			end
		end
		if i ~= nil then
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
	for i, v in pairs(self.frameOptions) do
		f = _G[v.name]
		if f and f.MAUnanchoredRelatives then
			for k, r in pairs(f.MAUnanchoredRelatives) do
				if not MovAny:IsModified(r) then
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
	local closure = function(f, p)
		return function()
			if MovAny:IsProtected(f) and InCombatLockdown() then
				return true
			end
			if not f.MAOrgPoint then
				f.MAOrgPoint = {f:GetPoint(1)}
			end
			MovAny:UnlockPoint(f)
			f:ClearAllPoints()
			if f.MASetPoint then
				f:MASetPoint(unpack(p))
			else
				f:SetPoint(unpack(p))
			end
			MovAny:LockPoint(f)
		end
	end
	MovAny.pendingActions[f .. ":Point"] = closure(f, p)
end

function MovAny:ApplyPosition(f, opt)
	if not opt or self.NoMove[f:GetName()] then
		return
	end
	if opt.pos then
		local relTo = opt.pos[2]
		if not relTo then
			return true
		else
			if not self.lSafeRelatives[relTo] then
				if type(relTo) == "table" and relTo.GetName then
					relTo = relTo:GetName()
				end
				if _G[relTo] then
					self.lSafeRelatives[relTo] = true
				else
					return true
				end
			end
		end

		local fn = f:GetName()
		if opt.orgPos == nil and not self:IsContainer(f:GetName()) and string.match("BagFrame", f:GetName()) ~= nil then
			MovAny:StoreOrgPoints(f, opt)
		end

		if UIPARENT_MANAGED_FRAME_POSITIONS[fn] then
			f.ignoreFramePositionManager = true
		end

		self:UnlockPoint(f)
		f:ClearAllPoints()
		if f.MASetPoint then
			f:MASetPoint(unpack(opt.pos))
		else
			f:SetPoint(unpack(opt.pos))
		end

		self:LockPoint(f, opt)

		if f.OnMAPosition then
			f.OnMAPosition(f)
		end

		if f.attachedChildren then
			for i, v in pairs(f.attachedChildren) do
				if
					not v.ignoreFramePositionManager and
					v.GetName and
					UIPARENT_MANAGED_FRAME_POSITIONS[v:GetName()] and
					not v.ignoreFramePositionManager and
					not MovAny:IsModified(v) and
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
			if
				f ~= MerchantFrame and
				f ~= BankFrame and
				f ~= ClassTrainerFrame and
				(not MovAny:IsProtected(f) or not InCombatLockdown())
			then
				if self.rendered then
					HideUIPanel(f)
				else
					local sfx = GetCVar("Sound_EnableSFX")
					if sfx then
						SetCVar("Sound_EnableSFX", 0)
					end
					if not wasShown then
						ShowUIPanel(f)
					end
					HideUIPanel(f)
					if sfx then
						SetCVar("Sound_EnableSFX", 1)
					end
				end
			end
			local o = self:GetFrameOptions(fn)
			if o then
				o.UIPanelWindows = UIPanelWindows[fn]
			end
			UIPanelWindows[fn] = nil
			f:SetAttribute("UIPanelLayout-enabled", false)
			tinsert(UISpecialFrames, f:GetName())

			if wasShown and f ~= MerchantFrame and f ~= BankFrame and f ~= ClassTrainerFrame and (not MovAny:IsProtected(f) or not InCombatLockdown()) then
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
			if v and not MovAny:IsModified(v) and v.GetName and v.UMFP then
				v.UMFP = nil
				v.ignoreFramePositionManager = nil
				umfp = true
			end
		end
	end

	if opt.UIPanelWindows then
		for i, v in pairs(UISpecialFrames) do
			if v == f:GetName() then
				tremove(UISpecialFrames, i)
				break
			end
		end

		UIPanelWindows[f:GetName()] = opt.UIPanelWindows
		if not readOnly then
			opt.UIPanelWindows = nil
		end
		f:SetAttribute("UIPanelLayout-enabled", true)

		if
			f:IsShown() and
			f ~= MerchantFrame and
			f ~= BankFrame and
			(not MovAny:IsProtected(f) or not InCombatLockdown())
		then
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
		if opt.orgAlpha == nil then
			opt.orgAlpha = f:GetAlpha()
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

	local alpha = opt.orgAlpha
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
	if opt.hidden and not f.MAHidden then
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
		self:ShowFrame(f, readOnly, true)
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
			if opt.width and opt.orgWidth == nil then
				opt.orgWidth = f:GetWidth()
			end
			if opt.height and opt.orgHeight == nil then
				opt.orgHeight = f:GetHeight()
			end
			if self.lHideOnScale[f:GetName()] then
				for i, v in pairs(self.lHideOnScale[f:GetName()]) do
					self:LockVisibility(v)
				end
			end
			if type(opt.width) == "number" and opt.width > 0 then
				f:SetWidth(opt.width)
			end
			if type(opt.height) == "number" and opt.height > 0 then
				f:SetHeight(opt.height)
			end
			self:LockScale(f)
			if self.lLinkedScaling[f:GetName()] then
				for i, v in pairs(self.lLinkedScaling[f:GetName()]) do
					if not self:IsModified(v) then
						self:ApplyScale(_G[v], opt)
					end
				end
			end
			if f.OnMAScale then
				f.OnMAScale(f, opt.width, opt.height)
			end
		end
	elseif opt.scale ~= nil and opt.scale >= 0 then
		if readOnly == nil and not opt.orgScale then
			opt.orgScale = f:GetScale()
		end

		f:SetScale(opt.scale)
		self:LockScale(f)

		if self.lHideOnScale[f:GetName()] then
			for i, v in pairs(self.lHideOnScale[f:GetName()]) do
				self:LockVisibility(v)
			end
		end

		if f.attachedChildren and not f.MADontScaleChildren then
			for i, v in pairs(f.attachedChildren) do
				self:ApplyScale(v, opt)
			end
		end

		if self.lLinkedScaling[f:GetName()] then
			for i, v in pairs(self.lLinkedScaling[f:GetName()]) do
				if not self:IsModified(v) then
					self:ApplyScale(_G[v], opt)
				end
			end
		end
		if f.OnMAScale then
			f.OnMAScale(f, opt.scale)
		end
	end
end

function MovAny:ResetScale(f, opt, readOnly)
	-- XX: should prolly change second condition to self:CanBeScaled(f)
	if not opt or (f.GetName and self.NoScale[f:GetName()]) then
		return
	end

	self:UnlockScale(f)
	if self.ScaleWH[f:GetName()] then
		if (opt.orgWidth and f:GetWidth() ~= opt.orgWidth) or (opt.orgHeight and f:GetHeight() ~= opt.orgHeight) then
			if opt.orgWidth ~= nil and opt.orgWidth > 0 then
				f:SetWidth(opt.orgWidth)
			end
			if opt.orgHeight ~= nil and opt.orgHeight > 0 then
				f:SetHeight(opt.orgHeight)
			end
			if self.lHideOnScale[f:GetName()] then
				for i, v in pairs(self.lHideOnScale[f:GetName()]) do
					self:UnlockVisibility(v)
				end
			end
			if self.lLinkedScaling[f:GetName()] then
				local lf
				for i, v in pairs(self.lLinkedScaling[f:GetName()]) do
					if not self:IsModified(v) then
						lf = _G[v]
						if self:CanBeScaled(lf) then
							if self:IsProtected(lf) and InCombatLockdown() then
								self.pendingFrames[v] = opt
							else
								self:ResetScale(lf, opt, readOnly)
							end
						end
					end
				end
			end
			if f.OnMAScale then
				f.OnMAScale(f, opt.width, opt.height)
			end
		end
		if not readOnly then
			opt.orgWidth = nil
			opt.orgHeight = nil
			opt.width = nil
			opt.height = nil
		end
	elseif self:IsScalableFrame(f) then
		local scale = opt.orgScale or 1
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
		if f.attachedChildren and not f.MADontScaleChildren then
			for i, v in pairs(f.attachedChildren) do
				if not self:IsModified(v) then
					if self:CanBeScaled(v) then
						if self:IsProtected(v) and InCombatLockdown() then
							self.pendingFrames[i] = opt
						else
							self:ResetScale(v, opt, readOnly)
						end
					end
				end
			end
		end
		if self.lLinkedScaling[f:GetName()] then
			for i, v in pairs(self.lLinkedScaling[f:GetName()]) do
				self:ResetScale(_G[v], opt, readOnly)
			end
		end
		if f.OnMAScale then
			f.OnMAScale(f, scale)
		end

		if not readOnly then
			opt.scale = nil
			opt.orgScale = nil
		end
	end
end

function MovAny:ApplyLayers(f, opt, readOnly)
	if not opt then
		return
	end
	if opt.disableLayerArtwork then
		f:DisableDrawLayer("ARTWORK")
	end
	if opt.disableLayerBackground then
		f:DisableDrawLayer("BACKGROUND")
	end
	if opt.disableLayerBorder then
		f:DisableDrawLayer("BORDER")
	end
	if opt.disableLayerHighlight then
		f:DisableDrawLayer("HIGHLIGHT")
	end
	if opt.disableLayerOverlay then
		f:DisableDrawLayer("OVERLAY")
	end
end

function MovAny:ResetLayers(f, opt, readOnly)
	if not opt then
		return
	end
	if not f.EnableDrawLayer then
		if not readOnly then
			opt.disableLayerArtwork = nil
			opt.disableLayerBackground = nil
			opt.disableLayerBorder = nil
			opt.disableLayerHighlight = nil
			opt.disableLayerOverlay = nil
			return
		end
	end
	if opt.disableLayerArtwork then
		f:EnableDrawLayer("ARTWORK")
		if not readOnly then
			opt.disableLayerArtwork = nil
		end
	end
	if opt.disableLayerBackground then
		f:EnableDrawLayer("BACKGROUND")
		if not readOnly then
			opt.disableLayerBackground = nil
		end
	end
	if opt.disableLayerBorder then
		f:EnableDrawLayer("BORDER")
		if not readOnly then
			opt.disableLayerBorder = nil
		end
	end
	if opt.disableLayerHighlight then
		f:EnableDrawLayer("HIGHLIGHT")
		if not readOnly then
			opt.disableLayerHighlight = nil
		end
	end
	if opt.disableLayerOverlay then
		f:EnableDrawLayer("OVERLAY")
		if not readOnly then
			opt.disableLayerOverlay = nil
		end
	end
end

function MovAny:ApplyMisc(f, opt, readOnly)
	if not opt then
		return
	end

	if opt.frameStrata then
		if not opt.orgFrameStrata then
			opt.orgFrameStrata = f:GetFrameStrata()
		end
		f:SetFrameStrata(opt.frameStrata)
	end

	if opt.clampToScreen and f.IsClampedToScreen then
		if not opt.orgClampToScreen then
			opt.orgClampToScreen = f:IsClampedToScreen()
		end
		f:SetClampedToScreen(opt.clampToScreen)
	end

	if opt.enableMouse ~= nil then
		opt.orgEnableMouse = f:IsMouseEnabled()
		f:EnableMouse(opt.enableMouse)
	end

	if opt.movable ~= nil then
		opt.orgMovable = f:IsMovable()
		f:SetMovable(opt.movable)
	end

	if opt.unregisterAllEvents and f.UnregisterAllEvents then
		f:UnregisterAllEvents()
	end
end

function MovAny:ResetMisc(f, opt, readOnly)
	if not opt then
		return
	end
	if opt.orgFrameStrata then
		f:SetFrameStrata(opt.orgFrameStrata)
		if not readOnly then
			opt.frameStrata = nil
			opt.orgFrameStrata = nil
		end
	end

	if opt.orgClampToScreen and f.IsClampedToScreen then
		f:SetClampedToScreen(opt.orgClampToScreen)
		if not readOnly then
			opt.clampToScreen = nil
			opt.orgClampToScreen = nil
		end
	end

	if opt.orgEnableMouse then
		f:EnableMouse(opt.orgEnableMouse)
		if not readOnly then
			opt.orgEnableMouse = nil
			opt.enableMouse = nil
		end
	end

	if opt.orgMovable then
		f:SetMovable(opt.orgMovable)
		if not readOnly then
			opt.orgMovable = nil
			opt.movable = nil
		end
	end

	if not readOnly then
		opt.unregisterAllEvents = nil
	end
end

-- modfied version of blizzards updateContainerFrameAnchors
function MovAny:hUpdateContainerFrameAnchors()
	if kMADB.noBags then
		return
	end
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
		if not bag or (bag and not MovAny:IsModified(bag, "pos") and not MovAny:GetMoverByFrame(bag)) then
			MovAny:UnlockScale(frame)
			frame:SetScale(containerScale)

			MovAny:UnlockPoint(frame)
			frame:ClearAllPoints()
			if lastBag == nil then
				-- First bag
				frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", GetScreenWidth() - xOffset - CONTAINER_WIDTH, yOffset)
			elseif freeScreenHeight < frame:GetHeight() then
				-- Start a new column
				column = column + 1
				freeScreenHeight = screenHeight - yOffset
				frame:SetPoint("BOTTOMLEFT", frame:GetParent(), "BOTTOMLEFT", GetScreenWidth() - xOffset - (column * CONTAINER_WIDTH) - CONTAINER_WIDTH, yOffset)
			else
				-- Anchor to the previous bag
				frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", select(4, lastBag:GetPoint(1)), lastBag:GetTop() + CONTAINER_SPACING)
			end
			freeScreenHeight = freeScreenHeight - frame:GetHeight() - VISIBLE_CONTAINER_SPACING

			lastBag = frame
		end
	end
end

----------------------------------------------------------------
-- X: slash commands

SLASH_MAMOVE1 = "/move"
SlashCmdList["MAMOVE"] = function(msg)
	if msg == nil or string.len(msg) == 0 then
		MovAny:ToggleGUI()
	else
		MovAny:ToggleMove(MovAny:Translate(msg))
	end
end

SLASH_MAUNMOVE1 = "/unmove"
SlashCmdList["MAUNMOVE"] = function(msg)
	if msg then
		if MovAny.frameOptions[msg] then
			MovAny:ResetFrame(msg)
		elseif MovAny.frameOptions[MovAny:Translate(msg)] then
			MovAny:ResetFrame(MovAny:Translate(msg))
		end
	else
		MovAny_Print(L.CMD_SYNTAX_UNMOVE)
	end
end

SLASH_MAHIDE1 = "/hide"
SlashCmdList["MAHIDE"] = function(msg)
	if msg == nil or string.len(msg) == 0 then
		MovAny_Print(L.CMD_SYNTAX_HIDE)
		return
	end
	MovAny:ToggleHide(MovAny:Translate(msg))
end

SLASH_MAIMPORT1 = "/moveimport"
SlashCmdList["MAIMPORT"] = function(msg)
	if msg == nil or string.len(msg) == 0 then
		MovAny_Print(L.CMD_SYNTAX_IMPORT)
		return
	end

	if InCombatLockdown() then
		MovAny_Print(L.DISABLED_DURING_COMBAT)
		return
	end

	if kMADB.profiles[msg] == nil then
		MovAny_Print(string.format(L.PROFILE_UNKNOWN, msg))
		return
	end

	MovAny:CopyProfile(msg, MovAny:GetProfileName())
	MovAny:UpdateProfile()
	MovAny_Print(string.format(L.PROFILE_IMPORTED, msg, MovAny:GetProfileName()))
end

SLASH_MAEXPORT1 = "/moveexport"
SlashCmdList["MAEXPORT"] = function(msg)
	if msg == nil or string.len(msg) == 0 then
		MovAny_Print(L.CMD_SYNTAX_EXPORT)
		return
	end

	MovAny:CopyProfile(MovAny:GetProfileName(), msg)
	MovAny_Print(string.format(L.PROFILE_EXPORTED, MovAny:GetProfileName(), msg))
end

SLASH_MALIST1 = "/movelist"
SlashCmdList["MALIST"] = function(msg)
	MovAny_Print(L.PROFILES .. ":")
	for i, val in pairs(kMADB.profiles) do
		local str = ' "' .. i .. '"'
		if val == MovAny.frameOptions then
			str = str .. " <- " .. L.PROFILE_CURRENT
		end
		MovAny_Print(str)
	end
end

SLASH_MADELETE1 = "/movedelete"
SLASH_MADELETE2 = "/movedel"
SlashCmdList["MADELETE"] = function(msg)
	if msg == nil or string.len(msg) == 0 then
		MovAny_Print(L.CMD_SYNTAX_DELETE)
		return
	end

	if kMADB.profiles[msg] == nil then
		MovAny_Print(string.format(L.PROFILE_UNKNOWN, msg))
		return
	end

	if msg == MovAny:GetProfileName() and InCombatLockdown() then
		MovAny_Print(L.PROFILE_CANT_DELETE_CURRENT_IN_COMBAT)
		return
	end
	if MovAny:DeleteProfile(msg) then
		MovAny_Print(string.format(L.PROFILE_DELETED, msg))
	end
end

SLASH_MAMAFE1 = "/mafe"
SlashCmdList["MAMAFE"] = function(msg)
	if string.len(msg) > 0 then
		MovAny:FrameEditor(MovAny:Translate(msg))
	else
		MovAny_Print(L.CMD_SYNTAX_MAFE)
	end
end

----------------------------------------------------------------
-- X: global functions

function numfor(n, decimals)
	if n == nil then
		return "nil"
	end
	n = string.format("%." .. (decimals or 2) .. "f", n)
	if decimals == nil then
		decimals = 2
	end
	while decimals > 0 do
		if string.sub(n, -1) == "0" then
			n = string.sub(n, 1, -2)
		end
		decimals = decimals - 1
	end
	if string.sub(n, -1) == "." then
		n = string.sub(n, 1, -2)
	end
	return n
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

function MovAny_Print(msgKey, msgHighlight, msgAdditional, r, g, b, frame)
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
function MovAny:ToggleEnableFrame(fn, opt)
	f = _G[fn]
	if f and fn ~= f:GetName() then
		fn = f:GetName()
	end
	opt = opt or MovAny:GetFrameOptions(fn)
	if opt.disabled then
		self:EnableFrame(fn)
	else
		self:DisableFrame(fn)
	end
	MovAny:UpdateGUIIfShown()
end

function MovAny:EnableFrame(fn)
	if fn == nil then return end

	local opt = self:GetFrameOptions(fn)
	if not opt then return end
	opt.disabled = nil

	local f = _G[fn]
	if not f then return end
	if not self:HookFrame(fn, f) then return end

	self:ApplyAll(f, opt)
	if f.MAOnEnable then
		f:MAOnEnable()
	end
end

function MovAny:DisableFrame(fn)
	if fn == nil then return end
	self:StopMoving(fn)

	local opt = self:GetFrameOptions(fn, nil, true)
	if not opt then return end

	local f = _G[fn]
	if not f then return end

	self:ResetFrame(f, nil, true)
	opt.disabled = true
end

function MovAny:UnhookTooltip()
	local tooltip = _G.GameTooltip
	if tooltip.MAMover then
		local opt = MovAny:GetFrameOptions(tooltip.MAMover:GetName())
		if type(opt) == "table" then
			if opt.hidden then
				tooltip.MAHidden = nil
			end
			MovAny:ResetAlpha(tooltip, opt, true)
			MovAny:ResetScale(tooltip, opt, true)
			MovAny:ResetMisc(tooltip, opt, true)
		end
		tooltip.MAMover = nil
	end
end

function MovAny:HookTooltip(mover)
	local l, r, t, b, anchor
	local tooltip = _G.GameTooltip

	self:UnhookTooltip()

	local opt = MovAny:GetFrameOptions(mover:GetName())
	if type(opt) ~= "table" then return end

	tooltip.MAMover = mover

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

	tooltip:ClearAllPoints()
	tooltip:SetPoint(anchor, mover, anchor, 0, 0)

	if opt.hidden then
		self:LockVisibility(tooltip)
	end
	MovAny:ApplyAlpha(tooltip, opt, true)
	MovAny:ApplyScale(tooltip, opt, true)
	MovAny:ApplyMisc(tooltip, opt, true)
end

function MovAny:hGameTooltip_SetDefaultAnchor(relative)
	local tooltip = _G.GameTooltip
	if tooltip.MASkip then
		return
	end
	if MovAny:IsModified("TooltipMover") then
		MovAny:HookTooltip(_G["TooltipMover"])
	elseif MovAny:IsModified("BagItemTooltipMover") then
		MovAny:UnlockPoint(tooltip)
	end
end

function MovAny:hGameTooltip_SetBagItem(container, slot)
	if MovAny:IsModified("BagItemTooltipMover") then
		MovAny:HookTooltip(_G["BagItemTooltipMover"])
	end
end

-- X: MA tooltip funcs
function MovAny:TooltipShow(this)
	if not this.tooltipText then return end
	if
		this.alwaysShowTooltip or
		(kMADB.tooltips and not IsShiftKeyDown() and not this.neverShowTooltip) or
		(not kMADB.tooltips and IsShiftKeyDown()) or
		(this.neverShowTooltip and IsShiftKeyDown())
	then
		GameTooltip:SetOwner(this, "ANCHOR_CURSOR")
		GameTooltip:ClearLines()
		GameTooltip:AddLine(this.tooltipText)
		GameTooltip:Show()
	end
end

function MovAny:TooltipHide()
	GameTooltip:Hide()
end

function MovAny:TooltipShowMultiline(this)
	local tooltipLines = this.tooltipLines
	if tooltipLines == nil then
		tooltipLines = MovAny:GetFrameTooltipLines(MovAny.frames[this.idx].name)
	end
	if tooltipLines == nil or next(tooltipLines) == nil then return end

	if
		this.alwaysShowTooltip or
		(this.neverShowTooltip and IsShiftKeyDown()) or
		(kMADB.tooltips and not IsShiftKeyDown() and not this.neverShowTooltip) or
		(not kMADB.tooltips and IsShiftKeyDown())
	then
		GameTooltip:SetOwner(this, "ANCHOR_CURSOR")
		GameTooltip:ClearLines()
		for i, v in ipairs(tooltipLines) do
			GameTooltip:AddLine(v)
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
			tinsert(msgs, "Original Scale: " .. numfor(opts.orgScale or 1))
			added = true
		end
		if opts.alpha and opts.orgAlpha and opts.alpha ~= opts.orgAlpha then
			if not added then
				tinsert(msgs, " ")
			end
			tinsert(msgs, "Original Alpha: " .. numfor(opts.orgAlpha))
			added = true
		end
	end

	return msgs
end

----------------------------------------------------------------
-- X: debugging code

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
		MovAny_Print(string.format(L.UNSUPPORTED_TYPE, type(o)))
		return
	end
	local s = " Name: " .. o:GetName()

	if o.GetObjectType then
		s = s .. "  Type: " .. o:GetObjectType()
	end

	local p = o:GetParent()
	if p == nil then
		p = UIParent
	end
	if o ~= p then
		s = s .. "  Parent: " .. (p:GetName() or "unnamed")
	end

	if o.MAParent then
		s = s .. " MA Parent: " .. ((type(o.MAParent) == "table" and o.MAParent:GetName()) or (type(o.MAParent) == "string" and o.MAParent) or "unnamed")
	end

	if s ~= "" then
		MovAny_Print(s)
	end
	if o.IsProtected and o:IsProtected() then
		MovAny_Print(" Protected: true")
	elseif o.MAProtected then
		MovAny_Print(" Virtually protected: true")
	end

	s = ""
	if o.IsShown then
		if o:IsShown() then
			s = s .. " Shown: true"
		else
			s = s .. " Shown: false"
		end
		if o.IsVisible then
			if o:IsVisible() then
				s = s .. " Visible: true"
			else
				s = s .. " Visible: false"
			end
		end
	end
	if o.IsTopLevel and o:IsToplevel() then
		s = s .. " Top Level: true"
	end
	if o.GetFrameLevel then
		s = s .. " Level: " .. o:GetFrameLevel()
	end
	if o.GetFrameStrata then
		s = s .. " Strata: " .. o:GetFrameStrata()
	end
	if s ~= "" then
		MovAny_Print(s)
	end

	local point = {o:GetPoint()}
	if point and point[1] and point[2] and point[3] and point[4] and point[5] then
		if not point[2] then
			point[2] = UIParent
		end
		MovAny_Print(" Point: " .. point[1] .. ", " .. point[2]:GetName() .. ", " .. point[3] .. ", " .. point[4] .. ", " .. point[5])
	end

	s = ""
	if o:GetTop() then
		s = " Top: " .. o:GetTop()
	end
	if o:GetRight() then
		s = s .. " Right: " .. o:GetRight()
	end
	if o:GetBottom() then
		s = s .. " Bottom: " .. o:GetBottom()
	end
	if o:GetLeft() then
		s = s .. " Left: " .. o:GetLeft()
	end
	if s ~= "" then
		MovAny_Print(s)
	end
	s = ""
	if o:GetHeight() then
		s = " Height: " .. o:GetHeight()
	end
	if o:GetWidth() then
		s = s .. " Width: " .. o:GetWidth()
	end
	if s ~= "" then
		MovAny_Print(s)
	end
	s = ""
	if o.GetScale then
		s = s .. " Scale: " .. o:GetScale()
	end
	if o.GetEffectiveScale then
		s = s .. " Effective: " .. o:GetEffectiveScale()
	end
	if s ~= "" then
		MovAny_Print(s)
	end
	s = ""
	if o.GetAlpha then
		s = s .. " Alpha: " .. o:GetAlpha()
	end
	if o.GetEffectiveAlpha then
		s = s .. " Effective: " .. o:GetEffectiveAlpha()
	end
	if s ~= "" then
		MovAny_Print(s)
	end
	s = ""
	if o.IsUserPlaced then
		if o:IsUserPlaced() then
			s = s .. " UserPlaced: true"
		else
			s = s .. " UserPlaced: false"
		end
	end
	if o.IsMovable then
		if o:IsMovable() then
			s = s .. " Movable: true"
		else
			s = s .. " Movable: false"
		end
	end
	if o.IsResizable then
		if o:IsResizable() then
			s = s .. " Resizable: true"
		else
			s = s .. " Resizable: false"
		end
	end
	if s ~= "" then
		MovAny_Print(s)
	end
	s = ""
	if o.IsKeyboardEnabled then
		if o:IsKeyboardEnabled() then
			s = s .. " KeyboardEnabled: true"
		else
			s = s .. " KeyboardEnabled: false"
		end
	end
	if o.IsMouseEnabled then
		if o:IsMouseEnabled() then
			s = s .. " MouseEnabled: true"
		else
			s = s .. " MouseEnabled: false"
		end
	end
	if o.IsMouseWheelEnabled then
		if o:IsMouseWheelEnabled() then
			s = s .. " MouseWheelEnabled: true"
		else
			s = s .. " MouseWheelEnabled: false"
		end
	end
	if s ~= "" then
		MovAny_Print(s)
	end

	local opts = self:GetFrameOptions(o:GetName())
	if opts ~= nil then
		MovAny_Print(" MA stored variables:")
		for i, v in pairs(opts) do
			if i ~= "cat" and i ~= "name" then
				if v == nil then
					MovAny_Print("   " .. i .. ": nil")
				elseif v == true then
					MovAny_Print("   " .. i .. ": true")
				elseif v == false then
					MovAny_Print("   " .. i .. ": false")
				elseif type(v) == "number" then
					MovAny_Print("   " .. i .. ": " .. numfor(v))
				elseif type(v) == "table" then
					s = ""
					for j, k in pairs(v) do
						s = s .. " " .. k
					end
					MovAny_Print("   " .. i .. ":" .. s)
				else
					MovAny_Print("   " .. i .. " is a " .. type(v) .. "")
				end
			end
		end
	end
end

SLASH_kMADBG1 = "/madbg"
SlashCmdList["kMADBG"] = function(msg)
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
		MovAny_Print(string.format(L.ELEMENT_NOT_FOUND_NAMED, msg))
	else
		MovAny:Dump(f)
	end
end

function MADebug()
	local ct = 0
	MovAny_Print("Frame options: " .. tlen(MovAny.frameOptions))
	for i, v in pairs(MovAny.frameOptions) do
		ct = ct + 1
		MovAny_Print(ct .. ": " .. v.name)
	end
end

MovAny.dbg = dbg

function MovAny:OptionCheckboxChecked(var)
	kMADB[var] = not kMADB[var]

	if var == "squareMM" then
		if kMADB.squareMM then
			MinimapBorder:SetTexture(nil)
			Minimap:SetMaskTexture("Interface\\AddOns\\KPack\\Modules\\MoveAnything\\MinimapMaskSquare")
		else
			MinimapBorder:SetTexture("Interface\\Minimap\\UI-Minimap-Border")
			Minimap:SetMaskTexture("Textures\\MinimapMask")
		end
	elseif var == "closeGUIOnEscape" then
		if kMADB.closeGUIOnEscape then
			tinsert(UISpecialFrames, "MAOptions")
		else
			for i, v in pairs(UISpecialFrames) do
				if v == "MAOptions" then
					tremove(UISpecialFrames, i)
					break
				end
			end
		end
	elseif var == "noMMMW" then
		if kMADB.noMMMW and Minimap:GetScript("OnMouseWheel") ~= nil then
			Minimap:SetScript("OnMouseWheel", nil)
			Minimap:EnableMouseWheel(false)
		elseif not kMADB.noMMMW and Minimap:GetScript("OnMouseWheel") == nil then
			Minimap:SetScript("OnMouseWheel", function(self, dir)
				if dir < 0 then
					Minimap_ZoomOut()
				else
					Minimap_ZoomIn()
				end
			end)
			Minimap:EnableMouseWheel(true)
		end
	end

	MovAny:UpdateGUIIfShown()
end

function MovAny:SetDefaultOptions()
	if kMADB.squareMM then
		Minimap:SetMaskTexture("Textures\\MinimapMask")
	end

	if kMADB.closeGUIOnEscape then
		for i, v in pairs(UISpecialFrames) do
			if v == "MAOptions" then
				tremove(UISpecialFrames, i)
				break
			end
		end
	end

	kMADB.alwaysShowNudger = nil
	kMADB.noBags = nil
	kMADB.noMMMW = nil
	kMADB.playSound = nil
	kMADB.tooltips = true
	kMADB.closeGUIOnEscape = nil
	kMADB.squareMM = nil
	kMADB.dontHookCreateFrame = nil
	kMADB.dontSearchFrameNames = nil
	kMADB.frameListRows = 18

	MovAny:UpdateGUIIfShown()
end

function MovAny_SetupDatabase()
	if type(KPack.db.MoveAnything) == "table" then
		kMADB = CopyTable(KPack.db.MoveAnything)
		KPack.db.MoveAnything = nil
		KPack:Print("Corrected SavedVariables. Please reload!", "MoveAnything")
	end
end

do
	local menu
	local menuList = {}

	function MovAny:OpenMenu()
		menu = menu or CreateFrame("Frame", "MoveAnythingMenu", UIParent, "UIDropDownMenuTemplate")
		menu.displayMode = "MENU"
		menu.initialize = function(self, level)
			if not level then return end
			local info

			if level == 1 then
				-- profiles
				info = UIDropDownMenu_CreateInfo()
				info.text = "Profiles"
				info.isTitle = 1
				info.notCheckable = 1
				UIDropDownMenu_AddButton(info, level)

				-- profile selection
				info = UIDropDownMenu_CreateInfo()
				info.text = "Select"
				info.value = "profiles"
				info.hasArrow = 1
				info.notCheckable = 1
				UIDropDownMenu_AddButton(info, level)

				-- rename profile
				info = UIDropDownMenu_CreateInfo()
				info.text = "Rename"
				info.func = MovAny.ProfileRenameClicked
				info.notCheckable = 1
				UIDropDownMenu_AddButton(info, level)

				-- save profile
				info = UIDropDownMenu_CreateInfo()
				info.text = SAVE
				info.func = function()
					StaticPopup_Show("MOVEANYTHING_PROFILE_SAVE_AS")
				end
				info.notCheckable = 1
				UIDropDownMenu_AddButton(info, level)

				-- add profile
				info = UIDropDownMenu_CreateInfo()
				info.text = ADD
				info.func = function()
					StaticPopup_Show("MOVEANYTHING_PROFILE_ADD")
				end
				info.notCheckable = 1
				UIDropDownMenu_AddButton(info, level)

				-- delete profile
				info = UIDropDownMenu_CreateInfo()
				info.text = DELETE
				info.func = function()
					StaticPopup_Show("MOVEANYTHING_PROFILE_DELETE", MovAny:GetProfileName())
				end
				info.notCheckable = 1
				UIDropDownMenu_AddButton(info, level)

				-- reset profile
				info = UIDropDownMenu_CreateInfo()
				info.text = RESET
				info.func = function()
					if kMADB.playSound then
						PlaySound("igMainMenuOption")
					end
					StaticPopup_Show("MOVEANYTHING_RESET_PROFILE_CONFIRM")
				end
				info.notCheckable = 1
				UIDropDownMenu_AddButton(info, level)

				-- import / Export
				info = UIDropDownMenu_CreateInfo()
				info.text = "Import/Export"
				info.value = "exporter"
				info.hasArrow = 1
				info.notCheckable = 1
				UIDropDownMenu_AddButton(info, level)

				-- separator
				info = UIDropDownMenu_CreateInfo()
				info.disabled = 1
				UIDropDownMenu_AddButton(info, level)

				-- options
				info = UIDropDownMenu_CreateInfo()
				info.text = "Options"
				info.isTitle = 1
				info.notCheckable = 1
				UIDropDownMenu_AddButton(info, level)

				-- options
				info = UIDropDownMenu_CreateInfo()
				info.text = "Configure"
				info.value = "options"
				info.hasArrow = 1
				info.notCheckable = 1
				UIDropDownMenu_AddButton(info, level)

				-- separator
				info = UIDropDownMenu_CreateInfo()
				info.disabled = 1
				UIDropDownMenu_AddButton(info, level)

				-- reset all
				info = UIDropDownMenu_CreateInfo()
				info.text = "Reset All"
				info.func = function()
					if kMADB.playSound then
						PlaySound("igMainMenuOption")
					end
					StaticPopup_Show("MOVEANYTHING_RESET_ALL_CONFIRM")
				end
				info.notCheckable = 1
				UIDropDownMenu_AddButton(info, level)
			elseif level == 2 then
				if UIDROPDOWNMENU_MENU_VALUE == "profiles" then
					local selected = MovAny:GetProfileName()

					info = UIDropDownMenu_CreateInfo()
					info.text = "default"
					info.arg1 = "default"
					info.func = MovAny.ChangeProfile
					info.checked = (selected == "default")
					UIDropDownMenu_AddButton(info, level)

					for name, _ in pairs(kMADB.profiles) do
						if name ~= "default" then
							info = UIDropDownMenu_CreateInfo()
							info.text = name
							info.arg1 = name
							info.func = MovAny.ChangeProfile
							info.checked = (selected == name)
							UIDropDownMenu_AddButton(info, level)
						end
					end
				elseif UIDROPDOWNMENU_MENU_VALUE == "exporter" then
					-- export profile
					info = UIDropDownMenu_CreateInfo()
					info.text = "Export"
					info.func = function()
						if kMADB.playSound then
							PlaySound("igMainMenuOption")
						end
						MovAny:PortDialog(2)
					end
					info.notCheckable = 1
					UIDropDownMenu_AddButton(info, level)

					-- import profile
					info = UIDropDownMenu_CreateInfo()
					info.text = "Import"
					info.func = function()
						if kMADB.playSound then
							PlaySound("igMainMenuOption")
						end
						MovAny:PortDialog(1)
					end
					info.notCheckable = 1
					UIDropDownMenu_AddButton(info, level)
				elseif UIDROPDOWNMENU_MENU_VALUE == "options" then
					-- always show nudger
					info = UIDropDownMenu_CreateInfo()
					info.text = "Show Nudger with main window"
					info.func = MovAny.OptionCheckboxChecked
					info.arg1 = "alwaysShowNudger"
					info.checked = kMADB.alwaysShowNudger
					UIDropDownMenu_AddButton(info, level)

					-- show tooltips
					info = UIDropDownMenu_CreateInfo()
					info.text = "Show Tooltips"
					info.func = MovAny.OptionCheckboxChecked
					info.arg1 = "tooltips"
					info.checked = kMADB.tooltips
					UIDropDownMenu_AddButton(info, level)

					-- play sound
					info = UIDropDownMenu_CreateInfo()
					info.text = "Play Sound"
					info.func = MovAny.OptionCheckboxChecked
					info.arg1 = "playSound"
					info.checked = kMADB.playSound
					UIDropDownMenu_AddButton(info, level)

					-- close on escape
					info = UIDropDownMenu_CreateInfo()
					info.text = "Escape key closes main window"
					info.func = MovAny.OptionCheckboxChecked
					info.arg1 = "closeGUIOnEscape"
					info.checked = kMADB.closeGUIOnEscape
					UIDropDownMenu_AddButton(info, level)

					-- disable search
					info = UIDropDownMenu_CreateInfo()
					info.text = "Dont search frame names"
					info.func = MovAny.OptionCheckboxChecked
					info.arg1 = "dontSearchFrameNames"
					info.checked = kMADB.dontSearchFrameNames
					UIDropDownMenu_AddButton(info, level)

					-- disable bags container
					info = UIDropDownMenu_CreateInfo()
					info.text = "Disable bag container hook"
					info.func = MovAny.OptionCheckboxChecked
					info.arg1 = "noBags"
					info.checked = kMADB.noBags
					UIDropDownMenu_AddButton(info, level)

					-- disable hook to CreateFrame
					info = UIDropDownMenu_CreateInfo()
					info.text = "Disable frame creation hook"
					info.func = MovAny.OptionCheckboxChecked
					info.arg1 = "dontHookCreateFrame"
					info.checked = kMADB.dontHookCreateFrame
					UIDropDownMenu_AddButton(info, level)

					-- square minimap
					info = UIDropDownMenu_CreateInfo()
					info.text = "Enable square Minimap"
					info.func = MovAny.OptionCheckboxChecked
					info.arg1 = "squareMM"
					info.checked = kMADB.squareMM
					UIDropDownMenu_AddButton(info, level)

					-- minimap mousewheel
					info = UIDropDownMenu_CreateInfo()
					info.text = "Disable Minimap mousewheel zoom"
					info.func = MovAny.OptionCheckboxChecked
					info.arg1 = "noMMMW"
					info.checked = kMADB.noMMMW
					UIDropDownMenu_AddButton(info, level)
				end
			end
		end
		ToggleDropDownMenu(1, nil, menu, "cursor")
	end
end

function MovAny:ProfileRenameClicked(b)
	local dlg = StaticPopup_Show("MOVEANYTHING_PROFILE_RENAME", MovAny:GetProfileName())
	if dlg then
		dlg.editBox:SetText(MovAny:GetProfileName())
	end
end

function MovAny:SetNumRows(num, dontUpdate)
	if not MAOptions then return end
	kMADB.frameListRows = num

	local base, h = 0, 24

	MAOptions:SetHeight(base + 81 + (num * h))
	MAScrollFrame:SetHeight(base + 11 + (num * h))
	MAScrollBorder:SetHeight(base - 22 + (num * h))

	for i = 1, 100, 1 do
		local row = _G["MAMove" .. i]
		if num >= i then
			if not row then
				row = CreateFrame("Frame", "MAMove" .. i, MAOptions, "MAListRowTemplate")
				if i == 1 then
					row:SetPoint("TOPLEFT", "MAOptionsFrameNameHeader", "BOTTOMLEFT", -8, -4)
				else
					row:SetPoint("TOPLEFT", "MAMove" .. (i - 1), "BOTTOMLEFT")
				end

				local label = _G["MAMove" .. i .. "FrameName"]
				label:SetScript("OnEnter", MovAny_TooltipShowMultiline)
				label:SetScript("OnLeave", MovAny_TooltipHide)
			end
		else
			if row then
				row:Hide()
			end
		end
	end

	if not dontUpdate then
		self:UpdateGUIIfShown(true)
	end
end

function MovAny_TooltipShow(a, b, c, d, e)
	MovAny:TooltipShow(a, b, c, d, e)
end
_G.MovAny_TooltipShow = MovAny_TooltipShow

function MovAny_TooltipHide(a, b, c, d, e)
	MovAny:TooltipHide(a, b, c, d, e)
end
_G.MovAny_TooltipHide = MovAny_TooltipHide

function MovAny_TooltipShowMultiline(a, b, c, d, e)
	MovAny:TooltipShowMultiline(a, b, c, d, e)
end
_G.MovAny_TooltipShowMultiline = MovAny_TooltipShowMultiline

function MovAny:Search(searchWord)
	searchWord = searchWord:trim()
	if searchWord:lower() ~= SEARCH:lower() then
		searchWord =
			string.gsub(string.gsub(string.lower(searchWord), "([%(%)%%%.%[%]%+%-%?])", "%%%1"), "%*", "[%%w %%c]*")
		if self.searchWord ~= searchWord then
			self.searchWord = searchWord
			self:UpdateGUIIfShown(true)
		end
	else
		self.searchWord = nil
		self:UpdateGUIIfShown()
	end
end

function MovAny:OnEvent(_, event, arg1)
	if event == "PLAYER_ENTER_COMBAT" then
		if #MovAny.movers > 0 then
			for i, v in ipairs(tcopy(MovAny.movers)) do
				if MovAny:IsProtected(v.tagged) then
					tinsert(MovAny.pendingMovers, v.tagged)
					MovAny:StopMoving(v.tagged:GetName())
				end
			end
		end
	elseif event == "PLAYER_REGEN_ENABLED" then
		if #MovAny.pendingMovers > 0 then
			for i, v in ipairs(MovAny.pendingMovers) do
				if _G.MAOptionsToggleMovers:GetChecked() then
					MovAny:AttachMover(v:GetName())
				else
					tinsert(MovAny.minimizedMovers, v)
				end
			end
			table.wipe(MovAny.pendingMovers)
		end
		MovAny:SyncFrames()
	elseif event == "ADDON_LOADED" then
		if arg1 == "Blizzard_TalentUI" then
			MovAny.hBlizzard_TalentUI()
		end
		MovAny:SyncFrames()
	elseif event == "PLAYER_FOCUS_CHANGED" then
		if MovAny.frameOptions["FocusFrame"] then
			MovAny.pendingFrames["FocusFrame"] = MovAny.frameOptions["FocusFrame"]
			MovAny:SyncFrames()
		end
	elseif event == "BANKFRAME_OPENED" then
		local ds = MovAny.lDelayedSync
		for i = 1, 7, 1 do
			ds["BankBagFrame" .. i] = nil
		end
		MovAny:SyncFrames()
		for i = 1, 7, 1 do
			MovAny:CreateVM("BankBagFrame" .. i)
		end
	elseif event == "BANKFRAME_CLOSED" then
		local ds = MovAny.lDelayedSync
		for i = 1, 7, 1 do
			ds["BankBagFrame" .. i] = L.FRAME_ONLY_WHEN_BANK_IS_OPEN
		end
	elseif event == "PLAYER_LOGOUT" then
		MovAny:OnPlayerLogout()
	elseif event == "PLAYER_ENTERING_WORLD" then
		if MovAny.Boot ~= nil then
			MovAny:Boot()
			MovAny.Boot = nil
			MovAny.ParseData = nil
		end
		MovAny:SyncAllFrames()
		collectgarbage()
	else
		MovAny:SyncAllFrames()
	end
end

local function MAMoverTemplate_OnMouseWheel(self, dir)
	MovAny:MoverOnMouseWheel(self, dir)
end
_G.MAMoverTemplate_OnMouseWheel = MAMoverTemplate_OnMouseWheel

local function MANudgeButton_OnClick(self, event, button)
	MovAny:Nudge(self.dir, button)
end
_G.MANudgeButton_OnClick = MANudgeButton_OnClick

local function MANudger_OnMouseWheel(self, dir)
	MovAny:NudgerChangeMover(dir)
end
_G.MANudger_OnMouseWheel = MANudger_OnMouseWheel

function MovAny:CreateVM(name)
	local data = MovAny.lVirtualMovers[name]
	if not data then
		return
	end
	if data.created then
		return _G[name]
	end
	local vm = CreateFrame("Frame", name, UIParent, data.inherits, "MADontHook")

	if data.id then
		vm:SetID(data.id)
	end
	vm.data = data

	if data.linkedSize then
		local ref = _G[data.linkedSize]
		if ref then
			vm:SetWidth(ref:GetWidth())
			vm:SetHeight(ref:GetHeight())
		end
	else
		if data.w then
			vm:SetWidth(data.w)
		end
		if data.h then
			vm:SetHeight(data.h)
		end
	end

	if data.dontLock then
		vm.MADontLock = true
	end
	if data.dontHide then
		vm.MADontHide = true
	end

	vm.FoundChild = function(self, index, child)
		if not self.firstChild then
			self.firstChild = child
		end
		child.MAParent = self
		if data.OnMAFoundChild then
			data.OnMAFoundChild(self, index, child)
		end
		if not self.MADontLock then
			MovAny:LockPoint(child)
		end
		if self.MAHidden and not child.MAHidden then
			MovAny:LockVisibility(child)
		end
		self.attachedChildren[index] = child
		self.lastChild = child
		return child
	end

	vm.ReleaseChild = function(self, index)
		local child = self.attachedChildren[index]
		if not child then
			return
		end
		if not self.MADontLock then
			MovAny:UnlockPoint(child)
		end
		if data.OnMAReleaseChild then
			data.OnMAReleaseChild(self, index, child)
		end
		self.lastChild = child
	end

	vm.MAScanForChildren = function(self, dontCallNewChild)
		if not self.attachedChildren then
			return
		end
		local newChild = false
		if type(data.count) == "number" then
			local name
			for i = 1, data.count, 1 do
				name = data.prefix .. i
				if not self.attachedChildren[name] then
					local child = _G[name]
					if child and not MovAny:IsModified(name) then
						newChild = self:FoundChild(i, child, 1)
					end
				end
			end
			if data.prefix1 then
				for i = 1, data.count, 1 do
					name = data.prefix1 .. i
					if not self.attachedChildren[name] then
						local child = _G[name]
						if child and not MovAny:IsModified(name) then
							newChild = self:FoundChild(i, child, 2)
						end
					end
				end
			end
			if data.prefix2 then
				for i = 1, data.count, 1 do
					name = data.prefix2 .. 2
					if not self.attachedChildren[name] then
						local child = _G[name]
						if child and not MovAny:IsModified(name) then
							newChild = self:FoundChild(i, child, 3)
						end
					end
				end
			end
		end
		if type(data.children) == "table" then
			for i, v in pairs(data.children) do
				local child = type(v) == "string" and _G[v] or v
				if type(child) == "table" and not self.attachedChildren[child:GetName()] then
					if not MovAny:IsModified(child) then
						newChild = self:FoundChild(child:GetName(), child)
					end
				end
			end
		end
		if not dontCallNewChild and newChild and self.OnMANewChild then
			self:OnMANewChild()
		end
	end

	local opt = self:GetFrameOptions(name)
	vm.opt = opt

	if not vm.MAPoint then
		if data.point then
			vm:SetPoint(unpack(data.point))
			if opt and opt.pos and not opt.orgPos then
				opt.orgPos = data.point
			end
		elseif data.relPoint then
			vm:SetPoint(unpack(data.relPoint))
			vm:SetPoint(unpack(self:GetRelativePoint(nil, vm)))
			if opt and opt.pos and not opt.orgPos then
				opt.orgPos = data.point
			end
		elseif not opt or not opt.pos then
			if data.linkedPoint then
				local ref = _G[data.linkedPoint]
				if ref then
					local p = MovAny:GetRelativePoint(nil, ref)
					if p then
						vm:SetPoint(unpack(p))
					end
				end
			end
		end
	elseif data.point then
		opt.orgPos = data.point
	end

	if opt and opt.pos and data.point and not opt.orgPos then
		opt.orgPos = data.point
	end

	if data.protected then
		vm.MAProtected = true
	end
	if data.dontScale then
		vm.MADontScaleChildren = true
	end

	if data.frameStrata and (not opt or not opt.frameStrata) then
		vm:SetFrameStrata(data.frameStrata)
	end

	vm.OnMAAttach = function(self)
		if data.linkedSize then
			local ref = _G[data.linkedSize]
			if ref then
				self:SetWidth(ref:GetWidth())
				self:SetHeight(ref:GetHeight())
			end
		end
		if not self.opt or not self.opt.pos then
			if data.linkedPoint then
				local ref = _G[data.linkedPoint]
				if ref then
					local p = MovAny:GetRelativePoint(nil, ref)
					if p then
						self:SetPoint(unpack(p))
					end
				end
			end
		end
		if data.OnMAAttach then
			data.OnMAAttach(self)
		end
		if data.OnMAPosition then
			data.OnMAPosition(self)
		end
	end
	if data.OnMAPosition then
		vm.OnMAPosition = data.OnMAPosition
	end
	if data.OnMAAlpha then
		vm.OnMAAlpha = data.OnMAAlpha
	end
	if data.OnMAScale then
		vm.OnMAScale = data.OnMAScale
	end
	if data.OnMAPreReset then
		vm.OnMAPreReset = data.OnMAPreReset
	end
	if data.OnMAPostAttach then
		vm.OnMAPostAttach = data.OnMAPostAttach
	end
	if data.OnMAPostHook then
		vm.OnMAPostHook = data.OnMAPostHook
	end
	vm.OnMAHide = function(self, hidden)
		if hidden then
			if self.attachedChildren then
				for i, v in pairs(self.attachedChildren) do
					MovAny:LockVisibility(v)
				end
			end
		else
			if self.attachedChildren then
				for i, v in pairs(self.attachedChildren) do
					MovAny:UnlockVisibility(v)
				end
			end
		end
		if data.OnMAHide then
			data.OnMAHide(self, hidden)
		end
	end
	if data.OnMAMoving then
		vm.OnMAMoving = data.OnMAMoving
	end
	if data.OnMADetach then
		vm.OnMADetach = data.OnMADetach
	end
	if data.OnMAPositionReset then
		vm.OnMAPositionReset = data.OnMAPositionReset
	end

	if vm.OnMAHook and not data.OnMAHook then
		data.OnMAHook = vm.OnMAHook
	end
	vm.OnMAHook = function(self)
		self.opt = MovAny:GetFrameOptions(self:GetName())
		if self.opt and self.opt.disabled then
			return
		end
		if data.excludes and MovAny:IsModified(data.excludes) then
			MovAny:ResetFrame(data.excludes)
			MovAny:UpdateGUIIfShown(true)
		end
		self.attachedChildren = {}
		self:MAScanForChildren(true)
		if data.OnMAHook then
			data.OnMAHook(self)
		end
		self:Show()
	end

	if vm.OnMAPostReset and not data.OnMAPostReset then
		data.OnMAPostReset = vm.OnMAPostReset
	end
	vm.OnMAPostReset = function(self)
		if data.OnMAPostReset then
			data.OnMAPostReset(self)
		end
		if type(self.attachedChildren) == "table" then
			if type(data.count) == "number" then
				local name
				for i = 1, data.count, 1 do
					self:ReleaseChild(i)
				end
			end
			if type(self.data.children) == "table" then
				self.lastChild = nil
				for _, name in pairs(self.data.children) do
					self:ReleaseChild(name)
				end
			end
		end
		self.firstChild = nil
		self.lastChild = nil
		self:Hide()
	end

	if data.OnMAScanForChildren then
		vm.OnMAScanForChildren = data.OnMAScanForChildren
	end

	vm.OnMANewChild = function(self)
		MovAny:SyncFrame(self:GetName())
		if data.OnMANewChild then
			data:OnMANewChild()
		end
	end

	vm.MAOnEnable = function(self)
		self:MAScanForChildren()
	end

	if data.OnLoad then
		vm.MAOnLoad = data.OnLoad
		vm:MAOnLoad()
		vm.MAOnLoad = nil
	end

	if vm.OnMACreateVM then
		vm:OnMACreateVM(vm)
	end

	data.created = true
	return vm
end

function MovAny:UnserializeProfile(str)
	str = string.gsub(str, "^%s+", "")
	str = string.gsub(str, "%s+$", "")
	str = string.gsub(str, "[\r\n]", "")
	local sName
	for i, v in string.gmatch(str, ',name:"(.-)"') do
		sName = i
	end

	if not sName then
		MovAny_Print(L.UNSERIALIZE_PROFILE_NO_NAME)
		return
	end
	local frames = {}
	local opt
	str = str .. ","
	for i in string.gmatch(str, "frames:{(.+)}") do
		for j in string.gmatch(i, "(%[.-%])") do
			opt = MovAny:UnserializeFrame(j)
			if opt then
				frames[opt.name] = opt
			end
		end
	end

	local tName = sName
	local ct = 1
	while kMADB.profiles[tName] do
		tName = sName .. " (" .. ct .. ")"
		ct = ct + 1
	end
	MovAny:AddProfile(tName)
	kMADB.profiles[tName].frames = frames

	MovAny_Print(string.format(L.UNSERIALIZE_PROFILE_COMPLETED, tlen(frames), tName))
	return true
end

function MovAny:UnserializeFrame(str, name)
	str = string.gsub(str, "^%s+", "")
	str = string.gsub(str, "%s+$", "")
	str = string.gsub(str, "[\r\n]", "")
	str = string.match(str, "%[(.+)%]")
	--[s:0.70035458463692,h:1,p:("CENTER","UIParent","CENTER",1028.675318659,84.760391583122),n:"MAOptions"]
	if not str then
		MovAny_Print(L.UNSERIALIZE_FRAME_INVALID_FORMAT)
		return nil
	end
	str = str .. ","
	local scannedName
	local opt = {}
	for m1, m2, m3 in string.gmatch(str, "(%a+):(.-),") do
		if m1 == "s" then
			opt.scale = tonumber(m2)
		elseif m1 == "hi" then
			opt.hidden = true
		elseif m1 == "a" then
			opt.alpha = tonumber(m2)
		elseif m1 == "w" then
			opt.width = tonumber(m2)
		elseif m1 == "h" then
			opt.height = tonumber(m2)
		elseif m1 == "fs" then
			opt.frameStrata = string.sub(m2, 2, -2)
		elseif m1 == "cts" then
			opt.clampToScreen = true
		elseif m1 == "em" then
			opt.enableMouse = true
		elseif m1 == "m" then
			opt.movable = true
		elseif m1 == "uae" then
			opt.unregisterAllEvents = true
		elseif m1 == "dla" then
			opt.disableLayerArtwork = true
		elseif m1 == "dlb" then
			opt.disableLayerBackground = true
		elseif m1 == "dlbo" then
			opt.disableLayerBorder = true
		elseif m1 == "dlh" then
			opt.disableLayerHighlight = true
		elseif m1 == "dlo" then
			opt.disableLayerOverlay = true
		elseif m1 == "n" then
			scannedName = string.sub(m2, 2, -2)
		end
	end
	--,
	for m1, m2, m3, m4, m5 in string.gmatch(str, 'p:%("(.-)","(.-)","(.-)",(-?%d+%.*%d*),(-?%d+%.*%d*)%)') do
		opt.pos = {m1, m2, m3, tonumber(m4), tonumber(m5)}
	end

	if name and name ~= scannedName then
		MovAny_Print(L.UNSERIALIZE_FRAME_NAME_DIFFERS)
		return
	end

	opt.name = scannedName or name

	return opt
end

function MovAny:SerializeProfile(pn)
	local p = kMADB.profiles[pn]

	local s = ""

	for i, v in pairs(p.frames) do
		s = s .. "," .. self:SerializeFrame(i, v)
	end
	s = "frames:{" .. string.sub(s, 2) .. '},name:"' .. string.gsub(string.gsub(pn, "%]", ")"), "%[", "(") .. '"'
	return s
end

function MovAny:SerializeFrame(fn, opt)
	opt = opt or self:GetFrameOptions(fn)

	local s = "["

	for i, v in pairs(opt) do
		if i == "pos" then
			s = s .. 'p:("' .. v[1] .. '","' .. v[2] .. '","' .. v[3] .. '",' .. v[4] .. "," .. v[5] .. "),"
		elseif i == "hidden" then
			s = s .. "hi:1,"
		elseif i == "alpha" then
			s = s .. "a:" .. v .. ","
		elseif i == "scale" then
			s = s .. "s:" .. v .. ","
		elseif i == "width" then
			s = s .. "w:" .. v .. ","
		elseif i == "height" then
			s = s .. "h:" .. v .. ","
		elseif i == "frameStrata" then
			s = s .. 'fs:"' .. v .. '",'
		elseif i == "clampToScreen" then
			s = s .. "cts:1,"
		elseif i == "enableMouse" then
			s = s .. "em:1,"
		elseif i == "movable" then
			s = s .. "m:1,"
		elseif i == "unregisterAllEvents" then
			s = s .. "uae:1,"
		elseif i == "disableLayerArtwork" then
			s = s .. "dla:1,"
		elseif i == "disableLayerBackground" then
			s = s .. "dlb:1,"
		elseif i == "disableLayerBorder" then
			s = s .. "dlbo:1,"
		elseif i == "disableLayerHighlight" then
			s = s .. "dlh:1,"
		elseif i == "disableLayerOverlay" then
			s = s .. "dlo:1,"
		end
	end
	s = s .. 'n:"' .. fn .. '"'

	s = s .. "]"
	return s
end