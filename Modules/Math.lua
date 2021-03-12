local addonName, addon = ...
local mod = addon.Math or CreateFrame("Frame")
addon.Math = mod
mod:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
mod:RegisterEvent("ADDON_LOADED")

-- cache frequently used globals
local find, gsub = string.find, string.gsub
local previous

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

function mod:ADDON_LOADED(name)
	if name ~= addonName then return end
	self:UnregisterEvent("ADDON_LOADED")
	SlashCmdList["KPACKMATH"] = KPack_Math
	_G.SLASH_KPACKMATH1 = "/math"
	_G.SLASH_KPACKMATH2 = "/calc"
end