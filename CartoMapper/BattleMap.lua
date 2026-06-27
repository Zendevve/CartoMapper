--[[--------------------------------------------------------------------------------------------
BattleMap.lua
Battlefield Minimap customization (Shift+M).
Handles sizing, opacity, dragging/unlocking, and pin scaling for WotLK.
--------------------------------------------------------------------------------------------]]--

local BattleMap = CreateFrame("Frame")
CartoMapper.modules["battleMap"] = BattleMap
BattleMap.liveToggle = true

local DB = CartoMapper.DB

local function ApplyBattleMapSettings()
    if not BattlefieldMinimap then return end
    
    local state = DB.GetOpt("battleMap")
    
    -- Toggle default elements visibility
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

    -- Hide/show default tile textures
    for i = 1, 12 do
        local tex = _G["BattlefieldMinimap" .. i]
        if tex then
            if state then tex:Hide() else tex:Show() end
        end
    end

    if not state then
        -- Restore default dimensions/movability
        BattlefieldMinimap:SetScale(1.0)
        BattlefieldMinimap:SetAlpha(1.0)
        BattlefieldMinimap:SetMovable(false)
        BattlefieldMinimap:EnableMouse(false)
        return
    end

    -- Size (Scale)
    local width = DB.GetOpt("battleMapSize") or 300
    local scale = width / 224 -- 224 is default BattlefieldMinimap width
    BattlefieldMinimap:SetScale(scale)

    -- Opacity
    local opacity = DB.GetOpt("battleMapOpacity") or 1.0
    BattlefieldMinimap:SetAlpha(opacity)

    -- Unlock / Movable
    local unlocked = DB.GetOpt("unlockBattlefield")
    BattlefieldMinimap:SetMovable(unlocked)
    BattlefieldMinimap:EnableMouse(unlocked)

    if unlocked then
        BattlefieldMinimap:RegisterForDrag("LeftButton")
        BattlefieldMinimap:SetScript("OnDragStart", function(self)
            self:StartMoving()
        end)
        BattlefieldMinimap:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint()
            DB.SetOpt("battleMapA", point)
            DB.SetOpt("battleMapR", relativePoint)
            DB.SetOpt("battleMapX", xOfs)
            DB.SetOpt("battleMapY", yOfs)
        end)
    else
        BattlefieldMinimap:RegisterForDrag(nil)
        BattlefieldMinimap:SetScript("OnDragStart", nil)
        BattlefieldMinimap:SetScript("OnDragStop", nil)
    end

    -- Position restore
    local a = DB.GetOpt("battleMapA")
    local r = DB.GetOpt("battleMapR")
    local x = DB.GetOpt("battleMapX")
    local y = DB.GetOpt("battleMapY")
    if a and r and x and y then
        BattlefieldMinimap:ClearAllPoints()
        BattlefieldMinimap:SetPoint(a, UIParent, r, x, y)
    end

    -- Rescale Pins
    local pSize = DB.GetOpt("battlePlayerArrowSize") or 12
    local gSize = DB.GetOpt("battleGroupIconSize") or 12
    
    -- Scale factor relative to default size
    local arrowScale = pSize / 16
    local groupScale = gSize / 16

    if BattlefieldMinimapPlayer then
        BattlefieldMinimapPlayer:SetScale(arrowScale)
    end

    for i = 1, 4 do
        local f = _G["BattlefieldMinimapParty" .. i]
        if f then f:SetScale(groupScale) end
    end

    for i = 1, 40 do
        local f = _G["BattlefieldMinimapRaid" .. i]
        if f then f:SetScale(groupScale) end
    end
end

local function SetupMap()
    if not BattlefieldMinimap then return end

    ApplyBattleMapSettings()

    -- Hook BattlefieldMinimap_Update to keep textures hidden and maintain pin scales
    if not BattleMap.hookedUpdate then
        hooksecurefunc("BattlefieldMinimap_Update", function()
            if not DB.GetOpt("battleMap") then return end
            for i = 1, 12 do
                local tex = _G["BattlefieldMinimap" .. i]
                if tex then tex:Hide() end
            end
            ApplyBattleMapSettings()
        end)
        BattleMap.hookedUpdate = true
    end
end

function BattleMap.Enable()
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

function BattleMap.Disable()
    BattleMap.enabled = false
    ApplyBattleMapSettings()
end

function CartoMapper.UpdateBattleMap()
    ApplyBattleMapSettings()
end
