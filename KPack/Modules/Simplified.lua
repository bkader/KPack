local core = KPack
if not core then return end
core:AddModule("Simplified", "Adds lots of slash commands, shortcut to lots of other functions.", function(L)
	if core:IsDisabled("Simplified") then return end

	local function Print(msg)
		if msg then
			core:Print(msg, "Simplified")
		end
	end

	do
		local cmdFormat = "|cffffd700%s|r"

		local function SlashCommandHandler(cmd)
			if cmd == "help" then
				Print(L["Current list of commands:"])
				print(cmdFormat:format("/lbg"), LEAVE_BATTLEGROUND)
				print(cmdFormat:format("/dgt"), TELEPORT_TO_DUNGEON)
				print(cmdFormat:format("/dgr"), RESET_INSTANCES)
				print(cmdFormat:format("/cl"), COMBAT_LOG)
				print(cmdFormat:format("/rc"), READY_CHECK)
				print(cmdFormat:format("/ds"), L["Change Specilization"])
				print(cmdFormat:format("/gm"), HELP_LABEL)
				print(cmdFormat:format("/vk"), VOTE_TO_KICK)
				print(cmdFormat:format("/gl"), PARTY_PROMOTE)
				print(cmdFormat:format("/lg"), PARTY_LEAVE)
				print(cmdFormat:format("/ol"), UNIT_NAMEPLATES_ALLOW_OVERLAP)
				print(cmdFormat:format("/sh"), SHOW_HELM)
				print(cmdFormat:format("/sc"), SHOW_CLOAK)
				print(cmdFormat:format("/ri"), RAID_INFO)
				print(cmdFormat:format("/mc"), MAX_FOLLOW_DIST)
				print(cmdFormat:format("/rl"), L["Reload UI"])
			else
				Print(L:F("Available command for |caaf49141%s|r is |cffffd700%s|r", "/simp", "help"))
			end
		end

		-- Slash commands
		SlashCmdList["KPACKSIMPLIFIED"] = SlashCommandHandler
		SLASH_KPACKSIMPLIFIED1 = "/os"
		SLASH_KPACKSIMPLIFIED2 = "/simp"
	end

	-- ///////////////////////////////////////////////////////
	-- Leave Battlgroun/Arena & Dungeon Teleport
	-- ///////////////////////////////////////////////////////

	local S_LeaveBattlefield, S_LFGTeleport
	do
		local IsInInstance = IsInInstance
		local IsActiveBattlefieldArena = IsActiveBattlefieldArena
		local LeaveBattlefield = LeaveBattlefield
		local LFGTeleport = LFGTeleport

		-- leave battleground / arena
		function S_LeaveBattlefield()
			local _, bgtype = IsInInstance()
			if bgtype == "arena" or bgtype == "pvp" then
				if bgtype == "pvp" then
					bgtype = "battleground"
				elseif bgtype == "arena" then
					bgtype = (select(2, IsActiveBattlefieldArena())) and "rated arena match" or "arena skirmish"
				end

				StaticPopupDialogs["KPACK_LEAVEBATTLEFIELD"] = {
					text = "Do you want to leave this |cff5CB3FF" .. bgtype .. "|r?\n",
					button1 = "Yes",
					button2 = "No",
					timeout = 0,
					whileDead = 1,
					hideOnEscape = 1,
					OnAccept = function()
						LeaveBattlefield()
					end,
					OnCancel = function()
					end
				}
				StaticPopup_Show("KPACK_LEAVEBATTLEFIELD")
			end
		end

		-- dungeon teleport
		function S_LFGTeleport()
			local inInstance, _ = IsInInstance()
			LFGTeleport((inInstance ~= nil))
		end
	end

	-- ///////////////////////////////////////////////////////
	-- Toggle CombatLog
	-- ///////////////////////////////////////////////////////

	local S_CombatLog
	do
		local toggle = {}
		local LoggingCombat = LoggingCombat
		local CombatLog = _G.CombatLog

		toggle.on = function()
			if LoggingCombat() then
				Print(L:F("Combat logging is currently %s.", L["|cff00ff00enabled|r"]))
			else
				Print(L:F("Combat logging is now %s.", L["|cff00ff00enabled|r"]))
				LoggingCombat(1)
			end
		end

		toggle.off = function()
			if not LoggingCombat() then
				Print(L:F("Combat logging is currently %s.", L["|cffff0000disabled|r"]))
			else
				Print(L:F("Combat logging is now %s.", L["|cffff0000disabled|r"]))
				LoggingCombat(0)
			end
		end

		function S_CombatLog(arg)
			if type(toggle[arg]) == "function" then
				toggle[arg]()
			else
				Print(L:F("Acceptable commands for: |caaf49141%s|r", "/cl"))
				print("on or off")
			end
		end
	end

	-- ///////////////////////////////////////////////////////
	-- Spec Change
	-- ///////////////////////////////////////////////////////

	local S_Respect
	do
		local GetActiveTalentGroup = GetActiveTalentGroup
		local SetActiveTalentGroup = SetActiveTalentGroup

		function S_Respect()
			local spec = (GetActiveTalentGroup() == 1) and 2 or 1
			SetActiveTalentGroup(spec)
		end
	end

	-- ///////////////////////////////////////////////////////
	-- Uninvite Target, Promote to Leader
	-- ///////////////////////////////////////////////////////

	local S_UninviteUnit
	local S_PromoteToLeader
	do
		local UninviteUnit, UnitName = UninviteUnit, UnitName
		local PromoteToLeader = PromoteToLeader

		function S_UninviteUnit()
			UninviteUnit(UnitName("target"))
		end

		function S_PromoteToLeader()
			PromoteToLeader("target")
		end
	end

	-- ///////////////////////////////////////////////////////
	-- Nameplates overlap, Show/Hide Helm & Cloak & MaxCamera
	-- ///////////////////////////////////////////////////////

	local S_NameplatesOverlap
	local S_ShowHelm, S_ShowCloak
	local S_CameraZoomOut
	do
		local abs = math.abs
		local GetCVar, SetCVar = GetCVar, SetCVar
		local ShowingHelm, ShowingCloak = ShowingHelm, ShowingCloak
		local ShowHelm, ShowCloak = ShowHelm, ShowCloak
		local CameraZoomOut = CameraZoomOut

		function S_NameplatesOverlap()
			SetCVar("nameplateAllowOverlap", abs(GetCVar("nameplateAllowOverlap") - 1))
		end

		function S_ShowHelm()
			ShowHelm((not ShowingHelm()))
		end

		function S_ShowCloak()
			ShowCloak((not ShowingCloak()))
		end

		function S_CameraZoomOut()
			local inc = GetCVar("cameraDistanceMax")
			CameraZoomOut(inc or 50)
		end
	end

	-- ///////////////////////////////////////////////////////
	-- Raid Info
	-- ///////////////////////////////////////////////////////

	local S_RaidInfo
	do
		local ToggleFriendsFrame = ToggleFriendsFrame

		function S_RaidInfo()
			if RaidInfoFrame:IsShown() and FriendsFrame:IsShown() then
				ToggleFriendsFrame(5)
				RaidInfoFrame:Hide()
			else
				ToggleFriendsFrame(5)
				RaidInfoFrame:Show()
			end
		end
	end

	-- ///////////////////////////////////////////////////////

	core:RegisterForEvent("PLAYER_ENTERING_WORLD", function()
		-- leave battleground / arena
		SlashCmdList["KPACK_LEAVEBATTLEFIELD"] = S_LeaveBattlefield
		SLASH_KPACK_LEAVEBATTLEFIELD1 = "/lbg"

		-- dungeon teleport in/out
		SlashCmdList["KPACK_DUNGEONTELEPORT"] = S_LFGTeleport
		SLASH_KPACK_DUNGEONTELEPORT1 = "/dgt"
		SLASH_KPACK_DUNGEONTELEPORT2 = "/dungeontele"

		-- reset instances
		SlashCmdList["KPACK_DUNGEONRESET"] = ResetInstances
		SLASH_KPACK_DUNGEONRESET1 = "/dgr"
		SLASH_KPACK_DUNGEONRESET2 = "/dungeonreset"

		-- combatlog
		SlashCmdList["KPACK_COMBATLOG"] = S_CombatLog
		SLASH_KPACK_COMBATLOG1 = "/cl"

		-- ready check
		SlashCmdList["KPACK_READYCHECK"] = DoReadyCheck
		SLASH_KPACK_READYCHECK1 = "/rc"
		SLASH_KPACK_READYCHECK2 = "/кс"

		-- change spec
		SlashCmdList["KPACK_RESPEC"] = S_Respect
		SLASH_KPACK_RESPEC1 = "/ds"
		SLASH_KPACK_RESPEC2 = "/respec"
		SLASH_KPACK_RESPEC3 = "/dualspec"

		-- toggle gm frame
		SlashCmdList["KPACKGMFRAME"] = ToggleHelpFrame
		SLASH_KPACKGMFRAME1 = "/gm"

		-- kick from group
		SlashCmdList["KPACK_GROUPKICK"] = S_UninviteUnit
		SLASH_KPACK_GROUPKICK1 = "/vk"
		SLASH_KPACK_GROUPKICK2 = "/votekick"
		SLASH_KPACK_GROUPKICK3 = "/gk"
		SLASH_KPACK_GROUPKICK4 = "/groupkick"

		-- promote to leader
		SlashCmdList["KPACK_GIVELEAD"] = S_PromoteToLeader
		SLASH_KPACK_GIVELEAD1 = "/gl"
		SLASH_KPACK_GIVELEAD2 = "/grouplead"
		SLASH_KPACK_GIVELEAD3 = "/lead"
		SLASH_KPACK_GIVELEAD4 = "/leader"

		-- leave group
		SlashCmdList["KPACK_LEAVEGROUP"] = LeaveParty
		SLASH_KPACK_LEAVEGROUP1 = "/lg"

		-- nameplates overlap
		SlashCmdList["KPACK_NPOVERLAP"] = S_NameplatesOverlap
		SLASH_KPACK_NPOVERLAP1 = "/ol"
		SLASH_KPACK_NPOVERLAP2 = "/overlap"

		-- show/hide helm & cloak
		SlashCmdList["KPACK_SHOWHELM"] = S_ShowHelm
		SlashCmdList["KPACK_SHOWCLOAK"] = S_ShowCloak
		SLASH_KPACK_SHOWHELM1 = "/sh"
		SLASH_KPACK_SHOWHELM2 = "/showhelm"
		SLASH_KPACK_SHOWCLOAK1 = "/sc"
		SLASH_KPACK_SHOWCLOAK2 = "/showcloak"

		-- raid info frame
		SlashCmdList["KPACK_RAIDINFO"] = S_RaidInfo
		SLASH_KPACK_RAIDINFO1 = "/ri"

		-- max camera zoom out
		SlashCmdList["KPACK_MAXCAMERA"] = S_CameraZoomOut
		SLASH_KPACK_MAXCAMERA1 = "/mc"
		SLASH_KPACK_MAXCAMERA2 = "/maxcamera"

		-- reload UI
		SlashCmdList["KPACK_RELOAD"] = ReloadUI
		SLASH_KPACK_RELOAD1 = "/rl"
	end)
end)