local addonName, addon = ...
local L = addon.L

local mod = addon.FriendsInfo or CreateFrame("Frame")
addon.FriendsInfo = mod
mod:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
mod:RegisterEvent("ADDON_LOADED")

FriendsInfoDB = {}

-- cache frequently used globals
local BNGetFriendInfo, GetFriendInfo = BNGetFriendInfo, GetFriendInfo
local FriendsFrame_GetLastOnline = FriendsFrame_GetLastOnline
local GetRealmName = GetRealmName
local format, time, type = string.format, time, type

-- needed locals
local realm

-- module default print function.
local function Print(msg)
    if msg then
        addon:Print(msg, "FriendsInfo")
    end
end

do
    -- this function is hooked to default FriendsFrame scroll frame
    local function FriendsInfo_SetButton(button, index, firstButton)
        local noteColor = "|cfffde05c"

        if button.buttonType == FRIENDS_BUTTON_TYPE_BNET then
            local presenceID, givenName, surname, toonName, toonID, client, isOnline, lastOnline, isAFK, isDND, messageText, noteText, isFriend, unknown = BNGetFriendInfo(button.id)
            if noteText then
                button.info:SetText(button.info:GetText() .. " " .. noteColor .. "(" .. noteText .. ")")
            end
        end

        if button.buttonType ~= FRIENDS_BUTTON_TYPE_WOW then
            return
        end

        local name, level, class, area, connected, status, note = GetFriendInfo(button.id)
        if not name then
            return
        end

        local n
        if note then n = noteColor .. "(" .. note .. ")" end

        -- add the friend to database
        FriendsInfoDB[realm] = FriendsInfoDB[realm] or {}
        FriendsInfoDB[realm][name] = FriendsInfoDB[realm][name] or {}

        -- is the player online?
        if connected then
            -- offline? display old details.
            FriendsInfoDB[realm][name].level = level
            FriendsInfoDB[realm][name].class = class
            FriendsInfoDB[realm][name].area = area
            FriendsInfoDB[realm][name].lastSeen = format("%i", time())

            if n then button.info:SetText(button.info:GetText() .. " " .. n) end
        else
            level = FriendsInfoDB[realm][name].level
            class = FriendsInfoDB[realm][name].class
            if class and level then
                local nameText = name .. ", " .. format(FRIENDS_LEVEL_TEMPLATE, level, class)
                button.name:SetText(nameText)
            end

            local lastSeen = FriendsInfoDB[realm][name].lastSeen
            if lastSeen then
                local infoText = L:F("Last seen %s ago", FriendsFrame_GetLastOnline(lastSeen))
                if n then
                    button.info:SetText(infoText .. " " .. n)
                else
                    button.info:SetText(infoText)
                end
            elseif n then
                button.info:SetText(n)
            end
        end
    end

    -- initializes the module.
    local function FriendsInfo_Initialize()
        realm = GetRealmName()
        hooksecurefunc(FriendsFrameFriendsScrollFrame, "buttonFunc", FriendsInfo_SetButton)
    end

    -- on player entering the world
    function mod:PLAYER_ENTERING_WORLD()
        FriendsInfo_Initialize()
    end
end

-- frame event handler.
function mod:ADDON_LOADED(name)
	self:UnregisterEvent("ADDON_LOADED")
    if name == addonName then
	    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    end
end