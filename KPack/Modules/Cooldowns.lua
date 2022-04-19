local core = KPack
if not core then return end
core:AddModule("Cooldowns", "Adds text to items, spell and abilities that are on cooldown to indicate when they will be ready to use.", function(L)
	if core:IsDisabled("Cooldowns") or _G.KkthnxUI then return end

	local mod = {}
	LibStub("AceHook-3.0"):Embed(mod)

	local str_format = string.format
	local math_floor = math.floor
	local math_min = math.min
	local GetTime = GetTime

	local HookCooldows, IsBlacklisted, changed
	local options, GetOptions
	local DB, SetupDatabase
	local defaults = {
		enabled = true,
		font = "Friz Quadrata TT",
		fontSize = 18,
		fontFlags = "OUTLINE",
		minScale = 0.5,
		threshold = 5.5,
		minDuration = 3,
		colors = {
			short = {1, 0, 0, 1}, -- <= 5 seconds
			secs = {1, 1, 0, 1}, -- < 1 minute
			mins = {1, 1, 1, 1}, -- >= 1 minute
			hrs = {0.7, 0.7, 0.7, 1}, -- >= 1 hr
			days = {0.7, 0.7, 0.7, 1} -- >= 1 day
		},
		useBlacklist = true,
		useWhitelist = false,
		blacklist = {}
	}

	local function Cooldowns_FormattedText(s)
		if s >= 86400 then
			return str_format("%dd", math_floor(s / 86400 + 0.5)), s % 86400, DB.colors.days
		elseif s >= 3600 then
			return str_format("%dh", math_floor(s / 3600 + 0.5)), s % 3600, DB.colors.hrs
		elseif s >= 60 then
			return str_format("%dm", math_floor(s / 60 + 0.5)), s % 60, DB.colors.mins
		end
		local color = (s >= DB.threshold) and DB.colors.secs or DB.colors.short
		return math_floor(s + 0.5), s - math_floor(s), color
	end

	local function Cooldowns_TimerOnUpdate(self, elapsed)
		if self.text:IsShown() then
			local color  -- will be used later.

			if self.nextUpdate > 0 then
				self.nextUpdate = self.nextUpdate - elapsed
			else
				if (self:GetEffectiveScale() / UIParent:GetEffectiveScale()) < DB.minScale then
					self.text:SetText("")
					self.nextUpdate = 1
				else
					local remain = self.duration - (GetTime() - self.start)
					if math_floor(remain + 0.5) > 0 then
						local text, nextUpdate
						text, nextUpdate, color = Cooldowns_FormattedText(remain)
						self.text:SetText(text)
						self.text:SetTextColor(unpack(color))
						self.nextUpdate = nextUpdate
					else
						self.text:Hide()
					end
				end
			end

			if changed then
				if color then
					local scale = math_min(self:GetParent():GetWidth() / 36, 1)
					self.text:SetFont(core:MediaFetch("font", DB.font), DB.fontSize * scale, DB.fontFlags)
					self.text:SetTextColor(unpack(color))
				end
				changed = nil
			end
		end
	end

	local function Cooldowns_CreateTimer(self)
		local scale = math_min(self:GetParent():GetWidth() / 36, 1)
		if scale < DB.minScale then
			self.noCooldownCount = true
		else
			local text = self:CreateFontString(nil, "OVERLAY")
			text:SetPoint("CENTER", 0, 1)
			text:SetFont(core:MediaFetch("font", DB.font), DB.fontSize * scale, DB.fontFlags)
			text:SetTextColor(unpack(DB.colors.days))

			self.text = text
			self:SetScript("OnUpdate", Cooldowns_TimerOnUpdate)
			return text
		end
	end

	local function Cooldowns_StartTimer(self, start, duration)
		self.start = start
		self.duration = duration
		self.nextUpdate = 0

		local text = self.text or (not self.noCooldownCount and Cooldowns_CreateTimer(self))
		if text then
			text:Show()
		end
	end

	function SetupDatabase()
		if not DB then
			if type(core.db.OmniCC) ~= "table" or next(core.db.OmniCC) == nil then
				core.db.OmniCC = CopyTable(defaults)
			end
			if core.db.OmniCC.blacklist == nil then
				core.db.OmniCC.blacklist = {}
			end
			if core.db.OmniCC.useBlacklist == nil then
				core.db.OmniCC.useBlacklist = true
				core.db.OmniCC.useWhitelist = false
			end
			DB = core.db.OmniCC
		end
	end

	function GetOptions()
		if not options then
			local disabled = function()
				return not (DB and DB.enabled)
			end

			local filterList = {}

			options = {
				type = "group",
				name = L["Cooldown Text"],
				get = function(i)
					return DB[i[#i]]
				end,
				set = function(i, val)
					DB[i[#i]] = val
					changed = true
				end,
				args = {
					enabled = {
						type = "toggle",
						name = L["Enable"],
						order = 0,
						set = function()
							DB.enabled = not DB.enabled
							HookCooldows()
						end
					},
					reset = {
						type = "execute",
						name = RESET,
						order = 1,
						disabled = disabled,
						confirm = function()
							return L:F("Are you sure you want to reset %s to default?", L["Cooldown Text"])
						end,
						func = function()
							wipe(core.db.OmniCC)
							DB = nil
							SetupDatabase()
							core:Print(L["module's settings reset to default."], L["Cooldown Text"])
							changed = true
						end
					},
					info = {
						type = "header",
						name = L["Some settings require UI to be reloaded."],
						order = 2,
						width = "full"
					},
					sep = {
						type = "description",
						name = " ",
						order = 2.1,
						width = "full"
					},
					minScale = {
						type = "range",
						name = L["Minimum Scale"],
						desc = L["The minimum scale required for icons to show cooldown text."],
						disabled = disabled,
						order = 3,
						min = 0.1,
						max = 1,
						step = 0.01,
						bigStep = 0.05
					},
					minDuration = {
						type = "range",
						name = L["Minimum Duration"],
						desc = L["The minimum time left required to show cooldown texts."],
						disabled = disabled,
						order = 4,
						min = 0,
						max = 60,
						step = 1,
						bigStep = 5
					},
					threshold = {
						type = "range",
						name = L["Threashold"],
						desc = L["The time left at which the time left is considered short."],
						disabled = disabled,
						order = 5,
						width = "double",
						min = 0,
						max = 30,
						step = 0.1,
						bigStep = 1,
						get = function()
							return math_floor(DB.threshold or 5)
						end,
						set = function(_, val)
							DB.threshold = math_floor(val) + 0.5
							changed = true
						end
					},
					appearance = {
						type = "group",
						name = L["Font"],
						disabled = disabled,
						inline = true,
						order = 6,
						args = {
							font = {
								type = "select",
								name = L["Font"],
								dialogControl = "LSM30_Font",
								order = 1,
								width = "double",
								values = AceGUIWidgetLSMlists.font
							},
							fontSize = {
								type = "range",
								name = L["Font Size"],
								order = 2,
								min = 6,
								max = 30,
								step = 1
							},
							fontFlags = {
								type = "select",
								name = L["Font Outline"],
								order = 3,
								values = {
									[""] = NONE,
									["OUTLINE"] = L["Outline"],
									["THINOUTLINE"] = L["Thin outline"],
									["THICKOUTLINE"] = L["Thick outline"],
									["MONOCHROME"] = L["Monochrome"],
									["OUTLINEMONOCHROME"] = L["Outlined monochrome"]
								}
							}
						}
					},
					colors = {
						type = "group",
						name = L["Color"],
						inline = true,
						disabled = disabled,
						order = 7,
						get = function(i)
							return unpack(DB.colors[i[#i]])
						end,
						set = function(i, r, g, b)
							DB.colors[i[#i]] = {r, g, b, 1}
							changed = true
						end,
						args = {
							short = {
								type = "color",
								name = L["Short"],
								order = 1
							},
							secs = {
								type = "color",
								name = L["Seconds"],
								order = 2
							},
							mins = {
								type = "color",
								name = L["Minutes"],
								order = 3
							},
							hrs = {
								type = "color",
								name = L["Hours"],
								order = 4
							},
							days = {
								type = "color",
								name = L["Days"],
								order = 5
							}
						}
					},
					blacklist = {
						type = "group",
						name = L.filtering,
						inline = true,
						disabled = disabled,
						order = 8,
						args = {
							useBlacklist = {
								type = "toggle",
								name = L["Blacklist"],
								desc = L["Only display text on frames not on the blacklist."],
								order = 1,
								get = function()
									return DB.useBlacklist
								end,
								set = function()
									DB.useBlacklist = not DB.useBlacklist
									if DB.useBlacklist == true then
										DB.useWhitelist = false
									end
								end
							},
							useWhitelist = {
								type = "toggle",
								name = L["Whitelist"],
								desc = L["Only display text on registered frames."],
								order = 2,
								get = function()
									return DB.useWhitelist
								end,
								set = function()
									DB.useWhitelist = not DB.useWhitelist
									if DB.useWhitelist == true then
										DB.useBlacklist = false
									end
								end
							},
							list = {
								type = "input",
								name = L["Filtered Frames"],
								desc = L["Enter the names of frames you don't want cooldown texts to be shown on.\nOne name per line."],
								multiline = true,
								width = "double",
								order = 3,
								get = function()
									wipe(filterList)
									for k, _ in pairs(DB.blacklist) do
										tinsert(filterList, k)
									end
									return table.concat(filterList, "\n")
								end,
								set = function(_, val)
									val = val:trim()
									local lines = {}
									for s in val:gmatch("[^\r\n]+") do
										if s:trim() ~= "" then
											lines[s:trim()] = true
										end
									end
									DB.blacklist = lines
								end
							}
						}
					}
				}
			}
		end

		return options
	end

	function HookCooldows()
		local f = getmetatable(ActionButton1Cooldown).__index
		if DB.enabled and not _G.OmniCC then
			mod:Hook(f, "SetCooldown", true)
		elseif mod:IsHooked(f, "SetCooldown") then
			mod:Unhook(f, "SetCooldown")
		end
	end

	do
		local blacklistCache = setmetatable({}, {__index = function(t, frame)
			if frame.noCooldownCount then
				return true
			end

			local fname = frame:GetName()
			local blacklisted = false
			if fname and DB.blacklist then
				for k in pairs(DB.blacklist) do
					if fname:match(k) then
						blacklisted = true
						break
					end
				end
			end
			t[frame] = blacklisted
			return blacklisted
		end})

		function IsBlacklisted(frame)
			return (blacklistCache[frame] or frame.noCooldownCount)
		end
	end

	function mod:SetCooldown(frame, start, duration)
		-- 1) invalid frame.
		if not frame then return end
		-- 2) blacklist frame.
		if DB.useBlacklist and IsBlacklisted(frame) then return end
		-- 3) not whitelisted frame.
		if DB.useWhitelist and not IsBlacklisted(frame) then return end

		if start > 0 and duration > (DB.minDuration or 3) then
			Cooldowns_StartTimer(frame, start, duration)
		else
			local text = frame.text
			if text then
				text:Hide()
			end
		end
	end

	core:RegisterForEvent("PLAYER_LOGIN", function()
		SetupDatabase()
		core.options.args.Options.args.Cooldowns = GetOptions()
		HookCooldows()
	end)
end)