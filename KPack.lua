local addonName, addon = ...
local L = addon.L

_G.KPack = addon

local CreateFrame = CreateFrame
local lower, tostring = string.lower, tostring

-- used to replace fonts
do
	local nonLatin = {ruRU = true, koKR = true, zhCN = true, zhTW = true}
	if nonLatin[GetLocale()] then
		addon.nonLatin = true
	end
end

local f = CreateFrame("Frame")
f:SetScript("OnEvent", function(self, event, ...) self[event](self, event, ...) end)
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_FLAGS_CHANGED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")

local help = "|cffffd700%s|r: %s"

local function SlashCommandHandler(cmd)
    if cmd:lower() == "help" or cmd:lower() == "" then
        addon:Print(L["Accessible module commands are:"])
        print(help:format("/abm", L:F("access |caaf49141%s|r module commands", "ActionBars")))
        print(help:format("/align", L:F("access |caaf49141%s|r module commands", "Align")))
        print(help:format("/auto", L:F("access |caaf49141%s|r module commands", "AutoMate")))
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
    else
        addon:Print(L:F("Available command for |caaf49141%s|r is |cffffd700%s|r", "/kpack", "help"))
    end
end

-- main print function
function addon:Print(msg, pref)
    if msg then
        -- prepare the prefix:
        if not pref then
            pref = "|cff33ff99" .. addonName .. "|r"
        else
            pref = "|cff33ff99" .. addonName .. "|r - |caaf49141" .. pref .. "|r"
        end
        print(string.format("%s : %s", pref, tostring(msg)))
    end
end

-- used to kill a frame
local function noFunc() end
do
    function addon:Kill(frame)
        if frame and frame.SetScript then
            frame:UnregisterAllEvents()
            frame:SetScript("OnEvent", nil)
            frame:SetScript("OnUpdate", nil)
            frame:SetScript("OnHide", nil)
            frame:Hide()
            frame.SetScript = noFunc
            frame.RegisterEvent = noFunc
            frame.RegisterAllEvents = noFunc
            frame.Show = noFunc
        end
    end
end

-- Timer mimic
do
    local setmetatable = setmetatable
    local Timer = addon.Timer
    if not Timer then
        Timer = {}
        addon.Timer = Timer
    end

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
end

-- Events
function f:ADDON_LOADED(_, name)
    if lower(name) == lower(addonName) then
        addon:Print(L["addon loaded. use |cffffd700/kp help|r for help."])

        SlashCmdList["KPACK"] = SlashCommandHandler
        _G.SLASH_KPACK1 = "/kp"
        _G.SLASH_KPACK2 = "/kpack"

        addon.name = select(1, UnitName("player"))
        addon.class = select(2, UnitClass("player"))
    end
end

do
    local collectgarbage = collectgarbage
    local UnitIsAFK = UnitIsAFK
    local InCombatLockdown = InCombatLockdown
    eventcount = 0

    function f:PLAYER_ENTERING_WORLD(event, unit)
        eventcount = eventcount + 1

        if (InCombatLockdown() and eventcount > 25000) or (not InCombatLockdown() and eventcount > 10000) or event == "PLAYER_ENTERING_WORLD" then
            collectgarbage("collect")
            eventcount = 0
            self:UnregisterEvent(event)
        else
            if unit ~= "player" then return end
            if UnitIsAFK(unit) then collectgarbage("collect") end
        end
    end
    f.PLAYER_FLAGS_CHANGED = f.PLAYER_ENTERING_WORLD
end

-- Addon sync
function addon:Sync(prefix, msg)
    local zoneType = select(2, IsInInstance())
    if zoneType == "pvp" or zoneType == "arena" then
        SendAddonMessage(prefix, msg, "BATTLEGROUND")
    elseif GetRealNumRaidMembers() > 0 then
        SendAddonMessage(prefix, msg, "RAID")
    elseif GetRealNumPartyMembers() > 0 then
        SendAddonMessage(prefix, msg, "PARTY")
    end
end