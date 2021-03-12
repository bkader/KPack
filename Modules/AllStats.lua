local addonName, addon = ...
local L = addon.L

local mod = CreateFrame("Frame")
mod:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
mod:RegisterEvent("ADDON_LOADED")

local function AllStats_CreateMidTex(parent)
    local frame = parent:CreateTexture(nil, parent)
    frame:SetSize(144, 53)
    frame:SetTexture([[Interface\PaperDollInfoFrame\UI-Character-StatBackground]])
    frame:SetTexCoord(0, 0.8984375, 0.125, 0.1953125)
    return frame
end

local function AllStats_CreateFrame()
    local frame = CreateFrame("Frame", "KPackAllStats", PaperDollFrame)
    frame:SetPoint("TOPLEFT", PaperDollFrame, "TOPRIGHT", -35, -33)
    frame:SetSize(144, 500)
    frame:SetToplevel(true)

    local textop = frame:CreateTexture(nil, frame)
    textop:SetSize(144, 16)
    textop:SetTexture([[Interface\PaperDollInfoFrame\UI-Character-StatBackground]])
    textop:SetTexCoord(0, 0.8984375, 0, 0.125)
    textop:SetPoint("TOPLEFT")

    local texmid1 = AllStats_CreateMidTex(frame)
    local texmid2 = AllStats_CreateMidTex(frame)
    local texmid3 = AllStats_CreateMidTex(frame)
    local texmid4 = AllStats_CreateMidTex(frame)
    local texmid5 = AllStats_CreateMidTex(frame)
    local texmid6 = AllStats_CreateMidTex(frame)
    local texmid7 = AllStats_CreateMidTex(frame)

    texmid1:SetPoint("TOPLEFT", textop, "BOTTOMLEFT")
    texmid2:SetPoint("TOPLEFT", texmid1, "BOTTOMLEFT")
    texmid3:SetPoint("TOPLEFT", texmid2, "BOTTOMLEFT")
    texmid4:SetPoint("TOPLEFT", texmid3, "BOTTOMLEFT")
    texmid5:SetPoint("TOPLEFT", texmid4, "BOTTOMLEFT")
    texmid6:SetPoint("TOPLEFT", texmid5, "BOTTOMLEFT")
    texmid7:SetPoint("TOPLEFT", texmid6, "BOTTOMLEFT")

    local texbot = frame:CreateTexture(nil, frame)
    texbot:SetSize(144, 16)
    texbot:SetTexture([[Interface\PaperDollInfoFrame\UI-Character-StatBackground]])
    texbot:SetTexCoord(0, 0.8984375, 0.484375, 0.609375)
    texbot:SetPoint("TOPLEFT", texmid7, "BOTTOMLEFT")

    return frame
end

local AllStats_PritStats
do
    local function AllStats_CreateStatFrame(name, text)
        local frame = CreateFrame("Frame", "AllStatsFrame" .. name, mod.frame, "StatFrameTemplate")
        frame:SetWidth(128)
        if text ~= nil then
            local t = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            t:SetPoint("BOTTOM", frame, "TOP", 0, -1)
            t:SetText(text)
            frame.text = text
        end
        return frame
    end

    function AllStats_PritStats()
        -- strength
        local str = AllStats_CreateStatFrame("1", PLAYERSTAT_BASE_STATS)
        str:SetPoint("TOPLEFT", 9, -13)
        PaperDollFrame_SetStat(str, 1)

        -- agility
        local agi = AllStats_CreateStatFrame("2")
        agi:SetPoint("TOPLEFT", str, "BOTTOMLEFT", 0, 1)
        PaperDollFrame_SetStat(agi, 2)

        -- stamina
        local sta = AllStats_CreateStatFrame("3")
        sta:SetPoint("TOPLEFT", agi, "BOTTOMLEFT", 0, 1)
        PaperDollFrame_SetStat(sta, 3)

        -- intellect
        local int = AllStats_CreateStatFrame("4")
        int:SetPoint("TOPLEFT", sta, "BOTTOMLEFT", 0, 1)
        PaperDollFrame_SetStat(int, 4)

        -- spirit
        local spi = AllStats_CreateStatFrame("5")
        spi:SetPoint("TOPLEFT", int, "BOTTOMLEFT", 0, 1)
        PaperDollFrame_SetStat(spi, 5)

        local md = AllStats_CreateStatFrame("MeleeDamage", PLAYERSTAT_MELEE_COMBAT)
        md:SetPoint("TOPLEFT", spi, "BOTTOMLEFT", 0, -11)
        PaperDollFrame_SetDamage(md)
        md:SetScript("OnEnter", CharacterDamageFrame_OnEnter)

        local ms = AllStats_CreateStatFrame("MeleeSpeed")
        ms:SetPoint("TOPLEFT", md, "BOTTOMLEFT", 0, 1)
        PaperDollFrame_SetAttackSpeed(ms)

        local mp = AllStats_CreateStatFrame("MeleePower")
        mp:SetPoint("TOPLEFT", ms, "BOTTOMLEFT", 0, 1)
        PaperDollFrame_SetAttackPower(mp)

        local mh = AllStats_CreateStatFrame("MeleeHit")
        mh:SetPoint("TOPLEFT", mp, "BOTTOMLEFT", 0, 1)
        PaperDollFrame_SetRating(mh, CR_HIT_MELEE)

        local mc = AllStats_CreateStatFrame("MeleeCrit")
        mc:SetPoint("TOPLEFT", mh, "BOTTOMLEFT", 0, 1)
        PaperDollFrame_SetMeleeCritChance(mc)

        local me = AllStats_CreateStatFrame("MeleeExpert")
        me:SetPoint("TOPLEFT", mc, "BOTTOMLEFT", 0, 1)
        PaperDollFrame_SetExpertise(me)

        local rd = AllStats_CreateStatFrame("RangeDamage", PLAYERSTAT_RANGED_COMBAT)
        rd:SetPoint("TOPLEFT", me, "BOTTOMLEFT", 0, -11)
        PaperDollFrame_SetRangedDamage(rd)
        rd:SetScript("OnEnter", CharacterRangedDamageFrame_OnEnter)

        local rs = AllStats_CreateStatFrame("RangeSpeed")
        rs:SetPoint("TOPLEFT", rd, "BOTTOMLEFT", 0, 1)
        PaperDollFrame_SetRangedAttackSpeed(rs)

        local rp = AllStats_CreateStatFrame("RangePower")
        rp:SetPoint("TOPLEFT", rs, "BOTTOMLEFT", 0, 1)
        PaperDollFrame_SetRangedAttackPower(rp)

        local rh = AllStats_CreateStatFrame("RangeHit")
        rh:SetPoint("TOPLEFT", rp, "BOTTOMLEFT", 0, 1)
        PaperDollFrame_SetRating(rh, CR_HIT_RANGED)

        local rc = AllStats_CreateStatFrame("RangeCrit")
        rc:SetPoint("TOPLEFT", rh, "BOTTOMLEFT", 0, 1)
        PaperDollFrame_SetRangedCritChance(rc)

        local sd = AllStats_CreateStatFrame("SpellDamage", PLAYERSTAT_SPELL_COMBAT)
        sd:SetPoint("TOPLEFT", rc, "BOTTOMLEFT", 0, -11)
        PaperDollFrame_SetSpellBonusDamage(sd)
        sd:SetScript("OnEnter", CharacterSpellBonusDamage_OnEnter)

        local she = AllStats_CreateStatFrame("SpellHeal")
        she:SetPoint("TOPLEFT", sd, "BOTTOMLEFT", 0, 1)
        PaperDollFrame_SetSpellBonusHealing(she)

        local shi = AllStats_CreateStatFrame("SpellHit")
        shi:SetPoint("TOPLEFT", she, "BOTTOMLEFT", 0, 1)
        PaperDollFrame_SetRating(shi, CR_HIT_SPELL)

        local sc = AllStats_CreateStatFrame("SpellCrit")
        sc:SetPoint("TOPLEFT", shi, "BOTTOMLEFT", 0, 1)
        PaperDollFrame_SetSpellCritChance(sc)
        sc:SetScript("OnEnter", CharacterSpellCritChance_OnEnter)

        local sha = AllStats_CreateStatFrame("SpellHaste")
        sha:SetPoint("TOPLEFT", sc, "BOTTOMLEFT", 0, 1)
        PaperDollFrame_SetSpellHaste(sha)

        local sr = AllStats_CreateStatFrame("SpellRegen")
        sr:SetPoint("TOPLEFT", sha, "BOTTOMLEFT", 0, 1)
        PaperDollFrame_SetManaRegen(sr)

        local armor = AllStats_CreateStatFrame("Armor")
        armor:SetPoint("TOPLEFT", sr, "BOTTOMLEFT", 0, 1)
        PaperDollFrame_SetArmor(armor)

        local def = AllStats_CreateStatFrame("Defense", PLAYERSTAT_DEFENSES)
        def:SetPoint("TOPLEFT", armor, "BOTTOMLEFT", 0, -11)
        PaperDollFrame_SetDefense(def)

        local dodge = AllStats_CreateStatFrame("Dodge")
        dodge:SetPoint("TOPLEFT", def, "BOTTOMLEFT", 0, 1)
        PaperDollFrame_SetDodge(dodge)

        local parry = AllStats_CreateStatFrame("Parry")
        parry:SetPoint("TOPLEFT", dodge, "BOTTOMLEFT", 0, 1)
        PaperDollFrame_SetParry(parry)

        local block = AllStats_CreateStatFrame("Block")
        block:SetPoint("TOPLEFT", parry, "BOTTOMLEFT", 0, 1)
        PaperDollFrame_SetBlock(block)

        local res = AllStats_CreateStatFrame("Resil")
        res:SetPoint("TOPLEFT", block, "BOTTOMLEFT", 0, 1)
        PaperDollFrame_SetResilience(res)
    end
end

local function AllStats_PaperDollFrame_UpdateStats()
    AllStats_PritStats()
end

local btn
local function AllStats_PaperDollFrame_OnShow(self)
    if not btn then
        btn = CreateFrame("Button", nil, PaperDollFrame, "UIPanelButtonTemplate")
        btn:SetSize(50, 20)
        btn:SetPoint("BOTTOMRIGHT", -43, 86)
        btn:SetText(L["Stats"])
        btn:SetScript("OnClick", function(self, button)
            if mod.frame and mod.frame:IsShown() then
                mod.frame:Hide()
                self:UnlockHighlight()
            elseif mod.frame then
                mod.frame:Show()
                self:LockHighlight()
            end
        end)
    end

    if btn and mod.frame and mod.frame:IsShown() then
        btn:LockHighlight()
    end
end

function mod:ADDON_LOADED(name)
	if name == addonName then
		self.frame = self.frame or AllStats_CreateFrame()
		_G.CharacterAttributesFrame:Hide()
		_G.CharacterModelFrame:SetHeight(300)
		PaperDollFrame_UpdateStats = AllStats_PaperDollFrame_UpdateStats
		PaperDollFrame:HookScript("OnShow", AllStats_PaperDollFrame_OnShow)
	end
end