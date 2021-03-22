assert(KPack, "KPack not found!")
KPack:AddModule("AutoMate", "Automates some of the more tedious tasks in WoW.", function(folder, core, L)
    if core:IsDisabled("AutoMate") then return end

    local mod = core.AutoMate or {}
    core.AutoMate = mod

    local DB
    local defaults = {
        enabled = true,
        duels = false,
        gossip = false,
        junk = true,
        nameplate = false,
        repair = true,
        uiscale = false,
        camera = true,
        screenshot = false
    }

    local PLAYER_ENTERING_WORLD
    local PLAYER_REGEN_ENABLED
    local PLAYER_REGEN_DISABLED

    local chatFrame = DEFAULT_CHAT_FRAME

    -- module's print function
    local function Print(msg)
        if msg then
            core:Print(msg, "AutoMate")
        end
    end

    -- mimics system messages
    local function PrintSys(msg)
        if msg then
            chatFrame:AddMessage(msg, 255, 255, 0)
        end
    end

	local function SetupDatabase()
		if DB then return end

		if type(KPackDB.Automate) ~= "table" or not next(KPackDB.Automate) then
			KPackDB.Automate = CopyTable(defaults)
		end

		DB = KPackDB.Automate
	end

    do
        -- automatic ui scale
        local function Automate_UIScale()
            if DB.uiscale then
                local scalefix = CreateFrame("Frame")
                scalefix:RegisterEvent("PLAYER_LOGIN")
                scalefix:SetScript("OnEvent", function()
                    SetCVar("useUiScale", 1)
                    SetCVar("uiScale", 768 / string.match(({GetScreenResolutions()})[GetCurrentResolution()], "%d+x(%d+)"))
                end)
            end

            -- Max camera distance, screenshots quality.
            SetCVar("cameraDistanceMax", 50)
            SetCVar("cameraDistanceMaxFactor", 3.4)
            SetCVar("screenshotQuality", SCREENSHOT_QUALITY)
            SaveView(5)
        end

        function PLAYER_ENTERING_WORLD()
            if not DB then SetupDatabase() end
            if DB.enabled then
                Automate_UIScale()
                mod:AdjustCamera()
            end
        end

        core:RegisterCallback("PLAYER_ENTERING_WORLD", PLAYER_ENTERING_WORLD)
    end

    -- ///////////////////////////////////////////////////////
    -- Ignore Duels
    -- ///////////////////////////////////////////////////////

    core:RegisterCallback("DUEL_REQUESTED", function()
        if DB.enabled and DB.duels then
            CancelDuel()
            StaticPopup_Hide("DUEL_REQUESTED")
        end
    end)

    -- ///////////////////////////////////////////////////////
    -- Skip Gossip
    -- ///////////////////////////////////////////////////////

    do
        local function Automate_SkipGossip()
            if not DB.enabled or not DB.gossip then
                return
            end
            if (GetNumGossipActiveQuests() + GetNumGossipAvailableQuests()) == 0 and GetNumGossipOptions() == 1 then
                SelectGossipOption(1)
            end
            for i = 1, GetNumGossipActiveQuests() do
                if select(i * 4, GetGossipActiveQuests(i)) == 1 then
                    SelectGossipActiveQuest(i)
                end
            end
        end
        core:RegisterCallback("GOSSIP_SHOW", Automate_SkipGossip)
        core:RegisterCallback("QUEST_GREETING", Automate_SkipGossip)
    end

    -- ///////////////////////////////////////////////////////
    -- Auto Nameplates
    -- ///////////////////////////////////////////////////////

    function PLAYER_REGEN_ENABLED()
        if DB.enabled then
            if DB.nameplate then
                SetCVar("nameplateShowEnemies", 0)
                _G.NAMEPLATES_ON = false
            end
            if DB.camera then
                mod:AdjustCamera()
            end
        end
    end
    core:RegisterCallback("PLAYER_REGEN_ENABLED", PLAYER_REGEN_ENABLED)

    function PLAYER_REGEN_DISABLED()
        if DB.enabled and DB.nameplate then
            SetCVar("nameplateShowEnemies", 1)
            _G.NAMEPLATES_ON = true
        end
    end
    core:RegisterCallback("PLAYER_REGEN_DISABLED", PLAYER_REGEN_DISABLED)

    -- ///////////////////////////////////////////////////////
    -- Auto Repair, Auto Sell Junk and Stack Buying
    -- ///////////////////////////////////////////////////////

    do
        -- handles auto selling junk
        local function Automate_SellJunk()
            if DB.junk then
                local i = 0

                for bag = 0, 4 do
                    for slot = 0, GetContainerNumSlots(bag) do
                        local link = GetContainerItemLink(bag, slot)
                        if link and select(3, GetItemInfo(link)) == 0 then
                            ShowMerchantSellCursor(1)
                            UseContainerItem(bag, slot)
                            i = i + 1
                        end
                    end
                end

                if i > 0 then
                    PrintSys(L:F("You have successfully sold %d grey items.", i))
                end
            end
        end

		-- handles auto repair
		local function Automate_Repair()
		    if DB.repair and CanMerchantRepair() == 1 then
		        local cost, needed = GetRepairAllCost()
		        if needed then
		            local guildWithdraw = GetGuildBankWithdrawMoney()
		            local useGuild = CanGuildBankRepair() and (guildWithdraw > cost or guildWithdraw == -1)
		            if useGuild then
		                RepairAllItems(1)
		                local vCopper = cost % 100
		                local vSilver = floor((cost % 10000) / 100)
		                local vGold = floor(cost / 100000)
		                PrintSys(L:F("Repair cost covered by Guild Bank: %dg %ds %dc.", tostring(vGold), tostring(vSilver), tostring(vCopper)))
		            elseif cost < GetMoney() then
		                RepairAllItems()
		                local vCopper = cost % 100
		                local vSilver = floor((cost % 10000) / 100)
		                local vGold = floor(cost / 100000)
		                PrintSys(L:F("Your items have been repaired for %dg %ds %dc.", tostring(vGold), tostring(vSilver), tostring(vCopper)))
		            else
		                PrintSys(L["You don't have enough money to repair items!"])
		            end
		        end
		    end
		end


        core:RegisterCallback("MERCHANT_SHOW", function()
            if DB.enabled then
                Automate_Repair()
                Automate_SellJunk()
            end
        end)

        -- replace default action so we can buy stack
        local Old_MerchantItemButton_OnModifiedClick = _G.MerchantItemButton_OnModifiedClick
        _G.MerchantItemButton_OnModifiedClick = function(self, ...)
            if IsAltKeyDown() then
                local maxStack = select(8, GetItemInfo(GetMerchantItemLink(this:GetID())))
                local _, _, _, quantity, _, _, _ = GetMerchantItemInfo(this:GetID())
                if maxStack and maxStack > 1 then
                    BuyMerchantItem(this:GetID(), floor(maxStack / quantity))
                end
            end
            Old_MerchantItemButton_OnModifiedClick(self, ...)
        end
    end

    -- ///////////////////////////////////////////////////////
    -- Automatic Screenshot
    -- ///////////////////////////////////////////////////////

    function mod:AdjustCamera()
        if DB.camera and not InCombatLockdown() then
            SetCVar("cameraDistanceMaxFactor", "2.6")
            MoveViewOutStart(50000)
        end
    end

    -- ///////////////////////////////////////////////////////
    -- Trainer Button
    -- ///////////////////////////////////////////////////////

    do
        local button, locked
        local skillsToLearn, skillsLearned
        local process

        local function Automate_TrainReset()
            button:SetScript("OnUpdate", nil)
            locked = nil
            skillsLearned = nil
            skillsToLearn = nil
            process = nil
            button.delay = nil
        end

        local function Automate_TrainAll_OnUpdate(self, elapsed)
            self.delay = self.delay - elapsed
            if self.delay <= 0 then
                Automate_TrainReset()
            end
        end

        local function Automate_TrainAll()
            locked = true
            button:Disable()

            local j, cost = 0
            local money = GetMoney()

            for i = 1, GetNumTrainerServices() do
                if select(3, GetTrainerServiceInfo(i)) == "available" then
                    j = j + 1
                    cost = GetTrainerServiceCost(i)
                    if money >= cost then
                        money = money - cost
                        BuyTrainerService(i)
                    else
                        Automate_TrainReset()
                        return
                    end
                end
            end

            if j > 0 then
                skillsToLearn = j
                skillsLearned = 0

                process = true
                button.delay = 1
                button:SetScript("OnUpdate", Automate_TrainAll_OnUpdate)
            else
                Automate_TrainReset()
            end
        end

        core:RegisterCallback("TRAINER_UPDATE", function()
            if not DB.enabled or not process then return end

            skillsLearned = skillsLearned + 1

            if skillsLearned >= skillsToLearn then
                Automate_TrainReset()
                Automate_TrainAll()
            else
                button.delay = 1
            end
        end)

        function mod:TrainButtonCreate()
            if button then return end
            button = CreateFrame("Button", "KPackTrainAllButton", ClassTrainerFrame, "KPackButtonTemplate")
            button:SetSize(80, 18)
            button:SetFormattedText("%s %s", TRAIN, ALL)
            button:SetPoint("RIGHT", ClassTrainerFrameCloseButton, "LEFT", 1, 0)
            button:SetScript("OnClick", function() Automate_TrainAll() end)
        end

        function mod:TrainButtonUpdate()
            if locked then
                return
            end

            for i = 1, GetNumTrainerServices() do
                if select(3, GetTrainerServiceInfo(i)) == "available" then
                    button:Enable()
                    return
                end
            end

            button:Disable()
        end
    end

    -- ///////////////////////////////////////////////////////
    -- Automatic Screenshot
    -- ///////////////////////////////////////////////////////

    core:RegisterCallback("ACHIEVEMENT_EARNED", function()
        if DB.enabled and DB.screenshot then
            core.After(1, function() Screenshot() end)
        end
    end)

    -- ///////////////////////////////////////////////////////

    do
        local commands = {
            toggle = L["toggle module status"],
            duels = L["ignore all duels"],
            gossip = L["skip quests gossip"],
            junk = L["automatically sell junks"],
            nameplate = L["show nameplates only in combat"],
            repair = L["equiment repair using guild gold or own gold"],
            uiscale = L["automatic ui scale"],
            camera = L["automatic max camera zoom out"],
            screenshot = L["automatic screenshot on achievement"]
        }

        local more = {
            L["|cffffd700Alt-Click|r to buy a stack of item from merchant."],
            L["You can keybind raid icons on MouseOver. Check keybindings."]
        }

        local function SlashCommandHandler(cmd)
            if not cmd then
                return
            end
            cmd = cmd:lower()

            local msg, status

            if cmd == "toggle" then
                DB.enabled = not DB.enabled
                msg = "module status: %s"
                status = (DB.enabled == true)
            elseif cmd == "duel" or cmd == "duels" then
                DB.duels = not DB.duels
                msg = "ignore duels: %s"
                status = (DB.duels == true)
            elseif cmd == "gossip" then
                DB.gossip = not DB.gossip
                msg = "skip gossip: %s"
                status = (DB.gossip == true)
            elseif cmd == "grey" or cmd == "junk" then
                DB.junk = not DB.junk
                msg = "sell junk: %s"
                status = (DB.junk == true)
            elseif cmd == "repair" then
                DB.repair = not DB.repair
                msg = "auto repair: %s"
                status = (DB.repair == true)
            elseif cmd == "nameplate" or cmd == "nameplates" then
                DB.nameplate = not DB.nameplate
                msg = "auto nameplates: %s"
                status = (DB.nameplate == true)
                if status then
                    PLAYER_REGEN_ENABLED()
                else
                    PLAYER_REGEN_DISABLED()
                end
            elseif cmd == "ui" or cmd == "uiscale" then
                DB.uiscale = not DB.uiscale
                msg = "auto ui scale: %s"
                status = (DB.uiscale == true)
            elseif cmd == "camera" then
                DB.camera = not DB.camera
                msg = "auto max camera: %s"
                status = (DB.camera == true)
            elseif cmd == "ss" or cmd == "screenshot" then
                DB.screenshot = not DB.screenshot
                msg = "auto screenshot on achievement: %s"
                status = (DB.screenshot == true)
            end

            if msg then
                Print(L:F(msg, status and L["|cff00ff00ON|r"] or L["|cffff0000OFF|r"]))
                PLAYER_ENTERING_WORLD()
                return
            end

            Print(L:F("Acceptable commands for: |caaf49141%s|r", "/auto"))
            for k, v in pairs(commands) do
                print("|cffffd700" .. k .. "|r", v)
            end

            print(L:F("More from |caaf49141%s|r:", "AutoMate"))
            for _, m in ipairs(more) do
                print("-", m)
            end
        end

        SlashCmdList["KPACKAUTOMATE"] = SlashCommandHandler
        SLASH_KPACKAUTOMATE1 = "automate"
        SLASH_KPACKAUTOMATE2 = "/auto"

        core:RegisterCallback("ADDON_LOADED", function(_, name)
            if name == folder then
				SetupDatabase()

            elseif name == "Blizzard_TrainerUI" then
				SetupDatabase()
				if DB.enabled then
					mod:TrainButtonCreate()
					hooksecurefunc("ClassTrainerFrame_Update", mod.TrainButtonUpdate)
				end
            end
        end)
    end

end)
BINDING_HEADER_KPACKAUTOMATE = "|cfff58cbaK|r|caaf49141Pack|r AutoMate"
BINDING_NAME_KPACKAUTOMATE_1 = "MouseOver: " .. RAID_TARGET_1
BINDING_NAME_KPACKAUTOMATE_2 = "MouseOver: " .. RAID_TARGET_2
BINDING_NAME_KPACKAUTOMATE_3 = "MouseOver: " .. RAID_TARGET_3
BINDING_NAME_KPACKAUTOMATE_4 = "MouseOver: " .. RAID_TARGET_4
BINDING_NAME_KPACKAUTOMATE_5 = "MouseOver: " .. RAID_TARGET_5
BINDING_NAME_KPACKAUTOMATE_6 = "MouseOver: " .. RAID_TARGET_6
BINDING_NAME_KPACKAUTOMATE_7 = "MouseOver: " .. RAID_TARGET_7
BINDING_NAME_KPACKAUTOMATE_8 = "MouseOver: " .. RAID_TARGET_8
BINDING_NAME_KPACKAUTOMATE_0 = KPack.L["Remove Icon"]