local MovAny = MovAny
if not MovAny then return end

local KPack = KPack
if not KPack then return end

local L = KPack.L

MovAny.lVirtualMovers = {
	UIPanelMover1 = {
		w = 384,
		h = 512,
		point = {"TOPLEFT", "UIParent", "TOPLEFT", 0, -104},
		OnMAAttach = MovAny.SyncUIPanels,
		OnMAPosition = MovAny.SyncUIPanels,
		OnMAAlpha = MovAny.SyncUIPanels,
		OnMAScale = MovAny.SyncUIPanels
	},
	UIPanelMover2 = {
		w = 384,
		h = 512,
		point = {"TOPLEFT", "UIParent", "TOPLEFT", 384, -104},
		OnMAAttach = MovAny.SyncUIPanels,
		OnMAPosition = MovAny.SyncUIPanels,
		OnMAAlpha = MovAny.SyncUIPanels,
		OnMAScale = MovAny.SyncUIPanels
	},
	UIPanelMover3 = {
		w = 384,
		h = 512,
		point = {"TOPLEFT", "UIParent", "TOPLEFT", 772, -104},
		OnMAAttach = MovAny.SyncUIPanels,
		OnMAPosition = MovAny.SyncUIPanels,
		OnMAAlpha = MovAny.SyncUIPanels,
		OnMAScale = MovAny.SyncUIPanels
	},
	TooltipMover = {
		frameStrata = "TOOLTIP",
		w = 150,
		h = 80,
		point = {"TOP", "UIParent", 0, 0},
		OnShow = function(self)
			self:SetFrameLevel(GameTooltip:GetFrameLevel() + 1)
		end,
		OnMAPostHook = function(self)
			MovAny:HookTooltip(self)
		end,
		OnMAPosition = function(self)
			MovAny:HookTooltip(self)
		end,
		OnMAPreReset = function(self, opt)
			local tooltip = _G.GameTooltip
			MovAny:UnlockPoint(tooltip)
			MovAny:ResetScale(tooltip, opt, true)
			MovAny:ResetAlpha(tooltip, opt, true)
			MovAny:ResetHide(tooltip, opt, true)
			MovAny:ResetMisc(tooltip, opt, true)
			tooltip.MAHidden = nil
		end
	},
	BagItemTooltipMover = {
		frameStrata = "TOOLTIP",
		w = 150,
		h = 80,
		point = {"TOP", "UIParent", 0, 0},
		OnLoad = function(self)
			self:SetFrameLevel(GameTooltip:GetFrameLevel() + 1)
		end,
		OnMAPreReset = function(self, opt)
			local tooltip = _G.GameTooltip
			MovAny:UnlockPoint(tooltip)
			MovAny:ResetScale(tooltip, opt, true)
			MovAny:ResetAlpha(tooltip, opt, true)
			MovAny:ResetMisc(tooltip, opt, true)
			tooltip.MAHidden = nil
		end
	},
	BagButtonsMover = {
		w = 196,
		h = 44,
		relPoint = {"BOTTOMRIGHT", "MainMenuBarArtFrame", "BOTTOMRIGHT", -6, -2},
		excludes = "BagButtonsVerticalMover",
		children = {
			"MainMenuBarBackpackButton",
			"CharacterBag0Slot",
			"CharacterBag1Slot",
			"CharacterBag2Slot",
			"CharacterBag3Slot"
		},
		OnMAFoundChild = function(self, index, child)
			child:ClearAllPoints()
			if child == self.firstChild then
				child:SetPoint("RIGHT", self, "RIGHT", 0, 0)
			else
				child:SetPoint("RIGHT", self.lastChild, "LEFT", -4, 0)
			end
		end,
		OnMAReleaseChild = function(self, index, child)
			child:ClearAllPoints()
			if child == self.firstChild then
				child:SetPoint("BOTTOMRIGHT", "MainMenuBarArtFrame", "BOTTOMRIGHT", -6, -2)
			else
				child:SetPoint("RIGHT", self.lastChild, "LEFT", -4, 0)
			end
		end
	},
	BagButtonsVerticalMover = {
		w = 44,
		h = 173,
		relPoint = {"BOTTOMRIGHT", "MainMenuBarArtFrame", "BOTTOMRIGHT", -6, -2},
		excludes = "BagButtonsMover",
		notMAParent = true,
		children = {
			"MainMenuBarBackpackButton",
			"CharacterBag0Slot",
			"CharacterBag1Slot",
			"CharacterBag2Slot",
			"CharacterBag3Slot"
		},
		OnMAFoundChild = function(self, index, child)
			child:ClearAllPoints()
			if child == self.firstChild then
				child:SetPoint("BOTTOM", self, "BOTTOM", 0, 0)
			else
				child:SetPoint("BOTTOM", self.lastChild, "TOP", 0, 3)
			end
			child.MAParent = self
		end,
		OnMAReleaseChild = function(self, index, child)
			child:ClearAllPoints()
			if child == self.firstChild then
				child:SetPoint("BOTTOMRIGHT", "MainMenuBarArtFrame", "BOTTOMRIGHT", -6, -2)
			else
				child:SetPoint("RIGHT", self.lastChild, "LEFT", -4, 0)
			end
			child.MAParent = "BagButtonsMover"
		end
	},
	BagFrame1 = {inherits = "MovableBagFrame", id = 0},
	BagFrame2 = {inherits = "MovableBagFrame", id = 1},
	BagFrame3 = {inherits = "MovableBagFrame", id = 2},
	BagFrame4 = {inherits = "MovableBagFrame", id = 3},
	BagFrame5 = {inherits = "MovableBagFrame", id = 4},
	BankBagFrame1 = {inherits = "MovableBagFrame", id = 5},
	BankBagFrame2 = {inherits = "MovableBagFrame", id = 6},
	BankBagFrame3 = {inherits = "MovableBagFrame", id = 7},
	BankBagFrame4 = {inherits = "MovableBagFrame", id = 8},
	BankBagFrame5 = {inherits = "MovableBagFrame", id = 9},
	BankBagFrame6 = {inherits = "MovableBagFrame", id = 10},
	BankBagFrame7 = {inherits = "MovableBagFrame", id = 11},
	KeyRingFrame = {inherits = "MovableBagFrame", id = -2},
	MicroButtonsMover = {
		w = 253,
		h = 36,
		relPoint = {"BOTTOMLEFT", "MainMenuBarArtFrame", "BOTTOMLEFT", 549, 2},
		excludes = "MicroButtonsVerticalMover",
		children = {
			"CharacterMicroButton",
			"SpellbookMicroButton",
			"TalentMicroButton",
			"AchievementMicroButton",
			"QuestLogMicroButton",
			"GuildMicroButton",
			"PVPMicroButton",
			"LFDMicroButton",
			"MainMenuMicroButton",
			"HelpMicroButton"
		},
		OnMAFoundChild = function(self, index, child)
			if child == self.firstChild then
				child:ClearAllPoints()
				child:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT")
			end
		end,
		OnMAReleaseChild = function(self, index, child)
			if child == self.firstChild then
				child:ClearAllPoints()
				child:SetPoint("BOTTOMLEFT", "MainMenuBarArtFrame", "BOTTOMLEFT", 548, 2)
			end
		end
	},
	MicroButtonsVerticalMover = {
		w = 28,
		h = 340,
		relPoint = {"BOTTOMLEFT", "MainMenuBarArtFrame", "BOTTOMLEFT", 546, 2},
		excludes = "MicroButtonsMover",
		notMAParent = true,
		children = {
			"CharacterMicroButton",
			"SpellbookMicroButton",
			"TalentMicroButton",
			"AchievementMicroButton",
			"QuestLogMicroButton",
			"GuildMicroButton",
			"PVPMicroButton",
			"LFDMicroButton",
			"MainMenuMicroButton",
			"HelpMicroButton"
		},
		OnMAFoundChild = function(self, index, child)
			child:ClearAllPoints()
			if child == self.firstChild then
				child:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 24)
			else
				child:SetPoint("TOPLEFT", self.lastChild, "BOTTOMLEFT", 0, 24)
			end
		end,
		OnMAReleaseChild = function(self, index, child)
			child.MAParent = "MicroButtonsMover"
			child:ClearAllPoints()
			if child == self.firstChild then
				child:SetPoint("BOTTOMLEFT", "MainMenuBarArtFrame", "BOTTOMLEFT", 546, 2)
			else
				child:SetPoint("BOTTOMLEFT", self.lastChild, "BOTTOMRIGHT", -2, 0)
			end
		end
	},
	BasicActionButtonsMover = {
		w = 498,
		h = 38,
		relPoint = {"BOTTOMLEFT", "MainMenuBarArtFrame", "BOTTOMLEFT", 8, 3},
		protected = true,
		excludes = "BasicActionButtonsVerticalMover",
		prefix = "ActionButton",
		count = 12,
		OnMAHook = function(self)
			local b, bab
			ActionButton1:ClearAllPoints()
			if ActionButton1.MASetPoint then
				ActionButton1:MASetPoint("LEFT", self, "LEFT")
			else
				ActionButton1:SetPoint("LEFT", self, "LEFT")
			end
			BonusActionButton1:ClearAllPoints()
			if BonusActionButton1.MASetPoint then
				BonusActionButton1:MASetPoint("LEFT", self, "LEFT")
			else
				BonusActionButton1:SetPoint("LEFT", self, "LEFT")
			end
			ActionBarUpButton:ClearAllPoints()
			ActionBarUpButton:SetPoint("TOPLEFT", "ActionButton12", "TOPRIGHT", 0, 7)
			ActionBarDownButton:ClearAllPoints()
			ActionBarDownButton:SetPoint("BOTTOMLEFT", "ActionButton12", "BOTTOMRIGHT", 0, -9)
			for i = 1, 12, 1 do
				b = _G["ActionButton" .. i]
				bab = _G["BonusActionButton" .. i]
				if i > 1 then
					b:ClearAllPoints()
					b:SetPoint("LEFT", "ActionButton" .. (i - 1), "RIGHT", 6, 0)
					bab:ClearAllPoints()
					bab:SetPoint("CENTER", b, "CENTER")
				end
				b.MAParent = self
				bab.MAParent = self
				tinsert(self.attachedChildren, bab)
			end
			if not MovAny:IsModified("ActionBarUpButton") then
				tinsert(self.attachedChildren, ActionBarUpButton)
			end
			if not MovAny:IsModified("ActionBarDownButton") then
				tinsert(self.attachedChildren, ActionBarDownButton)
			end

			MovAny:LockPoint(ActionButton1)
			MovAny:LockPoint(BonusActionButton1)
		end,
		OnMAPostReset = function(self)
			MovAny:UnlockPoint(ActionButton1)
			MovAny:UnlockPoint(BonusActionButton1)
			local b, pb = _G["ActionButton1"]
			b:ClearAllPoints()
			if b.MASetPoint then
				b:MASetPoint("BOTTOMLEFT", "MainMenuBarArtFrame", "BOTTOMLEFT", 8, 4)
			else
				b:SetPoint("BOTTOMLEFT", "MainMenuBarArtFrame", "BOTTOMLEFT", 8, 4)
			end
			pb = b
			b = _G["BonusActionButton1"]
			b:ClearAllPoints()
			if b.MASetPoint then
				b:MASetPoint("BOTTOMLEFT", "MainMenuBarArtFrame", "BOTTOMLEFT", 8, 4)
			else
				b:SetPoint("BOTTOMLEFT", "MainMenuBarArtFrame", "BOTTOMLEFT", 8, 4)
			end
			ActionBarUpButton:ClearAllPoints()
			ActionBarUpButton:SetPoint("CENTER", "MainMenuBarArtFrame", "TOPLEFT", 522, -22)
			ActionBarDownButton:ClearAllPoints()
			ActionBarDownButton:SetPoint("CENTER", "MainMenuBarArtFrame", "TOPLEFT", 522, -42)
			for i = 2, 12, 1 do
				b = _G["ActionButton" .. i]
				b:ClearAllPoints()
				b:SetPoint("LEFT", pb, "RIGHT", 6, 0)
			end
		end
	},
	BasicActionButtonsVerticalMover = {
		w = 38,
		h = 475,
		relPoint = {"BOTTOMLEFT", "MainMenuBarArtFrame", "BOTTOMLEFT", 8, 4},
		protected = true,
		excludes = "BasicActionButtonsMover",
		OnMAHook = function(self)
			local b, pb
			b = _G["ActionButton1"]
			b:ClearAllPoints()
			if b.MASetPoint then
				b:MASetPoint("TOP", self, "TOP")
			else
				b:SetPoint("TOP", self, "TOP")
			end
			pb = b
			b = _G["BonusActionButton1"]
			b:ClearAllPoints()
			if b.MASetPoint then
				b:MASetPoint("TOP", self, "TOP")
			else
				b:SetPoint("TOP", self, "TOP")
			end
			for i = 1, 12, 1 do
				b = _G["ActionButton" .. i]
				tinsert(self.attachedChildren, _G["ActionButton" .. i])
				tinsert(self.attachedChildren, _G["BonusActionButton" .. i])
				if i > 1 then
					b:ClearAllPoints()
					b:SetPoint("TOP", pb, "BOTTOM", 0, -2)
				end
				b.MAParent = self
				pb = b
			end
			tinsert(self.attachedChildren, ActionBarUpButton)
			tinsert(self.attachedChildren, ActionBarDownButton)
			ActionBarUpButton:ClearAllPoints()
			ActionBarUpButton:SetPoint("TOPLEFT", "ActionButton12", "BOTTOMLEFT", -8, 4)
			ActionBarDownButton:ClearAllPoints()
			ActionBarDownButton:SetPoint("TOPRIGHT", "ActionButton12", "BOTTOMRIGHT", 8, 4)
		end,
		OnMAPostReset = function(self)
			local b, pb
			b = _G["ActionButton1"]
			b:ClearAllPoints()
			if b.MASetPoint then
				b:MASetPoint("BOTTOMLEFT", "MainMenuBarArtFrame", "BOTTOMLEFT", 8, 4)
			else
				b:SetPoint("BOTTOMLEFT", "MainMenuBarArtFrame", "BOTTOMLEFT", 8, 4)
			end
			pb = b
			b = _G["BonusActionButton1"]
			b:ClearAllPoints()
			if b.MASetPoint then
				b:MASetPoint("BOTTOMLEFT", "MainMenuBarArtFrame", "BOTTOMLEFT", 8, 4)
			else
				b:SetPoint("BOTTOMLEFT", "MainMenuBarArtFrame", "BOTTOMLEFT", 8, 4)
			end
			ActionBarUpButton:ClearAllPoints()
			ActionBarUpButton:SetPoint("CENTER", "MainMenuBarArtFrame", "TOPLEFT", 522, -22)
			ActionBarDownButton:ClearAllPoints()
			ActionBarDownButton:SetPoint("CENTER", "MainMenuBarArtFrame", "TOPLEFT", 522, -42)
			for i = 2, 12, 1 do
				b = _G["ActionButton" .. i]
				b.MAParent = _G["BasicActionButtonsMover"]
				b:ClearAllPoints()
				b:SetPoint("LEFT", pb, "RIGHT", 6, 0)
				pb = b
			end
		end
	},
	PetActionButtonsMover = {
		w = 370,
		h = 32,
		point = {"BOTTOMLEFT", "PetActionBarFrame", "BOTTOMLEFT", 370, 32},
		excludes = "PetActionButtonsVerticalMover",
		protected = true,
		prefix = "PetActionButton",
		count = 10,
		OnMAFoundChild = function(self, index, child)
			child:ClearAllPoints()
			if index == 1 then
				child:SetPoint("LEFT", self, "LEFT", 0, 0)
			else
				child:SetPoint("LEFT", self.lastChild, "RIGHT", 4, 0)
			end
		end,
		OnMAReleaseChild = function(self, index, child)
			child:ClearAllPoints()
			if index == 1 then
				child:SetPoint("BOTTOMLEFT", "PetActionBarFrame", "BOTTOMLEFT", 36, 1)
			else
				child:SetPoint("LEFT", self.lastChild, "RIGHT", 8, 0)
			end
		end
	},
	PetActionButtonsVerticalMover = {
		w = 43,
		h = 370,
		point = {"BOTTOMLEFT", "PetActionBarFrame", "BOTTOMLEFT", 36, 1},
		excludes = "PetActionButtonsMover",
		notMAParent = true,
		protected = true,
		prefix = "PetActionButton",
		count = 10,
		OnMAFoundChild = function(self, index, child)
			child:ClearAllPoints()
			child.MAParent = self
			if index == 1 then
				child:SetPoint("TOP", self, "TOP", 0, 0)
			else
				child:SetPoint("TOP", self.lastChild, "BOTTOM", 0, -3)
			end
		end,
		OnMAReleaseChild = function(self, index, child)
			child:ClearAllPoints()
			child.MAParent = "PetActionButtonsMover"
			if index == 1 then
				child:SetPoint("BOTTOMLEFT", "PetActionBarFrame", "BOTTOMLEFT", 36, 1)
			else
				child:SetPoint("LEFT", self.lastChild, "RIGHT", 8, 0)
			end
		end
	},
	ShapeshiftButtonsMover = {
		w = 225,
		h = 37,
		point = {"BOTTOMLEFT", "MainMenuBar", "TOPLEFT", 45, 30},
		excludes = "ShapeshiftButtonsVerticalMover",
		protected = true,
		prefix = "ShapeshiftButton",
		count = 10,
		dontLock = true,
		OnMAHook = function(self)
			local b = _G.ShapeshiftBarFrame
			b:DisableDrawLayer("BACKGROUND")
			b:DisableDrawLayer("BORDER")
			MovAny:UnlockPoint(b)
			b:ClearAllPoints()
			b:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 0, 0)
			MovAny:LockPoint(b)
			b.ignoreFramePositionManager = true
			b:SetMovable(true)
			b:SetUserPlaced(true)
			self.sbf = b
		end,
		OnMAPreReset = function(self)
			local b = self.sbf
			MovAny:UnlockPoint(b)
			b:SetPoint("BOTTOMLEFT", _G.MainMenuBar, "TOPLEFT", 45, 30)
			b:EnableDrawLayer("BACKGROUND")
			b:EnableDrawLayer("BORDER")
			b.ignoreFramePositionManager = nil
			b:SetUserPlaced(nil)
			b:SetMovable(nil)
		end,
		OnMAPostReset = function(self)
		end,
		OnMAHide = function(self, hidden)
			if hidden then
				MovAny:LockVisibility(self.sbf)
			else
				MovAny:UnlockVisibility(self.sbf)
			end
		end
	},
	ShapeshiftButtonsVerticalMover = {
		w = 32,
		h = 225,
		point = {"BOTTOMLEFT", "ShapeshiftBarFrame", "BOTTOMLEFT", 11, 3},
		excludes = "ShapeshiftButtonsMover",
		notMAParent = true,
		protected = true,
		prefix = "ShapeshiftButton",
		count = 10,
		OnMAHook = function(self)
			local b = _G.ShapeshiftBarFrame
			b:DisableDrawLayer("BACKGROUND")
			b:DisableDrawLayer("BORDER")
			b.ignoreFramePositionManager = true
			b:SetMovable(true)
			b:SetUserPlaced(true)
			self.sbf = b
		end,
		OnMAPostReset = function(self)
			local b = self.sbf
			b:EnableDrawLayer("BACKGROUND")
			b:EnableDrawLayer("BORDER")
			b.ignoreFramePositionManager = nil
			if self.sbf:IsUserPlaced() then
				self.sbf:SetUserPlaced(nil)
			end
			if self.sbf:IsMovable() then
				self.sbf:SetMovable(nil)
			end
		end,
		OnMAFoundChild = function(self, index, child)
			child.MAParent = self
			child:ClearAllPoints()
			if child == self.firstChild then
				child:SetPoint("TOP", self, "TOP", 0, -7)
			else
				child:SetPoint("TOP", self.lastChild, "BOTTOM", 0, -7)
			end
		end,
		OnMAReleaseChild = function(self, index, child)
			child.MAParent = "ShapeshiftButtonsMover"
			child:ClearAllPoints()
			if child == self.firstChild then
				child:SetPoint("BOTTOMLEFT", self.sbf, "BOTTOMLEFT", 11, 3)
			else
				child:SetPoint("LEFT", self.lastChild, "RIGHT", 8, 0)
			end
		end
	},
	MultiBarRightHorizontalMover = {
		w = 498,
		h = 38,
		point = {"BOTTOM", "UIParent", "BOTTOM", 0, 250},
		excludes = "MultiBarRight",
		notMAParent = true,
		protected = true,
		prefix = "MultiBarRightButton",
		count = 12,
		OnMAFoundChild = function(self, index, child)
			child:ClearAllPoints()
			if index == 1 then
				child:SetPoint("TOPLEFT", self)
			else
				child:SetPoint("LEFT", self.lastChild, "RIGHT", 6, 0)
			end
		end,
		OnMAReleaseChild = function(self, index, child)
			child:ClearAllPoints()
			if index == 1 then
				child:SetPoint("TOPRIGHT", "MultiBarRight")
			else
				child:SetPoint("TOP", self.lastChild, "BOTTOM", 0, -6)
			end
			child.MAParent = nil
		end
	},
	MultiBarLeftHorizontalMover = {
		w = 498,
		h = 38,
		point = {"BOTTOM", "UIParent", "BOTTOM", 0, 285},
		excludes = "MultiBarLeft",
		notMAParent = true,
		protected = true,
		prefix = "MultiBarLeftButton",
		count = 12,
		OnMAFoundChild = function(self, index, child)
			child:ClearAllPoints()
			if index == 1 then
				child:SetPoint("TOPLEFT", self)
			else
				child:SetPoint("LEFT", self.lastChild, "RIGHT", 6, 0)
			end
		end,
		OnMAReleaseChild = function(self, index, child)
			child:ClearAllPoints()
			if index == 1 then
				child:SetPoint("TOPRIGHT", "MultiBarLeft")
			else
				child:SetPoint("TOP", self.lastChild, "BOTTOM", 0, -6)
			end
			child.MAParent = nil
		end
	},
	PartyMember1DebuffsMover = {
		w = 66,
		h = 15,
		point = {"TOPLEFT", "PartyMemberFrame1", "TOPLEFT", 48, -32},
		prefix = "PartyMemberFrame1Debuff",
		count = MAX_PARTY_DEBUFFS,
		dontLock = true,
		OnMAFoundChild = function(self, index, child)
			if index == 1 then
				child:ClearAllPoints()
				child:SetPoint("TOPLEFT", self)
				MovAny:LockPoint(child)
			end
		end,
		OnMAReleaseChild = function(self, index, child)
			if index == 1 then
				MovAny:UnlockPoint(child)
				child:ClearAllPoints()
				child:SetPoint("TOPLEFT", "PartyMemberFrame1", 48, -32)
			end
		end,
		OnMAHook = function(self)
			self:SetScale(_G["PartyMemberFrame1"]:GetEffectiveScale() / UIParent:GetScale())
		end
	},
	PartyMember2DebuffsMover = {
		w = 66,
		h = 15,
		point = {"TOPLEFT", "PartyMemberFrame2", "TOPLEFT", 48, -32},
		prefix = "PartyMemberFrame2Debuff",
		count = MAX_PARTY_DEBUFFS,
		dontLock = true,
		OnMAFoundChild = function(self, index, child)
			if index == 1 then
				child:ClearAllPoints()
				child:SetPoint("TOPLEFT", self)
				MovAny:LockPoint(child)
			end
		end,
		OnMAReleaseChild = function(self, index, child)
			if index == 1 then
				MovAny:UnlockPoint(child)
				child:ClearAllPoints()
				child:SetPoint("TOPLEFT", "PartyMemberFrame2", 48, -32)
			end
		end,
		OnMAHook = function(self)
			self:SetScale(_G["PartyMemberFrame2"]:GetEffectiveScale() / UIParent:GetScale())
		end
	},
	PartyMember3DebuffsMover = {
		w = 66,
		h = 15,
		point = {"TOPLEFT", "PartyMemberFrame3", "TOPLEFT", 48, -32},
		prefix = "PartyMemberFrame3Debuff",
		count = MAX_PARTY_DEBUFFS,
		dontLock = true,
		OnMAFoundChild = function(self, index, child)
			if index == 1 then
				child:ClearAllPoints()
				child:SetPoint("TOPLEFT", self)
				MovAny:LockPoint(child)
			end
		end,
		OnMAReleaseChild = function(self, index, child)
			if index == 1 then
				MovAny:UnlockPoint(child)
				child:ClearAllPoints()
				child:SetPoint("TOPLEFT", "PartyMemberFrame3", 48, -32)
			end
		end,
		OnMAHook = function(self)
			self:SetScale(_G["PartyMemberFrame3"]:GetEffectiveScale() / UIParent:GetScale())
		end
	},
	PartyMember4DebuffsMover = {
		w = 66,
		h = 17,
		point = {"TOPLEFT", "PartyMemberFrame4", "TOPLEFT", 48, -32},
		prefix = "PartyMemberFrame4Debuff",
		count = MAX_PARTY_DEBUFFS,
		dontLock = true,
		OnMAFoundChild = function(self, index, child)
			if index == 1 then
				child:ClearAllPoints()
				child:SetPoint("TOPLEFT", self)
				MovAny:LockPoint(child)
			end
		end,
		OnMAReleaseChild = function(self, index, child)
			if index == 1 then
				MovAny:UnlockPoint(child)
				child:ClearAllPoints()
				child:SetPoint("TOPLEFT", "PartyMemberFrame4", 48, -32)
			end
		end,
		OnMAHook = function(self)
			self:SetScale(_G["PartyMemberFrame4"]:GetEffectiveScale() / UIParent:GetScale())
		end
	},
	PetDebuffsMover = {
		w = 66,
		h = 17,
		point = {"TOPLEFT", "PetFrame", "TOPLEFT", 48, -42},
		prefix = "PetFrameDebuff",
		count = 4,
		OnMAFoundChild = function(self, index, child)
			if index == 1 then
				child:ClearAllPoints()
				child:SetPoint("TOPLEFT", self, "TOPLEFT", 1, -1)
			end
		end,
		OnMAReleaseChild = function(self, index, child)
			if index == 1 then
				child:ClearAllPoints()
				child:SetPoint("TOPLEFT", "PetFrame", 48, -42)
			end
		end,
		OnMAHook = function(self)
			self:SetScale(_G["PetFrame"]:GetEffectiveScale() / UIParent:GetScale())
		end
	},
	TargetBuffsMover = {
		w = 122,
		h = 21,
		point = {"TOPLEFT", "TargetFrame", "BOTTOMLEFT", 5, 32},
		prefix = "TargetFrameBuff",
		count = MAX_TARGET_BUFFS,
		dontLock = true,
		OnLoad = function(self)
			if TargetFrame_UpdateAuras then
				hooksecurefunc("TargetFrame_UpdateAuras", function(frame)
					if frame == TargetFrame and self.MAHooked then
						self:MAScanForChildren()
					end
				end)
			end
		end,
		OnMAFoundChild = function(self, index, child)
			if index == 1 then
				child:ClearAllPoints()
				child:SetPoint("TOPLEFT", self)
				MovAny:LockPoint(child)
			end
		end,
		OnMAReleaseChild = function(self, index, child)
			if index == 1 then
				MovAny:UnlockPoint(child)
				child:ClearAllPoints()
				child:SetPoint("TOPLEFT", TargetFrame, "BOTTOMLEFT", 5, 32)
			end
		end,
		OnMAHook = function(self)
			self:SetScale(_G["TargetFrame"]:GetEffectiveScale() / UIParent:GetScale())
		end
	},
	TargetDebuffsMover = {
		w = 122,
		h = 23,
		point = {"TOPLEFT", "TargetFrame", "BOTTOMLEFT", 5, 35},
		prefix = "TargetFrameDebuff",
		count = MAX_TARGET_DEBUFFS,
		dontLock = true,
		OnLoad = function(self)
			if TargetFrame_UpdateAuras then
				hooksecurefunc("TargetFrame_UpdateAuras", function(frame)
					if frame == TargetFrame and self.MAHooked then
						self:MAScanForChildren()
					end
				end)
			end
		end,
		OnMAFoundChild = function(self, index, child)
			if self.firstChild == child then
				child:ClearAllPoints()
				child:SetPoint("TOPLEFT", self, "TOPLEFT", 1, -1)
				MovAny:LockPoint(child)
			end
		end,
		OnMAReleaseChild = function(self, index, child)
			if self.firstChild == child then
				MovAny:UnlockPoint(child)
				child:ClearAllPoints()
				child:SetPoint("TOPLEFT", TargetFrame, "BOTTOMLEFT", 5, 35)
			end
		end,
		OnMAHook = function(self)
			self:SetScale(_G["TargetFrame"]:GetEffectiveScale() / UIParent:GetScale())
		end
	},
	FocusBuffsMover = {
		w = 124,
		h = 23,
		point = {"TOPLEFT", "FocusFrame", "BOTTOMLEFT", 4, 33},
		prefix = "FocusFrameBuff",
		count = MAX_TARGET_BUFFS,
		dontLock = true,
		OnLoad = function(self)
			if TargetFrame_UpdateAuras then
				hooksecurefunc("TargetFrame_UpdateAuras", function(frame)
					if frame == FocusFrame and self.MAHooked then
						self:MAScanForChildren()
					end
				end)
			end
		end,
		OnMAFoundChild = function(self, index, child)
			if index == 1 then
				child:ClearAllPoints()
				child:SetPoint("TOPLEFT", self, "TOPLEFT", 1, -1)
				MovAny:LockPoint(child)
			end
		end,
		OnMAReleaseChild = function(self, index, child)
			if index == 1 then
				MovAny:UnlockPoint(child)
				child:ClearAllPoints()
				child:SetPoint("TOPLEFT", FocusFrame, "BOTTOMLEFT", 5, 35)
			end
		end,
		OnMAHook = function(self)
			self:SetScale(_G["FocusFrame"]:GetEffectiveScale() / UIParent:GetScale())
		end
	},
	FocusDebuffsMover = {
		w = 124,
		h = 21,
		point = {"TOPLEFT", "FocusFrame", "BOTTOMLEFT", 4, 33},
		prefix = "FocusFrameDebuff",
		count = MAX_TARGET_DEBUFFS,
		dontLock = true,
		OnLoad = function(self)
			if TargetFrame_UpdateAuras then
				hooksecurefunc("TargetFrame_UpdateAuras", function(frame)
					if frame == FocusFrame and self.MAHooked then
						self:MAScanForChildren()
					end
				end)
			end
		end,
		OnMAFoundChild = function(self, index, child)
			if index == 1 then
				child:ClearAllPoints()
				child:SetPoint("TOPLEFT", self, "TOPLEFT", 1, -1)
				MovAny:LockPoint(child)
			end
		end,
		OnMAReleaseChild = function(self, index, child)
			if index == 1 then
				MovAny:UnlockPoint(child)
				child:ClearAllPoints()
				child:SetPoint("TOPLEFT", FocusFrame, "BOTTOMLEFT", 4, 33)
			end
		end,
		OnMAHook = function(self)
			self:SetScale(_G["FocusFrame"]:GetEffectiveScale() / UIParent:GetScale())
		end
	},
	TargetFrameToTDebuffsMover = {
		w = 23,
		h = 23,
		point = {"TOPLEFT", "TargetFrameToT", "TOPRIGHT", 3, -9},
		prefix = "TargetFrameToTDebuff",
		count = 4,
		OnLoad = function(self)
			if TargetFrame_CreateTargetofTarget then
				hooksecurefunc("TargetFrame_CreateTargetofTarget", function(frame)
					if frame == TargetFrame and self.MAHooked then
						self:MAScanForChildren()
					end
				end)
			end
		end,
		OnMAFoundChild = function(self, index, child)
			if index == 1 then
				child:ClearAllPoints()
				child:SetPoint("TOPLEFT", self, "TOPLEFT", 1, -1)
			end
		end,
		OnMAReleaseChild = function(self, index, child)
			if index == 1 then
				child:ClearAllPoints()
				child:SetPoint("TOPLEFT", TargetFrameToT, "TOPRIGHT", 4, -10)
			end
		end,
		OnMAHook = function(self)
			self:SetScale(_G["TargetFrameToT"]:GetEffectiveScale() / UIParent:GetScale())
		end
	},
	PlayerBuffsMover = {
		w = 31,
		h = 31,
		point = {"TOPRIGHT", "UIParent", "TOPRIGHT", -205, -13},
		children = {"TemporaryEnchantFrame", "ConsolidatedBuffs"},
		prefix = "BuffButton",
		count = 32,
		dontHide = true,
		dontLock = true,
		dontScale = true,
		OnLoad = function(self)
			if BuffFrame_Update then
				local opt
				hooksecurefunc("BuffFrame_Update", function()
					if not self.MAHooked then return end
					opt = self.opt
					if opt and not opt.disabled and MovAny:IsModified(self, nil, opt) then
						self:MAScanForChildren()
						if GetCVar("consolidateBuffs") == "1" then
							if not opt.hidden and self.attachedChildren and self.opt.scale then
								for i, v in pairs(self.attachedChildren) do
									MovAny:UnlockScale(v)
									if v:GetParent():GetName() ~= "ConsolidatedBuffsContainer" then
										v:SetScale(self.opt.scale)
									else
										v:SetScale(1)
									end
									MovAny:LockScale(v)
								end
							end

							MovAny:UnlockPoint(self.tef)
							self.tef:ClearAllPoints()
							if BuffFrame.numConsolidated == 0 then
								self.tef:SetPoint("TOPRIGHT", "ConsolidatedBuffs", "TOPRIGHT", 0, 0)
							else
								self.tef:SetPoint("TOPRIGHT", "ConsolidatedBuffs", "TOPLEFT", -7, 0)
							end

							MovAny:LockPoint(self.tef)
						end
					end
				end)
			end
		end,
		OnMAFoundChild = function(self, index, child)
			if self.opt and self.opt.scale then
				MovAny:UnlockScale(child)
				if child:GetParent():GetName() ~= "ConsolidatedBuffsContainer" then
					child:SetScale(self.opt.scale)
				else
					child:SetScale(1)
				end
				MovAny:LockScale(child)
			end
		end,
		OnMAScale = function(self, scale)
			if self.attachedChildren then
				for i, child in pairs(self.attachedChildren) do
					MovAny:UnlockScale(child)
					if child:GetParent():GetName() ~= "ConsolidatedBuffsContainer" then
						child:SetScale(scale)
					else
						child:SetScale(1)
					end
					MovAny:LockScale(child)
				end
			end
		end,
		OnMAHook = function(self)
			local b = _G["BuffFrame"]
			self:SetScale(b:GetEffectiveScale() / UIParent:GetScale())
			b:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, 0)
			MovAny:LockPoint(b)

			b = _G["TemporaryEnchantFrame"]
			MovAny:LockPoint(b)
			self.tef = b

			b = _G["ConsolidatedBuffs"]
			b:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, 0)
			MovAny:LockPoint(b)
			if BuffFrame.numConsolidated == 0 then
				b:Hide()
			end

			self.opt = MovAny:GetFrameOptions(self:GetName())

			if self.attachedChildren and GetCVar("consolidateBuffs") == "1" and self.opt and self.opt.scale then
				for i, v in pairs(self.attachedChildren) do
					MovAny:UnlockScale(v)
					if v:GetParent():GetName() ~= "ConsolidatedBuffsContainer" then
						v:SetScale(self.opt.scale)
					else
						v:SetScale(1)
					end
					MovAny:LockScale(v)
				end
			end
		end,
		OnMAPreReset = function(self)
			for i, v in pairs(self.attachedChildren) do
				MovAny:UnlockScale(v)
				v:SetScale(1)
			end
		end,
		OnMAPostReset = function(self)
			local b = _G["BuffFrame"]
			MovAny:UnlockPoint(b)
			b:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -205, -13)
			b = _G["ConsolidatedBuffs"]
			MovAny:UnlockPoint(b)
			b:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -180, -13)

			MovAny:UnlockPoint(self.tef)
			self.tef = nil
		end,
		OnMAHide = function(self, hidden)
			if hidden then
				MovAny:LockVisibility(_G["ConsolidatedBuffs"])
				MovAny:LockVisibility(_G["BuffFrame"])
				MovAny:LockVisibility(_G["TemporaryEnchantFrame"])
			else
				MovAny:UnlockVisibility(_G["ConsolidatedBuffs"])
				MovAny:UnlockVisibility(_G["BuffFrame"])
				MovAny:UnlockVisibility(_G["TemporaryEnchantFrame"])
			end
		end
	},
	PlayerDebuffsMover = {
		w = 31,
		h = 31,
		prefix = "DebuffButton",
		count = 16,
		point = {"TOPRIGHT", "BuffFrame", "BOTTOMRIGHT", 0, -50},
		OnLoad = function(self)
			if BuffFrame_Update then
				hooksecurefunc("BuffFrame_Update", function()
					if self.MAHooked then
						self:MAScanForChildren()
					end
				end)
			end
		end,
		OnMAFoundChild = function(self, index, child)
			if index == 1 then
				child:ClearAllPoints()
				child:SetPoint("TOPRIGHT", self, "TOPRIGHT", -1, -1)
			end
		end,
		OnMAReleaseChild = function(self, index, child)
			if index == 1 then
				child:ClearAllPoints()
				child:SetPoint("TOPRIGHT", ConsolidatedBuffs, "BOTTOMRIGHT", 0, -TempEnchant1:GetHeight() * 3)
			end
		end,
		OnMAHook = function(self)
			self:SetScale(_G["BuffFrame"]:GetEffectiveScale() / UIParent:GetScale())
		end
	},
	FocusFrameToTDebuffsMover = {
		w = 23,
		h = 23,
		point = {"TOPLEFT", "FocusFrameToT", "TOPRIGHT", 3, -9},
		prefix = "FocusFrameToTDebuff",
		count = 8,
		OnMAFoundChild = function(self, index, child)
			if index == 1 then
				child:ClearAllPoints()
				child:SetPoint("TOPLEFT", self, 1, -1)
			end
		end,
		OnMAReleaseChild = function(self, index, child)
			if index == 1 then
				child:ClearAllPoints()
				child:SetPoint("TOPLEFT", "FocusFrameToT", "TOPRIGHT", 4, -10)
			end
		end,
		OnMAHook = function(self)
			self:SetScale(_G["FocusFrameToT"]:GetEffectiveScale() / UIParent:GetScale())
		end
	}
}