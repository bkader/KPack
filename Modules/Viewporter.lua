assert(KPack, "KPack not found!")
KPack:AddModule("Viewporter", function(_, core, L)
	if core:IsDisabled("Viewporter") then return end

	local frame = CreateFrame("Frame")

	-- saved variables and defaults
	local DB
	local defaults = {
	    enabled = false,
	    left = 0,
	    right = 0,
	    top = 0,
	    bottom = 0,
	    firstTime = true
	}

	-- needed locales
	local initialized
	local sides = {
		left = "left",
		right = "right",
		top = "top",
		bottom = "bottom",
		bot = "bottom"
	}

	-- module's print function
	local function Print(msg)
	    if msg then
	        core:Print(msg, "Viewporter")
	    end
	end

	-- called everytime we need to make changes to the viewport
	local function Viewporter_Initialize()
		if initialized then return end
	    local left, right, top, bottom = 0, 0, 0, 0
	    if DB.enabled then
	        left = DB.left
	        right = DB.right
	        top = DB.top
	        bottom = DB.bottom
	    end

	    local scale = 768 / UIParent:GetHeight()
	    WorldFrame:SetPoint("TOPLEFT", (left * scale), -(top * scale))
	    WorldFrame:SetPoint("BOTTOMRIGHT", -(right * scale), (bottom * scale))

	    initialized = true
	end

	-- slash commands handler
	local function SlashCommandHandler(msg)
	    local cmd, rest = strsplit(" ", msg, 2)
	    cmd = cmd:lower()
	    rest = rest and rest:trim() or ""

	    if cmd == "toggle" then
	        DB.enabled = not DB.enabled
	        Print(DB.enabled and L["|cff00ff00enabled|r"] or L["|cffff0000disabled|r"])
	        initialized = nil
	        frame:Show()
	    elseif cmd == "enable" or cmd == "on" then
	        DB.enabled = true
	        initialized = nil
	        frame:Show()
	        Print(L["|cff00ff00enabled|r"])
	    elseif cmd == "disable" or cmd == "off" then
	        DB.enabled = false
	        initialized = nil
	        frame:Show()
	        Print(L["|cffff0000disabled|r"])
	    elseif cmd == "reset" or cmd == "default" then
	        wipe(KPackCharDB.Viewporter)
	        KPackCharDB.Viewporter = CopyTable(defaults)
	        DB = KPackCharDB.Viewporter
	        initialized = nil
	        frame:Show()
	        Print(L["module's settings reset to default."])
	    elseif sides[cmd] then
	        local size = tonumber(rest)
	        size = size or 0
	        DB[sides[cmd]] = size
	        initialized = nil
	        frame:Show()
	    else
	        Print(L:F("Acceptable commands for: |caaf49141%s|r", "/vp"))
	        print("|cffffd700toggle|r", L["Toggles viewporter status."])
	        print("|cffffd700enable|r", L["Enables viewporter."])
	        print("|cffffd700disable|r", L["Disables viewporter."])
	        print("|cffffd700reset|r", L["Resets module settings to default."])
	        print("|cffffd700side|r [|cff00ffffn|r]", L["where side is left, right, top or bottom."])
	        print(L:F("|cffffd700Example|r: %s", "/vp bottom 120"))
	        return
	    end

	    Viewporter_Initialize()
	end

	do
	    local function Viewporter_OnUpdate(self, elapsed)
	        if DB.firstTime then
	            DB.firstTime = false
	        end
	        Viewporter_Initialize()
			self:Hide()
	    end

	    core:RegisterCallback("PLAYER_ENTERING_WORLD", function()
			frame:SetScript("OnUpdate", DB.enabled and Viewporter_OnUpdate or nil)
		end)
	end

	-- frame event handler
	core:RegisterCallback("VARIABLES_LOADED", function()
        if type(KPackCharDB.Viewporter) ~= "table" or not next(KPackCharDB.Viewporter) then
            KPackCharDB.Viewporter = CopyTable(defaults)
        end
        DB = KPackCharDB.Viewporter

        SlashCmdList["KPACKVIEWPORTER"] = SlashCommandHandler
        SLASH_KPACKVIEWPORTER1 = "/vp"
        SLASH_KPACKVIEWPORTER2 = "/viewport"
        SLASH_KPACKVIEWPORTER3 = "/viewporter"
    end)
end)