local addonName, addon = ...
local L = addon.L

AutomateDB = {}
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

local mod = CreateFrame("Frame")
mod:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
mod:RegisterEvent("ADDON_LOADED")

-- module's print function
local function Print(msg)
    if msg then
        addon:Print(msg, "AutoMate")
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
        if AutomateDB.uiscale then
            local scalefix = CreateFrame("Frame")
            scalefix:RegisterEvent("PLAYER_LOGIN")
            scalefix:SetScript(
                "OnEvent",
                function()
                    SetCVar("useUiScale", 1)
                    SetCVar(
                        "uiScale",
                        768 / string.match(({GetScreenResolutions()})[GetCurrentResolution()], "%d+x(%d+)")
                    )
                end
            )
        end

        -- Max camera distance, screenshots quality.
        SetCVar("cameraDistanceMax", 50)
        SetCVar("cameraDistanceMaxFactor", 3.4)
        SetCVar("screenshotQuality", SCREENSHOT_QUALITY)
        SaveView(5)
    end

    function mod:PLAYER_ENTERING_WORLD()
        mod:UnregisterEvent("PLAYER_ENTERING_WORLD")

        if AutomateDB.enabled then
            self:RegisterEvent("DUEL_REQUESTED")
            self:RegisterEvent("GOSSIP_SHOW")
            self:RegisterEvent("QUEST_GREETING")
            self:RegisterEvent("PLAYER_REGEN_DISABLED")
            self:RegisterEvent("PLAYER_REGEN_ENABLED")
            self:RegisterEvent("MERCHANT_SHOW")
            self:RegisterEvent("ACHIEVEMENT_EARNED")

            hooksecurefunc("ShowReadyCheck", Automate_ReadyCheck)
            Automate_UIScale()
            self:AdjustCamera()
        else
            self:UnregisterEvent("DUEL_REQUESTED")
            self:UnregisterEvent("GOSSIP_SHOW")
            self:UnregisterEvent("QUEST_GREETING")
            self:UnregisterEvent("PLAYER_REGEN_DISABLED")
            self:UnregisterEvent("PLAYER_REGEN_ENABLED")
            self:UnregisterEvent("MERCHANT_SHOW")
            self:UnregisterEvent("ACHIEVEMENT_EARNED")
        end
    end
end

-- ///////////////////////////////////////////////////////
-- Ignore Duels
-- ///////////////////////////////////////////////////////

function mod:DUEL_REQUESTED()
    if AutomateDB.duels then
        CancelDuel()
        StaticPopup_Hide("DUEL_REQUESTED")
    end
end

-- ///////////////////////////////////////////////////////
-- Skip Gossip
-- ///////////////////////////////////////////////////////

function mod:GOSSIP_SHOW()
    if not AutomateDB.gossip then
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
mod.QUEST_GREETING = mod.GOSSIP_SHOW

-- ///////////////////////////////////////////////////////
-- Auto Nameplates
-- ///////////////////////////////////////////////////////

function mod:PLAYER_REGEN_ENABLED()
    if AutomateDB.nameplate then
        SetCVar("nameplateShowEnemies", 0)
        _G.NAMEPLATES_ON = false
    end
	if AutomateDB.camera then
		self:AdjustCamera()
	end
end

function mod:PLAYER_REGEN_DISABLED()
    if AutomateDB.nameplate then
        SetCVar("nameplateShowEnemies", 1)
        _G.NAMEPLATES_ON = true
    end
end

-- ///////////////////////////////////////////////////////
-- Auto Repair, Auto Sell Junk and Stack Buying
-- ///////////////////////////////////////////////////////

do
    -- handles auto selling junk
    local function Automate_SellJunk()
        if AutomateDB.junk then
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
        if AutomateDB.repair and CanMerchantRepair() == 1 then
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
                        PrintSys(
                            L:F(
                                "Repair cost covered by Guild Bank: %dg %ds %dc.",
                                tostring(vGold),
                                tostring(vSilver),
                                tostring(vCopper)
                            )
                        )
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
                    PrintSys(
                        L:F(
                            "Your items have been repaired for %dg %ds %dc.",
                            tostring(vGold),
                            tostring(vSilver),
                            tostring(vCopper)
                        )
                    )
                else
                    PrintSys(L["You don't have enough money to repair items!"])
                end
            end
        end
    end

    function mod:MERCHANT_SHOW()
        Automate_Repair()
        Automate_SellJunk()
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
	if AutomateDB.camera and not InCombatLockdown() then
		SetCVar("cameraDistanceMaxFactor", "2.6")
		MoveViewOutStart(50000)
	end
end

-- ///////////////////////////////////////////////////////
-- Automatic Screenshot
-- ///////////////////////////////////////////////////////

function mod:ACHIEVEMENT_EARNED()
    if AutomateDB.screenshot then
        addon.Timer.After(1, function() Screenshot() end)
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
            AutomateDB.enabled = not AutomateDB.enabled
            msg = "module status: %s"
            status = (AutomateDB.enabled == true)
        elseif cmd == "duel" or cmd == "duels" then
            AutomateDB.duels = not AutomateDB.duels
            msg = "ignore duels: %s"
            status = (AutomateDB.duels == true)
        elseif cmd == "gossip" then
            AutomateDB.gossip = not AutomateDB.gossip
            msg = "skip gossip: %s"
            status = (AutomateDB.gossip == true)
        elseif cmd == "grey" or cmd == "junk" then
            AutomateDB.junk = not AutomateDB.junk
            msg = "sell junk: %s"
            status = (AutomateDB.junk == true)
        elseif cmd == "repair" then
            AutomateDB.repair = not AutomateDB.repair
            msg = "auto repair: %s"
            status = (AutomateDB.repair == true)
        elseif cmd == "nameplate" or cmd == "nameplates" then
            AutomateDB.nameplate = not AutomateDB.nameplate
            msg = "auto nameplates: %s"
            status = (AutomateDB.nameplate == true)
            if status then
                mod:PLAYER_REGEN_ENABLED()
            else
                mod:PLAYER_REGEN_DISABLED()
            end
        elseif cmd == "ui" or cmd == "uiscale" then
            AutomateDB.uiscale = not AutomateDB.uiscale
            msg = "auto ui scale: %s"
            status = (AutomateDB.uiscale == true)
        elseif cmd == "camera" then
            AutomateDB.camera = not AutomateDB.camera
            msg = "auto max camera: %s"
            status = (AutomateDB.camera == true)
        elseif cmd == "ss" or cmd == "screenshot" then
            AutomateDB.screenshot = not AutomateDB.screenshot
            msg = "auto screenshot on achievement: %s"
            status = (AutomateDB.screenshot == true)
        end

        if msg then
            Print(L:F(msg, status and L["|cff00ff00ON|r"] or L["|cffff0000OFF|r"]))
            mod:PLAYER_ENTERING_WORLD()
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

    function mod:ADDON_LOADED(name)
		if name ~= addonName then return end
		self:UnregisterEvent("ADDON_LOADED")

		if next(AutomateDB) == nil then
			AutomateDB = defaults
		end

		SlashCmdList["KPACKAUTOMATE"] = SlashCommandHandler
		_G.SLASH_KPACKAUTOMATE1 = "automate"
		_G.SLASH_KPACKAUTOMATE2 = "/auto"

		self:RegisterEvent("PLAYER_ENTERING_WORLD")
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