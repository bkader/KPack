local folder, core = ...
_G[folder] = core

-- main saved varialbes
KPackDB = {}
KPackCharDB = {}

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
    waitFrame:SetScript("OnUpdate",
    function(self, elapsed)
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
        cmd = cmd and cmd:lower()
        if cmd == "help" then
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
        elseif cmd == "about" or cmd == "info" then
            core:Print("This small addon was made with big passion by |cfff58cbaKader|r.\n If you have suggestions or you are facing issues with my addons, feel free to message me on the forums, Github, CurseForge or Discord:\n|cffffd700bkader#6361|r or |cff7289d9https://discord.gg/a8z5CyS3eW|r")
        else
            InterfaceOptionsFrame_OpenToCategory(core.panel)
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

    function core:RegisterCallback(event, callback, ...)
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

    local function SetupOptionsPanel(panel)
        panel.title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        panel.title:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -16)
        panel.title:SetSize(350, 15)
        panel.title:SetJustifyH("LEFT")
        panel.title:SetJustifyV("TOP")
        panel.title:SetText("|cfff58cbaKader|r|caaf49141Pack|r")

        local scrollFrame = CreateFrame("ScrollFrame", "$parentScrollFrame", panel, "UIPanelScrollFrameTemplate")
        scrollFrame:SetSize(panel:GetWidth(), panel:GetHeight())
        scrollFrame:SetPoint("TOPLEFT", 10, -38)
        scrollFrame:SetPoint("BOTTOMRIGHT", -30, 32)

        local scrollBar = _G[scrollFrame:GetName() .. "ScrollBar"]

        local scrollChild = CreateFrame("Frame", "$parentScrollChild", scrollFrame)
        scrollChild:SetHeight(#core.modules / 2)
        scrollChild:SetWidth(scrollFrame:GetWidth())
        scrollChild:SetAllPoints(scrollFrame)
        scrollFrame:SetScrollChild(scrollChild)

        -- reload ui button
        local reload = CreateFrame("Button", nil, panel, "KPackButtonTemplate")
        reload:SetWidth(100)
        reload:SetPoint("BOTTOMRIGHT", -5, 5)
        reload:SetText(L["Reload UI"])
        reload:SetScript("OnClick", function(self) ReloadUI() end)

        -- enable all
        local enable = CreateFrame("Button", nil, panel, "KPackButtonTemplate")
        enable:SetWidth(85)
        enable:SetPoint("BOTTOMLEFT", 5, 5)
        enable:SetText(L["Enable All"])

        local disable = CreateFrame("Button", nil, panel, "KPackButtonTemplate")
        disable:SetWidth(85)
        disable:SetPoint("LEFT", enable, "RIGHT")
        disable:SetText(L["Disable All"])

        -- list all modules.
        local buttons = {}
        for i, mod in ipairs(core.modules) do
            local check = CreateFrame("CheckButton", "KPackModule" .. i, scrollChild, "ChatConfigCheckButtonTemplate")
            _G["KPackModule" .. i .. "Text"]:SetText(mod.name)
            if i == 1 then
                check:SetPoint("TOPLEFT")
            elseif i % 2 == 0 then
                check:SetPoint("LEFT", buttons[i - 1], "RIGHT", 175, 0)
            else
                check:SetPoint("TOPLEFT", buttons[i - 2], "BOTTOMLEFT")
            end

            check:SetChecked(not core:IsDisabled(mod.name))

            check:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine(mod.name)
                if mod.desc then
                    GameTooltip:AddLine(mod.desc, 1, 1, 1, 1, false)
                end
                GameTooltip:Show()
            end)
            check:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
            check:SetScript("OnClick", function(self)
                if self:GetChecked() == 1 then
                    KPackDB.disabled[mod.name] = true
                else
                    KPackDB.disabled[mod.name] = nil
                end

                reload:Enable()
            end)

            buttons[i] = check
        end

        enable:SetScript("OnClick", function(self)
            KPackDB.disabled = {}
            for _, check in ipairs(buttons) do
                check:SetChecked(true)
            end
        end)

        disable:SetScript("OnClick", function(self)
            for _, check in ipairs(buttons) do
                check:SetChecked(false)
            end
            for _, mod in ipairs(core.modules) do
                KPackDB.disabled[mod.name] = true
            end
        end)
    end

    core:RegisterCallback("ADDON_LOADED", function(_, name)
        if name == folder then
            core:Print(L["addon loaded. use |cffffd700/kp help|r for help."])

            SlashCmdList["KPACK"] = SlashCommandHandler
            _G.SLASH_KPACK1 = "/kp"
            _G.SLASH_KPACK2 = "/kpack"

            core.name = select(1, UnitName("player"))
            core.class = select(2, UnitClass("player"))
            core.guid = UnitGUID("player")

            core.panel = CreateFrame("Frame", "KPackInterfaceOptions", UIParent)
            core.panel.name = folder
            core.panel:SetScript("OnShow", function(self) SetupOptionsPanel(self) end)
            InterfaceOptions_AddCategory(core.panel)

            if core.moduleslist then
                for i = 1, #core.moduleslist do
                    core.moduleslist[i](folder, core, L)
                end
                core.moduleslist = nil
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

    self.modules = self.modules or {}
    self.modules[#self.modules + 1] = {name = name, desc = desc}
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