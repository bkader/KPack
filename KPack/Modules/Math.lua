local core = KPack
if not core then return end
core:AddModule("Math", "A simple slash calculator.", function()
	if core:IsDisabled("Math") then return end

	-- cache frequently used globals
	local find, gsub = string.find, string.gsub
	local previous = nil

	-- main function that does calculation
	function KPack_Math(eq)
		if not find(eq, "^[()*/+%^-0123456789. ]+$") then
			return
		end

		local expr = eq
		eq = gsub(eq, " ", "")
		if find(eq, "[()]%^") or find(eq, "%^[()]") then
			return
		end

		eq = gsub(eq, "([%d%.]+)^([%d%.]+)", "(ldexp(%1,%2-1))")
		eq = gsub(eq, "(%d)%(", "%1*(")
		eq = gsub(eq, "%)([%d%.])", ")*%1")
		eq = gsub(eq, "%)%(", ")*(")

		local _, _, first = find(eq, "^([*/+-])")
		if first and previous then
			eq = previous .. " " .. eq
		elseif first then
			return
		end

		RunScript('print("' .. expr .. ' = "..' .. eq .. ")")
		RunScript("previous = " .. eq)
	end

	SlashCmdList["KPACKMATH"] = KPack_Math
	SLASH_KPACKMATH1 = "/math"
	SLASH_KPACKMATH2 = "/calc"
end)