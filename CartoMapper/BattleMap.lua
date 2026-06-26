--[[--------------------------------------------------------------------------------------------
BattleMap.lua
Battlefield Minimap customization (Shift+M).
--------------------------------------------------------------------------------------------]]--

local BattleMap = CreateFrame("Frame")
CartoMapper.modules["battleMap"] = BattleMap

local function SetupMap()
    if not BattlefieldMinimap then return end

    -- Hide surrounding border textures
    BattlefieldMinimapCorner:Hide()
    BattlefieldMinimapBackground:Hide()
    BattlefieldMinimapCloseButton:Hide()
    BattlefieldMinimapTab:Hide()

    -- Transparent look: hide the 12 base textures
    for i = 1, 12 do
        local tex = _G["BattlefieldMinimap" .. i]
        if tex then
            tex:Hide()
        end
    end

    -- Hook BattlefieldMinimap_Update to keep textures hidden (if default code tries to show them)
    hooksecurefunc("BattlefieldMinimap_Update", function()
        for i = 1, 12 do
            local tex = _G["BattlefieldMinimap" .. i]
            if tex then
                tex:Hide()
            end
        end
    end)
end

function BattleMap.Enable()
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
