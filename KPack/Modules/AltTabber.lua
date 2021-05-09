assert(KPack, "KPack not found!")
KPack:AddModule("AltTabber", "Allows you to never miss important events even if you play with the game sound off.", function(_, core, L)
	if core:IsDisabled("AltTabber") then return end

	local AltTabber = CreateFrame("Frame")
	core.AltTabber = AltTabber
	AltTabber:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)

	local _GetCVar, _SetCVar = GetCVar, SetCVar
	local _PlaySoundFile = PlaySoundFile
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
					whisper = true
				}
			end
			DB = core.db.AltTabber
		end
	end

	local function SetupEvents(self)
		if not self or self ~= AltTabber then
			return
		end

		self:RegisterEvent("PLAYER_ENTERING_WORLD")

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
	end

	function AltTabber:PLAYER_ENTERING_WORLD()
		SetupDatabase()
		if not StaticPopupDialogs["CONFIRM_BATTLEFIELD_ENTRY"].OnShow then
			StaticPopupDialogs["CONFIRM_BATTLEFIELD_ENTRY"].OnShow = function()
				_PlaySoundFile("Sound\\Spells\\PVPEnterQueue.wav")
			end
		end
	end

	local function AltTabber_PlaySound(file, var)
		if disabled or not DB.enabled or (var and not DB[var]) then
			return
		end

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

	function AltTabber:CHAT_MSG_RAID_WARNING()
		AltTabber_PlaySound("Sound\\Interface\\RaidWarning.wav", "warning")
	end

	function AltTabber:PARTY_INVITE_REQUEST(name)
		if not AltTabber_IsIgnored(name) then
			AltTabber_PlaySound("Sound\\Interface\\iPlayerInviteA.wav", "invite")
		end
	end

	function AltTabber:CHAT_MSG_WHISPER(_, name)
		if not AltTabber_IsIgnored(name) then
			AltTabber_PlaySound("Interface\\AddOns\\KPack\\Media\\Sounds\\Whisper.ogg", "whisper")
		end
	end

	core:RegisterForEvent("PLAYER_LOGIN", function()
		SetupDatabase()
		core.options.args.Options.args.AltTabber = options

		if _G.AltTabber or not DB.enabled then
			AltTabber:UnregisterAllEvents()
			disabled = true
		else
			SetupEvents(AltTabber)
			disabled = nil
		end
	end)
end)