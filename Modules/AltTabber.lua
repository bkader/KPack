assert(KPack, "KPack not found!")
KPack:AddModule(
	"AltTabber",
	"Allows you to never miss important events even if you play with the game sound off.",
	function(_, core)
	    if core:IsDisabled("AltTabber") then return end

	    local _GetCVar, _SetCVar = GetCVar, SetCVar
	    local _PlaySoundFile = PlaySoundFile

	    core:RegisterCallback("PLAYER_ENTERING_WORLD", function()
	        if not StaticPopupDialogs["CONFIRM_BATTLEFIELD_ENTRY"].OnShow then
	            StaticPopupDialogs["CONFIRM_BATTLEFIELD_ENTRY"].OnShow = function()
	                _PlaySoundFile("Sound\\Spells\\PVPEnterQueue.wav")
	            end
	        end
	    end)

	    local function AltTabber_PlaySound(file)
	        local Sound_EnableSFX = _GetCVar("Sound_EnableSFX")
	        local Sound_EnableAllSound = _GetCVar("Sound_EnableAllSound")

	        if Sound_EnableSFX == "0" then
	            if _GetCVar("Sound_EnableSoundWhenGameIsInBG") == "0" then
	                _SetCVar("Sound_EnableSoundWhenGameIsInBG", "1")
	            elseif Sound_EnableAllSound == "0" then
	                _SetCVar("Sound_EnableAllSound", "1")
	                _SetCVar("Sound_EnableSFX", "0")
	                _SetCVar("Sound_EnableAmbience", "0")
	                _SetCVar("Sound_EnableMusic", "0")
	            else
	                _PlaySoundFile(file)
	            end
	        end
	    end

	    core:RegisterCallback("READY_CHECK", function()
	        AltTabber_PlaySound("Sound\\Interface\\levelup2.wav")
	    end)

	    core:RegisterCallback("LFG_PROPOSAL_SHOW", function()
	        AltTabber_PlaySound("Sound\\Interface\\LFG_DungeonReady.wav")
	    end)

	    core:RegisterCallback("CHAT_MSG_RAID_WARNING", function()
	        AltTabber_PlaySound("Sound\\Interface\\RaidWarning.wav")
	    end)

	    core:RegisterCallback("PARTY_INVITE_REQUEST", function(_, name)
			if core.IgnoreMore and core.IgnoreMore:IsIgnored(name) then
				return
			end
			AltTabber_PlaySound("Sound\\Interface\\iPlayerInviteA.wav")
	    end)

	    core:RegisterCallback("CHAT_MSG_WHISPER", function(_, _, name)
			if core.IgnoreMore and core.IgnoreMore:IsIgnored(name) then
				return
			end
	        AltTabber_PlaySound("Interface\\AddOns\\KPack\\Media\\Sounds\\Whisper.ogg")
	    end)
	end
)