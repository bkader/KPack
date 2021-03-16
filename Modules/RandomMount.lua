--[[ Credits to: Mike Hendricks(AttilaTheFun) ]]
local folder, core = ...

local mod = core.RandomMount or {}
core.RandomMount = mod

local E = core:Events()

-- lua api
local format = string.format
local strlen = string.len
local strsub = string.sub
local strfind = string.find
local strlower = string.lower
local tostring = tostring
local tonumber = tonumber
local pairs, ipairs = pairs, ipairs
local GetTime = GetTime
local tconcat, tinsert, tremove = table.concat, table.insert, table.remove

-- wow api
local GetSpellInfo = GetSpellInfo
local GetWintergraspWaitTime = GetWintergraspWaitTime
local GetNumSkillLines = GetNumSkillLines
local GetSkillLineInfo = GetSkillLineInfo
local GetPlayerMapPosition = GetPlayerMapPosition
local GetNumTitles = GetNumTitles
local GetNumCompanions = GetNumCompanions
local GetNumMacros = GetNumMacros
local GetNumMacroIcons = GetNumMacroIcons
local GetMacroInfo = GetMacroInfo
local GetCompanionInfo = GetCompanionInfo
local GetRealZoneText = GetRealZoneText
local GetMinimapZoneText = GetMinimapZoneText

local ColdWeatherFlying = select(1, GetSpellInfo(54197))

local mountDict = {
    [10789] = {2, "Spotted Frostsaber"},
    [10793] = {2, "Striped Nightsaber"},
    [10795] = {4, "Ivory Raptor"},
    [10796] = {34, "Turquoise Raptor"},
    [10798] = {2, "Obsidian Raptor"},
    [10799] = {34, "Violet Raptor"},
    [10873] = {2, "Red Mechanostrider"},
    [10969] = {2, "Blue Mechanostrider"},
    [13819] = {2, "Warhorse"},
    [15779] = {4, "White Mechanostrider Mod B"},
    [15780] = {2, "Green Mechanostrider"},
    [15781] = {2, "Steel Mechanostrider"},
    [16055] = {4, "Black Nightsaber"},
    [16056] = {4, "Ancient Frostsaber"},
    [16058] = {2, "Primal Leopard"},
    [16059] = {2, "Tawny Sabercat"},
    [16060] = {2, "Golden Sabercat"},
    [16080] = {4, "Red Wolf"},
    [16081] = {4, "Winter Wolf"},
    [16082] = {4, "Palomino"},
    [16083] = {4, "White Stallion"},
    [16084] = {4, "Mottled Red Raptor"},
    [17229] = {4, "Winterspring Frostsaber"},
    [17450] = {4, "Ivory Raptor"},
    [17453] = {2, "Green Mechanostrider"},
    [17454] = {2, "Unpainted Mechanostrider"},
    [17455] = {2, "Purple Mechanostrider"},
    [17456] = {2, "Red and Blue Mechanostrider"},
    [17458] = {2, "Fluorescent Green Mechanostrider"},
    [17459] = {4, "Icy Blue Mechanostrider Mod A"},
    [17460] = {4, "Frost Ram"},
    [17461] = {4, "Black Ram"},
    [17462] = {34, "Red Skeletal Horse"},
    [17463] = {34, "Blue Skeletal Horse"},
    [17464] = {34, "Brown Skeletal Horse"},
    [17465] = {36, "Green Skeletal Warhorse"},
    [17481] = {36, "Rivendare's Deathcharger"},
    [18363] = {2, "Riding Kodo"},
    [18989] = {2, "Gray Kodo"},
    [18990] = {2, "Brown Kodo"},
    [18991] = {4, "Green Kodo"},
    [18992] = {4, "Teal Kodo"},
    [22717] = {4, "Black War Steed"},
    [22718] = {4, "Black War Kodo"},
    [22719] = {4, "Black Battlestrider"},
    [22720] = {4, "Black War Ram"},
    [22721] = {36, "Black War Raptor"},
    [22722] = {36, "Red Skeletal Warhorse"},
    [22723] = {4, "Black War Tiger"},
    [22724] = {36, "Black War Wolf"},
    [23161] = {4, "Dreadsteed"},
    [23214] = {4, "Charger"},
    [23219] = {4, "Swift Mistsaber"},
    [23220] = {4, "Swift Dawnsaber"},
    [23221] = {4, "Swift Frostsaber"},
    [23222] = {4, "Swift Yellow Mechanostrider"},
    [23223] = {4, "Swift White Mechanostrider"},
    [23225] = {4, "Swift Green Mechanostrider"},
    [23227] = {4, "Swift Palomino"},
    [23228] = {4, "Swift White Steed"},
    [23229] = {4, "Swift Brown Steed"},
    [23238] = {4, "Swift Brown Ram"},
    [23239] = {4, "Swift Gray Ram"},
    [23240] = {4, "Swift White Ram"},
    [23241] = {36, "Swift Blue Raptor"},
    [23242] = {36, "Swift Olive Raptor"},
    [23243] = {36, "Swift Orange Raptor"},
    [23246] = {36, "Purple Skeletal Warhorse"},
    [23247] = {4, "Great White Kodo"},
    [23248] = {4, "Great Gray Kodo"},
    [23249] = {4, "Great Brown Kodo"},
    [23250] = {36, "Swift Brown Wolf"},
    [23251] = {36, "Swift Timber Wolf"},
    [23252] = {36, "Swift Gray Wolf"},
    [23338] = {4, "Swift Stormsaber"},
    [23509] = {36, "Frostwolf Howler"},
    [23510] = {4, "Stormpike Battle Charger"},
    [24242] = {4, "Swift Razzashi Raptor"},
    [24252] = {4, "Swift Zulian Tiger"},
    [25953] = {32, "Blue Qiraji Battle Tank"},
    [26054] = {32, "Red Qiraji Battle Tank"},
    [26055] = {32, "Yellow Qiraji Battle Tank"},
    [26056] = {32, "Green Qiraji Battle Tank"},
    [26656] = {4, "Black Qiraji Battle Tank"},
    [28828] = {16, "Nether Drake"},
    [29059] = {4, "Naxxramas Deathcharger"},
    [30174] = {1, "Riding Turtle"},
    [32235] = {8, "Golden Gryphon"},
    [32239] = {8, "Ebon Gryphon"},
    [32240] = {8, "Snowy Gryphon"},
    [32242] = {16, "Swift Blue Gryphon"},
    [32243] = {8, "Tawny Wind Rider"},
    [32244] = {8, "Blue Wind Rider"},
    [32245] = {8, "Green Wind Rider"},
    [32246] = {16, "Swift Red Wind Rider"},
    [32289] = {16, "Swift Red Gryphon"},
    [32290] = {16, "Swift Green Gryphon"},
    [32292] = {16, "Swift Purple Gryphon"},
    [32295] = {16, "Swift Green Wind Rider"},
    [32296] = {16, "Swift Yellow Wind Rider"},
    [32297] = {16, "Swift Purple Wind Rider"},
    [32345] = {16, "Peep the Phoenix Mount"},
    [33630] = {2, "Blue Mechanostrider"},
    [3363] = {16, "Nether Drake"},
    [33660] = {4, "Swift Pink Hawkstrider"},
    [34406] = {2, "Brown Elekk"},
    [34407] = {4, "Great Elite Elekk"},
    [34767] = {4, "Summon Charger"},
    [34769] = {2, "Summon Warhorse"},
    [34790] = {4, "Dark War Talbuk"},
    [34795] = {2, "Red Hawkstrider"},
    [34896] = {4, "Cobalt War Talbuk"},
    [34897] = {4, "White War Talbuk"},
    [34898] = {4, "Silver War Talbuk"},
    [34899] = {4, "Tan War Talbuk"},
    [35018] = {2, "Purple Hawkstrider"},
    [35020] = {2, "Blue Hawkstrider"},
    [35022] = {2, "Black Hawkstrider"},
    [35025] = {4, "Swift Green Hawkstrider"},
    [35027] = {4, "Swift Purple Hawkstrider"},
    [35028] = {4, "Swift Warstrider"},
    [35710] = {2, "Gray Elekk"},
    [35711] = {2, "Purple Elekk"},
    [35712] = {4, "Great Green Elekk"},
    [35713] = {4, "Great Blue Elekk"},
    [35714] = {4, "Great Purple Elekk"},
    [36702] = {4, "Fiery Warhorse"},
    [37015] = {80, "Swift Nether Drake"},
    [39315] = {4, "Cobalt Riding Talbuk"},
    [39316] = {4, "Dark Riding Talbuk"},
    [39317] = {4, "Silver Riding Talbuk"},
    [39318] = {4, "Tan Riding Talbuk"},
    [39319] = {4, "White Riding Talbuk"},
    [39798] = {16, "Green Riding Nether Ray"},
    [39800] = {16, "Red Riding Nether Ray"},
    [39801] = {16, "Purple Riding Nether Ray"},
    [39802] = {16, "Silver Riding Nether Ray"},
    [39803] = {16, "Blue Riding Nether Ray"},
    [40192] = {80, "Ashes of Al'ar"},
    [41252] = {4, "Raven Lord"},
    [41513] = {16, "Onyx Netherwing Drake"},
    [41514] = {16, "Azure Netherwing Drake"},
    [41515] = {16, "Cobalt Netherwing Drake"},
    [41516] = {16, "Purple Netherwing Drake"},
    [41517] = {16, "Veridian Netherwing Drake"},
    [41518] = {16, "Violet Netherwing Drake"},
    [42776] = {2, "Spectral Tiger"},
    [42777] = {6, "Swift Spectral Tiger"},
    [42781] = {4, "Upper Deck - Spectral Tiger Mount"},
    [43688] = {4, "Amani War Bear"},
    [43810] = {16, "Frost Wyrm"},
    [43899] = {2, "Brewfest Ram"},
    [43900] = {4, "Swift Brewfest Ram"},
    [43927] = {16, "Cenarion War Hippogryph"},
    [44151] = {16, "Turbo-Charged Flying Machine"},
    [44153] = {8, "Flying Machine"},
    [44317] = {16, "Merciless Nether Drake"},
    [44744] = {16, "Merciless Nether Drake"},
    [45593] = {4, "Darkspear Raptor"},
    [458] = {2, "Brown Horse"},
    [459] = {2, "Gray Wolf"},
    [46102] = {4, "Venomhide Ravasaur"},
    [46197] = {16, "X-51 Nether-Rocket"},
    [46199] = {16, "X-51 Nether-Rocket X-TREME"},
    [46628] = {4, "Swift White Hawkstrider"},
    [468] = {4, "White Stallion"},
    [47037] = {4, "Swift War Elekk"},
    [470] = {2, "Black Stallion"},
    [471] = {2, "Palamino"},
    [472] = {2, "Pinto"},
    [48025] = {20, "Headless Horseman's Mount"},
    [48027] = {4, "Black War Elekk"},
    [48778] = {4, "Acherus Deathcharger"},
    [48954] = {4, "Swift Zhevra"},
    [49193] = {16, "Vengeful Nether Drake"},
    [49322] = {4, "Swift Zhevra"},
    [49378] = {2, "Brewfest Riding Kodo"},
    [49379] = {4, "Great Brewfest Kodo"},
    [50869] = {2, "Brewfest Kodo"},
    [50870] = {2, "Brewfest Ram"},
    [51412] = {4, "Big Battle Bear"},
    [51960] = {16, "Frostwyrm Mount"},
    [54729] = {24, "Winged Steed of the Ebon Blade"},
    [54753] = {4, "White Polar Bear Mount"},
    [55531] = {4, "Mechano-hog"},
    [5784] = {2, "Felsteed"},
    [578] = {2, "Black Wolf"},
    [579] = {4, "Red Wolf"},
    [580] = {34, "Timber Wolf"},
    [581] = {4, "Winter Wolf"},
    [58615] = {16, "Brutal Nether Drake"},
    [58983] = {6, "Big Blizzard Bear"},
    [59567] = {16, "Azure Drake"},
    [59568] = {16, "Blue Drake"},
    [59569] = {16, "Bronze Drake"},
    [59570] = {16, "Red Drake"},
    [59571] = {16, "Twilight Drake"},
    [59572] = {2, "Black Polar Bear"},
    [59573] = {4, "Brown Polar Bear"},
    [59650] = {16, "Black Drake"},
    [59785] = {4, "Black War Mammoth"},
    [59788] = {4, "Black War Mammoth"},
    [59791] = {4, "Wooly Mammoth"},
    [59793] = {4, "Wooly Mammoth"},
    [59797] = {4, "Ice Mammoth"},
    [59799] = {4, "Ice Mammoth"},
    [59802] = {4, "Grand Ice Mammoth"},
    [59804] = {4, "Grand Ice Mammoth"},
    [59810] = {4, "Grand Black War Mammoth"},
    [59811] = {4, "Grand Black War Mammoth"},
    [59961] = {16, "Red Proto-Drake"},
    [59976] = {80, "Black Proto-Drake"},
    [59996] = {16, "Blue Proto-Drake"},
    [60002] = {16, "Time-Lost Proto-Drake"},
    [60021] = {80, "Plagued Proto-Drake"},
    [60024] = {80, "Violet Proto-Drake"},
    [60025] = {16, "Albino Drake"},
    [60114] = {4, "Armored Brown Bear"},
    [60116] = {4, "Armored Brown Bear"},
    [60118] = {4, "Black War Bear"},
    [60119] = {4, "Black War Bear"},
    [60136] = {4, "Grand Caravan Mammoth"},
    [60140] = {4, "Grand Caravan Mammoth"},
    [60424] = {4, "Mekgineer's Chopper"},
    [61229] = {16, "Armored Snowy Gryphon"},
    [61230] = {16, "Armored Blue Wind Rider"},
    [61294] = {16, "Green Proto-Drake"},
    [61309] = {16, "Magnificent Flying Carpet"},
    [61425] = {4, "Traveler's Tundra Mammoth"},
    [61442] = {16, "Swift Mooncloth Carpet"},
    [61444] = {16, "Swift Shadoweave Carpet"},
    [61446] = {16, "Swift Spellfire Carpet"},
    [61447] = {4, "Traveler's Tundra Mammoth"},
    [61451] = {8, "Flying Carpet"},
    [61465] = {4, "Grand Black War Mammoth"},
    [61467] = {4, "Grand Black War Mammoth"},
    [61469] = {4, "Grand Ice Mammoth"},
    [61470] = {4, "Grand Ice Mammoth"},
    [61996] = {16, "Blue Dragonhawk"},
    [61997] = {16, "Red Dragonhawk"},
    [62048] = {16, "Black Dragonhawk Mount"},
    [63232] = {4, "Stormwind Steed"},
    [63636] = {4, "Ironforge Ram"},
    [63637] = {4, "Darnassian Nightsaber"},
    [63638] = {4, "Gnomeregan Mechanostrider"},
    [63639] = {4, "Exodar Elekk"},
    [63640] = {4, "Orgrimmar Wolf"},
    [63641] = {4, "Thunder Bluff Kodo"},
    [63642] = {4, "Silvermoon Hawkstrider"},
    [63643] = {4, "Forsaken Warhorse"},
    [63796] = {80, "Mimiron's Head"},
    [63844] = {16, "Argent Hippogryph"},
    [63956] = {80, "Ironbound Proto-Drake"},
    [63963] = {80, "Rusted Proto-Drake"},
    [64656] = {32, "Blue Skeletal Warhorse"},
    [64657] = {2, "White Kodo"},
    [64658] = {2, "Black Wolf"},
    [64659] = {4, "Venomhide Ravasaur"},
    [64731] = {2, "Sea Turtle"},
    [64927] = {16, "Deadly Gladiator's Frostwyrm"},
    [64977] = {2, "Black Skeletal Horse"},
    [64987] = {6, "Big Blizzard Bear [PH]"},
    [65636] = {4, "Swift Moonsaber"},
    [65637] = {4, "Great Red Elekk"},
    [65638] = {4, "Swift Moonsaber"},
    [65639] = {4, "Swift Red Hawkstrider"},
    [65640] = {4, "Swift Gray Steed"},
    [65641] = {4, "Great Golden Kodo"},
    [65642] = {4, "Turbostrider"},
    [65643] = {4, "Swift Violet Ram"},
    [65644] = {4, "Swift Purple Raptor"},
    [65645] = {4, "White Skeletal Warhorse"},
    [65646] = {4, "Swift Burgundy Wolf"},
    [65917] = {4, "Magic Rooster"},
    [66087] = {16, "Silver Covenant Hippogryph"},
    [66088] = {16, "Sunreaver Dragonhawk"},
    [66090] = {4, "Quel'dorei Steed"},
    [66091] = {4, "Sunreaver Hawkstrider"},
    [66122] = {4, "Magic Rooster"},
    [66123] = {4, "Magic Rooster"},
    [66124] = {4, "Magic Rooster"},
    [6648] = {2, "Chestnut Mare"},
    [6653] = {34, "Dire Wolf"},
    [6654] = {34, "Brown Wolf"},
    [66846] = {4, "Ochre Skeletal Warhorse"},
    [66847] = {2, "Striped Dawnsaber"},
    [66906] = {4, "Argent Charger"},
    [67466] = {4, "Argent Warhorse"},
    [6777] = {2, "Gray Ram"},
    [68056] = {4, "Swift Horde Wolf"},
    [68057] = {4, "Swift Alliance Steed"},
    [6896] = {4, "Black Ram"},
    [6897] = {2, "Blue Ram"},
    [6898] = {2, "White Ram"},
    [6899] = {2, "Brown Ram"},
    [69395] = {80, "Onyxian Drake"},
    [71342] = {94, "Big Love Rocket"},
    [72286] = {22, "Invincible"},
    [72807] = {80, "Icebound Frostbrood Vanquisher"},
    [72808] = {80, "Bloodbathed Frostbrood Vanquisher"},
    [73313] = {22, "Crimson Deathcharger"},
    [75596] = {16, "Frosty Flying Carpet"},
    [75614] = {94, "Celestial Steed"},
    [75973] = {80, "X-53 Touring Rocket"},
    [8394] = {2, "Striped Frostsaber"},
    [8395] = {34, "Emerald Raptor"},
    [8980] = {2, "Skeletal Horse"},
}

--Saved Variables
local debug = false --display debug info if enabled
local debug2 = false --Display debug info on all mounts
local notWanted = {} --Mounts that are not wanted to be summoned
local removeMount = false --Enable or disable notWanted mounts
local epicfly = true --Enable or disable epic flying mounts
local epicride = true --Enable or disable epic riding mounts
local threeten = false --Enable or disable only summoning of 310% speed mounts
local locationChk = true --enable or disable specific mounts in special locations
local locations = {} --locations to summon specific mounts(specialMounts)
local specialMounts = {} --special mounts to summon if in a specific location
local rndTitle = false --Randomly change the title when summoning a mount
local safeFly = false --Safe flying dismount if flying
local macroIcon = false --Update the macro icon with last summoned mount
local zones = {} --Contains the list of location filters
local threeTenSummonable = false --The user has 310% mounts

--names to check for cold weather flying
local zoneIndex = {
    "Howling Fjord",
    "Borean Tundra",
    "Dragonblight",
    "Grizzly Hills",
    "Zul'Drak",
    "Sholazar Basin",
    "The Storm Peaks",
    "Crystalsong Forest",
    "Icecrown",
    "Wintergrasp",
    "Coldarra",
    "The Frozen Sea"
}

local nosummonlist = {} --Stores the last few mounts summoned so it won't summon it again
local lastTime = GetTime() --Safe flying last time that dismount was called

--bindings
BINDING_HEADER_KPACKRANDOMMOUNT = "|cff69ccf0K|r|caaf49141Pack|r Random Mount"
BINDING_NAME_KPACKRANDOMMOUNT_REG = "Auto Summon"
BINDING_NAME_KPACKRANDOMMOUNT_RIDING = "Summon Riding"
BINDING_NAME_KPACKRANDOMMOUNT_FLYING = "Summon Flying"

local function Print(msg)
    if msg then
        core:Print(msg, "RandomMount")
    end
end

local function PrintSummon(color, creatureName, r, ridingSK, creatureDict, zoneText, canFly, creatureSpellID, mountNum)
    canFly = tostring(canFly)
    print(format("|c%s%s - Mnt#:%s - Skill: %s - type:%s - %s - %s - flyZone:%s - cID:%s - cond:%s|r", color, creatureName, r, ridingSK, creatureDict, zoneText, GetMinimapZoneText(), canFly, creatureSpellID, mountNum)
    )
end

local function CanFlyHere()
    -- Check for flyable area
    if not IsFlyableArea() then
        return (false)
    end

    local coldWeather = IsUsableSpell(ColdWeatherFlying)

    -- Check for Dalaran
    if GetRealZoneText() == "Dalaran" then
        if coldWeather then
            local posX, posY = GetPlayerMapPosition("player")
            if GetMinimapZoneText() == "Krasus' Landing" then
                return (true)
            elseif GetMinimapZoneText() == "The Underbelly" then
                if posX <= 0.3 then
                    return (true)
                end
            elseif GetMinimapZoneText() == "The Violet Citadel" then
                if (posX - 0.24) ^ 2 + (posY - 0.39) ^ 2 < 0.9 then
                    return (true)
                end
            elseif (posX - 0.87) ^ 2 + (posY - 0.62) ^ 2 < 0.008 then
                return (true)
            elseif (posX - 0.47) ^ 2 + (posY - 0.42) ^ 2 < 0.002 then
                return (true)
            elseif (posX - 0.47) ^ 2 + (posY - 0.38) ^ 2 < 0.002 then
                return (true)
            end
        end
        return (false)
    end
    -- Check for Wintergrasp
    if GetRealZoneText() == "Wintergrasp" and not GetWintergraspWaitTime() then
        return (false)
    end
    -- Northrend check
    local zoneText = GetRealZoneText()
    for i, zone in ipairs(zoneIndex) do
        if zoneText == zone then
            if coldWeather then
                return (true)
            end
            return (false)
        end
    end

    return (true)
end

local function GetRidingSkill()
    --get the current riding skill
    for skillIndex = 1, GetNumSkillLines() do
        local skillName, isHeader, _, skillRank = GetSkillLineInfo(skillIndex)
        if isHeader == nil then
            if skillName == "Riding" then
                return (skillRank)
            end
        end
    end
    return (0)
end

local function seaTurtle()
    for i = 1, GetNumCompanions("MOUNT"), 1 do
        local _, _, creatureSpellID = GetCompanionInfo("MOUNT", i)
        if creatureSpellID == 64731 then --Turtle: 64731 dire wolf: 6653
            return i
        end
    end
    return -1
end

local function HasZoneMounts(flying, qiraji, searchMount, search)
    local hasThreeTenMounts = false
    --check to see if special zone mounts are learned and process search
    for i = 1, GetNumCompanions("MOUNT"), 1 do
        local _, creatureName, creatureSpellID = GetCompanionInfo("MOUNT", i)
        if search ~= "" then
            if strfind(strlower(creatureName), strlower(search)) then
                tinsert(searchMount, i)
            end
        end
        local chk = true
        if strfind(creatureName, "Qiraji") then
            chk = true
            for n, notW in ipairs(notWanted) do
                if strfind(strlower(creatureName), strlower(notW)) then
                    chk = false
                    break
                end
            end
            if chk then
                tinsert(qiraji, i)
            end
        else
            if mountDict[creatureSpellID] then
                if ((mountDict[creatureSpellID][1] / 8) % 2) >= 1 or ((mountDict[creatureSpellID][1] / 16) % 2) >= 1 then
                    tinsert(flying, i)
                end
            else
                Print(creatureName .. " " .. creatureSpellID .. " not in table, please report on curse.com.")
            end
        end
        if mountDict[creatureSpellID] and ((mountDict[creatureSpellID][1] / 64) % 2) >= 1 then
            hasThreeTenMounts = true
        end
    end
    if hasThreeTenMounts then
        threeTenSummonable = true
    end
    return flying, qiraji, searchMount
end

local function lfmChk(creatureName)
    if locationChk then
        for j, k in ipairs(specialMounts) do
            if strfind(strlower(creatureName), strlower(k)) then
                return true
            end
        end
    end
    return false
end

-- from http://lua-users.org/wiki/SplitJoin  by PeterPrade
local function splitString(delimiter, text)
    local list = {}
    local pos = 1
    if strfind("", delimiter, 1) then -- this would result in endless loops
        error("delimiter matches empty string!")
    end
    while 1 do
        local first, last = strfind(text, delimiter, pos)
        if first then -- found?
            tinsert(list, strsub(text, pos, first - 1))
            pos = last + 1
        else
            tinsert(list, strsub(text, pos))
            break
        end
    end
    return list
end

local function AddLocF(info)
    if strlen(info) > 0 then
        local i = strfind(info, ":")
        local locVar = strsub(info, 0, i - 1)
        local mntVar = splitString(",", strsub(info, i + 1))
        if not zones[strlower(locVar)] then
            zones[strlower(locVar)] = {}
        end
        for _, v in ipairs(mntVar) do
            local found = false
            for n, item in ipairs(zones[strlower(locVar)]) do
                if v == item then
                    Print(v .. " already added.")
                    found = true
                    break
                end
            end
            if not found then
                tinsert(zones[strlower(locVar)], v)
            end
        end
        Print("When in " .. strlower(locVar) .. " mounts with " .. tconcat(zones[strlower(locVar)], ",") .. " will be summoned.")
    end
end

local function printLocF()
    Print("Location Mount database", "FFff00ff")
    for i, v in pairs(zones) do
        Print(i .. ":")
        for j, w in ipairs(zones[i]) do
            Print("       " .. w)
        end
    end
end

local function removeLocF(info)
    if strlen(info) > 0 then
        local i = strfind(info, ":")
        --if : not found then remove zone table
        if not i then
            Print("Zone " .. info .. " is no longer filtered.")
            zones[info] = nil
        else
            local locVar = strsub(info, 0, i - 1)
            local mntVar = splitString(",", strsub(info, i + 1))
            for _, v in ipairs(mntVar) do
                local found = false
                for n, item in ipairs(zones[locVar]) do
                    if v == item then
                        Print(v .. " removed from " .. locVar .. ".")
                        tremove(zones[locVar], n)
                        found = true
                        break
                    end
                end
                if not found then
                    Print(v .. " not found in " .. locVar .. ".")
                end
            end
            if #zones[locVar] == 0 then
                Print(locVar .. " removed because it has no mounts.")
                zones[locVar] = nil
            end
        end
    end
    -- if : found then remove zone table elements, not entire table, if table is empty place * to signify empty
end

local function TestMount(r, ridingSK, zoneText, canFly, flying, qiraji, searchMount, debug, inLocation, repeatChk, zoneChk)
    local _, creatureName, creatureSpellID = GetCompanionInfo("MOUNT", r)
    local mv
    if mountDict[creatureSpellID] then
        mv = mountDict[creatureSpellID][1]
        if mv then
            --Remove Mount processing
            if removeMount then
                for n, notW in ipairs(notWanted) do
                    if strfind(strlower(creatureName), strlower(notW)) or creatureSpellID == tonumber(notW) then
                        return false
                    end
                end
            end
            --Zone Checking
            if locationChk and zoneChk then
                realZone = GetRealZoneText()
                miniMapZone = GetMinimapZoneText()
                local found = false
                if zones[strlower(miniMapZone)] then
                    zoneChk = false
                    for i, tpe in ipairs(zones[strlower(miniMapZone)]) do
                        if strfind(strlower(creatureName), strlower(tpe)) or tpe == "*" then
                            zoneChk = true
                            found = true
                            if debug then
                                Print(tpe .. " : " .. creatureName .. " is found")
                            end
                            break
                        end
                    end
                end
                if zones[strlower(realZone)] then
                    if not found then
                        zoneChk = false
                        for i, tpe in ipairs(zones[strlower(realZone)]) do
                            if strfind(strlower(creatureName), strlower(tpe)) or tpe == "*" then
                                zoneChk = true
                                if debug then
                                    Print(tpe .. " : " .. creatureName .. " is found")
                                end
                                break
                            end
                        end
                    end
                end
                if not zoneChk then
                    return false
                end
            end
            --Repeat Mount check
            if repeatChk then
                for i, m in ipairs(nosummonlist) do
                    if m == r then
                        return false
                    end
                end
            end
            --flying mounts
            if canFly and #flying > 0 and ridingSK >= 225 then
                --zone specific mounts
                if ridingSK >= 300 and ((mv / 16) % 2) >= 1 and epicfly then
                    if #searchMount > 0 then
                        for i, s in ipairs(searchMount) do
                            if r == s then
                                if debug then
                                    PrintSummon("FF00ffff", creatureName, r, ridingSK, mountDict[creatureSpellID][1], zoneText, canFly, creatureSpellID, 12)
                                end
                                return true
                            end
                        end
                    elseif inLocation then
                        if lfmChk(creatureName) then
                            if debug then
                                PrintSummon("FF00ffff", creatureName, r, ridingSK, mountDict[creatureSpellID][1], zoneText, canFly, creatureSpellID, 11)
                            end
                            return true
                        end
                    else
                        --threeten
                        if threeten and ((mv / 64) % 2) >= 1 and threeTenSummonable then
                            if debug then
                                PrintSummon("FF00ffff", creatureName, r, ridingSK, mountDict[creatureSpellID][1], zoneText, canFly, creatureSpellID, 13)
                            end
                            return true
                        elseif threeten and threeTenSummonable then
                            return false
                        end
                        if debug then
                            PrintSummon("FF00ffff", creatureName, r, ridingSK, mountDict[creatureSpellID][1], zoneText, canFly, creatureSpellID, 10)
                        end
                        return true
                    end
                elseif (ridingSK == 225 or not epicfly) and ((mv / 8) % 2) >= 1 then
                    if #searchMount > 0 then
                        for i, s in ipairs(searchMount) do
                            if r == s then
                                if debug then
                                    PrintSummon("FF00ffff", creatureName, r, ridingSK, mountDict[creatureSpellID][1], zoneText, canFly, creatureSpellID, 22)
                                end
                                return true
                            end
                        end
                    elseif inLocation then
                        if lfmChk(creatureName) then
                            if debug then
                                PrintSummon("FF00ffff", creatureName, r, ridingSK, mountDict[creatureSpellID][1], zoneText, canFly, creatureSpellID, 21)
                            end
                            return true
                        end
                    else
                        if debug then
                            PrintSummon("FF00ffff", creatureName, r, ridingSK, mountDict[creatureSpellID][1], zoneText, canFly, creatureSpellID, 20)
                        end
                        return true
                    end
                end
            elseif zoneText == "Ahn'Qiraj" and #qiraji > 0 then
                --Regular Mounts
                if ridingSK >= 150 and ((mv / 32) % 2) >= 1 then
                    if #searchMount > 0 then
                        for i, s in ipairs(searchMount) do
                            if r == s then
                                if debug then
                                    PrintSummon("FF00ffff", creatureName, r, ridingSK, mountDict[creatureSpellID][1], zoneText, canFly, creatureSpellID, 37)
                                end
                                return true
                            end
                        end
                    elseif inLocation then
                        if lfmChk(creatureName) then
                            if debug then
                                PrintSummon("FF00ffff", creatureName, r, ridingSK, mountDict[creatureSpellID][1], zoneText, canFly, creatureSpellID, 36)
                            end
                            return true
                        end
                    elseif strfind(creatureName, "Qiraji") then
                        if debug then
                            PrintSummon("FF00ffff", creatureName, r, ridingSK, mountDict[creatureSpellID][1], zoneText, canFly, creatureSpellID, 35)
                        end
                        return true
                    end
                end
            else
                if ridingSK >= 150 and ((mv / 4) % 2) >= 1 and epicride then
                    if #searchMount > 0 then
                        for i, s in ipairs(searchMount) do
                            if r == s then
                                if debug then
                                    PrintSummon("FF00ffff", creatureName, r, ridingSK, mountDict[creatureSpellID][1], zoneText, canFly, creatureSpellID, 52)
                                end
                                return true
                            end
                        end
                    elseif inLocation then
                        if lfmChk(creatureName) then
                            if debug then
                                PrintSummon("FF00ffff", creatureName, r, ridingSK, mountDict[creatureSpellID][1], zoneText, canFly, creatureSpellID, 51)
                            end
                            return true
                        end
                    else
                        if debug then
                            PrintSummon("FF00ffff", creatureName, r, ridingSK, mountDict[creatureSpellID][1], zoneText, canFly, creatureSpellID, 50)
                        end
                        return true
                    end
                elseif (ridingSK == 75 or not epicride) and ((mv / 2) % 2) >= 1 then
                    if #searchMount > 0 then
                        for i, s in ipairs(searchMount) do
                            if r == s then
                                if debug then
                                    PrintSummon("FF00ffff", creatureName, r, ridingSK, mountDict[creatureSpellID][1], zoneText, canFly, creatureSpellID, 62)
                                end
                                return true
                            end
                        end
                    elseif inLocation then
                        if lfmChk(creatureName) then
                            if debug then
                                PrintSummon("FF00ffff", creatureName, r, ridingSK, mountDict[creatureSpellID][1], zoneText, canFly, creatureSpellID, 61)
                            end
                            return true
                        end
                    else
                        if debug then
                            PrintSummon("FF00ffff", creatureName, r, ridingSK, mountDict[creatureSpellID][1], zoneText, canFly, creatureSpellID, 60)
                        end
                        return true
                    end
                end
            end
            if debug2 then
                PrintSummon("FFffff99", creatureName, r, ridingSK, mountDict[creatureSpellID][1], zoneText, canFly, creatureSpellID, 00)
            end
        end
    end
end

local function randomSudo(max)
    local oldrandom = math.random
    local randomtable
    math.random = function()
        if randomtable == nil then
            randomtable = {}
            for i = 1, max do
                randomtable[i] = oldrandom()
            end
        end
        local x = oldrandom()
        local i = 1 + math.floor(max * x)
        x, randomtable[i] = randomtable[i], x
        return x
    end
end

local function KPack_FindMount(arg1)
    local s = 0
    local r
    local qiraji = {}
    local flying = {}
    local search = ""
    local searchMount = {}
    local zoneText = GetRealZoneText()
    local zoneMounts = 2
    local canFly
    local ridingSK = GetRidingSkill()
    local inLocation = false --Used to check for location

    if arg1 == "riding" then
        canFly = false
    elseif arg1 == "help" then
        Print("Random Mount V0.9.84 optional flags:")
        Print("mnt: rmount: Will summon riding/flying mounts in the appropriate areas. mnt and rmount are interchangeable")
        Print("riding: Summons riding mounts in flying areas")
        Print("flying: Attempt to summon a flying mount")
        Print("help: Display help")
        Print("% (search Term): Summons a mount based on specified search term \rexample: to summon a skeletal warhorse type: /mnt skeletal")
        Print("epicfly: Toggle summoning of epic and 310% flying mounts")
        Print("epicride: Toggle summoning of epic riding mounts")
        Print("310: Toggle only summoning of 310% speed mounts")
        Print("config: Prints the current configuration")
        Print("rfilter: Toggle mount filtering")
        Print("safefly: Toggle double click to dismount while flying")
        Print("rfilters: List current filters")
        Print("locfilter: Toggle filter to summon only specific mounts in specific locations")
        Print("addloc % (zone:mount name1, mount name2, ...): Add locations and mounts to location checking. Separate mounts with commas. Use * as a wildcard to specify all mounts.")
        Print("removeloc % (zone:mount name1, mount name2, ...): Removes locations and mounts from location checking. Separate mounts with commas.")
        Print("loctable: Print the current location filtering table.")
        Print("clearloc: Clears location filters")
        Print("remove %: Remove all mounts matching % if rfilter is enabled")
        Print("clear: Clears all filters")
        Print("clearrem: Clears the mount removal table")
        Print("whereami: Prints your zone and mini-map zone, and map coordinates.")
        Print("title: Enable or disable random title change.")
        Print("icon: Enable or disable changing random mount macro icons to the last summoned mount.")
        Print("oculus: Create a macro that will summon the drakes in The Oculus if you have them in your inventory.")
        Print("druid: Create a macro for druids that will cancel your form before trying to summon a mount.")
        Print("debug: Toggle debug printing for posting error messages")
        Print("No Flag: Summon a appropriate mount for the area")
        return
    elseif arg1 == "config" then
        if debug then
            Print("Debug: Enabled")
        else
            Print("Debug: Disabled")
        end
        if removeMount then
            Print("Mounts filtered: " .. tconcat(notWanted, ", "))
        else
            Print("Mount Removal Disabled.")
        end
        if epicfly then
            Print("Epic flying enabled.")
        else
            Print("Epic flying disabled.")
        end
        if epicride then
            Print("Epic riding enabled.")
        else
            Print("Epic riding disabled.")
        end
        if threeten then
            Print("Only summons 310% speed mounts.")
        else
            Print("310% mounts considered Epic.")
        end
        if safeFly then
            Print("Safe flying enabled. Double click to dismount while flying")
        else
            Print("Safe flying disabled.")
        end
        if rndTitle then
            Print("Random title enabled.")
        else
            Print("Random title disabled.")
        end
        if macroIcon then
            Print("Icon changing enabled.")
        else
            Print("Icon changing disabled.")
        end
        return
    elseif arg1 == "whereami" then
        local posX, posY = GetPlayerMapPosition("player")
        Print("You are in " .. GetRealZoneText() .. ", " .. GetMinimapZoneText() .. ", " .. posX .. ", " .. posY)
        return
    elseif arg1 == "debug" then
        if debug == false then
            debug = true
            Print("Debug information enabled.")
        elseif debug == true then
            debug = false
            Print("Debug information disabled.")
        end
        return
    elseif arg1 == "oculus" then
        Print("Macro is being created")
        local macroId =
            CreateMacro("RndOclus", 12, '/script if (GetItemCount(37859)+GetItemCount(37860)+GetItemCount(37815)==0) then KPack.RandomMount:FindMount(""); end\n/use item:37859\n/use item:37860\n/use item:37815\n#/mnt', nil, 1)
        return
    elseif arg1 == "druid" then
        Print("Macro is being created")
        local macroId = CreateMacro("RndDruid", 12, "/cancelform\n/rmount", nil, 1)
        return
    elseif arg1 == "debug2" then
        if debug2 == false then
            debug2 = true
            debug = true
            Print("Debug2 information enabled. Your chat window will be spamed.")
        elseif debug2 == true then
            debug2 = false
            Print("Debug2 information disabled.")
        end
        return
    elseif arg1 == "epicfly" then
        if epicfly == false then
            epicfly = true
            Print("Epic flying enabled.")
        elseif epicfly == true then
            epicfly = false
            Print("Epic flying disabled.")
        end
        return
    elseif arg1 == "locfilter" then
        if locationChk == false then
            locationChk = true
            Print("Location mount filtering enabled.")
        elseif locationChk == true then
            locationChk = false
            Print("Location mount filtering disabled.")
        end
        return
    elseif arg1 == "epicride" then
        if epicride == false then
            epicride = true
            Print("Epic riding enabled.")
        elseif epicride == true then
            epicride = false
            Print("Epic riding disabled.")
        end
        return
    elseif arg1 == "310" then
        if threeten == false then
            threeten = true
            Print("Only summons 310% speed mounts.")
        elseif threeten == true then
            threeten = false
            Print("Summons 310% speed mounts if epicfly is enabled.")
        end
        return
    elseif arg1 == "rfilter" then
        if removeMount == false then
            removeMount = true
            Print("Mount removal enabled.")
        elseif removeMount == true then
            removeMount = false
            Print("Mount removal disabled.")
        end
        return
    elseif arg1 == "safefly" then
        if safeFly == false then
            safeFly = true
            Print("Safe flying enabled. Double click to dismount while flying")
        elseif safeFly == true then
            safeFly = false
            Print("Safe flying disabled.")
        end
        return
    elseif arg1 == "rfilters" then
        if removeMount then
            Print("Mounts filtered: " .. tconcat(notWanted, ", "))
        else
            Print("Mount removal disabled.")
        end
        return
    elseif arg1 == "title" then
        if rndTitle == false then
            rndTitle = true
            Print("Random title enabled.")
        elseif rndTitle == true then
            rndTitle = false
            Print("Random title disabled.")
        end
        return
    elseif arg1 == "icon" then
        if macroIcon == false then
            macroIcon = true
            Print("Icon changing enabled.")
        elseif macroIcon == true then
            macroIcon = false
            Print("Icon changing disabled.")
        end
        return
    elseif arg1 == "clear" then
        notWanted = {}
        zones = {}
        --specialMounts = {}
        Print("All tables cleared.")
        return
    elseif arg1 == "clearrem" then
        notWanted = {}
        Print("Remove mount table cleared.")
        return
    elseif arg1 == "clearloc" then
        zones = {}
        Print("Special location table cleared.")
        return
    elseif arg1 == "loctable" then
        printLocF()
        return
    elseif strfind(arg1, "removeloc") then
        Print(strsub(arg1, 11))
        if strlen(strsub(arg1, 11)) > 0 then
            removeLocF(strsub(arg1, 11))
        end
        return
    elseif arg1 == "flying" then
        canFly = true
    elseif strfind(arg1, "addloc") then
        if strlen(strsub(arg1, 8)) > 0 then
            AddLocF(strsub(arg1, 8))
        end
        return
    elseif strfind(arg1, "remove") then
        local found = false
        if strlen(strsub(arg1, 8)) > 0 then
            for n, notW in ipairs(notWanted) do
                if strsub(arg1, 8) == notW then
                    Print(strsub(arg1, 8) .. " already added.")
                    found = true
                    break
                end
            end
            --Print(tconcat(notWanted, ", "))
            if not found then
                Print("Mounts matching " .. strsub(arg1, 8) .. " will no longer be summoned.")
                tinsert(notWanted, strsub(arg1, 8))
            end
        end
        return
    elseif arg1 == "rnd" then
        r = randomSudo(GetNumCompanions("MOUNT"))
        Print(r)
    else
        search = arg1
        canFly = CanFlyHere()
    end
    if IsMounted() then
        if safeFly and IsFlying() then
            local curTime = GetTime()
            if curTime < (lastTime + 0.5) then
                Dismount()
                return
            else
                lastTime = curTime
                return
            end
        else
            Dismount()
            return
        end
    end
    if UnitInVehicle(UnitName("player")) then
        VehicleExit()
        return
    end
    if rndTitle then
        local titles = {}
        for i = 1, GetNumTitles(), 1 do
            if IsTitleKnown(i) == 1 then
                tinsert(titles, i)
            end
        end
        SetCurrentTitle(titles[random(#titles)])
    end
    local _, _, mount = HasZoneMounts(flying, qiraji, searchMount, search)
    if search ~= "" and next(mount) == nil then
        Print("No matching mount found.")
        return
    end
    local repeatChk = true
    local runawayChk = 0
    numCompanions = GetNumCompanions("MOUNT")
    --if there are less than 10 mounts no real reason to check for repeats
    if numCompanions < 10 then
        repeatChk = false
    end
    local zoneChk = true
    if ridingSK >= 75 then
        r = seaTurtle()
        if IsSwimming() then
            runawayChk = 500
        --Print("Is swiming")
        end
        --Print("pre if" .. r)
        if r ~= -1 and search == "" and runawayChk == 500 then
            --Print("sea turtle")
        else
            repeat
                r = random(numCompanions)
                s = TestMount(r, ridingSK, zoneText, canFly, flying, qiraji, searchMount, debug, inLocation, repeatChk, zoneChk)
                runawayChk = runawayChk + 1 --No mounts found after 1000 trys so just quit otherwise it will lock up
                if runawayChk > 1000 then
                    s = true
                elseif runawayChk > 750 then
                    zoneChk = false
                elseif runawayChk > 500 then --no acceptable mounts found in the first 500 trys so turn off can fly
                    canFly = false
                elseif repeatChk and runawayChk > 250 then --Turn off repeatChk if no usable mounts are found within the first 250 checks
                    repeatChk = false
                end
            until s == true
        end
        if runawayChk > 1000 then
            Print("No usable mounts found")
        elseif r == -1 then
            --Print("sea turtle 1")
            return
        else
            if debug2 then
                Print("Runaway Check: " .. runawayChk .. " Number of mounts:" .. numCompanions, "FFffff99")
            end
            if InCombatLockdown() then
                if debug then
                    Print("You are in combat.")
                end
                return
            end
            CallCompanion("MOUNT", r)
            --Repeat Mount check
            tinsert(nosummonlist, r)
            if #nosummonlist > 5 then
                tremove(nosummonlist, 1)
            end
            -- Change Macro Icons
            if macroIcon then
                local _, _, _, icon = GetCompanionInfo("MOUNT", r)
                local numglobal, numperchar = GetNumMacros()
                -- loop to change the icons of macros that are calling /rmount
                for i = 1, numglobal, 1 do
                    -- Get iconIndex info
                    local numIcons = GetNumMacroIcons()
                    for j = 1, numIcons do
                        if strlower(GetMacroIconInfo(j)) == strlower(icon) then
                            iconIndex = j
                            break
                        end
                    end
                    local name, texture, macrobody, localVar = GetMacroInfo(i)
                    if
                        strfind(strlower(macrobody), strlower("/rmount")) or
                            strfind(strlower(macrobody), strlower("/mnt"))
                     then
                        --Print( texture .. " " .. icon)
                        EditMacro(i, nil, iconIndex)
                    end
                end
            end
        end
    end
end

function mod:FindMount(arg1)
    return KPack_FindMount(arg1)
end

function E:ADDON_LOADED(name)
    if name == folder then
        self:UnregisterEvent("ADDON_LOADED")
        SlashCmdList["KPACKRANDOMMOUNT"] = KPack_FindMount
        SLASH_KPACKRANDOMMOUNT1 = "/mnt"
        SLASH_KPACKRANDOMMOUNT2 = "/rmount"
    end
end