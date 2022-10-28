local folder, core = ...
core.callbacks = core.callbacks or LibStub("CallbackHandler-1.0"):New(core)
core.title = GetAddOnMetadata(folder, "Title")
core.version = GetAddOnMetadata(folder, "Version")
_G.KPack = core

local L = core.L
core.ACD = LibStub("AceConfigDialog-3.0")
local LBF = LibStub("LibButtonFacade", true)

local select, next, type = select, next, type
local tinsert, tremove = table.insert, table.remove
local setmetatable = setmetatable
local __off -- number of disabled modules

-- player & class
do
	local function RGBPercToHex(r, g, b)
		r = r <= 1 and r >= 0 and r or 0
		g = g <= 1 and g >= 0 and g or 0
		b = b <= 1 and b >= 0 and b or 0
		return format("ff%02x%02x%02x", r * 255, g * 255, b * 255)
	end

	core.classcolors = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
	for classname, classtable in pairs(core.classcolors) do
		classtable.colorStr = classtable.colorStr or RGBPercToHex(classtable.r, classtable.g, classtable.b)
	end
end

core.name = UnitName("player")
core.race = select(2, UnitRace("player"))
core.faction = UnitFactionGroup("player")
core.class = select(2, UnitClass("player"))
core.mycolor = core.classcolors[core.class]

-- Project Ascension
core.Ascension = (type(C_Realm) == "table")
core.AscensionCoA = core.Ascension and C_Realm:IsConquestOfAzeroth()

-------------------------------------------------------------------------------
-- C_Timer mimic
--

do
	local TickerPrototype = {}
	local TickerMetatable = {__index = TickerPrototype}

	local WaitTable = {}

	local new, del
	do
		local list = {cache = {}, trash = {}}
		setmetatable(list.trash, {__mode = "v"})

		function new()
			return tremove(list.cache) or {}
		end

		function del(t)
			if t then
				setmetatable(t, nil)
				for k, v in pairs(t) do
					t[k] = nil
				end
				tinsert(list.cache, 1, t)
				while #list.cache > 20 do
					tinsert(list.trash, 1, tremove(list.cache))
				end
			end
		end
	end

	local function WaitFunc(self, elapsed)
		local total = #WaitTable
		local i = 1

		while i <= total do
			local ticker = WaitTable[i]

			if ticker._cancelled then
				del(tremove(WaitTable, i))
				total = total - 1
			elseif ticker._delay > elapsed then
				ticker._delay = ticker._delay - elapsed
				i = i + 1
			else
				ticker._callback(ticker)

				if ticker._iterations == -1 then
					ticker._delay = ticker._duration
					i = i + 1
				elseif ticker._iterations > 1 then
					ticker._iterations = ticker._iterations - 1
					ticker._delay = ticker._duration
					i = i + 1
				elseif ticker._iterations == 1 then
					del(tremove(WaitTable, i))
					total = total - 1
				end
			end
		end

		if #WaitTable == 0 then
			self:Hide()
		end
	end

	local WaitFrame = _G.KPack_WaitFrame or CreateFrame("Frame", "KPack_WaitFrame", UIParent)
	WaitFrame:SetScript("OnUpdate", WaitFunc)

	local function AddDelayedCall(ticker, oldTicker)
		ticker = (oldTicker and type(oldTicker) == "table") and oldTicker or ticker
		tinsert(WaitTable, ticker)
		WaitFrame:Show()
	end

	local function ValidateArguments(duration, callback, callFunc)
		if type(duration) ~= "number" then
			error(format(
				"Bad argument #1 to '" .. callFunc .. "' (number expected, got %s)",
				duration ~= nil and type(duration) or "no value"
			), 2)
		elseif type(callback) ~= "function" then
			error(format(
				"Bad argument #2 to '" .. callFunc .. "' (function expected, got %s)",
				callback ~= nil and type(callback) or "no value"
			), 2)
		end
	end

	local function After(duration, callback, ...)
		ValidateArguments(duration, callback, "After")

		local ticker = new()

		ticker._iterations = 1
		ticker._delay = max(0.01, duration)
		ticker._callback = callback

		AddDelayedCall(ticker)
	end

	local function CreateTicker(duration, callback, iterations, ...)
		local ticker = new()
		setmetatable(ticker, TickerMetatable)

		ticker._iterations = iterations or -1
		ticker._delay = max(0.01, duration)
		ticker._duration = ticker._delay
		ticker._callback = callback

		AddDelayedCall(ticker)
		return ticker
	end

	local function NewTicker(duration, callback, iterations, ...)
		ValidateArguments(duration, callback, "NewTicker")
		return CreateTicker(duration, callback, iterations, ...)
	end

	local function NewTimer(duration, callback, ...)
		ValidateArguments(duration, callback, "NewTimer")
		return CreateTicker(duration, callback, 1, ...)
	end

	local function CancelTimer(ticker, silent)
		if ticker and ticker.Cancel then
			ticker:Cancel()
		elseif not silent then
			error("KPack.CancelTimer(timer[, silent]): '"..tostring(ticker).."' - no such timer registered")
		end
		return nil
	end

	function TickerPrototype:Cancel()
		self._cancelled = true
	end
	function TickerPrototype:IsCancelled()
		return self._cancelled
	end

	core.After = After
	core.NewTicker = NewTicker
	core.NewTimer = NewTimer
	core.CancelTimer = CancelTimer
end

-------------------------------------------------------------------------------
-- Weak Table
--

do
	local wipe = wipe or table.wipe

	local weaktable = {__mode = "v"}
	function core.WeakTable(t)
		return setmetatable(wipe(t or {}), weaktable)
	end

	-- Shamelessly copied from Omen - thanks!
	local tablePool = core.tablePool or setmetatable({}, {__mode = "kv"})
	core.tablePool = tablePool

	-- get a new table
	function core.newTable()
		local t = next(tablePool) or {}
		tablePool[t] = nil
		return t
	end

	-- delete table and return to pool
	function core.delTable(t)
		if type(t) == "table" then
			wipe(t)
			t[true] = true
			t[true] = nil
			tablePool[t] = true
		end
		return nil
	end
end

-------------------------------------------------------------------------------

local format = string.format

-- main print function
function core:Print(msg, pref)
	if msg then
		-- prepare the prefix:
		if not pref then
			pref = "|cff33ff99" .. folder .. "|r"
		else
			pref = "|cff33ff99" .. folder .. "|r - |caaf49141" .. pref .. "|r"
		end
		DEFAULT_CHAT_FRAME:AddMessage(format("%s: %s", pref, tostring(msg)))
	end
end

-- mimics system message output
do
	local info
	function core:PrintSys(msg)
		if msg then
			info = info or ChatTypeInfo["SYSTEM"]
			DEFAULT_CHAT_FRAME:AddMessage(tostring(msg), info.r, info.g, info.b, info.id)
		end
	end
end

-- notify function to print message to raid warning frame
function core:Notify(msg, pref)
	if msg then
		-- prepare the prefix:
		if not pref then
			pref = "|cff33ff99" .. folder .. "|r"
		else
			pref = "|cff33ff99" .. folder .. "|r - |caaf49141" .. pref .. "|r"
		end
		RaidNotice_AddMessage(RaidWarningFrame, format("%s: %s", pref, tostring(msg)), ChatTypeInfo["SAY"])
	end
end

-- functions used to kill functions/frames.
core.Noop = function() return end
function core:Kill(frame)
	if frame and frame.SetScript then
		frame:UnregisterAllEvents()
		frame:SetScript("OnEvent", nil)
		frame:SetScript("OnUpdate", nil)
		frame:SetScript("OnHide", nil)
		frame:Hide()
		frame.SetScript = core.Noop
		frame.RegisterEvent = core.Noop
		frame.RegisterAllEvents = core.Noop
		frame.Show = core.Noop
	end
end

-- used to show or hide frame based on a condition
function core:ShowIf(frame, condition)
	if not frame or not frame.Show then
		return
	elseif condition and not frame:IsShown() then
		frame:Show()
	elseif not condition and frame:IsShown() then
		frame:Hide()
	end
end

-- used to abbreviate long texts
local match = string.match
local utf8lower = string.utf8lower
local utf8sub = string.utf8sub

function core:Abbrev(str)
	local letters, lastWord = "", match(str, ".+%s(.+)$")
	if lastWord then
		for word in gmatch(str, ".-%s") do
			local firstLetter = utf8sub(gsub(word, "^[%s%p]*", ""), 1, 1)
			if firstLetter ~= utf8lower(firstLetter) then
				letters = format("%s%s. ", letters, firstLetter)
			end
		end
		str = format("%s%s", letters, lastWord)
	end
	return str
end

function core:RegisterForEvent(event, callback, ...)
	if not self.frame then
		self.frame = CreateFrame("Frame")
		self.frame:SetScript("OnEvent", function(f, event, ...)
			for func, args in next, f.events[event] do
				func(unpack(args), ...)
			end
		end)
	end
	self.frame.events = self.frame.events or {}
	self.frame.events[event] = self.frame.events[event] or {}
	self.frame.events[event][callback] = {...}
	self.frame:RegisterEvent(event)
end

-------------------------------------------------------------------------------
-- Options
--

do
	local options = {
		type = "group",
		name = format("%s - %s", core.title, core.version),
		childGroups = "tab",
		args = {
			Options = {
				type = "group",
				name = L["Options"],
				order = 0,
				hidden = function() return (__off == #core.moduleslist) end,
				args = {}
			},
			Modules = {
				type = "group",
				name = L["Modules"],
				order = 99999,
				width = "full",
				get = function(i)
					return KPackDB.disabled[i[#i]]
				end,
				set = function(i, val)
					KPackDB.disabled[i[#i]] = val
					core.options.args.Modules.args.apply.disabled = false
				end,
				args = {
					apply = {
						type = "execute",
						name = APPLY,
						order = 1,
						width = "full",
						disabled = true,
						confirm = function()
							return L["This change requires a UI reload. Are you sure?"]
						end,
						func = function()
							ReloadUI()
						end
					},
					list = {
						type = "group",
						name = L["Tick the modules you want to disable."],
						order = 2,
						inline = true,
						args = {}
					}
				}
			}
		}
	}
	core.options = options
end

-------------------------------------------------------------------------------
-- Core
--

do
	do
		local nonLatin = {ruRU = true, koKR = true, zhCN = true, zhTW = true}
		if nonLatin[core.locale] then
			core.nonLatin = true
		end
	end

	local tostring = tostring

	local help = "|cffffd700%s|r: %s"
	local function SlashCommandHandler(cmd)
		cmd = cmd and cmd:lower()
		if cmd == "help" then
			print(L:F("Acceptable commands for: |caaf49141%s|r", "kp"), ": config", ", about", ", reinstall")
			core:Print(L["Accessible module commands are:"])
			print(help:format("/abm", L:F("access |caaf49141%s|r module commands", "ActionBars")))
			print(help:format("/align", L:F("access |caaf49141%s|r module commands", "Align")))
			print(help:format("/cf", L:F("access |caaf49141%s|r module commands", "ChatFilter")))
			print(help:format("/cm", L:F("access |caaf49141%s|r module commands", "ChatMods")))
			print(help:format("/gs", L:F("access |caaf49141%s|r module commands", "GearScore")))
			print(help:format("/clf", L:F("access |caaf49141%s|r module commands", "CombatLogFix")))
			print(help:format("/erf", L:F("access |caaf49141%s|r module commands", "ErrorFilter")))
			print(help:format("/im", L:F("access |caaf49141%s|r module commands", "IgnoreMore")))
			print(help:format("/lu", L:F("access |caaf49141%s|r module commands", "LookUp")))
			print(help:format("/lmf", L:F("access |caaf49141%s|r module commands", "LootMessageFilter")))
			print(help:format("/math", L:F("to use the |caaf49141%s|r module", "Math")))
			print(help:format("/mm", L:F("to use the |caaf49141%s|r module", "Minimap")))
			print(help:format("/np", L:F("access |caaf49141%s|r module commands", "Nameplates")))
			print(help:format("/ps", L:F("access |caaf49141%s|r module commands", "PersonalResources")))
			print(help:format("/qb", L:F("access |caaf49141%s|r module commands", "QuickButton")))
			print(help:format("/scp", L:F("access |caaf49141%s|r module commands", "SimpleComboPoints")))
			print(help:format("/simp", L:F("access |caaf49141%s|r module commands", "Simplified")))
			print(help:format("/tip", L:F("access |caaf49141%s|r module commands", "Tooltip")))
			print(help:format("/uf", L:F("access |caaf49141%s|r module commands", "UnitFrames")))
			print(help:format("/vp", L:F("access |caaf49141%s|r module commands", "Viewporter")))
		elseif cmd == "about" or cmd == "info" then
			core:Print("This small addon was made with big passion by |cfff58cbaKader|r.\n If you have suggestions or you are facing issues with my addons, feel free to message me on the forums, Github, CurseForge or Discord:\n|cffffd700bkader#5341|r or |cff7289d9https://discord.gg/a8z5CyS3eW|r")
		elseif cmd == "reinstall" or cmd == "default" then
			wipe(KPackDB)
			wipe(KPackCharDB)
			ReloadUI()
		else
			core:OpenConfig()
		end
	end

	function core:OpenConfig(...)
		core.ACD:SetDefaultSize(folder, 655, 500)
		if ... then
			core.ACD:Open(folder)
			core.ACD:SelectGroup(folder, ...)
		elseif not core.ACD:Close(folder) then
			core.ACD:Open(folder)
		end
	end

	local function CheckFirstRun()
		if next(core.db) == nil then
			-- modules that are disabled by default.
			core.db.disabled = core.db.disabled or {}
			core.db.disabled[L["BlizzMove"]] = true
			core.db.disabled[L["Action Bar Saver"]] = true
			core.db.disabled[L["Align"]] = true
			core.db.disabled[L["Auto Track"]] = true
			core.db.disabled[L["Binder"]] = true
			core.db.disabled[L["Bubblicious"]] = true
			core.db.disabled[L["CombatLogFix"]] = true
			core.db.disabled[L["CombatTime"]] = true
			core.db.disabled[L["EnhancedStackSplit"]] = true
			core.db.disabled[L["FriendsInfo"]] = true
			core.db.disabled[L["GarbageProtector"]] = true
			core.db.disabled[L["GearScoreLite"]] = true
			core.db.disabled[L["IgnoreMore"]] = true
			core.db.disabled[L["ImprovedLootFrame"]] = true
			core.db.disabled[L["LiveStream"]] = true
			core.db.disabled[L["LookUp"]] = true
			core.db.disabled[L["Math"]] = true
			core.db.disabled[L["PullnBreak"]] = true
			core.db.disabled[L["QuickButton"]] = true
			core.db.disabled[L["Reflux"]] = true
			core.db.disabled[L["SlashIn"]] = true
			core.db.disabled[L["TellMeWhen"]] = true
			core.db.disabled[L["Viewporter"]] = true
			core.db.disabled[L["Virtual Plates"]] = true
			core.db.disabled[L["AddOnSkins"]] = true
		end
	end

	core:RegisterForEvent("ADDON_LOADED", function(_, name)
		if name == folder then
			KPackDB = KPackDB or {}
			core.db = KPackDB

			KPackCharDB = KPackCharDB or {}
			core.char = KPackCharDB

			CheckFirstRun()

			LibStub("AceConfig-3.0"):RegisterOptionsTable(folder, core.options)
			core.optionsFrame = core.ACD:AddToBlizOptions(folder, folder)

			SlashCmdList["KPACK"] = SlashCommandHandler
			_G.SLASH_KPACK1 = "/kp"
			_G.SLASH_KPACK2 = "/kpack"

			core:MediaRegister("statusbar", "Half", [[Interface\Addons\KPack\Media\Statusbar\half]])
			core:MediaRegister("statusbar", "KPack Blank", [[Interface\Addons\KPack\Media\Textures\blank]])
			core:MediaRegister("statusbar", "KPack Gloss", [[Interface\Addons\KPack\Media\Statusbar\gloss]])
			core:MediaRegister("statusbar", "KPack Norm", [[Interface\Addons\KPack\Media\Statusbar\norm]])
			core:MediaRegister("statusbar", "KPack", [[Interface\Addons\KPack\Media\Statusbar\statusbar]])
			core:MediaRegister("statusbar", "Melli", [[Interface\Addons\KPack\Media\Statusbar\melli]])
			core:MediaRegister("statusbar", "One Pixel", [[Interface\Addons\KPack\Media\Statusbar\onepixel]])
			core:MediaRegister("font", "Hooge", [[Interface\Addons\KPack\Media\Fonts\HOOGE.ttf]])
			core:MediaRegister("font", "Yanone", [[Interface\Addons\KPack\Media\Fonts\yanone.ttf]])

			core:Print(L["addon loaded. use |cffffd700/kp|r to access options."])

			core.ElvUI = _G.ElvUI and select(1, unpack(ElvUI)) or false
			if core.moduleslist then
				for i = 1, #core.moduleslist do
					core.moduleslist[i](L, folder)
				end
			end
			if LBF then
				LBF:RegisterSkinCallback("KPack", core.OnSkin, core)
			end
		end
	end)

	do
		-- automatic garbage collection
		local collectgarbage = collectgarbage
		local UnitIsAFK = UnitIsAFK
		local InCombatLockdown = InCombatLockdown
		local eventcount = 0

		local f = CreateFrame("Frame")
		f:SetScript("OnEvent", function(self, event, arg1)
			if event == "PLAYER_LOGIN" then
				core.guid = UnitGUID("player")
			elseif (InCombatLockdown() and eventcount > 25000) or (not InCombatLockdown() and eventcount > 10000) or event == "PLAYER_ENTERING_WORLD" then
				collectgarbage("collect")
				eventcount = 0
				self:UnregisterEvent(event)
			elseif event == "PLAYER_REGEN_ENABLED" then
				core.After(3, function()
					collectgarbage("collect")
					eventcount = 0
				end)
				core.InCombat = false
				core.callbacks:Fire("PLAYER_COMBAT_LEAVE")
			elseif event == "PLAYER_REGEN_DISABLED" then
				core.InCombat = true
				core.callbacks:Fire("PLAYER_COMBAT_ENTER")
			else
				if arg1 ~= "player" then
					return
				end
				if UnitIsAFK(arg1) then
					collectgarbage("collect")
				end
			end
			eventcount = eventcount + 1
		end)
		f:RegisterEvent("PLAYER_LOGIN")
		f:RegisterEvent("PLAYER_ENTERING_WORLD")
		f:RegisterEvent("PLAYER_FLAGS_CHANGED")
		f:RegisterEvent("PLAYER_REGEN_ENABLED")
		f:RegisterEvent("PLAYER_REGEN_DISABLED")
	end

	-- Addon sync
	function core:Sync(prefix, msg)
		local zoneType = select(2, IsInInstance())
		if zoneType == "pvp" or zoneType == "arena" then
			SendAddonMessage(prefix, msg, "BATTLEGROUND")
		elseif GetRealNumRaidMembers() > 0 then
			SendAddonMessage(prefix, msg, "RAID")
		elseif GetRealNumPartyMembers() > 0 then
			SendAddonMessage(prefix, msg, "PARTY")
		end
	end
end

-- LibButtonFacade
function core:OnSkin(skin, glossAlpha, gloss, group, _, colors)
	local styleDB
	if group == L["Buff Frame"] then
		if not self:IsDisabled("BuffFrame") then
			if not self.db.BuffFrame.style then
				self.db.BuffFrame.style = {}
			end
			styleDB = self.db.BuffFrame.style
		end
	end

	if styleDB then
		styleDB[1] = skin
		styleDB[2] = glossAlpha
		styleDB[3] = gloss
		styleDB[4] = colors
	end
end

-------------------------------------------------------------------------------
-- Modules
--

function core:AddModule(name, desc, func)
	if type(desc) == "function" then
		func = desc
		desc = nil
	end

	self.moduleslist = self.moduleslist or {}
	self.moduleslist[#self.moduleslist + 1] = func

	self.options.args.Modules.args.list.args[name] = {
		type = "toggle",
		name = L[name],
		desc = L[desc]
	}
end

function core:IsDisabled(...)
	self.db.disabled = self.db.disabled or {}
	for i = 1, select("#", ...) do
		if self.db.disabled[select(i, ...)] == true then
			__off = (__off or 0) + 1
			return true
		end
	end
	return false
end

-- checks if addon(s) is (are) loaded
function core:AddOnIsLoaded(...)
	for i = 1, select("#", ...) do
		local name = select(i, ...)
		if IsAddOnLoaded(name) then
			return true, name
		end
	end
	return false, nil
end

-- check if an addon is loaded and has module.
function core:AddOnHasModule(name, modname)
	local loaded = self:AddOnIsLoaded(name)
	if loaded and _G[name] then
		-- using AceAddon
		if _G[name].GetModule then
			local mod = _G[name]:GetModule(modname, true)
			return (mod and mod:IsEnabled())
		end
		-- using custom
		if _G[name].modules and _G[name].modules[modname] then
			return true
		end
	end
	return false
end

-------------------------------------------------------------------------------
-- Functions to save and restore frame positions
--

function core:SavePosition(f, db, withSize)
	if f then
		local x, y = f:GetLeft(), f:GetTop()
		local s = db.scale or f:GetEffectiveScale()
		db.xOfs, db.yOfs = x * s, y * s

		if withSize then
			if db.width then
				db.width = f:GetWidth()
			end
			if db.height then
				db.height = f:GetHeight()
			end
		end
	end
end

function core:RestorePosition(f, db, withSize)
	if f then
		local x, y = db.xOfs, db.yOfs
		if not x or not y then
			f:ClearAllPoints()
			f:SetPoint("CENTER", UIParent)
			return false
		end

		local s = db.scale or f:GetEffectiveScale()
		f:ClearAllPoints()
		f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / s, y / s)

		if withSize then
			if db.width then
				f:SetWidth(db.width)
			end
			if db.height then
				f:SetHeight(db.height)
			end
		end
		return true
	end
end

-------------------------------------------------------------------------------
-- LibSharedMedia Stuff
--

do
	local LSM = LibStub("LibSharedMedia-3.0")

	function core:MediaFetch(mediatype, key, default)
		return (key and LSM:Fetch(mediatype, key)) or (default and LSM:Fetch(mediatype, default)) or default
	end

	function core:MediaRegister(mediatype, key, path)
		LSM:Register(mediatype, key, path)
	end

	function core:RegisterLSMCallback(obj, event, callback)
		LSM.RegisterCallback(obj, event, callback)
	end
end

-------------------------------------------------------------------------------
-- Classy-1.0 mimic
--

function core:NewClass(ftype, parent)
	local class = CreateFrame(ftype)
	class:Hide()
	class.mt = {__index = class}

	if parent then
		class = setmetatable(class, {__index = parent})

		class.super = function(self, method, ...)
			return parent[method](self, ...)
		end
	end

	class.Bind = function(self, obj)
		return setmetatable(obj, self.mt)
	end

	return class
end

-------------------------------------------------------------------------------
-- StatusBarPrototype
--

do
	local StatusBarPrototype = {
		minValue = 0.0,
		maxValue = 1.0,
		value = 1,
		rotate = true,
		reverse = false,
		orientation = "HORIZONTAL",
		fill = "STANDARD",
		-- [[ API ]]--
		Update = function(self, OnSizeChanged)
			self.progress = (self.value - self.minValue) / (self.maxValue - self.minValue)

			local align1, align2
			local TLx, TLy, BLx, BLy, TRx, TRy, BRx, BRy
			local TLx_, TLy_, BLx_, BLy_, TRx_, TRy_, BRx_, BRy_
			local width, height = self:GetSize()

			if self.orientation == "HORIZONTAL" then
				self.xProgress = width * self.progress -- progress horizontally
				if self.fill == "CENTER" then
					align1, align2 = "TOP", "BOTTOM"
				elseif self.reverse or self.fill == "REVERSE" then
					align1, align2 = "TOPRIGHT", "BOTTOMRIGHT"
				else
					align1, align2 = "TOPLEFT", "BOTTOMLEFT"
				end
			elseif self.orientation == "VERTICAL" then
				self.yProgress = height * self.progress -- progress vertically
				if self.fill == "CENTER" then
					align1, align2 = "LEFT", "RIGHT"
				elseif self.reverse or self.fill == "REVERSE" then
					align1, align2 = "TOPLEFT", "TOPRIGHT"
				else
					align1, align2 = "BOTTOMLEFT", "BOTTOMRIGHT"
				end
			end

			if self.rotate then
				TLx, TLy = 0.0, 1.0
				TRx, TRy = 0.0, 0.0
				BLx, BLy = 1.0, 1.0
				BRx, BRy = 1.0, 0.0
				TLx_, TLy_ = TLx, TLy
				TRx_, TRy_ = TRx, TRy
				BLx_, BLy_ = BLx * self.progress, BLy
				BRx_, BRy_ = BRx * self.progress, BRy
			else
				TLx, TLy = 0.0, 0.0
				TRx, TRy = 1.0, 0.0
				BLx, BLy = 0.0, 1.0
				BRx, BRy = 1.0, 1.0
				TLx_, TLy_ = TLx, TLy
				TRx_, TRy_ = TRx * self.progress, TRy
				BLx_, BLy_ = BLx, BLy
				BRx_, BRy_ = BRx * self.progress, BRy
			end

			if not OnSizeChanged then
				self.bg:ClearAllPoints()
				self.bg:SetAllPoints()
				self.bg:SetTexCoord(TLx, TLy, BLx, BLy, TRx, TRy, BRx, BRy)

				self.fg:ClearAllPoints()
				self.fg:SetPoint(align1)
				self.fg:SetPoint(align2)
				self.fg:SetTexCoord(TLx_, TLy_, BLx_, BLy_, TRx_, TRy_, BRx_, BRy_)
			end

			if self.xProgress then
				self.fg:SetWidth(self.xProgress > 0 and self.xProgress or 0.1)
			end
			if self.yProgress then
				self.fg:SetHeight(self.yProgress > 0 and self.yProgress or 0.1)
			end
		end,
		OnSizeChanged = function(self, width, height)
			self:Update(true)
		end,
		SetMinMaxValues = function(self, minValue, maxValue)
			assert((type(minValue) == "number" and type(maxValue) == "number"), "Usage: StatusBar:SetMinMaxValues(number, number)")

			if maxValue > minValue then
				self.minValue = minValue
				self.maxValue = maxValue
			else
				self.minValue = 0
				self.maxValue = 1
			end

			if not self.value or self.value > self.maxValue then
				self.value = self.maxValue
			elseif not self.value or self.value < self.minValue then
				self.value = self.minValue
			end

			self:Update()
		end,
		GetMinMaxValues = function(self)
			return self.minValue, self.maxValue
		end,
		SetValue = function(self, value)
			assert(type(value) == "number", "Usage: StatusBar:SetValue(number)")
			if value >= self.minValue and value <= self.maxValue then
				self.value = value
				self:Update()
			end
		end,
		GetValue = function(self)
			return self.value
		end,
		SetOrientation = function(self, orientation)
			if orientation == "HORIZONTAL" or orientation == "VERTICAL" then
				self.orientation = orientation
				self:Update()
			end
		end,
		GetOrientation = function(self)
			return self.orientation
		end,
		SetRotatesTexture = function(self, rotate)
			if type(rotate) == "boolean" then
				self.rotate = rotate
				self:Update()
			end
		end,
		GetRotatesTexture = function(self)
			return self.rotate
		end,
		SetReverseFill = function(self, reverse)
			self.reverse = (reverse == true)
			self:Update()
		end,
		GetReverseFill = function(self)
			return self.reverse
		end,
		SetFillStyle = function(self, style)
			if type(style) == "string" and style:upper() == "CENTER" or style:upper() == "REVERSE" then
				self.fill = style:upper()
				self:Update()
			else
				self.fill = "STANDARD"
				self:Update()
			end
		end,
		GetFillStyle = function(self)
			return self.fill
		end,
		SetStatusBarTexture = function(self, texture)
			self.fg:SetTexture(texture)
			self.bg:SetTexture(texture)
		end,
		GetStatusBarTexture = function(self)
			return self.fg
		end,
		SetForegroundColor = function(self, r, g, b, a)
			self.fg:SetVertexColor(r, g, b, a)
		end,
		GetForegroundColor = function(self)
			return self.fg
		end,
		SetBackgroundColor = function(self, r, g, b, a)
			self.bg:SetVertexColor(r, g, b, a)
		end,
		GetBackgroundColor = function(self)
			return self.bg:GetVertexColor()
		end,
		SetTexture = function(self, texture)
			self:SetStatusBarTexture(texture)
		end,
		GetTexture = function(self)
			return self.fg:GetTexture()
		end,
		SetStatusBarColor = function(self, r, g, b, a)
			self:SetForegroundColor(r, g, b, a)
		end,
		SetVertexColor = function(self, r, g, b, a)
			self:SetForegroundColor(r, g, b, a)
		end,
		GetVertexColor = function(self)
			return self.fg:GetVertexColor()
		end,
		SetStatusBarGradient = function(self, r1, g1, b1, a1, r2, g2, b2, a2)
			self.fg:SetGradientAlpha(self.orientation, r1, g1, b1, a1, r2, g2, b2, a2)
		end,
		SetStatusBarGradientAuto = function(self, r, g, b, a)
			self.fg:SetGradientAlpha(self.orientation, 0.5 + (r * 1.1), g * 0.7, b * 0.7, a, r * 0.7, g * 0.7, 0.5 + (b * 1.1), a)
		end,
		SetStatusBarSmartGradient = function(self, r1, g1, b1, r2, g2, b2)
			self.fg:SetGradientAlpha(self.orientation, r1, g1, b1, 1, r2 or r1, g2 or g1, b2 or b1, 1)
		end,
		GetObjectType = function(self)
			return "StatusBar"
		end,
		IsObjectType = function(self, otype)
			return (otype == self:GetObjectType()) and 1 or nil
		end
	}

	function core:CreateStatusBar(name, parent)
		local bar = CreateFrame("Frame", name, parent)
		bar.fg = bar.fg or bar:CreateTexture(name and "$parent.Texture", "ARTWORK")
		bar.bg = bar.bg or bar:CreateTexture(name and "$parent.Background", "BACKGROUND")
		for k, v in pairs(StatusBarPrototype) do bar[k] = v end
		bar:SetRotatesTexture(false)
		bar:HookScript("OnSizeChanged", bar.OnSizeChanged)
		bar:Update()
		bar.bg:Hide()
		return bar
	end
end