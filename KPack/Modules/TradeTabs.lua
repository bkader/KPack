local core = KPack
if not core then return end
core:AddModule("TradeTabs", "Adds tabs for your profession windows, allows you to switch to another profession window quickly.", function()
	if core:IsDisabled("TradeTabs") then return end

	-- cache frequently used globals
	local _CreateFrame = CreateFrame
	local _IsAddOnLoaded = IsAddOnLoaded
	local _IsLoggedIn = IsLoggedIn
	local _GetSpellInfo = GetSpellInfo
	local _GetSpellName = GetSpellName
	local _GetSpellTexture = GetSpellTexture
	local _IsCurrentSpell = IsCurrentSpell
	local _ipairs = ipairs

	-- create our module table.
	local mod = _CreateFrame("Frame", "TradeTabs")

	-- lists of profession spell IDS.
	-- Note: spells order determines tabs order.
	local spells = {
		28596, -- Alchemy
		29844, -- Blacksmithing
		28029, -- Enchanting
		30350, -- Engineering
		45357, -- Inscription
		28897, -- Jewel Crafting
		32549, -- Leatherworking
		53428, -- Runeforging
		2656, -- Smelting
		26790, -- Tailoring
		33359, -- Cooking
		27028, -- First Aid
		13262, -- Disenchant
		51005, -- Milling
		31252, -- Prospecting
		818 -- Basic Campfire
	}

	-- module's event handler.
	function mod:OnEvent(event, ...)
		self:UnregisterEvent(event)
		if not _IsLoggedIn() then
			self:RegisterEvent(event)
		elseif InCombatLockdown() then
			self:RegisterEvent("PLAYER_REGEN_ENABLED")
		else
			self:Initialize()
		end
	end

	-- Initializes the module.
	function mod:Initialize()
		if self.initialized or not _IsAddOnLoaded("Blizzard_TradeSkillUI") then
			return
		end

		for i = 1, #spells do
			local n = _GetSpellInfo(spells[i])
			spells[n] = -1
			spells[i] = n
		end

		local parent = TradeSkillFrame
		if _G.SkilletFrame then
			parent = _G.SkilletFrame
			self:UnregisterAllEvents()
		end

		for i = 1, MAX_SPELLS do
			local n = _GetSpellName(i, "spell")
			if spells[n] then
				spells[n] = i
			end
		end

		local prev
		for i, spell in _ipairs(spells) do
			local spellid = spells[spell]
			if type(spellid) == "number" and spellid > 0 then
				local tab = self:CreateTab(spell, spellid, parent)
				local point, relPoint, x, y = "TOPLEFT", "BOTTOMLEFT", 0, -17
				if not prev then
					prev, relPoint, x, y = parent, "TOPRIGHT", -33, -44
					if parent == _G.SkilletFrame then
						x = 0
					end
				end
				tab:SetPoint(point, prev, relPoint, x, y)
				prev = tab
			end
		end

		self.initialized = true
	end

	do
		-- show the profession's name tooltip when the tab is hovered.
		local function onEnter(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(self.tooltip)
			self:GetParent():LockHighlight()
		end

		-- simply hide the tooltip
		local function onLeave(self)
			GameTooltip:Hide()
			self:GetParent():UnlockHighlight()
		end

		local function updateSelection(self)
			if _IsCurrentSpell(self.spellid, "spell") then
				self:SetChecked(true)
				self.clickStopper:Show()
			else
				self:SetChecked(false)
				self.clickStopper:Hide()
			end
		end

		-- this function creates a fake button above the profession tab
		-- button in order to prevent closing the trade skill window.
		local function createClickStopper(button)
			local f = _CreateFrame("Frame", nil, button)
			f:SetAllPoints(button)
			f:EnableMouse(true)
			f:SetScript("OnEnter", onEnter)
			f:SetScript("OnLeave", onLeave)
			button.clickStopper = f
			f.tooltip = button.tooltip
			f:Hide()
		end

		-- handles profession tab creation.
		function mod:CreateTab(spell, spellid, parent)
			local button = _CreateFrame("CheckButton", nil, parent, "SpellBookSkillLineTabTemplate,SecureActionButtonTemplate")
			button.tooltip = spell
			button:Show()
			button:SetAttribute("type", "spell")
			button:SetAttribute("spell", spell)
			button.spellid = spellid
			button:SetNormalTexture(_GetSpellTexture(spellid, "spell"))

			button:SetScript("OnEvent", updateSelection)
			button:RegisterEvent("TRADE_SKILL_SHOW")
			button:RegisterEvent("TRADE_SKILL_CLOSE")
			button:RegisterEvent("CURRENT_SPELL_CAST_CHANGED")
			createClickStopper(button)
			updateSelection(button)

			if core.ElvUI and not button.skinned then
				button:SetTemplate("Default")
				button:StyleButton()
				button:DisableDrawLayer("BACKGROUND")
				button:GetNormalTexture():SetInside(button.backdrop)
				button:GetNormalTexture():SetTexCoord(unpack(core.ElvUI.TexCoords))
				button.skinned = true
			end

			return button
		end
	end

	mod:RegisterEvent("TRADE_SKILL_SHOW")
	mod:SetScript("OnEvent", mod.OnEvent)
	mod:Initialize()
end)