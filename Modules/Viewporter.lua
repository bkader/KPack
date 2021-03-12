local addonName, addon = ...
local L = addon.L

-- module event frame
local f = CreateFrame("Frame")
f.lastUpdated = 0
f:RegisterEvent("ADDON_LOADED")

-- saved variables and defaults
ViewporterDB = {}
local defaults = {
    enabled = true,
    left = 0,
    right = 0,
    top = 0,
    bottom = 0,
    firstTime = true
}

-- needed locales
local updateInterval = 0.1
local initialized = false
local sides = {
    left = true,
    right = true,
    top = true,
    bottom = true
}

-- module's print function
local function Print(msg)
    if msg then
        addon:Print(msg, "Viewporter")
    end
end

-- called everytime we need to make changes to the viewport
local function Viewporter_Initialize()
    local left, right, top, bottom = 0, 0, 0, 0
    if ViewporterDB.enabled then
        left = ViewporterDB.left
        right = ViewporterDB.right
        top = ViewporterDB.top
        bottom = ViewporterDB.bottom
    end

    local scale = 768 / UIParent:GetHeight()
    WorldFrame:SetPoint("TOPLEFT", (left * scale), -(top * scale))
    WorldFrame:SetPoint("BOTTOMRIGHT", -(right * scale), (bottom * scale))

    initialized = true
end

-- slash commands handler
local function SlashCommandHandler(msg)
    local cmd, rest = strsplit(" ", msg, 2)
    cmd = cmd:lower()
    rest = rest and rest:trim() or ""

    if cmd == "toggle" then
        ViewporterDB.enabled = not ViewporterDB.enabled
        Print(ViewporterDB.enabled and L["|cff00ff00enabled|r"] or L["|cffff0000disabled|r"])
        initialized = false
    elseif cmd == "enable" or cmd == "on" then
        ViewporterDB.enabled = true
        initialized = false
        Print(L["|cff00ff00enabled|r"])
    elseif cmd == "disable" or cmd == "off" then
        ViewporterDB.enabled = false
        initialized = false
        Print(L["|cffff0000disabled|r"])
    elseif cmd == "reset" or cmd == "default" then
        ViewporterDB = defaults
        initialized = false
        Print(L["module's settings reset to default."])
    elseif sides[cmd] then
        local size = tonumber(rest)
        size = size or 0
        ViewporterDB[cmd] = size
        initialized = false
    else
        Print(L:F("Acceptable commands for: |caaf49141%s|r", "/vp"))
        print("|cffffd700toggle|r", L["Toggles viewporter status."])
        print("|cffffd700enable|r", L["Enables viewporter."])
        print("|cffffd700disable|r", L["Disables viewporter."])
        print("|cffffd700reset|r", L["Resets module settings to default."])
        print("|cffffd700side|r [|cff00ffffn|r]", L["where side is left, right, top or bottom."])
        print(L:F("|cffffd700Example|r: %s", "/vp bottom 120"))
        return
    end

    Viewporter_Initialize()
end

-- frame event handler
local function EventHandler(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name:lower() == addonName:lower() then
            f:UnregisterEvent("ADDON_LOADED")

            if next(ViewporterDB) == nil then
                ViewporterDB = defaults
            end

            SlashCmdList["KPACKVIEWPORTER"] = SlashCommandHandler
            SLASH_KPACKVIEWPORTER1 = "/vp"
            SLASH_KPACKVIEWPORTER2 = "/viewport"
            SLASH_KPACKVIEWPORTER3 = "/viewporter"

            f:RegisterEvent("PLAYER_ENTERING_WORLD")
        end
    elseif f[event] and type(f[event]) == "function" then
        return f[event](self, ...)
    end
end
f:SetScript("OnEvent", EventHandler)

do
    local function Viewporter_OnUpdate(self, elapsed)
        self.lastUpdated = self.lastUpdated + elapsed
        if self.lastUpdated > updateInterval then
            if ViewporterDB.firstTime then
                ViewporterDB.firstTime = false
            end
            if not initialized then
                Viewporter_Initialize()
            end
            self.lastUpdated = 0
        end
    end

    function f:PLAYER_ENTERING_WORLD()
        if ViewporterDB.enabled then
            f:SetScript("OnUpdate", Viewporter_OnUpdate)
        else
            f:SetScript("OnUpdate", nil)
        end
        f:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end
end