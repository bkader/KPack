--[[-------------------------------------------------------------
Sorry Aaron Mast but, I like the library and I am using it.
All credits go to you though + it's an over 10years old file.

libTab v 1.0a 2009-12-14

This is an embedded library used by my mods. It is not intended
for external use or as a standalone add-on.

Copyright 2009 Aaron Mast, All Rights Reserved
]] ---------------------------------------------------------------

local version = 1001

if not libTab or libTab.Version < version then
    if (libTab) then
        local localData = libTab.Data
    else
        localData = {}
    end

    libTab = {
        Version = version,
        --
        -- Internal functions, not to be called directly
        --

        tabOrderedPairs = function(self, t, o)
            local a = {}
            if (not o) then
                return nil
            end
            for k, v in pairs(t) do
                a[v[o]] = k
            end
            local i = 0
            local iter = function()
                i = i + 1
                if (a[i] == nil) then
                    return nil
                else
                    return a[i], t[a[i]]
                end
            end
            return iter
        end,
        tabFilteredPairs = function(self, t, f)
            local a = {}
            for k, v in pairs(t) do
                if (type(k) == f) then
                    table.insert(a, k)
                end
            end
            local i = 0
            local iter = function()
                i = i + 1
                if (a[i] == nil) then
                    return nil
                else
                    return a[i], t[a[i]]
                end
            end
            return iter
        end,
        tabHighlight = function(tabsId, tab)
            for key, value in libTab:tabFilteredPairs(libTab.Data[tabsId].tab, "number") do
                if (tab == key) then
                    getglobal("libTab" .. tabsId .. key):SetChecked(1)
                else
                    getglobal("libTab" .. tabsId .. key):SetChecked(0)
                end
            end
        end,
        tabOnClick = function(self, tabsId, tab)
            local caller = libTab.Data[tabsId].tab[tab]
            local gId = libTab.Data[tabsId].tab["gid_" .. caller.Frame]

            if (caller.OnClickFunction) then
                caller.OnClickFunction(caller)
            end

            if (gId) then
                libTab.Data[tabsId].tab["group_" .. gId] = caller.Frame
            end

            ShowUIPanel(getglobal(caller.Frame))
            libTab.tabHighlight(tabsId, tab)
        end,
        tabOnShow = function(self, tabsId, ...)
            local tab = libTab.Data[tabsId].tab["fid_" .. self:GetName()]
            local caller = libTab.Data[tabsId].tab[tab]
            local gId = libTab.Data[tabsId].tab["gid_" .. caller.Frame]
            local group
            if (gId) then
                group = libTab.Data[tabsId].tab["group_" .. gId]
            else
                group = nil
            end

            if (gId and group) then
                if (group ~= caller.Frame and getglobal(group):IsShown()) then
                    if (caller.OnShow) then
                        caller.OnShow(self, ...)
                    end
                    for key, value in libTab:tabFilteredPairs(libTab.Data[tabsId].tab, "number") do
                        HideUIPanel(getglobal(value.Frame))
                    end
                    return
                end
            end

            if (gId) then
                group = group or caller.Frame
                tab = libTab.Data[tabsId].tab["fid_" .. group]
                caller = libTab.Data[tabsId].tab[tab]
            end

            for key, value in libTab:tabFilteredPairs(libTab.Data[tabsId].tab, "number") do
                if (tab ~= key) then
                    HideUIPanel(getglobal(value.Frame))
                end
            end

            if (not getglobal(caller.Frame):IsShown()) then
                ShowUIPanel(getglobal(caller.Frame))
            end

            libTab.Data[tabsId].parent:SetParent(caller.Frame)
            libTab.Data[tabsId].parent:ClearAllPoints()
            libTab.Data[tabsId].parent:SetPoint(
                "TOPLEFT",
                caller.Frame,
                "TOPRIGHT",
                caller.offsetX,
                libTab.TabOffsetY + caller.offsetY
            )
            libTab.tabHighlight(tabsId, tab)

            if (caller.OnShowFunction) then
                caller.OnShowFunction(caller)
            end

            if (caller.OnShow) then
                caller.OnShow(self, ...)
            end

            if (gId) then
                libTab.Data[tabsId].tab["group_" .. gId] = caller.Frame
            end
        end,
        tabOnHide = function(self, tabsId, ...)
            local caller = libTab.Data[tabsId].tab[libTab.Data[tabsId].tab["fid_" .. self:GetName()]]

            if (caller.OnHideFunction) then
                caller.OnHideFunction(caller)
            end

            if (caller.OnHide) then
                caller.OnHide(self, ...)
            end
        end,
        tabHook = function(self, tabsId)
            for key in libTab:tabFilteredPairs(libTab.Data[tabsId].tab, "number") do
                libTab.Data[tabsId].tab[key]["OnShow"] =
                    getglobal(libTab.Data[tabsId].tab[key].Frame):GetScript("OnShow") or nil
                getglobal(libTab.Data[tabsId].tab[key].Frame):SetScript(
                    "OnShow",
                    function(self, ...)
                        libTab.tabOnShow(self, tabsId, ...)
                    end
                )
                libTab.Data[tabsId].tab[key]["OnHide"] =
                    getglobal(libTab.Data[tabsId].tab[key].Frame):GetScript("OnHide") or nil
                getglobal(libTab.Data[tabsId].tab[key].Frame):SetScript(
                    "OnHide",
                    function(self, ...)
                        libTab.tabOnHide(self, tabsId, ...)
                    end
                )
            end
        end,
        --
        -- Add-on called functions
        --

        initialize = function(self, tabsId, tabsTable)
            if not (type(tabsId) == "string" and type(tabsTable) == "table") then
                return false -- malformed input, must die
            end

            if (libTab.Data[tabsId]) then
                return false -- cannot initialize an existing id, die
            end

            libTab.Data[tabsId] = {}

            libTab.Data[tabsId].parent = CreateFrame("Frame", "libTab" .. tabsId .. "ParentFrame")
            libTab.Data[tabsId].parent:SetHeight(1)
            libTab.Data[tabsId].parent:SetWidth(1)
            libTab.Data[tabsId].parent.tabsId = tabsId

            local i = 0
            local lastTab = 0
            libTab.Data[tabsId].tab = {}
            for key, value in libTab:tabOrderedPairs(tabsTable, "order") do
                if not (type(value.Frame, value.Texture, value.ToolTip) == "string" and type(value.order) == "number") then
                    return false -- malformed table data, must die
                end
                for label, data in pairs(libTab.Data) do
                    if (type(data) == "table" and label ~= tabsId) then
                        if libTab.Data[label].tab["fid_" .. value.Frame] then
                            return false -- another add-on has hooked this frame, we can not have two hooks as tabs will overlap, must die
                        end
                    end
                end
                i = i + 1
                libTab.Data[tabsId].tab[i] =
                    CreateFrame("CheckButton", "libTab" .. tabsId .. i, libTab.Data[tabsId].parent, "libTabtabTemplate")
                libTab.Data[tabsId].tab[i]:SetID(i)
                if (i == 1) then
                    libTab.Data[tabsId].tab[i]:ClearAllPoints()
                    libTab.Data[tabsId].tab[i]:SetPoint("TOPLEFT", libTab.Data[tabsId].parent, "BOTTOMLEFT", 0, 0)
                else
                    libTab.Data[tabsId].tab[i]:ClearAllPoints()
                    libTab.Data[tabsId].tab[i]:SetPoint(
                        "TOPLEFT",
                        libTab.Data[tabsId].tab[lastTab],
                        "BOTTOMLEFT",
                        0,
                        -17
                    )
                end
                libTab.Data[tabsId].tab[i]:SetNormalTexture(value.Texture)
                libTab.Data[tabsId].tab[i].ToolTip = value.ToolTip
                libTab.Data[tabsId].tab[i].Frame = value.Frame
                libTab.Data[tabsId].tab[i].order = value.order
                libTab.Data[tabsId].tab[i].group = value.group or nil
                libTab.Data[tabsId].tab[i].offsetX = value.offsetX or 0
                libTab.Data[tabsId].tab[i].offsetY = value.offsetY or 0
                --UIPanelWindows[value.Frame]["pushable"] = 1
                UIPanelWindows[value.Frame]["width"] =
                    getglobal(value.Frame):GetWidth() + (libTab.TabOffsetX + value.offsetX)
                libTab.Data[tabsId].tab[i].OnClickFunction = value.OnClickFunction or nil
                libTab.Data[tabsId].tab[i].OnShowFunction = value.OnShowFunction or nil
                libTab.Data[tabsId].tab[i].OnHideFunction = value.OnHideFunction or nil
                libTab.Data[tabsId].tab["gid_" .. value.Frame] = value.group or nil
                if (value.group) then
                    libTab.Data[tabsId].tab["group_" .. value.group] = nil
                end
                libTab.Data[tabsId].tab["fid_" .. value.Frame] = i
                lastTab = i
            end
            libTab:tabHook(tabsId)
        end,
        tabSetGroupFrame = function(self, tabsId, Frame)
            local gId = libTab.Data[tabsId].tab["gid_" .. Frame]
            local group
            if (gId) then
                group = libTab.Data[tabsId].tab["group_" .. gId]
            else
                group = nil
            end

            if (gId and group) then
                libTab.Data[tabsId].tab["group_" .. gId] = Frame
            end
        end,
        -- DO NOT CHANGE BELOW --
        TabOffsetX = 32,
        TabOffsetY = -65,
        -- DO NOT CHANGE ABOVE --

        Data = localData
    }
end
