local core = KPack
if not core then return end
core:AddModule("Reflux", "A small lightweight profile manager.", function(L)
	if core:IsDisabled("Reflux") then return end

	local emulated_default_addons = {}
	local LoadAddOn = LoadAddOn
	local IsAddOnLoaded = IsAddOnLoaded
	local IsAddOnLoadOnDemand = IsAddOnLoadOnDemand
	local DB

	local function Print(msg)
		core:Print(msg, "Reflux")
	end

	local function deepCopy(t1, t2)
		local res = {}
		if type(t1) ~= "table" then
			return t1
		end
		for i, v in pairs(t1) do
			if type(v) ~= "table" then
				res[i] = v
			else
				t2 = t2 or {}
				t2[t1] = res
				if t2[v] then
					res[i] = t2[v]
				else
					res[i] = deepCopy(v, t2)
				end
			end
		end
		return res
	end

	local function loadAceLibs()
		if IsAddOnLoadOnDemand("Ace2") and not IsAddOnLoaded("Ace2") then
			Print(L:F("Loading %s since it is configured as LoadOnDemand and NOT loaded", "Ace2"))
			LoadAddOn("Ace2")
		end
		if IsAddOnLoadOnDemand("Ace3") and not IsAddOnLoaded("Ace3") then
			Print(L:F("Loading %s since it is configured as LoadOnDemand and NOT loaded", "Ace3"))
			LoadAddOn("Ace3")
		end
		if IsAddOnLoadOnDemand("LibRock-1.0") and not IsAddOnLoaded("LibRock-1.0") then
			Print(L:F("Loading %s since it is configured as LoadOnDemand and NOT loaded", "LibRock-1.0"))
			LoadAddOn("LibRock-1.0")
		end
	end

	-- Setup ace profiles if we find any
	local function SetAceProfile(profile, addon)
		local LibStub = _G["LibStub"]
		local AceLibrary = _G["AceLibrary"]
		local Rock = _G["Rock"]

		-- Ace DB 3 check
		if LibStub then
			local AceDB = LibStub("AceDB-3.0", true)
			if AceDB and AceDB.db_registry then
				for db in pairs(AceDB.db_registry) do
					if not db.parent then
						if addon then
							if addon and db.sv == addon then
								db:SetProfile(profile)
							end
						else
							db:SetProfile(profile)
						end
					end
				end
			end
		end

		-- Ace DB 2 check is thoery we shoul dbe able to check this via LibStub
		-- However someone may have some anceitn copy of Ace2 that was never upgraded to LibStub
		-- AceLibrary delegate to LibStub so its all good
		if AceLibrary and AceLibrary:HasInstance("AceDB-2.0") then
			local AceDB = AceLibrary("AceDB-2.0")
			if AceDB and AceDB.registry then
				for db in pairs(AceDB.registry) do
					if addon then
						if addon and db.db.name == addon then
							db:SetProfile(profile)
						end
					else
						if db:IsActive() then
							db:SetProfile(profile)
						else
							db:ToggleActive(true)
							db:SetProfile(profile)
							db:ToggleActive(false)
						end
					end
				end
			end
		end

		-- Rock loading
		if Rock and Rock:HasLibrary("LibRockDB-1.0") then
			local RockDB = Rock:GetLibrary("LibRockDB-1.0", false, false)
			if RockDB and RockDB.data then
				for db in pairs(RockDB.data) do
					if addon then
						if addon and db.dbName == addon then
							db:SetProfile(profile)
						end
					else
						db:SetProfile(profile)
					end
				end
			end
		end
	end

	-- Attempt to save all current profiles to a Define one
	-- this cloning is to make it easier to transition to Reflux management
	local function CloneProfiles(profile)
		loadAceLibs()
		local LibStub = _G["LibStub"]
		local AceLibrary = _G["AceLibrary"]

		-- Ace DB 3 check
		if LibStub then
			local AceDB = LibStub("AceDB-3.0", true)
			if AceDB and AceDB.db_registry then
				for db in pairs(AceDB.db_registry) do
					if not db.parent then
						local currentProfile = db:GetCurrentProfile()
						db:SetProfile(profile)
						db:CopyProfile(currentProfile, false)
					end
				end
			end
		end

		-- Ace DB 2 check is thoery we shoul dbe able to check this via LibStub
		-- However someone may have some anceitn copy of Ace2 that was never upgraded to LibStub
		-- AceLibrary delegate to LibStub so its all good
		if AceLibrary and AceLibrary:HasInstance("AceDB-2.0") then
			local AceDB = AceLibrary("AceDB-2.0")
			if AceDB and AceDB.registry then
				for db in pairs(AceDB.registry) do
					local function cp()
						local currentProfile = db:GetProfile()
						db:SetProfile(profile)
						db:CopyProfileFrom(currentProfile)
					end
					if db:IsActive() then
						pcall(cp)
					else
						db:ToggleActive(true)
						pcall(cp)
						db:ToggleActive(false)
					end
				end
			end
		end

		-- Rock copy profile
		if _G.Rock and _G.Rock:HasLibrary("LibRockDB-1.0") then
			local RockDB = _G.Rock:GetLibrary("LibRockDB-1.0", false, false)
			if RockDB and RockDB.data then
				for db in pairs(RockDB.data) do
					local currentProfile = db:GetProfile()
					db:SetProfile(profile)
					db:CopyProfile(currentProfile)
				end
			end
		end
	end

	-- Copy ace profiles if we find any
	local function CopyAceProfile(profile)
		local LibStub = _G["LibStub"]
		local AceLibrary = _G["AceLibrary"]
		-- Ace DB 3 check
		if LibStub then
			local AceDB = LibStub:GetLibrary("AceDB-3.0", true)
			if AceDB and AceDB.db_registry then
				for db in pairs(AceDB.db_registry) do
					if not db.parent then --db.sv is a ref to the saved vairable name
						db:CopyProfile(profile, false)
					end
				end
			end
		end

		-- Ace DB 2 check is thoery we shoul dbe able to check this via LibStub
		-- However someone may have some anceitn copy of Ace2 that was never upgraded to LibStub
		-- AceLibrary delegate to LibStub so its all good
		if AceLibrary and AceLibrary:HasInstance("AceDB-2.0") then
			local AceDB = AceLibrary("AceDB-2.0")
			if AceDB and AceDB.registry then
				for db in pairs(AceDB.registry) do
					local function cp()
						db:CopyProfileFrom(profile)
					end
					if db:IsActive() then
						pcall(cp)
					else
						db:ToggleActive(true)
						pcall(cp)
						db:ToggleActive(false)
					end
				end
			end
		end

		-- Rock copy profile
		if _G.Rock and _G.Rock:HasLibrary("LibRockDB-1.0") then
			local RockDB = _G.Rock:GetLibrary("LibRockDB-1.0", false, false)
			if RockDB and RockDB.data then
				for db in pairs(RockDB.data) do
					db:CopyProfile(profile)
				end
			end
		end
	end
	-- Delete Ace profile
	local function DeleteAceProfile(profile)
		local LibStub = _G["LibStub"]
		local AceLibrary = _G["AceLibrary"]
		-- Ace DB 3 check
		if LibStub then
			local AceDB = LibStub:GetLibrary("AceDB-3.0", true)
			if AceDB and AceDB.db_registry then
				for db in pairs(AceDB.db_registry) do
					if not db.parent then --db.sv is a ref to the saved vairable name
						db:DeleteProfile(profile, true)
					end
				end
			end
		end
		-- Ace DB 2 check is thoery we shoul dbe able to check this via LibStub
		-- However someone may have some anceitn copy of Ace2 that was never upgraded to LibStub
		-- AceLibrary delegate to LibStub so its all good
		if AceLibrary and AceLibrary:HasInstance("AceDB-2.0") then
			local AceDB = AceLibrary("AceDB-2.0")
			if AceDB and AceDB.registry then
				for db in pairs(AceDB.registry) do
					local function cp()
						db:DeleteProfile(profile, true)
					end
					pcall(cp)
				end
			end
		end
		-- Rock delete profile
		if _G.Rock and _G.Rock:HasLibrary("LibRockDB-1.0") then
			local RockDB = _G.Rock:GetLibrary("LibRockDB-1.0", false, false)
			if RockDB and RockDB.data then
				for db in pairs(RockDB.data) do
					db:RemoveProfile(profile)
				end
			end
		end
	end

	-- Show help
	local function ShowHelp()
		Print(L:F("Acceptable commands for: |caaf49141%s|r", "/reflux"))
		print("|cffffd700switch|r |cff00ffffprofile|r", L["This switches to a given profile. Emulated variables are only touched if you previously created a profile in reflux. This automatically Reloads the UI"])
		print("|cffffd700addons|r |cff00ffffprofile|r", L["This restores a previously saved set of addons. Due to technical reasons, it cant switch profiles at the same time. This automatically Reloads the UI"])
		print("|cffffd700create|r |cff00ffffprofile|r", L["This created a profile set."])
		print("|cffffd700add|r |cff00ffffvar|r", L["This will add a given saved variable to the profile emulation. You will need to get this name from the .toc file"])
		print("|cffffd700save|r <|cff00ffffaddons|r>", L["This saves the emulated profiles. Optionally if you can save addon state as well in the profile."])
		print("|cffffd700cleardb|r", L["This will clear out all Reflux saved information."])
		print("|cffffd700show|r", L["This will show you what the active profile is, and all emulated variables."])
		print("|cffffd700copy|r |cff00ffffprofile|r", L["This will attempt to copy the provide profile to the current profile. This automatically Reloads the UI."])
		print("|cffffd700delete|r |cff00ffffprofile|r", L["This is delete a given profile. Please NOTE you can NOT delete the active profile."])
		print("|cffffd700switchexact|r |caaf49141addonSVName|r |cff00ffffprofile|r", L["This will reset JUST the profiled addonSVname to the given profile. This requires advance knowledge of the addon saved variable name."])
		print("|cffffd700snapshot|r |cff00ffffprofile|r", L["This will instruct Reflux to scan your profiles and copy them into the new profile name. This command should allow you to snapshot your current config to a new profile"])
	end

	-- Store Addon state
	local function StoreAddonState(tbl)
		local index = 1
		local count = GetNumAddOns()
		while index < count do
			local name, title, notes, enabled, loadable, reason, security = GetAddOnInfo(index)
			tbl[name] = enabled or 0
			index = index + 1
		end
	end
	local function GetAddonSV(tbl)
		local index = 1
		local count = GetNumAddOns()
		while index < count do
			local name, title, notes, enabled, loadable, reason, security = GetAddOnInfo(index)
			local variables = GetAddOnMetadata(name, "SavedVariables")
			tbl[name] = variables or ""
			index = index + 1
			if variables then
				print("Addon:" .. name .. " SV:" .. variables)
			end
		end
	end
	local function RestoreAddonState(tbl)
		for k, v in pairs(tbl) do
			if v == 1 then
				EnableAddOn(k)
			else
				DisableAddOn(k)
			end
		end
		ReloadUI()
	end

	local function SetupDatabase()
		if not DB then
			if type(core.db.Reflux) ~= "table" then
				core.db.Reflux = {profiles = {}, activeProfile = false, emulated = {}, addons = {}}
			end
			DB = core.db.Reflux
		end
	end

	local function SlashCmdHandler(msg)
		-- make sure to always setup database
		SetupDatabase()

		local cmd, arg = strmatch(msg, "%s*([^%s]+)%s*(.*)")
		if cmd == nil or strlen(cmd) < 1 then
			ShowHelp()
		elseif cmd == "show" then
			if DB.activeProfile then
				Print(L:F("Active profile is %s", DB.activeProfile))
			else
				Print(L["There is no active profile."])
			end
			for k, _ in pairs(DB.profiles) do
				Print(L:F("%s is an available profile.", k))
			end
			if DB.emulated then
				if #DB.emulated == 0 then
					Print(L["Nothing is being emulated"])
				end
				for _, var in pairs(DB.emulated) do
					Print(L:F("%s is being emulated.", var))
				end
			end
			if DB.addons and DB.activeProfile and DB.addons[DB.activeProfile] then
				Print(L["Addon state for the active profile."])
				if not DB.addons[DB.activeProfile] then
					DB.addons[DB.activeProfile] = {}
				end
				for k, v in pairs(DB.addons[DB.activeProfile]) do
					print(k .. ":", v == 1 and L["|cff00ff00ON|r"] or L["|cffff0000OFF|r"])
				end
			else
				Print(L["Addon state is not being saved."])
			end
			local tbl = {}
			GetAddonSV(tbl)
		elseif cmd == "switchexact" then
			-- We dont switch emulated profiles Ace profiles only since we are NOT reloadiing the UI
			-- this is hacky
			local addon, profile = strmatch(arg, "%s*([^%s]+)%s*(.*)")
			if not addon or not profile then
				ShowHelp()
				return
			end
			SetAceProfile(profile, addon)
		elseif cmd == "switch" then
			if not arg or strlen(arg) < 1 then
				ShowHelp()
				return
			end
			-- Check DB to see if we have a createdProfile called xxx
			if DB.profiles[arg] then
				-- do a dep copy of all the saved off tables
				for k, v in pairs(DB.profiles[arg]) do
					if v and k then
						setglobal(k, deepCopy(v))
					end
				end
			end
			SetAceProfile(arg)
			DB.activeProfile = arg
			ReloadUI()
		elseif cmd == "addons" then
			if not arg or strlen(arg) < 1 then
				ShowHelp()
				return
			end
			if DB.addons[arg] then
				RestoreAddonState(DB.addons[arg])
			end
		elseif cmd == "cleardb" then
			core.db.Reflux, DB = nil, nil
			SetupDatabase()
			Print(L["Reflux database cleared."])
		elseif cmd == "save" then
			if not DB.activeProfile then
				Print(L["No profiles are active, please create or switch to one."])
				return
			end
			if DB.profiles[DB.activeProfile] then
				for index, var in ipairs(DB.emulated) do
					DB.profiles[DB.activeProfile][var] = getglobal(var)
					Print(L:F("Saving %s", var))
				end
			else
				Print(L["No emulations saved."])
			end
			if arg == "addons" then
				DB.addons[DB.activeProfile] = {}
				StoreAddonState(DB.addons[DB.activeProfile])
				Print(L["Saving addons."])
			end
		elseif cmd == "create" and strlen(arg) > 2 then
			SetAceProfile(arg)
			DB.profiles[arg] = {}
			DB.activeProfile = arg
			for index, var in ipairs(DB.emulated) do
				setglobal(var, nil)
			end
			ReloadUI()
		elseif cmd == "snapshot" and strlen(arg) > 2 then
			-- Clone command will create a new profile based off of existing profiles
			-- To accomplish this, we will go through each Ace2/3 profile figure out the curent profile name
			-- then we will create a new profile and ask each addond to copy their previous profile
			-- to the new profile.
			CloneProfiles(arg)
			if not DB.activeProfile then
				DB.profiles[arg] = {}
				DB.activeProfile = arg
				DB.addons[arg] = {}
				for index, var in ipairs(DB.emulated) do
					setglobal(var, nil)
				end
			end
			if DB.profiles[arg] then
				DB.profiles[DB.activeProfile] = deepCopy(DB.profiles[arg])
				DB.addons[DB.activeProfile] = deepCopy(DB.addons[arg])
				for k, v in pairs(DB.profiles[DB.activeProfile]) do
					if v and k then
						setglobal(k, deepCopy(v))
					end
				end
			end
			DB.activeProfile = arg
		elseif cmd == "copy" and strlen(arg) > 2 then
			if not DB.activeProfile then
				Print(L["You need to activate a profile before you can copy from another profile."])
				return
			end
			CopyAceProfile(arg)
			if DB.profiles[arg] then
				DB.profiles[DB.activeProfile] = deepCopy(DB.profiles[arg])
				DB.addons[DB.activeProfile] = deepCopy(DB.addons[arg])
				for k, v in pairs(DB.profiles[DB.activeProfile]) do
					if v and k then
						setglobal(k, deepCopy(v))
					end
				end
			end
			ReloadUI()
		elseif cmd == "delete" and strlen(arg) > 2 then
			if DB.profiles[arg] then
				DB.profiles[arg] = nil
				DB.addons[arg] = nil
			end
			if arg == DB.activeProfile then
				DB.activeProfile = false
			end
			DeleteAceProfile(arg)
		elseif cmd == "add" and strlen(arg) > 2 then
			if DB.emulated then
				if getglobal(arg) then
					tinsert(DB.emulated, arg)
					Print(L:F("%s added to emulation list.", arg))
				else
					Print(L:F("%s not found, please check the spelling it is case sensistive.", arg))
				end
			end
		else
			ShowHelp()
		end
	end

	core:RegisterForEvent("PLAYER_LOGIN", function()
		SetupDatabase()
		SLASH_KPACKREFLUX1 = "/reflux"
		SlashCmdList.KPACKREFLUX = SlashCmdHandler
	end)
end)