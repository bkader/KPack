local addonName, addon = ...
local L = addon.L
local mod = addon.BlizzMove
if not mod then
    mod = {}
    addon.BlizzMove = mod
end

-- module's event frame
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")

BlizzMoveDB = {}
local defaults = {
    AchievementFrame = {save = true},
    CalendarFrame = {save = true},
    AuctionFrame = {save = true},
    GuildBankFrame = {save = true}
}
local optionPanel

-- cache frequetly used globals
local GetMouseFocus = GetMouseFocus

-- print function
local function Print(msg)
    if msg then
        addon:Print(msg, "BlizzMove")
    end
end

local SetMoveHandler
do
    do
        -- handlers the frame OnShow event
        local function OnShow(self, ...)
            local settings = BlizzMoveDB[self:GetName()]
            if settings and settings.point and settings.save and _G[settings.relativeTo] then
                self:ClearAllPoints()
                self:SetPoint(settings.point, settings.relativeTo, settings.relativePoint, settings.xOfs, settings.yOfs)
                local scale = settings.scale
                if scale then
                    self:SetScale(scale)
                end
            end
        end

        -- handles frames rescaling
        local function OnMouseWheel(self, ...)
            if IsControlKeyDown() then
                local frameToMove = self.frameToMove
                local scale = frameToMove:GetScale() or 1
                local arg1 = select(1, ...)
                if arg1 == 1 then
                    scale = scale + .1
                    if scale > 1.5 then
                        scale = 1.5
                    end
                else
                    scale = scale - .1
                    if scale < 0.5 then
                        scale = 0.5
                    end
                end

                frameToMove:SetScale(scale)
                if self.settings then
                    self.settings.scale = scale
                end
            end
        end

        -- handles frames OnDragStart event
        local function OnDragStart(self)
            local frameToMove = self.frameToMove
            local settings = frameToMove.settings
            frameToMove:StartMoving()
            frameToMove.isMoving = true
        end

        -- handles frames OnDragStop
        local function OnDragStop(self)
            local frameToMove = self.frameToMove
            local settings = frameToMove.settings
            frameToMove:StopMovingOrSizing()
            frameToMove.isMoving = false
            if not settings then
                return
            end
            settings.point, settings.relativeTo, settings.relativePoint, settings.xOfs, settings.yOfs =
                frameToMove:GetPoint()
        end

        -- handles frames OnMouseUp
        local function OnMouseUp(self, ...)
            local frameToMove = self.frameToMove
            OnDragStop(self)

            if IsControlKeyDown() then
                local settings = frameToMove.settings
                if settings then
                    settings.save = not settings.save
                    if settings.save then
                        Print(L:F("%s will be saved.", frameToMove:GetName()))
                    else
                        Print(L:F("%s will not be saved.", frameToMove:GetName()))
                    end
                else
                    Print(L:F("%s will be saved.", frameToMove:GetName()))
                    BlizzMoveDB[frameToMove:GetName()] = {}
                    settings = BlizzMoveDB[frameToMove:GetName()]
                    settings.save = true
                    settings.point, settings.relativeTo, settings.relativePoint, settings.xOfs, settings.yOfs =
                        frameToMove:GetPoint()
                    if settings.relativeTo then
                        settings.relativeTo = settings.relativeTo:GetName()
                    end
                    frameToMove.settings = settings
                end
            end
        end

        -- sets frames move handlers.
        function SetMoveHandler(frameToMove, handler)
            if not frameToMove then
                return
            end
            handler = handler or frameToMove

            local settings = BlizzMoveDB[frameToMove:GetName()]
            if not settings then
                settings = defaults[frameToMove:GetName()] or {}
                BlizzMoveDB[frameToMove:GetName()] = settings
            end

            frameToMove.settings = settings
            handler.frameToMove = frameToMove

            if not frameToMove.EnableMouse then
                return
            end

            frameToMove:EnableMouse(true)
            frameToMove:SetMovable(true)
            handler:RegisterForDrag("RightButton")

            handler:SetScript("OnDragStart", OnDragStart)
            handler:SetScript("OnDragStop", OnDragStop)

            --override frame position according to settings when shown
            frameToMove:HookScript("OnShow", OnShow)

            --hook OnMouseUp
            handler:HookScript("OnMouseUp", OnMouseUp)

            --hook Scroll for setting scale
            handler:EnableMouseWheel(true)
            handler:HookScript("OnMouseWheel", OnMouseWheel)
        end
    end

    local CreateOptionPanel
    do
        -- resets all frames positions and scales
        local function ResetDB()
            for k, v in pairs(BlizzMoveDB) do
                wipe(v)
                v.save = (defaults[k] and defaults[k].save == true) or false
            end
        end

        -- creates the option panel
        function CreateOptionPanel()
            optionPanel = CreateFrame("Frame", "BlizzMovePanel", UIParent)

            -- window title
            local title = optionPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
            title:SetPoint("TOPLEFT", 16, -16)
            title:SetText("BlizzMove")

            local subtitle = optionPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
            subtitle:SetHeight(35)
            subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
            subtitle:SetPoint("RIGHT", optionPanel, -32, 0)
            subtitle:SetNonSpaceWrap(true)
            subtitle:SetJustifyH("LEFT")
            subtitle:SetJustifyV("TOP")
            subtitle:SetText(L["Click the button below to reset all frames."])

            local button = CreateFrame("Button", nil, optionPanel, "UIPanelButtonTemplate")
            button:SetWidth(100)
            button:SetHeight(30)
            button:SetScript("OnClick", ResetDB)
            button:SetText(RESET)
            button:SetPoint("TOPLEFT", 20, -60)

            optionPanel.name = "BlizzMove"
            InterfaceOptions_AddCategory(optionPanel)
        end
    end

    -- frame event handler
    local function EventHandler(self, event, arg1, arg2)
        if event == "PLAYER_ENTERING_WORLD" then
            -- InspectFrame
            if _G.BlizzMove then
                return
            end

            if next(BlizzMoveDB) == nil then
                BlizzMoveDB = defaults
            end

            f:RegisterEvent("ADDON_LOADED")

            SetMoveHandler(CharacterFrame, PaperDollFrame)
            SetMoveHandler(CharacterFrame, TokenFrame)
            SetMoveHandler(CharacterFrame, SkillFrame)
            SetMoveHandler(CharacterFrame, ReputationFrame)
            SetMoveHandler(CharacterFrame, PetPaperDollFrameCompanionFrame)
            SetMoveHandler(SpellBookFrame)
            SetMoveHandler(QuestLogFrame)
            SetMoveHandler(FriendsFrame)

            if PVPParentFrame then
                SetMoveHandler(PVPParentFrame, PVPFrame)
            else
                SetMoveHandler(PVPFrame)
            end

            SetMoveHandler(_G.LFGParentFrame)
            SetMoveHandler(GameMenuFrame)
            SetMoveHandler(GossipFrame)
            SetMoveHandler(DressUpFrame)
            SetMoveHandler(QuestFrame)
            SetMoveHandler(MerchantFrame)
            SetMoveHandler(HelpFrame)
            SetMoveHandler(PlayerTalentFrame)
            SetMoveHandler(ClassTrainerFrame)
            SetMoveHandler(MailFrame)
            SetMoveHandler(BankFrame)
            SetMoveHandler(VideoOptionsFrame)
            SetMoveHandler(InterfaceOptionsFrame)
            SetMoveHandler(LootFrame)
            SetMoveHandler(LFDParentFrame)
            SetMoveHandler(LFRParentFrame)
            SetMoveHandler(TradeFrame)

            -- create option frame
            InterfaceOptionsFrame:HookScript("OnShow", function()
                if not optionPanel then
                    CreateOptionPanel()
                end
            end)

            f:UnregisterEvent("PLAYER_ENTERING_WORLD")
        elseif arg1 == "Blizzard_InspectUI" then
            -- GuildBankFrame
            SetMoveHandler(InspectFrame)
        elseif arg1 == "Blizzard_GuildBankUI" then
            -- TradeSkillFrame
            SetMoveHandler(GuildBankFrame)
        elseif arg1 == "Blizzard_TradeSkillUI" then
            -- ItemSocketingFrame
            SetMoveHandler(TradeSkillFrame)
        elseif arg1 == "Blizzard_ItemSocketingUI" then
            -- BarberShopFrame
            SetMoveHandler(ItemSocketingFrame)
        elseif arg1 == "Blizzard_BarbershopUI" then
            -- GlyphFrame
            SetMoveHandler(BarberShopFrame)
        elseif arg1 == "Blizzard_GlyphUI" then
            -- MacroFrame
            SetMoveHandler(SpellBookFrame, GlyphFrame)
        elseif arg1 == "Blizzard_MacroUI" then
            -- AchievementFrame
            SetMoveHandler(MacroFrame)
        elseif arg1 == "Blizzard_AchievementUI" then
            -- PlayerTalentFrame
            SetMoveHandler(AchievementFrame, AchievementFrameHeader)
        elseif arg1 == "Blizzard_TalentUI" then
            -- CalendarFrame
            SetMoveHandler(PlayerTalentFrame)
        elseif arg1 == "Blizzard_Calendar" then
            -- ClassTrainerFrame
            SetMoveHandler(CalendarFrame)
        elseif arg1 == "Blizzard_TrainerUI" then
            -- KeyBindingFrame
            SetMoveHandler(ClassTrainerFrame)
        elseif arg1 == "Blizzard_BindingUI" then
            -- AuctionFrame
            SetMoveHandler(KeyBindingFrame)
        elseif arg1 == "Blizzard_AuctionUI" then
            SetMoveHandler(AuctionFrame)
        end
    end
    f:SetScript("OnEvent", EventHandler)
end

-- toggles frames lock/unlock statuses
function mod:Toggle(handler)
    handler = handler or GetMouseFocus()
    if not handler then
        return
    end

    -- we're not moving the whole thing are we?!
    if handler:GetName() == "WorldFrame" then
        return
    end

    local lastParent, frameToMove, i = handler, handler, 0

    while lastParent and lastParent ~= UIParent and i < 100 do
        frameToMove = lastParent
        lastParent = lastParent:GetParent()
        i = i + 1
    end

    if handler and frameToMove then
        if handler:GetScript("OnDragStart") then
            handler:SetScript("OnDragStart", nil)
            Print(L:F("%s locked.", frameToMove:GetName()))
        else
            Print(L:F("%s will move with handler %s", frameToMove:GetName(), handler:GetName()))
            SetMoveHandler(frameToMove, handler)
        end
    else
        Print(L["Error parent not found!"])
    end
end

-- add to keybidings frame
_G.BINDING_HEADER_KPACKBLIZZMOVE = "BlizzMove"
_G.BINDING_NAME_KPACKMOVEFRAME = L["Move/Lock a Frame"]