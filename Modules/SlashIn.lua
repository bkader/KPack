local addonName, addon = ...

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")

-- cache frequently used globals
local tonumber = tonumber
local MacroEditBox = MacroEditBox
local MacroEditBox_OnEvent

-- module's print function
local function Print(msg)
    if msg then
        addon:Print(msg, "SlashIn")
    end
end

local SlashCommandHandler
do
    -- callback to use for Timer
    local function OnCallback(cmd)
        MacroEditBox_OnEvent(MacroEditBox, "EXECUTE_CHAT_LINE", cmd)
    end

    -- slash command handler
    function SlashCommandHandler(msg)
        local secs, cmd = msg:match("^([^%s]+)%s+(.*)$")
        secs = tonumber(secs)
        if not secs or #cmd == 0 then
            Print("usage: /in <seconds> <command>")
            print("example: /in 1.5 /say hi")
        elseif cmd:find("cast") or cmd:find("use") then
            Print("/use or /cast are blocked by Blizzard UI.")
        else
            addon.Timer.After(tonumber(secs) - 0.5, function() OnCallback(cmd) end)
        end
    end
end

-- frame event handler
local function EventHandler(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name:lower() == addonName:lower() then
            f:UnregisterEvent("ADDON_LOADED")

            MacroEditBox_OnEvent = MacroEditBox:GetScript("OnEvent")

            SlashCmdList["KPACKSLASHIN"] = SlashCommandHandler
            SLASH_KPACKSLASHIN1 = "/in"
            SLASH_KPACKSLASHIN2 = "/slashin"
        end
    end
end
f:SetScript("OnEvent", EventHandler)