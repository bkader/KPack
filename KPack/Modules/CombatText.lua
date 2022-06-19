--[[   ____ _____
__  __/ ___|_   _|_
\ \/ / |     | |_| |_
 >  <| |___  | |_   _|
/_/\_\\____| |_| |_|
World of Warcraft (4.3)
Author: Dandruff
]]
local core = KPack
if not core then return end
core:AddModule("xCT", "Replacement addon for Blizzard’s scrolling combat text.", function(L)
	if core:IsDisabled("xCT") then return end

	-- lua api globals
	local floor = math.floor
	local random = math.random
	local select = select
	local pairs = pairs
	local unpack = unpack
	local time = time
	local strfind = string.find
	local strlower = string.lower
	local _

	-- wow api globals
	local CreateFrame = CreateFrame
	local GetSpellTexture, GetSpellInfo = GetSpellTexture, GetSpellInfo
	local UnitGUID, UnitName, UnitClass = UnitGUID, UnitName, UnitClass
	local UnitHasVehicleUI = UnitHasVehicleUI
	local UnitHealth, UnitHealthMax = UnitHealth, UnitHealthMax
	local UnitPowerType = UnitPowerType
	local UnitPower, UnitPowerMax = UnitPower, UnitPowerMax
	local gflags = nil

	-- xCT internal color Printer for debug and such
	local pr = function(msg)
		core:Print(tostring(msg), "|cffFF0000x|rCT|cffddff55+|r")
	end

	local ct = {
		myname = select(1, UnitName("player")),
		myclass = select(2, UnitClass("player")),

		-- --------------------------------------------------------------------------------------
		-- Blizzard Damage Options.
		-- --------------------------------------------------------------------------------------
		-- Use Blizzard Damage/Healing Output (Numbers Above Mob/Player's Head)
		blizzheadnumbers = false, -- (You need to restart WoW to see changes!)

		-- "Everything else" font size (heals/interrupts and the like)
		fontsize = 16,
		font = "Interface\\Addons\\KPack\\Media\\Fonts\\yanone.ttf",

		-- --------------------------------------------------------------------------------------
		-- xCT+ Frames
		-- --------------------------------------------------------------------------------------

		-- Allow mouse scrolling on ALL frames (recommended "false")
		scrollable = false,
		-- Max lines to keep in scrollable mode.
		-- More lines = more Memory Nom nom nom
		maxlines = 64,

		-- ==================================================================================
		-- Healing/Damage Outing Frame (frame is called "xCTdone")
		-- ==================================================================================
		damageout = true, -- show outgoing damage
		healingout = true, -- show outgoing heals

		-- Filter Units/Periodic Spells
		petdamage = true, -- show your pet damage.
		dotdamage = true, -- show DoT damage
		showhots = true, -- show periodic healing effects in xCT healing frame.
		showimmunes = true, -- show "IMMUNE"s when you or your target cannot take damage or healing
		hideautoattack = false, -- Hides the auto attack icon from outgoing frame

		-- Damage/Healing Icon Sizes and Appearence
		damagecolor = true, -- display colored damage numbers by type
		icons = true, -- show outgoing damage icons
		iconsize = 16, -- outgoing damage icons' size
		damagefontsize = 16,
		fontstyle = "OUTLINE", -- valid options are "OUTLINE", "MONOCHROME", "THICKOUTLINE", "OUTLINE,MONOCHROME", "THICKOUTLINE,MONOCHROME"
		damagefont = "Interface\\Addons\\KPack\\Media\\Fonts\\yanone.ttf",

		-- Damage/Healing Minimum Value threshold
		treshold = 1, -- minimum value for outgoing damage
		healtreshold = 1, -- minimum value for outgoing heals


		-- ==================================================================================
		-- Incming Healing Frame (frame is called "xCTheal")
		-- ==================================================================================
		healwindow = true,

		-- ==================================================================================
		-- Critical Damage/Healing Outging Frame (frame is called "xCTcrit")
		-- ==================================================================================
		critwindow = false,

		-- Critical Icon Sizes
		criticons = true, -- show crit icons
		criticonsize = 14, -- size of the icons in the crit frame

		-- Critical Custom Font and Format
		critfont = "Interface\\Addons\\KPack\\Media\\Fonts\\yanone.ttf",
		critfontstyle = "OUTLINE",
		critfontsize = 22, -- crit font size ("auto" or Number)

		-- Critical Appearance Options
		critprefix = "|cffFF0000*|r", -- prefix symbol shown before crit'd amount (default: red *)
		critpostfix = "|cffFF0000*|r", -- postfix symbol shown after crit'd amount (default: red *)

		-- Filter Criticals
		filtercrits = false, -- Allows you to turn on a list that will filter out buffs
		crits_blacklist = false, -- Filter list is a blacklist (If you want a TRUE whitelist, don't forget to hide Swings too!!)
		showswingcrits = true, -- Allows you to show/hide (true / false) swing criticals
		showasnoncrit = true, -- When a spell it filtered, show it in the non Critical window (with critical pre/post-fixes)

		-- ==================================================================================
		-- Loot Items/Money Gains (frame is called "xCTloot")
		-- ==================================================================================
		lootwindow = true, -- Enable the frame "xCTloot" (use instead of "xCTgen" for Loot/Money)

		-- What to show in "xCTloot"
		lootitems = true,
		lootmoney = true,

		-- Item Options
		loothideicons = false, -- hide item icons when looted
		looticonsize = 20, -- Icon size of looted, crafted and quest items
		itemstotal = true, -- show the total amount of items in bag ("[Epic Item Name]x1 (x23)") - This is currently bugged and inacurate

		-- Item/Money Filter
		crafteditems = nil, -- show crafted items ( nil = default, false = always hide, true = always show)
		questitems = nil, -- show quest items ( nil = default, false = always hide, true = always show)
		itemsquality = 3, -- filter items shown by item quality: 0 = Poor, 1 = Common, 2 = Uncommon, 3 = Rare, 4 = Epic, 5 = Legendary, 6 = Artifact, 7 = Heirloom
		minmoney = 0, -- filter money received events, less than this amount (4G 32S 12C = 43212)

		-- Item/Money Appearance
		colorblind = false, -- shows letters G, S, and C instead of textures

		-- ==================================================================================
		-- Spell / Ability Procs Frame (frame is called "xCTproc")
		-- ==================================================================================
		-- NOTE: This only has the ability to show only procs that blizzards sends to it
		--       (mostly spells that "light up" and some others too).
		procwindow = false, -- Enable the frame to show Procs

		-- Proc Frame Custom Font Options
		procfont = "Interface\\Addons\\KPack\\Media\\Fonts\\yanone.ttf",
		procfontsize = 16, -- proc font size ("auto" or Number)
		procfontstyle = "OUTLINE",

		-- ==================================================================================
		-- Power Gains/Fades Incoming Frame (frame is called "xCTpwr")
		-- ==================================================================================
		powergainswindow = false, -- Enable the frame to show Auras

		-- Filter Auras Gains or Fades
		showharmfulaura = true, -- Show Harmful Auras (Gains and Losses)
		showhelpfulaura = true, -- Show Helpful Auras (Gains and Losses)
		showgains = true, -- Show Gains in the Aura frame
		showfades = true, -- Show Fades in the Aura frame
		filteraura = true, -- allows you to filter out unwanted aura gains/losses
		aura_blacklist = true, -- aura list is a blacklist (opposed to a whitelist)

		-- Filter Aura Helpers
		debug_aura = false, -- Shows your Aura's names in the chatbox.  Useful when adding to the filter yourself.
		-- __________________________________________________________________________________

		-- --------------------------------------------------------------------------------------
		-- xCT+ Frames' Justification
		-- --------------------------------------------------------------------------------------
		-- Justification Options: "RIGHT", "LEFT", "CENTER"
		justify_1 = "LEFT", -- Damage Incoming Frame (frame is called "xCTdmg")
		justify_2 = "RIGHT", -- Healing Incoming Frame (frame is called "xCTheal")
		justify_3 = "CENTER", -- General Buffs Gains/Drops Frame (frame is called "xCTgen")
		justify_4 = "RIGHT", -- Healing/Damage Outgoing Frame (frame is called "xCTdone")
		justify_5 = "CENTER", -- Loot/Money Gains Frame (frame is called "xCTloot")
		justify_6 = "LEFT", -- Criticals Outgoing Frame (frame is called "xCTcrit")
		justify_7 = "LEFT", -- Power Gains Frame (frame is called "xCTpwr")
		justify_8 = "CENTER", -- Procs Frame (frame is called "xCTproc")

		-- --------------------------------------------------------------------------------------
		-- xCT+ Class Specific and Misc. Options
		-- --------------------------------------------------------------------------------------
		-- Priest
		stopvespam = true, -- Hides Healing Spam for Priests in Shadowform.

		-- Death Knight
		dkrunes = false, -- Show Death Knight Rune Recharge
		mergedualwield = true, -- Merge dual wield damage

		-- Misc.
		-- Spell Spam Spam Spam Spam Spam Spam Spam Spam
		mergeaoespam = true, -- Merges multiple AoE spam into single message, can be useful for dots too.
		mergeaoespamtime = 0.1, -- Time in seconds AoE spell will be merged into single message.  Minimum is 1.
		mergethreshold = 0.1, -- (c) Merfin

		-- Helpful Alerts (Shown in the Gerenal Gains/Drops Frame)
		killingblow = false, -- Alerts with the name of the PC/NPC that you had a killing blow on (Req. damageout = true)
		dispel = true, -- Alerts with the name of the (De)Buff Dispelled (Req. damageout = true)
		interrupt = true, -- Alerts with the name of the Spell Interupted (Req. damageout = true)

		-- Alignment Help (Shown when configuring frames)
		showgrid = true, -- shows a grid when moving xCT windows around

		-- Show Procs
		filterprocs = true -- Enable to hide procs from ALL frames (will show in xCTproc or xCTgen otherwise)
	}

	--[[

	Filter Auras
	Allows you to filter auras (by name only). Some settings that affect this filter:

	ct.aura_blacklist - changes the following list to be a blacklist or white list

	Examples: ct.auranames["Chronohunter"]  = true
	]]

	if ct.filteraura then
		ct.auranames = {}
	end

	--[[
	Filter Criticals
	Allows you to filter out certain criticals and have them show in the regular damage
	frame.

	Some settings that affect this:
	ct.filtercrits     -  Allows you to turn on a list that will filter out buffs
	ct.crits_blacklist -  This list is a blacklist (opposed to a whitelist)
	ct.showswingcrits  -  Allows you to show/hide (true / false) swing criticals

	Examples: ct.critfilter[# Spell ID] = true
	]]

	if ct.filtercrits then
		ct.critfilter = {}
		ct.critfilter[3044] = true -- Arcane Shot
	end

	--[[
	Filter Outgoing Heals (For Spammy Heals)
	See class-specific config for filtered spells.
	]]

	if ct.healingout then
		ct.healfilter = {}
	end

	--[[
	Merge Outgoing Damage (For Spammy Damage)
	See class-specific config for merged spells.
	]]

	if ct.mergeaoespam then
		ct.aoespam = {}
	end

	--[[ Class Specific Filter Assignment ]]
	if ct.myclass == "WARLOCK" then
		if ct.mergeaoespam then
			ct.aoespam[47834] = true -- Seed of Corruption (Explosion)
			ct.aoespam[348] = true -- Immolate
			ct.aoespam[47818] = true -- Rain of Fire
			ct.aoespam[47822] = true -- Hellfire Effect
			ct.aoespam[61291] = true -- Shadowflame (shadow direct damage)
			ct.aoespam[61290] = true -- Shadowflame (fire dot)
			ct.aoespam[50590] = true -- Immolation Aura
			ct.aoespam[47994] = true -- Cleave (Felguard)
		end
		if ct.healingout then
			ct.healfilter[47893] = true -- Fel Armor
			ct.healfilter[63106] = true -- Siphon Life
			ct.healfilter[54181] = true -- Fel Synergy
			ct.healfilter[47857] = true -- Drain Life
		end
		if ct.filtercrits then
		end

	elseif ct.myclass == "DRUID" then
		if ct.mergeaoespam then
			ct.aoespam[48466] = true -- Hurricane
			ct.aoespam[50288] = true -- Starfall
			ct.aoespam[53227] = true -- Typhoon
			ct.aoespam[62078] = true -- Swipe (Cat Form)
			ct.aoespam[48562] = true -- Swipe (Bear Form)
		end
		if ct.healingout then
			ct.aoespam[48438] = true -- Wild Growth
			ct.aoespam[48445] = true -- Tranquility
		end
		if ct.filtercrits then
		end

	elseif ct.myclass == "PALADIN" then
		if ct.mergeaoespam then
			ct.aoespam[48819] = true -- Consecration
			ct.aoespam[2812] = true -- Holy Wrath
			ct.aoespam[53385] = true -- Divine Storm
			ct.aoespam[20424] = true -- Seals of Command
			ct.aoespam[53595] = true -- Hammer of the Righteous
			ct.aoespam[31935] = true -- Avenger's Shield
		end

		if ct.healingout then
			ct.aoespam[54172] = true -- Divinge Storm
		end

		if ct.filtercrits then
		end

	elseif ct.myclass == "PRIEST" then
		if ct.mergeaoespam then
			ct.aoespam[48078] = true -- Holy Nova (Damage Effect)
			ct.aoespam[53022] = true -- Mind Seer
		end
		if ct.healingout then
			ct.healfilter[15290] = true -- Vampiric Embrace
		end
		if ct.filtercrits then
		end

	elseif ct.myclass == "SHAMAN" then
		if ct.mergeaoespam then
			ct.aoespam[49271] = true -- Chain Lightning
			ct.aoespam[45297] = 49271 -- Chain Lightning - Elemental Overload
			ct.aoespam[61654] = true -- Fire Nova
			ct.aoespam[59159] = true -- Thunderstorm
			ct.aoespam[58735] = true -- Magma Totem
			ct.aoespam[25504] = true -- Windfury
		end
		if ct.healingout then
			ct.aoespam[55459] = true -- Chain Heal
			ct.aoespam[52042] = true -- Healing Stream Totem
			ct.aoespam[52000] = true -- Earthliving
			ct.aoespam[61295] = true -- Riptide (Instant & HoT)
		end
		if ct.filtercrits then
		end

	elseif ct.myclass == "MAGE" then
		if ct.mergeaoespam then
			ct.aoespam[27086] = true -- Flamestrike (Rank 7)
			ct.aoespam[42925] = true -- Flamestrike (Rank 8)
			ct.aoespam[42926] = true -- Flamestrike (Rank 9)
			ct.aoespam[42950] = true -- Dragon's Breath
			ct.aoespam[42938] = true -- Blizzard
			ct.aoespam[42917] = true -- Frost Nova
			ct.aoespam[42921] = true -- Arcane Explosion
			ct.aoespam[42945] = true -- Blast Wave       (Thanks Shestak)
			ct.aoespam[42931] = true -- Cone of Cold     (Thanks Shestak)
		end
		if ct.filtercrits then
		end

	elseif ct.myclass == "WARRIOR" then
		if ct.mergeaoespam then
			ct.aoespam[47520] = true -- Cleave
			ct.aoespam[46968] = true -- Shockwave
			ct.aoespam[47502] = true -- Thunder Clap
			ct.aoespam[50622] = true -- Bladestorm (Whirlwind)
			ct.aoespam[1680] = true -- Whirlwind
			ct.aoespam[12721] = true -- Deep Wounds
		end
		if ct.healingout then
			ct.healfilter[23880] = true -- Bloodthirst
			ct.healfilter[55694] = true -- Enraged Regeneration
		end
		if ct.filtercrits then
		end
	elseif ct.myclass == "HUNTER" then
		if ct.mergeaoespam then
			ct.aoespam[49048] = true -- Multi-Shot
			ct.aoespam[49065] = true -- Explosive Trap
		end
		if ct.filtercrits then
		end
	elseif ct.myclass == "DEATHKNIGHT" then
		if ct.mergeaoespam then
			ct.aoespam[55262] = true -- Heart Strike
			ct.aoespam[55095] = true -- Frost Fever
			ct.aoespam[55078] = true -- Blood Plague
			ct.aoespam[49941] = true -- Blood Boil
			ct.aoespam[52212] = true -- Death and Decay
			ct.aoespam[50526] = true -- Wondering Plague

			if ct.mergedualwield then
				ct.aoespam[55050] = true --  Heart Strike
				ct.aoespam[49020] = true --    Obliterate MH
				ct.aoespam[66198] = 49020 --    Obliterate OH
				ct.aoespam[49998] = true --  Death Strike MH
				ct.aoespam[66188] = 49998 --  Death Strike OH
				ct.aoespam[45462] = true -- Plague Strike MH
				ct.aoespam[66216] = 45462 -- Plague Strike OH
				ct.aoespam[49143] = true --  Frost Strike MH
				ct.aoespam[66196] = 49143 --  Frost Strike OH
				ct.aoespam[56815] = true --   Rune Strike MH
				ct.aoespam[66217] = 56815 --   Rune Strike OH
				ct.aoespam[45902] = true --  Blood Strike MH
				ct.aoespam[66215] = 45902 --  Blood Strike OH
			end
		end
		if ct.healingout then
			ct.healfilter[50475] = true -- Blood Presence
		end
		if ct.filtercrits then
		end

	elseif ct.myclass == "ROGUE" then
		if ct.mergeaoespam then
			ct.aoespam[51723] = true -- Fan of Knives (H1)
			ct.aoespam[52874] = true -- Fan of Knives (H2)
			ct.aoespam[57970] = true -- Deadly Poison
			ct.aoespam[57965] = true -- Instant Poison
		end
		if ct.filtercrits then
		end
	end

	if ct.mergeaoespam then
		ct.aoespam[56488] = true -- Global Sapper Charge (Explosion)
		ct.aoespam[56350] = true -- Saronite Bomb (Explosion)
	end

	--[[  Role Specific Filter Assignment  ]]
	-- Healers
	if ct.myclass == "DRUID" or ct.myclass == "PRIEST" or ct.myclass == "SHAMAN" or ct.myclass == "PALADIN" then
	end

	--[[  Defining the Frames  ]]
	local framenames = {"dmg", "gen"} -- Default frames (Always enabled)
	local numf = #framenames -- Number of Frames

	--[[  Extra Frames  ]]
	-- Add window for separate damage and healing windows
	if ct.damageout or ct.healingout then
		numf = numf + 1 -- 3
		framenames[numf] = "done"
	end

	-- Add window for incoming heal
	if ct.healwindow then
		numf = numf + 1 -- 4
		framenames[numf] = "heal"
	end

	-- Add window for loot events
	if ct.lootwindow then
		numf = numf + 1 -- 5
		framenames[numf] = "loot"
	end

	-- Add window for crit events
	if ct.critwindow then
		numf = numf + 1 -- 6
		framenames[numf] = "crit"
	end

	-- Add a window for power gains
	if ct.powergainswindow then
		numf = numf + 1 -- 7
		framenames[numf] = "pwr"
	end

	-- Add a window for procs
	if ct.procwindow then
		numf = numf + 1 -- 8
		framenames[numf] = "proc"
	end

	--[[  Overload Blizzard's GetSpellTexture so that I can get "Text" instead of an Image.  ]]
	local GetSpellTextureFormatted = function(spellID, iconSize)
		local msg = ""
		if ct.texticons then
			if spellID == PET_ATTACK_TEXTURE then
				msg = " [" .. GetSpellInfo(5547) .. "] " -- "Swing"
			else
				local name = GetSpellInfo(spellID)
				if name then
					msg = " [" .. name .. "] "
				else
					pr(L:F("No Name SpellID: %s", spellID))
				end
			end
		else
			if spellID == PET_ATTACK_TEXTURE then
				msg = " \124T" .. PET_ATTACK_TEXTURE .. ":" .. iconSize .. ":" .. iconSize .. ":0:0:64:64:5:59:5:59\124t"
			else
				local _, _, icon = GetSpellInfo(spellID)
				if icon then
					msg = " \124T" .. icon .. ":" .. iconSize .. ":" .. iconSize .. ":0:0:64:64:5:59:5:59\124t"
				else
					msg = " \124T" .. ct.blank .. ":" .. iconSize .. ":" .. iconSize .. ":0:0:64:64:5:59:5:59\124t"
				end
			end
		end
		return msg
	end

	-- Sanity Check:
	-- If "ct.texticons" are enabled, I need to enable "ct.icons" incase
	-- the user has it disabled
	if ct.texticons then ct.icon = true end

	--[[  Spam Merger  ]]
	local SQ
	-- Yep, that's the spell merger

	--[[
	Change Player Unit
	Allows you to change the Player's unit.
	This is in case you get in a vehicle and you want to
	recieve damage combat text from the vehicle.
	]]
	local function SetUnit()
		ct.unit = UnitHasVehicleUI("player") and "vehicle" or "player"
		CombatTextSetActiveUnit(ct.unit)
	end

	--[[  Limit Lines (Memory Optimizer)  ]]
	local function LimitLines()
		for i = 1, #ct.frames do
			local f = ct.frames[i]
			f:SetMaxLines(f:GetHeight() / ct.fontsize)
		end
	end

	--[[ Scrollable Frames - Not recommended ]]
	local function SetScroll()
		for i = 1, #ct.frames do
			ct.frames[i]:EnableMouseWheel(true)
			ct.frames[i]:SetScript("OnMouseWheel", function(self, delta)
				if delta > 0 then
					self:ScrollUp()
				elseif delta < 0 then
					self:ScrollDown()
				end
			end)
		end
	end

	--[[
	Align Grid
	Uses resources until UI Reset, but is loaded on demand
	]]
	local AlignGrid
	local function AlignGridShow()
		if not AlignGrid then
			AlignGrid = CreateFrame("Frame", nil, UIParent)
			AlignGrid:SetAllPoints(UIParent)
			local boxSize = 32

			-- Get the current screen resolution, Mid-points, and the total number of lines
			local ResX, ResY = GetScreenWidth(), GetScreenHeight()
			local midX, midY = ResX / 2, ResY / 2
			local iLinesLeftRight, iLinesTopBottom = midX / boxSize, midY / boxSize

			-- Vertical Bars
			for i = 1, iLinesLeftRight do
				-- Vertical Bars to the Left of the Center
				local tt1 = AlignGrid:CreateTexture(nil, "TOOLTIP")
				if i % 4 == 0 then
					tt1:SetTexture(.3, .3, .3, .8)
				elseif i % 2 == 0 then
					tt1:SetTexture(.1, .1, .1, .8)
				else
					tt1:SetTexture(0, 0, 0, .8)
				end
				tt1:SetPoint("TOP", AlignGrid, "TOP", -i * boxSize, 0)
				tt1:SetPoint("BOTTOM", AlignGrid, "BOTTOM", -i * boxSize, 0)
				tt1:SetWidth(1)

				-- Vertical Bars to the Right of the Center
				local tt2 = AlignGrid:CreateTexture(nil, "TOOLTIP")
				if i % 4 == 0 then
					tt2:SetTexture(.3, .3, .3, .8)
				elseif i % 2 == 0 then
					tt2:SetTexture(.1, .1, .1, .8)
				else
					tt2:SetTexture(0, 0, 0, .8)
				end
				tt2:SetPoint("TOP", AlignGrid, "TOP", i * boxSize + 1, 0)
				tt2:SetPoint("BOTTOM", AlignGrid, "BOTTOM", i * boxSize + 1, 0)
				tt2:SetWidth(1)
			end

			-- Horizontal Bars
			for i = 1, iLinesTopBottom do
				-- Horizontal Bars to the Below of the Center
				local tt3 = AlignGrid:CreateTexture(nil, "TOOLTIP")
				if i % 4 == 0 then
					tt3:SetTexture(.3, .3, .3, .8)
				elseif i % 2 == 0 then
					tt3:SetTexture(.1, .1, .1, .8)
				else
					tt3:SetTexture(0, 0, 0, .8)
				end
				tt3:SetPoint("LEFT", AlignGrid, "LEFT", 0, -i * boxSize + 1)
				tt3:SetPoint("RIGHT", AlignGrid, "RIGHT", 0, -i * boxSize + 1)
				tt3:SetHeight(1)

				-- Horizontal Bars to the Above of the Center
				local tt4 = AlignGrid:CreateTexture(nil, "TOOLTIP")
				if i % 4 == 0 then
					tt4:SetTexture(.3, .3, .3, .8)
				elseif i % 2 == 0 then
					tt4:SetTexture(.1, .1, .1, .8)
				else
					tt4:SetTexture(0, 0, 0, .8)
				end
				tt4:SetPoint("LEFT", AlignGrid, "LEFT", 0, i * boxSize)
				tt4:SetPoint("RIGHT", AlignGrid, "RIGHT", 0, i * boxSize)
				tt4:SetHeight(1)
			end

			--Create the Vertical Middle Bar
			local tta = AlignGrid:CreateTexture(nil, "TOOLTIP")
			tta:SetTexture(1, 0, 0, .6)
			tta:SetPoint("TOP", AlignGrid, "TOP", 0, 0)
			tta:SetPoint("BOTTOM", AlignGrid, "BOTTOM", 0, 0)
			tta:SetWidth(2)

			--Create the Horizontal Middle Bar
			local ttb = AlignGrid:CreateTexture(nil, "TOOLTIP")
			ttb:SetTexture(1, 0, 0, .6)
			ttb:SetPoint("LEFT", AlignGrid, "LEFT", 0, 0)
			ttb:SetPoint("RIGHT", AlignGrid, "RIGHT", 0, 0)
			ttb:SetHeight(2)
		else
			AlignGrid:Show()
		end
	end

	local function AlignGridKill()
		AlignGrid:Hide()
	end

	--[[  Loot and Money Parsing  ]]
	-- RegEx String for Loot Items
	local parseloot = "([^|]*)|cff(%x*)|H[^:]*:(%d+):[-?%d+:]+|h%[?([^%]]*)%]|h|r?%s?x?(%d*)%.?"

	-- Loot Event Handlers
	local function ChatMsgMoney_Handler(msg)
		local g, s, c = tonumber(msg:match(GOLD_AMOUNT:gsub("%%d", "(%%d+)"))), tonumber(msg:match(SILVER_AMOUNT:gsub("%%d", "(%%d+)"))), tonumber(msg:match(COPPER_AMOUNT:gsub("%%d", "(%%d+)")))
		local money, o = (g and g * 10000 or 0) + (s and s * 100 or 0) + (c or 0), MONEY .. ": "
		if money >= ct.minmoney then
			if ct.colorblind then
				o = o .. (g and g .. " G " or "") .. (s and s .. " S " or "") .. (c and c .. " C " or "")
			else
				o = o .. GetCoinTextureString(money) .. " "
			end
			if msg:find("share") then
				o = o .. "(split)"
			end
			(xCTloot or xCTgen):AddMessage(o, 1, 1, 0) -- yellow
		end
	end

	local function ChatMsgLoot_Handler(msg)
		local pM, iQ, iI, iN, iA = select(3, strfind(msg, parseloot)) -- Pre-Message, ItemColor, ItemID, ItemName, ItemAmount
		local qq, _, _, tt, _, _, _, ic = select(3, GetItemInfo(iI)) -- Item Quality, See "GetAuctionItemClasses()", Item Icon Texture Location

		local item = {}
		item.name = iN
		item.id = iI
		item.amount = tonumber(iA) or 1
		item.quality = qq
		item.type = tt
		item.icon = ic
		item.crafted = (pM == LOOT_ITEM_CREATED_SELF:gsub("%%.*", ""))
		item.self = (pM == LOOT_ITEM_PUSHED_SELF:gsub("%%.*", "") or pM == LOOT_ITEM_SELF:gsub("%%.*", "") or pM == LOOT_ITEM_CREATED_SELF:gsub("%%.*", ""))

		if (ct.lootitems and item.self and item.quality >= ct.itemsquality) or (item.type == "Quest" and ct.questitems and item.self) or (item.crafted and ct.crafteditems) then
			if item.crafted and ct.crafteditems == false then
				return
			end
			if item.type == "Quest" and ct.questitems == false then
				return
			end

			local r, g, b = GetItemQualityColor(item.quality)
			local s = item.type .. ": [" .. item.name .. "] "
			if ct.colorblind then
				s = item.type .. " (" .. _G["ITEM_QUALITY" .. item.quality .. "_DESC"] .. "): [" .. item.name .. "] "
			end

			-- Add the Texture
			if not ct.loothideicons then
				s = s .. "\124T" .. item.icon .. ":" .. ct.looticonsize .. ":" .. ct.looticonsize .. ":0:0:64:64:5:59:5:59\124t"
			end

			-- Amount Looted
			s = s .. " x " .. item.amount

			-- Total items in bag
			if ct.itemstotal then
				s = s .. "   (" .. (GetItemCount(item.id)) .. ")" -- buggy AS HELL :\
			end

			-- Add the message
			(xCTloot or xCTgen):AddMessage(s, r, g, b)
		end
	end

	-- Partial Resist Styler (Format String)
	local part = "-%s (%s %s)"
	local r, g, b

	-- Handlers for Combat Text and other incoming events.  Outgoing events are handled further down.
	local function OnEvent(self, event, subevent, ...)
		if event == "COMBAT_TEXT_UPDATE" then
			local arg2, arg3 = ...
			if SHOW_COMBAT_TEXT == "0" then return else
				if subevent == "DAMAGE" then
					xCTdmg:AddMessage("-" .. arg2, .75, .1, .1)
				elseif subevent == "DAMAGE_CRIT" then
					xCTdmg:AddMessage(ct.critprefix .. "-" .. arg2 .. ct.critpostfix, 1, .1, .1)
				elseif subevent == "SPELL_DAMAGE" then
					xCTdmg:AddMessage("-" .. arg2, .75, .3, .85)
				elseif subevent == "SPELL_DAMAGE_CRIT" then
					xCTdmg:AddMessage(ct.critprefix .. "-" .. arg2 .. ct.critpostfix, 1, .3, .5)
				elseif subevent == "HEAL" and xCTheal then
					if arg3 >= ct.healtreshold then
						if arg2 then
							if COMBAT_TEXT_SHOW_FRIENDLY_NAMES == "1" then
								xCTheal:AddMessage(arg2 .. " +" .. arg3, .1, .75, .1)
							else
								xCTheal:AddMessage("+" .. arg3, .1, .75, .1)
							end
						end
					end
				elseif subevent == "HEAL_CRIT" and xCTheal then
					if arg3 >= ct.healtreshold then
						if arg2 then
							if COMBAT_TEXT_SHOW_FRIENDLY_NAMES == "1" then
								xCTheal:AddMessage(arg2 .. " +" .. arg3, .1, 1, .1)
							else
								xCTheal:AddMessage("+" .. arg3, .1, 1, .1)
							end
						end
					end
					return
				elseif subevent == "PERIODIC_HEAL" and xCTheal then
					if arg3 >= ct.healtreshold then
						xCTheal:AddMessage("+" .. arg3, .1, .5, .1)
					end
				elseif subevent == "SPELL_CAST" then
					if not ct.filterprocs then
						(xCTproc or xCTgen):AddMessage(arg2, 1, .82, 0)
					end
				elseif subevent == "MISS" and COMBAT_TEXT_SHOW_DODGE_PARRY_MISS == "1" then
					xCTdmg:AddMessage(MISS, .5, .5, .5)
				elseif subevent == "DODGE" and COMBAT_TEXT_SHOW_DODGE_PARRY_MISS == "1" then
					xCTdmg:AddMessage(DODGE, .5, .5, .5)
				elseif subevent == "PARRY" and COMBAT_TEXT_SHOW_DODGE_PARRY_MISS == "1" then
					xCTdmg:AddMessage(PARRY, .5, .5, .5)
				elseif subevent == "EVADE" and COMBAT_TEXT_SHOW_DODGE_PARRY_MISS == "1" then
					xCTdmg:AddMessage(EVADE, .5, .5, .5)
				elseif subevent == "IMMUNE" and COMBAT_TEXT_SHOW_DODGE_PARRY_MISS == "1" then
					if not ct.showimmunes then
						return
					end
					if ct.mergeimmunespam then
						SQ[subevent]["locked"] = true
						SQ[subevent]["queue"] = IMMUNE
						SQ[subevent]["msg"] = ""
						SQ[subevent]["color"] = {.5, .5, .5}
						SQ[subevent]["count"] = SQ[subevent]["count"] + 1
						if SQ[subevent]["count"] == 1 then
							SQ[subevent]["utime"] = time()
						end
						SQ[subevent]["locked"] = false
						return
					else
						xCTdmg:AddMessage(IMMUNE, .5, .5, .5)
					end
				elseif subevent == "DEFLECT" and COMBAT_TEXT_SHOW_DODGE_PARRY_MISS == "1" then
					xCTdmg:AddMessage(DEFLECT, .5, .5, .5)
				elseif subevent == "REFLECT" and COMBAT_TEXT_SHOW_DODGE_PARRY_MISS == "1" then
					xCTdmg:AddMessage(REFLECT, .5, .5, .5)
				elseif subevent == "SPELL_MISS" and COMBAT_TEXT_SHOW_DODGE_PARRY_MISS == "1" then
					xCTdmg:AddMessage(MISS, .5, .5, .5)
				elseif subevent == "SPELL_DODGE" and COMBAT_TEXT_SHOW_DODGE_PARRY_MISS == "1" then
					xCTdmg:AddMessage(DODGE, .5, .5, .5)
				elseif subevent == "SPELL_PARRY" and COMBAT_TEXT_SHOW_DODGE_PARRY_MISS == "1" then
					xCTdmg:AddMessage(PARRY, .5, .5, .5)
				elseif subevent == "SPELL_EVADE" and COMBAT_TEXT_SHOW_DODGE_PARRY_MISS == "1" then
					xCTdmg:AddMessage(EVADE, .5, .5, .5)
				elseif subevent == "SPELL_IMMUNE" and COMBAT_TEXT_SHOW_DODGE_PARRY_MISS == "1" then
					if not ct.showimmunes then
						return
					end
					if ct.mergeimmunespam then
						SQ[subevent]["locked"] = true
						SQ[subevent]["queue"] = IMMUNE
						SQ[subevent]["msg"] = ""
						SQ[subevent]["color"] = {.5, .5, .5}
						SQ[subevent]["count"] = SQ[subevent]["count"] + 1
						if SQ[subevent]["count"] == 1 then
							SQ[subevent]["utime"] = time()
						end
						SQ[subevent]["locked"] = false
						return
					else
						xCTdmg:AddMessage(IMMUNE, .5, .5, .5)
					end
				elseif subevent == "SPELL_DEFLECT" and COMBAT_TEXT_SHOW_DODGE_PARRY_MISS == "1" then
					xCTdmg:AddMessage(DEFLECT, .5, .5, .5)
				elseif subevent == "SPELL_REFLECT" and COMBAT_TEXT_SHOW_DODGE_PARRY_MISS == "1" then
					xCTdmg:AddMessage(REFLECT, .5, .5, .5)
				elseif subevent == "RESIST" then
					if arg3 then
						if COMBAT_TEXT_SHOW_RESISTANCES == "1" then
							xCTdmg:AddMessage(part:format(arg2, RESIST, arg3), .75, .5, .5)
						else
							xCTdmg:AddMessage(arg2, .75, .1, .1)
						end
					elseif COMBAT_TEXT_SHOW_RESISTANCES == "1" then
						xCTdmg:AddMessage(RESIST, .5, .5, .5)
					end
				elseif subevent == "BLOCK" then
					if arg3 then
						if COMBAT_TEXT_SHOW_RESISTANCES == "1" then
							xCTdmg:AddMessage(part:format(arg2, BLOCK, arg3), .75, .5, .5)
						else
							xCTdmg:AddMessage(arg2, .75, .1, .1)
						end
					elseif COMBAT_TEXT_SHOW_RESISTANCES == "1" then
						xCTdmg:AddMessage(BLOCK, .5, .5, .5)
					end
				elseif subevent == "ABSORB" then
					if arg3 then
						if COMBAT_TEXT_SHOW_RESISTANCES == "1" then
							xCTdmg:AddMessage(part:format(arg2, ABSORB, arg3), .75, .5, .5)
						else
							xCTdmg:AddMessage(arg2, .75, .1, .1)
						end
					elseif COMBAT_TEXT_SHOW_RESISTANCES == "1" then
						xCTdmg:AddMessage(ABSORB, .5, .5, .5)
					end
				elseif subevent == "SPELL_RESIST" then
					if arg3 then
						if COMBAT_TEXT_SHOW_RESISTANCES == "1" then
							xCTdmg:AddMessage(part:format(arg2, RESIST, arg3), .5, .3, .5)
						else
							xCTdmg:AddMessage(arg2, .75, .3, .85)
						end
					elseif COMBAT_TEXT_SHOW_RESISTANCES == "1" then
						xCTdmg:AddMessage(RESIST, .5, .5, .5)
					end
				elseif subevent == "SPELL_BLOCK" then
					if arg3 then
						if COMBAT_TEXT_SHOW_RESISTANCES == "1" then
							xCTdmg:AddMessage(part:format(arg2, BLOCK, arg3), .5, .3, .5)
						else
							xCTdmg:AddMessage("-" .. arg2, .75, .3, .85)
						end
					elseif COMBAT_TEXT_SHOW_RESISTANCES == "1" then
						xCTdmg:AddMessage(BLOCK, .5, .5, .5)
					end
				elseif subevent == "SPELL_ABSORB" then
					if arg3 then
						if COMBAT_TEXT_SHOW_RESISTANCES == "1" then
							xCTdmg:AddMessage(part:format(arg2, ABSORB, arg3), .5, .3, .5)
						else
							xCTdmg:AddMessage(arg2, .75, .3, .85)
						end
					elseif COMBAT_TEXT_SHOW_RESISTANCES == "1" then
						xCTdmg:AddMessage(ABSORB, .5, .5, .5)
					end
				elseif subevent == "ENERGIZE" and COMBAT_TEXT_SHOW_ENERGIZE == "1" then
					if tonumber(arg2) > 0 then
						if
							arg3 and arg3 == "MANA" or arg3 == "RAGE" or arg3 == "FOCUS" or arg3 == "ENERGY" or
								arg3 == "RUNIC_POWER"
						 then
							(xCTpwr or xCTgen):AddMessage("+" .. arg2 .. " " .. _G[arg3], PowerBarColor[arg3].r, PowerBarColor[arg3].g, PowerBarColor[arg3].b)
						end
					end
				elseif subevent == "PERIODIC_ENERGIZE" and COMBAT_TEXT_SHOW_PERIODIC_ENERGIZE == "1" then
					if tonumber(arg2) > 0 then
						if arg3 and arg3 == "MANA" or arg3 == "RAGE" or arg3 == "FOCUS" or arg3 == "ENERGY" or arg3 == "RUNIC_POWER" then
							(xCTpwr or xCTgen):AddMessage("+" .. arg2 .. " " .. _G[arg3], PowerBarColor[arg3].r, PowerBarColor[arg3].g, PowerBarColor[arg3].b)
						end
					end
				elseif subevent == "SPELL_AURA_START" and COMBAT_TEXT_SHOW_AURAS == "1" then
					if ct.debug_aura then
						pr("AURA_S", arg2)
					end
					if not ct.showhelpfulaura then
						return
					end

					if ct.filteraura then
						if ct.auranames[arg2] and ct.aura_blacklist then
							return
						elseif not ct.aura_blacklist then
							return
						end
					end

					xCTgen:AddMessage("+" .. arg2, 1, .5, .5)
				elseif subevent == "SPELL_AURA_END" and COMBAT_TEXT_SHOW_AURAS == "1" then
					if ct.debug_aura then
						pr("AURA_E", arg2)
					end
					if not ct.showhelpfulaura then
						return
					end

					if ct.filteraura then
						if ct.auranames[arg2] and ct.aura_blacklist then
							return
						elseif not ct.aura_blacklist then
							return
						end
					end

					xCTgen:AddMessage("-" .. arg2, .5, .5, .5)
				elseif subevent == "HONOR_GAINED" and COMBAT_TEXT_SHOW_HONOR_GAINED == "1" then
					arg2 = tonumber(arg2)
					if arg2 and abs(arg2) > 1 then
						arg2 = floor(arg2)
						if arg2 > 0 then
							xCTgen:AddMessage(HONOR .. " +" .. arg2, .1, .1, 1)
						end
					end
				elseif subevent == "FACTION" and COMBAT_TEXT_SHOW_REPUTATION == "1" then
					xCTgen:AddMessage(arg2 .. " +" .. arg3, .1, .1, 1)
				elseif subevent == "SPELL_ACTIVE" and COMBAT_TEXT_SHOW_REACTIVES == "1" then
					xCTgen:AddMessage(arg2, 1, .82, 0)
				end
			end
		elseif event == "UNIT_HEALTH" and COMBAT_TEXT_SHOW_LOW_HEALTH_MANA == "1" then
			if subevent == ct.unit then
				if UnitHealth(ct.unit) / UnitHealthMax(ct.unit) <= COMBAT_TEXT_LOW_HEALTH_THRESHOLD then
					if not lowHealth then
						xCTgen:AddMessage(HEALTH_LOW, 1, .1, .1)
						lowHealth = true
					end
				else
					lowHealth = nil
				end
			end
		elseif event == "UNIT_MANA" and COMBAT_TEXT_SHOW_LOW_HEALTH_MANA == "1" then
			if subevent == ct.unit then
				local _, powerToken = UnitPowerType(ct.unit)
				if powerToken == "MANA" and UnitPower(ct.unit) / UnitPowerMax(ct.unit) <= COMBAT_TEXT_LOW_MANA_THRESHOLD then
					if not lowMana then
						xCTgen:AddMessage(MANA_LOW, 1, .1, .1)
						lowMana = true
					end
				else
					lowMana = nil
				end
			end
		elseif event == "PLAYER_REGEN_ENABLED" and COMBAT_TEXT_SHOW_COMBAT_STATE == "1" then
			xCTgen:AddMessage("-" .. LEAVING_COMBAT, .1, 1, .1)
		elseif event == "PLAYER_REGEN_DISABLED" and COMBAT_TEXT_SHOW_COMBAT_STATE == "1" then
			xCTgen:AddMessage("+" .. ENTERING_COMBAT, 1, .1, .1)
		elseif event == "UNIT_COMBO_POINTS" and COMBAT_TEXT_SHOW_COMBO_POINTS == "1" then
			if subevent == ct.unit then
				local cp = GetComboPoints(ct.unit, "target")
				if cp > 0 then
					r, g, b = 1, .82, .0
					if cp == MAX_COMBO_POINTS then
						r, g, b = 0, .82, 1
					end
					xCTgen:AddMessage(format(COMBAT_TEXT_COMBO_POINTS, cp), r, g, b)
				end
			end
		elseif event == "RUNE_POWER_UPDATE" then
			local arg1, arg2 = subevent, ...
			if arg2 then
				local rune = GetRuneType(arg1)
				local msg = COMBAT_TEXT_RUNE[rune]
				if rune == 1 then
					r, g, b = .75, 0, 0
				elseif rune == 2 then
					r, g, b = .75, 1, 0
				elseif rune == 3 then
					r, g, b = 0, 1, 1
				end
				if rune and rune < 4 then
					(xCTpwr or xCTgen):AddMessage("+" .. msg, r, g, b)
				end
			end
		elseif event == "UNIT_ENTERED_VEHICLE" or event == "UNIT_EXITING_VEHICLE" then
			if ... == "player" then
				SetUnit()
			end
		elseif event == "PLAYER_ENTERING_WORLD" then
			SetUnit()
			if ct.scrollable then
				SetScroll()
			else
				LimitLines()
			end
			if ct.damageout or ct.healingout then
				ct.pguid = UnitGUID("player")
			end
		elseif event == "CHAT_MSG_LOOT" then
			ChatMsgLoot_Handler(subevent)
		elseif event == "CHAT_MSG_MONEY" then
			ChatMsgMoney_Handler(subevent)
		end
	end

	--[[  Change Damage Font  ]]
	if ct.damagestyle then
		_G.DAMAGE_TEXT_FONT = ct.damageoutfont
	end

	--[[  Create the Frames  ]]
	ct.locked = true -- not configuring
	ct.frames = {} -- location to store the frames
	for i = 1, numf do
		local f = CreateFrame("ScrollingMessageFrame", "xCT" .. framenames[i], UIParent)
		f:SetFont(ct.font, ct.fontsize, ct.fontstyle)
		f:SetShadowColor(0, 0, 0, 0)
		f:SetTimeVisible(3)
		f:SetMaxLines(ct.maxlines)
		f:SetSpacing(2)
		f:SetWidth(128)
		f:SetHeight(128)
		f:SetPoint("CENTER", 0, 0)
		f:SetMovable(true)
		f:SetResizable(true)
		f:SetMinResize(64, 64)
		f:SetMaxResize(768, 768)
		f:SetUserPlaced(true)
		f:SetClampedToScreen(true)
		f:SetClampRectInsets(0, 0, ct.fontsize, 0)
		if framenames[i] == "dmg" then
			f:SetJustifyH(ct.justify_1)
			f:SetPoint("CENTER", -320, 0)
		elseif framenames[i] == "heal" then
			f:SetJustifyH(ct.justify_2)
			f:SetPoint("CENTER", -512, 0)
			f:SetWidth(256)
		elseif framenames[i] == "gen" then
			f:SetJustifyH(ct.justify_3)
			f:SetWidth(256)
			f:SetPoint("CENTER", 0, 192)
		elseif framenames[i] == "done" then
			f:SetJustifyH(ct.justify_4)
			f:SetPoint("CENTER", 320, 0)
			local a, _, c = f:GetFont()
			if type(ct.damagefontsize) == "number" then
				f:SetFont(ct.damagefont, ct.damagefontsize, ct.fontstyle)
			else
				if ct.icons then
					if ct.texticons then
						f:SetFont(a, ct.iconsize, c)
					else
						f:SetFont(a, ct.iconsize / 2, c)
					end
				end
			end
		elseif framenames[i] == "loot" then
			f:SetJustifyH(ct.justify_5)
			f:SetWidth(256)
			f:SetPoint("CENTER", 0, -192)
		elseif framenames[i] == "crit" then
			f:SetJustifyH(ct.justify_6)
			f:SetWidth(256)
			f:SetPoint("CENTER", 128, 0)
			if type(ct.critfontsize) == "number" then
				f:SetFont(ct.critfont, ct.critfontsize, ct.critfontstyle)
			else
				if ct.criticons then
					if ct.texticons then
						f:SetFont(ct.critfont, ct.criticonsize, ct.critfontstyle)
					else
						f:SetFont(ct.critfont, ct.criticonsize / 2, ct.critfontstyle)
					end
				end
			end
		elseif framenames[i] == "pwr" then
			f:SetJustifyH(ct.justify_7)
			f:SetPoint("CENTER", 512, 0)
			f:SetWidth(256)
		elseif framenames[i] == "proc" then
			f:SetJustifyH(ct.justify_8)
			f:SetWidth(256)
			f:SetPoint("CENTER", -128, 0)
			f:SetFont(ct.procfont, ct.procfontsize, ct.procfontstyle)
		end
		ct.frames[i] = f
	end

	-- register events
	local xCT = CreateFrame("Frame")
	xCT:RegisterEvent("COMBAT_TEXT_UPDATE")
	xCT:RegisterEvent("UNIT_HEALTH")
	xCT:RegisterEvent("UNIT_MANA")
	xCT:RegisterEvent("PLAYER_REGEN_DISABLED")
	xCT:RegisterEvent("PLAYER_REGEN_ENABLED")
	xCT:RegisterEvent("UNIT_COMBO_POINTS")
	xCT:RegisterEvent("UNIT_ENTERED_VEHICLE")
	xCT:RegisterEvent("UNIT_EXITING_VEHICLE")
	xCT:RegisterEvent("PLAYER_ENTERING_WORLD")

	-- Register DK Events
	if ct.dkrunes and select(2, UnitClass("player")) == "DEATHKNIGHT" then
		xCT:RegisterEvent("RUNE_POWER_UPDATE")
	end

	-- Register Loot Events
	if ct.lootitems or ct.questitems or ct.crafteditems then
		xCT:RegisterEvent("CHAT_MSG_LOOT")
	end

	-- Register Money Events
	if ct.lootmoney then
		xCT:RegisterEvent("CHAT_MSG_MONEY")
	end

	xCT:SetScript("OnEvent", OnEvent)

	-- Blizzard Damage/Healing Head Anchors
	if not ct.blizzheadnumbers then
		-- Move the options up
		local defaultFont, defaultSize = InterfaceOptionsCombatTextPanelTargetEffectsText:GetFont()

		InterfaceOptionsCombatTextPanelEnableFCT:ClearAllPoints()
		InterfaceOptionsCombatTextPanelEnableFCT:SetPoint("TOPLEFT", 18, -82)

		InterfaceOptionsCombatTextPanelTargetEffects:ClearAllPoints()
		InterfaceOptionsCombatTextPanelTargetEffects:SetPoint("TOPLEFT", 18, -280)

		-- Hide invalid Objects
		InterfaceOptionsCombatTextPanelTargetDamage:Hide()
		InterfaceOptionsCombatTextPanelPeriodicDamage:Hide()
		InterfaceOptionsCombatTextPanelPetDamage:Hide()
		InterfaceOptionsCombatTextPanelHealing:Hide()
		SetCVar("CombatLogPeriodicSpells", 0)
		SetCVar("PetMeleeDamage", 0)
		SetCVar("CombatDamage", 0)
		SetCVar("CombatHealing", 0)
	end

	-- Turn off Blizzard's Combat Text
	CombatText:UnregisterAllEvents()
	CombatText:SetScript("OnLoad", nil)
	CombatText:SetScript("OnEvent", nil)
	CombatText:SetScript("OnUpdate", nil)

	-- Direction does NOT work with xCT+ at all
	InterfaceOptionsCombatTextPanelFCTDropDown:Hide()

	-- Intercept Messages Sent by other Add-Ons that use CombatText_AddMessage
	_G.Blizzard_CombatText_AddMessage = CombatText_AddMessage
	function CombatText_AddMessage(message, scrollFunction, r, g, b, displayType, isStaggered)
		xCTgen:AddMessage(message, r, g, b)
	end

	-- Modify Blizzard's Combat Text Options Title  ("Powered by xCT+")
	InterfaceOptionsCombatTextPanelTitle:SetText(COMBAT_TEXT_LABEL .. " (powered by \124cffFF0000x\124rCT\124cffDDFF55+\124r)")

	-- Awesome Config and Test Modes
	local StartConfigmode = function()
		if not InCombatLockdown() then
			for i = 1, #ct.frames do
				local f = ct.frames[i]
				f:SetBackdrop({
					bgFile = "Interface/Tooltips/UI-Tooltip-Background",
					edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
					tile = false,
					tileSize = 0,
					edgeSize = 2,
					insets = {left = 0, right = 0, top = 0, bottom = 0}
				})
				f:SetBackdropColor(.1, .1, .1, .8)
				f:SetBackdropBorderColor(.1, .1, .1, .5)

				f.fs = f:CreateFontString(nil, "OVERLAY")
				f.fs:SetFont(ct.font, ct.fontsize, ct.fontstyle)
				f.fs:SetPoint("BOTTOM", f, "TOP", 0, 0)
				if framenames[i] == "dmg" then
					f.fs:SetText(DAMAGE)
					f.fs:SetTextColor(1, .1, .1, .9)
				elseif framenames[i] == "heal" then
					f.fs:SetText(SHOW_COMBAT_HEALING)
					f.fs:SetTextColor(.1, 1, .1, .9)
				elseif framenames[i] == "gen" then
					f.fs:SetText(COMBAT_TEXT_LABEL)
					f.fs:SetTextColor(.1, .1, 1, .9)
				elseif framenames[i] == "done" then
					f.fs:SetText(SCORE_DAMAGE_DONE .. " / " .. SCORE_HEALING_DONE)
					f.fs:SetTextColor(1, 1, 0, .9)
				elseif framenames[i] == "loot" then
					f.fs:SetText(LOOT)
					f.fs:SetTextColor(1, 1, 1, .9)
				elseif framenames[i] == "crit" then
					f.fs:SetText("crits")
					f.fs:SetTextColor(1, .5, 0, .9)
				elseif framenames[i] == "pwr" then
					f.fs:SetText("power gains")
					f.fs:SetTextColor(.8, .1, 1, .9)
				elseif framenames[i] == "proc" then
					f.fs:SetText("procs")
					f.fs:SetTextColor(1, .6, .3, .9)
				end

				f.t = f:CreateTexture("ARTWORK")
				f.t:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
				f.t:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -19)
				f.t:SetHeight(20)
				f.t:SetTexture(.5, .5, .5)
				f.t:SetAlpha(.3)

				f.d = f:CreateTexture("ARTWORK")
				f.d:SetHeight(16)
				f.d:SetWidth(16)
				f.d:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
				f.d:SetTexture(.5, .5, .5)
				f.d:SetAlpha(.3)

				f.tr = f:CreateTitleRegion()
				f.tr:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
				f.tr:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
				f.tr:SetHeight(20)

				-- font string Position (location)
				f.fsp = f:CreateFontString(nil, "OVERLAY")
				f.fsp:SetFont(ct.font, ct.fontsize, ct.fontstyle)
				f.fsp:SetPoint("TOPLEFT", f, "TOPLEFT", 3, -3)
				f.fsp:SetText("")
				f.fsp:Hide()

				-- font string width
				f.fsw = f:CreateFontString(nil, "OVERLAY")
				f.fsw:SetFont(ct.font, ct.fontsize, ct.fontstyle)
				f.fsw:SetPoint("BOTTOM", f, "BOTTOM", 0, 0)
				f.fsw:SetText("")
				f.fsw:Hide()

				-- font string height
				f.fsh = f:CreateFontString(nil, "OVERLAY")
				f.fsh:SetFont(ct.font, ct.fontsize, ct.fontstyle)
				f.fsh:SetPoint("LEFT", f, "LEFT", 3, 0)
				f.fsh:SetText("")
				f.fsh:Hide()

				local ResX, ResY = GetScreenWidth(), GetScreenHeight()
				local midX, midY = ResX / 2, ResY / 2

				f:SetScript("OnLeave", function(...)
					f:SetScript("OnUpdate", nil)
					f.fsp:Hide()
					f.fsw:Hide()
					f.fsh:Hide()
				end)
				f:SetScript("OnEnter", function(...)
					f:SetScript("OnUpdate", function(...)
						f.fsp:SetText(floor(f:GetLeft() - midX + 1) .. ", " .. floor(f:GetTop() - midY + 2))
						f.fsw:SetText(floor(f:GetWidth()))
						f.fsh:SetText(floor(f:GetHeight()))
					end)
					f.fsp:Show()
					f.fsw:Show()
					f.fsh:Show()
				end)

				f:EnableMouse(true)
				f:RegisterForDrag("LeftButton")
				f:SetScript("OnDragStart", f.StartSizing)
				if not ct.scrollable then
					f:SetScript("OnSizeChanged", function(self)
						self:SetMaxLines(self:GetHeight() / ct.fontsize)
						self:Clear()
					end)
				end

				f:SetScript("OnDragStop", f.StopMovingOrSizing)
				ct.locked = false
			end

			-- also show the align grid during config
			if ct.showgrid then
				AlignGridShow()
			end

			pr(L["unlocked."])
		else
			pr(ERR_NOT_IN_COMBAT)
		end
	end

	local function EndConfigmode()
		for i = 1, #ct.frames do
			f = ct.frames[i]
			f:SetBackdrop(nil)
			f.fs:Hide()
			f.fs = nil
			f.t:Hide()
			f.t = nil
			f.d:Hide()
			f.d = nil
			f.tr = nil
			f:EnableMouse(false)
			f:SetScript("OnDragStart", nil)
			f:SetScript("OnDragStop", nil)
		end
		ct.locked = true

		-- Kill align grid
		if ct.showgrid then
			AlignGridKill()
		end

		pr(L["Window positions unsaved, don't forget to reload UI."])
	end

	local function StartTestMode()
		local TimeSinceLastUpdate = 0
		local UpdateInterval
		if ct.damagecolor then
			ct.dmindex = {}
			ct.dmindex[1] = 1
			ct.dmindex[2] = 2
			ct.dmindex[3] = 4
			ct.dmindex[4] = 8
			ct.dmindex[5] = 16
			ct.dmindex[6] = 32
			ct.dmindex[7] = 64
		end

		local energies = {
			[0] = "MANA",
			[1] = "RAGE",
			[2] = "FOCUS",
			[3] = "ENERGY",
			[4] = "HAPPINESS",
			[5] = "RUNES",
			[6] = "RUNIC_POWER"
		}

		for i = 1, #ct.frames do
			ct.frames[i]:SetScript("OnUpdate", function(self, elapsed)
				UpdateInterval = random(65, 1000) / 250
				TimeSinceLastUpdate = TimeSinceLastUpdate + elapsed
				if TimeSinceLastUpdate > UpdateInterval then
					if framenames[i] == "dmg" then
						ct.frames[i]:AddMessage("-" .. random(100000), 1, random(255) / 255, random(255) / 255)
					elseif framenames[i] == "heal" then
						if COMBAT_TEXT_SHOW_FRIENDLY_NAMES == "1" and random(1, 2) % 2 == 0 then
							ct.frames[i]:AddMessage(UnitName("player") .. " +" .. random(50000), .1, random(128, 255) / 255, .1)
						else
							ct.frames[i]:AddMessage("+" .. random(50000), .1, random(128, 255) / 255, .1)
						end
					elseif framenames[i] == "gen" then
						ct.frames[i]:AddMessage(COMBAT_TEXT_LABEL, random(255) / 255, random(255) / 255, random(255) / 255)
					elseif framenames[i] == "done" then
						local msg = random(40000)
						local icon
						local color = {}
						if ct.icons then
							while not icon do
								local id = random(10000, 900000)
								_, _, icon = GetSpellInfo(id)
							end
						end
						if icon then
							msg = msg .. " \124T" .. icon .. ":" .. ct.iconsize .. ":" .. ct.iconsize .. ":0:0:64:64:5:59:5:59\124t"
							if ct.damagecolor then
								color = ct.dmgcolor[ct.dmindex[random(#ct.dmindex)]]
							else
								color = {1, 1, 0}
							end
						elseif ct.damagecolor and not ct.icons then
							color = ct.dmgcolor[ct.dmindex[random(#ct.dmindex)]]
						elseif not ct.damagecolor then
							color = {1, 1, random(0, 1)}
						end
						ct.frames[i]:AddMessage(msg, unpack(color))
					elseif framenames[i] == "loot" then
						if random(3) % 3 == 0 then
							local money = random(1000000)
							ct.frames[i]:AddMessage(MONEY .. ": " .. GetCoinTextureString(money), 1, 1, 0) -- yellow
						end
					elseif framenames[i] == "crit" then
						if random(3) % 1 == 0 then
							local icon
							local crit = random(10000, 900000)
							local color = {1, 1, random(0, 1)}

							if ct.icons then
								while not icon do
									local id = random(10000, 90000)
									_, _, icon = GetSpellInfo(id)
								end
							end

							if icon then
								crit = ct.critprefix .. crit .. ct.critpostfix .. " \124T" .. icon .. ":" .. ct.criticonsize .. ":" .. ct.criticonsize .. ":0:0:64:64:5:59:5:59\124t"
								if ct.damagecolor then
									color = ct.dmgcolor[ct.dmindex[random(#ct.dmindex)]]
								end
							elseif ct.damagecolor and not ct.icons then
								color = ct.dmgcolor[ct.dmindex[random(#ct.dmindex)]]
							end

							ct.frames[i]:AddMessage(crit, unpack(color))
						end
					elseif framenames[i] == "pwr" then
						if random(3) % 3 == 0 then
							local etype = random(0, 6)
							ct.frames[i]:AddMessage(
								"+" .. random(500) .. " " .. _G[energies[etype]],
								PowerBarColor[etype].r,
								PowerBarColor[etype].g,
								PowerBarColor[etype].b
							)
						end
					elseif framenames[i] == "proc" then
						if random(3) % 3 == 0 then
							ct.frames[i]:AddMessage("A Spell Proc'd!", 1, 1, 0)
						end
					end

					TimeSinceLastUpdate = 0
				end
			end)
			ct.testmode = true
		end
	end

	local function EndTestMode()
		for i = 1, #ct.frames do
			ct.frames[i]:SetScript("OnUpdate", nil)
			ct.frames[i]:Clear()
		end
		if ct.damagecolor then
			ct.dmindex = nil
		end
		ct.testmode = false
	end

	--[[  Pop-Up Dialog  ]]
	StaticPopupDialogs["KPACK_XCT_LOCK"] = {
		text = L["To save window positions you need to reload your UI."],
		button1 = ACCEPT,
		button2 = CANCEL,
		OnAccept = function()
			if not InCombatLockdown() then
				ReloadUI()
			else
				EndConfigmode()
			end
		end,
		OnCancel = EndConfigmode,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = true,
		showAlert = true
	}

	-- Register Slash Commands
	SLASH_KPACK_XCT1 = "/xct"
	SlashCmdList["KPACK_XCT"] = function(input)
		input = strlower(input)
		local args = {}

		-- get the args
		for v in input:gmatch("%w+") do
			args[#args + 1] = v
		end

		if args[1] == "unlock" then
			if ct.locked then
				StartConfigmode()
			else
				pr(L["already unlocked."])
			end
		elseif args[1] == "lock" then
			if ct.locked then
				pr(L["already locked."])
			else
				StaticPopup_Show("KPACK_XCT_LOCK")
			end
		elseif args[1] == "test" then
			if (ct.testmode) then
				EndTestMode()
				pr(L["test mode disabled."])
			else
				StartTestMode()
				pr(L["test mode enabled."])
			end
		else
			pr(L:F("Acceptable commands for: |caaf49141%s|r", "/xct"))
			print(L:F("%s: to move and resize frames.", "|cffFF0000/xct unlock|r"))
			print(L:F("%s: to lock frames.", "|cffFF0000/xct lock|r"))
			print(L:F("%s: to toggle testmode (sample xCT output).", "|cffFF0000/xct test|r"))
		end
	end

	-- awesome shadow priest helper
	if ct.stopvespam and ct.myclass == "PRIEST" then
		local sp = CreateFrame("Frame")
		sp:SetScript("OnEvent", function(...)
			if GetShapeshiftForm() == 1 then
				if ct.blizzheadnumbers then
					SetCVar("CombatHealing", 0)
				end
			else
				if ct.blizzheadnumbers then
					SetCVar("CombatHealing", 1)
				end
			end
		end)
		sp:RegisterEvent("PLAYER_ENTERING_WORLD")
		sp:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
		sp:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
	end

	-- spam merger
	if ct.mergeaoespam then
		if ct.damageout or ct.healingout then
			if not ct.mergeaoespamtime or ct.mergeaoespamtime < 1 then
				ct.mergeaoespamtime = 1
			end
			SQ = {}
			for k, v in pairs(ct.aoespam) do
				SQ[k] = {queue = 0, msg = "", color = {}, count = 0, utime = 0, locked = false}
			end
			ct.SpamQueue = function(spellId, add)
				local amount
				local spam = SQ[spellId]["queue"]
				if spam and type(spam) == "number" then
					amount = spam + add
				else
					amount = add
				end
				return amount
			end
			local tslu = 0
			local xCTspam = CreateFrame("Frame")
			xCTspam:SetScript("OnUpdate", function(self, elapsed)
				local count
				tslu = tslu + elapsed
				if tslu > 0.5 then
					tslu = 0
					local utime = time()
					for k, v in pairs(SQ) do
						if not SQ[k]["locked"] and SQ[k]["queue"] > 0 and SQ[k]["utime"] + ct.mergeaoespamtime <= utime then
							if SQ[k]["count"] > 1 then
								count = " |cffFFFFFF x " .. SQ[k]["count"] .. "|r"
							else
								count = ""
							end
							xCTdone:AddMessage(SQ[k]["queue"] .. SQ[k]["msg"] .. count, unpack(SQ[k]["color"]))
							SQ[k]["queue"] = 0
							SQ[k]["count"] = 0
						end
					end
				end
			end)
		end
	end

	-- damage
	if (ct.damageout) then
		if gflags == nil then
			gflags = bit.bor(COMBATLOG_OBJECT_AFFILIATION_MINE, COMBATLOG_OBJECT_REACTION_FRIENDLY, COMBATLOG_OBJECT_CONTROL_PLAYER, COMBATLOG_OBJECT_TYPE_GUARDIAN)
		end

		local xCTd = CreateFrame("Frame")
		if ct.damagecolor then
			ct.dmgcolor = {}
			ct.dmgcolor[1] = {1, 1, 0} -- physical
			ct.dmgcolor[2] = {1, .9, .5} -- holy
			ct.dmgcolor[4] = {1, .5, 0} -- fire
			ct.dmgcolor[8] = {.3, 1, .3} -- nature
			ct.dmgcolor[16] = {.5, 1, 1} -- frost
			ct.dmgcolor[32] = {.5, .5, 1} -- shadow
			ct.dmgcolor[64] = {1, .5, 1} -- arcane
		end

		if ct.icons then
			ct.blank = "Interface\\Addons\\KPack\\Media\\Textures\\blank"
		end

		local dmg = function(self, event, ...)
			local msg, icon, frame = "", "", xCTdone
			local timestamp, eventType, sourceGUID, sourceName, sourceFlags, destGUID, destName = select(1, ...)
			if (sourceGUID == ct.pguid and destGUID ~= ct.pguid) or (sourceGUID == UnitGUID("pet") and ct.petdamage) or (sourceFlags == gflags) then
				if eventType == "SWING_DAMAGE" then
					local amount, _, _, _, _, _, critical = select(9, ...)
					if amount >= ct.treshold then
						msg = amount
						local iconsize = ct.iconsize
						if critical then
							frame = xCTcrit or frame
							msg = ct.critprefix .. msg .. ct.critpostfix
							iconsize = ct.criticonsize

							-- Filter Criticals
							if ct.filtercrits and not ct.showswingcrits then
								if ct.showasnoncrit then
									frame = xCTdone -- redirect to the regular frame
								else
									return
								end
							end
						end
						if ct.icons and not ct.hideautoattack then
							local spellNameOrID
							if sourceGUID == UnitGUID("pet") or sourceFlags == gflags then
								spellNameOrID = PET_ATTACK_TEXTURE
							else
								spellNameOrID = 6603
							end
							msg = msg .. GetSpellTextureFormatted(spellNameOrID, iconsize)
						end
						frame:AddMessage(msg)
					end
				elseif eventType == "RANGE_DAMAGE" then
					local spellId, _, _, amount, _, _, _, _, _, critical = select(9, ...)
					if amount >= ct.treshold then
						msg = amount
						local iconsize = ct.iconsize
						if critical then
							local bfilter = false
							msg = ct.critprefix .. msg .. ct.critpostfix
							iconsize = ct.criticonsize
							frame = xCTcrit or frame

							-- Filter Criticals
							if ct.filtercrits then
								if spellId == 75 and not ct.showswingcrits then
									bfilter = true
								elseif ct.critfilter[spellId] and ct.crits_blacklist then
									bfilter = true
								elseif not ct.critfilter[spellId] and not ct.crits_blacklist then
									bfilter = true
								end
							end

							-- Redirect to the regular frame
							if bfilter then
								if ct.showasnoncrit then
									frame = xCTdone
								else
									return
								end
							end
						end
						if ct.icons then
							if not (spellId == 75 and ct.hideautoattack) then
								msg = msg .. GetSpellTextureFormatted(spellId, iconsize)
							end
						end
						frame:AddMessage(msg)
					end
				elseif eventType == "SPELL_DAMAGE" or (eventType == "SPELL_PERIODIC_DAMAGE" and ct.dotdamage) then
					local spellId, _, spellSchool, amount, _, _, _, _, _, critical = select(9, ...)
					if amount >= ct.treshold then
						local color = {}
						local rawamount = amount
						local iconsize = ct.iconsize
						if critical then
							local bfilter = false
							frame = xCTcrit or frame
							amount = ct.critprefix .. amount .. ct.critpostfix
							iconsize = ct.criticonsize

							-- Filter Criticals
							if ct.filtercrits then
								if ct.critfilter[spellId] and ct.crits_blacklist then
									bfilter = true
								elseif not ct.critfilter[spellId] and not ct.crits_blacklist then
									bfilter = true
								end
							end

							-- Redirect to the regular frame
							if bfilter then
								if ct.showasnoncrit then
									frame = xCTdone
								else
									return
								end
							end
						end
						if ct.damagecolor then
							if ct.dmgcolor[spellSchool] then
								color = ct.dmgcolor[spellSchool]
							else
								color = ct.dmgcolor[1]
							end
						else
							color = {1, 1, 0}
						end
						if ct.icons then
							msg = GetSpellTextureFormatted(spellId, iconsize)
						else
							msg = ""
						end
						if ct.mergeaoespam and ct.aoespam[spellId] then
							SQ[spellId]["locked"] = true
							SQ[spellId]["queue"] = ct.SpamQueue(spellId, rawamount)
							SQ[spellId]["msg"] = msg
							SQ[spellId]["color"] = color
							SQ[spellId]["count"] = SQ[spellId]["count"] + 1
							if SQ[spellId]["count"] == 1 then
								SQ[spellId]["utime"] = time()
							end
							SQ[spellId]["locked"] = false

							return
						end

						frame:AddMessage(amount .. "" .. msg, unpack(color))
					end
				elseif eventType == "SWING_MISSED" then
					local missType = select(9, ...)

					if not ct.showimmunes then
						if strlower(missType) == strlower(IMMUNE) then
							return
						end
					end

					if ct.icons and not ct.hideautoattack then
						local spellNameOrID
						if sourceGUID == UnitGUID("pet") or sourceFlags == gflags then
							spellNameOrID = PET_ATTACK_TEXTURE
						else
							spellNameOrID = 6603
						end
						missType = missType .. GetSpellTextureFormatted(spellNameOrID, ct.iconsize)
					end
					xCTdone:AddMessage(missType)
				elseif eventType == "SPELL_MISSED" or eventType == "RANGE_MISSED" then
					local spellId, _, _, missType, _ = select(9, ...)

					if not ct.showimmunes then
						if strlower(missType) == strlower(IMMUNE) then
							return
						end
					end

					if ct.icons then
						missType = missType .. GetSpellTextureFormatted(spellId, ct.iconsize)
					end
					xCTdone:AddMessage(missType)
				elseif eventType == "SPELL_DISPEL" and ct.dispel then
					local target, _, _, id, effect, _, etype = select(9, ...)
					local color
					if ct.icons then
						msg = GetSpellTextureFormatted(id, ct.iconsize)
					end
					if etype == "BUFF" then
						color = {0, 1, .5}
					else
						color = {1, 0, .5}
					end
					xCTgen:AddMessage(ACTION_SPELL_DISPEL .. ": " .. effect .. msg, unpack(color))
				elseif eventType == "SPELL_INTERRUPT" and ct.interrupt then
					local target, _, _, id, effect = select(9, ...)
					local color = {1, .5, 0}
					if ct.icons then
						msg = GetSpellTextureFormatted(id, ct.iconsize)
					end
					xCTgen:AddMessage(ACTION_SPELL_INTERRUPT .. ": " .. effect .. msg, unpack(color))
				elseif eventType == "SPELL_STOLEN" and ct.dispel then
					local target, _, _, id, effect = select(9, ...)
					local color = {.9, 0, .9}
					if ct.icons then
						msg = GetSpellTextureFormatted(id, ct.iconsize)
					end
					xCTgen:AddMessage(ACTION_SPELL_STOLEN .. ": " .. effect .. msg, unpack(color))
				elseif eventType == "PARTY_KILL" and ct.killingblow then
					local tname = select(7, ...)
					msg = ACTION_PARTY_KILL:sub(1, 1):upper() .. ACTION_PARTY_KILL:sub(2)
					xCTgen:AddMessage(ACTION_PARTY_KILL .. ": " .. tname, .2, 1, .2)
				end
			end
		end

		xCTd:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		xCTd:SetScript("OnEvent", dmg)
	end

	-- healing
	if (ct.healingout) then
		if gflags == nil then
			gflags = bit.bor(COMBATLOG_OBJECT_AFFILIATION_MINE, COMBATLOG_OBJECT_REACTION_FRIENDLY, COMBATLOG_OBJECT_CONTROL_PLAYER, COMBATLOG_OBJECT_TYPE_GUARDIAN)
		end

		local xCTh = CreateFrame("Frame")
		if ct.icons then
			ct.blank = "Interface\\Addons\\KPack\\Media\\Textures\\blank"
		end
		local heal = function(self, event, ...)
			local msg, icon, frame = "", "", xCTdone
			local timestamp, eventType, sourceGUID, sourceName, sourceFlags, destGUID, destName = select(1, ...)
			if sourceGUID == ct.pguid or sourceFlags == gflags then
				if eventType == "SPELL_HEAL" or eventType == "SPELL_PERIODIC_HEAL" and ct.showhots then
					if ct.healingout then
						local spellId, spellName, spellSchool, amount, overhealing, absorbed, critical = select(9, ...)
						if ct.healfilter[spellId] then
							return
						end
						if amount >= ct.healtreshold then
							local color = {.1, .65, .1}
							local rawamount = amount
							local iconsize = ct.iconsize
							if critical then
								local bfilter = false
								amount = ct.critprefix .. amount .. ct.critpostfix
								color = {.1, 1, .1}
								frame = xCTcrit or frame
								iconsize = ct.criticonsize

								-- Filter Criticals
								if ct.filtercrits then
									if ct.critfilter[spellId] and ct.crits_blacklist then
										bfilter = true
									elseif not ct.critfilter[spellId] and not ct.crits_blacklist then
										bfilter = true
									end
								end

								-- Redirect to the regular frame
								if bfilter then
									if ct.showasnoncrit then
										frame = xCTdone
									else
										return
									end
								end
							end
							if ct.icons then
								msg = GetSpellTextureFormatted(spellId, iconsize)
							end
							if ct.mergeaoespam and ct.aoespam[spellId] then
								SQ[spellId]["locked"] = true
								SQ[spellId]["queue"] = ct.SpamQueue(spellId, rawamount)
								SQ[spellId]["msg"] = msg
								SQ[spellId]["color"] = color
								SQ[spellId]["count"] = SQ[spellId]["count"] + 1
								if SQ[spellId]["count"] == 1 then
									SQ[spellId]["utime"] = time()
								end
								SQ[spellId]["locked"] = false

								return
							end
							frame:AddMessage(amount .. "" .. msg, unpack(color))
						end
					end
				end
			end
		end

		xCTh:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		xCTh:SetScript("OnEvent", heal)
	end
end)