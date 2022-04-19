local core = KPack
if not core then return end
core:AddModule("SpeedyLoad", "Disables certain events during loading screens to drastically improve loading times.", function(_, folder)
		if core:IsDisabled("SpeedyLoad") then return end

		local f = CreateFrame("Frame")
		f:RegisterEvent("ADDON_LOADED")

		-- cache frequently used globals
		local pairs, wipe, select, pcall = pairs, wipe, select, pcall
		local getmetatable = getmetatable
		local GetFramesRegisteredForEvent = GetFramesRegisteredForEvent
		local issecurevariable, hooksecurefunc = issecurevariable, hooksecurefunc

		-- needed locals
		local enteredOnce, listenForUnreg
		local occured, list = {}
		local events = {
			SPELLS_CHANGED = {},
			USE_GLYPH = {},
			PET_TALENT_UPDATE = {},
			PLAYER_TALENT_UPDATE = {},
			WORLD_MAP_UPDATE = {},
			UPDATE_WORLD_STATES = {},
			CRITERIA_UPDATE = {},
			RECEIVED_ACHIEVEMENT_LIST = {},
			ACTIONBAR_SLOT_CHANGED = {},
			SPELL_UPDATE_USABLE = {},
			UPDATE_FACTION = {}
		}

		local validUnregisterFuncs = {[f.UnregisterEvent] = true}

		local function SpeedyLoad_IsValidUnregisterFunc(tbl, func)
			if not func then return false end
			local valid = issecurevariable(tbl, "UnregisterEvent")
			if not validUnregisterFuncs[func] then
				validUnregisterFuncs[func] = not (not valid)
			end
			return valid
		end

		local function SpeedyLoad_Unregister(event, ...)
			for i = 1, select("#", ...) do
				local frame = select(i, ...)
				local UnregisterEvent = frame.UnregisterEvent

				if validUnregisterFuncs[UnregisterEvent] or SpeedyLoad_IsValidUnregisterFunc(frame, UnregisterEvent) then
					UnregisterEvent(frame, event)
					events[event][frame] = 1
				end
			end
		end

		local function EventHandler(self, event, ...)
			if event == "ADDON_LOADED" then
				local name = ...
				if name:lower() == folder:lower() then
					f:UnregisterEvent("ADDON_LOADED")

					-- we make sure our PLAYER_ENTERING_WORLD is always the first
					list = {GetFramesRegisteredForEvent("PLAYER_ENTERING_WORLD")}
					for i, frame in ipairs(list) do
						frame:UnregisterEvent("PLAYER_ENTERING_WORLD")
					end

					-- after we register PLAYER_ENTERING_WORLD to our frame, we put back
					-- the event to all the frames it was removed from.
					f:RegisterEvent("PLAYER_ENTERING_WORLD")
					for i, frame in ipairs(list) do
						if frame then
							frame:RegisterEvent("PLAYER_ENTERING_WORLD")
						end
					end
					wipe(list)
					list = nil

					-- wtf blizzard, why registering this event?
					if PetStableFrame then
						PetStableFrame:UnregisterEvent("SPELLS_CHANGED")
					end
				end
			elseif event == "PLAYER_ENTERING_WORLD" then
				-- on the player leaving the world
				if not enteredOnce then
					f:RegisterEvent("PLAYER_LEAVING_WORLD")
					hooksecurefunc(getmetatable(f).__index, "UnregisterEvent", function(frame, event)
						if listenForUnreg then
							local frames = events[event]
							if frames then
								frames[frame] = nil
							end
						end
					end)
					enteredOnce = 1
				else
					listenForUnreg = nil
					for e, frames in pairs(events) do
						for frame in pairs(frames) do
							frame:RegisterEvent(e)
							local OnEvent = occured[e] and frame:GetScript("OnEvent")
							if OnEvent then
								local arg1 = (e == "ACTIONBAR_SLOT_CHANGED") and 0 or nil

								local success, err = pcall(OnEvent, frame, e, arg1)
								if not success then
									geterrorhandler()(err, 1)
								end
							end
							frames[frame] = nil
						end
					end
					wipe(occured)
				end
			elseif event == "PLAYER_LEAVING_WORLD" then
				wipe(occured)
				for e in pairs(events) do
					SpeedyLoad_Unregister(e, GetFramesRegisteredForEvent(e))
					f:RegisterEvent(e) -- MUST REGISTER AFTER UNREGISTER (duh?)
				end
				listenForUnreg = 1
			else
				occured[event] = 1
				f:UnregisterEvent(event)
			end
		end
		f:SetScript("OnEvent", EventHandler)
	end
)