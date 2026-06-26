--[[--------------------------------------------------------------------------------------------
GroupIcons.lua
Class-colored player and group icons with raid subgroups.
--------------------------------------------------------------------------------------------]]--

local GroupIcons = CreateFrame("Frame")
CartoMapper.modules["groupIcons"] = GroupIcons

local assetPath = "Interface\\AddOns\\CartoMapper\\assets\\"
local normalTexture = assetPath .. "Normal"
local groupTexturePattern = assetPath .. "Group%d"

local function UpdateUnitIcon(tex, unit)
    if not tex or not unit then return end

    -- Get class and subgroup info
    local _, classFileName = UnitClass(unit)
    if not classFileName then return end

    -- Handle subgroup texture for raid members
    if string.find(unit, "raid", 1, true) then
        local raidIndex = string.sub(unit, 5)
        local _, _, subgroup = GetRaidRosterInfo(tonumber(raidIndex) or 0)
        if subgroup then
            tex:SetTexture(string.format(groupTexturePattern, subgroup))
        else
            tex:SetTexture(normalTexture)
        end
    else
        tex:SetTexture(normalTexture)
    end

    -- Visual states (combat red flashing, dead grey flashing, AFK/inactive purple, class colored otherwise)
    local classColor = RAID_CLASS_COLORS[classFileName]
    if (GetTime() % 1 < 0.5) then
        if UnitAffectingCombat(unit) then
            tex:SetVertexColor(0.8, 0, 0) -- red flashing
        elseif UnitIsDeadOrGhost(unit) then
            tex:SetVertexColor(0.2, 0.2, 0.2) -- dark grey flashing
        elseif PlayerIsPVPInactive and PlayerIsPVPInactive(unit) then
            tex:SetVertexColor(0.5, 0.2, 0.8) -- purple flashing
        elseif classColor then
            tex:SetVertexColor(classColor.r, classColor.g, classColor.b)
        end
    elseif classColor then
        tex:SetVertexColor(classColor.r, classColor.g, classColor.b)
    else
        tex:SetVertexColor(0.8, 0.8, 0.8)
    end
end

local function OnUpdate(self, elapsed)
    self.elapsed = (self.elapsed or 0.5) - elapsed
    if self.elapsed <= 0 then
        self.elapsed = 0.5
        UpdateUnitIcon(self.icon, self.unit)
    end
end

local function FixUnit(unit, state, isNormal)
    local frame = _G[unit]
    if not frame then return end
    
    local icon = frame.icon
    if state then
        frame.elapsed = 0.5
        frame:SetScript("OnUpdate", OnUpdate)
        frame:SetScript("OnEvent", nil)
        if isNormal then
            icon:SetTexture(normalTexture)
        end
    else
        frame.elapsed = nil
        frame:SetScript("OnUpdate", nil)
        frame:SetScript("OnEvent", WorldMapUnit_OnEvent)
        icon:SetVertexColor(1, 1, 1)
        icon:SetTexture("Interface\\WorldMap\\WorldMapPartyIcon")
    end
end

local function FixWorldMapUnits(state)
    for i = 1, 4 do
        FixUnit("WorldMapParty" .. i, state, true)
    end
    for i = 1, 40 do
        FixUnit("WorldMapRaid" .. i, state, false)
    end
end

local function FixBattlefieldUnits(state)
    if BattlefieldMinimap then
        for i = 1, 4 do
            FixUnit("BattlefieldMinimapParty" .. i, state, true)
        end
        for i = 1, 40 do
            FixUnit("BattlefieldMinimapRaid" .. i, state, false)
        end
    end
end

function GroupIcons.Enable()
    -- Support custom class color addons
    if CUSTOM_CLASS_COLORS then
        RAID_CLASS_COLORS = CUSTOM_CLASS_COLORS
    end

    FixWorldMapUnits(true)
    hooksecurefunc("WorldMapUnit_Update", function(unitFrame)
        UpdateUnitIcon(unitFrame.icon, unitFrame.unit)
    end)

    if not IsAddOnLoaded("Blizzard_BattlefieldMinimap") then
        GroupIcons:RegisterEvent("ADDON_LOADED")
        GroupIcons:SetScript("OnEvent", function(self, event, addon)
            if addon == "Blizzard_BattlefieldMinimap" then
                FixBattlefieldUnits(true)
                self:UnregisterEvent("ADDON_LOADED")
            end
        end)
    else
        FixBattlefieldUnits(true)
    end
end
