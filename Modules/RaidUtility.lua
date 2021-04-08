assert(KPack, "KPack not found!")
KPack:AddModule("RaidUtility", function(_, core, L)
    if core:IsDisabled("RaidUtility") then return end

    local mod = core.RaidUtility or {}
    core.RaidUtility = mod

    local LSM = core.LSM or LibStub("LibSharedMedia-3.0")
    core.LSM = LSM

    local pairs, ipairs, select = pairs, ipairs, select
    local tinsert, tsort = table.insert, table.sort
    local strformat, strfind, strlower, strlen = string.format, string.find, string.lower, string.len
    local CreateFrame = CreateFrame
    local GetNumRaidMembers = GetNumRaidMembers
    local GetNumPartyMembers = GetNumPartyMembers
    local GetSpellInfo = GetSpellInfo
    local UnitExists, UnitIsPlayer, UnitIsFriend = UnitExists, UnitIsPlayer, UnitIsFriend
    local UnitName, UnitGUID, UnitClass = UnitName, UnitGUID, UnitClass
    local UnitInParty, UnitIsPartyLeader, IsPartyLeader = UnitInParty, UnitIsPartyLeader, IsPartyLeader
    local UnitInRaid, UnitIsRaidOfficer, IsRaidLeader = UnitInRaid, UnitIsRaidOfficer, IsRaidLeader
    local UnitPower, UnitPowerMax, UnitBuff = UnitPower, UnitPowerMax, UnitBuff

    local DB, SetupDatabase, _
    local defaults = {}
    local order = 1
    local options = {
        type = "group",
        name = L["Raid Utility"],
        args = {}
    }
    local CreateRaidUtilityPanel

    -- common functions

    local function Print(msg)
        if msg then
            core:Print(msg, "RaidUtility")
        end
    end

    local function CheckUnit(unit)
        return (unit and (UnitInParty(unit) or UnitInRaid(unit)) and UnitIsPlayer(unit) and UnitIsFriend("player", unit))
    end

    ---------------------------------------------------------------------------
    -- Raid Menu

    do
        local IsPartyLeader = IsPartyLeader
        local IsRaidLeader = IsRaidLeader
        local IsRaidOfficer = IsRaidOfficer
        local InCombatLockdown = InCombatLockdown
        local DoReadyCheck = DoReadyCheck
        local ToggleFriendsFrame = ToggleFriendsFrame

        local GetRaidRosterInfo = GetRaidRosterInfo
        local UninviteUnit = UninviteUnit

        local RaidUtilityPanel
        local showButton

        -- defaults
        defaults.Menu = {
            enabled = true,
            locked = false,
            point = "TOP",
            xOfs = -400,
            yOfs = 1
        }

        local function CheckRaidStatus()
            local inInstance, instanceType = IsInInstance()
            if (((IsRaidLeader() or IsRaidOfficer()) and GetNumRaidMembers() > 0) or (IsPartyLeader() and GetNumPartyMembers() > 0)) and not (inInstance and (instanceType == "pvp" or instanceType == "arena")) then
                return true
            else
                return false
            end
        end

        function CreateRaidUtilityPanel()
            SetupDatabase()
            if not DB.Menu.enabled or RaidUtilityPanel then
                return
            end
            RaidUtilityPanel = CreateFrame("Frame", "KPackRaidUtilityPanel", UIParent, "SecureHandlerClickTemplate")
            RaidUtilityPanel:SetBackdrop({
                bgFile = [[Interface\DialogFrame\UI-DialogBox-Background-Dark]],
                edgeFile = [[Interface\DialogFrame\UI-DialogBox-Border]],
                edgeSize = 8,
                insets = {left = 1, right = 1, top = 1, bottom = 1}
            })
            RaidUtilityPanel:SetBackdropColor(0, 0, 1, 0.85)
            RaidUtilityPanel:SetSize(230, 112)
            RaidUtilityPanel:SetPoint("TOP", UIParent, "TOP", -400, 1)
            RaidUtilityPanel:SetFrameLevel(3)
            RaidUtilityPanel:SetFrameStrata("HIGH")

            showButton = CreateFrame("Button", "KPackRaidUtility_ShowButton", UIParent, "KPackButtonTemplate, SecureHandlerClickTemplate")
            showButton:SetSize(136, 20)
            showButton:SetPoint(
                DB.Menu.point or "TOP",
                UIParent,
                DB.Menu.point or "TOP",
                DB.Menu.xOfs or -400,
                DB.Menu.yOfs or 0
            )
            showButton:SetText(RAID_CONTROL)
            showButton:SetFrameRef("KPackRaidUtilityPanel", RaidUtilityPanel)
            showButton:SetAttribute("_onclick", [=[
				local raidUtil = self:GetFrameRef("KPackRaidUtilityPanel")
				local closeBtn = raidUtil:GetFrameRef("KPackRaidUtility_CloseButton")
				self:Hide()
				raidUtil:Show()

				local point = self:GetPoint()
				local raidUtilPoint, closeBtnPoint, yOffset
				if string.find(point, "BOTTOM") then
					raidUtilPoint, closeBtnPoint, yOffset = "BOTTOM", "TOP", 2
				else
					raidUtilPoint, closeBtnPoint, yOffset = "TOP", "BOTTOM", -2
				end

				raidUtil:ClearAllPoints()
				raidUtil:SetPoint(raidUtilPoint, self, raidUtilPoint)

				closeBtn:ClearAllPoints()
				closeBtn:SetPoint(raidUtilPoint, raidUtil, closeBtnPoint, 0, yOffset)
			]=])
            showButton:SetScript("OnMouseUp", function(self) RaidUtilityPanel.toggled = true end)
            showButton:SetMovable(true)
            showButton:SetClampedToScreen(true)
            showButton:SetClampRectInsets(0, 0, -1, 1)
            showButton:RegisterForDrag("RightButton")
            showButton:SetFrameStrata("HIGH")
            showButton:SetScript("OnDragStart", function(self)
                if InCombatLockdown() then
                    Print(ERR_NOT_IN_COMBAT)
                    return
                elseif DB.Menu.locked then
                    return
                end
                self.moving = true
                self:StartMoving()
            end)

            showButton:SetScript("OnDragStop", function(self)
                if self.moving then
                    self.moving = nil
                    self:StopMovingOrSizing()
                    local point = self:GetPoint()
                    local xOffset = self:GetCenter()
                    local screenWidth = UIParent:GetWidth() / 2
                    xOffset = xOffset - screenWidth
                    self:ClearAllPoints()
                    if strfind(point, "BOTTOM") then
                        self:SetPoint("BOTTOM", UIParent, "BOTTOM", xOffset, -1)
                    else
                        self:SetPoint("TOP", UIParent, "TOP", xOffset, 1)
                    end
                    DB.Menu.point, _, _, DB.Menu.xOfs, DB.Menu.yOfs = self:GetPoint(1)
                end
            end)

            local close = CreateFrame("Button", "KPackRaidUtility_CloseButton", RaidUtilityPanel, "KPackButtonTemplate, SecureHandlerClickTemplate")
            close:SetSize(136, 20)
            close:SetPoint("TOP", RaidUtilityPanel, "BOTTOM", 0, -1)
            close:SetText(CLOSE)
            close:SetFrameRef("KPackRaidUtility_ShowButton", showButton)
            close:SetAttribute("_onclick", [=[self:GetParent():Hide(); self:GetFrameRef("KPackRaidUtility_ShowButton"):Show();]=])
            close:SetScript("OnMouseUp", function(self) RaidUtilityPanel.toggled = nil end)
            RaidUtilityPanel:SetFrameRef("KPackRaidUtility_CloseButton", close)

            local disband = CreateFrame("Button", nil, RaidUtilityPanel, "KPackButtonTemplate, SecureActionButtonTemplate")
            disband:SetSize(200, 20)
            disband:SetPoint("TOP", RaidUtilityPanel, "TOP", 0, -8)
            disband:SetText(L["Disband Group"])
            disband:SetScript("OnMouseUp", function()
                if CheckRaidStatus() then
                    StaticPopup_Show("DISBAND_RAID")
                end
            end)

            local maintank = CreateFrame("Button", nil, RaidUtilityPanel, "KPackButtonTemplate, SecureActionButtonTemplate")
            maintank:SetSize(95, 20)
            maintank:SetPoint("TOPLEFT", disband, "BOTTOMLEFT", 0, -5)
            maintank:SetText(MAINTANK)
            maintank:SetAttribute("type", "maintank")
            maintank:SetAttribute("unit", "target")
            maintank:SetAttribute("action", "toggle")

            local offtank = CreateFrame("Button", nil, RaidUtilityPanel, "KPackButtonTemplate, SecureActionButtonTemplate")
            offtank:SetSize(95, 20)
            offtank:SetPoint("TOPRIGHT", disband, "BOTTOMRIGHT", 0, -5)
            offtank:SetText(MAINASSIST)
            offtank:SetAttribute("type", "mainassist")
            offtank:SetAttribute("unit", "target")
            offtank:SetAttribute("action", "toggle")

            local ready = CreateFrame("Button", nil, RaidUtilityPanel, "KPackButtonTemplate, SecureActionButtonTemplate")
            ready:SetSize(200, 20)
            ready:SetPoint("TOPLEFT", maintank, "BOTTOMLEFT", 0, -5)
            ready:SetText(READY_CHECK)
            ready:SetScript("OnMouseUp", function()
                if CheckRaidStatus() then
                    DoReadyCheck()
                end
            end)

            local control = CreateFrame("Button", nil, RaidUtilityPanel, "KPackButtonTemplate, SecureActionButtonTemplate")
            control:SetSize(95, 20)
            control:SetPoint("TOPLEFT", ready, "BOTTOMLEFT", 0, -5)
            control:SetText(L["Raid Menu"])
            control:SetScript("OnMouseUp", function()
                if InCombatLockdown() then
                    Print(ERR_NOT_IN_COMBAT)
                    return
                end
                ToggleFriendsFrame(5)
            end)
            RaidUtilityPanel.control = control

            local convert =
                CreateFrame("Button", nil, RaidUtilityPanel, "SecureHandlerClickTemplate, KPackButtonTemplate")
            convert:SetSize(95, 20)
            convert:SetPoint("TOPRIGHT", ready, "BOTTOMRIGHT", 0, -5)
            convert:SetText(CONVERT_TO_RAID)
            convert:SetScript("OnMouseUp", function()
                if CheckRaidStatus() then
                    ConvertToRaid()
                    SetLootMethod("master", "player")
                end
            end)
            RaidUtilityPanel.convert = convert
        end

        function mod:RaidUtilityToggle()
            if not DB.Menu.enabled then
                if KPackRaidUtilityPanel then
                    KPackRaidUtilityPanel:Hide()
                    if KPackRaidUtility_ShowButton then
                        KPackRaidUtility_ShowButton:Hide()
                    end
                end
                return
            end

            CreateRaidUtilityPanel()

            if GetNumRaidMembers() == 0 and GetNumPartyMembers() > 0 and IsPartyLeader() then
                RaidUtilityPanel.control:SetWidth(95)
                RaidUtilityPanel.convert:Show()
            else
                RaidUtilityPanel.control:SetWidth(200)
                RaidUtilityPanel.convert:Hide()
            end

            if InCombatLockdown() then
                return
            end

            if CheckRaidStatus() then
                if RaidUtilityPanel.toggled == true then
                    RaidUtilityPanel:Show()
                    showButton:Hide()
                else
                    RaidUtilityPanel:Hide()
                    showButton:Show()
                end
            else
                RaidUtilityPanel:Hide()
                showButton:Hide()
            end
        end
        core:RegisterForEvent("PLAYER_ENTERING_WORLD", mod.RaidUtilityToggle)
        core:RegisterForEvent("RAID_ROSTER_UPDATE", mod.RaidUtilityToggle)
        core:RegisterForEvent("PARTY_MEMBERS_CHANGED", mod.RaidUtilityToggle)
        core:RegisterForEvent("PLAYER_REGEN_ENABLED", mod.RaidUtilityToggle)

        StaticPopupDialogs.DISBAND_RAID = {
            text = L["Are you sure you want to disband the group?"],
            button1 = ACCEPT,
            button2 = CANCEL,
            OnAccept = function()
                if InCombatLockdown() then
                    return
                end
                local numRaid = GetNumRaidMembers()
                if numRaid > 0 then
                    for i = 1, numRaid do
                        local name, _, _, _, _, _, _, online = GetRaidRosterInfo(i)
                        if online and name ~= core.name then
                            UninviteUnit(name)
                        end
                    end
                else
                    for i = MAX_PARTY_MEMBERS, 1, -1 do
                        if GetPartyMember(i) then
                            UninviteUnit(UnitName("party" .. i))
                        end
                    end
                end
            end,
            timeout = 0,
            whileDead = 1,
            hideOnEscape = 1,
            preferredIndex = 3
        }

        options.args.Control = {
            type = "group",
            name = RAID_CONTROL,
            order = order,
            get = function(i)
                return DB.Menu[i[#i]]
            end,
            set = function(i, val)
                DB.Menu[i[#i]] = val
                mod:RaidUtilityToggle()
            end,
            args = {
                enabled = {
                    type = "toggle",
                    name = L["Enable"],
                    order = 1
                },
                locked = {
                    type = "toggle",
                    name = L["Lock"],
                    order = 2
                }
            }
        }
        order = order + 1
    end

    ---------------------------------------------------------------------------
    -- Loot Method

    do
        local HandleLootMethod
        defaults.Loot = {
            enabled = false,
            party = {
                enabled = true,
                method = "group",
                threshold = 2,
                master = ""
            },
            raid = {
                enabled = true,
                method = "master",
                threshold = 2,
                master = ""
            }
        }

        options.args.Loot = {
            type = "group",
            name = LOOT_METHOD,
            order = order,
            args = {
                enabled = {
                    type = "toggle",
                    name = L["Enable"],
                    order = 1,
                    get = function()
                        return DB.Loot.enabled
                    end,
                    set = function(_, val)
                        DB.Loot.enabled = val
                        HandleLootMethod()
                    end
                },
                party = {
                    type = "group",
                    name = PARTY,
                    order = 2,
                    inline = true,
                    disabled = function()
                        return not DB.Loot.enabled
                    end,
                    get = function(i)
                        return DB.Loot.party[i[#i]]
                    end,
                    set = function(i, val)
                        DB.Loot.party[i[#i]] = val
                    end,
                    args = {
                        enabled = {
                            type = "toggle",
                            name = L["Enable"],
                            order = 1,
                            width = "full"
                        },
                        method = {
                            type = "select",
                            name = LOOT_METHOD,
                            order = 2,
                            disabled = function()
                                return not DB.Loot.party.enabled
                            end,
                            values = {
                                needbeforegreed = LOOT_NEED_BEFORE_GREED,
                                freeforall = LOOT_FREE_FOR_ALL,
                                roundrobin = LOOT_ROUND_ROBIN,
                                master = LOOT_MASTER_LOOTER,
                                group = LOOT_GROUP_LOOT
                            }
                        },
                        threshold = {
                            type = "select",
                            name = LOOT_THRESHOLD,
                            order = 3,
                            disabled = function()
                                return not DB.Loot.party.enabled
                            end,
                            values = {
                                [2] = "|cff1eff00" .. ITEM_QUALITY2_DESC .. "|r",
                                [3] = "|cff0070dd" .. ITEM_QUALITY3_DESC .. "|r",
                                [4] = "|cffa335ee" .. ITEM_QUALITY4_DESC .. "|r",
                                [5] = "|cffff8000" .. ITEM_QUALITY5_DESC .. "|r",
                                [6] = "|cffe6cc80" .. ITEM_QUALITY6_DESC .. "|r"
                            }
                        }
                    }
                },
                raid = {
                    type = "group",
                    name = RAID,
                    order = 3,
                    inline = true,
                    disabled = function()
                        return not DB.Loot.enabled
                    end,
                    get = function(i)
                        return DB.Loot.raid[i[#i]]
                    end,
                    set = function(i, val)
                        DB.Loot.raid[i[#i]] = val
                    end,
                    args = {
                        enabled = {
                            type = "toggle",
                            name = L["Enable"],
                            order = 1,
                            width = "full"
                        },
                        method = {
                            type = "select",
                            name = LOOT_METHOD,
                            order = 2,
                            disabled = function()
                                return not DB.Loot.raid.enabled
                            end,
                            values = {
                                needbeforegreed = LOOT_NEED_BEFORE_GREED,
                                freeforall = LOOT_FREE_FOR_ALL,
                                roundrobin = LOOT_ROUND_ROBIN,
                                master = LOOT_MASTER_LOOTER,
                                group = LOOT_GROUP_LOOT
                            }
                        },
                        threshold = {
                            type = "select",
                            name = LOOT_THRESHOLD,
                            order = 3,
                            disabled = function()
                                return not DB.Loot.raid.enabled
                            end,
                            values = {
                                [2] = "|cff1eff00" .. ITEM_QUALITY2_DESC .. "|r",
                                [3] = "|cff0070dd" .. ITEM_QUALITY3_DESC .. "|r",
                                [4] = "|cffa335ee" .. ITEM_QUALITY4_DESC .. "|r",
                                [5] = "|cffff8000" .. ITEM_QUALITY5_DESC .. "|r",
                                [6] = "|cffe6cc80" .. ITEM_QUALITY6_DESC .. "|r"
                            }
                        }
                    }
                },
                reset = {
                    type = "execute",
                    name = RESET,
                    order = 99,
                    width = "full",
                    confirm = function()
                        return L:F("Are you sure you want to reset %s to default?", LOOT_METHOD)
                    end,
                    func = function()
                        DB.Loot = defaults.Loot
                    end
                }
            }
        }
        order = order + 1

        local frame = CreateFrame("Frame")
        frame:Hide()
        frame:SetScript("OnUpdate", function(self, elapsed)
            self.elapsed = (self.elapsed or 0) + elapsed
            if self.elapsed >= 3 then
                SetLootThreshold(self.threshold)
                self:Hide()
            end
        end)

        function mod:IsPromoted(name)
            name = name or "player"
            if UnitInRaid(name) then
                return UnitIsRaidOfficer(name), "raid"
            elseif UnitInParty(name) then
                return UnitIsPartyLeader(name), "party"
            end
        end

        function HandleLootMethod()
            if not DB.Loot.enabled then
                return
            end
            local ranked, key = mod:IsPromoted()
            if not ranked or not key then
                return
            end
            if not DB.Loot[key].enabled then
                return
            end

            if IsRaidLeader() or IsPartyLeader() then
                local method = DB.Loot[key].method
                local threshold = DB.Loot[key].threshold

                local current = GetLootMethod()
                if current and current == method then
                    -- the threshold was changed, so we make sure to change it.
                    if threshold ~= GetLootThreshold() then
                        frame.threshold = threshold
                        frame.elapsed = 0
                        frame:Show()
                    end
                    return
                end
                SetLootMethod(method, core.name, threshold)

                if method == "master" or method == "group" then
                    frame.threshold = threshold
                    frame.elapsed = 0
                    frame:Show()
                end
            end
        end

        core:RegisterForEvent("PLAYER_ENTERING_WORLD", HandleLootMethod)
        core:RegisterForEvent("PARTY_CONVERTED_TO_RAID", HandleLootMethod)
    end

    ---------------------------------------------------------------------------
    -- Paladin Auras

    do
        -- paladin auras
        local aurasOrder, spellIcons
        local testAuras, testMode
        local auraMastery = select(1, GetSpellInfo(31821))
        do
            local auraDevotion = select(1, GetSpellInfo(48942))
            local auraRetribution = select(1, GetSpellInfo(54043))
            local auraConcentration = select(1, GetSpellInfo(19746))
            local auraShadow = select(1, GetSpellInfo(48943))
            local auraFrost = select(1, GetSpellInfo(48945))
            local auraFire = select(1, GetSpellInfo(48947))
            local auraCrusader = select(1, GetSpellInfo(32223))

            aurasOrder = {
                [auraDevotion] = 1,
                [auraRetribution] = 2,
                [auraConcentration] = 3,
                [auraShadow] = 4,
                [auraFrost] = 5,
                [auraFire] = 6,
                [auraCrusader] = 7
            }

            spellIcons = {
                [auraDevotion] = "Interface\\Icons\\Spell_Holy_DevotionAura",
                [auraRetribution] = "Interface\\Icons\\Spell_Holy_AuraOfLight",
                [auraConcentration] = "Interface\\Icons\\Spell_Holy_MindSooth",
                [auraShadow] = "Interface\\Icons\\Spell_Shadow_SealOfKings",
                [auraFrost] = "Interface\\Icons\\Spell_Frost_WizardMark",
                [auraFire] = "Interface\\Icons\\Spell_Fire_SealOfFire",
                [auraCrusader] = "Interface\\Icons\\Spell_Holy_CrusaderAura"
            }

            testAuras = {
                [auraDevotion] = "Name1",
                [auraRetribution] = "Name2",
                [auraConcentration] = "Name3",
                [auraShadow] = "Name4",
                [auraFrost] = "Name5",
                [auraFire] = "Name6",
                [auraCrusader] = "Name7"
            }
        end

        -- defaults
        defaults.Auras = {
            enabled = true,
            locked = false,
            updateInterval = 0.25,
            hideTitle = false,
            scale = 1,
            font = "Yanone",
            fontSize = 14,
            fontFlags = "OUTLINE",
            iconSize = 24,
            align = "LEFT",
            spacing = 2
        }

        local display, CreateDisplay
        local ShowDisplay, HideDisplay
        local LockDisplay, UnlockDisplay
        local UpdateDisplay

        local auras, auraFrames = {}, {}
        local AddAura, RemoveAura
        local FetchDisplay, fetched
        local RenderDisplay, rendered
        local ResetFrames

        function AddAura(auraname, playername)
            auras[auraname] = playername
            rendered = nil
        end

        function RemoveAura(auraname, playername)
            auras[auraname] = nil
            local f = _G["KPackPaladinAuras" .. playername]
            if f then
                f:Hide()
                f.cooldown:Hide()
            end
            rendered = nil
        end

        function FetchDisplay()
            if not fetched then
                auras = {}
                for i = 1, 32 do
                    local name, _, icon, _, _, _, _, unit = UnitBuff("player", i)
                    if name and spellIcons[name] and unit then
                        AddAura(name, UnitName(unit))
                    end
                end
                fetched = true
            end
        end

        do
            local function SortAuras(a, b)
                if not aurasOrder[a[1]] then
                    return true
                elseif not aurasOrder[b[1]] then
                    return false
                else
                    return aurasOrder[a[1]] < aurasOrder[b[1]]
                end
            end

            function ResetFrames()
                for k, v in pairs(auraFrames) do
                    if _G[k] then
                        _G[k]:Hide()
                        _G[k] = nil
                    end
                    v = nil
                end
            end

            function RenderDisplay()
                ResetFrames()
                if not DB.Auras.enabled then
                    rendered = true
                    return
                end

                local list = {}
                for auraname, playername in pairs(auras) do
                    tinsert(list, {auraname, playername})
                end
                tsort(list, SortAuras)

                local size = DB.Auras.iconSize or 24

                for i = 1, #list do
                    local aura = list[i]
                    local fname = "KPackPaladinAuras" .. aura[2]

                    local f = _G[fname]
                    if not f then
                        f = CreateFrame("Frame", fname, display)

                        local t = f:CreateTexture(nil, "BACKGROUND")
                        t:SetSize(size, size)
                        t:SetTexCoord(0.1, 0.9, 0.1, 0.9)
                        f.icon = t

                        t = CreateFrame("Cooldown", nil, display, "CooldownFrameTemplate")
                        t:SetAllPoints(f.icon)
                        f.cooldown = t

                        t = f:CreateFontString(nil, "ARTWORK")
                        t:SetFont(LSM:Fetch("font", DB.Auras.font), DB.Auras.fontSize, DB.Auras.fontFlags)
                        t:SetSize(110, size)
                        t:SetJustifyV("MIDDLE")
                        f.name = t
                    end

                    f:SetSize(134, size)
                    f:SetPoint("TOPLEFT", display, "TOPLEFT", 0, -((size + (DB.Auras.spacing or 0)) * (i - 1)))
                    f.icon:SetTexture(spellIcons[aura[1]])
                    f.name:SetText(aura[2])
                    f:Show()

                    if DB.Auras.align == "RIGHT" then
                        f.icon:SetPoint("RIGHT", f, "RIGHT", -3, 0)
                        f.name:SetPoint("RIGHT", f.icon, "LEFT", -(size / 3), 0)
                        f.name:SetJustifyH("RIGHT")
                    else
                        f.icon:SetPoint("LEFT", f, "LEFT", 3, 0)
                        f.name:SetPoint("LEFT", f.icon, "RIGHT", size / 3, 0)
                        f.name:SetJustifyH("LEFT")
                    end
                    auraFrames[fname] = true
                end

                rendered = true
            end
        end

        function UpdateDisplay()
            if not display then
                return
            end

            if DB.Auras.enabled then
                ShowDisplay()
            else
                HideDisplay()
            end

            if DB.Auras.locked then
                LockDisplay()
            else
                UnlockDisplay()
            end

            core:RestorePosition(display, DB.Auras)

            display:SetScale(DB.Auras.scale or 1)

            display.header:SetFont(LSM:Fetch("font", DB.Auras.font), DB.Auras.fontSize, DB.Auras.fontFlags)
            display.header:SetJustifyH(DB.Auras.align or "LEFT")
            if DB.Auras.hideTitle and display.locked then
                display.header:Hide()
            else
                display.header:Show()
            end

            local iconSize = DB.Auras.iconSize or 24
            display:SetHeight(iconSize * 7 + (DB.Auras.spacing or 0) * 6)

            if testMode then
                auras = testAuras
            else
                auras, fetched = {}, nil
                FetchDisplay()
            end

            for _, name in pairs(auras) do
                local f = _G["KPackPaladinAuras" .. name]
                if f then
                    f:SetHeight(iconSize + 2)
                    f.name:SetFont(LSM:Fetch("font", DB.Auras.font), DB.Auras.fontSize, DB.Auras.fontFlags)
                    f.icon:SetSize(iconSize, iconSize)

                    f.icon:ClearAllPoints()
                    f.name:ClearAllPoints()
                    if DB.Auras.align == "RIGHT" then
                        f.icon:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
                        f.name:SetPoint("RIGHT", f.icon, "LEFT", -(iconSize / 3), 0)
                        f.name:SetJustifyH("RIGHT")
                    else
                        f.icon:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
                        f.name:SetPoint("LEFT", f.icon, "RIGHT", iconSize / 3, 0)
                        f.name:SetJustifyH("LEFT")
                    end
                end
            end

            rendered = nil
        end

        do
            local function StartMoving(self)
                self.moving = true
                self:StartMoving()
            end

            local function StopMoving(self)
                if self.moving then
                    self:StopMovingOrSizing()
                    self.moving = nil
                    core:SavePosition(self, DB.Auras)
                end
            end

            local function OnMouseDown(self, button)
                if button == "RightButton" then
                    core:OpenConfig("RaidUtility")
                end
            end

            function CreateDisplay()
                if display then
                    return
                end
                display = CreateFrame("Frame", "KPackPaladinAuras", UIParent)
                display:SetSize(134, (DB.Auras.iconSize or 24) * 7 + (DB.Auras.spacing or 0) * 6)
                display:SetClampedToScreen(true)
                display:SetScale(DB.Auras.scale or 1)
                core:RestorePosition(display, DB.Auras)

                local t = display:CreateTexture(nil, "BACKGROUND")
                t:SetPoint("TOPLEFT", -2, 2)
                t:SetPoint("BOTTOMRIGHT", 2, -2)
                t:SetTexture(0, 0, 0, 0.5)
                display.bg = t

                t = display:CreateFontString(nil, "OVERLAY")
                t:SetFont(LSM:Fetch("font", DB.Auras.font), DB.Auras.fontSize, DB.Auras.fontFlags)
                t:SetPoint("BOTTOMLEFT", display, "TOPLEFT", 0, 5)
                t:SetPoint("BOTTOMRIGHT", display, "TOPRIGHT", 0, 5)
                t:SetText(L["Paladin Auras"])
                t:SetTextColor(0.96, 0.55, 0.73)
                t:SetJustifyH(DB.Auras.align or "LEFT")
                display.header = t
            end

            function LockDisplay()
                if not display then
                    CreateDisplay()
                end
                display:EnableMouse(false)
                display:SetMovable(false)
                display:RegisterForDrag(nil)
                display:SetScript("OnDragStart", nil)
                display:SetScript("OnDragStop", nil)
                display:SetScript("OnMouseDown", nil)
                display.bg:SetTexture(0, 0, 0, 0)
                if DB.Auras.hideTitle then
                    display.header:Hide()
                end
                display.locked = true
            end

            function UnlockDisplay()
                if not display then
                    CreateDisplay()
                end
                display:EnableMouse(true)
                display:SetMovable(true)
                display:RegisterForDrag("LeftButton")
                display:SetScript("OnDragStart", StartMoving)
                display:SetScript("OnDragStop", StopMoving)
                display:SetScript("OnMouseDown", OnMouseDown)
                display.bg:SetTexture(0, 0, 0, 0.5)
                if DB.Auras.hideTitle then
                    display.header:Show()
                end
                display.locked = nil
            end
        end

        do
            local function OnUpdate(self, elapsed)
                self.lastUpdate = (self.lastUpdate or 0) + elapsed
                if self.lastUpdate > (DB.Auras.updateInterval or 0.25) then
                    if not fetched then
                        FetchDisplay()
                    end
                    if not rendered then
                        RenderDisplay()
                    end
                    self.lastUpdate = 0
                end
            end

            local function OnEvent(self, event, ...)
                if not self or self ~= display or event ~= "COMBAT_LOG_EVENT_UNFILTERED" then
                    return
                elseif arg2 == "SPELL_AURA_APPLIED" and arg4 and CheckUnit(arg4) then
                    if spellIcons[arg10] and arg7 and arg7 == core.name then
                        AddAura(arg10, arg4)
                    elseif arg10 == auraMastery then
                        local f = _G["KPackPaladinAuras" .. arg4]
                        if f then
                            CooldownFrame_SetTimer(f.cooldown, GetTime(), 6, 1)
                        end
                    end
                elseif arg2 == "SPELL_AURA_REMOVED" and arg4 and CheckUnit(arg4) then
                    if spellIcons[arg10] and arg7 and arg7 == core.name then
                        RemoveAura(arg10, arg4)
                    elseif arg10 == auraMastery then
                        local f = _G["KPackPaladinAuras" .. arg4]
                        if f then
                            rendered = nil
                            f.cooldown:Hide()
                        end
                    end
                end
            end

            function ShowDisplay()
                if not display then
                    CreateDisplay()
                end
                display:Show()
                display:SetScript("OnUpdate", OnUpdate)
                display:SetScript("OnEvent", OnEvent)
                display:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
            end

            function HideDisplay()
                if display then
                    display:Hide()
                    display:SetScript("OnUpdate", nil)
                    display:SetScript("OnEvent", nil)
                    display:UnregisterAllEvents()
                end
            end
        end

        options.args.Auras = {
            type = "group",
            name = L["Paladin Auras"],
            order = order,
            get = function(i)
                return DB.Auras[i[#i]]
            end,
            set = function(i, val)
                DB.Auras[i[#i]] = val
                UpdateDisplay()
            end,
            args = {
                enabled = {
                    type = "toggle",
                    name = L["Enable"],
                    order = 1
                },
                testMode = {
                    type = "toggle",
                    name = L["Configuration Mode"],
                    desc = L["Toggle configuration mode to allow moving frames and setting appearance options."],
                    order = 2,
                    get = function()
                        return testMode
                    end,
                    set = function(_, val)
                        testMode = val
                        if testMode then
                            display:UnregisterAllEvents()
                        else
                            display:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
                        end
                        ResetFrames()
                        UpdateDisplay()
                    end
                },
                locked = {
                    type = "toggle",
                    name = L["Lock"],
                    order = 3,
                    disabled = function()
                        return not DB.Auras.enabled
                    end
                },
                updateInterval = {
                    type = "range",
                    name = L["Update Frequency"],
                    order = 4,
                    disabled = function()
                        return not DB.Auras.enabled
                    end,
                    min = 0.1,
                    max = 1,
                    step = 0.05,
                    bigStep = 0.1
                },
                appearance = {
                    type = "group",
                    name = L["Appearance"],
                    order = 5,
                    inline = true,
                    disabled = function()
                        return not DB.Auras.enabled
                    end,
                    args = {
                        font = {
                            type = "select",
                            name = L["Font"],
                            order = 1,
                            dialogControl = "LSM30_Font",
                            values = AceGUIWidgetLSMlists.font
                        },
                        fontFlags = {
                            type = "select",
                            name = L["Font Outline"],
                            order = 2,
                            values = {
                                [""] = NONE,
                                ["OUTLINE"] = L["Outline"],
                                ["THINOUTLINE"] = L["Thin outline"],
                                ["THICKOUTLINE"] = L["Thick outline"],
                                ["MONOCHROME"] = L["Monochrome"],
                                ["OUTLINEMONOCHROME"] = L["Outlined monochrome"]
                            }
                        },
                        fontSize = {
                            type = "range",
                            name = L["Font Size"],
                            order = 3,
                            min = 8,
                            max = 30,
                            step = 1
                        },
                        align = {
                            type = "select",
                            name = L["Text Alignment"],
                            order = 4,
                            values = {LEFT = L["Left"], RIGHT = L["Right"]}
                        },
                        iconSize = {
                            type = "range",
                            name = L["Icon Size"],
                            order = 5,
                            min = 8,
                            max = 30,
                            step = 1
                        },
                        spacing = {
                            type = "range",
                            name = L["Spacing"],
                            order = 6,
                            min = 0,
                            max = 30,
                            step = 1
                        },
                        scale = {
                            type = "range",
                            name = L["Scale"],
                            order = 7,
                            min = 0.5,
                            max = 3,
                            step = 0.01,
                            bigStep = 0.1
                        },
                        hideTitle = {
                            type = "toggle",
                            name = L["Hide Title"],
                            desc = L["Enable this if you want to hide the title text when locked."],
                            order = 8
                        }
                    }
                },
                reset = {
                    type = "execute",
                    name = RESET,
                    order = 99,
                    width = "full",
                    confirm = function()
                        return L:F("Are you sure you want to reset %s to default?", L["Paladin Auras"])
                    end,
                    func = function()
                        DB.Auras = defaults.Auras
                        UpdateDisplay()
                    end
                }
            }
        }
        order = order + 1

        core:RegisterForEvent("PLAYER_ENTERING_WORLD", function()
            SetupDatabase()
            if DB.Auras.enabled then
                ShowDisplay()
            else
                HideDisplay()
            end

            if DB.Auras.locked then
                LockDisplay()
            else
                UnlockDisplay()
            end
        end)
    end

    ---------------------------------------------------------------------------
    -- Sunder counter

    do
        local display, CreateDisplay
        local ShowDisplay, HideDisplay
        local LockDisplay, UnlockDisplay
        local UpdateDisplay
        local RenderDisplay, rendered
        local ResetFrames

        local AddSunder, ResetSunders, ReportSunders

        local sunder = select(1, GetSpellInfo(47467))
        local sunders, sunderFrames = {}, {}
        local testSunders, testMode = {Name1 = 20, Name2 = 32, Name3 = 6, Name4 = 12}

        -- defaults
        defaults.Sunders = {
            enabled = true,
            locked = false,
            updateInterval = 0.25,
            hideTitle = false,
            font = "Yanone",
            fontSize = 14,
            fontFlags = "OUTLINE",
            align = "RIGHT",
            spacing = 2,
            scale = 1,
            sunders = {}
        }

        function UpdateDisplay()
            if not display then
                return
            end

            if DB.Sunders.enabled then
                ShowDisplay()
            else
                HideDisplay()
            end

            if DB.Sunders.locked then
                LockDisplay()
            else
                UnlockDisplay()
            end

            core:RestorePosition(display, DB.Sunders)

            display:SetScale(DB.Sunders.scale or 1)

            display.header.text:SetFont(
                LSM:Fetch("font", DB.Sunders.font),
                DB.Sunders.fontSize,
                DB.Sunders.fontFlags
            )
            display.header.text:SetJustifyH(DB.Sunders.align or "LEFT")
            if DB.Sunders.hideTitle and display.locked then
                display.header:Hide()
            else
                display.header:Show()
            end

            sunders = testMode and testSunders or DB.Sunders.sunders

            for name, _ in pairs(sunders) do
                local f = _G["KPackSunderCounter" .. name]
                if f then
                    f.text:SetFont(LSM:Fetch("font", DB.Sunders.font), DB.Sunders.fontSize, DB.Sunders.fontFlags)
                    f.text:SetJustifyH(DB.Sunders.align or "RIGHT")
                end
            end

            rendered = nil
        end

        do
            local menuFrame
            local menu = {
                {
                    text = RESET,
                    func = function()
                        ResetSunders()
                    end,
                    notCheckable = 1
                },
                {
                    text = L["Report"],
                    func = function()
                        ReportSunders()
                    end,
                    notCheckable = 1
                }
            }

            local function StartMoving(self)
                self.moving = true
                self:StartMoving()
            end

            local function StopMoving(self)
                if self.moving then
                    self:StopMovingOrSizing()
                    self.moving = nil
                    core:SavePosition(self, DB.Sunders)
                end
            end

            local function OnMouseDown(self, button)
                if button == "RightButton" then
                    core:OpenConfig("RaidUtility")
                end
            end

            function CreateDisplay()
                if display then
                    return
                end
                display = CreateFrame("Frame", "KPackSunderCounter", UIParent)
                display:SetSize(134, 20)
                display:SetClampedToScreen(true)
                display:SetScale(DB.Sunders.scale or 1)
                core:RestorePosition(display, DB.Sunders)

                local t = display:CreateTexture(nil, "BACKGROUND")
                t:SetPoint("TOPLEFT", -2, 2)
                t:SetPoint("BOTTOMRIGHT", 2, -2)
                t:SetTexture(0, 0, 0, 0.5)
                display.bg = t

                t = CreateFrame("Button", nil, display)
                t:SetHeight(DB.Sunders.fontSize + 4)

                t.text = t:CreateFontString(nil, "OVERLAY")
                t.text:SetFont(LSM:Fetch("font", DB.Sunders.font), DB.Sunders.fontSize, DB.Sunders.fontFlags)
                t.text:SetText(sunder)
                t.text:SetAllPoints(t)
                t.text:SetJustifyH(DB.Sunders.align or "LEFT")
                t.text:SetJustifyV("BOTTOM")
                t.text:SetTextColor(0.78, 0.61, 0.43)
                t:SetPoint("BOTTOMLEFT", display, "TOPLEFT", 0, 5)
                t:SetPoint("BOTTOMRIGHT", display, "TOPRIGHT", 0, 5)
                t:RegisterForClicks("RightButtonUp")
                t:SetScript("OnMouseUp", function(self, button)
                    if next(sunders) and not testMode and button == "RightButton" then
                        menuFrame = menuFrame or CreateFrame("Frame", "KPackSunderCounterMenu", display, "UIDropDownMenuTemplate")
                        EasyMenu(menu, menuFrame, "cursor", 0, 0, "MENU")
                    end
                end)
                display.header = t
            end

            function LockDisplay()
                if not display then
                    CreateDisplay()
                end
                display:EnableMouse(false)
                display:SetMovable(false)
                display:RegisterForDrag(nil)
                display:SetScript("OnDragStart", nil)
                display:SetScript("OnDragStop", nil)
                display:SetScript("OnMouseDown", nil)
                display.bg:SetTexture(0, 0, 0, 0)
                if DB.Sunders.hideTitle then
                    display.header:Hide()
                end
                display.locked = true
            end

            function UnlockDisplay()
                if not display then
                    CreateDisplay()
                end
                display:EnableMouse(true)
                display:SetMovable(true)
                display:RegisterForDrag("LeftButton")
                display:SetScript("OnDragStart", StartMoving)
                display:SetScript("OnDragStop", StopMoving)
                display:SetScript("OnMouseDown", OnMouseDown)
                display.bg:SetTexture(0, 0, 0, 0.5)
                if DB.Sunders.hideTitle then
                    display.header:Show()
                end
                display.locked = nil
            end
        end

        function AddSunder(name)
            sunders[name] = (sunders[name] or 0) + 1
            rendered = nil
        end

        function ResetSunders()
            ResetFrames()
            DB.Sunders.sunders = {}
            rendered = nil
            UpdateDisplay()
        end

        function ReportSunders()
            if testMode then
                return
            end

            local list = {}
            for name, count in pairs(sunders) do
                tinsert(list, {name, count})
            end
            if #list == 0 then
                return
            end
            tsort(list, function(a, b) return (a[2] or 0) > (b[2] or 0) end)

            local channel = "SAY"
            if GetNumRaidMembers() > 0 then
                channel = "RAID"
            elseif GetNumPartyMembers() > 0 then
                channel = "PARTY"
            end

            SendChatMessage(sunder, channel)
            for i, sun in ipairs(list) do
                SendChatMessage(strformat("%2u. %s   %s", i, sun[1], sun[2]), channel)
            end
        end

        do
            local function OnUpdate(self, elapsed)
                self.lastUpdate = (self.lastUpdate or 0) + elapsed
                if self.lastUpdate > (DB.Sunders.updateInterval or 0.25) then
                    if not rendered then
                        RenderDisplay()
                    end
                    self.lastUpdate = 0
                end
            end

            local function OnEvent(self, event, ...)
                if not self or self ~= display or event ~= "COMBAT_LOG_EVENT_UNFILTERED" then
                    return
                end
                if arg4 and CheckUnit(arg4) and arg2 == "SPELL_CAST_SUCCESS" and arg10 and arg10 == sunder then
                    AddSunder(arg4)
                end
            end

            function ShowDisplay()
                if not display then
                    CreateDisplay()
                end
                display:Show()
                display:SetScript("OnUpdate", OnUpdate)
                display:SetScript("OnEvent", OnEvent)
                display:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
            end

            function HideDisplay()
                if display then
                    display:Hide()
                    display:SetScript("OnUpdate", nil)
                    display:SetScript("OnEvent", nil)
                    display:UnregisterAllEvents()
                end
            end
        end

        function ResetFrames()
            for k, v in pairs(sunderFrames) do
                if _G[k] then
                    _G[k]:Hide()
                    _G[k] = nil
                end
                v = nil
            end
        end

        function RenderDisplay()
            if rendered then
                return
            end
            ResetFrames()

            local list = {}
            for name, count in pairs(sunders or {}) do
                tinsert(list, {name, count})
            end
            tsort(list, function(a, b) return (a[2] or 0) > (b[2] or 0) end)

            local height = 20

            for i = 1, #list do
                local entry = list[i]
                if entry then
                    local fname = "KPackSunderCounter" .. entry[1]

                    local f = _G[fname]
                    if not f then
                        f = CreateFrame("Frame", fname, display)

                        local t = f:CreateFontString(nil, "OVERLAY")
                        t:SetFont(LSM:Fetch("font", DB.Sunders.font), DB.Sunders.fontSize, DB.Sunders.fontFlags)
                        t:SetPoint("TOPLEFT", f, "TOPLEFT")
                        t:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT")
                        t:SetJustifyH(DB.Sunders.align or "RIGHT")
                        t:SetJustifyV("MIDDLE")
                        f.text = t
                    end

                    f:SetHeight(20)
                    f.text:SetText(strformat("%s: %d", entry[1], entry[2]))
                    f:SetPoint("TOPLEFT", display, "TOPLEFT", 0, -((21 + (DB.Sunders.spacing or 0)) * (i - 1)))
                    f:SetPoint("RIGHT", display)
                    f:Show()
                    if i > 1 then
                        height = height + 21 + (DB.Sunders.spacing or 0)
                    end
                    sunderFrames[fname] = true
                end
            end

            display:SetHeight(height)
            rendered = true
        end

        options.args.Sunders = {
            type = "group",
            name = sunder,
            order = order,
            get = function(i)
                return DB.Sunders[i[#i]]
            end,
            set = function(i, val)
                DB.Sunders[i[#i]] = val
                UpdateDisplay()
            end,
            args = {
                enabled = {
                    type = "toggle",
                    name = L["Enable"],
                    order = 1
                },
                testMode = {
                    type = "toggle",
                    name = L["Configuration Mode"],
                    desc = L["Toggle configuration mode to allow moving frames and setting appearance options."],
                    order = 2,
                    get = function()
                        return testMode
                    end,
                    set = function(_, val)
                        testMode = val
                        if testMode then
                            display:UnregisterAllEvents()
                        else
                            display:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
                        end
                        ResetFrames()
                        UpdateDisplay()
                    end
                },
                locked = {
                    type = "toggle",
                    name = L["Lock"],
                    order = 3,
                    disabled = function()
                        return not DB.Sunders.enabled
                    end
                },
                updateInterval = {
                    type = "range",
                    name = L["Update Frequency"],
                    order = 4,
                    disabled = function()
                        return not DB.Sunders.enabled
                    end,
                    min = 0.1,
                    max = 1,
                    step = 0.05,
                    bigStep = 0.1
                },
                appearance = {
                    type = "group",
                    name = L["Appearance"],
                    order = 5,
                    inline = true,
                    disabled = function()
                        return not DB.Sunders.enabled
                    end,
                    args = {
                        font = {
                            type = "select",
                            name = L["Font"],
                            order = 1,
                            dialogControl = "LSM30_Font",
                            values = AceGUIWidgetLSMlists.font
                        },
                        fontFlags = {
                            type = "select",
                            name = L["Font Outline"],
                            order = 2,
                            values = {
                                [""] = NONE,
                                ["OUTLINE"] = L["Outline"],
                                ["THINOUTLINE"] = L["Thin outline"],
                                ["THICKOUTLINE"] = L["Thick outline"],
                                ["MONOCHROME"] = L["Monochrome"],
                                ["OUTLINEMONOCHROME"] = L["Outlined monochrome"]
                            }
                        },
                        fontSize = {
                            type = "range",
                            name = L["Font Size"],
                            order = 3,
                            min = 8,
                            max = 30,
                            step = 1
                        },
                        align = {
                            type = "select",
                            name = L["Text Alignment"],
                            order = 4,
                            values = {LEFT = L["Left"], RIGHT = L["Right"]}
                        },
                        spacing = {
                            type = "range",
                            name = L["Spacing"],
                            order = 5,
                            min = 0,
                            max = 30,
                            step = 1
                        },
                        scale = {
                            type = "range",
                            name = L["Scale"],
                            order = 6,
                            min = 0.5,
                            max = 3,
                            step = 0.01,
                            bigStep = 0.1
                        },
                        hideTitle = {
                            type = "toggle",
                            name = L["Hide Title"],
                            desc = L["Enable this if you want to hide the title text when locked."],
                            order = 7
                        }
                    }
                },
                reset = {
                    type = "execute",
                    name = RESET,
                    order = 99,
                    width = "full",
                    confirm = function()
                        return L:F("Are you sure you want to reset %s to default?", sunder)
                    end,
                    func = function()
                        DB.Sunders = defaults.Sunders
                        UpdateDisplay()
                    end
                }
            }
        }
        order = order + 1

        core:RegisterForEvent("PLAYER_ENTERING_WORLD", function()
            SetupDatabase()
            if DB.Sunders.enabled then
                sunders = DB.Sunders.sunders
                ShowDisplay()
            else
                HideDisplay()
            end

            if DB.Sunders.locked then
                LockDisplay()
            else
                UnlockDisplay()
            end

            SLASH_KPACKSUNDER1 = "/sunder"
            SlashCmdList.KPACKSUNDER = function(cmd)
                cmd = strlower(cmd:trim())
                if cmd == "reset" then
                    ResetSunders()
                elseif cmd == "report" then
                    ReportSunders()
                elseif cmd == "lock" then
                    LockDisplay()
                elseif cmd == "unlock" then
                    UnlockDisplay()
                else
                    core:OpenConfig("RaidUtility")
                end
            end
        end)
    end

    ---------------------------------------------------------------------------
    -- Healers Mana

    do
        defaults.Mana = {
            enabled = true,
            locked = false,
            updateInterval = 0.25,
            hideTitle = false,
            scale = 1,
            font = "Yanone",
            fontSize = 14,
            fontFlags = "OUTLINE",
            showIcon = true,
            iconSize = 24,
            align = "LEFT",
            width = 180,
            spacing = 2
        }

        local LGT = LibStub("LibGroupTalents-1.0", true)
        local display, CreateDisplay
        local ShowDisplay, HideDisplay
        local LockDisplay, UnlockDisplay
        local UpdateDisplay
        local RenderDisplay, rendered
        local UpdateMana
        local healers, healerFrames = {}, {}
        local testHealers = {
            raid1 = {
                name = "Name 1",
                class = "DRUID",
                curmana = 25000,
                maxmana = 44000,
                icon = "Interface\\Icons\\spell_nature_healingtouch"
            },
            raid2 = {
                name = "Name 2",
                class = "SHAMAN",
                curmana = 18000,
                maxmana = 36000,
                icon = "Interface\\Icons\\spell_nature_magicimmunity"
            },
            raid3 = {
                name = "Name 3",
                class = "PRIEST",
                spec = 2,
                curmana = 24000,
                maxmana = 32000,
                icon = "Interface\\Icons\\spell_holy_guardianspirit"
            },
            raid4 = {
                name = "Name 4",
                class = "PRIEST",
                curmana = 17000,
                maxmana = 32000,
                icon = "Interface\\Icons\\spell_holy_powerwordshield"
            },
            raid5 = {
                name = "Name 5",
                class = "PALADIN",
                curmana = 17000,
                maxmana = 45000,
                icon = "Interface\\Icons\\spell_holy_holybolt"
            }
        }

        local colorsTable = {
            DRUID = {1, 0.49, 0.04},
            PALADIN = {0.96, 0.55, 0.73},
            PRIEST = {1, 1, 1},
            SHAMAN = {0, 0.44, 0.87}
        }

        local function GetHealerIcon(unit, class)
            class = class or select(2, UnitClass(unit))
            if class == "SHAMAN" then
                return "Interface\\Icons\\spell_nature_magicimmunity"
            elseif class == "PALADIN" then
                return "Interface\\Icons\\spell_holy_holybolt"
            elseif class == "DRUID" then
                return "Interface\\Icons\\spell_nature_healingtouch"
            elseif class == "PRIEST" then
                local tree = LGT.roster[UnitGUID(unit)].talents[LGT:GetActiveTalentGroup(unit)]
                if strlen(tree[1]) > strlen(tree[2]) then
                    return "Interface\\Icons\\spell_holy_powerwordshield"
                else
                    return "Interface\\Icons\\spell_holy_guardianspirit"
                end
            end
            return "Interface\\Icons\\INV_Misc_QuestionMark"
        end

        local function ResetFrames()
            for k, v in pairs(healerFrames) do
                if _G[k] then
                    _G[k]:Hide()
                    _G[k] = nil
                end
                v = nil
            end
        end

        local function CacheHealers()
            if testMode then
                return
            end

            local prefix, min, max = "raid", 1, GetNumRaidMembers()
            if max == 0 then
                prefix, min, max = "party", 0, GetNumPartyMembers()
            end

            healers = {}

            for i = min, max do
                local unit = (i == 0) and "player" or prefix .. tostring(i)
                if UnitExists(unit) and LGT:GetUnitRole(unit) == "healer" then
                    local class = select(2, UnitClass(unit))
                    healers[unit] = {
                        name = UnitName(unit),
                        class = class,
                        icon = GetHealerIcon(unit, class),
                        curmana = UnitPower(unit, 0),
                        maxmana = UnitPowerMax(unit, 0)
                    }
                elseif healers[unit] then
                    healers[unit] = nil
                end
            end

            rendered = nil
        end

        function UpdateMana(unit, curmana, maxmana)
            if unit and healers[unit] then
                healers[unit].curmana = curmana
                healers[unit].maxmana = maxmana
            end
        end

        function UpdateDisplay()
            if not display then
                return
            end

            if DB.Mana.enabled then
                ShowDisplay()
            else
                HideDisplay()
            end

            if DB.Mana.locked then
                LockDisplay()
            else
                UnlockDisplay()
            end

            core:RestorePosition(display, DB.Mana)

            display:SetWidth(DB.Mana.width or 180)
            display:SetScale(DB.Mana.scale or 1)

            display.header:SetFont(LSM:Fetch("font", DB.Mana.font), DB.Mana.fontSize, DB.Mana.fontFlags)
            display.header:SetJustifyH(DB.Mana.align or "LEFT")
            if DB.Mana.hideTitle and display.locked then
                display.header:Hide()
            else
                display.header:Show()
            end

            if testMode then
                healers = testHealers
            else
                CacheHealers()
            end

            for unit, data in pairs(healers) do
                local f = _G["KPackHealersMana" .. data.name]
                if f then
                    f.icon:SetSize(DB.Mana.iconSize, DB.Mana.iconSize)
                    f.name:SetFont(LSM:Fetch("font", DB.Mana.font), DB.Mana.fontSize, DB.Mana.fontFlags)
                    f.mana:SetFont(LSM:Fetch("font", DB.Mana.font), DB.Mana.fontSize, DB.Mana.fontFlags)

                    if f.align ~= DB.Mana.align then
                        f.align = DB.Mana.align
                        f.icon:ClearAllPoints()
                        f.name:ClearAllPoints()
                        f.mana:ClearAllPoints()
                        if f.align == "RIGHT" then
                            f.icon:SetPoint("RIGHT", f, "RIGHT", 0, 0)
                            f.name:SetPoint("RIGHT", f.icon, "LEFT", -3, 0)
                            f.name:SetJustifyH("RIGHT")
                            f.mana:SetPoint("LEFT", f, "LEFT", 0, 0)
                            f.mana:SetPoint("RIGHT", f.name, "LEFT", -1, 0)
                            f.mana:SetJustifyH("LEFT")
                        else
                            f.icon:SetPoint("LEFT", f, "LEFT", 0, 0)
                            f.name:SetPoint("LEFT", f.icon, "RIGHT", 3, 0)
                            f.name:SetJustifyH("LEFT")
                            f.mana:SetPoint("LEFT", f.name, "RIGHT", 1, 0)
                            f.mana:SetPoint("RIGHT", f, "RIGHT", 0, 0)
                            f.mana:SetJustifyH("RIGHT")
                        end
                    end
                end
            end

            rendered = nil
        end

        do
            local function StartMoving(self)
                self.moving = true
                self:StartMoving()
            end

            local function StopMoving(self)
                if self.moving then
                    self:StopMovingOrSizing()
                    self.moving = nil
                    core:SavePosition(self, DB.Mana)
                end
            end

            local function OnMouseDown(self, button)
                if button == "RightButton" then
                    core:OpenConfig("RaidUtility")
                end
            end

            function CreateDisplay()
                if display then
                    return
                end
                display = CreateFrame("Frame", "KPackHealersMana", UIParent)
                display:SetSize(DB.Mana.width or 180, DB.Mana.iconSize or 24)
                display:SetClampedToScreen(true)
                display:SetScale(DB.Mana.scale or 1)
                core:RestorePosition(display, DB.Mana)

                local t = display:CreateTexture(nil, "BACKGROUND")
                t:SetPoint("TOPLEFT", -2, 2)
                t:SetPoint("BOTTOMRIGHT", 2, -2)
                t:SetTexture(0, 0, 0, 0.5)
                display.bg = t

                t = display:CreateFontString(nil, "OVERLAY")
                t:SetFont(LSM:Fetch("font", DB.Mana.font), DB.Mana.fontSize, DB.Mana.fontFlags)
                t:SetText(L["Healers Mana"])
                t:SetJustifyH(DB.Mana.align or "LEFT")
                t:SetPoint("BOTTOMLEFT", display, "TOPLEFT", 0, 5)
                t:SetPoint("BOTTOMRIGHT", display, "TOPRIGHT", 0, 5)
                display.header = t
            end

            function LockDisplay()
                if not display then
                    CreateDisplay()
                end
                display:EnableMouse(false)
                display:SetMovable(false)
                display:RegisterForDrag(nil)
                display:SetScript("OnDragStart", nil)
                display:SetScript("OnDragStop", nil)
                display:SetScript("OnMouseDown", nil)
                display.bg:SetTexture(0, 0, 0, 0)
                if DB.Mana.hideTitle then
                    display.header:Hide()
                end
                display.locked = true
            end

            function UnlockDisplay()
                if not display then
                    CreateDisplay()
                end
                display:EnableMouse(true)
                display:SetMovable(true)
                display:RegisterForDrag("LeftButton")
                display:SetScript("OnDragStart", StartMoving)
                display:SetScript("OnDragStop", StopMoving)
                display:SetScript("OnMouseDown", OnMouseDown)
                display.bg:SetTexture(0, 0, 0, 0.5)
                if DB.Sunders.hideTitle then
                    display.header:Show()
                end
                display.locked = nil
            end
        end

        do
            local function OnUpdate(self, elapsed)
                self.lastUpdate = (self.lastUpdate or 0) + elapsed
                if self.lastUpdate > (DB.Sunders.updateInterval or 0.25) then
                    if not rendered then
                        RenderDisplay()
                    end
                    for _, data in pairs(healers) do
                        local f = _G["KPackHealersMana" .. data.name]
                        if f then
                            f.mana:SetText(strformat("%02.f%%", 100 * data.curmana / data.maxmana))
                        end
                    end
                    self.lastUpdate = 0
                end
            end

            local cacheEvents = {
                ACTIVE_TALENT_GROUP_CHANGED = true,
                PARTY_MEMBERS_CHANGED = true,
                RAID_ROSTER_UPDATE = true,
                PLAYER_REGEN_DISABLED = true
            }

            local function OnEvent(self, event, ...)
                if not self or self ~= display then
                    return
                end
                if cacheEvents[event] then
                    CacheHealers()
                elseif arg1 and CheckUnit(arg1) and healers[arg1] then
                    if event == "UNIT_MANA" then
                        UpdateMana(arg1, UnitPower(arg1, 0), UnitPowerMax(arg1, 0))
                    elseif event == "UNIT_AURA" then
                        local f = _G["KPackHealersMana" .. UnitName(arg1)]
                        if not f then
                            return
                        end

                        local _, _, icon, _, _, duration, _, _, _, _, _ = UnitBuff(arg1, TUTORIAL_TITLE12)
                        if icon then
                            f._icon = f._icon or f.icon:GetTexture()
                            f.icon:SetTexture(icon)
                            if not f.drinking then
                                f.drinking = true
                                CooldownFrame_SetTimer(f.cooldown, GetTime(), duration, 1)
                            end
                        else
                            if f._icon then
                                f.icon:SetTexture(f._icon)
                                f._icon = nil
                            end
                            if f.drinking then
                                f.drinking = nil
                                f.cooldown:Hide()
                            end
                        end
                    end
                end
            end

            function ShowDisplay()
                if not display then
                    CreateDisplay()
                end
                display:Show()
                display:SetScript("OnUpdate", OnUpdate)
                display:SetScript("OnEvent", OnEvent)
                display:RegisterEvent("PARTY_MEMBERS_CHANGED")
                display:RegisterEvent("RAID_ROSTER_UPDATE")
                display:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
                display:RegisterEvent("UNIT_MANA")
                display:RegisterEvent("UNIT_AURA")
            end

            function HideDisplay()
                if display then
                    display:Hide()
                    display:SetScript("OnUpdate", nil)
                    display:SetScript("OnEvent", nil)
                    display:UnregisterAllEvents()
                end
            end
        end

        function RenderDisplay()
            ResetFrames()
            if rendered then
                return
            end
            local size = DB.Mana.iconSize or 24
            local height = size
            local i = 1
            for unit, data in pairs(healers) do
                local fname = "KPackHealersMana" .. data.name
                local f = _G[fname]
                if not f then
                    f = CreateFrame("Frame", fname, display)

                    local t = f:CreateTexture(nil, "BACKGROUND")
                    t:SetSize(size, size)
                    t:SetTexCoord(0.1, 0.9, 0.1, 0.9)
                    f.icon = t

                    t = CreateFrame("Cooldown", nil, display, "CooldownFrameTemplate")
                    t:SetAllPoints(f.icon)
                    f.cooldown = t

                    t = f:CreateFontString(nil, "ARTWORK")
                    t:SetFont(LSM:Fetch("font", DB.Mana.font), DB.Mana.fontSize, DB.Mana.fontFlags)
                    t:SetJustifyV("MIDDLE")
                    t:SetText(data.name)
                    t:SetTextColor(unpack(colorsTable[data.class]))
                    f.name = t

                    t = f:CreateFontString(nil, "ARTWORK")
                    t:SetFont(LSM:Fetch("font", DB.Mana.font), DB.Mana.fontSize, DB.Mana.fontFlags)
                    t:SetJustifyV("MIDDLE")
                    f.mana = t
                end

                f:SetHeight(size)
                f:SetPoint("TOPLEFT", display, "TOPLEFT", 0, -((size + (DB.Mana.spacing or 0)) * (i - 1)))
                f:SetPoint("RIGHT", display, "RIGHT", 0, 0)
                f.icon:SetTexture(data.icon)
                f.mana:SetText(strformat("%02.f%%", 100 * data.curmana / data.maxmana))
                f:Show()

                f.align = DB.Mana.align
                if f.align == "RIGHT" then
                    f.icon:SetPoint("RIGHT", f, "RIGHT", 0, 0)
                    f.name:SetPoint("RIGHT", f.icon, "LEFT", -3, 0)
                    f.name:SetJustifyH("RIGHT")
                    f.mana:SetPoint("LEFT", f, "LEFT", 0, 0)
                    f.mana:SetPoint("RIGHT", f.name, "LEFT", -1, 0)
                    f.mana:SetJustifyH("LEFT")
                else
                    f.icon:SetPoint("LEFT", f, "LEFT", 0, 0)
                    f.name:SetPoint("LEFT", f.icon, "RIGHT", 3, 0)
                    f.name:SetJustifyH("LEFT")
                    f.mana:SetPoint("LEFT", f.name, "RIGHT", 1, 0)
                    f.mana:SetPoint("RIGHT", f, "RIGHT", 0, 0)
                    f.mana:SetJustifyH("RIGHT")
                end
                if i > 1 then
                    height = height + size + (DB.Mana.spacing or 0)
                end
                i = i + 1
                healerFrames[fname] = true
            end

            display:SetHeight(height)
            rendered = true
        end

        options.args.Mana = {
            type = "group",
            name = L["Healers Mana"],
            order = order,
            get = function(i)
                return DB.Mana[i[#i]]
            end,
            set = function(i, val)
                DB.Mana[i[#i]] = val
                UpdateDisplay()
            end,
            args = {
                enabled = {
                    type = "toggle",
                    name = L["Enable"],
                    order = 1
                },
                testMode = {
                    type = "toggle",
                    name = L["Configuration Mode"],
                    desc = L["Toggle configuration mode to allow moving frames and setting appearance options."],
                    order = 2,
                    get = function()
                        return testMode
                    end,
                    set = function(_, val)
                        testMode = val
                        if testMode then
                            display:UnregisterAllEvents()
                        else
                            display:RegisterEvent("PARTY_MEMBERS_CHANGED")
                            display:RegisterEvent("RAID_ROSTER_UPDATE")
                            display:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
                            display:RegisterEvent("UNIT_MANA")
                            display:RegisterEvent("UNIT_AURA")
                        end
                        ResetFrames()
                        UpdateDisplay()
                    end
                },
                locked = {
                    type = "toggle",
                    name = L["Lock"],
                    order = 3,
                    disabled = function()
                        return not DB.Mana.enabled
                    end
                },
                updateInterval = {
                    type = "range",
                    name = L["Update Frequency"],
                    order = 4,
                    disabled = function()
                        return not DB.Mana.enabled
                    end,
                    min = 0.1,
                    max = 1,
                    step = 0.05,
                    bigStep = 0.1
                },
                appearance = {
                    type = "group",
                    name = L["Appearance"],
                    order = 5,
                    inline = true,
                    disabled = function()
                        return not DB.Mana.enabled
                    end,
                    args = {
                        font = {
                            type = "select",
                            name = L["Font"],
                            order = 1,
                            dialogControl = "LSM30_Font",
                            values = AceGUIWidgetLSMlists.font
                        },
                        fontFlags = {
                            type = "select",
                            name = L["Font Outline"],
                            order = 2,
                            values = {
                                [""] = NONE,
                                ["OUTLINE"] = L["Outline"],
                                ["THINOUTLINE"] = L["Thin outline"],
                                ["THICKOUTLINE"] = L["Thick outline"],
                                ["MONOCHROME"] = L["Monochrome"],
                                ["OUTLINEMONOCHROME"] = L["Outlined monochrome"]
                            }
                        },
                        fontSize = {
                            type = "range",
                            name = L["Font Size"],
                            order = 3,
                            min = 8,
                            max = 30,
                            step = 1
                        },
                        align = {
                            type = "select",
                            name = L["Text Alignment"],
                            order = 4,
                            values = {LEFT = L["Left"], RIGHT = L["Right"]}
                        },
                        iconSize = {
                            type = "range",
                            name = L["Icon Size"],
                            order = 5,
                            min = 8,
                            max = 30,
                            step = 1
                        },
                        width = {
                            type = "range",
                            name = L["Width"],
                            order = 6,
                            min = 120,
                            max = 240,
                            step = 1
                        },
                        spacing = {
                            type = "range",
                            name = L["Spacing"],
                            order = 7,
                            min = 0,
                            max = 30,
                            step = 1
                        },
                        scale = {
                            type = "range",
                            name = L["Scale"],
                            order = 8,
                            min = 0.5,
                            max = 3,
                            step = 0.01,
                            bigStep = 0.1
                        },
                        hideTitle = {
                            type = "toggle",
                            name = L["Hide Title"],
                            desc = L["Enable this if you want to hide the title text when locked."],
                            order = 9
                        }
                    }
                },
                reset = {
                    type = "execute",
                    name = RESET,
                    order = 99,
                    width = "full",
                    confirm = function()
                        return L:F("Are you sure you want to reset %s to default?", L["Healers Mana"])
                    end,
                    func = function()
                        DB.Mana = defaults.Mana
                        UpdateDisplay()
                    end
                }
            }
        }
        order = order + 1
        core:RegisterForEvent("PLAYER_ENTERING_WORLD", function()
            SetupDatabase()
            if not LGT then
                return
            end
            core.After(5, CacheHealers)

            if DB.Mana.enabled then
                ShowDisplay()
            else
                HideDisplay()
            end

            if DB.Mana.locked then
                LockDisplay()
            else
                UnlockDisplay()
            end
        end)
    end

    ---------------------------------------------------------------------------
    -- Go Go!

    function SetupDatabase()
        if not DB then
            if type(core.db.RaidUtility) ~= "table" or not next(core.db.RaidUtility) then
                core.db.RaidUtility = CopyTable(defaults)
            end
            DB = core.db.RaidUtility

            -- database check to fix in case of updates.
            for k, v in pairs(defaults) do
                if DB[k] == nil then
                    DB[k] = CopyTable(v)
                end
            end
            -- delete old entries
            for k, v in pairs(DB) do
                if defaults[k] == nil then
                    DB[k] = nil
                end
            end
        end
    end

    core:RegisterForEvent("PLAYER_LOGIN", function()
        SetupDatabase()
        CreateRaidUtilityPanel()
        core.options.args.RaidUtility = options
    end)
end)