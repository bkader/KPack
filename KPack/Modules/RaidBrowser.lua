local core = KPack
if not core or core.Ascension then return end
core:AddModule("Raid Browser", 'Searches for LFR messages sent in chat and /y channels and lists any found raids in the "Browse" tab of the raid browser.', function(L)
	if core:IsDisabled("Raid Browser") then return end

	local RaidBrowser = core.RaidBrowser or CreateFrame("Frame")
	core.RaidBrowser = RaidBrowser
	RaidBrowser:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)

	local pairs, ipairs = pairs, ipairs
	local strlower = string.lower
	local strfind = string.find
	local strsub = string.sub
	local strgsub = string.gsub
	local strformat = string.format
	local tinsert = table.insert
	local math_huge, math_floor = math.huge, math.floor

	local GetScore = _G.GearScore_GetScore or core.GetGearScore or core.Noop

	local DB
	local lfm_event_listeners = {CHAT_MSG_CHANNEL = {}, CHAT_MSG_YELL = {}}
	local algorithm = {}
	do
		function algorithm.max_of(t)
			local result = -math_huge
			local index = 1

			for i, v in ipairs(t) do
				if v and v > result then
					result = v
					index = i
				end
			end

			return index, result
		end

		function algorithm.transform(values, fn)
			local t = {}

			for _, v in ipairs(values) do
				local result = fn(v)
				tinsert(t, result)
			end

			return t
		end

		function algorithm.find_if(t, pred)
			for i, v in ipairs(t) do
				if pred(v) then
					return i
				end
			end

			return nil
		end

		function algorithm.copy_back(target, source)
			for _, v in ipairs(source) do
				tinsert(target, v)
			end

			return target
		end
	end

	local function Print(msg)
		if msg then
			core:Print(msg, "RaidBrowser")
		end
	end

	local function printf(...)
		core:Print(format(...), "RaidBrowser")
	end

	---------------------------------------------------------------------------

	local RefreshLFMMessages
	do
		local sep = "[%s-_,.]"
		local csep = sep .. "*"
		local psep = sep .. "+"
		local raidpatterns = {
			hc = {
				"<raid>" .. csep .. "<size>" .. csep .. "m?a?n?" .. csep .. "%(?hc?%)?",
				psep .. "%(?hc?%)?" .. csep .. "<raid>" .. csep .. "<size>",
				"<raid>" .. csep .. "%(?hc?%)?" .. csep .. "<size>",
				"<fullraid>" .. csep .. "<size>" .. sep .. "m?a?n?" .. csep .. "%(?hc?%)?",
				psep .. "%(?hc?%)?" .. csep .. "<fullraid>" .. csep .. "<size>",
				"<fullraid>" .. csep .. "%(?hc?%)?" .. csep .. "<size>"
			},
			nm = {
				"<raid>" .. csep .. "<size>" .. csep .. "m?a?n?" .. csep .. "%(?nm?%)?",
				psep .. "%(?nm?%)?" .. csep .. "<raid>" .. csep .. "<size>",
				"<raid>" .. csep .. "%(?nm?%)?" .. csep .. "<size>",
				"<raid>" .. csep .. "<size>",
				"<fullraid>" .. csep .. "<size>" .. csep .. "m?a?n?" .. csep .. "%(?nm?%)?",
				psep .. "%(?nm?%)?" .. csep .. "<fullraid>" .. csep .. "<size>",
				"<fullraid>" .. csep .. "%(?nm?%)?" .. csep .. "<size>",
				"<fullraid>" .. csep .. "<size>"
			},
			simple = {
				"<raid>" .. csep .. "<size>" .. csep .. "ma?n?",
				"<raid>" .. csep .. "<size>",
				"<size>" .. csep .. "ma?n?" .. csep .. "<raid>"
			}
		}

		local function CreatePatternFromTemplate(name, size, diff)
			diff = diff or "nm"

			if size == 10 then
				size = "1[0o]"
			elseif size == 40 then
				size = "4[0p]"
			end

			return algorithm.transform(raidpatterns[diff], function(pattern)
				pattern = strgsub(pattern, "<raid>", name)
				pattern = strgsub(pattern, "<size>", size)
				return pattern
			end)
		end

		local raid_list = {
			-- Note: The order of each raid is deliberate.
			-- Heroic raids are checked first, since NM raids will have the default 'icc10' pattern.
			-- Be careful about changing the order of the raids below
			{
				name = "icc25rep",
				instance_name = "Icecrown Citadel",
				size = 25,
				patterns = {
					"icc" .. csep .. "25" .. csep .. "m?a?n?" .. csep .. "repu?t?a?t?i?o?n?" .. csep,
					"icc" .. csep .. "repu?t?a?t?i?o?n?" .. csep .. "25" .. csep .. "m?a?n?",
					"icc" .. csep .. "25" .. csep .. "nm?" .. csep .. "farm",
					"rep" .. csep .. "farm" .. csep .. "icc" .. csep .. 25
				}
			},
			{
				name = "icc10rep",
				instance_name = "Icecrown Citadel",
				size = 10,
				patterns = {
					"icc" .. csep .. "10" .. csep .. "m?a?n?" .. csep .. "repu?t?a?t?i?o?n?" .. csep,
					"icc" .. csep .. "repu?t?a?t?i?o?n?" .. csep .. "10",
					"icc" .. csep .. "10" .. csep .. "nm?" .. csep .. "farm",
					"icc" .. csep .. "nm?" .. csep .. "farm",
					"icc" .. csep .. "repu?t?a?t?i?o?n?",
					"rep" .. csep .. "farm" .. csep .. "icc" .. csep .. 10
				}
			},
			{
				name = "icc10hc",
				instance_name = "Icecrown Citadel",
				size = 10,
				patterns = algorithm.copy_back(CreatePatternFromTemplate("icc", 10, "hc"), {"bane of the fallen king"})
			},
			{
				name = "icc25hc",
				instance_name = "Icecrown Citadel",
				size = 25,
				patterns = algorithm.copy_back(CreatePatternFromTemplate("icc", 25, "hc"), {"the light of dawn"})
			},
			{
				name = "icc10nm",
				instance_name = "Icecrown Citadel",
				size = 10,
				patterns = CreatePatternFromTemplate("icc", 10, "nm")
			},
			{
				name = "icc25nm",
				instance_name = "Icecrown Citadel",
				size = 25,
				patterns = CreatePatternFromTemplate("icc", 25, "nm")
			},
			{
				name = "toc10hc",
				instance_name = "Trial of the Crusader",
				size = 10,
				patterns = algorithm.copy_back(CreatePatternFromTemplate("toc", 10, "hc"), {"togc" .. csep .. "10"})
			},
			{
				name = "toc25hc",
				instance_name = "Trial of the Crusader",
				size = 25,
				patterns = algorithm.copy_back(CreatePatternFromTemplate("toc", 25, "hc"), {"togc" .. csep .. "25"})
			},
			{
				name = "toc10nm",
				instance_name = "Trial of the Crusader",
				size = 10,
				patterns = algorithm.copy_back(CreatePatternFromTemplate("toc", 10, "nm"), {"%[call of the crusade %(10 player%)%]"})
			},
			{
				name = "toc25nm",
				instance_name = "Trial of the Crusader",
				size = 25,
				patterns = algorithm.copy_back(CreatePatternFromTemplate("toc", 25, "nm"), {"%[call of the crusade %(25 player%)%]"})
			},
			{
				name = "rs10hc",
				instance_name = "The Ruby Sanctum",
				size = 10,
				patterns = CreatePatternFromTemplate("rs", 10, "hc")
			},
			{
				name = "rs25hc",
				instance_name = "The Ruby Sanctum",
				size = 25,
				patterns = algorithm.copy_back(CreatePatternFromTemplate("rs", 25, "hc"), {"ruby" .. csep .. "sanctum" .. csep .. 25})
			},
			{
				name = "rs10nm",
				instance_name = "The Ruby Sanctum",
				size = 10,
				patterns = algorithm.copy_back(CreatePatternFromTemplate("rs", 10, "nm"), {"ruby" .. csep .. "sanctum" .. csep .. 10})
			},
			{
				name = "rs25nm",
				instance_name = "The Ruby Sanctum",
				size = 25,
				patterns = algorithm.copy_back({" rs 25n "}, CreatePatternFromTemplate("rs", 25, "nm"))
			},
			{
				name = "voa10",
				instance_name = "Vault of Archavon",
				size = 10,
				patterns = CreatePatternFromTemplate("voa", 10, "simple")
			},
			{
				name = "voa25",
				instance_name = "Vault of Archavon",
				size = 25,
				patterns = CreatePatternFromTemplate("voa", 25, "simple")
			},
			{
				name = "ulduar10",
				instance_name = "Ulduar",
				size = 10,
				patterns = {"ull?a?d[au]?[au]?r?" .. csep .. "10"}
			},
			{
				name = "ulduar25",
				instance_name = "Ulduar",
				size = 25,
				patterns = {"ull?a?d[au]?[au]?r?" .. csep .. "25"}
			},
			{
				name = "os10",
				instance_name = "The Obsidian Sanctum",
				size = 10,
				patterns = algorithm.copy_back(CreatePatternFromTemplate("os", 10, "simple"), {"sartharion must die!"})
			},
			{
				name = "os25",
				instance_name = "The Obsidian Sanctum",
				size = 25,
				patterns = algorithm.copy_back(CreatePatternFromTemplate("os", 25, "simple"), {"%[sartharion must die!%]" .. csep .. "25", csep .. "25" .. "%[sartharion must die%!%]"})
			},
			{
				name = "naxx10",
				instance_name = "Naxxramas",
				size = 10,
				patterns = {
					"the fall of naxxramas %(10 player%)",
					"noth" .. csep .. "the" .. csep .. "plaguebringer" .. csep .. "must" .. csep .. "die!",
					"instructor" .. csep .. "razuvious" .. csep .. "must" .. csep .. "die!",
					"naxx?ramm?as" .. csep .. "10",
					"anub\"rekhan" .. csep .. "must" .. csep .. "die!",
					"patchwerk must die!",
					"naxx?" .. csep .. "10",
					"naxx" .. sep .. "weekly",
					"patchwerk" .. csep .. "must" .. csep .. "die!"
				}
			},
			{
				name = "naxx25",
				instance_name = "Naxxramas",
				size = 25,
				patterns = {
					"the fall of naxxramas %(25 player%)",
					"naxx?ramm?as" .. csep .. "25",
					"naxx?" .. csep .. "25",
				}
			},
			{
				name = "onyxia10",
				instance_name = "Onyxia's Lair",
				size = 10,
				patterns = {"onyxia's lair (10 player)", "onyx?i?a?" .. csep .. "10"}
			},
			{
				name = "onyxia25",
				instance_name = "Onyxia's Lair",
				size = 25,
				patterns = {"onyxia's lair (25 player)", "onyx?i?a?" .. csep .. "25"}
			},
			{
				name = "karazhan10",
				instance_name = "Karazhan",
				size = 10,
				patterns = {"kar?a?z?h?a?n?" .. csep .. "1?0?", "^kz" .. csep .. "10", sep .. "kz" .. csep .. "10"}
			},
			{
				name = "molten core",
				instance_name = "Molten Core",
				size = 40,
				patterns = {
					"molte?n" .. csep .. "core?",
					"[%s-_,.%^]+mc" .. csep .. "4?0?[%s-_,.$]+"
				}
			},
			{
				name = "black temple",
				instance_name = "The Black Temple",
				size = 25,
				patterns = {
					"black" .. csep .. "temple",
					"[%s-_,.]+bt" .. csep .. "25[%s-_,.]+"
				}
			},
			{
				name = "sunwell25",
				instance_name = "The Sunwell",
				size = 25,
				patterns = {"sunwell" .. csep .. "plateau", "swp" .. sep, sep .. "swp"}
			},
			{
				name = "ssc25",
				instance_name = "Coilfang: Serpentshrine Cavern",
				size = 25,
				patterns = {
					"^ssc",
					sep .. "ssc",
					"ssc" .. sep,
					"ssc" .. csep .. "$",
					"serpent" .. csep .. "shrine" .. csep .. "cavern"
				}
			},
			{
				name = "aq40",
				instance_name = "Ahn'Qiraj Temple",
				size = 40,
				patterns = {
					"temple?" .. csep .. "of?" .. csep .. "ahn'?" .. csep .. "qiraj",
					sep .. "*aq" .. csep .. "40" .. csep
				}
			},
			{
				name = "aq20",
				instance_name = "Ruins of Ahn'Qiraj",
				size = 20,
				patterns = {
					"ruins?" .. csep .. "of?" .. csep .. "ahn'?" .. csep .. "qiraj",
					"aq" .. csep .. "20"
				}
			}
		}

		local role_patterns = {
			dps = {
				"[0-9]*" .. csep .. "dps",
				-- melee dps
				"[0-9]*" .. csep .. "m[dp][dp]s",
				"[0-9]*" .. csep .. "rogue",
				"[0-9]*" .. csep .. "kitt?y?",
				"[0-9]*" .. csep .. "cat" .. sep,
				"[0-9]*" .. csep .. "feral" .. csep .. "cat" .. sep,
				"[0-9]*" .. csep .. "feral" .. sep,
				"[0-9]*" .. csep .. "ret" .. csep .. "pal[al]?[dy]?i?n?",
				-- ranged dps
				"[0-9]*" .. csep .. "r[dp][dp]s",
				"[0-9]*" .. csep .. "w?a?r?lock",
				"[0-9]*" .. csep .. "spri?e?st",
				"[0-9]*" .. csep .. "elem?e?n?t?a?l?",
				"[0-9]*" .. csep .. "mage",
				"[0-9]*" .. csep .. "boo?mm?y?k?i?n?",
				"[0-9]*" .. csep .. "hunte?r?s?"
			},
			healer = {
				"[0-9]*" .. csep .. "he[a]?l[er|ers]*", -- LF healer
				"[0-9]*" .. csep .. "re?s?t?o?" .. csep .. "d[ru][ud][iu]d?", -- LF rdruid/rdudu
				"[0-9]*" .. csep .. "tree", -- LF tree
				"[0-9]*" .. csep .. "re?s?t?o?" .. csep .. "shamm?y?", -- LF rsham
				"[0-9]*" .. csep .. "di?s?c?o?" .. csep .. "pri?e?st", -- disc priest
				"[0-9]*" .. csep .. "ho?l?l?y?" .. csep .. "pala" -- LF hpala
			},
			tank = {
				"[0-9]*" .. csep .. "t[a]?nk[s]?", -- NEED TANKS
				"[0-9]*" .. csep .. "tn?[a]?k[s]?", -- Need TNAK
				"[%s-_,.]+[mo]t[%s-_,.]+", -- Need MT/OT
				"[0-9]*" .. csep .. "bears?",
				"[0-9]*" .. csep .. "prot" .. csep .. "pal[al]?[dy]?i?n?"
			}
		}

		local gearscore_patterns = {
			"[1-6]" .. csep .. "k[0-9]+",
			"[1-6][.,][0-9]",
			"[1-6]" .. csep .. "k" .. csep .. "%+",
			"[1-6]" .. csep .. "k" .. sep,
			"%+?" .. csep .. "[1-6]" .. csep .. "k" .. sep,
			"[1-6][0-9][0-9][0-9]",
			"[1-6]%+"
		}

		local lfm_patterns = {
			"lf[0-9]*m",
			"lf" .. csep .. "all",
			"need",
			"need" .. csep .. "all",
			"seek" .. csep .. "[0-9]*" .. csep .. "he[a]?l[er|ers]*", -- seek healer
			"seek" .. csep .. "[0-9]*" .. csep .. "t[a]?nk[s]?", -- seek 5 tanks
			"seek" .. csep .. "[0-9]*" .. csep .. "[mr]?dps", -- seek 9 DPS
			"looking" .. csep .. "for" .. csep .. "all",
			"looking" .. csep .. "for" .. csep .. "an?" .. sep,
			"looking" .. csep .. "for" .. csep .. "[0-9]*" .. csep .. "more", -- looking for 9 more
			"lf" .. csep .. ".*for", -- LF <any characters> for
			"looking" .. csep .. "for" .. csep .. ".*" .. sep .. "for", -- LF <any characters> for
			"lf" .. csep .. "[0-9]*" .. csep .. "he[a]?l[er|ers]*", -- LF healer
			"lf" .. csep .. "[0-9]*" .. csep .. "t[a]?nk[s]?", -- LF 5 tanks
			"lf" .. csep .. "[0-9]*" .. csep .. "[mr]?dps", -- LF 9 DPS
			"whispe?r?" .. csep .. "me",
			sep .. "w" .. csep .. "me" -- /w me
			--''..sep..'/w'..csep..'[%a]+', -- Too greedy
		}

		local guild_recruitment_patterns = {
			"recrui?ti?n?g?",
			"we" .. csep .. "raid",
			"we" .. csep .. "are" .. csep .. "raidi?n?g?",
			"[<({-][%a%s]+[-})>]" .. csep .. "is" .. csep .. "a?", -- (<GuildName> is a) pve guild looking for
			"is" .. csep .. "[%a%s]*playe?rs?",
			"[0-9][0-9][pa]m" .. csep .. "st", -- we raid (12pm set)
			"autorecruit",
			"raid" .. csep .. "time",
			"active" .. csep .. "raiders?",
			"is" .. csep .. "a" .. csep .. "[%a]*" .. csep .. "[pvep][pvep][pvep]" .. csep .. "guild",
			"lf" .. sep .. "members"
		}

		local wts_message_patterns = {
			"wts" .. sep,
			"selling" .. sep
		}

		function RefreshLFMMessages()
			for name, info in pairs(RaidBrowser.messages) do
				-- If the last message from the sender was too long ago, then
				-- remove his raid from lfm_messages.
				if time() - info.time > RaidBrowser.expiresin then
					RaidBrowser.messages[name] = nil
				end
			end
		end

		local function RemoveAchievementText(message)
			return strgsub(message, "|c.*|r", "")
		end

		local function FormatGSString(gs)
			local formatted = strgsub(gs, sep .. "*%+?", "") -- Trim whitespace
			formatted = strgsub(formatted, "k", "")
			formatted = strgsub(formatted, sep, ".")
			formatted = tonumber(formatted)

			-- Convert ex: 5800 into 5.8 for display
			if formatted > 1000 then
				-- Convert 57.0 into 5.7
				formatted = formatted / 1000
			elseif formatted > 100 then
				-- Convert 57.0 into 5.7
				formatted = formatted / 100
			elseif formatted > 10 then
				formatted = formatted / 10
			end

			return strformat("%.1f", formatted)
		end

		local function IsGuildRecruitment(message)
			return algorithm.find_if(guild_recruitment_patterns, function(pattern)
				return strfind(message, pattern)
			end)
		end

		local function IsWTSMessage(message)
			return algorithm.find_if(wts_message_patterns, function(pattern)
				return strfind(message, pattern)
			end)
		end

		-- Basic http pattern matching for streaming sites and etc.
		local function RemoveHttpLinks(message)
			local http_pattern = "https?://*[%a]*.[%a]*.[%a]*/?[%a%-%%0-9_]*/?"
			return strgsub(message, http_pattern, "")
		end

		local function FindRoles(roles, message, pattern_table, role)
			local found = false
			for _, pattern in ipairs(pattern_table[role]) do
				local result = strfind(message, pattern)

				-- If a raid was found then save it to our list of roles and continue.
				if result then
					found = true

					-- Remove the substring from the message
					message = strgsub(message, pattern, "")
				end
			end

			if not found then
				return roles, message
			end

			tinsert(roles, role)
			return roles, message
		end

		function RaidBrowser.RaidInfo(message)
			if not message then
				return
			end
			message = strlower(message)
			message = RemoveHttpLinks(message)

			-- Stop if it's a guild recruit message
			if IsGuildRecruitment(message) or IsWTSMessage(message) then
				return
			end

			-- Search for LFM announcement in the message
			local lfm_found = algorithm.find_if(lfm_patterns, function(pattern)
				return strfind(message, pattern)
			end)

			if not lfm_found then
				return
			end

			-- Get the raid_info from the message
			local raid_info = nil
			for _, r in ipairs(raid_list) do
				for _, pattern in ipairs(r.patterns) do
					local result = strfind(message, pattern)

					-- If a raid was found then save it and continue.
					if result then
						raid_info = r

						-- Remove the substring from the message
						message = strgsub(message, pattern, "")
						break
					end
				end

				if raid_info then
					break
				end
			end

			message = RemoveAchievementText(message)

			-- Get any roles that are needed
			local roles = {}

			--if strfind(message, '
			if not strfind(message, "lfm? all ") and not strfind(message, "need all ") then
				roles, message = FindRoles(roles, message, role_patterns, "dps")
				roles, message = FindRoles(roles, message, role_patterns, "tank")
				roles, message = FindRoles(roles, message, role_patterns, "healer")
			end

			-- If there is only an LFM message, then it is assumed that all roles are needed
			if #roles == 0 then
				roles = {"dps", "tank", "healer"}
			end

			local gs = " "

			-- Search for a gearscore requirement.
			for _, pattern in pairs(gearscore_patterns) do
				local gs_start, gs_end = strfind(message, pattern)

				-- If a gs requirement was found, then save it and continue.
				if gs_start and gs_end then
					gs = FormatGSString(strsub(message, gs_start, gs_end))
					break
				end
			end

			return raid_info, roles, gs
		end

		local function IsLFMChannel(channel)
			return channel == "CHAT_MSG_CHANNEL" or channel == "CHAT_MSG_YELL"
		end

		local function EventHandler(self, event, message, sender)
			if IsLFMChannel(event) then
				local raid_info, roles, gs = RaidBrowser.RaidInfo(message)
				if raid_info and roles and gs then
					-- Put the sender in the table of active raids
					RaidBrowser.messages[sender] = {
						raid_info = raid_info,
						roles = roles,
						gs = gs,
						time = time(),
						message = message
					}

					RaidBrowser.GUI.UpdateList()
				end
			end
		end

		local function SetupDatabase()
			if not DB then
				if type(core.char.LFR) ~= "table" or not next(core.char.LFR) then
					core.char.LFR = {currentset = "active", raidsets = {[PRIMARY] = {}, [SECONDARY] = {}}}
				end
				DB = core.char.LFR
			end
		end

		core:RegisterForEvent("PLAYER_LOGIN", function()
			SetupDatabase()
			RaidBrowser.expiresin = 60

			RaidBrowser.messages = {}
			RaidBrowser.timer = core.NewTicker(10, RefreshLFMMessages)
			for channel, listener in pairs(lfm_event_listeners) do
				RaidBrowser.AddEventListener(channel, EventHandler)
			end

			RaidBrowser:RegisterEvent("PLAYER_ENTERING_WORLD")
			RaidBrowser:RegisterEvent("PLAYER_LEAVING_WORLD")

			RaidBrowser.GUI.raidset.initialize()
		end)

		function RaidBrowser:PLAYER_ENTERING_WORLD()
			SetupDatabase()
		end

		function RaidBrowser:PLAYER_LEAVING_WORLD()
			for channel, listener in pairs(lfm_event_listeners) do
				RaidBrowser.RemoveEventListener(channel, listener)
			end

			if RaidBrowser.timer then
				core.CancelTimer(RaidBrowser.timer, true)
			end
		end
	end

	---------------------------------------------------------------------------

	do
		local registry = {}
		local frame = CreateFrame("Frame")

		local function ScriptError(etype, err)
			local name, line, msg = err:match('%[string (".-")%]:(%d+): (.*)')
			printf("%s error%s:\n %s", etype, name and format(" in %s at line %d", name, line, msg) or "", err)
		end

		local function UnregisterOrphanedEvent(event)
			if not next(registry[event]) then
				registry[event] = nil
				frame:UnregisterEvent(event)
			end
		end

		local function OnEvent(...)
			local self, event = ...
			for listener, val in pairs(registry[event]) do
				local success, rv = pcall(listener[1], listener[2], select(2, ...))
				if rv then
					registry[event][listener] = nil
					if not success then
						ScriptError("event callback", rv)
					end
				end
			end

			UnregisterOrphanedEvent(event)
		end

		frame:SetScript("OnEvent", OnEvent)

		function RaidBrowser.AddEventListener(event, callback, userparam)
			assert(callback, "invalid callback")
			if not registry[event] then
				registry[event] = {}
				frame:RegisterEvent(event)
			end

			local listener = {callback, userparam}
			registry[event][listener] = true
			return listener
		end

		function RaidBrowser.RemoveEventListener(event, listener)
			registry[event][listener] = nil
			UnregisterOrphanedEvent(event)
		end
	end

	---------------------------------------------------------------------------

	do
		local stats = {}

		local raid_achievements = {
			icc = {
				4531, -- Storming the Citadel 10-man
				4604, -- Storming the Citadel 25-man
				4628, -- Storming the Citadel 10-man HC
				4632, -- Storming the Citadel 25-man HC
				4528, -- The Plagueworks 10-man
				4605, -- The Plagueworks 25-man
				4629, -- The Plagueworks 10-man HC
				4633, -- The Plagueworks 25-man HC
				4529, -- The Crimson Hall 10-man
				4606, -- The Crimson Hall 25-man
				4630, -- The Crimson Hall 10-man HC
				4634, -- The Crimson Hall 25-man HC
				4527, -- The Frostwing Halls 10-man
				4607, -- The Frostwing Halls 25-man
				4631, -- The Frostwing Halls 10-man HC
				4635, -- The Frostwing Halls 25-man HC
				4530, -- The Frozen Throne (LK10 NM)
				4597, -- The Frozen Throne (LK25 NM)
				4583, -- Bane of the Fallen King (LK10 HC)
				4584 -- The Light of Dawn (LK25 HC)
			},
			toc = {
				3917, -- Call of the Crusade 10-man
				3916, -- Call of the Crusade 25-man
				3918, -- Call of the Grand Crusade (10 HC)
				3812 -- Call of the Grand Crusade (25 HC)
			},
			rs = {
				4817, -- The Twilight Destroyer 10
				4815, -- The Twilight Destroyer 25
				4818, -- The Twilight Destroyer 10 HC
				4816 -- The Twilight Destroyer 25 HC
			}
		}

		local function FindBestAchievement(raid)
			local ids = raid_achievements[raid]
			if not ids then
				return nil
			end

			local max_achievement = nil

			-- Find the highest ranking completed achievement
			for i, id in ipairs(ids) do
				local _, _, _, completed = GetAchievementInfo(id)
				if completed and (not max_achievement or max_achievement[1] <= i) then
					max_achievement = {i, id}
				end
			end

			-- Find the highest ranking completed achievement criterion
			for i, id in ipairs(ids) do
				for j = 1, GetAchievementNumCriteria(id) do
					local _, _, completed = GetAchievementCriteriaInfo(id, j)
					if completed and (not max_achievement or max_achievement[1] <= i) then
						max_achievement = {i, id}
					end
				end
			end

			if max_achievement then
				return max_achievement[2]
			else
				return nil
			end
		end

		-- Function wrapper around GetTalentTabInfo
		local function GetTalentTabPoints(i)
			local _, _, pts = GetTalentTabInfo(i)
			return pts
		end

		function stats.ActiveSpecIndex()
			local indices = algorithm.transform({1, 2, 3}, GetTalentTabPoints)
			local i, v = algorithm.max_of(indices)
			return i
		end

		do
			local FERAL_COMBAT = "Feral Combat"
			if core.locale == "deDE" then
				FERAL_COMBAT = "Wilder Kampf"
			elseif core.locale == "esES" then
				FERAL_COMBAT = "Combate Feral"
			elseif core.locale == "esMX" then
				FERAL_COMBAT = "Combate feral"
			elseif core.locale == "frFR" then
				FERAL_COMBAT = "Combat farouche"
			elseif core.locale == "koKR" then
				FERAL_COMBAT = "야성"
			elseif core.locale == "ruRU" then
				FERAL_COMBAT = "Сила зверя"
			elseif core.locale == "zhCN" then
				FERAL_COMBAT = "野性战斗"
			elseif core.locale == "zhTW" then
				FERAL_COMBAT = "野性戰鬥"
			end

			function stats.ActiveSpec()
				local active_tab = stats.ActiveSpecIndex()
				local tab_name = GetTalentTabInfo(active_tab)

				-- If we're a feral druid, then we need to distinguish between tank and cat feral.
				if tab_name == FERAL_COMBAT then
					local protector_of_pack_talent = 22
					local _, _, _, _, points = GetTalentInfo(active_tab, protector_of_pack_talent)
					if points > 0 then
						return "Feral (Bear)"
					else
						return "Feral (Cat)"
					end
				end

				return tab_name
			end
		end

		function stats.RaidLockInfo(instance_name, size)
			RequestRaidInfo()
			for i = 1, GetNumSavedInstances() do
				local saved_name, _, reset, _, locked, _, _, _, saved_size = GetSavedInstanceInfo(i)

				if saved_name == instance_name and saved_size == size and locked then
					return true, reset
				end
			end

			return false, nil
		end

		function stats.GetActiveRaidset()
			local spec, gs = stats.ActiveSpec(), GetScore(core.name, "player")
			return spec, gs
		end

		function stats.GetRaidset(set)
			local raidset = DB.raidsets[set]
			if not raidset then
				return
			end
			return raidset.spec, raidset.gs
		end

		function stats.CurrentRaidset()
			if DB.currentset == "active" then
				return stats.GetActiveRaidset()
			end

			return stats.GetRaidset(DB.currentset)
		end

		function stats.SelectCurrentRaidset(set)
			DB.currentset = set
		end

		function stats.SavePrimaryRaidset()
			local spec, gs = stats.GetActiveRaidset()
			DB.raidsets[PRIMARY] = {spec = spec, gs = gs}
		end

		function stats.SaveSecondaryRaidset()
			local spec, gs = stats.GetActiveRaidset()
			DB.raidsets[SECONDARY] = {spec = spec, gs = gs}
		end

		function stats.BuildInvString(raid_name)
			local message = "inv "
			local class = UnitClass("player")

			local spec, gs = stats.CurrentRaidset()
			if gs then message = message .. gs .. "gs " end
			if spec then message = message .. spec .. "spec " end
			message = message .. class

			-- Remove difficulty and raid_name size from the string
			raid_name = strgsub(raid_name, "[1|2][0|5](%w+)", "")

			-- Find the best possible achievement for the given raid_name.
			local achieve_id = FindBestAchievement(raid_name)
			if achieve_id then
				message = message .. " " .. GetAchievementLink(achieve_id)
			end

			return message
		end

		RaidBrowser.stats = stats
	end

	---------------------------------------------------------------------------

	do
		local GUI = {}

		local search_button = LFRQueueFrameFindGroupButton
		local join_button = LFRBrowseFrameInviteButton
		local refresh_button = LFRBrowseFrameRefreshButton

		local name_column = LFRBrowseFrameColumnHeader1
		local gs_list_column = LFRBrowseFrameColumnHeader2
		local raid_list_column = LFRBrowseFrameColumnHeader3

		gs_list_column:SetText("GS")
		raid_list_column:SetText(RAID)

		local function OnJoin()
			local raid_name = RaidBrowser.messages[LFRBrowseFrame.selectedName].raid_info.name
			local message = RaidBrowser.stats.BuildInvString(raid_name)
			SendChatMessage(message, "WHISPER", nil, LFRBrowseFrame.selectedName)
		end

		local function ClearHighlights()
			for i = 1, NUM_LFR_LIST_BUTTONS do
				_G["LFRBrowseFrameListButton" .. i]:UnlockHighlight()
			end
		end

		join_button:SetText(JOIN)
		join_button:SetScript("OnClick", OnJoin)
		if refresh_button:GetScript("OnClick") then
			refresh_button:HookScript("OnClick", RefreshLFMMessages)
		else
			refresh_button:SetScript("OnClick", RefreshLFMMessages)
		end

		local function FormatCount(value)
			if value == 1 then
				return " "
			end

			return "s "
		end

		local function FormatSeconds(seconds)
			seconds = tonumber(seconds) or 0

			if seconds <= 0 then
				return "00 seconds"
			end

			local days_text = ""
			local hours_text = ""
			local mins_text = ""
			local seconds_text = ""

			if seconds >= 86400 then
				local days = math_floor(seconds / 86400)
				days_text = days .. " day" .. FormatCount(days)
				seconds = seconds % 86400
			end

			if seconds >= 3600 then
				local hours = math_floor(seconds / 3600)
				hours_text = hours .. " hr" .. FormatCount(hours)
				seconds = seconds % 3600
			end

			if seconds >= 60 then
				local minutes = math_floor(seconds / 60)
				minutes_text = minutes .. " min" .. FormatCount(minutes)
			end

			return days_text .. hours_text .. minutes_text
		end

		LFRBrowseFrame:SetScript("OnHide", function(self)
			self.selectedName = nil
			ClearHighlights()
			LFRBrowse_UpdateButtonStates()
		end)

		-- Setup tooltip and LFR button entry functionality.
		for i = 1, NUM_LFR_LIST_BUTTONS do
			local button = _G["LFRBrowseFrameListButton" .. i]
			button:SetScript("OnDoubleClick", OnJoin)
			button:SetScript("OnClick", function(button)
				LFRBrowseFrame.selectedName = button.unitName
				ClearHighlights()
				button:LockHighlight()
				LFRBrowse_UpdateButtonStates()
			end)

			button:SetScript("OnEnter", function(button)
				GameTooltip:SetOwner(button, "ANCHOR_RIGHT")

				local seconds = time() - button.lfm_info.time
				local last_sent = strformat("Last sent: %d seconds ago", seconds)
				GameTooltip:AddLine(button.lfm_info.message, 1, 1, 1, true)
				GameTooltip:AddLine(last_sent)

				if button.raid_locked then
					GameTooltip:AddLine("\nYou are |cffff0000saved|cffffd100 for " .. button.raid_info.name)
					local _, reset_time =
						RaidBrowser.stats.RaidLockInfo(button.raid_info.instance_name, button.raid_info.size)
					GameTooltip:AddLine("Lockout expires in " .. FormatSeconds(reset_time))
				else
					GameTooltip:AddLine("\nYou are |cff00ffffnot saved|cffffd100 for " .. button.raid_info.name)
				end

				GameTooltip:Show()
			end)

			button:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
		end

		-- Hide unused dropdown menu
		LFRBrowseFrameRaidDropDown:Hide()

		search_button:SetText(L["Find Raid"])
		search_button:SetScript("OnClick", function() end)

		-- Assignment operator for LFR buttons
		local function AssignLFRButton(button, host_name, lfm_info, index)
			local offset = FauxScrollFrame_GetOffset(LFRBrowseFrameListScrollFrame)
			button.index = index
			index = index - offset

			button.lfm_info = lfm_info
			button.raid_info = lfm_info.raid_info

			-- Update selected LFR raid host name
			button.unitName = host_name

			-- Update button text with raid host name , GS, Raid, and role information
			button.name:SetText(host_name)
			button.level:SetText(button.lfm_info.gs) -- Previously level, now GS

			-- Raid name
			button.class:SetText(button.raid_info.name)

			button.raid_locked = RaidBrowser.stats.RaidLockInfo(button.raid_info.instance_name, button.raid_info.size)
			button.type = "party"

			button.partyIcon:Show()

			button.tankIcon:Hide()
			button.healerIcon:Hide()
			button.damageIcon:Hide()

			-- Get all the roles from the lfm info table
			for _, role in pairs(button.lfm_info.roles) do
				if role == "tank" then
					button.tankIcon:Show()
				end

				if role == "healer" then
					button.healerIcon:Show()
				end

				if role == "melee_dps" or role == "ranged_dps" or role == "dps" then
					button.damageIcon:Show()
				end
			end

			button:Enable()
			button.name:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
			button.level:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)

			-- If the raid is saved, then color the raid text in the list as red
			if button.raid_locked then
				button.class:SetTextColor(1, 0, 0)
			else
				button.class:SetTextColor(0, 1, 1)
			end

			-- Set up the corresponding textures for the roles columns
			button.tankIcon:SetTexture("Interface\\LFGFrame\\LFGRole")
			button.healerIcon:SetTexture("Interface\\LFGFrame\\LFGRole")
			button.damageIcon:SetTexture("Interface\\LFGFrame\\LFGRole")
			button.partyIcon:SetTexture("Interface\\LFGFrame\\LFGRole")
		end

		local function insert_lfm_button(button, index)
			local host_name = nil
			local count = 1

			for n, lfm_info in pairs(RaidBrowser.messages) do
				if count == index then
					AssignLFRButton(button, n, lfm_info, index)
					break
				end

				count = count + 1
			end
		end

		local function UpdateButtons()
			local playerName = core.name
			local selectedName = LFRBrowseFrame.selectedName

			LFRBrowseFrameSendMessageButton:Enable()
			LFRBrowseFrameInviteButton:Enable()
		end

		local function ClearList()
			for i = 1, NUM_LFR_LIST_BUTTONS do
				local button = _G["LFRBrowseFrameListButton" .. i]
				button:Hide()
				button:UnlockHighlight()
			end
		end

		local function tlength(T)
			local count = 0
			for _ in pairs(T) do
				count = count + 1
			end
			return count
		end

		function GUI.UpdateList()
			LFRBrowseFrameRefreshButton.timeUntilNextRefresh = LFR_BROWSE_AUTO_REFRESH_TIME

			local numResults = tlength(RaidBrowser.messages)

			FauxScrollFrame_Update(LFRBrowseFrameListScrollFrame, numResults, NUM_LFR_LIST_BUTTONS, 16)

			local offset = FauxScrollFrame_GetOffset(LFRBrowseFrameListScrollFrame)

			ClearList()

			-- Update button information
			for i = 1, NUM_LFR_LIST_BUTTONS do
				local button = _G["LFRBrowseFrameListButton" .. i]
				if (i <= numResults) then
					insert_lfm_button(button, i + offset)
					button:Show()
				else
					button:Hide()
				end
			end

			ClearHighlights()

			-- Update button highlights
			for i = 1, NUM_LFR_LIST_BUTTONS do
				local button = _G["LFRBrowseFrameListButton" .. i]
				if (LFRBrowseFrame.selectedName == button.unitName) then
					button:LockHighlight()
				else
					button:UnlockHighlight()
				end
			end

			UpdateButtons()
		end

		-- Setup LFR browser hooks
		LFRBrowse_UpdateButtonStates = UpdateButtons
		_G.LFRBrowseFrameList_Update = GUI.UpdateList
		_G.LFRBrowseFrameListButton_SetData = insert_lfm_button

		-- Set the "Browse" tab to be active.
		LFRFrame_SetActiveTab(2)

		LFRParentFrameTab1:Hide()
		LFRParentFrameTab2:Hide()

		RaidBrowser.GUI = GUI
	end

	---------------------------------------------------------------------------

	do
		local raidset = {}

		local frame = CreateFrame("Frame", "RaidBrowserRaidSetMenu", LFRBrowseFrame, "UIDropDownMenuTemplate")
		UIDropDownMenu_SetWidth(frame, 150)
		frame:SetWidth(90)

		local current_selection = nil

		local function IsActiveSelected(option)
			return ("active" == current_selection)
		end

		local function is_primary_selected(option)
			return (PRIMARY == current_selection)
		end

		local function is_secondary_selected(option)
			return (SECONDARY == current_selection)
		end

		local function set_selection(selection)
			local text = ""

			if selection == "active" then
				text = L["Active"]
			else
				local spec, gs = RaidBrowser.stats.GetRaidset(selection)
				if not spec then
					text = "Open"
				else
					text = spec .. " " .. gs .. "gs"
				end
			end

			UIDropDownMenu_SetText(frame, text)
			current_selection = selection
		end

		local function on_active()
			set_selection("active")
			RaidBrowser.stats.SelectCurrentRaidset("active")
		end

		local function on_primary()
			set_selection(PRIMARY)
			RaidBrowser.stats.SelectCurrentRaidset(PRIMARY)
		end

		local function on_secondary()
			set_selection(SECONDARY)
			RaidBrowser.stats.SelectCurrentRaidset(SECONDARY)
		end

		local menu = {
			{
				text = L["Active"],
				func = on_active,
				checked = ("active" == current_selection)
			},
			{
				text = PRIMARY,
				func = on_primary,
				checked = (PRIMARY == current_selection)
			},
			{
				text = SECONDARY,
				func = on_secondary,
				checked = (SECONDARY == current_selection)
			}
		}

		-- Get the menu option text
		local function GetOptionText(option)
			local spec = RaidBrowser.stats.GetRaidset(option)
			if not spec then
				return (option .. ": Open")
			end

			return (option .. ": " .. spec)
		end

		-- Setup dropdown menu for the raidset selection
		frame:SetPoint("CENTER", LFRBrowseFrame, "CENTER", 30, 165)
		UIDropDownMenu_Initialize(frame, EasyMenu_Initialize, nil, nil, menu)

		local function ShowMenu()
			menu[2].text = GetOptionText(PRIMARY)
			menu[3].text = GetOptionText(SECONDARY)
			ToggleDropDownMenu(1, nil, frame, frame, 25, 10, menu)
		end

		_G["RaidBrowserRaidSetMenuButton"]:SetScript("OnClick", ShowMenu)

		local function OnRaidsetSave()
			if current_selection == PRIMARY then
				RaidBrowser.stats.SavePrimaryRaidset()
			elseif current_selection == SECONDARY then
				RaidBrowser.stats.SaveSecondaryRaidset()
			end

			local spec, gs = RaidBrowser.stats.CurrentRaidset()
			Print("Raidset saved: " .. spec .. " " .. gs .. "gs")
			set_selection(current_selection)
		end

		function raidset.initialize()
			set_selection(DB.currentset)
		end
		RaidBrowser.GUI.raidset = raidset

		-- Create raidset save button
		local button =
			CreateFrame("BUTTON", "RaidBrowserRaidSetSaveButton", LFRBrowseFrame, "OptionsButtonTemplate")
		button:SetPoint("CENTER", LFRBrowseFrame, "CENTER", -53, 168)
		button:EnableMouse(true)
		button:RegisterForClicks("AnyUp")

		button:SetText("Save Raid Set")
		button:SetWidth(110)
		button:SetScript("OnClick", OnRaidsetSave)
		button:Show()
	end
end)