local core = KPack
if not core then return end
core:AddModule("SlashIn", "|cff00ff00/in|r", function()
	if core:IsDisabled("SlashIn") then return end

	-- cache frequently used globals
	local tonumber = tonumber
	local MacroEditBox = MacroEditBox
	local MacroEditBox_OnEvent

	-- module's print function
	local function Print(msg)
		if msg then
			core:Print(msg, "SlashIn")
		end
	end

	local SlashCommandHandler
	do
		-- callback to use for Timer
		local function OnCallback(cmd)
			MacroEditBox_OnEvent(MacroEditBox, "EXECUTE_CHAT_LINE", cmd)
		end

		-- slash command handler
		function SlashCommandHandler(msg)
			local secs, cmd = msg:match("^([^%s]+)%s+(.*)$")
			secs = tonumber(secs)
			if not secs or #cmd == 0 then
				Print("usage: /in <seconds> <command>")
				print("example: /in 1.5 /say hi")
			elseif cmd:find("cast") or cmd:find("use") then
				Print("/use or /cast are blocked by Blizzard UI.")
			else
				core.After(
					tonumber(secs) - 0.5,
					function()
						OnCallback(cmd)
					end
				)
			end
		end
	end

	core:RegisterForEvent("PLAYER_LOGIN", function()
		MacroEditBox_OnEvent = MacroEditBox:GetScript("OnEvent")
		SlashCmdList["KPACKSLASHIN"] = SlashCommandHandler
		SLASH_KPACKSLASHIN1 = "/in"
		SLASH_KPACKSLASHIN2 = "/slashin"
	end)
end)