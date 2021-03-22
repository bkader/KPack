assert(KPack, "KPack not found!")
KPack:AddModule("PullnBreak", function(folder, core, L)
    if core:IsDisabled("PullnBreak") then return end

    local mod = core.PullnBreak or {}
    core.PullnBreak = mod

    local DB
    local defaults = {
        type = "pull",
        duration = 10,
        starttime = 0
    }

    -- cache frequently used global
    local formatMin = INT_SPELL_DURATION_MIN
    local formatSec = INT_SPELL_DURATION_SEC
    local GetRealNumRaidMembers = GetRealNumRaidMembers
    local GetRealNumPartyMembers = GetRealNumPartyMembers
    local IsRaidLeader, IsRaidOfficer = IsRaidLeader, IsRaidOfficer
    local SendChatMessage = SendChatMessage
    local floor, ceil = math.floor, math.ceil

    -- needed locals
    local started, isBreak
    local frame = CreateFrame("Frame")

    -- guesses the channel to which send the message
    local function PullnBreak_GuessChannel()
        local channel
        if GetRealNumRaidMembers() > 0 then
            channel = (IsRaidLeader() or IsRaidOfficer()) and "RAID_WARNING" or "RAID"
        elseif GetRealNumPartyMembers() > 0 then
            channel = "PARTY"
        end
        return channel
    end

    -- announces the message
    local function PullnBreak_Announce(msg, channel)
        if msg then
            channel = channel or PullnBreak_GuessChannel()
            if channel then
                SendChatMessage(msg, channel)
            end
        end
    end

    -- starts the timer
    function mod:StartTimer(dur, t)
        local channel = PullnBreak_GuessChannel()
        if not channel then
            return
        end

        started = not started
        isBreak = (t == "break")
        local ended = false

        dur = dur or DB.duration
        DB.type = isBreak and "break" or "pull"

        local timer = floor(isBreak and dur * 60 or dur) + 1
        DB.duration = timer

        if not started then
            PullnBreak_Announce(isBreak and L["{rt7} Break Canceled {rt7}"] or L["{rt7} Pull ABORTED {rt7}"])
            DB.type = "pull"
            DB.starttime = 0
            ended = true
            isBreak = nil
        end

        local startTime = floor(GetTime())
        DB.starttime = startTime
        local throttle = timer

        frame:SetScript("OnUpdate", function(self, elapsed)
            ended = not started

            if ended then
                self:SetScript("OnUpdate", nil)
                return
            end

            local countdown = (startTime - floor(GetTime()) + timer)

            if (countdown + 1 == throttle) and countdown >= 0 then
                if countdown == 0 then
                    local output = isBreak and L["{rt1} Break Ends Now {rt1}"] or L["{rt8} Pull Now! {rt8}"]
                    PullnBreak_Announce(output)
                    DB.type = "pull"
                    DB.starttime = 0

                    throttle = countdown
                    ended = true
                    started = nil
                    isBreak = nil
                else
                    if throttle == timer then
                        local output

                        if countdown >= 60 then
                            output = L:F(isBreak and "%s Break starts now!" or "Pull in %s", formatMin:format(ceil(countdown / 60)))
                        else
                            output = L:F(isBreak and "%s Break starts now!" or "Pull in %s", formatSec:format(countdown))
                        end

                        core:Sync("DBMv4-Pizza", ("%s\t%s"):format(countdown, isBreak and "Break time!" or "Pull in"))
                        PullnBreak_Announce(output)
                    elseif countdown >= 60 and countdown % 60 == 0 then
                        local output = L:F(isBreak and "Break ends in %s" or "Pull in %s", formatMin:format(ceil(countdown / 60)))
                        PullnBreak_Announce(output)
                    elseif (countdown >= 10 and countdown <= 30) and countdown % 15 == 0 then
                        local output

                        if countdown == 30 then
                            output = L:F(isBreak and "Break ends in %s" or "Pull in %s", formatSec:format(countdown))
                        elseif not isBreak then
                            output = L:F("Pull in %s", formatSec:format(countdown))
                        end

                        PullnBreak_Announce(output)
                    elseif not isBreak and (countdown == 10 or countdown == 7 or countdown == 5 or (countdown > 0 and countdown <= 3)) then
                        PullnBreak_Announce(L:F("Pull in %s", formatSec:format(countdown)))
                    end

                    throttle = countdown
                end
            end
        end)
    end

    -- handles the pull command
    local function CommandHandler_Pull(cmd)
        mod:StartTimer(tonumber(cmd))
    end

    -- handles the break command
    local function CommandHandler_Break(cmd)
        mod:StartTimer(tonumber(cmd), "break")
    end

    local function SetupDatabase()
        if not DB then
            if type(KPackCharDB.PullnBreak) ~= "table" or not next(KPackCharDB.PullnBreak) then
                KPackCharDB.PullnBreak = CopyTable(defaults)
            end
            DB = KPackCharDB.PullnBreak
        end
    end
    core:RegisterForEvent("PLAYER_LOGIN", SetupDatabase)

    -- used to resume after reload or relog
    core:RegisterForEvent("PLAYER_ENTERING_WORLD", function()
        SetupDatabase()
        local currtime = GetTime()

        if DB.starttime > (currtime - DB.duration) then
            local timeleft = ceil(DB.starttime + DB.duration - currtime)
            if DB.type == "break" then
                mod:StartTimer(timeleft / 60, "break")
            else
                mod:StartTimer(timeleft)
            end
        elseif DB.starttime ~= 0 or DB.type ~= "pull" then
            DB.type = "pull"
            DB.starttime = 0
            started = nil
            isBreak = nil
        end
    end)

    SlashCmdList["KPACKPULL"] = CommandHandler_Pull
    _G.SLASH_KPACKPULL1 = "/pull"
    SlashCmdList["KPACKBREAK"] = CommandHandler_Break
    _G.SLASH_KPACKBREAK1 = "/break"
end)