local core = KPack
if not core then return end
core:AddModule("AltTabber", "Allows you to never miss important events even if you play with the game sound off.", function(L)
	if core:IsDisabled("AltTabber") then return end

	local AltTabber = CreateFrame("Frame")
	core.AltTabber = AltTabber
	AltTabber:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)

	local GetCVar, SetCVar = GetCVar, SetCVar
	local PlaySoundFile, GetTime = PlaySoundFile, GetTime
	local DB, disabled

	local function _disabled()
		return (disabled or not DB.enabled)
	end

	local options = {
		type = "group",
		name = "AltTabber",
		get = function(i)
			return DB[i[#i]]
		end,
		set = function(i, val)
			DB[i[#i]] = val
			AltTabber:PLAYER_ENTERING_WORLD()
		end,
		args = {
			enabled = {
				type = "toggle",
				name = L["Enable"],
				order = 0,
				disabled = function()
					return disabled
				end
			},
			sep = {
				type = "description",
				name = " ",
				order = 0.1,
				width = "full"
			},
			tip = {
				type = "description",
				name = L["Tick the sounds you want AltTabber to play:"],
				order = 1,
				disabled = _disabled,
				width = "full"
			},
			ready = {
				type = "toggle",
				name = READY_CHECK,
				order = 2,
				disabled = _disabled
			},
			lfg = {
				type = "toggle",
				name = LFG_TYPE_RANDOM_DUNGEON,
				order = 3,
				disabled = _disabled
			},
			warning = {
				type = "toggle",
				name = RAID_WARNING,
				order = 4,
				disabled = _disabled
			},
			invite = {
				type = "toggle",
				name = GROUP_INVITE,
				order = 5,
				disabled = _disabled
			},
			whisper = {
				type = "toggle",
				name = WHISPER,
				order = 6,
				disabled = _disabled
			},
			achievement = {
				type = "toggle",
				name = ACHIEVEMENTS,
				order = 7,
				disabled = _disabled
			}
		}
	}

	local function SetupDatabase()
		if not DB then
			if type(core.db.AltTabber) ~= "table" or not next(core.db.AltTabber) then
				core.db.AltTabber = {
					enabled = true,
					ready = true,
					lfg = true,
					warning = true,
					invite = true,
					whisper = true,
					achievement = true
				}
			end
			DB = core.db.AltTabber
		end
	end

	local function SetupEvents(self)
		if not self or self ~= AltTabber then
			return
		end

		if DB.ready then
			self:RegisterEvent("READY_CHECK")
		else
			self:UnregisterEvent("READY_CHECK")
		end

		if DB.lfg then
			self:RegisterEvent("LFG_PROPOSAL_SHOW")
		else
			self:UnregisterEvent("LFG_PROPOSAL_SHOW")
		end

		if DB.warning then
			self:RegisterEvent("CHAT_MSG_RAID_WARNING")
		else
			self:UnregisterEvent("CHAT_MSG_RAID_WARNING")
		end

		if DB.invite then
			self:RegisterEvent("PARTY_INVITE_REQUEST")
		else
			self:UnregisterEvent("PARTY_INVITE_REQUEST")
		end

		if DB.whisper then
			self:RegisterEvent("CHAT_MSG_WHISPER")
		else
			self:UnregisterEvent("CHAT_MSG_WHISPER")
		end

		if DB.achievement then
			self:RegisterEvent("ACHIEVEMENT_EARNED")
		else
			self:UnregisterEvent("ACHIEVEMENT_EARNED")
		end
	end

	function AltTabber:PLAYER_ENTERING_WORLD()
		SetupDatabase()
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")
		if not StaticPopupDialogs["CONFIRM_BATTLEFIELD_ENTRY"].OnShow then
			StaticPopupDialogs["CONFIRM_BATTLEFIELD_ENTRY"].OnShow = function()
				PlaySoundFile("Sound\\Spells\\PVPThroughQueue.wav")
			end
		else
			hooksecurefunc(StaticPopupDialogs["CONFIRM_BATTLEFIELD_ENTRY"], "OnShow", function()
				PlaySoundFile("Sound\\Spells\\PVPThroughQueue.wav")
			end)
		end
		if DB.enabled then
			SetupEvents(AltTabber)
		else
			AltTabber:UnregisterAllEvents()
		end
	end

	local function AltTabber_PlaySound(file, var)
		if disabled or not DB.enabled or (var and not DB[var]) then
			return
		end

		local Sound_EnableSFX = GetCVar("Sound_EnableSFX")
		local Sound_EnableAllSound = GetCVar("Sound_EnableAllSound")

		if Sound_EnableSFX == "0" then
			if GetCVar("Sound_EnableSoundWhenGameIsInBG") == "0" then
				SetCVar("Sound_EnableSoundWhenGameIsInBG", "1")
			elseif Sound_EnableAllSound == "0" then
				SetCVar("Sound_EnableAllSound", "1")
				SetCVar("Sound_EnableSFX", "0")
				SetCVar("Sound_EnableAmbience", "0")
				SetCVar("Sound_EnableMusic", "0")
			else
				PlaySoundFile(file)
			end
		end
	end

	local function AltTabber_IsIgnored(name)
		if core.IgnoreMore and core.IgnoreMore:IsIgnored(name) then
			return true
		end

		for i = 1, GetNumIgnores() do
			local n = GetIgnoreName(i)
			if n == name then
				return true
			end
		end

		return false
	end

	function AltTabber:READY_CHECK()
		AltTabber_PlaySound("Sound\\Interface\\levelup2.wav", "ready")
	end

	function AltTabber:LFG_PROPOSAL_SHOW()
		AltTabber_PlaySound("Sound\\Interface\\LFG_DungeonReady.wav", "lfg")
	end

	function AltTabber:PARTY_INVITE_REQUEST(name)
		if not AltTabber_IsIgnored(name) then
			AltTabber_PlaySound("Sound\\Interface\\iPlayerInviteA.wav", "invite")
		end
	end

	do
		local prevtime = 0 -- only plays once every 1sec (default)
		function AltTabber:CHAT_MSG_RAID_WARNING()
			if (GetTime() - prevtime) >= 1 then
				AltTabber_PlaySound("Sound\\Interface\\RaidWarning.wav", "warning")
				prevtime = GetTime()
			end
		end
	end

	do
		local prevtime = 0 -- only plays once every 5sec
		function AltTabber:CHAT_MSG_WHISPER(_, name)
			if (GetTime() - prevtime) >= 5 and not AltTabber_IsIgnored(name) then
				AltTabber_PlaySound("Interface\\AddOns\\KPack\\Media\\Sounds\\Whisper.ogg", "whisper")
				prevtime = GetTime()
			end
		end
	end

	do
		local prevtime = 0 -- only plays once every 5sec
		function AltTabber:ACHIEVEMENT_EARNED()
			if (GetTime() - prevtime) >= 1 then
				AltTabber_PlaySound("Sound\\Spells\\AchievmentSound1.wav", "achievement")
				prevtime = GetTime()
			end
		end
	end

	core:RegisterForEvent("PLAYER_LOGIN", function()
		SetupDatabase()
		core.options.args.Options.args.AltTabber = options
		disabled = (_G.AltTabber ~= nil)
		AltTabber:RegisterEvent("PLAYER_ENTERING_WORLD")
	end)
end)