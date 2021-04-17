assert(KPack, "KPack not found!")
KPack:AddModule("Cooldowns", "Adds text to items, spell and abilities that are on cooldown to indicate when they will be ready to use.", function(_, core)
    if core:IsDisabled("Cooldowns") then return end

    local DAY, HOUR, MINUTE, SHORT = 86400, 3600, 60, 5
    local ICON_SIZE = 36
    local textFont = STANDARD_TEXT_FONT
    local fontSize = 18
    local minScale = 0.6
    local minDuration = 3
    local treshold = 5.5
    local colors = {
        short = {1, 0, 0, 1}, -- <= 5 seconds
        secs = {1, 1, 0, 1}, -- < 1 minute
        mins = {1, 1, 1, 1}, -- >= 1 minute
        hrs = {0.7, 0.7, 0.7, 1}, -- >= 1 hr
        days = {0.7, 0.7, 0.7, 1} -- >= 1 day
    }
    -- cache frequently used globals
    local str_format = string.format
    local math_floor = math.floor
    local math_min = math.min
    local GetTime = GetTime

    local function Cooldowns_FormattedText(s)
        if s >= DAY then
            return str_format("%dd", math_floor(s / DAY + 0.5)), s % DAY, colors.days
        elseif s >= HOUR then
            return str_format("%dh", math_floor(s / HOUR + 0.5)), s % HOUR, colors.hrs
        elseif s >= MINUTE then
            return str_format("%dm", math_floor(s / MINUTE + 0.5)), s % MINUTE, colors.mins
        end
        local color = (s >= treshold) and colors.secs or colors.short
        return math_floor(s + 0.5), s - math_floor(s), color
    end

    local function Cooldowns_TimerOnUpdate(self, elapsed)
        if self.text:IsShown() then
            if self.nextUpdate > 0 then
                self.nextUpdate = self.nextUpdate - elapsed
            else
                if (self:GetEffectiveScale() / UIParent:GetEffectiveScale()) < minScale then
                    self.text:SetText("")
                    self.nextUpdate = 1
                else
                    local remain = self.duration - (GetTime() - self.start)
                    if math_floor(remain + 0.5) > 0 then
                        local time, nextUpdate, color = Cooldowns_FormattedText(remain)
                        self.text:SetText(time)
                        self.text:SetTextColor(unpack(color))
                        self.nextUpdate = nextUpdate
                    else
                        self.text:Hide()
                    end
                end
            end
        end
    end

    local function Cooldowns_CreateTimer(self)
        local scale = math_min(self:GetParent():GetWidth() / ICON_SIZE, 1)
        if scale < minScale then
            self.noOCC = true
        else
            local text = self:CreateFontString(nil, "OVERLAY")
            text:SetPoint("CENTER", 0, 1)
            text:SetFont(textFont, fontSize * scale, "OUTLINE")
            text:SetTextColor(unpack(colors.days))

            self.text = text
            self:SetScript("OnUpdate", Cooldowns_TimerOnUpdate)
            return text
        end
    end

    local function Cooldowns_StartTimer(self, start, duration)
        self.start = start
        self.duration = duration
        self.nextUpdate = 0

        local text = self.text or (not self.noOCC and Cooldowns_CreateTimer(self))
        if text then
            text:Show()
        end
    end

    core:RegisterForEvent("PLAYER_LOGIN", function()
        if not _G.OmniCC then
            hooksecurefunc(getmetatable(ActionButton1Cooldown).__index, "SetCooldown", function(self, start, duration)
                if self.noOCC then return end
                if start > 0 and duration > minDuration then
                    Cooldowns_StartTimer(self, start, duration)
                else
                    local text = self.text
                    if text then
                        text:Hide()
                    end
                end
            end)
        end
    end)
end)