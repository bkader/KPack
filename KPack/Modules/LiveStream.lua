local core = KPack
if not core then return end
core:AddModule("LiveStream", "|cff00ff00/stream, /livestream|r", function(L)
	if core:IsDisabled("LiveStream") then return end

	local defaults = {
		msg = "Check out my livestream @ {link} !!",
		emote = "tells you to check out his livestream @ {link}",
		url = "",
		time = 5,
		sendToChannel = false,
		sendToDND = true,
		sendToEmote = false,
		sendToGuild = true,
		sendToParty = false,
		sendToRaid = false,
		sendToRW = false,
		sendToSay = false,
		sendToYell = false
	}

	local pairs, next = pairs, next
	local SendChatMessage = SendChatMessage
	local GetNumPartyMembers = GetNumPartyMembers
	local GetNumRaidMembers = GetNumRaidMembers
	local IsInGuild = IsInGuild

	local SetupDatabase, DB
	local GetOptions, options
	local Start, Stop, Broadcast
	local started, output, emote
	local channels, ListChannels = {}
	local frame, OnUpdate = CreateFrame("Frame")
	frame:RegisterEvent("CHANNEL_UI_UPDATE")
	frame:SetScript("OnEvent", function(self, event, ...) ListChannels() end)

	function ListChannels()
		if options then
			options.args.channels.args = {}
			for i = 1, 10, 1 do
				local id, name = GetChannelName(i)
				if id and name then
					options.args.channels.args[tostring(id)] = {
						type = "toggle",
						name = name,
						order = i
					}
				end
			end
		end
	end

	function Start()
		if not started then
			if (not DB.url or DB.url:trim() == "") then
				frame:SetScript("OnUpdate", nil)
				frame:Hide()
				started, output, emote = nil, nil, nil
				return
			end

			if DB.msg and DB.msg:find("{link}") then
				output = DB.msg:trim():gsub("{link}", DB.url:trim())
			else
				output = DB.url:trim()
			end

			if DB.emote and DB.emote:find("{link}") ~= "" then
				emote = DB.emote:trim():gsub("{link}", DB.url:trim())
			else
				emote = DB.url:trim()
			end

			frame:SetScript("OnUpdate", OnUpdate)
			frame:Show()
			core:Print(L:F("message broadcasting %s", L["|cff00ff00ON|r"]), "LiveStream")
			started = true
			Broadcast()
		end
	end

	function Stop()
		if started then
			frame:SetScript("OnUpdate", nil)
			frame:Hide()
			core:Print(L:F("message broadcasting %s", L["|cffff0000OFF|r"]), "LiveStream")
			started, output, emote = nil, nil, nil
		end
	end

	function Broadcast()
		if not started then
			return
		end

		if not output then
			Stop()
			return
		end

		if DB.sendToSay then
			SendChatMessage(output, "SAY")
		end

		if DB.sendToYell then
			SendChatMessage(output, "YELL")
		end

		if DB.sendToDND then
			SendChatMessage(output, "DND")
		end

		if DB.sendToGuild and IsInGuild() then
			SendChatMessage(output, "GUILD")
		end

		if DB.sendToParty and GetNumPartyMembers() > 0 then
			SendChatMessage(output, "PARTY")
		end

		if DB.sendToRaid and GetNumRaidMembers() > 0 then
			SendChatMessage(output, "RAID")
		end

		if DB.sendToRW then
			SendChatMessage(output, "RAID_WARNING")
		end

		if DB.sendToEmote and emote then
			SendChatMessage(emote, "EMOTE")
		end

		if DB.sendToChannel and next(channels) then
			for k, v in pairs(channels) do
				if v then
					SendChatMessage(output, "CHANNEL", nil, k)
				end
			end
		end
	end

	function OnUpdate(self, elapsed)
		self.elapsed = (self.elapsed or 0) + elapsed
		if self.elapsed > (DB.time * 60) then
			Broadcast()
			self.elapsed = 0
		end
	end

	function SetupDatabase(force)
		if force then
			DB = nil
			SetupDatabase()
			return
		end
		if not DB then
			if type(core.db.LiveStream) ~= "table" or next(core.db.LiveStream) == nil then
				core.db.LiveStream = CopyTable(defaults)
			end
			DB = core.db.LiveStream
		end
	end

	function GetOptions()
		if not options then
			options = {
				type = "group",
				name = "LiveStream",
				get = function(i)
					return DB[i[#i]]
				end,
				set = function(i, val)
					DB[i[#i]] = val
					SetupDatabase(true)
				end,
				args = {
					start = {
						type = "execute",
						name = function()
							return started and L["Stop Broadcasting"] or L["Start Broadcasting"]
						end,
						disabled = function()
							return not (DB and DB.url and DB.url:trim() ~= "")
						end,
						func = function()
							if started then
								Stop()
							else
								Start()
							end
						end,
						order = 0,
						width = "double"
					},
					time = {
						type = "range",
						name = L["Duration"],
						desc = L["Time in minutes after which the message is broadcasted."],
						min = 1,
						max = 15,
						step = 1,
						order = 1,
						width = "double"
					},
					url = {
						type = "input",
						name = L["Channel"],
						desc = L["The link to your livestream channel."],
						order = 2,
						width = "double"
					},
					msg = {
						type = "input",
						name = L["Message"],
						desc = L["The message that will be sent with your livestream channel's link."] .. "\n\n" .. L["Use |cffffd700{link}|r where you want your channel link to be."],
						order = 3,
						width = "double"
					},
					emote = {
						type = "input",
						name = L["Emote"],
						desc = L["The message that will be sent with your livestream channel's link via /emote."] .. "\n\n" .. L["Use |cffffd700{link}|r where you want your channel link to be."],
						disabled = function()
							return not DB.sendToEmote
						end,
						hidden = function()
							return not DB.sendToEmote
						end,
						order = 4,
						width = "double"
					},
					sep1 = {
						type = "description",
						name = " ",
						order = 5,
						width = "full"
					},
					sendToSay = {
						type = "toggle",
						name = L:F("Send to %s", SAY),
						desc = L:F("Should send the message to the %s channel.", SAY),
						order = 6
					},
					sendToYell = {
						type = "toggle",
						name = L:F("Send to %s", YELL),
						desc = L:F("Should send the message to the %s channel.", YELL),
						order = 7
					},
					sendToDND = {
						type = "toggle",
						name = L:F("Send to %s", DND),
						desc = L:F("Should send the message to the %s channel.", DND),
						order = 8
					},
					sendToGuild = {
						type = "toggle",
						name = L:F("Send to %s", GUILD),
						desc = L:F("Should send the message to the %s channel.", GUILD),
						order = 9
					},
					sendToParty = {
						type = "toggle",
						name = L:F("Send to %s", PARTY),
						desc = L:F("Should send the message to the %s channel.", PARTY),
						order = 10
					},
					sendToRaid = {
						type = "toggle",
						name = L:F("Send to %s", RAID),
						desc = L:F("Should send the message to the %s channel.", RAID),
						order = 11
					},
					sendToRW = {
						type = "toggle",
						name = L:F("Send to %s", RAID_WARNING),
						desc = L:F("Should send the message to the %s channel.", RAID_WARNING),
						order = 12
					},
					sendToEmote = {
						type = "toggle",
						name = L:F("Send to %s", EMOTE),
						desc = L:F("Should send the message to the %s channel.", EMOTE),
						order = 13
					},
					sendToChannel = {
						type = "toggle",
						name = L:F("Send to %s", CHANNELS),
						order = 14,
						set = function()
							DB.sendToChannel = not DB.sendToChannel
							if DB.sendToChannel then
								ListChannels()
							end
						end
					},
					channels = {
						type = "group",
						name = L["Channels"],
						order = 15,
						inline = true,
						get = function(i)
							return channels[tonumber(i[#i])]
						end,
						set = function(i, val)
							channels[tonumber(i[#i])] = val
						end,
						disabled = function()
							return not DB.sendToChannel
						end,
						hidden = function()
							return not DB.sendToChannel
						end,
						args = {}
					},
					sep2 = {
						type = "description",
						name = " ",
						order = 98,
						width = "full"
					},
					reset = {
						type = "execute",
						name = RESET,
						order = 99,
						width = "double",
						confirm = function()
							return L:F("Are you sure you want to reset %s to default?", "LiveStream")
						end,
						func = function()
							wipe(core.db.LiveStream)
							DB, started = nil, nil
							SetupDatabase()
							core:Print(L["module's settings reset to default."], "LiveStream")
						end
					}
				}
			}
		end

		ListChannels()
		return options
	end

	core:RegisterForEvent("PLAYER_LOGIN", function()
		SetupDatabase()
		core.options.args.Options.args.LiveStream = GetOptions()

		SLASH_KPACKLIVESTREAM1 = "/stream"
		SLASH_KPACKLIVESTREAM2 = "/livestream"
		SlashCmdList["KPACKLIVESTREAM"] = function(cmd)
			if cmd == "start" or cmd == "on" then
				Start()
			elseif cmd == "stop" or cmd == "off" then
				Stop()
			else
				core:OpenConfig("Options", "LiveStream")
			end
		end
	end)
end)