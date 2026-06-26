--[[--------------------------------------------------------------------------------------------
Zoom.lua
World Map Scroll-to-Zoom and Drag-to-Pan functionality.
Also handles Ctrl + Scroll windowed map scaling and inverse scale correction for map pins.
--------------------------------------------------------------------------------------------]]--

local Zoom = {}
CartoMapper.modules["zoom"] = Zoom

local MAX_ZOOM = 4.0
local ZOOM_STEP = 0.1
local MIN_ZOOM = 1.0

local MINIMODE_MIN_ZOOM = 0.5
local MINIMODE_MAX_ZOOM = 3.0
local MINIMODE_ZOOM_STEP = 0.05

local PreviousState = {
    panX = 0,
    panY = 0,
    scale = 1.0,
    zone = 0
}

local function SetPOIMaxBounds()
    WorldMapScrollFrame.maxY = WorldMapDetailFrame:GetHeight() * -WORLDMAP_SETTINGS.size + 12
    WorldMapScrollFrame.maxX = WorldMapDetailFrame:GetWidth() * WORLDMAP_SETTINGS.size + 12
end

local function SetDetailFrameScale(scale)
    WorldMapDetailFrame:SetScale(scale)
    SetPOIMaxBounds()

    -- Correct scaling on map sub-elements so they do not bloat when zoomed in
    local invScale = 1 / scale
    WorldMapPOIFrame:SetScale(1 / WORLDMAP_SETTINGS.size)
    WorldMapBlobFrame:SetScale(scale)

    WorldMapPlayer:SetScale(invScale)
    WorldMapDeathRelease:SetScale(invScale)
    WorldMapCorpse:SetScale(invScale)

    -- Party Members
    for i = 1, MAX_PARTY_MEMBERS do
        local f = _G["WorldMapParty" .. i]
        if f then f:SetScale(invScale) end
    end

    -- Raid Members
    for i = 1, MAX_RAID_MEMBERS do
        local f = _G["WorldMapRaid" .. i]
        if f then f:SetScale(invScale) end
    end

    -- Flags
    local numFlags = GetNumBattlefieldFlagPositions()
    for i = 1, numFlags do
        local f = _G["WorldMapFlag" .. i]
        if f then f:SetScale(invScale) end
    end

    -- Vehicles
    if MAP_VEHICLES then
        for i = 1, #MAP_VEHICLES do
            if MAP_VEHICLES[i] then MAP_VEHICLES[i]:SetScale(invScale) end
        end
    end

    WorldMapFrame_OnEvent(WorldMapFrame, "DISPLAY_SIZE_CHANGED")
end

local function PersistMapScrollAndPan()
    PreviousState.panX = WorldMapScrollFrame:GetHorizontalScroll()
    PreviousState.panY = WorldMapScrollFrame:GetVerticalScroll()
    PreviousState.scale = WorldMapDetailFrame:GetScale()
    PreviousState.zone = GetCurrentMapZone()
end

local function AfterScrollOrPan()
    PersistMapScrollAndPan()
    if WORLDMAP_SETTINGS.selectedQuest and WorldMapBlobFrame.DrawQuestBlob then
        WorldMapBlobFrame:DrawQuestBlob(WORLDMAP_SETTINGS.selectedQuestId, false)
        WorldMapBlobFrame:DrawQuestBlob(WORLDMAP_SETTINGS.selectedQuestId, true)
    end
end

-- Resize quest POI buttons so they do not drift or scale awkwardly
local function ResizeQuestPOIs()
    local QUEST_POI_MAX_TYPES = 4
    local POI_TYPE_MAX_BUTTONS = 25
    local scale = WorldMapDetailFrame:GetScale()

    local function resizePOI(poiButton)
        if not poiButton then return end
        local _, _, _, x, y = poiButton:GetPoint()
        if x and y then
            local s = WORLDMAP_SETTINGS.size / WorldMapDetailFrame:GetEffectiveScale()
            local posX = x * 1 / s
            local posY = y * 1 / s
            poiButton:SetScale(s)
            poiButton:SetPoint("CENTER", poiButton:GetParent(), "TOPLEFT", posX, posY)
        end
    end

    for i = 1, QUEST_POI_MAX_TYPES do
        for j = 1, POI_TYPE_MAX_BUTTONS do
            resizePOI(_G["poiWorldMapPOIFrame" .. i .. "_" .. j])
        end
    end
    if QUEST_POI_SWAP_BUTTONS then
        resizePOI(QUEST_POI_SWAP_BUTTONS["WorldMapPOIFrame"])
    end
end

local function updatePointRelativeTo(frame, newRelativeFrame)
    if not frame then return end
    local currentPoint, _currentRelativeFrame, currentRelativePoint, currentOffsetX, currentOffsetY = frame:GetPoint()
    if currentPoint and currentRelativePoint then
        frame:ClearAllPoints()
        frame:SetPoint(currentPoint, newRelativeFrame, currentRelativePoint, currentOffsetX, currentOffsetY)
    end
end

local function SetupWorldMapFrame()
    WorldMapScrollFrameScrollBar:Hide()
    WorldMapFrame:EnableMouse(true)
    WorldMapScrollFrame:EnableMouse(true)
    WorldMapScrollFrame.panning = false
    WorldMapScrollFrame.moved = false

    -- Adapt coordinates of quest tracker and frame positions based on WotLK sizes
    WorldMapScrollFrame:ClearAllPoints()
    if WORLDMAP_SETTINGS.size == WORLDMAP_QUESTLIST_SIZE then
        WorldMapScrollFrame:SetPoint("TOPLEFT", WorldMapPositioningGuide, "TOP", -726, -99)
        if WorldMapTrackQuest then
            WorldMapTrackQuest:SetPoint("BOTTOMLEFT", WorldMapPositioningGuide, "BOTTOMLEFT", 8, 4)
        end
    elseif WORLDMAP_SETTINGS.size == WORLDMAP_WINDOWED_SIZE then
        if WorldMapTrackQuest then
            WorldMapTrackQuest:SetPoint("BOTTOMLEFT", WorldMapPositioningGuide, "BOTTOMLEFT", 16, -9)
        end

        WorldMapFrame:SetPoint("TOPLEFT", WorldMapScreenAnchor or UIParent, 0, 0)
        WorldMapFrame:SetScale(CartoMapperDB.mapScale or 1.0)
        WorldMapFrame:SetMovable("true")
        WorldMapTitleButton:Show()
        WorldMapTitleButton:ClearAllPoints()
        WorldMapFrameTitle:Show()
        WorldMapFrameTitle:ClearAllPoints()
        WorldMapFrameTitle:SetPoint("CENTER", WorldMapTitleButton, "CENTER", 32, 0)

        if WORLDMAP_SETTINGS.advanced then
            WorldMapScrollFrame:SetPoint("TOPLEFT", 19, -42)
            WorldMapTitleButton:SetPoint("TOPLEFT", WorldMapFrame, "TOPLEFT", 13, 0)
        else
            WorldMapScrollFrame:SetPoint("TOPLEFT", 37, -66)
            WorldMapTitleButton:SetPoint("TOPLEFT", WorldMapFrame, "TOPLEFT", 13, -14)
        end
    else
        WorldMapScrollFrame:SetPoint("TOPLEFT", WorldMapPositioningGuide, "TOPLEFT", 11, -70.5)
        if WorldMapTrackQuest then
            WorldMapTrackQuest:SetPoint("BOTTOMLEFT", WorldMapPositioningGuide, "BOTTOMLEFT", 16, -9)
        end
    end

    WorldMapScrollFrame:SetScale(WORLDMAP_SETTINGS.size)
    SetDetailFrameScale(1.0)
    WorldMapDetailFrame:SetAllPoints(WorldMapScrollFrame)
    WorldMapScrollFrame:SetHorizontalScroll(0)
    WorldMapScrollFrame:SetVerticalScroll(0)

    -- Persist zoom across reopenings of the same zone
    if GetCurrentMapZone() == PreviousState.zone then
        SetDetailFrameScale(PreviousState.scale)
        WorldMapScrollFrame:SetHorizontalScroll(PreviousState.panX)
        WorldMapScrollFrame:SetVerticalScroll(PreviousState.panY)
    end

    WorldMapButton:SetScale(1.0)
    WorldMapButton:SetAllPoints(WorldMapDetailFrame)
    WorldMapButton:SetParent(WorldMapDetailFrame)
    WorldMapPOIFrame:SetParent(WorldMapDetailFrame)
    WorldMapBlobFrame:SetParent(WorldMapDetailFrame)
    WorldMapBlobFrame:ClearAllPoints()
    WorldMapBlobFrame:SetAllPoints(WorldMapDetailFrame)
    WorldMapPlayer:SetParent(WorldMapDetailFrame)

    -- Anchor Quest Log sub-elements to the scroll frame instead of the scaled detail frame
    updatePointRelativeTo(WorldMapQuestScrollFrame, WorldMapScrollFrame)
    updatePointRelativeTo(WorldMapQuestDetailScrollFrame, WorldMapScrollFrame)
end

-- Mouse Scroll Zoom Handler
local function WorldMapScrollFrame_OnMouseWheel(self, delta)
    -- Ctrl + Scroll scales the windowed world map frame itself
    if IsControlKeyDown() and WORLDMAP_SETTINGS.size == WORLDMAP_WINDOWED_SIZE then
        local oldScale = WorldMapFrame:GetScale()
        local newScale = oldScale + delta * MINIMODE_ZOOM_STEP
        newScale = math.max(MINIMODE_MIN_ZOOM, newScale)
        newScale = math.min(MINIMODE_MAX_ZOOM, newScale)

        WorldMapFrame:SetScale(newScale)
        CartoMapperDB.mapScale = newScale
        return
    end

    -- Scroll-wheel Zoom map detail
    local oldScrollH = WorldMapScrollFrame:GetHorizontalScroll()
    local oldScrollV = WorldMapScrollFrame:GetVerticalScroll()

    local cursorX, cursorY = GetCursorPosition()
    cursorX = cursorX / WorldMapScrollFrame:GetEffectiveScale()
    cursorY = cursorY / WorldMapScrollFrame:GetEffectiveScale()

    local frameX = cursorX - WorldMapScrollFrame:GetLeft()
    local frameY = WorldMapScrollFrame:GetTop() - cursorY

    local oldScale = WorldMapDetailFrame:GetScale()
    local newScale = oldScale * (1.0 + delta * ZOOM_STEP)
    newScale = math.max(MIN_ZOOM, newScale)
    newScale = math.min(MAX_ZOOM, newScale)

    SetDetailFrameScale(newScale)

    WorldMapScrollFrame.maxX = ((WorldMapDetailFrame:GetWidth() * newScale) - WorldMapScrollFrame:GetWidth()) / newScale
    WorldMapScrollFrame.maxY = ((WorldMapDetailFrame:GetHeight() * newScale) - WorldMapScrollFrame:GetHeight()) / newScale
    WorldMapScrollFrame.zoomedIn = WorldMapDetailFrame:GetScale() > MIN_ZOOM

    local centerX = oldScrollH + frameX / oldScale
    local centerY = oldScrollV + frameY / oldScale
    local newScrollH = centerX - frameX / newScale
    local newScrollV = centerY - frameY / newScale

    newScrollH = math.min(newScrollH, WorldMapScrollFrame.maxX)
    newScrollH = math.max(0, newScrollH)
    newScrollV = math.min(newScrollV, WorldMapScrollFrame.maxY)
    newScrollV = math.max(0, newScrollV)

    WorldMapScrollFrame:SetHorizontalScroll(newScrollH)
    WorldMapScrollFrame:SetVerticalScroll(newScrollV)
    AfterScrollOrPan()
end

-- Click and Drag Panning
local function WorldMapButton_OnMouseDown(self, button)
    if button == "LeftButton" and WorldMapScrollFrame.zoomedIn then
        WorldMapScrollFrame.panning = true
        local x, y = GetCursorPosition()
        WorldMapScrollFrame.cursorX = x
        WorldMapScrollFrame.cursorY = y
        WorldMapScrollFrame.x = WorldMapScrollFrame:GetHorizontalScroll()
        WorldMapScrollFrame.y = WorldMapScrollFrame:GetVerticalScroll()
        WorldMapScrollFrame.moved = false
    end
end

local function WorldMapButton_OnMouseUp(self, button)
    WorldMapScrollFrame.panning = false
    if not WorldMapScrollFrame.moved then
        -- Default zoom click (subzone/continent click)
        WorldMapButton_OnClick(WorldMapButton, button)
        -- Reset scale when changing zones
        SetDetailFrameScale(MIN_ZOOM)
        WorldMapScrollFrame:SetHorizontalScroll(0)
        WorldMapScrollFrame:SetVerticalScroll(0)
        AfterScrollOrPan()
        WorldMapScrollFrame.zoomedIn = false
    end
    WorldMapScrollFrame.moved = false
end

local function WorldMapScrollFrame_OnPan(cursorX, cursorY)
    local dX = WorldMapScrollFrame.cursorX - cursorX
    local dY = cursorY - WorldMapScrollFrame.cursorY
    local scale = WorldMapScrollFrame:GetEffectiveScale()
    dX = dX / scale
    dY = dY / scale
    if math.abs(dX) >= 1 or math.abs(dY) >= 1 then
        WorldMapScrollFrame.moved = true
        
        local x = math.max(0, dX + WorldMapScrollFrame.x)
        x = math.min(x, WorldMapScrollFrame.maxX)
        WorldMapScrollFrame:SetHorizontalScroll(x)

        local y = math.max(0, dY + WorldMapScrollFrame.y)
        y = math.min(y, WorldMapScrollFrame.maxY)
        WorldMapScrollFrame:SetVerticalScroll(y)
        AfterScrollOrPan()
    end
end

local function WorldMapButton_OnUpdate(self, elapsed)
    if WorldMapScrollFrame.panning then
        local x, y = GetCursorPosition()
        WorldMapScrollFrame_OnPan(x, y)
    end
end

function Zoom.Enable()
    -- Create the scroll frame dynamically if it doesn't exist yet
    if not WorldMapScrollFrame then
        WorldMapScrollFrame = CreateFrame("ScrollFrame", "WorldMapScrollFrame", WorldMapFrame, "FauxScrollFrameTemplate")
        WorldMapScrollFrame:SetSize(1002, 668)
        WorldMapScrollFrame:SetPoint("TOPLEFT", WorldMapPositioningGuide, "TOPLEFT")
    end

    -- Set nesting structures
    WorldMapScrollFrame:SetScrollChild(WorldMapDetailFrame)
    WorldMapScrollFrame:SetScript("OnMouseWheel", WorldMapScrollFrame_OnMouseWheel)
    WorldMapButton:SetScript("OnMouseDown", WorldMapButton_OnMouseDown)
    WorldMapButton:SetScript("OnMouseUp", WorldMapButton_OnMouseUp)
    WorldMapDetailFrame:SetParent(WorldMapScrollFrame)

    -- Reparent the area label so it doesn't move or scale with the detail frame zoom
    if WorldMapFrameAreaFrame then
        WorldMapFrameAreaFrame:SetParent(WorldMapFrame)
        WorldMapFrameAreaFrame:SetFrameLevel(WORLDMAP_POI_FRAMELEVEL or 3)
        WorldMapFrameAreaFrame:ClearAllPoints()
        WorldMapFrameAreaFrame:SetPoint("TOP", WorldMapScrollFrame, "TOP", 0, -10)
    end

    -- Disable built-in map ping model scale issues
    if WorldMapPing then
        WorldMapPing.Show = function() return end
        WorldMapPing:SetModelScale(0)
    end

    -- Hook layout update routines
    hooksecurefunc("WorldMapFrame_SetFullMapView", SetupWorldMapFrame)
    hooksecurefunc("WorldMapFrame_SetQuestMapView", SetupWorldMapFrame)
    hooksecurefunc("WorldMap_ToggleSizeDown", SetupWorldMapFrame)
    hooksecurefunc("WorldMap_ToggleSizeUp", SetupWorldMapFrame)
    hooksecurefunc("WorldMapFrame_UpdateQuests", ResizeQuestPOIs)
    hooksecurefunc("WorldMapFrame_SetPOIMaxBounds", SetPOIMaxBounds)

    -- Correct positioning of the quest objectives checkbox in minimized view
    hooksecurefunc("WorldMapQuestShowObjectives_AdjustPosition", function()
        if not WorldMapQuestShowObjectives then return end
        if WORLDMAP_SETTINGS.size == WORLDMAP_WINDOWED_SIZE then
            WorldMapQuestShowObjectives:SetPoint("BOTTOMRIGHT", WorldMapPositioningGuide, "BOTTOMRIGHT",
                -30 - (WorldMapQuestShowObjectivesText and WorldMapQuestShowObjectivesText:GetWidth() or 0), -9)
        else
            WorldMapQuestShowObjectives:SetPoint("BOTTOMRIGHT", WorldMapPositioningGuide, "BOTTOMRIGHT",
                -15 - (WorldMapQuestShowObjectivesText and WorldMapQuestShowObjectivesText:GetWidth() or 0), 4)
        end
    end)

    -- Windowed map drag-to-move bindings
    WorldMapTitleButton:SetScript("OnDragStart", function()
        if WorldMapScreenAnchor then
            WorldMapScreenAnchor:ClearAllPoints()
        end
        WorldMapFrame:ClearAllPoints()
        WorldMapFrame:StartMoving()
    end)
    WorldMapTitleButton:SetScript("OnDragStop", function()
        WorldMapFrame:StopMovingOrSizing()
        if WorldMapScreenAnchor then
            WorldMapScreenAnchor:StartMoving()
            WorldMapScreenAnchor:SetPoint("TOPLEFT", WorldMapFrame)
            WorldMapScreenAnchor:StopMovingOrSizing()
        end
    end)

    -- Setup custom OnUpdate for map mouse positioning
    WorldMapButton:HookScript("OnUpdate", WorldMapButton_OnUpdate)

    -- Setup on show
    local original_WorldMapFrame_OnShow = WorldMapFrame:GetScript("OnShow")
    WorldMapFrame:SetScript("OnShow", function(self)
        if original_WorldMapFrame_OnShow then
            original_WorldMapFrame_OnShow(self)
        end
        SetupWorldMapFrame()
    end)
end
