local folder, core = ...
_G[folder] = core

-- main saved varialbes
KPackDB =  {}
KPackCharDB =  {}
-------------------------------------------------------------------------------
-- Event handling system
--

do
    local F, events = CreateFrame("Frame"), {}

    local pairs = pairs
    local next = next
    local strmatch = string.match

    local function Raise(_, event, ...)
        if events[event] then
            for module in pairs(events[event]) do
                module[event](module, ...)
            end
        end
    end

    local function RegisterEvent(module, event, func)
        if func then
            rawset(module, event, func)
        end
        events[event] = events[event] or {}
        events[event][module] = true
        if strmatch(event, "^[%u_]+$") then
            F:RegisterEvent(event)
        end
        return module
    end

    local function UnregisterEvent(module, event)
        if events[event] then
            events[event][module] = nil
            if not next(events[event]) and strmatch(event, "^[%u_]+$") then -- don't unregister unless the event table is empty
                F:UnregisterEvent(event)
            end
        end
        return module
    end

    local Module = {
        __newindex = RegisterEvent,
        __call = Raise,
        __index = {
            RegisterEvent = RegisterEvent,
            UnregisterEvent = UnregisterEvent,
            Raise = Raise
        }
    }

    core.Events = setmetatable({}, { __call = function(eve)
            local module = setmetatable({}, Module)
            eve[#eve + 1] = module
            return module
        end
    })

    F:SetScript("OnEvent", Raise)
end

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
-- Core
--

do
    local E = core:Events()
    local L = core.L

    local tostring = tostring

    -- used to replace fonts
    do
        local nonLatin = {ruRU = true, koKR = true, zhCN = true, zhTW = true}
        if nonLatin[GetLocale()] then
            core.nonLatin = true
        end
    end

    local help = "|cffffd700%s|r: %s"

    local function SlashCommandHandler(cmd)
        if cmd:lower() == "help" or cmd:lower() == "" then
            core:Print(L["Accessible module commands are:"])
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
            core:Print(L:F("Available command for |caaf49141%s|r is |cffffd700%s|r", "/kpack", "help"))
        end
    end

    -- main print function
    function core:Print(msg, pref)
        if msg then
            -- prepare the prefix:
            if not pref then
                pref = "|cff33ff99" .. folder .. "|r"
            else
                pref = "|cff33ff99" .. folder .. "|r - |caaf49141" .. pref .. "|r"
            end
            print(string.format("%s : %s", pref, tostring(msg)))
        end
    end

    -- used to kill a frame
    local function noFunc()
    end
    do
        function core:Kill(frame)
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

    -- Events
    function E:ADDON_LOADED(name)
        if name == folder then
            self:UnregisterEvent("ADDON_LOADED")
            core:Print(L["addon loaded. use |cffffd700/kp help|r for help."])

            SlashCmdList["KPACK"] = SlashCommandHandler
            _G.SLASH_KPACK1 = "/kp"
            _G.SLASH_KPACK2 = "/kpack"

            core.name = select(1, UnitName("player"))
            core.class = select(2, UnitClass("player"))
            core.guid = UnitGUID("player")
        end
    end

	do
	    -- automatic garbage collection
	    local collectgarbage = collectgarbage
	    local UnitIsAFK = UnitIsAFK
	    local InCombatLockdown = InCombatLockdown
	    local eventcount = 0

	    local f = CreateFrame("Frame")
	    f:SetScript("OnEvent", function(self, event, ...)
            if (InCombatLockdown() and eventcount > 25000) or (not InCombatLockdown() and eventcount > 10000) or event == "PLAYER_ENTERING_WORLD" then
                collectgarbage("collect")
                eventcount = 0
                self:UnregisterEvent(event)
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
	    f:RegisterEvent("PLAYER_FLAGS_CHANGED")
	    f:RegisterEvent("PLAYER_ENTERING_WORLD")
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