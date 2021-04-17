assert(KPack, "KPack not found!")
KPack:AddModule("ClassTimer", function(folder, core, L)
    if core:IsDisabled("ClassTimer") then return end

    local ClassTimer = {}
    core.ClassTimer = ClassTimer

    local LSM = core.LSM or LibStub("LibSharedMedia-3.0")

    local unpack = unpack
    local GetTime = GetTime
    local table_sort = table.sort
    local math_ceil = math.ceil
    local gsub = string.gsub
    local pairs, ipairs = pairs, ipairs
    local UnitIsUnit = UnitIsUnit

    local hasPet = (core.class == "HUNTER" or core.class == "WARLOCK" or core.class == "DEATHKNIGHT")
    local unlocked, sticky = {}, {}
    ClassTimer.unlocked = unlocked

    local GetSpellInfo = GetSpellInfo
    local DB, _

    local timers = {
        DEATHKNIGHT = {
            Misc = {51271,49039,48792,55095,49194,22744,55078,51726,59052,51123,57623,49182,63560,49222}
        },
        DRUID = {
            Buffs = {2893,22812,12536,29166,33763,8936,774},
            DOTs = {339,2637,5570,8921},
            Feral = {50322,52610,5211,5211,99,5229,22842,33745,22570,9007,1822,1079,5217},
            Talents = {58181,50334,16850,16857,16979,33831,33878,33876,48438,48517,48518,69369,16689},
            Misc = {33786,770,2637,2908}
        },
        HUNTER = {
            Stings = {3043,1978,3034,19386},
            Stuns = {3385,61685,35100,5116,19306,19407,19228,19577,19503,2974},
            Talents = {19184,19434,19574,34455,19615,34948,53302,56342,53301,63468,34692},
            Traps = {63668,13812,3355,13810,13797},
            Misc = {1539,53517,19263,34500,1543,1130,53480,34506,136,6150,3045,1513,34490}
        },
        MAGE = {
            Buffs = {1459,61024,23028,61316,1008,604,6117,30451,30482},
            DOTs = {22959,133,44614,2120,11119,11366,44457,11180},
            Stuns = {11113,120,31661,168,122,11071,116,11103,11185,11175},
            Talents = {12042,12472,48108,44401,44543,57761,31589,12536,55342,11255},
            Misc = {31641,2139,11426,45438,118,28272,28271,61305,130}
        },
        PALADIN = {
            Blessings = {1044,1022,6940,1038,20217,19740,20911,19742,25898,25782,25899,25894},
            Buffs = {31884,498,642,20177,53601,53486,54428,20925},
            Judgements = {53407,20271,53671,53408},
            Seals = {20375,20164,20165,21084,31801,53736,20166},
            Stuns = {853,20066},
            Misc = {53380,31935,26573,31842,64205,53563,31833,53672,20127,10326,20049,20335,53380,31803,9452}
        },
        PRIEST = {
            Buffs = {27811,47585,14892,14531,33206,10060,139,15270,34754,59887,47930,15257,59000,61792,63735,47788,33150},
            DOTs = {2944,33076,589,15487,15286,14914,48301,64044,34914},
            Stuns = {552,586,1706,453,17,8122,9484,15258,20711,6788}
        },
        ROGUE = {
            Buffs = {13750,32645,13877,31224,5277,14278,14144,36554,5171,2983,51662,51713,58426,51690,1856},
            DOTs = {703,8647,1943},
            Poisons = {44289,41190,2818,2819,11353,11354,25349,26968,27187,57969,57970,13218,13222,13223,13224,27189,57974,57975},
            Stuns = {31124,2094,1833,1776,408,6770},
            Misc = {1330,18425,26679,16511,51693,51722,14251}
        },
        SHAMAN = {
            Buffs = {16176,30160,29062,29206,30823,51945,55198,17364,61295,51562,30802},
            Shocks = {8042,8050,8056},
            Shields = {324,974,52127}
        },
        WARLOCK = {
            Buffs = {34935,1098,1122,30299,17941,63321,32394,63156,47245,17794},
            Curses = {980,603,18223,1490,1714,702},
            DOTs = {172,44518,61290,18265,27243,30108},
            Misc = {18288,710,48184,6789,5782,5484,29893,6358,17877,20707}
        },
        WARRIOR = {
            Buffs = {6673,18499,23881,469,12292,29801,1719,20230,29834,2565,29723,12317,58363,46951,46916,56636,46856,871},
            DOTs = {12721,1160,1715,12294,64382,6552,772,72,7386,6343},
            Stuns = {7922,12809,30153,5530,12323},
            Misc = {2687,1161,20243,676,46859,46924,5246,694,7384,6572}
        }
    }



    local function Print(msg)
    	if msg then
    		core:Print(msg, "ClassTimer")
    	end
    end

    local new, del
    do
    	local cache = setmetatable({}, {__mode ="k"})
    	function new()
    		local t = next(cache)
    		if t then
    			cache[t] = nil
    			return t
    		else
    			return {}
    		end
    	end
    	function del(t)
			for k in pairs(t) do
				t[k] = nil
			end
			cache[t] = true
			return nil
    	end
    end

    local OnUpdate, bars
    do
		local min = L["%dm"]
		local seclong = L["%ds"]
		local secshort = L["%.1fs"]

		local function tioptionsm(num)
			if num <= 10 then
				return L:F("%.1fs", num)
			elseif num <= 60 then
				return L:F("%ds", num)
			else
				return L:F("%dm", math_ceil(num/60))
			end
		end

		function OnUpdate(self)
			local currentTime = GetTime()
			local endTime = self.endTime
			local startTime = self.startTime
			if currentTime > endTime then
				if unlocked[self.unit] then
					unlocked[self.unit] = nil
					unlocked.General = nil
				end

				if self.unit ~= "sticky" then
					ClassTimer:UpdateUnitBars(self.unit)
				else
					bars.sticky[sticky[self.name..self.unitname]]:Hide()
					ClassTimer:StickyUpdate(sticky[self.name..self.unitname])
				end
			else
				local elapsed = (currentTime - startTime)
				if self.tt then
					self.timetext:SetText(tioptionsm(endTime - currentTime))
				end

				local sp = self:GetWidth()*elapsed/(endTime-startTime)
				if self.reversed then
					self:SetValue(startTime + elapsed)
					self.spark:SetPoint('CENTER', self, 'LEFT', sp, 0)
				else
					self:SetValue(endTime - elapsed)
					self.spark:SetPoint('CENTER', self, 'RIGHT', -sp, 0)
				end
			end
		end
    end

	ClassTimer.options = {
		type = "group",
		name = "ClassTimer",
		childGroups = "tree",
		args = {
			enable = {
				type = "toggle",
				name = L["Enable"],
				order = 1,
				get = function() return DB.Enabled end,
				set = function(_, v) DB.Enabled = v end
			},
			lock = {
				type = "toggle",
				name = L["Lock"],
				order = 2,
				get = function() return unlocked.general end,
				set = function(info, v)
					unlocked.general = not v
					for k in pairs(bars) do
						local unit = k
						unlocked[unit] = not v
						if v or not DB.Units[unit].enable or (DB.Group[unit] and unit ~= DB.AllInOneOwner) then
							bars[unit][1]:SetScript('OnDragStart', nil)
							bars[unit][1]:SetScript('OnDragStop', nil)
							if not DB.Units[unit].click then
								bars[unit][1]:EnableMouse(false)
							end
						else
							local bar = bars[unit][1]
							bar.icon:SetTexture("Interface\\Icons\\Ability_Druid_Enrage")
							bar.text:SetText(L['%s, Drag to move']:format(L[unit]))
							bar:EnableMouse(true)
							bar:SetMovable(true)
							bar.startTime = GetTime()
							bar.endTime = GetTime() + 120
							bar:SetMinMaxValues(GetTime(),  GetTime() + 120)
							bar:RegisterForDrag('LeftButton')
							bar.unit = unit
							bar:SetScript('OnDragStart', dragstart)
							bar:SetScript('OnDragStop', dragstop)
							bar:SetAlpha(1)
							bar:Show()
						end
						ClassTimer:UpdateUnitBars(unit)
					end
				end
			},
			BarSettings = {
				type = 'group',
				name = L['Bar Settings'],
				order = 3,
				args = {
					Spacer = {
						type = "header",
						order = 1,
						name = L["Bar Settings"]
					},
					EnabledUnits = {
						order = 1,
						name = L["Enabled Units"],
						type = "multiselect",
						get = function(info, key)
							return DB.Units[key].enable
						end,
						set = function(info, key, value)
							DB.Units[key].enable = value
						end,
					},
					AllInOne = {
						type = 'group',
						name = L['AllInOne'],
						inline = true,
						args = {
							Units = {
								type = 'multiselect',
								name = L['Units'],
								desc = L['Display all the buffs and debuffs on the AllInOne owner bar'],
								get = function(_, key) return DB.Group[key] end,
								set = function(_, key, value)
									if not DB.AllInOneOwner then
										DB.AllInOneOwner = key
									elseif not DB.Group[DB.AllInOneOwner] then
										DB.AllInOneOwner = key
									end
										DB.Group[key] = value
								end,
								order = 2,
							},
							Owner = {
								type = 'select',
								name = L['Owner'],
								desc = L['Display the AllInOne Bars this bar'],
								get = function() return DB.AllInOneOwner end,
								set = function(_, value) DB.AllInOneOwner = value DB.Group[value] = true  end,
								order = 3,
							}
						}
					}
				}
			},
		}
	}

    do
    	local function MouseUp(bar, button)
    		if DB.Units[bar.unit].click then
    			if button == 'RightButton' then
    				local msg = L['%s has %s left']:format(bar.text:GetText(), bar.timetext:GetText())
    				if UnitInRaid('player') then
    					SendChatMessage(msg, 'RAID')
    				elseif GetNumPartyMembers() > 0 then
    					SendChatMessage(msg, 'PARTY')
    				end
    			end
    		end
    	end

    	local framefactory = {
    		__index = function(t,k)
    			local bar = CreateFrame('StatusBar', nil, UIParent)
    			t[k] = bar
    			bar:SetFrameStrata('MEDIUM')
    			bar:Hide()
    			bar:SetClampedToScreen(true)
    			bar:SetScript('OnUpdate', OnUpdate)
    			bar:SetBackdrop({bgFile = 'Interface\\Tooltips\\UI-Tooltip-Background', tile = true, tileSize = 16})
    			bar.text = bar:CreateFontString(nil, 'OVERLAY')
    			bar.timetext = bar:CreateFontString(nil, 'OVERLAY')
    			bar.icon = bar:CreateTexture(nil, 'DIALOG')
    			bar:SetScript('OnMouseUp', MouseUp)

    			local spark = bar:CreateTexture(nil, "OVERLAY")
    			bar.spark = spark
    			spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    			spark:SetWidth(16)
    			spark:SetBlendMode("ADD")
    			spark:Show()
    			ClassTimer:ApplySettings()

    			return bar
    		end
    	}

    	bars = {
    		target = setmetatable({}, framefactory),
    		focus  = setmetatable({}, framefactory),
    		player = setmetatable({}, framefactory),
    		sticky = setmetatable({}, framefactory),
    		pet    = hasPet and setmetatable({}, framefactory) or nil
    	}
    	ClassTimer.bars = bars
    end

    ClassTimer.backup = {
		enable                 = true,
		buffs                  = true,
		click                  = false,
		debuffs                = true,
		differentColors        = false,
		growup                 = false,
		showIcons              = false,
		icons                  = true,
		iconSide               = 'LEFT',
		scale                  = 1,
		spacing                = 0,
		nametext               = true,
		timetext               = true,
		texture                = 'Blizzard',
		width                  = 150,
		height                 = 16,
		font                   = 'Friz Quadrata TT',
		fontsize               = 9,
		alpha                  = 1,
		scale                  = 1,
		bartext                = '%s (%a) (%u)',
		sizeEnable             = false,
		sizeMax                = 5,
		buffcolor              = {0,0.49, 1, 1},
		alwaysshownbuffcolor   = {0.35, 0.45, 0.6, 1},
		Poisoncolor            = {0, 1, 0, 1},
		Magiccolor             = {0, 0, 1, 1},
		Diseasecolor           = {.55, .15, 0, 1},
		Cursecolor             = {5, 0, 5, 1},
		debuffcolor            = {1.0,0.7, 0, 1},
		alwaysshowndebuffcolor = {0.5, 0.45, 0.1, 1},
		backgroundcolor        = {0,0, 0, 1},
		textcolor              = {1,1,1},
    }
    ClassTimer.defaults = {
    	Enabled = true,
    	Locked = false,
    	Abilities = {},
    	Group     = {},
    	Sticky    = {},
    	Custom = {},
    	AlwaysShown = {},
    	Units     = {
    		['focus']  = { click = true },
    		['sticky'] = { enable = false },
    		['player'] = {},
    		['target'] = {},
    		['pet'] = {},
    		['general'] = {},
    	},
    }

    function ClassTimer:CreateTimers()
    	return timers[core.class]
    end

    function ClassTimer:Race()
    	local spells = {
    		BloodElf = {25046,28734},
    		Draenei = {28880},
    		Dwarf = {20594},
    		Gnome = {20589},
    		Orc = {20572},
    		Scourge = {20577,7744},
    		Tauren = {20549},
    		Troll = {20554},
    	}
    	return spells[core.race]
    end

	function ClassTimer:List(tbl)
		if not tbl then return end
		local list = {}
		for k, v in pairs(tbl) do
			local n = GetSpellInfo(v)
			list[n] = n
		end
		return list
	end

	function ClassTimer:AddUnitOptions(utype)
		local path = ClassTimer.options.args.BarSettings
		path.args[utype] = {
			name = L[utype],
			type = "group",
			desc = "Settings for "..L[utype],
			order = utype == 'general' and 1 or 20,
			childGroups = "tab",
			hidden = function()
				return not(DB.Units[utype].enable or ClassTimer.backup.enable)
			end,
			get = function(info)
				return DB.Units[info.arg[1]][info.arg[2]]
			end,
			set = function(info, value)
				if info.arg[1] == "general" then
					for k in pairs(bars) do
						DB.Units[k][info.arg[2]] = value
					end
				end
				DB.Units[info.arg[1]][info.arg[2]] = value
				ClassTimer.ApplySettings()
			end,
			args = {
				Header = {
					type = 'header',
					order = 1,
					name = L[utype],
				},
				General = {
					name = L["General"],
					type = "group",
					order = 1,
					args = {
						buffs = {
							type = 'toggle',
							name = L['Enable Buffs'],
							desc = L['Show buffs'],
							order = 1,
							arg = {utype, 'buffs'},
						},
						debuffs = {
							type = 'toggle',
							name = L['Enable Debuffs'],
							desc = L['Show debuffs'],
							order = 2,
							arg = {utype, 'debuffs'},
						},
						click = {
							type = 'toggle',
							name = L['Use Clicks'],
							desc = L['Print timeleft and ability on right click'],
							arg = {utype, 'click'},
							order = 4,
						},
						growUp = {
							type = 'toggle',
							name = L['Grow Up'],
							desc = L['Set bars to grow up'],
							order = 5,
							arg = {utype, 'growup'},
						},
						reversed = {
							type = 'toggle',
							name = L['Reversed'],
							desc = L['Reverse the bars (fill vs deplete)'],
							order = 6,
							arg = {utype, 'reversed'},
						},
						reverseSort = {
							type = 'toggle',
							name = L['Reverse sort'],
							desc = L['Reverse up/down sorting'],
							order = 7,
							arg = {utype, 'reverseSort'},
						},

						showiconsOnly = {
							type = 'toggle',
							name = L['Show Only Icons'],
							desc = L['Show only icons and timeleft'],
							arg = {utype, 'showIcons'},
							order = 8,
						},
						iconSide = {
							type = 'select',
							name = L['Icon Position'],
							desc = L['Set the side of the bar that the icon appears on'],
							values = {['LEFT']=L['Left'], ['RIGHT']=L['Right']},
							arg = {utype, 'iconSide'},
							order = 9,
						},
					},
				},
				FrameAttributes = {
					name = L["Frame Attributes"],
					type = "group",
					order = 2,
					args = {
						width = {
							type = 'range',
							name = L['Bar Width'],
							desc = L['Set the width of the bars'],
							min = 50,
							max = 300,
							step = 1,
							--bigStep = 5,
							arg = {utype, 'width'},
							order = 1,
						},
						height = {
							type = 'range',
							name = L['Bar Height'],
							desc = L['Set the height of the bars'],
							min = 4,
							max = 25,
							step = 1,
							--bigStep = 5,
							arg = {utype, 'height'},
							order = 2,
						},
						scale = {
							type = 'range',
							name = L['Scale'],
							desc = L['Set the scale of the bars'],
							min = .1,
							max = 2,
							step = .01,
							--bigStep = .1,
							order = 3,
							arg = {utype, 'scale'},
						},
						spacing = {
							type = 'range',
							name = L['Spacing'],
							desc = L['Tweak the space between bars'],
							min = -5,
							max = 5,
							step = .1,
							--bigStep = 1,
							arg = {utype, 'spacing'},
							order = 4,
						},
						alpha = {
							type = 'range',
							name = L['Alpha'],
							desc = L['Set the alpha of the bars'],
							order = 5,
							min = 0,
							max = 1,
							step = .05,
							arg = {utype, 'alpha'},
						},
						sizes = {
							type = 'group',
							name = L['Change size'],
							desc = L['Change bar size depending on duration if its less that the max time setting'],
							order = 6,
							inline = true,
							args = {
								enable = {
									type = 'toggle',
									name = L['Enable'],
									desc = L['Enable changing of bar size depending on duration if its less that the max time setting'],
									order = 1,
									arg = {utype, 'sizeEnable'}
								},
								maxTime = {
									type = 'range',
									name = L['Max time'],
									desc = L['Max time to change bar sizes for'],
									order = 2,
									max = 60,
									min = 5,
									step = .5,
									--bigStep = 1,
									hidden = function() return not DB.Units[utype].sizeEnable or ClassTimer.backup.sizeEnable end,
									arg = {utype, 'sizeMax'},
								}
							}
						},
					},
				},
				Texts = {
					name = L["Texts"],
					type = "group",
					order = 3,
					args = {
						text = {
							type = 'input',
							name = L['Bar Text'],
							desc = L['Set the bar text'],
							order = 1,
							usage = L['<%s for spell, %a for applications, %n for name, %u for unit>'],
							arg = {utype, 'bartext'},
						},
						timetext = {
							type = 'toggle',
							name = L['Time Text'],
							desc = L['Display the time remaining on buffs/debuffs on their bars'],
							arg = {utype, 'timetext'},
							order = 2,
						},
						textcolor = {
							type = 'color',
							name = L['Text Color'],
							desc = L['Set the color of the text for the bars'],
							arg = {utype, 'textcolor'},
							get = getColor,
							set = setColor,
							order = 3,
						},
						font = {
							type = 'select',
							name = L['Font'],
							desc = L['Set the font used in the bars'],
							values = function() return ClassTimer:List(sm:List('font')) end,
							arg = {utype, 'font'},
							order = 4,
						},
						fontsize = {
							type = 'range',
							name = L['Font Size'],
							desc = L['Set the font size for the bars'],
							min = 3,
							max = 15,
							step = .5,
							--bigStep = 2,
							arg = {utype, 'fontsize'},
							order = 5,
						},
					},
				},
				Textures = {
					name = L["Textures"],
					type = "group",
					order = 4,
					args = {
						texture = {
							type = 'select',
							name = L['Texture'],
							desc = L['Set the bar Texture'],
							values = function() return ClassTimer:List(sm:List('statusbar')) end,
							order = 1,
							arg = {utype, 'texture'},
						},
						showicons = {
							type = 'toggle',
							name = L['Show Icons'],
							desc = L['Show icons on buffs and debuffs'],
							arg = {utype, 'icons'},
							order = 2,
						},
						iconside = {
							type = 'select',
							name = L['Icon Position'],
							desc = L['Set the side of the bar that the icon appears on'],
							values = {LEFT = L['Left'], RIGHT = L['Right']},
							arg = {utype, 'iconSide'},
							order = 3,
						},
						buffcolor = {
							type = 'color',
							name = L['Buff Color'],
							desc = L['Set the color of the bars for buffs'],
							get = getColor,
							set = setColor,
							hasAlpha = true,
							arg = {utype, 'buffcolor'},
							order = 4,
						},
						alwaysshownbuffcolor = {
							type = 'color',
							name = L['AlwaysShown buff Color'],
							desc = L['Set the color of the bars for always shown buffs'],
							get = getColor,
							set = setColor,
							hasAlpha = true,
							arg = {utype, 'alwaysshownbuffcolor'},
							order = 5,
						},
						backgroundcolor = {
							type = 'color',
							name = L['Background Color'],
							desc = L['Set the color of the bars background'],
							get = getColor,
							set = setColor,
							hasAlpha = true,
							arg = {utype, 'backgroundcolor'},
							order = 6,
						},
						Debuffs = {
							type = 'group',
							name = L['Debuff Colors'],
							desc = L['Set the color of the bars for debuffs'],
							inline = true,
							order = 7,
							args = {
								Normal = {
									type = 'color',
									name = L['Normal'],
									desc = L['Set color for normal'],
									get = getColor,
									set = setColor,
									order = 1,
									hasAlpha = true,
									arg = {utype, 'debuffcolor'},
								},
								alwaysshown = {
									type = 'color',
									name = L['AlwaysShown'],
									desc = L['Set the color for always shown debuffs'],
									get = getColor,
									set = setColor,
									order = 1,
									hasAlpha = true,
									arg = {utype, 'alwaysshowndebuffcolor'},
								},
								differentColors = {
									type = 'toggle',
									name = L['Different colors'],
									desc = L['Different colors for different debuffs types'],
									order = 2,
									arg = {utype, 'differentColors'},
								},
								Curse = {
									type = 'color',
									name = L['Curse'],
									desc = L['Set color for curses'],
									get = getColor,
									set = setColor,
									order = 5,
									hasAlpha = true,
									arg = {utype, 'Cursecolor'},
									hidden = function() return not DB.Units[utype].differentColors or ClassTimer.backup.differentColors end,
								},
								Poison = {
									type = 'color',
									name = L['Poison'],
									desc = L['Set color for poisons'],
									get = getColor,
									set = setColor,
									order = 6,
									hasAlpha = true,
									arg = {utype, 'Poisoncolor'},
									hidden = function() return not DB.Units[utype].differentColors or ClassTimer.backup.differentColors end,
								},
								Magic = {
									type = 'color',
									name = L['Magic'],
									desc = L['Set color for magics'],
									get = getColor,
									set = setColor,
									order = 7,
									hasAlpha = true,
									arg = {utype, 'Magiccolor'},
									hidden = function() return not DB.Units[utype].differentColors or ClassTimer.backup.differentColors end,
								},
								Disease = {
									type = 'color',
									name = L['Disease'],
									desc = L['Set color for diseases'],
									get = getColor,
									set = setColor,
									order = 8,
									hasAlpha = true,
									arg = {utype, 'Diseasecolor'},
									hidden = function() return not DB.Units[utype].differentColors or ClassTimer.backup.differentColors end,
								},
							},
						},
					},
				},
				Sticky = type == "sticky" and {
					type = 'group',
					name = L['Add Sticky'],
					desc = L['Add a move to be sticky'],
					order = 7,
					args = {},
				} or nil
			},
		}
	end

	local values = {}
	local values2 = {}
	for k in pairs(bars) do
		values[k] = L[k]
		values2[k] = L[k]
		ClassTimer:AddUnitOptions(k)
	end

	ClassTimer:AddUnitOptions('general')
	ClassTimer.options.args.BarSettings.args.EnabledUnits.values = values
	values2['sticky'] = nil
	ClassTimer.options.args.BarSettings.args.AllInOne.args.Units.values = values2
	ClassTimer.options.args.BarSettings.args.AllInOne.args.Owner.values = values2
	local values = nil
	local values2 = nil

    core:RegisterForEvent("VARIABLES_LOADED", function()
    	if type(core.char.ClassTimer) ~= "table" or not next(core.char.ClassTimer) then
    		core.char.ClassTimer = CopyTable(ClassTimer.defaults)
    	end
    	DB = core.char.ClassTimer

    	local validate, timerargs = {}, {}
    	local tbl = ClassTimer:CreateTimers()
    	tbl["Race"] = ClassTimer:Race()

    	for k, v in pairs(tbl) do
    		for i in ipairs(v) do
    			DB.Abilities[v[i]] = true
    		end

    		timerargs[k] = {
    			type = "group",
    			name = L[k],
    			desc = L["Which buffs to show"],
    			order = 4,
    			args = {
    				shown = {
    					type = "multiselect",
    					name = L["Show"],
    					desc = L["Select to show"],
						get = function(_, key) return DB.Abilities[key] end,
						set = function(_, key, value) DB.Abilities[key] = value validate[key] = value and key or nil end,
						values = ClassTimer:List(v),
    				}
    			}
    		}
    	end

		timerargs.Spacer = {
			type = "header",
			order = 1,
			name = L["Timers"]
		}
		timerargs.Extras = {
			type = 'group',
			name = L['Extras'],
			desc = L['Other abilities'],
			order = 10,
			args = {
				Add = {
					type = 'input',
					name = L['Add a custom timer'],
					get = function() return "" end,
					set = function(_, value) DB.Custom[value] = value validate[value] = value end,
					usage = L['<Spell Name in games locale>']
				},
				Remove = {
					type = 'multiselect',
					name = L['Remove a custom timer'],
					get = function() return false end,
					set = function(_, key) DB.Custom[key] = nil validate[key] = nil end,
					values = DB.Custom,
				}
			}
		}
		timerargs.AlwaysShown = {
			type = 'group',
			name = L['AlwaysShown'],
			desc = L['Abilities to track regardless of the caster'],
			order = 11,
			args = {
				Add = {
					type = 'input',
					name = L['Add a timer that is always shown'],
					get = function() return "" end,
					set = function(_, value) DB.AlwaysShown[value] = value validate[value] = value end,
					usage = L['<Spell Name in games locale>']
				},
				Remove = {
					type = 'multiselect',
					name = L['Remove an AlwaysShown timer'],
					get = function() return false end,
					set = function(_, key) DB.AlwaysShown[key] = nil validate[key] = nil end,
					values = DB.AlwaysShown,
				}
			}
		}
		ClassTimer.options.args.Timers = {
			type = 'group',
			name = L['Timers'],
			desc = L['Enable or disable timers'],
			childGroups = 'tab',
			order = 1,
			args = timerargs
		}

		for v in pairs(DB.Abilities) do
			validate[v] = v
		end
		for v in pairs(DB.Custom) do
			validate[v] = v
		end
		for v in pairs(DB.AlwaysShown) do
			validate[v] = v
		end
		-- ClassTimer.options.args.BarSettings.args.sticky.args.Sticky.args.addSticky = {
		-- 	type = 'multiselect',
		-- 	name = L['Add Sticky'],
		-- 	desc = L['Add a move to be sticky'],
		-- 	get =  function(_, v) return DB.Sticky[v] end,
		-- 	order = 5,
		-- 	set = function(_, v, u) DB.Sticky[v] = u end,
		-- 	values = validate
		-- }

		core.options.args.ClassTimer = ClassTimer.options
	end)

	do
		local function sortup(a,b)
				return  a.remaining > b.remaining
		end
		local function sort(a,b)
				return a.remaining < b.remaining
		end
		local function text(text, spell, apps, unit)
			local str = text
			str = gsub(str, '%%s', spell)
			str = gsub(str, '%%u', L[unit])
			str = gsub(str, '%%n', GetUnitName(unit))
			if apps and apps > 1 then
				str = gsub(str, '%%a', apps)
			else
				str = gsub(str, '%%a', '')
			end
			str = gsub(str, '%s%s+', ' ')
			str = gsub(str, '%p%p+', '')
			str = gsub(str, '%s+$', '')
			return str
		end
		local tmp = {}
		local called = false -- prevent recursive calls when new bars are created.
		local stickyset = false
		local whatsMine = {
			player = true,
			pet = true,
			vehicle = true,
		}
		function ClassTimer:GetBuffs(unit, db)
			local currentTime = GetTime()
			if db.buffs then
				local i=1
				while true do
	                local name, _, texture, count, _, duration, endTime, caster = UnitBuff(unit, i)
	                if not name then
						break
					end
	                local isMine = whatsMine[caster]
					if duration and duration > 0 and (DB.Abilities[name] or DB.Custom[name]) and isMine or DB.AlwaysShown[name] then
						local t = new()
						if DB.Units.sticky.enable and DB.Sticky[name] then
							t.startTime = endTime - duration
							t.endTime = endTime
							stickyset = true
							t.unitname = UnitName(unit)
							t.alwaysshown = not ismine and DB.AlwaysShown[name]
							number = sticky[name..t.unitname] or #sticky+1
							sticky[number] = t
							sticky[name..t.unitname] = number
						elseif isMine then
							tmp[#tmp+1] = t
						elseif DB.AlwaysShown[name] then
							t.alwaysshown = true
							tmp[#tmp+1] = t
						end
						t.name = name
						t.unit = unit
						t.remaining = endTime-currentTime
						t.texture = texture
						t.duration = duration
						t.endTime = endTime
						t.count = count
						t.isbuff = true
					end
					i=i+1
				end
			end
			if db.debuffs then
				local i=1
				while true do
	                local name, _, texture, count, debuffType, duration, endTime, caster = UnitDebuff(unit, i)
	                if not name then
						break
					end
	                local isMine = whatsMine[caster]
					if duration and duration > 0 and (DB.Abilities[name] or DB.Custom[name]) and isMine or DB.AlwaysShown[name] then
						local t = new()
						if DB.Units.sticky.enable and DB.Sticky[name] then
							t.startTime = endTime - duration
							t.endTime = endTime
							stickyset = true
							t.unitname = UnitName(unit)
							t.alwaysshown = not ismine and DB.AlwaysShown[name]
							number = sticky[name..t.unitname] or #sticky+1
							sticky[number] = t
							sticky[name..t.unitname] = number
						elseif isMine then
							tmp[#tmp+1] = t
						elseif DB.AlwaysShown[name] then
							t.alwaysshown = true
							tmp[#tmp + 1] = t
						end
						t.name = name
						t.unit = unit
						t.texture = texture
						t.duration = duration
						t.remaining = endTime-currentTime
						t.endTime = endTime
						t.count = count
						t.dispelType = debuffType
					end
					i=i+1
				end
			end
		end
		function ClassTimer:UpdateUnitBars(unit)
			if not bars[unit] then return end
			local db = DB.Units[unit]
			for k, v in pairs(self.backup) do
				if db[k] == nil then
					db[k] = v
				end
			end
			if unlocked[unit] then return end
			if DB.Group[unit] then unit = DB.AllInOneOwner end
			if called then
				return
			end
			called = true
			if db.enable then
				local currentTime = GetTime()
				for k in pairs(tmp) do
					tmp[k] = del(tmp[k])
				end
				self:GetBuffs(unit, db)
				if DB.Group[unit] then
					for k, v in pairs(DB.Group) do
						if v then
							if k ~= 'focus' then
								if not UnitIsUnit(k, unit) then self:GetBuffs(k, db) end
							else
								if not UnitIsUnit(k, unit) and not UnitIsUnit(k, 'target') then self:GetBuffs(k, db) end
							end
						end
					end
				end
				local sortby = db.growup
				if db.reverseSort then
					sortby = not sortby
				end
				table_sort(tmp, sortby and sortup or sort)

				for k,v in ipairs(tmp) do
					local bar = bars[unit][k]

					bar.text:SetText(text(db.bartext, v.name, v.count, v.unit))
					bar.icon:SetTexture(v.texture)
					local startTime, endTime = v.endTime - v.duration, v.endTime
					bar.startTime = startTime
					bar.unit = unit
					bar.duration = v.duration
					bar.endTime = endTime
					bar.isbuff = v.isbuff
					bar.alwaysshown = v.alwaysshown
					if db.reversed then
						bar.reversed = true
					else
						bar.reversed = nil
					end
					if db.sizeEnable then
						if bar.duration < db.sizeMax then
							local width = (bar.duration/db.sizeMax)*db.width
							bar:SetWidth(width)
							bar.timetext:SetWidth(width)
							bar.text:SetWidth(width - db.fontsize * 2.5)
						else
							bar:SetWidth(db.width)
							bar.timetext:SetWidth(db.width)
							bar.text:SetWidth(db.width - db.fontsize * 2.5)
						end
					end
					if not db.showIcons then
						if bar.alwaysshown then
							bar:SetStatusBarColor(unpack(bar.isbuff and db.alwaysshownbuffcolor or db.alwaysshowndebuffcolor))
						elseif bar.isbuff then
							bar:SetStatusBarColor(unpack(db.buffcolor))
						elseif db.differentColors and v.dispelType then
							bar.dispelType = v.dispelType
							bar:SetStatusBarColor(unpack(db[v.dispelType .. 'color']))
						else
							bar:SetStatusBarColor(unpack(db.debuffcolor))
						end
					end
					bar:SetMinMaxValues(startTime, endTime)
					bar:Show()
				end
				for i = #tmp+1, #bars[unit] do
					bars[unit][i]:Hide()
				end
			else
				for _, v in ipairs(bars[unit]) do
					v:Hide()
				end
			end
			if stickyset then
				self:StickyUpdate()
				stickyset = nil
			end
			called = false
		end
		function ClassTimer:StickyUpdate(del)
			local db = DB.Units.sticky
			if unlocked.sticky then return end
			if db.enable then
				if del then
					for k = del, #sticky do
						local frame = bars.sticky[k+1]
						sticky[del] = nil
						if not sticky[k] and sticky[k+1] then
							sticky[k] = sticky[k+1]
							--sticky[frame.name..frame.unitname] = k
							if sticky[k+1] == #sticky then
								sticky[k+1] = nil
							end
						end
					end
				end
				for k,v in ipairs(sticky) do
					local bar = bars.sticky[k]
					bar.text:SetText(text(db.bartext, v.name, v.count, v.unit))
					bar.icon:SetTexture(v.texture)
					bar.startTime = v.startTime
					bar.unit = 'sticky'
					bar.unitname = v.unitname
					bar.duration = v.duration
					bar.sticky = v.sticky
					bar.endTime = v.endTime
					bar.isbuff = v.isbuff
					bar.alwaysshown = v.alwaysshown
					bar.name = v.name
					if db.sizeEnable then
						if bar.duration < db.sizeMax then
							local width = (bar.duration/db.sizeMax)*db.width
							bar:SetWidth(width)
							bar.timetext:SetWidth(width)
							bar.text:SetWidth(width - db.fontsize * 2.5)
						else
							bar:SetWidth(db.width)
							bar.timetext:SetWidth(db.width)
							bar.text:SetWidth(db.width - db.fontsize * 2.5)
						end
					end
					if db.reversed then
						bar.reversed = true
					else
						bar.reversed = nil
					end
					if not db.showIcons then
						if bar.alwaysshown then
							bar:SetStatusBarColor(unpack(bar.isbuff and db.alwaysshownbuffcolor or db.alwaysshowndebuffcolor))
						elseif bar.isbuff then
							bar:SetStatusBarColor(unpack(db.buffcolor))
						elseif db.differentColors and v.dispelType then
							bar.dispelType = v.dispelType
							bar:SetStatusBarColor(unpack(db[v.dispelType .. 'color']))
						else
							bar:SetStatusBarColor(unpack(db.debuffcolor))
						end
					end
					bar:SetMinMaxValues(v.startTime, v.endTime)
					bar:Show()
				end
				for i = #sticky+1, #bars.sticky do
					bars.sticky[i]:Hide()
				end
			else
				for _, v in ipairs(bars.sticky) do
					v:Hide()
				end
			end
		end
	end
	do
		local function apply(unit, i, bar, db)
			local bars = bars[unit]
			local showIcons = db.showIcons
			local spacing = db.spacing
			local backup = ClassTimer.backup

			bar:ClearAllPoints()
			bar:SetStatusBarTexture(LSM:Fetch('statusbar', LSM.OverrideMedia.statusbar or db.texture or backup.texture))
			bar:SetHeight(db.height or backup.height)
			bar:SetScale(db.scale or backup.scale)
			bar:SetAlpha(db.alpha or backup.alpha)
			bar:SetWidth(db.width or backup.width)
			if db.sizeEnable and bar.duration and bar.duration < db.sizeMax then
				local width = (bar.duration/db.sizeMax)*db.width
				bar:SetWidth(width)
				bar.timetext:SetWidth(width)
				bar.text:SetWidth(width - db.fontsize * 2.5)
			else
				bar:SetWidth(db.width or backup.width)
				bar.timetext:SetWidth(db.width or backup.width)
				bar.text:SetWidth((db.width or backup.width) - (db.fontsize or backup.fontsize) * 2.5)
			end
			bar.spark:SetHeight((db.height or backup.height) + 25)
			if showIcons then
				bar:SetStatusBarColor(1, 1, 1, 0)
				bar:SetBackdropColor(1, 1, 1, 0)
				bar.spark:Hide()
				bar.text:SetFont(LSM:Fetch('font', (db.font or backup.font)), db.fontsize or backup.fontsize)
			else
				if not db.showIcons then
					if bar.alwaysshown then
						bar:SetStatusBarColor(unpack(bar.isbuff and db.alwaysshownbuffcolor or db.alwaysshowndebuffcolor))
					elseif bar.isbuff then
						bar:SetStatusBarColor(unpack(db.buffcolor))
					elseif db.differentColors and bar.dispelType then
						bar:SetStatusBarColor(unpack(db[bar.dispelType..'color']))
					else
						bar:SetStatusBarColor(unpack(db.debuffcolor or backup.debuffcolor))
					end
				end
				bar.spark:Show()
				bar:SetBackdropColor(unpack(db.backgroundcolor or backup.backgroundcolor))
			end
			if db.click or unlocked[unit] then
				bar:EnableMouse(true)
			else
				bar:EnableMouse(false)
			end
			if db.reversed then
				bar.reversed = true
			else
				bar.reversed = nil
			end
			if i == 1 then
				if db.x then
					bar:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', db.x, db.y)
				else
					bar:SetPoint('CENTER', UIParent)
				end
			else
				if db.growup then
					bar:SetPoint('BOTTOMLEFT', bars[i-1], 'TOPLEFT', 0, spacing)
				else
					bar:SetPoint('TOPLEFT', bars[i-1], 'BOTTOMLEFT', 0, -1 * spacing)
				end
			end

			local timetext = bar.timetext
			if db.timetext then
				timetext:Show()
				timetext:ClearAllPoints()
				timetext:SetFont(LSM:Fetch('font', db.font), db.fontsize)
				timetext:SetShadowColor( 0, 0, 0, 1)
				timetext:SetShadowOffset( 0.8, -0.8 )
				timetext:SetTextColor(unpack(db.textcolor))
				timetext:SetNonSpaceWrap(false)
				timetext:ClearAllPoints()
				timetext:SetPoint('LEFT', bar, 'LEFT', showIcons and db.iconSide == 'LEFT' and 2 or -2, 0)
				timetext:SetJustifyH(showIcons and db.iconSide == 'LEFT' and 'LEFT' or 'RIGHT')
				bar.tt = true
			else
				timetext:Hide()
				bar.tt = false
			end

			local text = bar.text
			text:SetFont(LSM:Fetch('font', db.font or backup.font), db.fontsize or backup.fontsize)
			if db.nametext and not showIcons then
				text:Show()
				text:ClearAllPoints()
				text:SetShadowColor( 0, 0, 0, 1)
				text:SetShadowOffset( 0.8, -0.8 )
				text:SetTextColor(unpack(db.textcolor or backup.textcolor))
				text:SetNonSpaceWrap(false)
				text:ClearAllPoints()
				text:SetHeight(db.height or backup.height)
				text:SetPoint('LEFT', bar, 'LEFT', 2, 0)
				text:SetJustifyH('LEFT')
			else
				text:Hide()
			end

			local icon = bar.icon
			if db.icons then
				icon:Show()
				icon:SetWidth(db.height or backup.height)
				icon:SetHeight(db.height or backup.height)
				icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
				icon:ClearAllPoints()
				if (db.iconSide or backup.iconSide) == 'LEFT' then
					icon:SetPoint('RIGHT', bar, 'LEFT', 0, 0)
				else
					icon:SetPoint('LEFT', bar, 'RIGHT', 0, 0)
				end
			else
				icon:Hide()
			end
		end
		function ClassTimer:ApplySettings()
			for n, k in pairs(bars) do
				for u, v in pairs(k) do
					apply(n, u, v, DB.Units[n])
				end
			end
		end
	end

	core:RegisterForEvent("UNIT_AURA", function(_, unit)
		ClassTimer:UpdateUnitBars(unit)
	end)

	core:RegisterForEvent("PLAYER_TARGET_CHANGED", function()
		ClassTimer:UpdateUnitBars("target")
	end)
	core:RegisterForEvent("PLAYER_FOCUS_CHANGED", function()
		ClassTimer:UpdateUnitBars("focus")
	end)
	core:RegisterForEvent("PLAYER_PET_CHANGED", function()
		ClassTimer:UpdateUnitBars("pet")
	end)
end)