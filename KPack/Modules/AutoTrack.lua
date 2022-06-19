local core = KPack
if not core then return end
core:AddModule("Auto Track", "Tracking addon for Hunters only.", function(L)
	core.class = core.class or select(2, UnitClass("player"))
	if core.class ~= "HUNTER" or core:IsDisabled("Auto Track") then return end

	local AutoTrack = CreateFrame("Frame")
	AutoTrack:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
	core.AutoTrack = AutoTrack

	local pairs = pairs
	local GetSpellInfo = GetSpellInfo
	local GetSpellCooldown = GetSpellCooldown
	local GetNumTrackingTypes = GetNumTrackingTypes
	local GetTrackingInfo = GetTrackingInfo
	local SetTracking = SetTracking
	local UnitCreatureType = UnitCreatureType
	local UnitCanAttack = UnitCanAttack
	local UnitIsDead = UnitIsDead

	local DB, _
	local revertid

	local defaults = {enabled = true, revert = false}

	local tracking = {
		Beast = 0,
		Demon = 0,
		Dragonkin = 0,
		Elemental = 0,
		Giant = 0,
		Humanoid = 0,
		Undead = 0
	}

	local creature = {
		Beast = "Beast",
		Demon = "Demon",
		Dragonkin = "Dragonkin",
		Elemental = "Elemental",
		Giant = "Giant",
		Humanoid = "Humanoid",
		Undead = "Undead"
	}
	if core.locale == "deDE" then
		creature = {
			Beast = "Wildtier",
			Demon = "Dämon",
			Dragonkin = "Drachkin",
			Elemental = "Elementar",
			Giant = "Riese",
			Humanoid = "Humanoid",
			Undead = "Untoter"
		}
	elseif core.locale == "frFR" then
		creature = {
			Beast = "Bête",
			Demon = "Démon",
			Dragonkin = "Draconien",
			Elemental = "Elémentaire",
			Giant = "Géant",
			Humanoid = "Humanoïde",
			Undead = "Mort-vivant"
		}
	elseif core.locale == "esES" then
		creature = {
			Beast = "Bestia",
			Demon = "Demonio",
			Dragonkin = "Dragón",
			Elemental = "Elemental",
			Giant = "Gigante",
			Humanoid = "Humanoide",
			Undead = "No-muerto"
		}
	elseif core.locale == "esMX" then
		creature = {
			Beast = "Bestia",
			Demon = "Demonio",
			Dragonkin = "Dragon",
			Elemental = "Elemental",
			Giant = "Gigante",
			Humanoid = "Humanoide",
			Undead = "No-muerto"
		}
	elseif core.locale == "koKR" then
		creature = {
			Beast = "야수",
			Demon = "악마",
			Dragonkin = "용족",
			Elemental = "정령",
			Giant = "거인",
			Humanoid = "인간형",
			Undead = "언데드"
		}
	elseif core.locale == "zhCN" then
		creature = {
			Beast = "野兽",
			Demon = "恶魔",
			Dragonkin = "龙类",
			Elemental = "元素生物",
			Giant = "巨人",
			Humanoid = "人型生物",
			Undead = "亡灵"
		}
	elseif core.locale == "zhTW" then
		creature = {
			Beast = "野獸",
			Demon = "惡魔",
			Dragonkin = "龍類",
			Elemental = "元素生物",
			Giant = "巨人",
			Humanoid = "人型生物",
			Undead = "不死族"
		}
	elseif core.locale == "ruRU" then
		creature = {
			Beast = "Животное",
			Demon = "Демон",
			Dragonkin = "Дракон",
			Elemental = "Элементаль",
			Giant = "Великан",
			Humanoid = "Гуманоид",
			Undead = "Нежить"
		}
	end

	local reverseCreature = {}
	for k, v in pairs(creature) do
		reverseCreature[v] = k
	end

	function AutoTrack:CheckTrackingIDS()
		for i = 1, GetNumTrackingTypes() do
			local name, _, _, _ = GetTrackingInfo(i)
			if name == GetSpellInfo(1494) then
				tracking["Beast"] = i
			elseif name == GetSpellInfo(19883) then
				tracking["Humanoid"] = i
			elseif name == GetSpellInfo(19884) then
				tracking["Undead"] = i
			elseif name == GetSpellInfo(19882) then
				tracking["Giant"] = i
			elseif name == GetSpellInfo(19880) then
				tracking["Elemental"] = i
			elseif name == GetSpellInfo(19878) then
				tracking["Demon"] = i
			elseif name == GetSpellInfo(19879) then
				tracking["Dragonkin"] = i
			end
		end
	end

	local function AutoTrack_GetCurrentTracking()
		for i = 1, GetNumTrackingTypes() do
			if select(3, GetTrackingInfo(i)) then
				return i
			end
		end
	end

	function AutoTrack:TrackIt()
		local trackid = 0

		if UnitExists("target") then
			local creaturetype = UnitCreatureType("target")
			if UnitCanAttack("player", "target") and not UnitIsDead("target") and creaturetype then
				if AutoTrack_GetCurrentTracking() ~= tracking[reverseCreature[creaturetype]] then
					trackid = tracking[reverseCreature[creaturetype]]
				else
					trackid = 0
				end
			elseif DB.revert then
				trackid = revertid or 0
			end
		elseif DB.revert then
			trackid = revertid or 0
		end

		core.After(0.5, function() SetTracking(trackid) end)
	end

	local options = {
		type = "group",
		name = L["Auto Track"],
		get = function(i)
			return DB[i[#i]]
		end,
		set = function(i, val)
			DB[i[#i]] = val
			AutoTrack:ApplySettings()
		end,
		args = {
			enabled = {
				type = "toggle",
				name = L["Enable"],
				order = 1,
				width = "double",
			},
			revert = {
				type = "toggle",
				name = L["Revert"],
				desc = L["Whether to revert to previous track."],
				descStyle = "inline",
				order = 2,
				width = "double",
				disabled = function() return not DB.enabled end
			}
		}
	}

	function AutoTrack:SetupDatabase()
		if not DB then
			if type(core.char.AutoTrack) ~= "table" then
				core.char.AutoTrack = CopyTable(defaults)
			end
			DB = core.char.AutoTrack
		end
	end

	function AutoTrack:ApplySettings()
		if DB.enabled then
			AutoTrack:RegisterEvent("PLAYER_REGEN_ENABLED")
			AutoTrack:RegisterEvent("PLAYER_REGEN_DISABLED")
			AutoTrack:RegisterEvent("CHAT_MSG_SKILL")
		else
			AutoTrack:UnregisterAllEvents()
		end
	end

	function AutoTrack:PLAYER_REGEN_ENABLED()
		if DB.enabled then
			AutoTrack:TrackIt()
		end
	end

	function AutoTrack:PLAYER_REGEN_DISABLED()
		if DB.enabled then
			if DB.revert then
				revertid = AutoTrack_GetCurrentTracking()
			end
			AutoTrack:TrackIt()
		end
	end

	function AutoTrack:CHAT_MSG_SKILL()
		if DB.enabled then
			AutoTrack:CheckTrackingIDS()
		end
	end

	core:RegisterForEvent("PLAYER_LOGIN", function()
		AutoTrack:SetupDatabase()
		SLASH_KPACKTRACK1 = "/autotrack"
		SLASH_KPACKTRACK2 = "/track"
		SLASH_KPACKTRACK3 = "/at"
		SlashCmdList.KPACKTRACK = AutoTrack.TrackIt
		core.options.args.Options.args.AutoTrack = options
		core.After(2, function()
			AutoTrack:CheckTrackingIDS()
			AutoTrack:ApplySettings()
		end)
	end)
end)