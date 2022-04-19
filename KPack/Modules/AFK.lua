local core = KPack
if not core then return end
core:AddModule("AFK", "Shows a timer window whenever you go AFK.", function(L)
	if core:IsDisabled("AFK") or core.ElvUI then return end

	local _CreateFrame = CreateFrame
	local _UnitIsAFK = UnitIsAFK
	local _SendChatMessage = SendChatMessage
	local _GetGameTime = GetGameTime
	local _floor, _format, _tostring = math.floor, string.format, tostring

	local AFK, AfkFrame
	local total, afk_minutes, afk_seconds = 0, 0, 0
	local update, updateInterval = 0, 1
	local cameraSpeed = 0.05

	local _MoveViewLeftStart = MoveViewLeftStart
	local _MoveViewLeftStop = MoveViewLeftStop

	-- rotates the camera
	local function View_MoveCamera(speed)
		speed = speed or cameraSpeed
		_MoveViewLeftStart(speed)
	end

	-- stops camera movement
	local function View_StopCamera()
		_MoveViewLeftStop()
	end

	local CreateWindow
	local Window_OnUpdate
	do
		-- handles back button OnClick event
		local function Button_OnClick(self)
			if AfkFrame then
				AfkFrame:Hide() -- hide the window by default.
				if _UnitIsAFK("player") then -- remove the AFK status.
					_SendChatMessage("", "AFK")
					AfkFrame.timer:SetText("00:00")
				end
			end
		end

		do
			-- changes the window timer's text.
			local function Window_DisplayTime(minutes, seconds)
				if AfkFrame then
					AfkFrame.timer:SetText(_format("%02d", _tostring(minutes)) .. ":" .. _format("%02d", _tostring(seconds)))
				end
			end

			-- calculates time the player's been afk for.
			local function Window_ParseSeconds(num)
				local minutes, seconds = afk_minutes, afk_seconds
				if num >= 60 then
					minutes = _floor(num / 60)
					seconds = _tostring(num - (minutes * 60))
					Window_DisplayTime(minutes, seconds)
				else
					minutes = 0
					seconds = num
					Window_DisplayTime(minutes, seconds)
				end
				afk_minutes = _tostring(minutes)
				afk_seconds = _tostring(seconds)
			end

			-- window OnUpdate handler
			function Window_OnUpdate(self, elapsed)
				if AFK == true then
					update = update + elapsed
					if update > updateInterval then
						total = total + 1
						Window_ParseSeconds(total)
						update = 0
					end
				end
			end
		end

		-- creates the AFK window
		function CreateWindow()
			local frame = _CreateFrame("Frame", "AfkFrame")
			frame:SetBackdrop({
				bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
				edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border-Dark",
				tile = true,
				tileSize = 8,
				edgeSize = 8,
				insets = {left = 3, right = 4, top = 4, bottom = 3}
			})
			frame:SetSize(250, 90)
			frame:SetPoint("CENTER", UIParent, 0, 100)
			frame:EnableMouse(true)
			frame:SetMovable(true)
			frame:SetUserPlaced(true)
			frame:SetClampedToScreen(true)

			-- register the frame's movement functions.
			frame:SetScript("OnMouseDown", frame.StartMoving)
			frame:SetScript("OnMouseUp", frame.StopMovingOrSizing)

			-- AFK text
			local text = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
			text:SetPoint("TOP", frame, "TOP", 0, -10)
			text:SetText(L["You are AFK!"])
			frame.text = text

			-- AFK Timer
			local timer = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
			timer:SetPoint("TOP", frame, "TOP", 0, -35)
			timer:SetText("00:00")
			frame.timer = timer

			-- I'm back button
			local button = _CreateFrame("Button", nil, frame, "KPackButtonTemplate")
			button:SetSize(100, 25)
			button:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)
			button:SetText(L["I am Back"])
			button:RegisterForClicks("LeftButtonUp")
			button:SetScript("OnClick", Button_OnClick)
			frame.button = button

			-- frame close button.
			local close = _CreateFrame("Button", nil, frame, "UIPanelCloseButton")
			close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -8)
			frame.close = close

			-- hide the frame and assign it to mod.
			frame:Hide()
			return frame
		end
	end

	core:RegisterForEvent("PLAYER_LOGIN", function()
		AfkFrame = AfkFrame or CreateWindow()
	end)

	core:RegisterForEvent("PLAYER_FLAGS_CHANGED", function(_, unit)
		if unit ~= "player" then
			return
		elseif _UnitIsAFK(unit) then
			AFK = true
			View_MoveCamera(cameraSpeed)
			AfkFrame = AfkFrame or CreateWindow()
			AfkFrame:Show()
			AfkFrame:SetScript("OnUpdate", Window_OnUpdate)
		else
			AFK = false
			total = 0
			View_StopCamera()
			if AfkFrame then
				AfkFrame:Hide()
				AfkFrame:SetScript("OnUpdate", nil)
			end
		end
	end)
end)