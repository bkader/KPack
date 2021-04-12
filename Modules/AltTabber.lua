assert(KPack, "KPack not found!")
KPack:AddModule("AltTabber", "Allows you to never miss important events even if you play with the game sound off.", function(_, core, L)
    if core:IsDisabled("AltTabber") then return end

    local _GetCVar, _SetCVar = GetCVar, SetCVar
    local _PlaySoundFile = PlaySoundFile
    local DB

    local function disabled()
        return not DB.enabled
    end

    local options = {
        type = "group",
        name = "AltTabber",
        get = function(i)
            return DB[i[#i]]
        end,
        set = function(i, val)
            DB[i[#i]] = val
        end,
        args = {
            enabled = {
                type = "toggle",
                name = L["Enable"],
                order = 0
            },
            sep = {
                type = "description",
                name = " ",
                order = 0.1,
                width = "full"
            },
            tip = {
                type = "description",
                name = L["Tick the sounds you want AltTabber to play:"],
                order = 1,
                disabled = disabled,
                width = "full"
            },
            ready = {
                type = "toggle",
                name = READY_CHECK,
                order = 2,
                disabled = disabled
            },
            lfg = {
                type = "toggle",
                name = LFG_TYPE_RANDOM_DUNGEON,
                order = 3,
                disabled = disabled
            },
            warning = {
                type = "toggle",
                name = RAID_WARNING,
                order = 4,
                disabled = disabled
            },
            invite = {
                type = "toggle",
                name = GROUP_INVITE,
                order = 5,
                disabled = disabled
            },
            whisper = {
                type = "toggle",
                name = WHISPER,
                order = 6,
                disabled = disabled
            }
        }
    }

    local function LoadDatabase()
        if not DB then
            if type(core.db.AltTabber) ~= "table" or not next(core.db.AltTabber) then
                core.db.AltTabber = {
                    enabled = true,
                    ready = true,
                    lfg = true,
                    warning = true,
                    invite = true,
                    whisper = true
                }
            end
            DB = core.db.AltTabber
        end
    end

    core:RegisterForEvent("PLAYER_LOGIN", function()
        LoadDatabase()
        core.options.args.Options.args.AltTabber = options
    end)

    core:RegisterForEvent("PLAYER_ENTERING_WORLD", function()
        LoadDatabase()
        if not StaticPopupDialogs["CONFIRM_BATTLEFIELD_ENTRY"].OnShow then
            StaticPopupDialogs["CONFIRM_BATTLEFIELD_ENTRY"].OnShow = function()
                _PlaySoundFile("Sound\\Spells\\PVPEnterQueue.wav")
            end
        end
    end)

    local function AltTabber_PlaySound(file, var)
        if not DB.enabled or (var and not DB[var]) then
            return
        end

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

    core:RegisterForEvent("READY_CHECK", function()
        AltTabber_PlaySound("Sound\\Interface\\levelup2.wav", "ready")
    end)

    core:RegisterForEvent("LFG_PROPOSAL_SHOW", function()
        AltTabber_PlaySound("Sound\\Interface\\LFG_DungeonReady.wav", "lfg")
    end)

    core:RegisterForEvent("CHAT_MSG_RAID_WARNING", function()
        AltTabber_PlaySound("Sound\\Interface\\RaidWarning.wav", "warning")
    end)

    core:RegisterForEvent("PARTY_INVITE_REQUEST", function(_, name)
        if core.IgnoreMore and core.IgnoreMore:IsIgnored(name) then
            return
        end
        AltTabber_PlaySound("Sound\\Interface\\iPlayerInviteA.wav", "invite")
    end)

    core:RegisterForEvent("CHAT_MSG_WHISPER", function(_, _, name)
        if core.IgnoreMore and core.IgnoreMore:IsIgnored(name) then
            return
        end
        AltTabber_PlaySound("Interface\\AddOns\\KPack\\Media\\Sounds\\Whisper.ogg", "whisper")
    end)
end)