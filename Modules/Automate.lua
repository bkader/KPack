local folder, core = ...

local mod = core.AutoMate or {}
core.AutoMate = mod

local E = core:Events()
local L = core.L

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

do
    -- Proper ready check sound.
    local function Automate_ReadyCheck(self, initiator, timeLeft)
        if initiator ~= "player" then
            PlaySound("ReadyCheck")
        end
    end

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

    function E:PLAYER_ENTERING_WORLD()
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        if DB.enabled then
            hooksecurefunc("ShowReadyCheck", Automate_ReadyCheck)
            Automate_UIScale()
            mod:AdjustCamera()
        end
    end
end

-- ///////////////////////////////////////////////////////
-- Ignore Duels
-- ///////////////////////////////////////////////////////

function E:DUEL_REQUESTED()
    if DB.duels then
        CancelDuel()
        StaticPopup_Hide("DUEL_REQUESTED")
    else
        self:UnregisterEvent("DUEL_REQUESTED")
    end
end

-- ///////////////////////////////////////////////////////
-- Skip Gossip
-- ///////////////////////////////////////////////////////

function E:GOSSIP_SHOW()
    if not DB.gossip then
        self:UnregisterEvent("GOSSIP_SHOW")
        self:UnregisterEvent("QUEST_GREETING")
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
E.QUEST_GREETING = E.GOSSIP_SHOW

-- ///////////////////////////////////////////////////////
-- Auto Nameplates
-- ///////////////////////////////////////////////////////

function E:PLAYER_REGEN_ENABLED()
    if DB.enabled then
	    if DB.nameplate then
	        SetCVar("nameplateShowEnemies", 0)
	        _G.NAMEPLATES_ON = false
	    end
	    if DB.camera then
	        mod:AdjustCamera()
	    end
    else
    	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    end
end

function E:PLAYER_REGEN_DISABLED()
    if DB.nameplate then
        SetCVar("nameplateShowEnemies", 1)
        _G.NAMEPLATES_ON = true
    else
    	self:UnregisterEvent("PLAYER_REGEN_DISABLED")
    end
end

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
            local repairAllCost, canRepair = GetRepairAllCost()
            if repairAllCost > 0 and canRepair == 1 then
                -- use guild gold
                if IsInGuild() then
                    local guildMoney = GetGuildBankWithdrawMoney()
                    if guildMoney > GetGuildBankMoney() then
                        guildMoney = GetGuildBankMoney()
                    end
                    if guildMoney > repairAllCost and CanGuildBankRepair() then
                        RepairAllItems(1)
                        local vCopper = repairAllCost % 100
                        local vSilver = floor((repairAllCost % 10000) / 100)
                        local vGold = floor(repairAllCost / 100000)
                        PrintSys(L:F("Repair cost covered by Guild Bank: %dg %ds %dc.", tostring(vGold), tostring(vSilver), tostring(vCopper)))
                        return
                    end
                end

                -- use own gold
                local money = GetMoney()
                if money > repairAllCost then
                    RepairAllItems()
                    local vCopper = repairAllCost % 100
                    local vSilver = floor((repairAllCost % 10000) / 100)
                    local vGold = floor(repairAllCost / 100000)
                    PrintSys(L:F("Your items have been repaired for %dg %ds %dc.", tostring(vGold), tostring(vSilver), tostring(vCopper)))
                else
                    PrintSys(L["You don't have enough money to repair items!"])
                end
            end
        end
    end

    function E:MERCHANT_SHOW()
        if DB.enabled then
	        Automate_Repair()
	        Automate_SellJunk()
        else
        	self:UnregisterEvent("MERCHANT_SHOW")
        end
    end

    -- replace default action so we can buy stack
    local Old_MerchantItemButton_OnModifiedClick = _G.MerchantItemButton_OnModifiedClick
    _G.MerchantItemButton_OnModifiedClick = function(self, ...)
        if IsAltKeyDown() then
            local maxStack = select(8, GetItemInfo(GetMerchantItemLink(this:GetID())))
            local name, texture, price, quantity, numAvailable, isUsable, extendedCost =
                GetMerchantItemInfo(this:GetID())
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

    function E:TRAINER_UPDATE()
        if not process then return end

        skillsLearned = skillsLearned + 1

        if skillsLearned >= skillsToLearn then
            Automate_TrainReset()
            Automate_TrainAll()
        else
            button.delay = 1
        end
    end

    function mod:TrainButtonCreate()
        if button then return end
        button = CreateFrame("Button", "KPackTrainAllButton", ClassTrainerFrame, "KPackButtonTemplate")
        button:SetSize(80, 18)
        button:SetFormattedText("%s %s", TRAIN, ALL)
        button:SetPoint("RIGHT", ClassTrainerFrameCloseButton, "LEFT", 1, 0)
        button:SetScript("OnClick", function() Automate_TrainAll() end)
    end

    function mod:TrainButtonUpdate()
        if locked then return end

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

function E:ACHIEVEMENT_EARNED()
	if DB.enabled and DB.screenshot then
		core.After(1, function() Screenshot() end)
	else
		self:UnregisterEvent("ACHIEVEMENT_EARNED")
	end
end

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
                E:PLAYER_REGEN_ENABLED()
            else
                E:PLAYER_REGEN_DISABLED()
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
            E:PLAYER_ENTERING_WORLD()
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

    function E:ADDON_LOADED(name)
        if name == folder then

			if type(KPackDB.Automate) ~= "table" or not next(KPackDB.Automate) then
				KPackDB.Automate = CopyTable(defaults)
			end
			DB = KPackDB.Automate

	        SlashCmdList["KPACKAUTOMATE"] = SlashCommandHandler
	        _G.SLASH_KPACKAUTOMATE1 = "automate"
	        _G.SLASH_KPACKAUTOMATE2 = "/auto"
		elseif name == "Blizzard_TrainerUI" and DB.enabled then
			mod:TrainButtonCreate()
			hooksecurefunc("ClassTrainerFrame_Update", mod.TrainButtonUpdate)
			self:UnregisterEvent("ADDON_LOADED")
		end
	end
end

_G.BINDING_HEADER_KPACKAUTOMATE = "|cff69ccf0K|r|caaf49141Pack|r AutoMate"
_G.BINDING_NAME_KPACKAUTOMATE_1 = "MouseOver: " .. _G.RAID_TARGET_1
_G.BINDING_NAME_KPACKAUTOMATE_2 = "MouseOver: " .. _G.RAID_TARGET_2
_G.BINDING_NAME_KPACKAUTOMATE_3 = "MouseOver: " .. _G.RAID_TARGET_3
_G.BINDING_NAME_KPACKAUTOMATE_4 = "MouseOver: " .. _G.RAID_TARGET_4
_G.BINDING_NAME_KPACKAUTOMATE_5 = "MouseOver: " .. _G.RAID_TARGET_5
_G.BINDING_NAME_KPACKAUTOMATE_6 = "MouseOver: " .. _G.RAID_TARGET_6
_G.BINDING_NAME_KPACKAUTOMATE_7 = "MouseOver: " .. _G.RAID_TARGET_7
_G.BINDING_NAME_KPACKAUTOMATE_8 = "MouseOver: " .. _G.RAID_TARGET_8
_G.BINDING_NAME_KPACKAUTOMATE_0 = L["Remove Icon"]