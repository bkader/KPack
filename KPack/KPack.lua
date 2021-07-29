local folder, core = ...
_G.KPack = core
core.callbacks = core.callbacks or LibStub("CallbackHandler-1.0"):New(core)
core.version = GetAddOnMetadata("KPack", "Version")

local L = core.L
core.ACD = LibStub("AceConfigDialog-3.0")
core.LSM = LibStub("LibSharedMedia-3.0")
local LBF = LibStub("LibButtonFacade", true)

-- player & class
core.guid = UnitGUID("player")
core.name = UnitName("player")
core.class = select(2, UnitClass("player"))
core.race = select(2, UnitRace("player"))
core.faction = UnitFactionGroup("player")
core.classcolors = {
	DEATHKNIGHT = {r = 0.77, g = 0.12, b = 0.23, colorStr = "ffc41f3b"},
	DRUID = {r = 1, g = 0.49, b = 0.04, colorStr = "ffff7d0a"},
	HUNTER = {r = 0.67, g = 0.83, b = 0.45, colorStr = "ffabd473"},
	MAGE = {r = 0.41, g = 0.8, b = 0.94, colorStr = "ff3fc7eb"},
	PALADIN = {r = 0.96, g = 0.55, b = 0.73, colorStr = "fff58cba"},
	PRIEST = {r = 1, g = 1, b = 1, colorStr = "ffffffff"},
	ROGUE = {r = 1, g = 0.96, b = 0.41, colorStr = "fffff569"},
	SHAMAN = {r = 0, g = 0.44, b = 0.87, colorStr = "ff0070de"},
	WARLOCK = {r = 0.58, g = 0.51, b = 0.79, colorStr = "ff8788ee"},
	WARRIOR = {r = 0.78, g = 0.61, b = 0.43, colorStr = "ffc79c6e"}
}
core.mycolor = core.classcolors[core.class]

-------------------------------------------------------------------------------
-- C_Timer mimic
--

do
	local setmetatable = setmetatable
	local Timer = {}

	local TickerPrototype = {}
	local TickerMetatable = {
		__index = TickerPrototype,
		__metatable = true
	}

	local waitTable = {}
	local waitFrame = _G.KPackTimerFrame or CreateFrame("Frame", "KPackTimerFrame", UIParent)
	waitFrame:SetScript("OnUpdate", function(self, elapsed)
		local total = #waitTable
		for i = 1, total do
			local ticker = waitTable[i]
			if ticker then
				if ticker._cancelled then
					tremove(waitTable, i)
				elseif ticker._delay > elapsed then
					ticker._delay = ticker._delay - elapsed
					i = i + 1
				else
					ticker._callback(ticker)
					if ticker._remainingIterations == -1 then
						ticker._delay = ticker._duration
						i = i + 1
					elseif ticker._remainingIterations > 1 then
						ticker._remainingIterations = ticker._remainingIterations - 1
						ticker._delay = ticker._duration
						i = i + 1
					elseif ticker._remainingIterations == 1 then
						tremove(waitTable, i)
						total = total - 1
					end
				end
			end
		end

		if #waitTable == 0 then
			self:Hide()
		end
	end)

	local function AddDelayedCall(ticker, oldTicker)
		if oldTicker and type(oldTicker) == "table" then
			ticker = oldTicker
		end
		tinsert(waitTable, ticker)
		waitFrame:Show()
	end

	local function CreateTicker(duration, callback, iterations)
		local ticker = setmetatable({}, TickerMetatable)
		ticker._remainingIterations = iterations or -1
		ticker._duration = duration
		ticker._delay = duration
		ticker._callback = callback

		AddDelayedCall(ticker)
		return ticker
	end

	function Timer.After(duration, callback)
		AddDelayedCall({
			_remainingIterations = 1,
			_delay = duration,
			_callback = callback
		})
	end

	function Timer.NewTimer(duration, callback)
		return CreateTicker(duration, callback, 1)
	end

	function Timer.NewTicker(duration, callback, iterations)
		return CreateTicker(duration, callback, iterations)
	end

	function TickerPrototype:Cancel()
		self._cancelled = true
	end

	core.After = Timer.After
	core.NewTimer = Timer.NewTimer
	core.NewTicker = Timer.NewTicker
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

function core:RegisterForEvent(event, callback, ...)
	if not self.frame then
		self.frame = CreateFrame("Frame")
		function self.frame:OnEvent(event, ...)
			for callback, args in next, self.callbacks[event] do
				callback(args, ...)
			end
		end
		self.frame:SetScript("OnEvent", self.frame.OnEvent)
	end
	if not self.frame.callbacks then
		self.frame.callbacks = {}
	end
	if not self.frame.callbacks[event] then
		self.frame.callbacks[event] = {}
	end
	self.frame.callbacks[event][callback] = {...}
	self.frame:RegisterEvent(event)
end

-------------------------------------------------------------------------------
-- Options
--

do
	local options = {
		type = "group",
		name = "|cfff58cbaKader|r|caaf49141Pack|r " .. core.version,
		childGroups = "tab",
		args = {
			Options = {
				type = "group",
				name = L["Options"],
				order = 0,
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
			print(help:format("/about", "about the addon."))
		elseif cmd == "about" or cmd == "info" then
			core:Print("This small addon was made with big passion by |cfff58cbaKader|r.\n If you have suggestions or you are facing issues with my addons, feel free to message me on the forums, Github, CurseForge or Discord:\n|cffffd700bkader#6361|r or |cff7289d9https://discord.gg/a8z5CyS3eW|r")
		else
			core:OpenConfig()
		end
	end

	function core:OpenConfig(...)
		self.ACD:SetDefaultSize(folder, 655, 500)
		if ... then
			self.ACD:Open(folder)
			self.ACD:SelectGroup(folder, ...)
		elseif not self.ACD:Close(folder) then
			self.ACD:Open(folder)
		end
	end

	core:RegisterForEvent("ADDON_LOADED", function(_, name)
		if name == folder then
			KPackDB = KPackDB or {}
			core.db = KPackDB

			KPackCharDB = KPackCharDB or {}
			core.char = KPackCharDB

			LibStub("AceConfig-3.0"):RegisterOptionsTable(folder, core.options)
			core.optionsFrame = core.ACD:AddToBlizOptions(folder, folder)

			SlashCmdList["KPACK"] = SlashCommandHandler
			_G.SLASH_KPACK1 = "/kp"
			_G.SLASH_KPACK2 = "/kpack"

			core.LSM:Register("statusbar", "Half", [[Interface\Addons\KPack\Media\Statusbar\half]])
			core.LSM:Register("statusbar", "KPack", [[Interface\Addons\KPack\Media\Statusbar\statusbar]])
			core.LSM:Register("statusbar", "KPack Blank", [[Interface\Addons\KPack\Media\Textures\blank]])
			core.LSM:Register("statusbar", "KPack Gloss", [[Interface\Addons\KPack\Media\Statusbar\gloss]])
			core.LSM:Register("statusbar", "KPack Norm", [[Interface\Addons\KPack\Media\Statusbar\norm]])
			core.LSM:Register("statusbar", "Melli", [[Interface\Addons\KPack\Media\Statusbar\melli]])
			core.LSM:Register("font", "Hooge", [[Interface\Addons\KPack\Media\Fonts\HOOGE.ttf]])
			core.LSM:Register("font", "Yanone", [[Interface\Addons\KPack\Media\Fonts\yanone.ttf]])

			core:Print(L["addon loaded. use |cffffd700/kp|r to access options."])

			core.ElvUI = _G.ElvUI and select(1, unpack(ElvUI)) or false
			if core.moduleslist then
				for i = 1, #core.moduleslist do
					core.moduleslist[i](folder, core, L)
				end
				core.moduleslist = nil
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
			if (InCombatLockdown() and eventcount > 25000) or (not InCombatLockdown() and eventcount > 10000) or event == "PLAYER_ENTERING_WORLD" then
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
		name = name,
		desc = L[desc]
	}
end

function core:IsDisabled(...)
	KPackDB.disabled = KPackDB.disabled or {}
	for i = 1, select("#", ...) do
		local name = select(i, ...)
		if KPackDB.disabled[name] == true then
			name = nil
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
			-- print("here", modname, mod:IsEnabled())
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