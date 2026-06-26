--[[--------------------------------------------------------------------------------------------
BattleMap.lua
Battlefield Minimap customization (Shift+M).
--------------------------------------------------------------------------------------------]]--

local BattleMap = CreateFrame("Frame")
CartoMapper.modules["battleMap"] = BattleMap

local function SetupBattleMapVisibility()
    if not BattlefieldMinimap then return end
    local state = CartoMapperDB.battleMap

    if state then
        BattlefieldMinimapCorner:Hide()
        BattlefieldMinimapBackground:Hide()
        BattlefieldMinimapCloseButton:Hide()
        BattlefieldMinimapTab:Hide()
    else
        BattlefieldMinimapCorner:Show()
        BattlefieldMinimapBackground:Show()
        BattlefieldMinimapCloseButton:Show()
        BattlefieldMinimapTab:Show()
    end

    for i = 1, 12 do
        local tex = _G["BattlefieldMinimap" .. i]
        if tex then
            if state then tex:Hide() else tex:Show() end
        end
    end
end

local function SetupMap()
    if not BattlefieldMinimap then return end

    SetupBattleMapVisibility()

    -- Hook BattlefieldMinimap_Update to keep textures hidden (if default code tries to show them)
    hooksecurefunc("BattlefieldMinimap_Update", function()
        if not CartoMapperDB.battleMap then return end
        for i = 1, 12 do
            local tex = _G["BattlefieldMinimap" .. i]
            if tex then
                tex:Hide()
            end
        end
    end)
end

function BattleMap.Enable()
    if BattleMap.enabled then return end
    BattleMap.enabled = true
    if not IsAddOnLoaded("Blizzard_BattlefieldMinimap") then
        BattleMap:RegisterEvent("ADDON_LOADED")
        BattleMap:SetScript("OnEvent", function(self, event, addon)
            if addon == "Blizzard_BattlefieldMinimap" then
                SetupMap()
                self:UnregisterEvent("ADDON_LOADED")
            end
        end)
    else
        SetupMap()
    end
end

function CartoMapper.UpdateBattleMap()
    if not BattleMap.enabled then
        BattleMap.Enable()
    else
        SetupBattleMapVisibility()
    end
end
