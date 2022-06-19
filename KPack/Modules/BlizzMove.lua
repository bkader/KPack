local core = KPack
if not core then return end
core:AddModule("BlizzMove", "Makes the Blizzard windows movable.", function(L)
	if core:IsDisabled("BlizzMove") or _G.BlizzMove then return end

	local mod = core.BlizzMove or {}
	core.BlizzMove = mod

	local DB, _
	local defaults = {
		mouseButton = "LeftButton",
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
			core:Print(msg, "BlizzMove")
		end
	end

	local SetMoveHandler
	do
		do
			-- handlers the frame OnShow event
			local function OnShow(self, ...)
				local settings = DB[self:GetName()]
				if settings and settings.point and settings.save then
					self:ClearAllPoints()
					self:SetPoint(
						settings.point,
						settings.relativeTo or UIParent,
						settings.relativePoint,
						settings.xOfs,
						settings.yOfs
					)
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
					local settings = frameToMove.settings
					if settings then
						settings.scale = scale
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
					frameToMove:GetPoint(1)
				if settings.relativeTo then
					settings.relativeTo = settings.relativeTo:GetName()
				end
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
						DB[frameToMove:GetName()] = {}
						settings = DB[frameToMove:GetName()]
						settings.save = true
						settings.point, settings.relativeTo, settings.relativePoint, settings.xOfs, settings.yOfs =
							frameToMove:GetPoint(1)
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

				--fix for elvui AchievementFrame skin
				--i dont know how to look at "ElvPrivateDB.profiles.CharacterName-RealmName.skins.blizzard.achievement" for proper fix :(
				if (handler == AchievementFrameHeader) and (IsAddOnLoaded("ElvUI")) then
					handler = frameToMove
				end

				local settings = DB[frameToMove:GetName()]
				if not settings then
					settings = defaults[frameToMove:GetName()] or {}
					DB[frameToMove:GetName()] = settings
				end

				frameToMove.settings = settings
				handler.frameToMove = frameToMove

				if not frameToMove.EnableMouse then
					return
				end

				frameToMove:EnableMouse(true)
				frameToMove:SetMovable(true)
				handler:RegisterForDrag(DB.mouseButton or "LeftButton")

				handler:SetScript("OnDragStart", OnDragStart)
				handler:SetScript("OnDragStop", OnDragStop)

				frameToMove:HookScript("OnShow", OnShow)
				handler:HookScript("OnMouseUp", OnMouseUp)
				handler:EnableMouseWheel(true)
				handler:HookScript("OnMouseWheel", OnMouseWheel)
			end
		end

		core:RegisterForEvent("PLAYER_ENTERING_WORLD", function()
			if type(core.db.BlizzMove) ~= "table" or not next(core.db.BlizzMove) then
				core.db.BlizzMove = CopyTable(defaults)
			end
			DB = core.db.BlizzMove

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
			local mouseBtn = DB.mouseButton
			local unchanged = function()
				return (not DB.mouseButton or DB.mouseButton == mouseBtn)
			end

			core.options.args.Options.args.BlizzMove = {
				type = "group",
				name = "BlizzMove",
				width = "full",
				args = {
					button = {
						type = "select",
						name = function()
							if unchanged() then
								return L["Mouse Button"]
							else
								return format("%s - \124cffffffff%s\124r", L["Mouse Button"], L["Please reload ui."])
							end
						end,
						get = function() return DB.mouseButton or "LeftButton" end,
						set = function(_, val) DB.mouseButton = val end,
						values = {LeftButton = L["Left Mouse Button"], RightButton = L["Right Mouse Button"], MiddleButton = L["Middle Mouse"]},
						width = "double",
						order = 1,
					},
					reload = {
						type = "execute",
						name = L["Reload UI"],
						func = function() ReloadUI() end,
						width = "double",
						order = 2,
						hidden = unchanged
					},
					empty_1 = {
						type = "description",
						name = " ",
						width = "full",
						order = 3
					},
					reset = {
						type = "execute",
						name = RESET,
						desc = L["Click the button below to reset all frames."],
						width = "double",
						order = 4,
						func = function()
							for k, v in pairs(DB) do
								wipe(v)
								v.save = (defaults[k] and defaults[k].save == true) or false
							end
						end
					}
				}
			}

			core:RegisterForEvent("ADDON_LOADED", function(_, name)
				if name == "Blizzard_InspectUI" then
					SetMoveHandler(InspectFrame)
				elseif name == "Blizzard_GuildBankUI" then
					SetMoveHandler(GuildBankFrame)
				elseif name == "Blizzard_TradeSkillUI" then
					SetMoveHandler(TradeSkillFrame)
				elseif name == "Blizzard_ItemSocketingUI" then
					SetMoveHandler(ItemSocketingFrame)
				elseif name == "Blizzard_BarbershopUI" then
					SetMoveHandler(BarberShopFrame)
				elseif name == "Blizzard_GlyphUI" then
					SetMoveHandler(PlayerTalentFrame, GlyphFrame)
				elseif name == "Blizzard_MacroUI" then
					SetMoveHandler(MacroFrame)
				elseif name == "Blizzard_AchievementUI" then
					SetMoveHandler(AchievementFrame, AchievementFrameHeader)
				elseif name == "Blizzard_TalentUI" then
					SetMoveHandler(PlayerTalentFrame)
				elseif name == "Blizzard_Calendar" then
					SetMoveHandler(CalendarFrame)
				elseif name == "Blizzard_TrainerUI" then
					SetMoveHandler(ClassTrainerFrame)
				elseif name == "Blizzard_BindingUI" then
					SetMoveHandler(KeyBindingFrame)
				elseif name == "Blizzard_AuctionUI" then
					SetMoveHandler(AuctionFrame)
				end
			end)
		end)
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
end)