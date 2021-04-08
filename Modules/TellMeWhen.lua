assert(KPack, "KPack not found!")
KPack:AddModule("TellMeWhen", function(folder, core, L)
    if core:IsDisabled("TellMeWhen") then return end

    local TellMeWhen = {}
    core.TellMeWhen = TellMeWhen

    local GetItemCooldown = GetItemCooldown
    local GetSpellCooldown = GetSpellCooldown
    local GetSpellInfo = GetSpellInfo
    local GetSpellTexture = GetSpellTexture
    local IsSpellInRange = IsSpellInRange
    local IsUsableSpell = IsUsableSpell
    local UnitAura = UnitAura

    local LiCD = LibStub("LibInternalCooldowns", true)
    if LiCD and LiCD.GetItemCooldown then
        GetItemCooldown = function(...)
            return LiCD:GetItemCooldown(...)
        end
    end

    local function TMW_IsSpellInRange(spellId, unit)
        local spellName = tonumber(spellId) and GetSpellInfo(spellId) or spellId
        return IsSpellInRange(spellName, unit)
    end

    local function TMW_GetSpellTexture(spellName)
        if tonumber(spellName) then
            return select(3, GetSpellInfo(spellName))
        end
        return GetSpellTexture(spellName)
    end

    local maxGroups, maxRows = 8, 7
    local updateInterval = 0.25
    local activeSpec, _
    local highlightColor = HIGHLIGHT_FONT_COLOR
    local normalColor = NORMAL_FONT_COLOR

    local iconDefaults = {
        BuffOrDebuff = "HELPFUL",
        BuffShowWhen = "present",
        CooldownShowWhen = "usable",
        CooldownType = "spell",
        Enabled = false,
        Name = "",
        OnlyMine = false,
        ShowTimer = false,
        Type = "",
        Unit = "player",
        WpnEnchantType = "mainhand"
    }

    local groupDefaults = {
        Enabled = false,
        Scale = 2.0,
        Rows = 1,
        Columns = 4,
        Icons = {},
        OnlyInCombat = false,
        PrimarySpec = true,
        SecondarySpec = true
    }

    for i = 1, maxRows * maxRows do
        groupDefaults.Icons[i] = iconDefaults
    end

    local DB, _
    local defaults = {
        Locked = false,
        Groups = {}
    }

    local TellMeWhen_BuffEquivalencies = {
        Bleeding = "Pounce Bleed;Rake;Rip;Lacerate;Rupture;Garrote;Savage Rend;Rend;Deep Wound",
        DontMelee = "Berserk;Evasion;Shield Wall;Retaliation;Dispersion;Hand of Sacrifice;Hand of Protection;Divine Shield;Divine Protection;Ice Block;Icebound Fortitude;Cyclone;Banish",
        FaerieFires = "Faerie Fire;Faerie Fire (Feral)",
        ImmuneToMagicCC = "Divine Shield;Ice Block;The Beast Within;Beastial Wrath;Cyclone;Banish",
        ImmuneToStun = "Divine Shield;Ice Block;The Beast Within;Beastial Wrath;Icebound Fortitude;Hand of Protection;Cyclone;Banish",
        Incapacitated = "Gouge;Maim;Repentance;Reckless Charge;Hungering Cold",
        MeleeSlowed = "Rocket Burst;Infected Wounds;Judgements of the Just;Earth Shock;Thunder Clap;Icy Touch",
        MovementSlowed = "Incapacitating Shout;Chains of Ice;Icy Clutch;Slow;Daze;Hamstring;Piercing Howl;Wing Clip;Frost Trap Aura;Frostbolt;Cone of Cold;Blast Wave;Mind Flay;Crippling Poison;Deadly Throw;Frost Shock;Earthbind;Curse of Exhaustion",
        Stunned = "Reckless Charge;Bash;Maim;Pounce;Starfire Stun;Intimidation;Impact;Hammer of Justice;Stun;Blackout;Kidney Shot;Cheap Shot;Shadowfury;Intercept;Charge Stun;Concussion Blow;War Stomp",
        StunnedOrIncapacitated = "Gouge;Maim;Repentance;Reckless Charge;Hungering Cold;Bash;Pounce;Starfire Stun;Intimidation;Impact;Hammer of Justice;Stun;Blackout;Kidney Shot;Cheap Shot;Shadowfury;Intercept;Charge Stun;Concussion Blow;War Stomp",
        VulnerableToBleed = "Mangle (Cat);Mangle (Bear);Trauma",
        WoTLKDebuffs = "71237;71289;71204;72293;69279;69674;72272;73020;70447;70672;70911;72999;71822;70867;71340;71267;70923;70873;70106;69762;69766;70128;70126;70541;70337;69409;69409;73797;73798;74453;74367;74562;74792"
    }

    local function TellMeWhen_CreateGroup(name, parent, ...)
        local group = CreateFrame("Frame", name, parent or UIParent)
        group:SetSize(1, 1)
        group:SetToplevel(true)
        group:SetMovable(true)
        if select(1, ...) then
            group:SetPoint(...)
        end

        local t = group:CreateTexture(nil, "BACKGROUND")
        t:SetTexture(0, 0, 0, 0)
        t:SetVertexColor(0.6, 0.6, 0.6)
        t:SetAllPoints(true)
        group.texture = t

        local resize = CreateFrame("Button", nil, group)
        resize:SetPoint("BOTTOMRIGHT")
        resize:SetSize(10, 10)
        t = resize:CreateTexture(nil, "BACKGROUND")
        t:SetTexture([[Interface\AddOns\KPack\Media\Textures\resize]])
        t:SetVertexColor(0.6, 0.6, 0.6)
        t:SetSize(10, 10)
        t:SetAllPoints(resize)
        resize.texture = t
        resize:SetScript("OnMouseDown", function(self, button)
            TellMeWhen:StartSizing(self, button)
        end)
        resize:SetScript("OnMouseUp", function(self, button)
            TellMeWhen:StopSizing(self, button)
        end)
        resize:SetScript("OnEnter", function(self)
            TellMeWhen:GUIButton_OnEnter(self, L["Resize"], L["Click and drag to change size."])
            self.texture:SetVertexColor(1, 1, 1)
        end)
        resize:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
            self.texture:SetVertexColor(0.6, 0.6, 0.6)
        end)
        group.resize = resize

        return group
    end

    local function TellMeWhen_CreateIcon(name, parent)
        local icon = CreateFrame("Frame", name, parent)
        icon:SetSize(30, 30)

        local t = icon:CreateTexture(nil, "BACKGROUND")
        t:SetTexture([[Interface\Buttons\UI-EmptySlot-Disabled]])
        t:SetSize(46, 46)
        t:SetPoint("CENTER")

        t = icon:CreateTexture("$parentTexture", "ARTWORK")
        t:SetTexture([[Interface\Icons\INV_Misc_QuestionMark]])
        t:SetAllPoints(icon)
        icon.texture = t

        t = icon:CreateTexture("$parentHighlight", "HIGHLIGHT")
        t:SetTexture([[Interface\Buttons\ButtonHilight-Square]])
        t:SetAllPoints(icon)
        t:SetBlendMode("ADD")
        icon.highlight = t

        t = icon:CreateFontString("$parentCount", "ARTWORK", "NumberFontNormalSmall")
        t:SetPoint("BOTTOMRIGHT", -2, 2)
        t:SetJustifyH("RIGHT")
        icon.countText = t

        t = CreateFrame("Cooldown", "$parentCooldown", icon)
        t:SetAllPoints(icon)
        icon.Cooldown = t

        t = CreateFrame("Frame", "$parentDropDown", icon, "UIDropDownMenuTemplate")
        t:SetPoint("TOP")
        t:Hide()
        UIDropDownMenu_Initialize(t, TellMeWhen.IconMenu_Initialize, "MENU")
        t:SetScript("OnShow", function(self)
            UIDropDownMenu_Initialize(self, TellMeWhen.IconMenu_Initialize, "MENU")
        end)

        icon:SetScript("OnEnter", function(self, motion)
            TellMeWhen:Icon_OnEnter(self, motion)
        end)
        icon:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
        icon:RegisterForDrag("LeftButton")
        icon:SetScript("OnDragStart", function(self)
            self:GetParent():StartMoving()
        end)
        icon:SetScript("OnDragStop", function(self)
            self:GetParent():StopMovingOrSizing()
            local group = DB.Groups[self:GetParent():GetID()]
            group.point, _, _, group.x, group.y = self:GetParent():GetPoint(1)
        end)
        icon:SetScript("OnMouseDown", function(self, button)
            TellMeWhen:Icon_OnMouseDown(self, button)
        end)

        return icon
    end

    -- -------------
    -- RESIZE BUTTON
    -- -------------

    function TellMeWhen:GUIButton_OnEnter(icon, shortText, longText)
        local tooltip = _G["GameTooltip"]
        if GetCVar("UberTooltips") == "1" then
            GameTooltip_SetDefaultAnchor(tooltip, icon)
            tooltip:AddLine(shortText, highlightColor.r, highlightColor.g, highlightColor.b, 1)
            tooltip:AddLine(longText, normalColor.r, normalColor.g, normalColor.b, 1)
            tooltip:Show()
        else
            tooltip:SetOwner(icon, "ANCHOR_BOTTOMLEFT")
            tooltip:SetText(shortText)
        end
    end

    do
        local function TellMeWhen_SizeUpdate(icon)
            local uiScale = UIParent:GetScale()
            local scalingFrame = icon:GetParent()
            local cursorX, cursorY = GetCursorPosition(UIParent)

            local newXScale = scalingFrame.oldScale * (cursorX / uiScale - scalingFrame.oldX * scalingFrame.oldScale) / (icon.oldCursorX / uiScale - scalingFrame.oldX * scalingFrame.oldScale)
            local newYScale = scalingFrame.oldScale * (cursorY / uiScale - scalingFrame.oldY * scalingFrame.oldScale) / (icon.oldCursorY / uiScale - scalingFrame.oldY * scalingFrame.oldScale)
            local newScale = max(0.6, newXScale, newYScale)
            scalingFrame:SetScale(newScale)

            local newX = scalingFrame.oldX * scalingFrame.oldScale / newScale
            local newY = scalingFrame.oldY * scalingFrame.oldScale / newScale
            scalingFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", newX, newY)
        end

        function TellMeWhen:StartSizing(icon, button)
            local scalingFrame = icon:GetParent()
            scalingFrame.oldScale = scalingFrame:GetScale()
            icon.oldCursorX, icon.oldCursorY = GetCursorPosition(UIParent)
            scalingFrame.oldX = scalingFrame:GetLeft()
            scalingFrame.oldY = scalingFrame:GetTop()
            icon:SetScript("OnUpdate", TellMeWhen_SizeUpdate)
        end
    end

    function TellMeWhen:StopSizing(icon, button)
        icon:SetScript("OnUpdate", nil)
        DB.Groups[icon:GetParent():GetID()].Scale = icon:GetParent():GetScale()
    end

    -- -------------
    -- ICON FUNCTION
    -- -------------

    local function TellMeWhen_SplitNames(buffName, convertIDs)
        local buffNames
        if buffName:find(";") ~= nil then
            buffNames = {strsplit(";", buffName)}
        else
            buffNames = {buffName}
        end
        for i, name in ipairs(buffNames) do
            buffNames[i] = name
        end

        return buffNames
    end

    local function TellMeWhen_GetSpellNames(buffName, firstOnly)
        local buffNames
        if TellMeWhen_BuffEquivalencies[buffName] then
            buffNames = TellMeWhen_SplitNames(TellMeWhen_BuffEquivalencies[buffName], "spell")
        else
            buffNames = TellMeWhen_SplitNames(buffName, "spell")
        end
        return firstOnly and buffNames[1] or buffNames
    end

    local function TellMeWhen_GetItemNames(buffName, firstOnly)
        local buffNames = TellMeWhen_SplitNames(buffName, "item")
        return firstOnly and buffNames[1] or buffNames
    end

    local defaultSpells = {
        ROGUE = GetSpellInfo(1752), -- sinister strike
        PRIEST = GetSpellInfo(139), -- renew
        DRUID = GetSpellInfo(774), -- rejuvenation
        WARRIOR = GetSpellInfo(6673), -- battle shout
        MAGE = GetSpellInfo(168), -- frost armor
        WARLOCK = GetSpellInfo(1454), -- life tap
        PALADIN = GetSpellInfo(1152), -- purify
        SHAMAN = GetSpellInfo(324), -- lightning shield
        HUNTER = GetSpellInfo(1978), -- serpent sting
        DEATHKNIGHT = GetSpellInfo(45462) -- plague strike
    }
    local defaultSpell = defaultSpells[core.class]
    local function TellMeWhen_GetGCD()
        return select(2, GetSpellCooldown(defaultSpell))
    end

    local function TellMeWhen_Icon_SpellCooldown_OnUpdate(self, elapsed)
        self.updateTimer = self.updateTimer - elapsed
        if self.updateTimer <= 0 then
            self.updateTimer = updateInterval
            local name = self.Name[1] or ""
            local _, timeLeft, _ = GetSpellCooldown(name)
            local inrange = TMW_IsSpellInRange(name, self.Unit)
            if LiCD and LiCD.talentsRev[name] then
                name = LiCD.talentsRev[name]
                timeLeft = 0
            end
            local _, nomana = IsUsableSpell(name)
            local OnGCD = TellMeWhen_GetGCD() == timeLeft and timeLeft > 0
            local _, _, _, _, _, _, _, minRange, maxRange = GetSpellInfo(name)
            if not maxRange or inrange == nil then
                inrange = 1
            end
            if timeLeft then
                if (timeLeft == 0 or OnGCD) and inrange == 1 and not nomana then
                    self.texture:SetVertexColor(1, 1, 1, 1)
                    self:SetAlpha(self.usableAlpha)
                elseif self.usableAlpha == 1 and (timeLeft == 0 or OnGCD) then
                    self.texture:SetVertexColor(0.5, 0.5, 0.5, 1)
                    self:SetAlpha(self.usableAlpha)
                else
                    self.texture:SetVertexColor(1, 1, 1, 1)
                    self:SetAlpha(self.unusableAlpha)
                end
            end
        end
    end

    local function TellMeWhen_Icon_SpellCooldown_OnEvent(self, event, ...)
        local startTime, timeLeft, _

        if event == "COMBAT_LOG_EVENT_UNFILTERED" and arg2 == "SPELL_ENERGIZE" then
            if arg9 and LiCD and LiCD.cooldowns[arg9] then
                startTime, timeLeft = GetTime(), LiCD.cooldowns[arg9]
            end
        else
            startTime, timeLeft, _ = GetSpellCooldown(self.Name[1] or "")
        end
        if timeLeft then
            CooldownFrame_SetTimer(self.Cooldown, startTime, timeLeft, 1)
        end
    end

    local function TellMeWhen_Icon_ItemCooldown_OnUpdate(self, elapsed)
        self.updateTimer = self.updateTimer - elapsed
        if self.updateTimer <= 0 then
            self.updateTimer = updateInterval
            local _, timeLeft, _ = GetItemCooldown(self.Name[1] or "")
            if timeLeft then
                if timeLeft == 0 or TellMeWhen_GetGCD() == timeLeft then
                    self:SetAlpha(self.usableAlpha)
                elseif timeLeft > 0 and TellMeWhen_GetGCD() ~= timeLeft then
                    self:SetAlpha(self.unusableAlpha)
                end
            end
        end
    end

    local function TellMeWhen_Icon_ItemCooldown_OnEvent(self)
        local startTime, timeLeft, enable = GetItemCooldown(self.Name[1] or "")
        if timeLeft then
            CooldownFrame_SetTimer(self.Cooldown, startTime, timeLeft, 1)
        end
    end

    local function TellMeWhen_Icon_BuffCheck(icon)
        if UnitExists(icon.Unit) then
            local maxExpirationTime = 0
            local processedBuffInAuraNames = false

		    local filter = icon.OnlyMine and "PLAYER"
		    local func = (icon.BuffOrDebuff == "HELPFUL") and UnitBuff or UnitDebuff

            for _, iName in ipairs(icon.Name) do
                local buffName, iconTexture, count, duration, expirationTime
                local auraId = tonumber(iName)
                if auraId then
                    for i = 1, 32 do
                        local name, _, tex, stack, _, dur, expires, _, _, _, spellId = func(icon.Unit, i, nil, filter)
                        if name and spellId and spellId == auraId then
                            buffName, iconTexture, count, duration, expirationTime = name, tex, stack, dur, expires
                            break
                        end
                    end
                else
                    buffName, _, iconTexture, count, _, duration, expirationTime = func(icon.Unit, iName, nil, filter)
                end

                if buffName then
                    if icon.texture:GetTexture() ~= iconTexture then
                        icon.texture:SetTexture(iconTexture)
                        icon.learnedTexture = true
                    end
                    if icon.presentAlpha then
                        icon:SetAlpha(icon.presentAlpha)
                    end
                    icon.texture:SetVertexColor(1, 1, 1, 1)
                    if count > 1 then
                        icon.countText:SetText(count)
                        icon.countText:Show()
                    else
                        icon.countText:Hide()
                    end
                    if icon.ShowTimer and not UnitIsDead(icon.Unit) then
                        CooldownFrame_SetTimer(icon.Cooldown, expirationTime - duration, duration, 1)
                    end
                    processedBuffInAuraNames = true
                end
            end
            if processedBuffInAuraNames then
                return
            end

            if icon.absentAlpha then
                icon:SetAlpha(icon.absentAlpha)
            end
            if icon.presentAlpha == 1 and icon.absentAlpha == 1 then
                icon.texture:SetVertexColor(1, 0.35, 0.35, 1)
            end

            icon.countText:Hide()
            if icon.ShowTimer then
                CooldownFrame_SetTimer(icon.Cooldown, 0, 0, 0)
            end
        else
            icon:SetAlpha(0)
            CooldownFrame_SetTimer(icon.Cooldown, 0, 0, 0)
        end
    end

    local function TellMeWhen_Icon_Buff_OnEvent(self, event, ...)
        if event == "COMBAT_LOG_EVENT_UNFILTERED" and arg2 == "UNIT_DIED" then
            if arg6 == UnitGUID(self.Unit) then
                TellMeWhen_Icon_BuffCheck(self)
            end
        elseif event == "UNIT_AURA" and arg1 == self.Unit then
            TellMeWhen_Icon_BuffCheck(self)
        elseif (self.Unit == "target" and event == "PLAYER_TARGET_CHANGED") or (self.Unit == "focus" and event == "PLAYER_FOCUS_CHANGED") then
            TellMeWhen_Icon_BuffCheck(self)
        end
    end

    local function TellMeWhen_Icon_ReactiveCheck(icon)
        local name = icon.Name[1] or ""
        local usable, nomana = IsUsableSpell(name)
        local _, timeLeft, _ = GetSpellCooldown(name)
        local inrange = TMW_IsSpellInRange(name, icon.Unit)
        if (inrange == nil) then
            inrange = 1
        end
        if usable then
            if inrange and not nomana then
                icon.texture:SetVertexColor(1, 1, 1, 1)
                icon:SetAlpha(icon.usableAlpha)
            elseif not inrange or nomana then
                icon.texture:SetVertexColor(.35, .35, .35, 1)
                icon:SetAlpha(icon.usableAlpha)
            else
                icon.texture:SetVertexColor(1, 1, 1, 1)
                icon:SetAlpha(icon.unusableAlpha)
            end
        else
            icon:SetAlpha(icon.unusableAlpha)
        end
    end

    local function TellMeWhen_Icon_Reactive_OnEvent(self, event)
        if event == "ACTIONBAR_UPDATE_USABLE" then
            TellMeWhen_Icon_ReactiveCheck(self)
        elseif event == "ACTIONBAR_UPDATE_COOLDOWN" then
            if self.ShowTimer then
                TellMeWhen_Icon_SpellCooldown_OnEvent(self, event)
            end
            TellMeWhen_Icon_ReactiveCheck(self)
        end
    end

    local function TellMeWhen_Icon_WpnEnchant_OnEvent(self, event, ...)
        if event == "UNIT_INVENTORY_CHANGED" and arg1 == "player" then
            local slotID, _
            if self.WpnEnchantType == "mainhand" then
                slotID, _ = GetInventorySlotInfo("MainHandSlot")
            elseif self.WpnEnchantType == "offhand" then
                slotID, _ = GetInventorySlotInfo("SecondaryHandSlot")
            end
            local wpnTexture = GetInventoryItemTexture("player", slotID)
            if wpnTexture then
                self.texture:SetTexture(wpnTexture)
            else
                self.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            end
            self.startTime = GetTime()
        end
    end

    local function TellMeWhen_Icon_WpnEnchant_OnUpdate(self, elapsed)
        self.updateTimer = self.updateTimer - elapsed
        if self.updateTimer <= 0 then
            self.updateTimer = updateInterval
            local hasMainHandEnchant, mainHandExpiration, mainHandCharges, hasOffHandEnchant, offHandExpiration, offHandCharges = GetWeaponEnchantInfo()
            if self.WpnEnchantType == "mainhand" and hasMainHandEnchant then
                self:SetAlpha(self.presentAlpha)
                if mainHandCharges > 1 then
                    self.countText:SetText(mainHandCharges)
                    self.countText:Show()
                else
                    self.countText:Hide()
                end
                if self.ShowTimer then
                    if self.startTime ~= nil then
                        CooldownFrame_SetTimer(self.Cooldown, GetTime(), mainHandExpiration / 1000, 1)
                    else
                        self.startTime = GetTime()
                    end
                end
            elseif self.WpnEnchantType == "offhand" and hasOffHandEnchant then
                self:SetAlpha(self.presentAlpha)
                if offHandCharges > 1 then
                    self.countText:SetText(offHandCharges)
                    self.countText:Show()
                else
                    self.countText:Hide()
                end
                if self.ShowTimer then
                    if self.startTime ~= nil then
                        CooldownFrame_SetTimer(self.Cooldown, GetTime(), offHandExpiration / 1000, 1)
                    else
                        self.startTime = GetTime()
                    end
                end
            else
                self:SetAlpha(self.absentAlpha)
                CooldownFrame_SetTimer(self.Cooldown, 0, 0, 0)
            end
        end
    end

    local function TellMeWhen_Icon_Totem_OnEvent(self, event, ...)
        local foundTotem
        for iSlot = 1, 4 do
            local haveTotem, totemName, startTime, totemDuration, totemIcon = GetTotemInfo(iSlot)
            for i, iName in ipairs(self.Name) do
                if totemName and totemName:find(iName) then
                    foundTotem = true
                    self.texture:SetVertexColor(1, 1, 1, 1)
                    self:SetAlpha(self.presentAlpha)

                    if self.texture:GetTexture() ~= totemIcon then
                        self.texture:SetTexture(totemIcon)
                        self.learnedTexture = true
                    end

                    if self.ShowTimer then
                        local precise = GetTime()
                        if precise - startTime > 1 then
                            precise = startTime + 1
                        end
                        CooldownFrame_SetTimer(self.Cooldown, precise, totemDuration, 1)
                    end
                    self:SetScript("OnUpdate", nil)
                    break
                end
            end
        end
        if not foundTotem then
            if self.absentAlpha == 1 and self.presentAlpha == 1 then
                self.texture:SetVertexColor(1, 0.35, 0.35, 1)
            end
            self:SetAlpha(self.absentAlpha)
            CooldownFrame_SetTimer(self.Cooldown, 0, 0, 0)
        end
    end

    local function TellMeWhen_Group_OnEvent(self, event)
        if event == "PLAYER_REGEN_DISABLED" then
            self:Show()
        elseif event == "PLAYER_REGEN_ENABLED" then
            self:Hide()
        end
    end

    do
        local currentIcon = {groupID = 1, iconID = 1}

        StaticPopupDialogs["TELLMEWHEN_CHOOSENAME_DIALOG"] = {
            text = L["Enter the Name or Id of the Spell, Ability, Item, Buff, Debuff you want this icon to monitor. You can add multiple Buffs/Debuffs by seperating them with ;"],
            button1 = ACCEPT,
            button2 = CANCEL,
            hasEditBox = 1,
            maxLetters = 200,
            OnShow = function(this)
                local groupID = currentIcon.groupID
                local iconID = currentIcon.iconID
                local text = DB.Groups[groupID].Icons[iconID].Name
                _G[this:GetName() .. "EditBox"]:SetText(text)
                _G[this:GetName() .. "EditBox"]:SetFocus()
            end,
            OnAccept = function(iconNumber)
                local text = _G[this:GetParent():GetName() .. "EditBox"]:GetText()
                TellMeWhen:IconMenu_ChooseName(text)
            end,
            EditBoxOnEnterPressed = function(iconNumber)
                local text = _G[this:GetParent():GetName() .. "EditBox"]:GetText()
                TellMeWhen:IconMenu_ChooseName(text)
                this:GetParent():Hide()
            end,
            EditBoxOnEscapePressed = function()
                this:GetParent():Hide()
            end,
            OnHide = function()
                if _G.ChatFrameEditBox and _G.ChatFrameEditBox:IsVisible() then
                    _G.ChatFrameEditBox:SetFocus()
                end
                _G[this:GetName() .. "EditBox"]:SetText("")
            end,
            timeout = 0,
            whileDead = 1,
            hideOnEscape = 1
        }

        local TellMeWhen_IconMenu_CooldownOptions = {
            {value = "CooldownType", text = L["Cooldown type"], hasArrow = true},
            {value = "CooldownShowWhen", text = L["Show icon when"], hasArrow = true},
            {value = "ShowTimer", text = L["Show timer"]}
        }

        local TellMeWhen_IconMenu_ReactiveOptions = {
            {value = "CooldownShowWhen", text = L["Show icon when"], hasArrow = true},
            {value = "ShowTimer", text = L["Show timer"]}
        }

        local TellMeWhen_IconMenu_BuffOptions = {
            {value = "BuffOrDebuff", text = L["Buff or Debuff"], hasArrow = true},
            {value = "Unit", text = L["Unit to watch"], hasArrow = true},
            {value = "BuffShowWhen", text = L["Show icon when"], hasArrow = true},
            {value = "ShowTimer", text = L["Show timer"]},
            {value = "OnlyMine", text = L["Only show if cast by self"]}
        }

        local TellMeWhen_IconMenu_WpnEnchantOptions = {
            {value = "WpnEnchantType", text = L["Weapon slot to monitor"], hasArrow = true},
            {value = "BuffShowWhen", text = L["Show icon when"], hasArrow = true},
            {value = "ShowTimer", text = L["Show timer"]}
        }

        local TellMeWhen_IconMenu_TotemOptions = {
            {value = "Unit", text = L["Unit to watch"], hasArrow = true},
            {value = "BuffShowWhen", text = L["Show icon when"], hasArrow = true},
            {value = "ShowTimer", text = L["Show timer"]}
        }

        local TellMeWhen_IconMenu_SubMenus = {
            -- the keys on this table need to match the settings variable names
            Type = {
                {value = "cooldown", text = L["Cooldown"]},
                {value = "buff", text = L["Buff or Debuff"]},
                {value = "reactive", text = L["Reactive spell or ability"]},
                {value = "wpnenchant", text = L["Temporary weapon enchant"]},
                {value = "totem", text = L["Totem/non-MoG Ghoul"]}
            },
            CooldownType = {
                {value = "spell", text = L["Spell or ability"]},
                {value = "item", text = L["Item"]}
            },
            BuffOrDebuff = {
                {value = "HELPFUL", text = L["Buff"]},
                {value = "HARMFUL", text = L["Debuff"]}
            },
            Unit = {
                {value = "player", text = STATUS_TEXT_PLAYER},
                {value = "target", text = STATUS_TEXT_TARGET},
                {value = "targettarget", text = L["Target of Target"]},
                {value = "focus", text = FOCUS},
                {value = "focustarget", text = TARGETFOCUS},
                {value = "pet", text = PET},
                {value = "pettarget", text = L["Pet Target"]}
            },
            BuffShowWhen = {
                {value = "present", text = L["Present"]},
                {value = "absent", text = L["Absent"]},
                {value = "always", text = L["Always"]}
            },
            CooldownShowWhen = {
                {value = "usable", text = L["Usable"]},
                {value = "unusable", text = L["Unusable"]},
                {value = "always", text = L["Always"]}
            },
            WpnEnchantType = {
                {value = "mainhand", text = INVTYPE_WEAPONMAINHAND},
                {value = "offhand", text = INVTYPE_WEAPONOFFHAND}
            }
        }

        function TellMeWhen:Icon_OnEnter(this, motion)
            GameTooltip_SetDefaultAnchor(GameTooltip, this)
            GameTooltip:AddLine("TellMeWhen", highlightColor.r, highlightColor.g, highlightColor.b, 1)
            GameTooltip:AddLine(L["Right click for icon options. More options in Blizzard interface options menu. Type /tellmewhen to lock and enable module."], normalColor.r, normalColor.g, normalColor.b, 1)
            GameTooltip:Show()
        end

        function TellMeWhen:Icon_OnMouseDown(this, button)
            if button == "RightButton" then
                PlaySound("UChatScrollButton")
                currentIcon.iconID = this:GetID()
                currentIcon.groupID = this:GetParent():GetID()
                ToggleDropDownMenu(1, nil, _G[this:GetName() .. "DropDown"], "cursor", 0, 0)
            end
        end

        function TellMeWhen:IconMenu_Initialize()
            local groupID = currentIcon.groupID
            local iconID = currentIcon.iconID

            local name = DB.Groups[groupID].Icons[iconID].Name
            local iconType = DB.Groups[groupID].Icons[iconID]["Type"]
            local enabled = DB.Groups[groupID].Icons[iconID]["Enabled"]

            if UIDROPDOWNMENU_MENU_LEVEL == 2 then
                local subMenus = TellMeWhen_IconMenu_SubMenus
                for index, value in ipairs(subMenus[UIDROPDOWNMENU_MENU_VALUE]) do
                    local info = UIDropDownMenu_CreateInfo()
                    info.text = subMenus[UIDROPDOWNMENU_MENU_VALUE][index].text
                    info.value = subMenus[UIDROPDOWNMENU_MENU_VALUE][index].value
                    info.checked = (info.value == DB.Groups[groupID].Icons[iconID][UIDROPDOWNMENU_MENU_VALUE])
                    info.func = TellMeWhen.IconMenu_ChooseSetting
                    UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
                end
                return
            end

            -- show name
            if name and name ~= "" then
                local info = UIDropDownMenu_CreateInfo()
                info.text = name
                info.isTitle = true
                UIDropDownMenu_AddButton(info)
            end

            -- choose name
            if iconType ~= "wpnenchant" then
                info = UIDropDownMenu_CreateInfo()
                info.text = L["Choose spell/item/buff/etc."]
                info.func = TellMeWhen.IconMenu_ShowNameDialog
                UIDropDownMenu_AddButton(info)
            end

            -- enable icon
            info = UIDropDownMenu_CreateInfo()
            info.value = "Enabled"
            info.text = L["Enable"]
            info.checked = enabled
            info.func = TellMeWhen.IconMenu_ToggleSetting
            info.keepShownOnClick = true
            UIDropDownMenu_AddButton(info)

            -- icon type
            info = UIDropDownMenu_CreateInfo()
            info.value = "Type"
            info.text = L["Icon type"]
            info.hasArrow = true
            UIDropDownMenu_AddButton(info)

            -- additional options
            if iconType == "cooldown" or iconType == "buff" or iconType == "reactive" or iconType == "wpnenchant" or iconType == "totem" then
                info = UIDropDownMenu_CreateInfo()
                info.disabled = true
                UIDropDownMenu_AddButton(info)

                local moreOptions
                if iconType == "cooldown" then
                    moreOptions = TellMeWhen_IconMenu_CooldownOptions
                elseif iconType == "buff" then
                    moreOptions = TellMeWhen_IconMenu_BuffOptions
                elseif iconType == "reactive" then
                    moreOptions = TellMeWhen_IconMenu_ReactiveOptions
                elseif iconType == "wpnenchant" then
                    moreOptions = TellMeWhen_IconMenu_WpnEnchantOptions
                elseif iconType == "totem" then
                    moreOptions = TellMeWhen_IconMenu_TotemOptions
                end

                for index, value in ipairs(moreOptions) do
                    info = UIDropDownMenu_CreateInfo()
                    info.text = moreOptions[index].text
                    info.value = moreOptions[index].value
                    info.hasArrow = moreOptions[index].hasArrow
                    if not info.hasArrow then
                        info.func = TellMeWhen.IconMenu_ToggleSetting
                        info.checked = DB.Groups[groupID].Icons[iconID][info.value]
                    end
                    info.keepShownOnClick = true
                    UIDropDownMenu_AddButton(info)
                end
            else
                info = UIDropDownMenu_CreateInfo()
                info.text = L["More options"]
                info.disabled = true
                UIDropDownMenu_AddButton(info)
            end

            -- clear settings
            if (name and name ~= "") or iconType ~= "" then
                info = UIDropDownMenu_CreateInfo()
                info.disabled = true
                UIDropDownMenu_AddButton(info)

                info = UIDropDownMenu_CreateInfo()
                info.text = L["Clear settings"]
                info.func = TellMeWhen.IconMenu_ClearSettings
                UIDropDownMenu_AddButton(info)
            end
        end

        function TellMeWhen:IconMenu_ShowNameDialog()
            local dialog = StaticPopup_Show("TELLMEWHEN_CHOOSENAME_DIALOG")
        end

        function TellMeWhen:IconMenu_ChooseName(text)
            local groupID = currentIcon.groupID
            local iconID = currentIcon.iconID
            DB.Groups[groupID].Icons[iconID].Name = text
            _G["KTellMeWhen_Group" .. groupID .. "_Icon" .. iconID].learnedTexture = nil
            TellMeWhen:Icon_Update(_G["KTellMeWhen_Group" .. groupID .. "_Icon" .. iconID], groupID, iconID)
        end

        function TellMeWhen:IconMenu_ToggleSetting()
            local groupID = currentIcon.groupID
            local iconID = currentIcon.iconID
            DB.Groups[groupID].Icons[iconID][this.value] = this.checked
            TellMeWhen:Icon_Update(_G["KTellMeWhen_Group" .. groupID .. "_Icon" .. iconID], groupID, iconID)
        end

        function TellMeWhen:IconMenu_ChooseSetting()
            local groupID = currentIcon.groupID
            local iconID = currentIcon.iconID
            DB.Groups[groupID].Icons[iconID][UIDROPDOWNMENU_MENU_VALUE] = this.value
            TellMeWhen:Icon_Update(_G["KTellMeWhen_Group" .. groupID .. "_Icon" .. iconID], groupID, iconID)
            if UIDROPDOWNMENU_MENU_VALUE == "Type" then
                CloseDropDownMenus()
            end
        end

        function TellMeWhen:IconMenu_ClearSettings()
            local groupID = currentIcon.groupID
            local iconID = currentIcon.iconID
            DB.Groups[groupID].Icons[iconID] = CopyTable(iconDefaults)
            TellMeWhen:Icon_Update(_G["KTellMeWhen_Group" .. groupID .. "_Icon" .. iconID], groupID, iconID)
            CloseDropDownMenus()
        end
    end

    -- ---------------
    -- GROUP FUNCTIONs
    -- ---------------

    function TellMeWhen:Group_Update(groupID)
        local currentSpec = TellMeWhen:GetActiveTalentGroup()
        local groupName = "KTellMeWhen_Group" .. groupID
        local group = _G[groupName]
        if not group then return end
        local resizeButton = group.resize

        local locked = DB.Locked
        local genabled = DB.Groups[groupID].Enabled
        local scale = DB.Groups[groupID].Scale
        local rows = DB.Groups[groupID].Rows
        local columns = DB.Groups[groupID].Columns
        local onlyInCombat = DB.Groups[groupID].OnlyInCombat
        local activePriSpec = DB.Groups[groupID].PrimarySpec
        local activeSecSpec = DB.Groups[groupID].SecondarySpec
        local iconSpacing = DB.Groups[groupID].Spacing or 1

        if (currentSpec == 1 and not activePriSpec) or (currentSpec == 2 and not activeSecSpec) then
            genabled = false
        end

        if genabled then
            for row = 1, rows do
                for column = 1, columns do
                    local iconID = (row - 1) * columns + column
                    local iconName = groupName .. "_Icon" .. iconID
                    local icon = _G[iconName] or TellMeWhen_CreateIcon(iconName, group)
                    icon:SetID(iconID)
                    icon:Show()
                    if (column > 1) then
                        icon:SetPoint("TOPLEFT", _G[groupName .. "_Icon" .. (iconID - 1)], "TOPRIGHT", iconSpacing, 0)
                    elseif row > 1 and column == 1 then
                        icon:SetPoint("TOPLEFT", _G[groupName .. "_Icon" .. (iconID - columns)], "BOTTOMLEFT", 0, -iconSpacing)
                    elseif iconID == 1 then
                        icon:SetPoint("TOPLEFT", group, "TOPLEFT")
                    end
                    TellMeWhen:Icon_Update(icon, groupID, iconID)
                    if not genabled then
                        TellMeWhen:Icon_ClearScripts(icon)
                    end
                end
            end
            for iconID = rows * columns + 1, maxRows * maxRows do
                local icon = _G[groupName .. "_Icon" .. iconID]
                if icon then
                    icon:Hide()
                    TellMeWhen:Icon_ClearScripts(icon)
                end
            end

            group:SetScale(scale)
            local lastIcon = groupName .. "_Icon" .. (rows * columns)
            resizeButton:SetPoint("BOTTOMRIGHT", lastIcon, "BOTTOMRIGHT", 3, -3)
            if locked then
                resizeButton:Hide()
            else
                resizeButton:Show()
            end
        end

        if onlyInCombat and genabled and locked then
            group:RegisterEvent("PLAYER_REGEN_ENABLED")
            group:RegisterEvent("PLAYER_REGEN_DISABLED")
            group:SetScript("OnEvent", TellMeWhen_Group_OnEvent)
            group:Hide()
        else
            group:UnregisterEvent("PLAYER_REGEN_ENABLED")
            group:UnregisterEvent("PLAYER_REGEN_DISABLED")
            group:SetScript("OnEvent", nil)
            if genabled then
                group:Show()
            else
                group:Hide()
            end
        end
    end

    function TellMeWhen:Icon_Update(icon, groupID, iconID)
        local iconSettings = DB.Groups[groupID].Icons[iconID]
        local Enabled = iconSettings.Enabled
        local iconType = iconSettings.Type
        local CooldownType = iconSettings.CooldownType
        local CooldownShowWhen = iconSettings.CooldownShowWhen
        local BuffShowWhen = iconSettings.BuffShowWhen
        if CooldownType == "spell" then
            icon.Name = TellMeWhen_GetSpellNames(iconSettings.Name)
        elseif CooldownType == "item" then
            icon.Name = TellMeWhen_GetItemNames(iconSettings.Name)
        end
        icon.Unit = iconSettings.Unit
        icon.ShowTimer = iconSettings.ShowTimer
        icon.OnlyMine = iconSettings.OnlyMine
        icon.BuffOrDebuff = iconSettings.BuffOrDebuff
        icon.WpnEnchantType = iconSettings.WpnEnchantType

        icon.updateTimer = updateInterval

        icon:UnregisterEvent("ACTIONBAR_UPDATE_STATE")
        icon:UnregisterEvent("ACTIONBAR_UPDATE_USABLE")
        icon:UnregisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
        icon:UnregisterEvent("PLAYER_TARGET_CHANGED")
        icon:UnregisterEvent("PLAYER_FOCUS_CHANGED")
        icon:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        icon:UnregisterEvent("UNIT_INVENTORY_CHANGED")
        icon:UnregisterEvent("BAG_UPDATE_COOLDOWN")
        icon:UnregisterEvent("UNIT_AURA")
        icon:UnregisterEvent("PLAYER_TOTEM_UPDATE")

        if Enabled or not DB.Locked then
            if CooldownShowWhen == "usable" then
                icon.usableAlpha = 1
                icon.unusableAlpha = 0
            elseif CooldownShowWhen == "unusable" then
                icon.usableAlpha = 0
                icon.unusableAlpha = 1
            elseif CooldownShowWhen == "always" then
                icon.usableAlpha = 1
                icon.unusableAlpha = 1
            else
                icon.usableAlpha = 1
                icon.unusableAlpha = 1
            end

            if BuffShowWhen == "present" then
                icon.presentAlpha = 1
                icon.absentAlpha = 0
            elseif BuffShowWhen == "absent" then
                icon.presentAlpha = 0
                icon.absentAlpha = 1
            elseif BuffShowWhen == "always" then
                icon.presentAlpha = 1
                icon.absentAlpha = 1
            else
                icon.presentAlpha = 1
                icon.absentAlpha = 1
            end

            if iconType == "cooldown" then
                if CooldownType == "spell" then
                    local spell = icon.Name[1]
                    if LiCD and LiCD.talentsRev[icon.Name[1]] then
                        spell = LiCD.talentsRev[icon.Name[1]]
                    end
                    if GetSpellCooldown(spell or "") then
                        icon.texture:SetTexture(TMW_GetSpellTexture(spell) or select(3, GetSpellInfo(spell)))
                        icon:SetScript("OnUpdate", TellMeWhen_Icon_SpellCooldown_OnUpdate)
                        if icon.ShowTimer then
                            icon:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
                            icon:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
                            icon:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
                            icon:SetScript("OnEvent", TellMeWhen_Icon_SpellCooldown_OnEvent)
                        else
                            icon:SetScript("OnEvent", nil)
                        end
                    else
                        TellMeWhen:Icon_ClearScripts(icon)
                        icon.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                    end
                elseif CooldownType == "item" then
                    local itemName, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(icon.Name[1] or "")
                    if itemName then
                        icon.texture:SetTexture(itemTexture)
                        icon:SetScript("OnUpdate", TellMeWhen_Icon_ItemCooldown_OnUpdate)
                        if icon.ShowTimer then
                            icon:RegisterEvent("BAG_UPDATE_COOLDOWN")
                            icon:SetScript("OnEvent", TellMeWhen_Icon_ItemCooldown_OnEvent)
                        else
                            icon:SetScript("OnEvent", nil)
                        end
                    else
                        TellMeWhen:Icon_ClearScripts(icon)
                        icon.learnedTexture = false
                        icon.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                    end
                end
                icon.Cooldown:SetReverse(false)
            elseif iconType == "buff" then
                icon:RegisterEvent("PLAYER_TARGET_CHANGED")
                icon:RegisterEvent("PLAYER_FOCUS_CHANGED")
                icon:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
                icon:RegisterEvent("UNIT_AURA")
                icon:SetScript("OnEvent", TellMeWhen_Icon_Buff_OnEvent)
                icon:SetScript("OnUpdate", nil)

                if not icon.Name[1] then
                    icon.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                elseif TMW_GetSpellTexture(icon.Name[1] or "") then
                    icon.texture:SetTexture(TMW_GetSpellTexture(icon.Name[1]))
                elseif (not icon.learnedTexture) then
                    icon.texture:SetTexture("Interface\\Icons\\INV_Misc_PocketWatch_01")
                end
                icon.Cooldown:SetReverse(true)
            elseif iconType == "reactive" then
                if TMW_GetSpellTexture(icon.Name[1] or "") then
                    icon.texture:SetTexture(TMW_GetSpellTexture(icon.Name[1]))
                    icon:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
                    icon:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
                    icon:SetScript("OnEvent", TellMeWhen_Icon_Reactive_OnEvent)
                    icon:SetScript("OnUpdate", TellMeWhen_Icon_Reactive_OnEvent)
                else
                    TellMeWhen:Icon_ClearScripts(icon)
                    icon.learnedTexture = false
                    icon.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                end
            elseif iconType == "wpnenchant" then
                icon:RegisterEvent("UNIT_INVENTORY_CHANGED")
                local slotID, _
                if icon.WpnEnchantType == "mainhand" then
                    slotID, _ = GetInventorySlotInfo("MainHandSlot")
                elseif icon.WpnEnchantType == "offhand" then
                    slotID, _ = GetInventorySlotInfo("SecondaryHandSlot")
                end
                local wpnTexture = GetInventoryItemTexture("player", slotID)
                if wpnTexture then
                    icon.texture:SetTexture(wpnTexture)
                    icon:SetScript("OnEvent", TellMeWhen_Icon_WpnEnchant_OnEvent)
                    icon:SetScript("OnUpdate", TellMeWhen_Icon_WpnEnchant_OnUpdate)
                else
                    TellMeWhen:Icon_ClearScripts(icon)
                    icon.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                end
            elseif iconType == "totem" then
                icon:RegisterEvent("PLAYER_TOTEM_UPDATE")
                icon:SetScript("OnEvent", TellMeWhen_Icon_Totem_OnEvent)
                icon:SetScript("OnUpdate", TellMeWhen_Icon_Totem_OnEvent)
                TellMeWhen_Icon_Totem_OnEvent(icon)
                if not icon.Name[1] then
                    icon.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                    icon.learnedTexture = false
                elseif TMW_GetSpellTexture(icon.Name[1] or "") then
                    icon.texture:SetTexture(TMW_GetSpellTexture(icon.Name[1]))
                elseif not icon.learnedTexture then
                    icon.texture:SetTexture("Interface\\Icons\\INV_Misc_PocketWatch_01")
                end
            else
                TellMeWhen:Icon_ClearScripts(icon)
                if icon.Name[1] ~= "" then
                    icon.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                else
                    icon.texture:SetTexture(nil)
                end
            end
        end

        icon.countText:Hide()
        icon.Cooldown:Hide()

        if Enabled then
            icon:SetAlpha(1.0)
        else
            icon:SetAlpha(0.4)
            TellMeWhen:Icon_ClearScripts(icon)
        end

        icon:Show()
        if DB.Locked then
            icon:EnableMouse(0)
            if not Enabled then
                icon:Hide()
            elseif not icon.Name[1] and iconType ~= "wpnenchant" then
                icon:Hide()
            end
            TellMeWhen:Icon_StatusCheck(icon, iconType)
        else
            icon:EnableMouse(1)
            icon.texture:SetVertexColor(1, 1, 1, 1)
            TellMeWhen:Icon_ClearScripts(icon)
        end
    end

    function TellMeWhen:Icon_ClearScripts(icon)
        icon:SetScript("OnEvent", nil)
        icon:SetScript("OnUpdate", nil)
    end

    function TellMeWhen:Icon_StatusCheck(icon, iconType)
        if iconType == "reactive" then
            TellMeWhen_Icon_ReactiveCheck(icon)
        elseif iconType == "buff" then
            TellMeWhen_Icon_BuffCheck(icon)
        elseif iconType == "cooldown" then
            TellMeWhen_Icon_SpellCooldown_OnEvent(icon)
        end
    end

    function TellMeWhen:TalentUpdate()
        activeSpec = GetActiveTalentGroup()
    end

    function TellMeWhen:GetActiveTalentGroup()
        if not activeSpec then
            TellMeWhen:TalentUpdate()
        end
        return activeSpec
    end

    function TellMeWhen:Update()
        for i = 1, maxGroups do
            TellMeWhen:Group_Update(i)
        end
    end

    function TellMeWhen:LockToggle()
        if DB.Locked then
            DB.Locked = false
        else
            DB.Locked = true
        end
        PlaySound("UChatScrollButton")
        TellMeWhen:Update()
    end

    function TellMeWhen:Reset()
        for i = 1, maxGroups do
            defaults.Groups[i] = groupDefaults
        end
        core.char.TMW = CopyTable(defaults)
        for i = 1, maxGroups do
            local group = _G["KTellMeWhen_Group" .. i]
            group:ClearAllPoints()
            group:SetPoint("TOPLEFT", "UIParent", "TOPLEFT", 100, -50 - (35 * i))
        end
        DB = core.char.TMW
        DB.Groups[1].Enabled = true
        TellMeWhen:Update()
        core:Print(L["Groups have been reset!"], "TellMeWhen")
    end

    local function SlashCommandHandler(cmd)
        if cmd == "reset" or cmd == "default" then
            TellMeWhen:Reset()
        elseif cmd == "config" or cmd == "options" then
            core:OpenConfig("TellMeWhen")
        else
            TellMeWhen:LockToggle()
        end
    end

    core:RegisterForEvent("VARIABLES_LOADED", function()
        if type(core.char.TMW) ~= "table" or not next(core.char.TMW) then
            for i = 1, maxGroups do
                defaults.Groups[i] = groupDefaults
            end

            core.char.TMW = CopyTable(defaults)
            core.char.TMW.Groups[1].Enabled = true
        end
        DB = core.char.TMW

        local pos = {"TOPLEFT", 100, -50}
        for i = 1, maxGroups do
            local g = TellMeWhen_CreateGroup("KTellMeWhen_Group" .. i, UIParent, DB.Groups[i].point or pos[1], DB.Groups[i].x or pos[2], DB.Groups[i].y or pos[3])
            pos[3] = pos[3] - 35
            g:SetID(i)
        end

        SLASH_KPACKTELLMEWHEN1 = "/tellmewhen"
        SLASH_KPACKTELLMEWHEN2 = "/tmw"
        SlashCmdList.KPACKTELLMEWHEN = SlashCommandHandler
    end)

    local options = {
        type = "group",
        name = "TellMeWhen",
        args = {
            desc1 = {
                type = "description",
                name = L["These options allow you to change the number, arrangement, and behavior of reminder icons."],
                order = 0,
                width = "full"
            },
            Locked = {
                type = "execute",
                name = function()
                    return DB.Locked and L["Unlock"] or L["Lock"]
                end,
                desc = L['Icons work when locked. When unlocked, you can move/size icon groups and right click individual icons for more settings. You can also type "/tellmewhen" or "/tmw" to lock/unlock.'],
                order = 0.1,
                func = function()
                    TellMeWhen:LockToggle()
                end
            },
            Reset = {
                type = "execute",
                name = RESET,
                order = 0.2,
                func = function()
                    TellMeWhen:Reset()
                end,
                confirm = function()
                    return L["Are you sure you want to reset all groups?"]
                end
            }
        }
    }

    core:RegisterForEvent("PLAYER_LOGIN", function()
        TellMeWhen:Update()

        for i = 1, maxGroups do
            options.args["group" .. i] = {
                type = "group",
                name = GROUP .. " " .. i,
                order = i,
                get = function(info)
                    return DB.Groups[i][info[#info]]
                end,
                set = function(info, val)
                    DB.Groups[i][info[#info]] = val
                    TellMeWhen:Update()
                end,
                args = {
                    header = {
                        type = "header",
                        name = GROUP .. " " .. i,
                        order = 0
                    },
                    Enabled = {
                        type = "toggle",
                        name = L["Enable"],
                        desc = L["Show and enable this group of icons."],
                        order = 1
                    },
                    PrimarySpec = {
                        type = "toggle",
                        name = L["Primary Spec"],
                        desc = L["Check to show this group of icons while in primary spec."],
                        order = 2
                    },
                    SecondarySpec = {
                        type = "toggle",
                        name = L["Secondary Spec"],
                        desc = L["Check to show this group of icons while in secondary spec."],
                        order = 3
                    },
                    OnlyInCombat = {
                        type = "toggle",
                        name = L["Only in combat"],
                        desc = L["Check to only show this group of icons while in combat."],
                        order = 4
                    },
                    Scale = {
                        type = "range",
                        name = L["Scale"],
                        order = 5,
                        min = 0.5,
                        max = 8,
                        step = 0.01,
                        bigStep = 0.1
                    },
                    Columns = {
                        type = "range",
                        name = L["Columns"],
                        desc = L["Set the number of icon columns in this group."],
                        order = 6,
                        min = 1,
                        max = 8,
                        step = 1
                    },
                    Rows = {
                        type = "range",
                        name = L["Rows"],
                        desc = L["Set the number of icon rows in this group."],
                        order = 6,
                        min = 1,
                        max = maxRows,
                        step = 1
                    },
                    Spacing = {
                        type = "range",
                        name = L["Spacing"],
                        order = 7,
                        min = 0,
                        max = 50,
                        step = 1
                    },
                    sep1 = {
                        type = "description",
                        name = " ",
                        order = 8
                    },
                    Reset = {
                        type = "execute",
                        name = RESET,
                        order = 9,
                        width = "full",
                        func = function()
                            local locked

                            if DB.Locked then
                                locked = true
                                DB.Locked = false
                                TellMeWhen:Group_Update(i)
                            end
                            local group = _G["KTellMeWhen_Group" .. i]
                            group:ClearAllPoints()
                            group:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 100, -50 - (35 * i - 1))
                            group.Scale = 2
                            DB.Groups[i].Scale = 2
                            TellMeWhen:Group_Update(i)

                            if locked then
                                DB.Locked = true
                                TellMeWhen:Group_Update(i)
                            end
                            core:Print(L:F("Group %d position successfully reset.", i), "TellMeWhen")
                        end
                    }
                }
            }
        end

        core.options.args.TellMeWhen = options
    end)

    core:RegisterForEvent("PLAYER_ENTERING_WORLD", TellMeWhen.Update)
    core:RegisterForEvent("PLAYER_TALENT_UPDATE", function()
        TellMeWhen:TalentUpdate()
        TellMeWhen:Update()
    end)
end)