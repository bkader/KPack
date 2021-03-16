local folder, core = ...

local E = core:Events()
local L = core.L

local frame = CreateFrame("Frame")

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
local initialized
local sides = {
	left = "left",
	right = "right",
	top = "top",
	bottom = "bottom",
	bot = "bottom"
}

-- module's print function
local function Print(msg)
    if msg then
        core:Print(msg, "Viewporter")
    end
end

-- called everytime we need to make changes to the viewport
local function Viewporter_Initialize()
	if initialized then return end
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
        initialized = nil
        frame:Show()
    elseif cmd == "enable" or cmd == "on" then
        ViewporterDB.enabled = true
        initialized = nil
        frame:Show()
        Print(L["|cff00ff00enabled|r"])
    elseif cmd == "disable" or cmd == "off" then
        ViewporterDB.enabled = false
        initialized = nil
        frame:Show()
        Print(L["|cffff0000disabled|r"])
    elseif cmd == "reset" or cmd == "default" then
        ViewporterDB = defaults
        initialized = nil
        frame:Show()
        Print(L["module's settings reset to default."])
    elseif sides[cmd] then
        local size = tonumber(rest)
        size = size or 0
        ViewporterDB[sides[cmd]] = size
        initialized = nil
        frame:Show()
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

do
    local function Viewporter_OnUpdate(self, elapsed)
        if ViewporterDB.firstTime then
            ViewporterDB.firstTime = false
        end
        Viewporter_Initialize()
		self:Hide()
    end

    function E:PLAYER_ENTERING_WORLD()
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        if ViewporterDB.enabled then
            frame:SetScript("OnUpdate", Viewporter_OnUpdate)
        else
            frame:SetScript("OnUpdate", nil)
        end
    end
end

-- frame event handler
function E:ADDON_LOADED(name)
    if name == folder then
        self:UnregisterEvent("ADDON_LOADED")

        if next(ViewporterDB) == nil then
            ViewporterDB = defaults
        end

        SlashCmdList["KPACKVIEWPORTER"] = SlashCommandHandler
        SLASH_KPACKVIEWPORTER1 = "/vp"
        SLASH_KPACKVIEWPORTER2 = "/viewport"
        SLASH_KPACKVIEWPORTER3 = "/viewporter"

        self:RegisterEvent("PLAYER_ENTERING_WORLD")
    end
end