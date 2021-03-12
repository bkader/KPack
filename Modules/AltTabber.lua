local addonName, addon = ...

local mod = CreateFrame("Frame")
mod:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
mod:RegisterEvent("PLAYER_ENTERING_WORLD")

local _GetCVar, _SetCVar = GetCVar, SetCVar
local _PlaySoundFile = PlaySoundFile

function mod:PLAYER_ENTERING_WORLD()
    self:RegisterEvent("CHAT_MSG_RAID_WARNING")
    self:RegisterEvent("READY_CHECK")
    self:RegisterEvent("LFG_PROPOSAL_SHOW")
    if not StaticPopupDialogs["CONFIRM_BATTLEFIELD_ENTRY"].OnShow then
        StaticPopupDialogs["CONFIRM_BATTLEFIELD_ENTRY"].OnShow = function()
            _PlaySoundFile("Sound\\Spells\\PVPEnterQueue.wav")
        end
    end
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end

local function AltTabber_PlaySound(file)
    local Sound_EnableSFX = _GetCVar("Sound_EnableSFX")
    local Sound_EnableAllSound = _GetCVar("Sound_EnableAllSound")

    if Sound_EnableSFX == "0" then
        if _GetCVar("Sound_EnableSoundWhenGameIsInBG") == "0" then
            _SetCVar("Sound_EnableSoundWhenGameIsInBG", "1")
        elseif Sound_EnableAllSound == "0" then
            _SetCVar("Sound_EnableAllSound", "1")
            _SetCVar("Sound_EnableSFX", "0")
            _SetCVar("Sound_EnableAmbience", "0")
            _SetCVar("Sound_EnableMusic", "0")
        else
            _PlaySoundFile(file)
        end
    end
end

function mod:READY_CHECK()
    AltTabber_PlaySound("Sound\\Interface\\levelup2.wav")
end

function mod:LFG_PROPOSAL_SHOW()
    AltTabber_PlaySound("Sound\\Interface\\LFG_DungeonReady.wav")
end

function mod:CHAT_MSG_RAID_WARNING()
    AltTabber_PlaySound("Sound\\Interface\\RaidWarning.wav")
end