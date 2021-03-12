local _, addon = ...

local setmetatable = setmetatable
local tostring, format = tostring, string.format
local rawset, rawget = rawset, rawget

local L = setmetatable({}, {
    __newindex = function(self, key, value)
        rawset(self, key, value == true and key or value)
    end,
    __index = function(self, key)
        return key
    end
})

function L:F(line, ...)
    line = L[line]
    return format(line, ...)
end

addon.L = L

-- //////////////////////////////////////////////////////
-- General:
-- //////////////////////////////////////////////////////

L["addon loaded. use |cffffd700/kp help|r for help."] = true
L["module loaded."] = true

L["module enabled."] = true
L["module disable."] = true

L["enable the module."] = true
L["disable the module."] = true
L["show module status."] = true
L["access module configuration"] = true

L["Please reload ui."] = true

L["Module Status"] = true
L["module status: %s"] = true
L["enable module"] = true
L["disable module"] = true
L["toggle module status"] = true

L["Acceptable commands for: |caaf49141%s|r"] = true
L["Unknown Command. Type \"|caaf49141%s|r\" for a list of commands."] = true
L["Available command for |caaf49141%s|r is |cffffd700%s|r"] = true
L["access |caaf49141%s|r module commands"] = true
L["to use the |caaf49141%s|r module"] = true
L["Enables or disables the module."] = true
L["Resets module settings to default."] = true
L["module's settings reset to default."] = true

L["|cff00ff00enabled|r"] = true
L["|cffff0000disabled|r"] = true
L["|cff00ff00ON|r"] = true
L["|cffff0000OFF|r"] = true
L["|cffffd700Example|r: %s"] = true
L["More from |caaf49141%s|r:"] = true

L["Current list of commands:"] = true
L["|cffffd700%s|r: %s"] = true

-- //////////////////////////////////////////////////////
-- AddOn Manager:
-- //////////////////////////////////////////////////////

L["Reload UI"] = true
L["Enable all"] = true
L["Disable all"] = true
L["|cffff4400Dependencies: |r"] = true
L["|cffffffff%d|r AddOns: |cffffffff%d|r |cff00ff00Enabled|r, |cffffffff%d|r |cffff0000Disabled|r"] = true

-- //////////////////////////////////////////////////////
-- Action Bars module:
-- //////////////////////////////////////////////////////

L["move right action bars on top of middle ones."] = true
L["move right action bars to their default location."] = true
L["scales the action bars. n between 0 and 1."] = true
L["toggles pixel perfect mode."] = true
L["toggles bars range dectection."] = true
L["toggles gryphons."] = true
L["changes opacity of keybindings and macros names. n between 0 and 1."] = true
L["shows right action bars on mouseover."] = true
L["toggles BfA action bars."] = true
L["action bars scale set to: |cff00ffff%s|r"] = true
L["pixel perfect mode: %s"] = true
L["gryphons: %s"] = true
L["hotkeys opacity set to: |cff00ffff%s|r"] = true
L["range detection: %s"] = true
L["mouseover right bars: %s"] = true
L["BfA UI: %s"] = true

-- //////////////////////////////////////////////////////
-- AFK module:
-- //////////////////////////////////////////////////////

L["You are AFK!"] = true
L["I am Back"] = true

-- //////////////////////////////////////////////////////
-- Armory Linl
-- //////////////////////////////////////////////////////

L["Armory Link"] = true
L["Warmane Armory Link"] = true
L["Couldn't find realm!"] = true

-- //////////////////////////////////////////////////////
-- AutoMate
-- //////////////////////////////////////////////////////

L["ignore all duels"] = true
L["skip quests gossip"] = true
L["automatically sell junks"] = true
L["show nameplates only in combat"] = true
L["show the minimap only in combat"] = true
L["equiment repair using guild gold or own gold"] = true
L["automatic ui scale"] = true
L["automatic max camera zoom out"] = true
L["automatic screenshot on achievement"] = true

L["ignore duels: %s"] = true
L["skip gossip: %s"] = true
L["sell junk: %s"] = true
L["auto repair: %s"] = true
L["auto nameplates: %s"] = true
L["auto hide minimap: %s"] = true
L["auto ui scale: %s"] = true
L["auto max camera: %s"] = true
L["auto screenshot on achievement: %s"] = true

-- More
L["|cffffd700Alt-Click|r to buy a stack of item from merchant."] = true
L["A proper ReadyCheck sound."] = true
L["You can keybind raid icons on MouseOver. Check keybindings."] = true
L["MouseOver and Mark"] = true
L["Remove Icon"] = true

-- //////////////////////////////////////////////////////
-- BlizzMove
-- //////////////////////////////////////////////////////

L["Click the button below to reset all frames."] = true
L["Move/Lock a Frame"] = true
L["%s will be saved."] = true
L["%s will not be saved."] = true
L["%s will move with handler %s"] = true

-- //////////////////////////////////////////////////////
-- Chat Filter
-- //////////////////////////////////////////////////////

L["Chat Filter"] = true
L["filter is now %s"] = true
L["Input is not a number"] = true
L["filter keywords are:"] = true
L["notifications are now %s"] = true
L["The message log is empty."] = true
L["Displaying the last %d messages:"] = true
L["the word |cff00ffff%s|r was added successfully."] = true
L["the word |cff00ffff%s|r was removed successfully."] = true
L["Index is out of range. Max value is |cff00ffff%d|r."] = true
L["settings were set to default."] = true
L["Turn filter |cff00ff00on|r / |cffff0000off|r"] = true
L["View filter keywords (case-insensitive)"] = true
L["Adds a |cff00ffffkeyword|r"] = true
L["Remove keyword by |cff00ffffposition|r"] = true
L["Show or hide filter notifications"] = true
L["View the last |cff00ffffn|r filtered messages (up to 20)"] = true
L["Resets settings to default"] = true
L["filtered a message from |cff00ffff%s|r"] = true

-- //////////////////////////////////////////////////////
-- ChatMods
-- //////////////////////////////////////////////////////
L["editbox put in center"] = true
L["editbox set to default position"] = true
L["editbox position set to: |cff00ffff%s|r"] = true
L["put the editbox in the middle of the screen."] = true
L["put the editbox on top of the chat frame."] = true
L["put the editbox at the bottom of the chat frame."] = true

-- //////////////////////////////////////////////////////
-- Close Up
-- //////////////////////////////////////////////////////

L["Undress"] = true
L["Cannot dress NPC models."] = true

-- //////////////////////////////////////////////////////
-- CombatLogFix
-- //////////////////////////////////////////////////////

L["Show set options"] = true
L["Zone Clearing"] = true
L["Auto Clearing"] = true
L["Message Report"] = true
L["Queued Clearing"] = true
L["%d filtered/%d events found. Cleared combat log, as it broke."] = true
L["List of set options."] = true
L["Toggles clearing on zone type change."] = true
L["Toggles clearing combat log when it breaks."] = true
L["Toggles not clearing until you drop combat."] = true
L["Toggles reporting how many messages were found when it broke."] = true

L["You have successfully sold %d grey items."] = true
L["Repair cost covered by Guild Bank: %dg %ds %dc."] = true
L["Your items have been repaired for %dg %ds %dc."] = true
L["You don't have enough money to repair items!"] = true

-- //////////////////////////////////////////////////////
-- CombatTime
-- //////////////////////////////////////////////////////

L["trigger the in-game stopwatch on combat"] = true
L["using stopwatch: %s"] = true

-- //////////////////////////////////////////////////////
-- ErrorFilter
-- //////////////////////////////////////////////////////

L["database cleared."] = true
L["filter database:"] = true
L["Error frame is now hidden."] = true
L["Error frame is now visible."] = true
L["filter added: %s"] = true
L["hide error frame."] = true
L["show error frame."] = true
L["list of filtered errors."] = true
L["clear the list of filtered errors."] = true
L["add an error filter"] = true
L["delete a filter by index"] = true

-- //////////////////////////////////////////////////////
-- FriendsInfo
-- //////////////////////////////////////////////////////

L["Last seen %s ago"] = true

-- //////////////////////////////////////////////////////
-- GearScoreLite:
-- //////////////////////////////////////////////////////

L["Toggles display of scores on players."] = true
L["Toggles display of scores for items."] = true
L["Toggles iLevel information."] = true
L["Resets GearScore's Options back to Default."] = true
L["Toggles display of comparative info between you and your target's GearScore."] = true

L["Player Scores: %s"] = true
L["Item Scores: %s"] = true
L["Item Levels: %s"] = true
L["Comparisons: %s"] = true

-- //////////////////////////////////////////////////////
-- IgnoreMore
-- //////////////////////////////////////////////////////

L["%s does not look like a valid player name."] = true
L["Reason for ignoring this player:"] = true
L["remove a player from ignore list"] = true
L["wipe the ingore list"] = true
L["ignore list wiped"] = true
L["|cff00ffff%s|r successfully removed from the ignore list"] = true
L["could not find a player named %|cff00ffff%s|r on the ignore list"] = true
L["invalid player name"] = true

-- //////////////////////////////////////////////////////
-- LookUp
-- //////////////////////////////////////////////////////
L["Searching for items containing |cffffd700%s|r"] = true
L["Searching for spells containing |cffffd700%s|r"] = true
L["Search completed, |cffffd700%d|r items matched."] = true
L["Search completed, |cffffd700%d|r spells matched."] = true
L["Item ID not found in local cache."] = true
L["Spell ID not found in local cache."] = true
L["|cffffd700Item|r : %s"] = true
L["|cffffd700Spell|r : %s [%d]"] = true
L["Searches for item link in local cache."] = true
L["Searches for spell link."] = true

-- //////////////////////////////////////////////////////
-- LootMessageFilter
-- //////////////////////////////////////////////////////

L["Minimum item rarity for loot filter set to %s"] = true
L["Check the filter status."] = true

-- //////////////////////////////////////////////////////
-- Minimap
-- //////////////////////////////////////////////////////

L["Calendar"] = true
L["show minimap"] = true
L["hide minimap"] = true
L["change minimap scale"] = true
L["toggle hiding minimap in combat"] = true
L["minimap shown."] = true
L["minimap hidden."] = true
L["hide in combat: %s"] = true
L["lock the minimap"] = true
L["unlocks the minimap"] = true
L["Once unlocked, the minimap can be moved by holding both SHIFT and ALT buttons."] = true

-- //////////////////////////////////////////////////////
-- MoveAnything
-- //////////////////////////////////////////////////////

L["Reset %s? Press again to confirm"] = true
L["Resetting %s"] = true
L["MoveAnything: Reset all frames in the current profile?"] = true
L["Can't interact with %s during combat."] = true
L["Disabled during combat."] = true
L["Unsupported type: %s"] = true
L["Unsupported frame: %s"] = true
L["%s can only be hidden"] = true
L["%s can only be modified while it's shown on the screen"] = true
L["You can only move %i frames at once"] = true
L["UI element not found"] = true
L["UI element not found: %s"] = true
L["Profiles can't be switched during combat"] = true
L["Syntax: /unmove framename"] = true
L["Syntax: /moveimport ProfileName"] = true
L["Syntax: /moveexport ProfileName"] = true
L["Syntax: /movedelete ProfileName"] = true
L["Syntax: /hide ProfileName"] = true
L["Unknown profile: %s"] = true
L["Profile imported: %s"] = true
L["Profile exported: %s"] = true
L["Profile deleted: %s"] = true
L["Can't delete current profile during combat"] = true
L["Profiles"] = true
L["Current"] = true
L["No named elements found"] = true

L["Use character specific settings"] = true
L["Current profile: %s"] = true

L.MATTHelp = "Toggles display of tooltips. Press Shift when mousing over elements to reverse tooltip display behavior"
L.MAMFHelp = "Show only modified frames"
L.MACEHelp = "Toggle all categories"
L.MASyncHelp = "Synchronizes all frames modified by MoveAnything"
L.MACloseHelp = "Closes this dialog. Ctrl-Shift-Alt click reloads the interface"
L.MAResetHelp = "Resets all frames"

-- //////////////////////////////////////////////////////
-- Personal Resources
-- //////////////////////////////////////////////////////

L["show personal resources"] = true
L["hide personal resources"] = true
L["toggle showing personal resources out of combat"] = true
L["change personal resources scale"] = true
L["change personal resources width"] = true
L["change personal resources height"] = true

-- //////////////////////////////////////////////////////
-- SimpleComboPoints
-- //////////////////////////////////////////////////////

L["The width must be a valid number"] = true
L["The height must be a valid number"] = true
L["Scale has to be a number, recommended to be between 0.5 and 3"] = true
L["Spacing has to be a number, recommended to be between 0.5 and 3"] = true
L["Changes the points width or height."] = true
L["Show out of combat: %s"] = true
L["Changes frame scale."] = true
L["Changes spacing between points."] = true
L["Changes points color."] = true
L["Toggles showing combo points out of combat."] = true

-- //////////////////////////////////////////////////////
-- Simplified
-- //////////////////////////////////////////////////////

L["Combat logging is currently %s."] = true
L["Combat logging is now %s."] = true
L["Change Specilization"] = true

-- //////////////////////////////////////////////////////
-- Tooltip
-- //////////////////////////////////////////////////////

L["toggles unit tooltip in combat"] = true
L["toggles bar spells tooltip in combat"] = true
L["toggles pet bar spells tooltip in combat"] = true
L["toggles class bar spells tooltip in combat"] = true
L["change tooltips scale"] = true
L["moves tooltip to top middle of the screen"] = true
L["toggles enhanced tooltips (requires reload)"] = true

L["unit tooltip in combat: %s"] = true
L["bar spells tooltip in combat: %s"] = true
L["pet bar spells tooltip in combat: %s"] = true
L["class bar spells tooltip in combat: %s"] = true
L["tooltip scale set to: |cff00ffff%s|r"] = true
L["enhanced tooltips: %s"] = true
L["tooltip moved to top middle of the screen."] = true
L["tooltip moved to default position."] = true

-- //////////////////////////////////////////////////////
-- PullnBreak
-- //////////////////////////////////////////////////////

L["Pull in %s"] = true
L["{rt8} Pull Now! {rt8}"] = true
L["{rt7} Pull ABORTED {rt7}"] = true

L["%s Break starts now!"] = true
L["Break ends in %s"] = true
L["{rt1} Break Ends Now {rt1}"] = true
L["{rt7} Break Canceled {rt7}"] = true

-- //////////////////////////////////////////////////////
-- QuickButton
-- //////////////////////////////////////////////////////

L["Turns module |cff00ff00ON|r or |cffff0000OFF|r."] = true
L["Turns macro creation |cff00ff00ON|r or |cffff0000OFF|r."] = true
L["button scale set to |cff00ffff%s|r"] = true
L["Scales the button."] = true

-- //////////////////////////////////////////////////////
-- UnitFrames
-- //////////////////////////////////////////////////////

L["changes the unit frames scale."] = true
L["toggle using class icons instead of portraits"] = true
L["To move the player and target, hold SHIFT and ALT while dragging them around."] = true

-- //////////////////////////////////////////////////////
-- Viewporter
-- //////////////////////////////////////////////////////

L["changes thew viewport on the selected side."] = true
L["Toggles viewporter status."] = true
L["Enables viewporter."] = true
L["Disables viewporter."] = true
L["where side is left, right, top or bottom."] = true